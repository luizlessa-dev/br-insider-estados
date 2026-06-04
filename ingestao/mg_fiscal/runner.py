"""
Runner MG Fiscal — ingestão de empenhos estaduais de Minas Gerais.

Uso:
  # Ingere um ano específico
  python -m ingestao.mg_fiscal.runner --ano 2025

  # Ingere múltiplos anos
  python -m ingestao.mg_fiscal.runner --ano 2024 --ano 2025 --ano 2026

  # Ingere todos os anos mapeados (2022–2026)
  python -m ingestao.mg_fiscal.runner --todos

  # Apenas valida o download sem gravar (dry-run)
  python -m ingestao.mg_fiscal.runner --ano 2026 --dry-run

Variáveis de ambiente necessárias:
  SUPABASE_URL
  SUPABASE_SERVICE_ROLE_KEY  (ou INTERNAL_SUPABASE_SERVICE_ROLE_KEY)
"""
from __future__ import annotations

import argparse
import logging
import sys

from .connector import anos_disponiveis, iter_empenhos
from .persistence import MGFiscalWriter

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(name)s %(levelname)s %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("mg_fiscal.runner")


def run_empenhos(writer: MGFiscalWriter | None, ano: int, dry_run: bool = False) -> None:
    dataset = f"mg_empenhos_{ano}"

    log_id = writer.start_log(dataset) if writer else None
    n = 0
    try:
        empenhos = iter_empenhos(ano)

        if dry_run:
            # Consome o generator para validar parsing sem gravar
            for emp in empenhos:
                n += 1
                if n % 10_000 == 0:
                    logger.info("dry-run %d: %d linhas processadas…", ano, n)
            logger.info("dry-run %d: %d empenhos parseados OK (nada gravado)", ano, n)
        else:
            if not writer:
                logger.error("Sem writer configurado — use --dry-run ou configure as env vars.")
                sys.exit(1)
            n = writer.upsert_empenhos(empenhos)
            logger.info("empenhos %d: %d linhas gravadas/atualizadas", ano, n)

        if writer:
            writer.finish_log(log_id, "ok", n_gravados=n)

    except Exception as exc:
        logger.error("empenhos %d falhou: %s", ano, exc)
        if writer:
            writer.finish_log(log_id, "erro", erro=str(exc))
        raise


def main() -> None:
    parser = argparse.ArgumentParser(description="Ingere empenhos estaduais MG")
    parser.add_argument(
        "--ano",
        type=int,
        action="append",
        dest="anos",
        metavar="ANO",
        help="Ano a ingerir (pode repetir: --ano 2024 --ano 2025)",
    )
    parser.add_argument(
        "--todos",
        action="store_true",
        help=f"Ingere todos os anos disponíveis: {anos_disponiveis()}",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Baixa e parseia sem gravar no Supabase",
    )
    args = parser.parse_args()

    if args.todos:
        anos = anos_disponiveis()
    elif args.anos:
        anos = sorted(set(args.anos))
    else:
        parser.error("Informe --ano ANO ou --todos")

    writer = None if args.dry_run else MGFiscalWriter.from_env()
    if not args.dry_run and writer is None:
        logger.error(
            "Env vars SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY não configuradas. "
            "Use --dry-run para testar sem banco."
        )
        sys.exit(1)

    for ano in anos:
        logger.info("=== Iniciando empenhos %d ===", ano)
        run_empenhos(writer, ano, dry_run=args.dry_run)

    logger.info("Concluído. Anos processados: %s", anos)


if __name__ == "__main__":
    main()
