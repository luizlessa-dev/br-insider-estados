"""
Runner PEPs — The Brasilia Insider

Uso:
  python -m ingestao.cgu.peps_runner
  python -m ingestao.cgu.peps_runner --desde 2024-01-01
  python -m ingestao.cgu.peps_runner --cpf 12345678901

Variáveis de ambiente:
  SUPABASE_URL
  SUPABASE_SERVICE_ROLE_KEY
  PORTAL_TRANSPARENCIA_API_KEY
"""
from __future__ import annotations

import argparse
import logging
import os
import sys
from datetime import date

from .peps_connector import FIRST_YEAR, PepsConnector
from .peps_persistence import PepsWriter

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(name)s %(levelname)s %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("cgu.peps.runner")


def main() -> None:
    parser = argparse.ArgumentParser(description="Ingestão PEPs → Supabase")
    parser.add_argument("--ano-inicio", type=int, default=None,
                        help="Retomar a partir deste ano (janelas anuais)")
    parser.add_argument("--nome", default=None,
                        help="Busca pontual por nome")
    args = parser.parse_args()

    api_key = os.environ.get("PORTAL_TRANSPARENCIA_API_KEY")
    if not api_key:
        logger.error("PORTAL_TRANSPARENCIA_API_KEY não configurada.")
        sys.exit(1)

    connector = PepsConnector(api_key)
    writer = PepsWriter.from_env()
    if not writer:
        logger.error("Credenciais Supabase ausentes.")
        sys.exit(1)

    log_id = writer.start_log("peps")
    try:
        if args.nome:
            peps = connector.fetch_by_nome(args.nome)
            desc = f"PEPs nome={args.nome}"
        elif args.ano_inicio:
            peps = connector.iter_all(ano_inicio=args.ano_inicio)
            desc = f"PEPs desde {args.ano_inicio}"
        else:
            peps = connector.iter_all(ano_inicio=FIRST_YEAR)
            desc = "PEPs full"

        n = writer.upsert_peps(peps)
        writer.finish_log(log_id, "ok", n_novos=n)
        logger.info("%s: %d registros upsertados", desc, n)
    except Exception as exc:
        writer.finish_log(log_id, "erro", erro=str(exc))
        logger.error("PEPs falhou: %s", exc)
        sys.exit(1)


if __name__ == "__main__":
    main()
