-- bloco 03_types_domains — gerado por split_baseline.py (ordem interna = ordem do dump)
CREATE TYPE "portal_transparencia"."status_ingest" AS ENUM (
    'pendente',
    'em_andamento',
    'sucesso',
    'erro'
);

CREATE TYPE "portal_transparencia"."tipo_cadastro_sancao" AS ENUM (
    'CEIS',
    'CNEP',
    'CEPIM',
    'LENIENCIA'
);

CREATE TYPE "portal_transparencia"."tipo_pessoa" AS ENUM (
    'PJ',
    'PF',
    'SEM_CNPJ_CPF'
);

CREATE TYPE "public"."midia_categoria" AS ENUM (
    'tv_aberta',
    'tv_fechada',
    'digital',
    'radio',
    'impresso',
    'ooh',
    'cinema'
);

CREATE TYPE "public"."midia_metodologia" AS ENUM (
    'ibope_painel',
    'ibope_sam',
    'kantar_tam',
    'youtube_api',
    'portal_transparencia',
    'inter_meios',
    'manual'
);

CREATE TYPE "public"."midia_tipo_evento" AS ENUM (
    'esporte',
    'entretenimento',
    'politica',
    'jornalismo'
);
