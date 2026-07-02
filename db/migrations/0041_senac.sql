-- The BR Insider — SENAC (Serviço Nacional de Aprendizagem Comercial)
-- Fonte: transparencia.senac.br — API JSON pública (sem autenticação)
-- Regionais: DN + 27 DRs estaduais
-- Endpoints:
--   contratos/parcerias/convênios/acordos/patrocínios → /service/api/contratos-parcerias?regional={sigla}
--   licitações → /service/api/licitacoes/regional/{sigla}

-- ── Tipos de contrato (campo tipo) ─────────────────────────────────────────
-- 1 = Contrato | 2 = Acordo | 3 = Convênio | 4 = Parceria | 5 = Patrocínio

-- ── Contratos, Parcerias, Convênios, Acordos e Patrocínios ─────────────────
CREATE TABLE IF NOT EXISTS public.senac_contratos (
  id                    BIGSERIAL PRIMARY KEY,
  regional              TEXT        NOT NULL,  -- ex: dn, sp, mg
  numero                TEXT        NOT NULL,  -- número interno
  numero_origem         TEXT,                  -- número original do processo
  tipo                  SMALLINT,              -- 1=contrato 2=acordo 3=convenio 4=parceria 5=patrocinio
  situacao              TEXT,
  objeto                TEXT,
  favorecido            TEXT,
  cnpj_cpf              TEXT,
  tipo_pessoa           SMALLINT,              -- 1=PJ 0=PF
  elemento_despesa      TEXT,
  modalidade_origem     TEXT,
  natureza              SMALLINT,
  valor_total           NUMERIC(18,2),
  valor_pago            NUMERIC(18,2),
  data_contratacao      DATE,
  data_fim              DATE,
  ano_mes_referencia    TEXT,
  data_ultima_carga     TIMESTAMPTZ,
  data_ingestao         DATE        NOT NULL DEFAULT CURRENT_DATE,
  UNIQUE (regional, numero)
);

COMMENT ON TABLE public.senac_contratos IS
  'Contratos, parcerias, convênios, acordos e patrocínios SENAC por DR. '
  'Tipo: 1=contrato 2=acordo 3=convenio 4=parceria 5=patrocinio. '
  'Fonte: transparencia.senac.br/service/api/contratos-parcerias?regional={sigla} (sem auth). '
  'DN + 27 regionais estaduais.';

CREATE INDEX IF NOT EXISTS idx_senac_contratos_regional  ON public.senac_contratos(regional);
CREATE INDEX IF NOT EXISTS idx_senac_contratos_cnpj      ON public.senac_contratos(cnpj_cpf);
CREATE INDEX IF NOT EXISTS idx_senac_contratos_tipo      ON public.senac_contratos(tipo);

-- ── Licitações ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.senac_licitacoes (
  id                    BIGSERIAL PRIMARY KEY,
  regional              TEXT        NOT NULL,
  modalidade_id         TEXT,
  modalidade            TEXT,
  licitacao_id          TEXT        NOT NULL,  -- UUID da licitação no portal
  situacao              TEXT,
  numero_processo       TEXT,
  objeto                TEXT,
  data_abertura         TIMESTAMPTZ,
  data_situacao         TIMESTAMPTZ,
  data_ultima_carga     TIMESTAMPTZ,
  data_ingestao         DATE        NOT NULL DEFAULT CURRENT_DATE,
  UNIQUE (regional, licitacao_id)
);

COMMENT ON TABLE public.senac_licitacoes IS
  'Licitações SENAC por DR. '
  'Fonte: transparencia.senac.br/service/api/licitacoes/regional/{sigla} (sem auth). '
  'DN + 27 regionais estaduais.';

CREATE INDEX IF NOT EXISTS idx_senac_licitacoes_regional ON public.senac_licitacoes(regional);

-- ── View CNPJ × emendas parlamentares ─────────────────────────────────────
CREATE OR REPLACE VIEW public.vw_senac_cnpj_emendas AS
SELECT
  cnpj_cpf,
  favorecido,
  regional,
  COUNT(*)                          AS qtd_contratos,
  SUM(valor_total)                  AS valor_total_contratos,
  SUM(valor_pago)                   AS valor_total_pago
FROM public.senac_contratos
WHERE cnpj_cpf IS NOT NULL
  AND cnpj_cpf NOT IN ('', '-')
GROUP BY cnpj_cpf, favorecido, regional;

COMMENT ON VIEW public.vw_senac_cnpj_emendas IS
  'Fornecedores SENAC agrupados por CNPJ/regional — base para cruzamento com emendas e doações TSE.';
