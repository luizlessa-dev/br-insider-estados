"""
Conector: BigDataCorp — Ondemand Polícia Civil — Antecedentes Criminais (PF)

Cobertura: BA, CE, ES, MG, MS, MT, PA, PE, RR, RS, SC, SP (12 estados).
Se o estado do consultado não estiver coberto, retorna status -2007 e não é cobrado.
Custo: por consulta, sem testes gratuitos. Configurar permissão em:
  BigDataCorp → Configurações da Plataforma → APIs Ondemand

Env var: BIGDATA_CORP_TOKEN
Docs: https://docs.bigdatacorp.com.br/plataforma/reference/ondemand-policia-civil-antecedentes-criminais-pessoa
"""
from __future__ import annotations

import logging
import os
import re

import requests

from .base import SubradarSource

logger = logging.getLogger("subradar.policia_civil_pf")

_BDC_TOKEN = os.environ.get("BIGDATA_CORP_TOKEN", "")
_BASE = "https://plataforma.bigdatacorp.com.br"
_DATASET = "ondemand_policia_civil_antecedentes_criminais_pessoa"

# Estados cobertos pelo dataset (para log/documentação)
_ESTADOS_COBERTOS = {"BA", "CE", "ES", "MG", "MS", "MT", "PA", "PE", "RR", "RS", "SC", "SP"}

# Códigos de status BDC que indicam ausência de dados (não cobrado)
_STATUS_SEM_DADOS = {-2007, -2008}


def _strip(cpf: str) -> str:
    return re.sub(r"\D", "", str(cpf or ""))


def _consultar_pc(cpf: str, nome: str | None) -> dict:
    """Chama o endpoint Ondemand Polícia Civil da BigDataCorp."""
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
            logger.debug("PoliciaСivil BDC: HTTP %d", resp.status_code)
            return {}
        data = resp.json()
        datasets = data.get("Result", [{}])[0].get("Result", {})
        result = datasets.get(_DATASET, {})

        # Verifica status BDC — sem dados ou estado não coberto
        status_code = result.get("StatusCode") or result.get("status_code")
        if status_code in _STATUS_SEM_DADOS:
            logger.debug("PoliciaСivil BDC: status %d (estado não coberto ou sem dados)", status_code)
            return {}

        return result
    except Exception as e:
        logger.debug("PoliciaСivil BDC: %s", e)
        return {}


class PolicíaCivilPFConnector(SubradarSource):
    """
    Antecedentes criminais nas Polícias Civis estaduais via BigDataCorp Ondemand.
    Cobertura: BA, CE, ES, MG, MS, MT, PA, PE, RR, RS, SC, SP.
    Gracioso se token ausente ou estado não coberto.
    """
    fonte = "policia_civil_pf"
    request_delay = 1.5

    def consultar_cnpj(self, cnpj_or_cpf: str, razao_social: str | None = None, **_) -> list[dict]:
        if not _BDC_TOKEN:
            logger.debug("policia_civil_pf: BIGDATA_CORP_TOKEN ausente — pulando")
            return []

        cpf = _strip(cnpj_or_cpf)
        if len(cpf) != 11:
            return []

        dados = _consultar_pc(cpf, razao_social)
        if not dados:
            return []

        ocorrencias = dados.get("Ocorrencias") or dados.get("ocorrencias") or []
        if not ocorrencias:
            logger.debug("policia_civil_pf: sem ocorrências para CPF %s***", cpf[:3])
            return []

        cpf_fmt = f"{cpf[:3]}.{cpf[3:6]}.{cpf[6:9]}-{cpf[9:]}"
        alertas = []
        for oc in ocorrencias:
            tipo = oc.get("TipoOcorrencia") or oc.get("tipo") or "Ocorrência"
            descricao = oc.get("Descricao") or oc.get("descricao") or ""
            data_oc = oc.get("DataOcorrencia") or oc.get("data") or ""
            uf = oc.get("UF") or oc.get("uf") or ""
            delegacia = oc.get("Delegacia") or oc.get("delegacia") or ""

            partes = [f"Tipo: {tipo}"]
            if descricao:
                partes.append(descricao)
            if delegacia:
                partes.append(f"Delegacia: {delegacia}")
            if data_oc:
                partes.append(f"Data: {data_oc}")
            if uf:
                partes.append(f"UF: {uf}")

            alertas.append({
                "fonte": self.fonte,
                "categoria": "judicial",
                "severidade": "critico",
                "titulo": f"Polícia Civil — antecedente criminal: {cpf_fmt}",
                "descricao": ". ".join(partes),
                "url_fonte": "https://www.bigdatacorp.com.br",
                "is_novo": True,
            })

        logger.info("policia_civil_pf: %d ocorrência(s) para CPF %s***", len(alertas), cpf[:3])
        return alertas

    def resumo_pf(self, cpf: str, nome: str | None = None) -> dict | None:
        if not _BDC_TOKEN:
            return None
        digits = _strip(cpf)
        if len(digits) != 11:
            return None
        dados = _consultar_pc(digits, nome)
        if not dados:
            # Estado não coberto — retorna nao_aplicavel em vez de limpo
            return {
                "fonte": self.fonte,
                "categoria": "judicial",
                "status": "nao_aplicavel",
                "titulo_secao": "Antecedentes Criminais — Polícia Civil Estadual",
                "resumo": f"Estado não coberto (cobertura: {', '.join(sorted(_ESTADOS_COBERTOS))})",
                "detalhes": {"estados_cobertos": sorted(_ESTADOS_COBERTOS)},
            }
        ocorrencias = dados.get("Ocorrencias") or dados.get("ocorrencias") or []
        n = len(ocorrencias)
        return {
            "fonte": self.fonte,
            "categoria": "judicial",
            "status": "critico" if n else "limpo",
            "titulo_secao": "Antecedentes Criminais — Polícia Civil Estadual",
            "resumo": f"{n} ocorrência(s) encontrada(s) na Polícia Civil" if n else "Nenhum antecedente na Polícia Civil",
            "detalhes": {"total": n, "estados_cobertos": sorted(_ESTADOS_COBERTOS), "ocorrencias": ocorrencias[:5]},
        }
