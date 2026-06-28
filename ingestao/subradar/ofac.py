"""
Conector: OFAC SDN List — Office of Foreign Assets Control (EUA)

Fonte: sanctionslistservice.ofac.treas.gov
Formato: XML público, sem autenticação (redirect S3)
Frequência: atualizada diariamente pelo Tesouro dos EUA
Cobertura: Specially Designated Nationals (SDN) — sanções dos EUA

Nota: OpenSanctions já cobre us_ofac_sdn via API, mas este conector
faz download direto do XML oficial para:
  1. Independência de terceiros
  2. Cobertura de CNPJs sem key OpenSanctions
  3. Dados mais frescos (OFAC atualiza intraday)
"""
from __future__ import annotations

import logging
import re
import time
import xml.etree.ElementTree as ET
from typing import Any

import requests

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.ofac")

OFAC_SDN_URL = "https://sanctionslistservice.ofac.treas.gov/api/PublicationPreview/exports/SDN.XML"
NS = {"sdn": "https://sanctionslistservice.ofac.treas.gov/api/PublicationPreview/exports/sdn"}

_cache_index: dict[str, list[dict]] | None = None
_cache_ts: float = 0.0
_CACHE_TTL = 3600 * 4  # 4h (OFAC atualiza durante o dia)


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", str(cnpj or ""))


def _fmt(cnpj: str) -> str:
    c = _strip(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _normalize_id(raw: str) -> str:
    """Remove pontuação de identificadores para comparação."""
    return re.sub(r"[\s\.\-/]", "", raw.upper())


def _load_ofac() -> dict[str, list[dict]]:
    """
    Baixa o XML da OFAC e indexa por identificadores (CNPJ, EIN, business number).
    Retorna dict: identificador_normalizado → lista de entidades SDN.
    """
    global _cache_index, _cache_ts
    if _cache_index is not None and time.monotonic() - _cache_ts < _CACHE_TTL:
        return _cache_index

    logger.info("OFAC: baixando SDN XML…")
    try:
        resp = requests.get(
            OFAC_SDN_URL,
            timeout=120,
            allow_redirects=True,
            headers={"User-Agent": "Subradar/1.0 (dados-publicos; contato@subradar.com.br)"},
        )
        resp.raise_for_status()
    except Exception as e:
        logger.error("OFAC: falha ao baixar XML: %s", e)
        _cache_index = _cache_index or {}
        return _cache_index

    try:
        root = ET.fromstring(resp.content)
    except ET.ParseError as e:
        logger.error("OFAC: erro ao parsear XML: %s", e)
        _cache_index = {}
        return _cache_index

    # Namespaces no XML da OFAC variam — detectamos automaticamente
    ns_match = re.search(r'\{([^}]+)\}', root.tag)
    ns_prefix = f"{{{ns_match.group(1)}}}" if ns_match else ""

    index: dict[str, list[dict]] = {}

    for entry in root.iter(f"{ns_prefix}sdnEntry"):
        uid = entry.findtext(f"{ns_prefix}uid") or ""
        last_name = entry.findtext(f"{ns_prefix}lastName") or ""
        first_name = entry.findtext(f"{ns_prefix}firstName") or ""
        sdn_type = entry.findtext(f"{ns_prefix}sdnType") or ""
        programs = [
            p.text for p in entry.findall(f".//{ns_prefix}program") if p.text
        ]
        entity_data = {
            "uid": uid,
            "nome": f"{first_name} {last_name}".strip() or last_name,
            "tipo": sdn_type,
            "programas": programs,
        }

        # Indexa por todos os identificadores alternativos (ID numbers)
        for id_elem in entry.findall(f".//{ns_prefix}idList/{ns_prefix}id"):
            id_type = (id_elem.findtext(f"{ns_prefix}idType") or "").upper()
            id_number = id_elem.findtext(f"{ns_prefix}idNumber") or ""
            if not id_number:
                continue
            # Tipos relevantes para CNPJs brasileiros
            if any(t in id_type for t in ("CNPJ", "TAX", "BUSINESS", "REGISTRATION", "FISCAL", "ID")):
                key = _normalize_id(id_number)
                if key:
                    index.setdefault(key, []).append(entity_data)

        # Também indexa pelo nome normalizado (para busca por razão social)
        nome_key = _normalize_id(last_name) if last_name else None
        if nome_key and len(nome_key) > 4:
            index.setdefault(f"NAME:{nome_key}", []).append(entity_data)

    _cache_index = index
    _cache_ts = time.monotonic()
    logger.info("OFAC SDN: %d identificadores indexados", len(index))
    return index


class OFACConnector(SubradarSource):
    fonte = "ofac_sdn"
    request_delay = 0.0  # dados locais após cache

    def consultar_cnpj(self, cnpj: str, razao_social: str | None = None) -> list[dict]:
        cnpj_digits = _strip(cnpj)
        cnpj_fmt = _fmt(cnpj_digits)
        ciclo = _ciclo_atual()

        index = _load_ofac()

        hits: list[dict] = []

        # Busca pelo CNPJ normalizado
        cnpj_key = _normalize_id(cnpj_digits)
        hits.extend(index.get(cnpj_key, []))

        # Busca também pelo CNPJ formatado (XX.XXX.XXX/XXXX-XX)
        cnpj_fmt_key = _normalize_id(cnpj_fmt)
        for h in index.get(cnpj_fmt_key, []):
            if h not in hits:
                hits.append(h)

        # Busca por razão social (opcional, reduz falsos positivos)
        if razao_social and not hits:
            rs_key = f"NAME:{_normalize_id(razao_social)}"
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
            programas = ", ".join(h.get("programas", [])) or "N/I"
            alertas.append({
                "cnpj": cnpj_fmt,
                "ciclo": ciclo,
                "fonte": self.fonte,
                "categoria": "internacional",
                "severidade": "critico",
                "titulo": f"Sanção OFAC/EUA — SDN List: {h.get('nome', 'N/I')}",
                "descricao": (
                    f"Entidade encontrada na SDN List do OFAC (Tesouro dos EUA). "
                    f"Tipo: {h.get('tipo', 'N/I')}. Programas de sanção: {programas}. "
                    f"Transações com esta entidade podem violar lei americana (IEEPA/TWEA)."
                ),
                "referencia_id": h.get("uid"),
                "url_fonte": f"https://sanctionssearch.ofac.treas.gov/",
                "is_novo": True,
            })

        logger.info("OFAC SDN: %d alertas para %s", len(alertas), cnpj_fmt)
        return alertas
