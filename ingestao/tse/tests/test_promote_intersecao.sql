-- Teste da promoção por INTERSEÇÃO (staging ∩ final) em tse_promote_year.
--
-- Uso (banco de TESTE, nunca produção):
--   psql "$DB_TESTE" -v ON_ERROR_STOP=1 -f ingestao/tse/tests/test_promote_intersecao.sql
-- Pré-condição: roles anon/authenticated/service_role existem (imagem Supabase)
-- e a migration ingestao/tse/sql/0001_tse_safe_pipeline.sql foi aplicada APÓS
-- a criação das tabelas finais deste setup (o runner do repositório faz isso).
--
-- Cobre os 9 cenários exigidos:
--   1. staging tem source_id e final não → promove;
--   2. staging e final têm source_id → source_id é promovido;
--   3. falta coluna obrigatória → falha ANTES de tocar a final;
--   4. colunas técnicas nunca são promovidas;
--   5. ordem das colunas é determinística (ordem da final);
--   6. identificadores exóticos são quotados corretamente;
--   7. rollback preserva dados anteriores diante de erro no insert;
--   8. advisory lock continua presente na função;
--   9. nenhuma constraint/índice UNIQUE sobre source_id.

\set ON_ERROR_STOP on

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
create or replace function pg_temp.seed_run(p_dataset text, p_ano int, p_n int)
returns uuid language plpgsql as $$
declare v_run uuid := gen_random_uuid(); i int;
begin
  insert into tse_load_runs(run_id, dataset, ano, phase, status, min_expected)
  values (v_run, p_dataset, p_ano, 'staged', 'running', 1);
  if p_dataset = 'receitas' then
    for i in 1..p_n loop
      insert into tse_receitas_staging(ano_eleicao, source_id, numero_recibo, valor, run_id, row_fingerprint)
      values (p_ano, 'SQ-'||i, 'R-'||v_run||'-'||i, 10.0,
              v_run, encode(sha256((p_ano||'|'||i||'|'||v_run)::bytea), 'hex'));
    end loop;
  else
    for i in 1..p_n loop
      insert into tse_despesas_staging(ano_eleicao, source_id, numero_documento, valor_despesa, run_id, row_fingerprint)
      values (p_ano, 'SQ-'||i, 'D-'||v_run||'-'||i, 20.0,
              v_run, encode(sha256((p_ano||'|'||i||'|'||v_run)::bytea), 'hex'));
    end loop;
  end if;
  return v_run;
end $$;

-- ---------------------------------------------------------------------------
-- 1. staging TEM source_id, final NÃO tem → promoção funciona
-- ---------------------------------------------------------------------------
do $$
declare v_run uuid; v_ret jsonb; v_cnt bigint;
begin
  v_run := pg_temp.seed_run('receitas', 1998, 50);
  v_ret := tse_promote_year('receitas', 1998, v_run, 1);
  select count(*) into v_cnt from tse_receitas where ano_eleicao = 1998;
  if v_cnt <> 50 then raise exception 'T1 FALHA: esperava 50 na final, obtive %', v_cnt; end if;
  if v_ret->'promoted_columns' ? 'source_id' then
    raise exception 'T1 FALHA: source_id promovido sem existir na final';
  end if;
  if not (v_ret->'discarded_staging_columns' ? 'source_id') then
    raise exception 'T1 FALHA: source_id deveria constar como descartada';
  end if;
  raise notice 'T1 OK: promocao sem source_id na final (50 linhas)';
end $$;

-- ---------------------------------------------------------------------------
-- 4. colunas técnicas nunca promovidas / 5. ordem determinística = ordem da final
-- ---------------------------------------------------------------------------
do $$
declare v_run uuid; v_ret jsonb; v_expected jsonb;
begin
  v_run := pg_temp.seed_run('receitas', 1997, 5);
  v_ret := tse_promote_year('receitas', 1997, v_run, 1);
  if v_ret->'promoted_columns' ?| array['run_id','staged_at','row_fingerprint','identity_key','id'] then
    raise exception 'T4 FALHA: coluna tecnica/id na lista promovida: %', v_ret->'promoted_columns';
  end if;
  select to_jsonb(array_agg(f.column_name order by f.ordinal_position)) into v_expected
    from information_schema.columns f
   where f.table_schema='public' and f.table_name='tse_receitas'
     and f.column_name not in ('run_id','staged_at','row_fingerprint','identity_key','id')
     and exists (select 1 from information_schema.columns s
                  where s.table_schema='public' and s.table_name='tse_receitas_staging'
                    and s.column_name = f.column_name);
  if v_ret->'promoted_columns' <> v_expected then
    raise exception 'T5 FALHA: ordem nao deterministica. obtido=% esperado=%',
      v_ret->'promoted_columns', v_expected;
  end if;
  raise notice 'T4/T5 OK: sem colunas tecnicas; ordem = ordem da final';
end $$;

-- ---------------------------------------------------------------------------
-- 2. staging E final têm source_id → source_id é promovido
-- ---------------------------------------------------------------------------
alter table public.tse_receitas add column source_id text;
do $$
declare v_run uuid; v_ret jsonb; v_cnt bigint;
begin
  v_run := pg_temp.seed_run('receitas', 1998, 30);
  v_ret := tse_promote_year('receitas', 1998, v_run, 1);
  if not (v_ret->'promoted_columns' ? 'source_id') then
    raise exception 'T2 FALHA: source_id existe na final e nao foi promovido';
  end if;
  select count(*) into v_cnt from tse_receitas where ano_eleicao = 1998 and source_id is not null;
  if v_cnt <> 30 then raise exception 'T2 FALHA: source_id nao populado (%/30)', v_cnt; end if;
  raise notice 'T2 OK: source_id promovido quando a final tem a coluna (30/30)';
