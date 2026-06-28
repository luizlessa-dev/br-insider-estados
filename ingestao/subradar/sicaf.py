"""
Conector: SICAF — Fornecedores Impedidos/Suspensos para Contratos Federais

Fonte: Portal de Compras do Governo Federal (compras.dados.gov.br)
API: /fornecedores/v1/ocorrencias.json?cnpj={cnpj_digits}
Frequência: consulta por CNPJ a cada execução (cache 12h por CNPJ)

Alertas gerados por:
  - Impedimento ou inidoneidade → critico
  - Suspensão → atencao
  - Outras ocorrências → info

Fallback: /fornecedores/v1/fornecedores.json?cnpj={cnpj_digits} para verificar situacao_fornecedor
"""
from __future__ import annotations

import logging
import re
import time
from typing import Any

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.sicaf")

OCORRENCIAS_URL = "https://compras.dados.gov.br/fornecedores/v1/ocorrencias.json"
FORNECEDORES_URL = "https://compras.dados.gov.br/fornecedores/v1/fornecedores.json"

_cache: dict[str, list[dict]] = {}
_cache_ts: dict[str, float] = {}
_CACHE_TTL = 3600 * 12  # 12h


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", str(cnpj or ""))


def _fmt(cnpj: str) -> str:
    c = _strip(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _severidade(tipo: str) -> str:
    t = tipo.upper()
    if any(k in t for k in ("IMPEDIMENTO", "INIDONEIDADE", "INIDÔNEO", "INIDÔNEA")):
        return "critico"
    if "SUSPEN" in t:
        return "atencao"
    return "info"


def _consultar_ocorrencias(session, cnpj_digits: str) -> list[dict] | None:
    """Retorna lista de ocorrências ou None em caso de erro irrecuperável."""
    try:
        resp = session.get(OCORRENCIAS_URL, params={"cnpj": cnpj_digits}, timeout=20)
        if resp.status_code == 404:
            return []
        resp.raise_for_status()
        data = resp.json()
        # API pode retornar dict com "_embedded" ou lista direta
        if isinstance(data, list):
            return data
        if isinstance(data, dict):
            embedded = data.get("_embedded", {})
            if isinstance(embedded, dict):
                for v in embedded.values():
                    if isinstance(v, list):
                        return v
            return data.get("ocorrencias", data.get("items", []))
        return []
    except Exception as e:
        logger.debug("SICAF ocorrencias falhou para %s: %s", cnpj_digits, e)
        return None


def _consultar_situacao_fallback(session, cnpj_digits: str) -> list[dict]:
    """Fallback: verifica situacao_fornecedor via endpoint de fornecedores."""
    try:
        resp = session.get(FORNECEDORES_URL, params={"cnpj": cnpj_digits}, timeout=20)
        if not resp.ok:
            return []
        data = resp.json()
        # Navega embedded HAL ou lista
        itens: list[dict] = []
        if isinstance(data, list):
            itens = data
        elif isinstance(data, dict):
            embedded = data.get("_embedded", {})
            for v in (embedded.values() if isinstance(embedded, dict) else []):
                if isinstance(v, list):
                    itens = v
                    break
            if not itens:
                itens = [data] if data.get("cnpj") else []

        resultados = []
        for item in itens:
            situacao = item.get("situacao_fornecedor", item.get("situacao", ""))
            if situacao and situacao.upper() != "ATIVO":
                resultados.append({
                    "tipo_ocorrencia": "SITUACAO_IRREGULAR",
                    "descricao_ocorrencia": f"Situação do fornecedor: {situacao}",
                    "data_inicio_ocorrencia": None,
                    "data_fim_ocorrencia": None,
                    "orgao": item.get("orgao_vinculador", ""),
                    "razao_social": item.get("razao_social", ""),
                    "_via_fallback": True,
                })
        return resultados
    except Exception as e:
        logger.debug("SICAF fallback falhou para %s: %s", cnpj_digits, e)
        return []


class SICAFConnector(SubradarSource):
    fonte = "sicaf"
    request_delay = 0.5

    def consultar_cnpj(self, cnpj: str) -> list[dict]:
        cnpj_digits = _strip(cnpj)
        cnpj_fmt = _fmt(cnpj_digits)
        ciclo = _ciclo_atual()

        # Cache por CNPJ
        now = time.monotonic()
        if cnpj_digits in _cache and now - _cache_ts.get(cnpj_digits, 0) < _CACHE_TTL:
            ocorrencias = _cache[cnpj_digits]
        else:
            ocorrencias = _consultar_ocorrencias(self._session, cnpj_digits)
            if ocorrencias is None:
                # Endpoint falhou — tenta fallback
                ocorrencias = _consultar_situacao_fallback(self._session, cnpj_digits)
            _cache[cnpj_digits] = ocorrencias
            _cache_ts[cnpj_digits] = now

        if not ocorrencias:
            return []

        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, ocorrencias)
        if not mudou:
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt,
            "fonte": self.fonte,
            "ciclo": ciclo,
            "hash_dados": hash_novo,
            "dados": {"ocorrencias": ocorrencias},
        }])

        alertas = []
        for oc in ocorrencias:
            tipo = oc.get("tipo_ocorrencia", "OCORRÊNCIA SICAF")
            descricao = oc.get("descricao_ocorrencia", "")
            data_inicio = oc.get("data_inicio_ocorrencia", "")
            data_fim = oc.get("data_fim_ocorrencia", "")
            orgao = oc.get("orgao", "")
            sev = _severidade(tipo)

            texto = f"SICAF — {tipo}"
            if descricao:
                texto += f": {descricao}"
            if orgao:
                texto += f" | Órgão: {orgao}"
            if data_inicio:
                texto += f" | Início: {data_inicio}"
            if data_fim:
                texto += f" | Fim: {data_fim}"

            alertas.append({
                "cnpj": cnpj_fmt,
                "ciclo": ciclo,
                "fonte": self.fonte,
                "categoria": "compliance",
                "severidade": sev,
                "titulo": f"SICAF — {tipo}",
                "descricao": texto,
                "url_fonte": "https://www.comprasgovernamentais.gov.br/index.php/fornecedor/sicaf",
                "is_novo": True,
            })

        return alertas
