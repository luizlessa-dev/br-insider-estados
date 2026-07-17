# Status dos testes do pipeline seguro TSE

## Executados e passando

- **Unitários** (`test_safe_loader.py`, fakes, offline): 15 passam — inclui
  fingerprint (determinismo + ordinal distingue idênticas + normalização),
  gates, rollback simulado, idempotência, resume (mesmo/diferente hash),
  sent-vs-inserted (conflito inesperado sem resume).
- **Integrados no banco** (branch Supabase DESCARTÁVEL, criada/testada/excluída):
  identity_key por fingerprint, fallback com docs NULL coexistindo, reenvio
  idempotente por (run_id, identity_key), gates (contagem, mistura de anos),
  swap atômico, rollback transacional REAL, override auditado (pct_drop +
  GITHUB_RUN_ID/ACTOR/SHA/run_url), RLS/grants (anon negado).
- **Parsing real** (download do CDN + parse, SEM escrita no Supabase): 2018 e
  2022 (2024 em coleta) — nomes de coluna SQ_*, cobertura, duplicidade.

## PENDENTES — explicitamente NÃO resolvidos

Estes dois NÃO foram executados e NÃO devem ser considerados resolvidos por
aproximações:

1. **Benchmark ponta a ponta (download → parse → COPY → promote) via conexão
   direta.** O que foi medido é o custo SERVER-SIDE (INSERT...SELECT via MCP:
   promote/count/gate) — isso é uma aproximação COPY-equivalente, **não** o
   benchmark end-to-end. Falta rodar `copy_backend.py` contra um Postgres com
   `TSE_PG_DSN` (conexão direta TLS), medindo download, parse, COPY real,
   throughput e memória.

2. **Concorrência com DUAS conexões Postgres simultâneas** (`test_concurrency_psycopg.py`).
   Só foi observado, via `pg_locks`, que a RPC ADQUIRE o advisory lock — isso
   **não** é o teste de bloqueio entre dois backends. Falta rodar as duas
   conexões e registrar: início-A, aquisição do lock, tentativa-B, tempo de
   espera, commit-A, aquisição-B, estado final.

Motivo de ambos estarem pendentes: o tooling atual não expõe uma connection
string direta ao Postgres da branch descartável (DNS direto desativado; o pooler
só aceita `postgres.<ref>` com senha não recuperável via MCP). Ambos rodam
assim que houver um ambiente descartável com conexão direta (`TSE_IT_PGURL` /
`TSE_PG_DSN`).

## Gated (pulam sem env)

- `test_integration_supabase.py` — requer `TSE_IT_URL` + `TSE_IT_SERVICE_KEY`.
- `test_concurrency_psycopg.py` — requer `TSE_IT_PGURL`.
