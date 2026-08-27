"""
Direct Data — MonitorApp: Monitoramento de Entidades com Alertas Push

Fluxo:
  1. Cadastrar entidade: POST /api/MonitorApp/RegisterEntity
  2. Registrar webhook:  POST /api/Webhook/CreateUrlCallBack  (opcional — fallback = poll)
  3. Confirmar webhook:  POST /api/Webhook/ConfirmUrlCallBack
  4. Ler eventos:        GET  /api/MonitorApp/GetMonitoringEvents  (poll periódico)
                         GET  /api/MonitorApp/GetEntityEvents/<entityGuid>

Evento recebido: {eventGuid, entityGuid, entityName, apiName, apiCategory,
                  eventDescription, executionDate}

Integração com o pipeline Subradar:
  - MonitorAppPollConnector.consultar_cnpj() lê os eventos pendentes da entidade
    e converte em alertas Subradar standard.
  - MonitorAppSetup.register_entity() registra um CNPJ/CPF no MonitorApp.
  - MonitorAppSetup.setup_webhook() configura o webhook para receber push events
    (requer URL pública — não funciona em dev local).

Env var: DIRECT_DATA_TOKEN
"""
from __future__ import annotations

import logging
import os
import re
from datetime import datetime, timezone
from typing import Any

import requests

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.directdata_monitorapp")

_BASE  = "https://api.app.directd.com.br"
_TOKEN = os.environ.get("DIRECT_DATA_TOKEN", "")

# Categorias que mapeiam para severidade crítica
_CRITICO_CATEGORIES = frozenset({
    "protestos", "processos", "falencia", "recuperacao_judicial",
    "irregularidade_fiscal", "sancao",
})

_ATENCAO_CATEGORIES = frozenset({
    "negativacao", "restricao", "inadimplencia", "divida", "cobranca",
})


def _headers() -> dict:
    return {"Token": _TOKEN, "Content-Type": "application/json"}


def _strip_doc(doc: str) -> str:
    return re.sub(r"\D", "", str(doc or ""))


def _fmt_cnpj(cnpj: str) -> str:
    c = _strip_doc(cnpj)
    if len(c) == 14:
        return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}"
    if len(c) == 11:
        return f"{c[:3]}.{c[3:6]}.{c[6:9]}-{c[9:11]}"
    return cnpj


def _category_severity(api_category: str) -> str:
    cat = (api_category or "").lower().replace(" ", "_").replace("-", "_")
    if any(k in cat for k in _CRITICO_CATEGORIES):
        return "critico"
    if any(k in cat for k in _ATENCAO_CATEGORIES):
        return "atencao"
    return "info"


# ─────────────────────────────────────────────────────────────
# API calls
# ─────────────────────────────────────────────────────────────

def get_monitoring_list() -> list[dict]:
    """Lista todas as entidades monitoradas na conta."""
    resp = requests.get(
        f"{_BASE}/api/MonitorApp/GetMonitoringList",
        headers=_headers(),
        timeout=20,
    )
    resp.raise_for_status()
    return resp.json() or []


def get_entity_events(entity_guid: str, page: int = 1, page_size: int = 50) -> dict:
    """Eventos de uma entidade específica."""
    resp = requests.get(
        f"{_BASE}/api/MonitorApp/GetEntityEvents/{entity_guid}",
        headers=_headers(),
        params={"page": page, "pageSize": page_size},
        timeout=20,
    )
    resp.raise_for_status()
    return resp.json() or {}


def get_monitoring_events(page: int = 1, page_size: int = 100) -> dict:
    """Todos os eventos recentes da conta (independente de entidade)."""
    resp = requests.get(
        f"{_BASE}/api/MonitorApp/GetMonitoringEvents",
        headers=_headers(),
        params={"page": page, "pageSize": page_size},
        timeout=20,
    )
    resp.raise_for_status()
    return resp.json() or {}


def get_entity_detail(entity_guid: str) -> dict:
    """Detalhe de monitoramento de uma entidade (frequência, status, histórico)."""
    resp = requests.get(
        f"{_BASE}/api/MonitorApp/GetMonitoringDetail/{entity_guid}",
        headers=_headers(),
        timeout=20,
    )
    resp.raise_for_status()
    return resp.json() or {}


def find_entity_by_document(document: str) -> dict | None:
    """Localiza a entidade monitorada pelo documento (CNPJ ou CPF)."""
    doc_digits = _strip_doc(document)
    entities = get_monitoring_list()
    for entity in entities:
        if _strip_doc(str(entity.get("document") or "")) == doc_digits:
            return entity
    return None


# ─────────────────────────────────────────────────────────────
# Setup helpers (webhook + registro de entidade)
# ─────────────────────────────────────────────────────────────

