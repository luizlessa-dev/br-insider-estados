# Auditoria global de privilégios — produção `redgg…jzhb`

Auditoria **read-only**, executada em 2026-07-18/19. Nenhuma alteração foi
feita em produção nesta auditoria. Todos os achados abaixo foram confirmados
por consulta direta ao catálogo (`pg_class`, `pg_default_acl`,
`information_schema`, `has_table_privilege` etc.) — isso prova que o
**privilégio existe no PostgreSQL**. Não prova, por si só, que o privilégio é
**explorável através da API pública** (PostgREST/Supabase). As duas coisas são
distintas e são tratadas separadamente em cada achado abaixo.

## Metodologia de severidade

- **CRITICAL** — operação destrutiva **+** caminho de exploração
  **comprovado e executável** (testado ao vivo ou mecanismo documentado da
  própria plataforma sem ambiguidade) **+** alto impacto.
- **HIGH** — privilégio destrutivo real concedido no banco, mas a
  explorabilidade remota (via API pública, conexão externa) **ainda não foi
  demonstrada** nesta auditoria.
- **MEDIUM/LOW** — conforme impacto e condições adicionais (ex.: proteção
  estrutural do próprio Postgres torna o grant inerte hoje).

A existência de `TRUNCATE` no catálogo **não** implica automaticamente
CRITICAL — depende de existir caminho comprovado até ele.

## 1. `pg_default_acl` — impacto em objetos futuros

| Role proprietária | Schema | Tipo de objeto | Concede a | Privilégios |
|---|---|---|---|---|
| `postgres` | `public` | **tabelas** | anon, authenticated, service_role, postgres | `arwdDxtm` (SELECT/INSERT/UPDATE/DELETE/TRUNCATE/REFERENCES/TRIGGER/MAINTAIN) |
| `postgres` | `public` | sequences | anon, authenticated, service_role, postgres | `rwU` (SELECT/UPDATE/USAGE) |
| `postgres` | `public` | functions | anon, authenticated, service_role, postgres | `X` (EXECUTE) |
| `postgres` | `storage` | tabelas/sequences/functions | idem acima | idem acima |
| `supabase_admin` | `cron`, `extensions`, `graphql`, `graphql_public`, `realtime`, `public` (2ª entrada) | diversos | variável (algumas só a `postgres`/`dashboard_user`) | variável |
| `supabase_auth_admin` | `auth` | tabelas/sequences/functions | `postgres`, `dashboard_user` | plataforma |

**Achado central — default ACL de `postgres`/`public`/tabelas:**

- **Privilégio no PostgreSQL:** `arwdDxtm` concedido por padrão a
  anon/authenticated/service_role em toda tabela nova criada por `postgres`
  em `public`. Confirmado por consulta direta a `pg_default_acl`.
- **Impacto potencial:** toda tabela nova de aplicação nasceria com escrita
  pública completa, replicando o mesmo padrão que a 0047 corrigiu em apenas
  2 das 344 tabelas existentes.
- **Caminho de exploração comprovado:** nenhum testado nesta auditoria —
  não foi criada nenhuma tabela nova para observar o comportamento real.
- **Caminho de exploração não comprovado:** se uma tabela nova em schema
  exposto pela API (`public`) é imediatamente operável via PostgREST sob
  anon/authenticated assim que criada — **não verificado empiricamente**.
- **Controles compensatórios:** nenhum workflow automatizado cria tabelas
  hoje (§2) — toda criação passa por intervenção humana, que poderia (mas
  não é obrigada a) revogar manualmente após criar.
- **Severidade final: HIGH sistêmico.** Elevável a **CRITICAL** somente se
  um teste futuro em ambiente descartável comprovar que uma tabela nova em
  schema exposto nasce imediatamente operável sob anon/authenticated através
  da API pública (não apenas via catálogo SQL).

**Não incluído no escopo da 0047:** o default ACL em si permanece ativo — a
0047 corrigiu apenas objetos *já existentes* (`tse_receitas`, `tse_despesas`).

## 2. Quem cria objetos normalmente

- **100% dos owners** de tabelas/views/materialized views/sequences nos 7
  schemas de aplicação (`public, public_api, analytics, bcb, cidadania_ai,
  homabrasil, portal_transparencia`) é **`postgres`** — confirmado por
  agregação `distinct owner` por schema (nenhum outro owner encontrado).
