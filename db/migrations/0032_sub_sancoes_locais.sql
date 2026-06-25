-- ─────────────────────────────────────────────────────────────────────────────
-- 0032 — Tabelas locais para CEIS, CNEP e CEPIM
-- Alimentadas pelo seeder sancoes_seeder.py (seed mensal via API paginada)
-- Permitem lookup por CNPJ sem depender de filtro da API do Portal Transparência
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS sub_ceis (
    id                  BIGINT        PRIMARY KEY,
    cnpj_cpf            TEXT          NOT NULL,  -- pessoa.cnpjFormatado ou cpfFormatado
    nome                TEXT,
    tipo_sancao         TEXT,
    orgao_sancionador   TEXT,
    esfera              TEXT,
    data_inicio         DATE,
    data_fim            DATE,
    numero_processo     TEXT,
    fundamentacao       TEXT,
    texto_publicacao    TEXT,
    link_publicacao     TEXT,
    atualizado_em       TIMESTAMPTZ   NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_sub_ceis_cnpj ON sub_ceis(cnpj_cpf);

-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS sub_cnep (
    id                  BIGINT        PRIMARY KEY,
    cnpj_cpf            TEXT          NOT NULL,
    nome                TEXT,
    tipo_sancao         TEXT,
    orgao_sancionador   TEXT,
    esfera              TEXT,
    data_inicio         DATE,
    data_fim            DATE,
    numero_processo     TEXT,
    fundamentacao       TEXT,
    texto_publicacao    TEXT,
    link_publicacao     TEXT,
    atualizado_em       TIMESTAMPTZ   NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_sub_cnep_cnpj ON sub_cnep(cnpj_cpf);

-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS sub_cepim (
    id                  BIGINT        PRIMARY KEY,
    cnpj                TEXT          NOT NULL,  -- pessoaJuridica.cnpjFormatado
    nome                TEXT,
    motivo              TEXT,
    orgao_superior      TEXT,
    num_convenio        TEXT,
    data_referencia     DATE,
    atualizado_em       TIMESTAMPTZ   NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_sub_cepim_cnpj ON sub_cepim(cnpj);
