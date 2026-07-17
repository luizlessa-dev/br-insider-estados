-- ============================================================================
-- TSE — pipeline seguro: staging estável + progresso + swap atômico + override.
--
-- DELIVERABLE / NÃO APLICADO EM PRODUÇÃO. Home canônico: quando o baseline for
-- autorizado, promover para transparencia-federal/supabase/migrations/.
--
-- DDL RESOLVIDA (sem LIKE): as colunas de staging são declaradas explicitamente,
-- espelhando os tipos reais de public.tse_receitas / public.tse_despesas
-- (introspecção 2026-07-16), EXCETO:
--   • id / sequência  — NÃO copiada: a final gera o id no INSERT do swap.
--   • ingested_at     — NÃO copiada: a final preenche via default now().
--   • índices de consulta (trgm/parciais) — NÃO copiados: staging é efêmero.
--   • PK do id, defaults, triggers, identity — NÃO copiados (não há triggers na
--     final; não há identity — id usa nextval de sequência própria da final).
-- Constraint copiada/adaptada: a UNIQUE natural. Ver nota de unicidade abaixo.
-- ============================================================================

-- IDENTIDADE — row_fingerprint (ver análise de unicidade).
-- Descoberta empírica (produção, 2026-07-16): numero_recibo (receitas) e
-- numero_documento (despesas) são 100% NULL nos anos recentes (2022/2024). A
-- chave natural do TSE (SQ_RECEITA/SQ_DESPESA) NÃO é capturada pelo parser
-- atual. Um NULLS NOT DISTINCT sobre a natkey colapsaria TODAS as linhas nulas
-- num único registro → perda massiva. Um hash só de conteúdo colapsa ~5–6% de
-- linhas legítimas idênticas.
--
-- Solução: row_fingerprint = SHA-256( ano | ordinal_no_arquivo | conteúdo
-- normalizado ). O ordinal (posição determinística na sequência de parse de um
-- ZIP estático pós-eleição) distingue linhas legítimas idênticas; o conteúdo
-- detecta drift do arquivo. UNIQUE (run_id, row_fingerprint) → idempotência de
-- reenvio do mesmo arquivo/run e zero colapso de duplicatas legítimas.

-- ── 1. Staging receitas ─────────────────────────────────────────────────────
create table if not exists public.tse_receitas_staging (
  ano_eleicao                smallint      not null,
  numero_recibo              text,
  cpf_candidato              text,
  nome_candidato             text,
  cargo                      text,
  sigla_partido              text,
  uf                         character(2),
  cpf_cnpj_doador            text,
  nome_doador                text,
  tipo_doador                text,
  setor_economico_doador     text,
  cpf_cnpj_doador_originario text,
  nome_doador_originario     text,
  natureza_receita           text,
  origem_receita             text,
  especie_recurso            text,
  fonte_recurso              text,
  valor                      numeric(16,2) not null,
  data_receita               date,
  data_prestacao_contas      date,
  -- controle
  run_id                     uuid          not null,
  row_fingerprint            text          not null,
  staged_at                  timestamptz   not null default now()
);
create unique index if not exists uq_tse_receitas_staging_fp
  on public.tse_receitas_staging (run_id, row_fingerprint);

-- ── 2. Staging despesas ─────────────────────────────────────────────────────
create table if not exists public.tse_despesas_staging (
  ano_eleicao         smallint      not null,
  numero_documento    text,
  cpf_candidato       text,
  nome_candidato      text,
  cargo               text,
  sigla_partido       text,
  uf                  character(2),
  cpf_cnpj_fornecedor text,
  nome_fornecedor     text,
  tipo_despesa        text,
  descricao_despesa   text,
  origem_despesa      text,
  especie_recurso     text,
  fonte_recurso       text,
  valor_despesa       numeric(16,2) not null,
  valor_prestado      numeric(16,2),
  data_despesa        date,
  run_id              uuid          not null,
  row_fingerprint     text          not null,
  staged_at           timestamptz   not null default now()
);
create unique index if not exists uq_tse_despesas_staging_fp
  on public.tse_despesas_staging (run_id, row_fingerprint);

-- Postura pós-P0: RLS ligada, sem policy (só service_role), sem grant anon/auth.
alter table public.tse_receitas_staging enable row level security;
alter table public.tse_despesas_staging enable row level security;
revoke all on public.tse_receitas_staging from anon, authenticated;
revoke all on public.tse_despesas_staging from anon, authenticated;

