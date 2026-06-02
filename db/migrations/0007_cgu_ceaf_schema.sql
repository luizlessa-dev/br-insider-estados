-- The Brasilia Insider — CEAF (Cadastro de Expulsões da Administração Federal)
-- Fonte: API REST do Portal da Transparência
--   GET https://api.portaldatransparencia.gov.br/api-de-dados/ceaf
--   Chave: header "chave-api-dados" (registrar em portaldatransparencia.gov.br/api-de-dados/cadastrar-email)
-- Cobertura: desde 2003. Atualizado conforme novas portarias no DOU.
--
-- Prefixo: ceaf_*
--
-- CRUZAMENTO PRIMÁRIO COM CGU-PAD:
--   ceaf_expulsoes.numero_processo ↔ cgu_pad_processos.numero_processo
--   → traz NOME e CPF para processos que o CGU-PAD não individualiza.
--
-- Outros cruzamentos:
--   cpf_punido × emendas_favorecidos (pessoa física)
--   orgao_nome  × cgu_pad_processos.entidade
--   orgao_nome  × siafi_fornecedor

-- ═══════════════════════════════════════════════════════════════════════════
-- FATO: Expulsão individual
-- ═══════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.ceaf_expulsoes (
  id                  INTEGER     PRIMARY KEY,    -- id da API

  -- Datas
  data_publicacao     DATE,                       -- publicação no DOU
  data_referencia     DATE,                       -- data da portaria

  -- Punido
  cpf_punido          TEXT,                       -- cpfPunidoFormatado (mascarado: ***XXX***)
  nome_punido         TEXT,                       -- nomePunido
  tipo_punicao        TEXT,                       -- "Demissão", "Cassação de Aposentadoria", etc.

  -- Cargo
  cargo_efetivo       TEXT,
  cargo_comissao      TEXT,

  -- Órgão
  orgao_sigla         TEXT,
  orgao_pasta_sigla   TEXT,                       -- ministério supervisor
  orgao_nome          TEXT,
  uf_lotacao          CHAR(2),

  -- Processo / DOU
  portaria            TEXT,
  numero_processo     TEXT,                       -- JOIN com cgu_pad_processos
  pagina_dou          TEXT,
  secao_dou           TEXT,

  -- Fundamentos legais (array de descricao)
  fundamentacao       TEXT[],

  ingested_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ceaf_nome
  ON public.ceaf_expulsoes
  USING gin (to_tsvector('portuguese', coalesce(nome_punido, '')));

CREATE INDEX IF NOT EXISTS idx_ceaf_orgao
  ON public.ceaf_expulsoes(orgao_nome);

CREATE INDEX IF NOT EXISTS idx_ceaf_data_pub
  ON public.ceaf_expulsoes(data_publicacao DESC NULLS LAST);

CREATE INDEX IF NOT EXISTS idx_ceaf_tipo
  ON public.ceaf_expulsoes(tipo_punicao);

CREATE INDEX IF NOT EXISTS idx_ceaf_processo
  ON public.ceaf_expulsoes(numero_processo)
  WHERE numero_processo IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_ceaf_uf
  ON public.ceaf_expulsoes(uf_lotacao);

COMMENT ON TABLE public.ceaf_expulsoes IS
  'Cadastro de Expulsões da Administração Federal. '
  'Uma linha por expulsão individual. '
  'numero_processo faz JOIN com cgu_pad_processos para cruzar processo ↔ nome.';

-- ═══════════════════════════════════════════════════════════════════════════
-- LOG de ingestão
-- ═══════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.ceaf_ingest_log (
  id              BIGSERIAL   PRIMARY KEY,
  started_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  finished_at     TIMESTAMPTZ,
  status          TEXT        NOT NULL DEFAULT 'running',
  n_processados   INTEGER,
  n_paginas       INTEGER,
  erro            TEXT
);

-- ═══════════════════════════════════════════════════════════════════════════
-- VIEWS ANALÍTICAS
-- ═══════════════════════════════════════════════════════════════════════════

-- Ranking de órgãos por expulsões individuais (com nome do servidor)
CREATE OR REPLACE VIEW public.ceaf_ranking_orgaos AS
SELECT
  orgao_nome,
  orgao_pasta_sigla                               AS pasta,
  uf_lotacao,
  COUNT(*)                                        AS total_expulsoes,
  COUNT(*) FILTER (WHERE tipo_punicao ILIKE '%demiss%')
                                                  AS demissoes,
  COUNT(*) FILTER (WHERE tipo_punicao ILIKE '%cassacao%' OR tipo_punicao ILIKE '%cassação%')
                                                  AS cassacoes_aposentadoria,
  MIN(data_publicacao)                            AS primeira_expulsao,
  MAX(data_publicacao)                            AS ultima_expulsao
FROM public.ceaf_expulsoes
GROUP BY orgao_nome, orgao_pasta_sigla, uf_lotacao
ORDER BY total_expulsoes DESC NULLS LAST;

-- JOIN OURO: expulsão individual + processo disciplinar
-- Traz nome do servidor para os processos do CGU-PAD
CREATE OR REPLACE VIEW public.ceaf_x_cgu_pad AS
SELECT
  e.id                                            AS ceaf_id,
  e.nome_punido,
  e.cpf_punido,
  e.tipo_punicao,
  e.cargo_efetivo,
  e.orgao_nome,
  e.uf_lotacao,
  e.data_publicacao,
  e.portaria,
  e.numero_processo,
  p.tipo_processo,
  p.assuntos                                      AS assuntos_pad,
  p.n_investigados,
  p.n_expulsivas                                  AS total_expulsivas_processo,
  p.data_instauracao,
  p.fase_atual
FROM public.ceaf_expulsoes e
LEFT JOIN public.cgu_pad_processos p
  ON e.numero_processo = p.numero_processo
WHERE e.numero_processo IS NOT NULL;

COMMENT ON VIEW public.ceaf_x_cgu_pad IS
  'JOIN entre CEAF (nome/CPF do expulso) e CGU-PAD (assunto/tipo do processo). '
  'Base principal para pautas: quem foi demitido, de onde, por quê.';

-- Série temporal anual de expulsões
CREATE OR REPLACE VIEW public.ceaf_serie_temporal AS
SELECT
  EXTRACT(YEAR FROM data_publicacao)::INTEGER     AS ano,
  tipo_punicao,
  COUNT(*)                                        AS n_expulsoes,
  COUNT(DISTINCT orgao_nome)                      AS n_orgaos
FROM public.ceaf_expulsoes
WHERE data_publicacao IS NOT NULL
GROUP BY ano, tipo_punicao
ORDER BY ano DESC;

-- ═══════════════════════════════════════════════════════════════════════════
-- RLS
-- ═══════════════════════════════════════════════════════════════════════════
ALTER TABLE public.ceaf_expulsoes    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ceaf_ingest_log   ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE tbl TEXT;
BEGIN
  FOR tbl IN SELECT unnest(ARRAY['ceaf_expulsoes','ceaf_ingest_log'])
  LOOP
    EXECUTE format(
      'DROP POLICY IF EXISTS %I ON public.%I; '
      'CREATE POLICY %I ON public.%I FOR SELECT USING (true);',
      'public_read_' || tbl, tbl, 'public_read_' || tbl, tbl
    );
  END LOOP;
END $$;
