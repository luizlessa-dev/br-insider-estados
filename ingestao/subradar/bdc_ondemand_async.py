"""
Módulo: BDC On-Demand Async (BigDataCorp)

Submete queries assíncronas para datasets on-demand do BigDataCorp e armazena
os queryIds no banco (sub_bdc_queries). O resultado chega via webhook:
  POST https://redggdtakzmsabwvjzhb.supabase.co/functions/v1/bdc-webhook

Fluxo:
  1. Após rodar os conectores síncronos, runner.py chama `submit_ondemand_pj`
     (ou `submit_ondemand_pf`) com CNPJ/CPF + dossie_id.
  2. Este módulo itera pelos datasets configurados e faz POST para a API BDC.
  3. BDC retorna {"MatchKeys": "queryid{uuid}"} — salvo em sub_bdc_queries.
  4. Quando o BDC processar, chama o webhook, que converte em alertas.

Env vars:
  BDC_TOKEN_ID        — header TokenId
  BDC_ACCESS_TOKEN    — header AccessToken
  BDC_WEBHOOK_URL     — URL pública da Edge Function (NotificationUrl)
  SUPABASE_URL        — URL do projeto Supabase
  SUPABASE_SERVICE_KEY — service_role key para inserir em sub_bdc_queries

Datasets disponíveis (ativados em 2026-07-31):
  PJ: ondemand_pgfn, ondemand_debitos_estaduais_negativa, ondemand_cnj_negativa,
      ondemand_debitos_trabalhistas_negativa, ondemand_fgts, ondemand_ibama_embargos,
      ondemand_ibama_negativa, ondemand_ibama_regulatoria, ondemand_cgu_negativa,
      ondemand_cgu_correcional_negativa, ondemand_acoes_trabalhistas,
      ondemand_acoes_judiciais_nada_consta, ondemand_comprot
  PF: ondemand_pgfn, ondemand_debitos_estaduais_negativa, ondemand_cnj_negativa,
      ondemand_debitos_trabalhistas_negativa, ondemand_ibama_embargos,
      ondemand_ibama_negativa, ondemand_ibama_regulatoria, ondemand_cgu_correcional_negativa,
      ondemand_acoes_trabalhistas, ondemand_acoes_judiciais_nada_consta, ondemand_comprot,
      ondemand_policia_federal_antecedentes_criminais,
      ondemand_bacen_sancoes_administrativas, ondemand_tse_quitacao_eleitoral
"""
from __future__ import annotations

import logging
import os
import re
import uuid
from typing import Literal

import requests

logger = logging.getLogger("subradar.bdc_ondemand")

_BDC_URL     = "https://plataforma.bigdatacorp.com.br/pessoas"
_BDC_URL_PJ  = "https://plataforma.bigdatacorp.com.br/empresas"
_TOKEN_ID    = os.environ.get("BDC_TOKEN_ID", "")
_ACCESS_TOKEN = os.environ.get("BDC_ACCESS_TOKEN", "")
_WEBHOOK_URL = os.environ.get(
    "BDC_WEBHOOK_URL",
    "https://redggdtakzmsabwvjzhb.supabase.co/functions/v1/bdc-webhook",
)
_SUPABASE_URL = os.environ.get("SUPABASE_URL", "https://redggdtakzmsabwvjzhb.supabase.co")
_SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_KEY", "")

# Datasets on-demand para PJ (CNPJ)
DATASETS_PJ = [
    "ondemand_pgfn",
    "ondemand_debitos_estaduais_negativa",
    "ondemand_cnj_negativa",
    "ondemand_debitos_trabalhistas_negativa",
    "ondemand_fgts",
    "ondemand_ibama_embargos",
    "ondemand_ibama_negativa",
    "ondemand_ibama_regulatoria",
    "ondemand_cgu_negativa",
    "ondemand_cgu_correcional_negativa",
    "ondemand_acoes_trabalhistas",
    "ondemand_acoes_judiciais_nada_consta",
    "ondemand_comprot",
]

# Datasets on-demand para PF (CPF)
DATASETS_PF = [
    "ondemand_pgfn",
    "ondemand_debitos_estaduais_negativa",
    "ondemand_cnj_negativa",
    "ondemand_debitos_trabalhistas_negativa",
    "ondemand_ibama_embargos",
    "ondemand_ibama_negativa",
    "ondemand_ibama_regulatoria",
    "ondemand_cgu_correcional_negativa",
    "ondemand_acoes_trabalhistas",
    "ondemand_acoes_judiciais_nada_consta",
    "ondemand_comprot",
    "ondemand_policia_federal_antecedentes_criminais",
    "ondemand_bacen_sancoes_administrativas",
    "ondemand_tse_quitacao_eleitoral",
]


def _strip(doc: str) -> str:
    return re.sub(r"\D", "", str(doc or ""))


