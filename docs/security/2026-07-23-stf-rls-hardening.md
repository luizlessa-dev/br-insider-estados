# Hardening de RLS nas tabelas STF — registro de auditoria

Status: aplicado em produção. Este documento é um registro administrativo
posterior à aplicação — não descreve trabalho pendente.

## Contexto

O domínio STF do BR Insider (repositório `br-insider-estados`, projeto
Supabase `redggdtakzmsabwvjzhb`) mantém seis objetos públicos consumidos
pelo frontend `observatorio-stf` (role `anon`):

- `public.stf_gastos`
- `public.stf_ministros`
- `public.stf_votacoes`
- `public.stf_repercussao_geral`
- `public.stf_processos_politicos`
- `public.stf_v_ministros_scores` (view)

## Problema original

Baseline anterior à migration: as cinco tabelas tinham `GRANT ALL` para
`anon` e `authenticated` e Row Level Security desabilitada, sem nenhuma
policy versionada. A escrita legítima sempre foi feita exclusivamente por
`service_role`, mas o cliente anônimo/autenticado tinha, na prática,
privilégio de escrita e alteração estrutural nas tabelas — não apenas de
leitura.

## PR #14

- Repositório: `luizlessa-dev/br-insider-estados`
- URL: https://github.com/luizlessa-dev/br-insider-estados/pull/14
- Título: `fix(db): restringe escrita e habilita RLS nas tabelas STF`
- Base: `main` ← Head: `fix/stf-rls-hardening`
- Estado: `MERGED`
- Merged em: 2026-07-23T15:56:45Z, por `luizlessa-dev`

## Commits da branch

1. `b9290257d0f89265c8f027d7144a9d6547f8e47d` — 2026-07-23T03:04:47Z
   `fix(db): restringe escrita e habilita RLS nas tabelas STF`
2. `5d100350d50f78ef35fea10d3d278f3b52fa4c7c` — 2026-07-23T13:23:35Z
   `fix(db): corrige assertion de privilégios no hardening STF`
   Correção de um bug real na validação: `has_table_privilege` com lista
   agregada (`'SELECT, INSERT, UPDATE, DELETE'`) tem semântica **OR**, não
   AND — a postcondition da migration aprovava mesmo com apenas um dos
   privilégios ainda presente. Substituído por checagem individual por
   privilégio para `service_role` e `postgres` em cada tabela/view.

## Commit do merge (main)

- `ee856ce4c048dcfb8d9829718b56d1db0ce362a7`
  `fix(db): habilita RLS e restringe privilégios de cliente nas tabelas STF`

## Migration

- Arquivo: `supabase/migrations/20260723030044_harden_stf_tables_rls.sql`
- 377 linhas, único arquivo adicionado pela PR (`ADDED`, sem outras
  alterações de código na PR)

### SHA256

```
2517e9f23ae1dcbdcacb5fa6bddf4959f33d2ef1677f2e289cb10d86d8f1ccc5
```

Calculado sobre o conteúdo do arquivo em `origin/main` no momento desta
auditoria (2026-07-23).

## Projeto Supabase

- ID: `redggdtakzmsabwvjzhb`
- Compartilhado pelo ecossistema BR Insider (`br-insider`,
  `br-insider-estados`, `observatorio-judiciario`, `observatorio-stf`)

## Data

- Commits da branch: 2026-07-23 (03:04 UTC e 13:23 UTC)
- Merge da PR #14: 2026-07-23T15:56:45Z
- Migration registrada em `supabase_migrations.schema_migrations`:
  versão `20260723190016` (2026-07-23T19:00:16Z) — ver nota em Auditoria
  abaixo sobre a divergência entre esse número e o prefixo do nome do
  arquivo (`20260723030044`).

## Validação

Consulta somente leitura a `mcp_supabase.get_advisors` (tipo `security`)
no projeto `redggdtakzmsabwvjzhb`, filtrada aos objetos do escopo desta
migration:

- `public.stf_processos_politicos`: advisory `INFO` —
  `rls_enabled_no_policy` ("has RLS enabled, but no policies exist").
  Esperado e intencional: a migration habilita RLS sem policy nessa
  tabela deliberadamente, para negar todo acesso de `anon`/`authenticated`
  por padrão (acesso exclusivo via `service_role`/`postgres`).
- `public.stf_gastos`, `public.stf_ministros`, `public.stf_votacoes`,
  `public.stf_repercussao_geral`, `public.stf_v_ministros_scores`: nenhum
  advisory de segurança pendente.

Nenhum advisory de nível `ERROR` ou `WARN` associado aos seis objetos do
escopo.

## Resultado

Desenho final aplicado, conforme cabeçalho da própria migration:

- Quatro tabelas com consumidor público confirmado (`stf_gastos`,
  `stf_ministros`, `stf_votacoes`, `stf_repercussao_geral`): RLS
  habilitada + policy pública de `SELECT` para `anon`/`authenticated`;
  privilégios de escrita e estruturais revogados desses roles.
- `stf_processos_politicos` (sem consumidor público confirmado): RLS
  habilitada, sem policy — nega tudo por padrão; `SELECT` também revogado
  explicitamente de `anon`/`authenticated` como defesa em profundidade.
- `stf_v_ministros_scores`: `security_invoker = true`, para que a RLS de
  `stf_ministros`/`stf_votacoes` valha também através da view.
- Escrita permanece exclusiva de `service_role`/`postgres` nos seis
  objetos.

## Auditoria

Consulta somente leitura a `supabase_migrations.schema_migrations` no
projeto `redggdtakzmsabwvjzhb` (via ferramenta `list_migrations`,
read-only) confirma um registro com `name = harden_stf_tables_rls`.

**Achado**: a versão registrada é `20260723190016`, e **não**
`20260723030044` como o prefixo do nome do arquivo local sugere. A
diferença (~16h) é posterior ao merge da PR (15:56:45Z), o que é
cronologicamente consistente com um `db push` para produção feito depois
do merge — mas o número de versão em si não corresponde ao prefixo do
arquivo. Isso é registrado aqui como achado de auditoria, sem correção:
esta tarefa foi escopada como somente leitura e não deve executar
`migration repair` nem qualquer escrita no banco.

## Rollback conceitual

Não executado nem planejado nesta tarefa — descrito apenas para registro.
Reverter este hardening exigiria uma nova migration (nunca edição da
existente) que restaurasse, para `anon`/`authenticated`, os privilégios de
escrita hoje revogados e desabilitasse RLS nas cinco tabelas — reduzindo a
tabela a uma decisão explícita e revisada, não a um `DROP POLICY` isolado,
já que a policy de `SELECT` pública deve continuar existindo enquanto o
frontend `observatorio-stf` consumir esses dados via `anon`.

## Evidências

- PR: https://github.com/luizlessa-dev/br-insider-estados/pull/14
- Commits: `b929025`, `5d10035` (branch); `ee856ce` (merge em `main`)
- Migration: `supabase/migrations/20260723030044_harden_stf_tables_rls.sql`
  (SHA256 acima)
- `list_migrations` (Supabase MCP, read-only): registro
  `20260723190016 / harden_stf_tables_rls`
- `get_advisors` tipo `security` (Supabase MCP, read-only): 3 advisories
  mencionando objetos `stf_*`, nenhum de severidade `ERROR`/`WARN` nos
  seis objetos do escopo
