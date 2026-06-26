"""
Conector: DataJud / CNJ — Falências e Recuperações Judiciais

API: api-publica.datajud.cnj.jus.br (Elasticsearch)
Auth: APIKey CNJ — cadastrar em https://datajud-wiki.cnj.jus.br/api-publica/acesso

Variável de ambiente: DATAJUD_API_KEY

Consulta por CNPJ nas classes processuais de interesse:
  1116 = Falência
  1294 = Recuperação Judicial
  1295 = Recuperação Extrajudicial
  1296 = Insolvência Civil

Estratégia: busca texto-livre pelo CNPJ (sem formatação) em `dadosBasicos.partes.CPFouCNPJ`.
"""
from __future__ import annotations

import logging
import os
import re
import time

import requests as req

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.datajud")

DATAJUD_KEY  = os.environ.get("DATAJUD_API_KEY", "")
DATAJUD_BASE = "https://api-publica.datajud.cnj.jus.br"

# Índices de tribunais (um por tribunal — consultamos em paralelo os maiores)
INDICES = [
    "api_publica_tjsp",   # SP — maior volume de falências
    "api_publica_tjrj",
    "api_publica_tjmg",
    "api_publica_tjrs",
    "api_publica_tjpr",
    "api_publica_tjba",
    "api_publica_trf1",   # federal 1ª região
    "api_publica_trf2",
    "api_publica_trf3",
    "api_publica_trf4",
]

# Códigos de classe CNJ relevantes para compliance
CLASSES_INTERESSE = {
    "1116": "Falência",
    "1294": "Recuperação Judicial",
    "1295": "Recuperação Extrajudicial",
    "1296": "Insolvência Civil",
    "436":  "Execução Fiscal",
}


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", str(cnpj or ""))


def _fmt(cnpj: str) -> str:
    c = _strip(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _headers() -> dict:
    return {
        "Authorization": f"APIKey {DATAJUD_KEY}",
        "Content-Type": "application/json",
    }


def _search(indice: str, cnpj_digits: str) -> list[dict]:
    """Busca processos por CNPJ num índice DataJud."""
    query = {
        "size": 20,
        "query": {
            "bool": {
                "must": [
                    {"term": {"dadosBasicos.partes.CPFouCNPJ": cnpj_digits}},
                ],
                "filter": [
                    {"terms": {"classe.codigo": list(CLASSES_INTERESSE.keys())}},
                ],
            }
        },
        "_source": [
            "numeroProcesso", "classe", "dataHoraUltimaAtualizacao",
            "orgaoJulgador", "movimentos", "assuntos",
        ],
    }
    try:
        r = req.post(
            f"{DATAJUD_BASE}/{indice}/_search",
            json=query,
            headers=_headers(),
            timeout=20,
        )
        if r.status_code == 401:
            logger.warning("DataJud: APIKey inválida ou ausente")
            return []
        if r.status_code in (400, 404):
            return []
        r.raise_for_status()
        hits = r.json().get("hits", {}).get("hits", [])
        return [h["_source"] for h in hits]
    except Exception as e:
        logger.debug("DataJud %s: %s", indice, e)
        return []


class DataJudConnector(SubradarSource):
    fonte         = "datajud"
    request_delay = 0.5

    def consultar_cnpj(self, cnpj: str, razao_social: str | None = None) -> list[dict]:
        cnpj_limpo = _strip(cnpj)
        cnpj_fmt   = _fmt(cnpj_limpo)
        ciclo      = _ciclo_atual()

        if not DATAJUD_KEY:
            logger.info("DataJud: DATAJUD_API_KEY não configurada — fonte indisponível")
            return [{
                "cnpj": cnpj_fmt, "ciclo": ciclo, "fonte": self.fonte,
                "categoria": "judicial", "severidade": "info",
                "titulo": "DataJud — cobertura indisponível",
                "descricao": (
                    "A consulta de falências e recuperações judiciais requer APIKey do CNJ. "
                    "Cadastre em https://datajud-wiki.cnj.jus.br/api-publica/acesso e "
                    "defina DATAJUD_API_KEY no .env."
                ),
                "url_fonte": "https://datajud-wiki.cnj.jus.br",
                "is_novo": True,
            }]

        todos: list[dict] = []
        for indice in INDICES:
            processos = _search(indice, cnpj_limpo)
            todos.extend(processos)
            if processos:
                time.sleep(self.request_delay)

        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, todos)
        if not mudou:
            logger.info("DataJud: sem mudanças para %s", cnpj_fmt)
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt, "fonte": self.fonte, "ciclo": ciclo,
            "hash_dados": hash_novo, "dados": {"total": len(todos)},
        }])

        if not todos:
            return [{
                "cnpj": cnpj_fmt, "ciclo": ciclo, "fonte": self.fonte,
                "categoria": "judicial", "severidade": "ok",
                "titulo": "Sem processos de falência/recuperação judicial (DataJud)",
                "descricao": "CNPJ não encontrado como parte em processos de falência, recuperação judicial ou execução fiscal nos tribunais consultados.",
                "url_fonte": "https://datajud.cnj.jus.br",
                "is_novo": True,
            }]

        alertas = []
        seen: set[str] = set()
        for p in todos:
            num = p.get("numeroProcesso") or ""
            if num in seen:
                continue
            seen.add(num)

            classe_cod  = str((p.get("classe") or {}).get("codigo") or "")
            classe_nome = CLASSES_INTERESSE.get(classe_cod, (p.get("classe") or {}).get("nome") or "N/D")
            tribunal    = (p.get("orgaoJulgador") or {}).get("nome") or "N/D"
            dt_upd      = (p.get("dataHoraUltimaAtualizacao") or "")[:10]

            sev = "critico" if classe_cod in ("1116", "1296") else "atencao"

            alertas.append({
                "cnpj": cnpj_fmt, "ciclo": ciclo, "fonte": self.fonte,
                "categoria": "judicial",
                "severidade": sev,
                "titulo": f"DataJud — {classe_nome} — Processo {num}",
                "descricao": (
                    f"Processo de {classe_nome} identificado no DataJud/CNJ. "
                    f"Tribunal: {tribunal}. "
                    f"Última atualização: {dt_upd}."
                ),
                "referencia_id": num,
                "data_evento": dt_upd or None,
                "url_fonte": f"https://datajud.cnj.jus.br/processo/{num}",
                "is_novo": True,
            })

        logger.info("DataJud: %d processos para %s", len(alertas), cnpj_fmt)
        return alertas
