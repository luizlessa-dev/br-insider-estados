-- The BR Insider — Contratos de Publicidade Federal (PNCP) + Vínculos Mídia
-- Migration 0025
--
-- Novos objetos:
--   pncp_publicidade         — contratos federais de publicidade/comunicação
--   v_pncp_pub_por_orgao     — ranking de gastos com publicidade por órgão
--   v_pncp_pub_por_fornecedor — ranking de beneficiários de contratos de publicidade
--   v_midia_doadora_emenda   — empresa de comunicação que doa + recebe emenda
-- ============================================================================

-- ── Tabela principal ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.pncp_publicidade (
  -- PK = número de controle único do PNCP
  numero_controle_pncp    TEXT          PRIMARY KEY,

  ano_contrato            SMALLINT,
  data_assinatura         DATE,
  data_publicacao_pncp    TIMESTAMPTZ,
  data_vigencia_inicio    DATE,
  data_vigencia_fim       DATE,

  valor_inicial           NUMERIC(18,2),
  valor_global            NUMERIC(18,2),

  objeto_contrato         TEXT,
  numero_contrato         TEXT,
  modalidade              TEXT,

  -- fornecedor (empresa que presta o serviço de publicidade)
  cnpj_fornecedor         TEXT,
  nome_fornecedor         TEXT,

  -- órgão contratante
  cnpj_orgao              TEXT,
  nome_orgao              TEXT,
  esfera_orgao            TEXT,       -- 'F' federal, 'E' estadual, 'M' municipal
  poder_orgao             TEXT,       -- 'E' executivo, 'L' legislativo, 'J' judiciário
  uf_orgao                TEXT,
  municipio_orgao         TEXT,
  nome_unidade            TEXT,

  url_pncp                TEXT,
  coletado_em             TIMESTAMPTZ  NOT NULL DEFAULT now(),

  CONSTRAINT pncp_pub_valor_positivo CHECK (valor_global >= 0)
);

CREATE INDEX IF NOT EXISTS idx_pncp_pub_ano       ON public.pncp_publicidade(ano_contrato);
CREATE INDEX IF NOT EXISTS idx_pncp_pub_orgao     ON public.pncp_publicidade(cnpj_orgao);
CREATE INDEX IF NOT EXISTS idx_pncp_pub_fornecedor ON public.pncp_publicidade(cnpj_fornecedor);
CREATE INDEX IF NOT EXISTS idx_pncp_pub_uf        ON public.pncp_publicidade(uf_orgao);
CREATE INDEX IF NOT EXISTS idx_pncp_pub_objeto    ON public.pncp_publicidade USING GIN (to_tsvector('portuguese', objeto_contrato));

COMMENT ON TABLE public.pncp_publicidade IS
  'Contratos federais de publicidade/comunicação coletados do PNCP. '
  'Filtro: objetoContrato contém palavras-chave de publicidade + esferaId = F. '
  'Cobertura: 2023–atual. Atualizado semanalmente pelo cron pncp-publicidade.';

-- ── Views investigativas ──────────────────────────────────────────────────────

-- Gastos de publicidade por órgão federal (ranking anual)
CREATE OR REPLACE VIEW public.v_pncp_pub_por_orgao AS
SELECT
  ano_contrato,
  cnpj_orgao,
  nome_orgao,
  uf_orgao,
  COUNT(*)                               AS n_contratos,
  SUM(valor_global)                      AS total_brl,
  AVG(valor_global)                      AS media_contrato_brl,
  MAX(valor_global)                      AS maior_contrato_brl,
  COUNT(DISTINCT cnpj_fornecedor)        AS n_fornecedores_distintos,
  ARRAY_AGG(DISTINCT nome_fornecedor
    ORDER BY nome_fornecedor)
    FILTER (WHERE nome_fornecedor IS NOT NULL) AS fornecedores
FROM public.pncp_publicidade
GROUP BY ano_contrato, cnpj_orgao, nome_orgao, uf_orgao
ORDER BY total_brl DESC NULLS LAST;

COMMENT ON VIEW public.v_pncp_pub_por_orgao IS
  'Ranking de gastos com publicidade por órgão federal (PNCP). '
  'Produto: "Quem mais gasta com publicidade no governo federal?"';

