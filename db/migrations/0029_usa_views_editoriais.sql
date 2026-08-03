-- Views editoriais para análise de contratos de longa duração (USASpending)
-- Uso: pauta "contratos que sobrevivem a qualquer crise"

-- 1. Ritmo anual de pagamentos por contrato
CREATE OR REPLACE VIEW usa_v_ritmo_anual AS
SELECT
    award_id,
    EXTRACT(YEAR FROM data_acao)::INT          AS ano,
    COUNT(*)                                   AS total_transacoes,
    SUM(valor_federal_usd)                     AS valor_total_usd,
    ROUND(AVG(valor_federal_usd)::NUMERIC, 2)  AS valor_medio_usd,
    MIN(data_acao)                             AS primeira_transacao,
    MAX(data_acao)                             AS ultima_transacao
FROM usa_transacoes
WHERE data_acao IS NOT NULL
GROUP BY award_id, EXTRACT(YEAR FROM data_acao)
ORDER BY award_id, ano;

-- 2. Painel comparativo — resumo de cada contrato com métricas editoriais
CREATE OR REPLACE VIEW usa_v_painel_contratos AS
SELECT
    c.award_id,
    c.beneficiario_nome,
    c.agencia_nome,
    c.descricao,
    c.valor_obrigado_usd,
    c.data_inicio,
    c.data_fim,
    -- histórico de transações
    COUNT(t.transacao_id)                                               AS total_transacoes,
    MIN(t.data_acao)                                                    AS primeira_transacao,
    MAX(t.data_acao)                                                    AS ultima_transacao,
    SUM(t.valor_federal_usd)                                            AS total_pago_usd,
    ROUND(AVG(t.valor_federal_usd)::NUMERIC, 2)                         AS ticket_medio_usd,
    -- atividade recente (últimos 12 meses)
    COUNT(t.transacao_id) FILTER (
        WHERE t.data_acao >= CURRENT_DATE - INTERVAL '12 months'
    )                                                                   AS transacoes_ultimos_12m,
    SUM(t.valor_federal_usd) FILTER (
        WHERE t.data_acao >= CURRENT_DATE - INTERVAL '12 months'
    )                                                                   AS valor_ultimos_12m_usd,
    -- longevidade
    EXTRACT(YEAR FROM AGE(MAX(t.data_acao), MIN(t.data_acao)))::INT     AS anos_ativo,
    -- permalink
    c.permalink
FROM usa_contratos c
LEFT JOIN usa_transacoes t ON t.award_id = c.award_id
GROUP BY c.award_id, c.beneficiario_nome, c.agencia_nome, c.descricao,
         c.valor_obrigado_usd, c.data_inicio, c.data_fim, c.permalink
ORDER BY total_pago_usd DESC NULLS LAST;

-- 3. Detecção de acelerações — anos com volume acima da média histórica do contrato
CREATE OR REPLACE VIEW usa_v_anomalias_ritmo AS
WITH media_por_contrato AS (
    SELECT
        award_id,
        AVG(valor_total_usd)   AS media_anual_usd,
        STDDEV(valor_total_usd) AS desvio_padrao_usd
    FROM usa_v_ritmo_anual
    GROUP BY award_id
)
SELECT
    r.award_id,
    r.ano,
    r.total_transacoes,
    r.valor_total_usd,
    m.media_anual_usd,
    ROUND(
        ((r.valor_total_usd - m.media_anual_usd) / NULLIF(m.desvio_padrao_usd, 0))::NUMERIC,
        2
    )                          AS z_score,  -- >2 = anomalia positiva, <-2 = anomalia negativa
    CASE
        WHEN r.valor_total_usd > m.media_anual_usd * 1.5 THEN 'ACELERAÇÃO'
        WHEN r.valor_total_usd < m.media_anual_usd * 0.5 THEN 'REDUÇÃO'
        ELSE 'NORMAL'
    END                        AS classificacao
FROM usa_v_ritmo_anual r
JOIN media_por_contrato m USING (award_id)
WHERE r.ano >= 2000  -- foco na era moderna
ORDER BY ABS(r.valor_total_usd - m.media_anual_usd) DESC;

COMMENT ON VIEW usa_v_ritmo_anual IS
  'Pagamentos anuais por contrato. Permite detectar acelerações ou pausas ao longo do tempo.';
COMMENT ON VIEW usa_v_painel_contratos IS
  'Painel comparativo de contratos de longa duração: longevidade, atividade recente e ticket médio.';
COMMENT ON VIEW usa_v_anomalias_ritmo IS
  'Anos com volume de pagamento acima ou abaixo da média histórica do contrato (z-score + classificação).';
