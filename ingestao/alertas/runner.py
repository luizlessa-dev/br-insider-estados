"""
Runner — Alertas Investigativos BR Insider

Uso:
  python -m ingestao.alertas.runner           # roda todas as queries
  python -m ingestao.alertas.runner --dry-run  # só imprime, não envia
  python -m ingestao.alertas.runner --query ministerio_sancao  # query específica

Variáveis de ambiente:
  SUPABASE_URL
  SUPABASE_SERVICE_ROLE_KEY
  SLACK_WEBHOOK_URL          — webhook do canal #alertas-investigativos
  ALERT_EMAIL_TO             — email destino (opcional)
  SMTP_HOST / SMTP_PORT / SMTP_USER / SMTP_PASS (opcional)
"""
from __future__ import annotations

import argparse
import json
import logging
import os
import sys
from datetime import date

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s — %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
)
logger = logging.getLogger("alertas.runner")

try:
    from supabase import create_client
except ImportError:
    create_client = None

from .queries import QUERIES
from .notifier import (
    formatar_alerta_slack,
    formatar_email_html,
    enviar_slack,
    enviar_slack_simples,
    enviar_email,
)


def get_supabase():
    url = os.environ.get("SUPABASE_URL")
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    if not url or not key:
        logger.error("SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY são obrigatórias")
        sys.exit(1)
    if create_client is None:
        logger.error("supabase-py não instalado")
        sys.exit(1)
    return create_client(url, key)


def executar_query(supabase, sql: str) -> list[dict]:
    """Executa uma query SQL via Supabase RPC e retorna linhas."""
    try:
        result = supabase.rpc("executar_query_alertas", {"query_sql": sql}).execute()
        return result.data or []
    except Exception:
        # Fallback: usar postgrest diretamente via SQL raw
        try:
            result = supabase.postgrest.session.post(
                f"{os.environ['SUPABASE_URL']}/rest/v1/rpc/executar_query_alertas",
                json={"query_sql": sql},
                headers={
                    "apikey": os.environ["SUPABASE_SERVICE_ROLE_KEY"],
                    "Authorization": f"Bearer {os.environ['SUPABASE_SERVICE_ROLE_KEY']}",
                    "Content-Type": "application/json",
                },
            )
            return result.json() or []
        except Exception as e2:
            logger.error("Erro ao executar query: %s", e2)
            return []


def executar_query_direto(sql: str) -> list[dict]:
    """
    Executa SQL diretamente via psycopg2 (requer DATABASE_URL).
    Alternativa quando RPC não está disponível.
    """
    db_url = os.environ.get("DATABASE_URL")
    if not db_url:
        return []
    try:
        import psycopg2
        import psycopg2.extras
        conn = psycopg2.connect(db_url)
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cur.execute(sql)
        rows = [dict(r) for r in cur.fetchall()]
        conn.close()
        return rows
    except Exception as e:
        logger.error("psycopg2 erro: %s", e)
        return []


def run_alertas(
    queries_selecionadas: list[str] | None = None,
    dry_run: bool = False,
) -> dict[str, list[dict]]:
    """
    Executa todas as queries de alerta e envia notificações.
    Retorna dicionário {query_key: [rows]}.
    Usa psycopg2 (DATABASE_URL) se disponível; caso contrário usa
    a função RPC `run_sql` do Supabase (precisa ser criada no banco).
    """
    db_url = os.environ.get("DATABASE_URL") or os.environ.get("SUPABASE_DATABASE_URL")

    slack_url = os.environ.get("SLACK_WEBHOOK_URL", "")
    queries_a_rodar = queries_selecionadas or list(QUERIES.keys())
    resultados: dict[str, list[dict]] = {}
    total_alertas = 0

    logger.info("Rodando %d queries de alerta...", len(queries_a_rodar))

    for key in queries_a_rodar:
        if key not in QUERIES:
            logger.warning("Query '%s' não encontrada", key)
            continue

        meta = QUERIES[key]
        logger.info("Query: %s", key)

        rows = executar_query_direto(meta["sql"]) if db_url else executar_query(get_supabase(), meta["sql"])
        resultados[key] = rows

        if not rows:
            logger.info("  → 0 resultados")
            continue

        logger.info("  → %d resultado(s) [%s]", len(rows), meta["prioridade"])
        total_alertas += len(rows)

        if dry_run:
            print(f"\n{'='*60}")
            print(f"{meta['emoji']} {meta['titulo']} ({len(rows)} resultado(s))")
            print(f"{'='*60}")
            for row in rows[:3]:
                print(json.dumps(
                    {k: str(v) for k, v in row.items()},
                    indent=2, ensure_ascii=False
                ))
            continue

        # Envio Slack por query (apenas prioridade ALTA/CRÍTICA individualmente)
        if slack_url and meta["prioridade"] in ("ALTA", "CRÍTICA"):
            blocos = formatar_alerta_slack(meta, rows)
            if blocos:
                enviar_slack(
                    slack_url, blocos,
                    texto_fallback=f"{meta['emoji']} {meta['titulo']}: {len(rows)} ocorrência(s)"
                )

    if dry_run:
        return resultados

    # Digest consolidado no Slack (sempre, mesmo se 0 alertas críticos)
    if slack_url:
        linhas_digest = [f"*🔍 BR Insider — Digest de Alertas {date.today().isoformat()}*"]
        tem_algo = False
        for key, rows in resultados.items():
            meta = QUERIES[key]
            if rows:
                linhas_digest.append(f"{meta['emoji']} {meta['titulo']}: *{len(rows)}*")
                tem_algo = True
        if not tem_algo:
            linhas_digest.append("✅ Nenhum alerta crítico hoje.")
        enviar_slack_simples(slack_url, "\n".join(linhas_digest))

    # Email consolidado (todos os resultados)
    tem_resultados = any(rows for rows in resultados.values())
    if tem_resultados:
        html = formatar_email_html({k: (QUERIES[k], v) for k, v in resultados.items()})
        assunto = f"[BR Insider] {total_alertas} alerta(s) investigativo(s) — {date.today().isoformat()}"
        enviar_email(html, assunto)

    return resultados


def main():
    parser = argparse.ArgumentParser(description="Alertas investigativos BR Insider")
    parser.add_argument("--dry-run", action="store_true", help="Apenas imprime, não envia")
    parser.add_argument("--query", help="Rodar apenas uma query específica")
    args = parser.parse_args()

    queries = [args.query] if args.query else None
    resultados = run_alertas(queries_selecionadas=queries, dry_run=args.dry_run)

    # Resumo final
    print("\n=== RESUMO ===")
    for key, rows in resultados.items():
        meta = QUERIES[key]
        print(f"{meta['emoji']} {key}: {len(rows)} resultado(s) [{meta['prioridade']}]")


if __name__ == "__main__":
    main()