- **Nenhum workflow do GitHub Actions** aplica migrations (varredura dos 33
  workflows do repositório: zero ocorrência de `supabase db push`,
  `apply_migration` ou variável de senha de banco).
- O repositório **não tem `supabase/config.toml` nem `supabase/migrations/`**
  — migrations históricas foram aplicadas via API de gestão (MCP/Dashboard),
  sempre autenticadas como `postgres` (confirmado também pela role executora
  da própria 0047: `postgres`).
- **Conclusão:** todo DDL de produção passa por uma única via humana
  (operador com acesso à API de gestão), sempre como `postgres`. Não há
  pipeline automatizado de aplicação de migrations hoje.

## 3. Objetos TSE — inventário completo

A migration 0047 tratou **apenas** `tse_receitas` e `tse_despesas`. A
auditoria global encontrou **13 outros objetos** com privilégios
concedidos a anon/authenticated que vão além de SELECT, não cobertos.

### 3.1 Tabelas com RLS habilitada e zero policies (7 tabelas)

`tse_bens_candidatos`, `tse_candidatos`, `tse_conta_despesa`,
`tse_conta_extrato`, `tse_conta_notafiscal`, `tse_conta_receita`,
`tse_ingest_log` (esta última com 1 policy, que não cobre o achado abaixo).

- **Privilégio no PostgreSQL:** INSERT/UPDATE/DELETE/TRUNCATE/REFERENCES/
  TRIGGER/MAINTAIN concedidos a anon e authenticated, owner `postgres`.
- **Impacto potencial:** perda ou corrupção dos dados dessas tabelas.
- **Caminho de exploração comprovado:** nenhum. RLS habilitada com zero
  policies é *deny-by-default* no PostgreSQL para SELECT/INSERT/UPDATE/DELETE
  — mesmo com o GRANT, essas quatro operações são bloqueadas em tempo de
  execução para qualquer role sujeita a RLS. **Exceção:** `TRUNCATE` **não é
  regido por RLS** no PostgreSQL (comportamento documentado do motor, não
  hipótese) — a policy não o bloqueia.
- **Caminho de exploração não comprovado:** se `TRUNCATE` é alcançável a
  partir da API pública. O PostgREST (camada REST do Supabase) mapeia
  requisições HTTP para SELECT/INSERT/UPDATE/DELETE — **não expõe TRUNCATE
  como operação REST**. Um caminho de exploração exigiria conexão SQL direta
  autenticada como anon/authenticated (mecanismo de acesso não confirmado
  nesta auditoria) ou uma função RPC que execute TRUNCATE internamente
  (nenhuma encontrada).
- **Controles compensatórios:** RLS bloqueia INSERT/UPDATE/DELETE mesmo com
  o grant; ausência confirmada de RPC que exponha TRUNCATE; PostgREST não
  expõe TRUNCATE nativamente.
- **Severidade final: HIGH.** Privilégio destrutivo real (TRUNCATE) existe
  no banco; explorabilidade remota não demonstrada nesta auditoria.

### 3.2 Tabelas sem RLS habilitada (4 tabelas + 1 fora do padrão de nome)

`tse_bens_agg`, `tse_candidatos_receitas_agg`, `tse_receitas_brutas`,
`patrimonio_tse` (owner `postgres`, `patrimonio_tse` encontrada só na busca
ampla por nome — fora do padrão `tse_*`).

- **Privilégio no PostgreSQL:** INSERT/UPDATE/DELETE/TRUNCATE/REFERENCES/
  TRIGGER/MAINTAIN concedidos a anon e authenticated; **RLS desabilitada**
  (`relrowsecurity = false`) — nenhuma camada adicional de proteção.
- **Impacto potencial:** perda ou corrupção dos dados, incluindo via
  INSERT/UPDATE/DELETE (não só TRUNCATE), pois aqui não há RLS bloqueando
  essas operações como no §3.1.
