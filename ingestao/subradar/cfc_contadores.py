"""
Conector: CFC — Conselho Federal de Contabilidade

API REST pública e gratuita. Consulta situação do contador por CPF.
Retorna '1' (ativo), '0' (inativo) ou 'Erro' (CPF não encontrado no CFC).

Endpoint: GET https://sistemas.cfc.org.br/servico/api/Profissional?cpf={cpf}
Autenticação: nenhuma.
Documentação: https://sistemas.cfc.org.br/servico/help
"""
from __future__ import annotations

import logging
import re

import requests

from .base import SubradarSource

logger = logging.getLogger("subradar.cfc_contadores")

_CFC_URL = "https://sistemas.cfc.org.br/servico/api/Profissional"


def _strip(doc: str) -> str:
    return re.sub(r"\D", "", str(doc or ""))


class CFCContadoresConnector(SubradarSource):
    """
    Consulta situação do profissional no CFC por CPF.
    Só gera alerta se o CPF estiver registrado e INATIVO.
    Ausência de registro (Erro) não gera alerta — a pessoa pode simplesmente
    não ser contadora.
    """
    fonte = "cfc_contadores"
    request_delay = 0.5

    def consultar_cnpj(self, cnpj_or_cpf: str, **_) -> list[dict]:
        cpf = _strip(cnpj_or_cpf)
        if len(cpf) != 11:
            return []

        try:
            resp = requests.get(
                _CFC_URL,
                params={"cpf": cpf},
                headers={"User-Agent": "subradar/1.0 compliance-check"},
                timeout=10,
            )
        except Exception as e:
            logger.warning("CFC API indisponível: %s", e)
            return []

        if not resp.ok:
            logger.debug("CFC API: HTTP %d para CPF %s***", resp.status_code, cpf[:3])
            return []

        resultado = resp.text.strip().strip('"')  # retorna string "1", "0" ou "Erro"

        if resultado == "1":
            logger.debug("cfc_contadores: CPF %s*** ativo no CFC", cpf[:3])
            return []

        if resultado == "Erro":
            logger.debug("cfc_contadores: CPF %s*** não encontrado no CFC", cpf[:3])
            return []

        # resultado == "0" — registrado mas inativo
        cpf_fmt = f"{cpf[:3]}.{cpf[3:6]}.{cpf[6:9]}-{cpf[9:11]}"
        return [{
            "fonte": self.fonte,
            "categoria": "cadastral",
            "severidade": "atencao",
            "titulo": f"CFC — contador INATIVO: {cpf_fmt}",
            "descricao": (
                f"O CPF {cpf_fmt} consta no Conselho Federal de Contabilidade (CFC) "
                "com situação INATIVA. O profissional pode estar impedido de exercer "
                "atividades contábeis."
            ),
            "url_fonte": "https://www.cfc.org.br/consulta-de-profissional/",
            "is_novo": True,
        }]
