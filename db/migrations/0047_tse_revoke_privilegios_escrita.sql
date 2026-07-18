-- 0047: contenção de privilégios — tse_receitas / tse_despesas
--
-- Auditoria (2026-07-18, produção redggdtakzmsabwvjzhb, somente leitura):
-- anon e authenticated detêm INSERT/UPDATE/DELETE/TRUNCATE/REFERENCES/TRIGGER
-- nas duas tabelas finais TSE e USAGE/UPDATE nas sequences de id. A escrita
-- real é feita exclusivamente por service_role (loaders); anon/authenticated
-- só precisam de leitura. RLS já está habilitada sem policies (deny-all), mas
-- grant de TRUNCATE contorna RLS — TRUNCATE não é sujeito a policy.
--
-- Escopo deliberadamente mínimo:
--   * NÃO revoga SELECT (leitura pública preservada como está).
--   * NÃO altera RLS nem policies.
--   * NÃO concede nenhum privilégio novo.
--   * NÃO toca em outras tabelas, views ou no default ACL do schema
--     (grants de escrita em tse_v_* e o default ACL de public ficam
--     registrados para tratamento em migration própria).
--
-- Idempotente: REVOKE de privilégio inexistente é no-op no PostgreSQL.

-- 1. Tabelas finais: remove escrita e privilégios estruturais
revoke insert, update, delete, truncate, references, trigger
  on table public.tse_receitas
  from anon, authenticated;

revoke insert, update, delete, truncate, references, trigger
  on table public.tse_despesas
  from anon, authenticated;

-- 2. Sequences associadas: anon/authenticated não geram ids
--    (USAGE/UPDATE permitem nextval/setval; SELECT em sequence é inofensivo
--    e permanece, coerente com a decisão de não mexer em leitura.)
revoke usage, update on sequence public.tse_receitas_id_seq from anon, authenticated;
revoke usage, update on sequence public.tse_despesas_id_seq from anon, authenticated;
