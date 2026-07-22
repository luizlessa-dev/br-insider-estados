"""
Conector: BNMP — Banco Nacional de Mandados de Prisão (CNJ)

Verifica se o CPF possui mandado de prisão ativo em qualquer tribunal do país.
A API pública do CNJ exige credencial via PDPJ-Br (apenas órgãos públicos credenciados).
Este conector usa a Direct Data API v3 como proxy, que já possui convênio com o CNJ.

Custo: consumido pelo mesmo DIRECT_DATA_TOKEN do pipeline B2B.
Endpoint: GET https://apiv3.directd.com.br/api/CNJMandadosPrisao

Env var: DIRECT_DATA_TOKEN
Severity: critico — mandado de prisão ativo é impedimento grave para qualquer contratação.
"""
from __future__ import annotations

import logging
import os
import re

import requests

from .base import SubradarSource

logger = logging.getLogger("subradar.bnmp_pf")

_DD_TOKEN = os.environ.get("DIRECT_DATA_TOKEN", "")
_DD_V3_BASE = "https://apiv3.directd.com.br/api"

_STATUS_ATIVO = {"ativo", "pendente", "aberto", "vigente", "expedido"}


def _strip(cpf: str) -> str:
    return re.sub(r"\D", "", str(cpf or ""))


def _consultar_bnmp(cpf: str) -> list[dict]:
    """Consulta Direct Data v3 — BNMP mandados de prisão por CPF."""
    try:
        resp = requests.get(
            f"{_DD_V3_BASE}/CNJMandadosPrisao",
            params={"Cpf": cpf, "Token": _DD_TOKEN},
            timeout=20,
        )
        if not resp.ok:
            logger.debug("BNMP: HTTP %d para CPF %s***", resp.status_code, cpf[:3])
            return []
        data = resp.json()
        if isinstance(data, list):
            return data
        if isinstance(data, dict):
            return data.get("data", data.get("mandados", data.get("result", [])))
        return []
    except Exception as e:
        logger.debug("BNMP: %s", e)
        return []


class BNMPMandadosPrisaoPFConnector(SubradarSource):
    """
    Verifica mandados de prisão ativos no BNMP/CNJ via Direct Data v3.
    Só gera alerta se existir mandado com status ativo/vigente.
    Gracioso se DIRECT_DATA_TOKEN ausente.
    """
    fonte = "bnmp_cnj"
    request_delay = 1.0

    def consultar_cnpj(self, cnpj_or_cpf: str, razao_social: str | None = None, **_) -> list[dict]:
        if not _DD_TOKEN:
            logger.debug("bnmp_pf: DIRECT_DATA_TOKEN ausente — pulando")
            return []

        cpf = _strip(cnpj_or_cpf)
        if len(cpf) != 11:
            return []

        cpf_fmt = f"{cpf[:3]}.{cpf[3:6]}.{cpf[6:9]}-{cpf[9:11]}"
        mandados = _consultar_bnmp(cpf)

        if not mandados:
            logger.debug("bnmp_pf: sem mandados para CPF %s***", cpf[:3])
            return []

        alertas = []
        for m in mandados:
            status = (
                m.get("status") or
                m.get("situacao") or
                m.get("statusMandado") or ""
            ).lower().strip()

            # Ignora mandados revogados, cumpridos ou cancelados
            if status and not any(s in status for s in _STATUS_ATIVO):
                logger.debug("bnmp_pf: mandado ignorado (status=%s)", status)
                continue

            numero = m.get("numeroCnj") or m.get("numero") or m.get("id") or "s/n"
            tipo = m.get("tipoMandado") or m.get("tipo") or "Prisão"
            crime = m.get("crime") or m.get("delito") or m.get("infracaoPenal") or ""
            tribunal = m.get("tribunal") or m.get("orgaoExpedidor") or m.get("juizo") or ""

            descricao_partes = [f"Mandado n° {numero} — tipo: {tipo}"]
            if crime:
                descricao_partes.append(f"Infração: {crime}")
            if tribunal:
                descricao_partes.append(f"Órgão expedidor: {tribunal}")

            alertas.append({
                "fonte": self.fonte,
                "categoria": "judicial",
                "severidade": "critico",
                "titulo": f"BNMP/CNJ — mandado de prisão ATIVO: {cpf_fmt}",
                "descricao": ". ".join(descricao_partes),
                "url_fonte": "https://bnmp.pdpj.jus.br/",
                "referencia_id": str(numero),
                "is_novo": True,
            })

        if alertas:
            logger.info("bnmp_pf: %d mandado(s) ativo(s) para CPF %s***", len(alertas), cpf[:3])
        return alertas
