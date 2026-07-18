-- bloco 01_extensions — extensões nos MESMOS schemas de produção.
-- pg_cron e pg_net: apenas CREATE EXTENSION (criam os schemas cron/net);
-- nenhum dado operacional, nenhum cron.job, nenhuma função interna copiada.
create extension if not exists pg_trgm    with schema public;
create extension if not exists unaccent   with schema public;
create extension if not exists http       with schema public;
create extension if not exists pg_net     with schema public;
create extension if not exists vector     with schema public;
create extension if not exists pgcrypto   with schema extensions;
create extension if not exists "uuid-ossp" with schema extensions;
create extension if not exists pg_stat_statements with schema extensions;
do $$ begin
  create extension if not exists pg_cron;
exception when others then
  raise notice 'pg_cron indisponível neste ambiente: %', sqlerrm;
end $$;
