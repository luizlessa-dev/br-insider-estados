# PROVA 2 — Execução Local do Baseline (2026-07-22)

## 1. Resumo executivo

A PROVA 2 foi executada integralmente em ambiente Supabase **local e descartável**,
via Docker, dentro de um worktree Git isolado fixado no commit auditado
`f49df17908af1698149765f0fe6518189fb1500d`. Dois ciclos completos de
`supabase init` → `supabase start` → `supabase db reset` foram executados,
ambos com **exit code 0**, hardening TSE (incluindo `MAINTAIN`) confirmado e
**11/11 digests estruturais idênticos** ao manifesto `digests_esperados.txt`.
Uma terceira execução manual isolada (mesmo fluxo, mesmo commit, mesmas
versões) foi usada exclusivamente para consultas `SELECT` read-only antes do
cleanup automático do script oficial. Nenhuma ação remota, de escrita, ou de
homologação foi realizada. Um achado relevante contraria uma suposição do
enunciado (tabela `stf_ingestao_log` existe — ver seção 26).

## 2. SHA

- Commit auditado e usado em todas as execuções: `f49df17908af1698149765f0fe6518189fb1500d`
  (`chore(db): materializa baseline validado e restaura hardening MAINTAIN do TSE (#11)`, 2026-07-21 23:48:56 -0300)
- Digest do baseline montado a partir dos 17 blocos (drift-check): `604ad11b895d5323…` (SHA-256, 16 chars exibidos pelo script)

## 3. Worktree utilizado

- Caminho: `/Users/luizlessa/br-insider-worktrees/prova2-local-f49df17`
- Criado via `git worktree add --detach` a partir de `/Users/luizlessa/brasilia-insider`
- HEAD: detached, exatamente em `f49df17908af1698149765f0fe6518189fb1500d`
- Working tree: limpo antes, durante e depois de toda a execução
- Nenhuma branch Git criada para o worktree

## 4. Estado do checkout principal

- Caminho: `/Users/luizlessa/brasilia-insider`
- Branch local `main`: `ee89e1cb64546c0a2a09a99d3e7bcd60aaed28fb` (não avançou)
- `origin/main`: `f49df17908af1698149765f0fe6518189fb1500d`
- Arquivos modificados/não versionados de outros trabalhos em andamento:
  preservados intactos durante toda a execução — não lidos, não alterados,
  não usados como insumo desta prova
- Nenhum `git pull`, `merge`, `rebase`, `stash`, `checkout` ou `reset` foi
  executado no checkout principal
- Worktree previamente existente `prova1c-revalidacao` (caminho diferente):
  não tocado

## 5. Versão da CLI

- `supabase --version` → `2.109.0` (confirmado, exatamente a versão esperada)

## 6. Versão/imagem PostgreSQL

- Imagem observada em execução durante o ciclo manual de consultas (capturada
  ao vivo via `docker ps` antes do cleanup, container
  `supabase_db_baseline-verify-XXXXXX...`): `public.ecr.aws/supabase/postgres:17.6.1.140`
- `SELECT version()` no banco local: `PostgreSQL 17.6 on aarch64-unknown-linux-gnu, compiled by gcc (GCC) 15.2.0, 64-bit`
- Ressalva: a afirmação prévia "PostgreSQL 17.6.1.063 é idêntico à produção"
  (item 6 da Parte I) **não pôde ser confirmada e diverge da versão observada
  localmente** (`.140`, não `.063`). Não houve acesso remoto nesta prova para
  comparar com produção — classificado como informação ainda dependente de
  inspeção remota, e a citação de `.063` é uma inconsistência a esclarecer,
  não um fato confirmado.
- **Origem das duas versões (comprovado por arquivo versionado, revisão
  pós-execução)**: `.063` está documentada em `db/baseline/README.md:33` e
  em `db/baseline/BASELINE_METADATA.md` (linhas 14, 28 e 86 — a linha 14 é
  a origem textual da própria afirmação "idêntica à de produção", nunca
  verificada por inspeção remota em nenhum artefato lido nesta auditoria).
  `.140` já havia sido observada **antes** desta PROVA 2, na evidência da
  PROVA 1C (`db/baseline/evidence/PROVA1C_PORTABILIDADE_E_DRIFT.md:112`) —
  ou seja, a divergência `.063` vs `.140` não é nova nem específica desta
  execução, é uma inconsistência pré-existente entre a documentação
  estática do baseline (`BASELINE_METADATA.md`, de 2026-07-18) e o que o
  Supabase CLI atual efetivamente provisiona. `supabase/config.toml` fixa
  apenas `major_version = 17`; não há, em nenhum script (`50_baseline_verify.sh`,
  `60_drift_check.sh`) ou arquivo de configuração do worktree, qualquer
  fixação da imagem `postgres` por patch/build específico — consistente com
  a hipótese de que a imagem exata é resolvida pela versão do Supabase CLI
  instalada (`2.109.0` nesta execução), não pelo baseline. **Não há
  evidência, em nenhum artefato local, de comparação real com o Postgres de
  produção** — a afirmação "idêntica à de produção" deve ser tratada como
  não comprovada e substituída, nesta e em qualquer evidência futura, por
  algo como "imagem utilizada no ambiente local desta prova". Correção de
  `BASELINE_METADATA.md`/`README.md` está fora do escopo desta missão (só o
  documento de evidência pode ser alterado aqui) — recomenda-se abrir essa
  correção como item separado.