end $$;
alter table public.tse_receitas drop column source_id;

-- ---------------------------------------------------------------------------
-- 6. identificadores exóticos quotados corretamente
-- ---------------------------------------------------------------------------
alter table public.tse_receitas         add column "Valor Extra" numeric;
alter table public.tse_receitas_staging add column "Valor Extra" numeric;
do $$
declare v_run uuid; v_ret jsonb;
begin
  v_run := pg_temp.seed_run('receitas', 1996, 3);
  v_ret := tse_promote_year('receitas', 1996, v_run, 1);
  if not (v_ret->'promoted_columns' ? 'Valor Extra') then
    raise exception 'T6 FALHA: coluna com espaco/maiuscula nao promovida: %', v_ret->'promoted_columns';
  end if;
  raise notice 'T6 OK: identificador exotico ("Valor Extra") quotado e promovido';
end $$;
alter table public.tse_receitas         drop column "Valor Extra";
alter table public.tse_receitas_staging drop column "Valor Extra";

-- ---------------------------------------------------------------------------
-- 3. falta coluna obrigatória → falha ANTES de alterar a final
-- ---------------------------------------------------------------------------
do $$
declare v_run uuid; v_before bigint; v_after bigint; v_failed boolean := false;
begin
  -- estado prévio na final de despesas
  v_run := pg_temp.seed_run('despesas', 1998, 10);
  perform tse_promote_year('despesas', 1998, v_run, 1);
  select count(*) into v_before from tse_despesas where ano_eleicao = 1998;
  if v_before <> 10 then raise exception 'T3 setup falhou: % linhas', v_before; end if;

  -- remove coluna obrigatória da FINAL e tenta promover de novo
  execute 'alter table public.tse_despesas drop column numero_documento';
  v_run := pg_temp.seed_run('despesas', 1998, 7);
  begin
    perform tse_promote_year('despesas', 1998, v_run, 1);
  exception when others then
    v_failed := true;
    if position('colunas obrigatorias ausentes' in sqlerrm) = 0 then
      raise exception 'T3 FALHA: erro inesperado: %', sqlerrm;
    end if;
  end;
  if not v_failed then raise exception 'T3 FALHA: promocao deveria ter abortado'; end if;
  select count(*) into v_after from tse_despesas where ano_eleicao = 1998;
  if v_after <> v_before then
    raise exception 'T3 FALHA: final foi alterada (% -> %) apesar do abort', v_before, v_after;
  end if;
  execute 'alter table public.tse_despesas add column numero_documento text';
  raise notice 'T3 OK: abortou antes do delete; final intacta (% linhas)', v_after;
end $$;

-- ---------------------------------------------------------------------------
-- 7. rollback diante de erro no INSERT preserva os dados anteriores
-- ---------------------------------------------------------------------------
create or replace function pg_temp.veneno() returns trigger language plpgsql as $$
begin
  if new.numero_recibo like '%VENENO%' then raise exception 'linha sentinela envenenada'; end if;
  return new;
end $$;
do $$
declare v_run uuid; v_before bigint; v_after bigint; v_failed boolean := false;
begin
  select count(*) into v_before from tse_receitas where ano_eleicao = 1998;  -- 30 do T2
  v_run := pg_temp.seed_run('receitas', 1998, 5);
  update tse_receitas_staging set numero_recibo = numero_recibo || '-VENENO'
   where run_id = v_run and numero_recibo like '%-3';
  execute 'create trigger trg_veneno before insert on public.tse_receitas
             for each row execute function pg_temp.veneno()';
  begin
    perform tse_promote_year('receitas', 1998, v_run, 1);
  exception when others then v_failed := true;
  end;
  execute 'drop trigger trg_veneno on public.tse_receitas';
  if not v_failed then raise exception 'T7 FALHA: insert envenenado deveria falhar'; end if;
  select count(*) into v_after from tse_receitas where ano_eleicao = 1998;
  if v_after <> v_before then
    raise exception 'T7 FALHA: rollback nao preservou a final (% -> %)', v_before, v_after;
  end if;
  raise notice 'T7 OK: transacao revertida; final preservada (% linhas)', v_after;
end $$;

-- ---------------------------------------------------------------------------
-- 8. advisory lock permanece na função
-- ---------------------------------------------------------------------------
do $$
begin
  if position('pg_advisory_xact_lock' in pg_get_functiondef('public.tse_promote_year'::regproc)) = 0 then
    raise exception 'T8 FALHA: pg_advisory_xact_lock sumiu de tse_promote_year';
  end if;
  raise notice 'T8 OK: advisory lock presente (exclusao mutua real coberta por test_concurrency_psycopg.py)';
end $$;

-- ---------------------------------------------------------------------------
-- 9. nenhuma UNIQUE sobre source_id (staging e finais)
-- ---------------------------------------------------------------------------
do $$
declare v_cnt int;
begin
  select count(*) into v_cnt
    from pg_index i
    join pg_class t on t.oid = i.indrelid
    join pg_attribute a on a.attrelid = t.oid and a.attnum = any(i.indkey)
   where t.relname in ('tse_receitas','tse_despesas','tse_receitas_staging','tse_despesas_staging')
     and i.indisunique and a.attname = 'source_id';
  if v_cnt > 0 then raise exception 'T9 FALHA: % indice(s) UNIQUE cobrindo source_id', v_cnt; end if;
  raise notice 'T9 OK: zero UNIQUE sobre source_id';
end $$;

\echo 'test_promote_intersecao: SUCESSO (9/9 cenarios)'
