"""
Conector: UK Sanctions List — FCDO (Foreign Commonwealth & Development Office)

Fonte: sanctionslist.fcdo.gov.uk
Formato: CSV público, sem autenticação
URL: https://sanctionslist.fcdo.gov.uk/docs/UK-Sanctions-List.csv
Frequência: atualizada continuamente (regime pós-Brexit)

Cobre: todas as listas de sanções do Reino Unido, incluindo:
  - Global Human Rights
  - Global Anti-Corruption
  - Counter-Terrorism
  - Russia (maior lista pós-2022)
  - Belarus, Iran, Myanmar, etc.
"""
from __future__ import annotations

import csv
import io
import logging
import re
import time

import requests

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.uk_sanctions")

UK_CSV_URL = "https://sanctionslist.fcdo.gov.uk/docs/UK-Sanctions-List.csv"

_cache_index: dict[str, list[dict]] | None = None
_cache_ts: float = 0.0
_CACHE_TTL = 3600 * 6


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", str(cnpj or ""))


def _fmt(cnpj: str) -> str:
    c = _strip(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _normalize(s: str) -> str:
    return re.sub(r"[\s\.\-/]", "", s.upper())


def _load_uk() -> dict[str, list[dict]]:
    global _cache_index, _cache_ts
    if _cache_index is not None and time.monotonic() - _cache_ts < _CACHE_TTL:
        return _cache_index

    logger.info("UK Sanctions: baixando CSV…")
    try:
        resp = requests.get(
            UK_CSV_URL,
            timeout=60,
            headers={"User-Agent": "Subradar/1.0 (dados-publicos; contato@subradar.com.br)"},
        )
        resp.raise_for_status()
        content = resp.content.decode("utf-8-sig", errors="replace")
    except Exception as e:
        logger.error("UK Sanctions: falha ao baixar CSV: %s", e)
        _cache_index = _cache_index or {}
        return _cache_index

    index: dict[str, list[dict]] = {}

    try:
        # O CSV da FCDO inclui uma linha extra antes do header real:
        #   Line 0: "Report Date: DD-Mon-YYYY"
        #   Line 1: header real (Last Updated, Unique ID, ...)
        # csv.DictReader leria a linha 0 como header, gerando chaves None.
        lines = content.splitlines()
        # Descarta linhas que não são o header real (não começam com "Last Updated" ou similar)
        header_idx = 0
        for i, line in enumerate(lines):
            stripped = line.strip()
            if stripped.startswith("Last Updated") or stripped.startswith("Unique ID"):
                header_idx = i
                break
        content_clean = "\n".join(lines[header_idx:])

        reader = csv.DictReader(io.StringIO(content_clean))
        for row in reader:
            # Normaliza chaves
            r = {k.strip().lower().replace(" ", "_"): (v or "").strip() for k, v in row.items()}

            name = r.get("name_6", "") or r.get("name_1", "") or r.get("name", "")
            regime = r.get("regime", "") or r.get("sanctions_regime", "")
            entity_type = r.get("entity_type", "") or r.get("group_type", "")
            uid = r.get("group_id", "") or r.get("id", "")
            last_updated = r.get("last_updated", "") or r.get("date_listed", "")

            entity_data = {
                "nome": name,
                "regime": regime,
                "tipo": entity_type,
                "uid": uid,
                "ultima_atualizacao": last_updated,
            }

            # Indexa por todos os campos que possam conter CNPJ/tax ID
            for key, val in r.items():
                if not val or len(val) < 5:
                    continue
                # Campos de identificação numérica
                if any(t in key for t in ("id", "number", "registration", "tax", "fiscal", "cnpj")):
                    digits = _strip(val)
                    if 8 <= len(digits) <= 14:
                        norm = _normalize(digits)
                        index.setdefault(norm, []).append(entity_data)

            # Indexa pelo nome normalizado (busca por razão social)
            if name and len(name) > 4:
                name_key = f"NAME:{_normalize(name)}"
                index.setdefault(name_key, []).append(entity_data)

    except Exception as e:
        logger.error("UK Sanctions: erro ao parsear CSV: %s", e)

    _cache_index = index
    _cache_ts = time.monotonic()
    logger.info("UK Sanctions: %d identificadores indexados", len(index))
    return index


class UKSanctionsConnector(SubradarSource):
    fonte = "uk_sanctions"
    request_delay = 0.0

    def consultar_cnpj(self, cnpj: str, razao_social: str | None = None) -> list[dict]:
        cnpj_digits = _strip(cnpj)
        cnpj_fmt = _fmt(cnpj_digits)
        ciclo = _ciclo_atual()

        index = _load_uk()
        hits: list[dict] = []

        # Busca pelo CNPJ (digits e formatado)
        for key in (_normalize(cnpj_digits), _normalize(cnpj_fmt)):
            for h in index.get(key, []):
                if h not in hits:
                    hits.append(h)

        # Busca por razão social
        if razao_social and not hits:
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
            regime = h.get("regime", "N/I")
            alertas.append({
                "cnpj": cnpj_fmt,
                "ciclo": ciclo,
                "fonte": self.fonte,
                "categoria": "internacional",
                "severidade": "critico",
                "titulo": f"Sanção Reino Unido — {regime}: {h.get('nome', 'N/I')}",
                "descricao": (
                    f"Entidade encontrada na UK Sanctions List (FCDO). "
                    f"Regime: {regime}. Tipo: {h.get('tipo', 'N/I')}. "
                    f"Atualizado em: {h.get('ultima_atualizacao', 'N/I')}. "
                    f"Operações com esta entidade podem violar sanções britânicas."
                ),
                "referencia_id": h.get("uid"),
                "url_fonte": "https://www.gov.uk/government/publications/the-uk-sanctions-list",
                "is_novo": True,
            })

        logger.info("UK Sanctions: %d alertas para %s", len(alertas), cnpj_fmt)
        return alertas
