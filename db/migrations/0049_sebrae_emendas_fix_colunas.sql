-- Corrige o mapeamento trocado de colunas nas tabelas de emendas do SEBRAE.
-- Achado (2026-07-22): o próprio painel Qlik de origem (App e2407c39, objetos
-- AHSdRn/DumJhJv) tem a medida "Valor do contrato"/"Valor da emenda" e o campo
-- "Observação" com conteúdo trocado na fonte — confirmado via GetLayout/qDimensionInfo
-- e validado nas 22 linhas já ingeridas (100% de consistência).
-- O campo rotulado "Observação" sempre contém o valor monetário real.
-- A medida rotulada "Valor do contrato"/"Valor da emenda" sempre contém texto
-- livre truncado a ~30 caracteres (autor da emenda, nº de emenda ou nº de convênio).
-- Aplicada em produção (redggdtakzmsabwvjzhb) em 2026-07-22.

ALTER TABLE public.sebrae_emendas_contratos RENAME COLUMN valor_contrato TO nota_parlamentar_truncada;
ALTER TABLE public.sebrae_emendas_contratos RENAME COLUMN observacao TO valor_contrato;

COMMENT ON COLUMN public.sebrae_emendas_contratos.valor_contrato IS
  'Valor real do contrato/emenda. Corrigido em 2026-07-22: fonte Qlik tinha essa medida rotulada "Valor do contrato" apontando para texto, e o campo rotulado "Observação" continha o valor numérico. Ver nota_parlamentar_truncada.';
COMMENT ON COLUMN public.sebrae_emendas_contratos.nota_parlamentar_truncada IS
  'Texto livre truncado a ~30 caracteres (autor da emenda, nº de emenda ou nº de convênio, varia por linha), vindo da medida Qlik rotulada "Valor do contrato". Truncamento é do painel de origem — não é possível recuperar o texto completo por esse objeto Qlik.';

ALTER TABLE public.sebrae_emendas_convenios RENAME COLUMN valor_emenda TO nota_parlamentar_truncada;
ALTER TABLE public.sebrae_emendas_convenios RENAME COLUMN observacao TO valor_emenda;

COMMENT ON COLUMN public.sebrae_emendas_convenios.valor_emenda IS
  'Valor real do convênio/emenda. Corrigido em 2026-07-22: fonte Qlik tinha essa medida rotulada "Valor da emenda" apontando para texto, e o campo rotulado "Observação" continha o valor numérico. Ver nota_parlamentar_truncada.';
COMMENT ON COLUMN public.sebrae_emendas_convenios.nota_parlamentar_truncada IS
  'Texto livre truncado a ~30 caracteres (autor da emenda, nº de emenda ou nº de convênio, varia por linha), vindo da medida Qlik rotulada "Valor da emenda". Truncamento é do painel de origem — não é possível recuperar o texto completo por esse objeto Qlik.';
