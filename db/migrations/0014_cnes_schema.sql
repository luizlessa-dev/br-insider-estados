-- Migration 0014 — CNES: estabelecimentos de saúde
-- Fonte: apidadosabertos.saude.gov.br/cnes/estabelecimentos
-- Chave de cruzamento com emendas_favorecidos: numero_cnpj

CREATE TABLE IF NOT EXISTS cnes_estabelecimentos (
    codigo_cnes             INTEGER PRIMARY KEY,
    numero_cnpj             TEXT,                  -- pode ser nulo (PF credenciada)
    nome_razao_social       TEXT NOT NULL,
    nome_fantasia           TEXT,
    codigo_tipo_unidade     INTEGER,
    tipo_gestao             TEXT,                  -- M=Municipal, E=Estadual, D=Dupla, S=Sem gestão
    descricao_esfera_administrativa TEXT,
    descricao_natureza_juridica TEXT,
    -- localização
    codigo_uf               INTEGER,
    uf                      TEXT,                  -- sigla, derivada de ibge_municipios
    codigo_municipio        INTEGER,               -- código IBGE 6 dígitos
    codigo_cep              TEXT,
    endereco                TEXT,
    numero                  TEXT,
    bairro                  TEXT,
    latitude                NUMERIC(12,8),
    longitude               NUMERIC(12,8),
    -- contato
    telefone                TEXT,
    email                   TEXT,
    -- capacidades
    atende_sus              BOOLEAN,
    possui_centro_cirurgico BOOLEAN,
    possui_atendimento_hospitalar BOOLEAN,
    possui_atendimento_ambulatorial BOOLEAN,
    -- controle
    data_atualizacao        DATE,
    ingerido_em             TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS cnes_cnpj ON cnes_estabelecimentos(numero_cnpj) WHERE numero_cnpj IS NOT NULL;
CREATE INDEX IF NOT EXISTS cnes_municipio ON cnes_estabelecimentos(codigo_municipio);
CREATE INDEX IF NOT EXISTS cnes_uf ON cnes_estabelecimentos(codigo_uf);
CREATE INDEX IF NOT EXISTS cnes_tipo ON cnes_estabelecimentos(codigo_tipo_unidade);

-- ── View de cruzamento CNES × emendas ─────────────────────────────────
-- Responde: quais estabelecimentos de saúde receberam emendas, de quem e quanto?
CREATE OR REPLACE VIEW cnes_emendas AS
SELECT
    c.codigo_cnes,
    c.nome_razao_social,
    c.nome_fantasia,
    c.codigo_tipo_unidade,
    c.descricao_esfera_administrativa,
    c.uf,
    c.codigo_municipio,
    c.atende_sus,
    c.possui_atendimento_hospitalar,
    -- emendas agregadas
    COUNT(DISTINCT e.id)                    AS total_transacoes,
    COUNT(DISTINCT e.nome_autor)            AS total_autores,
    SUM(e.valor_recebido)                   AS total_recebido,
    MIN(e.ano_emenda)                       AS ano_primeira_emenda,
    MAX(e.ano_emenda)                       AS ano_ultima_emenda
FROM cnes_estabelecimentos c
JOIN emendas_favorecidos e ON e.codigo_favorecido = c.numero_cnpj
GROUP BY
    c.codigo_cnes, c.nome_razao_social, c.nome_fantasia,
    c.codigo_tipo_unidade, c.descricao_esfera_administrativa,
    c.uf, c.codigo_municipio, c.atende_sus, c.possui_atendimento_hospitalar;

COMMENT ON VIEW cnes_emendas IS
    'Cruzamento CNES × emendas_favorecidos por CNPJ. Base para investigação de destinação de emendas para setor saúde.';

-- ── View agregada por CNPJ (deduplicada) ──────────────────────────────
-- Resolve o problema de CNPJs compartilhados entre múltiplas unidades:
-- uma prefeitura usa o mesmo CNPJ em 10 UBS → sem esta view, o total
-- seria multiplicado por 10. Use esta view para rankings e totais reais.
CREATE OR REPLACE VIEW cnes_emendas_por_cnpj AS
SELECT
    c.numero_cnpj,
    MIN(c.nome_razao_social)                AS nome_favorecido,
    c.uf,
    -- contexto do favorecido
    COUNT(DISTINCT c.codigo_cnes)           AS total_unidades_cnes,
    bool_or(c.possui_atendimento_hospitalar) AS tem_hospital,
    bool_or(c.atende_sus)                   AS atende_sus,
    -- emendas (agregadas uma vez por transação, não por unidade)
    SUM(e.valor_recebido)                   AS total_recebido,
    COUNT(DISTINCT e.id)                    AS total_transacoes,
    COUNT(DISTINCT e.nome_autor)            AS total_autores,
    -- detalhe dos autores (array pra drill-down)
    array_agg(DISTINCT e.nome_autor ORDER BY e.nome_autor) AS autores,
    MIN(e.ano_emenda)                       AS ano_primeira_emenda,
    MAX(e.ano_emenda)                       AS ano_ultima_emenda
FROM cnes_estabelecimentos c
JOIN emendas_favorecidos e ON e.codigo_favorecido = c.numero_cnpj
GROUP BY c.numero_cnpj, c.uf
ORDER BY total_recebido DESC;

COMMENT ON VIEW cnes_emendas_por_cnpj IS
    'Ranking de favorecidos de emendas com cadastro CNES, deduplicado por CNPJ. '
    'Evita inflação de totais causada por múltiplas unidades com o mesmo CNPJ.';
