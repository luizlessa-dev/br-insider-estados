"""
Conector: Justiça Federal — Certidão Unificada (TRF1 a TRF6) via Infosimples

Substitui a consulta processual por tribunal, que usava caminhos do tipo
`poder_judiciario/processos/trf1/cpf`. Esses endpoints foram descontinuados e
respondiam 404; o conector tratava a falha como lista vazia e o laudo afirmava
"Nenhum processo encontrado" sem ter consultado nada.

Serviço: tribunal/trf/cert-unificada
Parâmetros: cpf, email (destino da certidão), tipo.

Os tipos foram confirmados lendo os PDFs emitidos (o JSON de retorno não informa
a natureza da certidão):
  1 — CERTIDÃO JUDICIAL CÍVEL (processos de classes cíveis em tramitação)
  2 — CERTIDÃO JUDICIAL CRIMINAL NEGATIVA (processos de classes criminais)
  3 — CERTIDÃO JUDICIAL PARA FINS ELEITORAIS (só processos com potencial de
      gerar inelegibilidade — escopo da Ficha Limpa, inútil para background
      check de admissão)

Emitimos 1 e 2. A criminal é a que pesa para contratação; a cível entra como
complemento patrimonial/contratual. Cada consulta custa R$ 0,20.

Env: INFOSIMPLES_TOKEN · SUBRADAR_OPERADOR (e-mail de destino; não usar o do cliente)
"""
from __future__ import annotations

import logging
import os
import re

import requests

from .base import SubradarSource, memoizar

logger = logging.getLogger("subradar.processos_infosimples_pf")

_TOKEN = os.environ.get("INFOSIMPLES_TOKEN", "")
_EMAIL = os.environ.get("SUBRADAR_OPERADOR", "luiz@lessalabs.com")
_ENDPOINT = "https://api.infosimples.com/api/v2/consultas/tribunal/trf/cert-unificada"
_TIPO_CIVEL = "1"
_TIPO_CRIMINAL = "2"


def _strip_cpf(cpf: str) -> str:
    return re.sub(r"\D", "", str(cpf or ""))


@memoizar
def _emitir(cpf: str, tipo: str) -> dict | None:
    """Emite uma certidão da Justiça Federal. None quando não foi possível."""
    if not _TOKEN:
        return None
    try:
        resp = requests.post(
            _ENDPOINT,
            data={
                "cpf": cpf,
                "email": _EMAIL,
                "tipo": tipo,
                "token": _TOKEN,
                "timeout": 600,
            },
            timeout=600,
        )
        j = resp.json()
        if j.get("code") != 200:
            logger.warning("Certidão TRF tipo %s: code %s (%s)", tipo, j.get("code"),
                           str(j.get("code_message"))[:90])
            return None
        itens = j.get("data") or []
        return itens[0] if itens else None
    except Exception as e:
        logger.warning("Certidão TRF tipo %s: %s", tipo, e)
        return None


def _ler_regionais(cert: dict) -> tuple[list, list, list, dict]:
    """Separa regionais em (negativos, com registro, sem resposta) + metadados."""
    det = cert.get("detalhes_certidao") or {}
    negativos, positivos, sem_resposta = [], [], []
    for t, v in (det.get("tribunais") or {}).items():
        estado = (v or {}).get("conseguiu_emitir_certidao_negativa")
        if estado is True:
            negativos.append(t)
        elif estado is False:
            positivos.append(t)
        else:
            # Regional sem veredito (acontece com o TRF4). Não conta como
            # negativa: some do total e é declarado no laudo.
            sem_resposta.append(t)
    return negativos, positivos, sem_resposta, det


