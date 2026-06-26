-- Rodada C: Lista Suja MTE + MTE Autos de Infração
-- Situação Cadastral e BACEN não precisam de tabela local (API em tempo real)

CREATE TABLE IF NOT EXISTS sub_lista_suja (
    id               BIGSERIAL PRIMARY KEY,
    cpf_cnpj         TEXT NOT NULL,
    tipo_doc         TEXT,
    nome_empregador  TEXT,
    uf               TEXT,
    municipio        TEXT,
    dat_inclusao     TEXT,
    qtd_trabalhadores TEXT,
    decisao_judicial TEXT,
    created_at       TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sub_lista_suja_doc ON sub_lista_suja (cpf_cnpj);

CREATE TABLE IF NOT EXISTS sub_mte_autos (
    id               BIGSERIAL PRIMARY KEY,
    cnpj             TEXT NOT NULL,
    num_ait          TEXT,
    des_situacao     TEXT,
    des_infracao     TEXT,
    val_multa        NUMERIC,
    dat_ait          DATE,
    sig_uf           TEXT,
    nom_municipio    TEXT,
    nom_razao_social TEXT,
    created_at       TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sub_mte_autos_cnpj ON sub_mte_autos (cnpj);
CREATE INDEX IF NOT EXISTS idx_sub_mte_autos_num  ON sub_mte_autos (num_ait);
