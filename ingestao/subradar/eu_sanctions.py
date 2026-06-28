"""
Conector: EU Consolidated Financial Sanctions List

Fonte: European Commission — Financial Sanctions Files (FSF)
URL: https://webgate.ec.europa.eu/fsd/fsf/public/files/xmlFullSanctionsList_1_1/content
Formato: XML público, sem autenticação
Frequência: atualizado continuamente (monitora terrorismo, RU, Bielorrússia, Iran, etc.)

Alertas gerados:
  - Entidade encontrada na lista de sanções financeiras da UE (CRÍTICO)
"""
from __future__ import annotations

import logging
import re
import time

import requests

try:
    from xml.etree import cElementTree as ET
except ImportError:
    from xml.etree import ElementTree as ET

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.eu_sanctions")

EU_XML_URL = (
    "https://webgate.ec.europa.eu/fsd/fsf/public/files/xmlFullSanctionsList_1_1/content"
)

_cache_index: dict[str, list[dict]] | None = None
_cache_ts: float = 0.0
_CACHE_TTL = 3600 * 6  # 6h


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", str(cnpj or ""))


def _fmt(cnpj: str) -> str:
    c = _strip(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _normalize(s: str) -> str:
    return re.sub(r"[\s\.\-/]", "", s.upper())


def _load_eu() -> dict[str, list[dict]]:
    global _cache_index, _cache_ts
    if _cache_index is not None and time.monotonic() - _cache_ts < _CACHE_TTL:
        return _cache_index

    logger.info("EU Sanctions: baixando XML…")
    try:
        resp = requests.get(
            EU_XML_URL,
            timeout=120,
            headers={"User-Agent": "Subradar/1.0 (dados-publicos; contato@subradar.com.br)"},
        )
        resp.raise_for_status()
        content = resp.content
    except Exception as e:
        logger.error("EU Sanctions: falha ao baixar XML: %s", e)
        _cache_index = _cache_index or {}
        return _cache_index

    index: dict[str, list[dict]] = {}

    try:
        root = ET.fromstring(content)
        # Remove namespace prefix for easier parsing
        ns = ""
        if root.tag.startswith("{"):
            ns = root.tag.split("}")[0] + "}"

        def tag(t: str) -> str:
            return f"{ns}{t}"

        for entity in root.iter(tag("sanctionEntity")):
            # Collect names from nameAlias elements
            names = []
            for alias in entity.iter(tag("nameAlias")):
                n = alias.get("wholeName") or alias.get("lastName") or alias.get("firstName") or ""
                n = n.strip()
                if n:
                    names.append(n)

            # Regulation info
            regulation = entity.find(tag("regulation"))
            reg_programme = ""
            if regulation is not None:
                reg_programme = regulation.get("programme", "") or ""

            entity_data = {
                "nome": names[0] if names else "N/I",
                "aliases": names[1:],
                "regime": reg_programme,
                "tipo": entity.get("subjectType", ""),
                "uid": entity.get("logicalId", ""),
            }

            # Index by document numbers
            for ident in entity.iter(tag("identification")):
                number = ident.get("number", "").strip()
                id_type = ident.get("identificationTypeCode", "").strip()
                if number and len(number) >= 5:
                    digits = _strip(number)
                    if 5 <= len(digits) <= 20:
                        norm = _normalize(digits)
                        index.setdefault(norm, []).append({**entity_data, "tipo_doc": id_type, "numero_doc": number})
                    # Also index raw normalized
                    norm_raw = _normalize(number)
                    index.setdefault(norm_raw, []).append({**entity_data, "tipo_doc": id_type, "numero_doc": number})

            # Index by names
            for name in names:
                if len(name) > 4:
                    name_key = f"NAME:{_normalize(name)}"
                    index.setdefault(name_key, []).append(entity_data)

    except Exception as e:
        logger.error("EU Sanctions: erro ao parsear XML: %s", e)

    _cache_index = index
    _cache_ts = time.monotonic()
    logger.info("EU Sanctions: %d identificadores indexados", len(index))
    return index


class EUSanctionsConnector(SubradarSource):
    fonte = "eu_sanctions"
    request_delay = 0.0

    def consultar_cnpj(self, cnpj: str, razao_social: str | None = None) -> list[dict]:
        cnpj_digits = _strip(cnpj)
        cnpj_fmt = _fmt(cnpj_digits)
        ciclo = _ciclo_atual()

        index = _load_eu()
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
                "titulo": f"Sanção EU — {regime}: {h.get('nome', 'N/I')}",
                "descricao": (
                    f"Entidade encontrada na EU Consolidated Financial Sanctions List. "
                    f"Regime: {regime}. Tipo: {h.get('tipo', 'N/I')}. "
                    f"Operações com esta entidade podem violar sanções da União Europeia."
                ),
                "referencia_id": h.get("uid"),
                "url_fonte": "https://www.sanctionsmap.eu/",
                "is_novo": True,
            })

        logger.info("EU Sanctions: %d alertas para %s", len(alertas), cnpj_fmt)
        return alertas
