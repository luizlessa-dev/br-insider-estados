-- Lookup table de normalização CNPJ — evita ALTER TABLE nas 4M linhas.
-- Popula via seed Python (seed_cota_cnpj_lookup.py).
-- JOIN: cota_despesa → cota_cnpj_lookup → emendas_favorecidos

CREATE TABLE IF NOT EXISTS public.cota_cnpj_lookup (
  cnpj_raw   TEXT PRIMARY KEY,   -- formato original: "300.693.140/0010-1"
  cnpj_norm  TEXT NOT NULL,      -- só dígitos: "30069314000101"
  is_cnpj    BOOLEAN GENERATED ALWAYS AS (length(regexp_replace(cnpj_raw,'[^0-9]','','g')) = 14) STORED
);

CREATE INDEX IF NOT EXISTS idx_cota_lookup_norm ON public.cota_cnpj_lookup(cnpj_norm);

COMMENT ON TABLE public.cota_cnpj_lookup IS
  'Mapeamento cnpj_raw → cnpj_norm para cota_despesa. '
  'Evita ALTER TABLE nas 4M linhas — JOIN através desta tabela.';

-- View de cruzamento usando lookup
CREATE OR REPLACE VIEW public.cota_emenda_cruzamento AS
SELECT
  lk.cnpj_norm                                       AS cnpj,
  c.nome_fornecedor                                  AS nome_na_cota,
  COUNT(DISTINCT c.id_deputado)                      AS dep_cota,
  ROUND(SUM(c.valor_liquido)::numeric, 2)            AS total_cota_brl,
  e.favorecido                                       AS nome_na_emenda,
  ROUND(e.valor_total::numeric, 2)                   AS total_emenda_brl,
  e.n_autores                                        AS autores_emenda
FROM public.cota_despesa c
JOIN public.cota_cnpj_lookup lk ON lk.cnpj_raw = c.cnpj_cpf_fornecedor
JOIN (
  SELECT codigo_favorecido,
         MAX(favorecido)              AS favorecido,
         SUM(valor_recebido)          AS valor_total,
         COUNT(DISTINCT codigo_autor) AS n_autores
  FROM public.emendas_favorecidos
  WHERE codigo_favorecido IS NOT NULL AND codigo_favorecido <> ''
  GROUP BY codigo_favorecido
) e ON e.codigo_favorecido = lk.cnpj_norm
WHERE lk.is_cnpj
GROUP BY lk.cnpj_norm, c.nome_fornecedor, e.favorecido, e.valor_total, e.n_autores
ORDER BY (SUM(c.valor_liquido) + e.valor_total) DESC NULLS LAST;
