-- ALESC — Assembleia Legislativa de Santa Catarina
-- 2026-08-02: Initial schema for ALESC connector (Tier 2, site structure pending mapping)

-- Table: ale_parlamentares_alesc
create table if not exists ale_parlamentares_alesc (
  id bigint primary key,
  assembly_id text not null default 'alesc',
  nome text not null,
  partido text,
  uf text not null default 'SC',
  foto_url text,
  email text,
  raw jsonb,
  criado_em timestamp default now(),
  atualizado_em timestamp default now()
);

-- Table: ale_proposicoes_alesc
create table if not exists ale_proposicoes_alesc (
  id bigint primary key,
  assembly_id text default 'alesc',
  numero text,
  titulo text,
  data_apresentacao date,
  autor_id bigint,
  status text,
  criado_em timestamp default now()
);

-- Table: ale_votacoes_alesc
create table if not exists ale_votacoes_alesc (
  id bigint primary key,
  proposicao_id bigint,
  data_votacao date,
  resultado text,
  criado_em timestamp default now()
);

-- Table: ale_votos_alesc
create table if not exists ale_votos_alesc (
  id bigint primary key,
  votacao_id bigint,
  parlamentar_id bigint,
  voto text,
  criado_em timestamp default now()
);

-- Indexes for performance
create index if not exists idx_alesc_parlamentares_nome on ale_parlamentares_alesc(nome);
create index if not exists idx_alesc_parlamentares_partido on ale_parlamentares_alesc(partido);
create index if not exists idx_alesc_proposicoes_data on ale_proposicoes_alesc(data_apresentacao);
create index if not exists idx_alesc_votacoes_data on ale_votacoes_alesc(data_votacao);

-- View: reconciliation
create or replace view ale_parlamentares_alesc_reconciliado as
select
  alp.id,
  alp.nome,
  alp.partido,
  alp.uf,
  alp.foto_url,
  alp.email,
  count(distinct aprop.id) as proposicoes_count,
  count(distinct av.id) as votos_count,
  alp.criado_em,
  alp.atualizado_em
from ale_parlamentares_alesc alp
left join ale_proposicoes_alesc aprop on alp.id = aprop.autor_id
left join ale_votos_alesc av on alp.id = av.parlamentar_id
group by alp.id, alp.nome, alp.partido, alp.uf, alp.foto_url, alp.email, alp.criado_em, alp.atualizado_em;

-- Metadata: track ingestion runs
create table if not exists ale_ingest_runs_alesc (
  run_id uuid primary key default gen_random_uuid(),
  assembly_id text default 'alesc',
  entidade text not null,
  status text not null,
  registros_processados int,
  erro_mensagem text,
  iniciado_em timestamp default now(),
  finalizado_em timestamp
);

create index if not exists idx_alesc_ingest_runs_assembly on ale_ingest_runs_alesc(assembly_id);
create index if not exists idx_alesc_ingest_runs_entidade on ale_ingest_runs_alesc(entidade);
