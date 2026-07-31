"""
Conector: Infosimples — PGFN / Certidão Conjunta Federal (PJ)

Endpoint confirmado (2026-07-31):
  POST https://api.infosimples.com/api/v2/consultas/receita-federal/pgfn/nova
  body: cnpj=... + token=... + timeout=600

Campos relevantes na resposta (data[0]):
  conseguiu_emitir_certidao_negativa: bool  — True = regular
  debitos_pgfn: bool  — True = tem dívida PGFN
  debitos_rfb:  bool  — True = tem dívida RFB
  tipo: str  — "Negativa", "Positiva", "Positiva com efeitos de negativa"
  validade_data: str
  certidao_codigo: str

Custo: R$ 0,26/consulta (confirmado em teste).
Env var: INFOSIMPLES_TOKEN

Este conector é complementar ao cnd_federal_pj.py (Direct Data).
Ativa apenas se INFOSIMPLES_TOKEN presente.
"""
from __future__ import annotations

import logging
import os
import re

import requests

from .base import SubradarSource

logger = logging.getLogger("subradar.infosimples_pgfn_pj")

TOKEN = os.environ.get("INFOSIMPLES_TOKEN", "")
_URL  = "https://api.infosimples.com/api/v2/consultas/receita-federal/pgfn/nova"

_TIPOS_IRREGULARES = {"positiva"}  # "positiva com efeitos de negativa" = regular


def _fmt14(cnpj: str) -> str:
    return re.sub(r"\D", "", str(cnpj or ""))


def _mask(cnpj14: str) -> str:
    if len(cnpj14) != 14:
        return cnpj14
    return f"{cnpj14[:2]}.{cnpj14[2:5]}.{cnpj14[5:8]}/{cnpj14[8:12]}-{cnpj14[12:]}"


class InfosimplesPGFNPJConnector(SubradarSource):
    """
    Consulta certidão conjunta PGFN/RFB via Infosimples.
    Gera alerta atencao se debitos_pgfn=True ou debitos_rfb=True
    e conseguiu_emitir_certidao_negativa=False.
    """

    fonte = "pgfn"

    def consultar_cnpj(self, cnpj: str, razao_social: str | None = None, **_) -> list[dict]:
        if not TOKEN:
            logger.debug("infosimples_pgfn: sem token — pulando")
            return []

        cnpj14 = _fmt14(cnpj)
        if len(cnpj14) != 14:
            return []

        cnpj_mask = _mask(cnpj14)

        try:
            resp = requests.post(
                _URL,
                data={"cnpj": cnpj14, "token": TOKEN, "timeout": 600},
                timeout=660,
            )
        except Exception as exc:
            logger.debug("infosimples_pgfn: erro de rede — %s", exc)
            return []

        if resp.status_code in (402, 429):
            logger.warning("infosimples_pgfn: HTTP %d para %s", resp.status_code, cnpj_mask)
            return []

        if not resp.ok:
            logger.debug("infosimples_pgfn: HTTP %d para %s", resp.status_code, cnpj_mask)
            return []

        try:
            data = resp.json()
        except Exception:
            return []

        code = data.get("code")
        if code != 200:
            logger.debug("infosimples_pgfn: code=%s para %s — %s", code, cnpj_mask,
                         data.get("code_message", ""))
            return []

        registros = data.get("data", [])
        if not registros:
            return []

        reg = registros[0]
        conseguiu   = reg.get("conseguiu_emitir_certidao_negativa")
        deb_pgfn    = reg.get("debitos_pgfn")
        deb_rfb     = reg.get("debitos_rfb")
        tipo        = (reg.get("tipo") or "").strip()
        validade    = reg.get("validade_data") or reg.get("validade") or ""
        codigo      = reg.get("certidao_codigo") or ""

        # Regular: conseguiu_emitir_certidao_negativa=True
        # Ou tipo "Positiva com efeitos de negativa" (parcelamento/suspensão)
        if conseguiu is True:
            logger.debug("infosimples_pgfn: %s — certidão negativa regular", cnpj_mask)
            return []

        tipo_lower = tipo.lower()
        if "efeitos de negativa" in tipo_lower or "negativa" == tipo_lower:
            logger.debug("infosimples_pgfn: %s — tipo=%r, regular", cnpj_mask, tipo)
            return []

        # Irregular: débito confirmado
        partes = [
            f"O CNPJ {cnpj_mask} ({razao_social or cnpj_mask}) possui débitos junto à "
            f"PGFN e/ou Receita Federal do Brasil.",
        ]
        if tipo:
            partes.append(f"Tipo da certidão: {tipo!r}.")
        if deb_pgfn:
            partes.append("Débitos PGFN confirmados.")
        if deb_rfb:
            partes.append("Débitos RFB confirmados.")
        if validade:
            partes.append(f"Validade: {validade}.")
        partes.append("Fonte: Infosimples / Receita Federal (PGFN).")

        logger.info("infosimples_pgfn: DÉBITO FEDERAL confirmado para %s (tipo=%r)", cnpj_mask, tipo)

        return [{
            "fonte": self.fonte,
            "categoria": "fiscal",
            "severidade": "atencao",
            "titulo": f"PGFN/RFB — certidão positiva: {cnpj_mask}",
            "descricao": " ".join(partes),
            "url_fonte": "https://solucoes.receita.fazenda.gov.br/Servicos/certidaointernet/PJ/Emitir",
            "referencia_id": f"infosimples-pgfn-{cnpj14}",
            "is_novo": True,
            "metadados": {
                "tipo": tipo,
                "debitos_pgfn": deb_pgfn,
                "debitos_rfb": deb_rfb,
                "certidao_codigo": codigo,
                "validade": validade,
            },
        }]