- **Caminho de exploração comprovado:** nenhum testado ao vivo nesta
  auditoria — nenhuma requisição HTTP real foi disparada contra produção.
  O mapeamento PostgREST de POST/PATCH/DELETE para INSERT/UPDATE/DELETE é
  comportamento **documentado e default** da plataforma Supabase (não é uma
  hipótese desta auditoria), mas a combinação específica "grant + RLS off +
  exposição de fato pela API neste projeto" não foi verificada
  empiricamente aqui.
- **Caminho de exploração não comprovado:** confirmação ao vivo (requisição
  real com a `anon` key contra o endpoint REST destas 4 tabelas).
- **Controles compensatórios:** nenhum identificado (sem RLS, sem policy).
- **Severidade final: HIGH**, com nota de que o mecanismo de exposição
  (PostgREST expõe INSERT/UPDATE/DELETE por padrão) é mais direto e melhor
  documentado do que o caso do TRUNCATE em §3.1 — **candidata prioritária**
  para a prova de caminho que elevaria a CRITICAL, mas não classificada
  como tal sem essa prova.

### 3.3 Sequences

| Sequence | anon/authenticated |
|---|---|
| `tse_bens_candidatos_id_seq` | USAGE + UPDATE concedidos |
| `tse_ingest_log_id_seq` | USAGE + UPDATE concedidos |

- **Privilégio no PostgreSQL:** USAGE/UPDATE (nextval/setval).
- **Impacto potencial:** colisão ou manipulação de IDs em inserts legítimos
  feitos por `service_role`; não é, por si só, destrutivo de dados
  existentes.
- **Caminho de exploração comprovado/não comprovado:** mesma limitação do
  §3.2 — depende de exposição via API/RPC, não testada ao vivo.
- **Controles compensatórios:** impacto limitado (não apaga dado existente).
- **Severidade final: MEDIUM.**

### 3.4 Materialized view — `mv_tse_ads_digitais`

- **Privilégio no PostgreSQL:** INSERT/UPDATE/DELETE/**TRUNCATE**/REFERENCES/
  TRIGGER/MAINTAIN concedidos a anon e authenticated — **autorizado no
  banco, confirmado por consulta direta ao catálogo.**
- **Impacto potencial:** perda completa do conteúdo da materialized view.
- **RLS:** **não aplicável** — o PostgreSQL não suporta Row-Level Security em
  materialized views (limitação estrutural do motor, não uma escolha de
  configuração). Diferente das tabelas do §3.1, não há nenhuma camada de
  RLS disponível para mitigar, ainda que se quisesse habilitá-la.
- **Caminho de exploração comprovado:** nenhum. O grant existe; a
  exploração via API/conexão real **ainda precisa ser comprovada** — não foi
  disparada nenhuma requisição real contra produção nesta auditoria.
- **Caminho de exploração não comprovado:** se TRUNCATE é alcançável via
  PostgREST (não é operação REST nativa — mesma ressalva do §3.1) ou via
  alguma outra via de conexão direta como anon/authenticated (não
  confirmada).
- **Controles compensatórios:** ausência de RPC que exponha TRUNCATE;
  PostgREST não expõe TRUNCATE nativamente. **Mas, diferente das tabelas do
  §3.1, não existe RLS como segunda camada** — o grant é a única barreira.
- **Severidade final: HIGH (provisória), elevável a CRITICAL após prova de
  caminho.** Justificativa da provisão: é o único objeto do inventário onde
  a única defesa estrutural possível (RLS) está genuinamente ausente por
  limitação do motor — não por lacuna de configuração corrigível. Recomenda-
  se tratar como prioridade de investigação/prova antes de qualquer outro
  item deste inventário.

### 3.5 Views (`tse_v_*` — 5 views investigativas + 1 fora do padrão)

`tse_v_doador_emenda`, `tse_v_dossie_doador`, `tse_v_financiadores_parlamentar`,
`tse_v_receptor_top`, `tse_v_rede_financiamento`, `v_bets_socios_tse`.

- **Privilégio no PostgreSQL:** INSERT/UPDATE/DELETE/TRUNCATE/REFERENCES/
  TRIGGER concedidos a anon e authenticated (sem MAINTAIN — não aplicável a
  views simples).
- **Propriedades confirmadas:** `is_updatable = NO`, `is_insertable_into =
  NO`, `is_trigger_updatable/deletable/insertable_into = NO`, zero `rules`
  customizadas, zero triggers `INSTEAD OF`. Tabelas-base (via `pg_depend`):
  `emendas_favorecidos`, `parlamentares`, `tse_candidatos`, `tse_receitas`.