## 7. Estado do Docker

- Docker daemon: ativo
- Containers pré-existentes (não pertencentes a esta prova, não interrompidos):
  stack completa `supabase_*_gastronomizae` (12 containers, projeto
  Gastronomizaê, ocupando as portas padrão 54321-54327/54322/54323/54324)
- Colisão de porta identificada com as portas padrão do Supabase local →
  resolvida usando o **offset padrão já embutido no script**
  (`BASELINE_VERIFY_PORT_OFFSET` não definido, default `1500` usado,
  documentado no próprio `50_baseline_verify.sh`). Portas com offset 1500
  (55821–55827) confirmadas livres antes da execução.
- Containers efêmeros da prova (ciclo 1, ciclo 2, ciclo de consultas): cada
  um criado com nome único via `mktemp` e destruído automaticamente pelo
  `trap cleanup EXIT` de cada execução (`supabase stop --no-backup` + `rm -rf`
  do diretório temporário)
- Pós-execução: containers idênticos à lista pré-existente em todas as
  verificações (diff vazio) — zero resíduo da prova em qualquer ciclo
- Volumes Docker: 4 antes, 4 depois (inalterado)

## 8. Espaço em disco

- Antes da prova: `228Gi` total, `192Gi` usado, **`6.5Gi` livre (97% de uso)**
- Durante a prova (mínimo observado): `4.4Gi` livre (98% de uso)
- Depois da prova: disco permaneceu estável na faixa de ~4-5Gi livres — sem
  esgotamento, mas **margem apertada**. Isso é registrado como risco/ressalva
  (seção 27): a máquina está operando com pouco espaço livre; execuções
  futuras do mesmo tipo devem monitorar disco antes de iniciar.
- Nenhum volume ou imagem Docker foi removido/limpo globalmente durante esta
  prova (sem `docker system prune`, sem limpeza de containers alheios)

## 9. Comandos executados literalmente

```
git -C /Users/luizlessa/brasilia-insider worktree add --detach \
  /Users/luizlessa/br-insider-worktrees/prova2-local-f49df17 \
  f49df17908af1698149765f0fe6518189fb1500d

git diff --check
bash -n db/baseline/tools/30_montar.sh
bash -n db/baseline/tools/50_baseline_verify.sh
bash -n db/baseline/tools/60_drift_check.sh
./db/baseline/tools/60_drift_check.sh

./db/baseline/tools/50_baseline_verify.sh          # ciclo 1
./db/baseline/tools/50_baseline_verify.sh          # ciclo 2 (mesmo comando, mesmo offset default)
```

Reprodução manual isolada (autorizada pela Parte H, sem alterar nenhum script
versionado — script auxiliar local não commitado, com `set -euo pipefail` e
`trap cleanup EXIT`), usando exatamente os mesmos passos do
`50_baseline_verify.sh` (mesma migration montada por `30_montar.sh`, mesmo
`supabase init`/`start`/`db reset`, mesmo offset de porta 1500):

```
./tools/30_montar.sh blocks "$TMPDIR/baseline.sql"
supabase init --force --yes
supabase start
supabase db reset
psql -h 127.0.0.1 -p <porta> -U postgres -d postgres -Atc "<SELECT ...>"   # apenas SELECTs, ver seção 11
supabase stop --no-backup   # cleanup via trap
```

Nenhum comando usou `--linked`, `--db-url` remoto, DSN remoto, ou
credenciais reais de produção. Confirmado por grep nos scripts (seção 6) e
por inspeção direta de cada comando executado.

## 10. Timestamps

| Evento | UTC |
|---|---|
| Preflight checkout principal | 2026-07-22T13:1x (aprox.) |
| Criação do worktree | precede drift-check |
| Drift-check | início 13:13:25Z, fim 13:13:26Z |
| Ciclo 1 — início | 13:13:50Z (pré-check) |
| Ciclo 1 — fim | 13:21:49Z |
| Ciclo 2 — início | 13:26:18Z |
| Ciclo 2 — fim | 13:29:04Z |
| Consultas manuais — início `supabase start` | 13:37:33Z |
| Consultas manuais — `db reset` concluído | 13:39:04Z |
| Consultas manuais — fim | 13:39:04Z |

## 11. Exit codes

- `git diff --check`: 0
- `bash -n` (30, 50, 60): 0 cada
- `60_drift_check.sh`: 0
- `50_baseline_verify.sh` ciclo 1: **0**
- `50_baseline_verify.sh` ciclo 2: **0** (confirmado via ausência de `FALHA` no log e presença da linha `baseline-verify: OK`, já que o processo rodou em background e o exit status via `wait` entre invocações separadas de shell não é confiável — o log é a fonte de verdade e foi inspecionado diretamente)
- Script manual de consultas: 0 (sem `FALHA` no output, todas as queries retornaram)

## 12. Resultado do drift-check

```
drift-check: OK — migration versionada idêntica aos 17 blocos (604ad11b895d5323…)
```

