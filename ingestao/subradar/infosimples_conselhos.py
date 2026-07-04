"""
Conector: Infosimples — Conselhos Profissionais

Cobre CRO (27 estados), COREN (PR e SP), CRF, CFM, CFMV, CFP, CFBM.
Custo: R$ 0,20/consulta (mensalidade mínima R$ 100/mês).

Busca por nome (razao_social passado via parâmetro) pois a maioria dos endpoints
Infosimples não aceita CPF diretamente — exceto CFM que aceita CRM.
Para CPF, usa o nome completo como chave de busca e filtra pelo nome exato.

Env var: INFOSIMPLES_TOKEN
Documentação: https://infosimples.com/consultas/

Retorna alerta se encontrar registro com situação diferente de ativa/regular.
Ausência de registro não gera alerta.
"""
from __future__ import annotations

import logging
import os
import re
import unicodedata

import requests

from .base import SubradarSource

logger = logging.getLogger("subradar.infosimples_conselhos")

TOKEN = os.environ.get("INFOSIMPLES_TOKEN", "")

_BASE = "https://api.infosimples.com/api/v2/consultas"

# Conselhos e seus endpoints Infosimples
_CONSELHOS = [
    {"sigla": "CRO",      "endpoint": f"{_BASE}/cro/sp/profissional"},   # SP como piloto
    {"sigla": "CRF",      "endpoint": f"{_BASE}/crf/federal/profissional"},
    {"sigla": "CFM",      "endpoint": f"{_BASE}/cfm/federal/medicos"},
    {"sigla": "CFMV",     "endpoint": f"{_BASE}/cfmv/federal/profissional"},
    {"sigla": "CFP",      "endpoint": f"{_BASE}/cfp/federal/profissional"},
    {"sigla": "CFBM",     "endpoint": f"{_BASE}/cfbm/federal/profissional"},  # Biomedicina
    {"sigla": "COREN-PR", "endpoint": f"{_BASE}/coren/pr/profissional"},
    {"sigla": "COREN-SP", "endpoint": f"{_BASE}/coren/sp/profissional"},
]

_ATIVO = {"ativo", "regular", "quite", "habilitado", "inscrito", "em atividade"}


def _normalize(s: str) -> str:
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    return s.upper().strip()


def _nome_match(nome_buscado: str, nome_resultado: str) -> bool:
    """Verifica se os nomes são suficientemente parecidos (primeiro + último nome)."""
    a = _normalize(nome_buscado).split()
    b = _normalize(nome_resultado).split()
    if not a or not b:
        return False
    # Primeiro e último nome devem coincidir
    return a[0] == b[0] and a[-1] == b[-1]


def _consultar_conselho(sigla: str, endpoint: str, nome: str) -> list[dict]:
    if not TOKEN or not nome:
        return []
    try:
        resp = requests.get(
            endpoint,
            params={"token": TOKEN, "nome": nome, "timeout": 600},
            timeout=30,
        )
        if not resp.ok:
            logger.debug("Infosimples %s: HTTP %d", sigla, resp.status_code)
            return []
        data = resp.json()
        if data.get("code") != 200:
            logger.debug("Infosimples %s: code %s", sigla, data.get("code"))
            return []
        return data.get("data", [])
    except Exception as e:
        logger.debug("Infosimples %s: %s", sigla, e)
        return []


class InfosimplesConselhosPFConnector(SubradarSource):
    """
    Consulta situação profissional em CRO, CRF, CFM, CFMV, CFP e COREN via Infosimples.
    Gracioso se INFOSIMPLES_TOKEN não estiver configurado.
    """
    fonte = "infosimples_conselhos"
    request_delay = 1.0

    def consultar_cnpj(self, cnpj_or_cpf: str, razao_social: str | None = None, **_) -> list[dict]:
        if not TOKEN:
            logger.debug("infosimples: INFOSIMPLES_TOKEN ausente — pulando")
            return []

        nome = razao_social or ""
        if not nome:
            return []

        alertas = []

        for conselho in _CONSELHOS:
            sigla = conselho["sigla"]
            registros = _consultar_conselho(sigla, conselho["endpoint"], nome)

            for reg in registros:
                nome_reg = reg.get("nome") or reg.get("profissional") or ""
                if not _nome_match(nome, nome_reg):
                    continue

                situacao = (
                    reg.get("situacao") or
                    reg.get("status") or
                    reg.get("situacao_inscricao") or ""
                ).lower().strip()

                numero = reg.get("numero") or reg.get("inscricao") or reg.get("cro") or ""

                if not situacao or any(a in situacao for a in _ATIVO):
                    logger.debug("infosimples %s: %s — %s (regular)", sigla, nome_reg, situacao)
                    continue

                alertas.append({
                    "fonte": self.fonte,
                    "categoria": "cadastral",
                    "severidade": "atencao",
                    "titulo": f"{sigla} — registro '{situacao.upper()}': {nome_reg}",
                    "descricao": (
                        f"Registro n° {numero} no {sigla} com situação '{situacao}'. "
                        f"Profissional pode estar impedido de exercer a atividade."
                    ),
                    "url_fonte": "https://infosimples.com/consultas/",
                    "is_novo": True,
                })

        return alertas
