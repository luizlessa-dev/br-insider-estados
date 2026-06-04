-- =============================================================================
-- Motor de Tendência de Voto — STF por Ministro
-- The BR Insider — queries jornalísticas
-- =============================================================================

-- 1. RANKING DE PROVIMENTO GERAL
--    "Quem mais concede o que os requerentes pedem?"
SELECT
    ministro,
    total_decisoes,
    taxa_provimento_pct,
    pct_monocratica         AS pct_monocratica,
    decisoes_ano_corrente
FROM stf_ministros_perfil
WHERE total_decisoes > 100
ORDER BY taxa_provimento_pct DESC;


-- 2. TENDÊNCIA POR CLASSE — "Como cada ministro decide em ADIs?"
SELECT
    ministro,
    classe,
    total,
    taxa_provimento_pct,
    taxa_provimento_ultimos_2a,
    -- Drift: mudou de comportamento nos últimos 2 anos?
    ROUND(taxa_provimento_ultimos_2a - taxa_provimento_pct, 1) AS drift_pct
FROM stf_tendencia_classe
WHERE classe IN ('ADI', 'ADPF', 'HC', 'MS', 'RE', 'ARE', 'Rcl')
  AND total >= 20
ORDER BY classe, taxa_provimento_pct DESC;


-- 3. MONOCRÁTICA vs COLEGIADA por ministro
--    "Quem mais decide sozinho — e essa decisão é diferente do coletivo?"
SELECT
    ministro,
    orgao_julgador,
    total,
    taxa_provimento_pct
FROM stf_tendencia_orgao
WHERE total >= 20
ORDER BY ministro, orgao_julgador;


-- 4. ACHADO: ministros que divergem mais do Plenário quando decidem sozinhos
--    (taxa monocrática muito diferente da taxa em Plenário)
WITH mono AS (
    SELECT ministro_id, taxa_provimento_pct AS taxa_mono
    FROM stf_tendencia_orgao
    WHERE orgao_julgador = 'monocrática' AND total >= 50
),
plen AS (
    SELECT ministro_id, taxa_provimento_pct AS taxa_plen
    FROM stf_tendencia_orgao
    WHERE orgao_julgador = 'Plenário' AND total >= 20
)
SELECT
    m.ministro_id,
    mono.taxa_mono,
    plen.taxa_plen,
    ROUND(mono.taxa_mono - plen.taxa_plen, 1) AS divergencia_pct
FROM stf_ministros_perfil m
JOIN mono USING (ministro_id)
JOIN plen USING (ministro_id)
ORDER BY ABS(mono.taxa_mono - plen.taxa_plen) DESC;


-- 5. QUEM JULGA HC? — Perfil de cada ministro em habeas corpus
--    (relevante para cobrir decisões em casos criminais de políticos)
SELECT
    ministro,
    total                       AS total_hc,
    favoraveis                  AS hc_concedidos,
    taxa_provimento_pct         AS pct_concessao,
    taxa_provimento_ultimos_2a  AS pct_concessao_2a
FROM stf_tendencia_classe
WHERE classe = 'HC'
  AND total >= 10
ORDER BY pct_concessao DESC;


-- 6. CRUZAMENTO COM EMENDAS (requer Fase 2 — stf_partes preenchido)
--    "Empresas que receberam emendas e também são partes em processos no STF"
SELECT
    p.nome                          AS parte_stf,
    p.cpf_cnpj,
    COUNT(DISTINCT p.incidente)     AS processos_stf,
    SUM(e.valor_pago)               AS total_emendas_r$,
    COUNT(DISTINCT e.autor_nome)    AS parlamentares_autores
FROM stf_partes p
JOIN emendas_favorecidos e ON e.cnpj_cpf_favorecido = p.cpf_cnpj
WHERE p.cpf_cnpj IS NOT NULL
GROUP BY p.nome, p.cpf_cnpj
HAVING SUM(e.valor_pago) > 1000000  -- R$ 1M+
ORDER BY total_emendas_r$ DESC
LIMIT 50;
