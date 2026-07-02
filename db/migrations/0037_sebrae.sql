-- The BR Insider — Sistema SEBRAE (Contratos, Licitações, Convênios, Patrocínios)
-- Fonte: paineis-lai.sebrae.com.br — Qlik Engine API (WebSocket, sem autenticação)
-- App ID: e2407c39-2fb9-4637-bf20-7eb974711cea
-- ~480k contratos + 21k licitações + 2.8k convênios + 1.9k patrocínios

-- ── Contratos ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.sebrae_contratos (
  id                  BIGSERIAL PRIMARY KEY,
  uf                  CHAR(2)     NOT NULL,
  ano                 SMALLINT,
  numero_contrato     TEXT        NOT NULL,
  data_contrato       TEXT,
  modalidade          TEXT,
  cnpj_cpf            TEXT,
  razao_social        TEXT,
  vigencia            TEXT,
  objeto              TEXT,
  aditivo             TEXT,
  valor_contrato      TEXT,
  valor_pago          TEXT,
  data_ingestao       DATE        NOT NULL DEFAULT CURRENT_DATE,
  UNIQUE (uf, numero_contrato)
);

COMMENT ON TABLE public.sebrae_contratos IS
  'Contratos do Sistema SEBRAE por UF. ~480k linhas. '
  'Fonte: Qlik Engine API paineis-lai.sebrae.com.br (App e2407c39).';

CREATE INDEX IF NOT EXISTS idx_sebrae_contratos_uf   ON public.sebrae_contratos(uf);
CREATE INDEX IF NOT EXISTS idx_sebrae_contratos_cnpj ON public.sebrae_contratos(cnpj_cpf);
CREATE INDEX IF NOT EXISTS idx_sebrae_contratos_ano  ON public.sebrae_contratos(ano);

-- ── Licitações ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.sebrae_licitacoes (
  id                  BIGSERIAL PRIMARY KEY,
  uf                  CHAR(2)     NOT NULL,
  numero_licitacao    TEXT        NOT NULL,
  tipo_julgamento     TEXT,
  menor_preco         TEXT,
  situacao            TEXT,
  modalidade          TEXT,
  julgamento          TEXT,
  objeto              TEXT,
  data_abertura       TEXT,
  data_homologacao    TEXT,
  resultado           TEXT,
  cnpj_fornecedor     TEXT,
  nome_fornecedor     TEXT,
  data_ingestao       DATE        NOT NULL DEFAULT CURRENT_DATE,
  UNIQUE (uf, numero_licitacao)
);

COMMENT ON TABLE public.sebrae_licitacoes IS
  'Licitações do Sistema SEBRAE por UF. ~21k linhas. '
  'Fonte: Qlik Engine API paineis-lai.sebrae.com.br.';

CREATE INDEX IF NOT EXISTS idx_sebrae_licitacoes_uf   ON public.sebrae_licitacoes(uf);
CREATE INDEX IF NOT EXISTS idx_sebrae_licitacoes_cnpj ON public.sebrae_licitacoes(cnpj_fornecedor);

-- ── Convênios ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.sebrae_convenios (
  id                      BIGSERIAL PRIMARY KEY,
  uf                      CHAR(2)     NOT NULL,
  ano                     SMALLINT,
  numero_convenio         TEXT        NOT NULL,
  data_convenio           TEXT,
  cnpj_cpf                TEXT,
  razao_social            TEXT,
  vigencia                TEXT,
  objeto                  TEXT,
  aditivo                 TEXT,
  participacao_sebrae     TEXT,
  valor_repasse           TEXT,
  valor_contrapartida     TEXT,
  data_ingestao           DATE        NOT NULL DEFAULT CURRENT_DATE,
  UNIQUE (uf, numero_convenio)
);

COMMENT ON TABLE public.sebrae_convenios IS
  'Convênios do Sistema SEBRAE por UF. ~2.8k linhas. '
  'Fonte: Qlik Engine API paineis-lai.sebrae.com.br.';