class MonitorAppSetup:
    """
    Operações de configuração do MonitorApp.
    Executadas manualmente ou em script de inicialização.
    """

    @staticmethod
    def register_entity(
        document: str,
        entity_name: str,
        frequency: str = "DAILY",
        apis: list[str] | None = None,
    ) -> dict:
        """
        Registra um CNPJ/CPF no MonitorApp.

        frequency: 'DAILY' | 'WEEKLY' | 'MONTHLY'
        apis: lista de nomes de APIs a monitorar (None = todas disponíveis)
        """
        body: dict[str, Any] = {
            "document":   _strip_doc(document),
            "entityName": entity_name,
            "frequency":  frequency,
        }
        if apis:
            body["apis"] = apis

        resp = requests.post(
            f"{_BASE}/api/MonitorApp/RegisterEntity",
            headers=_headers(),
            json=body,
            timeout=30,
        )
        resp.raise_for_status()
        result = resp.json()
        logger.info("MonitorApp: entidade registrada %s → guid=%s", document, result.get("entityGuid"))
        return result

    @staticmethod
    def setup_webhook(callback_url: str) -> dict:
        """
        Registra URL de webhook para receber push events.
        Retorna o código de confirmação necessário em confirm_webhook().

        O Direct Data faz uma chamada GET para callback_url?code=CALL-XXXX.
        A URL precisa ser pública e responder 200.
        """
        resp = requests.post(
            f"{_BASE}/api/Webhook/CreateUrlCallBack",
            headers=_headers(),
            json={"url": callback_url},
            timeout=20,
        )
        resp.raise_for_status()
        result = resp.json()
        logger.info("MonitorApp webhook criado: %s → código %s", callback_url, result.get("code"))
        return result

    @staticmethod
    def confirm_webhook(code: str) -> bool:
        """
        Confirma a URL de webhook com o código recebido na chamada de verificação.
        code: 'CALL-XXXX' recebido no GET enviado pelo Direct Data para a callback_url.
        """
        resp = requests.post(
            f"{_BASE}/api/Webhook/ConfirmUrlCallBack",
            headers=_headers(),
            json={"code": code},
            timeout=20,
        )
        resp.raise_for_status()
        result = resp.json()
        confirmed = result.get("confirmed", False)
        logger.info("MonitorApp webhook confirmado: %s", confirmed)
        return confirmed

    @staticmethod
    def list_webhooks() -> list[dict]:
        """Lista webhooks cadastrados na conta."""
        resp = requests.get(
            f"{_BASE}/api/Webhook/GetUrlCallBacks",
            headers=_headers(),
            timeout=15,
        )
        resp.raise_for_status()
        return resp.json() or []

    @staticmethod
    def delete_entity(entity_guid: str) -> bool:
        """Remove entidade do monitoramento."""
        resp = requests.delete(
            f"{_BASE}/api/MonitorApp/RemoveEntity/{entity_guid}",
            headers=_headers(),
            timeout=15,
        )
        return resp.ok


# ─────────────────────────────────────────────────────────────
# SubradarSource connector (poll de eventos)
# ─────────────────────────────────────────────────────────────

class DirectDataMonitorAppConnector(SubradarSource):
    """
    Connector Subradar que faz poll dos eventos MonitorApp por CNPJ/CPF.

    Precisa que a entidade já esteja registrada no MonitorApp.
    Usar MonitorAppSetup.register_entity() para cadastrar.
    """
    fonte = "directdata_monitorapp"
    request_delay = 1.0

    def consultar_cnpj(self, cnpj: str, razao_social: str | None = None) -> list[dict]:
        if not _TOKEN:
            logger.warning("DIRECT_DATA_TOKEN não configurado — MonitorApp ignorado.")
            return []

        doc_fmt = _fmt_cnpj(cnpj)
        ciclo   = _ciclo_atual()

        # Localiza entidade pelo documento
        try:
            entity = find_entity_by_document(cnpj)
        except Exception as e:
            logger.warning("MonitorApp: erro ao listar entidades: %s", e)
            return []

        if not entity:
            logger.debug("MonitorApp: %s não cadastrado — use MonitorAppSetup.register_entity()", doc_fmt)
            return []

        entity_guid = entity.get("entityGuid") or entity.get("monitoringGuid") or ""
        if not entity_guid:
            return []

        # Busca eventos da entidade
        try:
            events_resp = get_entity_events(entity_guid)
        except Exception as e:
            logger.warning("MonitorApp: erro ao buscar eventos de %s: %s", doc_fmt, e)
            return []

        events = events_resp.get("events") or events_resp.get("items") or []
        if not events:
            return []

        mudou, hash_novo = snapshot_changed(doc_fmt, self.fonte, ciclo, events)
        if not mudou:
            return []

        upsert("sub_snapshots", [{
            "cnpj":       doc_fmt,
            "fonte":      self.fonte,
            "ciclo":      ciclo,
            "hash_dados": hash_novo,
            "dados":      {"entity_guid": entity_guid, "total_eventos": len(events), "eventos": events},
        }])

        alertas = []
        for ev in events:
            api_name     = ev.get("apiName", "")
            api_category = ev.get("apiCategory", "")
            descricao    = ev.get("eventDescription", "")
            exec_date    = ev.get("executionDate", "")
            event_guid   = ev.get("eventGuid", "")

            severidade = _category_severity(api_category)
            if severidade == "info":
                # Eventos informativos não viram alerta — só ficam no snapshot
                continue

            alertas.append({
                "cnpj":         doc_fmt,
                "ciclo":        ciclo,
                "fonte":        self.fonte,
                "categoria":    "monitoramento",
                "severidade":   severidade,
                "titulo":       f"MonitorApp — {api_name or api_category}",
                "descricao": (
                    f"Evento detectado pelo Direct Data MonitorApp. "
                    f"Categoria: {api_category}. "
                    + (f"Descrição: {descricao}." if descricao else "")
                    + (f" Data: {exec_date[:10] if exec_date else 'N/I'}.")
                ),
                "referencia_id": event_guid or None,
                "url_fonte":     "https://app.directd.com.br",
                "is_novo":       True,
            })

        logger.info(
            "MonitorApp: %s → %d evento(s), %d alerta(s)",
            doc_fmt, len(events), len(alertas),
        )
        return alertas

    # alias para compatibilidade com runner_pf.py
    def consultar_cpf(self, cpf: str, **kwargs) -> list[dict]:
        return self.consultar_cnpj(cpf)
