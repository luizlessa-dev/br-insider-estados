"""
Conector: Direct Data — Dossiê Empresarial via API v3

API: api.app.directd.com.br
Auth: header `Token: <uuid>` (não Bearer)
Fluxo: POST /Dossier/Process → poll /Dossier/Status → GET /Dossier/Full-Details

Variáveis de ambiente:
  DIRECT_DATA_TOKEN     — UUID do token da plataforma
  DIRECT_DATA_TEMPLATE  — templateID do template "Compliance Empresarial (PLD-FT)"
                          Obter em: app.directd.com.br/dossie/setup → DevTools → Network

Template recomendado: "Compliance Empresarial (PLD-FT)" (~R$ 15,70 por consulta, +20 APIs)
  Cobre: sanções nacionais/internacionais, CEIS/CNEP, RFB, acordos de leniência,
         beneficiário final, dados cadastrais PJ Plus, processos judiciais.

Produto Subradar: plano "Essencial" e "Profissional" (Direct Data como fonte agregadora)
"""
from __future__ import annotations

import logging
import os
import time
import re

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.directdata")

DD_BASE     = "https://api.app.directd.com.br"
DD_TOKEN    = os.environ.get("DIRECT_DATA_TOKEN", "")
DD_TEMPLATE = os.environ.get("DIRECT_DATA_TEMPLATE", "")

# Segundos entre polls de status
_POLL_INTERVAL = 3
# Máximo de tentativas de poll (~90 segundos)
_POLL_MAX = 30


def _strip_cnpj(cnpj: str) -> str:
    return re.sub(r"\D", "", str(cnpj or ""))


