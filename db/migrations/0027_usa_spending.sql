-- USASpending.gov: contratos e grants federais americanos
-- Schema usa_* isolado (não colide com tabelas BR)
-- Fonte: api.usaspending.gov — público, sem autenticação

-- Agências federais (seed via usa_spending_runner --modo agencias)
CREATE TABLE IF NOT EXISTS usa_agencias (
    codigo          TEXT PRIMARY KEY,  -- toptier_code ex: "097" = DoD
    nome            TEXT NOT NULL,
    abreviacao      TEXT,
    ativo           BOOLEAN DEFAULT TRUE,
    total_obrigacoes_usd NUMERIC(18,2),
    atualizado_em   TIMESTAMPTZ DEFAULT NOW()
);

-- Contratos e grants
CREATE TABLE IF NOT EXISTS usa_contratos (
    award_id                TEXT PRIMARY KEY,  -- ID canônico USASpending
    tipo                    TEXT NOT NULL,     -- contract | grant | loan | direct_payment | other
    agencia_codigo          TEXT REFERENCES usa_agencias(codigo) ON DELETE SET NULL,
    agencia_nome            TEXT,
    subagencia_nome         TEXT,
    beneficiario_nome       TEXT,
    beneficiario_uei        TEXT,  -- Unique Entity Identifier (substituiu DUNS em 2022)
    beneficiario_estado     TEXT,
    valor_obrigado_usd      NUMERIC(18,2),
    valor_potencial_usd     NUMERIC(18,2),
    data_inicio             DATE,
    data_fim                DATE,
    data_assinatura         DATE,
    descricao               TEXT,
    naics_code              TEXT,
    naics_descricao         TEXT,
    lugar_execucao_estado   TEXT,
    lugar_execucao_pais     TEXT,
    permalink               TEXT,
    ingested_at             TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_usa_contratos_tipo          ON usa_contratos(tipo);
CREATE INDEX IF NOT EXISTS idx_usa_contratos_agencia       ON usa_contratos(agencia_codigo);
CREATE INDEX IF NOT EXISTS idx_usa_contratos_data_inicio   ON usa_contratos(data_inicio);
CREATE INDEX IF NOT EXISTS idx_usa_contratos_valor         ON usa_contratos(valor_obrigado_usd DESC);
CREATE INDEX IF NOT EXISTS idx_usa_contratos_beneficiario  ON usa_contratos(beneficiario_nome);
CREATE INDEX IF NOT EXISTS idx_usa_contratos_naics         ON usa_contratos(naics_code);

-- View de comparação de transparência (editorial)
-- Mostra tempo médio entre assinatura e publicação (USASpending publica em ~48h)
-- No Brasil esse dado é o prazo do Portal da Transparência (referência manual)
CREATE OR REPLACE VIEW usa_v_metricas_transparencia AS
SELECT
    tipo,
    COUNT(*)                                                    AS total_contratos,
    ROUND(AVG(valor_obrigado_usd)::NUMERIC, 2)                  AS valor_medio_usd,
    SUM(valor_obrigado_usd)                                     AS valor_total_usd,
    AVG(data_fim - data_inicio)                                 AS duracao_media_dias,
    -- Dias entre assinatura e publicação (proxy de transparência)
    AVG(ingested_at::DATE - data_assinatura)                    AS lag_publicacao_dias_aprox,
    MIN(data_inicio)                                            AS periodo_inicio,
    MAX(data_fim)                                               AS periodo_fim
FROM usa_contratos
WHERE data_assinatura IS NOT NULL
GROUP BY tipo
ORDER BY valor_total_usd DESC NULLS LAST;

-- View para pauta: maiores beneficiários
CREATE OR REPLACE VIEW usa_v_top_beneficiarios AS
SELECT
    beneficiario_nome,
    beneficiario_uei,
    COUNT(*)                        AS total_contratos,
    SUM(valor_obrigado_usd)         AS valor_total_usd,
    array_agg(DISTINCT tipo)        AS tipos,
    array_agg(DISTINCT agencia_nome ORDER BY agencia_nome) AS agencias
FROM usa_contratos
WHERE beneficiario_nome IS NOT NULL
GROUP BY beneficiario_nome, beneficiario_uei
ORDER BY valor_total_usd DESC NULLS LAST
LIMIT 1000;

COMMENT ON TABLE usa_contratos IS
  'Contratos e grants federais dos EUA via USASpending.gov. '
  'Uso editorial: comparar opacidade/detalhe com contratos federais BR.';
