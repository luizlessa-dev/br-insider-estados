-- The BR Insider — SENAR (Serviço Nacional de Aprendizagem Rural)
-- Fonte: app3.cna.org.br/transparencia — CSV público (sem autenticação)
-- Cobertura: SENAR nacional (dados não segmentados por AR estadual no portal)
-- Períodos: trimestrais (ex: 2025-1517); licitações por ano civil

-- ── Contratos ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.senar_contratos (
  id                    BIGSERIAL PRIMARY KEY,
  periodo_id            TEXT        NOT NULL,  -- ex: 2025-1517 (código trimestral do portal)
  numero_contrato       TEXT        NOT NULL,
  modalidade_licitacao  TEXT,
  natureza_objeto       TEXT,
  descricao_objeto      TEXT,
  categoria_objeto      TEXT,
  criterio_julgamento   TEXT,
  nome_contratada       TEXT,
  cnpj                  TEXT,
  cpf                   TEXT,
  data_contrato         TEXT,
  valor_contrato        TEXT,
  valor_pago            TEXT,
  vigencia_meses        TEXT,
  valor_aditivo_preco   TEXT,
  valor_aditivo_prazo   TEXT,
  obs                   TEXT,
  data_ingestao         DATE        NOT NULL DEFAULT CURRENT_DATE,
  UNIQUE (periodo_id, numero_contrato)
);

COMMENT ON TABLE public.senar_contratos IS
  'Contratos SENAR nacional por período trimestral. '
  'Fonte: app3.cna.org.br/transparencia/?gestaoContratosCsv-SENAR-{periodo_id}';

CREATE INDEX IF NOT EXISTS idx_senar_contratos_periodo ON public.senar_contratos(periodo_id);
CREATE INDEX IF NOT EXISTS idx_senar_contratos_cnpj    ON public.senar_contratos(cnpj);

-- ── Licitações ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.senar_licitacoes (
  id                      BIGSERIAL PRIMARY KEY,
  ano                     SMALLINT    NOT NULL,
  modalidade              TEXT,
  numero_ano              TEXT        NOT NULL,  -- ex: 001/2025
  processo                TEXT,
  descricao_objeto        TEXT,
  natureza_objeto         TEXT,
  data_abertura           TEXT,
  criterio_julgamento     TEXT,
  data_homologacao        TEXT,
  resultado_certame       TEXT,
  licitantes_propostas    TEXT,       -- campo livre com pipe-delimited
  situacao                TEXT,
  data_ingestao           DATE        NOT NULL DEFAULT CURRENT_DATE,
  UNIQUE (ano, numero_ano)
);

COMMENT ON TABLE public.senar_licitacoes IS
  'Licitações SENAR nacional por ano civil. '
  'Fonte: app3.cna.org.br/transparencia/?gestaoLicitacaoCsv-SENAR-{ano}';

CREATE INDEX IF NOT EXISTS idx_senar_licitacoes_ano  ON public.senar_licitacoes(ano);

-- ── Transferências de Recursos ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.senar_transferencias (
  id                      BIGSERIAL PRIMARY KEY,
  periodo_id              TEXT        NOT NULL,
  tipo                    TEXT,       -- TRANSFERÊNCIAS PARA FEDERAÇÕES | OUTROS CONVÊNIOS
  instrumento             TEXT,       -- ano referência
  tipo_transferencia      TEXT,
  nome_beneficiario       TEXT,
  cnpj                    TEXT,
  descricao_objeto        TEXT,
  data_firmamento         TEXT,
  qtde_parcelas_total     TEXT,
  qtde_parcelas_trans     TEXT,
  valor_pactuado          TEXT,
  valor_transferido       TEXT,
  prestacao_contas        TEXT,
  data_ingestao           DATE        NOT NULL DEFAULT CURRENT_DATE,
  UNIQUE (periodo_id, tipo, cnpj, data_firmamento, valor_pactuado)
);

COMMENT ON TABLE public.senar_transferencias IS
  'Transferências de recursos SENAR — federações e convênios. Sufixo -9 (união completa). '
  'Fonte: app3.cna.org.br/transparencia/?gestaoTransferenciaRecursosCsv-SENAR-{periodo_id}-9';

CREATE INDEX IF NOT EXISTS idx_senar_trans_periodo ON public.senar_transferencias(periodo_id);
CREATE INDEX IF NOT EXISTS idx_senar_trans_cnpj    ON public.senar_transferencias(cnpj);

-- ── View CNPJ × emendas parlamentares ─────────────────────────────────────
CREATE OR REPLACE VIEW public.vw_senar_cnpj_emendas AS
SELECT
  COALESCE(c.cnpj, t.cnpj)          AS cnpj,
  COALESCE(c.nome_contratada, t.nome_beneficiario) AS nome,
  COUNT(DISTINCT c.id)               AS qtd_contratos,
  COUNT(DISTINCT t.id)               AS qtd_transferencias,
  SUM(
    REPLACE(REPLACE(c.valor_contrato, '.', ''), ',', '.')::NUMERIC
  )                                  AS valor_total_contratos,
  SUM(
    REPLACE(REPLACE(t.valor_transferido, '.', ''), ',', '.')::NUMERIC
  )                                  AS valor_total_transferencias
FROM public.senar_contratos c
FULL OUTER JOIN public.senar_transferencias t
  ON c.cnpj = t.cnpj
WHERE COALESCE(c.cnpj, t.cnpj) IS NOT NULL
  AND COALESCE(c.cnpj, t.cnpj) NOT IN ('', '-')
GROUP BY COALESCE(c.cnpj, t.cnpj), COALESCE(c.nome_contratada, t.nome_beneficiario);

COMMENT ON VIEW public.vw_senar_cnpj_emendas IS
  'Fornecedores e beneficiários SENAR agrupados por CNPJ — base para cruzamento com emendas e doações TSE.';
