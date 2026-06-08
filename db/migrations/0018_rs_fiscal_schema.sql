-- RS Fiscal — despesas estaduais + log de ingestão
-- Fonte: dados.rs.gov.br (CAGE/RS — Contadoria e Auditoria-Geral do Estado)
-- Criado em: 2026-06-05

-- ── Despesas ──────────────────────────────────────────────────────────────────
create table if not exists rs_despesas (
    id                          text primary key,   -- "rs_<YYYYMM>_<empenho>_<fase>"

    ano_exercicio               integer not null,
    mes                         integer,
    fase_gasto                  text,               -- Empenho | Liquidação | Pagamento
    tipo_gasto                  text,

    numero_empenho              text,
    numero_processo             text,
    numero_contrato             text,

    cod_credor                  text,
    favorecido                  text,
    cnpj                        text,               -- chave de cruzamento (só dígitos)

    orgao                       text,
    uo                          text,
    elemento                    text,
    modalidade                  text,
    procedimento_licitatorio    text,
    tipo_procedimento           text,

    -- campo único em relação ao MG: município já vem no CSV
    municipio                   text,
    cod_municipio               text,

    data_gasto                  date,
    valor                       numeric(18,2),

    funcao                      text,
    subfuncao                   text,
    programa                    text,
    acao                        text,

    updated_at                  timestamptz default now()
);

create index if not exists rs_despesas_cnpj_idx      on rs_despesas (cnpj);
create index if not exists rs_despesas_ano_idx       on rs_despesas (ano_exercicio);
create index if not exists rs_despesas_municipio_idx on rs_despesas (municipio);
create index if not exists rs_despesas_fase_idx      on rs_despesas (fase_gasto);
create index if not exists rs_despesas_elemento_idx  on rs_despesas (elemento);

-- ── Log de ingestão ────────────────────────────────────────────────────────────
create table if not exists rs_ingest_log (
    id          uuid primary key default gen_random_uuid(),
    dataset     text not null,
    status      text not null default 'running',
    n_gravados  integer,
    erro        text,
    started_at  timestamptz default now(),
    finished_at timestamptz
);

-- ── View: cruzamento RS × emendas federais por CNPJ ──────────────────────────
-- Empresas que recebem despesas do governo RS E emendas parlamentares federais.
-- Inclui município destino — fecha o fio bancada RS → empresa → onde chegou.
create or replace view rs_cruzamento_emendas as
with rs_agg as (
    select
        cnpj,
        max(favorecido)         as razao_social_rs,
        count(distinct id)      as n_despesas_rs,
        sum(valor)              as total_pago_rs,
        -- municípios únicos onde a empresa recebeu pagamentos do RS
        array_agg(distinct municipio order by municipio) filter (
            where municipio is not null
        )                       as municipios_rs
    from rs_despesas
    where cnpj is not null
      and fase_gasto = 'Pagamento'
    group by cnpj
),
fed_agg as (
    select
        regexp_replace(codigo_favorecido, '[^0-9]', '', 'g') as cnpj_digits,
        count(distinct id)                                    as n_transacoes_emendas_fed,
        sum(valor_recebido)                                   as total_emendas_fed,
        array_agg(distinct nome_autor order by nome_autor) filter (
            where nome_autor is not null
        )                                                     as autores_emendas
    from emendas_favorecidos
    where codigo_favorecido is not null
    group by 1
)
select
    r.cnpj,
    r.razao_social_rs,
    r.n_despesas_rs,
    r.total_pago_rs,
    r.municipios_rs,
    f.n_transacoes_emendas_fed,
    f.total_emendas_fed,
    f.autores_emendas
from rs_agg r
join fed_agg f on r.cnpj = f.cnpj_digits
order by r.total_pago_rs desc nulls last;

comment on view rs_cruzamento_emendas is
    'Empresas que recebem pagamentos do governo RS E emendas federais. '
    'municipios_rs mostra onde o dinheiro estadual chegou no RS.';
