# Auditoria global de privilégios — produção `redggdtakzmsabwvjzhb`

Auditoria **read-only**, executada em 2026-07-18/19. Nenhuma alteração foi
feita em produção nesta auditoria. Todos os achados abaixo foram confirmados
por consulta direta ao catálogo (`pg_class`, `pg_default_acl`,
`information_schema`, `has_table_privilege` etc.), não por inferência.

## 1. `pg_default_acl` — impacto em objetos futuros

| Role proprietária | Schema | Tipo de objeto | Concede a | Privilégios | Impacto |
|---|---|---|---|---|---|
| `postgres` | `public` | **tabelas** | anon, authenticated, service_role, postgres | `arwdDxtm` (SELECT/INSERT/UPDATE/DELETE/TRUNCATE/REFERENCES/TRIGGER/MAINTAIN — tudo) | **CRITICAL** — toda tabela nova criada por `postgres` em `public` nasce publicamente gravável, inclusive por TRUNCATE/MAINTAIN |
| `postgres` | `public` | sequences | anon, authenticated, service_role, postgres | `rwU` (SELECT/UPDATE/USAGE) | HIGH — toda sequence nova é gravável (nextval/setval) por anon/authenticated |
| `postgres` | `public` | functions | anon, authenticated, service_role, postgres | `X` (EXECUTE) | INFORMATIONAL — padrão esperado do Postgres para funções; risco real depende de cada função (ver §3.5) |
| `postgres` | `storage` | tabelas/sequences/functions | idem acima | idem acima | MEDIUM — schema gerenciado pela plataforma; menor superfície de tabelas de aplicação |
| `supabase_admin` | `cron`, `extensions`, `graphql`, `graphql_public`, `realtime`, `public` (2ª entrada) | diversos | variável (algumas só a `postgres`/`dashboard_user`) | variável | INFORMATIONAL — schemas internos da plataforma, não de aplicação |
| `supabase_auth_admin` | `auth` | tabelas/sequences/functions | `postgres`, `dashboard_user` | plataforma | INFORMATIONAL |

**Achado central (CRITICAL):** a entrada `postgres`/`public`/tabelas é a causa-raiz
sistêmica do padrão encontrado em toda a base — não é peculiaridade das
tabelas TSE. **Todas as 344 tabelas de `public`** herdam este default ACL na
criação, a menos que uma migration subsequente revogue explicitamente (como a
0047 fez, table-a-table, para 2 das 344).

**Não incluído no escopo da 0047:** o default ACL em si permanece ativo — a
0047 corrigiu apenas objetos *já existentes* (`tse_receitas`, `tse_despesas`).
Qualquer tabela nova criada hoje em `public` nasce vulnerável de novo.

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
  pipeline automatizado de aplicação de migrations hoje — o que é ao mesmo
  tempo um controle (nada aplica migration sem intervenção humana) e um risco
  de escala (nenhuma verificação automática impede um novo `CREATE TABLE`
  vulnerável).

## 3. Objetos TSE — inventário completo

A migration 0047 tratou **apenas** `tse_receitas` e `tse_despesas`. A
auditoria global encontrou **13 outros objetos** com o mesmo padrão de
privilégio perigoso, não cobertos:

### 3.1 Tabelas

| Tabela | RLS | Policies | anon/authenticated têm | Severidade |
|---|---|---|---|---|
| `tse_receitas` | ON | 0 | — (corrigido pela 0047) | — |
| `tse_despesas` | ON | 0 | — (corrigido pela 0047) | — |
| `tse_bens_candidatos` | ON | 0 | INSERT/UPDATE/DELETE/TRUNCATE/REFERENCES/TRIGGER/MAINTAIN | **HIGH** |
| `tse_candidatos` | ON | 0 | idem | **HIGH** |
| `tse_conta_despesa` | ON | 0 | idem | **HIGH** |
| `tse_conta_extrato` | ON | 0 | idem | **HIGH** |
| `tse_conta_notafiscal` | ON | 0 | idem | **HIGH** |
| `tse_conta_receita` | ON | 0 | idem | **HIGH** |
| `tse_ingest_log` | ON | **1** | idem (TRUNCATE contorna a policy existente) | **HIGH** |
| `tse_bens_agg` | **OFF** | 0 | idem | **CRITICAL** (sem RLS nem grant restritivo) |
| `tse_candidatos_receitas_agg` | **OFF** | 0 | idem | **CRITICAL** |
| `tse_receitas_brutas` | **OFF** | 0 | idem | **CRITICAL** |
| `patrimonio_tse` | **OFF** | 0 | idem (nome fora do padrão `tse_*`, encontrado só na busca ampla) | **CRITICAL** |

