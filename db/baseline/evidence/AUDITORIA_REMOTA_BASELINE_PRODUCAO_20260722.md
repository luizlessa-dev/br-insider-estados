# Auditoria remota read-only — baseline × produção

- Repositório: `luizlessa-dev/br-insider-estados`
- Projeto Supabase: `redggdtakzmsabwvjzhb`
- Nome: `transparencia-federal`
- Região: `us-east-2`
- Data: `2026-07-22`
- Baseline validado no commit: `f49df17908af1698149765f0fe6518189fb1500d`
- Evidência local publicada no commit: `71ff10229e93e5f4a529458b3793236e7780161f`
- Natureza: exclusivamente read-only

## 1. Resumo executivo

Esta auditoria comparou o baseline local validado (commit `f49df17908af1698149765f0fe6518189fb1500d`) contra o estado observado do projeto Supabase de produção `redggdtakzmsabwvjzhb` (`transparencia-federal`, região `us-east-2`, PostgreSQL `17.6.1.063`, status `ACTIVE_HEALTHY`). O acesso à produção foi exclusivamente read-only, sem qualquer DDL, DML ou execução de função de aplicação.

O achado central é que cinco das sete tabelas do domínio STF permanecem, em produção, com RLS desabilitado e privilégios amplos concedidos a `anon` e `authenticated`. O baseline reproduz esse estado — não o corrige. Este risco é classificado como bloqueante e segue ativo em produção.

Fora esse achado bloqueante e um conjunto de achados de severidade alta e média (baseline ausente de `schema_migrations`, proveniência STF indeterminada, default privileges amplos, funções `SECURITY DEFINER` sem `search_path` fixo), o restante da comparação — schemas, funções de aplicação, policies, RLS de aplicação, extensões e hardening TSE — mostrou compatibilidade entre baseline e produção.

## 2. Escopo e metodologia

