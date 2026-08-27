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

LIMITAÇÃO DA API PÚBLICA: o campo `partes` (com CPF/CNPJ) não está disponível
na camada pública do DataJud — apenas na API restrita (convênio CNJ).
Estratégia atual: busca por número do processo usando CNPJ formatado como texto
no campo `numeroProcesso`, ou por razão social quando fornecida.
"""
from __future__ import annotations

import logging
import os
import re
import time

import requests as req

from .base import (SubradarSource, snapshot_changed, upsert, _ciclo_atual,
                   FonteIndisponivel)

logger = logging.getLogger("subradar.datajud")

DATAJUD_KEY  = os.environ.get("DATAJUD_API_KEY", "")
DATAJUD_BASE = "https://api-publica.datajud.cnj.jus.br"

# Índices de tribunais — cobertura ampliada (top 16 por volume + todos TRFs)
INDICES = [
    # Estaduais — maior volume de falências e execuções fiscais
    "api_publica_tjsp",   # SP
    "api_publica_tjrj",   # RJ
    "api_publica_tjmg",   # MG
    "api_publica_tjrs",   # RS
    "api_publica_tjpr",   # PR
    "api_publica_tjba",   # BA
    "api_publica_tjsc",   # SC
    "api_publica_tjgo",   # GO
    "api_publica_tjpe",   # PE
    "api_publica_tjce",   # CE
    "api_publica_tjdf",   # DF
    "api_publica_tjmt",   # MT
    "api_publica_tjms",   # MS
    "api_publica_tjam",   # AM
    "api_publica_tjpa",   # PA
    "api_publica_tjma",   # MA
    # Federais — execuções fiscais da União
    "api_publica_trf1",   # 1ª região (DF, MG, GO, MT, PA, AM, etc.)
    "api_publica_trf2",   # 2ª região (RJ, ES)
    "api_publica_trf3",   # 3ª região (SP, MS)
    "api_publica_trf4",   # 4ª região (RS, PR, SC)
    "api_publica_trf5",   # 5ª região (PE, CE, BA, SE, AL, RN, PB)
    "api_publica_trf6",   # 6ª região (MG — criado 2022)
    # Superior
    "api_publica_stj",    # STJ — recursos em processos falimentares relevantes
]

# Códigos de classe CNJ relevantes para compliance (expandido)
CLASSES_INTERESSE = {
    "1116": "Falência",
    "1294": "Recuperação Judicial",
    "1295": "Recuperação Extrajudicial",
    "1296": "Insolvência Civil",
    "436":  "Execução Fiscal",
    "1201": "Liquidação Extrajudicial",
    "109":  "Ação Penal — Procedimento Ordinário",  # crimes econômicos
    "241":  "Improbidade Administrativa",
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


def _search(indice: str, cnpj_digits: str, razao_social: str | None = None) -> list[dict]:
    """Busca processos por razão social ou CNPJ num índice DataJud.

    A API pública não expõe o campo partes.CPFouCNPJ — buscamos por
    razão social (quando disponível) ou pelo número do CNPJ como texto.
    """
    # Termo de busca: prefere razão social, fallback para CNPJ formatado
    cnpj_fmt = f"{cnpj_digits[:2]}.{cnpj_digits[2:5]}.{cnpj_digits[5:8]}/{cnpj_digits[8:12]}-{cnpj_digits[12:14]}"
    search_terms = []
    if razao_social:
        search_terms.append(razao_social)
    search_terms.append(cnpj_fmt)
    search_query = " OR ".join(f'"{t}"' for t in search_terms)

    query = {
        "size": 20,
        "query": {
            "bool": {
                "must": [
                    {"query_string": {"query": search_query, "default_operator": "OR"}},
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
            raise FonteIndisponivel("APIKey do DataJud inválida ou ausente")
        if r.status_code == 404:
            # Índice inexistente para este tribunal: não é falha da consulta.
            return []
        if r.status_code == 400:
            raise FonteIndisponivel(f"consulta rejeitada pelo índice {indice} (HTTP 400)")
        r.raise_for_status()
        hits = r.json().get("hits", {}).get("hits", [])
        return [h["_source"] for h in hits]
    except FonteIndisponivel:
        raise
    except Exception as e:
        raise FonteIndisponivel(f"falha ao consultar o índice {indice}", str(e))


class DataJudConnector(SubradarSource):
    fonte         = "datajud"
    request_delay = 0.5

    def consultar_cnpj(self, cnpj: str, razao_social: str | None = None) -> list[dict]:
        cnpj_limpo = _strip(cnpj)
        cnpj_fmt   = _fmt(cnpj_limpo)
        ciclo      = _ciclo_atual()

        # A API pública do DataJud NÃO publica as partes do processo. O _source
        # devolvido traz classe, assuntos, movimentos e número — nenhum nome,
        # nenhum CPF/CNPJ. Verificado contra a API real: query_string por
        # "PETROBRAS" ou pelo CNPJ devolve 0 resultados, enquanto a mesma busca
        # por um numeroProcesso colhido do índice devolve 2.
        #
        # Logo, buscar processo por parte aqui é estruturalmente impossível, e
        # o "nada encontrado" desta fonte nunca foi evidência de ausência. Ela
        # se declara não consultada até existir convênio CNJ (API restrita) ou
        # a cobertura migrar para o dataset `processes` do BigDataCorp, como
        # já foi feito no Subradar Imob.
        raise FonteIndisponivel(
            "a API pública do DataJud não indexa as partes do processo",
            "consulta por CNPJ ou razão social não retorna resultado por limitação da fonte; "
            "cobertura judicial depende de convênio CNJ ou de fonte alternativa",
        )

        if not DATAJUD_KEY:  # pragma: no cover - inalcançável, mantido para o dia da migração
            logger.info("DataJud: DATAJUD_API_KEY não configurada — fonte indisponível")
            raise FonteIndisponivel("DATAJUD_API_KEY não configurada")

        todos: list[dict] = []
        for indice in INDICES:
            processos = _search(indice, cnpj_limpo, razao_social)
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
            # Não afirmar ausência: ver a nota no topo de consultar_cnpj.
            raise FonteIndisponivel(
                "a API pública do DataJud não indexa as partes do processo",
                "resultado vazio não distingue 'não há processo' de 'não é possível buscar por parte'",
            )

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