-- Beneficiários (fornecedores) de contratos de publicidade federal
CREATE OR REPLACE VIEW public.v_pncp_pub_por_fornecedor AS
SELECT
  cnpj_fornecedor,
  nome_fornecedor,
  COUNT(*)                               AS n_contratos,
  COUNT(DISTINCT ano_contrato)           AS n_anos,
  COUNT(DISTINCT cnpj_orgao)            AS n_orgaos_clientes,
  SUM(valor_global)                      AS total_brl,
  MAX(valor_global)                      AS maior_contrato_brl,
  MIN(data_assinatura)                   AS primeiro_contrato,
  MAX(data_assinatura)                   AS ultimo_contrato,
  (ARRAY_AGG(DISTINCT nome_orgao ORDER BY nome_orgao))[1:10] AS orgaos_clientes_amostra
FROM public.pncp_publicidade
WHERE cnpj_fornecedor IS NOT NULL AND cnpj_fornecedor != ''
GROUP BY cnpj_fornecedor, nome_fornecedor
ORDER BY total_brl DESC NULLS LAST;

COMMENT ON VIEW public.v_pncp_pub_por_fornecedor IS
  'Ranking de fornecedores de publicidade federal. '
  'Produto: "Quem são as agências que vivem do governo?"';

-- Empresas de comunicação que doaram para campanhas E receberam emendas
-- (conflito: financiador de política + beneficiário de verba pública)
CREATE OR REPLACE VIEW public.v_midia_doadora_emenda AS
SELECT
  r.cpf_cnpj_doador                     AS cnpj,
  r.nome_doador                         AS nome_empresa,
  r.setor_economico_doador              AS setor_tse,
  SUM(r.valor)                          AS total_doado_campanha_brl,
  COUNT(DISTINCT r.nome_candidato)      AS n_candidatos_beneficiados,
  COUNT(DISTINCT r.ano_eleicao)         AS n_eleicoes,
  SUM(ef.valor_recebido)                AS total_emendas_recebidas_brl,
  COUNT(DISTINCT ef.numero_emenda)      AS n_emendas_recebidas,
  (ARRAY_AGG(DISTINCT ef.numero_emenda ORDER BY ef.numero_emenda))[1:10] AS emendas_amostra
FROM public.tse_receitas r
JOIN public.emendas_favorecidos ef
  ON ef.codigo_favorecido = r.cpf_cnpj_doador
WHERE
  r.tipo_doador = 'PJ'
  AND (
    r.setor_economico_doador ILIKE '%comunicação%'
    OR r.setor_economico_doador ILIKE '%comunicacao%'
    OR r.setor_economico_doador ILIKE '%publicidade%'
    OR r.setor_economico_doador ILIKE '%radiodifusão%'
    OR r.setor_economico_doador ILIKE '%radiodifusao%'
    OR r.setor_economico_doador ILIKE '%televisão%'
    OR r.setor_economico_doador ILIKE '%televisao%'
    OR r.setor_economico_doador ILIKE '%rádio%'
    OR r.setor_economico_doador ILIKE '%radio%'
    OR r.setor_economico_doador ILIKE '%mídia%'
    OR r.setor_economico_doador ILIKE '%midia%'
  )
GROUP BY r.cpf_cnpj_doador, r.nome_doador, r.setor_economico_doador
ORDER BY total_doado_campanha_brl DESC NULLS LAST;

COMMENT ON VIEW public.v_midia_doadora_emenda IS
  'Empresas de comunicação (classificadas pelo TSE) que financiaram campanhas '
  'E receberam emendas parlamentares — potencial conflito de interesse. '
  'Produto: "A mídia que depende de emenda e financia quem decide emendas."';

-- ── RLS ──────────────────────────────────────────────────────────────────────
ALTER TABLE public.pncp_publicidade ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'pncp_publicidade' AND policyname = 'leitura_publica'
  ) THEN
    CREATE POLICY leitura_publica ON public.pncp_publicidade
      FOR SELECT USING (true);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'pncp_publicidade' AND policyname = 'escrita_service_role'
  ) THEN
    CREATE POLICY escrita_service_role ON public.pncp_publicidade
      FOR ALL TO service_role USING (true);
  END IF;
END $$;
