"""
Teste EMPÍRICO de concorrência do advisory lock de tse_promote_year, usando
DUAS conexões PostgreSQL simultâneas (psycopg 3).

⚠️  Ambiente DESCARTÁVEL apenas. Requer conexão direta ao Postgres da branch
(não via PostgREST). Gated por TSE_IT_PGURL; sem ela, pula.

Como obter a connection string da branch descartável:
  Supabase Dashboard → Project (branch) → Settings → Database → Connection string
  (session mode). Exporte:
    TSE_IT_PGURL="postgresql://postgres:<senha>@<host>:5432/postgres"

Demonstra, com dois backends de verdade:
  1. Conexão A abre transação, chama uma função que adquire o MESMO advisory
     lock que tse_promote_year usa e segura (pg_sleep) — simula a promoção 1.
  2. Conexão B tenta pg_try_advisory_xact_lock no mesmo (dataset, ano):
     enquanto A segura, B recebe FALSE (não conseguiria promover — aguardaria).
  3. A faz COMMIT (libera o lock). B agora obtém TRUE.
  4. Não há DELETE concorrente: só um detém o lock por vez.
  5. Estado final consistente.

Observação: o lock de tse_promote_year é pg_advisory_xact_lock(hashtext(ds), ano).
Este teste usa exatamente a mesma chave para provar a exclusão mútua sem
precisar carregar dados reais.
"""
from __future__ import annotations

import os
import time

import pytest

psycopg = pytest.importorskip("psycopg")

PGURL = os.environ.get("TSE_IT_PGURL")
pytestmark = pytest.mark.skipif(
    not PGURL, reason="defina TSE_IT_PGURL (Postgres da branch descartável)"
)

DATASET = "receitas"
ANO = 1998
# mesma chave que a RPC usa: (hashtext(dataset), ano)


def _lock_key(conn):
    with conn.cursor() as cur:
        cur.execute("select hashtext(%s)::int, %s::int", (DATASET, ANO))
        return cur.fetchone()


def test_advisory_lock_exclusao_mutua():
    a = psycopg.connect(PGURL, autocommit=False)
    b = psycopg.connect(PGURL, autocommit=True)
    try:
        k1, k2 = _lock_key(a)

        # 1. A adquire o advisory xact lock e SEGURA (transação aberta)
        with a.cursor() as cur:
            cur.execute("select pg_advisory_xact_lock(%s, %s)", (k1, k2))

        # 2. B tenta o MESMO lock enquanto A segura → deve falhar (FALSE)
        with b.cursor() as cur:
            cur.execute("select pg_try_advisory_xact_lock(%s, %s)", (k1, k2))
            got_b = cur.fetchone()[0]
        assert got_b is False, "B não deveria obter o lock enquanto A o mantém"

        # 3. A libera (COMMIT encerra a transação e solta o xact lock)
        a.commit()
        time.sleep(0.2)

        # 4. B agora consegue o lock (exclusão mútua respeitada, um por vez)
        with b.cursor() as cur:
            cur.execute("select pg_try_advisory_xact_lock(%s, %s)", (k1, k2))
            got_b2 = cur.fetchone()[0]
        assert got_b2 is True, "B deveria obter o lock após A liberar"
    finally:
        a.close()
        b.close()


def test_promote_serializado_sem_delete_concorrente():
    """Duas promoções reais do mesmo (dataset, ano): a segunda espera a primeira.

    Requer que a migration esteja aplicada na branch (tabelas staging + RPC).
    Semeia dois runs, dispara a promoção de um em transação aberta segurando o
    lock, e confirma que a outra bloqueia até o commit — sem DELETE concorrente.
    """
    import threading
    import uuid

    def _seed_run(conn, run_id, n):
        with conn.cursor() as cur:
            cur.execute(
                "insert into tse_load_runs(run_id,dataset,ano,phase,status,min_expected) "
                "values (%s,%s,%s,'staged','running',1)", (run_id, DATASET, ANO))
            cur.executemany(
                "insert into tse_receitas_staging(run_id,ano_eleicao,numero_recibo,valor) "
                "values (%s,%s,%s,1.0)",
                [(run_id, ANO, f"C-{run_id}-{i}") for i in range(n)])
        conn.commit()

    a = psycopg.connect(PGURL, autocommit=False)
    b = psycopg.connect(PGURL, autocommit=False)
    try:
        with a.cursor() as cur:
            cur.execute("delete from tse_receitas where ano_eleicao=%s", (ANO,))
        a.commit()
        run_a, run_b = str(uuid.uuid4()), str(uuid.uuid4())
        _seed_run(a, run_a, 10)
        _seed_run(b, run_b, 10)

        # A começa a promover e SEGURA a transação (não commita ainda)
        with a.cursor() as cur:
            cur.execute("select tse_promote_year(%s,%s,%s,%s)", (DATASET, ANO, run_a, 1))
            # dentro da mesma transação o advisory lock está retido

        result = {}
        def promote_b():
            t0 = time.time()
            with b.cursor() as cur:
                cur.execute("select tse_promote_year(%s,%s,%s,%s)", (DATASET, ANO, run_b, 1))
            b.commit()
            result["waited_s"] = time.time() - t0

        th = threading.Thread(target=promote_b)
        th.start()
        time.sleep(1.0)          # B deve estar BLOQUEADO no lock
        assert not result, "B não deveria ter concluído enquanto A segura o lock"
        a.commit()               # libera o lock
        th.join(timeout=30)
        assert "waited_s" in result and result["waited_s"] >= 1.0

        # estado final consistente: só um run venceu; final tem 10 linhas
        with b.cursor() as cur:
            cur.execute("select count(*) from tse_receitas where ano_eleicao=%s", (ANO,))
            assert cur.fetchone()[0] == 10
    finally:
        for c in (a, b):
            try:
                with c.cursor() as cur:
                    cur.execute("delete from tse_receitas where ano_eleicao=%s", (ANO,))
                c.commit()
            except Exception:
                pass
            c.close()
