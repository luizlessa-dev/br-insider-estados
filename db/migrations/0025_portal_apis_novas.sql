-- Migration 0025: PEPs, Notas Fiscais, Contratos, Licitações, Emendas API
-- The Brasilia Insider · 2026-06-20

-- ── PEPs ──────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.peps (
    id                  integer PRIMARY KEY,
    cpf                 text,
    cpf_formatado       text,
    nome                text,
    nome_social         text,
    funcao              text,
    data_inicio_vinculo date,
    data_fim_vinculo    date,
    orgao_codigo        text,
    orgao_descricao     text,
    classificacao_pep   text,
    tipo_pep            text,
    relacionamentos     jsonb    DEFAULT '[]',
    updated_at          timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS peps_cpf_idx ON public.peps (cpf);
CREATE INDEX IF NOT EXISTS peps_nome_idx ON public.peps USING gin(to_tsvector('portuguese', coalesce(nome, '')));
CREATE INDEX IF NOT EXISTS peps_data_inicio_idx ON public.peps (data_inicio_vinculo);

CREATE TABLE IF NOT EXISTS public.peps_ingest_log (
    id          serial PRIMARY KEY,
    dataset     text,
    status      text,
    n_novos     integer DEFAULT 0,
    erro        text,
    started_at  timestamptz DEFAULT now(),
    finished_at timestamptz
);


-- ── Notas Fiscais ─────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.notas_fiscais (
    chave                       text PRIMARY KEY,  -- 44 dígitos
    numero                      text,
    serie                       text,
    data_emissao                date,
    data_processamento          date,
    emitente_cnpj               text,
    emitente_razao_social       text,
    emitente_uf                 char(2),
    emitente_municipio          text,
    destinatario_cnpj           text,
    destinatario_cpf            text,
    destinatario_razao_social   text,
    destinatario_uf             char(2),
    valor_nota                  numeric(18,2),
    natureza_operacao           text,
    situacao                    text,
    updated_at                  timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS nf_emitente_cnpj_idx ON public.notas_fiscais (emitente_cnpj);
CREATE INDEX IF NOT EXISTS nf_destinatario_cnpj_idx ON public.notas_fiscais (destinatario_cnpj);
CREATE INDEX IF NOT EXISTS nf_data_emissao_idx ON public.notas_fiscais (data_emissao);
CREATE INDEX IF NOT EXISTS nf_emitente_uf_idx ON public.notas_fiscais (emitente_uf);

CREATE TABLE IF NOT EXISTS public.notas_fiscais_ingest_log (
    id          serial PRIMARY KEY,
    descricao   text,
    status      text,
    n_novos     integer DEFAULT 0,
    erro        text,
    started_at  timestamptz DEFAULT now(),
    finished_at timestamptz
);


-- ── Contratos Federais ────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.contratos_federais (
    id                      integer PRIMARY KEY,  -- ID da API
    numero                  text,
    objeto                  text,
    data_assinatura         date,
    data_publicacao_tcu     date,
    data_inicio_vigencia    date,
    data_fim_vigencia       date,
    valor                   numeric(18,2),
    valor_aditivos          numeric(18,2),
    valor_total             numeric(18,2),
    situacao_codigo         text,
    situacao_descricao      text,
    fornecedor_cnpj         text,
    fornecedor_cpf          text,
    fornecedor_nome         text,
    fornecedor_razao_social text,
    ug_codigo               text,
    ug_descricao            text,
    orgao_codigo            text,
    orgao_descricao         text,
    orgao_poder             text,
    modalidade_codigo       text,
    modalidade_descricao    text,
    tipo_contrato           text,
    licitacao_numero        text,
    licitacao_modalidade    text,
    updated_at              timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS contratos_fornecedor_cnpj_idx ON public.contratos_federais (fornecedor_cnpj);
CREATE INDEX IF NOT EXISTS contratos_orgao_idx ON public.contratos_federais (orgao_codigo);
CREATE INDEX IF NOT EXISTS contratos_data_assinatura_idx ON public.contratos_federais (data_assinatura);
CREATE INDEX IF NOT EXISTS contratos_valor_total_idx ON public.contratos_federais (valor_total DESC);

CREATE TABLE IF NOT EXISTS public.contratos_ingest_log (
    id          serial PRIMARY KEY,
    descricao   text,
    status      text,
    n_novos     integer DEFAULT 0,
    erro        text,
    started_at  timestamptz DEFAULT now(),
    finished_at timestamptz
);


-- ── Licitações ────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.licitacoes (
    id                   integer PRIMARY KEY,
    numero               text,
    objeto               text,
    data_abertura        date,
    data_publicacao      date,
    situacao_codigo      text,
    situacao_descricao   text,
    modalidade_codigo    text,
    modalidade_descricao text,
    ug_codigo            text,
    ug_descricao         text,
    orgao_codigo         text,
    orgao_descricao      text,
    valor_estimado       numeric(18,2),
    tipo_licitacao       text,
    numero_processo      text,
    updated_at           timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS licitacoes_orgao_idx ON public.licitacoes (orgao_codigo);
CREATE INDEX IF NOT EXISTS licitacoes_data_publicacao_idx ON public.licitacoes (data_publicacao);
CREATE INDEX IF NOT EXISTS licitacoes_modalidade_idx ON public.licitacoes (modalidade_codigo);

CREATE TABLE IF NOT EXISTS public.licitacoes_participantes (
    id                      serial PRIMARY KEY,
    licitacao_id            integer REFERENCES public.licitacoes(id) ON DELETE CASCADE,
    cnpj                    text,
    cpf                     text,
    nome                    text,
    situacao_participante   text,
    situacao_fornecedor     text,
    valor_proposta          numeric(18,2),
    updated_at              timestamptz DEFAULT now(),
    UNIQUE (licitacao_id, cnpj, cpf)
);

CREATE INDEX IF NOT EXISTS licit_part_cnpj_idx ON public.licitacoes_participantes (cnpj);
CREATE INDEX IF NOT EXISTS licit_part_licitacao_idx ON public.licitacoes_participantes (licitacao_id);

CREATE TABLE IF NOT EXISTS public.licitacoes_ingest_log (
    id          serial PRIMARY KEY,
    descricao   text,
    status      text,
    n_novos     integer DEFAULT 0,
    erro        text,
    started_at  timestamptz DEFAULT now(),
    finished_at timestamptz
);


-- ── Emendas API ───────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.emendas_api (
    codigo                  text PRIMARY KEY,   -- chave de cruzamento com emendas_favorecidos
    ano                     integer,
    tipo                    text,               -- IND / COL / BAN / REL
    subtipo                 text,
    autor_nome              text,
    autor_cpf               text,
    autor_partido           text,
    autor_uf                char(2),
    autor_codigo_portal     text,
    funcao_codigo           text,
    funcao_descricao        text,
    subfuncao_codigo        text,
    subfuncao_descricao     text,
    localidade_ibge         text,
    localidade_descricao    text,
    valor_empenhado         numeric(18,2),
    valor_liquidado         numeric(18,2),
    valor_pago              numeric(18,2),
    valor_resto_pagar       numeric(18,2),
    updated_at              timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS emendas_api_ano_idx ON public.emendas_api (ano);
CREATE INDEX IF NOT EXISTS emendas_api_autor_cpf_idx ON public.emendas_api (autor_cpf);
CREATE INDEX IF NOT EXISTS emendas_api_autor_uf_idx ON public.emendas_api (autor_uf);
CREATE INDEX IF NOT EXISTS emendas_api_funcao_idx ON public.emendas_api (funcao_codigo);
CREATE INDEX IF NOT EXISTS emendas_api_localidade_idx ON public.emendas_api (localidade_ibge);

CREATE TABLE IF NOT EXISTS public.emendas_api_documentos (
    id              serial PRIMARY KEY,
    emenda_codigo   text REFERENCES public.emendas_api(codigo) ON DELETE CASCADE,
    codigo_documento text,
    tipo_documento  text,
    data            date,
    valor           numeric(18,2),
    orgao           text,
    acao            text,
    favorecido_cnpj text,
    favorecido_nome text,
    updated_at      timestamptz DEFAULT now(),
    UNIQUE (emenda_codigo, codigo_documento)
);

CREATE INDEX IF NOT EXISTS emendas_docs_favorecido_idx ON public.emendas_api_documentos (favorecido_cnpj);
CREATE INDEX IF NOT EXISTS emendas_docs_emenda_idx ON public.emendas_api_documentos (emenda_codigo);

CREATE TABLE IF NOT EXISTS public.emendas_api_ingest_log (
    id          serial PRIMARY KEY,
    dataset     text,
    status      text,
    n_novos     integer DEFAULT 0,
    erro        text,
    started_at  timestamptz DEFAULT now(),
    finished_at timestamptz
);


-- ── Views de cruzamento ───────────────────────────────────────────────────────

-- Emendas API enriquecidas com favorecidos (CSV)
CREATE OR REPLACE VIEW public.v_emenda_autor_favorecido AS
SELECT
    ea.codigo,
    ea.ano,
    ea.tipo,
    ea.autor_nome,
    ea.autor_partido,
    ea.autor_uf,
    ea.funcao_descricao,
    ea.subfuncao_descricao,
    ea.localidade_descricao,
    ea.valor_empenhado,
    ef.codigo_favorecido,
    ef.favorecido,
    ef.valor_recebido,
    ef.uf_favorecido,
    ef.municipio_favorecido
FROM public.emendas_api ea
JOIN public.emendas_favorecidos ef ON ea.codigo = ef.codigo_emenda;

-- Contratos de empresas que também receberam emendas
CREATE OR REPLACE VIEW public.v_empresa_emenda_contrato AS
SELECT
    c.fornecedor_cnpj        AS cnpj,
    c.fornecedor_razao_social AS razao_social,
    count(DISTINCT c.id)     AS total_contratos,
    sum(c.valor_total)       AS valor_total_contratos,
    count(DISTINCT ef.codigo_emenda) AS total_emendas,
    sum(ef.valor_recebido)   AS valor_total_emendas
FROM public.contratos_federais c
JOIN public.emendas_favorecidos ef ON c.fornecedor_cnpj = ef.codigo_favorecido
GROUP BY c.fornecedor_cnpj, c.fornecedor_razao_social;

-- PEPs que são parlamentares com emendas
CREATE OR REPLACE VIEW public.v_pep_emenda AS
SELECT
    p.nome                AS pep_nome,
    p.cpf,
    p.funcao,
    p.orgao_descricao,
    p.classificacao_pep,
    ea.codigo             AS emenda_codigo,
    ea.ano,
    ea.tipo,
    ea.valor_empenhado,
    ea.funcao_descricao,
    ea.localidade_descricao
FROM public.peps p
JOIN public.emendas_api ea ON p.cpf = ea.autor_cpf;