Exit code 0. `git status --short` no worktree permaneceu vazio antes e depois
— nenhuma alteração persistida por este passo (o script monta em arquivo
temporário via `mktemp`, nunca sobrescreve a migration versionada).

## 13. Primeiro ciclo

Comando: `./tools/50_baseline_verify.sh` (offset padrão 1500, sem override)

```
baseline-verify: OK (aplicação limpa + hardening inclusive MAINTAIN + digests idênticos) [ambiente canônico: supabase db reset]
```

- `supabase init`: concluído (sem log persistido — o script usa `TMPDIR`
  efêmero removido pelo `trap`; a mensagem final de sucesso é a evidência
  disponível, já que o script não deve ser alterado para persistir logs
  intermediários)
- `supabase start`: concluído (sem erro; do contrário o script teria
  impresso `FALHA: supabase start` e retornado exit≠0)
- `supabase db reset`: concluído, confirmado internamente pelo próprio
  script via grep por `Finished supabase db reset` e ausência de `^ERROR:`
- Hardening TSE (incluindo `MAINTAIN`): confirmado (do contrário teria
  impresso `FALHA: hardening TSE ausente`)
- Digests: 11/11 idênticos ao manifesto (do contrário teria impresso
  `DIVERGÊNCIA nos digests` e retornado exit≠0)
- Containers antes/depois: idênticos (zero resíduo)
- Disco antes: 5.4Gi livre; depois: 5.4Gi livre (estável)

## 14. Segundo ciclo

Mesmo comando, mesmo offset (1500, default), executado após confirmação de
descarte total da stack do ciclo 1.

```
baseline-verify: OK (aplicação limpa + hardening inclusive MAINTAIN + digests idênticos) [ambiente canônico: supabase db reset]
```

- Imagem Postgres confirmada ao vivo durante este ciclo (via `docker ps`
  enquanto o script rodava em background, antes do cleanup):
  `public.ecr.aws/supabase/postgres:17.6.1.140`, porta `55822` (54322+1500)
- Exit: OK, sem `FALHA`
- Containers antes/depois: idênticos ao ciclo 1 (zero resíduo)
- Disco antes: 5.0Gi livre; depois: 5.0Gi livre (estável)

## 15. Comparação determinística

- `diff` byte a byte entre o log final do ciclo 1 e do ciclo 2: **idêntico**
  (`LOGS_FINAIS_IDENTICOS`)
- Ambos os ciclos reportaram a mesma mensagem de sucesso, o que
  internamente implica: mesma aplicação limpa, mesmo hardening MAINTAIN
  presente, e os mesmos 11/11 digests batendo contra o mesmo manifesto —
  logo os dois ciclos são estruturalmente idênticos entre si (transitividade
  via o mesmo oráculo `digests_esperados.txt`)
- Containers, volumes e portas: mesmo padrão exato nos dois ciclos
- Nenhuma diferença não explicada foi observada. Nenhum critério de parada
  desta seção foi acionado.

## 16. Resultado da análise de idempotência

Análise estática dos 17 blocos (sem executar reaplicação no mesmo banco):

**Idempotentes** (seguro reaplicar sobre um banco já aplicado):
- `00_prelude.sql` — apenas `SET` de sessão
- `01_extensions.sql` — todas `CREATE EXTENSION IF NOT EXISTS`; `pg_cron`
  protegido por bloco `DO $$ ... EXCEPTION WHEN OTHERS` explícito
- `02_schemas.sql` — 7× `CREATE SCHEMA IF NOT EXISTS`
- `04_sequences.sql` — 86× `CREATE SEQUENCE IF NOT EXISTS`
- `05_tables.sql` — 364× `CREATE TABLE IF NOT EXISTS`
- `07_functions.sql` — 37× `CREATE OR REPLACE FUNCTION`
- `11_triggers.sql` — 3× `CREATE OR REPLACE TRIGGER`
- `12_rls.sql` — 224× `ALTER TABLE ... ENABLE/DISABLE ROW LEVEL SECURITY`
  (idempotente por natureza no Postgres)
- `14_comments.sql` — 188× `COMMENT ON` (sempre sobrescreve, idempotente por natureza)
- `15_grants.sql` — 1892 comandos `GRANT`/`REVOKE` (confirmado: 1886 `GRANT`
  + 6 `REVOKE`; o arquivo tem 3784 linhas físicas porque cada comando é
  seguido de uma linha em branco — "1892" refere-se a comandos, não a
  linhas de texto) (idempotente por natureza)
- `16_default_privileges.sql` — `ALTER DEFAULT PRIVILEGES` (idempotente por natureza)
- `17_hardening.sql` — apenas `REVOKE` (idempotente por natureza)

**Parcialmente idempotente:**
- `08_views_e_matviews.sql` — 162× `CREATE OR REPLACE VIEW` (idempotente) +
  31× `CREATE MATERIALIZED VIEW` **sem** `IF NOT EXISTS` (não idempotente)

**Não idempotentes** (falhariam com erro `already exists` numa reaplicação
direta sobre o mesmo schema já populado):
- `03_types_domains.sql` — 6× `CREATE TYPE`, sem guarda (Postgres não
  suporta `IF NOT EXISTS` para `TYPE`)
