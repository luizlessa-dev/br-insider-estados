"""
Conector: TSE — Situação Eleitoral (quitação do título)

Verifica se o CPF possui título eleitoral regular, cancelado ou suspenso.
A API oficial do TSE (CSE) requer cadastro por e-mail de órgão público.
Este conector usa a Direct Data API v3 como proxy.

Custo: consumido pelo mesmo DIRECT_DATA_TOKEN do pipeline B2B.
Endpoint: GET https://apiv3.directd.com.br/api/SituacaoEleitoral

Env var: DIRECT_DATA_TOKEN

Lógica de alerta:
  - isRegular = false → atencao (título irregular/cancelado/suspenso)
  - isRegular = true  → sem alerta (regular é o esperado)
  - CPF não encontrado na base eleitoral → sem alerta (pode não ter título)

Uso principal: due diligence de candidatos a cargos públicos, credenciamento de
prestadores e verificações de idoneidade onde quitação eleitoral é exigida por lei.
"""
from __future__ import annotations

import logging
import os
import re

import requests

from .base import SubradarSource

logger = logging.getLogger("subradar.tse_situacao_pf")

_DD_TOKEN = os.environ.get("DIRECT_DATA_TOKEN", "")
_INFOSIMPLES_TOKEN = os.environ.get("INFOSIMPLES_TOKEN", "")
_INFOSIMPLES_TSE = "https://api.infosimples.com/api/v2/consultas/tribunal/tse/certidao"


def _via_infosimples(cpf: str) -> dict | None:
    """Certidão de quitação eleitoral pelo TSE.

    Serviço restrito na Infosimples: exige habilitação prévia da conta pelo
    formulário https://api.infosimples.com/habilitar/tribunal%2Ftse%2Fcertidao
    (responde code 603 enquanto não habilitado). None quando não emitiu.
    """
    if not _INFOSIMPLES_TOKEN:
        return None
    try:
        r = requests.post(
            _INFOSIMPLES_TSE,
            data={"cpf": cpf, "token": _INFOSIMPLES_TOKEN, "timeout": 600},
            timeout=600,
        )
        j = r.json()
        if j.get("code") == 603:
            logger.warning("TSE: consulta não habilitada na Infosimples — habilitar em "
                           "https://api.infosimples.com/habilitar/tribunal%2Ftse%2Fcertidao")
            return None
        if j.get("code") != 200:
            logger.warning("TSE Infosimples: code %s (%s)", j.get("code"),
                           str(j.get("code_message"))[:80])
            return None
        itens = j.get("data") or []
        return itens[0] if itens else None
    except Exception as e:
        logger.warning("TSE Infosimples: %s", e)
        return None


_DD_V3_BASE = "https://apiv3.directd.com.br/api"

_STATUS_IRREGULAR = {
    "cancelado", "suspenso", "irregular",
    "pendente de revisão", "nulo", "excluído",
}


def _strip(cpf: str) -> str:
    return re.sub(r"\D", "", str(cpf or ""))


def _consultar_tse(cpf: str, nome: str = "") -> dict | None:
    """Consulta Direct Data v3 — situação eleitoral por CPF."""
    params: dict = {"Token": _DD_TOKEN, "CPF": cpf}
    if nome:
        params["Nome"] = nome
    try:
        resp = requests.get(
            f"{_DD_V3_BASE}/SituacaoEleitoral",
            params=params,
            timeout=20,
        )
        if not resp.ok:
            logger.debug("TSE: HTTP %d para CPF %s***", resp.status_code, cpf[:3])
            return None
        data = resp.json()
        if isinstance(data, list) and data:
            return data[0]
        if isinstance(data, dict):
            return data
        return None
    except Exception as e:
        logger.debug("TSE: %s", e)
        return None


