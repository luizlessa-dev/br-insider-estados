"""
Conector: PREVIC — Supervisão de Entidades Fechadas de Previdência Complementar

Fonte: dadosabertos.previc.gov.br (CKAN)
Dataset: Medidas Administrativas (auto de infração, regime especial, liquidação)

Estratégia:
  1. Busca via CKAN package_search por "medidas administrativas"
  2. Localiza resource em formato CSV ou JSON
  3. Baixa e indexa por CNPJ
  4. Cache do CSV inteiro em memória por 24h

Alertas gerados por:
  - liquidacao extrajudicial / regime especial → critico
  - auto de infracao / advertencia → atencao
  - outros → info

Retorna [] graciosamente se CKAN indisponível ou CNPJ não encontrado.
"""
from __future__ import annotations

import csv
import io
import logging
import re
import time
from typing import Any

import requests

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.previc")

CKAN_BASE = "https://dadosabertos.previc.gov.br"
PACKAGE_SEARCH_URL = f"{CKAN_BASE}/api/3/action/package_search"

_cache_index: dict[str, list[dict]] | None = None
_cache_ts: float = 0.0
_CACHE_TTL = 3600 * 24  # 24h


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", str(cnpj or ""))


def _fmt(cnpj: str) -> str:
    c = _strip(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _severidade(tipo: str) -> str:
    t = tipo.lower()
    if any(k in t for k in ("liquidacao", "liquidação", "regime especial", "intervenção", "intervencao")):
        return "critico"
    if any(k in t for k in ("auto de infracao", "auto de infração", "advertencia", "advertência", "multa")):
        return "atencao"
    return "info"


def _discover_csv_url() -> str | None:
    """Descobre a URL do CSV de medidas administrativas via CKAN."""
    try:
        resp = requests.get(
            PACKAGE_SEARCH_URL,
            params={"q": "medidas administrativas", "rows": 5},
            timeout=20,
            headers={"User-Agent": "Subradar/1.0 (dados-publicos; contato@subradar.com.br)"},
        )
        if not resp.ok:
            return None
        result = resp.json().get("result", {})
        packages = result.get("results", [])
        for pkg in packages:
            for resource in pkg.get("resources", []):
                fmt = resource.get("format", "").upper()
                url = resource.get("url", "")
                if fmt in ("CSV", "JSON") and url:
                    logger.info("PREVIC: resource encontrado: %s", url)
                    return url
    except Exception as e:
        logger.debug("PREVIC: package_search falhou: %s", e)
    return None


def _load_previc() -> dict[str, list[dict]]:
    """Baixa CSV e indexa por CNPJ (14 dígitos)."""
    global _cache_index, _cache_ts

    now = time.monotonic()
    if _cache_index is not None and now - _cache_ts < _CACHE_TTL:
        return _cache_index

    csv_url = _discover_csv_url()
    if not csv_url:
        logger.warning(
            "PREVIC: portal dadosabertos.previc.gov.br offline (HTTP 503 em jul/2026). "
            "Retornando vazio — próxima tentativa em 1h."
        )
        _cache_index = _cache_index or {}
        _cache_ts = now - _CACHE_TTL + 3600  # retry em 1h, não 24h
        return _cache_index

    logger.info("PREVIC: baixando dataset de medidas administrativas…")
    try:
        resp = requests.get(
            csv_url, timeout=60,
            headers={"User-Agent": "Subradar/1.0 (dados-publicos; contato@subradar.com.br)"},
        )
        resp.raise_for_status()
        content = resp.content.decode("utf-8", errors="replace")
    except Exception as e:
        logger.error("PREVIC: falha ao baixar CSV: %s", e)
        _cache_index = _cache_index or {}
        return _cache_index

    index: dict[str, list[dict]] = {}
    try:
        # Tenta CSV com ; depois com ,
        sample = content[:1000]
        sep = ";" if sample.count(";") > sample.count(",") else ","
        reader = csv.DictReader(io.StringIO(content), delimiter=sep)
        for row in reader:
            # Tenta variações comuns de coluna CNPJ
            cnpj_raw = (
                row.get("cnpj") or row.get("CNPJ") or
                row.get("cnpj_entidade") or row.get("nr_cnpj") or ""
            )
            cnpj_digits = _strip(cnpj_raw)
            if len(cnpj_digits) != 14:
                continue
            entry = {
                "razao_social": row.get("razao_social") or row.get("nome_entidade") or row.get("ds_razao_social", ""),
                "tipo_medida": row.get("tipo_medida") or row.get("ds_tipo_medida") or row.get("tipo_ocorrencia", ""),
                "descricao": row.get("descricao") or row.get("ds_descricao") or row.get("ds_medida", ""),
                "data_inicio": row.get("data_inicio") or row.get("dt_inicio") or row.get("data_publicacao", ""),
                "situacao": row.get("situacao") or row.get("ds_situacao", ""),
            }
            index.setdefault(cnpj_digits, []).append(entry)
    except Exception as e:
        logger.error("PREVIC: erro ao parsear CSV: %s", e)

    _cache_index = index
    _cache_ts = now
    logger.info("PREVIC: %d CNPJs indexados", len(index))
    return index


class PREVICConnector(SubradarSource):
    fonte = "previc"
    request_delay = 0.0  # dados locais após cache

    def consultar_cnpj(self, cnpj: str) -> list[dict]:
        cnpj_digits = _strip(cnpj)
        cnpj_fmt = _fmt(cnpj_digits)
        ciclo = _ciclo_atual()

        index = _load_previc()
        medidas = index.get(cnpj_digits)
        if not medidas:
            return []

        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, medidas)
        if not mudou:
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt,
            "fonte": self.fonte,
            "ciclo": ciclo,
            "hash_dados": hash_novo,
            "dados": {"medidas": medidas},
        }])

        alertas = []
        for m in medidas:
            tipo = m.get("tipo_medida", "MEDIDA ADMINISTRATIVA")
            descricao = m.get("descricao", "")
            data = m.get("data_inicio", "")
            situacao = m.get("situacao", "")
            sev = _severidade(tipo)

            texto = f"PREVIC — {tipo}"
            if descricao:
                texto += f": {descricao}"
            if situacao:
                texto += f" | Situação: {situacao}"
            if data:
                texto += f" | Data: {data}"

            alertas.append({
                "cnpj": cnpj_fmt,
                "ciclo": ciclo,
                "fonte": self.fonte,
                "categoria": "regulatorio",
                "severidade": sev,
                "titulo": f"PREVIC — {tipo}",
                "descricao": texto,
                "url_fonte": "https://dadosabertos.previc.gov.br",
                "is_novo": True,
            })

        return alertas
