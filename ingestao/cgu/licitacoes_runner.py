"""
Runner Licitações — The Brasilia Insider

Uso:
  # Por período (ingestão em lote)
  python -m ingestao.cgu.licitacoes_runner --inicio 2024-01-01 --fim 2024-12-31

  # Por período + órgão
  python -m ingestao.cgu.licitacoes_runner --inicio 2023-01-01 --fim 2024-12-31 --orgao 26000

  # Com participantes (mais lento, uso investigativo)
  python -m ingestao.cgu.licitacoes_runner --inicio 2024-01-01 --fim 2024-06-30 --com-participantes

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

from .licitacoes_connector import LicitacoesConnector
from .licitacoes_persistence import LicitacoesWriter

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(name)s %(levelname)s %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("cgu.licitacoes.runner")


def main() -> None:
    parser = argparse.ArgumentParser(description="Ingestão Licitações → Supabase")
    parser.add_argument("--inicio", type=lambda s: date.fromisoformat(s),
                        required=True, metavar="AAAA-MM-DD")
    parser.add_argument("--fim", type=lambda s: date.fromisoformat(s),
                        required=True, metavar="AAAA-MM-DD")
    parser.add_argument("--orgao", default=None, help="Código do órgão SIAFI")
    parser.add_argument("--com-participantes", action="store_true",
                        help="Enriquecer cada licitação com participantes (lento)")
    args = parser.parse_args()

    api_key = os.environ.get("PORTAL_TRANSPARENCIA_API_KEY")
    if not api_key:
        logger.error("PORTAL_TRANSPARENCIA_API_KEY não configurada.")
        sys.exit(1)

    connector = LicitacoesConnector(api_key)
    writer = LicitacoesWriter.from_env()
    if not writer:
        logger.error("Credenciais Supabase ausentes.")
        sys.exit(1)

    desc = f"Licitações {args.inicio}→{args.fim}"
    if args.orgao:
        desc += f" orgao={args.orgao}"
    if args.com_participantes:
        desc += " +participantes"

    log_id = writer.start_log(desc)
    try:
        licitacoes = connector.iter_por_periodo(
            args.inicio, args.fim,
            codigo_orgao=args.orgao,
            com_participantes=args.com_participantes,
        )
        n = writer.upsert_licitacoes(licitacoes)
        writer.finish_log(log_id, "ok", n_novos=n)
        logger.info("%s: %d licitações upsertadas", desc, n)
    except Exception as exc:
        writer.finish_log(log_id, "erro", erro=str(exc))
        logger.error("Falhou: %s", exc)
        sys.exit(1)


if __name__ == "__main__":
    main()
