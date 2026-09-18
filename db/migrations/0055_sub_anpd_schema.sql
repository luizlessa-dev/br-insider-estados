-- Processos administrativos sancionadores da ANPD (LGPD)
-- Fonte primária: XLSX oficial do Painel da Fiscalização (aba PAS), atualizado mensalmente
-- Complementado por: página "Decisões em Processos Sancionadores" (status fino + PDF do
-- Relatório de Instrução) e páginas "Saiba como fiscalizamos" (cross-check de CNPJ/conduta)
-- Populado pelo seeder mensal ingestao/subradar/anpd_seeder.py

CREATE TABLE IF NOT EXISTS sub_anpd (
    id                  BIGSERIAL     PRIMARY KEY,
    cnpj_cpf            TEXT,                    -- dígitos only; nullable (salvaguarda — não observado null nos 36 PAS inspecionados)
    ente_fiscalizado    TEXT          NOT NULL,
    num_processo        TEXT          NOT NULL,
    setor               TEXT,                    -- 'Público' | 'Privado' (coluna Setor do XLSX)
    conduta_apurada     TEXT,                    -- condutas imputadas/sancionadas, última instância disponível
    des_fase            TEXT          NOT NULL,  -- 'Em andamento' | 'Concluído' (XLSX: Situação atual)
    des_situacao        TEXT,                    -- status fino ("Recurso em análise pelo Conselho Diretor" etc — página Decisões)
    val_multa           NUMERIC,                 -- nullable; última instância disponível (pós CD > pós reconsideração > 1ª instância)
    dat_instauracao     DATE,
    dat_decisao_final   DATE,
    fundamentacao       TEXT,                    -- resumo extraído do PDF do Relatório de Instrução
    url_relatorio       TEXT,                    -- link direto pro PDF do Relatório de Instrução
    url_fonte           TEXT,                    -- link Pesquisa Pública SEI / página de origem do processo
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_sub_anpd_processo ON sub_anpd (num_processo);
CREATE INDEX IF NOT EXISTS idx_sub_anpd_cnpj ON sub_anpd (cnpj_cpf);
