-- The BR Insider — Cartão de Pagamento do Governo Federal (CPGF)
-- Fonte: portaldatransparencia.gov.br/download-de-dados/cpgf/{ano}
-- Granularidade: transação individual por portador × favorecido
-- Volume estimado: ~1,5M linhas/ano

CREATE TABLE IF NOT EXISTS public.cpgf_transacoes (
  id                    BIGSERIAL PRIMARY KEY,
  ano_mes               CHAR(7)         NOT NULL,       -- "2024-03"
  ano                   SMALLINT        NOT NULL,
  mes                   SMALLINT        NOT NULL,
  cpf_portador          TEXT            NOT NULL,
  nome_portador         TEXT,
  cpf_cnpj_favorecido   TEXT,
  nome_favorecido       TEXT,
  transacao             TEXT,
  estabelecimento       TEXT,
  municipio             TEXT,
  uf                    CHAR(2),
  valor                 NUMERIC(14, 2),
  ingested_at           TIMESTAMPTZ     NOT NULL DEFAULT now(),

  -- idempotência: mesmo portador, favorecido, mês e valor não duplica
  UNIQUE (ano_mes, cpf_portador, cpf_cnpj_favorecido, transacao, valor)
);

-- índices para cruzamentos editoriais
CREATE INDEX IF NOT EXISTS cpgf_portador_idx       ON public.cpgf_transacoes (cpf_portador);
CREATE INDEX IF NOT EXISTS cpgf_favorecido_idx     ON public.cpgf_transacoes (cpf_cnpj_favorecido);
CREATE INDEX IF NOT EXISTS cpgf_ano_mes_idx        ON public.cpgf_transacoes (ano_mes);
CREATE INDEX IF NOT EXISTS cpgf_uf_idx             ON public.cpgf_transacoes (uf);
CREATE INDEX IF NOT EXISTS cpgf_valor_idx          ON public.cpgf_transacoes (valor);

COMMENT ON TABLE public.cpgf_transacoes IS
  'Gastos com Cartão de Pagamento do Governo Federal — Portal da Transparência. '
  'Cruzável com cota_parlamentar (CEAP), viagens_scdp e doadores TSE.';
