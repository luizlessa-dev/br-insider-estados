"""
Ingestão de séries macroeconômicas do FRED (Federal Reserve Bank of St. Louis).

Séries ingeridas:
  DEXBZUS          — câmbio BRL/USD (diário)
  BRACPIALLMINMEI  — inflação Brasil, CPI geral (mensal)
  BRAGDPNADSMEI    — PIB Brasil, USD corrente ajust. sazonalmente (trimestral)

Uso:
    python -m ingestao.fred_macro [--series DEXBZUS,BRACPIALLMINMEI,BRAGDPNADSMEI]
    python -m ingestao.fred_macro --desde 2020-01-01

Requer:
    SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, FRED_API_KEY
"""
from __future__ import annotations

import argparse
import logging
import os
import time
from datetime import datetime, date, timezone
from typing import Any

import requests
from supabase import create_client, Client

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s — %(message)s",
)
logger = logging.getLogger("ingestao.fred_macro")

FRED_BASE = "https://api.stlouisfed.org/fred/series/observations"

DEFAULT_SERIES = [
    "DEXBZUS",           # câmbio BRL/USD diário
    "BRACPIALLMINMEI",   # inflação Brasil (CPI, mensal)
    "BRAGDPNADSMEI",     # PIB Brasil (trimestral, USD)
]


def _supabase() -> Client:
    url = os.environ["SUPABASE_URL"]
    key = os.environ["SUPABASE_SERVICE_ROLE_KEY"]
    return create_client(url, key)


def _fred_observations(
    series_id: str,
    api_key: str,
    observation_start: str | None = None,
) -> list[dict[str, Any]]:
    params: dict[str, str] = {
        "series_id":  series_id,
        "api_key":    api_key,
        "file_type":  "json",
        "sort_order": "asc",
    }
    if observation_start:
        params["observation_start"] = observation_start

    resp = requests.get(FRED_BASE, params=params, timeout=30)
    resp.raise_for_status()
    return resp.json().get("observations", [])


def ingest_series(
    db: Client,
    api_key: str,
    series_id: str,
    observation_start: str | None,
) -> int:
    logger.info("Buscando %s (desde %s)…", series_id, observation_start or "início")
    obs = _fred_observations(series_id, api_key, observation_start)

    rows = [
        {"series_id": series_id, "date": o["date"], "value": float(o["value"])}
        for o in obs
        if o.get("value") not in (".", "", None)  # FRED usa "." para dado ausente
    ]

    if not rows:
        logger.info("%s — nenhuma observação válida.", series_id)
        return 0

    # Upsert em lotes de 1 000
    batch_size = 1_000
    n_inseridos = 0
    for i in range(0, len(rows), batch_size):
        chunk = rows[i : i + batch_size]
        db.table("macro_fred").upsert(chunk, on_conflict="series_id,date").execute()
        n_inseridos += len(chunk)

    logger.info("%s — %d observações inseridas/atualizadas.", series_id, n_inseridos)
    return n_inseridos


def _log(db: Client, series_id: str, status: str, n: int, erro: str | None) -> None:
    db.table("macro_fred_ingest_log").insert(
        {
            "series_id":   series_id,
            "status":      status,
            "n_novos":     n,
            "erro":        erro,
            "finished_at": datetime.now(timezone.utc).isoformat(),
        }
    ).execute()


def main() -> None:
    parser = argparse.ArgumentParser(description="Ingestão FRED Macro")
    parser.add_argument(
        "--series",
        default=",".join(DEFAULT_SERIES),
        help="Séries separadas por vírgula",
    )
    parser.add_argument(
        "--desde",
        default=None,
        metavar="AAAA-MM-DD",
        help="Buscar apenas a partir desta data (incremental)",
    )
    args = parser.parse_args()

    api_key = os.environ.get("FRED_API_KEY", "")
    if not api_key:
        raise SystemExit("FRED_API_KEY não definida. Obtenha em research.stlouisfed.org/useraccount/apikeys")

    db = _supabase()
    series_list = [s.strip() for s in args.series.split(",") if s.strip()]

    for series_id in series_list:
        try:
            n = ingest_series(db, api_key, series_id, args.desde)
            _log(db, series_id, "ok", n, None)
        except Exception as exc:
            logger.error("%s — falhou: %s", series_id, exc)
            _log(db, series_id, "erro", 0, str(exc))
        # Respeita limite de cortesia da API (evita 429)
        time.sleep(0.5)


if __name__ == "__main__":
    main()
