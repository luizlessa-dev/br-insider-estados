-- ═══════════════════════════════════════════════════════════════════════════════
-- QUERIES INVESTIGATIVAS: Cota Parlamentar × Emendas
-- The Brasilia Insider
--
-- PRÉ-REQUISITO: migration 0021_cota_cnpj_norm.sql aplicada
-- (adiciona coluna cnpj_norm com apenas dígitos em cota_despesa)
-- ═══════════════════════════════════════════════════════════════════════════════


-- ── Q1: MESMO CNPJ NOS DOIS FLUXOS ──────────────────────────────────────────
-- Empresas que receberam dinheiro tanto via Cota Parlamentar (uso pessoal
-- do deputado) quanto via Emendas (verba pública). Alta densidade de pauta.

SELECT
  c.cnpj_norm                                           AS cnpj,
  c.nome_fornecedor                                     AS nome,
  ROUND(SUM(c.valor_liquido)::numeric, 2)              AS total_cota_brl,
  COUNT(DISTINCT c.id_deputado)                        AS n_deputados_cota,
  ROUND(SUM(ef.valor_recebido)::numeric, 2)            AS total_emenda_brl,
  COUNT(DISTINCT ef.codigo_autor)                      AS n_autores_emenda,
  ROUND((SUM(c.valor_liquido) + SUM(ef.valor_recebido))::numeric, 2) AS total_combinado_brl
FROM public.cota_despesa c
JOIN public.emendas_favorecidos ef
  ON ef.codigo_favorecido = c.cnpj_norm
WHERE c.cnpj_norm IS NOT NULL AND c.cnpj_norm <> ''
GROUP BY c.cnpj_norm, c.nome_fornecedor
ORDER BY total_combinado_brl DESC
LIMIT 50;


-- ── Q2: DEPUTADO USA COTA NO MESMO CNPJ QUE ELE EMENDOU ────────────────────
-- O padrão mais suspeito: o autor da emenda também gastou a própria cota
-- no mesmo fornecedor. Sugere relacionamento privilegiado ou conflito de interesse.

SELECT
  p.nome                                               AS parlamentar,
  p.partido,
  p.uf,
  c.cnpj_norm                                         AS cnpj,
  c.nome_fornecedor                                   AS fornecedor,
  ROUND(SUM(c.valor_liquido)::numeric, 2)             AS total_cota_brl,
  ROUND(SUM(ef.valor_recebido)::numeric, 2)           AS total_emenda_brl,
  COUNT(DISTINCT ef.codigo_emenda)                    AS n_emendas,
  MIN(c.data_emissao)                                 AS primeira_nota_cota,
  MAX(ef.ano_emenda)                                  AS ultimo_ano_emenda
FROM public.cota_despesa c
JOIN public.emendas_favorecidos ef
  ON ef.codigo_favorecido = c.cnpj_norm
JOIN public.cota_deputado cd
  ON cd.id_camara = c.id_deputado
JOIN public.parlamentares p
  ON p.nome = cd.nome   -- join por nome (fallback sem CPF cruzado)
  AND p.partido = cd.partido
  AND p.uf = cd.uf
WHERE c.cnpj_norm IS NOT NULL
  AND ef.codigo_autor = p.autor_orcamentario_id -- mesmo autor
GROUP BY p.nome, p.partido, p.uf, c.cnpj_norm, c.nome_fornecedor
ORDER BY (SUM(c.valor_liquido) + SUM(ef.valor_recebido)) DESC
LIMIT 30;


-- ── Q3: EMPRESAS COM MAIOR DIVERSIDADE DE DEPUTADOS NA COTA ─────────────────
-- Fornecedores com muitos deputados diferentes como clientes na cota.
-- Suspeita: empresa de lobby ou intermediação disfarçada de serviço.