- `06_constraints.sql` — 613× `ALTER TABLE ... ADD CONSTRAINT`, sem guarda
  (Postgres não suporta `ADD CONSTRAINT IF NOT EXISTS`)
- `08_views_e_matviews.sql` (parte matviews) — 31× sem `IF NOT EXISTS`
- `10_indexes.sql` — 785× `CREATE INDEX`/`CREATE UNIQUE INDEX`, sem guarda
  (Postgres suporta `IF NOT EXISTS` para índices, mas o bloco não usa)
- `13_policies.sql` — 165× `CREATE POLICY`, sem guarda (Postgres não
  suporta `IF NOT EXISTS` para `POLICY`, e nenhum `DROP POLICY IF EXISTS`
  precede a criação)

**Conclusão da Parte G**: uma reaplicação direta do baseline completo sobre
um banco já aplicado **falharia** já no bloco 03 (primeiro `CREATE TYPE`),
antes mesmo de alcançar constraints/índices/policies/matviews. Por isso,
**nenhuma segunda aplicação no mesmo banco foi executada**. Isto é
consistente com o próprio mecanismo usado nos dois ciclos: `supabase db
reset` recria o banco do zero a cada vez (drop + create), nunca reaplica
sobre um schema existente — é exatamente por isso que os ciclos 1 e 2
funcionaram identicamente. O baseline foi desenhado para aplicação limpa,
não para reaplicação idempotente no mesmo schema. **Isto não é tratado como
falha da PROVA 2.**

## 17. SECURITY DEFINER

Consulta local (`pg_proc.prosecdef`, schemas não-sistema):

- Total de funções `SECURITY DEFINER`: **21**
- Com `search_path` explicitamente configurado (via `proconfig`): **11**
- Sem `search_path` fixado: **10**
- Lista das 10 sem `search_path` fixado:
  `public.alerta_audiencias_semana`, `public.alerta_combo_sancao_emenda`,
  `public.alerta_ministerio_emenda`, `public.alerta_ministerio_sancao`,
  `public.alerta_ranking_privados`, `public.computar_votacoes_agg`,
  `public.handle_new_user`, `public.limpar_ask_cache_expirado`,
  `public.refresh_almg_fornecedores_intersetados`,
  `public.refresh_fornecedores_intersetados`

**Reconciliação 15 vs 21 (revisão pós-execução, análise estática de
arquivo, sem novo banco):** a auditoria anterior citou **15** funções
`SECURITY DEFINER` — este número refere-se exclusivamente às funções
definidas pelo próprio baseline em `07_functions.sql`. Contagem direta
desse arquivo (`grep`/parse por função) confirma **exatamente 15**
`CREATE OR REPLACE FUNCTION ... SECURITY DEFINER`, das quais **5** têm
`search_path` fixado e **10** não têm — e essas 10 são **exatamente** a
lista acima (mesmos nomes, mesma ordem de schema/nome). Ou seja, o
número "15" da auditoria anterior está **comprovado por arquivo
versionado** e é um subconjunto exato do "21" observado ao vivo.

Os **6** `SECURITY DEFINER` adicionais (21 − 15) não pertencem a nenhum
dos 17 blocos do baseline — não há nenhuma outra `CREATE FUNCTION` fora
de `07_functions.sql` em todo o baseline (confirmado por busca nos 17
blocos). Logo, são necessariamente objetos criados pela própria
plataforma Supabase/extensões durante `supabase init`/`start` (schemas
como `auth`, `storage`, `realtime`, `extensions`, `cron`, `net`,
`graphql`, `supabase_functions`), não pelo baseline em si. A aritmética
é integralmente consistente com essa hipótese (15 + 6 = 21;
5 + 6 = 11 com `search_path`; 10 + 0 = 10 sem `search_path` — ou seja,
os 6 adicionais teriam todos `search_path` fixado, compatível com a
convenção de hardening da própria plataforma Supabase). **Esta
atribuição específica (quais 6 funções, em qual schema) não foi
reconfirmada por consulta filtrada por schema nesta prova** — permanece
classificada como inferência plausível fortemente restringida pela
aritmética, não como fato comprovado por consulta registrada. Consulta
recomendada para uma futura reprodução (não executada nesta missão):
`select n.nspname, p.proname from pg_proc p join pg_namespace n on
n.oid = p.pronamespace where p.prosecdef and n.nspname not in
('pg_catalog','information_schema') order by 1,2;`

## 18. search_path

