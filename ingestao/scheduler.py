"""
Scheduler de ingestão — The Brasilia Insider
Roda todos os conectores implementados e reporta status.

Uso:
  python -m ingestao.scheduler --dias 7
  python -m ingestao.scheduler --assembly almg --dias 30
  python -m ingestao.scheduler --health-check
"""
from __future__ import annotations

import argparse
import logging
import sys
from datetime import date, timedelta

from .base_connector import NotImplementedConnector, ConnectorError
from .connectors import REGISTRY, get_connector, all_connectors

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s — %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("scheduler")


def run_health_checks() -> None:
    print(f"\n{'ASSEMBLEIA':<50} {'ID':<8} {'STATUS'}")
    print("─" * 75)
    ok = 0
    for connector in all_connectors():
        status = "✅ online" if connector.health_check() else "❌ offline"
        print(f"{connector.assembly_name:<50} {connector.assembly_id:<8} {status}")
        if "✅" in status:
            ok += 1
    print(f"\n{ok}/27 assembleias acessíveis\n")


def run_ingestion(assembly_ids: list[str] | None, data_inicio: date, data_fim: date) -> None:
    targets = assembly_ids or list(REGISTRY.keys())
    resultados = {"ok": [], "stub": [], "erro": []}

    for aid in targets:
        try:
            connector = get_connector(aid)
        except KeyError:
            logger.error("Assembly não encontrado: %s", aid)
            continue

        logger.info("▶ %s (%s)", connector.assembly_name, aid)
        try:
            deps = connector.get_deputados()
            props = connector.get_proposicoes(data_inicio, data_fim)
            vots = connector.get_votacoes(data_inicio, data_fim)
            logger.info(
                "  ✅ %d deputados | %d proposições | %d votações",
                len(deps), len(props), len(vots),
            )
            resultados["ok"].append(aid)

        except NotImplementedConnector:
            logger.info("  ⏳ %s — ainda não implementado (stub)", aid)
            resultados["stub"].append(aid)

        except ConnectorError as e:
            logger.warning("  ❌ %s — erro de conexão: %s", aid, e)
            resultados["erro"].append(aid)

        except Exception as e:
            logger.exception("  💥 %s — erro inesperado: %s", aid, e)
            resultados["erro"].append(aid)

    print(f"\n── Resumo ──────────────────────────────")
    print(f"  ✅ OK:    {len(resultados['ok'])} ({', '.join(resultados['ok']) or '—'})")
    print(f"  ⏳ Stubs: {len(resultados['stub'])}")
    print(f"  ❌ Erros: {len(resultados['erro'])} ({', '.join(resultados['erro']) or '—'})")
    print()


def main() -> None:
    parser = argparse.ArgumentParser(description="Ingestão de dados das assembleias estaduais")
    parser.add_argument("--dias", type=int, default=7, help="Janela de ingestão em dias (default: 7)")
    parser.add_argument("--assembly", nargs="*", help="IDs específicos (ex: almg alep). Default: todos.")
    parser.add_argument("--health-check", action="store_true", help="Apenas verifica conectividade")
    args = parser.parse_args()

    if args.health_check:
        run_health_checks()
        sys.exit(0)

    data_fim = date.today()
    data_inicio = data_fim - timedelta(days=args.dias)
    logger.info("Período: %s → %s", data_inicio, data_fim)

    run_ingestion(args.assembly, data_inicio, data_fim)


if __name__ == "__main__":
    main()
