-- Corrige 2 bugs achados em sebrae_licitacoes durante a reingestão de 2026-07-22:
--
-- 1) Colunas trocadas por ordem errada na lista do conector (bug nosso, confirmado
--    via GetLayout/qDimensionInfo posicional contra o objeto Qlik f7a53fdc-...):
--      coluna "tipo_julgamento" continha conteúdo de "Tipo da Licitação"
--      coluna "menor_preco"     continha conteúdo de "Tipo do Julgamento"
--      coluna "julgamento"      continha conteúdo de "Menor Preço"
--
-- 2) A UNIQUE(uf, numero_licitacao) tratava cada LICITAÇÃO como uma linha, mas a
--    granularidade real da fonte é (licitação × participante): cada concorrente é
--    uma linha própria (resultado="Participante"/"Vencedor"). Com ignore-duplicates,
--    isso descartava ~75% das linhas reais (ficavam só ~5.400 de ~21.600). Nova
--    chave (uf, numero_licitacao, cnpj_fornecedor, resultado) captura 21.158/21.617
--    (97,9%) — o resíduo de ~4% é licitação multi-lote onde o Qlik não expõe nº do
--    lote, então o mesmo fornecedor com o mesmo resultado em 2+ lotes ainda colide
--    (limitação real da fonte, não corrigível sem um campo que ela não expõe).
--
-- Aplicada em produção (redggdtakzmsabwvjzhb) em 2026-07-22, seguida de reingestão
-- completa (21.617 linhas extraídas do Qlik, 21.158 carregadas após dedupe pela
-- nova chave). ingestao/sebrae_connector.py atualizado (ordem de colunas +
-- CONFLICT_COLS) pra próximas cargas do cron já usarem o mapeamento certo.

ALTER TABLE public.sebrae_licitacoes RENAME COLUMN julgamento TO _tmp1;
ALTER TABLE public.sebrae_licitacoes RENAME COLUMN tipo_julgamento TO _tmp2;
ALTER TABLE public.sebrae_licitacoes RENAME COLUMN menor_preco TO tipo_julgamento;
ALTER TABLE public.sebrae_licitacoes RENAME COLUMN _tmp1 TO menor_preco;
ALTER TABLE public.sebrae_licitacoes RENAME COLUMN _tmp2 TO tipo_licitacao;

COMMENT ON COLUMN public.sebrae_licitacoes.tipo_licitacao  IS 'Campo Qlik "Tipo da Licitação" (ex: "Maior Lance ou Oferta"). Corrigido em 2026-07-22 — antes vinha rotulado tipo_julgamento por erro de ordem no conector.';
COMMENT ON COLUMN public.sebrae_licitacoes.tipo_julgamento IS 'Campo Qlik "Tipo do Julgamento" (ex: "Menor Preço"). Corrigido em 2026-07-22 — antes vinha rotulado menor_preco por erro de ordem no conector.';
COMMENT ON COLUMN public.sebrae_licitacoes.menor_preco     IS 'Campo Qlik "Menor Preço" — critério de julgamento (ex: "Por Item", "Global"). Corrigido em 2026-07-22 — antes vinha rotulado julgamento por erro de ordem no conector.';

ALTER TABLE public.sebrae_licitacoes DROP CONSTRAINT sebrae_licitacoes_uf_numero_licitacao_key;
ALTER TABLE public.sebrae_licitacoes ADD CONSTRAINT sebrae_licitacoes_uf_num_cnpj_resultado_key
  UNIQUE (uf, numero_licitacao, cnpj_fornecedor, resultado);

TRUNCATE TABLE public.sebrae_licitacoes RESTART IDENTITY;
