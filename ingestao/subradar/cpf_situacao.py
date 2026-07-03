"""
Conector: Situação Cadastral do CPF (Receita Federal)

Verifica se o CPF está regular, suspenso, cancelado, pendente de regularização
ou nulo (não existe). CPF irregular invalida qualquer outra consulta.

Fonte primária: BigDataCorp /peoplev2 com dataset basic_data (se token disponível)
Fonte secundária: ReceitaWS API pública (sem autenticação, rate-limited)

Retorna alerta crítico se CPF não estiver REGULAR.
"""
from __future__ import annotations

import logging
import os
import re

import requests

from .base import SubradarSource

logger = logging.getLogger("subradar.cpf_situacao")

BDC_TOKEN = os.environ.get("BIGDATA_CORP_TOKEN", "")
_BDC_PF_URL = "https://bigboost.bigdatacorp.com.br/peoplev2"
_RECEITAWS_URL = "https://www.receitaws.com.br/v1/cpf"

_STATUS_LABELS = {
    "REGULAR": "Regular",
    "SUSPENSA": "Suspensa",
    "TITULAR FALECIDO": "Titular falecido",
    "PENDENTE DE REGULARIZACAO": "Pendente de regularização",
    "CANCELADA POR ENCERRAMENTO DE ESPOLIO": "Cancelada — encerramento de espólio",
    "CANCELADA DE OFICIO": "Cancelada de ofício",
    "NULA": "Nula",
}


def _strip(doc: str) -> str:
    return re.sub(r"\D", "", str(doc or ""))


def _via_bigdatacorp(cpf: str) -> str | None:
    """Retorna situação cadastral via BigDataCorp. None se indisponível."""
    if not BDC_TOKEN:
        return None
    try:
        resp = requests.post(
            _BDC_PF_URL,
            json={"Datasets": "basic_data", "q": f"doc{{{cpf}}}", "Limit": 1},
            headers={"accept": "application/json", "content-type": "application/json", "AccessToken": BDC_TOKEN},
            timeout=15,
        )
        if not resp.ok:
            return None
        result = (resp.json().get("Result") or [{}])[0]
        bd = result.get("BasicData") or {}
        return bd.get("RegistrationStatus") or bd.get("TaxIdStatus") or None
    except Exception as e:
        logger.debug("BigDataCorp CPF situacao: %s", e)
        return None


def _via_receitaws(cpf: str) -> str | None:
    """Retorna situação via ReceitaWS (fallback, rate-limited)."""
    try:
        resp = requests.get(
            f"{_RECEITAWS_URL}/{cpf}",
            headers={"User-Agent": "subradar/1.0"},
            timeout=10,
        )
        if resp.ok:
            return resp.json().get("situacao") or None
    except Exception as e:
        logger.debug("ReceitaWS CPF situacao: %s", e)
    return None


class CPFSituacaoConnector(SubradarSource):
    """Verifica a situação cadastral do CPF na Receita Federal."""
    fonte = "cpf_situacao_rfb"
    request_delay = 0.5

    def consultar_cnpj(self, cnpj_or_cpf: str, **_) -> list[dict]:
        cpf = _strip(cnpj_or_cpf)
        if len(cpf) != 11:
            return []

        situacao = _via_bigdatacorp(cpf) or _via_receitaws(cpf)

        if situacao is None:
            logger.debug("cpf_situacao: situação não disponível para CPF %s***", cpf[:3])
            return []

        situacao_norm = situacao.upper().strip()
        label = _STATUS_LABELS.get(situacao_norm, situacao)

        if situacao_norm == "REGULAR":
            logger.debug("cpf_situacao: CPF %s*** REGULAR", cpf[:3])
            return []

        cpf_fmt = f"{cpf[:3]}.{cpf[3:6]}.{cpf[6:9]}-{cpf[9:11]}"
        severidade = "critico"

        return [{
            "fonte": self.fonte,
            "categoria": "cadastral",
            "severidade": severidade,
            "titulo": f"CPF {cpf_fmt} — Situação: {label}",
            "descricao": (
                f"A Receita Federal indica situação '{label}' para este CPF. "
                "CPF irregular pode indicar uso indevido de documento de terceiro."
            ),
            "url_fonte": "https://servicos.receita.fazenda.gov.br/Servicos/CPF/ConsultaSituacao/ConsultaPublica.asp",
            "is_novo": True,
        }]
