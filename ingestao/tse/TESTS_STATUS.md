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

## Resolvidos em 2026-08-23 (conexão direta obtida)

Os dois itens abaixo estavam pendentes porque o tooling MCP não expõe uma
connection string Postgres direta. O usuário forneceu a DSN de uma branch
descartável (`bahdswecdcfdnvqtyjup`) via arquivo local temporário (nunca
colada no chat); ambos foram executados e resolvidos. Detalhe completo em
[HOMOLOGACAO.md](HOMOLOGACAO.md).

1. **Benchmark ponta a ponta com COPY real** — harness sintético (ano fictício
   1998), rows passadas como gerador (não lista, mede streaming real):
   100k linhas em 17,24s (5.801 linhas/s, pico RSS 58,9 MB); 500k linhas em
   40,00s (12.499 linhas/s, pico RSS 57,75 MB). Memória praticamente idêntica
   com dataset 5× maior — confirma streaming sem acúmulo em RAM. Achado: bug
   real em [copy_backend.py](copy_backend.py) (parsing de DSN URI quebrado por
   concatenação incorreta de `sslmode=require`) — corrigido.

2. **Concorrência com duas conexões Postgres reais** (`test_concurrency_psycopg.py`) —
   `test_advisory_lock_exclusao_mutua` e `test_promote_serializado_sem_delete_concorrente`
   ambos passam. B bloqueia de verdade enquanto A segura `pg_advisory_xact_lock`
   (≥1,0s de espera medido), libera após `A.commit()`, estado final consistente
   (sem DELETE concorrente). Achado: o teste tinha um bug próprio (seed sem
   `row_fingerprint`, NOT NULL desde a migration 0001) — corrigido.

## Gated (pulam sem env)

- `test_integration_supabase.py` — requer `TSE_IT_URL` + `TSE_IT_SERVICE_KEY`
  (não usado nesta rodada; equivalente rodado via SQL direto na branch, ver
  HOMOLOGACAO.md).
- `test_concurrency_psycopg.py` — requer `TSE_IT_PGURL` (resolvido em 2026-08-23,
  ver acima; a branch que forneceu a DSN já foi apagada, então o teste volta a
  pular por padrão até uma nova branch/DSN serem fornecidas).
