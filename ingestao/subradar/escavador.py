"""
Conector: Escavador Business API — Processos Judiciais por CNPJ

API: api.escavador.com/api/v2
Auth: Bearer Token (PAT) — obter em api.escavador.com após ativação da conta
Docs: https://api.escavador.com/v1/docs/

Cobertura: todos os tribunais brasileiros indexados pelo Escavador (TJs, TRFs,
           TST, STJ, STF, JEFs, TREs) + publicações em DJe

Modelo de cobrança: créditos pré-pagos (validade 90 dias), debitados por
  consulta. Custo estimado: R$ 4,50 na primeira consulta do dia por CNPJ;
  R$ 0,05 em consultas repetidas no mesmo dia.

Variável de ambiente: ESCAVADOR_API_KEY

Severidade aplicada:
  critico  — Falência, Insolvência Civil, Recuperação Judicial/Extrajudicial
  atencao  — Execução Fiscal, Improbidade Administrativa, Ação Penal
  info     — demais classes processuais
"""
from __future__ import annotations

import logging
import os
import re
import time

import requests

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.escavador")

ESCAVADOR_KEY  = os.environ.get("ESCAVADOR_API_KEY", "")
ESCAVADOR_BASE = "https://api.escavador.com/api/v2"

# Palavras-chave no título do processo → severidade
# (a API v2 /envolvido/processos não retorna classe CNJ — usamos título e tribunal)
_CRITICO_KW = [
    "falência", "falencia", "recuperação judicial", "recuperacao judicial",
    "recuperação extrajudicial", "recuperacao extrajudicial", "insolvência", "insolvencia",
]
_ATENCAO_KW = [
    "execução fiscal", "execucao fiscal", "improbidade", "ação penal", "acao penal",
    "execução trabalhista", "execucao trabalhista",
]

# Siglas de tribunal → categoria legível
_TRIB_CAT = {
    "TRT": "Trabalhista",
    "TRF": "Federal",
    "TJ":  "Estadual",
    "TST": "Trabalhista (TST)",
    "STJ": "Superior",
    "STF": "Supremo",
}


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", str(cnpj or ""))


def _fmt(cnpj: str) -> str:
    c = _strip(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _headers() -> dict:
    return {
        "Authorization": f"Bearer {ESCAVADOR_KEY}",
        "Accept": "application/json",
        "User-Agent": "Subradar/1.0 (compliance; contato@subradar.com.br)",
    }


def _buscar_processos(cnpj_digits: str) -> list[dict]:
    """
    Consulta paginada de processos por CNPJ via API v2.
    Retorna lista bruta de processos (todos os itens, todas as páginas).
    """
    todos: list[dict] = []
    page = 1

    while True:
        try:
            r = requests.get(
                f"{ESCAVADOR_BASE}/envolvido/processos",
                params={"cpf_cnpj": cnpj_digits, "page": page, "limit": 50},
                headers=_headers(),
                timeout=30,
            )
        except Exception as e:
            logger.warning("Escavador: erro de rede na pág %d para %s: %s", page, cnpj_digits, e)
            break

        if r.status_code == 401:
            logger.error("Escavador: APIKey inválida ou sem créditos")
            break
        if r.status_code == 402:
            logger.error("Escavador: créditos esgotados")
            break
        if r.status_code == 404:
            break
        if not r.ok:
            logger.warning("Escavador: HTTP %s para %s pág %d", r.status_code, cnpj_digits, page)
            break

        try:
            data = r.json()
        except Exception:
            logger.warning("Escavador: resposta não-JSON para %s", cnpj_digits)
            break

        items = data.get("items") or data.get("data") or []
        todos.extend(items)

        meta = data.get("meta") or {}
        last_page = meta.get("last_page") or 1
        if page >= last_page or not items:
            break

        page += 1
        time.sleep(0.3)  # respeita rate limit

    return todos


def _severidade_por_titulo(titulo: str) -> str:
    t = titulo.lower()
    if any(kw in t for kw in _CRITICO_KW):
        return "critico"
    if any(kw in t for kw in _ATENCAO_KW):
        return "atencao"
    return "info"


def _tribunal_sigla(processo: dict) -> str:
    """Extrai sigla do tribunal da lista de fontes ou unidade_origem."""
    fontes = processo.get("fontes") or []
    if fontes:
        return fontes[0].get("sigla") or "N/D"
    unidade = processo.get("unidade_origem") or {}
    return unidade.get("tribunal_sigla") or "N/D"


def _categoria_tribunal(sigla: str) -> str:
    for prefixo, cat in _TRIB_CAT.items():
        if sigla.startswith(prefixo):
            return cat
    return "Judicial"


def _montar_alerta(processo: dict, cnpj_fmt: str, ciclo: str) -> dict:
    num    = processo.get("numero_cnj") or "N/D"
    trib   = _tribunal_sigla(processo)
    cat    = _categoria_tribunal(trib)
    dt_upd = (processo.get("data_ultima_movimentacao") or "")[:10]
    polo_a = processo.get("titulo_polo_ativo") or ""
    polo_p = processo.get("titulo_polo_passivo") or ""

    # Monta título descritivo com polos
    titulo_processo = f"Processo Judicial — {cat} — {trib}"
    sev = _severidade_por_titulo(polo_a + " " + polo_p + " " + trib)

    descricao = (
        f"Processo {num}. Tribunal: {trib}. "
        f"Polo ativo: {polo_a or 'N/D'}. Polo passivo: {polo_p or 'N/D'}. "
        f"Última movimentação: {dt_upd or 'N/D'}."
    )

    return {
        "cnpj": cnpj_fmt,
        "ciclo": ciclo,
        "fonte": "escavador",
        "categoria": "judicial",
        "severidade": sev,
        "titulo": f"Escavador — {titulo_processo} — {num}",
        "descricao": descricao,
        "referencia_id": num,
        "data_evento": dt_upd or None,
        "url_fonte": f"https://www.escavador.com/processos/{num.replace('.', '').replace('/', '-')}",
        "is_novo": True,
    }


class EscavadorConnector(SubradarSource):
    fonte         = "escavador"
    request_delay = 0.5

    def consultar_cnpj(self, cnpj: str) -> list[dict]:
        cnpj_digits = _strip(cnpj)
        cnpj_fmt    = _fmt(cnpj_digits)
        ciclo       = _ciclo_atual()

        if not ESCAVADOR_KEY:
            logger.info("Escavador: ESCAVADOR_API_KEY não configurada — fonte indisponível")
            return []

        processos = _buscar_processos(cnpj_digits)

        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, processos)
        if not mudou:
            logger.info("Escavador: sem mudanças para %s", cnpj_fmt)
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt,
            "fonte": self.fonte,
            "ciclo": ciclo,
            "hash_dados": hash_novo,
            "dados": {"total": len(processos)},
        }])

        if not processos:
            return []

        # Filtra duplicatas por número CNJ
        seen: set[str] = set()
        alertas: list[dict] = []
        for p in processos:
            num = p.get("numero_cnj") or p.get("numero") or ""
            if num in seen:
                continue
            seen.add(num)
            alertas.append(_montar_alerta(p, cnpj_fmt, ciclo))

        logger.info("Escavador: %d processos para %s", len(alertas), cnpj_fmt)
        return alertas
