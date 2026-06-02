-- The Brasilia Insider — CGU-PAD (Processos Administrativos Disciplinares)
-- Fonte: https://dadosabertos-download.cgu.gov.br/CGUPAD/CGUPAD.csv
-- Atualização: mensal. ~90 mil processos desde 2005.
--
-- Prefixo `cgu_pad_` — sem colidir com:
--   ale_*         (atividade legislativa estadual)
--   siafi_*       (execução orçamentária)
--   emendas_*     (emendas parlamentares)
--   cota_*        (cota parlamentar federal)
--
-- Cruzamentos estratégicos possíveis:
--   entidade × siafi_fornecedor.nome  → órgão punido também concentra contratos
--   entidade × emendas_favorecidos    → beneficiário de emenda com histórico disciplinar
--   assuntos ILIKE '%licitação%'      → fraude em licitação por órgão/período
--
-- RLS: leitura pública, escrita service_role.

-- ═══════════════════════════════════════════════════════════════════════════
-- FATO: Processo disciplinar
-- ═══════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.cgu_pad_processos (
  numero_processo     TEXT        PRIMARY KEY,  -- NumeroPadPrincipal

  tipo_processo       TEXT,                     -- PAD, Sindicância, Rito Sumário, etc.
  assuntos            TEXT[],                   -- array parseado do campo Assuntos
  pasta               TEXT,                     -- ministério supervisor
  entidade            TEXT,                     -- órgão/autarquia onde ocorreu

  uf                  CHAR(2),
  cidade              TEXT,

  data_instauracao    DATE,
  fase_atual          TEXT,
  data_fase           DATE,

  n_investigados      SMALLINT    NOT NULL DEFAULT 0,
  n_advertencias      SMALLINT    NOT NULL DEFAULT 0,
  n_suspensoes        SMALLINT    NOT NULL DEFAULT 0,
  n_expulsivas        SMALLINT    NOT NULL DEFAULT 0,  -- demissões / cassações
  n_outras_sancoes    SMALLINT    NOT NULL DEFAULT 0,

  -- flag derivada — qualquer sanção expulsiva
  tem_expulsiva       BOOLEAN     GENERATED ALWAYS AS (n_expulsivas > 0) STORED,

  ingested_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Índices para filtros e full-text
CREATE INDEX IF NOT EXISTS idx_pad_tipo
  ON public.cgu_pad_processos(tipo_processo);

CREATE INDEX IF NOT EXISTS idx_pad_uf
  ON public.cgu_pad_processos(uf);

CREATE INDEX IF NOT EXISTS idx_pad_data_inst
  ON public.cgu_pad_processos(data_instauracao DESC NULLS LAST);

CREATE INDEX IF NOT EXISTS idx_pad_fase
  ON public.cgu_pad_processos(fase_atual);

CREATE INDEX IF NOT EXISTS idx_pad_expulsiva
  ON public.cgu_pad_processos(tem_expulsiva)
  WHERE tem_expulsiva = true;

CREATE INDEX IF NOT EXISTS idx_pad_entidade_tsvec
  ON public.cgu_pad_processos
  USING gin (to_tsvector('portuguese', coalesce(entidade, '') || ' ' || coalesce(pasta, '')));

CREATE INDEX IF NOT EXISTS idx_pad_assuntos
  ON public.cgu_pad_processos USING gin (assuntos);

COMMENT ON TABLE public.cgu_pad_processos IS
  'Processos Administrativos Disciplinares (CGU-PAD). '
  'Uma linha por processo. Campo assuntos é array parseado do CSV. '
  'Cruzar entidade com siafi_fornecedor e emendas_favorecidos para achados.';

-- ═══════════════════════════════════════════════════════════════════════════
-- LOG de ingestão
-- ═══════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.cgu_pad_ingest_log (
  id              BIGSERIAL   PRIMARY KEY,
  started_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  finished_at     TIMESTAMPTZ,
  status          TEXT        NOT NULL DEFAULT 'running',  -- running | ok | erro
  n_processados   INTEGER,
  n_novos         INTEGER,
  n_atualizados   INTEGER,
  erro            TEXT
);

-- ═══════════════════════════════════════════════════════════════════════════
-- VIEWS ANALÍTICAS
-- ═══════════════════════════════════════════════════════════════════════════

-- Ranking de órgãos por volume de processos e sanções expulsivas
CREATE OR REPLACE VIEW public.cgu_pad_ranking_orgaos AS
SELECT
  entidade,
  pasta                                           AS ministerio,
  uf,
  COUNT(*)                                        AS total_processos,
  SUM(n_investigados)                             AS total_investigados,
  SUM(n_expulsivas)                               AS total_expulsivas,
  SUM(n_suspensoes)                               AS total_suspensoes,
  SUM(n_advertencias)                             AS total_advertencias,
  ROUND(100.0 * SUM(n_expulsivas) / NULLIF(COUNT(*), 0), 1)
                                                  AS pct_expulsivas
FROM public.cgu_pad_processos
WHERE fase_atual = 'Processo Julgado'
GROUP BY entidade, pasta, uf
ORDER BY total_expulsivas DESC NULLS LAST;

COMMENT ON VIEW public.cgu_pad_ranking_orgaos IS
  'Ranking de órgãos por sanções expulsivas em processos julgados. '
  'Base para matéria "órgãos com maior taxa de demissão disciplinar".';

-- Série temporal anual de processos instaurados por tipo
CREATE OR REPLACE VIEW public.cgu_pad_serie_temporal AS
SELECT
  EXTRACT(YEAR FROM data_instauracao)::INTEGER    AS ano,
  tipo_processo,
  COUNT(*)                                        AS n_processos,
  SUM(n_expulsivas)                               AS n_expulsivas
FROM public.cgu_pad_processos
WHERE data_instauracao IS NOT NULL
GROUP BY ano, tipo_processo
ORDER BY ano DESC, n_processos DESC;

-- ═══════════════════════════════════════════════════════════════════════════
-- RLS
-- ═══════════════════════════════════════════════════════════════════════════
ALTER TABLE public.cgu_pad_processos    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cgu_pad_ingest_log   ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE tbl TEXT;
BEGIN
  FOR tbl IN SELECT unnest(ARRAY['cgu_pad_processos','cgu_pad_ingest_log'])
  LOOP
    EXECUTE format(
      'DROP POLICY IF EXISTS %I ON public.%I; '
      'CREATE POLICY %I ON public.%I FOR SELECT USING (true);',
      'public_read_' || tbl, tbl, 'public_read_' || tbl, tbl
    );
  END LOOP;
END $$;
