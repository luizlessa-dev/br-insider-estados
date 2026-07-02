-- The BR Insider — Sistema Indústria: SESI + SENAI
-- Fonte: sistematransparenciaweb.com.br — REST API pública (sem autenticação)
-- Entidades: SENAI e SESI (27 DRs cada) — dados desde 2022
-- Módulos: contratos/patrocínios, licitações (+ participantes), convênios

-- ── Contratos e Patrocínios ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.sisi_contratos (
  id                        BIGSERIAL PRIMARY KEY,
  entidade                  TEXT        NOT NULL,  -- SENAI | SESI
  departamento              TEXT        NOT NULL,  -- ex: SENAI-SP
  codigo_contrato           BIGINT      NOT NULL,  -- codigoContratoPatrocinio (PK da API)
  ano                       SMALLINT,
  contrato                  TEXT,                  -- número do contrato
  processo                  TEXT,
  contratantes              TEXT,
  data_contrato             TEXT,
  vigencia_meses            INTEGER,
  data_final                TEXT,
  status_contrato           TEXT,
  modalidade                TEXT,
  objeto                    TEXT,
  categoria                 TEXT,
  cpf_cnpj                  TEXT,
  nome_razao_social         TEXT,
  valor_contrato            TEXT,
  valor_previsto            TEXT,
  valor_executado           TEXT,
  houve_aditivo_preco       TEXT,
  valor_aditivo             TEXT,
  houve_aditivo_prazo       TEXT,
  observacoes               TEXT,
  data_publicacao           TEXT,
  data_ingestao             DATE        NOT NULL DEFAULT CURRENT_DATE,
  UNIQUE (entidade, departamento, codigo_contrato)
);

COMMENT ON TABLE public.sisi_contratos IS
  'Contratos e patrocínios do Sistema Indústria (SESI + SENAI) por DR e ano. '
  'Fonte: sistematransparenciaweb.com.br/api-contratos (REST, sem auth). Dados desde 2022.';

CREATE INDEX IF NOT EXISTS idx_sisi_contratos_entidade    ON public.sisi_contratos(entidade);
CREATE INDEX IF NOT EXISTS idx_sisi_contratos_depto       ON public.sisi_contratos(departamento);
CREATE INDEX IF NOT EXISTS idx_sisi_contratos_cnpj        ON public.sisi_contratos(cpf_cnpj);
CREATE INDEX IF NOT EXISTS idx_sisi_contratos_ano         ON public.sisi_contratos(ano);

-- ── Licitações ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.sisi_licitacoes (
  id                        BIGSERIAL PRIMARY KEY,
  entidade                  TEXT        NOT NULL,
  departamento              TEXT        NOT NULL,
  codigo_licitacao          BIGINT      NOT NULL,  -- codigoLicitacao (PK da API)
  ano                       SMALLINT,
  numero                    TEXT,
  titulo                    TEXT,
  data_abertura             TEXT,
  modalidade                TEXT,
  objeto                    TEXT,
  status_licitacao          TEXT,
  crit_julgamento           TEXT,
  dt_homologacao            TEXT,
  nm_empresa_vencedora      TEXT,                  -- nmEmpresa do item de menor preço
  data_publicacao           TEXT,
  data_ingestao             DATE        NOT NULL DEFAULT CURRENT_DATE,
  UNIQUE (entidade, departamento, codigo_licitacao)
);

COMMENT ON TABLE public.sisi_licitacoes IS
  'Licitações do Sistema Indústria (SESI + SENAI) por DR e ano. '
  'Fonte: sistematransparenciaweb.com.br/api-licitacoes (REST, sem auth). Dados desde 2022.';

CREATE INDEX IF NOT EXISTS idx_sisi_licitacoes_entidade   ON public.sisi_licitacoes(entidade);
CREATE INDEX IF NOT EXISTS idx_sisi_licitacoes_depto      ON public.sisi_licitacoes(departamento);
CREATE INDEX IF NOT EXISTS idx_sisi_licitacoes_ano        ON public.sisi_licitacoes(ano);

