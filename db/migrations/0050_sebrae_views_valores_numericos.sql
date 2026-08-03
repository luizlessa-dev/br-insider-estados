-- Normaliza os campos de valor (TEXT em formato BR: milhar com ponto, decimal
-- com vírgula) das tabelas SEBRAE em NUMERIC, via função + views. Colunas
-- físicas permanecem TEXT (é o que o conector grava) — as views são a
-- interface segura pra ranking/soma/filtro numérico.
--
-- Achados na auditoria de 2026-07-22 tratados aqui:
--  - "-" e outros placeholders viram NULL (não erro de cast).
--  - Valores negativos legítimos (aditivos de redução contratual, ex:
--    "-7.866,00") são preservados — a regex antiga sem sinal os teria
--    descartado como lixo.
--  - `ano` fora do intervalo plausível (ex: 7202, 2027 encontrados em
--    sebrae_contratos) é anulado via sebrae_ano_valido() pra não vazar
--    outlier de digitação em agregações por ano.
--
-- Aplicada em produção (redggdtakzmsabwvjzhb) em 2026-07-22.
-- Validação pós-deploy: 473.893/473.893 linhas de sebrae_contratos parseadas
-- sem falha de cast (0 NULL por erro), 133 negativos preservados, 2 anos anulados.

CREATE OR REPLACE FUNCTION public.sebrae_parse_valor(v TEXT)
RETURNS NUMERIC
LANGUAGE sql IMMUTABLE STRICT AS $$
  SELECT CASE WHEN v ~ '^-?\d{1,3}(\.\d{3})*,\d{2}$'
              THEN REPLACE(REPLACE(v, '.', ''), ',', '.')::NUMERIC
         ELSE NULL END
$$;

COMMENT ON FUNCTION public.sebrae_parse_valor(TEXT) IS
  'Converte valor monetário BR (texto, milhar com ponto, decimal com vírgula, sinal opcional) em NUMERIC. Retorna NULL para placeholders tipo "-" ou texto não numérico, em vez de erro de cast.';

CREATE OR REPLACE FUNCTION public.sebrae_ano_valido(a SMALLINT)
RETURNS SMALLINT
LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE WHEN a BETWEEN 2000 AND 2026 THEN a ELSE NULL END
$$;

COMMENT ON FUNCTION public.sebrae_ano_valido(SMALLINT) IS
  'Anula valores de ano fora do intervalo plausível (ex: 7202, 2027 encontrados em sebrae_contratos na auditoria de 2026-07-22) para não contaminar agregações por ano.';

CREATE OR REPLACE VIEW public.vw_sebrae_contratos_num AS
SELECT
  id, uf, sebrae_ano_valido(ano) AS ano, numero_contrato, data_contrato, modalidade,
  cnpj_cpf, razao_social, vigencia, objeto, aditivo,
  sebrae_parse_valor(valor_contrato) AS valor_contrato_num,
  sebrae_parse_valor(valor_pago)     AS valor_pago_num,
  data_ingestao
FROM public.sebrae_contratos;

CREATE OR REPLACE VIEW public.vw_sebrae_convenios_num AS
SELECT
  id, uf, sebrae_ano_valido(ano) AS ano, numero_convenio, data_convenio,
  cnpj_cpf, razao_social, vigencia, objeto, aditivo,
  sebrae_parse_valor(participacao_sebrae)   AS participacao_sebrae_num,
  sebrae_parse_valor(valor_repasse)         AS valor_repasse_num,
  sebrae_parse_valor(valor_contrapartida)   AS valor_contrapartida_num,
  data_ingestao
FROM public.sebrae_convenios;

CREATE OR REPLACE VIEW public.vw_sebrae_patrocinios_num AS
SELECT
  id, uf, sebrae_ano_valido(ano) AS ano, numero_contrato, data_contrato,
  cnpj_cpf, razao_social, vigencia, objeto, aditivo,
  sebrae_parse_valor(valor_contrato) AS valor_contrato_num,
  sebrae_parse_valor(valor_pago)     AS valor_pago_num,
  data_ingestao
FROM public.sebrae_patrocinios;

CREATE OR REPLACE VIEW public.vw_sebrae_emendas_contratos_num AS
SELECT
  id, uf, sebrae_ano_valido(ano) AS ano, numero_contrato, data_contrato, modalidade,
  cnpj_cpf, razao_social, vigencia, objeto, aditivo,
  sebrae_parse_valor(valor_contrato) AS valor_contrato_num,
  nota_parlamentar_truncada,
  data_ingestao
FROM public.sebrae_emendas_contratos;

CREATE OR REPLACE VIEW public.vw_sebrae_emendas_convenios_num AS
SELECT
  id, uf, sebrae_ano_valido(ano) AS ano, numero_convenio, data_convenio,
  cnpj_cpf, razao_social, vigencia, objeto, aditivo,
  sebrae_parse_valor(valor_emenda) AS valor_emenda_num,
  nota_parlamentar_truncada,
  data_ingestao
FROM public.sebrae_emendas_convenios;

COMMENT ON VIEW public.vw_sebrae_contratos_num IS 'sebrae_contratos com valor_contrato/valor_pago normalizados em NUMERIC e ano fora do intervalo plausível anulado. Ver sebrae_parse_valor().';
COMMENT ON VIEW public.vw_sebrae_convenios_num IS 'sebrae_convenios com campos de valor normalizados em NUMERIC. Ver sebrae_parse_valor().';
COMMENT ON VIEW public.vw_sebrae_patrocinios_num IS 'sebrae_patrocinios com campos de valor normalizados em NUMERIC. Ver sebrae_parse_valor().';
COMMENT ON VIEW public.vw_sebrae_emendas_contratos_num IS 'sebrae_emendas_contratos com valor_contrato normalizado em NUMERIC (pós-fix de colunas trocadas de 2026-07-22).';
COMMENT ON VIEW public.vw_sebrae_emendas_convenios_num IS 'sebrae_emendas_convenios com valor_emenda normalizado em NUMERIC (pós-fix de colunas trocadas de 2026-07-22).';