- **Impacto potencial:** nenhum hoje (ver caminho comprovado abaixo).
- **Caminho de exploração comprovado (de que o grant é INERTE):** o
  PostgreSQL **rejeita em tempo de execução** qualquer INSERT/UPDATE/
  DELETE/TRUNCATE contra uma view sem regra, sem trigger `INSTEAD OF` e
  `NOT is_updatable/insertable_into` — isto é comportamento documentado do
  motor (não hipótese), verificável pelas próprias colunas de
  `information_schema.views` consultadas.
- **Caminho de exploração não comprovado:** nenhum — a ausência de
  exploração é a conclusão comprovada, não uma lacuna de prova.
- **Controles compensatórios:** a própria estrutura da view.
- **Severidade final: LOW, não INFORMATIONAL** — risco **latente**: se a
  definição de qualquer uma das 6 views mudar no futuro para algo
  simples/updatable, o grant passa a ser imediatamente explorável sem que
  ninguém tenha revisado privilégios naquele momento.

### 3.6 Functions TSE

Nenhuma função com prefixo `tse_` existe hoje em produção — confirmado
(`functions_tse: null`). Consistente com o diagnóstico anterior: o safe
pipeline (`0001_tse_safe_pipeline.sql`, incluindo `tse_promote_year` e
`tse_gc_staging`, ambas `SECURITY DEFINER` com `search_path` fixo) segue
**inativo**, nunca aplicado em produção.

- **Severidade final: INFORMATIONAL** — nada a corrigir hoje; o desenho já
  fixa `search_path` para quando/se for aplicado.

### 3.7 Functions SECURITY DEFINER sem search_path fixo (achado geral, não TSE)

15 funções `SECURITY DEFINER` em `public` (fora de extensões). **10 delas não
fixam `search_path`**: `handle_new_user`, `limpar_ask_cache_expirado`,
`refresh_fornecedores_intersetados`, `refresh_almg_fornecedores_intersetados`,
`computar_votacoes_agg`, `alerta_ministerio_sancao`, `alerta_ministerio_emenda`,
`alerta_combo_sancao_emenda`, `alerta_audiencias_semana`,
`alerta_ranking_privados`.

- **Privilégio no PostgreSQL:** execução com privilégios do owner
  (`SECURITY DEFINER`), sem `search_path` fixo no `proconfig`.
- **Impacto potencial:** um objeto malicioso criado em outro schema mais
  cedo no `search_path` efetivo da sessão poderia ser resolvido no lugar do
  objeto pretendido pela função (escalonamento de privilégio clássico).
- **Caminho de exploração comprovado/não comprovado:** depende de quem pode
  criar objetos nos schemas do `search_path` efetivo da sessão que chama
  cada função — **não avaliado individualmente aqui** (fora do escopo TSE
  desta missão).
- **Controles compensatórios:** não avaliados individualmente.
- **Severidade final: MEDIUM** — registrado para tratamento em iniciativa
  própria, função a função.

## 4. Classificação consolidada por severidade

| Severidade | Achados |
|---|---|
| **HIGH** (provisório, elevável a CRITICAL mediante prova de caminho) | `mv_tse_ads_digitais` (TRUNCATE autorizado no banco, RLS não aplicável — prioridade de investigação); default ACL de `postgres`/`public`/tabelas (raiz sistêmica) |
| **HIGH** | `tse_bens_agg`, `tse_candidatos_receitas_agg`, `tse_receitas_brutas`, `patrimonio_tse` (sem RLS, mecanismo de exposição mais direto — candidatas à próxima prova de caminho); `tse_bens_candidatos`, `tse_candidatos`, `tse_conta_despesa`, `tse_conta_extrato`, `tse_conta_notafiscal`, `tse_conta_receita`, `tse_ingest_log` (RLS mitiga INSERT/UPDATE/DELETE, não mitiga TRUNCATE) |
| **MEDIUM** | `tse_bens_candidatos_id_seq`, `tse_ingest_log_id_seq` (sequences graváveis); default ACL de sequences em `public`; 10 funções SECURITY DEFINER sem search_path fixo |
| **LOW** | As 5 views `tse_v_*` + `v_bets_socios_tse` (grants perigosos, porém comprovadamente inertes hoje pela semântica do Postgres; risco latente a mudança futura de definição) |
| **INFORMATIONAL** | Ausência de funções `tse_*` ativas (0001 confirmado inativo); default ACL de schemas de plataforma (`storage`, `cron`, `auth` etc. — não são schemas de aplicação) |

