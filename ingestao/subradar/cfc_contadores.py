"""
Conector: CFC — Conselho Federal de Contabilidade

API REST pública e gratuita. Consulta situação do contador por CPF.
Responde JSON: {"EhContadorAtivo": 0|1, "PossuiCNAIAtivo": 0|1}.

O endpoint já respondeu texto puro ('1'/'0'/'Erro') e mudou para JSON sem aviso;
o parsing abaixo aceita as duas formas e, em qualquer resposta que não confirme
explicitamente o registro ativo, não gera alerta.

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

        # Só afirma registro ativo quando a resposta confirma. Qualquer outro
        # formato é tratado como "não confirmado" — antes, o corpo JSON inteiro
        # caía no ramo de ativo e todo CPF consultado virava contador ativo.
        ativo = False
        try:
            payload = resp.json()
            if isinstance(payload, dict):
                ativo = str(payload.get("EhContadorAtivo", "0")) == "1"
            else:
                ativo = str(payload).strip() == "1"
        except ValueError:
            ativo = resp.text.strip().strip('"') == "1"

        if not ativo:
            logger.debug("cfc_contadores: CPF %s*** não registrado ou inativo no CFC", cpf[:3])
            return []

        cpf_fmt = f"{cpf[:3]}.{cpf[3:6]}.{cpf[6:9]}-{cpf[9:11]}"
        return [{
            "fonte": self.fonte,
            "categoria": "cadastral",
            "severidade": "atencao",
            "titulo": "Registro ativo no Conselho Federal de Contabilidade",
            "descricao": (
                "O CPF consta como contador com registro ativo no Conselho Federal "
                "de Contabilidade (CFC). É um dado cadastral, não uma ocorrência "
                "adversa: relevante apenas quando a função envolve serviços "
                "contábeis ou pode configurar conflito de interesse."
            ),
            "url_fonte": "https://www.cfc.org.br/consulta-de-profissional/",
            "is_novo": True,
        }]
