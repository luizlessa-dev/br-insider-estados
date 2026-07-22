"""
Conector: CNDT/TST — Certidão Negativa de Débitos Trabalhistas (PJ como empregadora)

Verifica se o CNPJ possui débitos trabalhistas junto ao TST — relevante para:
  - Empresas com histórico de inadimplência trabalhista
  - Fornecedores em processos de credenciamento público
  - Contratadas em licitações federais/estaduais

O portal público do TST (cndt.tst.jus.br) exige CAPTCHA na interface web.
Este conector usa a Direct Data API v3 como proxy.

Custo: consumido pelo DIRECT_DATA_TOKEN existente.
Env var: DIRECT_DATA_TOKEN
Severity: atencao — débito trabalhista como empregadora indica irregularidade
          mas não necessariamente ação criminal em curso.
"""
from __future__ import annotations

import logging
import os
import re

import requests

from .base import SubradarSource

logger = logging.getLogger("subradar.cndt_tst_pj")

_DD_TOKEN = os.environ.get("DIRECT_DATA_TOKEN", "")
_DD_V3_BASE = "https://apiv3.directd.com.br/api"

_NEGATIVA_LABELS = {
    "negativa", "sem débitos", "sem pendências",
    "regular", "nada consta", "certidão negativa",
}
_POSITIVA_LABELS = {
    "positiva", "com débitos", "com pendências",
    "irregular", "devedor", "certidão positiva",
}


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", str(cnpj or ""))


def _via_direct_data(cnpj: str) -> dict | None:
    """
    Consulta CNDT via Direct Data v3.
    Endpoint: TSTCertidaoNegativaDebitosTrabalhistas
    Response: { "retorno": { "possuiProcesso": bool, "numeroCertidao": str,
                             "totalProcessos": int, "processos": [{"codigo":"...", "local":"..."}] } }
    """
    if not _DD_TOKEN:
        return None
    try:
        resp = requests.get(
            f"{_DD_V3_BASE}/TSTCertidaoNegativaDebitosTrabalhistas",
            params={"Cnpj": cnpj, "Token": _DD_TOKEN},
            timeout=25,
        )
        if resp.ok and "json" in resp.headers.get("Content-Type", ""):
            data = resp.json()
            if isinstance(data, dict):
                return data
    except Exception as e:
        logger.debug("CNDT PJ Direct Data: %s", e)
    return None


def _extrair_situacao(data: dict | list) -> str:
    """Normaliza resposta Direct Data v3 para string de situação."""
    if isinstance(data, list) and data:
        data = data[0]
    if not isinstance(data, dict):
        return ""
    retorno = data.get("retorno") or data
    if isinstance(retorno, dict):
        for campo in ("situacao", "status", "tipoCertidao", "resultado",
                      "certidao", "descricao", "statusCertidao"):
            val = retorno.get(campo)
            if val and isinstance(val, str):
                return val.lower().strip()
    return ""


class CNDTTrabalhiPJConnector(SubradarSource):
    """
    Verifica CNDT/TST por CNPJ (PJ como empregadora).
    Gera alerta 'atencao' quando a certidão for positiva (há débito trabalhista).
    Gracioso se DIRECT_DATA_TOKEN ausente ou resposta inconclusiva.
    """
    fonte = "cndt_tst_pj"
    request_delay = 1.0

    def consultar_cnpj(self, cnpj_or_cpf: str, razao_social: str | None = None, **_) -> list[dict]:
        cnpj = _strip(cnpj_or_cpf)
        if len(cnpj) != 14:
            return []

        cnpj_fmt = f"{cnpj[:2]}.{cnpj[2:5]}.{cnpj[5:8]}/{cnpj[8:12]}-{cnpj[12:14]}"
        nome = razao_social or cnpj_fmt

        data = _via_direct_data(cnpj)

        if data is None:
            logger.debug("cndt_tst_pj: sem resposta para CNPJ %s***", cnpj[:6])
            return []

        retorno = data.get("retorno") or data if isinstance(data, dict) else {}
        possui_processo = retorno.get("possuiProcesso")

        # Sem ocorrência: possuiProcesso=False ou ausente
        if possui_processo is False:
            logger.debug("cndt_tst_pj: CNDT negativa para CNPJ %s***", cnpj[:6])
            return []

        # Fallback: tenta campo de situação textual
        situacao = _extrair_situacao(data)
        if situacao and any(neg in situacao for neg in _NEGATIVA_LABELS):
            logger.debug("cndt_tst_pj: CNDT negativa (textual) para CNPJ %s***", cnpj[:6])
            return []

        # Positiva: possuiProcesso=True ou situação textual indicando débito
        eh_positiva = (
            possui_processo is True or
            any(pos in situacao for pos in _POSITIVA_LABELS)
        )
        if not eh_positiva:
            logger.debug("cndt_tst_pj: sem dado conclusivo para CNPJ %s***", cnpj[:6])
            return []

        num_certidao = (
            retorno.get("numeroCertidao") or
            data.get("numeroCertidao") or
            retorno.get("numCertidao") or "s/n"
        )
        processos = retorno.get("processos") or []
        total = retorno.get("totalProcessos") or len(processos)

        logger.info("cndt_tst_pj: CNDT positiva para CNPJ %s*** — %d processo(s)", cnpj[:6], total)

        desc = (
            f"Certidão n° {num_certidao}. "
            f"{total} processo(s) trabalhista(s) vinculado(s) ao CNPJ {cnpj_fmt} "
            "como empregadora junto ao TST."
        )
        if processos:
            locais = ", ".join(p.get("local", "") for p in processos[:3] if p.get("local"))
            if locais:
                desc += f" Vara(s): {locais}."

        return [{
            "fonte": self.fonte,
            "categoria": "trabalhista",
            "severidade": "atencao",
            "titulo": f"CNDT/TST — certidão POSITIVA ({total} processo(s)): {nome}",
            "descricao": desc,
            "url_fonte": "https://cndt-certidao.tst.jus.br/",
            "referencia_id": str(num_certidao),
            "is_novo": True,
        }]
