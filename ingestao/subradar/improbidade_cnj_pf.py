"""
Conector: CNJ — Condenações por Improbidade Administrativa e Inelegibilidade

Consulta o CNIA (Cadastro Nacional de Condenações Cíveis por Ato de Improbidade
Administrativa e Inelegibilidade), mantido pelo CNJ, e emite certidão.

Cobre um risco que nenhuma outra fonte do dossiê alcança: condenação por
improbidade não aparece em antecedentes criminais (é ação cível), não consta na
CNDT (não é débito trabalhista) e nem sempre está nas bases de processos por
estar em segredo ou já transitada.

Serviço: cnj/improbidade · parâmetro: cpf · custo aproximado R$ 0,24
Retorno: certidao_negativa, registros, registros_lista
"""
from __future__ import annotations

import logging
import os
import re

import requests

from .base import SubradarSource

logger = logging.getLogger("subradar.improbidade_cnj_pf")

_TOKEN = os.environ.get("INFOSIMPLES_TOKEN", "")
_ENDPOINT = "https://api.infosimples.com/api/v2/consultas/cnj/improbidade"


def _strip_cpf(cpf: str) -> str:
    return re.sub(r"\D", "", str(cpf or ""))


def _consultar(cpf: str) -> dict | None:
    """Consulta o CNIA. None quando a certidão não pôde ser emitida."""
    if not _TOKEN:
        return None
    try:
        resp = requests.post(
            _ENDPOINT,
            data={"cpf": cpf, "token": _TOKEN, "timeout": 600},
            timeout=600,
        )
        j = resp.json()
        if j.get("code") != 200:
            logger.warning("CNIA improbidade: code %s (%s)", j.get("code"),
                           str(j.get("code_message"))[:90])
            return None
        itens = j.get("data") or []
        return itens[0] if itens else None
    except Exception as e:
        logger.warning("CNIA improbidade: %s", e)
        return None


class ImprobidadeCNJPFConnector(SubradarSource):
    """Condenações por improbidade administrativa e inelegibilidade (CNJ/CNIA)."""
    fonte = "cnj_improbidade"
    request_delay = 1.0

    def consultar_cpf(self, cpf: str, nome: str | None = None, **_) -> list[dict]:
        cpf_d = _strip_cpf(cpf)
        if len(cpf_d) != 11:
            return []
        d = _consultar(cpf_d)
        if not d or not d.get("registros"):
            return []
        registros = d.get("registros_lista") or []
        return [{
            "fonte": self.fonte,
            "categoria": "sancao",
            "severidade": "critico",
            "titulo": "Condenação por improbidade administrativa (CNJ)",
            "descricao": (
                f"Constam {d.get('registros')} registro(s) no Cadastro Nacional de "
                "Condenações Cíveis por Ato de Improbidade Administrativa e "
                "Inelegibilidade. "
                + "; ".join(str(r)[:120] for r in registros[:3])
            ),
            "url_fonte": "https://www.cnj.jus.br/improbidade_adm/consultar_requerido.php",
            "is_novo": True,
        }]

    def resumo_pf(self, cpf: str, nome: str | None = None) -> dict | None:
        cpf_d = _strip_cpf(cpf)
        if len(cpf_d) != 11:
            return None

        titulo = "Improbidade Administrativa (CNJ/CNIA)"
        if not _TOKEN:
            return {
                "fonte": self.fonte, "categoria": "sancao", "status": "pendente",
                "titulo_secao": titulo,
                "resumo": "Não foi possível consultar — token Infosimples ausente",
                "detalhes": {},
            }

        d = _consultar(cpf_d)
        # Certidão não emitida não equivale a certidão negativa.
        if d is None:
            return {
                "fonte": self.fonte, "categoria": "sancao", "status": "pendente",
                "titulo_secao": titulo,
                "resumo": "Não foi possível emitir a certidão junto ao CNJ",
                "detalhes": {},
            }

        n = d.get("registros") or 0
        negativa = d.get("certidao_negativa")
        if not n and negativa:
            return {
                "fonte": self.fonte, "categoria": "sancao", "status": "limpo",
                "titulo_secao": titulo,
                "resumo": "Certidão negativa — nenhuma condenação por improbidade",
                "detalhes": {"registros": 0, "certidao_negativa": True},
            }
        return {
            "fonte": self.fonte, "categoria": "sancao", "status": "critico",
            "titulo_secao": titulo,
            "resumo": f"{n} condenação(ões) por improbidade administrativa",
            "detalhes": {"registros": n, "lista": (d.get("registros_lista") or [])[:10]},
        }