SELECT
  c.cnpj_norm                                         AS cnpj,
  MAX(c.nome_fornecedor)                              AS nome,
  COUNT(DISTINCT c.id_deputado)                       AS n_deputados,
  COUNT(*)                                            AS n_notas,
  ROUND(SUM(c.valor_liquido)::numeric, 2)             AS total_brl,
  ROUND(AVG(c.valor_liquido)::numeric, 2)             AS ticket_medio,
  MAX(c.tipo_despesa)                                 AS categoria_principal,
  -- Aparece também em emendas?
  COUNT(DISTINCT ef.codigo_emenda)                    AS n_emendas_recebidas,
  ROUND(COALESCE(SUM(ef.valor_recebido), 0)::numeric, 2) AS total_emendas_brl
FROM public.cota_despesa c
LEFT JOIN public.emendas_favorecidos ef
  ON ef.codigo_favorecido = c.cnpj_norm
WHERE c.cnpj_norm IS NOT NULL AND length(c.cnpj_norm) = 14
GROUP BY c.cnpj_norm
HAVING COUNT(DISTINCT c.id_deputado) >= 10
ORDER BY n_deputados DESC, total_brl DESC
LIMIT 40;


-- ── Q4: CONCENTRAÇÃO — DEPUTADO COM GASTO ANORMAL EM UM ÚNICO FORNECEDOR ───
-- Deputados que concentram >40% da cota anual num único CNPJ.
-- Sinal de favorecimento, empresa "laranja" ou uso irregular.

WITH gasto_total AS (
  SELECT id_deputado, ano, SUM(valor_liquido) AS total_ano
  FROM public.cota_despesa
  GROUP BY id_deputado, ano
),
gasto_por_cnpj AS (
  SELECT id_deputado, ano, cnpj_norm, SUM(valor_liquido) AS total_cnpj
  FROM public.cota_despesa
  WHERE cnpj_norm IS NOT NULL AND cnpj_norm <> ''
  GROUP BY id_deputado, ano, cnpj_norm
)
SELECT
  cd.nome                                             AS parlamentar,
  cd.partido,
  cd.uf,
  g.ano,
  g.cnpj_norm                                        AS cnpj,
  MAX(c.nome_fornecedor)                             AS fornecedor,
  ROUND(g.total_cnpj::numeric, 2)                    AS gasto_no_cnpj,
  ROUND(t.total_ano::numeric, 2)                     AS gasto_total_ano,
  ROUND((g.total_cnpj / NULLIF(t.total_ano,0) * 100)::numeric, 1) AS pct_concentracao
FROM gasto_por_cnpj g
JOIN gasto_total t USING (id_deputado, ano)
JOIN public.cota_deputado cd ON cd.id_camara = g.id_deputado
JOIN public.cota_despesa c
  ON c.id_deputado = g.id_deputado AND c.cnpj_norm = g.cnpj_norm AND c.ano = g.ano
WHERE g.total_cnpj / NULLIF(t.total_ano, 0) > 0.40
  AND t.total_ano > 50000   -- filtrar casos com gasto ínfimo
  AND g.ano >= 2019
GROUP BY cd.nome, cd.partido, cd.uf, g.ano, g.cnpj_norm, g.total_cnpj, t.total_ano
ORDER BY pct_concentracao DESC
LIMIT 40;


-- ── Q5: FORNECEDOR NA COTA + SANÇÕES (CEIS/CNEP) ────────────────────────────
-- Empresas sancionadas que continuam recebendo dinheiro da cota parlamentar.

SELECT
  c.cnpj_norm                                         AS cnpj,
  MAX(c.nome_fornecedor)                              AS nome_cota,
  ROUND(SUM(c.valor_liquido)::numeric, 2)             AS total_cota_brl,
  COUNT(DISTINCT c.id_deputado)                       AS n_deputados,
  s.tipo_sancao,
  s.descricao_sancao,
  s.data_inicio,
  s.orgao_nome                                        AS orgao_sancionador,
  s.fundamentacao
FROM public.cota_despesa c
JOIN public.sancoes s
  ON s.cpf_cnpj = c.cnpj_norm
WHERE c.cnpj_norm IS NOT NULL AND length(c.cnpj_norm) = 14
GROUP BY c.cnpj_norm, s.tipo_sancao, s.descricao_sancao, s.data_inicio, s.orgao_nome, s.fundamentacao
ORDER BY total_cota_brl DESC
LIMIT 30;
