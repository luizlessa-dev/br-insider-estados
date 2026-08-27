"""
Conector: Protestos em cartório (CENPROT / IEPTB)

Protesto é inadimplência formalizada em cartório: mais grave que negativação em
bureau, porque houve ato notarial. Nenhuma outra fonte do dossiê cobre isso — o
conector antigo de protestos usava Direct Data, que responde 403.

Fontes, nesta ordem:
  1. ieptb/protestos — central nacional (IEPTB). Pode responder 615 quando a
     origem está instável; nesse caso cai para a de São Paulo.
  2. cenprot-sp/protestos — CENPROT SP, com abrangência declarada de 100% dos
     cartórios do estado.

Um "nada consta" da fonte estadual não é nacional: a cobertura efetiva vai no
resumo, para o laudo não sugerir alcance que não teve.

Env: INFOSIMPLES_TOKEN · custo aproximado R$ 0,30 por consulta
"""
from __future__ import annotations

import logging
import os
import re

import requests

from .base import SubradarSource, memoizar

logger = logging.getLogger("subradar.protestos_cenprot_pf")

_TOKEN = os.environ.get("INFOSIMPLES_TOKEN", "")
_BASE = "https://api.infosimples.com/api/v2/consultas"
_NACIONAL = f"{_BASE}/ieptb/protestos"
_SP = f"{_BASE}/cenprot-sp/protestos"

# A origem responde 612 tanto para "nada consta" quanto para falha de extração.
# Só tratamos como negativa quando a mensagem afirma a ausência.
_FRASES_NEGATIVA = ("não constam protestos", "nao constam protestos",
                    "nenhum protesto", "nada consta")


def _strip_cpf(cpf: str) -> str:
    return re.sub(r"\D", "", str(cpf or ""))


@memoizar
def _consultar(url: str, cpf: str) -> tuple[str, dict | list]:
    """Devolve (estado, payload) com estado em {ok, negativa, indisponivel}."""
    if not _TOKEN:
        return "indisponivel", {}
    try:
        r = requests.post(url, data={"cpf": cpf, "token": _TOKEN, "timeout": 600}, timeout=600)
        j = r.json()
        code = j.get("code")
        if code == 200:
            return "ok", (j.get("data") or [])
        if code == 612:
            msg = " ".join(str(e).lower() for e in (j.get("errors") or []))
            if any(f in msg for f in _FRASES_NEGATIVA):
                return "negativa", {"mensagem": (j.get("errors") or [""])[0]}
            logger.warning("Protestos: 612 sem confirmação de ausência — %s", msg[:90])
            return "indisponivel", {}
        logger.warning("Protestos: code %s (%s)", code, str(j.get("code_message"))[:80])
        return "indisponivel", {}
    except Exception as e:
        logger.warning("Protestos: %s", e)
        return "indisponivel", {}


class ProtestosCenprotPFConnector(SubradarSource):
    """Protestos em cartório por CPF."""
    fonte = "protestos_cenprot_pf"
    request_delay = 1.0

    def consultar_cpf(self, cpf: str, nome: str | None = None, **_) -> list[dict]:
        cpf_d = _strip_cpf(cpf)
        if len(cpf_d) != 11:
            return []
        for url in (_NACIONAL, _SP):
            estado, payload = _consultar(url, cpf_d)
            if estado == "negativa":
                return []
            if estado == "ok" and payload:
                total = sum(len(item.get("protestos") or []) or 1 for item in payload)
                return [{
                    "fonte": self.fonte,
                    "categoria": "divida",
                    "severidade": "critico" if total > 3 else "atencao",
                    "titulo": f"{total} protesto(s) em cartório",
                    "descricao": (
                        f"Constam {total} título(s) protestado(s) em cartório. "
                        "Protesto indica inadimplência formalizada, com efeito público."
                    ),
                    "url_fonte": "https://protestosp.com.br",
                    "is_novo": True,
                }]
        return []

    def resumo_pf(self, cpf: str, nome: str | None = None) -> dict | None:
        cpf_d = _strip_cpf(cpf)
        if len(cpf_d) != 11:
            return None

        titulo = "Protestos em Cartório"
        if not _TOKEN:
            return {
                "fonte": self.fonte, "categoria": "divida", "status": "pendente",
                "titulo_secao": titulo,
                "resumo": "Não foi possível consultar — token Infosimples ausente",
                "detalhes": {},
            }

        for url, cobertura in ((_NACIONAL, "nacional"), (_SP, "estadual (SP)")):
            estado, payload = _consultar(url, cpf_d)
            if estado == "negativa":
                return {
                    "fonte": self.fonte, "categoria": "divida", "status": "limpo",
                    "titulo_secao": titulo,
                    "resumo": f"Nenhum protesto encontrado — abrangência {cobertura}",
                    "detalhes": {"total": 0, "cobertura": cobertura,
                                 "mensagem": payload.get("mensagem") if isinstance(payload, dict) else None},
                }
            if estado == "ok":
                itens = payload if isinstance(payload, list) else []
                total = sum(len(i.get("protestos") or []) or 1 for i in itens)
                if not total:
                    return {
                        "fonte": self.fonte, "categoria": "divida", "status": "limpo",
                        "titulo_secao": titulo,
                        "resumo": f"Nenhum protesto encontrado — abrangência {cobertura}",
                        "detalhes": {"total": 0, "cobertura": cobertura},
                    }
                return {
                    "fonte": self.fonte, "categoria": "divida",
                    "status": "critico" if total > 3 else "alerta",
                    "titulo_secao": titulo,
                    "resumo": f"{total} protesto(s) em cartório — abrangência {cobertura}",
                    "detalhes": {"total": total, "cobertura": cobertura, "itens": itens[:10]},
                }

        return {
            "fonte": self.fonte, "categoria": "divida", "status": "pendente",
            "titulo_secao": titulo,
            "resumo": "Não foi possível consultar as centrais de protesto",
            "detalhes": {},
        }
