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
    Gera alerta se o CPF estiver registrado e ATIVO como contador.
    Inativo e não-encontrado não geram alerta — ausência de registro ou
    registro inativo não representam risco de compliance.
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

        if resultado == "Erro" or resultado == "0":
            logger.debug("cfc_contadores: CPF %s*** não registrado ou inativo no CFC", cpf[:3])
            return []

        # resultado == "1" — registrado e ATIVO (contador praticante)
        cpf_fmt = f"{cpf[:3]}.{cpf[3:6]}.{cpf[6:9]}-{cpf[9:11]}"
        return [{
            "fonte": self.fonte,
            "categoria": "cadastral",
            "severidade": "atencao",
            "titulo": f"CFC — contador ATIVO: {cpf_fmt}",
            "descricao": (
                f"O CPF {cpf_fmt} está registrado e ATIVO no Conselho Federal de "
                "Contabilidade (CFC). Verifique possível conflito de interesse em "
                "prestação de serviços contábeis."
            ),
            "url_fonte": "https://www.cfc.org.br/consulta-de-profissional/",
            "is_novo": True,
        }]
