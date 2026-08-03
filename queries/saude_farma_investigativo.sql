-- ═══════════════════════════════════════════════════════════════════════════════
-- QUERIES INVESTIGATIVAS: Saúde & Indústria Farmacêutica × Emendas × Campanha
-- The BR Insider
--
-- PRÉ-REQUISITOS:
--   migrations 0007 (tse), 0014 (cnes), 0022 (mg_siafi) aplicadas
--   views: tse_v_doador_emenda, cnes_emendas_por_cnpj
--
-- FLUXO: Empresa doa → parlamentar emenda → empresa recebe → (bônus: check CNES)
-- ═══════════════════════════════════════════════════════════════════════════════


-- ── Q1: CIRCUITO COMPLETO — doação → emenda → favorecido (setor saúde) ───────
-- Empresas do setor saúde/farma que doaram e depois receberam emenda do mesmo
-- parlamentar. É a smoking gun: financiou campanha, voltou como favorecido.

SELECT
  v.parlamentar,
  v.sigla_partido,
  v.uf,
  v.empresa_doadora,
  v.cnpj_doador,
  v.setor_economico_doador,
  ROUND(SUM(v.valor_doacao)::numeric, 2)    AS total_doado_brl,
  ROUND(SUM(v.valor_emenda)::numeric, 2)    AS total_emenda_brl,
  COUNT(DISTINCT v.ano_eleicao)             AS eleicoes,
  COUNT(DISTINCT v.ano_emenda)              AS anos_emendas,
  -- razão emenda/doação: quanto retornou por real investido
  ROUND((SUM(v.valor_emenda) / NULLIF(SUM(v.valor_doacao), 0))::numeric, 1) AS retorno_x
FROM public.tse_v_doador_emenda v
WHERE
  v.setor_economico_doador ILIKE '%saúde%'
  OR v.setor_economico_doador ILIKE '%farmac%'
  OR v.setor_economico_doador ILIKE '%hospital%'
  OR v.setor_economico_doador ILIKE '%medic%'
  OR v.setor_economico_doador ILIKE '%laborat%'
  OR v.setor_economico_doador ILIKE '%equipamento%'
  OR v.empresa_doadora       ILIKE '%drogaria%'
  OR v.empresa_doadora       ILIKE '%distribuidora%'
  OR v.empresa_doadora       ILIKE '%farma%'
  OR v.empresa_doadora       ILIKE '%lab %'
GROUP BY
  v.parlamentar, v.sigla_partido, v.uf,
  v.empresa_doadora, v.cnpj_doador, v.setor_economico_doador
HAVING SUM(v.valor_emenda) > 100000   -- filtra ruído
ORDER BY total_emenda_brl DESC
LIMIT 50;


-- ── Q2: RANKING GERAL — favorecidos de emenda no setor saúde (via CNES) ──────
-- Quais estabelecimentos de saúde mais receberam emendas, e quem são os autores?
-- Usa a view cnes_emendas_por_cnpj que deduplica CNPJs compartilhados.

SELECT
  cnpj,
  nome_favorecido,
  uf,
  total_unidades_cnes,
  tem_hospital,
  atende_sus,
  ROUND(total_recebido::numeric, 2)  AS total_emenda_brl,
  total_transacoes,
  total_autores,
  autores[1:5]                       AS top_5_autores,  -- primeiros 5 do array
  ano_primeira_emenda,
  ano_ultima_emenda
FROM public.cnes_emendas_por_cnpj
ORDER BY total_recebido DESC
LIMIT 40;


-- ── Q3: HOSPITAIS PRIVADOS × EMENDAS × DOAÇÃO TSE ───────────────────────────
-- Cruzamento triplo: hospital tem CNES + recebeu emenda + doou para o autor.
-- Detecta hospitais particulares capturando emendas via financiamento eleitoral.

WITH hospitais_emendas AS (
  SELECT
    cep.numero_cnpj,
    cep.nome_favorecido,
    cep.uf,
    cep.total_recebido,
    cep.total_autores,
    cep.autores
  FROM public.cnes_emendas_por_cnpj cep
  WHERE cep.tem_hospital = TRUE
    AND cep.atende_sus   = FALSE   -- privado puro (sem SUS)
    AND cep.total_recebido > 500000
)
SELECT
  he.nome_favorecido,
  he.numero_cnpj,
  he.uf,
  ROUND(he.total_recebido::numeric, 2)          AS total_emenda_brl,
  -- verificar se também doou para algum autor
  ROUND(SUM(r.valor)::numeric, 2)               AS total_doado_tse_brl,
  COUNT(DISTINCT r.cpf_candidato)               AS candidatos_financiados,
  array_agg(DISTINCT c.nome || ' (' || c.sigla_partido || ')' ORDER BY c.nome)
                                                AS candidatos_nomes
