-- =============================================================================
-- 0011_stf_schema.sql
-- Supremo Tribunal Federal — The BR Insider
-- Fase 1: CSVs do Corte Aberta + enriquecimento via endpoints ASP
-- Fase 2 (futura): motor de tendência de voto por ministro
-- =============================================================================

-- ---------------------------------------------------------------------------
-- stf_processos
-- Base: CSV de Acervo + CSV de Controle Concentrado do Corte Aberta
-- Enriquecível via abaInformacoes.asp?incidente=X
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS stf_processos (
    id                  SERIAL PRIMARY KEY,
    incidente           INTEGER UNIQUE,          -- ID interno STF (chave dos endpoints ASP)
    numero_processo     TEXT,                    -- ex: "ADI 7236"
    classe              TEXT,                    -- "ADI", "ADPF", "RE", "HC", "MS", etc.
    numero              INTEGER,
    ano_autuacao        INTEGER,
    data_autuacao       DATE,
    ministro_relator    TEXT,
    ministro_relator_id TEXT,                    -- slug normalizado ex: "alexandre-de-moraes"
    situacao            TEXT,                    -- "em tramitação", "baixado", etc.
    origem              TEXT,                    -- UF ou tribunal de origem
    assunto_principal   TEXT,
    -- Campos específicos de Controle Concentrado (ADI/ADC/ADPF/ADO)
    requerente          TEXT,
    requerido           TEXT,
    resultado_final     TEXT,                    -- "procedente", "improcedente", "prejudicado"
    data_julgamento     DATE,
    -- Metadados de ingestão
    fonte_csv           TEXT,                    -- "acervo", "controle_concentrado", "decisoes"
    ingested_at         TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_stf_processos_classe     ON stf_processos (classe);
CREATE INDEX IF NOT EXISTS idx_stf_processos_relator    ON stf_processos (ministro_relator_id);
CREATE INDEX IF NOT EXISTS idx_stf_processos_ano        ON stf_processos (ano_autuacao);
CREATE INDEX IF NOT EXISTS idx_stf_processos_resultado  ON stf_processos (resultado_final);

-- ---------------------------------------------------------------------------
-- stf_decisoes
-- Base: CSVs de Decisões 2000–2026 do Corte Aberta (por quinquênio)
-- Granularidade: 1 linha = 1 decisão de 1 ministro
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS stf_decisoes (
    id                  SERIAL PRIMARY KEY,
    incidente           INTEGER,
    numero_processo     TEXT,
    classe              TEXT,
    numero              INTEGER,
    ano_autuacao        INTEGER,
    data_decisao        DATE,
    tipo_decisao        TEXT,   -- "monocrática", "colegiada", "acórdão", "despacho"
    nome_decisao        TEXT,   -- "Agravo não provido", "Procedente", "Negado seguimento", etc.
    ministro            TEXT,   -- quem proferiu a decisão
    ministro_id         TEXT,   -- slug normalizado
    orgao_julgador      TEXT,   -- "Plenário", "1ª Turma", "2ª Turma", "Presidência"
    resultado           TEXT,   -- classificação normalizada (ver função abaixo)
    -- Campos adicionais disponíveis nos CSVs mais recentes
    assunto             TEXT,
    requerente          TEXT,
    -- Metadados
    fonte_csv           TEXT,   -- "decisoes_2000_2004", ..., "decisoes_2026"
    ingested_at         TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_stf_decisoes_incidente   ON stf_decisoes (incidente);
CREATE INDEX IF NOT EXISTS idx_stf_decisoes_ministro    ON stf_decisoes (ministro_id);
CREATE INDEX IF NOT EXISTS idx_stf_decisoes_classe      ON stf_decisoes (classe);
CREATE INDEX IF NOT EXISTS idx_stf_decisoes_data        ON stf_decisoes (data_decisao);
CREATE INDEX IF NOT EXISTS idx_stf_decisoes_resultado   ON stf_decisoes (resultado);
CREATE INDEX IF NOT EXISTS idx_stf_decisoes_orgao       ON stf_decisoes (orgao_julgador);

-- Evita duplicatas em re-ingestão
CREATE UNIQUE INDEX IF NOT EXISTS idx_stf_decisoes_uniq
    ON stf_decisoes (incidente, data_decisao, ministro_id, nome_decisao)
    WHERE incidente IS NOT NULL;

-- ---------------------------------------------------------------------------
-- stf_partes
-- Enriquecimento via abaPartes.asp?incidente=X (HTML scraping)
-- Permite cruzar CNPJs de partes com emendas_favorecidos
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS stf_partes (
    id                  SERIAL PRIMARY KEY,
    incidente           INTEGER NOT NULL,
    polo                TEXT,   -- "REQUERENTE", "REQUERIDO", "AMI. CURIAE", "ADV.", etc.
    nome                TEXT,
    cpf_cnpj            TEXT,   -- preenchido quando identificável
    ingested_at         TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (incidente, polo, nome)
);

CREATE INDEX IF NOT EXISTS idx_stf_partes_incidente ON stf_partes (incidente);
CREATE INDEX IF NOT EXISTS idx_stf_partes_cnpj      ON stf_partes (cpf_cnpj) WHERE cpf_cnpj IS NOT NULL;

-- ---------------------------------------------------------------------------
-- stf_ingestao_log
-- Controle de quais CSVs já foram processados
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS stf_ingestao_log (
    id           SERIAL PRIMARY KEY,
    dataset      TEXT NOT NULL,  -- ex: "decisoes_2020_2024", "acervo", "controle_concentrado"
    linhas_raw   INTEGER,
    linhas_ok    INTEGER,
    linhas_erro  INTEGER,
    arquivo_hash TEXT,           -- SHA256 do CSV para detectar atualizações
    ingested_at  TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (dataset, arquivo_hash)
);

-- =============================================================================
-- VIEWS: Motor de Tendência de Voto por Ministro (Fase 2)
-- Calculáveis já com os dados da Fase 1
-- =============================================================================

-- ---------------------------------------------------------------------------
-- stf_ministros_perfil
-- 1 linha por ministro — estatísticas gerais de decisão
-- ---------------------------------------------------------------------------
CREATE MATERIALIZED VIEW IF NOT EXISTS stf_ministros_perfil AS
SELECT
    ministro_id,
    ministro,
    COUNT(*)                                                    AS total_decisoes,
    COUNT(*) FILTER (WHERE data_decisao >= DATE_TRUNC('year', NOW()))
                                                                AS decisoes_ano_corrente,
    COUNT(*) FILTER (WHERE tipo_decisao = 'monocrática')        AS monocraticas,
    COUNT(*) FILTER (WHERE tipo_decisao IN ('colegiada','acórdão'))
                                                                AS colegiadas,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE tipo_decisao = 'monocrática')
        / NULLIF(COUNT(*), 0), 1
    )                                                           AS pct_monocratica,
    -- Resultado: favorável = "procedente" + "provido" | contrário = "improcedente" + "negado"
    COUNT(*) FILTER (WHERE resultado = 'favoravel')             AS favoraveis,
    COUNT(*) FILTER (WHERE resultado = 'contrario')             AS contrarios,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE resultado = 'favoravel')
        / NULLIF(COUNT(*) FILTER (WHERE resultado IN ('favoravel','contrario')), 0), 1
    )                                                           AS taxa_provimento_pct,
    MIN(data_decisao)                                           AS primeira_decisao,
    MAX(data_decisao)                                           AS ultima_decisao
