-- The BR Insider — IBAMA Autos de Infração (tabela editorial)
-- Fonte: bulk CSV (~114 MB comprimido) em stibamadadosabertosprd.blob.core.windows.net
-- Diferença de sub_ibama (Subradar): inclui PF + campos adicionais de cruzamento
-- Volume: ~700k autos (1977–2026)

CREATE TABLE IF NOT EXISTS public.ibama_autuacoes (
  id                    BIGSERIAL PRIMARY KEY,
  num_auto_infracao     TEXT            NOT NULL UNIQUE,
  tp_pessoa             CHAR(2),                        -- "PF" | "PJ"
  cpf_cnpj_infrator     TEXT            NOT NULL,       -- dígitos puros (11 ou 14)
  nome_infrator         TEXT,
  des_infracao          TEXT,
  des_situacao          TEXT,
  val_auto_infracao     NUMERIC(16, 2),
  dat_infracao          DATE,
  municipio             TEXT,
  uf                    CHAR(2),
  num_processo          TEXT,
  ingested_at           TIMESTAMPTZ     NOT NULL DEFAULT now()
);

-- índices para cruzamentos editoriais
CREATE INDEX IF NOT EXISTS ibama_cpf_cnpj_idx      ON public.ibama_autuacoes (cpf_cnpj_infrator);
CREATE INDEX IF NOT EXISTS ibama_uf_idx            ON public.ibama_autuacoes (uf);
CREATE INDEX IF NOT EXISTS ibama_municipio_idx     ON public.ibama_autuacoes (municipio);
CREATE INDEX IF NOT EXISTS ibama_dat_idx           ON public.ibama_autuacoes (dat_infracao);
CREATE INDEX IF NOT EXISTS ibama_val_idx           ON public.ibama_autuacoes (val_auto_infracao);
CREATE INDEX IF NOT EXISTS ibama_tp_pessoa_idx     ON public.ibama_autuacoes (tp_pessoa);

COMMENT ON TABLE public.ibama_autuacoes IS
  'Autos de infração do IBAMA — PF e PJ. '
  'Cruzável com doadores TSE, beneficiários de emendas, contratos PNCP e patrimônio TSE.';
