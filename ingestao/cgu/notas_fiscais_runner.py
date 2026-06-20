"""
Runner Notas Fiscais — The Brasilia Insider

Uso:
  # Por CNPJ (modo investigativo — principal caso de uso)
  python -m ingestao.cgu.notas_fiscais_runner --cnpj 12345678000190
  python -m ingestao.cgu.notas_fiscais_runner --cnpj 12345678000190 --inicio 2022-01-01 --fim 2023-12-31

  # Por período + UF
  python -m ingestao.cgu.notas_fiscais_runner --inicio 2024-01-01 --fim 2024-01-31 --uf RJ

  # Por chave específica
  python -m ingestao.cgu.notas_fiscais_runner --chave 35220612345678000190550010000012341234567890

  # Todos os CNPJs de uma investigação (arquivo com um CNPJ por linha)
  python -m ingestao.cgu.notas_fiscais_runner --lista-cnpjs cnpjs_investigados.txt

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
from pathlib import Path

from .notas_fiscais_connector import NotasFiscaisConnector
from .notas_fiscais_persistence import NotasFiscaisWriter

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(name)s %(levelname)s %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("cgu.notas_fiscais.runner")


def main() -> None:
    parser = argparse.ArgumentParser(description="Ingestão Notas Fiscais → Supabase")
    parser.add_argument("--cnpj", default=None, help="CNPJ do emitente")
    parser.add_argument("--lista-cnpjs", default=None, metavar="ARQUIVO",
                        help="Arquivo com um CNPJ por linha")
    parser.add_argument("--chave", default=None, help="Chave de 44 dígitos da NF")
    parser.add_argument("--inicio", type=lambda s: date.fromisoformat(s),
                        default=None, metavar="AAAA-MM-DD")
    parser.add_argument("--fim", type=lambda s: date.fromisoformat(s),
                        default=None, metavar="AAAA-MM-DD")
    parser.add_argument("--uf", default=None, help="Filtrar por UF do emitente")
    args = parser.parse_args()

    api_key = os.environ.get("PORTAL_TRANSPARENCIA_API_KEY")
    if not api_key:
        logger.error("PORTAL_TRANSPARENCIA_API_KEY não configurada.")
        sys.exit(1)

    connector = NotasFiscaisConnector(api_key)
    writer = NotasFiscaisWriter.from_env()
    if not writer:
        logger.error("Credenciais Supabase ausentes.")
        sys.exit(1)

    if args.chave:
        desc = f"NF chave={args.chave}"
        log_id = writer.start_log(desc)
        try:
            nf = connector.fetch_por_chave(args.chave)
            n = writer.upsert_notas(iter([nf]) if nf else iter([]))
            writer.finish_log(log_id, "ok", n_novos=n)
            logger.info("%s: %d registro(s)", desc, n)
        except Exception as exc:
            writer.finish_log(log_id, "erro", erro=str(exc))
            logger.error("Falhou: %s", exc)
            sys.exit(1)

    elif args.lista_cnpjs:
        cnpjs = Path(args.lista_cnpjs).read_text().splitlines()
        cnpjs = [c.strip() for c in cnpjs if c.strip()]
        desc = f"NFs lista de {len(cnpjs)} CNPJs"
        log_id = writer.start_log(desc)
        try:
            notas = connector.iter_cnpjs_investigados(cnpjs)
            n = writer.upsert_notas(notas)
            writer.finish_log(log_id, "ok", n_novos=n)
            logger.info("%s: %d notas upsertadas", desc, n)
        except Exception as exc:
            writer.finish_log(log_id, "erro", erro=str(exc))
            logger.error("Falhou: %s", exc)
            sys.exit(1)

    elif args.cnpj:
        desc = f"NFs CNPJ={args.cnpj}"
        log_id = writer.start_log(desc)
        try:
            notas = connector.iter_por_cnpj(args.cnpj, args.inicio, args.fim)
            n = writer.upsert_notas(notas)
            writer.finish_log(log_id, "ok", n_novos=n)
            logger.info("%s: %d notas upsertadas", desc, n)
        except Exception as exc:
            writer.finish_log(log_id, "erro", erro=str(exc))
            logger.error("Falhou: %s", exc)
            sys.exit(1)

    elif args.inicio and args.fim:
        desc = f"NFs período {args.inicio}→{args.fim}"
        if args.uf:
            desc += f" UF={args.uf}"
        log_id = writer.start_log(desc)
        try:
            notas = connector.iter_por_periodo(args.inicio, args.fim, args.uf)
            n = writer.upsert_notas(notas)
            writer.finish_log(log_id, "ok", n_novos=n)
            logger.info("%s: %d notas upsertadas", desc, n)
        except Exception as exc:
            writer.finish_log(log_id, "erro", erro=str(exc))
            logger.error("Falhou: %s", exc)
            sys.exit(1)

    else:
        parser.error("Informe --cnpj, --lista-cnpjs, --chave, ou --inicio + --fim")


if __name__ == "__main__":
    main()
