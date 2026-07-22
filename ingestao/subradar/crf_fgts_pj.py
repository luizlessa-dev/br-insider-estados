"""
Conector: CRF/FGTS — Certificado de Regularidade do FGTS (PJ)

Verifica se o CNPJ possui regularidade perante o FGTS junto à Caixa Econômica Federal.
Relevante para:
  - Empresas licitantes (exigência legal — Lei 8.036/90, art. 27)
  - Fornecedores e contratados com recursos públicos
  - Credenciamento de prestadores de serviço

O portal da Caixa (consulta-crf.caixa.gov.br) exige CAPTCHA na interface web.
Este conector tenta primeiro a Direct Data API v3 como proxy; se ausente ou falhar,
tenta o endpoint de emissão programática da Caixa (gracioso se bloqueado).

Custo: consumido pelo DIRECT_DATA_TOKEN existente.
Env var: DIRECT_DATA_TOKEN (opcional — gracioso se ausente)
Severity: atencao — CRF irregular indica inadimplência com FGTS dos empregados.
"""
from __future__ import annotations

import logging
import os
import re

import requests

from .base import SubradarSource

logger = logging.getLogger("subradar.crf_fgts_pj")

_DD_TOKEN = os.environ.get("DIRECT_DATA_TOKEN", "")
_DD_V3_BASE = "https://apiv3.directd.com.br/api"

# Endpoint público de consulta CRF (emissão programática / sistemas integrados)
_CRF_POST_URL = (
    "https://consulta-crf.caixa.gov.br/consultacrf/pages/consultaEmpregador.jsf"
)

_REGULAR_LABELS = {
    "regular", "regularidade", "com regularidade",
    "certificado de regularidade", "crf regular",
}
_IRREGULAR_LABELS = {
    "irregular", "sem regularidade", "inadimplente",
    "pendente", "negativo", "crf irregular",
}


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", str(cnpj or ""))


def _via_direct_data(cnpj14: str) -> dict | None:
    """
    Consulta CRF via Direct Data v3.
    Endpoint: CEFCertidaoRegularidadeFGTS
    Resposta esperada:
      { "retorno": { "situacao": "Regular"/"Irregular",
                     "numeroCRF": str,
                     "validade": str } }
    Variação alternativa:
      { "retorno": { "regular": bool, ... } }
    """
    if not _DD_TOKEN:
        return None
    try:
        resp = requests.get(
            f"{_DD_V3_BASE}/CEFCertidaoRegularidadeFGTS",
            params={"Cnpj": cnpj14, "Token": _DD_TOKEN},
            timeout=25,
        )
        if resp.ok and "json" in resp.headers.get("Content-Type", ""):
            data = resp.json()
            if isinstance(data, dict):
                return data
    except Exception as e:
        logger.debug("crf_fgts_pj Direct Data: %s", e)
    return None


def _via_portal_caixa(cnpj14: str) -> dict | None:
    """
    Tenta consulta direta ao portal da Caixa via POST (sem CAPTCHA em alguns fluxos).
    Retorna None se bloqueado ou indisponível.
    """
    try:
        payload = {"cnpj": cnpj14}
        headers = {
            "Content-Type": "application/x-www-form-urlencoded",
            "Referer": "https://consulta-crf.caixa.gov.br/",
            "Origin": "https://consulta-crf.caixa.gov.br",
        }
        resp = requests.post(
            _CRF_POST_URL,
            data=payload,
            headers=headers,
            timeout=20,
            allow_redirects=True,
        )
        if not resp.ok:
            logger.debug("crf_fgts_pj portal Caixa: HTTP %s", resp.status_code)
            return None
        body = resp.text.lower()
        # Tenta extrair situação da resposta HTML/JSON
        if "regular" in body and "irregular" not in body:
            return {"situacao_portal": "regular"}
        if "irregular" in body:
            return {"situacao_portal": "irregular"}
    except Exception as e:
        logger.debug("crf_fgts_pj portal Caixa: %s", e)
    return None


