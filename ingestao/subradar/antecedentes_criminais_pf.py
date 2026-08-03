"""
Conector: Infosimples — Antecedentes Criminais (Pessoa Física)

Consulta antecedentes criminais nacionais da Polícia Federal para PF.
Cobertura: Nacional (condenações transitadas em julgado, condenações em andamento).
Custo: R$ 0,50–1,50/consulta (mensalidade mínima R$ 100/mês).

Env var: INFOSIMPLES_TOKEN
Documentação: https://infosimples.com/consultas/

Retorna alerta se encontrar registro de antecedentes criminais.
Ausência de registro não gera alerta (retorna resumo com status "limpo").
"""
from __future__ import annotations

import logging
import os
import re

import requests

from .base import SubradarSource, _ciclo_atual

logger = logging.getLogger("subradar.antecedentes_criminais_pf")

TOKEN = os.environ.get("INFOSIMPLES_TOKEN", "")

_BASE = "https://api.infosimples.com/api/v2/consultas"
_ENDPOINT = f"{_BASE}/antecedentes_criminais/federal/pessoa_fisica"


def _strip_cpf(cpf: str) -> str:
    return re.sub(r"\D", "", cpf)


def _fmt_cpf(cpf: str) -> str:
    c = _strip_cpf(cpf)
    return f"{c[:3]}.{c[3:6]}.{c[6:9]}-{c[9:11]}" if len(c) == 11 else cpf


def _consultar_antecedentes(cpf: str, nome: str | None = None) -> dict:
    """Consulta antecedentes criminais na Infosimples."""
    if not TOKEN or not cpf:
        return {}

    cpf_limpo = _strip_cpf(cpf)
    if len(cpf_limpo) != 11:
        return {}

    try:
        resp = requests.get(
            _ENDPOINT,
            params={
                "token": TOKEN,
                "cpf": cpf_limpo,
                "nome": nome or "",
                "timeout": 600,
            },
            timeout=30,
        )
        if not resp.ok:
            logger.debug("Infosimples antecedentes_criminais: HTTP %d", resp.status_code)
            return {}

        data = resp.json()
        if data.get("code") != 200:
            logger.debug("Infosimples antecedentes_criminais: code %s", data.get("code"))
            return {}

        return data.get("data", {})
    except Exception as e:
        logger.debug("Infosimples antecedentes_criminais: %s", e)
        return {}


class AntecedentesHCrimosPFConnector(SubradarSource):
    """
    Consulta antecedentes criminais (Polícia Federal) para PF via Infosimples.
    Gracioso se INFOSIMPLES_TOKEN não estiver configurado.
    """
    fonte = "infosimples_antecedentes_criminais"
    request_delay = 1.0

    def consultar_cnpj(self, cnpj_or_cpf: str, razao_social: str | None = None, **_) -> list[dict]:
        """Interface CNPJ não aplicável para este conector PF."""
        return []

    def resumo_pf(self, cpf: str, nome: str | None = None) -> dict | None:
        """
        Retorna resumo de antecedentes criminais para PF.

        Returns:
            dict com status "limpo" ou "alerta"
            None se TOKEN ausente ou CPF inválido
        """
        if not TOKEN:
            logger.debug("antecedentes_criminais: INFOSIMPLES_TOKEN ausente — pulando")
            return None

        cpf_limpo = _strip_cpf(cpf)
        if len(cpf_limpo) != 11:
            logger.debug("antecedentes_criminais: CPF inválido %s", cpf)
            return None

        cpf_fmt = _fmt_cpf(cpf_limpo)
        resultado = _consultar_antecedentes(cpf_limpo, nome)

        # Resposta esperada: {"condenado": bool, "registros": [...]}
        # ou {"tem_antecedentes": bool, "detalhes": [...]}
        condenado = resultado.get("condenado", False)
        tem_antecedentes = resultado.get("tem_antecedentes", False)
        registros = resultado.get("registros", []) or resultado.get("detalhes", [])

        if not condenado and not tem_antecedentes:
            logger.info("Antecedentes Criminais: %s — sem registros", cpf_fmt)
            return {
                "fonte": self.fonte,
                "categoria": "penal",
                "status": "limpo",
                "titulo_secao": "Antecedentes Criminais (Polícia Federal)",
                "resumo": "Nenhum antecedente criminal encontrado",
                "detalhes": {"total_registros": 0},
            }

        # Se houver antecedentes
        n_registros = len(registros)
        severidade = "critico" if condenado else "atencao"
        status_txt = "CONDENADO(A)" if condenado else "Antecedentes encontrados"

        logger.warning("Antecedentes Criminais: %s — %s (%d registro(s))", cpf_fmt, status_txt, n_registros)

        return {
            "fonte": self.fonte,
            "categoria": "penal",
            "status": "alerta",
            "severidade": severidade,
            "titulo_secao": "Antecedentes Criminais (Polícia Federal)",
            "resumo": f"{status_txt} — {n_registros} registro(s)",
            "detalhes": {
                "total_registros": n_registros,
                "condenado": condenado,
                "registros": registros[:10],  # Top 10
            },
        }
