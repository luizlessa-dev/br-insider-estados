-- ALERN — Assembleia Legislativa do Rio Grande do Norte
create table if not exists ale_parlamentares_alern (id bigint primary key, assembly_id text default 'alern', nome text, partido text, uf text default 'RN', foto_url text, email text, raw jsonb, criado_em timestamp default now());
create table if not exists ale_proposicoes_alern (id bigint primary key, assembly_id text default 'alern', numero text, titulo text, data_apresentacao date, status text, criado_em timestamp default now());
create table if not exists ale_votacoes_alern (id bigint primary key, proposicao_id bigint, data_votacao date, resultado text, criado_em timestamp default now());
create index if not exists idx_alern_parlamentares_nome on ale_parlamentares_alern(nome);
create index if not exists idx_alern_proposicoes_data on ale_proposicoes_alern(data_apresentacao);
