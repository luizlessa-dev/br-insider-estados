-- The BR Insider — SESC (Serviço Social do Comércio)
-- Fonte: transparencia-[uf].sesc.com.br — CSV público (sem autenticação)
-- Portais: DN + 27 DRs estaduais (28 portais)
-- Datasets: contratos firmados (178), contratos pagos (179), convênios (180/183)

-- ── Contratos ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.sesc_contratos (
  id                    BIGSERIAL PRIMARY KEY,
  portal                TEXT        NOT NULL,  -- ex: DN, SP, MG
  dataset_id            SMALLINT    NOT NULL,  -- 178=firmados | 179=pagos
  unidade               TEXT,                  -- Unidade_id da API
  exercicio             SMALLINT,
  numero_contrato       TEXT        NOT NULL,
  objeto                TEXT,
  favorecido            TEXT,
  cnpj_cpf              TEXT,
  modalidade_licitacao  TEXT,
  data_contratacao      TEXT,
  elemento_despesa      TEXT,
  valor_contrato        TEXT,
  valor_pago            TEXT,                  -- dataset 179: Valor_do_Pagamento_no_exercicio
  data_ingestao         DATE        NOT NULL DEFAULT CURRENT_DATE,
  UNIQUE (portal, exercicio, numero_contrato)
);

COMMENT ON TABLE public.sesc_contratos IS
  'Contratos SESC por DR e exercício. Dataset 178 (firmados) e 179 (com pagamento). '
  'Fonte: transparencia-[uf].sesc.com.br/transparencia/dados/download/{id}/csv (sem auth). '
  '28 portais (DN + 27 UFs).';

CREATE INDEX IF NOT EXISTS idx_sesc_contratos_portal  ON public.sesc_contratos(portal);
CREATE INDEX IF NOT EXISTS idx_sesc_contratos_cnpj    ON public.sesc_contratos(cnpj_cpf);
CREATE INDEX IF NOT EXISTS idx_sesc_contratos_ano     ON public.sesc_contratos(exercicio);

-- ── Convênios ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.sesc_convenios (
  id                        BIGSERIAL PRIMARY KEY,
  portal                    TEXT        NOT NULL,
  dataset_id                SMALLINT    NOT NULL,  -- 180=firmados | 183=pagos
  unidade                   TEXT,
  exercicio                 TEXT,
  numero_convenio           TEXT        NOT NULL,
  objeto                    TEXT,
  favorecido                TEXT,
  cnpj_cpf                  TEXT,
  valor_contrapartida       TEXT,
  data_firmatura            TEXT,
  valor_total               TEXT,                  -- dataset 180: Valor_Total
  valor_pago_exercicio      TEXT,                  -- dataset 183: Valor_do_Pagamento_no_exercicio
  data_ingestao             DATE        NOT NULL DEFAULT CURRENT_DATE,
  UNIQUE (portal, exercicio, numero_convenio)
);

COMMENT ON TABLE public.sesc_convenios IS
  'Convênios SESC por DR e exercício. Dataset 180 (firmados) e 183 (com pagamento). '
  'Fonte: transparencia-[uf].sesc.com.br/transparencia/dados/download/{id}/csv (sem auth).';

CREATE INDEX IF NOT EXISTS idx_sesc_convenios_portal  ON public.sesc_convenios(portal);
CREATE INDEX IF NOT EXISTS idx_sesc_convenios_cnpj    ON public.sesc_convenios(cnpj_cpf);

-- ── View CNPJ × emendas parlamentares ─────────────────────────────────────
CREATE OR REPLACE VIEW public.vw_sesc_cnpj_emendas AS
SELECT
  cnpj_cpf,
  favorecido,
  portal,
  COUNT(*)                                         AS qtd_contratos,
  SUM(
    REPLACE(REPLACE(valor_contrato, '.', ''), ',', '.')::NUMERIC
  )                                                AS valor_total_contratos
FROM public.sesc_contratos
WHERE cnpj_cpf IS NOT NULL
  AND cnpj_cpf NOT IN ('', '-')
GROUP BY cnpj_cpf, favorecido, portal;

COMMENT ON VIEW public.vw_sesc_cnpj_emendas IS
  'Fornecedores SESC agrupados por CNPJ/portal — base para cruzamento com emendas e doações TSE.';
