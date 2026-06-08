"""
Runner Eleições 2026 — executa ingestão de candidatos, financiamento e/ou gastos.

Uso:
  python -m ingestao.ele2026.runner --dataset candidatos
  python -m ingestao.ele2026.runner --dataset financiamento
  python -m ingestao.ele2026.runner --dataset gastos
  python -m ingestao.ele2026.runner --dataset todos
  python -m ingestao.ele2026.runner --status          # verifica disponibilidade sem ingerir

Variáveis de ambiente necessárias:
  SUPABASE_URL
  SUPABASE_SERVICE_ROLE_KEY  (ou INTERNAL_SUPABASE_SERVICE_ROLE_KEY)

Status atual dos dados (atualizar connector.py quando o TSE publicar):
  candidatos    → DADOS_DISPONIVEIS        = False  (~agosto 2026)
  financiamento → FINANCIAMENTO_DISPONIVEL = False  (~out/nov 2026)
  gastos        → GASTOS_DISPONIVEIS       = False  (~out/nov 2026)
"""
from __future__ import annotations

import argparse
import logging
import sys

from .connector import (
    DADOS_DISPONIVEIS,
    FINANCIAMENTO_DISPONIVEL,
    GASTOS_DISPONIVEIS,
    DataIndisponivel,
    get_candidatos_2026,
    iter_financiamento_2026,
    iter_gastos_2026,
)
from .persistence import Ele2026Writer

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(name)s %(levelname)s %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("ele2026.runner")


# ─── Funções de ingestão ──────────────────────────────────────────────────────

def run_candidatos(writer: Ele2026Writer) -> None:
    log_id = writer.start_log("candidatos_2026")
    try:
        candidatos = get_candidatos_2026()
        n = writer.upsert_candidatos(candidatos)
        writer.finish_log(log_id, "ok", n_processados=len(candidatos), n_novos=n)
        logger.info("ele2026 candidatos: %d processados, %d gravados", len(candidatos), n)
    except DataIndisponivel as exc:
        writer.finish_log(log_id, "indisponivel", erro=str(exc))
        logger.warning("ele2026 candidatos: %s", exc)
        raise
    except Exception as exc:
        writer.finish_log(log_id, "erro", erro=str(exc))
        logger.error("ele2026 candidatos falhou: %s", exc)
        raise


def run_financiamento(writer: Ele2026Writer) -> None:
    log_id = writer.start_log("financiamento_2026")
    try:
        n = writer.upsert_financiamento(iter_financiamento_2026())
        writer.finish_log(log_id, "ok", n_novos=n)
        logger.info("ele2026 financiamento: %d gravados", n)
    except DataIndisponivel as exc:
        writer.finish_log(log_id, "indisponivel", erro=str(exc))
        logger.warning("ele2026 financiamento: %s", exc)
        raise
    except Exception as exc:
        writer.finish_log(log_id, "erro", erro=str(exc))
        logger.error("ele2026 financiamento falhou: %s", exc)
        raise


def run_gastos(writer: Ele2026Writer) -> None:
    log_id = writer.start_log("gastos_2026")
    try:
        n = writer.upsert_gastos(iter_gastos_2026())
        writer.finish_log(log_id, "ok", n_novos=n)
        logger.info("ele2026 gastos: %d gravados", n)
    except DataIndisponivel as exc:
        writer.finish_log(log_id, "indisponivel", erro=str(exc))
        logger.warning("ele2026 gastos: %s", exc)
        raise
    except Exception as exc:
        writer.finish_log(log_id, "erro", erro=str(exc))
        logger.error("ele2026 gastos falhou: %s", exc)
        raise


# ─── Status ───────────────────────────────────────────────────────────────────

def print_status() -> None:
    """Imprime estado atual dos dados sem tentar ingerir nada."""
    print("\n── Eleições 2026 — status de disponibilidade ──────────────────")
    print(f"  candidatos    : {'✅ DISPONÍVEL' if DADOS_DISPONIVEIS        else '⏳ aguardando TSE (~agosto 2026)'}")
    print(f"  financiamento : {'✅ DISPONÍVEL' if FINANCIAMENTO_DISPONIVEL else '⏳ aguardando TSE (~out/nov 2026)'}")
    print(f"  gastos        : {'✅ DISPONÍVEL' if GASTOS_DISPONIVEIS       else '⏳ aguardando TSE (~out/nov 2026)'}")
    print()
    print("  Para ativar quando o TSE publicar:")
    print("    editar ingestao/ele2026/connector.py")
    print("    setar DADOS_DISPONIVEIS / FINANCIAMENTO_DISPONIVEL / GASTOS_DISPONIVEIS = True")
    print("────────────────────────────────────────────────────────────────\n")


# ─── CLI ──────────────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Ingestão Eleições 2026 → Supabase",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument(
        "--dataset",
        choices=["candidatos", "financiamento", "gastos", "todos"],
        help="Dataset a ingerir",
    )
    parser.add_argument(
        "--status",
        action="store_true",
        help="Verifica disponibilidade dos dados sem ingerir",
    )
    args = parser.parse_args()

    if args.status or not args.dataset:
        print_status()
        sys.exit(0)

    writer = Ele2026Writer.from_env()
    if not writer:
        logger.error("Credenciais Supabase ausentes. Abortando.")
        sys.exit(1)

    writer.cleanup_stuck_logs()

    erros = 0
    datasets = (
        ["candidatos", "financiamento", "gastos"]
        if args.dataset == "todos"
        else [args.dataset]
    )

    for ds in datasets:
        try:
            if ds == "candidatos":
                run_candidatos(writer)
            elif ds == "financiamento":
                run_financiamento(writer)
            elif ds == "gastos":
                run_gastos(writer)
        except DataIndisponivel:
            # Esperado — não conta como erro de execução
            pass
        except Exception:
            erros += 1

    if erros:
        logger.error("%d dataset(s) falharam com erro inesperado.", erros)
        sys.exit(1)

    logger.info("ele2026 runner concluído.")


if __name__ == "__main__":
    main()