CREATE INDEX IF NOT EXISTS idx_sebrae_convenios_uf   ON public.sebrae_convenios(uf);
CREATE INDEX IF NOT EXISTS idx_sebrae_convenios_cnpj ON public.sebrae_convenios(cnpj_cpf);

-- ── Patrocínios ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.sebrae_patrocinios (
  id                  BIGSERIAL PRIMARY KEY,
  uf                  CHAR(2)     NOT NULL,
  ano                 SMALLINT,
  numero_contrato     TEXT        NOT NULL,
  data_contrato       TEXT,
  cnpj_cpf            TEXT,
  razao_social        TEXT,
  vigencia            TEXT,
  objeto              TEXT,
  aditivo             TEXT,
  valor_contrato      TEXT,
  valor_pago          TEXT,
  data_ingestao       DATE        NOT NULL DEFAULT CURRENT_DATE,
  UNIQUE (uf, numero_contrato)
);

COMMENT ON TABLE public.sebrae_patrocinios IS
  'Patrocínios do Sistema SEBRAE por UF. ~1.9k linhas. '
  'Fonte: Qlik Engine API paineis-lai.sebrae.com.br.';

-- ── Emendas ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.sebrae_emendas_contratos (
  id                  BIGSERIAL PRIMARY KEY,
  uf                  CHAR(2)     NOT NULL,
  ano                 SMALLINT,
  numero_contrato     TEXT        NOT NULL,
  data_contrato       TEXT,
  modalidade          TEXT,
  cnpj_cpf            TEXT,
  razao_social        TEXT,
  vigencia            TEXT,
  objeto              TEXT,
  aditivo             TEXT,
  observacao          TEXT,
  valor_contrato      TEXT,
  data_ingestao       DATE        NOT NULL DEFAULT CURRENT_DATE,
  UNIQUE (uf, numero_contrato)
);

CREATE TABLE IF NOT EXISTS public.sebrae_emendas_convenios (
  id                  BIGSERIAL PRIMARY KEY,
  uf                  CHAR(2)     NOT NULL,
  ano                 SMALLINT,
  numero_convenio     TEXT        NOT NULL,
  data_convenio       TEXT,
  cnpj_cpf            TEXT,
  razao_social        TEXT,
  vigencia            TEXT,
  objeto              TEXT,
  aditivo             TEXT,
  observacao          TEXT,
  valor_emenda        TEXT,
  data_ingestao       DATE        NOT NULL DEFAULT CURRENT_DATE,
  UNIQUE (uf, numero_convenio)
);

COMMENT ON TABLE public.sebrae_emendas_contratos IS
  'Contratos do SEBRAE provenientes de emendas parlamentares. '
  'Fonte: Qlik Engine API paineis-lai.sebrae.com.br.';
COMMENT ON TABLE public.sebrae_emendas_convenios IS
  'Convênios do SEBRAE provenientes de emendas parlamentares. '
  'Fonte: Qlik Engine API paineis-lai.sebrae.com.br.';

-- ── View de cruzamento CNPJ × emendas parlamentares ───────────────────────
CREATE OR REPLACE VIEW public.vw_sebrae_cnpj_emendas AS
SELECT
  sc.cnpj_cpf,
  sc.razao_social,
  sc.uf,
  COUNT(*)        AS qtd_contratos,
  SUM(
    REPLACE(REPLACE(sc.valor_contrato, '.', ''), ',', '.')::NUMERIC
  )               AS valor_total_contratos
FROM public.sebrae_contratos sc
WHERE sc.cnpj_cpf IS NOT NULL AND sc.cnpj_cpf != '-'
GROUP BY sc.cnpj_cpf, sc.razao_social, sc.uf;

COMMENT ON VIEW public.vw_sebrae_cnpj_emendas IS
  'Fornecedores SEBRAE agrupados por CNPJ/UF — base para cruzamento com emendas parlamentares e TSE.';
