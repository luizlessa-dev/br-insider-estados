"""
Runner — USASpending.gov
Ingere contratos e grants federais americanos no Supabase (schema usa_*).

Uso:
  python -m ingestao.usa_spending_runner --ano 2024
  python -m ingestao.usa_spending_runner --ano 2024 --agencia 097   # só DoD
  python -m ingestao.usa_spending_runner --modo agencias             # seed agências

Variáveis de ambiente necessárias:
  SUPABASE_URL
  SUPABASE_SERVICE_ROLE_KEY
"""
from __future__ import annotations

import argparse
import json
import logging
import os
import sys
from datetime import date

from supabase import create_client

from .usa_spending_connector import USAAgencia, USAContrato, USATransacao, buscar_contratos, buscar_transacoes, listar_agencias

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(name)s: %(message)s")
logger = logging.getLogger("usa_spending_runner")


# ── Supabase ──────────────────────────────────────────────────────────────────

def _supabase():
    url = os.environ["SUPABASE_URL"]
    key = os.environ["SUPABASE_SERVICE_ROLE_KEY"]
    return create_client(url, key)


# ── Upserts ───────────────────────────────────────────────────────────────────

def _upsert_agencias(sb, agencias: list[USAAgencia]) -> int:
    rows = [
        {
            "codigo": a.codigo,
            "nome": a.nome,
            "abreviacao": a.abreviacao,
            "ativo": a.ativo,
            "total_obrigacoes_usd": a.total_obrigacoes_usd,
        }
        for a in agencias
    ]
    sb.table("usa_agencias").upsert(rows, on_conflict="codigo").execute()
    return len(rows)


def _upsert_contratos(sb, contratos: list[USAContrato], batch: int = 200) -> int:
    # deduplicar por award_id antes do upsert (API pode retornar duplicatas entre páginas)
    seen: set[str] = set()
    unique = []
    for c in contratos:
        if c.award_id not in seen:
            seen.add(c.award_id)
            unique.append(c)
    contratos = unique

    rows = [
        {
            "award_id": c.award_id,
            "tipo": c.tipo,
            "agencia_codigo": c.agencia_codigo,
            "agencia_nome": c.agencia_nome,
            "subagencia_nome": c.subagencia_nome,
            "beneficiario_nome": c.beneficiario_nome,
            "beneficiario_uei": c.beneficiario_uei,
            "beneficiario_estado": c.beneficiario_estado,
            "valor_obrigado_usd": c.valor_obrigado_usd,
            "valor_potencial_usd": c.valor_potencial_usd,
            "data_inicio": c.data_inicio.isoformat() if c.data_inicio else None,
            "data_fim": c.data_fim.isoformat() if c.data_fim else None,
            "data_assinatura": c.data_assinatura.isoformat() if c.data_assinatura else None,
            "descricao": c.descricao,
            "naics_code": c.naics_code,
            "naics_descricao": c.naics_descricao,
            "lugar_execucao_estado": c.lugar_execucao_estado,
            "lugar_execucao_pais": c.lugar_execucao_pais,
            "permalink": c.permalink,
        }
        for c in contratos
    ]

    total = 0
    for i in range(0, len(rows), batch):
        sb.table("usa_contratos").upsert(rows[i:i+batch], on_conflict="award_id").execute()
        total += len(rows[i:i+batch])
        logger.info("upsert: %d/%d", total, len(rows))

    return total


# ── CLI ───────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--ano", type=int, default=date.today().year)
    parser.add_argument("--agencia", default=None, help="Código toptier (ex: 097 = DoD)")
    parser.add_argument("--modo", choices=["contratos", "agencias", "transacoes"], default="contratos")
    parser.add_argument("--award-id", default=None, help="generated_internal_id do contrato (modo transacoes)")
    parser.add_argument("--tipos", default="contract,grant", help="Tipos separados por vírgula")
    parser.add_argument("--valor-minimo", type=float, default=10_000)
    parser.add_argument("--max-paginas", type=int, default=50)
    args = parser.parse_args()

    sb = _supabase()

    if args.modo == "agencias":
        logger.info("Carregando agências federais...")
        agencias = listar_agencias()
        n = _upsert_agencias(sb, agencias)
        logger.info("✓ %d agências salvas", n)
        return

    if args.modo == "transacoes":
        if not args.award_id:
            logger.error("--award-id obrigatório no modo transacoes")
            return
        logger.info("Buscando transações para %s...", args.award_id)
        transacoes = buscar_transacoes(args.award_id, max_paginas=args.max_paginas)
        if not transacoes:
            logger.info("Nenhuma transação encontrada.")
            return
        # deduplicar por transacao_id (API pode retornar duplicatas entre páginas)
        seen_t: set[str] = set()
        rows = []
        for t in transacoes:
            if t.transacao_id and t.transacao_id not in seen_t:
                seen_t.add(t.transacao_id)
                rows.append({
                    "transacao_id": t.transacao_id,
                    "award_id": t.award_id,
                    "tipo_acao": t.tipo_acao,
                    "data_acao": t.data_acao.isoformat() if t.data_acao else None,
                    "valor_federal_usd": t.valor_federal_usd,
                    "valor_nao_federal_usd": t.valor_nao_federal_usd,
                    "descricao": t.descricao,
                    "agencia_nome": t.agencia_nome,
                    "beneficiario_nome": t.beneficiario_nome,
                    "lugar_execucao_pais": t.lugar_execucao_pais,
                    "lugar_execucao_estado": t.lugar_execucao_estado,
                })

        BATCH = 200
        for i in range(0, len(rows), BATCH):
            sb.table("usa_transacoes").upsert(rows[i:i+BATCH], on_conflict="transacao_id").execute()
        logger.info("✓ %d transações salvas no Supabase", len(rows))
        return

    # modo contratos
    inicio = date(args.ano, 1, 1)
    fim = date(args.ano, 12, 31)
    tipos = [t.strip() for t in args.tipos.split(",")]

    logger.info("Buscando %s de %s a %s (agência: %s)", tipos, inicio, fim, args.agencia or "todas")

    contratos = buscar_contratos(
        data_inicio=inicio,
        data_fim=fim,
        tipos=tipos,
        agencia_codigo=args.agencia,
        valor_minimo_usd=args.valor_minimo,
        max_paginas=args.max_paginas,
    )

    n = _upsert_contratos(sb, contratos)
    logger.info("✓ %d contratos salvos no Supabase", n)


if __name__ == "__main__":
    main()
