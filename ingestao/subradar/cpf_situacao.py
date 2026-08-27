"""
Conector: Situação Cadastral do CPF (Receita Federal)

Verifica se o CPF está regular, suspenso, cancelado, pendente de regularização
ou nulo (não existe). CPF irregular invalida qualquer outra consulta.

Fontes, nesta ordem:
  1. Receita Federal via Infosimples (receita-federal/cpf) — fonte primária,
     devolve situação cadastral, data de inscrição, ano de óbito e código de
     comprovante verificável no site da Receita. Exige cpf + birthdate.
  2. BigDataCorp basic_data — bureau, usado quando a Receita não responde.

Sem credencial BigDataCorp a seção fica pendente — não existe fonte pública
gratuita de situação de CPF. (Havia aqui um fallback para ReceitaWS, mas aquela
API só atende CNPJ: /v1/cpf responde 404, então nunca funcionou.)

Retorna alerta crítico se CPF não estiver REGULAR.
"""
from __future__ import annotations

import logging
import os
import re

import requests

from .base import SubradarSource

logger = logging.getLogger("subradar.cpf_situacao")

# Mesmas variáveis do resto dos conectores BigDataCorp. Este módulo lia
# BIGDATA_CORP_TOKEN, que não é o nome usado em lugar nenhum do projeto — a
# fonte primária ficava permanentemente vazia.
from .bigdatacorp import BDC_TOKEN_ID, BDC_ACCESS_TOKEN, _headers

_INFOSIMPLES_TOKEN = os.environ.get("INFOSIMPLES_TOKEN", "")
_INFOSIMPLES_RFB = "https://api.infosimples.com/api/v2/consultas/receita-federal/cpf"


def _via_receita(cpf: str, nascimento: str) -> dict | None:
    """Comprovante de situação cadastral direto na Receita. None se não emitiu."""
    if not _INFOSIMPLES_TOKEN or not nascimento:
        return None
    try:
        r = requests.post(
            _INFOSIMPLES_RFB,
            data={"cpf": cpf, "birthdate": nascimento,
                  "token": _INFOSIMPLES_TOKEN, "timeout": 600},
            timeout=600,
        )
        j = r.json()
        if j.get("code") != 200:
            logger.warning("Receita CPF: code %s (%s)", j.get("code"),
                           str(j.get("code_message"))[:80])
            return None
        itens = j.get("data") or []
        return itens[0] if itens else None
    except Exception as e:
        logger.warning("Receita CPF: %s", e)
        return None


_BDC_PF_URL = "https://bigboost.bigdatacorp.com.br/peoplev2"

_STATUS_LABELS = {
    "REGULAR": "Regular",
    "SUSPENSA": "Suspensa",
    "TITULAR FALECIDO": "Titular falecido",
    "PENDENTE DE REGULARIZACAO": "Pendente de regularização",
    "CANCELADA POR ENCERRAMENTO DE ESPOLIO": "Cancelada — encerramento de espólio",
    "CANCELADA DE OFICIO": "Cancelada de ofício",
    "NULA": "Nula",
}


def _strip(doc: str) -> str:
    return re.sub(r"\D", "", str(doc or ""))


def _via_bigdatacorp(cpf: str) -> str | None:
    """Retorna situação cadastral via BigDataCorp. None se indisponível."""
    if not BDC_ACCESS_TOKEN or not BDC_TOKEN_ID:
        return None
    try:
        resp = requests.post(
            _BDC_PF_URL,
            json={"Datasets": "basic_data", "q": f"doc{{{cpf}}}", "Limit": 1},
            headers=_headers(),
            timeout=15,
        )
        if not resp.ok:
            return None
        result = (resp.json().get("Result") or [{}])[0]
        bd = result.get("BasicData") or {}
        return bd.get("RegistrationStatus") or bd.get("TaxIdStatus") or None
    except Exception as e:
        logger.debug("BigDataCorp CPF situacao: %s", e)
        return None


