"""
Runner RS Fiscal — despesas estaduais do Rio Grande do Sul.

Uso:
  # Ano completo
  python -m ingestao.rs_fiscal.runner --ano 2025

  # Meses específicos (útil para atualização incremental)
  python -m ingestao.rs_fiscal.runner --ano 2026 --mes 4 --mes 5

  # Todos os anos disponíveis
  python -m ingestao.rs_fiscal.runner --todos

  # Apenas pagamentos (volume ~3x menor, suficiente para cruzamento por CNPJ)
  python -m ingestao.rs_fiscal.runner --ano 2025 --apenas-pagamentos

  # Dry-run (valida sem gravar)
  python -m ingestao.rs_fiscal.runner --ano 2026 --mes 4 --dry-run

Variáveis de ambiente:
  SUPABASE_URL
  SUPABASE_SERVICE_ROLE_KEY
"""
from __future__ import annotations

import argparse
import logging
import sys

from .connector import anos_disponiveis, iter_despesas
from .persistence import RSFiscalWriter

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(name)s %(levelname)s %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("rs_fiscal.runner")


def run_despesas(
    writer: RSFiscalWriter | None,
    ano: int,
    meses: list[int] | None,
    apenas_pagamentos: bool,
    dry_run: bool,
) -> None:
    meses_label = f"meses={meses}" if meses else "todos os meses"
    dataset = f"rs_despesas_{ano}"
    log_id = writer.start_log(dataset) if writer else None
    n = 0

    try:
        despesas = iter_despesas(ano, meses=meses, apenas_pagamentos=apenas_pagamentos)

        if dry_run:
            for d in despesas:
                n += 1
                if n % 50_000 == 0:
                    logger.info("dry-run %d (%s): %d linhas…", ano, meses_label, n)
            logger.info("dry-run %d: %d despesas parseadas OK (nada gravado)", ano, n)
        else:
            if not writer:
                logger.error("Sem writer — use --dry-run ou configure env vars.")
                sys.exit(1)
            n = writer.upsert_despesas(despesas)
            logger.info("rs_despesas %d (%s): %d linhas gravadas", ano, meses_label, n)

        if writer:
            writer.finish_log(log_id, "ok", n_gravados=n)

    except Exception as exc:
        logger.error("rs_despesas %d falhou: %s", ano, exc)
        if writer:
            writer.finish_log(log_id, "erro", erro=str(exc))
        raise


def main() -> None:
    parser = argparse.ArgumentParser(description="Ingere despesas estaduais RS")
    parser.add_argument("--ano", type=int, action="append", dest="anos", metavar="ANO")
    parser.add_argument("--mes", type=int, action="append", dest="meses", metavar="MES")
    parser.add_argument("--todos", action="store_true",
                        help=f"Todos os anos: {anos_disponiveis()}")
    parser.add_argument("--apenas-pagamentos", action="store_true",
                        help="Filtra só FaseGasto=Pagamento (~3x menos linhas)")
    parser.add_argument("--dry-run", action="store_true",
                        help="Parseia sem gravar no Supabase")
    args = parser.parse_args()

    if args.todos:
        anos = anos_disponiveis()
    elif args.anos:
        anos = sorted(set(args.anos))
    else:
        parser.error("Informe --ano ANO, --todos, ou --dry-run")

    writer = None if args.dry_run else RSFiscalWriter.from_env()
    if not args.dry_run and writer is None:
        logger.error("Env vars não configuradas. Use --dry-run para testar.")
        sys.exit(1)

    for ano in anos:
        logger.info("=== RS Fiscal %d ===", ano)
        run_despesas(writer, ano, args.meses, args.apenas_pagamentos, args.dry_run)

    logger.info("Concluído. Anos: %s", anos)


if __name__ == "__main__":
    main()
