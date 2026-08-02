-- ALEPA — Assembleia Legislativa do Pará (Tier 3, JS-rendering site)
create table if not exists ale_parlamentares_alepa (id bigint primary key, assembly_id text default 'alepa', nome text, partido text, uf text default 'PA', foto_url text, email text, raw jsonb, criado_em timestamp default now());
create table if not exists ale_proposicoes_alepa (id bigint primary key, assembly_id text default 'alepa', numero text, titulo text, data_apresentacao date, status text, criado_em timestamp default now());
create table if not exists ale_votacoes_alepa (id bigint primary key, proposicao_id bigint, data_votacao date, resultado text, criado_em timestamp default now());
create index if not exists idx_alepa_parlamentares_nome on ale_parlamentares_alepa(nome);
create index if not exists idx_alepa_proposicoes_data on ale_proposicoes_alepa(data_apresentacao);
