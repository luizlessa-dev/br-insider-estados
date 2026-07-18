# Runbook de homologação — pipeline seguro TSE (PR B)

Objetivo: homologar o pipeline seguro (staging + fingerprint + swap atômico +
COPY) num ambiente DESCARTÁVEL com conexão Postgres direta, sem tocar produção.

Pré-condições (não negociáveis):
- PR B mergeado como código inativo (`TSE_SAFE_LOADER` ausente, cron suspenso).
- Nenhuma migration aplicada em produção. Nenhum secret produtivo.
- Toda esta homologação roda contra a BRANCH descartável, nunca contra
  `redggdtakzmsabwvjzhb` (produção).

Convenção de variáveis (todas temporárias, só na máquina de homologação):
- `IT_REF`      — project_ref da branch descartável (ex.: `abcd...`).
- `TSE_IT_URL`  — `https://$IT_REF.supabase.co` (PostgREST).
- `TSE_IT_SERVICE_KEY` — service_role key da branch.
- `TSE_IT_PGURL`/`TSE_PG_DSN` — connection string Postgres DIRETA (TLS,
  `sslmode=require`), usada pelo COPY e pelo teste de concorrência.

---

## 1. Criar ambiente descartável com conexão Postgres direta

1. Criar branch Supabase da árvore de produção (Dashboard → Branches → Create,
   ou `create_branch`). Anotar `IT_REF`.
2. **Obter a connection string DIRETA** (o que faltou nas rodadas anteriores):
   Dashboard da branch → Settings → Database → Connection string → **Session
   mode** (porta 5432). Copiar para `TSE_PG_DSN` e `TSE_IT_PGURL` e anexar
   `sslmode=require` se ausente. Sem isso, os passos 5 e 6 não rodam.
3. Obter `TSE_IT_SERVICE_KEY` (Settings → API → service_role) e montar
   `TSE_IT_URL`.
4. Exportar tudo como env local (nunca commitar, nunca logar).

Nota: a branch replay das 142 migrations pode falhar (bug conhecido de baseline).
Se `tse_receitas`/`tse_despesas` não existirem na branch, criá-las com o schema
real (introspecção documentada) como fixture ANTES da migration — é ambiente de
teste, não produção.

## 2. Aplicar a migration

- Aplicar `ingestao/tse/sql/0001_tse_safe_pipeline.sql` na branch (via
  `supabase db push` apontando para a branch, ou `apply_migration` com o
  `project_id` da branch).
- Conferir: staging (receitas/despesas) com `identity_key` gerado e os dois
  CHECKs; `tse_load_runs` com colunas de progresso/proveniência/override;
  funções `tse_promote_year` e `tse_gc_staging` com owner `postgres` e EXECUTE
  só para `service_role`.

## 3. Criar secrets temporários

- Exportar no shell da homologação: `TSE_IT_URL`, `TSE_IT_SERVICE_KEY`,
  `TSE_IT_PGURL`, `TSE_PG_DSN`. Opcional para override: `GITHUB_RUN_ID`,
  `GITHUB_ACTOR`, `GITHUB_SHA`, `GITHUB_SERVER_URL`, `GITHUB_REPOSITORY`.
- Regras: só em ambiente de homologação; nunca em `.env` versionado; nunca em log.

## 4. Executar testes integrados (PostgREST/RPC)

```bash
.venv/bin/python -m pytest ingestao/tse/tests/test_integration_supabase.py -v
```
Cobre: grants/RLS (anon negado), carga normal + cleanup, quality gate + final
intacta, mistura de anos, run de outro ano recusado, idempotência de repromote.

## 5. Benchmark ponta a ponta com COPY

Rodar o fluxo real download → parse → COPY → gates → promote, com dados
sintéticos (100k e 500k linhas; se o ambiente suportar, repetir com um ano real
pequeno). Medir e registrar por escala:
- tempo de download; tempo de parse; tempo de COPY; tempo dos quality gates;
  tempo de promoção; duração total; memória de pico; throughput (linhas/s);
  nº de requisições (deve ser baixo — COPY é uma conexão, não milhares de POSTs).
- Verificar memória: o processo deve ficar estável (streaming) — **sem** crescer
  proporcional ao dataset (prova de que não acumula em RAM).

