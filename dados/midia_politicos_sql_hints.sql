-- =============================================================================
-- BR Insider — Mídia & Política: queries investigativas
-- Gerado automaticamente por midia_politicos.py
-- =============================================================================

-- EIXO A: empresas de comunicação doadoras × candidatos beneficiados
-- (copiar para Supabase SQL editor ou psql)

SELECT
  r.ano_eleicao,
  r.cpf_cnpj_doador               AS cnpj_doador,
  r.nome_doador                   AS nome_empresa_doadora,
  r.setor_economico_doador        AS setor_tse,
  r.nome_candidato,
  r.cargo,
  r.sigla_partido,
  r.uf,
  SUM(r.valor)                    AS total_doado,
  COUNT(*)                        AS n_doacoes,
  c.situacao_turno                AS resultado
FROM tse_receitas r
LEFT JOIN tse_candidatos c
  ON c.cpf = r.cpf_candidato AND c.ano_eleicao = r.ano_eleicao
WHERE
  r.tipo_doador = 'PJ'
  AND (
    r.setor_economico_doador ILIKE '%comunicação%'
    OR r.setor_economico_doador ILIKE '%comunicacao%'
    OR r.setor_economico_doador ILIKE '%publicidade%'
    OR r.setor_economico_doador ILIKE '%radiodifusão%'
    OR r.setor_economico_doador ILIKE '%radiodifusao%'
    OR r.setor_economico_doador ILIKE '%televisão%'
    OR r.setor_economico_doador ILIKE '%televisao%'
    OR r.setor_economico_doador ILIKE '%rádio%'
    OR r.setor_economico_doador ILIKE '%radio%'
    OR r.setor_economico_doador ILIKE '%mídia%'
    OR r.setor_economico_doador ILIKE '%midia%'
    OR r.setor_economico_doador ILIKE '%imprensa%'
    OR r.setor_economico_doador ILIKE '%editorial%'
  )
GROUP BY
  r.ano_eleicao, r.cpf_cnpj_doador, r.nome_doador, r.setor_economico_doador,
  r.nome_candidato, r.cargo, r.sigla_partido, r.uf, c.situacao_turno
ORDER BY total_doado DESC
LIMIT 2000;


-- EIXO B: parlamentares ativos que são sócios em empresas de mídia
-- (requer base RFB cnpj_socios populada)

SELECT
  p.nome                          AS parlamentar,
  p.partido,
  p.uf,
  cs.cnpj_basico,
  ce.razao_social                 AS empresa,
  cs.qualificacao                 AS papel_societario,
  cs.data_entrada,
  ce.porte_empresa
FROM cnpj_socios cs
JOIN parlamentares p
  ON p.cpf = cs.cpf_cnpj_socio
LEFT JOIN cnpj_empresas ce
  ON ce.cnpj_basico = cs.cnpj_basico
WHERE
  length(cs.cpf_cnpj_socio) = 11
  AND (
    ce.razao_social ILIKE '%radio%'
    OR ce.razao_social ILIKE '%rádio%'
    OR ce.razao_social ILIKE '%televisão%'
    OR ce.razao_social ILIKE '%televisao%'
    OR ce.razao_social ILIKE '%comunicações%'
    OR ce.razao_social ILIKE '%comunicacoes%'
    OR ce.razao_social ILIKE '%emissora%'
    OR ce.razao_social ILIKE '%publicidade%'
    OR ce.razao_social ILIKE '%jornal%'
    OR ce.razao_social ILIKE '%revista%'
    OR ce.razao_social ILIKE '%mídia%'
    OR ce.razao_social ILIKE '%midia%'
  )
ORDER BY p.nome;


-- EIXO C: empresa de comunicação que doa para campanha E recebe emenda
-- do mesmo parlamentar — conflito duplo

SELECT
  r.cpf_cnpj_doador               AS cnpj,
  r.nome_doador                   AS nome_empresa,
  r.setor_economico_doador        AS setor_tse,
  SUM(r.valor)                    AS total_doado_campanha,
  COUNT(DISTINCT r.nome_candidato) AS n_candidatos_beneficiados,
  ef.valor_recebido               AS total_emendas_recebidas,
  ef.numero_emenda
FROM tse_receitas r
JOIN emendas_favorecidos ef
  ON ef.codigo_favorecido = r.cpf_cnpj_doador
WHERE
  r.tipo_doador = 'PJ'
  AND (
    r.setor_economico_doador ILIKE '%comunicação%'
    OR r.setor_economico_doador ILIKE '%comunicacao%'
    OR r.setor_economico_doador ILIKE '%publicidade%'
    OR r.setor_economico_doador ILIKE '%radiodifusão%'
    OR r.setor_economico_doador ILIKE '%televisão%'
    OR r.setor_economico_doador ILIKE '%televisao%'
    OR r.setor_economico_doador ILIKE '%rádio%'
  )
GROUP BY
  r.cpf_cnpj_doador, r.nome_doador, r.setor_economico_doador,
  ef.valor_recebido, ef.numero_emenda
ORDER BY total_doado_campanha DESC
LIMIT 500;


-- EIXO D (complementar — disponível quando dados MC/ANATEL ingeridos):
-- SELECT a.*, t.nome_candidato, t.cargo
-- FROM anatel_radiodifusao_outorgas a
-- JOIN tse_candidatos t ON a.cpf_cnpj_titular = t.cpf
-- WHERE t.cargo IN ('DEPUTADO FEDERAL', 'SENADOR', 'GOVERNADOR', 'PRESIDENTE')
-- ORDER BY a.uf, a.municipio;
--
-- Para ingerir dados do MC manualmente:
--   1. Acesse https://www.gov.br/mcom (login gov.br)
--   2. Dados abertos > Radiodifusão > Outorgas
--   3. Baixe o CSV e coloque em dados/mc_outorgas_radiodifusao.csv
--   4. Execute: python -m ingestao.midia_politicos --ingerir-mc
