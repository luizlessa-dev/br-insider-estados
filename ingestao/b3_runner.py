"""
Runner: B3 Empresas Listadas → Supabase
Uso:
  python -m ingestao.b3_runner           # ingestão completa
  python -m ingestao.b3_runner --dry-run # só imprime, não grava
"""
from __future__ import annotations

import argparse
import dataclasses
import logging
import sys
from datetime import date, datetime
from typing import Any

from .b3_connector import EmpresaListada, fetch_empresas
from .persistence import SupabaseWriter

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(name)s] %(levelname)s — %(message)s",
)
logger = logging.getLogger("b3_runner")

TABLE = "b3_empresas_listadas"
PK = "codigo_cvm"


def _to_row(e: EmpresaListada) -> dict[str, Any]:
    row = dataclasses.asdict(e)
    for k, v in row.items():
        if isinstance(v, (date, datetime)):
            row[k] = v.isoformat()
    row["atualizado_em"] = datetime.utcnow().isoformat()
    return row


def run(dry_run: bool = False) -> None:
    empresas = fetch_empresas()

    if dry_run:
        logger.info("[dry-run] %d empresas — exemplo:", len(empresas))
        for e in empresas[:3]:
            logger.info("  %s | CNPJ: %s | ticker: %s | segmento: %s",
                        e.nome_empresa, e.cnpj, e.ticker, e.segmento)
        return

    writer = SupabaseWriter.from_env()
    if not writer:
        logger.error("Env vars de Supabase não configuradas. Abortando.")
        sys.exit(1)

    rows = [_to_row(e) for e in empresas]
    saved = writer._upsert(TABLE, rows, PK)
    logger.info("Gravadas %d empresas em %s", saved, TABLE)


def main() -> None:
    parser = argparse.ArgumentParser(description="Ingere lista de empresas B3")
    parser.add_argument("--dry-run", action="store_true",
                        help="Busca dados mas não grava no Supabase")
    args = parser.parse_args()
    run(dry_run=args.dry_run)


if __name__ == "__main__":
    main()
