"""
Runner Contratos Federais — The Brasilia Insider

Uso:
  # Por CNPJ de fornecedor (modo investigativo principal)
  python -m ingestao.cgu.contratos_runner --cnpj 12345678000190

  # Lista de CNPJs
  python -m ingestao.cgu.contratos_runner --lista-cnpjs cnpjs.txt

  # Por período
  python -m ingestao.cgu.contratos_runner --inicio 2024-01-01 --fim 2024-12-31

  # Por período + órgão
  python -m ingestao.cgu.contratos_runner --inicio 2023-01-01 --fim 2024-12-31 --orgao 26000

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

from .contratos_connector import ContratosConnector
from .contratos_persistence import ContratosWriter

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(name)s %(levelname)s %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("cgu.contratos.runner")


def main() -> None:
    parser = argparse.ArgumentParser(description="Ingestão Contratos Federais → Supabase")
    parser.add_argument("--cnpj", default=None)
    parser.add_argument("--lista-cnpjs", default=None, metavar="ARQUIVO")
    parser.add_argument("--inicio", type=lambda s: date.fromisoformat(s),
                        default=None, metavar="AAAA-MM-DD")
    parser.add_argument("--fim", type=lambda s: date.fromisoformat(s),
                        default=None, metavar="AAAA-MM-DD")
    parser.add_argument("--orgao", default=None, help="Código do órgão SIAFI")
    args = parser.parse_args()

    api_key = os.environ.get("PORTAL_TRANSPARENCIA_API_KEY")
    if not api_key:
        logger.error("PORTAL_TRANSPARENCIA_API_KEY não configurada.")
        sys.exit(1)

    connector = ContratosConnector(api_key)
    writer = ContratosWriter.from_env()
    if not writer:
        logger.error("Credenciais Supabase ausentes.")
        sys.exit(1)

    if args.lista_cnpjs:
        cnpjs = [c.strip() for c in Path(args.lista_cnpjs).read_text().splitlines() if c.strip()]
        desc = f"Contratos lista {len(cnpjs)} CNPJs"
        log_id = writer.start_log(desc)
        try:
            n = writer.upsert_contratos(connector.iter_cnpjs_investigados(cnpjs))
            writer.finish_log(log_id, "ok", n_novos=n)
            logger.info("%s: %d upsertados", desc, n)
        except Exception as exc:
            writer.finish_log(log_id, "erro", erro=str(exc))
            logger.error("Falhou: %s", exc)
            sys.exit(1)

    elif args.cnpj:
        desc = f"Contratos CNPJ={args.cnpj}"
        log_id = writer.start_log(desc)
        try:
            n = writer.upsert_contratos(connector.iter_por_cnpj(args.cnpj))
            writer.finish_log(log_id, "ok", n_novos=n)
            logger.info("%s: %d upsertados", desc, n)
        except Exception as exc:
            writer.finish_log(log_id, "erro", erro=str(exc))
            logger.error("Falhou: %s", exc)
            sys.exit(1)

    elif args.inicio and args.fim:
        desc = f"Contratos {args.inicio}→{args.fim}"
        if args.orgao:
            desc += f" orgao={args.orgao}"
        log_id = writer.start_log(desc)
        try:
            n = writer.upsert_contratos(
                connector.iter_por_periodo(args.inicio, args.fim, args.orgao)
            )
            writer.finish_log(log_id, "ok", n_novos=n)
            logger.info("%s: %d upsertados", desc, n)
        except Exception as exc:
            writer.finish_log(log_id, "erro", erro=str(exc))
            logger.error("Falhou: %s", exc)
            sys.exit(1)

    else:
        parser.error("Informe --cnpj, --lista-cnpjs, ou --inicio + --fim")


if __name__ == "__main__":
    main()
