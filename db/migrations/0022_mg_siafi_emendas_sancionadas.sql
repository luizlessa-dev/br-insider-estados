-- Migration 0022: MG SIAFI + Emendas Federais MG + Empresas Sancionadas MG
-- Fonte: dados.mg.gov.br (Portal de Dados Abertos MG)

-- ── SIAFI MG — execução financeira estadual ──────────────────────────────
create table if not exists mg_siafi_execucao (
    id                          text primary key,
    ano_exercicio               integer not null,
    unidade_orcamentaria_codigo text,
    unidade_orcamentaria_nome   text,
    orgao_codigo                text,
    orgao_nome                  text,
    funcao_codigo               text,
    funcao_descricao            text,
    subfuncao_codigo            text,
    subfuncao_descricao         text,
    programa_codigo             text,
    programa_descricao          text,
    acao_codigo                 text,
    acao_descricao              text,
    elemento_despesa_codigo     text,
    elemento_despesa_descricao  text,
    fonte_recurso_codigo        text,
    fonte_recurso_descricao     text,
    numero_empenho              text,
    data_empenho                date,
    razao_social_credor         text,
    cnpj_cpf_credor             text,
    valor_empenhado             numeric(18,2) default 0,
    valor_liquidado             numeric(18,2) default 0,
    valor_pago                  numeric(18,2) default 0,
    updated_at                  timestamptz default now()
);

create index if not exists idx_mg_siafi_cnpj    on mg_siafi_execucao (cnpj_cpf_credor);
create index if not exists idx_mg_siafi_ano     on mg_siafi_execucao (ano_exercicio);
create index if not exists idx_mg_siafi_orgao   on mg_siafi_execucao (orgao_codigo);
create index if not exists idx_mg_siafi_empenho on mg_siafi_execucao (numero_empenho);

-- ── Emendas Federais recebidas por MG ────────────────────────────────────
create table if not exists mg_emendas_federais (
    id               text primary key,
    esfera           text,
    modalidade       text,
    autoridade       text,
    tipo_instrumento text,
    numero_emenda    text,
    ano_emenda       integer,
    codigo_siafi     text,
    codigo_sigcon    text,
    valor_indicado   numeric(18,2) default 0,
    valor_repassado  numeric(18,2) default 0,
    objeto           text,
    funcao_governo   text,
    orgao_executor   text,
    updated_at       timestamptz default now()
);

create index if not exists idx_mg_emendas_numero on mg_emendas_federais (numero_emenda);
create index if not exists idx_mg_emendas_ano    on mg_emendas_federais (ano_emenda);
create index if not exists idx_mg_emendas_siafi  on mg_emendas_federais (codigo_siafi);

-- ── Execução de Emendas PIX (MG) ─────────────────────────────────────────
create table if not exists mg_emendas_pix (
    id              text primary key,
    numero_emenda   text,
    ano_emenda      integer,
    cnpj_favorecido text,
    nome_favorecido text,
    municipio       text,
    valor_pago      numeric(18,2) default 0,
    data_pagamento  date,
    objeto          text,
    updated_at      timestamptz default now()
);

create index if not exists idx_mg_emendas_pix_cnpj   on mg_emendas_pix (cnpj_favorecido);
create index if not exists idx_mg_emendas_pix_emenda  on mg_emendas_pix (numero_emenda);

-- ── Empresas Sancionadas — Lei Anticorrupção MG ───────────────────────────
create table if not exists mg_empresas_sancionadas (
    id                       text primary key,
    sei                      text,
    numero                   text,
    ano                      integer,
    portaria                 text,
    data_publicacao_portaria date,
    orgao_instaurador        text,
    orgao_lesado             text,
    empresa                  text,
    tipo_societario          text,
    cnpj                     text,
    conduta                  text,
    data_decisao             date,
    decisao                  text,
    fase                     text,
    valor_multa              numeric(18,2) default 0,
    updated_at               timestamptz default now()
);

create index if not exists idx_mg_sancionadas_cnpj on mg_empresas_sancionadas (cnpj);
