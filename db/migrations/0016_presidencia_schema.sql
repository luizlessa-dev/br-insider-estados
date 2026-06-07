-- =============================================================================
-- 0016_presidencia_schema.sql
-- Presidência da República — The BR Insider
-- Fonte: dadosabertos.presidencia.gov.br (download manual — WAF ativo)
-- Datasets:
--   1. Custos de ex-presidentes (Lei nº 7.474/1986) — XLSX granular SIC
--   2. Perfil e diversidade do pessoal da PR — CSV semestral/anual
-- =============================================================================

-- ---------------------------------------------------------------------------
-- pr_ex_presidentes_custos
-- Transações granulares do SIC por ex-presidente, natureza de despesa e mês.
-- Granularidade: 1 linha = 1 empenho/liquidação por centro de custo × mês.
-- Arquivo cobre 2021–2026 num único XLSX (~3.855 linhas).
-- ---------------------------------------------------------------------------
create table if not exists pr_ex_presidentes_custos (
    id                              text primary key,   -- hash determinístico

    -- Temporalidade
    ano_emissao                     integer not null,
    mes_emissao                     text,               -- ex: "JAN/2021"
    mes_referencia                  text,               -- ex: "OUT/2020"

    -- Classificação orçamentária
    grupo_despesa_codigo            text,
    grupo_despesa_nome              text,               -- "PESSOAL E ENCARGOS SOCIAIS" | "OUTRAS DESPESAS CORRENTES"
    natureza_despesa_codigo         text,
    natureza_despesa_nome           text,
    natureza_despesa_det_codigo     text,
    natureza_despesa_det_nome       text,

    -- Centro de custo (ex-presidente)
    centro_custo_codigo             text,
    centro_custo_nome               text,               -- ex: "EX-PR LULA DA SILVA"
    ex_presidente_slug              text,               -- ex: "lula", "fhc", "bolsonaro"

    -- Valor
    custo_valor                     numeric(14,2) not null,

    -- Metadados
    arquivo_origem                  text,
    ingested_at                     timestamptz default now()
);

create index if not exists pr_exp_slug_idx      on pr_ex_presidentes_custos (ex_presidente_slug);
create index if not exists pr_exp_ano_idx       on pr_ex_presidentes_custos (ano_emissao);
create index if not exists pr_exp_grupo_idx     on pr_ex_presidentes_custos (grupo_despesa_nome);
create index if not exists pr_exp_nat_idx       on pr_ex_presidentes_custos (natureza_despesa_nome);

comment on table pr_ex_presidentes_custos is
    'Transações SIC de custos das equipes de segurança e apoio a ex-presidentes '
    '(Lei nº 7.474/1986), 2021–2026. Fonte: dadosabertos.presidencia.gov.br.';

-- ---------------------------------------------------------------------------
-- pr_pessoal_diversidade
-- ---------------------------------------------------------------------------
create table if not exists pr_pessoal_diversidade (
    id                  text primary key,

    orgao               text not null,
    periodo             text not null,
    categoria_vinculo   text,
    dimensao            text not null,
    valor_dimensao      text not null,
    quantidade          integer not null,
    percentual          numeric(5,2),
    arquivo_origem      text,
    ingested_at         timestamptz default now()
);

create index if not exists pr_pessoal_orgao_idx     on pr_pessoal_diversidade (orgao);
create index if not exists pr_pessoal_periodo_idx   on pr_pessoal_diversidade (periodo);
create index if not exists pr_pessoal_dimensao_idx  on pr_pessoal_diversidade (dimensao);

-- ---------------------------------------------------------------------------
-- pr_ingest_log
-- ---------------------------------------------------------------------------
create table if not exists pr_ingest_log (
    id          uuid primary key default gen_random_uuid(),
    dataset     text not null,
    status      text not null default 'running',
    arquivo     text,
    n_linhas    integer,
    erro        text,
    started_at  timestamptz default now(),
    finished_at timestamptz
);

-- ---------------------------------------------------------------------------
-- Views de análise
-- ---------------------------------------------------------------------------

-- Custo anual por ex-presidente
create or replace view pr_ex_presidentes_custo_anual as
select
    ex_presidente_slug,
    centro_custo_nome                       as ex_presidente,
    ano_emissao                             as ano,
    sum(custo_valor)                        as custo_total,
    sum(case when grupo_despesa_nome ilike '%PESSOAL%' then custo_valor else 0 end) as custo_pessoal,
    sum(case when grupo_despesa_nome ilike '%OUTRAS%'  then custo_valor else 0 end) as custo_outras_despesas,
    count(*)                                as n_transacoes
from pr_ex_presidentes_custos
group by ex_presidente_slug, centro_custo_nome, ano_emissao
order by ano_emissao, custo_total desc;

comment on view pr_ex_presidentes_custo_anual is
    'Custo anual por ex-presidente: total, pessoal vs outras despesas.';

-- Custo por natureza de despesa × ex-presidente (para matérias)
create or replace view pr_ex_presidentes_por_natureza as
select
    ex_presidente_slug,
    centro_custo_nome                       as ex_presidente,
    ano_emissao                             as ano,
    natureza_despesa_nome,
    sum(custo_valor)                        as custo_total,
    count(*)                                as n_transacoes
from pr_ex_presidentes_custos
where natureza_despesa_nome is not null
group by ex_presidente_slug, centro_custo_nome, ano_emissao, natureza_despesa_nome
order by ano_emissao, ex_presidente_slug, custo_total desc;
