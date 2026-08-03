"""
Seed cota_cnpj_lookup — The Brasilia Insider

Lê os CNPJs brutos dos CSVs anuais da Cota Parlamentar (fonte canônica,
não o Supabase) e grava a tabela de normalização.
Muito mais rápido que paginar 4M linhas via API REST.

Uso:
  python -m ingestao.seed_cota_cnpj_lookup
"""
from __future__ import annotations

import csv
import io
import logging
import os
import re
import sys
import zipfile
from pathlib import Path

import requests
from dotenv import load_dotenv

load_dotenv(Path(__file__).parent.parent / ".env")
sys.path.insert(0, str(Path(__file__).parent.parent))

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s — %(message)s", datefmt="%H:%M:%S")
logger = logging.getLogger("seed_lookup")

BASE_URL = "https://www.camara.leg.br/cotas"
ANOS = list(range(2019, 2027))   # 2019-2026 — suficiente para cruzamento atual
BATCH = 500


def fetch_cnpjs_do_ano(ano: int, session: requests.Session) -> set[str]:
    """Baixa CSV do ano e retorna CNPJs únicos (campo txtCNPJCPF)."""
    url = f"{BASE_URL}/Ano-{ano}.csv.zip"
    logger.info("Baixando %d...", ano)
    try:
        r = session.get(url, timeout=120)
        r.raise_for_status()
    except Exception as e:
        logger.error("Falhou %d: %s", ano, e)
        return set()

    cnpjs: set[str] = set()
    with zipfile.ZipFile(io.BytesIO(r.content)) as zf:
        for name in zf.namelist():
            with zf.open(name) as f:
                reader = csv.DictReader(
                    io.TextIOWrapper(f, encoding="windows-1252", errors="replace"), delimiter=";"
                )
                for row in reader:
                    raw = (row.get("txtCNPJCPF") or "").strip()
                    if raw:
                        cnpjs.add(raw)

    logger.info("  %d — %d CNPJs únicos", ano, len(cnpjs))
    return cnpjs


def upsert_lookup(sb, batch: list[dict]) -> None:
    sb.table("cota_cnpj_lookup").upsert(batch, on_conflict="cnpj_raw").execute()


def main() -> None:
    from supabase import create_client
    sb = create_client(os.environ["SUPABASE_URL"], os.environ["SUPABASE_SERVICE_ROLE_KEY"])

    session = requests.Session()
    session.headers["User-Agent"] = "BRInsider/1.0 (contato@thebrinsider.com)"

    todos: set[str] = set()
    for ano in ANOS:
        todos |= fetch_cnpjs_do_ano(ano, session)

    logger.info("Total CNPJs únicos (2019-2026): %d", len(todos))

    payload = [
        {"cnpj_raw": raw, "cnpj_norm": re.sub(r"\D", "", raw)}
        for raw in todos
        if raw
    ]

    logger.info("Gravando %d entradas em cota_cnpj_lookup...", len(payload))
    for i in range(0, len(payload), BATCH):
        upsert_lookup(sb, payload[i : i + BATCH])
        if i % 5000 == 0:
            logger.info("  %d/%d gravados", i, len(payload))

    logger.info("Concluído — %d registros na lookup table.", len(payload))


if __name__ == "__main__":
    main()
