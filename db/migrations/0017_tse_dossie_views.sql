-- The BR Insider — TSE: views para dossiê de doadores e parlamentares
-- Passo 1: rastreamento de doações de campanha por pessoa física/jurídica
--
-- Novos objetos:
--   tse_v_dossie_doador       — perfil completo de um doador (busca por CPF/CNPJ ou nome)
--   tse_v_rede_financiamento  — doadores comuns entre parlamentares (rede de influência)
--   tse_v_receptor_top        — quem mais recebeu de um doador (ranking)
--
-- Índices adicionais:
--   idx_tse_receitas_nome_doador  — trgm para busca ~ilike eficiente

-- ─── Extensão trigram para busca textual eficiente ───────────────────────────
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX IF NOT EXISTS idx_tse_receitas_nome_doador_trgm
  ON public.tse_receitas USING GIN (nome_doador gin_trgm_ops)
  WHERE nome_doador IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_tse_receitas_nome_doador_originario_trgm
  ON public.tse_receitas USING GIN (nome_doador_originario gin_trgm_ops)
  WHERE nome_doador_originario IS NOT NULL;

-- ─── View 1: perfil de doador — todas as doações de um CPF/CNPJ ──────────────
-- Uso: WHERE cpf_cnpj_doador = '02781881686'   (Fabiano Zettel)
--   OU WHERE nome_doador ILIKE '%ZETTEL%'
CREATE OR REPLACE VIEW public.tse_v_dossie_doador AS
SELECT
  r.ano_eleicao,
  r.cpf_cnpj_doador,
  r.nome_doador,
  r.tipo_doador,
  r.setor_economico_doador,
  -- candidato recebedor
  r.nome_candidato,
  r.cargo,
  r.sigla_partido,
  r.uf,
  -- doador originário (quando a doação passa por intermediário)
  r.cpf_cnpj_doador_originario,
  r.nome_doador_originario,
  -- valor e data
  r.valor,
  r.data_receita,
  r.natureza_receita,
  r.origem_receita,
  -- link para candidato (se existir no banco)
  c.id                        AS tse_candidato_id,
  c.situacao_turno            AS resultado_eleicao,
  -- link para parlamentar ativo (se eleito e cadastrado)
  p.id                        AS parlamentar_id,
  p.id_camara,
  p.partido_atual
FROM public.tse_receitas r
LEFT JOIN public.tse_candidatos c
  ON c.cpf = r.cpf_candidato
  AND c.ano_eleicao = r.ano_eleicao
  AND length(r.cpf_candidato) >= 11
LEFT JOIN public.parlamentares p
  ON p.cpf = r.cpf_candidato
  AND length(r.cpf_candidato) >= 11;

COMMENT ON VIEW public.tse_v_dossie_doador IS
  'Todas as doações de um CPF/CNPJ ou nome. '
  'Filtrar por cpf_cnpj_doador (exato) ou nome_doador ILIKE. '
  'JOIN com parlamentares permite ver se candidato foi eleito e está ativo.';

-- ─── View 2: ranking de receptores de um doador ──────────────────────────────
-- Uso: SELECT * FROM tse_v_receptor_top WHERE cpf_cnpj_doador = '02781881686'
CREATE OR REPLACE VIEW public.tse_v_receptor_top AS
SELECT
  r.cpf_cnpj_doador,
  r.nome_doador,
  r.nome_candidato,
  r.cargo,
  r.sigla_partido,
  r.uf,
  COUNT(*)                        AS n_transacoes,
  SUM(r.valor)                    AS total_doado,
  MIN(r.ano_eleicao)              AS primeiro_ano,
  MAX(r.ano_eleicao)              AS ultimo_ano,
  STRING_AGG(DISTINCT r.ano_eleicao::TEXT, ', ' ORDER BY r.ano_eleicao::TEXT)
                                  AS anos,
  p.id_camara,
  p.ativo                         AS parlamentar_ativo
