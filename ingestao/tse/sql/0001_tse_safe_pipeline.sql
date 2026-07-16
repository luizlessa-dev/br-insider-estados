-- ============================================================================
-- TSE — pipeline seguro: staging estável + log de execução + swap atômico.
--
-- DELIVERABLE / NÃO APLICADO. Home canônico definitivo: quando o baseline for
-- autorizado, esta DDL deve ser promovida para
-- transparencia-federal/supabase/migrations/ (regra nova: DDL é
-- responsabilidade exclusiva das migrations, nunca criada em runtime).
--
-- Elimina o delete-before-load destrutivo. O pipeline carrega em staging
-- estável (criado AQUI, não em runtime), isolado por run_id, e só troca o ano
-- na final via tse_promote_year(): advisory lock + quality gates + DELETE+INSERT
-- numa única transação. Qualquer falha reverte tudo; a final nunca é tocada
-- antes de download + validação + staging completo + gates aprovados.
-- ============================================================================

-- ── 1. Staging estável (espelha o schema da final) ──────────────────────────
create table if not exists public.tse_receitas_staging
  (like public.tse_receitas including defaults);
alter table public.tse_receitas_staging
  add column if not exists run_id uuid not null,
  add column if not exists staged_at timestamptz not null default now();
create index if not exists idx_tse_receitas_staging_run
  on public.tse_receitas_staging (run_id);

create table if not exists public.tse_despesas_staging
  (like public.tse_despesas including defaults);
alter table public.tse_despesas_staging
  add column if not exists run_id uuid not null,
  add column if not exists staged_at timestamptz not null default now();
create index if not exists idx_tse_despesas_staging_run
  on public.tse_despesas_staging (run_id);

-- Postura pós-P0: RLS ligada, sem policy (só service_role), sem grant a anon/auth.
alter table public.tse_receitas_staging enable row level security;
alter table public.tse_despesas_staging enable row level security;
revoke all on public.tse_receitas_staging from anon, authenticated;
revoke all on public.tse_despesas_staging from anon, authenticated;

-- ── 2. Log de execução por run ──────────────────────────────────────────────
create table if not exists public.tse_load_runs (
  run_id            uuid primary key,
  dataset           text not null check (dataset in ('receitas','despesas')),
  ano               int  not null,
  phase             text not null default 'iniciado'
                    check (phase in ('iniciado','baixado','validado','staged',
                                     'quality_ok','promovido','falha')),
  status            text not null default 'running'
                    check (status in ('running','ok','erro')),
  rows_downloaded   bigint,
  rows_parsed       bigint,
  rows_staged       bigint,
  rows_final_before bigint,
  rows_final_after  bigint,
  min_expected      bigint,
  source_url        text,
  zip_bytes         bigint,
  error             text,
  started_at        timestamptz not null default now(),
  finished_at       timestamptz,
  staging_expires_at timestamptz
);
create index if not exists idx_tse_load_runs_dataset_ano
  on public.tse_load_runs (dataset, ano, started_at desc);

alter table public.tse_load_runs enable row level security;
revoke all on public.tse_load_runs from anon, authenticated;

-- ── 3. Swap atômico endurecido ──────────────────────────────────────────────
-- A função inteira roda numa transação: DELETE e INSERT acontecem juntos ou
-- nenhum acontece (rollback automático em qualquer erro/raise). O advisory lock
-- xact-scoped serializa promoções concorrentes do mesmo (dataset, ano).
--
-- Segurança de nome de tabela: v_final/v_stage/v_natkey NUNCA vêm de entrada do
-- chamador — são atribuídos de um whitelist estrito (if/elif) e interpolados só
-- via %I (quote_ident). p_dataset fora de {receitas,despesas} aborta.
create or replace function public.tse_promote_year(
  p_dataset      text,
  p_ano          int,
  p_run_id       uuid,
  p_min_expected bigint
) returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_final   text;
  v_stage   text;
  v_natkey  text;      -- chave natural do dataset (não nula, sem duplicidade)
  v_cols    text;
  v_run     record;
  v_staged  bigint;
  v_wrong_year bigint;
  v_null_key   bigint;
  v_dups       bigint;
  v_before  bigint;
  v_after   bigint;
