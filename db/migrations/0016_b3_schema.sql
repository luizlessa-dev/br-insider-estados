-- Migration 0016: B3 — Empresas Listadas
-- Fonte: sistemaswebb3-listados.b3.com.br (API pública, sem autenticação)
-- ~3.400 companhias abertas com CNPJ, segmento e status de listagem.
-- Principal uso: enriquecer emendas_favorecidos com flag de companhia aberta.

CREATE TABLE IF NOT EXISTS b3_empresas_listadas (
    codigo_cvm          TEXT PRIMARY KEY,         -- codeCVM (identificador B3/CVM)
    cnpj                TEXT,                     -- CNPJ sem formatação ("0" = sem CNPJ)
    ticker              TEXT,                     -- issuingCompany (ex: PETR)
    nome_empresa        TEXT NOT NULL,
    nome_negociacao     TEXT,                     -- tradingName
    segmento            TEXT,                     -- ex: "Novo Mercado", "Básico"
    segmento_en         TEXT,
    tipo_valor          TEXT,                     -- type (1=ação, 7=companhia fechada, etc.)
    tipo_bdr            TEXT,
    mercado             TEXT,                     -- NM, N1, N2, MB, DR3, DRE…
    market_indicator    TEXT,
    data_listagem       DATE,
    status              TEXT,                     -- "A" = ativo, "I" = inativo
    atualizado_em       TIMESTAMPTZ DEFAULT NOW()
);

-- Índice para o cruzamento principal: CNPJ × emendas_favorecidos
CREATE INDEX IF NOT EXISTS idx_b3_cnpj
    ON b3_empresas_listadas (cnpj)
    WHERE cnpj IS NOT NULL AND cnpj != '0';

-- View de cruzamento: favorecidos de emendas que são companhias abertas
CREATE OR REPLACE VIEW vw_emendas_companhias_abertas AS
SELECT
    ef.codigo_favorecido,
    ef.favorecido,
    ef.uf_favorecido,
    ef.municipio_favorecido,
    COUNT(*)                AS num_transacoes,
    SUM(ef.valor_recebido)  AS total_recebido,
    b3.nome_empresa,
    b3.ticker,
    b3.segmento,
    b3.mercado,
    b3.data_listagem
FROM emendas_favorecidos ef
JOIN b3_empresas_listadas b3
    ON ef.codigo_favorecido = b3.cnpj
WHERE b3.cnpj IS NOT NULL
  AND ef.codigo_favorecido IS NOT NULL
GROUP BY
    ef.codigo_favorecido, ef.favorecido, ef.uf_favorecido, ef.municipio_favorecido,
    b3.nome_empresa, b3.ticker, b3.segmento, b3.mercado, b3.data_listagem
ORDER BY total_recebido DESC;