-- ── 3. Progresso persistido por run (retomável) ─────────────────────────────
create table if not exists public.tse_load_runs (
  run_id            uuid primary key,
  dataset           text not null check (dataset in ('receitas','despesas')),
  ano               int  not null,
  phase             text not null default 'iniciado'
                    check (phase in ('iniciado','baixado','validado','staging',
                                     'staged','quality_ok','promovido','falha')),
  status            text not null default 'running'
                    check (status in ('running','ok','erro')),
  -- progresso de staging (retomada)
  batches_total          int,
  batch_atual            int     default 0,
  ultimo_batch_confirmado int    default 0,
  linhas_parseadas       bigint  default 0,
  linhas_staged          bigint  default 0,
  linhas_enviadas        bigint  default 0,   -- soma de linhas POST enviadas
  linhas_inseridas       bigint  default 0,   -- efetivamente inseridas (não-conflito)
  linhas_ignoradas       bigint  default 0,   -- ON CONFLICT DO NOTHING (retomada)
  -- proveniência / retomada (um staging pertence a UM arquivo)
  zip_sha256             text,
  pipeline_commit        text,
  transformer_version    text,
  -- swap
  rows_final_before bigint,
  rows_final_after  bigint,
  min_expected      bigint,
  null_key_count    bigint,        -- chaves naturais nulas (visível, não bloqueia)
  -- override auditado (ver seção 5)
  override_gate     boolean not null default false,
  override_motivo   text,
  override_by       text,
  override_at       timestamptz,
  source_url        text,
  zip_bytes         bigint,
  error             text,
  started_at        timestamptz not null default now(),
  finished_at       timestamptz,
  staging_expires_at timestamptz
);
create index if not exists idx_tse_load_runs_dataset_ano
  on public.tse_load_runs (dataset, ano, started_at desc);
create index if not exists idx_tse_load_runs_incompletos
  on public.tse_load_runs (dataset, ano) where status = 'running';

alter table public.tse_load_runs enable row level security;
revoke all on public.tse_load_runs from anon, authenticated;

-- ── 4. Swap atômico endurecido (com override auditado) ──────────────────────
create or replace function public.tse_promote_year(
  p_dataset      text,
  p_ano          int,
  p_run_id       uuid,
  p_min_expected bigint,
  p_override     boolean default false,
  p_override_motivo text default null,
  p_override_by  text default null
) returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_final   text;
  v_stage   text;
  v_natkey  text;
  v_cols    text;
  v_run     record;
  v_staged  bigint;
  v_wrong_year bigint;
  v_null_key   bigint;
  v_dups       bigint;
  v_before  bigint;
  v_after   bigint;