O escopo cobriu exclusivamente leitura de metadados e catálogos do projeto Supabase de produção (`information_schema`, catálogos `pg_catalog`, histórico de migrations, extensões instaladas, cron jobs e advisors de segurança), comparados contra os artefatos do baseline local validado no commit `f49df17908af1698149765f0fe6518189fb1500d` e contra a evidência local da PROVA 2 publicada no commit `71ff10229e93e5f4a529458b3793236e7780161f` (PR #12).

Não houve qualquer escrita, execução de função de aplicação, migration repair, alteração de `schema_migrations` ou aplicação do baseline em produção. A comparação de funções foi feita por metadados (assinatura, `SECURITY DEFINER`, `search_path`), não por hash de corpo integral. O advisor de performance do Supabase não foi consultado — apenas o advisor de segurança.

## 3. Identificação do projeto

- Projeto confirmado: `redggdtakzmsabwvjzhb` (`transparencia-federal`).
- Organização: Transparência Federal.
- Região: `us-east-2`.
- Status: `ACTIVE_HEALTHY`.
- PostgreSQL de produção: `17.6.1.063`.

## 4. Histórico de migrations

- 38 registros remotos em `schema_migrations`.
- Intervalo: de `20250313120000_initial_schema` até `20260722175004_bndes_dados_premium`.
- 23 migrations anteriores ao cutoff `20260718000000`.
- 15 migrations posteriores ao cutoff.
- A migration `20260718000000_baseline` está ausente de `schema_migrations` em produção.
- Nenhuma migration remota contém `stf` no nome.
- A proveniência dos objetos STF encontrados em produção é indeterminada — não há registro de migration correspondente.
- Nenhum migration repair foi realizado ou autorizado nesta auditoria.

## 5. PostgreSQL e extensões

- Produção roda PostgreSQL `17.6.1.063`.
- A PROVA 2 local usou PostgreSQL `17.6.1.140`.
- Ambas as versões pertencem à mesma série `17.6`, mas são builds diferentes.
- Equivalência binária entre os dois builds não foi demonstrada nesta auditoria.

Extensões — 9/9 presentes em produção:

- `pg_trgm`
- `unaccent`
- `http`
- `pg_net`
- `vector`
- `pgcrypto`
- `uuid-ossp`
- `pg_stat_statements`
- `pg_cron`

## 6. Funções, SECURITY DEFINER e search_path

- 37 funções do baseline foram encontradas em produção.
- 15 funções são `SECURITY DEFINER`.
- 5 dessas possuem `search_path` explícito fixado.
- 10 funções `SECURITY DEFINER` não possuem `search_path` fixado.
- A comparação foi feita por metadados (assinatura, flags, `search_path`); os corpos das funções não foram comparados integralmente por hash nesta auditoria.

## 7. Policies e RLS

- 165 policies de aplicação presentes tanto no baseline quanto em produção.
- 224 comandos `ENABLE ROW LEVEL SECURITY` no baseline.
- 226 tabelas de aplicação com RLS habilitado em produção.
- `FORCE ROW LEVEL SECURITY` igual a zero em ambos.
- O delta de duas tabelas é compatível com evolução do schema posterior ao baseline.
- A tabela `stf_ingestao_log` possui RLS habilitado, mas zero policies associadas.

## 8. Objetos STF

Sete tabelas do domínio STF confirmadas em produção:

- `stf_assinaturas`
- `stf_gastos`
- `stf_ingestao_log`
- `stf_ministros`
- `stf_processos_politicos`
- `stf_repercussao_geral`
- `stf_votacoes`

Situação observada:

- `stf_assinaturas`: RLS habilitado, uma policy.
- `stf_ingestao_log`: RLS habilitado, zero policies.
- As cinco tabelas restantes (`stf_gastos`, `stf_ministros`, `stf_processos_politicos`, `stf_repercussao_geral`, `stf_votacoes`): RLS desabilitado, com privilégios amplos concedidos a `anon` e `authenticated`.
- A exposição foi confirmada tanto por leitura de catálogos quanto pelo advisor de segurança do Supabase.
- Este é um risco ativo em produção.
- O baseline reproduz esse estado — não o corrige.
- As tabelas `stf_processos`, `stf_decisoes` e `stf_partes` não existem em produção nem no baseline.

## 9. Função e materialized views STF

- A função `stf_refresh_matviews()` existe em produção.
- Não é `SECURITY DEFINER`.
- Não possui `search_path` fixado.
- Referencia três materialized views: `stf_ministros_perfil`, `stf_tendencia_classe` e `stf_tendencia_orgao`.
- Nenhuma das três materialized views referenciadas existe em produção.
- A função é classificada como órfã.
- A função não foi executada nesta auditoria.

## 10. Hardening TSE

- Tabelas `tse_receitas` e `tse_despesas`.
- `anon` e `authenticated` possuem exclusivamente privilégio `SELECT`.
- Privilégios de escrita e `MAINTAIN` foram revogados para ambos os roles.
- Privilégios de `service_role` e do owner foram preservados.
- Este estado é compatível com o hardening já aplicado localmente.

## 11. Default privileges

- Tabelas novas criadas em `public` pelo role `postgres` recebem privilégios amplos por padrão.
- Sequences novas recebem privilégios concedidos a `anon`/`authenticated` por padrão.
- Funções novas recebem `EXECUTE` concedido por padrão.
- O bloco 16 do baseline reproduz esse mesmo estado de default privileges.
- O hardening dos default privileges permanece pendente.
- Este comportamento é apontado como causa estrutural provável das exposições encontradas nas tabelas STF.

## 12. Cron e advisors

- 12 cron jobs ativos em produção.
- Nenhum dos 12 é atribuível ao baseline.
- Um cron job contém placeholders não substituídos.
- Alguns cron jobs armazenam JWT `anon` em texto no corpo do job.
- Nenhum valor de credencial é reproduzido neste documento.

Advisor de segurança — 492 achados no total:

- 146 `rls_disabled_in_public`
- 135 `security_definer_view`
- 107 `rls_enabled_no_policy`
- 34 `function_search_path_mutable`
- 32 `materialized_view_in_api`
- 14 executáveis por `authenticated`
- 14 executáveis por `anon`
- 5 `extension_in_public`
- 4 `rls_policy_always_true`
- 1 `auth_leaked_password_protection`

Oito desses achados estão nominalmente relacionados ao domínio STF. O advisor de performance do Supabase não foi consultado nesta auditoria.

## 13. Matriz baseline × produção

| Categoria | Baseline | Produção | Status | Risco |
|---|---:|---:|---|---|
| Schemas de aplicação | 7 | 7 | compatível | baixo |
| Tabelas public | 344 | 352 | evolução posterior | baixo |
| Funções de aplicação | 37 | 37 | compatível por metadados | baixo |
| SECURITY DEFINER | 15 | 15 | compatível | médio |
| Search path explícito | 5 | 5 | compatível | baixo |
| SECURITY DEFINER sem search_path | 10 | 10 | compatível | médio |
| Policies | 165 | 165 | compatível | baixo |
| RLS | 224 | 226 | evolução posterior | baixo |
| FORCE RLS | 0 | 0 | compatível | baixo |
| Tabelas STF | 7 | 7 | compatível | bloqueante |
| Matviews STF referenciadas | 3 ausentes | 3 ausentes | função órfã | baixo |
| MAINTAIN TSE anon | revogado | revogado | compatível | baixo |
| MAINTAIN TSE authenticated | revogado | revogado | compatível | baixo |
| Extensões | 9 | 9 | compatível | baixo |
| Baseline em schema_migrations | ausente | ausente | confirmado | informativo |
| PostgreSQL | 17.6.1.140 | 17.6.1.063 | divergente | médio |

## 14. Achados por severidade

**Bloqueante**

- Cinco tabelas STF (`stf_gastos`, `stf_ministros`, `stf_processos_politicos`, `stf_repercussao_geral`, `stf_votacoes`) com RLS desligado e grants amplos para `anon` e `authenticated`.
- Isso permite leitura e escrita conforme os privilégios observados.
- Não corrigido nesta auditoria.

**Altos**

- Baseline ausente de `schema_migrations` em produção.
- Proveniência dos objetos STF indeterminada.
- Default privileges amplos em `public`.

**Médios**

- 10 funções `SECURITY DEFINER` sem `search_path` fixo.
- JWT `anon` armazenado em texto em cron jobs.
- Diferença de build do PostgreSQL entre baseline local e produção.

**Baixos**

- Evolução posterior de tabelas e contagem de RLS em relação ao baseline.
- Cron job com placeholder não substituído.
- Função STF órfã (`stf_refresh_matviews()`).

**Informativos**

- O padrão de exposição observado é sistêmico, não isolado ao domínio STF.
- 492 achados totais no advisor de segurança.
- `stf_v_ministros_scores` é uma view, não uma tabela.

**Indeterminados**

- Corpos integrais das funções (comparação não foi feita por hash).
- Diff completo de colunas/constraints das tabelas.
- Seis funções adicionais presentes apenas localmente.
- Resultado do advisor de performance (não consultado).

## 15. Limitações

Esta auditoria não comparou corpos de função por hash, não realizou diff completo de estrutura de tabelas além dos metadados listados, e não consultou o advisor de performance do Supabase. A equivalência binária entre os builds PostgreSQL `17.6.1.140` (local) e `17.6.1.063` (produção) não foi demonstrada. A proveniência dos objetos STF em produção não pôde ser confirmada por ausência de migration correspondente em `schema_migrations`.

## 16. Decisão

"Baseline compatível com produção, com ressalvas."

Compatibilidade não significa segurança: o baseline reproduz o estado observado em produção, incluindo suas exposições, sem corrigi-las. O baseline não foi aplicado nem registrado em produção nesta auditoria. Os riscos reproduzidos — em especial a exposição das cinco tabelas STF — continuam ativos em produção. Nenhuma ação corretiva é autorizada por este documento.

## 17. Declaração de não intervenção

Esta auditoria acessou o projeto Supabase exclusivamente em modo read-only. Não houve DDL, DML, execução de funções de aplicação, migration repair, alteração de schema_migrations, aplicação do baseline, criação de projeto ou branch Supabase, alteração do PR #12, homologação ou qualquer ação corretiva em produção.