FROM hospitais_emendas he
LEFT JOIN public.tse_receitas r
  ON r.cpf_cnpj_doador = he.numero_cnpj
LEFT JOIN public.tse_candidatos c
  ON c.cpf = r.cpf_candidato AND c.ano_eleicao = r.ano_eleicao
GROUP BY he.nome_favorecido, he.numero_cnpj, he.uf, he.total_recebido
ORDER BY total_emenda_brl DESC
LIMIT 30;


-- ── Q4: PARLAMENTARES COM MAIOR VOLUME DE EMENDAS PARA SAÚDE ─────────────────
-- Quem mais distribui emendas para estabelecimentos de saúde (via CNES)?
-- Detecta especialistas setoriais — potenciais alvos de lobby farmacêutico.

SELECT
  e.nome_autor                              AS parlamentar,
  e.partido_autor,
  e.uf_autor,
  COUNT(DISTINCT e.codigo_favorecido)       AS cnpjs_beneficiados,
  ROUND(SUM(e.valor_recebido)::numeric, 2)  AS total_emendas_saude_brl,
  COUNT(DISTINCT e.ano_emenda)             AS anos_ativos,
  COUNT(DISTINCT e.id)                     AS total_transacoes
FROM public.emendas_favorecidos e
WHERE e.codigo_favorecido IN (
  SELECT numero_cnpj FROM public.cnes_estabelecimentos
  WHERE numero_cnpj IS NOT NULL
)
GROUP BY e.nome_autor, e.partido_autor, e.uf_autor
ORDER BY total_emendas_saude_brl DESC
LIMIT 30;


-- ── Q5: DISTRIBUIDORAS / FARMA POR NOME (sem CNAE na tabela) ─────────────────
-- Busca por nome nas emendas_favorecidos — útil enquanto não tiver CNAE ingerido.
-- CNAEs relevantes: 4644-3 (medicamentos), 3250-7 (equipamentos médicos).

SELECT
  e.codigo_favorecido                         AS cnpj,
  e.favorecido                                AS nome,
  e.uf_favorecido,
  e.municipio_favorecido,
  ROUND(SUM(e.valor_recebido)::numeric, 2)    AS total_recebido_brl,
  COUNT(DISTINCT e.nome_autor)                AS total_autores,
  COUNT(DISTINCT e.ano_emenda)               AS anos_ativos,
  array_agg(DISTINCT e.nome_autor ORDER BY e.nome_autor) FILTER (WHERE e.nome_autor IS NOT NULL)
                                              AS autores
FROM public.emendas_favorecidos e
WHERE
  e.favorecido ILIKE '%farma%'
  OR e.favorecido ILIKE '%drogaria%'
  OR e.favorecido ILIKE '%distribuidora%'
  OR e.favorecido ILIKE '%medic%'
  OR e.favorecido ILIKE '%laborat%'
  OR e.favorecido ILIKE '%equipamento%'
  OR e.favorecido ILIKE '%hospital%'
  OR e.favorecido ILIKE '%clinica%'
  OR e.favorecido ILIKE '%saúde%'
GROUP BY e.codigo_favorecido, e.favorecido, e.uf_favorecido, e.municipio_favorecido
HAVING SUM(e.valor_recebido) > 200000
ORDER BY total_recebido_brl DESC
LIMIT 60;


-- ── Q6: SANEAMENTO — verificar se CNES está populado ─────────────────────────
-- Roda primeiro para saber se os dados já foram ingeridos.

SELECT
  COUNT(*)                              AS total_estabelecimentos,
  COUNT(numero_cnpj)                    AS com_cnpj,
  COUNT(CASE WHEN atende_sus THEN 1 END) AS atendem_sus,
  COUNT(CASE WHEN possui_atendimento_hospitalar THEN 1 END) AS hospitais
FROM public.cnes_estabelecimentos;

-- Se retornar 0 linhas → ingerir CNES antes de rodar Q2/Q3/Q4.
-- API: https://apidadosabertos.saude.gov.br/cnes/estabelecimentos?limit=100&offset=0