Este é um recorte **diferente** do item 17 (que cobre apenas `SECURITY
DEFINER`). A afirmação da auditoria anterior ("32 de 37 funções sem
search_path fixado") refere-se ao total de funções definidas no bloco
`07_functions.sql`, não apenas às `SECURITY DEFINER`. Verificado
**estaticamente**, por leitura direta do arquivo (sem depender de banco):

- Total de `CREATE OR REPLACE FUNCTION` em `07_functions.sql`: **37**
- Com cláusula `SET "search_path" TO '...'` explícita: **5**
- Sem `search_path` fixado: **32**

**Confirmado — bate exatamente com a afirmação original** (fato comprovado
por contagem direta, não inferência).

## 19. RLS

- Tabelas com RLS habilitado (consulta local, `pg_class.relrowsecurity`,
  schemas não-sistema, inclui schemas de infraestrutura Supabase): **252**
- Total de tabelas (`relkind='r'`, schemas não-sistema, incluindo Supabase
  infra como `auth`/`storage`/`realtime`/`vault`): **416**
- Total de tabelas definidas apenas pelo baseline (`05_tables.sql`, 7
  schemas próprios): **364** (confirmado estaticamente e bate com a
  afirmação original)
- Instrução `ALTER TABLE ... ENABLE/DISABLE ROW LEVEL SECURITY` no bloco
  `12_rls.sql`: **224** ocorrências

## 20. Policies

- Estático (bloco `13_policies.sql`, fonte de verdade do baseline): **165**
  `CREATE POLICY`, zero referenciando schemas `storage`/`auth` — **confirma
  exatamente a afirmação original** ("165 policies")
- Live (`pg_policies`, banco completo pós-reset, sem filtro de schema):
  **167** — a diferença de **+2** é atribuída a policies próprias de
  infraestrutura do Supabase (ex.: `storage.objects`, criadas pelo
  `supabase init`/`start`, não pelo baseline). Esta atribuição específica
  **não foi reconfirmada via query adicional filtrada por schema** (para não
  abrir mais um ciclo Docker com o disco apertado) — está marcada como
  inferência plausível, não fato comprovado. A diferença de +2 **não pode
  ser descrita como "sem impacto"**: permanece sem atribuição definitiva
  nesta prova. Revisão estática confirma que os 165 `CREATE POLICY` de
  `13_policies.sql` são todos distintos por `(schema, tabela, nome)` — zero
  duplicata exata — e nenhum referencia `storage`/`auth`/`realtime`/`vault`,
  então a origem dos +2 está necessariamente fora do texto do baseline.
  Consulta recomendada para uma futura reprodução local (não executada
  nesta missão): `select schemaname, count(*) from pg_policies where
  schemaname not in ('pg_catalog') group by 1 order by 1;` — comparando o
  resultado por schema contra os 7 schemas de aplicação do baseline
  isolaria exatamente quais 2 policies adicionais existem e em qual schema
  de plataforma.

## 21. Owners

Consulta local (`pg_tables.tableowner`, contagem por owner):

| Owner | Tabelas |
|---|---|
| postgres | 365 |
| supabase_auth_admin | 23 |
| supabase_admin | 11 |
| supabase_storage_admin | 10 |
| supabase_realtime_admin | 6 |
| supabase_functions_admin | 2 |

(Total inclui tabelas de infraestrutura Supabase, não apenas as 364 do
baseline — por isso a soma ultrapassa 364.)

## 22. Grants

- `15_grants.sql`: 1892 comandos `GRANT`/`REVOKE` (1886 + 6) — natureza
  idempotente confirmada estaticamente (nenhum `GRANT`/`REVOKE` repetido
  gera erro em Postgres)
- `16_default_privileges.sql`: `ALTER DEFAULT PRIVILEGES` para roles
  `postgres`/`anon`/`authenticated`/`service_role`, schema `public`

## 23. MAINTAIN

Consulta local direta:

```sql
select bool_or(has_table_privilege(r,t,'MAINTAIN'))
from unnest(array['anon','authenticated']) r
cross join unnest(array['public.tse_receitas','public.tse_despesas']) t
```

Resultado: **`f`** (false) — confirmado em ambos os ciclos oficiais (via
`50_baseline_verify.sh`, que falharia explicitamente com `FALHA: hardening
TSE ausente` se fosse `t`) e reconfirmado na consulta manual isolada.
`17_hardening.sql` contém `revoke maintain on table public.tse_receitas,
public.tse_despesas from anon, authenticated`, aplicado por último,
sobrepondo o bloco 15.

## 24. Dados

- `select count(*) from public.tse_receitas` → **0**
- `select count(*) from public.tse_despesas` → **0**
- Soma de `n_live_tup` (`pg_stat_user_tables`, schema `public`, todas as
  tabelas): **0**

Confirmado: zero linhas em qualquer tabela de aplicação após `supabase db
reset`, como esperado para um baseline estrutural (sem seed de dados).

## 25. Cron

- Extensão `pg_cron`: **instalada** (`pg_extension` contém 1 linha para
  `pg_cron`)
- `cron.job`: schema/tabela existe; **0** linhas — confirmado
  (`select count(*) from cron.job` → 0, quando a tabela existe)

## 26. Objetos STF — achado relevante (revisado e ampliado na auditoria)

A suposição do enunciado (Parte H) de que as tabelas `stf_processos`,
`stf_decisoes`, `stf_partes` e `stf_ingestao_log` estariam **todas
ausentes** por serem obsoletas **não se confirmou integralmente**. A
versão original desta seção subestimava o alcance real: uma varredura
estática de todos os 17 blocos (não apenas de `05_tables.sql`) encontra
**sete** tabelas `stf_*` ativas no baseline atual, não três.

**Tabelas `stf_*` no baseline atual** (todas em `public`, todas
confirmadas em `05_tables.sql`):

| Tabela | RLS (`12_rls.sql`) | Policies (`13_policies.sql`) | Grants (`15_grants.sql`) |
|---|---|---|---|
| `stf_assinaturas` | habilitado (linha 396) | 1 (`usuario ve propria assinatura`, linha 330) | anon/authenticated/service_role |
| `stf_gastos` | **ausente** | 0 | anon/authenticated/service_role |
| `stf_ingestao_log` | habilitado (linha 398) | **0** | anon/authenticated/service_role |
| `stf_ministros` | **ausente** | 0 | anon/authenticated/service_role |
| `stf_processos_politicos` | **ausente** | 0 | anon/authenticated/service_role |
| `stf_repercussao_geral` | **ausente** | 0 | anon/authenticated/service_role |
| `stf_votacoes` | **ausente** | 0 | anon/authenticated/service_role |

- `stf_processos`, `stf_decisoes`, `stf_partes`: **ausentes** (confirmado,
  zero ocorrências nos 17 blocos)
- `stf_ingestao_log`: **PRESENTE**, definida em `05_tables.sql` (linha
  4950), com sequence própria (`stf_ingestao_log_id_seq`), PK, constraint
  `UNIQUE(dataset, arquivo_hash)`, RLS habilitado (`12_rls.sql:398`) e
  grants concedidos a `anon`/`authenticated`/`service_role`
  (`15_grants.sql`). **Nuance não capturada na versão original desta
  seção**: `stf_ingestao_log` tem RLS habilitado mas **zero** `CREATE
  POLICY` associada em `13_policies.sql`. Sob a semântica padrão do
  Postgres, RLS habilitado sem nenhuma policy resulta em **negação total**
  de linhas para qualquer role sujeita a RLS (todas exceto roles com
  `BYPASSRLS`, tipicamente apenas roles internas do Supabase) —
  independentemente dos grants de tabela concedidos. Ou seja, os grants
  para `anon`/`authenticated` existem mas são, na prática, inertes para
  leitura/escrita de linhas nessa tabela sem um papel com `BYPASSRLS`
  (como `service_role`, dependendo da configuração local).
- A versão original desta seção citava, ao todo, apenas três tabelas
  `stf_*` ativas por nome: `stf_ingestao_log`, `stf_ministros` e
  `stf_processos_politicos` — sem analisar RLS/policies de nenhuma das
  duas últimas. A varredura desta auditoria encontra **quatro tabelas
  `stf_*` adicionais, nunca citadas em nenhuma versão do documento**:
  `stf_assinaturas`, `stf_gastos`, `stf_repercussao_geral` e
  `stf_votacoes`. Total: sete tabelas `stf_*` no baseline atual (ver
  tabela acima), todas com constraints e grants completos.
- Das sete, **apenas `stf_assinaturas` e `stf_ingestao_log` têm RLS
  habilitado** (`stf_assinaturas` com uma policy correspondente;
  `stf_ingestao_log` sem nenhuma, ver nuance acima). As outras cinco —
  `stf_gastos`, `stf_ministros`, `stf_processos_politicos`,
  `stf_repercussao_geral`, `stf_votacoes` — **não têm RLS habilitado em
  `12_rls.sql`**, e ainda assim recebem `GRANT ALL` para `anon` em
  `15_grants.sql`. Isto pode ser intencional (dados de referência/leitura
  pública sem necessidade de RLS por linha), mas não é discutido nem
  justificado em nenhum artefato do baseline lido nesta auditoria —
  reportado aqui como observação factual, sem juízo sobre se é correto ou
  não, por estar fora do escopo desta revisão (que não avalia adequação de
  política de segurança, apenas reconcilia afirmações).

**Achado adicional (novo, não presente em nenhuma versão anterior do
documento): função órfã `stf_refresh_matviews()`.** A função
`public.stf_refresh_matviews()`, definida em `07_functions.sql`, tem o
seguinte corpo:

```sql
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY stf_ministros_perfil;
    REFRESH MATERIALIZED VIEW CONCURRENTLY stf_tendencia_classe;
    REFRESH MATERIALIZED VIEW CONCURRENTLY stf_tendencia_orgao;
END;
```

Nenhuma das três materialized views referenciadas
(`stf_ministros_perfil`, `stf_tendencia_classe`, `stf_tendencia_orgao`)
existe em `08_views_e_matviews.sql` ou em qualquer outro bloco do
baseline atual — confirmado por busca nos 17 blocos (zero ocorrências
como definição). Essas três matviews **existiam** na migration antiga
`db/migrations/0011_stf_schema.sql` (linhas 123, 159, 201), mas foram
removidas em algum momento entre `0011` e o baseline atual, **sem que a
função que as atualiza fosse removida ou atualizada junto**. Na prática,
`stf_refresh_matviews()` está presente no baseline mas **falharia em
tempo de execução** (`relation "stf_ministros_perfil" does not exist") se
fosse chamada — um remanescente órfão, não detectado em nenhuma auditoria
anterior nem na execução original da PROVA 2. Este achado é puramente
estático (leitura de arquivo versionado); não foi testado em runtime
nesta auditoria (executar a função abriria uma nova sessão de banco, fora
do escopo autorizado). `db/migrations/0011_stf_schema.sql` **não foi
alterada** nesta auditoria, conforme guardrail.

**Conclusão revisada sobre `0011_stf_schema.sql`**: a afirmação original
desta seção ("isto contradiz a afirmação prévia de que
`0011_stf_schema.sql` está obsoleta") estava incompleta. A avaliação mais
precisa é: `0011_stf_schema.sql` está **parcialmente substituída**, não
integralmente obsoleta e não integralmente vigente:
- As três tabelas de ingestão bruta que definia (`stf_processos`,
  `stf_decisoes`, `stf_partes`) foram removidas do baseline atual.
- As três materialized views que definia (`stf_ministros_perfil`,
  `stf_tendencia_classe`, `stf_tendencia_orgao`) também foram removidas.
- A tabela `stf_ingestao_log` que definia permanece ativa, idêntica em
  função aparente, no baseline atual.
- Um remanescente da função de refresh dessas matviews
  (`stf_refresh_matviews()`) permanece no baseline atual, órfão e
  provavelmente quebrado.
- O modelo STF atual do baseline é bem mais amplo do que o de `0011`:
  inclui seis tabelas (`stf_assinaturas`, `stf_gastos`, `stf_ministros`,
  `stf_processos_politicos`, `stf_repercussao_geral`, `stf_votacoes`) que
  `0011_stf_schema.sql` nunca definiu — vieram de migrations posteriores
  não identificadas nesta auditoria (fora do escopo desta revisão
  determinar exatamente quais).

Não foi feita nenhuma tentativa de "corrigir" ou remover este achado —
apenas reportado, conforme instruído.

## 27. Riscos e ressalvas

1. **Disco em ~4-6Gi livres (97-98% de uso)** durante toda a execução.
   Nenhum esgotamento ocorreu, mas a margem é pequena; execuções futuras
   devem checar disco antes de iniciar e considerar liberar espaço.
2. **Logs intermediários de `supabase start`/`db reset` não são persistidos**
   pelo script oficial (por design: `trap cleanup EXIT` remove o `TMPDIR`
   assim que o script termina, com sucesso ou falha, exceto pelas últimas
   10 linhas impressas em caso de `FALHA`). Confirmado por leitura direta
   de `db/baseline/tools/50_baseline_verify.sh` (linhas 26-31: `TMPDIR` +
   `trap cleanup EXIT`; linhas 50-56: `start.log`/`reset.log` gravados
   apenas dentro de `$TMPDIR`) — não é apenas uma inferência do
   comportamento observado, é comprovado pelo próprio código do script. Em
   ambos os ciclos bem-sucedidos, a única evidência textual disponível é a
   mensagem final de sucesso — não é uma falha desta prova, é uma
   limitação de design do script (que não foi alterado, conforme
   guardrail). Por isso, a expressão "byte a byte idênticos" na seção 15
   deve ser lida estritamente como "a única linha de log final impressa em
   cada ciclo foi idêntica" — não como "os logs completos de execução
   foram comparados byte a byte" (esses logs completos não existem mais
   após cada ciclo).
3. **Divergência de versão PostgreSQL**: a afirmação prévia cita
   `17.6.1.063`; o ambiente local rodou `17.6.1.140`. Não verificável contra
   produção nesta prova (sem acesso remoto autorizado). Revisão pós-execução
   (ver seção 6) localiza a origem de cada número: `.063` vem de
   `BASELINE_METADATA.md`/`README.md` (documentação estática do baseline,
   nunca verificada contra produção); `.140` já havia sido observada
   independentemente na PROVA 1C, antes desta prova — não é uma divergência
   nova.
4. **Achado STF** (seção 26): suposição do enunciado parcialmente incorreta.
   A revisão desta auditoria ampliou substancialmente o achado original:
   sete tabelas `stf_*` ativas (não três), das quais cinco sem RLS habilitado
   apesar de `GRANT ALL` a `anon`; `stf_ingestao_log` com RLS habilitado mas
   zero policies (efetivamente sem acesso por linha para roles sujeitas a
   RLS); e uma função órfã (`stf_refresh_matviews()`) que referencia três
   materialized views inexistentes no baseline atual e provavelmente
   falharia se executada. `0011_stf_schema.sql` está parcialmente, não
   integralmente, substituída — ver detalhamento ampliado acima.
5. **Contagem de policies ao vivo (167) vs. estática (165)**: diferença de
   +2 **permanece sem atribuição definitiva** — não reconfirmada por query
   adicional (ver seção 20 para a consulta recomendada). Não deve ser lida
   como "sem impacto"; é uma lacuna de evidência a fechar em reprodução
   futura.
6. Nenhum dos riscos acima impediu a conclusão da prova nem indicou
   comportamento inesperado do mecanismo de aplicação do baseline em si
   (drift-check, digests, hardening MAINTAIN, cleanup). Os achados STF
   (item 4) e a lacuna de policies (item 5) são achados sobre o *conteúdo*
   do baseline, não sobre a validade da execução local da PROVA 2.

## 28. Critérios de parada

Nenhum critério de parada foi acionado. Não houve divergência entre ciclos,
não houve falha de drift-check, não houve necessidade de reaplicação no
mesmo banco (evitada preventivamente pela análise de idempotência), e não
houve impossibilidade de isolar a stack local.

## 29. Cleanup

- Stack do ciclo 1: destruída automaticamente pelo próprio script
  (confirmado: containers pós-ciclo idênticos aos pré-existentes)
- Stack do ciclo 2: idem
- Stack do ciclo manual de consultas: idem (confirmado após a execução:
  "nenhum residual (esperado, cleanup automatico)")
- Nenhuma stack externa (`gastronomizae`) foi interrompida em nenhum momento
- Diretórios temporários (`mktemp`): removidos pelo `trap` de cada execução
- Worktree isolado: **mantido** para revisão (não removido, conforme
  instrução da Parte L)
- Checkout principal: permanece exatamente como estava no preflight (branch
  `main` em `ee89e1c`, arquivos em andamento intactos)

## 30. Conclusão

Os dois ciclos oficiais do `50_baseline_verify.sh` e o ciclo manual de
consultas produziram resultados consistentes: aplicação limpa do baseline,
hardening TSE (incluindo `MAINTAIN`) presente, 11/11 digests estruturais
idênticos, zero dados, zero cron jobs, e cleanup completo em todos os casos.
A análise estática de idempotência confirma que o baseline foi desenhado
para aplicação limpa via `supabase db reset`, não para reaplicação direta no
mesmo schema — comportamento consistente com o observado. Um achado não
trivial (tabela `stf_ingestao_log` ativa, contrariando a suposição de que
todas as tabelas STF citadas estariam ausentes) foi identificado e reportado
sem tentativa de correção. A decisão local está detalhada na seção seguinte.

---

## Decisão

**B. PROVA 2 local aprovada com ressalvas.**

Ressalvas: disco em margem apertada durante toda a execução (seção 27.1);
apenas a linha final de log de cada ciclo está disponível como evidência,
não os logs completos (seção 27.2); divergência de versão PostgreSQL citada
previamente (`.063`, de `BASELINE_METADATA.md`, nunca verificada contra
produção) vs. observada localmente (`.140`), não verificável sem acesso
remoto e já visível desde a PROVA 1C (seção 27.3); achado STF ampliado
nesta auditoria — sete tabelas `stf_*` ativas (não três), cinco sem RLS
apesar de `GRANT ALL` a `anon`, `stf_ingestao_log` com RLS mas zero
policies, e uma função órfã (`stf_refresh_matviews()`) que referencia
matviews inexistentes no baseline atual (seção 26 e 27.4); diferença de +2
entre contagem estática (165) e ao vivo (167) de policies permanece sem
atribuição definitiva, não apenas "sem impacto" (seção 27.5); reconciliação
15→21 de funções `SECURITY DEFINER` explicada por aritmética consistente
mas não confirmada por consulta filtrada por schema (seção 17). Nenhuma
dessas ressalvas indica falha do **mecanismo de aplicação** do baseline —
todas as provas estruturais (digests, hardening MAINTAIN, cleanup) passaram
nos dois ciclos. As ressalvas sobre STF e sobre a contagem de policies são,
no entanto, achados sobre o **conteúdo** do baseline que merecem
acompanhamento antes de qualquer decisão de homologação remota.

Esta decisão refere-se **exclusivamente à reprodução local** e **não
autoriza homologação remota, aplicação em produção, ou qualquer ação sobre
o projeto Supabase `redggdtakzmsabwvjzhb`**.

---

## Adendo — atividade externa concorrente no checkout principal

Durante a revisão final (Parte L), constatou-se que o checkout principal
(`/Users/luizlessa/brasilia-insider`) avançou de `ee89e1cb64546c0a2a09a99d3e7bcd60aaed28fb`
(estado do preflight, Parte A) para `15b7801abb4ebfbb5457d08fa6698ad226c4f88c`.

Investigação via `git reflog show main` confirma a causa: um commit local
(`d772f61`, 2026-07-22 10:40:20 -03:00, `feat(subradar-pj): Infosimples CND
27 UFs + BNDES Devedores`) seguido de `git pull --rebase origin main`
(concluído 2026-07-22 10:40:30 -03:00, rebaseando sobre `f49df179` /
`origin/main`, resultando em `15b7801`). Esses dois eventos ocorreram
**dentro da janela desta sessão, mas nenhum deles foi executado por este
agente** — nenhum comando `git commit`, `git pull` ou `git rebase` foi
executado no checkout principal em nenhum momento desta prova (todas as
interações com o checkout principal, listadas na seção 9, foram
estritamente read-only, mais a criação do worktree via `worktree add`, que
não move o branch `main`). A explicação mais plausível é atividade
concorrente do usuário em outra sessão/terminal.

Isso não invalida a PROVA 2: toda a execução (drift-check, dois ciclos,
consultas) ocorreu inteiramente dentro do worktree isolado, detached em
`f49df179`, sem qualquer dependência do estado do checkout principal após
sua criação. Os arquivos em andamento (modificados/não versionados)
permanecem intactos e idênticos aos observados no preflight — apenas o
ponteiro do branch `main` avançou, por ação externa.

**Declaração final:**

A PROVA 2 foi executada exclusivamente em ambiente Supabase local e
descartável. Não houve supabase link, db push, migration repair, alteração
de schema_migrations, criação de projeto ou branch Supabase, execução de
loaders, alteração de dados remotos, homologação ou qualquer ação em
produção.
