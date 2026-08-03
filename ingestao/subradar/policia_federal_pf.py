"""
Conector: BigDataCorp — Ondemand Polícia Federal — Antecedentes Criminais (PF)

Cobertura: nacional (todos os estados).
Custo: por consulta, sem testes gratuitos. Configurar permissão em:
  BigDataCorp → Configurações da Plataforma → APIs Ondemand

Env var: BIGDATA_CORP_TOKEN
Docs: https://docs.bigdatacorp.com.br/plataforma/reference/ondemand-policia-federal-antecedentes-criminais-pessoa
"""
from __future__ import annotations

import logging
import os
import re

import requests

from .base import SubradarSource

logger = logging.getLogger("subradar.policia_federal_pf")

_BDC_TOKEN = os.environ.get("BIGDATA_CORP_TOKEN", "")
_BASE = "https://plataforma.bigdatacorp.com.br"
_DATASET = "ondemand_policia_federal_antecedentes_criminais_pessoa"


def _strip(cpf: str) -> str:
    return re.sub(r"\D", "", str(cpf or ""))


def _consultar_pf(cpf: str, nome: str | None) -> dict:
    """Chama o endpoint Ondemand PF da BigDataCorp."""
    try:
        payload: dict = {"q": f"doc{{{cpf}}}"}
        if nome:
            payload["nome"] = nome
        resp = requests.post(
            f"{_BASE}/pessoas",
            json={"Datasets": _DATASET, **payload},
            headers={
                "AccessToken": _BDC_TOKEN,
                "TokenId": _BDC_TOKEN,
                "content-type": "application/json",
            },
            timeout=40,
        )
        if not resp.ok:
            logger.debug("PoliciaFederal BDC: HTTP %d", resp.status_code)
            return {}
        data = resp.json()
        datasets = data.get("Result", [{}])[0].get("Result", {})
        return datasets.get(_DATASET, {})
    except Exception as e:
        logger.debug("PoliciaFederal BDC: %s", e)
        return {}


class PoliciaFederalPFConnector(SubradarSource):
    """
    Antecedentes criminais na Polícia Federal via BigDataCorp Ondemand.
    Cobertura nacional. Gracioso se BIGDATA_CORP_TOKEN ausente.
    """
    fonte = "policia_federal_pf"
    request_delay = 1.5

    def consultar_cnpj(self, cnpj_or_cpf: str, razao_social: str | None = None, **_) -> list[dict]:
        if not _BDC_TOKEN:
            logger.debug("policia_federal_pf: BIGDATA_CORP_TOKEN ausente — pulando")
            return []

        cpf = _strip(cnpj_or_cpf)
        if len(cpf) != 11:
            return []

        dados = _consultar_pf(cpf, razao_social)
        if not dados:
            return []

        ocorrencias = dados.get("Ocorrencias") or dados.get("ocorrencias") or []
        if not ocorrencias:
            logger.debug("policia_federal_pf: sem ocorrências para CPF %s***", cpf[:3])
            return []

        cpf_fmt = f"{cpf[:3]}.{cpf[3:6]}.{cpf[6:9]}-{cpf[9:]}"
        alertas = []
        for oc in ocorrencias:
            tipo = oc.get("TipoOcorrencia") or oc.get("tipo") or "Ocorrência"
            descricao = oc.get("Descricao") or oc.get("descricao") or ""
            data_oc = oc.get("DataOcorrencia") or oc.get("data") or ""
            uf = oc.get("UF") or oc.get("uf") or ""

            partes = [f"Tipo: {tipo}"]
            if descricao:
                partes.append(descricao)
            if data_oc:
                partes.append(f"Data: {data_oc}")
            if uf:
                partes.append(f"UF: {uf}")

            alertas.append({
                "fonte": self.fonte,
                "categoria": "judicial",
                "severidade": "critico",
                "titulo": f"Polícia Federal — antecedente criminal: {cpf_fmt}",
                "descricao": ". ".join(partes),
                "url_fonte": "https://www.gov.br/pf/pt-br",
                "is_novo": True,
            })

        logger.info("policia_federal_pf: %d ocorrência(s) para CPF %s***", len(alertas), cpf[:3])
        return alertas

    def resumo_pf(self, cpf: str, nome: str | None = None) -> dict | None:
        if not _BDC_TOKEN:
            return None
        digits = _strip(cpf)
        if len(digits) != 11:
            return None
        dados = _consultar_pf(digits, nome)
        ocorrencias = dados.get("Ocorrencias") or dados.get("ocorrencias") or []
        n = len(ocorrencias)
        return {
            "fonte": self.fonte,
            "categoria": "judicial",
            "status": "critico" if n else "limpo",
            "titulo_secao": "Antecedentes Criminais — Polícia Federal",
            "resumo": f"{n} ocorrência(s) encontrada(s) na PF" if n else "Nenhum antecedente na Polícia Federal",
            "detalhes": {"total": n, "ocorrencias": ocorrencias[:5]},
        }
