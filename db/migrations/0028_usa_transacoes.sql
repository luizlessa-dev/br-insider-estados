-- Transações individuais (aditivos/modificações) de contratos USASpending
-- Cada linha = uma ação sobre um contrato (new award, continuation, revision, etc.)

CREATE TABLE IF NOT EXISTS usa_transacoes (
    transacao_id            TEXT PRIMARY KEY,
    award_id                TEXT NOT NULL,  -- ID canônico do contrato-mãe (generated_internal_id)
    tipo_acao               TEXT,           -- NEW | CONTINUATION | REVISION | FUNDING ONLY | etc.
    data_acao               DATE,
    valor_federal_usd       NUMERIC(18,2),
    valor_nao_federal_usd   NUMERIC(18,2),
    descricao               TEXT,
    agencia_nome            TEXT,
    beneficiario_nome       TEXT,
    lugar_execucao_pais     TEXT,
    lugar_execucao_estado   TEXT,
    ingested_at             TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_usa_transacoes_award_id   ON usa_transacoes(award_id);
CREATE INDEX IF NOT EXISTS idx_usa_transacoes_data_acao  ON usa_transacoes(data_acao);
CREATE INDEX IF NOT EXISTS idx_usa_transacoes_tipo       ON usa_transacoes(tipo_acao);

COMMENT ON TABLE usa_transacoes IS
  'Modificações e aditivos individuais de contratos USASpending. '
  'Permite rastrear pagamentos pós-evento (ex: pós-invasão Ucrânia 2022).';
