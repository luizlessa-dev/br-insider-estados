-- ALEPI — Assembleia Legislativa do Piauí
create table if not exists ale_parlamentares_alepi (id bigint primary key, assembly_id text default 'alepi', nome text, partido text, uf text default 'PI', foto_url text, email text, raw jsonb, criado_em timestamp default now());
create table if not exists ale_proposicoes_alepi (id bigint primary key, assembly_id text default 'alepi', numero text, titulo text, data_apresentacao date, status text, criado_em timestamp default now());
create table if not exists ale_votacoes_alepi (id bigint primary key, proposicao_id bigint, data_votacao date, resultado text, criado_em timestamp default now());
create index if not exists idx_alepi_parlamentares_nome on ale_parlamentares_alepi(nome);
create index if not exists idx_alepi_proposicoes_data on ale_proposicoes_alepi(data_apresentacao);