-- ── Participantes de Licitações ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.sisi_licitacoes_participantes (
  id                        BIGSERIAL PRIMARY KEY,
  licitacao_codigo          BIGINT      NOT NULL,  -- FK lógica → sisi_licitacoes.codigo_licitacao
  entidade                  TEXT        NOT NULL,
  departamento              TEXT        NOT NULL,
  participante              TEXT,
  cnpj_cpf                  TEXT,
  valor_proposta            NUMERIC,
  data_ingestao             DATE        NOT NULL DEFAULT CURRENT_DATE,
  UNIQUE (entidade, departamento, licitacao_codigo, cnpj_cpf)
);

COMMENT ON TABLE public.sisi_licitacoes_participantes IS
  'Participantes (proponentes) por licitação SESI/SENAI — quem disputou e com qual preço. '
  'Permite detectar direcionamento e comparar preços entre DRs.';

CREATE INDEX IF NOT EXISTS idx_sisi_part_licitacao        ON public.sisi_licitacoes_participantes(licitacao_codigo);
CREATE INDEX IF NOT EXISTS idx_sisi_part_cnpj             ON public.sisi_licitacoes_participantes(cnpj_cpf);

-- ── Convênios ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.sisi_convenios (
  id                            BIGSERIAL PRIMARY KEY,
  entidade                      TEXT        NOT NULL,
  departamento                  TEXT        NOT NULL,
  codigo_convenio               BIGINT      NOT NULL,  -- codigoConvenios (PK da API)
  ano                           SMALLINT,
  numero_convenio               TEXT,
  data_convenio                 TEXT,
  vigencia                      TEXT,
  data_final                    TEXT,
  descricao_objeto              TEXT,
  razao_social_convenente       TEXT,
  cnpj                          TEXT,
  valor_participacao_concedente TEXT,
  valor_transferido             TEXT,
  status_convenio               TEXT,
  valor_contrapartida           TEXT,
  houve_aditivo_valor           TEXT,
  valor_aditivos                TEXT,
  houve_aditivo_prazo           TEXT,
  data_publicacao               TEXT,
  data_ingestao                 DATE        NOT NULL DEFAULT CURRENT_DATE,
  UNIQUE (entidade, departamento, codigo_convenio)
);

COMMENT ON TABLE public.sisi_convenios IS
  'Convênios do Sistema Indústria (SESI + SENAI) por DR e ano. '
  'Fonte: sistematransparenciaweb.com.br/api-convenios (REST, sem auth). Dados desde 2022.';

CREATE INDEX IF NOT EXISTS idx_sisi_convenios_entidade    ON public.sisi_convenios(entidade);
CREATE INDEX IF NOT EXISTS idx_sisi_convenios_depto       ON public.sisi_convenios(departamento);
CREATE INDEX IF NOT EXISTS idx_sisi_convenios_cnpj        ON public.sisi_convenios(cnpj);
CREATE INDEX IF NOT EXISTS idx_sisi_convenios_ano         ON public.sisi_convenios(ano);

-- ── View de cruzamento CNPJ × emendas parlamentares ───────────────────────
CREATE OR REPLACE VIEW public.vw_sisi_cnpj_emendas AS
SELECT
  cpf_cnpj,
  nome_razao_social,
  entidade,
  departamento,
  COUNT(*)                                     AS qtd_contratos,
  SUM(
    REPLACE(REPLACE(valor_contrato, '.', ''), ',', '.')::NUMERIC
  )                                            AS valor_total_contratos
FROM public.sisi_contratos
WHERE cpf_cnpj IS NOT NULL
  AND cpf_cnpj NOT IN ('', '-')
GROUP BY cpf_cnpj, nome_razao_social, entidade, departamento;

COMMENT ON VIEW public.vw_sisi_cnpj_emendas IS
  'Fornecedores SESI/SENAI agrupados por CNPJ — base para cruzamento com emendas parlamentares e doações TSE.';
