-- Migration: adapta tabela licitacoes para receber dados do PNCP
-- O Portal da Transparência usava id integer; o PNCP usa numeroControlePNCP (texto).
-- Estratégia: adicionar colunas PNCP sem quebrar o schema anterior.

ALTER TABLE public.licitacoes
    ADD COLUMN IF NOT EXISTS numero_controle_pncp text UNIQUE,
    ADD COLUMN IF NOT EXISTS cnpj_orgao            text,
    ADD COLUMN IF NOT EXISTS razao_social_orgao    text,
    ADD COLUMN IF NOT EXISTS esfera_orgao          text,      -- 'F'ederal 'E'stadual 'M'unicipal
    ADD COLUMN IF NOT EXISTS uf_unidade            text,
    ADD COLUMN IF NOT EXISTS municipio_unidade     text,
    ADD COLUMN IF NOT EXISTS ano_compra            integer,
    ADD COLUMN IF NOT EXISTS sequencial_compra     integer,
    ADD COLUMN IF NOT EXISTS valor_homologado      numeric(18,2),
    ADD COLUMN IF NOT EXISTS fonte                 text DEFAULT 'portal_tf';  -- 'pncp' | 'portal_tf'

CREATE INDEX IF NOT EXISTS licitacoes_pncp_idx   ON public.licitacoes (numero_controle_pncp);
CREATE INDEX IF NOT EXISTS licitacoes_cnpj_idx   ON public.licitacoes (cnpj_orgao);
CREATE INDEX IF NOT EXISTS licitacoes_fonte_idx  ON public.licitacoes (fonte);
