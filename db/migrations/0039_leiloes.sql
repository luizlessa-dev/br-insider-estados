-- The BR Insider — Leilões Judiciais e Extrajudiciais
-- Fonte A: DataJud/CNJ — processos de execução (API pública, sem partes/CNPJ)
-- Fonte B: Receita Federal — leiloeiros credenciados CNAE 8299-7/04
-- Nota: a API pública DataJud não expõe o campo `partes` (CPF/CNPJ mascarado).
--       Cruzamento com emendas/TSE é feito via leiloeiro (CNPJ) ou futuro PUBLICJUD.

-- ── Processos de execução (DataJud) ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.leiloes_processos (
  id                       BIGSERIAL    PRIMARY KEY,
  numero_processo          TEXT         NOT NULL,
  tribunal                 VARCHAR(12)  NOT NULL,
  grau                     VARCHAR(10),
  classe_codigo            INTEGER,
  classe_nome              TEXT,
  assuntos                 JSONB,
  orgao_julgador_codigo    INTEGER,
  orgao_julgador_nome      TEXT,
  municipio_ibge           INTEGER,
  movimentos               JSONB,         -- array completo p/ análise futura dos códigos TPU
  data_ajuizamento         TIMESTAMPTZ,
  data_ultima_atualizacao  TIMESTAMPTZ,
  data_ingestao            DATE         NOT NULL DEFAULT CURRENT_DATE,
  UNIQUE (numero_processo, tribunal)
);

COMMENT ON TABLE public.leiloes_processos IS
  'Processos de execução fiscal e de título extrajudicial — DataJud/CNJ. '
  'Classes: 159 (Exec. Título Extraj.), 1116 (Exec. Fiscal), 1028 (Exec. Cível), '
  '154 (Cumprimento de Sentença). '
  'LIMITAÇÃO: campo partes (CPF/CNPJ) não disponível na API pública CNJ. '
  'Atualização: mensal (cron dia 5, 02h UTC).';

CREATE INDEX IF NOT EXISTS idx_leiloes_proc_tribunal  ON public.leiloes_processos(tribunal);
CREATE INDEX IF NOT EXISTS idx_leiloes_proc_classe     ON public.leiloes_processos(classe_codigo);
CREATE INDEX IF NOT EXISTS idx_leiloes_proc_municipio  ON public.leiloes_processos(municipio_ibge);
CREATE INDEX IF NOT EXISTS idx_leiloes_proc_dt_upd     ON public.leiloes_processos(data_ultima_atualizacao);
CREATE INDEX IF NOT EXISTS idx_leiloes_proc_ajuiz      ON public.leiloes_processos(data_ajuizamento);

-- ── Leiloeiros credenciados (Receita Federal) ──────────────────────────────
CREATE TABLE IF NOT EXISTS public.leiloes_leiloeiros (
  id                         BIGSERIAL    PRIMARY KEY,
  cnpj_basico                CHAR(8)      NOT NULL,
  cnpj_ordem                 CHAR(4)      NOT NULL,
  cnpj_dv                    CHAR(2)      NOT NULL,
  cnpj_completo              CHAR(14)     GENERATED ALWAYS AS (cnpj_basico || cnpj_ordem || cnpj_dv) STORED,
  razao_social               TEXT,
  nome_fantasia              TEXT,
  situacao_cadastral         SMALLINT,    -- 1=Nula, 2=Ativa, 3=Suspensa, 4=Inapta, 8=Baixada
  data_situacao_cadastral    DATE,
  data_inicio_atividade      DATE,
  cnae_fiscal                VARCHAR(10),
  identificador_matriz_filial SMALLINT,   -- 1=MATRIZ, 2=FILIAL
  tipo_logradouro            TEXT,
  logradouro                 TEXT,
  numero                     TEXT,
  complemento                TEXT,
  bairro                     TEXT,
  cep                        TEXT,
  uf                         CHAR(2),
  municipio_codigo           INTEGER,
  ddd1                       VARCHAR(4),
  telefone1                  VARCHAR(15),
  correio_eletronico         TEXT,
  data_ingestao              DATE         NOT NULL DEFAULT CURRENT_DATE,
  UNIQUE (cnpj_basico, cnpj_ordem, cnpj_dv)
);

COMMENT ON TABLE public.leiloes_leiloeiros IS
  'Leiloeiros independentes credenciados — CNAE 8299-7/04 (código RFB: 8299704). '
  'Fonte: Receita Federal dadosabertos.rfb.gov.br/CNPJ/ (Estabelecimentos + Empresas). '
  'Cruzamento direto com emendas_favorecidos e tse_receitas via cnpj_completo. '
  'Atualização: mensal (cron dia 5, 02h UTC).';

CREATE INDEX IF NOT EXISTS idx_leiloes_leilo_uf       ON public.leiloes_leiloeiros(uf);
CREATE INDEX IF NOT EXISTS idx_leiloes_leilo_situacao  ON public.leiloes_leiloeiros(situacao_cadastral);
CREATE INDEX IF NOT EXISTS idx_leiloes_leilo_cnpj      ON public.leiloes_leiloeiros(cnpj_completo);
CREATE INDEX IF NOT EXISTS idx_leiloes_leilo_municipio ON public.leiloes_leiloeiros(municipio_codigo);
