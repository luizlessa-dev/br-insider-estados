"""
Conector: UN Security Council Consolidated Sanctions List

Fonte: United Nations Security Council — Sanctions Committee
URL: https://scsanctions.un.org/resources/xml/en/consolidated.xml
Formato: XML público, sem autenticação
Frequência: atualizado continuamente (Al-Qaeda, Taliban, ISIL/Da'esh, DPRK, etc.)

Alertas gerados:
  - Entidade encontrada na lista consolidada do Conselho de Segurança da ONU (CRÍTICO)
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

logger = logging.getLogger("subradar.un_sanctions")

UN_XML_URL = "https://scsanctions.un.org/resources/xml/en/consolidated.xml"

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


def _text(el, tag: str) -> str:
    child = el.find(tag)
    return (child.text or "").strip() if child is not None else ""


def _load_un() -> dict[str, list[dict]]:
    global _cache_index, _cache_ts
    if _cache_index is not None and time.monotonic() - _cache_ts < _CACHE_TTL:
        return _cache_index

    logger.info("UN Sanctions: baixando XML…")
    try:
        resp = requests.get(
            UN_XML_URL,
            timeout=120,
            allow_redirects=True,
            headers={"User-Agent": "Subradar/1.0 (dados-publicos; contato@subradar.com.br)"},
        )
        resp.raise_for_status()
        content = resp.content
    except Exception as e:
        logger.error("UN Sanctions: falha ao baixar XML: %s", e)
        _cache_index = _cache_index or {}
        return _cache_index

    index: dict[str, list[dict]] = {}

    try:
        root = ET.fromstring(content)

        # Handle namespace
        ns = ""
        if root.tag.startswith("{"):
            ns = root.tag.split("}")[0] + "}"

        def tag(t: str) -> str:
            return f"{ns}{t}" if ns else t

        def process_entity(el, entity_type: str) -> None:
            first = _text(el, tag("FIRST_NAME"))
            second = _text(el, tag("SECOND_NAME"))
            third = _text(el, tag("THIRD_NAME"))
            full_name = " ".join(p for p in [first, second, third] if p).strip()

            ref_number = _text(el, tag("REFERENCE_NUMBER"))
            list_type = _text(el, tag("UN_LIST_TYPE"))

            # Collect aliases
            aliases = []
            for alias_el in el.findall(f".//{tag('ENTITY_ALIAS')}") + el.findall(f".//{tag('INDIVIDUAL_ALIAS')}"):
                alias_name = _text(alias_el, tag("ALIAS_NAME"))
                if alias_name:
                    aliases.append(alias_name)

            entity_data = {
                "nome": full_name or "N/I",
                "tipo": entity_type,
                "lista": list_type,
                "referencia": ref_number,
                "aliases": aliases,
            }

            # Index by document numbers
            for doc_el in el.findall(f".//{tag('INDIVIDUAL_DOCUMENT')}") + el.findall(f".//{tag('ENTITY_DOCUMENT')}"):
                number = _text(doc_el, tag("NUMBER"))
                if number and len(number) >= 4:
                    digits = _strip(number)
                    if 4 <= len(digits) <= 20:
                        norm = _normalize(digits)
                        index.setdefault(norm, []).append(entity_data)
                    norm_raw = _normalize(number)
                    if norm_raw != _normalize(digits) if digits else True:
                        index.setdefault(norm_raw, []).append(entity_data)

            # Index by name + aliases
            all_names = ([full_name] if full_name else []) + aliases
            for name in all_names:
                if len(name) > 3:
                    name_key = f"NAME:{_normalize(name)}"
                    index.setdefault(name_key, []).append(entity_data)

        # Individuals
        individuals = root.find(f".//{tag('INDIVIDUALS')}")
        if individuals is not None:
            for ind in individuals.findall(tag("INDIVIDUAL")):
                process_entity(ind, "INDIVIDUAL")
        else:
            for ind in root.iter(tag("INDIVIDUAL")):
                process_entity(ind, "INDIVIDUAL")

        # Entities
        entities_el = root.find(f".//{tag('ENTITIES')}")
        if entities_el is not None:
            for ent in entities_el.findall(tag("ENTITY")):
                process_entity(ent, "ENTITY")
        else:
            for ent in root.iter(tag("ENTITY")):
                process_entity(ent, "ENTITY")

    except Exception as e:
        logger.error("UN Sanctions: erro ao parsear XML: %s", e)

    _cache_index = index
    _cache_ts = time.monotonic()
    logger.info("UN Sanctions: %d identificadores indexados", len(index))
    return index


class UNSanctionsConnector(SubradarSource):
    fonte = "un_sanctions"
    request_delay = 0.0

    def consultar_cnpj(self, cnpj: str, razao_social: str | None = None) -> list[dict]:
        cnpj_digits = _strip(cnpj)
        cnpj_fmt = _fmt(cnpj_digits)
        ciclo = _ciclo_atual()

        index = _load_un()
        hits: list[dict] = []

        for key in (_normalize(cnpj_digits), _normalize(cnpj_fmt)):
            for h in index.get(key, []):
                if h not in hits:
                    hits.append(h)

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
            lista = h.get("lista", "N/I")
            alertas.append({
                "cnpj": cnpj_fmt,
                "ciclo": ciclo,
                "fonte": self.fonte,
                "categoria": "internacional",
                "severidade": "critico",
                "titulo": f"Sanção ONU — {lista}: {h.get('nome', 'N/I')}",
                "descricao": (
                    f"Entidade encontrada na UN Security Council Consolidated Sanctions List. "
                    f"Lista: {lista}. Tipo: {h.get('tipo', 'N/I')}. "
                    f"Referência: {h.get('referencia', 'N/I')}. "
                    f"Operações com esta entidade podem violar resoluções do CSNU."
                ),
                "referencia_id": h.get("referencia"),
                "url_fonte": "https://www.un.org/securitycouncil/content/un-sc-consolidated-list",
                "is_novo": True,
            })

        logger.info("UN Sanctions: %d alertas para %s", len(alertas), cnpj_fmt)
        return alertas
