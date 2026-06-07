"""
IBGE — The Brasilia Insider
Ingesta municípios canônicos (API Localidades) e indicadores via SIDRA.

Uso:
    python -m ingestao.ibge seed-municipios
    python -m ingestao.ibge seed-pib
    python -m ingestao.ibge seed-censo
    python -m ingestao.ibge seed-all
"""
from __future__ import annotations

import logging
import os
import sys
import time
from typing import Iterator

import requests

from .persistence import SupabaseWriter

logger = logging.getLogger("ibge")

BASE_LOCALIDADES = "https://servicodados.ibge.gov.br/api/v1/localidades"
BASE_SIDRA       = "https://servicodados.ibge.gov.br/api/v3/agregados"

# SIDRA: tabela 5938 = PIB dos Municípios
# Variável 37 = PIB total a preços correntes (Mil Reais)
SIDRA_PIB_TABELA    = "5938"
SIDRA_PIB_VARIAVEL  = "37"    # PIB total em Mil Reais

# SIDRA: tabela 9605 = Censo 2022 — variável 93 = população residente
SIDRA_CENSO_TABELA    = "9605"
SIDRA_CENSO_VARIAVEL  = "93"


def _get(url: str, params: dict | None = None, delay: float = 0.3) -> dict | list:
    time.sleep(delay)
    r = requests.get(url, params=params, timeout=60)
    r.raise_for_status()
    return r.json()


# ── Municípios ─────────────────────────────────────────────────────────

def fetch_municipios() -> list[dict]:
    """Retorna todos os ~5.570 municípios com metadados geográficos."""
    logger.info("Buscando municípios na API Localidades...")
    data = _get(f"{BASE_LOCALIDADES}/municipios?orderBy=nome", delay=0)
    rows = []
    for m in data:
        micro = m.get("microrregiao") or {}
        meso  = micro.get("mesorregiao") or {}
        uf    = meso.get("UF") or {}
        ri    = m.get("regiao-imediata") or {}
        rint  = ri.get("regiao-intermediaria") or {}
        # fallback: quando microrregiao é null, tenta extrair UF via regiao-imediata
        if not uf:
            uf = rint.get("UF") or {}
        regiao = uf.get("regiao") or {}
        rows.append({
            "codigo_ibge":              str(m["id"]),
            "nome":                     m["nome"],
            "uf":                       uf.get("sigla", ""),
            "codigo_uf":                uf.get("id", 0),
            "nome_uf":                  uf.get("nome", ""),
            "nome_regiao":              regiao.get("nome", ""),
            "nome_mesorregiao":         meso.get("nome"),
            "nome_microrregiao":        micro.get("nome"),
            "nome_regiao_imediata":     ri.get("nome"),
            "nome_regiao_intermediaria": rint.get("nome"),
        })
    logger.info("%d municípios carregados.", len(rows))
    return rows


def save_municipios(writer: SupabaseWriter, rows: list[dict]) -> int:
    saved = 0
    for i in range(0, len(rows), 500):
        chunk = rows[i:i + 500]
        writer._upsert("ibge_municipios", chunk, "codigo_ibge")
        saved += len(chunk)
        logger.info("  → %d/%d municípios gravados", saved, len(rows))
    return saved


# ── Indicadores SIDRA ──────────────────────────────────────────────────

def _sidra_municipios(tabela: str, variavel: str, ano: str = "last") -> Iterator[dict]:
    """
    Consulta SIDRA para todos os municípios.
    Retorna dicts {codigo_ibge, valor, ano_referencia}.
    """
    # N6 = nível territorial município; all = todos os municípios
    url = f"{BASE_SIDRA}/{tabela}/periodos/{ano}/variaveis/{variavel}"
    params = {"localidades": "N6[all]"}
    logger.info("SIDRA tabela=%s variável=%s período=%s...", tabela, variavel, ano)
    data = _get(url, params=params, delay=1.0)

    for item in data:
        for resultado in item.get("resultados", []):
            for s in resultado.get("series", []):
                loc_id = s.get("localidade", {}).get("id", "")
                if not loc_id:
                    continue
                for periodo, valor_str in s.get("serie", {}).items():
                    if valor_str in ("...", "-", "", None):
                        continue
                    try:
                        valor = float(str(valor_str).replace(",", "."))
                    except (ValueError, AttributeError):
                        continue
                    yield {
                        "codigo_ibge": str(loc_id),
                        "periodo":     periodo,
                        "valor":       valor,
                    }


def fetch_pib_percapita(anos: str = "2019|2020|2021") -> list[dict]:
    rows = []
    for item in _sidra_municipios(SIDRA_PIB_TABELA, SIDRA_PIB_VARIAVEL, anos):
        rows.append({
            "codigo_ibge":  item["codigo_ibge"],
            "pesquisa_id":  "pib-municipios",
            "variavel_id":  "pib_total_mil_reais",
            "variavel_nome": "PIB total a preços correntes",
            "ano":          int(item["periodo"]),
            "valor":        item["valor"],
            "unidade":      "Mil Reais",
        })
    logger.info("%d linhas de PIB per capita carregadas.", len(rows))
    return rows


def fetch_populacao_censo() -> list[dict]:
    rows = []
    for item in _sidra_municipios(SIDRA_CENSO_TABELA, SIDRA_CENSO_VARIAVEL, "2022"):
        rows.append({
            "codigo_ibge":  item["codigo_ibge"],
            "pesquisa_id":  "censo-2022",
            "variavel_id":  "populacao",
            "variavel_nome": "População residente",
            "ano":          2022,
            "valor":        item["valor"],
            "unidade":      "habitantes",
        })
    logger.info("%d linhas de população carregadas.", len(rows))
    return rows


def save_indicadores(writer: SupabaseWriter, rows: list[dict]) -> int:
    saved = 0
    for i in range(0, len(rows), 500):
        chunk = rows[i:i + 500]
        writer._upsert(
            "ibge_indicadores", chunk,
            "codigo_ibge,pesquisa_id,variavel_id,ano"
        )
        saved += len(chunk)
    logger.info("%d indicadores gravados.", saved)
    return saved


# ── CLI ────────────────────────────────────────────────────────────────

def main(cmd: str = "seed-all") -> None:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(name)s] %(message)s",
    )
    writer = SupabaseWriter.from_env()
    if not writer:
        logger.error("Sem credenciais Supabase — abortando.")
        sys.exit(1)

    if cmd in ("seed-municipios", "seed-all"):
        rows = fetch_municipios()
        save_municipios(writer, rows)

    if cmd in ("seed-pib", "seed-all"):
        rows = fetch_pib_percapita()
        if rows:
            save_indicadores(writer, rows)

    if cmd in ("seed-censo", "seed-all"):
        rows = fetch_populacao_censo()
        if rows:
            save_indicadores(writer, rows)

    logger.info("Concluído: %s", cmd)


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "seed-all"
    main(cmd)
