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

# Classes CNJ → severidade
_CRITICO = {"1116", "1294", "1295", "1296"}   # Falência, RJ, RE, Insolvência Civil
_ATENCAO = {"436", "241", "109"}               # Exec. Fiscal, Improbidade, Ação Penal

_CLASSE_NOME = {
    "1116": "Falência",
    "1294": "Recuperação Judicial",
    "1295": "Recuperação Extrajudicial",
    "1296": "Insolvência Civil",
    "436":  "Execução Fiscal",
    "241":  "Improbidade Administrativa",
    "109":  "Ação Penal",
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
                params={"cpf_cnpj": cnpj_digits, "page": page, "per_page": 50},
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


def _severidade(classe_codigo: str) -> str:
    if classe_codigo in _CRITICO:
        return "critico"
    if classe_codigo in _ATENCAO:
        return "atencao"
    return "info"


def _montar_alerta(processo: dict, cnpj_fmt: str, ciclo: str) -> dict:
    num    = processo.get("numero_cnj") or processo.get("numero") or "N/D"
    classe = processo.get("classe") or {}
    cod    = str(classe.get("codigo") or "")
    nome   = classe.get("nome") or _CLASSE_NOME.get(cod, "Processo Judicial")
    trib   = (processo.get("tribunal") or {}).get("sigla") or "N/D"
    dt_upd = (processo.get("data_ultima_movimentacao") or "")[:10]
    sev    = _severidade(cod)

    ultima_mov = ""
    movs = processo.get("movimentacoes") or []
    if movs:
        ultima_mov = (movs[0].get("descricao") or "")[:200]

    descricao = (
        f"Processo {num} identificado pelo Escavador. "
        f"Tribunal: {trib}. "
        f"Última atualização: {dt_upd or 'N/D'}."
    )
    if ultima_mov:
        descricao += f" Última movimentação: {ultima_mov}."

    return {
        "cnpj": cnpj_fmt,
        "ciclo": ciclo,
        "fonte": "escavador",
        "categoria": "judicial",
        "severidade": sev,
        "titulo": f"Escavador — {nome} — {trib} — {num}",
        "descricao": descricao,
        "referencia_id": num,
        "data_evento": dt_upd or None,
        "url_fonte": f"https://www.escavador.com/processos/{num.replace('.', '').replace('/', '-').replace('-', '')}",
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