def _fmt_cnpj(cnpj: str) -> str:
    c = _strip_cnpj(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _headers() -> dict:
    return {
        "Token": DD_TOKEN,
        "Content-Type": "application/json",
        "Accept": "application/json",
    }


# ---------------------------------------------------------------------------
# Mapeamento de seções do dossiê → severidade e categoria
# ---------------------------------------------------------------------------

_SECAO_CRITICO = {
    "sancoes", "pld", "compliance", "leniencia", "ceis", "cnep", "cepim",
    "ofac", "onu", "ue", "interpol", "fbi",
}
_SECAO_ATENCAO = {
    "processos", "judicial", "trabalhista", "execucao", "debito", "protesto",
    "divida", "pgfn", "cadin",
}
_CATEGORIA_MAP = {
    "sancoes": "sanções",
    "pld": "sanções",
    "compliance": "sanções",
    "leniencia": "sanções",
    "ceis": "sanções",
    "cnep": "sanções",
    "cepim": "sanções",
    "ofac": "internacional",
    "onu": "internacional",
    "ue": "internacional",
    "interpol": "internacional",
    "processos": "judicial",
    "judicial": "judicial",
    "trabalhista": "judicial",
    "debito": "fiscal",
    "divida": "fiscal",
    "pgfn": "fiscal",
    "cadin": "fiscal",
    "protesto": "crédito",
    "cadastral": "cadastral",
    "societario": "cadastral",
}


def _classificar(chave: str) -> tuple[str, str]:
    """Retorna (severidade, categoria) a partir da chave da seção."""
    k = chave.lower()
    for palavra in _SECAO_CRITICO:
        if palavra in k:
            return "critico", _CATEGORIA_MAP.get(palavra, "sanções")
    for palavra in _SECAO_ATENCAO:
        if palavra in k:
            return "atencao", _CATEGORIA_MAP.get(palavra, "judicial")
    return "info", "geral"


# ---------------------------------------------------------------------------
# Funções de API
# ---------------------------------------------------------------------------

def _processar_dossie(cnpj_digits: str, session) -> str | None:
    """
    Inicia o processamento do dossiê. Retorna o dossieID (ex: DS-xxxxxxxx).
    """
    r = session.post(
        f"{DD_BASE}/api/Dossier/Process",
        json={"templateID": DD_TEMPLATE, "documents": [cnpj_digits]},
        headers=_headers(),
        timeout=30,
    )
    r.raise_for_status()
    data = r.json()

    if not data.get("success"):
        erro = (data.get("error") or {}).get("message", data.get("status", ""))
        logger.warning("Direct Data Process falhou: %s", erro)
        return None

    processos = data.get("dossierProcesses", [])
    if not processos:
        logger.warning("Direct Data: dossierProcesses vazio")
        return None

    # A API retorna dossieID (ex: DS-a712b92c), não dossierProcessId
    return processos[0].get("dossieID") or processos[0].get("id")


def _aguardar_conclusao(dossie_id: str, session) -> bool:
    """
    Poll via History até situationType = Concluído ou timeout.
    O endpoint /Status retorna 405 — a alternativa é History com filtro por guid.
    """
    for tentativa in range(_POLL_MAX):
        time.sleep(_POLL_INTERVAL)
        try:
            r = session.post(
                f"{DD_BASE}/api/Dossier/History",
                json={"id": dossie_id, "take": 1},
                headers=_headers(),
                timeout=15,
            )
            r.raise_for_status()
            data = r.json()
        except Exception as e:
            logger.warning("Direct Data History erro (tentativa %d): %s", tentativa + 1, e)
            continue

        histories = data.get("histories", [])
        if not histories:
            logger.debug("Direct Data: aguardando (tentativa %d, sem histórico ainda)", tentativa + 1)
            continue

        situacao = (histories[0].get("situationType") or {}).get("result", "").lower()
        resultado = (histories[0].get("resultType") or {}).get("result", "").lower()

        if "conclu" in situacao or "finaliz" in resultado:
            return True
        if any(s in situacao for s in ("erro", "falh", "saldo insuf", "indispon")):
            logger.warning("Direct Data: dossiê não processado — situação='%s'", situacao)
            return False

        logger.debug("Direct Data: aguardando (tentativa %d, situação=%s)", tentativa + 1, situacao)

    logger.warning("Direct Data: timeout aguardando dossiê %s", dossie_id)
    return False


def _buscar_detalhes(dossie_id: str, session) -> dict:
    """
    Busca resultado completo via GET /Dossier/Full-Details?dossieID=...
    """
    headers = {k: v for k, v in _headers().items() if k != "Content-Type"}
    r = session.get(
        f"{DD_BASE}/api/Dossier/Full-Details",
        params={"dossieID": dossie_id},
        headers=headers,
        timeout=30,
    )
    r.raise_for_status()
    return r.json()


# ---------------------------------------------------------------------------
# Extração de alertas do resultado
# ---------------------------------------------------------------------------

def _extrair_alertas(detalhes: dict, cnpj_fmt: str, ciclo: str) -> list[dict]:
    """
    Estrutura real da API Full-Details:
    {
      "summary": { "status": "Alerta", ... },
      "details": [
        {
          "nameAPI": "PGFN - Lista de Devedores",
          "moduleName": "Sanções e Restrições",
          "statusPriority": "Alerta",   ← "Regular" = sem ocorrência
          "alertList": [{"fieldName": "Flag Dívida", "value": "true"}],
          "object": { ... dados brutos ... }
        }, ...
      ]
    }
    """
    alertas = []
    details = detalhes.get("details", [])

    for item in details:
        prioridade = (item.get("statusPriority") or "").lower()
        if prioridade in ("regular", ""):
            continue  # sem ocorrência

        nome_api    = item.get("nameAPI", "")
        modulo      = item.get("moduleName", "")
        alert_list  = item.get("alertList", [])
        sev, cat    = _classificar(f"{nome_api} {modulo}")

        # Monta descrição a partir dos campos de alertList
        campos = "; ".join(
            f"{al.get('fieldName','')}: {al.get('value','')}"
            for al in alert_list
            if al.get("value") not in (None, "", "false", "False")
        )
        if not campos:
            campos = f"Ocorrência identificada em {nome_api}"

        alertas.append({
            "cnpj":          cnpj_fmt,
            "ciclo":         ciclo,
            "fonte":         "directdata",
            "categoria":     cat,
            "severidade":    sev,
            "titulo":        f"Direct Data — {nome_api}",
            "descricao":     campos[:2000],
            "referencia_id": item.get("apiid"),
            "is_novo":       True,
        })

    return alertas


# ---------------------------------------------------------------------------
# Conector principal
# ---------------------------------------------------------------------------

class DirectDataConnector(SubradarSource):
    fonte         = "directdata"
    request_delay = 1.0

    def consultar_cnpj(self, cnpj: str) -> list[dict]:
        if not DD_TOKEN:
            logger.info("DirectData: DIRECT_DATA_TOKEN não configurado — fonte indisponível")
            return []
        if not DD_TEMPLATE:
            logger.info("DirectData: DIRECT_DATA_TEMPLATE não configurado — aguardando templateID")
            return []

        cnpj_digits = _strip_cnpj(cnpj)
        cnpj_fmt    = _fmt_cnpj(cnpj_digits)
        ciclo       = _ciclo_atual()

        # 1. Inicia o dossiê
        try:
            process_id = _processar_dossie(cnpj_digits, self._session)
        except Exception as e:
            logger.warning("DirectData: erro ao iniciar dossiê para %s: %s", cnpj_fmt, e)
            return []

        if not process_id:
            return []

        # 2. Aguarda conclusão
        ok = _aguardar_conclusao(process_id, self._session)
        if not ok:
            return []

        # 3. Busca resultado
        try:
            detalhes = _buscar_detalhes(process_id, self._session)
        except Exception as e:
            logger.warning("DirectData: erro ao buscar detalhes %s: %s", process_id, e)
            return []

        # 4. Verifica se houve mudança (evita alertas duplicados por ciclo)
        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, detalhes)
        if not mudou:
            logger.info("DirectData: sem mudanças para %s", cnpj_fmt)
            return []

        upsert("sub_snapshots", [{
            "cnpj":      cnpj_fmt,
            "fonte":     self.fonte,
            "ciclo":     ciclo,
            "hash_dados": hash_novo,
            "dados":     {"process_id": process_id},
        }])

        # 5. Extrai alertas
        alertas = _extrair_alertas(detalhes, cnpj_fmt, ciclo)
        logger.info("DirectData: %d alertas para %s (process_id=%s)", len(alertas), cnpj_fmt, process_id)
        return alertas