FROM stf_decisoes
WHERE ministro_id IS NOT NULL
GROUP BY ministro_id, ministro
WITH DATA;

CREATE UNIQUE INDEX IF NOT EXISTS idx_stf_ministros_perfil_pk
    ON stf_ministros_perfil (ministro_id);

-- ---------------------------------------------------------------------------
-- stf_tendencia_classe
-- Taxa de provimento por ministro × classe processual
-- Núcleo do "motor de tendência"
-- ---------------------------------------------------------------------------
CREATE MATERIALIZED VIEW IF NOT EXISTS stf_tendencia_classe AS
SELECT
    ministro_id,
    ministro,
    classe,
    COUNT(*)                                                    AS total,
    COUNT(*) FILTER (WHERE resultado = 'favoravel')             AS favoraveis,
    COUNT(*) FILTER (WHERE resultado = 'contrario')             AS contrarios,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE resultado = 'favoravel')
        / NULLIF(COUNT(*) FILTER (WHERE resultado IN ('favoravel','contrario')), 0), 1
    )                                                           AS taxa_provimento_pct,
    -- Tendência temporal: últimos 2 anos vs período anterior
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE resultado = 'favoravel'
            AND data_decisao >= NOW() - INTERVAL '2 years'
        ) / NULLIF(
            COUNT(*) FILTER (
                WHERE resultado IN ('favoravel','contrario')
                AND data_decisao >= NOW() - INTERVAL '2 years'
            ), 0
        ), 1
    )                                                           AS taxa_provimento_ultimos_2a,
    COUNT(*) FILTER (WHERE tipo_decisao = 'monocrática')        AS monocraticas,
    COUNT(*) FILTER (WHERE tipo_decisao IN ('colegiada','acórdão'))
                                                                AS colegiadas
