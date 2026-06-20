"""
Runner Emendas API — The Brasilia Insider

Uso:
  # Full histórico (2014 → hoje)
  python -m ingestao.cgu.emendas_api_runner

  # Ano específico
  python -m ingestao.cgu.emendas_api_runner --ano 2024

  # Por parlamentar
  python -m ingestao.cgu.emendas_api_runner --autor 204554

  # Com documentos SIAFI (investigativo, lento — ~1 chamada extra por emenda)
  python -m ingestao.cgu.emendas_api_runner --ano 2024 --com-documentos

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

from .emendas_api_connector import FIRST_YEAR, EmendasApiConnector
from .emendas_api_persistence import EmendasApiWriter

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(name)s %(levelname)s %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("cgu.emendas_api.runner")


def main() -> None:
    parser = argparse.ArgumentParser(description="Ingestão Emendas API → Supabase")
    parser.add_argument("--ano", type=int, default=None, help="Ano específico")
    parser.add_argument("--autor", default=None, help="Código do autor (parlamentar)")
    parser.add_argument("--com-documentos", action="store_true",
                        help="Enriquecer emendas com documentos SIAFI (lento)")
    args = parser.parse_args()

    api_key = os.environ.get("PORTAL_TRANSPARENCIA_API_KEY")
    if not api_key:
        logger.error("PORTAL_TRANSPARENCIA_API_KEY não configurada.")
        sys.exit(1)

    connector = EmendasApiConnector(api_key)
    writer = EmendasApiWriter.from_env()
    if not writer:
        logger.error("Credenciais Supabase ausentes.")
        sys.exit(1)

    if args.autor:
        desc = f"Emendas autor={args.autor}"
        if args.ano:
            desc += f" ano={args.ano}"
        emendas = connector.iter_por_autor(args.autor, args.ano)
    elif args.ano:
        desc = f"Emendas ano={args.ano}"
        emendas = connector.iter_por_ano(args.ano)
    else:
        desc = f"Emendas full (desde {FIRST_YEAR})"
        emendas = connector.iter_all(ano_inicio=FIRST_YEAR)

    if args.com_documentos:
        desc += " +documentos"
        emendas = connector.enrich_documentos(emendas)

    log_id = writer.start_log(desc)
    try:
        n = writer.upsert_emendas(emendas)
        writer.finish_log(log_id, "ok", n_novos=n)
        logger.info("%s: %d emendas upsertadas", desc, n)
    except Exception as exc:
        writer.finish_log(log_id, "erro", erro=str(exc))
        logger.error("Falhou: %s", exc)
        sys.exit(1)


if __name__ == "__main__":
    main()
