-- Migration 0024: Despesas do Governo do Estado de SP (SIGEO Lei 131)
-- Fonte: fazenda.sp.gov.br/SigeoLei131 — download anual
-- Cobertura: 2023, 2024, 2025 (~3,5M linhas)

create table if not exists sp_despesas (
    id                          bigserial primary key,

    -- Classificação orçamentária
    ano                         smallint       not null,
    cod_orgao                   varchar(10)    not null,
    nome_orgao                  text,
    cod_uo                      varchar(10),
    nome_uo                     text,
    cod_ug                      varchar(10),
    nome_ug                     text,

    cod_categoria               varchar(5),
    nome_categoria              text,
    cod_grupo                   varchar(5),
    nome_grupo                  text,
    cod_modalidade              varchar(10),
    nome_modalidade             text,
    cod_elemento                varchar(10),
    nome_elemento               text,
    cod_item                    varchar(15),
    nome_item                   text,

    cod_funcao                  varchar(5),
    nome_funcao                 text,
    cod_subfuncao               varchar(5),
    nome_subfuncao              text,
    cod_programa                varchar(10),
    nome_programa               text,
    cod_ptrab                   varchar(20),
    nome_ptrab                  text,
    cod_fonte                   varchar(10),
    nome_fonte                  text,

    -- Documento
    numero_processo             varchar(30),
    numero_empenho              varchar(30),

    -- Credor (fornecedor)
    cod_credor                  varchar(20),
    nome_credor                 text,
    cnpj_credor                 varchar(14),   -- 14 dígitos sem formatação (quando PJ)

    -- Ação
    cod_acao                    varchar(20),
    nome_acao                   text,
    tipo_licitacao              text,

    -- Valores
    valor_empenhado             numeric(18,2)  default 0,
    valor_liquidado             numeric(18,2)  default 0,
    valor_pago                  numeric(18,2)  default 0,
    valor_pago_anos_ant         numeric(18,2)  default 0,

    created_at                  timestamptz    default now()
);

-- Índices para cruzamento por fornecedor
create index if not exists sp_despesas_cnpj_credor_idx  on sp_despesas (cnpj_credor);
create index if not exists sp_despesas_ano_orgao_idx     on sp_despesas (ano, cod_orgao);
create index if not exists sp_despesas_cod_credor_idx    on sp_despesas (cod_credor);

-- Constraint de unicidade por empenho + ano (evita duplicatas no upsert)
alter table sp_despesas
    add constraint sp_despesas_empenho_ano_uq
    unique (ano, numero_empenho, cod_credor, cod_item);

-- View auxiliar: resumo por credor × ano
create or replace view sp_despesas_por_credor as
select
    cnpj_credor,
    nome_credor,
    ano,
    count(*)                    as total_empenhos,
    sum(valor_empenhado)        as total_empenhado,
    sum(valor_liquidado)        as total_liquidado,
    sum(valor_pago)             as total_pago,
    array_agg(distinct nome_orgao order by nome_orgao) filter (where nome_orgao is not null) as orgaos
from sp_despesas
where cnpj_credor is not null
group by cnpj_credor, nome_credor, ano;
