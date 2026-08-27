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

from .base import SubradarSource, _ciclo_atual, memoizar

logger = logging.getLogger("subradar.antecedentes_criminais_pf")

TOKEN = os.environ.get("INFOSIMPLES_TOKEN", "")

_BASE = "https://api.infosimples.com/api/v2/consultas"
# O caminho antigo responde 404. Este é o serviço de emissão da certidão
# de antecedentes da PF, que exige cpf + nome + birthdate + nome_mae.
_ENDPOINT = "https://api.infosimples.com/api/v2/consultas/antecedentes-criminais/pf/emit"


def _strip_cpf(cpf: str) -> str:
    return re.sub(r"\D", "", cpf)


def _fmt_cpf(cpf: str) -> str:
    c = _strip_cpf(cpf)
    return f"{c[:3]}.{c[3:6]}.{c[6:9]}-{c[9:11]}" if len(c) == 11 else cpf


@memoizar
def _consultar_antecedentes(cpf: str, nome: str | None = None) -> dict | None:
    """Consulta antecedentes criminais na Infosimples.

    None quando a consulta não pôde ser feita — o endpoint hoje responde 404, e
    dicionário vazio virava "nenhum antecedente criminal encontrado" no laudo.
    """
    if not TOKEN or not cpf:
        return None

    cpf_limpo = _strip_cpf(cpf)
    if len(cpf_limpo) != 11:
        return None

    # A PF valida nome, nascimento e filiação contra o CPF: sem esses campos a
    # emissão é recusada (code 608). O formulário só coleta CPF e nome, então o
    # restante vem do cadastro básico do BigDataCorp.
    from .bigdatacorp_negativacoes import dados_cadastrais_pf
    cad = dados_cadastrais_pf(cpf_limpo)
    if not cad.get("nascimento") or not cad.get("nome_mae"):
        logger.warning("antecedentes_criminais: sem nascimento/filiação para o CPF — emissão impossível")
        return None

    try:
        resp = requests.post(
            _ENDPOINT,
            data={
                "token": TOKEN,
                "cpf": cpf_limpo,
                "nome": nome or cad.get("nome") or "",
                "birthdate": cad["nascimento"],
                "nome_mae": cad["nome_mae"],
                "timeout": 600,
            },
            timeout=600,
        )
        if not resp.ok:
            logger.warning("Infosimples antecedentes_criminais: HTTP %d — consulta não realizada",
                           resp.status_code)
            return None

        data = resp.json()
        if data.get("code") != 200:
            logger.warning("Infosimples antecedentes_criminais: code %s (%s) — consulta não realizada",
                           data.get("code"), str(data.get("code_message"))[:80])
            return None

        itens = data.get("data") or []
        return itens[0] if isinstance(itens, list) and itens else (itens or {})
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
        if resultado is None:
            return {
                "fonte": self.fonte, "categoria": "penal",
                "status": "pendente",
                "titulo_secao": "Antecedentes Criminais (Polícia Federal)",
                "resumo": "Não foi possível consultar — endpoint Infosimples indisponível",
                "detalhes": {},
            }

        # A emissão devolve a certidão em si:
        #   conseguiu_emitir_certidao_negativa, certidao_codigo, emissao_data, mensagem
        negativa = resultado.get("conseguiu_emitir_certidao_negativa")
        certidao = resultado.get("certidao_codigo") or resultado.get("certidao") or ""
        emissao = resultado.get("emissao_data") or ""
        mensagem = (resultado.get("mensagem") or "").strip()

        if negativa is None:
            logger.warning("Antecedentes Criminais: %s — resposta sem veredito", cpf_fmt)
            return {
                "fonte": self.fonte, "categoria": "penal", "status": "pendente",
                "titulo_secao": "Antecedentes Criminais (Polícia Federal)",
                "resumo": "Certidão não pôde ser emitida pela Polícia Federal",
                "detalhes": {"resposta": resultado},
            }

        if negativa:
            logger.info("Antecedentes Criminais: %s — certidão negativa %s", cpf_fmt, certidao)
            return {
                "fonte": self.fonte, "categoria": "penal", "status": "limpo",
                "titulo_secao": "Antecedentes Criminais (Polícia Federal)",
                "resumo": (
                    f"Certidão negativa emitida em {emissao} (nº {certidao})" if certidao
                    else "Certidão negativa — nada consta"
                ),
                "detalhes": {
                    "certidao": certidao, "emissao": emissao,
                    "mensagem": mensagem, "total_registros": 0,
                },
            }

        logger.warning("Antecedentes Criminais: %s — certidão POSITIVA", cpf_fmt)
        return {
            "fonte": self.fonte, "categoria": "penal", "status": "critico",
            "severidade": "critico",
            "titulo_secao": "Antecedentes Criminais (Polícia Federal)",
            "resumo": "Certidão POSITIVA — consta registro criminal na Polícia Federal",
            "detalhes": {"certidao": certidao, "emissao": emissao, "mensagem": mensagem},
        }