class ProcessosInfosimplesPFConnector(SubradarSource):
    """Certidões cível e criminal da Justiça Federal por CPF."""
    fonte = "infosimples_processos_judiciais"
    request_delay = 1.0

    def consultar_cpf(self, cpf: str, nome: str | None = None, **_) -> list[dict]:
        cpf_d = _strip_cpf(cpf)
        if len(cpf_d) != 11:
            return []
        alertas = []
        for tipo, rotulo, sev in ((_TIPO_CRIMINAL, "criminal", "critico"),
                                  (_TIPO_CIVEL, "cível", "atencao")):
            cert = _emitir(cpf_d, tipo)
            if not cert or cert.get("conseguiu_emitir") is not True:
                continue
            _, positivos, _, _ = _ler_regionais(cert)
            if not positivos:
                continue
            alertas.append({
                "fonte": self.fonte,
                "categoria": "judicial",
                "severidade": sev,
                "titulo": f"Justiça Federal — certidão {rotulo} com registro",
                "descricao": (
                    f"A certidão {rotulo} da Justiça Federal não saiu negativa em: "
                    + ", ".join(t.upper() for t in sorted(positivos))
                    + ". Consultar o inteiro teor para identificar os processos."
                ),
                "url_fonte": "https://certidao-unificada.cjf.jus.br",
                "is_novo": True,
            })
        return alertas

    def resumo_pf(self, cpf: str, nome: str | None = None) -> dict | None:
        cpf_d = _strip_cpf(cpf)
        if len(cpf_d) != 11:
            return None

        titulo = "Justiça Federal — Certidões Cível e Criminal"
        if not _TOKEN:
            return {
                "fonte": self.fonte, "categoria": "judicial", "status": "pendente",
                "titulo_secao": titulo,
                "resumo": "Não foi possível consultar — token Infosimples ausente",
                "detalhes": {},
            }

        resultados = {}
        for tipo, rotulo in ((_TIPO_CRIMINAL, "criminal"), (_TIPO_CIVEL, "civel")):
            cert = _emitir(cpf_d, tipo)
            if not cert or cert.get("conseguiu_emitir") is not True:
                resultados[rotulo] = None
                continue
            negativos, positivos, sem_resposta, det = _ler_regionais(cert)
            resultados[rotulo] = {
                "certidao": det.get("numero_certidao"),
                "codigo_validacao": det.get("codigo_validacao"),
                "emissao": det.get("normalizado_data_hora_emissao"),
                "negativos": negativos,
                "com_registro": positivos,
                "sem_resposta": sem_resposta,
            }

        # Certidão que não foi emitida não é certidão negativa. Basta uma das
        # duas falhar para a seção não poder afirmar ausência de processos.
        if any(v is None for v in resultados.values()):
            faltando = [k for k, v in resultados.items() if v is None]
            return {
                "fonte": self.fonte, "categoria": "judicial", "status": "pendente",
                "titulo_secao": titulo,
                "resumo": "Não foi possível emitir a certidão "
                          + " e ".join(faltando) + " da Justiça Federal",
                "detalhes": {"emitidas": {k: v for k, v in resultados.items() if v}},
            }

        crim, civ = resultados["criminal"], resultados["civel"]
        ufs = lambda l: "/".join(t.upper() for t in sorted(l))

        if crim["com_registro"]:
            status, resumo = "critico", f"Processo criminal na Justiça Federal ({ufs(crim['com_registro'])})"
        elif civ["com_registro"]:
            status, resumo = "alerta", f"Processo cível na Justiça Federal ({ufs(civ['com_registro'])})"
        else:
            status = "limpo"
            resumo = (f"Certidões negativas cível (nº {civ['certidao']}) e "
                      f"criminal (nº {crim['certidao']})")

        sem = sorted(set(crim["sem_resposta"]) | set(civ["sem_resposta"]))
        if sem:
            resumo += f" · {ufs(sem)} não respondeu"

        return {
            "fonte": self.fonte, "categoria": "judicial",
            "status": status,
            "titulo_secao": titulo,
            "resumo": resumo,
            "detalhes": {"criminal": crim, "civel": civ, "regionais_sem_resposta": sem},
        }