Comando de referência (COPY via `copy_backend.py`, exige `TSE_PG_DSN`):
```bash
TSE_PG_DSN="$TSE_PG_DSN" .venv/bin/python - <<'PY'
# harness de benchmark: gera N linhas sintéticas, COPY para staging, promove;
# imprime tempos e pico de memória (resource.getrusage). NÃO usa dado pessoal.
PY
```

## 6. Teste de concorrência (duas conexões)

```bash
TSE_IT_PGURL="$TSE_IT_PGURL" .venv/bin/python -m pytest \
  ingestao/tse/tests/test_concurrency_psycopg.py -v
```
Registrar da saída: início da transação A; aquisição do lock por A; tentativa de
B; tempo de espera de B; commit de A; aquisição por B; estado final (uma
promoção venceu, contagem consistente, sem DELETE concorrente).

## 7. Teste de retomada

- Criar um run, gravar `zip_sha256`+`zip_bytes`+`transformer_version`, carregar
  parcialmente (interromper).
- Retomar com o MESMO run_id e MESMO arquivo → confirmar que `ON CONFLICT
  (run_id, identity_key) DO NOTHING` não duplica e completa o que faltava.
- Tentar retomar com hash/tamanho/versão DIFERENTE → confirmar que exige NOVO
  run_id (retomada recusada). Ver `RESUME_PROTOCOL.md`.

## 8. Teste de rollback

- Forçar falha no INSERT final (trigger de veneno numa linha sentinela) durante
  o swap → confirmar que a transação inteira reverte e a tabela FINAL permanece
  exatamente como antes (contagem e linhas idênticas).

## 9. Validação de RLS e grants

- Com a `anon key`: `SELECT` em `tse_*_staging`/`tse_load_runs` → negado ou vazio;
  `POST /rpc/tse_promote_year` → negado.
- Confirmar `tse_promote_year`/`tse_gc_staging` executáveis só por `service_role`,
  owner `postgres`, `search_path` fixo.

## 10. Critérios objetivos de aprovação

Aprovar SOMENTE se TODOS forem verdadeiros:
- [ ] zero escrita em produção (todas as operações no `IT_REF`);
- [ ] COPY completo sem carga integral em memória (pico estável, streaming);
- [ ] final intocada em todas as falhas (rollback comprovado);
- [ ] staging retomável apenas com mesmo hash + tamanho + `transformer_version`;
- [ ] segunda promoção do mesmo (dataset, ano) AGUARDA o advisory lock;
- [ ] ausência de duplicação na retomada (contagem estável);
- [ ] `source_id` preservado no staging; na final somente se a coluna existir
      (a promoção usa a interseção staging∩final — o schema real de produção
      não tem `source_id` nas finais);
- [ ] `row_fingerprint` válido (`^[0-9a-f]{64}$`) em 100% das linhas (CHECK);
- [ ] contagem final == contagem validada do arquivo (parsed == staged == final);
- [ ] `tse_load_runs` com proveniência completa (zip_sha256, zip_bytes,
      source_url, pipeline_commit, transformer_version; override com pct_drop +
      github ctx quando aplicável);
- [ ] ambiente e secrets eliminados ao final (passos 11–12).

Qualquer item falhando ⇒ reprovado; corrigir e repetir.

## 11. Remoção dos secrets

- `unset TSE_IT_URL TSE_IT_SERVICE_KEY TSE_IT_PGURL TSE_PG_DSN GITHUB_*`.
- Limpar histórico do shell se as strings foram digitadas inline.
- Remover qualquer arquivo temporário de connection string.

## 12. Exclusão do ambiente

- Apagar a branch descartável (Dashboard → Branches → Delete, ou `delete_branch`).
- Confirmar que a branch não aparece mais em `list_branches`.
- Remover ZIPs baixados do CDN (`rm -f /tmp/tse_prest_*.zip`).

---

## Registro de homologação (preencher na execução)

| Item | Resultado | Evidência |
|---|---|---|
| Ambiente criado (IT_REF) | | |
| Migration aplicada | | |
| Testes integrados | | |
| Benchmark 100k/500k (tempos, memória, throughput) | | |
| Concorrência (tempos de lock) | | |
| Retomada (mesmo/diferente hash) | | |
| Rollback | | |
| RLS/grants | | |
| Todos os critérios de aprovação | | |
| Secrets removidos | | |
| Ambiente excluído | | |

Assinado por: ____________  Data: ____________  Veredito: aprovado / reprovado