Todas com owner `postgres`. Note que `RLS ON` **não neutraliza** o risco
aqui: TRUNCATE ignora policies de RLS por definição do Postgres — a única
defesa real contra TRUNCATE é a ausência do grant, não a RLS.

### 3.2 Sequences

| Sequence | anon/authenticated | Severidade |
|---|---|---|
| `tse_receitas_id_seq` | corrigido pela 0047 | — |
| `tse_despesas_id_seq` | corrigido pela 0047 | — |
| `tse_bens_candidatos_id_seq` | USAGE + UPDATE concedidos | MEDIUM |
| `tse_ingest_log_id_seq` | USAGE + UPDATE concedidos | MEDIUM |

### 3.3 Materialized view

| Objeto | RLS possível? | anon/authenticated têm | Severidade |
|---|---|---|---|
| `mv_tse_ads_digitais` | **Não** (Postgres não suporta RLS em matview) | INSERT/UPDATE/DELETE/**TRUNCATE**/REFERENCES/TRIGGER/MAINTAIN | **CRITICAL** |

Diferente das views simples (§3.4), **`TRUNCATE` funciona em materialized
views** no Postgres — este não é um grant inerte, é diretamente explorável
com a `anon` key pública, e não existe RLS para mitigar. Maior severidade
individual do inventário.

### 3.4 Views (`tse_v_*` — as 5 views investigativas)

`tse_v_doador_emenda`, `tse_v_dossie_doador`, `tse_v_financiadores_parlamentar`,
`tse_v_receptor_top`, `tse_v_rede_financiamento`.

| Propriedade | Valor (as 5 views) |
|---|---|
| `is_updatable` | `NO` |
| `is_insertable_into` | `NO` |
| `is_trigger_updatable/deletable/insertable_into` | `NO` |
| Rules customizadas | nenhuma |
| Triggers `INSTEAD OF` | nenhum |
| Tabelas-base (via `pg_depend`) | `emendas_favorecidos`, `parlamentares`, `tse_candidatos`, `tse_receitas` |
| Grants não-SELECT para anon/authenticated | INSERT/UPDATE/DELETE/TRUNCATE/REFERENCES/TRIGGER (sem MAINTAIN — não aplicável a views simples) |

**Risco concreto: LOW, não CRITICAL, apesar do grant.** Views sem regra,
sem `INSTEAD OF` trigger e `NOT is_updatable/is_insertable_into` **rejeitam
em tempo de execução** qualquer INSERT/UPDATE/DELETE/TRUNCATE — o Postgres
retorna erro antes de tocar dado (`cannot insert/update/delete/truncate a
view`). O grant é hoje **inerte**. Classificado LOW e não INFORMATIONAL
porque é um **risco latente**: se a definição de qualquer uma dessas 5 views
mudar no futuro para algo simples/updatable (ex.: `SELECT * FROM
tse_receitas` sem JOIN), o grant passa a ser imediatamente explorável sem que
ninguém tenha revisado privilégios naquele momento.

Outra view fora do padrão `tse_*`, mesma situação inerte: `v_bets_socios_tse`
(base: sócios TSE) — mesmos grants perigosos, mesma classificação LOW.

### 3.5 Functions TSE

Nenhuma função com prefixo `tse_` existe hoje em produção — confirmado
(`functions_tse: null`). Consistente com o diagnóstico anterior: o safe
pipeline (`0001_tse_safe_pipeline.sql`, incluindo `tse_promote_year` e
`tse_gc_staging`, ambas `SECURITY DEFINER` com `search_path` fixo) segue
**inativo**, nunca aplicado em produção. **INFORMATIONAL** — nada a corrigir
aqui hoje; o desenho já é seguro quando/se for aplicado.

### 3.6 Functions SECURITY DEFINER (achado geral, não TSE)

15 funções `SECURITY DEFINER` em `public` (fora de extensões). **10 delas não
fixam `search_path`**: `handle_new_user`, `limpar_ask_cache_expirado`,
`refresh_fornecedores_intersetados`, `refresh_almg_fornecedores_intersetados`,
`computar_votacoes_agg`, `alerta_ministerio_sancao`, `alerta_ministerio_emenda`,
`alerta_combo_sancao_emenda`, `alerta_audiencias_semana`,
`alerta_ranking_privados`.

