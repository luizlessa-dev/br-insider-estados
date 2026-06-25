-- =============================================================================
-- ANÁLISE: Gastos com ads digitais (Meta/Google) por candidatos — TSE 2024
-- Briefing: editorial/briefing_ads_digitais_tse.md
--
-- Contexto: o sentinela -4 do TSE (CPF não divulgável) era armazenado como '4'
-- por re.sub antes do fix de 2026-06-21. O script fix-tse-despesas-cpf-sentinela.py
-- converteu essas ~4M linhas de cpf='4' → NULL em tse_despesas.
--
-- Pergunta central: após o fix, o que é atribuível a candidatos identificados
-- em 2024? E o nome_candidato está preenchido mesmo para os cpf NULL?
-- =============================================================================

-- CNPJs das plataformas de anúncios
-- Meta (Facebook/Instagram): 13347016000117
-- Google Brasil:              06990590000123

-- -----------------------------------------------------------------------------
-- 1. DIAGNÓSTICO GERAL: split atribuído × não-atribuído (Meta, 2024)
-- -----------------------------------------------------------------------------
SELECT
  CASE
    WHEN cpf_candidato IS NULL     THEN 'cpf_null (ex-sentinela ou omitido)'
    WHEN nome_candidato IS NOT NULL THEN 'cpf_identificado'
    ELSE 'cpf_identificado_sem_nome'
  END                                               AS status_cpf,
  COUNT(*)                                          AS n_transacoes,
  COUNT(DISTINCT COALESCE(cpf_candidato, nome_candidato)) AS candidatos_unicos,
  SUM(valor_despesa)                                AS total_brl,
  ROUND(SUM(valor_despesa) * 100.0 /
    SUM(SUM(valor_despesa)) OVER (), 1)             AS pct_total
FROM tse_despesas
WHERE ano_eleicao            = 2024
  AND cpf_cnpj_fornecedor    = '13347016000117'
GROUP BY 1
ORDER BY total_brl DESC;

-- -----------------------------------------------------------------------------
-- 2. NOME_CANDIDATO preenchido nos rows onde cpf é NULL?
--    (chave para saber se podemos atribuir por nome mesmo sem CPF)
-- -----------------------------------------------------------------------------
SELECT
  CASE
    WHEN nome_candidato IS NOT NULL AND nome_candidato <> '' THEN 'nome_preenchido'
    ELSE 'sem_nome'
  END                        AS status_nome,
  COUNT(*)                   AS n_transacoes,
  SUM(valor_despesa)         AS total_brl
FROM tse_despesas
WHERE ano_eleicao         = 2024
  AND cpf_cnpj_fornecedor = '13347016000117'
  AND cpf_candidato IS NULL
GROUP BY 1;

-- -----------------------------------------------------------------------------
-- 3. TOP 30 CANDIDATOS por gasto no Meta (2024)
--    — usando cpf_candidato quando disponível, fallback nome_candidato
-- -----------------------------------------------------------------------------
SELECT
  COALESCE(cpf_candidato, '(sem CPF)')             AS cpf,
  nome_candidato,
  cargo,
  sigla_partido,
  uf,
  COUNT(*)                                          AS n_transacoes,
  SUM(valor_despesa)                                AS total_meta_brl
FROM tse_despesas
WHERE ano_eleicao         = 2024
  AND cpf_cnpj_fornecedor = '13347016000117'
  AND nome_candidato IS NOT NULL
  AND nome_candidato <> ''
GROUP BY 1, 2, 3, 4, 5
ORDER BY total_meta_brl DESC
LIMIT 30;

-- -----------------------------------------------------------------------------
-- 4. POR CARGO — Meta 2024 (candidatos com nome preenchido)
-- -----------------------------------------------------------------------------
SELECT
  cargo,
  COUNT(DISTINCT COALESCE(cpf_candidato, nome_candidato)) AS candidatos,
  SUM(valor_despesa)                                       AS total_brl,
  ROUND(AVG(valor_despesa), 0)                             AS media_transacao
FROM tse_despesas
WHERE ano_eleicao         = 2024
  AND cpf_cnpj_fornecedor = '13347016000117'
  AND nome_candidato IS NOT NULL
GROUP BY cargo
ORDER BY total_brl DESC;

-- -----------------------------------------------------------------------------
-- 5. POR PARTIDO — Meta 2024 (top 15)
-- -----------------------------------------------------------------------------
SELECT
  sigla_partido,
  COUNT(DISTINCT COALESCE(cpf_candidato, nome_candidato)) AS candidatos,
  SUM(valor_despesa)                                       AS total_brl
FROM tse_despesas
WHERE ano_eleicao         = 2024
  AND cpf_cnpj_fornecedor = '13347016000117'
  AND nome_candidato IS NOT NULL
GROUP BY sigla_partido
ORDER BY total_brl DESC
LIMIT 15;

-- -----------------------------------------------------------------------------
-- 6. COMPARAÇÃO META × GOOGLE (2024, todos os status de cpf)
-- -----------------------------------------------------------------------------
SELECT
  nome_fornecedor,
  cpf_cnpj_fornecedor,
  COUNT(*)                                                  AS n_transacoes,
  COUNT(DISTINCT COALESCE(cpf_candidato, nome_candidato))   AS candidatos,
  SUM(valor_despesa)                                        AS total_brl,
  SUM(valor_despesa) FILTER (WHERE cpf_candidato IS NOT NULL) AS atribuido_brl,
  SUM(valor_despesa) FILTER (WHERE cpf_candidato IS NULL)     AS nao_atribuido_brl
FROM tse_despesas
WHERE ano_eleicao = 2024
  AND cpf_cnpj_fornecedor IN ('13347016000117', '06990590000123')
GROUP BY nome_fornecedor, cpf_cnpj_fornecedor
ORDER BY total_brl DESC;

-- -----------------------------------------------------------------------------
-- 7. SÉRIE HISTÓRICA — Meta por ciclo (confirma crescimento 2018→2024)
-- -----------------------------------------------------------------------------
SELECT
  ano_eleicao,
  COUNT(DISTINCT COALESCE(cpf_candidato, nome_candidato)) AS candidatos,
  SUM(valor_despesa)                                       AS total_meta_brl
FROM tse_despesas
WHERE cpf_cnpj_fornecedor = '13347016000117'
GROUP BY ano_eleicao
ORDER BY ano_eleicao;
