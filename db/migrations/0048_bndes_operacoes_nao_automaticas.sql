-- The BR Insider — BNDES Operações Não Automáticas (tabela editorial)
-- Fonte: CKAN dadosabertos.bndes.gov.br, dataset "operacoes-financiamento"
--   resource "Operações não automáticas" (id 6f56b78c-510f-44b6-8274-78a5b7e931f4)
-- CNPJ do cliente vem COMPLETO neste resource (confirmado via datastore_search em
-- 2026-07-22) — diferente do resource "indiretas automáticas" (2,36M linhas), onde o
-- CNPJ vem mascarado e por isso NÃO é ingerido aqui.
-- Volume: ~23,6k linhas (uma por subcrédito de contrato), dados desde 2002,
-- atualização mensal.
--
-- SEM chave natural única: subcréditos do mesmo contrato podem ter valor e
-- data idênticos (confirmado em 2026-07-22 — 1.454 colisões numa chave
-- estendida de 7 campos, 384 linhas idênticas em TODOS os campos). Por isso
-- o conector faz full refresh (DELETE + INSERT) a cada execução, em vez de
-- upsert por chave natural.

CREATE TABLE IF NOT EXISTS public.bndes_operacoes_nao_automaticas (
  id                                          BIGSERIAL PRIMARY KEY,
  numero_do_contrato                         BIGINT          NOT NULL,
  cnpj                                        TEXT            NOT NULL,   -- só dígitos (14)
  cliente                                     TEXT,
  descricao_do_projeto                       TEXT,
  uf                                          CHAR(2),
  municipio                                   TEXT,
  municipio_codigo                           INTEGER,
  data_da_contratacao                        DATE,
  valor_contratado_reais                     NUMERIC(18, 2),
  valor_desembolsado_reais                   NUMERIC(18, 2),
  fonte_de_recurso_desembolsos               TEXT,
  custo_financeiro                           TEXT,
  juros                                      NUMERIC(9, 4),
  prazo_carencia_meses                       SMALLINT,
  prazo_amortizacao_meses                    SMALLINT,
  modalidade_de_apoio                        TEXT,
  forma_de_apoio                             TEXT,          -- 'DIRETA' | 'INDIRETA'
  produto                                    TEXT,
  instrumento_financeiro                     TEXT,
  inovacao                                   TEXT,
  area_operacional                           TEXT,
  setor_cnae                                 TEXT,
  subsetor_cnae_agrupado                     TEXT,
  subsetor_cnae_codigo                       TEXT,
  subsetor_cnae_nome                         TEXT,
  setor_bndes                                TEXT,
  subsetor_bndes                             TEXT,
  porte_do_cliente                           TEXT,
  natureza_do_cliente                        TEXT,
  instituicao_financeira_credenciada         TEXT,          -- só para forma_de_apoio='INDIRETA'
  cnpj_instituicao_financeira_credenciada    TEXT,          -- só dígitos, idem
  tipo_de_garantia                           TEXT,
  tipo_de_excepcionalidade                   TEXT,
  situacao_do_contrato                       TEXT,
  ingested_at                                TIMESTAMPTZ     NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.bndes_operacoes_nao_automaticas IS
  'Operações de financiamento do BNDES contratadas fora do rito automático '
  '(análise manual, diretas ou indiretas revisadas). ~23,6k linhas, CNPJ do '
  'cliente completo. Cruzável com contratos_federais.fornecedor_cnpj e '
  'emendas_favorecidos.codigo_favorecido.';

CREATE INDEX IF NOT EXISTS bndes_operacoes_cnpj_idx           ON public.bndes_operacoes_nao_automaticas (cnpj);
CREATE INDEX IF NOT EXISTS bndes_operacoes_uf_idx             ON public.bndes_operacoes_nao_automaticas (uf);
CREATE INDEX IF NOT EXISTS bndes_operacoes_contrato_idx       ON public.bndes_operacoes_nao_automaticas (numero_do_contrato);
CREATE INDEX IF NOT EXISTS bndes_operacoes_data_idx           ON public.bndes_operacoes_nao_automaticas (data_da_contratacao);
CREATE INDEX IF NOT EXISTS bndes_operacoes_valor_idx          ON public.bndes_operacoes_nao_automaticas (valor_contratado_reais);
CREATE INDEX IF NOT EXISTS bndes_operacoes_setor_bndes_idx    ON public.bndes_operacoes_nao_automaticas (setor_bndes);
CREATE INDEX IF NOT EXISTS bndes_operacoes_porte_idx          ON public.bndes_operacoes_nao_automaticas (porte_do_cliente);

-- ── View de cruzamento CNPJ × emendas parlamentares ───────────────────────
CREATE OR REPLACE VIEW public.vw_bndes_cnpj_emendas AS
SELECT
  bo.cnpj,
  bo.cliente,
  bo.uf,
  COUNT(*)                          AS qtd_operacoes,
  SUM(bo.valor_contratado_reais)    AS valor_total_contratado
FROM public.bndes_operacoes_nao_automaticas bo
WHERE bo.cnpj IS NOT NULL AND bo.cnpj <> ''
GROUP BY bo.cnpj, bo.cliente, bo.uf;

COMMENT ON VIEW public.vw_bndes_cnpj_emendas IS
  'Clientes do BNDES (operações não automáticas) agrupados por CNPJ/UF — '
  'base para cruzamento com emendas parlamentares, contratos PNCP e TSE.';