begin
  -- 4.1 dataset estritamente limitado (whitelist; nomes nunca vêm do chamador)
  if p_dataset = 'receitas' then
    v_final := 'tse_receitas'; v_stage := 'tse_receitas_staging'; v_natkey := 'numero_recibo';
  elsif p_dataset = 'despesas' then
    v_final := 'tse_despesas'; v_stage := 'tse_despesas_staging'; v_natkey := 'numero_documento';
  else
    raise exception 'dataset invalido: %', p_dataset;
  end if;

  -- 4.2 override: só válido com motivo não vazio (registrado adiante)
  if p_override then
    if p_override_motivo is null or btrim(p_override_motivo) = '' then
      raise exception 'override exige motivo nao vazio';
    end if;
  end if;

  -- 4.3 advisory lock por (dataset, ano)
  perform pg_advisory_xact_lock(hashtext(p_dataset), p_ano);

  -- 4.4 run vinculado a dataset+ano e ainda não promovido (idempotência)
  select * into v_run from public.tse_load_runs where run_id = p_run_id;
  if not found then
    raise exception 'run % inexistente em tse_load_runs', p_run_id;
  end if;
  if v_run.dataset <> p_dataset or v_run.ano <> p_ano then
    raise exception 'run % nao pertence a (%,%): tem (%,%)',
      p_run_id, p_dataset, p_ano, v_run.dataset, v_run.ano;
  end if;
  if v_run.phase = 'promovido' then
    return jsonb_build_object('dataset', p_dataset, 'ano', p_ano, 'run_id', p_run_id,
                              'already_promoted', true);
  end if;

  execute format('select count(*) from %I where run_id = $1', v_stage)
    into v_staged using p_run_id;
  if v_staged = 0 then
    raise exception 'staging vazio (dataset=% ano=% run=%)', p_dataset, p_ano, p_run_id;
  end if;

  -- 4.5 GATES DE INTEGRIDADE — NUNCA ignorados pelo override.
  -- (a) sem mistura de anos
  execute format('select count(*) from %I where run_id = $1 and ano_eleicao is distinct from $2', v_stage)
    into v_wrong_year using p_run_id, p_ano;
  if v_wrong_year > 0 then
    raise exception 'mistura de anos: % linhas com ano != % (run %)', v_wrong_year, p_ano, p_run_id;
  end if;
  -- (b) zero duplicidade da chave natural NÃO NULA (evita violar unique da final)
  execute format(
    'select coalesce(sum(c-1),0) from (select count(*) c from %I where run_id=$1 and %I is not null group by %I having count(*)>1) d',
    v_stage, v_natkey, v_natkey)
    into v_dups using p_run_id;
  if v_dups > 0 then
    raise exception 'duplicidade de chave natural: % repeticoes de % (run %)', v_dups, v_natkey, p_run_id;
  end if;
  -- (c) chaves naturais nulas: contadas e visíveis (a final PERMITE null; não bloqueia)
  execute format('select count(*) from %I where run_id=$1 and %I is null', v_stage, v_natkey)
    into v_null_key using p_run_id;

  -- 4.6 GATE DE CONTAGEM — este SIM pode ser sobreposto pelo override auditado.
  if p_min_expected is not null and v_staged < p_min_expected then
    if p_override then
      update public.tse_load_runs
         set override_gate = true, override_motivo = p_override_motivo,
             override_by = coalesce(p_override_by, session_user), override_at = now()
       where run_id = p_run_id;
      raise warning 'OVERRIDE gate de contagem: staged=% < min=% (run % por % motivo=%)',
        v_staged, p_min_expected, p_run_id, coalesce(p_override_by, session_user), p_override_motivo;
    else
      raise exception 'queda anormal: staged=% < min_expected=% (dataset=% ano=%). Use override auditado se intencional.',
        v_staged, p_min_expected, p_dataset, p_ano;
    end if;
  end if;

  execute format('select count(*) from %I where ano_eleicao = $1', v_final)
    into v_before using p_ano;

  select string_agg(quote_ident(column_name), ', ')
    into v_cols
    from information_schema.columns
   where table_schema = 'public' and table_name = v_stage
     and column_name not in ('run_id','staged_at','row_fingerprint');

  -- 4.7 SWAP ATÔMICO (mesma transação)
  execute format('delete from %I where ano_eleicao = $1', v_final) using p_ano;
  execute format('insert into %I (%s) select %s from %I where run_id = $1',
                 v_final, v_cols, v_cols, v_stage) using p_run_id;

  execute format('select count(*) from %I where ano_eleicao = $1', v_final)
    into v_after using p_ano;

  update public.tse_load_runs
     set phase='promovido', status='ok', rows_final_before=v_before,
         rows_final_after=v_after, linhas_staged=v_staged, null_key_count=v_null_key,
         finished_at=now()
   where run_id = p_run_id;

  execute format('delete from %I where run_id = $1', v_stage) using p_run_id;

  return jsonb_build_object('dataset', p_dataset, 'ano', p_ano, 'run_id', p_run_id,
                            'rows_before', v_before, 'rows_staged', v_staged,
                            'rows_after', v_after, 'null_key_count', v_null_key,
                            'override', p_override);
end;
$$;

revoke all on function public.tse_promote_year(text,int,uuid,bigint,boolean,text,text) from public, anon, authenticated;
grant execute on function public.tse_promote_year(text,int,uuid,bigint,boolean,text,text) to service_role;
alter function public.tse_promote_year(text,int,uuid,bigint,boolean,text,text) owner to postgres;

-- ── 5. GC de staging + runs abandonados ─────────────────────────────────────
create or replace function public.tse_gc_staging(p_abandon_after interval default interval '2 hours')
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_run record; v_removed bigint := 0; v_abandoned bigint := 0;
begin
  -- runs 'running' velhos demais → marcados abandonados (retomáveis ou GC)
  update public.tse_load_runs
     set status='erro', phase='falha', error=coalesce(error,'abandonado por timeout'),
         finished_at=now(),
         staging_expires_at=coalesce(staging_expires_at, now() + interval '7 days')
   where status='running' and started_at < now() - p_abandon_after;
  get diagnostics v_abandoned = row_count;

  for v_run in
    select run_id, dataset from public.tse_load_runs
    where staging_expires_at is not null and staging_expires_at < now()
  loop
    if v_run.dataset='receitas' then
      delete from public.tse_receitas_staging where run_id = v_run.run_id;
    else
      delete from public.tse_despesas_staging where run_id = v_run.run_id;
    end if;
    v_removed := v_removed + 1;
    update public.tse_load_runs set staging_expires_at=null where run_id=v_run.run_id;
  end loop;
  return jsonb_build_object('runs_abandonados', v_abandoned, 'staging_runs_limpos', v_removed);
end;
$$;

revoke all on function public.tse_gc_staging(interval) from public, anon, authenticated;
grant execute on function public.tse_gc_staging(interval) to service_role;
alter function public.tse_gc_staging(interval) owner to postgres;
