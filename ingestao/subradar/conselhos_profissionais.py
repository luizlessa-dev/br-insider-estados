"""
Conector: Conselhos Profissionais — situação do registro (Implanta API)

Verifica se o profissional está ativo e sem impedimento no conselho de classe.
Relevante para uso de credenciamento (médicos, engenheiros, advogados, contadores).

Conselhos disponíveis via Implanta API (footprint em expansão):
  - CREA (Engenharia e Agronomia)
  - CRM (Medicina)
  - OAB (Advocacia)
  - CRO (Odontologia)
  - CRC (Contabilidade)
  - COREN (Enfermagem)

Busca por CPF ou por nome. Retorna alerta se encontrar registro com situação
diferente de "Ativo" / "Regular".

Ref: Implanta API — https://www.implantasistemas.com.br/api (descoberta jul/2026)
"""
from __future__ import annotations

import logging
import os
import re

import requests

from .base import SubradarSource

logger = logging.getLogger("subradar.conselhos_profissionais")

IMPLANTA_TOKEN = os.environ.get("IMPLANTA_API_TOKEN", "")

# Endpoints conhecidos por conselho (expandir conforme footprint nacional)
_CONSELHOS = [
    {"sigla": "CREA-SP", "url": "https://www.creasp.org.br/api/v1/profissional"},
    # Demais a mapear conforme Implanta API footprint
]

_ATIVO_LABELS = {"ativo", "regular", "quite", "quite com anuidade"}


def _strip(doc: str) -> str:
    return re.sub(r"\D", "", str(doc or ""))


def _buscar_por_cpf_implanta(cpf: str) -> list[dict]:
    """Consulta Implanta API por CPF. Retorna lista de registros encontrados."""
    if not IMPLANTA_TOKEN:
        return []
    try:
        resp = requests.get(
            "https://api.implantasistemas.com.br/v1/profissionais",
            params={"cpf": cpf, "token": IMPLANTA_TOKEN},
            timeout=15,
        )
        if resp.ok and isinstance(resp.json(), list):
            return resp.json()
        if resp.ok and isinstance(resp.json(), dict):
            return [resp.json()]
    except Exception as e:
        logger.debug("Implanta API: %s", e)
    return []


def _buscar_crea_sp(cpf: str, nome: str) -> list[dict]:
    """Consulta pública CREA-SP por CPF ou nome (sem autenticação)."""
    resultados = []
    try:
        resp = requests.get(
            "https://www.creasp.org.br/profissional/consulta",
            params={"cpf": cpf} if cpf else {"nome": nome},
            headers={"User-Agent": "subradar/1.0 compliance-check"},
            timeout=10,
        )
        if resp.ok:
            data = resp.json() if resp.headers.get("content-type", "").startswith("application/json") else {}
            if isinstance(data, list):
                resultados = data
            elif isinstance(data, dict) and data:
                resultados = [data]
    except Exception as e:
        logger.debug("CREA-SP: %s", e)
    return resultados


class ConselhosProfissionaisConnector(SubradarSource):
    """
    Verifica situação do profissional em conselhos de classe (CREA, CRM, OAB…).
    Só gera alerta se o registro existir e NÃO estiver ativo/regular.
    Ausência de registro não gera alerta (a pessoa pode não ter esse conselho).
    """
    fonte = "conselhos_profissionais"
    request_delay = 1.0

    def consultar_cnpj(self, cnpj_or_cpf: str, razao_social: str | None = None, **_) -> list[dict]:
        cpf = _strip(cnpj_or_cpf)
        if len(cpf) != 11:
            return []

        cpf_fmt = f"{cpf[:3]}.{cpf[3:6]}.{cpf[6:9]}-{cpf[9:11]}"
        nome = razao_social or ""
        alertas = []

        # Via Implanta API (quando token disponível)
        registros = _buscar_por_cpf_implanta(cpf)

        # Fallback: CREA-SP público
        if not registros:
            registros = _buscar_crea_sp(cpf, nome)

        if not registros:
            logger.debug("conselhos: nenhum registro encontrado para CPF %s***", cpf[:3])
            return []

        for reg in registros:
            conselho = reg.get("conselho") or reg.get("sigla") or "Conselho"
            situacao = (reg.get("situacao") or reg.get("status") or "").lower().strip()
            numero = reg.get("numero") or reg.get("registro") or ""

            if not situacao:
                continue

            if situacao in _ATIVO_LABELS:
                logger.debug("conselhos: %s %s — %s (regular)", conselho, numero, situacao)
                continue

            alertas.append({
                "fonte": self.fonte,
                "categoria": "cadastral",
                "severidade": "atencao",
                "titulo": f"{conselho} — registro {situacao.upper()}: {cpf_fmt}",
                "descricao": (
                    f"Registro n° {numero} no {conselho} com situação '{situacao}'. "
                    "Profissional pode estar impedido de exercer a atividade."
                ),
                "url_fonte": "https://www.implantasistemas.com.br/consulta",
                "is_novo": True,
            })

        return alertas
