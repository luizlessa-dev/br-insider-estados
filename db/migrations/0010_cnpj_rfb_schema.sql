-- The Brasilia Insider — CNPJ Receita Federal (complementar)
-- A tabela cnpj_socios JÁ EXISTE no banco com 4.426+ registros.
-- Schema real: cnpj_basico, identificador, nome_socio, nome_norm,
--              cpf_cnpj_socio, qualificacao, data_entrada, faixa_etaria, atualizado_em
-- Este migration:
--   1. Cria cnpj_empresas (complementar — ainda não existia)
--   2. Cria view cruzada usando o schema REAL da cnpj_socios existente
--   3. Cria tabelas de log e aplica RLS

-- ═══════════════════════════════════════════════════════════════════════════
-- EMPRESAS
-- ═══════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.cnpj_empresas (
  cnpj_basico             CHAR(8)       PRIMARY KEY,
  razao_social            TEXT,
  natureza_juridica       TEXT,
  capital_social          TEXT,
  porte_empresa           TEXT,
  atualizado_em           TIMESTAMPTZ   NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_cnpj_emp_porte
  ON public.cnpj_empresas(porte_empresa);

COMMENT ON TABLE public.cnpj_empresas IS
  'Dados cadastrais básicos das empresas favorecidas (Receita Federal, dump mensal). '
  'cnpj_basico (8 dígitos) é chave de join com emendas_favorecidos via substring(codigo_favorecido,1,8).';

-- ═══════════════════════════════════════════════════════════════════════════
-- VIEW: Parlamentar é sócio de empresa que recebeu emenda
-- (usa schema REAL da cnpj_socios existente)
-- ═══════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE VIEW public.v_parlamentar_socio_emenda AS
SELECT
  p.nome                                    AS parlamentar,
  p.partido,
  p.uf,
  cs.cnpj_basico,
  ce.razao_social,
  ce.porte_empresa,
  cs.qualificacao,
  cs.data_entrada,
  SUM(ef.valor_recebido)                    AS total_emendas,
  COUNT(DISTINCT ef.codigo_emenda)          AS qtd_emendas,
  MAX(ef.ano_emenda)                        AS ultimo_ano
FROM public.cnpj_socios cs
LEFT JOIN public.cnpj_empresas ce ON ce.cnpj_basico = cs.cnpj_basico
JOIN public.parlamentares p       ON p.cpf = cs.cpf_cnpj_socio
JOIN public.emendas_favorecidos ef
  ON substring(ef.codigo_favorecido, 1, 8) = cs.cnpj_basico
WHERE length(cs.cpf_cnpj_socio) = 11
GROUP BY
  p.nome, p.partido, p.uf,
  cs.cnpj_basico, ce.razao_social, ce.porte_empresa,
  cs.qualificacao, cs.data_entrada
ORDER BY total_emendas DESC NULLS LAST;

COMMENT ON VIEW public.v_parlamentar_socio_emenda IS
  'Parlamentar que é sócio de empresa que recebeu emenda. '
  'Cruza cnpj_socios.cpf_cnpj_socio × parlamentares.cpf × emendas_favorecidos.';

-- ═══════════════════════════════════════════════════════════════════════════
-- LOG
-- ═══════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.cnpj_ingest_log (
  id          BIGSERIAL   PRIMARY KEY,
  particao    TEXT        NOT NULL,
  started_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  finished_at TIMESTAMPTZ,
  status      TEXT        NOT NULL DEFAULT 'running',
  n_matches   INTEGER,
  erro        TEXT
);

-- ═══════════════════════════════════════════════════════════════════════════
-- RLS
-- ═══════════════════════════════════════════════════════════════════════════
ALTER TABLE public.cnpj_empresas   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cnpj_ingest_log ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE tbl TEXT;
BEGIN
  FOR tbl IN SELECT unnest(ARRAY['cnpj_empresas','cnpj_ingest_log'])
  LOOP
    EXECUTE format(
      'DROP POLICY IF EXISTS %I ON public.%I; '
      'CREATE POLICY %I ON public.%I FOR SELECT USING (true);',
      'public_read_'||tbl, tbl, 'public_read_'||tbl, tbl
    );
  END LOOP;
END $$;