begin
  -- 3.1 dataset estritamente limitado
  if p_dataset = 'receitas' then
    v_final := 'tse_receitas'; v_stage := 'tse_receitas_staging'; v_natkey := 'numero_recibo';
  elsif p_dataset = 'despesas' then
    v_final := 'tse_despesas'; v_stage := 'tse_despesas_staging'; v_natkey := 'numero_documento';
  else
    raise exception 'dataset invalido: %', p_dataset;
  end if;

  -- 3.2 advisory lock por (dataset, ano): promoção simultânea do mesmo alvo espera
  perform pg_advisory_xact_lock(hashtext(p_dataset), p_ano);

  -- 3.3 run vinculado a dataset+ano e ainda não promovido (idempotência)
  select * into v_run from public.tse_load_runs where run_id = p_run_id;
  if not found then
    raise exception 'run % inexistente em tse_load_runs', p_run_id;
  end if;
  if v_run.dataset <> p_dataset or v_run.ano <> p_ano then
    raise exception 'run % nao pertence a (%,%): tem (%,%)',
      p_run_id, p_dataset, p_ano, v_run.dataset, v_run.ano;
  end if;
  if v_run.phase = 'promovido' then
    -- já promovido: não repromove. Retorno idempotente.
    return jsonb_build_object('dataset', p_dataset, 'ano', p_ano, 'run_id', p_run_id,
                              'already_promoted', true);
  end if;

  -- 3.4 quality gates de integridade no staging DESTE run
  execute format('select count(*) from %I where run_id = $1', v_stage)
    into v_staged using p_run_id;
  if v_staged = 0 then
    raise exception 'staging vazio (dataset=% ano=% run=%)', p_dataset, p_ano, p_run_id;
  end if;

  -- sem mistura de anos: toda linha do run tem ano_eleicao = p_ano
  execute format('select count(*) from %I where run_id = $1 and ano_eleicao is distinct from $2', v_stage)
    into v_wrong_year using p_run_id, p_ano;
  if v_wrong_year > 0 then
    raise exception 'mistura de anos: % linhas com ano != % (run %)', v_wrong_year, p_ano, p_run_id;
  end if;

  -- chave natural não nula
  execute format('select count(*) from %I where run_id = $1 and %I is null', v_stage, v_natkey)
    into v_null_key using p_run_id;
  if v_null_key > 0 then
    raise exception 'chave natural nula: % linhas sem % (run %)', v_null_key, v_natkey, p_run_id;
  end if;

  -- zero duplicidade da chave natural dentro do run
  execute format(
    'select coalesce(sum(c-1),0) from (select count(*) c from %I where run_id = $1 group by %I having count(*) > 1) d',
    v_stage, v_natkey)
    into v_dups using p_run_id;
  if v_dups > 0 then
    raise exception 'duplicidade de chave natural: % repeticoes de % (run %)', v_dups, v_natkey, p_run_id;
  end if;

  -- gate de contagem: staged >= min_expected (variação percentual contra execução anterior)
  if p_min_expected is not null and v_staged < p_min_expected then
    raise exception 'queda anormal: staged=% < min_expected=% (dataset=% ano=%)',
      v_staged, p_min_expected, p_dataset, p_ano;
  end if;

  execute format('select count(*) from %I where ano_eleicao = $1', v_final)
    into v_before using p_ano;

  -- lista de colunas do staging exceto as de controle (quote_ident → seguro)
  select string_agg(quote_ident(column_name), ', ')
    into v_cols
    from information_schema.columns
   where table_schema = 'public' and table_name = v_stage
     and column_name not in ('run_id','staged_at');

  -- 3.5 SWAP ATÔMICO (mesma transação): substitui o ano inteiro
  execute format('delete from %I where ano_eleicao = $1', v_final) using p_ano;
  execute format(
    'insert into %I (%s) select %s from %I where run_id = $1',
    v_final, v_cols, v_cols, v_stage
  ) using p_run_id;

  execute format('select count(*) from %I where ano_eleicao = $1', v_final)
    into v_after using p_ano;

  -- 3.6 marca run como promovido e limpa staging deste run
  update public.tse_load_runs
     set phase = 'promovido', status = 'ok',
         rows_final_before = v_before, rows_final_after = v_after,
         rows_staged = v_staged, finished_at = now()
   where run_id = p_run_id;

  execute format('delete from %I where run_id = $1', v_stage) using p_run_id;

  return jsonb_build_object('dataset', p_dataset, 'ano', p_ano, 'run_id', p_run_id,
                            'rows_before', v_before, 'rows_staged', v_staged,
                            'rows_after', v_after);
end;
$$;

-- Só service_role executa (postura pós-P0).
revoke all on function public.tse_promote_year(text, int, uuid, bigint) from public;
revoke all on function public.tse_promote_year(text, int, uuid, bigint) from anon, authenticated;
grant execute on function public.tse_promote_year(text, int, uuid, bigint) to service_role;

-- Owner esperado: postgres (SECURITY DEFINER roda com privilégio do dono).
-- Confirmar pós-aplicação: select pg_get_userbyid(proowner) from pg_proc
--   where proname='tse_promote_year';  -- deve retornar 'postgres'.
alter function public.tse_promote_year(text, int, uuid, bigint) owner to postgres;

-- ── 4. GC de staging expirado (idempotente) ─────────────────────────────────
create or replace function public.tse_gc_staging()
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_run record;
  v_removed bigint := 0;
begin
  for v_run in
    select run_id, dataset from public.tse_load_runs
    where staging_expires_at is not null and staging_expires_at < now()
  loop
    if v_run.dataset = 'receitas' then
      delete from public.tse_receitas_staging where run_id = v_run.run_id;
    elsif v_run.dataset = 'despesas' then
      delete from public.tse_despesas_staging where run_id = v_run.run_id;
    end if;
    v_removed := v_removed + 1;
    update public.tse_load_runs set staging_expires_at = null where run_id = v_run.run_id;
  end loop;
  return jsonb_build_object('runs_limpos', v_removed);
end;
$$;

revoke all on function public.tse_gc_staging() from public, anon, authenticated;
grant execute on function public.tse_gc_staging() to service_role;
alter function public.tse_gc_staging() owner to postgres;
