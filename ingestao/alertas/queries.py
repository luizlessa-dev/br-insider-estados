"""
Queries SQL dos alertas investigativos — BR Insider
Cada query retorna linhas de alerta prontas para envio.

Cruzamentos implementados:
  1. agenda_ministerial × sancoes
     Ministro reuniu com empresa sancionada (CEIS/CNEP).
     Chave: cnpj_instituicao do participante privado × sancoes.cpf_cnpj

  2. agenda_ministerial × emendas_favorecidos
     Ministro reuniu com empresa que recebeu emenda parlamentar.
     Chave: cnpj_instituicao × emendas_favorecidos.codigo_favorecido

  3. agenda_ministerial × sancoes + emendas (combo)
     O mais grave: empresa sancionada E que recebeu emenda está na agenda.

  4. audiencias_publicas × sancoes
     Empresa sancionada participou de audiência pública na Câmara.
     Chave: extração de CNPJ do campo descricao (heurística).

Todas as queries usam janela de 30 dias para não reprocessar histórico antigo.
"""

# ── 1. Ministro × empresa sancionada ─────────────────────────────────────────
ALERTA_MINISTERIO_SANCAO = """
WITH privados AS (
    -- Explode participantes_privados JSONB em linhas
    SELECT
        c.id                                        AS compromisso_id,
        c.data_inicio,
        c.hora_inicio,
        c.orgao_sigla,
        c.autoridade_nome,
        c.autoridade_cargo,
        c.assunto,
        c.local,
        p->>'nome'                                  AS participante_nome,
        p->>'cnpj_instituicao'                      AS cnpj_raw,
        regexp_replace(p->>'cnpj_instituicao', '[^0-9]', '', 'g') AS cnpj,
        p->>'nome_instituicao'                      AS instituicao,
        p->>'cargo_instituicao'                     AS cargo_inst
    FROM agenda_executivo_compromissos c,
         jsonb_array_elements(c.participantes_privados) p
    WHERE c.tem_participantes_privados = true
      AND c.data_inicio >= current_date - 30
      AND p->>'cnpj_instituicao' IS NOT NULL
      AND p->>'cnpj_instituicao' != ''
)
SELECT
    p.compromisso_id,
    p.data_inicio,
    p.hora_inicio,
    p.orgao_sigla,
    p.autoridade_nome,
    p.autoridade_cargo,
    p.assunto,
    p.local,
    p.participante_nome,
    p.cnpj_raw                                      AS cnpj_participante,
    p.instituicao,
    p.cargo_inst,
    s.cadastro                                      AS tipo_sancao,
    s.tipo_sancao                                   AS descricao_sancao,
    s.data_inicio_sancao,
    s.data_fim_sancao,
    s.orgao_nome                                    AS orgao_sancao,
    s.nome                                          AS nome_sancionado
FROM privados p
JOIN sancoes s ON s.cpf_cnpj = p.cnpj
WHERE length(p.cnpj) >= 14
ORDER BY p.data_inicio DESC, p.orgao_sigla;
"""

# ── 2. Ministro × empresa que recebeu emenda ─────────────────────────────────
ALERTA_MINISTERIO_EMENDA = """
WITH privados AS (
    SELECT
        c.id                                        AS compromisso_id,
        c.data_inicio,
        c.hora_inicio,
        c.orgao_sigla,
        c.autoridade_nome,
        c.autoridade_cargo,
        c.assunto,
        c.local,
        p->>'nome'                                  AS participante_nome,
        regexp_replace(p->>'cnpj_instituicao', '[^0-9]', '', 'g') AS cnpj,
        p->>'cnpj_instituicao'                      AS cnpj_raw,
        p->>'nome_instituicao'                      AS instituicao
    FROM agenda_executivo_compromissos c,
         jsonb_array_elements(c.participantes_privados) p
    WHERE c.tem_participantes_privados = true
      AND c.data_inicio >= current_date - 30
      AND p->>'cnpj_instituicao' IS NOT NULL
      AND p->>'cnpj_instituicao' != ''
)
SELECT
    p.compromisso_id,
    p.data_inicio,
    p.hora_inicio,
    p.orgao_sigla,
    p.autoridade_nome,
    p.autoridade_cargo,
    p.assunto,
    p.local,
    p.participante_nome,
    p.cnpj_raw                                      AS cnpj_participante,
    p.instituicao,
    ef.nome_autor                                   AS autor_emenda,
    ef.tipo_emenda,
    ef.ano_emenda,
    sum(ef.valor_recebido)                          AS total_recebido_emendas,
    count(*)                                        AS n_emendas
FROM privados p
JOIN emendas_favorecidos ef ON ef.codigo_favorecido = p.cnpj
WHERE length(p.cnpj) >= 14
GROUP BY
    p.compromisso_id, p.data_inicio, p.hora_inicio,
    p.orgao_sigla, p.autoridade_nome, p.autoridade_cargo,
    p.assunto, p.local, p.participante_nome, p.cnpj_raw,
    p.instituicao, ef.nome_autor, ef.tipo_emenda, ef.ano_emenda
HAVING sum(ef.valor_recebido) > 100000   -- apenas emendas > R$ 100k (reduz ruído)
ORDER BY total_recebido_emendas DESC;
"""

