-- Teste da migration 0047 (contenção de privilégios TSE).
--
-- Uso (banco de TESTE, nunca produção):
--   psql "$DB_TESTE" -v ON_ERROR_STOP=1 \
--     -f db/tests/test_0047_tse_revoke_privilegios.sql
--
-- Pré-condição do harness: roles anon/authenticated/service_role existem e o
-- estado pré-migration replica produção (grants completos + SELECT). O bloco
-- SETUP abaixo constrói esse estado do zero quando as tabelas não existem.
-- A migration é aplicada DUAS vezes (prova de idempotência) e as asserções
-- rodam depois de cada aplicação.

\set ON_ERROR_STOP on

-- ---------------------------------------------------------------------------
-- SETUP (somente ambiente de teste; no-op se objetos já existem)
-- ---------------------------------------------------------------------------
do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then
    create role anon nologin;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then
    create role authenticated nologin;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'service_role') then
    create role service_role nologin;
  end if;
end $$;

create table if not exists public.tse_receitas (
  id bigserial primary key,
  ano_eleicao smallint not null,
  valor numeric(16,2) not null
);
create table if not exists public.tse_despesas (
  id bigserial primary key,
  ano_eleicao smallint not null,
  valor_despesa numeric(16,2) not null
);

-- replica o estado vulnerável observado em produção (inclui MAINTAIN/PG17)
grant select, insert, update, delete, truncate, references, trigger, maintain
  on public.tse_receitas, public.tse_despesas to anon, authenticated;
grant usage, select, update
  on sequence public.tse_receitas_id_seq, public.tse_despesas_id_seq
  to anon, authenticated;
grant all on public.tse_receitas, public.tse_despesas to service_role;
grant usage, select, update
  on sequence public.tse_receitas_id_seq, public.tse_despesas_id_seq
  to service_role;

-- sanidade: o estado vulnerável está mesmo montado
do $$
begin
  if not has_table_privilege('anon', 'public.tse_receitas', 'TRUNCATE') then
    raise exception 'SETUP inválido: anon deveria ter TRUNCATE antes da migration';
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- 1ª aplicação da migration
-- ---------------------------------------------------------------------------
\i db/migrations/0047_tse_revoke_privilegios_escrita.sql

-- ---------------------------------------------------------------------------
-- Asserções (função reutilizada após cada aplicação)
-- ---------------------------------------------------------------------------
create or replace function pg_temp.assert_0047() returns void
language plpgsql as $$
declare
  t text;
  r text;
  p text;
begin
  foreach t in array array['public.tse_receitas', 'public.tse_despesas'] loop
    foreach r in array array['anon', 'authenticated'] loop
      -- escrita, privilégios estruturais e MAINTAIN: revogados
      foreach p in array array['INSERT','UPDATE','DELETE','TRUNCATE','REFERENCES','TRIGGER','MAINTAIN'] loop
        if has_table_privilege(r, t, p) then
          raise exception 'FALHA: % ainda tem % em %', r, p, t;
        end if;
      end loop;
      -- SELECT: preservado exatamente como antes
      if not has_table_privilege(r, t, 'SELECT') then
        raise exception 'FALHA: SELECT de % em % foi indevidamente revogado', r, t;
      end if;
    end loop;
    -- service_role permanece operacional (loaders), postura anterior intacta
    foreach p in array array['SELECT','INSERT','UPDATE','DELETE','MAINTAIN'] loop
      if not has_table_privilege('service_role', t, p) then
        raise exception 'FALHA: service_role perdeu % em %', p, t;
      end if;
    end loop;
    -- postgres (owner) conserva MAINTAIN
    if not has_table_privilege('postgres', t, 'MAINTAIN') then
      raise exception 'FALHA: postgres perdeu MAINTAIN em %', t;
    end if;
  end loop;

  -- sequences: anon/authenticated sem nextval/setval; service_role intacto
  foreach t in array array['public.tse_receitas_id_seq', 'public.tse_despesas_id_seq'] loop
    foreach r in array array['anon', 'authenticated'] loop
      if has_sequence_privilege(r, t, 'USAGE') or has_sequence_privilege(r, t, 'UPDATE') then
        raise exception 'FALHA: % ainda tem USAGE/UPDATE em %', r, t;
      end if;
    end loop;
    if not has_sequence_privilege('service_role', t, 'USAGE') then
      raise exception 'FALHA: service_role perdeu USAGE em %', t;
    end if;
  end loop;

  raise notice 'OK: asserções 0047 aprovadas';
end $$;

select pg_temp.assert_0047();

-- ---------------------------------------------------------------------------
-- 2ª aplicação (idempotência): reexecutar não pode falhar nem mudar o estado
-- ---------------------------------------------------------------------------
\i db/migrations/0047_tse_revoke_privilegios_escrita.sql
select pg_temp.assert_0047();

\echo 'test_0047: SUCESSO (migration aplicada 2x, estado final idêntico e correto)'
