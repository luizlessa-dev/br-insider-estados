"""
Conector: Infosimples — PGFN / Certidão Conjunta Federal (PF)

Endpoint confirmado:
  POST https://api.infosimples.com/api/v2/consultas/receita-federal/pgfn/nova
  body: cnpj=<CPF_SEM_MASCARA> + token=... + timeout=600

O endpoint da Infosimples aceita tanto CNPJ (14 dígitos) quanto CPF (11 dígitos)
no parâmetro "cnpj" para a consulta de certidão conjunta PGFN/RFB.

Campos relevantes na resposta (data[0]):
  conseguiu_emitir_certidao_negativa: bool  — True = regular
  debitos_pgfn: bool  — True = tem dívida PGFN
  debitos_rfb:  bool  — True = tem dívida RFB
  tipo: str  — "Negativa", "Positiva", "Positiva com efeitos de negativa"
  validade_data: str
  certidao_codigo: str

Custo: R$ 0,26/consulta (confirmado em teste).
Env var: INFOSIMPLES_TOKEN

Este conector é complementar ao divida_ativa.py (PGFN via portal público).
Ativa apenas se INFOSIMPLES_TOKEN presente.
"""
from __future__ import annotations

import logging
import os
import re

import requests

from .base import SubradarSource

logger = logging.getLogger("subradar.infosimples_pgfn_pf")

TOKEN = os.environ.get("INFOSIMPLES_TOKEN", "")
_URL  = "https://api.infosimples.com/api/v2/consultas/receita-federal/pgfn/nova"

_TIPOS_IRREGULARES = {"positiva"}  # "positiva com efeitos de negativa" = regular


def _fmt11(cpf: str) -> str:
    return re.sub(r"\D", "", str(cpf or ""))


def _mask_cpf(cpf11: str) -> str:
    if len(cpf11) != 11:
        return cpf11
    return f"{cpf11[:3]}.{cpf11[3:6]}.{cpf11[6:9]}-{cpf11[9:]}"


class InfosimplesPGFNPFConnector(SubradarSource):
    """
    Consulta certidão conjunta PGFN/RFB via Infosimples para CPF (PF).
    Gera alerta atencao se debitos_pgfn=True ou debitos_rfb=True
    e conseguiu_emitir_certidao_negativa=False.
    """

    fonte = "pgfn_pf"

    def consultar_cpf(self, cpf: str, nome: str | None = None, **_) -> list[dict]:
        if not TOKEN:
            logger.debug("infosimples_pgfn_pf: sem token — pulando")
            return []

        cpf11 = _fmt11(cpf)
        if len(cpf11) != 11:
            return []

        cpf_mask = _mask_cpf(cpf11)

        try:
            resp = requests.post(
                _URL,
                data={"cnpj": cpf11, "token": TOKEN, "timeout": 600},
                timeout=660,
            )
        except Exception as exc:
            logger.debug("infosimples_pgfn_pf: erro de rede — %s", exc)
            return []

        if resp.status_code in (402, 429):
            logger.warning("infosimples_pgfn_pf: HTTP %d para %s", resp.status_code, cpf_mask)
            return []

        if not resp.ok:
            logger.debug("infosimples_pgfn_pf: HTTP %d para %s", resp.status_code, cpf_mask)
            return []

        try:
            data = resp.json()
        except Exception:
            return []

        code = data.get("code")
        if code != 200:
            logger.debug("infosimples_pgfn_pf: code=%s para %s — %s", code, cpf_mask,
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

        if conseguiu is True:
            logger.debug("infosimples_pgfn_pf: %s — certidão negativa regular", cpf_mask)
            return []

        tipo_lower = tipo.lower()
        if "efeitos de negativa" in tipo_lower or "negativa" == tipo_lower:
            logger.debug("infosimples_pgfn_pf: %s — tipo=%r, regular", cpf_mask, tipo)
            return []

        titular = nome or cpf_mask
        partes = [
            f"O CPF {cpf_mask} ({titular}) possui débitos junto à "
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

        logger.info("infosimples_pgfn_pf: DÉBITO FEDERAL confirmado para %s (tipo=%r)", cpf_mask, tipo)

        return [{
            "fonte": self.fonte,
            "categoria": "fiscal",
            "severidade": "atencao",
            "titulo": f"PGFN/RFB — certidão positiva: {cpf_mask}",
            "descricao": " ".join(partes),
            "url_fonte": "https://solucoes.receita.fazenda.gov.br/Servicos/certidaointernet/PF/Emitir",
            "referencia_id": f"infosimples-pgfn-pf-{cpf11}",
            "is_novo": True,
            "metadados": {
                "tipo": tipo,
                "debitos_pgfn": deb_pgfn,
                "debitos_rfb": deb_rfb,
                "certidao_codigo": codigo,
                "validade": validade,
            },
        }]