# ── 3. Combo: sancionada + recebeu emenda (máxima prioridade) ─────────────────
ALERTA_COMBO_SANCAO_EMENDA = """
WITH privados AS (
    SELECT
        c.id                                        AS compromisso_id,
        c.data_inicio,
        c.hora_inicio,
        c.orgao_sigla,
        c.autoridade_nome,
        c.assunto,
        p->>'nome'                                  AS participante_nome,
        regexp_replace(p->>'cnpj_instituicao', '[^0-9]', '', 'g') AS cnpj,
        p->>'cnpj_instituicao'                      AS cnpj_raw,
        p->>'nome_instituicao'                      AS instituicao
    FROM agenda_executivo_compromissos c,
         jsonb_array_elements(c.participantes_privados) p
    WHERE c.tem_participantes_privados = true
      AND c.data_inicio >= current_date - 30
      AND p->>'cnpj_instituicao' IS NOT NULL
),
com_sancao AS (
    SELECT p.*, s.tipo_sancao, s.cadastro
    FROM privados p
    JOIN sancoes s ON s.cpf_cnpj = p.cnpj
    WHERE length(p.cnpj) >= 14
),
com_emenda AS (
    SELECT p.cnpj, sum(ef.valor_recebido) AS total_emendas
    FROM privados p
    JOIN emendas_favorecidos ef ON ef.codigo_favorecido = p.cnpj
    WHERE length(p.cnpj) >= 14
    GROUP BY p.cnpj
)
SELECT
    cs.compromisso_id,
    cs.data_inicio,
    cs.hora_inicio,
    cs.orgao_sigla,
    cs.autoridade_nome,
    cs.assunto,
    cs.participante_nome,
    cs.cnpj_raw,
    cs.instituicao,
    cs.cadastro                                     AS tipo_cadastro_sancao,
    cs.tipo_sancao,
    ce.total_emendas
FROM com_sancao cs
JOIN com_emenda ce ON ce.cnpj = cs.cnpj
ORDER BY ce.total_emendas DESC;
"""

# ── 4. Audiências públicas Câmara — últimos 7 dias ───────────────────────────
ALERTA_AUDIENCIAS_SEMANA = """
SELECT
    id,
    data_inicio_date                                AS data,
    data_hora_inicio,
    tipo_evento,
    situacao,
    descricao,
    local_nome                                      AS local,
    orgaos_siglas                                   AS comissoes,
    url_documento_pauta,
    url_registro
FROM agenda_camara_eventos
WHERE data_inicio_date >= current_date - 7
  AND (
      tipo_evento ilike '%audiência pública%'
   OR tipo_evento ilike '%audiencia publica%'
  )
ORDER BY data_hora_inicio DESC;
"""

# ── 5. Ministros com + reuniões privadas nos últimos 7 dias ──────────────────
ALERTA_RANKING_PRIVADOS = """
SELECT
    orgao_sigla,
    autoridade_nome,
    autoridade_cargo,
    count(*)                                        AS n_compromissos_privados,
    sum(n_participantes_privados)                   AS total_participantes_privados,
    min(data_inicio)                                AS primeira_reuniao,
    max(data_inicio)                                AS ultima_reuniao,
    array_agg(DISTINCT assunto ORDER BY assunto)    AS assuntos
FROM agenda_executivo_compromissos
WHERE tem_participantes_privados = true
  AND data_inicio >= current_date - 7
GROUP BY orgao_sigla, autoridade_nome, autoridade_cargo
ORDER BY n_compromissos_privados DESC
LIMIT 10;
"""

# Dicionário de todas as queries com metadados para o runner
QUERIES = {
    "ministerio_sancao": {
        "sql": ALERTA_MINISTERIO_SANCAO,
        "titulo": "🚨 Ministro reuniu com empresa SANCIONADA",
        "prioridade": "ALTA",
        "emoji": "🚨",
    },
    "combo_sancao_emenda": {
        "sql": ALERTA_COMBO_SANCAO_EMENDA,
        "titulo": "🔴 COMBO: empresa sancionada E recebeu emenda na agenda ministerial",
        "prioridade": "CRÍTICA",
        "emoji": "🔴",
    },
    "ministerio_emenda": {
        "sql": ALERTA_MINISTERIO_EMENDA,
        "titulo": "💰 Ministro reuniu com empresa que recebeu emenda (>R$100k)",
        "prioridade": "MÉDIA",
        "emoji": "💰",
    },
    "audiencias_semana": {
        "sql": ALERTA_AUDIENCIAS_SEMANA,
        "titulo": "📢 Audiências públicas na Câmara — últimos 7 dias",
        "prioridade": "INFO",
        "emoji": "📢",
    },
    "ranking_privados": {
        "sql": ALERTA_RANKING_PRIVADOS,
        "titulo": "📊 Ranking: ministros com mais reuniões privadas (7 dias)",
        "prioridade": "INFO",
        "emoji": "📊",
    },
}
