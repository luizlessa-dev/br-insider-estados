"""
Runner CGU-PAD — The Brasilia Insider
Uso:
  python -m ingestao.cgu.runner [--dry-run] [--limit N]

  --dry-run   baixa e parseia, mas não grava no Supabase
  --limit N   processa apenas as N primeiras linhas (dev/teste)

Env vars necessárias (quando não é dry-run):
  SUPABASE_URL
  SUPABASE_SERVICE_ROLE_KEY
"""
from __future__ import annotations

import argparse
import logging
import sys

from .pad_connector import CGUPADConnector
from .persistence import CGUWriter

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s — %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("cgu.runner")


def run(dry_run: bool = False, limit: int | None = None) -> int:
    connector = CGUPADConnector()
    raw = connector.fetch_raw()
    processos = list(connector.parse(raw))

    if limit:
        processos = processos[:limit]

    logger.info("Total parseado: %d processos", len(processos))

    # Estatísticas rápidas
    expulsivas = sum(1 for p in processos if p.n_expulsivas > 0)
    em_curso = sum(1 for p in processos if p.fase_atual != "Processo Julgado")
    logger.info(
        "  Expulsivas: %d | Em curso: %d",
        expulsivas,
        em_curso,
    )

    if dry_run:
        logger.info("dry-run — nada gravado.")
        return 0

    writer = CGUWriter.from_env()
    if not writer:
        logger.error("SUPABASE_URL/KEY ausentes. Use --dry-run ou configure o ambiente.")
        return 1

    log_id = writer.start_log()
    try:
        n = writer.upsert_processos(processos)
        writer.finish_log(log_id, status="ok", n_processados=n)
        logger.info("CGU-PAD concluído: %d registros no Supabase.", n)
    except Exception as exc:
        writer.finish_log(log_id, status="erro", erro=str(exc))
        logger.exception("CGU-PAD falhou: %s", exc)
        return 1

    return 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Ingestão CGU-PAD")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--limit", type=int, default=None)
    args = parser.parse_args()
    sys.exit(run(dry_run=args.dry_run, limit=args.limit))
