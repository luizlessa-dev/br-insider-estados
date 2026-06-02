"""
Runner CEAF — The Brasilia Insider
Uso:
  python3 -m ingestao.cgu.ceaf_runner [--dry-run] [--desde AAAA-MM-DD] [--ano-inicio AAAA]

  --dry-run               Busca e parseia, mas não grava no Supabase
  --desde AAAA-MM-DD      Carga incremental a partir de uma data (ex: 2026-01-01)
  --ano-inicio AAAA       Carga full a partir de um ano (padrão: 2003)

Env vars necessárias:
  PORTAL_TRANSPARENCIA_API_KEY   — chave obtida em portaldatransparencia.gov.br/api-de-dados/cadastrar-email
  SUPABASE_URL
  SUPABASE_SERVICE_ROLE_KEY
"""
from __future__ import annotations

import argparse
import logging
import os
import sys
from datetime import date

from .ceaf_connector import CEAFConnector, FIRST_YEAR
from .ceaf_persistence import CEAFWriter

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s — %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("cgu.ceaf.runner")


def run(
    dry_run: bool = False,
    desde: date | None = None,
    ano_inicio: int = FIRST_YEAR,
) -> int:
    api_key = os.environ.get("PORTAL_TRANSPARENCIA_API_KEY", "")
    if not api_key:
        logger.error(
            "PORTAL_TRANSPARENCIA_API_KEY não definida. "
            "Obtenha em: https://portaldatransparencia.gov.br/api-de-dados/cadastrar-email"
        )
        return 1

    connector = CEAFConnector(api_key)

    logger.info("Iniciando carga CEAF (%s)", "incremental desde " + str(desde) if desde else f"full desde {ano_inicio}")

    if desde:
        expulsoes = connector.load_incremental(desde)
    else:
        expulsoes = connector.load_full(ano_inicio=ano_inicio)

    logger.info("Total carregado: %d expulsões", len(expulsoes))

    # Estatísticas rápidas
    from collections import Counter
    tipos = Counter(e.tipo_punicao for e in expulsoes)
    logger.info("Tipos: %s", dict(tipos.most_common(5)))

    if dry_run:
        logger.info("dry-run — nada gravado.")
        return 0

    writer = CEAFWriter.from_env()
    if not writer:
        logger.error("SUPABASE_URL/KEY ausentes.")
        return 1

    log_id = writer.start_log()
    try:
        n = writer.upsert_expulsoes(expulsoes)
        writer.finish_log(log_id, status="ok", n_processados=n)
        logger.info("CEAF concluído: %d registros no Supabase.", n)
    except Exception as exc:
        writer.finish_log(log_id, status="erro", erro=str(exc))
        logger.exception("CEAF falhou: %s", exc)
        return 1

    return 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Ingestão CEAF")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--desde", type=date.fromisoformat, default=None,
                        help="Data ISO (AAAA-MM-DD) para carga incremental")
    parser.add_argument("--ano-inicio", type=int, default=FIRST_YEAR,
                        help="Ano inicial para carga full (padrão: 2003)")
    args = parser.parse_args()
    sys.exit(run(dry_run=args.dry_run, desde=args.desde, ano_inicio=args.ano_inicio))