FROM stf_decisoes
WHERE ministro_id IS NOT NULL
  AND classe IS NOT NULL
GROUP BY ministro_id, ministro, classe
WITH DATA;

CREATE INDEX IF NOT EXISTS idx_stf_tendencia_classe_min
    ON stf_tendencia_classe (ministro_id);
CREATE INDEX IF NOT EXISTS idx_stf_tendencia_classe_cls
    ON stf_tendencia_classe (classe);

-- ---------------------------------------------------------------------------
-- stf_tendencia_orgao
-- Como cada ministro vota diferente quando está no Plenário vs Turma vs monocrática
-- ---------------------------------------------------------------------------
CREATE MATERIALIZED VIEW IF NOT EXISTS stf_tendencia_orgao AS
SELECT
    ministro_id,
    ministro,
    orgao_julgador,
    COUNT(*)                                                    AS total,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE resultado = 'favoravel')
        / NULLIF(COUNT(*) FILTER (WHERE resultado IN ('favoravel','contrario')), 0), 1
    )                                                           AS taxa_provimento_pct
FROM stf_decisoes
WHERE ministro_id IS NOT NULL
  AND orgao_julgador IS NOT NULL
GROUP BY ministro_id, ministro, orgao_julgador
WITH DATA;

-- ---------------------------------------------------------------------------
-- Função de refresh das matviews (chamar após cada ingestão)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION stf_refresh_matviews()
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY stf_ministros_perfil;
    REFRESH MATERIALIZED VIEW CONCURRENTLY stf_tendencia_classe;
    REFRESH MATERIALIZED VIEW CONCURRENTLY stf_tendencia_orgao;
END;
$$;

COMMENT ON TABLE  stf_processos           IS 'Acervo STF — fonte: CSVs Corte Aberta + ASP scraping';
COMMENT ON TABLE  stf_decisoes            IS 'Decisões STF 2000-2026 — fonte: CSVs Corte Aberta por quinquênio';
COMMENT ON TABLE  stf_partes              IS 'Partes por processo — fonte: abaPartes.asp (Fase 2)';
COMMENT ON MATERIALIZED VIEW stf_ministros_perfil   IS 'Perfil estatístico por ministro — refresh após ingestão';
COMMENT ON MATERIALIZED VIEW stf_tendencia_classe   IS 'Taxa de provimento ministro×classe — núcleo do motor de tendência';
COMMENT ON MATERIALIZED VIEW stf_tendencia_orgao    IS 'Perfil por órgão julgador (Plenário/Turma/Monocrática)';
