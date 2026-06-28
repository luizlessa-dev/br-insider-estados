"""
Conector: World Bank Debarment List

Fonte: World Bank / OpenSanctions
URL: https://data.opensanctions.org/datasets/latest/worldbank_debarred/targets.simple.csv
Formato: CSV público, sem autenticação
Frequência: cache de 12h — atualizado pelo World Bank conforme novas debarrings

Alertas gerados:
  - Empresa impedida de contratar com o Banco Mundial (CRÍTICO)

Nota: matching por razão social (sem CNPJ disponível); aceita parâmetro razao_social.
"""
from __future__ import annotations

import csv
import io
import logging
import re
import time

import requests

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.worldbank_debarment")

WB_CSV_URL = (
    "https://data.opensanctions.org/datasets/latest/worldbank_debarred/targets.simple.csv"
)

_cache_index: dict[str, list[dict]] | None = None
_cache_ts: float = 0.0
_CACHE_TTL = 3600 * 12  # 12h


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", str(cnpj or ""))


def _fmt(cnpj: str) -> str:
    c = _strip(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _normalize(s: str) -> str:
    return re.sub(r"[\s\.\-/&,'\"]", "", s.upper())


def _load_wb() -> dict[str, list[dict]]:
    global _cache_index, _cache_ts
    if _cache_index is not None and time.monotonic() - _cache_ts < _CACHE_TTL:
        return _cache_index

    logger.info("WorldBank Debarment: baixando CSV…")
    try:
        resp = requests.get(
            WB_CSV_URL,
            timeout=60,
            headers={"User-Agent": "Subradar/1.0 (dados-publicos; contato@subradar.com.br)"},
        )
        resp.raise_for_status()
        content = resp.content.decode("utf-8", errors="replace")
    except Exception as e:
        logger.error("WorldBank Debarment: falha ao baixar CSV: %s", e)
        _cache_index = _cache_index or {}
        return _cache_index

    index: dict[str, list[dict]] = {}

    try:
        reader = csv.DictReader(io.StringIO(content))
        for row in reader:
            entity_id = (row.get("id") or "").strip()
            name = (row.get("name") or "").strip()
            aliases_raw = (row.get("aliases") or "").strip()
            countries = (row.get("countries") or "").strip()
            topics = (row.get("topics") or "").strip()
            datasets = (row.get("datasets") or "").strip()

            entity_data = {
                "nome": name,
                "paises": countries,
                "topicos": topics,
                "datasets": datasets,
                "uid": entity_id,
            }

            # Index by normalized name
            all_names = [name]
            if aliases_raw:
                all_names.extend(a.strip() for a in aliases_raw.split(";") if a.strip())

            for n in all_names:
                if len(n) > 4:
                    name_key = f"NAME:{_normalize(n)}"
                    index.setdefault(name_key, []).append(entity_data)

    except Exception as e:
        logger.error("WorldBank Debarment: erro ao parsear CSV: %s", e)

    _cache_index = index
    _cache_ts = time.monotonic()
    logger.info("WorldBank Debarment: %d nomes indexados", len(index))
    return index


class WorldBankDebarmentConnector(SubradarSource):
    fonte = "worldbank_debarment"
    request_delay = 0.0

    def consultar_cnpj(self, cnpj: str, razao_social: str | None = None) -> list[dict]:
        cnpj_digits = _strip(cnpj)
        cnpj_fmt = _fmt(cnpj_digits)
        ciclo = _ciclo_atual()

        if not razao_social:
            # Sem razão social não há como fazer o match
            return []

        index = _load_wb()
        hits: list[dict] = []

        rs_key = f"NAME:{_normalize(razao_social)}"
        hits.extend(index.get(rs_key, []))

        if not hits:
            return []

        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, hits)
        if not mudou:
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt,
            "fonte": self.fonte,
            "ciclo": ciclo,
            "hash_dados": hash_novo,
            "dados": {"total": len(hits), "entidades": hits},
        }])

        alertas = []
        for h in hits:
            alertas.append({
                "cnpj": cnpj_fmt,
                "ciclo": ciclo,
                "fonte": self.fonte,
                "categoria": "internacional",
                "severidade": "critico",
                "titulo": f"Impedimento Banco Mundial: {h.get('nome', 'N/I')}",
                "descricao": (
                    f"Empresa impedida de contratar com o Banco Mundial (debarment). "
                    f"Nome: {h.get('nome', 'N/I')}. "
                    f"Países: {h.get('paises', 'N/I')}. "
                    f"Tópicos: {h.get('topicos', 'N/I')}."
                ),
                "referencia_id": h.get("uid"),
                "url_fonte": "https://www.worldbank.org/en/projects-operations/procurement/debarred-firms",
                "is_novo": True,
            })

        logger.info("WorldBank Debarment: %d alertas para %s", len(alertas), cnpj_fmt)
        return alertas