**MEDIUM** — `SECURITY DEFINER` sem `search_path` fixo é um vetor clássico de
escalonamento (um objeto malicioso em outro schema mais cedo no `search_path`
efetivo pode ser resolvido no lugar do pretendido). Risco depende de quem
pode criar objetos nos schemas do `search_path` da sessão que chama a função
— não avaliado individualmente aqui (fora do escopo TSE desta missão), mas
registrado para tratamento em iniciativa própria.

## 4. Classificação consolidada por severidade

| Severidade | Achados |
|---|---|
| **CRITICAL** | Default ACL de `public`/tabelas (raiz sistêmica); `tse_bens_agg`, `tse_candidatos_receitas_agg`, `tse_receitas_brutas`, `patrimonio_tse` (sem RLS + grants perigosos); `mv_tse_ads_digitais` (TRUNCATE realmente executável, sem RLS possível) |
| **HIGH** | `tse_bens_candidatos`, `tse_candidatos`, `tse_conta_despesa`, `tse_conta_extrato`, `tse_conta_notafiscal`, `tse_conta_receita`, `tse_ingest_log` (RLS presente mas TRUNCATE a ignora) |
| **MEDIUM** | `tse_bens_candidatos_id_seq`, `tse_ingest_log_id_seq` (sequences graváveis); default ACL de sequences em `public`; 10 funções SECURITY DEFINER sem search_path fixo |
| **LOW** | As 5 views `tse_v_*` + `v_bets_socios_tse` (grants perigosos porém estruturalmente inertes hoje) |
| **INFORMATIONAL** | Ausência de funções `tse_*` ativas (0001 confirmado inativo); default ACL de schemas de plataforma (`storage`, `cron`, `auth` etc. — não são schemas de aplicação) |

## 5. Plano de hardening futuro (proposta — NÃO criada nem aplicada)

Migration hipotética (nome de trabalho: `0048_tse_hardening_completo.sql`),
separada em blocos independentes para permitir aplicação parcial/faseada:

**Bloco 1 — objetos TSE existentes (extensão direta da 0047):**
```sql
revoke insert, update, delete, truncate, references, trigger, maintain
  on table public.tse_bens_candidatos, public.tse_candidatos,
           public.tse_conta_despesa, public.tse_conta_extrato,
           public.tse_conta_notafiscal, public.tse_conta_receita,
           public.tse_ingest_log, public.tse_bens_agg,
           public.tse_candidatos_receitas_agg, public.tse_receitas_brutas,
           public.patrimonio_tse
  from anon, authenticated;
```
Risco: baixo (mesmo padrão já validado pela 0047, mesmos testes aplicáveis).

**Bloco 2 — views (hardening preventivo, mesmo sendo hoje inerte):**
```sql
revoke insert, update, delete, truncate, references, trigger
  on table public.tse_v_doador_emenda, public.tse_v_dossie_doador,
           public.tse_v_financiadores_parlamentar, public.tse_v_receptor_top,
           public.tse_v_rede_financiamento, public.v_bets_socios_tse
  from anon, authenticated;
```
Risco: nenhum (grants hoje inertes; a remoção apenas fecha o risco latente).

**Bloco 3 — materialized view (o item de maior urgência real):**
```sql
revoke insert, update, delete, truncate, references, trigger, maintain
  on table public.mv_tse_ads_digitais
  from anon, authenticated;
```
Risco: baixo. **Recomenda-se priorizar este bloco isoladamente** dado que é o
único item CRITICAL com exploração direta e imediata (TRUNCATE funciona em
matview) — pode justificar uma migration de emergência própria, no mesmo
padrão da 0047, antes mesmo do pacote completo.

**Bloco 4 — sequences:**
```sql
revoke usage, update on sequence
  public.tse_bens_candidatos_id_seq, public.tse_ingest_log_id_seq
  from anon, authenticated;
```

**Bloco 5 — default privileges (a correção sistêmica, tratada à parte por
maior impacto e reversibilidade mais delicada):**
```sql
alter default privileges for role postgres in schema public
  revoke insert, update, delete, truncate, references, trigger, maintain
  on tables from anon, authenticated;
alter default privileges for role postgres in schema public
  revoke usage, update on sequences from anon, authenticated;
```
Isto **não afeta objetos existentes** — só muda o padrão para tabelas/sequences
**futuras**. É complementar aos blocos 1–4, não substituto.

**Bloco 6 — functions SECURITY DEFINER sem search_path** (separado, maior
superfície de teste — cada função precisa de revisão individual do
`search_path` correto antes de fixar):
não redigido aqui; requer decisão função a função.

Nenhum destes blocos foi criado como arquivo de migration nem aplicado.
