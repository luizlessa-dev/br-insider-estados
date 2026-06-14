-- Migration 0023: PBH Despesas Orçamentárias + CMBH
-- Fonte: ckan.pbh.gov.br (datasets despesas-orcamentarias + despesas-orcamentarias-cmbh)

create table if not exists pbh_despesas_orcamentarias (
    id                    text primary key,       -- md5(fonte:ano:empenho:linha)
    fonte                 text not null,           -- 'pbh' | 'cmbh'
    ano_exercicio         integer,
    dt_movimento          date,
    unidade_orcamentaria  text,
    numero_empenho        text,
    funcao                text,
    subfuncao             text,
    programa              text,
    acao                  text,
    elemento_despesa      text,
    natureza_despesa      text,
    nome_credor           text,
    cnpj_cpf_credor       text,
    modalidade_licitacao  text,
    numero_licitacao      text,
    numero_emenda         text,
    exercicio_emenda      integer,
    vl_empenhado          numeric(18,2) default 0,
    vl_liquidado          numeric(18,2) default 0,
    vl_pago               numeric(18,2) default 0,
    vl_liquidado_resto    numeric(18,2) default 0,
    vl_pago_resto         numeric(18,2) default 0,
    updated_at            timestamptz default now()
);

create index if not exists idx_pbh_desp_cnpj    on pbh_despesas_orcamentarias (cnpj_cpf_credor);
create index if not exists idx_pbh_desp_ano     on pbh_despesas_orcamentarias (ano_exercicio);
create index if not exists idx_pbh_desp_emenda  on pbh_despesas_orcamentarias (numero_emenda);
create index if not exists idx_pbh_desp_empenho on pbh_despesas_orcamentarias (numero_empenho);
create index if not exists idx_pbh_desp_fonte   on pbh_despesas_orcamentarias (fonte);
create index if not exists idx_pbh_desp_credor  on pbh_despesas_orcamentarias (nome_credor);
