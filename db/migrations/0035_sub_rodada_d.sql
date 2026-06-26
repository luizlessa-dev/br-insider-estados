-- Rodada D: ANEEL, ANS, DataJud, TCU
-- DataJud e TCU não precisam de tabela local (consulta em tempo real)

CREATE TABLE IF NOT EXISTS sub_aneel_autos (
    id                       BIGSERIAL PRIMARY KEY,
    cnpj                     TEXT NOT NULL,
    num_auto_infracao        TEXT,
    nom_agente_fiscalizado   TEXT,
    nom_natureza_fiscalizacao TEXT,
    dsc_tipo_penalidade      TEXT,
    vlr_penalidade           NUMERIC,
    dat_lavratura            DATE,
    sig_fiscalizador         TEXT,
    num_processo             TEXT,
    dsc_decisao_juizo        TEXT,
    dsc_decisao_diretoria    TEXT,
    created_at               TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sub_aneel_cnpj ON sub_aneel_autos (cnpj);
CREATE INDEX IF NOT EXISTS idx_sub_aneel_num  ON sub_aneel_autos (num_auto_infracao);

CREATE TABLE IF NOT EXISTS sub_ans_operadoras (
    id              BIGSERIAL PRIMARY KEY,
    cnpj            TEXT NOT NULL,
    registro_ans    TEXT,
    razao_social    TEXT,
    nome_fantasia   TEXT,
    modalidade      TEXT,
    situacao        TEXT,
    uf              TEXT,
    municipio       TEXT,
    regiao          TEXT,
    dat_registro    DATE,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sub_ans_cnpj     ON sub_ans_operadoras (cnpj);
CREATE INDEX IF NOT EXISTS idx_sub_ans_registro ON sub_ans_operadoras (registro_ans);
