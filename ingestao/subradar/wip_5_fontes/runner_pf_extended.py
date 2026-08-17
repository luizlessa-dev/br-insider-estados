"""
Subradar PF — Pipeline Extended (Consumer + 3 Novas Fontes Gratuitas)

Versão com as 3 novas fontes do DIA 1:
- CNPI (Banco Central)
- CCF (Cheque Sem Fundo)
- Alienação RENAJUD

Total: 28 fontes (25 consumer + 3 gratuitas)
"""
from __future__ import annotations

# Importar runner_pf_consumer como base
from .runner_pf_consumer import (
    FONTES_PF_CONSUMER,
    calcular_score_risco,
    _strip,
    _fmt_cpf,
    _PESO_CRITICO,
    _PESO_ATENCAO,
    _PESO_INFO,
)

# Importar as 3 novas fontes
from .cnpi_pf import CNPIPFConnector
from .ccf_pf import CCFConnector
from .alienacao_renajud_pf import AlienacaoRENAJUDConnector

import logging
import re
import sys

from .base import upsert, _ciclo_atual, SUPABASE_URL, SUPABASE_KEY

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
)
logger = logging.getLogger("subradar.runner_pf_extended")

# ---------------------------------------------------------------------------
# Pipeline PF Extended — Consumer (20) + Novas Gratuitas (3) = 23 fontes
# ---------------------------------------------------------------------------

FONTES_PF_EXTENDED = FONTES_PF_CONSUMER + [
    # ── Novas fontes: Banco Central + RENAJUD (gratuitas) ──────────────────
    CNPIPFConnector(),           # CNPI — Inadimplentes BC
    CCFConnector(),              # CCF — Cheque Sem Fundo
    AlienacaoRENAJUDConnector(), # RENAJUD — Veículos Alienados
]


def processar_cpf(
    cpf: str,
    cliente_id: str,
    nome: str = "",
    dry_run: bool = False,
) -> list[dict]:
    cpf_digits = _strip(cpf)
    if len(cpf_digits) != 11:
        logger.error("CPF inválido: %s", cpf)
        return []

    cpf_fmt = _fmt_cpf(cpf_digits)
    ciclo = _ciclo_atual()
    fontes = FONTES_PF_EXTENDED

    logger.info("Subradar PF Extended — %s | %d fontes | dry_run=%s",
                cpf_fmt, len(fontes), dry_run)

    todos_alertas: list[dict] = []

    for fonte in fontes:
        nome_fonte = getattr(fonte, "fonte", "?")
        try:
            import inspect
            if hasattr(fonte, "consultar_cpf"):
                fn = fonte.consultar_cpf
                sig = inspect.signature(fn)
                alertas = fn(cpf_digits, nome=nome) if "nome" in sig.parameters else fn(cpf_digits)
            else:
                alertas = []

            if alertas:
                logger.info("  ✓ %s — %d alerta(s)", nome_fonte, len(alertas))
                todos_alertas.extend(alertas)
            else:
                logger.debug("  - %s — sem alertas", nome_fonte)

        except Exception as e:
            logger.error("  ✗ %s — erro: %s", nome_fonte, e)

    score = calcular_score_risco(todos_alertas)
    logger.info(
        "Score de risco: %d/100 [%s] — %d crítico(s), %d atenção",
        score["score"], score["faixa"], score["criticos"], score["atencao"],
    )

    if dry_run:
        logger.info("DRY RUN — %d alerta(s) encontrado(s), não gravado(s)", len(todos_alertas))
        print(f"\n  Score de risco: {score['score']}/100 [{score['faixa']}]")
        print(f"  {score['descricao']}\n")
        for a in todos_alertas[:10]:  # Mostrar até 10 alertas
            sev = a.get("severidade", "?").upper()
            print(f"  [{sev}] {a.get('titulo', '')} — {a.get('fonte', '')}")
        if len(todos_alertas) > 10:
            print(f"  ... e mais {len(todos_alertas) - 10}")
        return todos_alertas

    # Grava alertas no Supabase
    if SUPABASE_URL and SUPABASE_KEY:
        if todos_alertas:
            for alerta in todos_alertas:
                alerta["cliente_id"] = cliente_id
                alerta["cpf"] = cpf_fmt
            upsert("sub_pf_alertas", todos_alertas)
            logger.info("Gravados %d alertas para %s", len(todos_alertas), cpf_fmt)

        # Grava score
        import uuid as _uuid
        resultado_id = str(_uuid.uuid5(_uuid.NAMESPACE_DNS, f"{cpf_digits}-{ciclo}"))
        upsert("sub_pf_resultados", [{
            "id": resultado_id,
            "cpf": cpf_fmt,
            "cliente_id": cliente_id,
            "ciclo": ciclo,
            "score_risco": score["score"],
            "faixa_risco": score["faixa"],
            "total_alertas": score["total_alertas"],
            "score_detalhes": score,
        }])

    return todos_alertas


def main() -> None:
    import argparse
    parser = argparse.ArgumentParser(description="Subradar PF Extended — 23 fontes")
    parser.add_argument("--cpf", required=True, help="CPF a consultar")
    parser.add_argument("--nome", default="", help="Nome completo")
    parser.add_argument("--cliente-id", default="00000000-0000-0000-0000-000000000000")
    parser.add_argument("--dry-run", action="store_true", help="Não grava no Supabase")
    args = parser.parse_args()

    alertas = processar_cpf(
        cpf=args.cpf,
        cliente_id=args.cliente_id,
        nome=args.nome,
        dry_run=args.dry_run,
    )

    criticos = sum(1 for a in alertas if a.get("severidade") == "critico")
    atencao = sum(1 for a in alertas if a.get("severidade") == "atencao")
    info = len(alertas) - criticos - atencao
    logger.info("Concluído — %d crítico(s), %d atenção, %d info",
                criticos, atencao, info)


if __name__ == "__main__":
    main()