class CPFSituacaoConnector(SubradarSource):
    """Verifica a situação cadastral do CPF na Receita Federal."""
    fonte = "cpf_situacao_rfb"
    request_delay = 0.5

    def consultar_cnpj(self, cnpj_or_cpf: str, **_) -> list[dict]:
        cpf = _strip(cnpj_or_cpf)
        if len(cpf) != 11:
            return []

        situacao = _via_bigdatacorp(cpf)

        if situacao is None:
            logger.debug("cpf_situacao: situação não disponível para CPF %s***", cpf[:3])
            return []

        situacao_norm = situacao.upper().strip()
        label = _STATUS_LABELS.get(situacao_norm, situacao)

        if situacao_norm == "REGULAR":
            logger.debug("cpf_situacao: CPF %s*** REGULAR", cpf[:3])
            return []

        cpf_fmt = f"{cpf[:3]}.{cpf[3:6]}.{cpf[6:9]}-{cpf[9:11]}"
        severidade = "critico"

        return [{
            "fonte": self.fonte,
            "categoria": "cadastral",
            "severidade": severidade,
            "titulo": f"CPF {cpf_fmt} — Situação: {label}",
            "descricao": (
                f"A Receita Federal indica situação '{label}' para este CPF. "
                "CPF irregular pode indicar uso indevido de documento de terceiro."
            ),
            "url_fonte": "https://servicos.receita.fazenda.gov.br/Servicos/CPF/ConsultaSituacao/ConsultaPublica.asp",
            "is_novo": True,
        }]

    def resumo_pf(self, cpf: str, nome: str | None = None) -> dict | None:
        cpf_d = _strip(cpf)
        if len(cpf_d) != 11:
            return None
        # Fonte primária: Receita Federal. Precisa da data de nascimento, que o
        # formulário não coleta — vem do cadastro básico do BigDataCorp.
        cad = {}
        try:
            from .bigdatacorp_negativacoes import dados_cadastrais_pf
            cad = dados_cadastrais_pf(cpf_d) or {}
        except Exception:
            pass

        rfb = _via_receita(cpf_d, cad.get("nascimento", ""))
        if rfb:
            sit = (rfb.get("situacao_cadastral") or "").upper().strip()
            obito = rfb.get("normalizado_ano_obito") or 0
            label = _STATUS_LABELS.get(sit, sit.title() or "Não informada")
            regular = sit == "REGULAR" and not obito
            resumo = label
            if obito:
                resumo = f"CPF de titular falecido ({obito})"
            comprovante = rfb.get("consulta_comprovante") or ""
            if regular and comprovante:
                resumo = f"{label} — comprovante {comprovante}"
            return {
                "fonte": self.fonte, "categoria": "cadastral",
                "status": "limpo" if regular else "critico",
                "titulo_secao": "Situação CPF (Receita Federal)",
                "resumo": resumo,
                "detalhes": {
                    "situacao": sit,
                    "nome": rfb.get("nome"),
                    "data_inscricao": rfb.get("data_inscricao"),
                    "ano_obito": obito or None,
                    "comprovante": comprovante,
                    "consultado_em": rfb.get("consulta_datahora"),
                    "fonte": "Receita Federal via Infosimples",
                },
            }

        situacao = _via_bigdatacorp(cpf_d)
        if situacao is None:
            return {
                "fonte": self.fonte, "categoria": "cadastral",
                "status": "pendente", "titulo_secao": "Situação CPF",
                "resumo": "Não foi possível consultar — Receita e bureau indisponíveis",
                "detalhes": {},
            }
        norm = situacao.upper().strip()
        label = _STATUS_LABELS.get(norm, situacao)
        return {
            "fonte": self.fonte, "categoria": "cadastral",
            "status": "limpo" if norm == "REGULAR" else "alerta",
            "titulo_secao": "Situação CPF",
            "resumo": label,
            "detalhes": {"situacao_raw": situacao, "situacao_norm": norm},
        }