Nenhum item deste inventário foi classificado CRITICAL nesta auditoria — a
metodologia adotada exige um caminho de exploração comprovado (testado ao
vivo ou mecanismo inequívoco e já documentado da plataforma) antes dessa
classificação, e nenhuma requisição real foi disparada contra produção
durante este trabalho, que permaneceu estritamente read-only ao nível de
catálogo SQL.

## 5. Plano de hardening futuro (proposta — NÃO criada nem aplicada)

Migration hipotética (nome de trabalho: `0048_tse_hardening_completo.sql`),
separada em blocos independentes para permitir aplicação parcial/faseada:

**Bloco 1 — tabelas com RLS e zero policies (§3.1, extensão direta da 0047):**
```sql
revoke insert, update, delete, truncate, references, trigger, maintain
  on table public.tse_bens_candidatos, public.tse_candidatos,
           public.tse_conta_despesa, public.tse_conta_extrato,
           public.tse_conta_notafiscal, public.tse_conta_receita,
           public.tse_ingest_log
  from anon, authenticated;
```
Risco: baixo (mesmo padrão já validado pela 0047, mesmos testes aplicáveis).

**Bloco 2 — tabelas sem RLS (§3.2):**
```sql
revoke insert, update, delete, truncate, references, trigger, maintain
  on table public.tse_bens_agg, public.tse_candidatos_receitas_agg,
           public.tse_receitas_brutas, public.patrimonio_tse
  from anon, authenticated;
```
Risco: baixo. Recomenda-se investigar antes se RLS deveria ser habilitada
nestas tabelas (decisão de produto/dado, não só de segurança), já que hoje
não têm nenhuma policy de leitura definida explicitamente.

**Bloco 3 — views (hardening preventivo, mesmo sendo hoje inerte):**
```sql
revoke insert, update, delete, truncate, references, trigger
  on table public.tse_v_doador_emenda, public.tse_v_dossie_doador,
           public.tse_v_financiadores_parlamentar, public.tse_v_receptor_top,
           public.tse_v_rede_financiamento, public.v_bets_socios_tse
  from anon, authenticated;
```
Risco: nenhum (grants hoje inertes; a remoção apenas fecha o risco latente).

**Bloco 4 — materialized view (prioridade de investigação, §3.4):**
```sql
revoke insert, update, delete, truncate, references, trigger, maintain
  on table public.mv_tse_ads_digitais
  from anon, authenticated;
```
Risco: baixo. **Recomenda-se priorizar a investigação/prova de caminho
deste item** — é o único objeto sem nenhuma camada de RLS possível — e,
independentemente do resultado da prova, o REVOKE preventivo tem custo e
risco mínimos, podendo justificar uma migration isolada antes do pacote
completo.

**Bloco 5 — sequences:**
```sql
revoke usage, update on sequence
  public.tse_bens_candidatos_id_seq, public.tse_ingest_log_id_seq
  from anon, authenticated;
```

**Bloco 6 — default privileges (a correção sistêmica, tratada à parte por
maior impacto e reversibilidade mais delicada):**
```sql
alter default privileges for role postgres in schema public
  revoke insert, update, delete, truncate, references, trigger, maintain
  on tables from anon, authenticated;
alter default privileges for role postgres in schema public
  revoke usage, update on sequences from anon, authenticated;
```
Isto **não afeta objetos existentes** — só muda o padrão para tabelas/sequences
**futuras**. É complementar aos blocos 1–5, não substituto.

**Bloco 7 — functions SECURITY DEFINER sem search_path** (separado, maior
superfície de teste — cada função precisa de revisão individual do
`search_path` correto antes de fixar): não redigido aqui; requer decisão
função a função.

Nenhum destes blocos foi criado como arquivo de migration nem aplicado.
