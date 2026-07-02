"""
Conector: EU Consolidated Financial Sanctions List

Fonte primária: European Commission — Financial Sanctions Files (FSF)
  URL: https://webgate.ec.europa.eu/fsd/fsf/public/files/xmlFullSanctionsList_1_1/content
  Status: bloqueado com HTTP 403 desde jun/2026 (scraping bloqueado pela CE)

Fonte fallback: OpenSanctions — espelho público do dataset eu_fsf
  URL: https://data.opensanctions.org/datasets/latest/eu_fsf/entities.ftm.json
  Formato: NDJSON (FollowTheMoney), atualizado diariamente
  Sem autenticação necessária para o dataset eu_fsf público

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

# URL primária (bloqueada desde jun/2026, mas testada primeiro caso desbloqueiem)
EU_XML_URL = "https://webgate.ec.europa.eu/fsd/fsf/public/files/xmlFullSanctionsList_1_1/content"

# Fallback: OpenSanctions espelha eu_fsf diariamente em NDJSON (FTM format)
EU_FTM_URL = "https://data.opensanctions.org/datasets/latest/eu_fsf/entities.ftm.json"

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

    index: dict[str, list[dict]] = {}

    # Tenta fonte primária (XML webgate) — pode estar bloqueada
    loaded = _load_eu_xml(index)
    if not loaded:
        # Fallback: OpenSanctions NDJSON (FTM format), espelha eu_fsf diariamente
        _load_eu_ftm(index)

    _cache_index = index
    _cache_ts = time.monotonic()
    logger.info("EU Sanctions: %d identificadores indexados", len(index))
    return index


def _load_eu_xml(index: dict) -> bool:
    """Tenta carregar via XML oficial da Comissão Europeia. Retorna True se bem-sucedido."""
    logger.info("EU Sanctions: tentando XML via webgate.ec.europa.eu…")
    try:
        resp = requests.get(
            EU_XML_URL,
            timeout=60,
            headers={
                "User-Agent": "Mozilla/5.0 (compatible; Subradar/1.0; +https://subradar.com.br)",
                "Accept": "application/xml, text/xml, */*",
            },
        )
        if resp.status_code != 200 or len(resp.content) < 1000:
            logger.warning("EU Sanctions XML: HTTP %d — usando fallback OpenSanctions", resp.status_code)
            return False
        content = resp.content
    except Exception as e:
        logger.warning("EU Sanctions XML: %s — usando fallback OpenSanctions", e)
        return False

    try:
        root = ET.fromstring(content)
        ns = ""
        if root.tag.startswith("{"):
            ns = root.tag.split("}")[0] + "}"

        def tag(t: str) -> str:
            return f"{ns}{t}"

        for entity in root.iter(tag("sanctionEntity")):
            names = []
            for alias in entity.iter(tag("nameAlias")):
                n = alias.get("wholeName") or alias.get("lastName") or alias.get("firstName") or ""
                n = n.strip()
                if n:
                    names.append(n)
            regulation = entity.find(tag("regulation"))
            reg_programme = regulation.get("programme", "") if regulation is not None else ""
            entity_data = {
                "nome": names[0] if names else "N/I",
                "aliases": names[1:],
                "regime": reg_programme,
                "tipo": entity.get("subjectType", ""),
                "uid": entity.get("logicalId", ""),
            }
            for ident in entity.iter(tag("identification")):
                number = ident.get("number", "").strip()
                id_type = ident.get("identificationTypeCode", "").strip()
                if number and len(number) >= 5:
                    for norm in (_normalize(_strip(number)), _normalize(number)):
                        index.setdefault(norm, []).append({**entity_data, "tipo_doc": id_type, "numero_doc": number})
            for name in names:
                if len(name) > 4:
                    index.setdefault(f"NAME:{_normalize(name)}", []).append(entity_data)
        return bool(index)
    except Exception as e:
        logger.error("EU Sanctions XML: erro ao parsear: %s", e)
        return False


def _load_eu_ftm(index: dict) -> None:
    """
    Fallback: carrega via OpenSanctions FTM NDJSON (eu_fsf dataset público).
    Formato: uma entidade JSON por linha com properties.registrationNumber e properties.name.
    """
    import json as _json
    logger.info("EU Sanctions: carregando via OpenSanctions FTM (fallback)…")
    try:
        resp = requests.get(
            EU_FTM_URL,
            timeout=120,
            stream=True,
            headers={"User-Agent": "Subradar/1.0 (dados-publicos; contato@subradar.com.br)"},
        )
        if resp.status_code != 200:
            logger.error("EU Sanctions FTM: HTTP %d — sem dados disponíveis", resp.status_code)
            return
    except Exception as e:
        logger.error("EU Sanctions FTM: %s", e)
        return

    count = 0
    for raw_line in resp.iter_lines():
        if not raw_line:
            continue
        try:
            ent = _json.loads(raw_line)
        except Exception:
            continue

        props = ent.get("properties", {})
        names = props.get("name", []) + props.get("alias", [])
        reg_numbers = props.get("registrationNumber", [])
        caption = ent.get("caption", names[0] if names else "N/I")

        entity_data = {
            "nome": caption,
            "aliases": names[1:] if names else [],
            "regime": "EU FSF",
            "tipo": ent.get("schema", ""),
            "uid": ent.get("id", ""),
        }

        for number in reg_numbers:
            if number and len(number) >= 5:
                digits = _strip(number)
                for norm in filter(None, [_normalize(digits) if digits else None, _normalize(number)]):
                    index.setdefault(norm, []).append({**entity_data, "numero_doc": number})

        for name in names:
            if name and len(name) > 4:
                index.setdefault(f"NAME:{_normalize(name)}", []).append(entity_data)

        count += 1

    logger.info("EU Sanctions FTM: %d entidades processadas", count)


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
