-- Corrige o schema de public.cpgf_transacoes (0044_cpgf.sql) contra o CSV real do CGU.
--
-- Achado ao validar o fix da URL mensal (2026-07-11): o cabeçalho real do
-- ZIP CPGF NÃO tem estabelecimento/município/UF (campos que o schema
-- original supôs sem checar contra um arquivo real) — tem, em vez disso,
-- órgão superior / órgão / unidade gestora e data da transação, que o
-- schema original não capturava.
--
-- Cabeçalho real (202506_CPGF.csv):
--   CÓDIGO ÓRGÃO SUPERIOR; NOME ÓRGÃO SUPERIOR; CÓDIGO ÓRGÃO; NOME ÓRGÃO;
--   CÓDIGO UNIDADE GESTORA; NOME UNIDADE GESTORA; ANO EXTRATO; MÊS EXTRATO;
--   CPF PORTADOR; NOME PORTADOR; CNPJ OU CPF FAVORECIDO; NOME FAVORECIDO;
--   TRANSAÇÃO; DATA TRANSAÇÃO; VALOR TRANSAÇÃO
--
-- Não dropa estabelecimento/municipio/uf (ninguém popula, mas manter é
-- reversível; dropar coluna não é).

ALTER TABLE public.cpgf_transacoes
  ADD COLUMN IF NOT EXISTS codigo_orgao_superior     TEXT,
  ADD COLUMN IF NOT EXISTS nome_orgao_superior        TEXT,
  ADD COLUMN IF NOT EXISTS codigo_orgao               TEXT,
  ADD COLUMN IF NOT EXISTS nome_orgao                 TEXT,
  ADD COLUMN IF NOT EXISTS codigo_unidade_gestora      TEXT,
  ADD COLUMN IF NOT EXISTS nome_unidade_gestora        TEXT,
  ADD COLUMN IF NOT EXISTS data_transacao              DATE;

CREATE INDEX IF NOT EXISTS cpgf_orgao_idx ON public.cpgf_transacoes (codigo_orgao);
CREATE INDEX IF NOT EXISTS cpgf_ug_idx    ON public.cpgf_transacoes (codigo_unidade_gestora);

COMMENT ON COLUMN public.cpgf_transacoes.estabelecimento IS
  'Sem fonte no CSV real do CGU (schema original supôs campo inexistente) — sempre NULL desde 2026-07-11.';
COMMENT ON COLUMN public.cpgf_transacoes.municipio IS
  'Sem fonte no CSV real do CGU (schema original supôs campo inexistente) — sempre NULL desde 2026-07-11.';
COMMENT ON COLUMN public.cpgf_transacoes.uf IS
  'Sem fonte no CSV real do CGU (schema original supôs campo inexistente) — sempre NULL desde 2026-07-11.';
