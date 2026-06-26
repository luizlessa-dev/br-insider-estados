-- Tabelas locais para seeds bulk: IBAMA e CVM PAS
-- Aplicar: supabase db query --linked < db/migrations/0033_sub_ibama_cvm.sql

CREATE TABLE IF NOT EXISTS sub_ibama (
    id                    BIGSERIAL PRIMARY KEY,
    cpf_cnpj_infrator     TEXT NOT NULL,
    num_auto_infracao     TEXT,
    des_situacao_auto     TEXT,
    dat_auto_de_infracao  TEXT,
    des_infracao          TEXT,
    val_auto_infracao     NUMERIC,
    nom_municipio         TEXT,
    sig_uf                CHAR(2),
    num_processo          TEXT,
    nom_infrator          TEXT,
    created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sub_ibama_cnpj ON sub_ibama (cpf_cnpj_infrator);
CREATE INDEX IF NOT EXISTS idx_sub_ibama_auto ON sub_ibama (num_auto_infracao);

CREATE TABLE IF NOT EXISTS sub_cvm_pas (
    id                       BIGSERIAL PRIMARY KEY,
    cpf_cnpj                 TEXT NOT NULL,
    nom_acusado              TEXT,
    num_pas                  TEXT,
    des_sancao               TEXT,
    val_multa                NUMERIC,
    des_fase                 TEXT,
    des_tipo_irregularidade  TEXT,
    dat_julgamento           DATE,
    des_orgao_julgador       TEXT,
    created_at               TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sub_cvm_pas_cnpj ON sub_cvm_pas (cpf_cnpj);
CREATE INDEX IF NOT EXISTS idx_sub_cvm_pas_num  ON sub_cvm_pas (num_pas);
