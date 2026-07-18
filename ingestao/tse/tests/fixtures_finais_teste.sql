-- Fixture de TESTE: recria as tabelas finais com o schema estrutural REAL de
-- produção (introspecção 2026-07-18) — deliberadamente SEM source_id, que é o
-- cenário de produção. Uso exclusivo em banco descartável de teste.
create table if not exists public.tse_receitas (
  id                         bigserial primary key,
  ano_eleicao                smallint not null,
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
  ingested_at                timestamptz not null default now()
);
create unique index if not exists idx_tse_receitas_recibo_ano
  on public.tse_receitas (numero_recibo, ano_eleicao);

create table if not exists public.tse_despesas (
  id                  bigserial primary key,
  ano_eleicao         smallint not null,
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
  ingested_at         timestamptz not null default now()
);
