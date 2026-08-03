"""
Conector: Infosimples — Processos Judiciais (Pessoa Física)

Consulta processos judiciais em Tribunais Regionais Federais (TRF) e
Tribunais Regionais do Trabalho (TRT) para PF.

Cobertura: TRFs 1–6, TRTs 2–27 (maioria dos estados).
Custo: R$ 0,30–0,50/consulta (mensalidade mínima R$ 100/mês).

Funciona como fallback/complemento do Escavador:
  - Escavador tem cobertura mais ampla (estaduais + federais)
  - Infosimples via Tribunais diretos (cobertura federal apenas)
  - Usar Infosimples se Escavador tiver gap geográfico ou limites de busca

Tipos de processo:
  - Cível (TRF)
  - Penal (TRF)
  - Trabalhista (TRT)
  - Administrativo (TRF)

Env var: INFOSIMPLES_TOKEN
Documentação: https://infosimples.com/consultas/

Retorna alerta para processos "em andamento" ou "condenado".
Processos arquivados/extintos retornam como informação (sem alerta).
"""
from __future__ import annotations

import logging
import os
import re

import requests

from .base import SubradarSource

logger = logging.getLogger("subradar.processos_infosimples_pf")

TOKEN = os.environ.get("INFOSIMPLES_TOKEN", "")

_BASE = "https://api.infosimples.com/api/v2/consultas"

# Endpoints Infosimples para processos judiciais
_ENDPOINTS = [
    {"tribunal": "TRF1", "endpoint": f"{_BASE}/poder_judiciario/processos/trf1/cpf"},
    {"tribunal": "TRF2", "endpoint": f"{_BASE}/poder_judiciario/processos/trf2/cpf"},
    {"tribunal": "TRF3", "endpoint": f"{_BASE}/poder_judiciario/processos/trf3/cpf"},
    {"tribunal": "TRF4", "endpoint": f"{_BASE}/poder_judiciario/processos/trf4/cpf"},
    {"tribunal": "TRF5", "endpoint": f"{_BASE}/poder_judiciario/processos/trf5/cpf"},
    {"tribunal": "TRF6", "endpoint": f"{_BASE}/poder_judiciario/processos/trf6/cpf"},
    {"tribunal": "TRT2-SP", "endpoint": f"{_BASE}/poder_judiciario/processos/trt2/cpf"},
    {"tribunal": "TRT3-MG", "endpoint": f"{_BASE}/poder_judiciario/processos/trt3/cpf"},
    {"tribunal": "TRT4-RS", "endpoint": f"{_BASE}/poder_judiciario/processos/trt4/cpf"},
]


def _strip_cpf(cpf: str) -> str:
    return re.sub(r"\D", "", cpf)


def _fmt_cpf(cpf: str) -> str:
    c = _strip_cpf(cpf)
    return f"{c[:3]}.{c[3:6]}.{c[6:9]}-{c[9:11]}" if len(c) == 11 else cpf


def _consultar_tribunal(tribunal: str, endpoint: str, cpf: str, nome: str | None = None) -> list[dict]:
    """Consulta processos em um tribunal específico."""
    if not TOKEN or not cpf:
        return []

    cpf_limpo = _strip_cpf(cpf)
    if len(cpf_limpo) != 11:
        return []

    try:
        resp = requests.get(
            endpoint,
            params={
                "token": TOKEN,
                "cpf": cpf_limpo,
                "nome": nome or "",
                "timeout": 600,
            },
            timeout=30,
        )
        if not resp.ok:
            logger.debug("Infosimples %s: HTTP %d", tribunal, resp.status_code)
            return []

        data = resp.json()
        if data.get("code") != 200:
            logger.debug("Infosimples %s: code %s", tribunal, data.get("code"))
            return []

        return data.get("data", [])
    except Exception as e:
        logger.debug("Infosimples %s: %s", tribunal, e)
        return []