def _extrair_situacao(data: dict) -> tuple[bool | None, str, str]:
    """
    Normaliza resposta para (is_regular: bool|None, numero_crf: str, validade: str).
    Retorna None se inconclusivo.
    """
    retorno = data.get("retorno") or data
    if not isinstance(retorno, dict):
        return None, "", ""

    numero_crf = (
        retorno.get("numeroCRF")
        or retorno.get("numeroCrf")
        or retorno.get("numero")
        or retorno.get("numCrf")
        or "s/n"
    )
    validade = retorno.get("validade") or retorno.get("dataValidade") or ""

    # Campo booleano explícito
    regular_bool = retorno.get("regular")
    if isinstance(regular_bool, bool):
        return regular_bool, str(numero_crf), str(validade)

    # Campo textual de situação
    situacao_portal = data.get("situacao_portal", "")
    for campo in ("situacao", "status", "resultado", "descricao", "tipoCertidao"):
        val = retorno.get(campo) or ""
        if val and isinstance(val, str):
            situacao_portal = val.lower().strip()
            break

    if situacao_portal:
        if any(lbl in situacao_portal for lbl in _REGULAR_LABELS):
            return True, str(numero_crf), str(validade)
        if any(lbl in situacao_portal for lbl in _IRREGULAR_LABELS):
            return False, str(numero_crf), str(validade)

    return None, str(numero_crf), str(validade)


class CRFFGTSPJConnector(SubradarSource):
    """
    Verifica CRF/FGTS por CNPJ (PJ).
    Gera alerta 'atencao' quando a certidão for irregular (inadimplência com FGTS).
    Gracioso se DIRECT_DATA_TOKEN ausente e portal da Caixa não estiver acessível.
    """
    fonte = "crf_fgts"
    request_delay = 1.0

    def consultar_cnpj(self, cnpj_or_cpf: str, razao_social: str | None = None, **_) -> list[dict]:
        cnpj = _strip(cnpj_or_cpf)
        if len(cnpj) != 14:
            return []

        cnpj_fmt = (
            f"{cnpj[:2]}.{cnpj[2:5]}.{cnpj[5:8]}/{cnpj[8:12]}-{cnpj[12:14]}"
        )
        nome = razao_social or cnpj_fmt

        # Tentativa 1: Direct Data v3
        data = _via_direct_data(cnpj)

        # Tentativa 2: portal direto da Caixa (se DD falhou ou ausente)
        if data is None:
            logger.debug("crf_fgts_pj: DD indisponível para %s — tentando portal Caixa", cnpj_fmt)
            data = _via_portal_caixa(cnpj)

        if data is None:
            logger.debug("crf_fgts_pj: sem resposta para %s", cnpj_fmt)
            return []

        is_regular, numero_crf, validade = _extrair_situacao(data)

        # Regular → sem alerta
        if is_regular is True:
            logger.debug("crf_fgts_pj: CRF regular para %s (CRF %s)", cnpj_fmt, numero_crf)
            return []

        # Inconclusivo → gracioso
        if is_regular is None:
            logger.debug("crf_fgts_pj: sem dado conclusivo para %s", cnpj_fmt)
            return []

        # Irregular → alerta
        logger.info("crf_fgts_pj: CRF IRREGULAR para %s (CRF %s)", cnpj_fmt, numero_crf)

        desc_parts = [
            f"Certificado de Regularidade do FGTS IRREGULAR para {nome} (CNPJ {cnpj_fmt})."
        ]
        if numero_crf and numero_crf != "s/n":
            desc_parts.append(f"Número do CRF: {numero_crf}.")
        if validade:
            desc_parts.append(f"Validade/referência: {validade}.")
        desc_parts.append(
            "A irregularidade indica inadimplência com o recolhimento do FGTS dos empregados "
            "e impede a participação em licitações e contratos com a administração pública "
            "(Lei 8.036/90, art. 27, IV)."
        )

        return [{
            "fonte": self.fonte,
            "categoria": "trabalhista",
            "severidade": "atencao",
            "titulo": f"CRF/FGTS — certidão IRREGULAR: {cnpj_fmt}",
            "descricao": " ".join(desc_parts),
            "url_fonte": "https://consulta-crf.caixa.gov.br/",
            "referencia_id": str(numero_crf),
            "is_novo": True,
        }]
