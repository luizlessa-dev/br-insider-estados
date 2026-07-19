# Baseline candidato — metadata e proveniência

**Status: CANDIDATO local. NÃO commitado como definitivo. NÃO aplicado em
produção. NÃO registrado em schema_migrations.**

## Captura

| Campo | Valor |
|---|---|
| Data da captura | 2026-07-18 (18:13 BRT) |
| Origem | `redggdtakzmsabwvjzhb` (produção), somente leitura |
| Comando (sanitizado) | `supabase db dump -f <arquivo> --schema public,public_api,analytics,bcb,cidadania_ai,homabrasil,portal_transparencia` (credencial no keyring do CLI; nunca exposta) |
| PostgreSQL | 17.6 |
| Imagem Supabase Postgres | 17.6.1.063 (idêntica à de produção) |
| SHA-256 dump bruto | `2f28c841069fc6bb94fdcd33fdfd35bb44525c37f0eae1b0da214e028433184e` |
| SHA-256 canonicalizado | ver `shasum -a 256 baseline_canonicalizado.sql` (regenerável por `cat blocks/*.sql` na ordem numérica) |
| Snapshot bruto preservado | `snapshot/dump_bruto_20260718.sql` (auditoria; nunca editar) |

## BASELINE_CUTOFF

**`20260718000000`** (proposta de versão para o futuro registro formal).

| Campo | Valor |
|---|---|
| Timestamp da captura (UTC) | 2026-07-18T21:13Z |
| SHA-256 do dump bruto | `2f28c841069fc6bb94fdcd33fdfd35bb44525c37f0eae1b0da214e028433184e` |
| PostgreSQL | 17.6 |
| Imagem Supabase Postgres | `public.ecr.aws/supabase/postgres:17.6.1.063` |
| Commit Git de referência | `61bd94e` (origin/main de br-insider-estados na captura) |
| Schemas incluídos | public, public_api, analytics, bcb, cidadania_ai, homabrasil, portal_transparencia (+ cron/net via extensões) |
| Schemas omitidos | auth, storage, realtime, extensions, graphql*, vault, supabase_migrations, net/cron internos |
| Comando (sanitizado) | `supabase db dump -f <saida> --schema <lista acima>` — ver `tools/10_captura.sh` |

### As 23 migrations remotas absorvidas (todas ≤ cutoff)

`20250313120000_initial_schema`, `20250520000000_ceap`,
`20250521000000_emendas_completas`, `20250522000000_tse_financiamento`,
`20250523000000_ceaps_senado`, `20260520235500_emendas_restos_a_pagar`,
`20260521210000_ask_feature`, `20260521211000_exec_readonly_query`,
`20260602120000_mg_fornecedor_perfil`, `20260602130000_bcb_desenrola`,
`20260602200000_tse_contas_partidarias`,
`20260609172535_create_emendas_rp9_apoiamento`,
`20260609214419_views_rp9_sancionados`, `20260620140000_remote_only`,
`20260702100000_fix_contratos_federais_colunas`,
`20260702110000_fix_sancionados_null_dedup`,
`20260716021557_add_months_present_helper_for_gap_check`,
`20260716022319_add_distinct_dates_helper_for_dou_backfill_resume`,
`20260716022806_raise_statement_timeout_inside_gap_check_rpcs`,
`20260716163236_1a_revoke_write_truncate_anon_authenticated`,
`20260716163308_1b1_views_security_invoker`,
`20260716163328_1b2_fix_user_profiles_codigos_acesso_policies`,
`20260716163605_1b3_enable_rls_subradar_private_tables`.

Classificação das 23 migrations remotas: **todas ABSORVIDAS** pelo baseline
(anteriores ao cutoff; nenhuma posterior; nenhuma pendente). Pós-baseline,
todas se tornam **redundantes** para replay. Nota: `20250313120000
initial_schema` é adicionalmente **incompatível com replay em banco vazio**
(FK a `parlamentares`, objeto nunca versionado) — causa-raiz do
MIGRATIONS_FAILED de 2026-07-18; absorvida de toda forma.

## Estrutura canonicalizada (blocos, ordem de aplicação)

`00_prelude` (12 SETs pg_dump) → `01_extensions` (9; mesmos schemas de prod;
pg_cron/pg_net só CREATE EXTENSION — zero dados operacionais, zero cron.job,
zero funções internas copiadas) → `02_schemas` (7) → `03_types_domains` (6) →
`04_sequences` (86) → `05_tables` (456 stmts/364 tabelas) → `06_constraints`
(699, inclui `ALTER SEQUENCE … OWNED BY` pós-tabelas; FKs após UNIQUEs) →
`07_functions` (37) → `08_views_e_matviews` (193 — **bloco combinado**:
dependências existem nas DUAS direções entre views e MVs; a ordem original do
pg_dump é topológica; separação estrita quebra a aplicação — desvio documentado
do plano de blocos) → `10_indexes` (785) → `11_triggers` (3) → `12_rls` (224)
→ `13_policies` (165) → `14_comments` (188; bloco adicional) → `15_grants`
(1892, fiel a produção) → `16_default_privileges` (12, fiel — ver decisão
abaixo) → `17_hardening` (revoga grants perigosos TSE; espelha
`db/migrations/0047`).

## Normalizações aplicadas

- **Owners**: 692 `ALTER … OWNER TO` removidos — objetos ficam com o role
  executor (postgres, igual ao provisionamento de branch). Determinístico.
- **search_path / SECURITY DEFINER**: corpos de função preservados byte a byte
  (hash idêntico a produção); nenhuma reescrita.
- **ACLs**: bloco 15 fiel; hardening TSE aplicado por último (bloco 17).
- **Ambiente**: prelude do pg_dump mantido (`check_function_bodies=false` etc).

## Validação (2026-07-18, container `supabase/postgres:17.6.1.063`, db recém-provisionado, sem conexão remota)

- Aplicação do zero: **OK, zero erros** (`ON_ERROR_STOP=1`).
- Diff **por definição** (hashes normalizados, produção × rebuild):
  `views, matviews, indexes, constraints, functions, triggers, policies,
  rls_flags, sequencias` → **idênticos**. `colunas` → única divergência:
  `public.mg_remuneracao`, **renumeração de ordinais** (produção tem 2 colunas
  dropadas na história; attnum salta 17→20; nomes/tipos/nulabilidade/defaults
  idênticos) — benigna e **intencional**: não tentamos reproduzir attnums de
  colunas removidas (exigiria add+drop artificial). Os `digests_esperados.txt`
  do `baseline-verify` usam o valor canônico do rebuild. `grants_tabelas` → difere **apenas** pelo hardening
  TSE intencional do bloco 17.

## Default privileges vulneráveis (decisão em aberto — NENHUMA executada)

O default ACL de `public` (postgres e supabase_admin) concede
`arwdDxtm` (escrita completa + MAINTAIN) a anon/authenticated em toda tabela
nova. Opções:

- **A. Baseline fiel + migration imediata de hardening** (recomendada):
  bloco 16 permanece fiel; uma migration separada e auditada corrige o default
  ACL e os grants largos (rastro explícito de decisão de segurança).
- **B. Baseline já normalizado**: editar o bloco 16 antes do registro
  (menos rastro; mistura fidelidade com política).

## Omissões intencionais

Jobs `cron.job` (dados; desejável não replicar em branch), valores correntes
de sequences (schema-only), Vault secrets, schemas gerenciados
(auth/storage/realtime — plataforma), objetos internos de extensões,
publications Realtime.
