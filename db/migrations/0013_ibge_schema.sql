-- Migration 0013 — IBGE: municípios + indicadores
-- Tabela de referência canônica de municípios (base de reconciliação)
-- e indicadores socioeconômicos por município/UF via SIDRA.

-- ── Municípios ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS ibge_municipios (
    codigo_ibge         TEXT PRIMARY KEY,          -- 7 dígitos (ex: 3106200)
    nome                TEXT NOT NULL,
    uf                  TEXT NOT NULL,             -- sigla (ex: MG)
    codigo_uf           INTEGER NOT NULL,          -- código numérico da UF
    nome_uf             TEXT NOT NULL,
    nome_regiao         TEXT NOT NULL,             -- Norte/Nordeste/etc.
    nome_mesorregiao    TEXT,
    nome_microrregiao   TEXT,
    nome_regiao_imediata    TEXT,
    nome_regiao_intermediaria TEXT,
    latitude            NUMERIC(10,6),
    longitude           NUMERIC(10,6),
    atualizado_em       TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ibge_municipios_uf ON ibge_municipios(uf);
CREATE INDEX IF NOT EXISTS ibge_municipios_nome ON ibge_municipios(nome);

-- ── Indicadores por município (SIDRA) ──────────────────────────────────
-- Tabela genérica: uma linha por (município × pesquisa × variável × ano).
-- Permite adicionar novos indicadores sem nova migration.
CREATE TABLE IF NOT EXISTS ibge_indicadores (
    id                  BIGSERIAL PRIMARY KEY,
    codigo_ibge         TEXT NOT NULL REFERENCES ibge_municipios(codigo_ibge),
    pesquisa_id         TEXT NOT NULL,   -- ex: "pib-municipios", "censo-2022"
    variavel_id         TEXT NOT NULL,   -- ex: "pib_percapita", "populacao"
    variavel_nome       TEXT NOT NULL,
    ano                 INTEGER NOT NULL,
    valor               NUMERIC,
    unidade             TEXT,            -- ex: "R$ mil", "habitantes"
    atualizado_em       TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE (codigo_ibge, pesquisa_id, variavel_id, ano)
);

CREATE INDEX IF NOT EXISTS ibge_indicadores_municipio ON ibge_indicadores(codigo_ibge);
CREATE INDEX IF NOT EXISTS ibge_indicadores_pesquisa ON ibge_indicadores(pesquisa_id, variavel_id, ano);

-- ── View de enriquecimento para emendas ────────────────────────────────
-- Junta município canônico + PIB per capita mais recente para uso em queries
-- de favorecidos por emendas.
CREATE OR REPLACE VIEW ibge_municipios_enriquecidos AS
SELECT
    m.codigo_ibge,
    m.nome,
    m.uf,
    m.nome_uf,
    m.nome_regiao,
    m.nome_mesorregiao,
    pib.valor   AS pib_total_mil_reais,
    pib.ano     AS pib_ano,
    CASE WHEN pop.valor > 0 THEN ROUND((pib.valor * 1000.0 / pop.valor)::numeric, 2) END AS pib_percapita_calculado,
    pop.valor   AS populacao,
    pop.ano     AS populacao_ano
FROM ibge_municipios m
LEFT JOIN ibge_indicadores pib
    ON pib.codigo_ibge = m.codigo_ibge
    AND pib.pesquisa_id = 'pib-municipios'
    AND pib.variavel_id = 'pib_total_mil_reais'
    AND pib.ano = (
        SELECT MAX(ano) FROM ibge_indicadores
        WHERE codigo_ibge = m.codigo_ibge
          AND pesquisa_id = 'pib-municipios'
          AND variavel_id = 'pib_total_mil_reais'
    )
LEFT JOIN ibge_indicadores pop
    ON pop.codigo_ibge = m.codigo_ibge
    AND pop.pesquisa_id = 'censo-2022'
    AND pop.variavel_id = 'populacao'
    AND pop.ano = 2022;