FROM public.tse_receitas r
LEFT JOIN public.parlamentares p
  ON p.cpf = r.cpf_candidato
  AND length(r.cpf_candidato) >= 11
GROUP BY
  r.cpf_cnpj_doador, r.nome_doador,
  r.nome_candidato, r.cargo, r.sigla_partido, r.uf,
  p.id_camara, p.ativo;

COMMENT ON VIEW public.tse_v_receptor_top IS
  'Ranking de candidatos que receberam de um doador. '
  'Filtrar por cpf_cnpj_doador. Agrega 2022+2024.';

-- ─── View 3: rede de financiamento cruzado ───────────────────────────────────
-- Doadores que financiaram mais de um parlamentar (rede de influência)
-- Filtrar por cpf_candidato de um parlamentar específico para ver seus doadores
-- e quais outros parlamentares eles financiaram.
CREATE OR REPLACE VIEW public.tse_v_rede_financiamento AS
WITH doadores_parlamentar AS (
  -- todos os doadores de um parlamentar (qualquer ano)
  SELECT DISTINCT
    r.cpf_candidato,
    r.cpf_cnpj_doador,
    r.nome_doador
  FROM public.tse_receitas r
  WHERE r.cpf_cnpj_doador IS NOT NULL
)
SELECT
  dp.cpf_candidato                AS cpf_parlamentar_alvo,
  dp.cpf_cnpj_doador,
  dp.nome_doador,
  -- outros parlamentares que o mesmo doador financiou
  r2.cpf_candidato                AS cpf_outro_parlamentar,
  r2.nome_candidato               AS nome_outro_parlamentar,
  r2.sigla_partido                AS partido_outro,
  r2.uf                           AS uf_outro,
  r2.ano_eleicao,
  r2.valor
FROM doadores_parlamentar dp
JOIN public.tse_receitas r2
  ON r2.cpf_cnpj_doador = dp.cpf_cnpj_doador
  AND r2.cpf_candidato <> dp.cpf_candidato
ORDER BY dp.cpf_candidato, r2.valor DESC;

COMMENT ON VIEW public.tse_v_rede_financiamento IS
  'Para um parlamentar (cpf_parlamentar_alvo), mostra os doadores em comum com outros candidatos. '
  'Filtre por cpf_parlamentar_alvo = CPF do parlamentar. '
  'Útil para mapear redes de influência de um financiador.';

-- ─── View 4: cruzamento doador × favorecido de emenda (já existia como tse_v_doador_emenda)
-- Mantida sem alteração — esta migration não recria para não quebrar dependências.

-- ─── View 5: resumo de financiadores por parlamentar (para dossiê) ───────────
CREATE OR REPLACE VIEW public.tse_v_financiadores_parlamentar AS
SELECT
  r.cpf_candidato,
  r.nome_candidato,
  r.sigla_partido,
  r.uf,
  r.ano_eleicao,
  r.cpf_cnpj_doador,
  r.nome_doador,
  r.tipo_doador,
  r.setor_economico_doador,
  SUM(r.valor)                    AS total_recebido,
  COUNT(*)                        AS n_transacoes,
  MIN(r.data_receita)             AS primeira_doacao,
  MAX(r.data_receita)             AS ultima_doacao
FROM public.tse_receitas r
WHERE r.cpf_candidato IS NOT NULL
GROUP BY
  r.cpf_candidato, r.nome_candidato, r.sigla_partido, r.uf, r.ano_eleicao,
  r.cpf_cnpj_doador, r.nome_doador, r.tipo_doador, r.setor_economico_doador
ORDER BY total_recebido DESC;

COMMENT ON VIEW public.tse_v_financiadores_parlamentar IS
  'Todos os financiadores de um parlamentar, por ano. '
  'Filtrar por cpf_candidato ou nome_candidato ILIKE. '
  'Agregado: total recebido de cada doador.';