def _headers() -> dict:
    return {
        "TokenId": _TOKEN_ID,
        "AccessToken": _ACCESS_TOKEN,
        "Content-Type": "application/json",
    }


def _submit_one(
    dataset: str,
    doc: str,
    doc_type: Literal["cnpj", "cpf"],
    dossie_id: str,
) -> str | None:
    """
    Submete uma query async para um dataset BDC.
    Retorna o queryId (sem chaves) ou None em caso de falha.
    """
    prefix = "doc" if doc_type == "cpf" else "doc"
    url = _BDC_URL if doc_type == "cpf" else _BDC_URL_PJ

    payload = {
        "Datasets": dataset,
        "q": f"{prefix}{{{doc}}}",
        "Limit": 1,
        "NotificationUrl": _WEBHOOK_URL,
    }

    try:
        resp = requests.post(url, json=payload, headers=_headers(), timeout=30)
    except Exception as exc:
        logger.debug("bdc_ondemand/%s: erro de rede — %s", dataset, exc)
        return None

    if not resp.ok:
        logger.debug("bdc_ondemand/%s: HTTP %d para %s", dataset, resp.status_code, doc)
        return None

    try:
        body = resp.json()
    except Exception:
        return None

    # BDC retorna {"MatchKeys": "queryid{uuid-aqui}"}
    match_keys = body.get("MatchKeys") or body.get("matchkeys") or ""
    if not match_keys or "queryid{" not in str(match_keys):
        logger.debug("bdc_ondemand/%s: resposta inesperada — %r", dataset, body)
        return None

    raw = str(match_keys).replace("queryid{", "").replace("}", "").strip()
    logger.debug("bdc_ondemand/%s: queryId=%s para %s", dataset, raw, doc)
    return raw


def _save_query(
    query_id: str,
    dossie_id: str,
    cnpj: str,
    dataset: str,
) -> bool:
    """Persiste queryId em sub_bdc_queries via Supabase REST."""
    if not _SUPABASE_KEY:
        logger.warning("bdc_ondemand: SUPABASE_SERVICE_KEY ausente — queryId não salvo")
        return False

    url = f"{_SUPABASE_URL}/rest/v1/sub_bdc_queries"
    headers = {
        "apikey": _SUPABASE_KEY,
        "Authorization": f"Bearer {_SUPABASE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "return=minimal",
    }
    body = {
        "id": str(uuid.uuid4()),
        "query_id": query_id,
        "dossie_id": dossie_id,
        "cnpj": cnpj,
        "dataset": dataset,
        "status": "pending",
    }

    try:
        resp = requests.post(url, json=body, headers=headers, timeout=15)
        if resp.ok:
            return True
        logger.warning(
            "bdc_ondemand: erro ao salvar queryId %s — HTTP %d %s",
            query_id, resp.status_code, resp.text[:200],
        )
        return False
    except Exception as exc:
        logger.warning("bdc_ondemand: falha ao salvar queryId — %s", exc)
        return False


def submit_ondemand_pj(cnpj: str, dossie_id: str) -> int:
    """
    Submete todas as queries PJ on-demand para o CNPJ informado.
    Retorna o número de queries submetidas com sucesso.
    """
    if not _TOKEN_ID or not _ACCESS_TOKEN:
        logger.debug("bdc_ondemand_pj: credenciais BDC ausentes — pulando")
        return 0

    cnpj14 = _strip(cnpj)
    if len(cnpj14) != 14:
        logger.debug("bdc_ondemand_pj: CNPJ inválido (%r)", cnpj)
        return 0

    submitted = 0
    for dataset in DATASETS_PJ:
        query_id = _submit_one(dataset, cnpj14, "cnpj", dossie_id)
        if query_id and _save_query(query_id, dossie_id, cnpj14, dataset):
            submitted += 1

    logger.info("bdc_ondemand_pj: %d/%d queries submetidas para CNPJ %s",
                submitted, len(DATASETS_PJ), cnpj14)
    return submitted


def submit_ondemand_pf(cpf: str, dossie_id: str) -> int:
    """
    Submete todas as queries PF on-demand para o CPF informado.
    Retorna o número de queries submetidas com sucesso.
    """
    if not _TOKEN_ID or not _ACCESS_TOKEN:
        logger.debug("bdc_ondemand_pf: credenciais BDC ausentes — pulando")
        return 0

    cpf11 = _strip(cpf)
    if len(cpf11) != 11:
        logger.debug("bdc_ondemand_pf: CPF inválido (%r)", cpf)
        return 0

    submitted = 0
    for dataset in DATASETS_PF:
        query_id = _submit_one(dataset, cpf11, "cpf", dossie_id)
        if query_id and _save_query(query_id, dossie_id, cpf11, dataset):
            submitted += 1

    logger.info("bdc_ondemand_pf: %d/%d queries submetidas para CPF %s",
                submitted, len(DATASETS_PF), cpf11)
    return submitted