class TSESituacaoEleitoralPFConnector(SubradarSource):
    """
    Verifica situação eleitoral do CPF via TSE / Direct Data v3.
    Gera alerta 'atencao' quando o título está cancelado, suspenso ou irregular.
    Gracioso se DIRECT_DATA_TOKEN ausente.
    """
    fonte = "tse_situacao_eleitoral"
    request_delay = 0.5

    def consultar_cnpj(self, cnpj_or_cpf: str, razao_social: str | None = None, **_) -> list[dict]:
        if not _DD_TOKEN:
            logger.debug("tse_pf: DIRECT_DATA_TOKEN ausente — pulando")
            return []

        cpf = _strip(cnpj_or_cpf)
        if len(cpf) != 11:
            return []

        cpf_fmt = f"{cpf[:3]}.{cpf[3:6]}.{cpf[6:9]}-{cpf[9:11]}"
        nome = razao_social or ""

        dados = _consultar_tse(cpf, nome)
        if dados is None:
            logger.debug("tse_pf: sem resposta para CPF %s***", cpf[:3])
            return []

        # Normaliza campo de regularidade
        is_regular = dados.get("isRegular") or dados.get("regular") or dados.get("situacaoRegular")

        if is_regular is True or str(is_regular).lower() in ("true", "1", "sim"):
            logger.debug("tse_pf: CPF %s*** — título regular", cpf[:3])
            return []

        # Nenhum registro na base eleitoral (is_regular == None / campo ausente)
        status = (
            dados.get("status") or
            dados.get("situacao") or
            dados.get("descricaoSituacao") or
            dados.get("identificacao") or ""
        ).lower().strip()

        if not status and is_regular is None:
            logger.debug("tse_pf: CPF %s*** não localizado na base eleitoral", cpf[:3])
            return []

        # Determina se realmente irregular ou apenas desconhecido
        eh_irregular = (
            is_regular is False or
            str(is_regular).lower() in ("false", "0", "não", "nao") or
            any(s in status for s in _STATUS_IRREGULAR)
        )
        if not eh_irregular:
            return []

        numero_titulo = dados.get("numeroTitulo") or dados.get("titulo") or "s/n"
        zona = dados.get("zona") or dados.get("zonaEleitoral") or ""
        secao = dados.get("secao") or dados.get("secaoEleitoral") or ""
        municipio = dados.get("municipio") or dados.get("nomeMunicipio") or ""

        partes = [f"Título n° {numero_titulo} — situação: {status.upper() or 'IRREGULAR'}"]
        if municipio:
            partes.append(f"Município: {municipio}")
        if zona and secao:
            partes.append(f"Zona {zona} / Seção {secao}")

        logger.info("tse_pf: título irregular para CPF %s*** (status=%s)", cpf[:3], status)

        return [{
            "fonte": self.fonte,
            "categoria": "cadastral",
            "severidade": "atencao",
            "titulo": f"TSE — título eleitoral IRREGULAR: {cpf_fmt}",
            "descricao": ". ".join(partes),
            "url_fonte": "https://www.tse.jus.br/servicos-eleitorais/autoatendimento-eleitoral",
            "referencia_id": str(numero_titulo),
            "is_novo": True,
        }]

    def resumo_pf(self, cpf: str, nome: str | None = None) -> dict | None:
        cpf_d = _strip(cpf)
        titulo = "Situação Eleitoral (TSE)"

        # Fonte primária: certidão do TSE via Infosimples.
        cert = _via_infosimples(cpf_d)
        if cert is not None:
            quitado = cert.get("conseguiu_emitir_certidao_negativa")
            if quitado is None:
                quitado = not cert.get("consta")
            numero = cert.get("certidao_codigo") or cert.get("certidao") or ""
            return {
                "fonte": self.fonte, "categoria": "cadastral",
                "status": "limpo" if quitado else "alerta",
                "titulo_secao": titulo,
                "resumo": (
                    f"Quitação eleitoral regular — certidão nº {numero}" if quitado and numero
                    else "Quitação eleitoral regular" if quitado
                    else "Título eleitoral irregular ou pendente"
                ),
                "detalhes": {"certidao": numero, "resposta": cert},
            }

        # Sem certidão emitida não se afirma regularidade. O Direct Data, fonte
        # anterior, responde 403 e devolvia "título regular (quitado)" para
        # qualquer CPF.
        alertas = self.consultar_cnpj(cpf, razao_social=nome)
        if not alertas:
            return {
                "fonte": self.fonte, "categoria": "cadastral", "status": "pendente",
                "titulo_secao": titulo,
                "resumo": "Não foi possível consultar — certidão do TSE não emitida",
                "detalhes": {},
            }
        return {
            "fonte": self.fonte,
            "categoria": "cadastral",
            "status": "alerta",
            "titulo_secao": titulo,
            "resumo": alertas[0].get("titulo", "Título irregular"),
            "detalhes": {"total_irregulares": len(alertas),
                         "alertas": [a.get("descricao", "") for a in alertas[:2]]},
        }
