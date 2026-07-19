# Evidência de aplicação — migration 0047

Registro documental, sem dados sensíveis de conexão. Não é usado como fonte de
verdade para `schema_migrations` (esse registro continua exclusivamente no
banco); este arquivo é o rastro auditável do lado do repositório.

| Campo | Valor |
|---|---|
| Arquivo | `db/migrations/0047_tse_revoke_privilegios_escrita.sql` |
| Checksum SHA-256 | `cff2481223eb1fd5eda356f96bccfa8d7925da15dbb1001843fd3c49108d0ec5` |
| Merge SHA que introduziu o arquivo | `d308f9a` ([PR #7](https://github.com/luizlessa-dev/br-insider-estados/pull/7)) |
| Projeto Supabase | `redgg…jzhb` (ref mascarado — documento público) |
| Data/hora de aplicação (UTC) | início `2026-07-18T23:56:22.3Z` — fim `2026-07-18T23:56:30.3Z` |
| Duração | ≈ 8 segundos |
| Role executora | `postgres` (`current_user` = `session_user` = `postgres`) |
| Método | transação única via SQL direto — `BEGIN; SET LOCAL lock_timeout='5s'; SET LOCAL statement_timeout='30s'; <6 REVOKEs da 0047>; COMMIT;` |
| Resultado da transação | COMMIT bem-sucedido — sem erro, sem timeout, sem retry |
| Bloqueio observado | nenhum (`pg_locks` antes/depois: só `AccessShareLock`, sem espera) |

## Contagens (antes / depois — idênticas)

| Tabela | Antes | Depois |
|---|---|---|
| `public.tse_receitas` | 2.312.126 | 2.312.126 |
| `public.tse_despesas` | 6.584.694 | 6.584.694 |

## Matriz de privilégios — antes / depois

Privilégios não-SELECT em `tse_receitas` e `tse_despesas` para `anon` e
`authenticated`:

| Privilégio | Antes | Depois |
|---|---|---|
| INSERT | concedido | revogado |
| UPDATE | concedido | revogado |
| DELETE | concedido | revogado |
| TRUNCATE | concedido | revogado |
| REFERENCES | concedido | revogado |
| TRIGGER | concedido | revogado |
| MAINTAIN | concedido | revogado |
| SELECT | concedido | **preservado** (fora do escopo da 0047) |

Sequences `tse_receitas_id_seq` / `tse_despesas_id_seq` para `anon` e
`authenticated`:

| Privilégio | Antes | Depois |
|---|---|---|
| USAGE | concedido | revogado |
| UPDATE | concedido | revogado |
| SELECT | concedido | **preservado** (inofensivo; fora do escopo) |

`service_role` e `postgres` (owner): conjunto completo de privilégios nas duas
tabelas e nas duas sequences — **inalterado** antes e depois, verificado
explicitamente na pós-auditoria.

RLS (`ON`, sem `FORCE`), 0 policies, owners (`postgres`), contagem de colunas
(22 em `tse_receitas`, 19 em `tse_despesas`) — **idênticos** antes e depois.
Nenhuma alteração de schema.

## Ausência de loader, cron e efeitos colaterais

- `TSE_SAFE_LOADER`: não configurado, antes e depois.
- `TSE_PG_DSN`: não configurado, antes e depois.
- Cron: nenhuma alteração — nenhuma tabela `cron.job` tocada por esta migration.
- Workflows GitHub Actions: nenhum run novo disparado pela aplicação (o `push`
  para a migration não é gatilho de nenhum workflow do repositório).

## Rollback

Um rollback sanitizado (GRANTs específicos, sem `GRANT ALL`, restaurando
exatamente os privilégios do preflight) foi **preparado e mantido fora do
Git** (scratchpad local). **Não foi executado.** Nenhuma dependência legítima
foi encontrada na auditoria de código que exigisse reversão.
