-- The Brasilia Insider — schema canônico SIAFI (execução orçamentária federal).
-- Cobre dois streams complementares da CGU Portal da Transparência:
--   A. Execução mensal agregada (siafi_execucao_mensal)
--   B. Snapshot diário operacional (empenho, item, liquidação, pagamento, junction, favorecidos)
--
-- Prefixo `siafi_` — namespacing pra não colidir com:
--   - public.ale_*       (atividade legislativa estadual — migration 0001)
--   - public.almg_*      (verba indenizatória ALMG — pipeline TS legado)
--   - public.parlamentares, public.proposicoes (federal — pipeline TS legado)
--   - public.emendas_pix (já existente no schema federal)
--
-- Bronze: Parquet em R2/local (ingestao/lake/siafi/).
-- Silver: este schema. Carga via UPSERT idempotente pela PK natural da fonte.
-- Gold: views/MVs temáticas (futura migration 0004).
--
-- RLS: leitura pública (dado público), escrita só service_role (ingester).
-- Encoding silver: tudo em UTF-8. Valores monetários em NUMERIC(20,2).

-- ═════════════════════════════════════════════════════════════════════════
-- DIMENSÃO: Fornecedor (CNPJ/CPF/código especial SIAFI)
-- ═════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.siafi_fornecedor (
  cnpj_cpf            TEXT PRIMARY KEY,           -- pode ser CNPJ, CPF, ou código SIAFI especial (ex: "170500")
  nome                TEXT NOT NULL,
  tipo_pessoa         TEXT NOT NULL CHECK (tipo_pessoa IN ('PJ', 'PF', 'EXTERIOR', 'ESPECIAL')),
  -- Métricas agregadas (atualizadas por job nightly em F4)
  n_empenhos          INTEGER NOT NULL DEFAULT 0,
  n_pagamentos        INTEGER NOT NULL DEFAULT 0,
  valor_total_empenhado_brl  NUMERIC(20,2) NOT NULL DEFAULT 0,
  valor_total_pago_brl       NUMERIC(20,2) NOT NULL DEFAULT 0,
  primeira_aparicao   DATE,
  ultima_aparicao     DATE,
  -- Enriquecimento futuro (Receita Federal, CADIN, etc.)
  enriquecimento      JSONB,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_siafi_fornecedor_nome ON public.siafi_fornecedor USING gin (to_tsvector('portuguese', nome));
CREATE INDEX IF NOT EXISTS idx_siafi_fornecedor_tipo ON public.siafi_fornecedor(tipo_pessoa);

COMMENT ON TABLE public.siafi_fornecedor IS
  'Dim normalizada de favorecidos do SIAFI. cnpj_cpf pode ser código SIAFI especial '
  '(ex: "170500" = COORDENACAO-GERAL DE TESOURARIA). tipo_pessoa classifica origem.';


-- ═════════════════════════════════════════════════════════════════════════
-- STREAM A — Execução mensal agregada
-- Fonte: /despesas-execucao/{YYYYMM}/
-- Granularidade: linha por (competência × UG × programa × ação × elemento × emenda × subtítulo)
-- ═════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.siafi_execucao_mensal (
  -- PK natural (composta)
  competencia                 TEXT NOT NULL,            -- "2025/04" (formato origem)
  cod_ug                      TEXT NOT NULL,
  cod_programa_orcamentario   TEXT NOT NULL,
  cod_acao                    TEXT NOT NULL,
  cod_plano_orcamentario      TEXT NOT NULL,
  cod_elemento_despesa        TEXT NOT NULL,
  cod_modalidade_despesa      TEXT NOT NULL,
  cod_autor_emenda            TEXT NOT NULL,
  cod_subtitulo               TEXT NOT NULL,
  -- Dimensões nomeadas (denormalizadas — origem já entrega assim)
  nome_orgao_superior         TEXT,
  cod_orgao_superior          TEXT,
  nome_orgao_subordinado      TEXT,
  cod_orgao_subordinado       TEXT,
  nome_ug                     TEXT,
  cod_gestao                  TEXT,
  nome_gestao                 TEXT,
  cod_unidade_orcamentaria    TEXT,
  nome_unidade_orcamentaria   TEXT,
  cod_funcao                  TEXT,
  nome_funcao                 TEXT,
  cod_subfuncao               TEXT,
  nome_subfuncao              TEXT,
  nome_programa_orcamentario  TEXT,
  nome_acao                   TEXT,
  plano_orcamentario          TEXT,
  cod_programa_governo        TEXT,
  nome_programa_governo       TEXT,
  uf                          TEXT,
  municipio                   TEXT,
  nome_subtitulo              TEXT,
  cod_localizador             TEXT,
  nome_localizador            TEXT,
  sigla_localizador           TEXT,
  descricao_complementar_localizador  TEXT,
  nome_autor_emenda           TEXT,
  cod_categoria_economica     TEXT,
  nome_categoria_economica    TEXT,
  cod_grupo_despesa           TEXT,
  nome_grupo_despesa          TEXT,
  nome_elemento_despesa       TEXT,
  modalidade_despesa          TEXT,
  -- Métricas (NUMERIC ao invés de DOUBLE pra preservar centavos)
  valor_empenhado             NUMERIC(20,2) NOT NULL DEFAULT 0,
  valor_liquidado             NUMERIC(20,2) NOT NULL DEFAULT 0,
  valor_pago                  NUMERIC(20,2) NOT NULL DEFAULT 0,
  valor_restos_pagar_inscritos NUMERIC(20,2) NOT NULL DEFAULT 0,
  valor_restos_pagar_cancelado NUMERIC(20,2) NOT NULL DEFAULT 0,
  valor_restos_pagar_pagos    NUMERIC(20,2) NOT NULL DEFAULT 0,
  -- Auditoria
  source_last_modified        TIMESTAMPTZ,
  ingested_at                 TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (competencia, cod_ug, cod_programa_orcamentario, cod_acao,
               cod_plano_orcamentario, cod_elemento_despesa, cod_modalidade_despesa,
               cod_autor_emenda, cod_subtitulo)
);
CREATE INDEX IF NOT EXISTS idx_siafi_exec_competencia ON public.siafi_execucao_mensal(competencia);
CREATE INDEX IF NOT EXISTS idx_siafi_exec_orgao_sup ON public.siafi_execucao_mensal(cod_orgao_superior);
CREATE INDEX IF NOT EXISTS idx_siafi_exec_autor_emenda ON public.siafi_execucao_mensal(cod_autor_emenda) WHERE cod_autor_emenda <> '-1';
CREATE INDEX IF NOT EXISTS idx_siafi_exec_programa ON public.siafi_execucao_mensal(cod_programa_orcamentario);

COMMENT ON TABLE public.siafi_execucao_mensal IS
  'Stream A — execução orçamentária agregada por mês. Substitui a UI lenta '
  'do Portal da Transparência em consultas de séries temporais longas.';


-- ═════════════════════════════════════════════════════════════════════════
-- STREAM B — Empenho (snapshot do estado vigente no snapshot_date)
-- Fonte: /despesas/{YYYYMMDD}/_Despesas_Empenho.csv
-- ═════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.siafi_empenho (
  id_empenho              TEXT PRIMARY KEY,        -- ID canônico do portal (ex: "564324296")
  codigo_empenho          TEXT NOT NULL,           -- "257001000012025NE447249"
  codigo_empenho_resumido TEXT,                    -- "2025NE447249"
  snapshot_date           DATE NOT NULL,           -- data do ZIP de origem
  data_emissao            DATE,
  cod_tipo_documento      TEXT,
  tipo_documento          TEXT,
  tipo_empenho            TEXT,
  especie_empenho         TEXT,
  cod_orgao_superior      TEXT,
  nome_orgao_superior     TEXT,
  cod_orgao               TEXT,
  nome_orgao              TEXT,
  cod_ug                  TEXT,
  nome_ug                 TEXT,
  cod_gestao              TEXT,
  nome_gestao             TEXT,
  cnpj_favorecido         TEXT REFERENCES public.siafi_fornecedor(cnpj_cpf) DEFERRABLE INITIALLY DEFERRED,
  nome_favorecido         TEXT,
  observacao              TEXT,                    -- texto livre, RICO pra reportagem
  cod_esfera_orcamentaria TEXT,
  esfera_orcamentaria     TEXT,
  cod_tipo_credito        TEXT,
  tipo_credito            TEXT,
  cod_grupo_fonte_recurso TEXT,
  nome_grupo_fonte_recurso TEXT,
  cod_fonte_recurso       TEXT,
  nome_fonte_recurso      TEXT,
  cod_unidade_orcamentaria TEXT,
  nome_unidade_orcamentaria TEXT,
  cod_funcao              TEXT,
  nome_funcao             TEXT,
  cod_subfuncao           TEXT,
  nome_subfuncao          TEXT,
  cod_programa            TEXT,
  nome_programa           TEXT,
  cod_acao                TEXT,
  nome_acao               TEXT,
  linguagem_cidada        TEXT,
  cod_subtitulo           TEXT,
  nome_subtitulo          TEXT,
  cod_plano_orcamentario  TEXT,
  plano_orcamentario      TEXT,
  cod_programa_governo    TEXT,
  nome_programa_governo   TEXT,
  autor_emenda            TEXT,                    -- texto livre, ex: "BANCADA DO ACRE / EMENDA 11"
  cod_categoria_despesa   TEXT,
  categoria_despesa       TEXT,
  cod_grupo_despesa       TEXT,
  grupo_despesa           TEXT,
  cod_modalidade_aplicacao TEXT,
  modalidade_aplicacao    TEXT,
  cod_elemento_despesa    TEXT,
  elemento_despesa        TEXT,
  processo                TEXT,
  modalidade_licitacao    TEXT,
  inciso                  TEXT,
  amparo                  TEXT,
  ref_dispensa_inexigibilidade TEXT,
  cod_convenio            TEXT,
  contrato_repasse        TEXT,
  valor_original_empenho  NUMERIC(20,2),
  valor_empenho_brl       NUMERIC(20,2),
  valor_utilizado_conversao NUMERIC(20,8),
  source_last_modified    TIMESTAMPTZ,
  ingested_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_siafi_empenho_codigo ON public.siafi_empenho(codigo_empenho);
CREATE INDEX IF NOT EXISTS idx_siafi_empenho_snapshot ON public.siafi_empenho(snapshot_date);
CREATE INDEX IF NOT EXISTS idx_siafi_empenho_data_emissao ON public.siafi_empenho(data_emissao);
CREATE INDEX IF NOT EXISTS idx_siafi_empenho_favorecido ON public.siafi_empenho(cnpj_favorecido);
CREATE INDEX IF NOT EXISTS idx_siafi_empenho_orgao_sup ON public.siafi_empenho(cod_orgao_superior);
CREATE INDEX IF NOT EXISTS idx_siafi_empenho_autor_emenda ON public.siafi_empenho(autor_emenda) WHERE autor_emenda <> 'SEM EMENDA';
CREATE INDEX IF NOT EXISTS idx_siafi_empenho_convenio ON public.siafi_empenho(cod_convenio) WHERE cod_convenio NOT IN ('', '-1', 'NAO SE APLICA');
CREATE INDEX IF NOT EXISTS idx_siafi_empenho_observacao_tsv ON public.siafi_empenho USING gin (to_tsvector('portuguese', coalesce(observacao, '')));

COMMENT ON TABLE public.siafi_empenho IS
  'Stream B — cabeçalho do empenho (estado vigente no snapshot_date). '
  'Texto livre em `observacao` permite busca full-text por descrição da despesa.';


-- ═════════════════════════════════════════════════════════════════════════
-- STREAM B — Item Empenho
-- ═════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.siafi_item_empenho (
  id_empenho              TEXT NOT NULL REFERENCES public.siafi_empenho(id_empenho) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
  sequencial              TEXT NOT NULL,
  codigo_empenho          TEXT,
  cod_categoria_despesa   TEXT,
  categoria_despesa       TEXT,
  cod_grupo_despesa       TEXT,
  grupo_despesa           TEXT,
  cod_modalidade_aplicacao TEXT,
  modalidade_aplicacao    TEXT,
  cod_elemento_despesa    TEXT,
  elemento_despesa        TEXT,
  cod_subelemento_despesa TEXT,
  subelemento_despesa     TEXT,
  descricao               TEXT,
  quantidade              NUMERIC(20,4),
  valor_unitario          NUMERIC(20,4),
  valor_total             NUMERIC(20,2),
  valor_atual             NUMERIC(20,2),
  snapshot_date           DATE NOT NULL,
  source_last_modified    TIMESTAMPTZ,
  ingested_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (id_empenho, sequencial)
);
CREATE INDEX IF NOT EXISTS idx_siafi_item_subelem ON public.siafi_item_empenho(cod_subelemento_despesa);
CREATE INDEX IF NOT EXISTS idx_siafi_item_descricao_tsv ON public.siafi_item_empenho USING gin (to_tsvector('portuguese', coalesce(descricao, '')));


-- ═════════════════════════════════════════════════════════════════════════
-- STREAM B — Liquidação
-- ═════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.siafi_liquidacao (
  codigo_liquidacao       TEXT PRIMARY KEY,
  codigo_liquidacao_resumido TEXT,
  snapshot_date           DATE NOT NULL,
  data_emissao            DATE,
  cod_tipo_documento      TEXT,
  tipo_documento          TEXT,
  cod_orgao_superior      TEXT,
  nome_orgao_superior     TEXT,
  cod_orgao               TEXT,
  nome_orgao              TEXT,
  cod_ug                  TEXT,
  nome_ug                 TEXT,
  cod_gestao              TEXT,
  nome_gestao             TEXT,
  cnpj_favorecido         TEXT REFERENCES public.siafi_fornecedor(cnpj_cpf) DEFERRABLE INITIALLY DEFERRED,
  nome_favorecido         TEXT,
  observacao              TEXT,
  cod_categoria_despesa   TEXT,
  categoria_despesa       TEXT,
  cod_grupo_despesa       TEXT,
  grupo_despesa           TEXT,
  cod_modalidade_aplicacao TEXT,
  modalidade_aplicacao    TEXT,
  cod_elemento_despesa    TEXT,
  elemento_despesa        TEXT,
  cod_plano_orcamentario  TEXT,
  plano_orcamentario      TEXT,
  cod_programa_governo    TEXT,
  nome_programa_governo   TEXT,
  source_last_modified    TIMESTAMPTZ,
  ingested_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_siafi_liq_snapshot ON public.siafi_liquidacao(snapshot_date);
CREATE INDEX IF NOT EXISTS idx_siafi_liq_data_emissao ON public.siafi_liquidacao(data_emissao);
CREATE INDEX IF NOT EXISTS idx_siafi_liq_favorecido ON public.siafi_liquidacao(cnpj_favorecido);


-- ═════════════════════════════════════════════════════════════════════════
-- STREAM B — Pagamento
-- ═════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.siafi_pagamento (
  codigo_pagamento        TEXT PRIMARY KEY,
  codigo_pagamento_resumido TEXT,
  snapshot_date           DATE NOT NULL,
  data_emissao            DATE,
  cod_tipo_documento      TEXT,
  tipo_documento          TEXT,
  tipo_ob                 TEXT,
  extra_orcamentario      TEXT,
  cod_orgao_superior      TEXT,
  nome_orgao_superior     TEXT,
  cod_orgao               TEXT,
  nome_orgao              TEXT,
  cod_ug                  TEXT,
  nome_ug                 TEXT,
  cod_gestao              TEXT,
  nome_gestao             TEXT,
  cnpj_favorecido         TEXT REFERENCES public.siafi_fornecedor(cnpj_cpf) DEFERRABLE INITIALLY DEFERRED,
  nome_favorecido         TEXT,
  observacao              TEXT,
  processo                TEXT,
  cod_categoria_despesa   TEXT,
  categoria_despesa       TEXT,
  cod_grupo_despesa       TEXT,
  grupo_despesa           TEXT,
  cod_modalidade_aplicacao TEXT,
  modalidade_aplicacao    TEXT,
  cod_elemento_despesa    TEXT,
  elemento_despesa        TEXT,
  cod_plano_orcamentario  TEXT,
  plano_orcamentario      TEXT,
  cod_programa_governo    TEXT,
  nome_programa_governo   TEXT,
  valor_original_pagamento NUMERIC(20,2),
  valor_pagamento_brl     NUMERIC(20,2),
  valor_utilizado_conversao NUMERIC(20,8),
  source_last_modified    TIMESTAMPTZ,
  ingested_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_siafi_pag_snapshot ON public.siafi_pagamento(snapshot_date);
CREATE INDEX IF NOT EXISTS idx_siafi_pag_data_emissao ON public.siafi_pagamento(data_emissao);
CREATE INDEX IF NOT EXISTS idx_siafi_pag_favorecido ON public.siafi_pagamento(cnpj_favorecido);
CREATE INDEX IF NOT EXISTS idx_siafi_pag_orgao_sup ON public.siafi_pagamento(cod_orgao_superior);


-- ═════════════════════════════════════════════════════════════════════════
-- STREAM B — Junction Pagamento × Empenho (N:N)
-- ═════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.siafi_pagamento_empenho (
  codigo_pagamento        TEXT NOT NULL,
  codigo_empenho          TEXT NOT NULL,
  subitem                 TEXT NOT NULL,
  cod_natureza_despesa    TEXT,
  valor_pago              NUMERIC(20,2),
  valor_restos_pagar_inscritos NUMERIC(20,2),
  valor_restos_pagar_cancelado NUMERIC(20,2),
  valor_restos_pagar_pagos     NUMERIC(20,2),
  snapshot_date           DATE NOT NULL,
  source_last_modified    TIMESTAMPTZ,
  ingested_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (codigo_pagamento, codigo_empenho, subitem)
);
CREATE INDEX IF NOT EXISTS idx_siafi_pe_pagamento ON public.siafi_pagamento_empenho(codigo_pagamento);
CREATE INDEX IF NOT EXISTS idx_siafi_pe_empenho ON public.siafi_pagamento_empenho(codigo_empenho);

COMMENT ON TABLE public.siafi_pagamento_empenho IS
  'Junction N:N — uma OB pode impactar múltiplos empenhos e vice-versa. '
  'Tabela essencial pra rastrear "dinheiro saiu daqui pra ali" entre orçamento e caixa.';


-- ═════════════════════════════════════════════════════════════════════════
-- STREAM B — Favorecido final (quando pagamento vai pra lista, ex: folha)
-- ═════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.siafi_pagamento_favorecido_final (
  codigo_pagamento        TEXT NOT NULL,
  codigo_lista            TEXT NOT NULL,
  cnpj_favorecido_final   TEXT NOT NULL REFERENCES public.siafi_fornecedor(cnpj_cpf) DEFERRABLE INITIALLY DEFERRED,
  nome_favorecido_final   TEXT,
  data_emissao            DATE,
  valor_pagamento_brl     NUMERIC(20,2),
  snapshot_date           DATE NOT NULL,
  source_last_modified    TIMESTAMPTZ,
  ingested_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (codigo_pagamento, codigo_lista, cnpj_favorecido_final)
);
CREATE INDEX IF NOT EXISTS idx_siafi_pff_pagamento ON public.siafi_pagamento_favorecido_final(codigo_pagamento);
CREATE INDEX IF NOT EXISTS idx_siafi_pff_favorecido ON public.siafi_pagamento_favorecido_final(cnpj_favorecido_final);

COMMENT ON TABLE public.siafi_pagamento_favorecido_final IS
  'Quando o pagamento vai pra uma LISTA (folha de pessoal, lista de '
  'precatórios), aqui ficam os favorecidos finais individualizados.';


-- ═════════════════════════════════════════════════════════════════════════
-- RLS — leitura pública (dado público), escrita só service_role
-- ═════════════════════════════════════════════════════════════════════════
ALTER TABLE public.siafi_fornecedor ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.siafi_execucao_mensal ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.siafi_empenho ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.siafi_item_empenho ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.siafi_liquidacao ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.siafi_pagamento ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.siafi_pagamento_empenho ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.siafi_pagamento_favorecido_final ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOR tbl IN
    SELECT unnest(ARRAY[
      'siafi_fornecedor','siafi_execucao_mensal','siafi_empenho','siafi_item_empenho',
      'siafi_liquidacao','siafi_pagamento','siafi_pagamento_empenho','siafi_pagamento_favorecido_final'
    ])
  LOOP
    EXECUTE format(
      'DROP POLICY IF EXISTS %I ON public.%I; '
      'CREATE POLICY %I ON public.%I FOR SELECT USING (true);',
      'public_read_' || tbl, tbl, 'public_read_' || tbl, tbl
    );
  END LOOP;
END $$;
