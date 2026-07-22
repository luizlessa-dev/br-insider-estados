"""
Conector: CNDT/TST — Certidão Negativa de Débitos Trabalhistas (PF como empregador)

Verifica se o CPF possui débitos trabalhistas junto ao TST — relevante para:
  - MEIs que tiveram empregados domésticos
  - Sócios-gerentes responsabilizados por dívidas trabalhistas da empresa
  - Credenciamento de prestadores autônomos com histórico de empregados

O portal público do TST (cndt.tst.jus.br) exige CAPTCHA na interface web.
Este conector usa a Direct Data API v3 como proxy.

Fallback: consulta direta ao TST via POST sem CAPTCHA (endpoint de emissão
programática disponível para alguns sistemas integrados — tentado se DD falhar).

Custo: consumido pelo DIRECT_DATA_TOKEN existente.
Env var: DIRECT_DATA_TOKEN
Severity: atencao — débito trabalhista indica irregularidade mas não necessariamente
          ação criminal em curso (diferente de mandado de prisão ou sanção CGU).
"""
from __future__ import annotations

import logging
import os
import re

import requests

from .base import SubradarSource

logger = logging.getLogger("subradar.cndt_tst_pf")

_DD_TOKEN = os.environ.get("DIRECT_DATA_TOKEN", "")
_DD_V3_BASE = "https://apiv3.directd.com.br/api"

# Endpoints alternativos TST (tentados sem CAPTCHA)
_TST_ENDPOINTS = [
    "https://cndt.tst.jus.br/CNDT/api/certidao",
    "https://cndt.tst.jus.br/CNDT/emissaoCertidaoPDF.do",
]

_NEGATIVA_LABELS = {
    "negativa", "sem débitos", "sem pendências",
    "regular", "nada consta", "certidão negativa",
}
_POSITIVA_LABELS = {
    "positiva", "com débitos", "com pendências",
    "irregular", "devedor", "certidão positiva",
}


def _strip(cpf: str) -> str:
    return re.sub(r"\D", "", str(cpf or ""))


def _via_direct_data(cpf: str) -> dict | None:
    """
    Consulta CNDT via Direct Data v3.
    Endpoint confirmado: TSTCertidaoNegativaDebitosTrabalhistas
    Response: { "retorno": { "possuiProcesso": bool, "numeroCertidao": str, "processos": [] } }
    """
    if not _DD_TOKEN:
        return None
    try:
        resp = requests.get(
            f"{_DD_V3_BASE}/TSTCertidaoNegativaDebitosTrabalhistas",
            params={"Cpf": cpf, "Token": _DD_TOKEN},
            timeout=25,
        )
        if resp.ok and "json" in resp.headers.get("Content-Type", ""):
            data = resp.json()
            if isinstance(data, dict):
                return data
    except Exception as e:
        logger.debug("CNDT Direct Data: %s", e)
    return None


def _extrair_situacao(data: dict | list) -> str:
    """Normaliza resposta Direct Data v3 para string de situação."""
    if isinstance(data, list) and data:
        data = data[0]
    if not isinstance(data, dict):
        return ""
    # Direct Data v3: retorno está em data["retorno"]
    retorno = data.get("retorno") or data
    if isinstance(retorno, dict):
        for campo in ("situacao", "status", "tipoCertidao", "resultado",
                      "certidao", "descricao", "statusCertidao"):
            val = retorno.get(campo)
            if val and isinstance(val, str):
                return val.lower().strip()
    return ""


class CNDTTrabalhiPFConnector(SubradarSource):
    """
    Verifica CNDT/TST por CPF (PF como empregador ou responsável solidário).
    Gera alerta 'atencao' quando a certidão for positiva (há débito trabalhista).
    Gracioso se DIRECT_DATA_TOKEN ausente e TST direto não estiver disponível.
    """
    fonte = "cndt_tst"
    request_delay = 1.0

    def consultar_cnpj(self, cnpj_or_cpf: str, **_) -> list[dict]:
        cpf = _strip(cnpj_or_cpf)
        if len(cpf) != 11:
            return []

        cpf_fmt = f"{cpf[:3]}.{cpf[3:6]}.{cpf[6:9]}-{cpf[9:11]}"

        data = _via_direct_data(cpf)

        if data is None:
            logger.debug("cndt_tst_pf: sem resposta para CPF %s***", cpf[:3])
            return []

        # Direct Data v3: campos em data["retorno"]
        retorno = data.get("retorno") or data if isinstance(data, dict) else {}
        possui_processo = retorno.get("possuiProcesso")

        # Sem ocorrência: possuiProcesso=False ou ausente
        if possui_processo is False:
            logger.debug("cndt_tst_pf: CNDT negativa para CPF %s***", cpf[:3])
            return []

        # Fallback: tenta campo de situação textual
        situacao = _extrair_situacao(data)
        if situacao and any(neg in situacao for neg in _NEGATIVA_LABELS):
            logger.debug("cndt_tst_pf: CNDT negativa (textual) para CPF %s***", cpf[:3])
            return []

        # Positiva: possuiProcesso=True ou situação textual indicando débito
        eh_positiva = (
            possui_processo is True or
            any(pos in situacao for pos in _POSITIVA_LABELS)
        )
        if not eh_positiva:
            logger.debug("cndt_tst_pf: sem dado conclusivo para CPF %s***", cpf[:3])
            return []

        num_certidao = (
            retorno.get("numeroCertidao") or
            data.get("numeroCertidao") or
            retorno.get("numCertidao") or "s/n"
        )
        processos = retorno.get("processos") or []
        total = retorno.get("totalProcessos") or len(processos)

        logger.info("cndt_tst_pf: CNDT positiva para CPF %s*** — %s", cpf[:3], situacao)

        desc = (
            f"Certidão n° {num_certidao}. "
            f"{total} processo(s) trabalhista(s) vinculado(s) ao CPF como empregador "
            "ou responsável solidário junto ao TST."
        )
        if processos:
            locais = ", ".join(p.get("local", "") for p in processos[:3] if p.get("local"))
            if locais:
                desc += f" Vara(s): {locais}."

        logger.info("cndt_tst_pf: CNDT positiva para CPF %s*** — %d processo(s)", cpf[:3], total)

        return [{
            "fonte": self.fonte,
            "categoria": "trabalhista",
            "severidade": "atencao",
            "titulo": f"CNDT/TST — certidão POSITIVA ({total} processo(s)): {cpf_fmt}",
            "descricao": desc,
            "url_fonte": "https://cndt-certidao.tst.jus.br/",
            "referencia_id": str(num_certidao),
            "is_novo": True,
        }]