class ProcessosInfosimplesPFConnector(SubradarSource):
    """
    Consulta processos judiciais (TRF/TRT) para PF via Infosimples.
    Complemento do Escavador; cobre gaps geográficos específicos.
    Gracioso se INFOSIMPLES_TOKEN não estiver configurado.
    """
    fonte = "infosimples_processos_judiciais"
    request_delay = 1.0

    def consultar_cnpj(self, cnpj_or_cpf: str, razao_social: str | None = None, **_) -> list[dict]:
        """Interface CNPJ não aplicável para este conector PF."""
        return []

    def resumo_pf(self, cpf: str, nome: str | None = None) -> dict | None:
        """
        Retorna resumo de processos judiciais para PF.

        Returns:
            dict com status "limpo" ou "alerta"
            None se TOKEN ausente ou CPF inválido
        """
        if not TOKEN:
            logger.debug("processos_infosimples: INFOSIMPLES_TOKEN ausente — pulando")
            return None

        cpf_limpo = _strip_cpf(cpf)
        if len(cpf_limpo) != 11:
            logger.debug("processos_infosimples: CPF inválido %s", cpf)
            return None

        cpf_fmt = _fmt_cpf(cpf_limpo)

        # Consultar todos os tribunais
        todos_processos = []
        tribunais_com_resultados = set()

        for config in _ENDPOINTS:
            tribunal = config["tribunal"]
            endpoint = config["endpoint"]
            processos = _consultar_tribunal(tribunal, endpoint, cpf_limpo, nome)
            if processos:
                tribunais_com_resultados.add(tribunal)
                todos_processos.extend([{**p, "tribunal": tribunal} for p in processos])

        if not todos_processos:
            logger.info("Processos Infosimples: %s — sem registros", cpf_fmt)
            return {
                "fonte": self.fonte,
                "categoria": "judicial",
                "status": "limpo",
                "titulo_secao": "Processos Judiciais (TRF/TRT via Infosimples)",
                "resumo": "Nenhum processo encontrado",
                "detalhes": {"total_processos": 0},
            }

        # Filtrar apenas processos "relevantes" (em andamento, condenado, não arquivado)
        processos_relevantes = []
        processos_arquivados = []

        for p in todos_processos:
            situacao = (p.get("situacao") or p.get("status") or "").lower()
            if "arquiv" in situacao or "encerr" in situacao or "extint" in situacao:
                processos_arquivados.append(p)
            else:
                processos_relevantes.append(p)

        n_relevantes = len(processos_relevantes)
        n_total = len(todos_processos)

        if n_relevantes == 0:
            # Só arquivados/encerrados
            logger.info("Processos Infosimples: %s — %d processos arquivados/encerrados", cpf_fmt, n_total)
            return {
                "fonte": self.fonte,
                "categoria": "judicial",
                "status": "info",
                "titulo_secao": "Processos Judiciais (TRF/TRT via Infosimples)",
                "resumo": f"{n_total} processo(s) arquivado(s)/encerrado(s)",
                "detalhes": {
                    "total_processos": n_total,
                    "processos_relevantes": 0,
                    "tribunais": list(tribunais_com_resultados),
                },
            }

        # Processos em andamento ou condenado
        severidade = "atencao"
        condenacoes = [p for p in processos_relevantes if "condenad" in (p.get("situacao") or "").lower()]
        if condenacoes:
            severidade = "critico"

        logger.warning(
            "Processos Infosimples: %s — %d em andamento (%d condenações), %d arquivados",
            cpf_fmt, n_relevantes, len(condenacoes), n_total - n_relevantes,
        )

        return {
            "fonte": self.fonte,
            "categoria": "judicial",
            "status": "alerta",
            "severidade": severidade,
            "titulo_secao": "Processos Judiciais (TRF/TRT via Infosimples)",
            "resumo": f"{n_relevantes} processo(s) em andamento{' — CONDENAÇÕES' if condenacoes else ''}",
            "detalhes": {
                "total_processos": n_total,
                "processos_relevantes": n_relevantes,
                "condenacoes": len(condenacoes),
                "arquivados": n_total - n_relevantes,
                "tribunais": list(tribunais_com_resultados),
                "processos": processos_relevantes[:10],  # Top 10
            },
        }
