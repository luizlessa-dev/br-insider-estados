-- ALAL — Assembleia Legislativa de Alagoas
create table if not exists ale_parlamentares_alal (id bigint primary key, assembly_id text default 'alal', nome text, partido text, uf text default 'AL', foto_url text, email text, raw jsonb, criado_em timestamp default now());
create table if not exists ale_proposicoes_alal (id bigint primary key, assembly_id text default 'alal', numero text, titulo text, data_apresentacao date, status text, criado_em timestamp default now());
create table if not exists ale_votacoes_alal (id bigint primary key, proposicao_id bigint, data_votacao date, resultado text, criado_em timestamp default now());
create index if not exists idx_alal_parlamentares_nome on ale_parlamentares_alal(nome);
create index if not exists idx_alal_proposicoes_data on ale_proposicoes_alal(data_apresentacao);
