-- bloco 00_prelude — gerado por split_baseline.py (ordem interna = ordem do dump)
SET statement_timeout = 0;

SET lock_timeout = 0;

SET idle_in_transaction_session_timeout = 0;

SET client_encoding = 'UTF8';

SET standard_conforming_strings = on;

SELECT pg_catalog.set_config('search_path', '', false);

SET check_function_bodies = false;

SET xmloption = content;

SET client_min_messages = warning;

SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = "heap";
-- bloco 01_extensions — extensões nos MESMOS schemas de produção.
-- pg_cron e pg_net: apenas CREATE EXTENSION (criam os schemas cron/net);
-- nenhum dado operacional, nenhum cron.job, nenhuma função interna copiada.
create extension if not exists pg_trgm    with schema public;
create extension if not exists unaccent   with schema public;
create extension if not exists http       with schema public;
create extension if not exists pg_net     with schema public;
create extension if not exists vector     with schema public;
create extension if not exists pgcrypto   with schema extensions;
create extension if not exists "uuid-ossp" with schema extensions;
create extension if not exists pg_stat_statements with schema extensions;
do $$ begin
  create extension if not exists pg_cron;
exception when others then
  raise notice 'pg_cron indisponível neste ambiente: %', sqlerrm;
end $$;
-- bloco 02_schemas — gerado por split_baseline.py (ordem interna = ordem do dump)
CREATE SCHEMA IF NOT EXISTS "analytics";

CREATE SCHEMA IF NOT EXISTS "bcb";

CREATE SCHEMA IF NOT EXISTS "cidadania_ai";

CREATE SCHEMA IF NOT EXISTS "homabrasil";

CREATE SCHEMA IF NOT EXISTS "public";

CREATE SCHEMA IF NOT EXISTS "portal_transparencia";

CREATE SCHEMA IF NOT EXISTS "public_api";
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
-- bloco 04_sequences — gerado por split_baseline.py (ordem interna = ordem do dump)
CREATE SEQUENCE IF NOT EXISTS "bcb"."if_balanco_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "bcb"."scr_operacoes_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "bcb"."sicor_credito_rural_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "homabrasil"."desastres_historico_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "homabrasil"."homa_score_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "homabrasil"."infraestrutura_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "homabrasil"."municipios_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "homabrasil"."qualidade_vida_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "homabrasil"."risco_climatico_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "portal_transparencia"."cartoes_pagamento_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "portal_transparencia"."ingest_runs_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "portal_transparencia"."notas_fiscais_itens_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "portal_transparencia"."sancoes_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."aleba_despesas_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."alesc_despesas_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."assessores_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."autores_parlamentares_map_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."bets_licenciadas_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."casas_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."cbf_cnpjs_vinculados_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."cbf_socios_federacoes_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."ceaf_ingest_log_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."cgu_pad_ingest_log_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."cnpj_ingest_log_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."contratos_ingest_log_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."convenios_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."cpgf_transacoes_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."dou_alertas_cruzamento_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."dou_publicacoes_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."ele2026_alertas_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."ele2026_financiamento_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."ele2026_gastos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."ele2026_ingest_log_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."emendas_api_documentos_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."emendas_api_ingest_log_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."estados_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."execucao_financeira_siafi_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."execucao_financeira_transferencias_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."ibama_autuacoes_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."ibge_indicadores_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."indicadores_macroeconomicos_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."leiloes_leiloeiros_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."leiloes_processos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."licitacoes_ingest_log_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."licitacoes_participantes_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."ministerios_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."notas_fiscais_ingest_log_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."orgaos_federais_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."peps_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."peps_ingest_log_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."pgfn_divida_federacoes_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."portal_sancionados_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."sancoes_ingest_log_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."sebrae_contratos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."sebrae_convenios_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."sebrae_emendas_contratos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."sebrae_emendas_convenios_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."sebrae_licitacoes_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."sebrae_patrocinios_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."sen_proposicoes_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."senac_contratos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."senac_licitacoes_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."senar_contratos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."senar_licitacoes_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."senar_transferencias_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."sesc_contratos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."sesc_convenios_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."siafi_ingestao_log_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."sisi_contratos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."sisi_convenios_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."sisi_licitacoes_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."sisi_licitacoes_participantes_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."sp_contratos_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."sp_despesas_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."stf_ingestao_log_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."sub_aneel_autos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."sub_ans_operadoras_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."sub_cvm_pas_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."sub_ibama_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."sub_lista_suja_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."sub_mte_autos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."tribunais_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."tse_bens_candidatos_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."tse_despesas_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."tse_ingest_log_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS "public"."tse_receitas_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
-- bloco 05_tables — gerado por split_baseline.py (ordem interna = ordem do dump)
CREATE TABLE IF NOT EXISTS "public"."emendas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "mandato_id" "uuid",
    "municipio_id" "uuid",
    "tipo" "text",
    "valor" numeric,
    "ano" integer,
    "data_liberacao" "date",
    "ministerio" "text",
    "objeto" "text",
    "created_at" timestamp without time zone DEFAULT "now"(),
    "valor_empenhado" numeric,
    "valor_liquidado" numeric,
    "valor_pago" numeric,
    "codigo_emenda" "text",
    "funcao" "text",
    "subfuncao" "text",
    "municipio" "text",
    "uf" "text",
    "autor_orcamentario_id" "uuid",
    "uf_destino" "text",
    "municipio_nome" "text",
    "parlamentar_id" "uuid",
    "ministerio_id" integer,
    "orgao_id" integer,
    "autor_nome" "text",
    "orgao_executor" "text",
    "descricao" "text",
    "subtipo" "text",
    "beneficiario_nome" "text",
    "beneficiario_cnpj" "text",
    "valor_resto_inscrito" numeric DEFAULT 0,
    "valor_resto_cancelado" numeric DEFAULT 0,
    "valor_resto_pago" numeric DEFAULT 0
);

CREATE TABLE IF NOT EXISTS "public"."mandatos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "parlamentar_id" "uuid",
    "legislatura" integer,
    "inicio" "date",
    "fim" "date",
    "cargo" "text" DEFAULT 'Deputado Federal'::"text",
    "ativo" boolean DEFAULT true,
    "created_at" timestamp without time zone DEFAULT "now"(),
    "autor_orcamentario_id" "uuid",
    "parlamentar_uid" "uuid"
);

CREATE TABLE IF NOT EXISTS "public"."parlamentares" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "id_camara" integer,
    "nome" "text",
    "nome_parlamentar" "text",
    "partido" "text",
    "uf" "text",
    "foto_url" "text",
    "created_at" timestamp without time zone DEFAULT "now"(),
    "parlamentar_uid" "uuid" DEFAULT "gen_random_uuid"(),
    "identity_status" "text" DEFAULT 'verified'::"text",
    "autor_orcamentario_id" "uuid",
    "ativo" boolean DEFAULT true,
    "casa_legislativa" "text",
    "fonte_oficial" "text",
    "legislatura" integer,
    "mandato_id" "text",
    "email" "text",
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "partido_atual" "text",
    "id_senado" bigint,
    "cpf" "text",
    "id_tse_candidato" "text"
);

CREATE TABLE IF NOT EXISTS "bcb"."if_balanco" (
    "id" bigint NOT NULL,
    "cod_inst" "text" NOT NULL,
    "ano_mes" "text" NOT NULL,
    "nome_relatorio" "text" NOT NULL,
    "numero_relatorio" "text",
    "grupo" "text",
    "conta" "text",
    "nome_coluna" "text" NOT NULL,
    "saldo" numeric(22,2),
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "bcb"."if_cadastro" (
    "cod_inst" "text" NOT NULL,
    "nome_instituicao" "text" NOT NULL,
    "cnpj_lider" "text",
    "data_inicio_atividade" "date",
    "segmento" "text",
    "atividade" "text",
    "uf" "text",
    "municipio" "text",
    "situacao" "text",
    "cod_conglomerado_fin" "text",
    "cod_conglomerado_pru" "text",
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "bcb"."scr_operacoes" (
    "id" bigint NOT NULL,
    "data_base" "date" NOT NULL,
    "uf" "text",
    "segmento" "text" NOT NULL,
    "cliente" "text",
    "cnae_ocupacao" "text",
    "porte" "text",
    "modalidade" "text" NOT NULL,
    "submodalidade" "text",
    "origem" "text",
    "indexador" "text",
    "numero_de_operacoes" integer,
    "a_vencer_ate_90_dias" numeric(18,2),
    "a_vencer_de_91_ate_360_dias" numeric(18,2),
    "a_vencer_de_361_ate_1080_dias" numeric(18,2),
    "a_vencer_de_1081_ate_1800_dias" numeric(18,2),
    "a_vencer_de_1801_ate_5400_dias" numeric(18,2),
    "a_vencer_acima_de_5400_dias" numeric(18,2),
    "carteira_a_vencer" numeric(18,2),
    "vencido_de_15_ate_90_dias" numeric(18,2),
    "vencido_acima_de_90_dias" numeric(18,2),
    "carteira_vencida" numeric(18,2),
    "carteira_ativa" numeric(18,2),
    "carteira_inadimplencia" numeric(18,2),
    "ativo_problematico" numeric(18,2),
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "bcb"."sicor_credito_rural" (
    "id" bigint NOT NULL,
    "mes_emissao" integer NOT NULL,
    "ano_emissao" integer NOT NULL,
    "cnpj_if" "text" NOT NULL,
    "nome_if" "text",
    "segmento_if" "text",
    "cd_municipio_ibge" "text",
    "municipio" "text",
    "uf" "text" NOT NULL,
    "produto" "text",
    "finalidade" "text" NOT NULL,
    "cd_programa" "text",
    "nome_programa" "text",
    "cd_fonte_recurso" "text",
    "nome_fonte_recurso" "text",
    "cd_tipo_beneficiario" "text",
    "qt_contratos" integer,
    "vl_total" numeric(18,2),
    "area_ha" numeric(14,4),
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."emendas_favorecidos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "codigo_emenda" "text" NOT NULL,
    "codigo_autor" "text",
    "nome_autor" "text",
    "numero_emenda" "text",
    "tipo_emenda" "text",
    "subtipo" "text",
    "ano_emenda" integer,
    "ano_mes_pagamento" "text",
    "codigo_favorecido" "text",
    "favorecido" "text",
    "natureza_juridica" "text",
    "tipo_favorecido" "text",
    "uf_favorecido" "text",
    "municipio_favorecido" "text",
    "valor_recebido" numeric NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "cidadania_ai"."cases" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "category" "text" NOT NULL,
    "orgao_alvo" "text",
    "uf" "text",
    "municipio" "text",
    "facts" "text" NOT NULL,
    "objective" "text",
    "urgency" boolean DEFAULT false NOT NULL,
    "deadline_notes" "text",
    "evidence_links" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "status" "text" DEFAULT 'analyzed'::"text" NOT NULL,
    "analysis_json" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "cidadania_ai"."generated_docs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "case_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "doc_type" "text" NOT NULL,
    "doc_text" "text" NOT NULL,
    "format" "text" DEFAULT 'txt'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "cidadania_ai"."library_docs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "collection" "text" NOT NULL,
    "title" "text" NOT NULL,
    "source" "text",
    "content" "text" NOT NULL,
    "tags" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "embedding" "public"."vector"(1536),
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "cidadania_ai"."messages" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "case_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "role" "text" NOT NULL,
    "content" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "messages_role_check" CHECK (("role" = ANY (ARRAY['user'::"text", 'assistant'::"text", 'system'::"text"])))
);

CREATE TABLE IF NOT EXISTS "homabrasil"."desastres_historico" (
    "id" integer NOT NULL,
    "municipio_id" integer,
    "ano" smallint NOT NULL,
    "mes" smallint,
    "tipo_desastre" "text" NOT NULL,
    "decreto_federal" boolean DEFAULT false,
    "mortos" integer DEFAULT 0,
    "desabrigados" integer DEFAULT 0,
    "afetados" integer DEFAULT 0,
    "fonte" "text" DEFAULT 's2id'::"text"
);

CREATE TABLE IF NOT EXISTS "homabrasil"."homa_score" (
    "id" integer NOT NULL,
    "municipio_id" integer,
    "ano_ref" smallint NOT NULL,
    "score_qualidade_vida" numeric(5,2),
    "score_infraestrutura" numeric(5,2),
    "score_seguranca" numeric(5,2),
    "score_clima" numeric(5,2),
    "peso_qualidade_vida" numeric(3,2) DEFAULT 0.25,
    "peso_infraestrutura" numeric(3,2) DEFAULT 0.20,
    "peso_seguranca" numeric(3,2) DEFAULT 0.20,
    "peso_clima" numeric(3,2) DEFAULT 0.35,
    "homa_score" numeric(5,2),
    "tier" character(1),
    "calculado_em" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "homabrasil"."infraestrutura" (
    "id" integer NOT NULL,
    "municipio_id" integer,
    "ano" smallint NOT NULL,
    "cobertura_agua_pct" numeric(5,2),
    "cobertura_esgoto_pct" numeric(5,2),
    "coleta_lixo_pct" numeric(5,2),
    "leitos_sus_por_1000" numeric(6,3),
    "ubs_por_10000" numeric(6,3),
    "ideb_anos_iniciais" numeric(4,2),
    "ideb_anos_finais" numeric(4,2),
    "fonte" "text"
);

CREATE TABLE IF NOT EXISTS "homabrasil"."municipios" (
    "id" integer NOT NULL,
    "codigo_ibge" character(7) NOT NULL,
    "nome" "text" NOT NULL,
    "uf" character(2) NOT NULL,
    "regiao" "text",
    "populacao" integer,
    "area_km2" numeric,
    "lat" numeric,
    "lng" numeric,
    "updated_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "homabrasil"."qualidade_vida" (
    "id" integer NOT NULL,
    "municipio_id" integer,
    "ano" smallint NOT NULL,
    "idhm" numeric(4,3),
    "idhm_renda" numeric(4,3),
    "idhm_educacao" numeric(4,3),
    "idhm_longevidade" numeric(4,3),
    "renda_per_capita" numeric,
    "gini" numeric(4,3),
    "populacao_urbana_pct" numeric(5,2),
    "fonte" "text" DEFAULT 'atlas_brasil'::"text"
);

CREATE TABLE IF NOT EXISTS "homabrasil"."risco_climatico" (
    "id" integer NOT NULL,
    "municipio_id" integer,
    "ano_ref" smallint NOT NULL,
    "risco_enchente" numeric(5,2) DEFAULT 0,
    "risco_deslizamento" numeric(5,2) DEFAULT 0,
    "risco_seca" numeric(5,2) DEFAULT 0,
    "risco_calor_extremo" numeric(5,2) DEFAULT 0,
    "monitorado_cemaden" boolean DEFAULT false,
    "total_decretos_10anos" integer DEFAULT 0,
    "total_mortos_10anos" integer DEFAULT 0,
    "total_afetados_10anos" integer DEFAULT 0,
    "risco_climatico_score" numeric(5,2)
);

CREATE TABLE IF NOT EXISTS "portal_transparencia"."cartoes_pagamento" (
    "id" bigint NOT NULL,
    "cpf_portador_mascarado" "text" NOT NULL,
    "nome_portador" "text" NOT NULL,
    "codigo_orgao_superior" "text" NOT NULL,
    "nome_orgao_superior" "text",
    "codigo_orgao" "text" NOT NULL,
    "nome_orgao" "text",
    "codigo_unidade_gestora" "text",
    "nome_unidade_gestora" "text",
    "data_transacao" "date" NOT NULL,
    "tipo_transacao" "text",
    "cnpj_estabelecimento" "text",
    "nome_estabelecimento" "text",
    "valor" numeric(14,2) NOT NULL,
    "fonte_arquivo" "text",
    "ingerido_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "portal_transparencia"."favorecidos" (
    "cnpj_cpf" "text" NOT NULL,
    "tipo" "portal_transparencia"."tipo_pessoa" NOT NULL,
    "razao_social" "text",
    "nome_fantasia" "text",
    "uf" "text",
    "municipio_ibge" "text",
    "municipio_nome" "text",
    "data_primeira_aparicao" "date",
    "data_ultima_aparicao" "date",
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "portal_transparencia"."notas_fiscais" (
    "chave_nfe" "text" NOT NULL,
    "cnpj_emitente" "text" NOT NULL,
    "cnpj_destinatario" "text",
    "data_emissao" "date" NOT NULL,
    "valor_total" numeric(14,2) NOT NULL,
    "natureza_operacao" "text",
    "uf_emitente" "text",
    "modelo" "text",
    "fonte_arquivo" "text",
    "ingerido_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "portal_transparencia"."sancoes" (
    "id" bigint NOT NULL,
    "cadastro" "portal_transparencia"."tipo_cadastro_sancao" NOT NULL,
    "cnpj_cpf_sancionado" "text" NOT NULL,
    "razao_social_no_momento" "text",
    "tipo_sancao" "text" NOT NULL,
    "fundamentacao_legal" "text",
    "numero_processo" "text",
    "data_inicio_sancao" "date" NOT NULL,
    "data_final_sancao" "date",
    "orgao_sancionador" "text",
    "uf_orgao_sancionador" "text",
    "origem_informacao" "text",
    "fonte_arquivo" "text",
    "ingerido_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "portal_transparencia"."ingest_runs" (
    "id" bigint NOT NULL,
    "base" "text" NOT NULL,
    "competencia" "text" NOT NULL,
    "url_origem" "text" NOT NULL,
    "hash_arquivo" "text",
    "bytes_arquivo" bigint,
    "linhas_processadas" integer,
    "linhas_inseridas" integer,
    "linhas_atualizadas" integer,
    "linhas_descartadas" integer,
    "status" "portal_transparencia"."status_ingest" DEFAULT 'pendente'::"portal_transparencia"."status_ingest" NOT NULL,
    "erro_mensagem" "text",
    "iniciado_em" timestamp with time zone DEFAULT "now"() NOT NULL,
    "finalizado_em" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS "portal_transparencia"."notas_fiscais_itens" (
    "id" bigint NOT NULL,
    "chave_nfe" "text" NOT NULL,
    "numero_item" integer NOT NULL,
    "descricao" "text" NOT NULL,
    "ncm" "text",
    "quantidade" numeric(14,4),
    "unidade" "text",
    "valor_unitario" numeric(14,4),
    "valor_total" numeric(14,2)
);

CREATE TABLE IF NOT EXISTS "public"."agenda_camara_eventos" (
    "id" "text" NOT NULL,
    "data_hora_inicio" timestamp with time zone,
    "data_hora_fim" timestamp with time zone,
    "data_inicio_date" "date",
    "tipo_evento_cod" integer,
    "tipo_evento" "text",
    "situacao" "text",
    "descricao" "text",
    "local_nome" "text",
    "local_predio" "text",
    "local_sala" "text",
    "local_andar" "text",
    "local_externo" "text",
    "orgaos" "jsonb",
    "orgaos_siglas" "text"[],
    "url_documento_pauta" "text",
    "url_registro" "text",
    "url_convite" "text",
    "requerimentos" "jsonb",
    "raw" "jsonb",
    "ingested_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."agenda_executivo_compromissos" (
    "id" "text" NOT NULL,
    "tipo_compromisso" "text",
    "assunto" "text",
    "detalhamento" "text",
    "local" "text",
    "objetivos" "text",
    "orgao_id" integer,
    "orgao_sigla" "text",
    "autoridade_nome" "text",
    "autoridade_cargo" "text",
    "apo_id" integer,
    "data_inicio" "date",
    "data_termino" "date",
    "hora_inicio" "text",
    "hora_termino" "text",
    "tem_participantes_privados" boolean DEFAULT false,
    "n_participantes_privados" integer DEFAULT 0,
    "participantes_publicos" "jsonb",
    "participantes_privados" "jsonb",
    "representantes" "jsonb",
    "publicado_em" "text",
    "ultima_atualizacao" "text",
    "raw" "jsonb",
    "ingested_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."agenda_senado_comissoes" (
    "id" "text" NOT NULL,
    "data_hora_inicio" timestamp with time zone,
    "data_inicio_date" "date",
    "titulo" "text",
    "descricao" "text",
    "tipo_cod" "text",
    "tipo_desc" "text",
    "comissao_codigo" "text",
    "comissao_sigla" "text",
    "comissao_nome" "text",
    "casa" "text",
    "confirmada" boolean,
    "realizada" boolean,
    "situacao" "text",
    "local" "text",
    "tipo_presenca" "text",
    "url_pauta_simples" "text",
    "url_pauta_completa" "text",
    "partes" "jsonb",
    "raw" "jsonb",
    "ingested_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."agenda_senado_plenario" (
    "id" "text" NOT NULL,
    "data_sessao" "date" NOT NULL,
    "hora" "text",
    "tipo_sessao" "text",
    "casa" "text",
    "local" "text",
    "situacao" "text",
    "pauta_confirmada" boolean,
    "tipo_presenca" "text",
    "evento_tipo" "text",
    "evento_desc" "text",
    "origem_autor" "text",
    "requerimento" "text",
    "oradores" "jsonb",
    "raw" "jsonb",
    "ingested_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."agenda_ingest_log" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "fonte" "text" NOT NULL,
    "data_inicio" "date",
    "data_fim" "date",
    "status" "text" DEFAULT 'running'::"text" NOT NULL,
    "n_inseridos" integer,
    "n_atualizados" integer,
    "n_erros" integer,
    "erro_msg" "text",
    "started_at" timestamp with time zone DEFAULT "now"(),
    "finished_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS "public"."ale_casas" (
    "id" "text" NOT NULL,
    "nome" "text" NOT NULL,
    "nome_curto" "text",
    "uf" "text" NOT NULL,
    "capital" "text",
    "n_deputados" integer,
    "tier" integer,
    "base_url" "text",
    "api_url" "text",
    "notas" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."ale_ingest_runs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "casa_id" "text" NOT NULL,
    "started_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "finished_at" timestamp with time zone,
    "status" "text" DEFAULT 'running'::"text" NOT NULL,
    "data_inicio" "date",
    "data_fim" "date",
    "n_deputados" integer DEFAULT 0 NOT NULL,
    "n_proposicoes" integer DEFAULT 0 NOT NULL,
    "n_votacoes" integer DEFAULT 0 NOT NULL,
    "erro" "text"
);

CREATE TABLE IF NOT EXISTS "public"."ale_parlamentares" (
    "id" "text" NOT NULL,
    "casa_id" "text" NOT NULL,
    "nome" "text" NOT NULL,
    "slug" "text",
    "partido" "text",
    "uf" "text",
    "mandato_inicio" "date",
    "mandato_fim" "date",
    "foto_url" "text",
    "email" "text",
    "telefone" "text",
    "raw" "jsonb",
    "fetched_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."casas" (
    "id" integer NOT NULL,
    "sigla" "text" NOT NULL,
    "nome" "text" NOT NULL,
    "esfera" "text" NOT NULL,
    "uf" "text",
    "url_dados_abertos" "text",
    "url_transparencia" "text",
    "observacoes" "text",
    "ativo" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "casas_esfera_check" CHECK (("esfera" = ANY (ARRAY['federal'::"text", 'estadual'::"text", 'municipal'::"text"])))
);

CREATE TABLE IF NOT EXISTS "public"."parlamentares_estaduais" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "casa_id" integer NOT NULL,
    "id_externo" "text" NOT NULL,
    "nome" "text" NOT NULL,
    "partido" "text",
    "tag_localizacao" "text",
    "foto_url" "text",
    "ativo" boolean DEFAULT true NOT NULL,
    "legislatura" integer,
    "metadata" "jsonb",
    "ingested_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."ale_proposicoes" (
    "id" "text" NOT NULL,
    "casa_id" "text" NOT NULL,
    "numero" "text",
    "ano" integer,
    "tipo" "text",
    "ementa" "text",
    "autor" "text",
    "autor_id" "text",
    "data_apresentacao" "date",
    "situacao" "text",
    "regime" "text",
    "url" "text",
    "assuntos" "text"[],
    "raw" "jsonb",
    "fetched_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."ale_votacoes" (
    "id" "text" NOT NULL,
    "casa_id" "text" NOT NULL,
    "proposicao_id" "text",
    "data" "date",
    "hora" "text",
    "resultado" "text",
    "votos_sim" integer DEFAULT 0 NOT NULL,
    "votos_nao" integer DEFAULT 0 NOT NULL,
    "votos_abstencao" integer DEFAULT 0 NOT NULL,
    "votos_ausente" integer DEFAULT 0 NOT NULL,
    "raw" "jsonb",
    "fetched_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."ale_votos" (
    "votacao_id" "text" NOT NULL,
    "deputado_id" "text" NOT NULL,
    "deputado_nome" "text",
    "voto" "text",
    "partido" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."aleba_deputados" (
    "id_aleba" "text" NOT NULL,
    "nome" "text" NOT NULL,
    "nome_parlamentar" "text",
    "partido" "text",
    "uf" "text" DEFAULT 'BA'::"text",
    "ativo" boolean DEFAULT true,
    "atualizado_em" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."aleba_despesas" (
    "id" bigint NOT NULL,
    "id_aleba" "text",
    "nome_deputado" "text",
    "ano" integer,
    "mes" integer,
    "verba" "text",
    "descricao" "text",
    "favorecido" "text",
    "vencimento" "date",
    "valor" numeric(14,2),
    "ingerido_em" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."gastos_parlamentares" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "parlamentar_id" "uuid" NOT NULL,
    "casa_id" integer NOT NULL,
    "ano" integer NOT NULL,
    "mes" integer NOT NULL,
    "cod_categoria" "text" DEFAULT ''::"text" NOT NULL,
    "categoria" "text" NOT NULL,
    "categoria_total" numeric(14,2),
    "fornecedor" "text",
    "cnpj_cpf" "text" DEFAULT ''::"text" NOT NULL,
    "num_documento" "text" DEFAULT ''::"text" NOT NULL,
    "data_emissao" "date",
    "valor_bruto" numeric(14,2) DEFAULT 0 NOT NULL,
    "valor_reembolso" numeric(14,2),
    "url_origem" "text" NOT NULL,
    "metadata" "jsonb",
    "ingested_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "gastos_parlamentares_mes_check" CHECK ((("mes" >= 1) AND ("mes" <= 12)))
);

CREATE TABLE IF NOT EXISTS "public"."alertas_processo" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "email" "text" NOT NULL,
    "tipo" "text" NOT NULL,
    "numero_processo" "text",
    "tribunal" "text",
    "termo_busca" "text",
    "ativo" boolean DEFAULT true NOT NULL,
    "confirmado" boolean DEFAULT false NOT NULL,
    "token_confirmacao" "text" DEFAULT ("gen_random_uuid"())::"text",
    "token_cancelamento" "text" DEFAULT ("gen_random_uuid"())::"text",
    "ultimo_check" timestamp with time zone,
    "ultimo_resultado" "jsonb",
    "criado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."alerts_history" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tipo" "text" DEFAULT 'info'::"text" NOT NULL,
    "observatorio_id" "text",
    "titulo" "text" NOT NULL,
    "descricao" "text",
    "severidade" "text" DEFAULT 'low'::"text",
    "dados_json" "jsonb" DEFAULT '{}'::"jsonb",
    "resolvido" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."alesc_deputados" (
    "id_alesc" "text" NOT NULL,
    "nome" "text" NOT NULL,
    "nome_parlamentar" "text",
    "partido" "text",
    "uf" "text" DEFAULT 'SC'::"text",
    "mandato" "text",
    "ativo" boolean DEFAULT true,
    "atualizado_em" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."alesc_despesas" (
    "id" bigint NOT NULL,
    "id_alesc" "text",
    "nome_deputado" "text",
    "ano" integer,
    "mes" integer,
    "verba" "text",
    "descricao" "text",
    "favorecido" "text",
    "vencimento" "date",
    "valor" numeric(14,2),
    "ingerido_em" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."ceaps_brutas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ano" integer NOT NULL,
    "cod_documento" "text" NOT NULL,
    "deputado_id_externo" "text" NOT NULL,
    "tipo_despesa" "text",
    "nome_fornecedor" "text",
    "cnpj_cpf_fornecedor" "text",
    "valor_liquido" numeric(12,2),
    "valor_documento" numeric(12,2),
    "valor_glosa" numeric(12,2),
    "data_documento" "date",
    "url_documento" "text",
    "dados" "jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."api_rate_state" (
    "id" "text" NOT NULL,
    "requests_current_minute" integer DEFAULT 0,
    "minute_window" timestamp with time zone DEFAULT "now"(),
    "locked_until" timestamp with time zone,
    "updated_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."ask_cache" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "pergunta_hash" "text" NOT NULL,
    "pergunta_original" "text" NOT NULL,
    "sql_executado" "text" NOT NULL,
    "resultado" "jsonb" NOT NULL,
    "resposta_narrativa" "text" NOT NULL,
    "tabelas_usadas" "text"[],
    "input_tokens" integer DEFAULT 0,
    "output_tokens" integer DEFAULT 0,
    "custo_estimado_usd" numeric(10,6) DEFAULT 0,
    "hit_count" integer DEFAULT 1,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "expires_at" timestamp with time zone DEFAULT ("now"() + '7 days'::interval)
);

CREATE TABLE IF NOT EXISTS "public"."cam_parlamentar_risco" (
    "deputado_id" integer NOT NULL,
    "nome" "text" NOT NULL,
    "sigla_partido" "text",
    "sigla_uf" "text",
    "url_foto" "text",
    "score_total" numeric(5,1) DEFAULT 0 NOT NULL,
    "dim_ceap" numeric(5,1) DEFAULT 0,
    "dim_presenca" numeric(5,1) DEFAULT 0,
    "dim_producao" numeric(5,1) DEFAULT 0,
    "dim_financiamento" numeric(5,1) DEFAULT 0,
    "dim_rp9" numeric(5,1) DEFAULT 0,
    "ceap_total_2024" numeric(15,2),
    "passagens_aereas_2024" numeric(15,2),
    "presenca_pct" numeric(5,2),
    "concordancia_partido" numeric(5,2),
    "total_proposicoes" integer,
    "total_substantivo" integer,
    "financiamento_total" numeric(15,2),
    "financiamento_fefc" numeric(15,2),
    "patrimonio_2022" numeric(18,2),
    "fornecedores_sancionados" integer DEFAULT 0 NOT NULL,
    "doadores_sancionados" integer DEFAULT 0 NOT NULL,
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL,
    "cpf" "text",
    "total_legislaturas" integer,
    "primeira_legislatura" integer,
    "cargo_anterior" "text",
    "total_frentes" integer DEFAULT 0 NOT NULL,
    "total_comissoes" integer DEFAULT 0 NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."emendas_completas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "codigo_emenda" "text" NOT NULL,
    "ano" integer NOT NULL,
    "tipo_emenda" "text" NOT NULL,
    "eh_rp9" boolean GENERATED ALWAYS AS (("tipo_emenda" ~~* '%relator%'::"text")) STORED NOT NULL,
    "autor_nome" "text",
    "numero_emenda" "text",
    "localidade" "text",
    "uf" "text",
    "municipio" "text",
    "funcao" "text",
    "subfuncao" "text",
    "valor_empenhado" numeric(18,2) DEFAULT 0 NOT NULL,
    "valor_liquidado" numeric(18,2) DEFAULT 0 NOT NULL,
    "valor_pago" numeric(18,2) DEFAULT 0 NOT NULL,
    "valor_resto_inscrito" numeric(18,2) DEFAULT 0 NOT NULL,
    "valor_resto_cancelado" numeric(18,2) DEFAULT 0 NOT NULL,
    "valor_resto_pago" numeric(18,2) DEFAULT 0 NOT NULL,
    "dados" "jsonb",
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."ask_log" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "pergunta_original" "text" NOT NULL,
    "pergunta_hash" "text" NOT NULL,
    "ip_hash" "text",
    "user_agent" "text",
    "cache_hit" boolean DEFAULT false,
    "success" boolean DEFAULT true,
    "erro" "text",
    "latencia_ms" integer,
    "tokens_total" integer,
    "custo_usd" numeric(10,6),
    "created_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."ask_quota" (
    "user_id" "uuid" NOT NULL,
    "date" "date" DEFAULT CURRENT_DATE NOT NULL,
    "count" integer DEFAULT 0 NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."assessores" (
    "id" bigint NOT NULL,
    "parlamentar_id" "uuid",
    "nome" "text",
    "cargo" "text",
    "updated_at" timestamp without time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."authority_metrics" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "data" "date" DEFAULT CURRENT_DATE NOT NULL,
    "total_alertas" integer DEFAULT 0,
    "total_insights" integer DEFAULT 0,
    "total_teses" integer DEFAULT 0,
    "total_relatorios_publicados" integer DEFAULT 0,
    "crescimento_semanal" numeric DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."auto_briefings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "titulo" "text" NOT NULL,
    "resumo" "text",
    "conteudo" "text",
    "tipo" "text" DEFAULT 'geral'::"text",
    "publicado" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."autores_orcamentarios" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "nome_oficial" "text" NOT NULL,
    "nome_normalizado" "text" NOT NULL,
    "tipo_autor" "text" DEFAULT 'OUTRO'::"text" NOT NULL,
    "id_camara" integer,
    "id_senado" integer,
    "parlamentar_id" "uuid",
    "ativo" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "autores_orcamentarios_tipo_autor_check" CHECK (("tipo_autor" = ANY (ARRAY['DEPUTADO'::"text", 'SENADOR'::"text", 'BANCADA'::"text", 'COMISSAO'::"text", 'MESA'::"text", 'RELATOR'::"text", 'OUTRO'::"text"])))
);

CREATE TABLE IF NOT EXISTS "public"."autores_parlamentares_map" (
    "id" integer NOT NULL,
    "codigo_autor" "text",
    "nome_autor" "text",
    "parlamentar_id" "uuid",
    "metodo_match" "text",
    "confianca" numeric DEFAULT 0.0,
    "created_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."b3_empresas_listadas" (
    "codigo_cvm" "text" NOT NULL,
    "cnpj" "text",
    "ticker" "text",
    "nome_empresa" "text" NOT NULL,
    "nome_negociacao" "text",
    "segmento" "text",
    "segmento_en" "text",
    "tipo_valor" "text",
    "tipo_bdr" "text",
    "mercado" "text",
    "market_indicator" "text",
    "data_listagem" "date",
    "status" "text",
    "atualizado_em" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."b3_tickers" (
    "codigo_cvm" "text" NOT NULL,
    "tipo" "text" NOT NULL,
    "ticker" "text",
    "nome_empresa" "text",
    "nome_negociacao" "text",
    "cnpj" "text",
    "segmento" "text",
    "mercado" "text",
    "status" "text",
    "data_listagem" "date",
    "tipo_bdr" "text"
);

CREATE TABLE IF NOT EXISTS "public"."banks" (
    "ispb" "text" NOT NULL,
    "codigo" "text",
    "nome" "text",
    "nome_completo" "text"
);

CREATE TABLE IF NOT EXISTS "public"."beneficios_parlamentares" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "parlamentar_id" "uuid",
    "tipo_beneficio" "text",
    "valor" numeric DEFAULT 0,
    "data" "date",
    "descricao" "text",
    "fonte_dado" "text",
    "updated_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."bets_licenciadas" (
    "id" integer NOT NULL,
    "cnpj" character(14) NOT NULL,
    "nome" "text" NOT NULL,
    "portaria" "text",
    "marcas" "text"[],
    "dominios" "text"[],
    "data_ingestao" "date" DEFAULT CURRENT_DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."cam_comissoes" (
    "id" integer NOT NULL,
    "sigla" "text",
    "nome" "text" NOT NULL,
    "apelido" "text",
    "tipo_orgao" "text",
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."cam_comissoes_membros" (
    "comissao_id" integer NOT NULL,
    "deputado_id" integer NOT NULL,
    "nome" "text",
    "sigla_partido" "text",
    "sigla_uf" "text",
    "titulo" "text",
    "data_inicio" "date",
    "data_fim" "date"
);

CREATE TABLE IF NOT EXISTS "public"."cam_frentes" (
    "id" integer NOT NULL,
    "titulo" "text" NOT NULL,
    "id_legislatura" integer DEFAULT 57 NOT NULL,
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."cam_frentes_membros" (
    "frente_id" integer NOT NULL,
    "deputado_id" integer NOT NULL,
    "nome" "text",
    "sigla_partido" "text",
    "sigla_uf" "text"
);

CREATE TABLE IF NOT EXISTS "public"."cam_proposicoes" (
    "id" integer NOT NULL,
    "deputado_id" integer NOT NULL,
    "sigla_tipo" "text" NOT NULL,
    "numero" integer,
    "ano" integer,
    "ementa" "text",
    "data_apresentacao" timestamp with time zone,
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."cam_proposicoes_agg" (
    "deputado_id" integer NOT NULL,
    "nome" "text",
    "sigla_partido" "text",
    "sigla_uf" "text",
    "url_foto" "text",
    "total" integer DEFAULT 0 NOT NULL,
    "total_substantivo" integer DEFAULT 0 NOT NULL,
    "total_pl" integer DEFAULT 0 NOT NULL,
    "total_pec" integer DEFAULT 0 NOT NULL,
    "total_req" integer DEFAULT 0 NOT NULL,
    "por_tipo" "jsonb",
    "por_ano" "jsonb",
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."camara_frente" (
    "id" integer NOT NULL,
    "titulo" "text" NOT NULL,
    "id_legislatura" smallint,
    "ingested_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."camara_frente_membro" (
    "id_frente" integer NOT NULL,
    "id_deputado" integer NOT NULL,
    "nome_deputado" "text",
    "sigla_partido" "text",
    "sigla_uf" "text",
    "titulo_na_frente" "text",
    "ingested_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."camara_ocupacao" (
    "id_deputado" integer NOT NULL,
    "titulo" "text" NOT NULL,
    "entidade" "text",
    "entidade_uf" "text",
    "entidade_pais" "text",
    "ano_inicio" smallint,
    "ano_fim" smallint,
    "ingested_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."cambio_cotacoes" (
    "simbolo" "text" NOT NULL,
    "data_cotacao" "date" NOT NULL,
    "valor_compra" numeric,
    "valor_venda" numeric,
    "capturado_em" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."cambio_moedas" (
    "simbolo" "text" NOT NULL,
    "nome" "text",
    "tipo_moeda" "text"
);

CREATE TABLE IF NOT EXISTS "public"."cbf_cnpjs_vinculados" (
    "id" bigint NOT NULL,
    "cnpj_basico" "text" NOT NULL,
    "cnpj_completo" "text",
    "razao_social" "text",
    "natureza_juridica" "text",
    "situacao_cadastral" "text",
    "uf" "text",
    "cpf_socio" "text" NOT NULL,
    "nome_socio" "text",
    "qualificacao" "text",
    "cnpj_federacao_ref" "text" NOT NULL,
    "tem_emenda" boolean DEFAULT false,
    "total_emendas" numeric(18,2) DEFAULT 0,
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."cbf_socios_federacoes" (
    "id" bigint NOT NULL,
    "cnpj_federacao" "text" NOT NULL,
    "uf" "text" NOT NULL,
    "nome_federacao" "text" NOT NULL,
    "cpf_socio" "text" NOT NULL,
    "nome_socio" "text" NOT NULL,
    "qualificacao" "text",
    "data_entrada" "text",
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."ceaf_expulsoes" (
    "id" integer NOT NULL,
    "data_publicacao" "date",
    "data_referencia" "date",
    "cpf_punido" "text",
    "nome_punido" "text",
    "tipo_punicao" "text",
    "cargo_efetivo" "text",
    "cargo_comissao" "text",
    "orgao_sigla" "text",
    "orgao_pasta_sigla" "text",
    "orgao_nome" "text",
    "uf_lotacao" character(2),
    "portaria" "text",
    "numero_processo" "text",
    "pagina_dou" "text",
    "secao_dou" "text",
    "fundamentacao" "text"[],
    "ingested_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."ceaf_ingest_log" (
    "id" bigint NOT NULL,
    "started_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "finished_at" timestamp with time zone,
    "status" "text" DEFAULT 'running'::"text" NOT NULL,
    "n_processados" integer,
    "n_paginas" integer,
    "erro" "text"
);

CREATE TABLE IF NOT EXISTS "public"."cgu_pad_processos" (
    "numero_processo" "text" NOT NULL,
    "tipo_processo" "text",
    "assuntos" "text"[],
    "pasta" "text",
    "entidade" "text",
    "uf" character(2),
    "cidade" "text",
    "data_instauracao" "date",
    "fase_atual" "text",
    "data_fase" "date",
    "n_investigados" smallint DEFAULT 0 NOT NULL,
    "n_advertencias" smallint DEFAULT 0 NOT NULL,
    "n_suspensoes" smallint DEFAULT 0 NOT NULL,
    "n_expulsivas" smallint DEFAULT 0 NOT NULL,
    "n_outras_sancoes" smallint DEFAULT 0 NOT NULL,
    "tem_expulsiva" boolean GENERATED ALWAYS AS (("n_expulsivas" > 0)) STORED,
    "ingested_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."ceaps_ranking" (
    "deputado_id_externo" "text" NOT NULL,
    "ano" integer NOT NULL,
    "posicao" integer,
    "total_liquido" numeric(14,2) DEFAULT 0 NOT NULL,
    "total_documentos" integer DEFAULT 0 NOT NULL,
    "por_categoria" "jsonb",
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."ceaps_senado_brutas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "cod_documento" "text" NOT NULL,
    "ano" smallint NOT NULL,
    "senador" "text" NOT NULL,
    "senador_normalizado" "text",
    "mes" smallint,
    "tipo_despesa" "text",
    "cnpj_cpf" "text",
    "fornecedor" "text",
    "documento" "text",
    "data" "date",
    "detalhamento" "text",
    "valor_reembolsado" numeric(18,2) DEFAULT 0 NOT NULL,
    "dados" "jsonb",
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."ceaps_senado_ranking" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "senador" "text" NOT NULL,
    "senador_normalizado" "text" NOT NULL,
    "ano" smallint NOT NULL,
    "total_reembolsado" numeric(18,2) DEFAULT 0 NOT NULL,
    "total_documentos" integer DEFAULT 0 NOT NULL,
    "por_tipo" "jsonb",
    "top_fornecedores" "jsonb",
    "posicao" integer,
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."cgu_pad_ingest_log" (
    "id" bigint NOT NULL,
    "started_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "finished_at" timestamp with time zone,
    "status" "text" DEFAULT 'running'::"text" NOT NULL,
    "n_processados" integer,
    "n_novos" integer,
    "n_atualizados" integer,
    "erro" "text"
);

CREATE TABLE IF NOT EXISTS "public"."cnes_estabelecimentos" (
    "codigo_cnes" integer NOT NULL,
    "numero_cnpj" "text",
    "nome_razao_social" "text",
    "nome_fantasia" "text",
    "codigo_tipo_unidade" integer,
    "tipo_gestao" "text",
    "descricao_esfera_administrativa" "text",
    "descricao_natureza_juridica" "text",
    "codigo_uf" integer,
    "uf" "text",
    "codigo_municipio" integer,
    "codigo_cep" "text",
    "endereco" "text",
    "numero" "text",
    "bairro" "text",
    "latitude" numeric(12,8),
    "longitude" numeric(12,8),
    "telefone" "text",
    "email" "text",
    "atende_sus" boolean,
    "possui_centro_cirurgico" boolean,
    "possui_atendimento_hospitalar" boolean,
    "possui_atendimento_ambulatorial" boolean,
    "data_atualizacao" "date",
    "ingerido_em" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."cnpj_empresa" (
    "cnpj_basico" "text" NOT NULL,
    "razao_social" "text",
    "natureza_juridica" "text",
    "capital_social" numeric,
    "porte" "text",
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."cnpj_empresas" (
    "cnpj_basico" character(8) NOT NULL,
    "razao_social" "text",
    "natureza_juridica" "text",
    "capital_social" "text",
    "porte_empresa" "text",
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."cnpj_enriquecido" (
    "cnpj" "text" NOT NULL,
    "razao_social" "text",
    "nome_fantasia" "text",
    "situacao_cadastral" "text",
    "data_situacao_cadastral" "date",
    "cnae_principal_codigo" "text",
    "cnae_principal_descricao" "text",
    "natureza_juridica_codigo" "text",
    "natureza_juridica_desc" "text",
    "capital_social" numeric,
    "porte" "text",
    "municipio" "text",
    "uf" "text",
    "cep" "text",
    "qsa" "jsonb",
    "cnaes_secundarios" "jsonb",
    "payload_raw" "jsonb",
    "atualizado_em" timestamp with time zone DEFAULT "now"(),
    "erro" "text"
);

CREATE TABLE IF NOT EXISTS "public"."cnpj_ingest_log" (
    "id" bigint NOT NULL,
    "particao" "text" NOT NULL,
    "started_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "finished_at" timestamp with time zone,
    "status" "text" DEFAULT 'running'::"text" NOT NULL,
    "n_matches" integer,
    "erro" "text"
);

CREATE TABLE IF NOT EXISTS "public"."cnpj_socios" (
    "cnpj_basico" "text" NOT NULL,
    "identificador" "text",
    "nome_socio" "text",
    "nome_norm" "text",
    "cpf_cnpj_socio" "text",
    "qualificacao" "text",
    "data_entrada" "date",
    "faixa_etaria" "text",
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."cobertura_dados" (
    "ano" integer NOT NULL,
    "ultima_ingestao_em" timestamp with time zone,
    "status" "text",
    "total_registros" integer,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."codigos_acesso" (
    "codigo" "text" NOT NULL,
    "plano" "text" DEFAULT 'individual'::"text" NOT NULL,
    "validade_dias" integer DEFAULT 365 NOT NULL,
    "usado_em" timestamp with time zone,
    "usado_por" "uuid",
    "criado_em" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "codigos_acesso_plano_check" CHECK (("plano" = ANY (ARRAY['individual'::"text", 'institucional'::"text"])))
);

CREATE TABLE IF NOT EXISTS "public"."comissoes_parlamentares" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "parlamentar_id" "uuid" NOT NULL,
    "id_orgao" "text",
    "sigla" "text",
    "nome" "text" NOT NULL,
    "tipo" "text",
    "cargo" "text",
    "data_inicio" "date",
    "data_fim" "date",
    "situacao" "text" DEFAULT 'Ativa'::"text",
    "created_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."comissoes_senado" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "parlamentar_id" "uuid" NOT NULL,
    "id_cargo" "text",
    "nome_cargo" "text" NOT NULL,
    "tipo_funcao" "text",
    "data_inicio" "date",
    "data_fim" "date",
    "situacao" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."contratos_federais" (
    "id" integer NOT NULL,
    "numero" "text",
    "objeto" "text",
    "data_assinatura" "date",
    "data_publicacao_tcu" "date",
    "data_inicio_vigencia" "date",
    "data_fim_vigencia" "date",
    "valor" numeric(18,2),
    "valor_aditivos" numeric(18,2),
    "valor_total" numeric(18,2),
    "situacao_codigo" "text",
    "situacao_descricao" "text",
    "fornecedor_cnpj" "text",
    "fornecedor_cpf" "text",
    "fornecedor_nome" "text",
    "fornecedor_razao_social" "text",
    "ug_codigo" "text",
    "ug_descricao" "text",
    "orgao_codigo" "text",
    "orgao_descricao" "text",
    "orgao_poder" "text",
    "modalidade_codigo" "text",
    "modalidade_descricao" "text",
    "tipo_contrato" "text",
    "licitacao_numero" "text",
    "licitacao_modalidade" "text",
    "updated_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."contratos_ingest_log" (
    "id" integer NOT NULL,
    "descricao" "text",
    "status" "text",
    "n_novos" integer DEFAULT 0,
    "erro" "text",
    "started_at" timestamp with time zone DEFAULT "now"(),
    "finished_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS "public"."convenios" (
    "id" bigint NOT NULL,
    "id_portal" bigint,
    "numero" "text",
    "codigo" "text",
    "objeto" "text",
    "situacao" "text",
    "tipo_instrumento" "text",
    "numero_processo" "text",
    "data_publicacao" "date",
    "data_inicio_vigencia" "date",
    "data_final_vigencia" "date",
    "data_ultima_liberacao" "date",
    "data_conclusao" "date",
    "convenente_cnpj" "text",
    "convenente_cpf" "text",
    "convenente_nome" "text",
    "convenente_tipo" "text",
    "municipio_ibge" "text",
    "municipio_nome" "text",
    "uf" "text",
    "orgao_siafi" "text",
    "orgao_cnpj" "text",
    "orgao_sigla" "text",
    "orgao_nome" "text",
    "orgao_poder" "text",
    "orgao_maximo_codigo" "text",
    "orgao_maximo_sigla" "text",
    "orgao_maximo_nome" "text",
    "ug_codigo" "text",
    "ug_nome" "text",
    "subfuncao_codigo" "text",
    "subfuncao_descricao" "text",
    "funcao_codigo" "text",
    "funcao_descricao" "text",
    "valor" numeric(18,2),
    "valor_liberado" numeric(18,2),
    "valor_contrapartida" numeric(18,2),
    "valor_ultima_liberacao" numeric(18,2),
    "dados" "jsonb",
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL,
    "numero_siconv" "text"
);

CREATE TABLE IF NOT EXISTS "public"."cota_cnpj_lookup" (
    "cnpj_raw" "text" NOT NULL,
    "cnpj_norm" "text" NOT NULL,
    "is_cnpj" boolean GENERATED ALWAYS AS (("length"("regexp_replace"("cnpj_raw", '[^0-9]'::"text", ''::"text", 'g'::"text")) = 14)) STORED
);

CREATE TABLE IF NOT EXISTS "public"."cota_despesa" (
    "id_documento" bigint NOT NULL,
    "id_deputado" integer NOT NULL,
    "ano" smallint NOT NULL,
    "mes" smallint NOT NULL,
    "data_emissao" "date",
    "tipo_despesa" "text" NOT NULL,
    "sub_quotaid_cnt" smallint,
    "descricao" "text",
    "cnpj_cpf_fornecedor" "text",
    "nome_fornecedor" "text",
    "tipo_documento" smallint,
    "numero_documento" "text",
    "valor_documento" numeric(14,2) DEFAULT 0 NOT NULL,
    "valor_liquido" numeric(14,2) DEFAULT 0 NOT NULL,
    "valor_glosa" numeric(14,2) DEFAULT 0 NOT NULL,
    "num_sub_cota" smallint,
    "trecho" "text",
    "ano_csv" smallint NOT NULL,
    "ingested_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "cnpj_norm" "text" GENERATED ALWAYS AS ("regexp_replace"("cnpj_cpf_fornecedor", '[^0-9]'::"text", ''::"text", 'g'::"text")) STORED
);

CREATE TABLE IF NOT EXISTS "public"."cota_deputado" (
    "id_camara" integer NOT NULL,
    "nome" "text" NOT NULL,
    "cpf" "text",
    "partido" "text",
    "uf" "text",
    "legislatura" smallint,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."cpgf_transacoes" (
    "id" bigint NOT NULL,
    "ano_mes" character(7) NOT NULL,
    "ano" smallint NOT NULL,
    "mes" smallint NOT NULL,
    "cpf_portador" "text" NOT NULL,
    "nome_portador" "text",
    "cpf_cnpj_favorecido" "text",
    "nome_favorecido" "text",
    "transacao" "text",
    "estabelecimento" "text",
    "municipio" "text",
    "uf" character(2),
    "valor" numeric(14,2),
    "ingested_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."cptec_cidades" (
    "id" "text" NOT NULL,
    "nome" "text" NOT NULL,
    "estado" "text",
    "pais" "text" DEFAULT 'BR'::"text"
);

CREATE TABLE IF NOT EXISTS "public"."cron_execution_log" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "job_name" "text" NOT NULL,
    "status" "text" DEFAULT 'success'::"text" NOT NULL,
    "started_at" timestamp with time zone DEFAULT "now"(),
    "finished_at" timestamp with time zone DEFAULT "now"(),
    "duration_ms" integer,
    "records_processed" integer DEFAULT 0,
    "error_message" "text",
    "metadata" "jsonb",
    "executed_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."cvm_acusados" (
    "id" "text" NOT NULL,
    "nup" "text" NOT NULL,
    "nome_acusado" "text" NOT NULL,
    "nome_normalizado" "text" GENERATED ALWAYS AS ("upper"("regexp_replace"("nome_acusado", '[^A-Za-z√Ä-√ø0-9 ]'::"text", ''::"text", 'g'::"text"))) STORED,
    "situacao" "text",
    "data_situacao" "date",
    "updated_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."cvm_carteira_edge" (
    "cnpj_fundo" "text" NOT NULL,
    "cnpj_ativo" "text" NOT NULL,
    "denom_ativo" "text",
    "tipo_aplic" "text",
    "vl_merc" numeric,
    "dt_comptc" "date" NOT NULL,
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."cvm_corretoras" (
    "cnpj" "text" NOT NULL,
    "tipo" "text",
    "nome_social" "text",
    "nome_comercial" "text",
    "status" "text",
    "email" "text",
    "telefone" "text",
    "cep" "text",
    "uf" "text",
    "municipio" "text",
    "bairro" "text",
    "logradouro" "text",
    "codigo_cvm" "text",
    "valor_patrimonio_liquido" numeric,
    "data_patrimonio_liquido" "date",
    "data_inicio_situacao" "date",
    "data_registro" "date"
);

CREATE TABLE IF NOT EXISTS "public"."cvm_processos" (
    "nup" "text" NOT NULL,
    "objeto" "text",
    "ementa" "text",
    "data_abertura" "date",
    "componente_instrucao" "text",
    "fase_atual" "text",
    "subfase_atual" "text",
    "local_atual" "text",
    "data_ultima_movimentacao" "date",
    "updated_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."cvm_oferta" (
    "id_oferta" "text",
    "cnpj_emissor" "text",
    "nome_emissor" "text",
    "tipo_ativo" "text",
    "valor" numeric,
    "data_oferta" "date",
    "situacao" "text",
    "rito" "text",
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."mg_empresas_sancionadas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "cnpj_norm" "text",
    "cnpj_fmt" "text",
    "empresa" "text",
    "tipo_societario" "text",
    "conduta" "text",
    "decisao" "text",
    "fase" "text",
    "valor_multa" numeric(16,2),
    "orgao_instaurador" "text",
    "orgao_lesado" "text",
    "ano" integer,
    "data_publicacao_decisao" "date",
    "sei" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."portal_sancionados" (
    "id" integer NOT NULL,
    "cpf_cnpj" "text" NOT NULL,
    "nome" "text",
    "tipo_registro" "text" NOT NULL,
    "tipo_sancao" "text",
    "data_inicio" "date",
    "data_fim" "date",
    "orgao_nome" "text",
    "orgao_uf" "text",
    "ativo" boolean DEFAULT true NOT NULL,
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."cvm_fip_informe" (
    "cnpj_norm" "text" NOT NULL,
    "denom" "text",
    "tipo" "text",
    "classe_cota" "text",
    "dt_comptc" "date" NOT NULL,
    "vl_patrim_liq" numeric,
    "qt_cota" numeric,
    "vl_patrim_cota" numeric,
    "nr_cotst" integer,
    "vl_cap_compr" numeric,
    "vl_cap_integr" numeric,
    "pr_pf" numeric,
    "pr_pj_nfin" numeric,
    "pr_banco" numeric,
    "pr_pj_fin" numeric,
    "pr_rpps" numeric,
    "pr_efpc" numeric,
    "fonte" "text",
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."cvm_fundo" (
    "cnpj_norm" "text" NOT NULL,
    "denom" "text",
    "tipo" "text",
    "situacao" "text",
    "classe" "text",
    "classe_anbima" "text",
    "fundo_cotas" boolean,
    "data_registro" "date",
    "data_cancel" "date",
    "vl_patrim_liq" numeric,
    "dt_patrim_liq" "date",
    "cnpj_admin" "text",
    "admin" "text",
    "cnpj_gestor" "text",
    "gestor" "text",
    "cnpj_controlador" "text",
    "controlador" "text",
    "fonte" "text" DEFAULT 'cad_fi'::"text",
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."cvm_fip_participacao" (
    "cnpj_fip" "text" NOT NULL,
    "cnpj_empresa" "text",
    "nome_empresa" "text",
    "vl_merc" numeric,
    "dt_comptc" "date" NOT NULL,
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."cvm_fip_saf" (
    "cnpj_fip" "text" NOT NULL,
    "clube" "text",
    "nome_fip" "text",
    "papel" "text",
    "vinculo" "text",
    "confirmado" boolean DEFAULT false,
    "obs" "text",
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."cvm_fundos" (
    "cnpj" "text" NOT NULL,
    "denominacao_social" "text",
    "classe" "text",
    "situacao" "text",
    "patrimonio_liquido" numeric,
    "cotistas" integer,
    "administrador" "text",
    "gestor" "text",
    "custodiante" "text",
    "data_constituicao" "date",
    "data_cancelamento" "date",
    "payload_raw" "jsonb",
    "atualizado_em" timestamp with time zone DEFAULT "now"(),
    "erro" "text"
);

CREATE TABLE IF NOT EXISTS "public"."cvm_ingest_log" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "dataset" "text" NOT NULL,
    "status" "text" DEFAULT 'running'::"text" NOT NULL,
    "n_processos" integer,
    "n_acusados" integer,
    "erro" "text",
    "started_at" timestamp with time zone DEFAULT "now"(),
    "finished_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS "public"."cvm_saf" (
    "cnpj_norm" "text" NOT NULL,
    "clube" "text" NOT NULL,
    "razao_social" "text",
    "serie" "text",
    "investidor" "text",
    "data_constituicao" "date",
    "status" "text" DEFAULT 'ativa'::"text",
    "obs" "text",
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."cvm_saf_entidade_relacionada" (
    "cnpj_norm" "text" NOT NULL,
    "clube" "text" NOT NULL,
    "descricao" "text",
    "nome" "text",
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."sen_senadores" (
    "codigo" "text" NOT NULL,
    "nome_completo" "text",
    "nome_norm" "text",
    "partido" "text",
    "uf" "text",
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."sobrenome_blocklist" (
    "sobrenome" "text" NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."data_governance_log" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "job_name" "text",
    "source" "text",
    "status" "text",
    "rows_imported" integer DEFAULT 0,
    "validation_errors" integer DEFAULT 0,
    "completeness_score" integer DEFAULT 0,
    "started_at" timestamp with time zone,
    "finished_at" timestamp with time zone,
    "duration_ms" bigint,
    "metadata" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."data_pipeline_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "pipeline_run_id" "uuid",
    "step" "text" NOT NULL,
    "status" "text" NOT NULL,
    "duration_ms" integer,
    "rows_affected" integer DEFAULT 0,
    "error_message" "text",
    "metadata" "jsonb",
    "executed_at" timestamp without time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."data_pipeline_status" (
    "id" integer DEFAULT 1 NOT NULL,
    "last_success" timestamp without time zone,
    "last_run" timestamp without time zone,
    "status" "text"
);

CREATE TABLE IF NOT EXISTS "public"."data_sources_registry" (
    "source_name" "text" NOT NULL,
    "status" "text",
    "last_sync" timestamp with time zone,
    "reliability_score" numeric DEFAULT 0
);

CREATE TABLE IF NOT EXISTS "public"."declaracao_bens" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "parlamentar_id" "uuid" NOT NULL,
    "ano_eleicao" integer NOT NULL,
    "total_bens" numeric DEFAULT 0,
    "itens" "jsonb",
    "fonte" "text" DEFAULT 'tse'::"text",
    "created_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."deputados_brutas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "id_externo" "text" NOT NULL,
    "nome" "text" NOT NULL,
    "sigla_partido" "text",
    "sigla_uf" "text",
    "id_legislatura" integer,
    "url_foto" "text",
    "email" "text",
    "dados" "jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."despesas_gabinete_raw" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "parlamentar_uid" "uuid",
    "deputado_id" "text",
    "ano" integer,
    "mes" integer,
    "tipo_despesa" "text",
    "valor" numeric,
    "data_documento" "date",
    "created_at" timestamp without time zone DEFAULT "now"(),
    "num_documento" "text",
    "valor_liquido" numeric DEFAULT 0,
    "valor_glosa" numeric DEFAULT 0,
    "fornecedor" "text",
    "cnpj_cpf" "text",
    "url_documento" "text"
);

CREATE TABLE IF NOT EXISTS "public"."discursos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "parlamentar_id" "uuid" NOT NULL,
    "id_camara" "text",
    "data_hora_inicio" timestamp with time zone,
    "fase" "text",
    "tipo_discurso" "text",
    "keywords" "text",
    "sumario" "text",
    "transcricao" "text",
    "url_audio" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."discursos_camara" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "parlamentar_id" "uuid" NOT NULL,
    "id_camara" integer NOT NULL,
    "data_hora" timestamp with time zone NOT NULL,
    "fase_evento" "text",
    "tipo_discurso" "text",
    "sumario" "text",
    "transcricao" "text",
    "url_audio" "text",
    "url_video" "text",
    "evento_id" "text",
    "fonte_dado" "text" DEFAULT 'camara_api'::"text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."discursos_senado" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "parlamentar_id" "uuid" NOT NULL,
    "id_senado" "text",
    "data_hora" timestamp with time zone NOT NULL,
    "fase" "text",
    "tipo_discurso" "text",
    "texto" "text",
    "resumo" "text",
    "url_audio" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."dou_alertas_cruzamento" (
    "id" bigint NOT NULL,
    "id_externo" "text" NOT NULL,
    "titulo" "text",
    "data_publicacao" "date",
    "orgao" "text",
    "tipo_match" "text" NOT NULL,
    "valor_match" "text" NOT NULL,
    "criado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."dou_publicacoes" (
    "id" bigint NOT NULL,
    "id_externo" "text" NOT NULL,
    "secao" "text" NOT NULL,
    "data_publicacao" "date" NOT NULL,
    "tipo_ato" "text",
    "titulo" "text",
    "orgao" "text",
    "conteudo_html" "text",
    "cpfs_extraidos" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "cnpjs_extraidos" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "url_titulo" "text",
    "criado_em" timestamp with time zone DEFAULT "now"() NOT NULL,
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL,
    "assinante" "text"
);

CREATE TABLE IF NOT EXISTS "public"."ele2026_alertas" (
    "id" integer NOT NULL,
    "cpf" "text",
    "nome" "text" NOT NULL,
    "uf" character(2),
    "cargo_interesse" "text",
    "motivos" "text"[] NOT NULL,
    "descricao" "text",
    "parlamentar_id" "uuid",
    "emenda_total_hist" numeric(16,2),
    "tem_sancao" boolean DEFAULT false,
    "investigacoes" "text"[],
    "alerta_ativo" boolean DEFAULT true NOT NULL,
    "candidatura_entrou" boolean DEFAULT false NOT NULL,
    "financiamento_entrou" boolean DEFAULT false NOT NULL,
    "notificado_em" timestamp with time zone,
    "criado_em" timestamp with time zone DEFAULT "now"() NOT NULL,
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."ele2026_candidatos" (
    "id" "text" NOT NULL,
    "sq_candidato" "text" NOT NULL,
    "cpf" "text",
    "nome" "text" NOT NULL,
    "nome_urna" "text",
    "data_nascimento" "date",
    "genero" "text",
    "cor_raca" "text",
    "grau_instrucao" "text",
    "ocupacao" "text",
    "estado_civil" "text",
    "email" "text",
    "foto_url" "text",
    "cd_cargo" smallint,
    "cargo" "text",
    "uf" character(2),
    "municipio_nascimento" "text",
    "nr_partido" smallint,
    "sigla_partido" "text",
    "nome_partido" "text",
    "nome_federacao" "text",
    "sigla_federacao" "text",
    "situacao_candidatura" "text",
    "situacao_turno1" "text",
    "situacao_turno2" "text",
    "eleito" boolean,
    "reeleicao" boolean,
    "limite_despesa" numeric(16,2),
    "parlamentar_id" "uuid",
    "id_camara" integer,
    "ingested_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."ele2026_financiamento" (
    "id" bigint NOT NULL,
    "numero_recibo" "text",
    "data_receita" "date",
    "cpf_candidato" "text",
    "nome_candidato" "text",
    "cargo" "text",
    "sigla_partido" "text",
    "uf" character(2),
    "cpf_cnpj_doador" "text",
    "nome_doador" "text",
    "tipo_doador" "text",
    "setor_economico_doador" "text",
    "cpf_cnpj_doador_originario" "text",
    "nome_doador_originario" "text",
    "natureza_receita" "text",
    "origem_receita" "text",
    "especie_recurso" "text",
    "fonte_recurso" "text",
    "valor" numeric(16,2) NOT NULL,
    "data_prestacao_contas" "date",
    "ingested_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."ele2026_gastos" (
    "id" bigint NOT NULL,
    "numero_documento" "text",
    "data_despesa" "date",
    "cpf_candidato" "text",
    "nome_candidato" "text",
    "cargo" "text",
    "sigla_partido" "text",
    "uf" character(2),
    "cpf_cnpj_fornecedor" "text",
    "nome_fornecedor" "text",
    "tipo_despesa" "text",
    "descricao_despesa" "text",
    "origem_despesa" "text",
    "especie_recurso" "text",
    "fonte_recurso" "text",
    "valor_despesa" numeric(16,2) NOT NULL,
    "valor_prestado" numeric(16,2),
    "ingested_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."ele2026_ingest_log" (
    "id" bigint NOT NULL,
    "dataset" "text" NOT NULL,
    "started_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "finished_at" timestamp with time zone,
    "status" "text" DEFAULT 'running'::"text" NOT NULL,
    "n_processados" integer,
    "n_novos" integer,
    "n_atualizados" integer,
    "erro" "text"
);

CREATE TABLE IF NOT EXISTS "public"."sancoes" (
    "id" integer NOT NULL,
    "cadastro" "text" NOT NULL,
    "cpf_cnpj" "text",
    "cpf_cnpj_formatado" "text",
    "tipo_pessoa" "text",
    "nome" "text",
    "razao_social" "text",
    "nome_fantasia" "text",
    "tipo_sancao" "text",
    "descricao_sancao" "text",
    "data_inicio" "date",
    "data_fim" "date",
    "data_publicacao" "date",
    "data_transitado" "date",
    "data_referencia" "date",
    "orgao_nome" "text",
    "orgao_uf" character(2),
    "orgao_poder" "text",
    "orgao_esfera" "text",
    "numero_processo" "text",
    "fundamentacao" "text"[],
    "valor_multa" "text",
    "abrangencia" "text",
    "informacoes_adicionais" "text",
    "link_publicacao" "text",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "sancoes_cadastro_check" CHECK (("cadastro" = ANY (ARRAY['CEIS'::"text", 'CNEP'::"text"])))
);

CREATE TABLE IF NOT EXISTS "public"."tse_candidatos" (
    "id" "text" NOT NULL,
    "ano_eleicao" smallint NOT NULL,
    "sq_candidato" "text" NOT NULL,
    "cpf" "text",
    "nome" "text" NOT NULL,
    "nome_urna" "text",
    "data_nascimento" "date",
    "genero" "text",
    "cor_raca" "text",
    "grau_instrucao" "text",
    "ocupacao" "text",
    "estado_civil" "text",
    "email" "text",
    "cd_cargo" smallint,
    "cargo" "text",
    "uf" character(2),
    "municipio_nascimento" "text",
    "nr_partido" smallint,
    "sigla_partido" "text",
    "nome_partido" "text",
    "situacao_candidatura" "text",
    "situacao_turno" "text",
    "reeleicao" boolean,
    "limite_despesa" numeric(16,2),
    "ingested_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."emendas_api" (
    "codigo" "text" NOT NULL,
    "ano" integer,
    "tipo" "text",
    "subtipo" "text",
    "autor_nome" "text",
    "autor_cpf" "text",
    "autor_partido" "text",
    "autor_uf" character(2),
    "autor_codigo_portal" "text",
    "funcao_codigo" "text",
    "funcao_descricao" "text",
    "subfuncao_codigo" "text",
    "subfuncao_descricao" "text",
    "localidade_ibge" "text",
    "localidade_descricao" "text",
    "valor_empenhado" numeric(18,2),
    "valor_liquidado" numeric(18,2),
    "valor_pago" numeric(18,2),
    "valor_resto_pagar" numeric(18,2),
    "updated_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."emendas_api_documentos" (
    "id" integer NOT NULL,
    "emenda_codigo" "text",
    "codigo_documento" "text",
    "tipo_documento" "text",
    "data" "date",
    "valor" numeric(18,2),
    "orgao" "text",
    "acao" "text",
    "favorecido_cnpj" "text",
    "favorecido_nome" "text",
    "updated_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."emendas_api_ingest_log" (
    "id" integer NOT NULL,
    "dataset" "text",
    "status" "text",
    "n_novos" integer DEFAULT 0,
    "erro" "text",
    "started_at" timestamp with time zone DEFAULT "now"(),
    "finished_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS "public"."emendas_brutas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ano" integer NOT NULL,
    "id_externo" "text" NOT NULL,
    "dados" "jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."emendas_coletivas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "codigo_emenda" "text" NOT NULL,
    "ano" integer,
    "tipo_autor" "text",
    "nome_autor" "text",
    "funcao" "text",
    "subfuncao" "text",
    "ministerio" "text",
    "municipio_nome" "text",
    "uf_destino" "text",
    "valor_empenhado" numeric DEFAULT 0,
    "valor_liquidado" numeric DEFAULT 0,
    "valor_pago" numeric DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."emendas_convenios" (
    "numero_convenio" "text" NOT NULL,
    "codigo_emenda" "text" NOT NULL,
    "codigo_funcao" "text",
    "nome_funcao" "text",
    "codigo_subfuncao" "text",
    "nome_subfuncao" "text",
    "localidade_gasto" "text",
    "tipo_emenda" "text",
    "data_publicacao" "date",
    "convenente" "text",
    "objeto" "text",
    "valor" numeric,
    "ingested_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."emendas_financeiro" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ano" integer NOT NULL,
    "id_externo" "text" NOT NULL,
    "parlamentar_id" "uuid",
    "valor_empenhado" numeric(18,2) DEFAULT 0 NOT NULL,
    "valor_liquidado" numeric(18,2) DEFAULT 0 NOT NULL,
    "valor_pago" numeric(18,2) DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."emendas_metricas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ano" integer,
    "parlamentar" "text",
    "uf" "text",
    "total_emendas" integer,
    "valor_empenhado" numeric,
    "valor_liquidado" numeric,
    "valor_pago" numeric,
    "percentual_execucao" numeric,
    "updated_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."emendas_rp9_apoiamento" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "numero_emenda" "text" NOT NULL,
    "ano_emenda" integer,
    "autor_emenda" "text",
    "tipo_emenda" "text",
    "codigo_apoiador" "text",
    "nome_apoiador" "text",
    "cargo_apoiador" "text",
    "cnpj_favorecido" "text",
    "nome_favorecido" "text",
    "orgao_uge_codigo" "text",
    "orgao_uge_nome" "text",
    "unidade_orcamentaria_codigo" "text",
    "unidade_orcamentaria_nome" "text",
    "localizador" "text",
    "ne_atual" "text",
    "fonte_oficio" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."emendas_transparencia" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "parlamentar_uid" "uuid" NOT NULL,
    "valor" numeric DEFAULT 0,
    "ano" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."estados" (
    "id" integer NOT NULL,
    "sigla" "text" NOT NULL,
    "nome" "text" NOT NULL,
    "regiao" "text",
    "populacao" bigint,
    "pib" numeric,
    "created_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."execucao_financeira_siafi" (
    "id" bigint NOT NULL,
    "ano" integer NOT NULL,
    "numero_documento" "text" NOT NULL,
    "data_documento" "date",
    "orgao" "text",
    "favorecido" "text",
    "municipio" "text",
    "uf" "text",
    "valor_empenhado" numeric DEFAULT 0,
    "valor_liquidado" numeric DEFAULT 0,
    "valor_pago" numeric DEFAULT 0,
    "funcao" "text",
    "subfuncao" "text",
    "programa" "text",
    "fonte_dado" "text" DEFAULT 'portal_transparencia_siafi'::"text",
    "created_at" timestamp without time zone DEFAULT "now"(),
    "updated_at" timestamp without time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."execucao_financeira_transferencias" (
    "id" bigint NOT NULL,
    "ano" integer NOT NULL,
    "mes" integer NOT NULL,
    "orgao" "text",
    "favorecido" "text",
    "municipio" "text",
    "uf" "text",
    "valor" numeric(18,2),
    "tipo_transferencia" "text",
    "fonte_dado" "text",
    "created_at" timestamp without time zone DEFAULT "now"(),
    "updated_at" timestamp without time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."execucoes_pipeline" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "job_nome" "text" NOT NULL,
    "iniciado_em" timestamp with time zone DEFAULT "now"() NOT NULL,
    "finalizado_em" timestamp with time zone,
    "status" "text" NOT NULL,
    "detalhes" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."execucoes_pipeline_etapas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "execucao_id" "uuid" NOT NULL,
    "etapa_nome" "text" NOT NULL,
    "iniciado_em" timestamp with time zone DEFAULT "now"() NOT NULL,
    "finalizado_em" timestamp with time zone,
    "status" "text" NOT NULL,
    "detalhes" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."faf_planos_acao" (
    "id_plano_acao" integer NOT NULL,
    "codigo" "text",
    "data_inicio_vigencia" "date",
    "data_fim_vigencia" "date",
    "situacao" "text",
    "id_programa" integer,
    "sigla_orgao_repassador" "text",
    "cnpj_orgao_repassador" "text",
    "nome_orgao_repassador" "text",
    "cnpj_fundo_repassador" "text",
    "nome_fundo_repassador" "text",
    "uf_fundo_repassador" "text",
    "cnpj_ente_recebedor" "text",
    "nome_ente_recebedor" "text",
    "uf_recebedor" "text",
    "municipio_recebedor" "text",
    "ibge_recebedor" integer,
    "cnpj_fundo_recebedor" "text",
    "nome_fundo_recebedor" "text",
    "uf_fundo_recebedor" "text",
    "municipio_fundo_recebedor" "text",
    "ibge_fundo_recebedor" integer,
    "valor_total" numeric,
    "valor_repasse_total" numeric,
    "valor_repasse_emenda" numeric,
    "valor_repasse_voluntario" numeric,
    "valor_recursos_proprios" numeric,
    "valor_custeio" numeric,
    "valor_investimento" numeric,
    "valor_saldo_disponivel" numeric,
    "dados" "jsonb",
    "atualizado_em" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."financiamento_eleitoral" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "parlamentar_id" "uuid",
    "cpf_candidato" "text" NOT NULL,
    "ano_eleicao" integer NOT NULL,
    "sq_receita" bigint,
    "data_receita" "date",
    "fonte_receita" "text",
    "origem_receita" "text",
    "natureza_receita" "text",
    "especie_receita" "text",
    "valor" numeric(14,2) DEFAULT 0 NOT NULL,
    "nome_doador" "text",
    "cpf_cnpj_doador" "text",
    "nome_doador_rfb" "text",
    "uf_doador" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."fipe_tabelas" (
    "codigo" "text" NOT NULL,
    "mes" "text"
);

CREATE TABLE IF NOT EXISTS "public"."folha_custo_gabinete" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "casa" "text" NOT NULL,
    "parlamentar_nome" "text" NOT NULL,
    "parlamentar_id_externo" "text",
    "salario_tipo" "text" NOT NULL,
    "n_funcionarios" integer NOT NULL,
    "n_com_salario" integer NOT NULL,
    "soma_salarios" numeric(14,2),
    "media_salario" numeric(12,2),
    "maior_salario" numeric(12,2),
    "n_lotacoes" integer,
    "snapshot_date" "date" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."folha_doador_leads" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "casa" "text" NOT NULL,
    "parlamentar_id_externo" "text",
    "parlamentar_nome" "text",
    "secretario_nome" "text" NOT NULL,
    "doador_nome" "text" NOT NULL,
    "doador_cpf_cnpj" "text",
    "valor_doado" numeric(14,2),
    "ano_eleicao" smallint,
    "snapshot_date" "date" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."folha_gabinete" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "casa" "text" NOT NULL,
    "snapshot_date" "date" NOT NULL,
    "chave_natural" "text" NOT NULL,
    "secretario_nome" "text" NOT NULL,
    "secretario_id_externo" "text",
    "cargo" "text",
    "funcao" "text",
    "vinculo" "text",
    "parlamentar_id_externo" "text",
    "parlamentar_nome" "text",
    "gabinete_codigo" "text",
    "gabinete_raw" "text",
    "data_nomeacao" "date",
    "data_admissao" "date",
    "valor_remuneracao" numeric(12,2),
    "dados" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "folha_gabinete_casa_check" CHECK (("casa" = ANY (ARRAY['camara'::"text", 'senado'::"text"])))
);

CREATE TABLE IF NOT EXISTS "public"."folha_nepotismo_leads" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "casa" "text" NOT NULL,
    "secretario_nome" "text" NOT NULL,
    "gabinete_parlamentar_nome" "text",
    "gabinete_parlamentar_id" "text",
    "sobrenome" "text" NOT NULL,
    "parlamentar_homonimo_nome" "text" NOT NULL,
    "parlamentar_homonimo_id" "text",
    "snapshot_date" "date" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."fundacoes_partidarias" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "cnpj" "text" NOT NULL,
    "razao_social" "text" NOT NULL,
    "nome_popular" "text",
    "partido_sigla" "text" NOT NULL,
    "partido_cnpj" "text",
    "logradouro" "text",
    "numero" "text",
    "complemento" "text",
    "bairro" "text",
    "municipio" "text",
    "uf" "text",
    "cep" "text",
    "telefone" "text",
    "data_abertura" "date",
    "capital_social" numeric(18,2) DEFAULT 0,
    "natureza_juridica" "text",
    "situacao_cadastral" smallint,
    "presidente_nome" "text",
    "presidente_desde" "date",
    "mesmo_endereco_partido" boolean DEFAULT false,
    "mesmo_telefone_partido" boolean DEFAULT false,
    "dados_brasilapi" "jsonb",
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."fundacoes_repasses" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "sq_despesa" bigint NOT NULL,
    "aa_exercicio" smallint NOT NULL,
    "sg_partido" "text" NOT NULL,
    "nm_partido" "text",
    "cnpj_partido" "text",
    "cnpj_fundacao" "text" NOT NULL,
    "nm_fundacao" "text",
    "ds_gasto" "text",
    "tipo_repasse" "text" DEFAULT 'outros'::"text" NOT NULL,
    "dt_pagamento" "date",
    "vr_pagamento" numeric(18,2) DEFAULT 0 NOT NULL,
    "cd_fonte_despesa" smallint,
    "ds_fonte_despesa" "text",
    "dados" "jsonb",
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."fundacoes_embeddings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "cnpj" "text" NOT NULL,
    "chunk_type" "text" NOT NULL,
    "chunk_text" "text" NOT NULL,
    "embedding" "public"."vector"(1536),
    "metadata" "jsonb",
    "criado_em" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."fundacoes_nf_partidos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "sq_despesa" bigint NOT NULL,
    "aa_exercicio" smallint NOT NULL,
    "cnpj_partido" "text" NOT NULL,
    "sg_partido" "text",
    "uf" "text" DEFAULT 'BR'::"text",
    "nr_documento" "text",
    "cd_tipo_despesa" "text",
    "ds_tipo_despesa" "text",
    "vr_documento" numeric(18,2),
    "dt_pagamento" "date",
    "url_pdf" "text",
    "cnpj_fornecedor" "text",
    "tipo_fornecedor" "text",
    "eh_repasse_fundacao" boolean DEFAULT false,
    "fundacao_cnpj" "text",
    "dados" "jsonb",
    "atualizado_em" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."glossario_tech" (
    "id" "text" NOT NULL,
    "lang" "text" DEFAULT 'pt-br'::"text" NOT NULL,
    "titulo" "text" NOT NULL,
    "descricao" "text",
    "tags" "text"[] DEFAULT '{}'::"text"[],
    "letra" "text",
    "fonte_url" "text",
    "criado_em" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."judiciario_highlights" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "semana_referencia" "date" NOT NULL,
    "posicao" integer NOT NULL,
    "titulo_curto" "text" NOT NULL,
    "resumo" "text" NOT NULL,
    "tribunal_id" integer,
    "tema" "text",
    "link_externo" "text",
    "processo_id" "uuid",
    "ativo" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "judiciario_highlights_posicao_check" CHECK ((("posicao" >= 1) AND ("posicao" <= 99)))
);

CREATE TABLE IF NOT EXISTS "public"."judiciario_processos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tribunal_id" integer NOT NULL,
    "identificador_externo" "text" NOT NULL,
    "numero_processo" "text" NOT NULL,
    "classe" "text",
    "relator" "text",
    "orgao_julgador" "text",
    "tipo_decisao" "text",
    "data_decisao" "date",
    "tema" "text",
    "ementa" "text",
    "link_oficial" "text",
    "fonte" "text" DEFAULT 'datajud'::"text" NOT NULL,
    "metadata" "jsonb",
    "data_coleta" timestamp with time zone DEFAULT "now"() NOT NULL,
    "search_vector" "tsvector" GENERATED ALWAYS AS (((((("setweight"("to_tsvector"('"portuguese"'::"regconfig", COALESCE("numero_processo", ''::"text")), 'A'::"char") || "setweight"("to_tsvector"('"portuguese"'::"regconfig", COALESCE("classe", ''::"text")), 'B'::"char")) || "setweight"("to_tsvector"('"portuguese"'::"regconfig", COALESCE("relator", ''::"text")), 'B'::"char")) || "setweight"("to_tsvector"('"portuguese"'::"regconfig", COALESCE("orgao_julgador", ''::"text")), 'C'::"char")) || "setweight"("to_tsvector"('"portuguese"'::"regconfig", COALESCE("tema", ''::"text")), 'C'::"char")) || "setweight"("to_tsvector"('"portuguese"'::"regconfig", COALESCE("ementa", ''::"text")), 'D'::"char"))) STORED
);

CREATE TABLE IF NOT EXISTS "public"."tribunais" (
    "id" integer NOT NULL,
    "sigla" "text" NOT NULL,
    "nome_completo" "text" NOT NULL,
    "categoria" "text" NOT NULL,
    "uf" "text",
    "endpoint_datajud" "text",
    "cor" "text",
    "cor_light" "text",
    "ativo" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "tribunais_categoria_check" CHECK (("categoria" = ANY (ARRAY['superior'::"text", 'federal'::"text", 'estadual'::"text", 'trabalho'::"text", 'outro'::"text"])))
);

CREATE TABLE IF NOT EXISTS "public"."ibama_autuacoes" (
    "id" bigint NOT NULL,
    "num_auto_infracao" "text" NOT NULL,
    "tp_pessoa" character(2),
    "cpf_cnpj_infrator" "text" NOT NULL,
    "nome_infrator" "text",
    "des_infracao" "text",
    "des_situacao" "text",
    "val_auto_infracao" numeric(16,2),
    "dat_infracao" "date",
    "municipio" "text",
    "uf" character(2),
    "num_processo" "text",
    "ingested_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."ibge_indicadores" (
    "id" bigint NOT NULL,
    "codigo_ibge" "text" NOT NULL,
    "pesquisa_id" "text" NOT NULL,
    "variavel_id" "text" NOT NULL,
    "variavel_nome" "text" NOT NULL,
    "ano" integer NOT NULL,
    "valor" numeric,
    "unidade" "text",
    "atualizado_em" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."ibge_municipios" (
    "codigo_ibge" "text" NOT NULL,
    "nome" "text" NOT NULL,
    "uf" "text" NOT NULL,
    "codigo_uf" integer NOT NULL,
    "nome_uf" "text" NOT NULL,
    "nome_regiao" "text" NOT NULL,
    "nome_mesorregiao" "text",
    "nome_microrregiao" "text",
    "nome_regiao_imediata" "text",
    "nome_regiao_intermediaria" "text",
    "latitude" numeric(10,6),
    "longitude" numeric(10,6),
    "atualizado_em" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."identity_audit_results" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "parlamentar_uid" "uuid",
    "nome_detectado" "text",
    "nome_oficial" "text",
    "confidence" numeric,
    "status" "text" DEFAULT 'verified'::"text",
    "audit_run_at" timestamp without time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."identity_review_queue" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "parlamentar_uid" "uuid",
    "confidence" numeric,
    "review_status" "text" DEFAULT 'pending'::"text",
    "created_at" timestamp without time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."impacto_federativo" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "uf" "text" NOT NULL,
    "institution_id_estado" "uuid",
    "ano" integer NOT NULL,
    "total_emendas_empenhado" numeric DEFAULT 0,
    "total_emendas_pago" numeric DEFAULT 0,
    "total_transferencias" numeric DEFAULT 0,
    "num_parlamentares" integer DEFAULT 0,
    "num_emendas" integer DEFAULT 0,
    "score_impacto_parlamentar" numeric DEFAULT 0,
    "score_capacidade_fiscal_estado" numeric DEFAULT 0,
    "indice_correlacao" numeric DEFAULT 0,
    "narrativa" "text",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."indicadores" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "institution_id" "uuid" NOT NULL,
    "observatorio_id" "text" NOT NULL,
    "indicador" "text" NOT NULL,
    "valor" numeric DEFAULT 0 NOT NULL,
    "periodo" "text",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."indicadores_macroeconomicos" (
    "id" integer NOT NULL,
    "nome" "text" NOT NULL,
    "valor" numeric NOT NULL,
    "capturado_em" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."timeline_events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "parlamentar_uid" "uuid" NOT NULL,
    "event_type" "text" NOT NULL,
    "event_category" "text",
    "reference_table" "text",
    "reference_id" "uuid",
    "event_date" "date" NOT NULL,
    "legislatura" integer,
    "metadata" "jsonb",
    "created_at" timestamp without time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."ingestion_runs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "pipeline_name" "text" NOT NULL,
    "started_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "finished_at" timestamp with time zone,
    "status" "text" DEFAULT 'running'::"text" NOT NULL,
    "source" "text",
    "records_processed" integer DEFAULT 0,
    "records_inserted" integer DEFAULT 0,
    "records_updated" integer DEFAULT 0,
    "error_message" "text",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb"
);

CREATE TABLE IF NOT EXISTS "public"."institucional_power_index" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "parlamentar_id" "uuid",
    "nome" "text",
    "partido" "text",
    "uf" "text",
    "valor_pago_emendas" numeric,
    "valor_total_emendas" numeric,
    "taxa_execucao" numeric,
    "posicao_nacional" integer,
    "created_at" timestamp without time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."institutions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "observatorio_id" "text" NOT NULL,
    "external_id" "text",
    "nome" "text" NOT NULL,
    "nome_curto" "text",
    "tipo" "text",
    "uf" "text",
    "partido" "text",
    "foto_url" "text",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."intelligence_alerts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "parlamentar_uid" "uuid",
    "alert_type" "text",
    "created_at" timestamp without time zone DEFAULT "now"(),
    "read" boolean DEFAULT false
);

CREATE TABLE IF NOT EXISTS "public"."intelligence_notes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "titulo" "text" NOT NULL,
    "conteudo" "text",
    "tipo" "text" DEFAULT 'analise'::"text",
    "data_referencia" "date" DEFAULT CURRENT_DATE,
    "publicado" boolean DEFAULT false,
    "tags" "text"[] DEFAULT '{}'::"text"[],
    "created_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."intelligence_queue" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "parlamentar_uid" "uuid",
    "status" "text" DEFAULT 'pending'::"text",
    "priority" integer DEFAULT 1,
    "created_at" timestamp without time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."leiloes_leiloeiros" (
    "id" bigint NOT NULL,
    "cnpj_basico" character(8) NOT NULL,
    "cnpj_ordem" character(4) NOT NULL,
    "cnpj_dv" character(2) NOT NULL,
    "cnpj_completo" character(14) GENERATED ALWAYS AS (((("cnpj_basico")::"text" || ("cnpj_ordem")::"text") || ("cnpj_dv")::"text")) STORED,
    "razao_social" "text",
    "nome_fantasia" "text",
    "situacao_cadastral" smallint,
    "data_situacao_cadastral" "date",
    "data_inicio_atividade" "date",
    "cnae_fiscal" character varying(10),
    "identificador_matriz_filial" smallint,
    "tipo_logradouro" "text",
    "logradouro" "text",
    "numero" "text",
    "complemento" "text",
    "bairro" "text",
    "cep" "text",
    "uf" character(2),
    "municipio_codigo" integer,
    "ddd1" character varying(4),
    "telefone1" character varying(15),
    "correio_eletronico" "text",
    "data_ingestao" "date" DEFAULT CURRENT_DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."leiloes_processos" (
    "id" bigint NOT NULL,
    "numero_processo" "text" NOT NULL,
    "tribunal" character varying(12) NOT NULL,
    "grau" character varying(10),
    "classe_codigo" integer,
    "classe_nome" "text",
    "assuntos" "jsonb",
    "orgao_julgador_codigo" integer,
    "orgao_julgador_nome" "text",
    "municipio_ibge" integer,
    "movimentos" "jsonb",
    "data_ajuizamento" timestamp with time zone,
    "data_ultima_atualizacao" timestamp with time zone,
    "data_ingestao" "date" DEFAULT CURRENT_DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."licitacoes" (
    "id" integer DEFAULT 0,
    "numero" "text",
    "objeto" "text",
    "data_abertura" "date",
    "data_publicacao" "date",
    "situacao_codigo" "text",
    "situacao_descricao" "text",
    "modalidade_codigo" "text",
    "modalidade_descricao" "text",
    "ug_codigo" "text",
    "ug_descricao" "text",
    "orgao_codigo" "text",
    "orgao_descricao" "text",
    "valor_estimado" numeric(18,2),
    "tipo_licitacao" "text",
    "numero_processo" "text",
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "numero_controle_pncp" "text" NOT NULL,
    "cnpj_orgao" "text",
    "razao_social_orgao" "text",
    "esfera_orgao" "text",
    "uf_unidade" "text",
    "municipio_unidade" "text",
    "ano_compra" integer,
    "sequencial_compra" integer,
    "valor_homologado" numeric(18,2),
    "fonte" "text" DEFAULT 'portal_tf'::"text"
);

CREATE TABLE IF NOT EXISTS "public"."licitacoes_ingest_log" (
    "id" integer NOT NULL,
    "descricao" "text",
    "status" "text",
    "n_novos" integer DEFAULT 0,
    "erro" "text",
    "started_at" timestamp with time zone DEFAULT "now"(),
    "finished_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS "public"."licitacoes_participantes" (
    "id" integer NOT NULL,
    "licitacao_id" integer,
    "cnpj" "text",
    "cpf" "text",
    "nome" "text",
    "situacao_participante" "text",
    "situacao_fornecedor" "text",
    "valor_proposta" numeric(18,2),
    "updated_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."media_briefings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "report_id" "uuid",
    "headline" "text" NOT NULL,
    "subtitulo" "text",
    "pontos_chave" "text"[] DEFAULT '{}'::"text"[],
    "citacao_institucional" "text",
    "tweet" "text",
    "linkedin_post" "text",
    "press_release" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."mg_compras_fornecedor" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "cnpj_norm" "text",
    "nome" "text",
    "ano" integer,
    "n_contratos" integer,
    "vr_homologado" numeric(18,2),
    "vr_atualizado" numeric(18,2),
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."mg_contratos" (
    "id" "text" NOT NULL,
    "ano_assinatura" integer,
    "codigo_orgao" "text",
    "nome_orgao" "text",
    "cnpj_cpf_fornecedor" "text",
    "nome_fornecedor" "text",
    "tipo_pessoa" "text",
    "numero_processo" "text",
    "numero_contrato" "text",
    "situacao" "text",
    "tipo_contrato" "text",
    "objeto" "text",
    "data_assinatura" "date",
    "data_inicio_vigencia" "date",
    "data_termino_vigencia" "date",
    "procedimento_contratacao" "text",
    "procedimento_detalhamento" "text",
    "valor_total" numeric(18,2),
    "valor_empenhado" numeric(18,2),
    "valor_liquidado" numeric(18,2),
    "updated_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."mg_convenios" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "convenio_id" "text",
    "ano" integer,
    "orgao_id" "text",
    "municipio_id" "text",
    "convenente" "text",
    "convenente_cnpj" "text",
    "vr_total" numeric(16,2),
    "vr_concede" numeric(16,2),
    "vr_emenda_parl" numeric(16,2),
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."mg_convenios_entrada" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "id_convenio" "text",
    "concedente" "text",
    "concedente_doc" "text",
    "proponente" "text",
    "situacao" "text",
    "ano" integer,
    "vr_concedente" numeric(18,2),
    "vr_proponente" numeric(18,2),
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."mg_covid_compras" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "numero_processo" "text",
    "objeto" "text",
    "orgao_demandante" "text",
    "orgao_contrato" "text",
    "situacao" "text",
    "procedimento" "text",
    "numero_contrato" "text",
    "data_publicacao" "date",
    "contratado" "text",
    "cnpj_norm" "text",
    "item" "text",
    "linha_fornecimento" "text",
    "cidade_entrega" "text",
    "quantidade" numeric(16,3),
    "valor_ref_unit" numeric(16,2),
    "valor_hom_unit" numeric(16,2),
    "valor_referencia" numeric(16,2),
    "valor_homologado" numeric(16,2),
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."mg_empenhos" (
    "id" "text" NOT NULL,
    "ano_exercicio" integer NOT NULL,
    "unidade_orcamentaria_codigo" integer,
    "unidade_orcamentaria_sigla" "text",
    "unidade_orcamentaria_nome" "text",
    "ano_empenho" integer,
    "numero_empenho" integer,
    "data_registro" "date",
    "numero_processo_compra" "text",
    "elemento_despesa_codigo" integer,
    "elemento_despesa_descricao" "text",
    "item_despesa_codigo" integer,
    "item_despesa_descricao" "text",
    "fonte_recurso_codigo" integer,
    "fonte_recurso_descricao" "text",
    "razao_social_credor" "text",
    "cnpj_cpf_credor" "text",
    "valor_empenhado" numeric(18,2),
    "valor_liquidado" numeric(18,2),
    "valor_pago" numeric(18,2),
    "updated_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."mg_despesa_pessoal_vale" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ano_mes" integer,
    "masp" "text",
    "orgao_sigla" "text",
    "orgao" "text",
    "nome" "text",
    "valor" numeric(18,2),
    "cargo_sigla" "text",
    "cargo_descricao" "text",
    "data_inicio" "date",
    "data_termino" "date",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."mg_diarias_orgao" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ano" integer NOT NULL,
    "cd_unidade_orc" integer,
    "orgao" "text",
    "sigla" "text",
    "vr_empenhado" numeric(18,2),
    "vr_liquidado" numeric(18,2),
    "vr_pago" numeric(18,2),
    "qtd_registros" integer,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."mg_divida_tipo" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ano" integer NOT NULL,
    "cd_tipo" integer,
    "tipo" "text",
    "vr_juros" numeric(18,2),
    "vr_amortizacao" numeric(18,2),
    "vr_total" numeric(18,2) GENERATED ALWAYS AS ((COALESCE("vr_juros", (0)::numeric) + COALESCE("vr_amortizacao", (0)::numeric))) STORED,
    "qtd_registros" integer,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."mg_doacoes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tipo_instrumento" "text",
    "ano" integer,
    "mes" integer,
    "categoria_valor" "text",
    "orgao_recebedor" "text",
    "natureza_doador" "text",
    "doador" "text",
    "objeto" "text",
    "quantidade" "text",
    "vigencia" "text",
    "recurso_tj_mp" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "dedupe_key" "text" GENERATED ALWAYS AS ("md5"(((((((((COALESCE("doador", ''::"text") || '|'::"text") || COALESCE("objeto", ''::"text")) || '|'::"text") || COALESCE("orgao_recebedor", ''::"text")) || '|'::"text") || COALESCE(("ano")::"text", ''::"text")) || '|'::"text") || COALESCE(("mes")::"text", ''::"text")))) STORED
);

CREATE TABLE IF NOT EXISTS "public"."mg_emendas_estaduais" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "id_emenda" "text",
    "nr_emenda" "text",
    "ano" integer,
    "autor" "text",
    "grupo" "text",
    "modalidade" "text",
    "uo_beneficiada" "text",
    "objeto" "text",
    "vr_emenda" numeric(18,2),
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."mg_emendas_federais" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "esfera" "text",
    "modalidade" "text",
    "autoria" "text",
    "tipo_instrumento" "text",
    "numero_emenda" "text",
    "ano" integer,
    "codigo_siafi" "text",
    "codigo_sigcon" "text",
    "valor_indicado" numeric(18,2),
    "valor_repassado" numeric(18,2),
    "valor_nao_repassado" numeric(18,2) GENERATED ALWAYS AS ((COALESCE("valor_indicado", (0)::numeric) - COALESCE("valor_repassado", (0)::numeric))) STORED,
    "objeto" "text",
    "funcao_governo" "text",
    "orgao_executor" "text",
    "dedupe_key" "text" GENERATED ALWAYS AS ("md5"(((((((((((((((COALESCE("numero_emenda", ''::"text") || '|'::"text") || COALESCE(("ano")::"text", ''::"text")) || '|'::"text") || COALESCE("codigo_siafi", ''::"text")) || '|'::"text") || COALESCE("codigo_sigcon", ''::"text")) || '|'::"text") || COALESCE("orgao_executor", ''::"text")) || '|'::"text") || COALESCE("objeto", ''::"text")) || '|'::"text") || COALESCE(("valor_indicado")::"text", ''::"text")) || '|'::"text") || COALESCE(("valor_repassado")::"text", ''::"text")))) STORED,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."mg_emendas_pix" (
    "id" "text" NOT NULL,
    "numero_emenda" "text",
    "ano" integer,
    "cnpj_favorecido" "text",
    "nome_favorecido" "text",
    "municipio" "text",
    "valor_pago" numeric(18,2) DEFAULT 0,
    "data_pagamento" "date",
    "objeto" "text",
    "updated_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."mg_empenhos_sancionados" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ano" integer,
    "numero_empenho" "text",
    "orgao" "text",
    "credor" "text",
    "cnpj_norm" "text",
    "elemento_despesa" "text",
    "fonte_recurso" "text",
    "data_registro" "date",
    "numero_processo" "text",
    "valor_empenhado" numeric(16,2),
    "valor_liquidado" numeric(16,2),
    "valor_pago" numeric(16,2),
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "dedupe_key" "text" GENERATED ALWAYS AS ("md5"(((((((((((((((((COALESCE(("ano")::"text", ''::"text") || '|'::"text") || COALESCE("numero_empenho", ''::"text")) || '|'::"text") || COALESCE("orgao", ''::"text")) || '|'::"text") || COALESCE("elemento_despesa", ''::"text")) || '|'::"text") || COALESCE("fonte_recurso", ''::"text")) || '|'::"text") || COALESCE("numero_processo", ''::"text")) || '|'::"text") || COALESCE(("valor_empenhado")::"text", ''::"text")) || '|'::"text") || COALESCE(("valor_liquidado")::"text", ''::"text")) || '|'::"text") || COALESCE(("valor_pago")::"text", ''::"text")))) STORED
);

CREATE TABLE IF NOT EXISTS "public"."mg_licitacao_sobrepreco" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ano" integer,
    "numero_processo" "text",
    "numero_item" "text",
    "orgao" "text",
    "objeto" "text",
    "fornecedor" "text",
    "cnpj_norm" "text",
    "item_descricao" "text",
    "elemento" "text",
    "situacao" "text",
    "quantidade" numeric(18,3),
    "vr_unit_referencia" numeric(18,4),
    "vr_unit_homologado" numeric(18,4),
    "vr_total_referencia" numeric(18,2),
    "vr_total_homologado" numeric(18,2),
    "sobrepreco_valor" numeric(18,2) GENERATED ALWAYS AS ((COALESCE("vr_total_homologado", (0)::numeric) - COALESCE("vr_total_referencia", (0)::numeric))) STORED,
    "sobrepreco_pct" numeric(10,2) GENERATED ALWAYS AS ("round"(((("vr_unit_homologado" / NULLIF("vr_unit_referencia", (0)::numeric)) - (1)::numeric) * (100)::numeric), 2)) STORED,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."mg_notas_fornecedor" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "cnpj_norm" "text",
    "nome" "text",
    "ano" integer,
    "n_notas" integer,
    "valor_total" numeric(18,2),
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."mg_os_parcerias" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "id_instrumento" "text",
    "tipo_instrumento" "text",
    "num_termo" "text",
    "orgao_estatal" "text",
    "entidade" "text",
    "entidade_sigla" "text",
    "cnpj_norm" "text",
    "objeto" "text",
    "situacao" "text",
    "inicio_vigencia" "date",
    "fim_vigencia" "date",
    "vr_repasse_previsto" numeric(18,2),
    "vr_repasse_atualizado" numeric(18,2),
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."mg_terceirizados" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "empresa" "text",
    "cnpj_norm" "text",
    "orgao" "text",
    "mes_referencia" "date",
    "qtd_trabalhadores" integer,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."mg_ingest_log" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "dataset" "text" NOT NULL,
    "status" "text" DEFAULT 'running'::"text" NOT NULL,
    "n_gravados" integer,
    "erro" "text",
    "started_at" timestamp with time zone DEFAULT "now"(),
    "finished_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS "public"."mg_ipsemg_contratos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "num_contrato" "text",
    "cnpj_norm" "text",
    "nome" "text",
    "ramo_atividade" "text",
    "municipio" "text",
    "regiao" "text",
    "microrregiao" "text",
    "inicio_vigencia" "date",
    "fim_vigencia" "date",
    "periodo_referencia" "date",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."mg_lrf_limites" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "periodo" "text" NOT NULL,
    "ano_ref" integer,
    "rcl" numeric(18,2),
    "rcl_ajustada" numeric(18,2),
    "dtp" numeric(18,2),
    "limite_maximo" numeric(18,2),
    "limite_prudencial" numeric(18,2),
    "limite_alerta" numeric(18,2),
    "pct_dtp" numeric(6,2) GENERATED ALWAYS AS ("round"((("dtp" / NULLIF("rcl_ajustada", (0)::numeric)) * (100)::numeric), 2)) STORED,
    "pct_maximo" numeric(6,2) GENERATED ALWAYS AS ("round"((("limite_maximo" / NULLIF("rcl_ajustada", (0)::numeric)) * (100)::numeric), 2)) STORED,
    "pct_prudencial" numeric(6,2) GENERATED ALWAYS AS ("round"((("limite_prudencial" / NULLIF("rcl_ajustada", (0)::numeric)) * (100)::numeric), 2)) STORED,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."mg_lrf_pessoal" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "mes_ano" "text" NOT NULL,
    "ano" integer,
    "mes" integer,
    "despesa_bruta" numeric(18,2),
    "pessoal_ativo" numeric(18,2),
    "pessoal_inativo" numeric(18,2),
    "terceirizacoes" numeric(18,2),
    "despesa_liquida" numeric(18,2),
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."mg_obras" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "contrato" "text",
    "objeto" "text",
    "empresa" "text",
    "cnpj_norm" "text",
    "orgao" "text",
    "setor" "text",
    "situacao" "text",
    "modalidade" "text",
    "municipios" "text",
    "data_assinatura" "date",
    "dias_paralisados" integer,
    "dias_atuais" integer,
    "valor_total" numeric(16,2),
    "total_medido" numeric(16,2),
    "percentual_execucao" numeric(6,4),
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."mg_remuneracao" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "snapshot_mes" "date" NOT NULL,
    "ano" integer,
    "mes" integer,
    "poder" "text" DEFAULT 'executivo'::"text" NOT NULL,
    "orgao" "text",
    "servidor_nome" "text" NOT NULL,
    "servidor_id_externo" "text",
    "cargo" "text",
    "funcao" "text",
    "situacao" "text",
    "carga_horaria" "text",
    "remuneracao_bruta" numeric(14,2),
    "descontos" numeric(14,2),
    "remuneracao_liquida" numeric(14,2),
    "remuneracao_base" numeric(14,2),
    "teto_referencia" numeric(14,2) DEFAULT 46366.19 NOT NULL,
    "dados" "jsonb",
    "url_origem" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "abate_teto" numeric(14,2),
    "acima_teto" boolean GENERATED ALWAYS AS (((COALESCE("abate_teto", (0)::numeric) > (0)::numeric) OR ("remuneracao_base" > "teto_referencia"))) STORED,
    "valor_excedente" numeric(14,2) GENERATED ALWAYS AS (
CASE
    WHEN (COALESCE("abate_teto", (0)::numeric) > (0)::numeric) THEN "abate_teto"
    ELSE GREATEST(("remuneracao_base" - "teto_referencia"), (0)::numeric)
END) STORED
);

CREATE TABLE IF NOT EXISTS "public"."mg_reparacao_vale" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "codigo_iniciativa" "text",
    "iniciativa" "text",
    "anexo" "text",
    "valor" numeric(18,2),
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."mg_restos_orgao" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ano" integer NOT NULL,
    "cd_unidade_orc" integer,
    "orgao" "text",
    "sigla" "text",
    "vr_nao_processado" numeric(18,2),
    "vr_processado" numeric(18,2),
    "vr_pago" numeric(18,2),
    "vr_inscrito" numeric(18,2) GENERATED ALWAYS AS ((COALESCE("vr_nao_processado", (0)::numeric) + COALESCE("vr_processado", (0)::numeric))) STORED,
    "qtd_registros" integer,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."mg_siafi_execucao" (
    "id" "text" NOT NULL,
    "ano_exercicio" integer NOT NULL,
    "unidade_orcamentaria_codigo" "text",
    "unidade_orcamentaria_nome" "text",
    "orgao_codigo" "text",
    "orgao_nome" "text",
    "funcao_codigo" "text",
    "funcao_descricao" "text",
    "subfuncao_codigo" "text",
    "subfuncao_descricao" "text",
    "programa_codigo" "text",
    "programa_descricao" "text",
    "acao_codigo" "text",
    "acao_descricao" "text",
    "elemento_despesa_codigo" "text",
    "elemento_despesa_descricao" "text",
    "fonte_recurso_codigo" "text",
    "fonte_recurso_descricao" "text",
    "numero_empenho" "text",
    "data_empenho" "date",
    "razao_social_credor" "text",
    "cnpj_cpf_credor" "text",
    "valor_empenhado" numeric(18,2) DEFAULT 0,
    "valor_liquidado" numeric(18,2) DEFAULT 0,
    "valor_pago" numeric(18,2) DEFAULT 0,
    "updated_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."mg_voos_governador" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "numero_db" "text",
    "data_voo" "date",
    "aeronave" "text",
    "base" "text",
    "origem" "text",
    "destino" "text",
    "horas_voadas" "text",
    "historico" "text",
    "passageiro" "text",
    "cargo_passageiro" "text",
    "orgao_passageiro" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."midia_eventos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "slug" "text" NOT NULL,
    "nome" "text" NOT NULL,
    "tipo" "public"."midia_tipo_evento" NOT NULL,
    "data_inicio" "date" NOT NULL,
    "data_fim" "date",
    "descricao" "text",
    "notas" "text",
    "criado_em" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."midia_inter_meios" (
    "id" bigint NOT NULL,
    "ano" smallint NOT NULL,
    "categoria" "public"."midia_categoria" NOT NULL,
    "investimento_total" numeric(18,2),
    "share_pct" numeric(5,2),
    "variacao_anual_pct" numeric(6,2),
    "metodologia" "public"."midia_metodologia" DEFAULT 'inter_meios'::"public"."midia_metodologia",
    "notas" "text",
    "importado_em" timestamp with time zone DEFAULT "now"()
);

ALTER TABLE "public"."midia_inter_meios" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."midia_inter_meios_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."midia_kantar_releases" (
    "id" bigint NOT NULL,
    "semana_inicio" "date" NOT NULL,
    "semana_fim" "date" NOT NULL,
    "evento_id" "uuid",
    "veiculo_id" "uuid",
    "nome_veiculo_raw" "text" NOT NULL,
    "programa" "text" NOT NULL,
    "praca" "text" NOT NULL,
    "audiencia_media_pct" numeric(5,2),
    "audiencia_absoluta" bigint,
    "posicao_ranking" smallint,
    "metodologia" "public"."midia_metodologia" NOT NULL,
    "fonte_url" "text",
    "importado_em" timestamp with time zone DEFAULT "now"()
);

ALTER TABLE "public"."midia_kantar_releases" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."midia_kantar_releases_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."midia_secom_verbas" (
    "id" bigint NOT NULL,
    "cnpj" "text" NOT NULL,
    "nome_favorecido" "text" NOT NULL,
    "veiculo_id" "uuid",
    "ano" smallint NOT NULL,
    "mes" smallint NOT NULL,
    "valor" numeric(15,2) NOT NULL,
    "orgao_codigo" "text",
    "orgao_nome" "text",
    "metodologia" "public"."midia_metodologia" DEFAULT 'portal_transparencia'::"public"."midia_metodologia",
    "fonte_url" "text",
    "importado_em" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "midia_secom_verbas_mes_check" CHECK ((("mes" >= 1) AND ("mes" <= 12)))
);

ALTER TABLE "public"."midia_secom_verbas" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."midia_secom_verbas_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."midia_veiculos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "slug" "text" NOT NULL,
    "nome_comercial" "text" NOT NULL,
    "grupo" "text",
    "cnpjs" "text"[] DEFAULT '{}'::"text"[],
    "youtube_channel_id" "text",
    "categoria" "public"."midia_categoria" NOT NULL,
    "ativo" boolean DEFAULT true,
    "notas" "text",
    "criado_em" timestamp with time zone DEFAULT "now"(),
    "atualizado_em" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."midia_youtube_eventos" (
    "id" bigint NOT NULL,
    "evento_id" "uuid",
    "veiculo_id" "uuid",
    "youtube_channel_id" "text" NOT NULL,
    "youtube_video_id" "text",
    "data_coleta" "date" NOT NULL,
    "views_acumulados" bigint,
    "inscricoes_canal" bigint,
    "pico_simultaneos_declarado" bigint,
    "metodologia" "public"."midia_metodologia" DEFAULT 'youtube_api'::"public"."midia_metodologia",
    "fonte_url" "text",
    "importado_em" timestamp with time zone DEFAULT "now"()
);

ALTER TABLE "public"."midia_youtube_eventos" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."midia_youtube_eventos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."ministerios" (
    "id" integer NOT NULL,
    "nome" "text",
    "sigla" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."municipios" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "nome" "text",
    "uf" "text",
    "ibge_code" "text",
    "created_at" timestamp without time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."municipios_ibge" (
    "codigo_ibge" "text" NOT NULL,
    "nome" "text" NOT NULL,
    "uf" "text" NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."tse_receitas_brutas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "sq_receita" bigint NOT NULL,
    "ano_eleicao" smallint NOT NULL,
    "sq_candidato" "text" NOT NULL,
    "nm_candidato" "text" NOT NULL,
    "nr_cpf_candidato" "text",
    "cd_cargo" smallint NOT NULL,
    "ds_cargo" "text" NOT NULL,
    "sg_uf" "text" NOT NULL,
    "nr_partido" smallint,
    "sg_partido" "text",
    "nm_partido" "text",
    "cd_fonte_receita" smallint,
    "ds_fonte_receita" "text",
    "cd_origem_receita" integer,
    "ds_origem_receita" "text",
    "cd_especie_receita" smallint,
    "ds_especie_receita" "text",
    "nr_cpf_cnpj_doador" "text",
    "nm_doador" "text",
    "nm_doador_rfb" "text",
    "cd_cnae_doador" "text",
    "ds_cnae_doador" "text",
    "sg_uf_doador" "text",
    "vr_receita" numeric(18,2) DEFAULT 0 NOT NULL,
    "dt_receita" "date",
    "ds_receita" "text",
    "dados" "jsonb",
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."pncp_resultados" (
    "id_compra_item" "text" NOT NULL,
    "id_compra" "text",
    "numero_controle_pncp_compra" "text",
    "orgao_cnpj" "text",
    "unidade_codigo" "text",
    "uf" "text",
    "numero_item_pncp" integer,
    "sequencial_resultado" integer NOT NULL,
    "ni_fornecedor" "text",
    "tipo_pessoa" "text",
    "nome_fornecedor" "text",
    "quantidade_homologada" numeric(18,4),
    "valor_unitario_homologado" numeric(18,4),
    "valor_total_homologado" numeric(18,2),
    "percentual_desconto" numeric(8,4),
    "situacao_id" integer,
    "situacao_nome" "text",
    "porte_fornecedor_id" integer,
    "porte_fornecedor_nome" "text",
    "natureza_juridica_id" "text",
    "natureza_juridica_nome" "text",
    "data_resultado_pncp" timestamp with time zone,
    "data_inclusao_pncp" timestamp with time zone,
    "data_atualizacao_pncp" timestamp with time zone,
    "aplicacao_margem_preferencia" boolean,
    "aplicacao_beneficio_meepp" boolean,
    "ingerido_em" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."siafi_pagamento" (
    "codigo_pagamento" "text" NOT NULL,
    "codigo_pagamento_resumido" "text",
    "snapshot_date" "date" NOT NULL,
    "data_emissao" "date",
    "cod_tipo_documento" "text",
    "tipo_documento" "text",
    "tipo_ob" "text",
    "extra_orcamentario" "text",
    "cod_orgao_superior" "text",
    "nome_orgao_superior" "text",
    "cod_orgao" "text",
    "nome_orgao" "text",
    "cod_ug" "text",
    "nome_ug" "text",
    "cod_gestao" "text",
    "nome_gestao" "text",
    "cnpj_favorecido" "text",
    "nome_favorecido" "text",
    "observacao" "text",
    "processo" "text",
    "cod_categoria_despesa" "text",
    "categoria_despesa" "text",
    "cod_grupo_despesa" "text",
    "grupo_despesa" "text",
    "cod_modalidade_aplicacao" "text",
    "modalidade_aplicacao" "text",
    "cod_elemento_despesa" "text",
    "elemento_despesa" "text",
    "cod_plano_orcamentario" "text",
    "plano_orcamentario" "text",
    "cod_programa_governo" "text",
    "nome_programa_governo" "text",
    "valor_original_pagamento" numeric(20,2),
    "valor_pagamento_brl" numeric(20,2),
    "valor_utilizado_conversao" numeric(20,8),
    "source_last_modified" timestamp with time zone,
    "ingested_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."tse_despesas" (
    "id" bigint NOT NULL,
    "ano_eleicao" smallint NOT NULL,
    "numero_documento" "text",
    "cpf_candidato" "text",
    "nome_candidato" "text",
    "cargo" "text",
    "sigla_partido" "text",
    "uf" character(2),
    "cpf_cnpj_fornecedor" "text",
    "nome_fornecedor" "text",
    "tipo_despesa" "text",
    "descricao_despesa" "text",
    "origem_despesa" "text",
    "especie_recurso" "text",
    "fonte_recurso" "text",
    "valor_despesa" numeric(16,2) NOT NULL,
    "valor_prestado" numeric(16,2),
    "data_despesa" "date",
    "ingested_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."narrativas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "observatorio_id" "text" NOT NULL,
    "institution_id" "uuid",
    "tipo" "text" NOT NULL,
    "titulo" "text" NOT NULL,
    "resumo" "text",
    "narrativa" "text",
    "nivel_relevancia" integer DEFAULT 5 NOT NULL,
    "categoria" "text",
    "dados_json" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."narrative_events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "tipo_evento" "text",
    "entidade_tipo" "text",
    "entidade_id" "uuid",
    "titulo" "text",
    "narrativa" "text",
    "variacao_indice" numeric,
    "relevancia" numeric DEFAULT 0.5,
    "fonte" "text" DEFAULT 'think_engine'::"text",
    "status" "text" DEFAULT 'detected'::"text",
    "parlamentar" "text",
    "impacto_publico" "text"
);

CREATE TABLE IF NOT EXISTS "public"."ncm" (
    "codigo" "text" NOT NULL,
    "descricao" "text",
    "data_inicio" "date",
    "data_fim" "date",
    "tipo_ato" "text",
    "numero_ato" "text",
    "ano_ato" "text"
);

CREATE TABLE IF NOT EXISTS "public"."newsletter_sends" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "subscriber_id" "uuid",
    "semana_referencia" "date",
    "sent_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "status" "text",
    "error_message" "text"
);

CREATE TABLE IF NOT EXISTS "public"."newsletter_subscribers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "email" "text" NOT NULL,
    "tribunais_preferidos" "text"[] DEFAULT '{}'::"text"[],
    "ativo" boolean DEFAULT true NOT NULL,
    "confirmado" boolean DEFAULT false NOT NULL,
    "token_confirmacao" "text" DEFAULT ("gen_random_uuid"())::"text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "confirmed_at" timestamp with time zone,
    "unsubscribed_at" timestamp with time zone,
    "ip_signup" "inet",
    "user_agent" "text",
    "token_unsubscribe" "text" DEFAULT ("gen_random_uuid"())::"text"
);

CREATE TABLE IF NOT EXISTS "public"."notas_fiscais" (
    "chave" "text" NOT NULL,
    "numero" "text",
    "serie" "text",
    "data_emissao" "date",
    "data_processamento" "date",
    "emitente_cnpj" "text",
    "emitente_razao_social" "text",
    "emitente_uf" character(2),
    "emitente_municipio" "text",
    "destinatario_cnpj" "text",
    "destinatario_cpf" "text",
    "destinatario_razao_social" "text",
    "destinatario_uf" character(2),
    "valor_nota" numeric(18,2),
    "natureza_operacao" "text",
    "situacao" "text",
    "updated_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."notas_fiscais_ingest_log" (
    "id" integer NOT NULL,
    "descricao" "text",
    "status" "text",
    "n_novos" integer DEFAULT 0,
    "erro" "text",
    "started_at" timestamp with time zone DEFAULT "now"(),
    "finished_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS "public"."noticias" (
    "slug" "text" NOT NULL,
    "titulo" "text" NOT NULL,
    "resumo" "text" NOT NULL,
    "tag" "text" NOT NULL,
    "data_pub" "date" NOT NULL,
    "publicado" boolean DEFAULT false NOT NULL,
    "destaque" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "fonte_nome" "text",
    "fonte_url" "text",
    "tipo" "text" DEFAULT 'investigacao'::"text" NOT NULL,
    "conteudo_md" "text",
    CONSTRAINT "noticias_tipo_check" CHECK (("tipo" = ANY (ARRAY['investigacao'::"text", 'curadoria'::"text"])))
);

CREATE TABLE IF NOT EXISTS "public"."observatorios" (
    "id" "text" NOT NULL,
    "nome" "text" NOT NULL,
    "descricao" "text",
    "icone" "text",
    "cor" "text",
    "ativo" boolean DEFAULT false NOT NULL,
    "ordem" integer DEFAULT 0 NOT NULL,
    "fonte_dados" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."orgaos_federais" (
    "id" integer NOT NULL,
    "nome" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."parlamentar_contratos_cache" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "parlamentar_id" "uuid" NOT NULL,
    "contratos" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."political_intelligence_feed" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "parlamentar_uid" "uuid",
    "event_id" "uuid",
    "event_type" "text",
    "signal_type" "text",
    "signal_strength" numeric,
    "headline" "text",
    "summary" "text",
    "created_at" timestamp without time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."parlamentar_financiamento_cache" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "parlamentar_id" "uuid" NOT NULL,
    "receitas" "jsonb",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."parlamentar_identidade" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "parlamentar_id" "uuid" NOT NULL,
    "id_camara" bigint,
    "id_senado" bigint,
    "nome_normalizado" "text",
    "hash_identidade" "text",
    "metodo_match" "text",
    "confianca" numeric,
    "fonte_orcamentaria_id" bigint,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."parlamentar_identity_map" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "parlamentar_uid" "uuid" NOT NULL,
    "autor_orcamentario_id" "uuid" NOT NULL,
    "confidence" numeric DEFAULT 1.0,
    "source" "text",
    "created_at" timestamp without time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."parlamentar_inteligencia" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "parlamentar_id" "uuid",
    "score_influencia" numeric DEFAULT 0,
    "score_produtividade" numeric DEFAULT 0,
    "score_transparencia" numeric DEFAULT 0,
    "indice_global" numeric DEFAULT 0,
    "insights" "jsonb" DEFAULT '[]'::"jsonb",
    "teses" "jsonb" DEFAULT '[]'::"jsonb",
    "alertas" "jsonb" DEFAULT '[]'::"jsonb",
    "resumo" "text",
    "atualizado_em" timestamp with time zone DEFAULT "now"(),
    "created_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."parlamentar_sancoes_cache" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "parlamentar_id" "uuid" NOT NULL,
    "sancoes" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."patrimonio_tse" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "parlamentar_id" "uuid",
    "cpf" "text",
    "ano_eleicao" integer NOT NULL,
    "nr_ordem" "text",
    "ds_bem" "text",
    "vr_bem" numeric DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "ds_tipo_bem" "text"
);

CREATE TABLE IF NOT EXISTS "public"."pbh_despesas_orcamentarias" (
    "id" "text" NOT NULL,
    "fonte" "text" NOT NULL,
    "ano_exercicio" integer,
    "dt_movimento" "date",
    "unidade_orcamentaria" "text",
    "numero_empenho" "text",
    "funcao" "text",
    "subfuncao" "text",
    "programa" "text",
    "acao" "text",
    "elemento_despesa" "text",
    "natureza_despesa" "text",
    "nome_credor" "text",
    "cnpj_cpf_credor" "text",
    "modalidade_licitacao" "text",
    "numero_licitacao" "text",
    "numero_emenda" "text",
    "exercicio_emenda" integer,
    "vl_empenhado" numeric(18,2) DEFAULT 0,
    "vl_liquidado" numeric(18,2) DEFAULT 0,
    "vl_pago" numeric(18,2) DEFAULT 0,
    "vl_liquidado_resto" numeric(18,2) DEFAULT 0,
    "vl_pago_resto" numeric(18,2) DEFAULT 0,
    "updated_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."peps" (
    "id" integer NOT NULL,
    "cpf" "text",
    "nome" "text",
    "sigla_funcao" "text",
    "descricao_funcao" "text",
    "nivel_funcao" "text",
    "orgao_codigo" "text",
    "orgao_nome" "text",
    "data_inicio_exercicio" "date",
    "data_fim_exercicio" "date",
    "data_fim_carencia" "date",
    "updated_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."peps_ingest_log" (
    "id" integer NOT NULL,
    "dataset" "text",
    "status" "text",
    "n_novos" integer DEFAULT 0,
    "erro" "text",
    "started_at" timestamp with time zone DEFAULT "now"(),
    "finished_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS "public"."pgfn_divida_ativa" (
    "id" bigint NOT NULL,
    "cpf_cnpj" "text" NOT NULL,
    "tipo_pessoa" "text",
    "tipo_devedor" "text",
    "nome_devedor" "text",
    "uf_devedor" "text",
    "unidade_responsavel" "text",
    "numero_inscricao" "text",
    "tipo_situacao" "text",
    "situacao" "text",
    "tipo_credito" "text",
    "data_inscricao" "date",
    "indicador_ajuizado" "text",
    "valor_consolidado" numeric(18,2),
    "arquivo" "text",
    "ciclo" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);

ALTER TABLE "public"."pgfn_divida_ativa" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."pgfn_divida_ativa_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."pgfn_divida_federacoes" (
    "id" bigint NOT NULL,
    "cnpj" "text" NOT NULL,
    "nome" "text" NOT NULL,
    "uf" "text" NOT NULL,
    "tipo_arquivo" "text" NOT NULL,
    "trimestre" "text" NOT NULL,
    "total_divida" numeric(18,2) DEFAULT 0 NOT NULL,
    "total_inscricoes" integer DEFAULT 0 NOT NULL,
    "total_ajuizadas" integer DEFAULT 0 NOT NULL,
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."pix_participantes" (
    "ispb" "text" NOT NULL,
    "nome" "text",
    "nome_reduzido" "text",
    "modalidade_participacao" "text",
    "tipo_participacao" "text",
    "inicio_operacao" "date"
);

CREATE TABLE IF NOT EXISTS "public"."plen_deputado_agg" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "deputado_id" integer NOT NULL,
    "id_legislatura" integer DEFAULT 57 NOT NULL,
    "nome" "text",
    "sigla_partido" "text",
    "sigla_uf" "text",
    "url_foto" "text",
    "total_votacoes" integer DEFAULT 0 NOT NULL,
    "presencas" integer DEFAULT 0 NOT NULL,
    "ausencias" integer DEFAULT 0 NOT NULL,
    "votos_sim" integer DEFAULT 0 NOT NULL,
    "votos_nao" integer DEFAULT 0 NOT NULL,
    "votos_abstencao" integer DEFAULT 0 NOT NULL,
    "votos_obstrucao" integer DEFAULT 0 NOT NULL,
    "votos_artigo17" integer DEFAULT 0 NOT NULL,
    "pct_presenca" numeric(6,2),
    "concordancia_partido" numeric(6,2),
    "posicao" integer,
    "posicao_partido" integer,
    "por_tipo_voto" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."plen_orientacoes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "votacao_id" "text" NOT NULL,
    "sigla_bancada" "text" NOT NULL,
    "nome_bancada" "text",
    "orientacao" "text" NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."plen_votacoes" (
    "id" "text" NOT NULL,
    "uri" "text",
    "data" "date" NOT NULL,
    "data_hora_registro" timestamp with time zone,
    "sigla_orgao" "text" DEFAULT 'PLEN'::"text",
    "uri_evento" "text",
    "proposicao_autora" "text",
    "uri_proposicao" "text",
    "descricao" "text",
    "aprovacao" integer,
    "votos_sim" integer DEFAULT 0,
    "votos_nao" integer DEFAULT 0,
    "votos_abstencao" integer DEFAULT 0,
    "votos_obstrucao" integer DEFAULT 0,
    "votos_artigo17" integer DEFAULT 0,
    "id_legislatura" integer DEFAULT 57 NOT NULL,
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."plen_votos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "votacao_id" "text" NOT NULL,
    "deputado_id" integer NOT NULL,
    "nome" "text",
    "sigla_partido" "text",
    "sigla_uf" "text",
    "id_legislatura" integer,
    "url_foto" "text",
    "data_registro_voto" timestamp with time zone,
    "tipo_voto" "text" NOT NULL,
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."pncp_licitacoes" (
    "numero_controle_pncp" "text" NOT NULL,
    "orgao_cnpj" "text",
    "orgao_nome" "text",
    "poder_id" "text",
    "esfera_id" "text",
    "ano_compra" integer,
    "sequencial_compra" integer,
    "numero_compra" "text",
    "processo" "text",
    "modalidade_id" integer,
    "modalidade_nome" "text",
    "modo_disputa_id" integer,
    "modo_disputa_nome" "text",
    "objeto_compra" "text",
    "valor_estimado" numeric(18,2),
    "valor_homologado" numeric(18,2),
    "data_publicacao_pncp" timestamp with time zone,
    "data_abertura_proposta" timestamp with time zone,
    "data_encerramento_proposta" timestamp with time zone,
    "data_inclusao" timestamp with time zone,
    "data_atualizacao" timestamp with time zone,
    "situacao_id" integer,
    "situacao_nome" "text",
    "uf" "text",
    "municipio_nome" "text",
    "municipio_ibge" "text",
    "unidade_codigo" "text",
    "unidade_nome" "text",
    "emenda_parlamentar" boolean,
    "srp" boolean,
    "existe_resultado" boolean,
    "link_sistema_origem" "text",
    "dados" "jsonb" DEFAULT '{}'::"jsonb",
    "ingerido_em" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."pncp_publicidade" (
    "numero_controle_pncp" "text" NOT NULL,
    "ano_contrato" smallint,
    "data_assinatura" "date",
    "data_publicacao_pncp" timestamp with time zone,
    "data_vigencia_inicio" "date",
    "data_vigencia_fim" "date",
    "valor_inicial" numeric(18,2),
    "valor_global" numeric(18,2),
    "objeto_contrato" "text",
    "numero_contrato" "text",
    "modalidade" "text",
    "cnpj_fornecedor" "text",
    "nome_fornecedor" "text",
    "cnpj_orgao" "text",
    "nome_orgao" "text",
    "esfera_orgao" "text",
    "poder_orgao" "text",
    "uf_orgao" "text",
    "municipio_orgao" "text",
    "nome_unidade" "text",
    "url_pncp" "text",
    "coletado_em" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "pncp_pub_valor_positivo" CHECK (("valor_global" >= (0)::numeric))
);

CREATE TABLE IF NOT EXISTS "public"."pr_ex_presidentes_custos" (
    "id" "text" NOT NULL,
    "ano_emissao" integer NOT NULL,
    "mes_emissao" "text",
    "mes_referencia" "text",
    "grupo_despesa_codigo" "text",
    "grupo_despesa_nome" "text",
    "natureza_despesa_codigo" "text",
    "natureza_despesa_nome" "text",
    "natureza_despesa_det_codigo" "text",
    "natureza_despesa_det_nome" "text",
    "centro_custo_codigo" "text",
    "centro_custo_nome" "text",
    "ex_presidente_slug" "text",
    "custo_valor" numeric(14,2) NOT NULL,
    "arquivo_origem" "text",
    "ingested_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."pr_ingest_log" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "dataset" "text" NOT NULL,
    "status" "text" DEFAULT 'running'::"text" NOT NULL,
    "arquivo" "text",
    "n_linhas" integer,
    "erro" "text",
    "started_at" timestamp with time zone DEFAULT "now"(),
    "finished_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS "public"."pr_pessoal_diversidade" (
    "id" "text" NOT NULL,
    "orgao" "text" NOT NULL,
    "periodo" "text" NOT NULL,
    "categoria_vinculo" "text",
    "dimensao" "text" NOT NULL,
    "valor_dimensao" "text" NOT NULL,
    "quantidade" integer NOT NULL,
    "percentual" numeric(5,2),
    "arquivo_origem" "text",
    "ingested_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."presencas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "parlamentar_uid" "uuid",
    "data_sessao" "date",
    "presenca" boolean,
    "created_at" timestamp without time zone DEFAULT "now"(),
    "parlamentar_id" "uuid"
);

CREATE TABLE IF NOT EXISTS "public"."public_reports" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" "text",
    "summary" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."ranking_cache" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "parlamentar_uid" "uuid",
    "nome" "text",
    "partido" "text",
    "uf" "text",
    "posicao" integer,
    "score" numeric,
    "execucao_orcamentaria" numeric,
    "influencia" numeric,
    "transparencia" numeric,
    "created_at" timestamp without time zone DEFAULT "now"(),
    "parlamentar_id" "uuid",
    "nome_parlamentar" "text",
    "foto_url" "text",
    "total_emendas" integer DEFAULT 0,
    "valor_total_emendas" numeric DEFAULT 0,
    "valor_pago_emendas" numeric DEFAULT 0,
    "taxa_execucao_emendas" numeric DEFAULT 0,
    "total_despesas_gabinete" numeric DEFAULT 0,
    "total_beneficios" numeric DEFAULT 0,
    "quantidade_assessores" integer DEFAULT 0,
    "custo_total_parlamentar" numeric DEFAULT 0,
    "total_proposicoes" integer DEFAULT 0,
    "total_votacoes" integer DEFAULT 0,
    "total_presencas" integer DEFAULT 0,
    "taxa_presenca" numeric DEFAULT 0,
    "total_transferencias" numeric DEFAULT 0,
    "valor_transferencias" numeric DEFAULT 0,
    "score_orcamento" numeric DEFAULT 0,
    "score_custo" numeric DEFAULT 0,
    "score_produtividade" numeric DEFAULT 0,
    "score_influencia" numeric DEFAULT 0,
    "indice_poder_parlamentar" numeric DEFAULT 0,
    "posicao_nacional" integer DEFAULT 0,
    "posicao_uf" integer DEFAULT 0,
    "posicao_partido" integer DEFAULT 0,
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "legislatura" integer,
    "mandato_id" "uuid"
);

CREATE TABLE IF NOT EXISTS "public"."ranking_parlamentar" (
    "parlamentar_id" "uuid" NOT NULL,
    "ano" integer NOT NULL,
    "posicao" integer NOT NULL,
    "valor_total" numeric(18,2) NOT NULL,
    "metricas" "jsonb",
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."ranking_parlamentar_build" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "build_id" "uuid" NOT NULL,
    "parlamentar_id" "uuid" NOT NULL,
    "ano" integer NOT NULL,
    "posicao" integer NOT NULL,
    "valor_total" numeric(18,2) NOT NULL,
    "metricas" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."ranking_snapshot" (
    "captured_at" timestamp with time zone DEFAULT "now"(),
    "parlamentar_id" "uuid",
    "posicao" integer,
    "indice" numeric,
    "snapshot_id" "text",
    "calculation_date" timestamp with time zone DEFAULT "now"(),
    "methodology_version" "text" DEFAULT '1.0'::"text",
    "id" "uuid" DEFAULT "gen_random_uuid"(),
    "posicao_nacional" integer,
    "indice_poder_parlamentar" numeric,
    "nome" "text",
    "nome_parlamentar" "text",
    "partido" "text",
    "uf" "text",
    "posicao_uf" integer,
    "posicao_partido" integer,
    "foto_url" "text",
    "legislatura" integer,
    "mandato_id" "uuid",
    "total_emendas" integer,
    "valor_total_emendas" numeric,
    "valor_pago_emendas" numeric,
    "taxa_execucao_emendas" numeric,
    "total_despesas_gabinete" numeric,
    "total_beneficios" numeric,
    "quantidade_assessores" integer,
    "custo_total_parlamentar" numeric,
    "total_proposicoes" integer,
    "total_votacoes" integer,
    "total_presencas" integer,
    "taxa_presenca" numeric,
    "total_transferencias" numeric,
    "valor_transferencias" numeric,
    "score_orcamento" numeric,
    "score_custo" numeric,
    "score_produtividade" numeric,
    "score_influencia" numeric
);

CREATE TABLE IF NOT EXISTS "public"."rs_despesas" (
    "id" "text" NOT NULL,
    "ano_exercicio" integer NOT NULL,
    "mes" integer,
    "fase_gasto" "text",
    "tipo_gasto" "text",
    "numero_empenho" "text",
    "numero_processo" "text",
    "numero_contrato" "text",
    "cod_credor" "text",
    "favorecido" "text",
    "cnpj" "text",
    "orgao" "text",
    "uo" "text",
    "elemento" "text",
    "modalidade" "text",
    "procedimento_licitatorio" "text",
    "tipo_procedimento" "text",
    "municipio" "text",
    "cod_municipio" "text",
    "data_gasto" "date",
    "valor" numeric(18,2),
    "funcao" "text",
    "subfuncao" "text",
    "programa" "text",
    "acao" "text",
    "updated_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."rs_ingest_log" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "dataset" "text" NOT NULL,
    "status" "text" DEFAULT 'running'::"text" NOT NULL,
    "n_gravados" integer,
    "erro" "text",
    "started_at" timestamp with time zone DEFAULT "now"(),
    "finished_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS "public"."sancoes_ingest_log" (
    "id" bigint NOT NULL,
    "dataset" "text" NOT NULL,
    "started_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "finished_at" timestamp with time zone,
    "status" "text" DEFAULT 'running'::"text" NOT NULL,
    "n_novos" integer,
    "erro" "text"
);

CREATE TABLE IF NOT EXISTS "public"."scores" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "institution_id" "uuid" NOT NULL,
    "observatorio_id" "text" NOT NULL,
    "dimensao" "text" NOT NULL,
    "score" numeric DEFAULT 0 NOT NULL,
    "indice_geral" numeric DEFAULT 0 NOT NULL,
    "posicao_nacional" integer,
    "posicao_uf" integer,
    "posicao_tipo" integer,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."sebrae_contratos" (
    "id" bigint NOT NULL,
    "uf" character(2) NOT NULL,
    "ano" smallint,
    "numero_contrato" "text" NOT NULL,
    "data_contrato" "text",
    "modalidade" "text",
    "cnpj_cpf" "text",
    "razao_social" "text",
    "vigencia" "text",
    "objeto" "text",
    "aditivo" "text",
    "valor_contrato" "text",
    "valor_pago" "text",
    "data_ingestao" "date" DEFAULT CURRENT_DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."sebrae_convenios" (
    "id" bigint NOT NULL,
    "uf" character(2) NOT NULL,
    "ano" smallint,
    "numero_convenio" "text" NOT NULL,
    "data_convenio" "text",
    "cnpj_cpf" "text",
    "razao_social" "text",
    "vigencia" "text",
    "objeto" "text",
    "aditivo" "text",
    "participacao_sebrae" "text",
    "valor_repasse" "text",
    "valor_contrapartida" "text",
    "data_ingestao" "date" DEFAULT CURRENT_DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."sebrae_emendas_contratos" (
    "id" bigint NOT NULL,
    "uf" character(2) NOT NULL,
    "ano" smallint,
    "numero_contrato" "text" NOT NULL,
    "data_contrato" "text",
    "modalidade" "text",
    "cnpj_cpf" "text",
    "razao_social" "text",
    "vigencia" "text",
    "objeto" "text",
    "aditivo" "text",
    "observacao" "text",
    "valor_contrato" "text",
    "data_ingestao" "date" DEFAULT CURRENT_DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."sebrae_emendas_convenios" (
    "id" bigint NOT NULL,
    "uf" character(2) NOT NULL,
    "ano" smallint,
    "numero_convenio" "text" NOT NULL,
    "data_convenio" "text",
    "cnpj_cpf" "text",
    "razao_social" "text",
    "vigencia" "text",
    "objeto" "text",
    "aditivo" "text",
    "observacao" "text",
    "valor_emenda" "text",
    "data_ingestao" "date" DEFAULT CURRENT_DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."sebrae_licitacoes" (
    "id" bigint NOT NULL,
    "uf" character(2) NOT NULL,
    "numero_licitacao" "text" NOT NULL,
    "tipo_julgamento" "text",
    "menor_preco" "text",
    "situacao" "text",
    "modalidade" "text",
    "julgamento" "text",
    "objeto" "text",
    "data_abertura" "text",
    "data_homologacao" "text",
    "resultado" "text",
    "cnpj_fornecedor" "text",
    "nome_fornecedor" "text",
    "data_ingestao" "date" DEFAULT CURRENT_DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."sebrae_patrocinios" (
    "id" bigint NOT NULL,
    "uf" character(2) NOT NULL,
    "ano" smallint,
    "numero_contrato" "text" NOT NULL,
    "data_contrato" "text",
    "cnpj_cpf" "text",
    "razao_social" "text",
    "vigencia" "text",
    "objeto" "text",
    "aditivo" "text",
    "valor_contrato" "text",
    "valor_pago" "text",
    "data_ingestao" "date" DEFAULT CURRENT_DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."sen_parlamentar_risco" (
    "senador_codigo" "text" NOT NULL,
    "nome" "text",
    "partido" "text",
    "uf" "text",
    "dim_ceap" numeric,
    "dim_presenca" numeric,
    "dim_producao" numeric,
    "dim_financiamento" numeric,
    "dim_rp9" numeric,
    "score_total" numeric,
    "ceap_total" numeric,
    "presenca_pct" numeric,
    "total_proposicoes" integer,
    "financiamento_total" numeric,
    "rp9_vinculos" integer,
    "updated_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."sen_proposicoes" (
    "id" bigint NOT NULL,
    "senador_codigo" "text" NOT NULL,
    "sigla_materia" "text",
    "numero" "text",
    "ano" "text",
    "ementa" "text",
    "data_apresentacao" "date",
    "tipo_autoria" "text"
);

CREATE TABLE IF NOT EXISTS "public"."senac_contratos" (
    "id" bigint NOT NULL,
    "regional" "text" NOT NULL,
    "numero" "text" NOT NULL,
    "numero_origem" "text",
    "tipo" smallint,
    "situacao" "text",
    "objeto" "text",
    "favorecido" "text",
    "cnpj_cpf" "text",
    "tipo_pessoa" smallint,
    "elemento_despesa" "text",
    "modalidade_origem" "text",
    "natureza" smallint,
    "valor_total" numeric(18,2),
    "valor_pago" numeric(18,2),
    "data_contratacao" "date",
    "data_fim" "date",
    "ano_mes_referencia" "text",
    "data_ultima_carga" timestamp with time zone,
    "data_ingestao" "date" DEFAULT CURRENT_DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."senac_licitacoes" (
    "id" bigint NOT NULL,
    "regional" "text" NOT NULL,
    "modalidade_id" "text",
    "modalidade" "text",
    "licitacao_id" "text" NOT NULL,
    "situacao" "text",
    "numero_processo" "text",
    "objeto" "text",
    "data_abertura" timestamp with time zone,
    "data_situacao" timestamp with time zone,
    "data_ultima_carga" timestamp with time zone,
    "data_ingestao" "date" DEFAULT CURRENT_DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."senado_ceaps_despesa" (
    "id" bigint NOT NULL,
    "tipo_documento" "text",
    "ano" smallint NOT NULL,
    "mes" smallint NOT NULL,
    "cod_senador" integer NOT NULL,
    "nome_senador" "text" NOT NULL,
    "tipo_despesa" "text" NOT NULL,
    "cpf_cnpj" "text",
    "nome_fornecedor" "text",
    "documento" "text",
    "data" "date",
    "detalhamento" "text",
    "valor_reembolsado" numeric(14,2) DEFAULT 0 NOT NULL,
    "ano_csv" smallint NOT NULL,
    "ingested_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."senado_orientacao" (
    "id_sve" integer NOT NULL,
    "sigla_partido" "text" NOT NULL,
    "orientacao" "text" NOT NULL,
    "ingested_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."senado_votacao" (
    "id_sve" integer NOT NULL,
    "cod_sessao" integer,
    "cod_sessao_votacao" integer,
    "data_sessao" "date",
    "hora_inicio" "text",
    "tipo_sessao" "text",
    "numero_sessao" "text",
    "descricao" "text",
    "resultado" "text",
    "cod_materia" integer,
    "sigla_materia" "text",
    "numero_materia" "text",
    "ano_materia" smallint,
    "secreta" boolean DEFAULT false NOT NULL,
    "votos_sim" smallint,
    "votos_nao" smallint,
    "votos_abstencao" smallint,
    "ingested_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."senado_voto" (
    "id_sve" integer NOT NULL,
    "cod_parlamentar" integer NOT NULL,
    "nome_parlamentar" "text",
    "sigla_partido" "text",
    "sigla_uf" "text",
    "voto" "text" NOT NULL,
    "ingested_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."senadores_brutas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "id_externo" "text" NOT NULL,
    "nome" "text" NOT NULL,
    "sigla_partido" "text",
    "sigla_uf" "text",
    "url_foto" "text",
    "email" "text",
    "dados" "jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."senar_contratos" (
    "id" bigint NOT NULL,
    "periodo_id" "text" NOT NULL,
    "numero_contrato" "text" NOT NULL,
    "modalidade_licitacao" "text",
    "natureza_objeto" "text",
    "descricao_objeto" "text",
    "categoria_objeto" "text",
    "criterio_julgamento" "text",
    "nome_contratada" "text",
    "cnpj" "text",
    "cpf" "text",
    "data_contrato" "text",
    "valor_contrato" "text",
    "valor_pago" "text",
    "vigencia_meses" "text",
    "valor_aditivo_preco" "text",
    "valor_aditivo_prazo" "text",
    "obs" "text",
    "data_ingestao" "date" DEFAULT CURRENT_DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."senar_licitacoes" (
    "id" bigint NOT NULL,
    "ano" smallint NOT NULL,
    "modalidade" "text",
    "numero_ano" "text" NOT NULL,
    "processo" "text",
    "descricao_objeto" "text",
    "natureza_objeto" "text",
    "data_abertura" "text",
    "criterio_julgamento" "text",
    "data_homologacao" "text",
    "resultado_certame" "text",
    "licitantes_propostas" "text",
    "situacao" "text",
    "data_ingestao" "date" DEFAULT CURRENT_DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."senar_transferencias" (
    "id" bigint NOT NULL,
    "periodo_id" "text" NOT NULL,
    "tipo" "text",
    "instrumento" "text",
    "tipo_transferencia" "text",
    "nome_beneficiario" "text",
    "cnpj" "text",
    "descricao_objeto" "text",
    "data_firmamento" "text",
    "qtde_parcelas_total" "text",
    "qtde_parcelas_trans" "text",
    "valor_pactuado" "text",
    "valor_transferido" "text",
    "prestacao_contas" "text",
    "data_ingestao" "date" DEFAULT CURRENT_DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."sesc_contratos" (
    "id" bigint NOT NULL,
    "portal" "text" NOT NULL,
    "dataset_id" smallint NOT NULL,
    "unidade" "text",
    "exercicio" smallint,
    "numero_contrato" "text" NOT NULL,
    "objeto" "text",
    "favorecido" "text",
    "cnpj_cpf" "text",
    "modalidade_licitacao" "text",
    "data_contratacao" "text",
    "elemento_despesa" "text",
    "valor_contrato" "text",
    "valor_pago" "text",
    "data_ingestao" "date" DEFAULT CURRENT_DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."sesc_convenios" (
    "id" bigint NOT NULL,
    "portal" "text" NOT NULL,
    "dataset_id" smallint NOT NULL,
    "unidade" "text",
    "exercicio" "text",
    "numero_convenio" "text" NOT NULL,
    "objeto" "text",
    "favorecido" "text",
    "cnpj_cpf" "text",
    "valor_contrapartida" "text",
    "data_firmatura" "text",
    "valor_total" "text",
    "valor_pago_exercicio" "text",
    "data_ingestao" "date" DEFAULT CURRENT_DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."siafi_empenho" (
    "id_empenho" "text" NOT NULL,
    "codigo_empenho" "text" NOT NULL,
    "codigo_empenho_resumido" "text",
    "snapshot_date" "date" NOT NULL,
    "data_emissao" "date",
    "cod_tipo_documento" "text",
    "tipo_documento" "text",
    "tipo_empenho" "text",
    "especie_empenho" "text",
    "cod_orgao_superior" "text",
    "nome_orgao_superior" "text",
    "cod_orgao" "text",
    "nome_orgao" "text",
    "cod_ug" "text",
    "nome_ug" "text",
    "cod_gestao" "text",
    "nome_gestao" "text",
    "cnpj_favorecido" "text",
    "nome_favorecido" "text",
    "observacao" "text",
    "cod_esfera_orcamentaria" "text",
    "esfera_orcamentaria" "text",
    "cod_tipo_credito" "text",
    "tipo_credito" "text",
    "cod_grupo_fonte_recurso" "text",
    "nome_grupo_fonte_recurso" "text",
    "cod_fonte_recurso" "text",
    "nome_fonte_recurso" "text",
    "cod_unidade_orcamentaria" "text",
    "nome_unidade_orcamentaria" "text",
    "cod_funcao" "text",
    "nome_funcao" "text",
    "cod_subfuncao" "text",
    "nome_subfuncao" "text",
    "cod_programa" "text",
    "nome_programa" "text",
    "cod_acao" "text",
    "nome_acao" "text",
    "linguagem_cidada" "text",
    "cod_subtitulo" "text",
    "nome_subtitulo" "text",
    "cod_plano_orcamentario" "text",
    "plano_orcamentario" "text",
    "cod_programa_governo" "text",
    "nome_programa_governo" "text",
    "autor_emenda" "text",
    "cod_categoria_despesa" "text",
    "categoria_despesa" "text",
    "cod_grupo_despesa" "text",
    "grupo_despesa" "text",
    "cod_modalidade_aplicacao" "text",
    "modalidade_aplicacao" "text",
    "cod_elemento_despesa" "text",
    "elemento_despesa" "text",
    "processo" "text",
    "modalidade_licitacao" "text",
    "inciso" "text",
    "amparo" "text",
    "ref_dispensa_inexigibilidade" "text",
    "cod_convenio" "text",
    "contrato_repasse" "text",
    "valor_original_empenho" numeric(20,2),
    "valor_empenho_brl" numeric(20,2),
    "valor_utilizado_conversao" numeric(20,8),
    "source_last_modified" timestamp with time zone,
    "ingested_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."siafi_execucao_mensal" (
    "competencia" "text" NOT NULL,
    "cod_ug" "text" NOT NULL,
    "cod_programa_orcamentario" "text" NOT NULL,
    "cod_acao" "text" NOT NULL,
    "cod_plano_orcamentario" "text" NOT NULL,
    "cod_elemento_despesa" "text" NOT NULL,
    "cod_modalidade_despesa" "text" NOT NULL,
    "cod_autor_emenda" "text" NOT NULL,
    "cod_subtitulo" "text" NOT NULL,
    "nome_orgao_superior" "text",
    "cod_orgao_superior" "text",
    "nome_orgao_subordinado" "text",
    "cod_orgao_subordinado" "text",
    "nome_ug" "text",
    "cod_gestao" "text",
    "nome_gestao" "text",
    "cod_unidade_orcamentaria" "text",
    "nome_unidade_orcamentaria" "text",
    "cod_funcao" "text",
    "nome_funcao" "text",
    "cod_subfuncao" "text",
    "nome_subfuncao" "text",
    "nome_programa_orcamentario" "text",
    "nome_acao" "text",
    "plano_orcamentario" "text",
    "cod_programa_governo" "text",
    "nome_programa_governo" "text",
    "uf" "text",
    "municipio" "text",
    "nome_subtitulo" "text",
    "cod_localizador" "text",
    "nome_localizador" "text",
    "sigla_localizador" "text",
    "descricao_complementar_localizador" "text",
    "nome_autor_emenda" "text",
    "cod_categoria_economica" "text",
    "nome_categoria_economica" "text",
    "cod_grupo_despesa" "text",
    "nome_grupo_despesa" "text",
    "nome_elemento_despesa" "text",
    "modalidade_despesa" "text",
    "valor_empenhado" numeric(20,2) DEFAULT 0 NOT NULL,
    "valor_liquidado" numeric(20,2) DEFAULT 0 NOT NULL,
    "valor_pago" numeric(20,2) DEFAULT 0 NOT NULL,
    "valor_restos_pagar_inscritos" numeric(20,2) DEFAULT 0 NOT NULL,
    "valor_restos_pagar_cancelado" numeric(20,2) DEFAULT 0 NOT NULL,
    "valor_restos_pagar_pagos" numeric(20,2) DEFAULT 0 NOT NULL,
    "source_last_modified" timestamp with time zone,
    "ingested_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."siafi_fornecedor" (
    "cnpj_cpf" "text" NOT NULL,
    "nome" "text" NOT NULL,
    "tipo_pessoa" "text" NOT NULL,
    "n_empenhos" integer DEFAULT 0 NOT NULL,
    "n_pagamentos" integer DEFAULT 0 NOT NULL,
    "valor_total_empenhado_brl" numeric(20,2) DEFAULT 0 NOT NULL,
    "valor_total_pago_brl" numeric(20,2) DEFAULT 0 NOT NULL,
    "primeira_aparicao" "date",
    "ultima_aparicao" "date",
    "enriquecimento" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "siafi_fornecedor_tipo_pessoa_check" CHECK (("tipo_pessoa" = ANY (ARRAY['PJ'::"text", 'PF'::"text", 'EXTERIOR'::"text", 'ESPECIAL'::"text"])))
);

CREATE TABLE IF NOT EXISTS "public"."siafi_ingestao_log" (
    "id" bigint NOT NULL,
    "stream" "text" NOT NULL,
    "competencia" "text",
    "source_url" "text" NOT NULL,
    "source_last_modified" timestamp with time zone,
    "rows_bronze" integer,
    "rows_silver" integer,
    "status" "text" NOT NULL,
    "error" "text",
    "duration_seconds" numeric(10,2),
    "ingested_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "siafi_ingestao_log_status_check" CHECK (("status" = ANY (ARRAY['ok'::"text", 'failed'::"text", 'skipped'::"text"]))),
    CONSTRAINT "siafi_ingestao_log_stream_check" CHECK (("stream" = ANY (ARRAY['execucao_mensal'::"text", 'snapshot_diario'::"text"])))
);

CREATE TABLE IF NOT EXISTS "public"."siafi_item_empenho" (
    "id_empenho" "text" NOT NULL,
    "sequencial" "text" NOT NULL,
    "codigo_empenho" "text",
    "cod_categoria_despesa" "text",
    "categoria_despesa" "text",
    "cod_grupo_despesa" "text",
    "grupo_despesa" "text",
    "cod_modalidade_aplicacao" "text",
    "modalidade_aplicacao" "text",
    "cod_elemento_despesa" "text",
    "elemento_despesa" "text",
    "cod_subelemento_despesa" "text",
    "subelemento_despesa" "text",
    "descricao" "text",
    "quantidade" numeric(20,4),
    "valor_unitario" numeric(20,4),
    "valor_total" numeric(20,2),
    "valor_atual" numeric(20,2),
    "snapshot_date" "date" NOT NULL,
    "source_last_modified" timestamp with time zone,
    "ingested_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."siafi_liquidacao" (
    "codigo_liquidacao" "text" NOT NULL,
    "codigo_liquidacao_resumido" "text",
    "snapshot_date" "date" NOT NULL,
    "data_emissao" "date",
    "cod_tipo_documento" "text",
    "tipo_documento" "text",
    "cod_orgao_superior" "text",
    "nome_orgao_superior" "text",
    "cod_orgao" "text",
    "nome_orgao" "text",
    "cod_ug" "text",
    "nome_ug" "text",
    "cod_gestao" "text",
    "nome_gestao" "text",
    "cnpj_favorecido" "text",
    "nome_favorecido" "text",
    "observacao" "text",
    "cod_categoria_despesa" "text",
    "categoria_despesa" "text",
    "cod_grupo_despesa" "text",
    "grupo_despesa" "text",
    "cod_modalidade_aplicacao" "text",
    "modalidade_aplicacao" "text",
    "cod_elemento_despesa" "text",
    "elemento_despesa" "text",
    "cod_plano_orcamentario" "text",
    "plano_orcamentario" "text",
    "cod_programa_governo" "text",
    "nome_programa_governo" "text",
    "source_last_modified" timestamp with time zone,
    "ingested_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."siafi_pagamento_empenho" (
    "codigo_pagamento" "text" NOT NULL,
    "codigo_empenho" "text" NOT NULL,
    "subitem" "text" NOT NULL,
    "cod_natureza_despesa" "text",
    "valor_pago" numeric(20,2),
    "valor_restos_pagar_inscritos" numeric(20,2),
    "valor_restos_pagar_cancelado" numeric(20,2),
    "valor_restos_pagar_pagos" numeric(20,2),
    "snapshot_date" "date" NOT NULL,
    "source_last_modified" timestamp with time zone,
    "ingested_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."siafi_pagamento_favorecido_final" (
    "codigo_pagamento" "text" NOT NULL,
    "codigo_lista" "text" NOT NULL,
    "cnpj_favorecido_final" "text" NOT NULL,
    "nome_favorecido_final" "text",
    "data_emissao" "date",
    "valor_pagamento_brl" numeric(20,2),
    "snapshot_date" "date" NOT NULL,
    "source_last_modified" timestamp with time zone,
    "ingested_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."sisi_contratos" (
    "id" bigint NOT NULL,
    "entidade" "text" NOT NULL,
    "departamento" "text" NOT NULL,
    "codigo_contrato" bigint NOT NULL,
    "ano" smallint,
    "contrato" "text",
    "processo" "text",
    "contratantes" "text",
    "data_contrato" "text",
    "vigencia_meses" integer,
    "data_final" "text",
    "status_contrato" "text",
    "modalidade" "text",
    "objeto" "text",
    "categoria" "text",
    "cpf_cnpj" "text",
    "nome_razao_social" "text",
    "valor_contrato" "text",
    "valor_previsto" "text",
    "valor_executado" "text",
    "houve_aditivo_preco" "text",
    "valor_aditivo" "text",
    "houve_aditivo_prazo" "text",
    "observacoes" "text",
    "data_publicacao" "text",
    "data_ingestao" "date" DEFAULT CURRENT_DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."sisi_convenios" (
    "id" bigint NOT NULL,
    "entidade" "text" NOT NULL,
    "departamento" "text" NOT NULL,
    "codigo_convenio" bigint NOT NULL,
    "ano" smallint,
    "numero_convenio" "text",
    "data_convenio" "text",
    "vigencia" "text",
    "data_final" "text",
    "descricao_objeto" "text",
    "razao_social_convenente" "text",
    "cnpj" "text",
    "valor_participacao_concedente" "text",
    "valor_transferido" "text",
    "status_convenio" "text",
    "valor_contrapartida" "text",
    "houve_aditivo_valor" "text",
    "valor_aditivos" "text",
    "houve_aditivo_prazo" "text",
    "data_publicacao" "text",
    "data_ingestao" "date" DEFAULT CURRENT_DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."sisi_licitacoes" (
    "id" bigint NOT NULL,
    "entidade" "text" NOT NULL,
    "departamento" "text" NOT NULL,
    "codigo_licitacao" bigint NOT NULL,
    "ano" smallint,
    "numero" "text",
    "titulo" "text",
    "data_abertura" "text",
    "modalidade" "text",
    "objeto" "text",
    "status_licitacao" "text",
    "crit_julgamento" "text",
    "dt_homologacao" "text",
    "nm_empresa_vencedora" "text",
    "data_publicacao" "text",
    "data_ingestao" "date" DEFAULT CURRENT_DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."sisi_licitacoes_participantes" (
    "id" bigint NOT NULL,
    "licitacao_codigo" bigint NOT NULL,
    "entidade" "text" NOT NULL,
    "departamento" "text" NOT NULL,
    "participante" "text",
    "cnpj_cpf" "text",
    "valor_proposta" numeric,
    "data_ingestao" "date" DEFAULT CURRENT_DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."snapshots_ranking" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "build_em" timestamp with time zone NOT NULL,
    "ano" integer NOT NULL,
    "dados" "jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."sp_contratos" (
    "id" integer NOT NULL,
    "numero_contrato" "text" NOT NULL,
    "orgao" "text",
    "unidade" "text",
    "cnpj_contratado" "text",
    "nome_contratado" "text",
    "objeto" "text",
    "valor_global" numeric(18,2),
    "data_inicio" "date",
    "data_termino" "date",
    "tipo" "text",
    "link_contratos_gov" "text",
    "fonte" "text" DEFAULT 'portal_transparencia_sp'::"text",
    "atualizado_em" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."sp_despesas" (
    "id" bigint NOT NULL,
    "ano" smallint NOT NULL,
    "cod_orgao" character varying(10) NOT NULL,
    "nome_orgao" "text",
    "cod_uo" character varying(10),
    "nome_uo" "text",
    "cod_ug" character varying(10),
    "nome_ug" "text",
    "cod_categoria" character varying(5),
    "nome_categoria" "text",
    "cod_grupo" character varying(5),
    "nome_grupo" "text",
    "cod_modalidade" character varying(10),
    "nome_modalidade" "text",
    "cod_elemento" character varying(10),
    "nome_elemento" "text",
    "cod_item" character varying(15),
    "nome_item" "text",
    "cod_funcao" character varying(5),
    "nome_funcao" "text",
    "cod_subfuncao" character varying(5),
    "nome_subfuncao" "text",
    "cod_programa" character varying(10),
    "nome_programa" "text",
    "cod_ptrab" character varying(20),
    "nome_ptrab" "text",
    "cod_fonte" character varying(10),
    "nome_fonte" "text",
    "numero_processo" character varying(30),
    "numero_empenho" character varying(30),
    "cod_credor" character varying(20),
    "nome_credor" "text",
    "cnpj_credor" character varying(14),
    "cod_acao" character varying(20),
    "nome_acao" "text",
    "tipo_licitacao" "text",
    "valor_empenhado" numeric(18,2) DEFAULT 0,
    "valor_liquidado" numeric(18,2) DEFAULT 0,
    "valor_pago" numeric(18,2) DEFAULT 0,
    "valor_pago_anos_ant" numeric(18,2) DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."stf_assinaturas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "email" "text" NOT NULL,
    "stripe_customer_id" "text",
    "stripe_sub_id" "text",
    "plano" "text",
    "status" "text" DEFAULT 'ativa'::"text",
    "vigente_ate" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "stf_assinaturas_plano_check" CHECK (("plano" = ANY (ARRAY['mensal'::"text", 'anual'::"text"]))),
    CONSTRAINT "stf_assinaturas_status_check" CHECK (("status" = ANY (ARRAY['ativa'::"text", 'cancelada'::"text", 'pausada'::"text"])))
);

CREATE TABLE IF NOT EXISTS "public"."stf_gastos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ministro_id" "uuid" NOT NULL,
    "ano" smallint NOT NULL,
    "mes" smallint NOT NULL,
    "categoria" "text" NOT NULL,
    "descricao" "text",
    "valor" numeric(14,2) NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "fonte" "text",
    "data_inicio" "date",
    "data_fim" "date",
    "destino" "text",
    "num_diarias" numeric
);

CREATE TABLE IF NOT EXISTS "public"."stf_ingestao_log" (
    "id" integer NOT NULL,
    "dataset" "text" NOT NULL,
    "linhas_raw" integer,
    "linhas_ok" integer,
    "linhas_erro" integer,
    "arquivo_hash" "text",
    "ingested_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."stf_ministros" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "nome" "text" NOT NULL,
    "iniciais" "text" NOT NULL,
    "data_posse" "date" NOT NULL,
    "data_saida" "date",
    "indicado_por" "text" NOT NULL,
    "partido_indicante" "text" NOT NULL,
    "cargo_anterior" "text",
    "formacao" "text",
    "aposentadoria_comp" "date",
    "ativo" boolean DEFAULT true NOT NULL,
    "score_geral" numeric(4,2),
    "score_direitos_civis" numeric(4,2),
    "score_lib_imprensa" numeric(4,2),
    "score_seg_publica" numeric(4,2),
    "score_economico" numeric(4,2),
    "score_democracia" numeric(4,2),
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."stf_processos_politicos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "numero" "text" NOT NULL,
    "classe" "text" NOT NULL,
    "relator_id" "uuid",
    "partes" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "assunto" "text" NOT NULL,
    "status" "text" NOT NULL,
    "data_dist" "date" NOT NULL,
    "data_julg" "date",
    "resultado" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "stf_processos_politicos_status_check" CHECK (("status" = ANY (ARRAY['em_andamento'::"text", 'julgado'::"text", 'prescrito'::"text", 'suspenso'::"text"])))
);

CREATE TABLE IF NOT EXISTS "public"."stf_repercussao_geral" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tema" integer NOT NULL,
    "titulo" "text" NOT NULL,
    "tese" "text",
    "status" "text" NOT NULL,
    "data_reconh" "date",
    "data_julg" "date",
    "processos_imp" integer,
    "relator_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "leading_case" "text",
    "destaque" boolean DEFAULT false,
    "incidente_id" "text",
    CONSTRAINT "stf_repercussao_geral_status_check" CHECK (("status" = ANY (ARRAY['pendente'::"text", 'julgado'::"text", 'sobrestado'::"text"])))
);

CREATE TABLE IF NOT EXISTS "public"."stf_votacoes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ministro_id" "uuid" NOT NULL,
    "processo" "text" NOT NULL,
    "classe" "text" NOT NULL,
    "data" "date" NOT NULL,
    "ementa" "text" NOT NULL,
    "voto" "text" NOT NULL,
    "resultado" "text",
    "tema_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "stf_votacoes_resultado_check" CHECK (("resultado" = ANY (ARRAY['procedente'::"text", 'improcedente'::"text", 'parcial'::"text"]))),
    CONSTRAINT "stf_votacoes_voto_check" CHECK (("voto" = ANY (ARRAY['favor'::"text", 'contra'::"text", 'abstencao'::"text", 'ausente'::"text"])))
);

CREATE TABLE IF NOT EXISTS "public"."sub_alertas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "dossie_id" "uuid" NOT NULL,
    "cnpj" "text" NOT NULL,
    "ciclo" "text" NOT NULL,
    "fonte" "text" NOT NULL,
    "categoria" "text" NOT NULL,
    "severidade" "text" NOT NULL,
    "titulo" "text" NOT NULL,
    "descricao" "text",
    "valor_brl" numeric(18,2),
    "contraparte" "text",
    "data_evento" "date",
    "referencia_id" "text",
    "url_fonte" "text",
    "is_novo" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "sub_alertas_severidade_check" CHECK (("severidade" = ANY (ARRAY['critico'::"text", 'atencao'::"text", 'ok'::"text", 'info'::"text"])))
);

CREATE TABLE IF NOT EXISTS "public"."sub_aneel_autos" (
    "id" bigint NOT NULL,
    "cnpj" "text" NOT NULL,
    "num_auto_infracao" "text",
    "nom_agente_fiscalizado" "text",
    "nom_natureza_fiscalizacao" "text",
    "dsc_tipo_penalidade" "text",
    "vlr_penalidade" numeric,
    "dat_lavratura" "date",
    "sig_fiscalizador" "text",
    "num_processo" "text",
    "dsc_decisao_juizo" "text",
    "dsc_decisao_diretoria" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."sub_ans_operadoras" (
    "id" bigint NOT NULL,
    "cnpj" "text" NOT NULL,
    "registro_ans" "text",
    "razao_social" "text",
    "nome_fantasia" "text",
    "modalidade" "text",
    "situacao" "text",
    "uf" "text",
    "municipio" "text",
    "regiao" "text",
    "dat_registro" "date",
    "created_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."sub_ceis" (
    "id" bigint NOT NULL,
    "cnpj_cpf" "text" NOT NULL,
    "nome" "text",
    "tipo_sancao" "text",
    "orgao_sancionador" "text",
    "esfera" "text",
    "data_inicio" "date",
    "data_fim" "date",
    "numero_processo" "text",
    "fundamentacao" "text",
    "texto_publicacao" "text",
    "link_publicacao" "text",
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."sub_cepim" (
    "id" bigint NOT NULL,
    "cnpj" "text" NOT NULL,
    "nome" "text",
    "motivo" "text",
    "orgao_superior" "text",
    "num_convenio" "text",
    "data_referencia" "date",
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."sub_clientes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "nome" "text" NOT NULL,
    "email" "text" NOT NULL,
    "empresa" "text",
    "plano" "text" DEFAULT 'starter'::"text" NOT NULL,
    "status" "text" DEFAULT 'trial'::"text" NOT NULL,
    "max_cnpjs" integer DEFAULT 3 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "acesso_token" "text",
    CONSTRAINT "sub_clientes_plano_check" CHECK (("plano" = ANY (ARRAY['trial'::"text", 'starter'::"text", 'profissional'::"text", 'enterprise'::"text"]))),
    CONSTRAINT "sub_clientes_status_check" CHECK (("status" = ANY (ARRAY['trial'::"text", 'ativo'::"text", 'pausado'::"text", 'cancelado'::"text"])))
);

CREATE TABLE IF NOT EXISTS "public"."sub_cnep" (
    "id" bigint NOT NULL,
    "cnpj_cpf" "text" NOT NULL,
    "nome" "text",
    "tipo_sancao" "text",
    "orgao_sancionador" "text",
    "esfera" "text",
    "data_inicio" "date",
    "data_fim" "date",
    "numero_processo" "text",
    "fundamentacao" "text",
    "texto_publicacao" "text",
    "link_publicacao" "text",
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."sub_cnpjs_monitorados" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "cliente_id" "uuid" NOT NULL,
    "cnpj" "text" NOT NULL,
    "razao_social" "text",
    "ativo" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."sub_cvm_pas" (
    "id" bigint NOT NULL,
    "cpf_cnpj" "text" NOT NULL,
    "nom_acusado" "text",
    "num_pas" "text",
    "des_sancao" "text",
    "val_multa" numeric,
    "des_fase" "text",
    "des_tipo_irregularidade" "text",
    "dat_julgamento" "date",
    "des_orgao_julgador" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."sub_dossies" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "cliente_id" "uuid" NOT NULL,
    "cnpj" "text" NOT NULL,
    "razao_social" "text",
    "ciclo" "text" NOT NULL,
    "score_num" integer DEFAULT 0 NOT NULL,
    "score_texto" "text" DEFAULT 'baixo'::"text" NOT NULL,
    "total_alertas" integer DEFAULT 0 NOT NULL,
    "status" "text" DEFAULT 'gerado'::"text" NOT NULL,
    "pdf_url" "text",
    "generated_at" timestamp with time zone DEFAULT "now"(),
    "sent_at" timestamp with time zone,
    CONSTRAINT "sub_dossies_score_num_check" CHECK ((("score_num" >= 0) AND ("score_num" <= 100))),
    CONSTRAINT "sub_dossies_score_texto_check" CHECK (("score_texto" = ANY (ARRAY['baixo'::"text", 'medio'::"text", 'alto'::"text", 'critico'::"text"]))),
    CONSTRAINT "sub_dossies_status_check" CHECK (("status" = ANY (ARRAY['gerado'::"text", 'enviado'::"text", 'lido'::"text"])))
);

CREATE TABLE IF NOT EXISTS "public"."sub_envios" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "dossie_id" "uuid" NOT NULL,
    "cliente_id" "uuid" NOT NULL,
    "canal" "text" DEFAULT 'email'::"text" NOT NULL,
    "destinatario" "text" NOT NULL,
    "status" "text" DEFAULT 'enviado'::"text" NOT NULL,
    "enviado_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "sub_envios_canal_check" CHECK (("canal" = ANY (ARRAY['email'::"text", 'pdf'::"text", 'api'::"text"]))),
    CONSTRAINT "sub_envios_status_check" CHECK (("status" = ANY (ARRAY['enviado'::"text", 'falhou'::"text", 'abriu'::"text"])))
);

CREATE TABLE IF NOT EXISTS "public"."sub_ibama" (
    "id" bigint NOT NULL,
    "cpf_cnpj_infrator" "text" NOT NULL,
    "num_auto_infracao" "text",
    "des_situacao_auto" "text",
    "dat_auto_de_infracao" "text",
    "des_infracao" "text",
    "val_auto_infracao" numeric,
    "nom_municipio" "text",
    "sig_uf" "text",
    "num_processo" "text",
    "nom_infrator" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."sub_lista_suja" (
    "id" bigint NOT NULL,
    "cpf_cnpj" "text" NOT NULL,
    "tipo_doc" "text",
    "nome_empregador" "text",
    "uf" "text",
    "municipio" "text",
    "dat_inclusao" "text",
    "qtd_trabalhadores" "text",
    "decisao_judicial" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."sub_mte_autos" (
    "id" bigint NOT NULL,
    "cnpj" "text" NOT NULL,
    "num_ait" "text",
    "des_situacao" "text",
    "des_infracao" "text",
    "val_multa" numeric,
    "dat_ait" "date",
    "sig_uf" "text",
    "nom_municipio" "text",
    "nom_razao_social" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."sub_pf_consultas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "session_id" "text" NOT NULL,
    "tipo" "text" NOT NULL,
    "status" "text" DEFAULT 'pendente'::"text" NOT NULL,
    "cpf_consultado" "text" NOT NULL,
    "nome_consultado" "text" NOT NULL,
    "finalidade" "text" NOT NULL,
    "email_cliente" "text" NOT NULL,
    "consentimento" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "sub_pf_consultas_status_check" CHECK (("status" = ANY (ARRAY['pendente'::"text", 'processando'::"text", 'concluida'::"text", 'erro'::"text"]))),
    CONSTRAINT "sub_pf_consultas_tipo_check" CHECK (("tipo" = ANY (ARRAY['simples'::"text", 'completa'::"text"])))
);

CREATE TABLE IF NOT EXISTS "public"."sub_snapshots" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "cnpj" "text" NOT NULL,
    "ciclo" "text" NOT NULL,
    "fonte" "text" NOT NULL,
    "hash_dados" "text" NOT NULL,
    "dados" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."subscriptions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "email" "text" NOT NULL,
    "stripe_customer_id" "text",
    "stripe_subscription_id" "text",
    "plan" "text",
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "cnpjs_limit" integer DEFAULT 10 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "subscriptions_plan_check" CHECK (("plan" = ANY (ARRAY['essencial'::"text", 'profissional'::"text", 'enterprise'::"text"]))),
    CONSTRAINT "subscriptions_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'canceled'::"text", 'paused'::"text", 'past_due'::"text", 'trialing'::"text"])))
);

CREATE TABLE IF NOT EXISTS "public"."sync_jobs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ano" integer NOT NULL,
    "status" "text" NOT NULL,
    "started_at" timestamp with time zone DEFAULT "now"(),
    "finished_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS "public"."sync_progress" (
    "ano" integer NOT NULL,
    "ultima_pagina" integer DEFAULT 0
);

CREATE TABLE IF NOT EXISTS "public"."system_state" (
    "key" "text" NOT NULL,
    "value" "jsonb",
    "updated_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."ted_planos_acao" (
    "id_plano_acao" integer NOT NULL,
    "id_programa" integer,
    "sigla_unidade_descentralizada" "text",
    "unidade_descentralizada" "text",
    "sigla_unidade_execucao" "text",
    "unidade_execucao" "text",
    "valor_total" numeric,
    "data_inicio_vigencia" "date",
    "data_fim_vigencia" "date",
    "objeto" "text",
    "situacao" "text",
    "ano" integer,
    "forma_execucao_direta" boolean,
    "forma_execucao_particulares" boolean,
    "forma_execucao_descentralizada" boolean,
    "valor_beneficiario_especifico" numeric,
    "valor_chamamento_publico" numeric,
    "dados" "jsonb",
    "atualizado_em" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."ted_termos_execucao" (
    "id_termo" integer NOT NULL,
    "id_plano_acao" integer,
    "situacao" "text",
    "numero_processo_sei" "text",
    "numero_ns" "text",
    "data_assinatura" "date",
    "data_divulgacao" "date",
    "data_recebimento" "date",
    "data_efetivacao" "date",
    "minuta_padrao" boolean,
    "dados" "jsonb",
    "atualizado_em" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."tse_bens_agg" (
    "sq_candidato" "text" NOT NULL,
    "ano_eleicao" integer NOT NULL,
    "total_bens" integer DEFAULT 0 NOT NULL,
    "total_patrimonio" numeric(18,2) DEFAULT 0 NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."tse_bens_candidatos" (
    "id" integer NOT NULL,
    "sq_candidato" "text" NOT NULL,
    "ano_eleicao" integer NOT NULL,
    "sg_uf" "text",
    "nr_ordem" integer DEFAULT 1 NOT NULL,
    "cd_tipo" integer,
    "ds_tipo" "text",
    "ds_bem" "text",
    "vr_bem" numeric(18,2) DEFAULT 0 NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."tse_candidatos_receitas_agg" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "sq_candidato" "text" NOT NULL,
    "ano_eleicao" smallint NOT NULL,
    "nm_candidato" "text" NOT NULL,
    "nr_cpf_candidato" "text",
    "cd_cargo" smallint NOT NULL,
    "ds_cargo" "text" NOT NULL,
    "sg_uf" "text" NOT NULL,
    "sg_partido" "text",
    "nm_partido" "text",
    "total_receitas" numeric(18,2) DEFAULT 0 NOT NULL,
    "total_registros" integer DEFAULT 0 NOT NULL,
    "fefc" numeric(18,2) DEFAULT 0 NOT NULL,
    "fundo_partidario" numeric(18,2) DEFAULT 0 NOT NULL,
    "recursos_proprios" numeric(18,2) DEFAULT 0 NOT NULL,
    "outros_recursos" numeric(18,2) DEFAULT 0 NOT NULL,
    "posicao" integer,
    "posicao_cargo" integer,
    "por_origem" "jsonb",
    "top_doadores" "jsonb",
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."tse_conta_despesa" (
    "id_hash" "text" NOT NULL,
    "aa_exercicio" integer NOT NULL,
    "sg_uf" "text",
    "cd_municipio" integer,
    "nm_municipio" "text",
    "nr_zona" integer,
    "sg_partido" "text",
    "nm_partido" "text",
    "ds_esfera" "text",
    "cnpj_prestador" "text",
    "sq_despesa" bigint,
    "ds_tipo_despesa" "text",
    "ds_fonte_recurso" "text",
    "vr_despesa" numeric(16,2),
    "cpf_cnpj_fornecedor" "text",
    "nm_fornecedor" "text",
    "ds_tipo_fornecedor" "text",
    "ds_tipo_documento" "text",
    "nr_documento" "text",
    "vr_documento" numeric(16,2),
    "dt_pagamento" "date",
    "vr_pagamento" numeric(16,2),
    "ingerido_em" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."tse_conta_extrato" (
    "id_hash" "text" NOT NULL,
    "aa_referencia" integer NOT NULL,
    "sg_partido" "text",
    "nm_esfera" "text",
    "cnpj_partido" "text",
    "nm_banco" "text",
    "nr_agencia" "text",
    "nr_conta" "text",
    "tp_conta" "text",
    "dt_lancamento" "date",
    "tp_lancamento" "text",
    "ds_lancamento" "text",
    "vr_lancamento" numeric(16,2),
    "ds_tipo_operacao" "text",
    "ds_fonte_recurso" "text",
    "cpf_cnpj_contraparte" "text",
    "tp_pessoa_contraparte" "text",
    "nm_contraparte" "text",
    "nm_banco_contraparte" "text",
    "ingerido_em" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."tse_conta_notafiscal" (
    "id_hash" "text" NOT NULL,
    "aa_exercicio" integer NOT NULL,
    "sg_uf" "text",
    "sg_partido" "text",
    "cnpj_prestador" "text",
    "sq_despesa" bigint,
    "ds_tipo_despesa" "text",
    "cpf_cnpj_fornecedor" "text",
    "nr_documento" "text",
    "vr_documento" numeric(16,2),
    "dt_pagamento" "date",
    "url_documento" "text",
    "ingerido_em" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."tse_conta_receita" (
    "id_hash" "text" NOT NULL,
    "aa_exercicio" integer NOT NULL,
    "sg_uf" "text",
    "cd_municipio" integer,
    "nm_municipio" "text",
    "nr_zona" integer,
    "sg_partido" "text",
    "nm_partido" "text",
    "ds_esfera" "text",
    "cnpj_prestador" "text",
    "ds_receita" "text",
    "ds_fonte_recurso" "text",
    "ds_natureza" "text",
    "ds_especie" "text",
    "ds_origem_doacao" "text",
    "cpf_cnpj_doador" "text",
    "nm_doador" "text",
    "uf_doador" "text",
    "municipio_doador" "text",
    "ds_cargo_doador" "text",
    "nr_recibo" "text",
    "nr_documento" "text",
    "vr_receita" numeric(16,2),
    "dt_receita" "date",
    "ingerido_em" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."tse_ingest_log" (
    "id" bigint NOT NULL,
    "dataset" "text" NOT NULL,
    "started_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "finished_at" timestamp with time zone,
    "status" "text" DEFAULT 'running'::"text" NOT NULL,
    "n_processados" integer,
    "n_novos" integer,
    "n_atualizados" integer,
    "erro" "text"
);

CREATE TABLE IF NOT EXISTS "public"."tse_receitas" (
    "id" bigint NOT NULL,
    "ano_eleicao" smallint NOT NULL,
    "numero_recibo" "text",
    "cpf_candidato" "text",
    "nome_candidato" "text",
    "cargo" "text",
    "sigla_partido" "text",
    "uf" character(2),
    "cpf_cnpj_doador" "text",
    "nome_doador" "text",
    "tipo_doador" "text",
    "setor_economico_doador" "text",
    "cpf_cnpj_doador_originario" "text",
    "nome_doador_originario" "text",
    "natureza_receita" "text",
    "origem_receita" "text",
    "especie_recurso" "text",
    "fonte_recurso" "text",
    "valor" numeric(16,2) NOT NULL,
    "data_receita" "date",
    "data_prestacao_contas" "date",
    "ingested_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."tuss_procedimentos" (
    "codigo" "text" NOT NULL,
    "nome" "text"
);

CREATE TABLE IF NOT EXISTS "public"."usa_agencias" (
    "codigo" "text" NOT NULL,
    "nome" "text" NOT NULL,
    "abreviacao" "text",
    "ativo" boolean DEFAULT true,
    "total_obrigacoes_usd" numeric(18,2),
    "atualizado_em" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."usa_contratos" (
    "award_id" "text" NOT NULL,
    "tipo" "text" NOT NULL,
    "agencia_codigo" "text",
    "agencia_nome" "text",
    "subagencia_nome" "text",
    "beneficiario_nome" "text",
    "beneficiario_uei" "text",
    "beneficiario_estado" "text",
    "valor_obrigado_usd" numeric(18,2),
    "valor_potencial_usd" numeric(18,2),
    "data_inicio" "date",
    "data_fim" "date",
    "data_assinatura" "date",
    "descricao" "text",
    "naics_code" "text",
    "naics_descricao" "text",
    "lugar_execucao_estado" "text",
    "lugar_execucao_pais" "text",
    "permalink" "text",
    "ingested_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."usa_transacoes" (
    "transacao_id" "text" NOT NULL,
    "award_id" "text" NOT NULL,
    "tipo_acao" "text",
    "data_acao" "date",
    "valor_federal_usd" numeric(18,2),
    "valor_nao_federal_usd" numeric(18,2),
    "descricao" "text",
    "agencia_nome" "text",
    "beneficiario_nome" "text",
    "lugar_execucao_pais" "text",
    "lugar_execucao_estado" "text",
    "ingested_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."user_profiles" (
    "id" "uuid" NOT NULL,
    "email" "text" NOT NULL,
    "plano" "text" DEFAULT 'free'::"text" NOT NULL,
    "plano_valido_ate" timestamp with time zone,
    "criado_em" timestamp with time zone DEFAULT "now"() NOT NULL,
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL,
    "stripe_customer_id" "text",
    CONSTRAINT "user_profiles_plano_check" CHECK (("plano" = ANY (ARRAY['free'::"text", 'individual'::"text", 'institucional'::"text"])))
);

CREATE TABLE IF NOT EXISTS "public"."viagens" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "id_portal" bigint,
    "nome_beneficiario" "text",
    "cpf_formatado" "text",
    "motivo" "text",
    "tipo_viagem" "text",
    "situacao" "text",
    "orgao_nome" "text",
    "orgao_codigo" "text",
    "orgao_sigla" "text",
    "data_inicio" "date",
    "data_fim" "date",
    "valor_diarias" numeric DEFAULT 0,
    "valor_passagens" numeric DEFAULT 0,
    "valor_total" numeric DEFAULT 0,
    "valor_devolucao" numeric DEFAULT 0,
    "ano" integer,
    "urgente" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "parlamentar_id" "uuid",
    "pcdp" "text",
    "num_pcdp" "text",
    "urgencia" boolean,
    "beneficiario_nome" "text",
    "beneficiario_cpf" "text",
    "cargo" "text",
    "funcao" "text",
    "orgao_poder" "text",
    "valor_passagem" numeric(14,2),
    "atualizado_em" timestamp with time zone DEFAULT "now"(),
    "destinos" "text",
    "destino_municipio" "text",
    "destino_uf" "text",
    "origem_municipio" "text",
    "origem_uf" "text",
    "destino_pais" "text"
);

CREATE TABLE IF NOT EXISTS "public"."voos_camara_companhia_agg" (
    "companhia" "text" NOT NULL,
    "companhia_eh_aerea" boolean DEFAULT false NOT NULL,
    "ano" integer NOT NULL,
    "total_gasto" numeric(14,2) DEFAULT 0 NOT NULL,
    "n_documentos" integer DEFAULT 0 NOT NULL,
    "share_pct" numeric(6,2) DEFAULT 0 NOT NULL,
    "posicao" integer,
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."voos_camara_deputado_agg" (
    "deputado_id_externo" "text" NOT NULL,
    "nome" "text",
    "sigla_partido" "text",
    "sigla_uf" "text",
    "ano" integer NOT NULL,
    "total_gasto" numeric(14,2) DEFAULT 0 NOT NULL,
    "n_documentos" integer DEFAULT 0 NOT NULL,
    "posicao" integer,
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."voos_senado" (
    "id" bigint NOT NULL,
    "cod_documento" "text" NOT NULL,
    "ano" integer NOT NULL,
    "mes" integer,
    "senador_normalizado" "text",
    "companhia" "text" NOT NULL,
    "companhia_eh_aerea" boolean DEFAULT false NOT NULL,
    "agencia" "text",
    "localizador" "text",
    "passageiro" "text",
    "vinculo" "text",
    "eh_parlamentar" boolean DEFAULT false NOT NULL,
    "voo_numero" "text",
    "origem" "text",
    "destino" "text",
    "data_voo" "date",
    "valor_reembolsado_doc" numeric(14,2),
    "raw_detalhamento" "text",
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."voos_senado_companhia_agg" (
    "companhia" "text" NOT NULL,
    "ano" integer NOT NULL,
    "total_gasto" numeric(14,2) DEFAULT 0 NOT NULL,
    "n_documentos" integer DEFAULT 0 NOT NULL,
    "n_trechos" integer DEFAULT 0 NOT NULL,
    "share_pct" numeric(6,2) DEFAULT 0 NOT NULL,
    "posicao" integer,
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."voos_senado_companhia_senador_agg" (
    "companhia" "text" NOT NULL,
    "senador_normalizado" "text",
    "n_trechos" integer DEFAULT 0 NOT NULL,
    "n_documentos" integer DEFAULT 0 NOT NULL,
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE "public"."voos_senado" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."voos_senado_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."voos_senado_parlamentar_agg" (
    "senador_normalizado" "text",
    "ano" integer NOT NULL,
    "total_gasto" numeric(14,2) DEFAULT 0 NOT NULL,
    "n_documentos" integer DEFAULT 0 NOT NULL,
    "n_trechos" integer DEFAULT 0 NOT NULL,
    "n_trechos_terceiros" integer DEFAULT 0 NOT NULL,
    "ticket_medio" numeric(14,2) DEFAULT 0 NOT NULL,
    "posicao" integer,
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."voos_senado_rota_agg" (
    "companhia" "text" NOT NULL,
    "origem" "text",
    "destino" "text",
    "n_trechos" integer DEFAULT 0 NOT NULL,
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."voos_senado_terceiros_agg" (
    "passageiro" "text" NOT NULL,
    "vinculo" "text",
    "senador_normalizado" "text",
    "n_trechos" integer DEFAULT 0 NOT NULL,
    "atualizado_em" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."votacoes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "parlamentar_uid" "uuid",
    "proposicao_id" "text",
    "voto" "text",
    "data_votacao" "date",
    "created_at" timestamp without time zone DEFAULT "now"(),
    "parlamentar_id" "uuid"
);

CREATE TABLE IF NOT EXISTS "public"."votacoes_brutas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "deputado_id_externo" "text" NOT NULL,
    "id_votacao" integer NOT NULL,
    "descricao_voto" "text",
    "dados" "jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."votacoes_orientacoes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "votacao_id" "text" NOT NULL,
    "sigla_orgao" "text",
    "sigla_bancada" "text" NOT NULL,
    "nome_bancada" "text",
    "orientacao" "text",
    "data_votacao" "date",
    "fonte_dado" "text" DEFAULT 'camara_api'::"text",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."votacoes_senado" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "parlamentar_id" "uuid",
    "id_sessao" "text",
    "data_sessao" "date",
    "voto" "text",
    "materia" "text",
    "ementa" "text",
    "resultado" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);

CREATE TABLE IF NOT EXISTS "public"."watchlist_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "watchlist_id" "uuid",
    "parlamentar_uid" "uuid"
);

CREATE TABLE IF NOT EXISTS "public"."watchlists" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "nome" "text",
    "created_at" timestamp without time zone DEFAULT "now"()
);

ALTER TABLE ONLY "bcb"."if_balanco" ALTER COLUMN "id" SET DEFAULT "nextval"('"bcb"."if_balanco_id_seq"'::"regclass");

ALTER TABLE ONLY "bcb"."scr_operacoes" ALTER COLUMN "id" SET DEFAULT "nextval"('"bcb"."scr_operacoes_id_seq"'::"regclass");

ALTER TABLE ONLY "bcb"."sicor_credito_rural" ALTER COLUMN "id" SET DEFAULT "nextval"('"bcb"."sicor_credito_rural_id_seq"'::"regclass");

ALTER TABLE ONLY "homabrasil"."desastres_historico" ALTER COLUMN "id" SET DEFAULT "nextval"('"homabrasil"."desastres_historico_id_seq"'::"regclass");

ALTER TABLE ONLY "homabrasil"."homa_score" ALTER COLUMN "id" SET DEFAULT "nextval"('"homabrasil"."homa_score_id_seq"'::"regclass");

ALTER TABLE ONLY "homabrasil"."infraestrutura" ALTER COLUMN "id" SET DEFAULT "nextval"('"homabrasil"."infraestrutura_id_seq"'::"regclass");

ALTER TABLE ONLY "homabrasil"."municipios" ALTER COLUMN "id" SET DEFAULT "nextval"('"homabrasil"."municipios_id_seq"'::"regclass");

ALTER TABLE ONLY "homabrasil"."qualidade_vida" ALTER COLUMN "id" SET DEFAULT "nextval"('"homabrasil"."qualidade_vida_id_seq"'::"regclass");

ALTER TABLE ONLY "homabrasil"."risco_climatico" ALTER COLUMN "id" SET DEFAULT "nextval"('"homabrasil"."risco_climatico_id_seq"'::"regclass");

ALTER TABLE ONLY "portal_transparencia"."cartoes_pagamento" ALTER COLUMN "id" SET DEFAULT "nextval"('"portal_transparencia"."cartoes_pagamento_id_seq"'::"regclass");

ALTER TABLE ONLY "portal_transparencia"."ingest_runs" ALTER COLUMN "id" SET DEFAULT "nextval"('"portal_transparencia"."ingest_runs_id_seq"'::"regclass");

ALTER TABLE ONLY "portal_transparencia"."notas_fiscais_itens" ALTER COLUMN "id" SET DEFAULT "nextval"('"portal_transparencia"."notas_fiscais_itens_id_seq"'::"regclass");

ALTER TABLE ONLY "portal_transparencia"."sancoes" ALTER COLUMN "id" SET DEFAULT "nextval"('"portal_transparencia"."sancoes_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."aleba_despesas" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."aleba_despesas_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."alesc_despesas" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."alesc_despesas_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."assessores" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."assessores_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."autores_parlamentares_map" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."autores_parlamentares_map_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."bets_licenciadas" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."bets_licenciadas_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."casas" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."casas_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."cbf_cnpjs_vinculados" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."cbf_cnpjs_vinculados_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."cbf_socios_federacoes" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."cbf_socios_federacoes_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."ceaf_ingest_log" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."ceaf_ingest_log_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."cgu_pad_ingest_log" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."cgu_pad_ingest_log_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."cnpj_ingest_log" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."cnpj_ingest_log_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."contratos_ingest_log" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."contratos_ingest_log_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."convenios" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."convenios_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."cpgf_transacoes" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."cpgf_transacoes_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."dou_alertas_cruzamento" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."dou_alertas_cruzamento_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."dou_publicacoes" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."dou_publicacoes_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."ele2026_alertas" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."ele2026_alertas_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."ele2026_financiamento" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."ele2026_financiamento_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."ele2026_gastos" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."ele2026_gastos_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."ele2026_ingest_log" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."ele2026_ingest_log_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."emendas_api_documentos" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."emendas_api_documentos_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."emendas_api_ingest_log" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."emendas_api_ingest_log_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."estados" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."estados_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."execucao_financeira_siafi" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."execucao_financeira_siafi_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."execucao_financeira_transferencias" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."execucao_financeira_transferencias_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."ibama_autuacoes" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."ibama_autuacoes_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."ibge_indicadores" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."ibge_indicadores_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."indicadores_macroeconomicos" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."indicadores_macroeconomicos_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."leiloes_leiloeiros" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."leiloes_leiloeiros_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."leiloes_processos" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."leiloes_processos_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."licitacoes_ingest_log" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."licitacoes_ingest_log_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."licitacoes_participantes" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."licitacoes_participantes_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."ministerios" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."ministerios_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."notas_fiscais_ingest_log" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."notas_fiscais_ingest_log_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."orgaos_federais" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."orgaos_federais_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."peps" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."peps_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."peps_ingest_log" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."peps_ingest_log_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."pgfn_divida_federacoes" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."pgfn_divida_federacoes_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."portal_sancionados" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."portal_sancionados_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."sancoes_ingest_log" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."sancoes_ingest_log_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."sebrae_contratos" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."sebrae_contratos_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."sebrae_convenios" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."sebrae_convenios_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."sebrae_emendas_contratos" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."sebrae_emendas_contratos_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."sebrae_emendas_convenios" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."sebrae_emendas_convenios_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."sebrae_licitacoes" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."sebrae_licitacoes_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."sebrae_patrocinios" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."sebrae_patrocinios_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."sen_proposicoes" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."sen_proposicoes_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."senac_contratos" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."senac_contratos_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."senac_licitacoes" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."senac_licitacoes_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."senar_contratos" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."senar_contratos_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."senar_licitacoes" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."senar_licitacoes_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."senar_transferencias" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."senar_transferencias_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."sesc_contratos" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."sesc_contratos_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."sesc_convenios" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."sesc_convenios_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."siafi_ingestao_log" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."siafi_ingestao_log_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."sisi_contratos" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."sisi_contratos_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."sisi_convenios" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."sisi_convenios_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."sisi_licitacoes" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."sisi_licitacoes_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."sisi_licitacoes_participantes" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."sisi_licitacoes_participantes_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."sp_contratos" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."sp_contratos_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."sp_despesas" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."sp_despesas_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."stf_ingestao_log" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."stf_ingestao_log_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."sub_aneel_autos" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."sub_aneel_autos_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."sub_ans_operadoras" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."sub_ans_operadoras_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."sub_cvm_pas" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."sub_cvm_pas_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."sub_ibama" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."sub_ibama_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."sub_lista_suja" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."sub_lista_suja_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."sub_mte_autos" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."sub_mte_autos_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."tribunais" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."tribunais_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."tse_bens_candidatos" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."tse_bens_candidatos_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."tse_despesas" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."tse_despesas_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."tse_ingest_log" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."tse_ingest_log_id_seq"'::"regclass");

ALTER TABLE ONLY "public"."tse_receitas" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."tse_receitas_id_seq"'::"regclass");
-- bloco 06_constraints — gerado por split_baseline.py (ordem interna = ordem do dump)
ALTER SEQUENCE "bcb"."if_balanco_id_seq" OWNED BY "bcb"."if_balanco"."id";

ALTER SEQUENCE "bcb"."scr_operacoes_id_seq" OWNED BY "bcb"."scr_operacoes"."id";

ALTER SEQUENCE "bcb"."sicor_credito_rural_id_seq" OWNED BY "bcb"."sicor_credito_rural"."id";

ALTER SEQUENCE "homabrasil"."desastres_historico_id_seq" OWNED BY "homabrasil"."desastres_historico"."id";

ALTER SEQUENCE "homabrasil"."homa_score_id_seq" OWNED BY "homabrasil"."homa_score"."id";

ALTER SEQUENCE "homabrasil"."infraestrutura_id_seq" OWNED BY "homabrasil"."infraestrutura"."id";

ALTER SEQUENCE "homabrasil"."municipios_id_seq" OWNED BY "homabrasil"."municipios"."id";

ALTER SEQUENCE "homabrasil"."qualidade_vida_id_seq" OWNED BY "homabrasil"."qualidade_vida"."id";

ALTER SEQUENCE "homabrasil"."risco_climatico_id_seq" OWNED BY "homabrasil"."risco_climatico"."id";

ALTER SEQUENCE "portal_transparencia"."cartoes_pagamento_id_seq" OWNED BY "portal_transparencia"."cartoes_pagamento"."id";

ALTER SEQUENCE "portal_transparencia"."ingest_runs_id_seq" OWNED BY "portal_transparencia"."ingest_runs"."id";

ALTER SEQUENCE "portal_transparencia"."notas_fiscais_itens_id_seq" OWNED BY "portal_transparencia"."notas_fiscais_itens"."id";

ALTER SEQUENCE "portal_transparencia"."sancoes_id_seq" OWNED BY "portal_transparencia"."sancoes"."id";

ALTER SEQUENCE "public"."aleba_despesas_id_seq" OWNED BY "public"."aleba_despesas"."id";

ALTER SEQUENCE "public"."alesc_despesas_id_seq" OWNED BY "public"."alesc_despesas"."id";

ALTER SEQUENCE "public"."assessores_id_seq" OWNED BY "public"."assessores"."id";

ALTER SEQUENCE "public"."autores_parlamentares_map_id_seq" OWNED BY "public"."autores_parlamentares_map"."id";

ALTER SEQUENCE "public"."bets_licenciadas_id_seq" OWNED BY "public"."bets_licenciadas"."id";

ALTER SEQUENCE "public"."casas_id_seq" OWNED BY "public"."casas"."id";

ALTER SEQUENCE "public"."cbf_cnpjs_vinculados_id_seq" OWNED BY "public"."cbf_cnpjs_vinculados"."id";

ALTER SEQUENCE "public"."cbf_socios_federacoes_id_seq" OWNED BY "public"."cbf_socios_federacoes"."id";

ALTER SEQUENCE "public"."ceaf_ingest_log_id_seq" OWNED BY "public"."ceaf_ingest_log"."id";

ALTER SEQUENCE "public"."cgu_pad_ingest_log_id_seq" OWNED BY "public"."cgu_pad_ingest_log"."id";

ALTER SEQUENCE "public"."cnpj_ingest_log_id_seq" OWNED BY "public"."cnpj_ingest_log"."id";

ALTER SEQUENCE "public"."contratos_ingest_log_id_seq" OWNED BY "public"."contratos_ingest_log"."id";

ALTER SEQUENCE "public"."convenios_id_seq" OWNED BY "public"."convenios"."id";

ALTER SEQUENCE "public"."cpgf_transacoes_id_seq" OWNED BY "public"."cpgf_transacoes"."id";

ALTER SEQUENCE "public"."dou_alertas_cruzamento_id_seq" OWNED BY "public"."dou_alertas_cruzamento"."id";

ALTER SEQUENCE "public"."dou_publicacoes_id_seq" OWNED BY "public"."dou_publicacoes"."id";

ALTER SEQUENCE "public"."ele2026_alertas_id_seq" OWNED BY "public"."ele2026_alertas"."id";

ALTER SEQUENCE "public"."ele2026_financiamento_id_seq" OWNED BY "public"."ele2026_financiamento"."id";

ALTER SEQUENCE "public"."ele2026_gastos_id_seq" OWNED BY "public"."ele2026_gastos"."id";

ALTER SEQUENCE "public"."ele2026_ingest_log_id_seq" OWNED BY "public"."ele2026_ingest_log"."id";

ALTER SEQUENCE "public"."emendas_api_documentos_id_seq" OWNED BY "public"."emendas_api_documentos"."id";

ALTER SEQUENCE "public"."emendas_api_ingest_log_id_seq" OWNED BY "public"."emendas_api_ingest_log"."id";

ALTER SEQUENCE "public"."estados_id_seq" OWNED BY "public"."estados"."id";

ALTER SEQUENCE "public"."execucao_financeira_siafi_id_seq" OWNED BY "public"."execucao_financeira_siafi"."id";

ALTER SEQUENCE "public"."execucao_financeira_transferencias_id_seq" OWNED BY "public"."execucao_financeira_transferencias"."id";

ALTER SEQUENCE "public"."ibama_autuacoes_id_seq" OWNED BY "public"."ibama_autuacoes"."id";

ALTER SEQUENCE "public"."ibge_indicadores_id_seq" OWNED BY "public"."ibge_indicadores"."id";

ALTER SEQUENCE "public"."indicadores_macroeconomicos_id_seq" OWNED BY "public"."indicadores_macroeconomicos"."id";

ALTER SEQUENCE "public"."leiloes_leiloeiros_id_seq" OWNED BY "public"."leiloes_leiloeiros"."id";

ALTER SEQUENCE "public"."leiloes_processos_id_seq" OWNED BY "public"."leiloes_processos"."id";

ALTER SEQUENCE "public"."licitacoes_ingest_log_id_seq" OWNED BY "public"."licitacoes_ingest_log"."id";

ALTER SEQUENCE "public"."licitacoes_participantes_id_seq" OWNED BY "public"."licitacoes_participantes"."id";

ALTER SEQUENCE "public"."ministerios_id_seq" OWNED BY "public"."ministerios"."id";

ALTER SEQUENCE "public"."notas_fiscais_ingest_log_id_seq" OWNED BY "public"."notas_fiscais_ingest_log"."id";

ALTER SEQUENCE "public"."orgaos_federais_id_seq" OWNED BY "public"."orgaos_federais"."id";

ALTER SEQUENCE "public"."peps_id_seq" OWNED BY "public"."peps"."id";

ALTER SEQUENCE "public"."peps_ingest_log_id_seq" OWNED BY "public"."peps_ingest_log"."id";

ALTER SEQUENCE "public"."pgfn_divida_federacoes_id_seq" OWNED BY "public"."pgfn_divida_federacoes"."id";

ALTER SEQUENCE "public"."portal_sancionados_id_seq" OWNED BY "public"."portal_sancionados"."id";

ALTER SEQUENCE "public"."sancoes_ingest_log_id_seq" OWNED BY "public"."sancoes_ingest_log"."id";

ALTER SEQUENCE "public"."sebrae_contratos_id_seq" OWNED BY "public"."sebrae_contratos"."id";

ALTER SEQUENCE "public"."sebrae_convenios_id_seq" OWNED BY "public"."sebrae_convenios"."id";

ALTER SEQUENCE "public"."sebrae_emendas_contratos_id_seq" OWNED BY "public"."sebrae_emendas_contratos"."id";

ALTER SEQUENCE "public"."sebrae_emendas_convenios_id_seq" OWNED BY "public"."sebrae_emendas_convenios"."id";

ALTER SEQUENCE "public"."sebrae_licitacoes_id_seq" OWNED BY "public"."sebrae_licitacoes"."id";

ALTER SEQUENCE "public"."sebrae_patrocinios_id_seq" OWNED BY "public"."sebrae_patrocinios"."id";

ALTER SEQUENCE "public"."sen_proposicoes_id_seq" OWNED BY "public"."sen_proposicoes"."id";

ALTER SEQUENCE "public"."senac_contratos_id_seq" OWNED BY "public"."senac_contratos"."id";

ALTER SEQUENCE "public"."senac_licitacoes_id_seq" OWNED BY "public"."senac_licitacoes"."id";

ALTER SEQUENCE "public"."senar_contratos_id_seq" OWNED BY "public"."senar_contratos"."id";

ALTER SEQUENCE "public"."senar_licitacoes_id_seq" OWNED BY "public"."senar_licitacoes"."id";

ALTER SEQUENCE "public"."senar_transferencias_id_seq" OWNED BY "public"."senar_transferencias"."id";

ALTER SEQUENCE "public"."sesc_contratos_id_seq" OWNED BY "public"."sesc_contratos"."id";

ALTER SEQUENCE "public"."sesc_convenios_id_seq" OWNED BY "public"."sesc_convenios"."id";

ALTER SEQUENCE "public"."siafi_ingestao_log_id_seq" OWNED BY "public"."siafi_ingestao_log"."id";

ALTER SEQUENCE "public"."sisi_contratos_id_seq" OWNED BY "public"."sisi_contratos"."id";

ALTER SEQUENCE "public"."sisi_convenios_id_seq" OWNED BY "public"."sisi_convenios"."id";

ALTER SEQUENCE "public"."sisi_licitacoes_id_seq" OWNED BY "public"."sisi_licitacoes"."id";

ALTER SEQUENCE "public"."sisi_licitacoes_participantes_id_seq" OWNED BY "public"."sisi_licitacoes_participantes"."id";

ALTER SEQUENCE "public"."sp_contratos_id_seq" OWNED BY "public"."sp_contratos"."id";

ALTER SEQUENCE "public"."sp_despesas_id_seq" OWNED BY "public"."sp_despesas"."id";

ALTER SEQUENCE "public"."stf_ingestao_log_id_seq" OWNED BY "public"."stf_ingestao_log"."id";

ALTER SEQUENCE "public"."sub_aneel_autos_id_seq" OWNED BY "public"."sub_aneel_autos"."id";

ALTER SEQUENCE "public"."sub_ans_operadoras_id_seq" OWNED BY "public"."sub_ans_operadoras"."id";

ALTER SEQUENCE "public"."sub_cvm_pas_id_seq" OWNED BY "public"."sub_cvm_pas"."id";

ALTER SEQUENCE "public"."sub_ibama_id_seq" OWNED BY "public"."sub_ibama"."id";

ALTER SEQUENCE "public"."sub_lista_suja_id_seq" OWNED BY "public"."sub_lista_suja"."id";

ALTER SEQUENCE "public"."sub_mte_autos_id_seq" OWNED BY "public"."sub_mte_autos"."id";

ALTER SEQUENCE "public"."tribunais_id_seq" OWNED BY "public"."tribunais"."id";

ALTER SEQUENCE "public"."tse_bens_candidatos_id_seq" OWNED BY "public"."tse_bens_candidatos"."id";

ALTER SEQUENCE "public"."tse_despesas_id_seq" OWNED BY "public"."tse_despesas"."id";

ALTER SEQUENCE "public"."tse_ingest_log_id_seq" OWNED BY "public"."tse_ingest_log"."id";

ALTER SEQUENCE "public"."tse_receitas_id_seq" OWNED BY "public"."tse_receitas"."id";

ALTER TABLE ONLY "bcb"."if_balanco"
    ADD CONSTRAINT "if_balanco_cod_inst_ano_mes_nome_relatorio_conta_nome_colun_key" UNIQUE ("cod_inst", "ano_mes", "nome_relatorio", "conta", "nome_coluna");

ALTER TABLE ONLY "bcb"."if_balanco"
    ADD CONSTRAINT "if_balanco_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "bcb"."if_cadastro"
    ADD CONSTRAINT "if_cadastro_pkey" PRIMARY KEY ("cod_inst");

ALTER TABLE ONLY "bcb"."scr_operacoes"
    ADD CONSTRAINT "scr_operacoes_data_base_uf_segmento_cliente_cnae_ocupacao_p_key" UNIQUE ("data_base", "uf", "segmento", "cliente", "cnae_ocupacao", "porte", "modalidade", "submodalidade", "origem", "indexador");

ALTER TABLE ONLY "bcb"."scr_operacoes"
    ADD CONSTRAINT "scr_operacoes_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "bcb"."sicor_credito_rural"
    ADD CONSTRAINT "sicor_credito_rural_mes_emissao_ano_emissao_cnpj_if_cd_muni_key" UNIQUE ("mes_emissao", "ano_emissao", "cnpj_if", "cd_municipio_ibge", "produto", "finalidade", "cd_fonte_recurso");

ALTER TABLE ONLY "bcb"."sicor_credito_rural"
    ADD CONSTRAINT "sicor_credito_rural_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "cidadania_ai"."cases"
    ADD CONSTRAINT "cases_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "cidadania_ai"."generated_docs"
    ADD CONSTRAINT "generated_docs_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "cidadania_ai"."library_docs"
    ADD CONSTRAINT "library_docs_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "cidadania_ai"."messages"
    ADD CONSTRAINT "messages_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "homabrasil"."desastres_historico"
    ADD CONSTRAINT "desastres_historico_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "homabrasil"."homa_score"
    ADD CONSTRAINT "homa_score_municipio_id_ano_ref_key" UNIQUE ("municipio_id", "ano_ref");

ALTER TABLE ONLY "homabrasil"."homa_score"
    ADD CONSTRAINT "homa_score_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "homabrasil"."infraestrutura"
    ADD CONSTRAINT "infraestrutura_municipio_id_ano_key" UNIQUE ("municipio_id", "ano");

ALTER TABLE ONLY "homabrasil"."infraestrutura"
    ADD CONSTRAINT "infraestrutura_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "homabrasil"."municipios"
    ADD CONSTRAINT "municipios_codigo_ibge_key" UNIQUE ("codigo_ibge");

ALTER TABLE ONLY "homabrasil"."municipios"
    ADD CONSTRAINT "municipios_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "homabrasil"."qualidade_vida"
    ADD CONSTRAINT "qualidade_vida_municipio_id_ano_key" UNIQUE ("municipio_id", "ano");

ALTER TABLE ONLY "homabrasil"."qualidade_vida"
    ADD CONSTRAINT "qualidade_vida_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "homabrasil"."risco_climatico"
    ADD CONSTRAINT "risco_climatico_municipio_id_ano_ref_key" UNIQUE ("municipio_id", "ano_ref");

ALTER TABLE ONLY "homabrasil"."risco_climatico"
    ADD CONSTRAINT "risco_climatico_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "portal_transparencia"."cartoes_pagamento"
    ADD CONSTRAINT "cartoes_pagamento_cpf_portador_mascarado_data_transacao_cnp_key" UNIQUE ("cpf_portador_mascarado", "data_transacao", "cnpj_estabelecimento", "valor", "codigo_orgao");

ALTER TABLE ONLY "portal_transparencia"."cartoes_pagamento"
    ADD CONSTRAINT "cartoes_pagamento_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "portal_transparencia"."favorecidos"
    ADD CONSTRAINT "favorecidos_pkey" PRIMARY KEY ("cnpj_cpf");

ALTER TABLE ONLY "portal_transparencia"."ingest_runs"
    ADD CONSTRAINT "ingest_runs_base_competencia_hash_arquivo_key" UNIQUE ("base", "competencia", "hash_arquivo");

ALTER TABLE ONLY "portal_transparencia"."ingest_runs"
    ADD CONSTRAINT "ingest_runs_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "portal_transparencia"."notas_fiscais_itens"
    ADD CONSTRAINT "notas_fiscais_itens_chave_nfe_numero_item_key" UNIQUE ("chave_nfe", "numero_item");

ALTER TABLE ONLY "portal_transparencia"."notas_fiscais_itens"
    ADD CONSTRAINT "notas_fiscais_itens_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "portal_transparencia"."notas_fiscais"
    ADD CONSTRAINT "notas_fiscais_pkey" PRIMARY KEY ("chave_nfe");

ALTER TABLE ONLY "portal_transparencia"."sancoes"
    ADD CONSTRAINT "sancoes_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."agenda_camara_eventos"
    ADD CONSTRAINT "agenda_camara_eventos_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."agenda_executivo_compromissos"
    ADD CONSTRAINT "agenda_executivo_compromissos_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."agenda_ingest_log"
    ADD CONSTRAINT "agenda_ingest_log_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."agenda_senado_comissoes"
    ADD CONSTRAINT "agenda_senado_comissoes_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."agenda_senado_plenario"
    ADD CONSTRAINT "agenda_senado_plenario_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."ale_casas"
    ADD CONSTRAINT "ale_casas_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."ale_ingest_runs"
    ADD CONSTRAINT "ale_ingest_runs_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."ale_parlamentares"
    ADD CONSTRAINT "ale_parlamentares_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."ale_proposicoes"
    ADD CONSTRAINT "ale_proposicoes_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."ale_votacoes"
    ADD CONSTRAINT "ale_votacoes_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."ale_votos"
    ADD CONSTRAINT "ale_votos_pkey" PRIMARY KEY ("votacao_id", "deputado_id");

ALTER TABLE ONLY "public"."aleba_deputados"
    ADD CONSTRAINT "aleba_deputados_pkey" PRIMARY KEY ("id_aleba");

ALTER TABLE ONLY "public"."aleba_despesas"
    ADD CONSTRAINT "aleba_despesas_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."alertas_processo"
    ADD CONSTRAINT "alertas_processo_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."alerts_history"
    ADD CONSTRAINT "alerts_history_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."alesc_deputados"
    ADD CONSTRAINT "alesc_deputados_pkey" PRIMARY KEY ("id_alesc");

ALTER TABLE ONLY "public"."alesc_despesas"
    ADD CONSTRAINT "alesc_despesas_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."api_rate_state"
    ADD CONSTRAINT "api_rate_state_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."ask_cache"
    ADD CONSTRAINT "ask_cache_pergunta_hash_key" UNIQUE ("pergunta_hash");

ALTER TABLE ONLY "public"."ask_cache"
    ADD CONSTRAINT "ask_cache_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."ask_log"
    ADD CONSTRAINT "ask_log_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."ask_quota"
    ADD CONSTRAINT "ask_quota_pkey" PRIMARY KEY ("user_id", "date");

ALTER TABLE ONLY "public"."assessores"
    ADD CONSTRAINT "assessores_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."authority_metrics"
    ADD CONSTRAINT "authority_metrics_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."auto_briefings"
    ADD CONSTRAINT "auto_briefings_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."autores_orcamentarios"
    ADD CONSTRAINT "autores_orcamentarios_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."autores_parlamentares_map"
    ADD CONSTRAINT "autores_parlamentares_map_codigo_autor_key" UNIQUE ("codigo_autor");

ALTER TABLE ONLY "public"."autores_parlamentares_map"
    ADD CONSTRAINT "autores_parlamentares_map_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."b3_empresas_listadas"
    ADD CONSTRAINT "b3_empresas_listadas_pkey" PRIMARY KEY ("codigo_cvm");

ALTER TABLE ONLY "public"."b3_tickers"
    ADD CONSTRAINT "b3_tickers_pkey" PRIMARY KEY ("codigo_cvm", "tipo");

ALTER TABLE ONLY "public"."banks"
    ADD CONSTRAINT "banks_pkey" PRIMARY KEY ("ispb");

ALTER TABLE ONLY "public"."beneficios_parlamentares"
    ADD CONSTRAINT "beneficios_parlamentares_parlamentar_id_tipo_beneficio_data_key" UNIQUE ("parlamentar_id", "tipo_beneficio", "data");

ALTER TABLE ONLY "public"."beneficios_parlamentares"
    ADD CONSTRAINT "beneficios_parlamentares_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."bets_licenciadas"
    ADD CONSTRAINT "bets_licenciadas_cnpj_key" UNIQUE ("cnpj");

ALTER TABLE ONLY "public"."bets_licenciadas"
    ADD CONSTRAINT "bets_licenciadas_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."cam_comissoes_membros"
    ADD CONSTRAINT "cam_comissoes_membros_pkey" PRIMARY KEY ("comissao_id", "deputado_id");

ALTER TABLE ONLY "public"."cam_comissoes"
    ADD CONSTRAINT "cam_comissoes_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."cam_frentes_membros"
    ADD CONSTRAINT "cam_frentes_membros_pkey" PRIMARY KEY ("frente_id", "deputado_id");

ALTER TABLE ONLY "public"."cam_frentes"
    ADD CONSTRAINT "cam_frentes_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."cam_parlamentar_risco"
    ADD CONSTRAINT "cam_parlamentar_risco_pkey" PRIMARY KEY ("deputado_id");

ALTER TABLE ONLY "public"."cam_proposicoes_agg"
    ADD CONSTRAINT "cam_proposicoes_agg_pkey" PRIMARY KEY ("deputado_id");

ALTER TABLE ONLY "public"."cam_proposicoes"
    ADD CONSTRAINT "cam_proposicoes_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."camara_frente_membro"
    ADD CONSTRAINT "camara_frente_membro_pkey" PRIMARY KEY ("id_frente", "id_deputado");

ALTER TABLE ONLY "public"."camara_frente"
    ADD CONSTRAINT "camara_frente_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."camara_ocupacao"
    ADD CONSTRAINT "camara_ocupacao_pkey" PRIMARY KEY ("id_deputado", "titulo");

ALTER TABLE ONLY "public"."cambio_cotacoes"
    ADD CONSTRAINT "cambio_cotacoes_pkey" PRIMARY KEY ("simbolo", "data_cotacao");

ALTER TABLE ONLY "public"."cambio_moedas"
    ADD CONSTRAINT "cambio_moedas_pkey" PRIMARY KEY ("simbolo");

ALTER TABLE ONLY "public"."casas"
    ADD CONSTRAINT "casas_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."casas"
    ADD CONSTRAINT "casas_sigla_key" UNIQUE ("sigla");

ALTER TABLE ONLY "public"."cbf_cnpjs_vinculados"
    ADD CONSTRAINT "cbf_cnpjs_vinculados_cnpj_basico_cpf_socio_cnpj_federacao_r_key" UNIQUE ("cnpj_basico", "cpf_socio", "cnpj_federacao_ref");

ALTER TABLE ONLY "public"."cbf_cnpjs_vinculados"
    ADD CONSTRAINT "cbf_cnpjs_vinculados_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."cbf_socios_federacoes"
    ADD CONSTRAINT "cbf_socios_federacoes_cnpj_federacao_cpf_socio_key" UNIQUE ("cnpj_federacao", "cpf_socio");

ALTER TABLE ONLY "public"."cbf_socios_federacoes"
    ADD CONSTRAINT "cbf_socios_federacoes_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."ceaf_expulsoes"
    ADD CONSTRAINT "ceaf_expulsoes_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."ceaf_ingest_log"
    ADD CONSTRAINT "ceaf_ingest_log_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."ceaps_brutas"
    ADD CONSTRAINT "ceaps_brutas_ano_cod_documento_key" UNIQUE ("ano", "cod_documento");

ALTER TABLE ONLY "public"."ceaps_brutas"
    ADD CONSTRAINT "ceaps_brutas_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."ceaps_ranking"
    ADD CONSTRAINT "ceaps_ranking_pkey" PRIMARY KEY ("deputado_id_externo", "ano");

ALTER TABLE ONLY "public"."ceaps_senado_brutas"
    ADD CONSTRAINT "ceaps_senado_brutas_cod_documento_ano_key" UNIQUE ("cod_documento", "ano");

ALTER TABLE ONLY "public"."ceaps_senado_brutas"
    ADD CONSTRAINT "ceaps_senado_brutas_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."ceaps_senado_ranking"
    ADD CONSTRAINT "ceaps_senado_ranking_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."ceaps_senado_ranking"
    ADD CONSTRAINT "ceaps_senado_ranking_senador_normalizado_ano_key" UNIQUE ("senador_normalizado", "ano");

ALTER TABLE ONLY "public"."cgu_pad_ingest_log"
    ADD CONSTRAINT "cgu_pad_ingest_log_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."cgu_pad_processos"
    ADD CONSTRAINT "cgu_pad_processos_pkey" PRIMARY KEY ("numero_processo");

ALTER TABLE ONLY "public"."cnes_estabelecimentos"
    ADD CONSTRAINT "cnes_estabelecimentos_pkey" PRIMARY KEY ("codigo_cnes");

ALTER TABLE ONLY "public"."cnpj_empresa"
    ADD CONSTRAINT "cnpj_empresa_pkey" PRIMARY KEY ("cnpj_basico");

ALTER TABLE ONLY "public"."cnpj_empresas"
    ADD CONSTRAINT "cnpj_empresas_pkey" PRIMARY KEY ("cnpj_basico");

ALTER TABLE ONLY "public"."cnpj_enriquecido"
    ADD CONSTRAINT "cnpj_enriquecido_pkey" PRIMARY KEY ("cnpj");

ALTER TABLE ONLY "public"."cnpj_ingest_log"
    ADD CONSTRAINT "cnpj_ingest_log_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."cnpj_socios"
    ADD CONSTRAINT "cnpj_socios_cnpj_basico_nome_socio_cpf_cnpj_socio_key" UNIQUE NULLS NOT DISTINCT ("cnpj_basico", "nome_socio", "cpf_cnpj_socio");

ALTER TABLE ONLY "public"."cobertura_dados"
    ADD CONSTRAINT "cobertura_dados_pkey" PRIMARY KEY ("ano");

ALTER TABLE ONLY "public"."codigos_acesso"
    ADD CONSTRAINT "codigos_acesso_pkey" PRIMARY KEY ("codigo");

ALTER TABLE ONLY "public"."comissoes_parlamentares"
    ADD CONSTRAINT "comissoes_parlamentares_parlamentar_id_id_orgao_cargo_key" UNIQUE ("parlamentar_id", "id_orgao", "cargo");

ALTER TABLE ONLY "public"."comissoes_parlamentares"
    ADD CONSTRAINT "comissoes_parlamentares_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."comissoes_senado"
    ADD CONSTRAINT "comissoes_senado_parlamentar_id_id_cargo_tipo_funcao_key" UNIQUE ("parlamentar_id", "id_cargo", "tipo_funcao");

ALTER TABLE ONLY "public"."comissoes_senado"
    ADD CONSTRAINT "comissoes_senado_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."contratos_federais"
    ADD CONSTRAINT "contratos_federais_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."contratos_ingest_log"
    ADD CONSTRAINT "contratos_ingest_log_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."convenios"
    ADD CONSTRAINT "convenios_id_portal_key" UNIQUE ("id_portal");

ALTER TABLE ONLY "public"."convenios"
    ADD CONSTRAINT "convenios_numero_key" UNIQUE ("numero");

ALTER TABLE ONLY "public"."convenios"
    ADD CONSTRAINT "convenios_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."cota_cnpj_lookup"
    ADD CONSTRAINT "cota_cnpj_lookup_pkey" PRIMARY KEY ("cnpj_raw");

ALTER TABLE ONLY "public"."cota_deputado"
    ADD CONSTRAINT "cota_deputado_pkey" PRIMARY KEY ("id_camara");

ALTER TABLE ONLY "public"."cota_despesa"
    ADD CONSTRAINT "cota_despesa_pkey" PRIMARY KEY ("id_documento", "id_deputado");

ALTER TABLE ONLY "public"."cpgf_transacoes"
    ADD CONSTRAINT "cpgf_transacoes_ano_mes_cpf_portador_cpf_cnpj_favorecido_tr_key" UNIQUE ("ano_mes", "cpf_portador", "cpf_cnpj_favorecido", "transacao", "valor");

ALTER TABLE ONLY "public"."cpgf_transacoes"
    ADD CONSTRAINT "cpgf_transacoes_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."cptec_cidades"
    ADD CONSTRAINT "cptec_cidades_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."cron_execution_log"
    ADD CONSTRAINT "cron_execution_log_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."cvm_acusados"
    ADD CONSTRAINT "cvm_acusados_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."cvm_carteira_edge"
    ADD CONSTRAINT "cvm_carteira_edge_cnpj_fundo_cnpj_ativo_dt_comptc_key" UNIQUE NULLS NOT DISTINCT ("cnpj_fundo", "cnpj_ativo", "dt_comptc");

ALTER TABLE ONLY "public"."cvm_corretoras"
    ADD CONSTRAINT "cvm_corretoras_pkey" PRIMARY KEY ("cnpj");

ALTER TABLE ONLY "public"."cvm_fip_informe"
    ADD CONSTRAINT "cvm_fip_informe_cnpj_norm_classe_cota_dt_comptc_key" UNIQUE NULLS NOT DISTINCT ("cnpj_norm", "classe_cota", "dt_comptc");

ALTER TABLE ONLY "public"."cvm_fip_participacao"
    ADD CONSTRAINT "cvm_fip_participacao_cnpj_fip_cnpj_empresa_dt_comptc_key" UNIQUE NULLS NOT DISTINCT ("cnpj_fip", "cnpj_empresa", "dt_comptc");

ALTER TABLE ONLY "public"."cvm_fip_saf"
    ADD CONSTRAINT "cvm_fip_saf_pkey" PRIMARY KEY ("cnpj_fip");

ALTER TABLE ONLY "public"."cvm_fundo"
    ADD CONSTRAINT "cvm_fundo_pkey" PRIMARY KEY ("cnpj_norm");

ALTER TABLE ONLY "public"."cvm_fundos"
    ADD CONSTRAINT "cvm_fundos_pkey" PRIMARY KEY ("cnpj");

ALTER TABLE ONLY "public"."cvm_ingest_log"
    ADD CONSTRAINT "cvm_ingest_log_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."cvm_oferta"
    ADD CONSTRAINT "cvm_oferta_id_oferta_cnpj_emissor_tipo_ativo_key" UNIQUE NULLS NOT DISTINCT ("id_oferta", "cnpj_emissor", "tipo_ativo");

ALTER TABLE ONLY "public"."cvm_processos"
    ADD CONSTRAINT "cvm_processos_pkey" PRIMARY KEY ("nup");

ALTER TABLE ONLY "public"."cvm_saf_entidade_relacionada"
    ADD CONSTRAINT "cvm_saf_entidade_relacionada_pkey" PRIMARY KEY ("cnpj_norm");

ALTER TABLE ONLY "public"."cvm_saf"
    ADD CONSTRAINT "cvm_saf_pkey" PRIMARY KEY ("cnpj_norm");

ALTER TABLE ONLY "public"."data_governance_log"
    ADD CONSTRAINT "data_governance_log_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."data_pipeline_logs"
    ADD CONSTRAINT "data_pipeline_logs_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."data_pipeline_status"
    ADD CONSTRAINT "data_pipeline_status_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."data_sources_registry"
    ADD CONSTRAINT "data_sources_registry_pkey" PRIMARY KEY ("source_name");

ALTER TABLE ONLY "public"."declaracao_bens"
    ADD CONSTRAINT "declaracao_bens_parlamentar_id_ano_eleicao_key" UNIQUE ("parlamentar_id", "ano_eleicao");

ALTER TABLE ONLY "public"."declaracao_bens"
    ADD CONSTRAINT "declaracao_bens_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."deputados_brutas"
    ADD CONSTRAINT "deputados_brutas_id_externo_key" UNIQUE ("id_externo");

ALTER TABLE ONLY "public"."deputados_brutas"
    ADD CONSTRAINT "deputados_brutas_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."despesas_gabinete_raw"
    ADD CONSTRAINT "despesas_gabinete_raw_deputado_id_ano_mes_num_documento_tipo_ke" UNIQUE ("deputado_id", "ano", "mes", "num_documento", "tipo_despesa");

ALTER TABLE ONLY "public"."despesas_gabinete_raw"
    ADD CONSTRAINT "despesas_gabinete_raw_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."discursos_camara"
    ADD CONSTRAINT "discursos_camara_parlamentar_id_data_hora_tipo_discurso_key" UNIQUE ("parlamentar_id", "data_hora", "tipo_discurso");

ALTER TABLE ONLY "public"."discursos_camara"
    ADD CONSTRAINT "discursos_camara_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."discursos"
    ADD CONSTRAINT "discursos_id_camara_key" UNIQUE ("id_camara");

ALTER TABLE ONLY "public"."discursos"
    ADD CONSTRAINT "discursos_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."discursos_senado"
    ADD CONSTRAINT "discursos_senado_parlamentar_id_data_hora_tipo_discurso_key" UNIQUE ("parlamentar_id", "data_hora", "tipo_discurso");

ALTER TABLE ONLY "public"."discursos_senado"
    ADD CONSTRAINT "discursos_senado_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."dou_alertas_cruzamento"
    ADD CONSTRAINT "dou_alertas_cruzamento_id_externo_tipo_match_valor_match_key" UNIQUE ("id_externo", "tipo_match", "valor_match");

ALTER TABLE ONLY "public"."dou_alertas_cruzamento"
    ADD CONSTRAINT "dou_alertas_cruzamento_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."dou_publicacoes"
    ADD CONSTRAINT "dou_publicacoes_id_externo_key" UNIQUE ("id_externo");

ALTER TABLE ONLY "public"."dou_publicacoes"
    ADD CONSTRAINT "dou_publicacoes_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."ele2026_alertas"
    ADD CONSTRAINT "ele2026_alertas_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."ele2026_candidatos"
    ADD CONSTRAINT "ele2026_candidatos_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."ele2026_financiamento"
    ADD CONSTRAINT "ele2026_financiamento_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."ele2026_gastos"
    ADD CONSTRAINT "ele2026_gastos_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."ele2026_ingest_log"
    ADD CONSTRAINT "ele2026_ingest_log_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."emendas_api_documentos"
    ADD CONSTRAINT "emendas_api_documentos_emenda_codigo_codigo_documento_key" UNIQUE ("emenda_codigo", "codigo_documento");

ALTER TABLE ONLY "public"."emendas_api_documentos"
    ADD CONSTRAINT "emendas_api_documentos_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."emendas_api_ingest_log"
    ADD CONSTRAINT "emendas_api_ingest_log_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."emendas_api"
    ADD CONSTRAINT "emendas_api_pkey" PRIMARY KEY ("codigo");

ALTER TABLE ONLY "public"."emendas_brutas"
    ADD CONSTRAINT "emendas_brutas_ano_id_externo_key" UNIQUE ("ano", "id_externo");

ALTER TABLE ONLY "public"."emendas_brutas"
    ADD CONSTRAINT "emendas_brutas_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."emendas_coletivas"
    ADD CONSTRAINT "emendas_coletivas_codigo_emenda_key" UNIQUE ("codigo_emenda");

ALTER TABLE ONLY "public"."emendas_coletivas"
    ADD CONSTRAINT "emendas_coletivas_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."emendas_completas"
    ADD CONSTRAINT "emendas_completas_codigo_emenda_ano_key" UNIQUE ("codigo_emenda", "ano");

ALTER TABLE ONLY "public"."emendas_completas"
    ADD CONSTRAINT "emendas_completas_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."emendas_convenios"
    ADD CONSTRAINT "emendas_convenios_pkey" PRIMARY KEY ("numero_convenio");

ALTER TABLE ONLY "public"."emendas_favorecidos"
    ADD CONSTRAINT "emendas_favorecidos_codigo_emenda_ano_mes_pagamento_codigo__key" UNIQUE ("codigo_emenda", "ano_mes_pagamento", "codigo_favorecido", "valor_recebido");

ALTER TABLE ONLY "public"."emendas_favorecidos"
    ADD CONSTRAINT "emendas_favorecidos_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."emendas_financeiro"
    ADD CONSTRAINT "emendas_financeiro_ano_id_externo_key" UNIQUE ("ano", "id_externo");

ALTER TABLE ONLY "public"."emendas_financeiro"
    ADD CONSTRAINT "emendas_financeiro_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."emendas_metricas"
    ADD CONSTRAINT "emendas_metricas_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."emendas"
    ADD CONSTRAINT "emendas_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."emendas_rp9_apoiamento"
    ADD CONSTRAINT "emendas_rp9_apoiamento_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."emendas_transparencia"
    ADD CONSTRAINT "emendas_transparencia_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."estados"
    ADD CONSTRAINT "estados_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."estados"
    ADD CONSTRAINT "estados_sigla_key" UNIQUE ("sigla");

ALTER TABLE ONLY "public"."execucao_financeira_siafi"
    ADD CONSTRAINT "execucao_financeira_siafi_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."execucao_financeira_transferencias"
    ADD CONSTRAINT "execucao_financeira_transferencias_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."execucoes_pipeline_etapas"
    ADD CONSTRAINT "execucoes_pipeline_etapas_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."execucoes_pipeline"
    ADD CONSTRAINT "execucoes_pipeline_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."faf_planos_acao"
    ADD CONSTRAINT "faf_planos_acao_pkey" PRIMARY KEY ("id_plano_acao");

ALTER TABLE ONLY "public"."financiamento_eleitoral"
    ADD CONSTRAINT "financiamento_eleitoral_cpf_candidato_ano_eleicao_sq_receit_key" UNIQUE ("cpf_candidato", "ano_eleicao", "sq_receita");

ALTER TABLE ONLY "public"."financiamento_eleitoral"
    ADD CONSTRAINT "financiamento_eleitoral_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."fipe_tabelas"
    ADD CONSTRAINT "fipe_tabelas_pkey" PRIMARY KEY ("codigo");

ALTER TABLE ONLY "public"."folha_custo_gabinete"
    ADD CONSTRAINT "folha_custo_gabinete_casa_parlamentar_nome_snapshot_date_key" UNIQUE ("casa", "parlamentar_nome", "snapshot_date");

ALTER TABLE ONLY "public"."folha_custo_gabinete"
    ADD CONSTRAINT "folha_custo_gabinete_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."folha_doador_leads"
    ADD CONSTRAINT "folha_doador_leads_casa_parlamentar_id_externo_secretario_n_key" UNIQUE ("casa", "parlamentar_id_externo", "secretario_nome", "ano_eleicao");

ALTER TABLE ONLY "public"."folha_doador_leads"
    ADD CONSTRAINT "folha_doador_leads_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."folha_gabinete"
    ADD CONSTRAINT "folha_gabinete_casa_chave_natural_snapshot_date_key" UNIQUE ("casa", "chave_natural", "snapshot_date");

ALTER TABLE ONLY "public"."folha_gabinete"
    ADD CONSTRAINT "folha_gabinete_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."folha_nepotismo_leads"
    ADD CONSTRAINT "folha_nepotismo_leads_casa_secretario_nome_gabinete_parlame_key" UNIQUE ("casa", "secretario_nome", "gabinete_parlamentar_id", "parlamentar_homonimo_id");

ALTER TABLE ONLY "public"."folha_nepotismo_leads"
    ADD CONSTRAINT "folha_nepotismo_leads_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."fundacoes_embeddings"
    ADD CONSTRAINT "fundacoes_embeddings_cnpj_chunk_type_key" UNIQUE ("cnpj", "chunk_type");

ALTER TABLE ONLY "public"."fundacoes_embeddings"
    ADD CONSTRAINT "fundacoes_embeddings_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."fundacoes_nf_partidos"
    ADD CONSTRAINT "fundacoes_nf_partidos_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."fundacoes_nf_partidos"
    ADD CONSTRAINT "fundacoes_nf_partidos_unique" UNIQUE ("sq_despesa", "aa_exercicio", "cnpj_partido", "nr_documento");

ALTER TABLE ONLY "public"."fundacoes_partidarias"
    ADD CONSTRAINT "fundacoes_partidarias_cnpj_key" UNIQUE ("cnpj");

ALTER TABLE ONLY "public"."fundacoes_partidarias"
    ADD CONSTRAINT "fundacoes_partidarias_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."fundacoes_repasses"
    ADD CONSTRAINT "fundacoes_repasses_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."fundacoes_repasses"
    ADD CONSTRAINT "fundacoes_repasses_sq_despesa_aa_exercicio_key" UNIQUE ("sq_despesa", "aa_exercicio");

ALTER TABLE ONLY "public"."gastos_parlamentares"
    ADD CONSTRAINT "gastos_parlamentares_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."glossario_tech"
    ADD CONSTRAINT "glossario_tech_pkey" PRIMARY KEY ("id", "lang");

ALTER TABLE ONLY "public"."ibama_autuacoes"
    ADD CONSTRAINT "ibama_autuacoes_num_auto_infracao_key" UNIQUE ("num_auto_infracao");

ALTER TABLE ONLY "public"."ibama_autuacoes"
    ADD CONSTRAINT "ibama_autuacoes_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."ibge_indicadores"
    ADD CONSTRAINT "ibge_indicadores_codigo_ibge_pesquisa_id_variavel_id_ano_key" UNIQUE ("codigo_ibge", "pesquisa_id", "variavel_id", "ano");

ALTER TABLE ONLY "public"."ibge_indicadores"
    ADD CONSTRAINT "ibge_indicadores_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."ibge_municipios"
    ADD CONSTRAINT "ibge_municipios_pkey" PRIMARY KEY ("codigo_ibge");

ALTER TABLE ONLY "public"."identity_audit_results"
    ADD CONSTRAINT "identity_audit_results_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."identity_review_queue"
    ADD CONSTRAINT "identity_review_queue_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."impacto_federativo"
    ADD CONSTRAINT "impacto_federativo_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."impacto_federativo"
    ADD CONSTRAINT "impacto_federativo_uf_ano_key" UNIQUE ("uf", "ano");

ALTER TABLE ONLY "public"."indicadores_macroeconomicos"
    ADD CONSTRAINT "indicadores_macroeconomicos_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."indicadores"
    ADD CONSTRAINT "indicadores_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."ingestion_runs"
    ADD CONSTRAINT "ingestion_runs_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."institucional_power_index"
    ADD CONSTRAINT "institucional_power_index_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."institutions"
    ADD CONSTRAINT "institutions_observatorio_id_external_id_key" UNIQUE ("observatorio_id", "external_id");

ALTER TABLE ONLY "public"."institutions"
    ADD CONSTRAINT "institutions_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."intelligence_alerts"
    ADD CONSTRAINT "intelligence_alerts_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."intelligence_notes"
    ADD CONSTRAINT "intelligence_notes_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."intelligence_queue"
    ADD CONSTRAINT "intelligence_queue_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."judiciario_highlights"
    ADD CONSTRAINT "judiciario_highlights_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."judiciario_highlights"
    ADD CONSTRAINT "judiciario_highlights_semana_referencia_posicao_key" UNIQUE ("semana_referencia", "posicao");

ALTER TABLE ONLY "public"."judiciario_processos"
    ADD CONSTRAINT "judiciario_processos_identificador_externo_key" UNIQUE ("identificador_externo");

ALTER TABLE ONLY "public"."judiciario_processos"
    ADD CONSTRAINT "judiciario_processos_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."leiloes_leiloeiros"
    ADD CONSTRAINT "leiloes_leiloeiros_cnpj_basico_cnpj_ordem_cnpj_dv_key" UNIQUE ("cnpj_basico", "cnpj_ordem", "cnpj_dv");

ALTER TABLE ONLY "public"."leiloes_leiloeiros"
    ADD CONSTRAINT "leiloes_leiloeiros_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."leiloes_processos"
    ADD CONSTRAINT "leiloes_processos_numero_processo_tribunal_key" UNIQUE ("numero_processo", "tribunal");

ALTER TABLE ONLY "public"."leiloes_processos"
    ADD CONSTRAINT "leiloes_processos_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."licitacoes_ingest_log"
    ADD CONSTRAINT "licitacoes_ingest_log_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."licitacoes"
    ADD CONSTRAINT "licitacoes_numero_controle_pncp_key" UNIQUE ("numero_controle_pncp");

ALTER TABLE ONLY "public"."licitacoes_participantes"
    ADD CONSTRAINT "licitacoes_participantes_licitacao_id_cnpj_cpf_key" UNIQUE ("licitacao_id", "cnpj", "cpf");

ALTER TABLE ONLY "public"."licitacoes_participantes"
    ADD CONSTRAINT "licitacoes_participantes_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."licitacoes"
    ADD CONSTRAINT "licitacoes_pkey" PRIMARY KEY ("numero_controle_pncp");

ALTER TABLE ONLY "public"."mandatos"
    ADD CONSTRAINT "mandatos_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."media_briefings"
    ADD CONSTRAINT "media_briefings_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."mg_compras_fornecedor"
    ADD CONSTRAINT "mg_compras_fornecedor_cnpj_norm_ano_key" UNIQUE NULLS NOT DISTINCT ("cnpj_norm", "ano");

ALTER TABLE ONLY "public"."mg_compras_fornecedor"
    ADD CONSTRAINT "mg_compras_fornecedor_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."mg_contratos"
    ADD CONSTRAINT "mg_contratos_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."mg_convenios"
    ADD CONSTRAINT "mg_convenios_convenio_id_ano_key" UNIQUE NULLS NOT DISTINCT ("convenio_id", "ano");

ALTER TABLE ONLY "public"."mg_convenios_entrada"
    ADD CONSTRAINT "mg_convenios_entrada_id_convenio_key" UNIQUE NULLS NOT DISTINCT ("id_convenio");

ALTER TABLE ONLY "public"."mg_convenios_entrada"
    ADD CONSTRAINT "mg_convenios_entrada_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."mg_convenios"
    ADD CONSTRAINT "mg_convenios_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."mg_covid_compras"
    ADD CONSTRAINT "mg_covid_compras_numero_processo_item_cnpj_norm_valor_homol_key" UNIQUE NULLS NOT DISTINCT ("numero_processo", "item", "cnpj_norm", "valor_homologado");

ALTER TABLE ONLY "public"."mg_covid_compras"
    ADD CONSTRAINT "mg_covid_compras_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."mg_despesa_pessoal_vale"
    ADD CONSTRAINT "mg_despesa_pessoal_vale_ano_mes_masp_cargo_sigla_key" UNIQUE NULLS NOT DISTINCT ("ano_mes", "masp", "cargo_sigla");

ALTER TABLE ONLY "public"."mg_despesa_pessoal_vale"
    ADD CONSTRAINT "mg_despesa_pessoal_vale_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."mg_diarias_orgao"
    ADD CONSTRAINT "mg_diarias_orgao_ano_cd_unidade_orc_key" UNIQUE NULLS NOT DISTINCT ("ano", "cd_unidade_orc");

ALTER TABLE ONLY "public"."mg_diarias_orgao"
    ADD CONSTRAINT "mg_diarias_orgao_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."mg_divida_tipo"
    ADD CONSTRAINT "mg_divida_tipo_ano_cd_tipo_key" UNIQUE NULLS NOT DISTINCT ("ano", "cd_tipo");

ALTER TABLE ONLY "public"."mg_divida_tipo"
    ADD CONSTRAINT "mg_divida_tipo_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."mg_doacoes"
    ADD CONSTRAINT "mg_doacoes_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."mg_emendas_estaduais"
    ADD CONSTRAINT "mg_emendas_estaduais_id_emenda_key" UNIQUE NULLS NOT DISTINCT ("id_emenda");

ALTER TABLE ONLY "public"."mg_emendas_estaduais"
    ADD CONSTRAINT "mg_emendas_estaduais_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."mg_emendas_federais"
    ADD CONSTRAINT "mg_emendas_federais_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."mg_emendas_pix"
    ADD CONSTRAINT "mg_emendas_pix_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."mg_empenhos"
    ADD CONSTRAINT "mg_empenhos_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."mg_empenhos_sancionados"
    ADD CONSTRAINT "mg_empenhos_sancionados_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."mg_empresas_sancionadas"
    ADD CONSTRAINT "mg_empresas_sancionadas_cnpj_norm_sei_key" UNIQUE NULLS NOT DISTINCT ("cnpj_norm", "sei");

ALTER TABLE ONLY "public"."mg_empresas_sancionadas"
    ADD CONSTRAINT "mg_empresas_sancionadas_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."mg_ingest_log"
    ADD CONSTRAINT "mg_ingest_log_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."mg_ipsemg_contratos"
    ADD CONSTRAINT "mg_ipsemg_contratos_num_contrato_cnpj_norm_inicio_vigencia_key" UNIQUE NULLS NOT DISTINCT ("num_contrato", "cnpj_norm", "inicio_vigencia");

ALTER TABLE ONLY "public"."mg_ipsemg_contratos"
    ADD CONSTRAINT "mg_ipsemg_contratos_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."mg_licitacao_sobrepreco"
    ADD CONSTRAINT "mg_licitacao_sobrepreco_ano_numero_processo_numero_item_key" UNIQUE NULLS NOT DISTINCT ("ano", "numero_processo", "numero_item");

ALTER TABLE ONLY "public"."mg_licitacao_sobrepreco"
    ADD CONSTRAINT "mg_licitacao_sobrepreco_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."mg_lrf_limites"
    ADD CONSTRAINT "mg_lrf_limites_periodo_key" UNIQUE ("periodo");

ALTER TABLE ONLY "public"."mg_lrf_limites"
    ADD CONSTRAINT "mg_lrf_limites_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."mg_lrf_pessoal"
    ADD CONSTRAINT "mg_lrf_pessoal_mes_ano_key" UNIQUE ("mes_ano");

ALTER TABLE ONLY "public"."mg_lrf_pessoal"
    ADD CONSTRAINT "mg_lrf_pessoal_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."mg_notas_fornecedor"
    ADD CONSTRAINT "mg_notas_fornecedor_cnpj_norm_ano_key" UNIQUE NULLS NOT DISTINCT ("cnpj_norm", "ano");

ALTER TABLE ONLY "public"."mg_notas_fornecedor"
    ADD CONSTRAINT "mg_notas_fornecedor_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."mg_obras"
    ADD CONSTRAINT "mg_obras_contrato_cnpj_norm_key" UNIQUE NULLS NOT DISTINCT ("contrato", "cnpj_norm");

ALTER TABLE ONLY "public"."mg_obras"
    ADD CONSTRAINT "mg_obras_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."mg_os_parcerias"
    ADD CONSTRAINT "mg_os_parcerias_id_instrumento_key" UNIQUE NULLS NOT DISTINCT ("id_instrumento");

ALTER TABLE ONLY "public"."mg_os_parcerias"
    ADD CONSTRAINT "mg_os_parcerias_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."mg_remuneracao"
    ADD CONSTRAINT "mg_remuneracao_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."mg_remuneracao"
    ADD CONSTRAINT "mg_remuneracao_snapshot_mes_orgao_servidor_nome_cargo_remun_key" UNIQUE ("snapshot_mes", "orgao", "servidor_nome", "cargo", "remuneracao_base");

ALTER TABLE ONLY "public"."mg_reparacao_vale"
    ADD CONSTRAINT "mg_reparacao_vale_codigo_iniciativa_key" UNIQUE NULLS NOT DISTINCT ("codigo_iniciativa");

ALTER TABLE ONLY "public"."mg_reparacao_vale"
    ADD CONSTRAINT "mg_reparacao_vale_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."mg_restos_orgao"
    ADD CONSTRAINT "mg_restos_orgao_ano_cd_unidade_orc_key" UNIQUE NULLS NOT DISTINCT ("ano", "cd_unidade_orc");

ALTER TABLE ONLY "public"."mg_restos_orgao"
    ADD CONSTRAINT "mg_restos_orgao_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."mg_siafi_execucao"
    ADD CONSTRAINT "mg_siafi_execucao_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."mg_terceirizados"
    ADD CONSTRAINT "mg_terceirizados_cnpj_norm_orgao_mes_referencia_key" UNIQUE NULLS NOT DISTINCT ("cnpj_norm", "orgao", "mes_referencia");

ALTER TABLE ONLY "public"."mg_terceirizados"
    ADD CONSTRAINT "mg_terceirizados_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."mg_voos_governador"
    ADD CONSTRAINT "mg_voos_governador_numero_db_passageiro_destino_key" UNIQUE NULLS NOT DISTINCT ("numero_db", "passageiro", "destino");

ALTER TABLE ONLY "public"."mg_voos_governador"
    ADD CONSTRAINT "mg_voos_governador_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."midia_eventos"
    ADD CONSTRAINT "midia_eventos_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."midia_eventos"
    ADD CONSTRAINT "midia_eventos_slug_key" UNIQUE ("slug");

ALTER TABLE ONLY "public"."midia_inter_meios"
    ADD CONSTRAINT "midia_inter_meios_ano_categoria_key" UNIQUE ("ano", "categoria");

ALTER TABLE ONLY "public"."midia_inter_meios"
    ADD CONSTRAINT "midia_inter_meios_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."midia_kantar_releases"
    ADD CONSTRAINT "midia_kantar_releases_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."midia_kantar_releases"
    ADD CONSTRAINT "midia_kantar_releases_semana_inicio_programa_praca_veiculo__key" UNIQUE ("semana_inicio", "programa", "praca", "veiculo_id");

ALTER TABLE ONLY "public"."midia_secom_verbas"
    ADD CONSTRAINT "midia_secom_verbas_cnpj_ano_mes_orgao_codigo_key" UNIQUE ("cnpj", "ano", "mes", "orgao_codigo");

ALTER TABLE ONLY "public"."midia_secom_verbas"
    ADD CONSTRAINT "midia_secom_verbas_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."midia_veiculos"
    ADD CONSTRAINT "midia_veiculos_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."midia_veiculos"
    ADD CONSTRAINT "midia_veiculos_slug_key" UNIQUE ("slug");

ALTER TABLE ONLY "public"."midia_youtube_eventos"
    ADD CONSTRAINT "midia_youtube_eventos_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."midia_youtube_eventos"
    ADD CONSTRAINT "midia_youtube_eventos_youtube_channel_id_evento_id_data_col_key" UNIQUE ("youtube_channel_id", "evento_id", "data_coleta");

ALTER TABLE ONLY "public"."ministerios"
    ADD CONSTRAINT "ministerios_nome_key" UNIQUE ("nome");

ALTER TABLE ONLY "public"."ministerios"
    ADD CONSTRAINT "ministerios_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."municipios_ibge"
    ADD CONSTRAINT "municipios_ibge_pkey" PRIMARY KEY ("codigo_ibge");

ALTER TABLE ONLY "public"."municipios"
    ADD CONSTRAINT "municipios_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."narrativas"
    ADD CONSTRAINT "narrativas_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."narrative_events"
    ADD CONSTRAINT "narrative_events_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."ncm"
    ADD CONSTRAINT "ncm_pkey" PRIMARY KEY ("codigo");

ALTER TABLE ONLY "public"."newsletter_sends"
    ADD CONSTRAINT "newsletter_sends_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."newsletter_subscribers"
    ADD CONSTRAINT "newsletter_subscribers_email_key" UNIQUE ("email");

ALTER TABLE ONLY "public"."newsletter_subscribers"
    ADD CONSTRAINT "newsletter_subscribers_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."notas_fiscais_ingest_log"
    ADD CONSTRAINT "notas_fiscais_ingest_log_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."notas_fiscais"
    ADD CONSTRAINT "notas_fiscais_pkey" PRIMARY KEY ("chave");

ALTER TABLE ONLY "public"."noticias"
    ADD CONSTRAINT "noticias_pkey" PRIMARY KEY ("slug");

ALTER TABLE ONLY "public"."observatorios"
    ADD CONSTRAINT "observatorios_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."orgaos_federais"
    ADD CONSTRAINT "orgaos_federais_nome_key" UNIQUE ("nome");

ALTER TABLE ONLY "public"."orgaos_federais"
    ADD CONSTRAINT "orgaos_federais_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."parlamentar_contratos_cache"
    ADD CONSTRAINT "parlamentar_contratos_cache_parlamentar_id_key" UNIQUE ("parlamentar_id");

ALTER TABLE ONLY "public"."parlamentar_contratos_cache"
    ADD CONSTRAINT "parlamentar_contratos_cache_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."parlamentar_financiamento_cache"
    ADD CONSTRAINT "parlamentar_financiamento_cache_parlamentar_id_key" UNIQUE ("parlamentar_id");

ALTER TABLE ONLY "public"."parlamentar_financiamento_cache"
    ADD CONSTRAINT "parlamentar_financiamento_cache_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."parlamentar_identidade"
    ADD CONSTRAINT "parlamentar_identidade_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."parlamentar_identity_map"
    ADD CONSTRAINT "parlamentar_identity_map_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."parlamentar_inteligencia"
    ADD CONSTRAINT "parlamentar_inteligencia_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."parlamentar_sancoes_cache"
    ADD CONSTRAINT "parlamentar_sancoes_cache_parlamentar_id_key" UNIQUE ("parlamentar_id");

ALTER TABLE ONLY "public"."parlamentar_sancoes_cache"
    ADD CONSTRAINT "parlamentar_sancoes_cache_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."parlamentares"
    ADD CONSTRAINT "parlamentar_uid_unique" UNIQUE ("parlamentar_uid");

ALTER TABLE ONLY "public"."parlamentares_estaduais"
    ADD CONSTRAINT "parlamentares_estaduais_casa_id_id_externo_key" UNIQUE ("casa_id", "id_externo");

ALTER TABLE ONLY "public"."parlamentares_estaduais"
    ADD CONSTRAINT "parlamentares_estaduais_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."parlamentares"
    ADD CONSTRAINT "parlamentares_id_camara_key" UNIQUE ("id_camara");

ALTER TABLE ONLY "public"."parlamentares"
    ADD CONSTRAINT "parlamentares_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."patrimonio_tse"
    ADD CONSTRAINT "patrimonio_tse_cpf_ano_eleicao_nr_ordem_key" UNIQUE ("cpf", "ano_eleicao", "nr_ordem");

ALTER TABLE ONLY "public"."patrimonio_tse"
    ADD CONSTRAINT "patrimonio_tse_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."pbh_despesas_orcamentarias"
    ADD CONSTRAINT "pbh_despesas_orcamentarias_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."peps"
    ADD CONSTRAINT "peps_cpf_orgao_codigo_data_inicio_exercicio_key" UNIQUE ("cpf", "orgao_codigo", "data_inicio_exercicio");

ALTER TABLE ONLY "public"."peps_ingest_log"
    ADD CONSTRAINT "peps_ingest_log_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."peps"
    ADD CONSTRAINT "peps_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."pgfn_divida_ativa"
    ADD CONSTRAINT "pgfn_divida_ativa_numero_inscricao_ciclo_key" UNIQUE ("numero_inscricao", "ciclo");

ALTER TABLE ONLY "public"."pgfn_divida_ativa"
    ADD CONSTRAINT "pgfn_divida_ativa_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."pgfn_divida_federacoes"
    ADD CONSTRAINT "pgfn_divida_federacoes_cnpj_tipo_arquivo_trimestre_key" UNIQUE ("cnpj", "tipo_arquivo", "trimestre");

ALTER TABLE ONLY "public"."pgfn_divida_federacoes"
    ADD CONSTRAINT "pgfn_divida_federacoes_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."pix_participantes"
    ADD CONSTRAINT "pix_participantes_pkey" PRIMARY KEY ("ispb");

ALTER TABLE ONLY "public"."plen_deputado_agg"
    ADD CONSTRAINT "plen_deputado_agg_deputado_id_id_legislatura_key" UNIQUE ("deputado_id", "id_legislatura");

ALTER TABLE ONLY "public"."plen_deputado_agg"
    ADD CONSTRAINT "plen_deputado_agg_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."plen_orientacoes"
    ADD CONSTRAINT "plen_orientacoes_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."plen_orientacoes"
    ADD CONSTRAINT "plen_orientacoes_votacao_id_sigla_bancada_key" UNIQUE ("votacao_id", "sigla_bancada");

ALTER TABLE ONLY "public"."plen_votacoes"
    ADD CONSTRAINT "plen_votacoes_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."plen_votos"
    ADD CONSTRAINT "plen_votos_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."plen_votos"
    ADD CONSTRAINT "plen_votos_votacao_id_deputado_id_key" UNIQUE ("votacao_id", "deputado_id");

ALTER TABLE ONLY "public"."pncp_licitacoes"
    ADD CONSTRAINT "pncp_licitacoes_pkey" PRIMARY KEY ("numero_controle_pncp");

ALTER TABLE ONLY "public"."pncp_publicidade"
    ADD CONSTRAINT "pncp_publicidade_pkey" PRIMARY KEY ("numero_controle_pncp");

ALTER TABLE ONLY "public"."pncp_resultados"
    ADD CONSTRAINT "pncp_resultados_pkey" PRIMARY KEY ("id_compra_item", "sequencial_resultado");

ALTER TABLE ONLY "public"."political_intelligence_feed"
    ADD CONSTRAINT "political_intelligence_feed_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."portal_sancionados"
    ADD CONSTRAINT "portal_sancionados_dedup" UNIQUE NULLS NOT DISTINCT ("cpf_cnpj", "tipo_registro", "tipo_sancao", "data_inicio");

ALTER TABLE ONLY "public"."portal_sancionados"
    ADD CONSTRAINT "portal_sancionados_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."pr_ex_presidentes_custos"
    ADD CONSTRAINT "pr_ex_presidentes_custos_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."pr_ingest_log"
    ADD CONSTRAINT "pr_ingest_log_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."pr_pessoal_diversidade"
    ADD CONSTRAINT "pr_pessoal_diversidade_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."presencas"
    ADD CONSTRAINT "presencas_parlamentar_data_unique" UNIQUE ("parlamentar_id", "data_sessao");

ALTER TABLE ONLY "public"."presencas"
    ADD CONSTRAINT "presencas_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."public_reports"
    ADD CONSTRAINT "public_reports_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."ranking_cache"
    ADD CONSTRAINT "ranking_cache_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."ranking_parlamentar_build"
    ADD CONSTRAINT "ranking_parlamentar_build_build_id_parlamentar_id_ano_key" UNIQUE ("build_id", "parlamentar_id", "ano");

ALTER TABLE ONLY "public"."ranking_parlamentar_build"
    ADD CONSTRAINT "ranking_parlamentar_build_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."ranking_parlamentar"
    ADD CONSTRAINT "ranking_parlamentar_pkey" PRIMARY KEY ("parlamentar_id", "ano");

ALTER TABLE ONLY "public"."rs_despesas"
    ADD CONSTRAINT "rs_despesas_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."rs_ingest_log"
    ADD CONSTRAINT "rs_ingest_log_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sancoes_ingest_log"
    ADD CONSTRAINT "sancoes_ingest_log_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sancoes"
    ADD CONSTRAINT "sancoes_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."scores"
    ADD CONSTRAINT "scores_institution_id_dimensao_key" UNIQUE ("institution_id", "dimensao");

ALTER TABLE ONLY "public"."scores"
    ADD CONSTRAINT "scores_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sebrae_contratos"
    ADD CONSTRAINT "sebrae_contratos_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sebrae_contratos"
    ADD CONSTRAINT "sebrae_contratos_uf_numero_contrato_key" UNIQUE ("uf", "numero_contrato");

ALTER TABLE ONLY "public"."sebrae_convenios"
    ADD CONSTRAINT "sebrae_convenios_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sebrae_convenios"
    ADD CONSTRAINT "sebrae_convenios_uf_numero_convenio_key" UNIQUE ("uf", "numero_convenio");

ALTER TABLE ONLY "public"."sebrae_emendas_contratos"
    ADD CONSTRAINT "sebrae_emendas_contratos_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sebrae_emendas_contratos"
    ADD CONSTRAINT "sebrae_emendas_contratos_uf_numero_contrato_key" UNIQUE ("uf", "numero_contrato");

ALTER TABLE ONLY "public"."sebrae_emendas_convenios"
    ADD CONSTRAINT "sebrae_emendas_convenios_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sebrae_emendas_convenios"
    ADD CONSTRAINT "sebrae_emendas_convenios_uf_numero_convenio_key" UNIQUE ("uf", "numero_convenio");

ALTER TABLE ONLY "public"."sebrae_licitacoes"
    ADD CONSTRAINT "sebrae_licitacoes_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sebrae_licitacoes"
    ADD CONSTRAINT "sebrae_licitacoes_uf_numero_licitacao_key" UNIQUE ("uf", "numero_licitacao");

ALTER TABLE ONLY "public"."sebrae_patrocinios"
    ADD CONSTRAINT "sebrae_patrocinios_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sebrae_patrocinios"
    ADD CONSTRAINT "sebrae_patrocinios_uf_numero_contrato_key" UNIQUE ("uf", "numero_contrato");

ALTER TABLE ONLY "public"."sen_parlamentar_risco"
    ADD CONSTRAINT "sen_parlamentar_risco_pkey" PRIMARY KEY ("senador_codigo");

ALTER TABLE ONLY "public"."sen_proposicoes"
    ADD CONSTRAINT "sen_proposicoes_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sen_proposicoes"
    ADD CONSTRAINT "sen_proposicoes_senador_codigo_sigla_materia_numero_ano_key" UNIQUE ("senador_codigo", "sigla_materia", "numero", "ano");

ALTER TABLE ONLY "public"."sen_senadores"
    ADD CONSTRAINT "sen_senadores_pkey" PRIMARY KEY ("codigo");

ALTER TABLE ONLY "public"."senac_contratos"
    ADD CONSTRAINT "senac_contratos_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."senac_contratos"
    ADD CONSTRAINT "senac_contratos_regional_numero_key" UNIQUE ("regional", "numero");

ALTER TABLE ONLY "public"."senac_licitacoes"
    ADD CONSTRAINT "senac_licitacoes_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."senac_licitacoes"
    ADD CONSTRAINT "senac_licitacoes_regional_licitacao_id_key" UNIQUE ("regional", "licitacao_id");

ALTER TABLE ONLY "public"."senado_ceaps_despesa"
    ADD CONSTRAINT "senado_ceaps_despesa_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."senado_orientacao"
    ADD CONSTRAINT "senado_orientacao_pkey" PRIMARY KEY ("id_sve", "sigla_partido");

ALTER TABLE ONLY "public"."senado_votacao"
    ADD CONSTRAINT "senado_votacao_pkey" PRIMARY KEY ("id_sve");

ALTER TABLE ONLY "public"."senado_voto"
    ADD CONSTRAINT "senado_voto_pkey" PRIMARY KEY ("id_sve", "cod_parlamentar");

ALTER TABLE ONLY "public"."senadores_brutas"
    ADD CONSTRAINT "senadores_brutas_id_externo_key" UNIQUE ("id_externo");

ALTER TABLE ONLY "public"."senadores_brutas"
    ADD CONSTRAINT "senadores_brutas_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."senar_contratos"
    ADD CONSTRAINT "senar_contratos_periodo_id_numero_contrato_key" UNIQUE ("periodo_id", "numero_contrato");

ALTER TABLE ONLY "public"."senar_contratos"
    ADD CONSTRAINT "senar_contratos_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."senar_licitacoes"
    ADD CONSTRAINT "senar_licitacoes_ano_numero_ano_key" UNIQUE ("ano", "numero_ano");

ALTER TABLE ONLY "public"."senar_licitacoes"
    ADD CONSTRAINT "senar_licitacoes_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."senar_transferencias"
    ADD CONSTRAINT "senar_transferencias_periodo_id_tipo_cnpj_data_firmamento_v_key" UNIQUE ("periodo_id", "tipo", "cnpj", "data_firmamento", "valor_pactuado");

ALTER TABLE ONLY "public"."senar_transferencias"
    ADD CONSTRAINT "senar_transferencias_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sesc_contratos"
    ADD CONSTRAINT "sesc_contratos_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sesc_contratos"
    ADD CONSTRAINT "sesc_contratos_portal_exercicio_numero_contrato_key" UNIQUE ("portal", "exercicio", "numero_contrato");

ALTER TABLE ONLY "public"."sesc_convenios"
    ADD CONSTRAINT "sesc_convenios_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sesc_convenios"
    ADD CONSTRAINT "sesc_convenios_portal_exercicio_numero_convenio_key" UNIQUE ("portal", "exercicio", "numero_convenio");

ALTER TABLE ONLY "public"."siafi_empenho"
    ADD CONSTRAINT "siafi_empenho_pkey" PRIMARY KEY ("id_empenho");

ALTER TABLE ONLY "public"."siafi_execucao_mensal"
    ADD CONSTRAINT "siafi_execucao_mensal_pkey" PRIMARY KEY ("competencia", "cod_ug", "cod_programa_orcamentario", "cod_acao", "cod_plano_orcamentario", "cod_elemento_despesa", "cod_modalidade_despesa", "cod_autor_emenda", "cod_subtitulo");

ALTER TABLE ONLY "public"."siafi_fornecedor"
    ADD CONSTRAINT "siafi_fornecedor_pkey" PRIMARY KEY ("cnpj_cpf");

ALTER TABLE ONLY "public"."siafi_ingestao_log"
    ADD CONSTRAINT "siafi_ingestao_log_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."siafi_item_empenho"
    ADD CONSTRAINT "siafi_item_empenho_pkey" PRIMARY KEY ("id_empenho", "sequencial");

ALTER TABLE ONLY "public"."siafi_liquidacao"
    ADD CONSTRAINT "siafi_liquidacao_pkey" PRIMARY KEY ("codigo_liquidacao");

ALTER TABLE ONLY "public"."siafi_pagamento_empenho"
    ADD CONSTRAINT "siafi_pagamento_empenho_pkey" PRIMARY KEY ("codigo_pagamento", "codigo_empenho", "subitem");

ALTER TABLE ONLY "public"."siafi_pagamento_favorecido_final"
    ADD CONSTRAINT "siafi_pagamento_favorecido_final_pkey" PRIMARY KEY ("codigo_pagamento", "codigo_lista", "cnpj_favorecido_final");

ALTER TABLE ONLY "public"."siafi_pagamento"
    ADD CONSTRAINT "siafi_pagamento_pkey" PRIMARY KEY ("codigo_pagamento");

ALTER TABLE ONLY "public"."sisi_contratos"
    ADD CONSTRAINT "sisi_contratos_entidade_departamento_codigo_contrato_key" UNIQUE ("entidade", "departamento", "codigo_contrato");

ALTER TABLE ONLY "public"."sisi_contratos"
    ADD CONSTRAINT "sisi_contratos_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sisi_convenios"
    ADD CONSTRAINT "sisi_convenios_entidade_departamento_codigo_convenio_key" UNIQUE ("entidade", "departamento", "codigo_convenio");

ALTER TABLE ONLY "public"."sisi_convenios"
    ADD CONSTRAINT "sisi_convenios_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sisi_licitacoes"
    ADD CONSTRAINT "sisi_licitacoes_entidade_departamento_codigo_licitacao_key" UNIQUE ("entidade", "departamento", "codigo_licitacao");

ALTER TABLE ONLY "public"."sisi_licitacoes_participantes"
    ADD CONSTRAINT "sisi_licitacoes_participantes_entidade_departamento_licitac_key" UNIQUE ("entidade", "departamento", "licitacao_codigo", "cnpj_cpf");

ALTER TABLE ONLY "public"."sisi_licitacoes_participantes"
    ADD CONSTRAINT "sisi_licitacoes_participantes_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sisi_licitacoes"
    ADD CONSTRAINT "sisi_licitacoes_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."snapshots_ranking"
    ADD CONSTRAINT "snapshots_ranking_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sobrenome_blocklist"
    ADD CONSTRAINT "sobrenome_blocklist_pkey" PRIMARY KEY ("sobrenome");

ALTER TABLE ONLY "public"."sp_contratos"
    ADD CONSTRAINT "sp_contratos_numero_contrato_cnpj_contratado_orgao_key" UNIQUE ("numero_contrato", "cnpj_contratado", "orgao");

ALTER TABLE ONLY "public"."sp_contratos"
    ADD CONSTRAINT "sp_contratos_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sp_despesas"
    ADD CONSTRAINT "sp_despesas_empenho_ano_uq" UNIQUE ("ano", "numero_empenho", "cod_credor", "cod_item");

ALTER TABLE ONLY "public"."sp_despesas"
    ADD CONSTRAINT "sp_despesas_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."stf_assinaturas"
    ADD CONSTRAINT "stf_assinaturas_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."stf_assinaturas"
    ADD CONSTRAINT "stf_assinaturas_stripe_customer_id_key" UNIQUE ("stripe_customer_id");

ALTER TABLE ONLY "public"."stf_assinaturas"
    ADD CONSTRAINT "stf_assinaturas_stripe_sub_id_key" UNIQUE ("stripe_sub_id");

ALTER TABLE ONLY "public"."stf_gastos"
    ADD CONSTRAINT "stf_gastos_ministro_ano_mes_categoria_descricao_key" UNIQUE ("ministro_id", "ano", "mes", "categoria", "descricao");

ALTER TABLE ONLY "public"."stf_gastos"
    ADD CONSTRAINT "stf_gastos_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."stf_ingestao_log"
    ADD CONSTRAINT "stf_ingestao_log_dataset_arquivo_hash_key" UNIQUE ("dataset", "arquivo_hash");

ALTER TABLE ONLY "public"."stf_ingestao_log"
    ADD CONSTRAINT "stf_ingestao_log_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."stf_ministros"
    ADD CONSTRAINT "stf_ministros_iniciais_key" UNIQUE ("iniciais");

ALTER TABLE ONLY "public"."stf_ministros"
    ADD CONSTRAINT "stf_ministros_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."stf_processos_politicos"
    ADD CONSTRAINT "stf_processos_politicos_numero_classe_key" UNIQUE ("numero", "classe");

ALTER TABLE ONLY "public"."stf_processos_politicos"
    ADD CONSTRAINT "stf_processos_politicos_numero_key" UNIQUE ("numero");

ALTER TABLE ONLY "public"."stf_processos_politicos"
    ADD CONSTRAINT "stf_processos_politicos_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."stf_repercussao_geral"
    ADD CONSTRAINT "stf_repercussao_geral_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."stf_repercussao_geral"
    ADD CONSTRAINT "stf_repercussao_geral_tema_key" UNIQUE ("tema");

ALTER TABLE ONLY "public"."stf_votacoes"
    ADD CONSTRAINT "stf_votacoes_ministro_processo_data_key" UNIQUE ("ministro_id", "processo", "data");

ALTER TABLE ONLY "public"."stf_votacoes"
    ADD CONSTRAINT "stf_votacoes_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sub_alertas"
    ADD CONSTRAINT "sub_alertas_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sub_aneel_autos"
    ADD CONSTRAINT "sub_aneel_autos_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sub_ans_operadoras"
    ADD CONSTRAINT "sub_ans_operadoras_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sub_ceis"
    ADD CONSTRAINT "sub_ceis_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sub_cepim"
    ADD CONSTRAINT "sub_cepim_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sub_clientes"
    ADD CONSTRAINT "sub_clientes_acesso_token_key" UNIQUE ("acesso_token");

ALTER TABLE ONLY "public"."sub_clientes"
    ADD CONSTRAINT "sub_clientes_email_key" UNIQUE ("email");

ALTER TABLE ONLY "public"."sub_clientes"
    ADD CONSTRAINT "sub_clientes_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sub_cnep"
    ADD CONSTRAINT "sub_cnep_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sub_cnpjs_monitorados"
    ADD CONSTRAINT "sub_cnpjs_monitorados_cliente_id_cnpj_key" UNIQUE ("cliente_id", "cnpj");

ALTER TABLE ONLY "public"."sub_cnpjs_monitorados"
    ADD CONSTRAINT "sub_cnpjs_monitorados_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sub_cvm_pas"
    ADD CONSTRAINT "sub_cvm_pas_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sub_dossies"
    ADD CONSTRAINT "sub_dossies_cliente_id_cnpj_ciclo_key" UNIQUE ("cliente_id", "cnpj", "ciclo");

ALTER TABLE ONLY "public"."sub_dossies"
    ADD CONSTRAINT "sub_dossies_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sub_envios"
    ADD CONSTRAINT "sub_envios_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sub_ibama"
    ADD CONSTRAINT "sub_ibama_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sub_lista_suja"
    ADD CONSTRAINT "sub_lista_suja_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sub_mte_autos"
    ADD CONSTRAINT "sub_mte_autos_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sub_pf_consultas"
    ADD CONSTRAINT "sub_pf_consultas_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sub_pf_consultas"
    ADD CONSTRAINT "sub_pf_consultas_session_id_key" UNIQUE ("session_id");

ALTER TABLE ONLY "public"."sub_snapshots"
    ADD CONSTRAINT "sub_snapshots_cnpj_ciclo_fonte_key" UNIQUE ("cnpj", "ciclo", "fonte");

ALTER TABLE ONLY "public"."sub_snapshots"
    ADD CONSTRAINT "sub_snapshots_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_email_key" UNIQUE ("email");

ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sync_jobs"
    ADD CONSTRAINT "sync_jobs_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."sync_progress"
    ADD CONSTRAINT "sync_progress_pkey" PRIMARY KEY ("ano");

ALTER TABLE ONLY "public"."system_state"
    ADD CONSTRAINT "system_state_pkey" PRIMARY KEY ("key");

ALTER TABLE ONLY "public"."ted_planos_acao"
    ADD CONSTRAINT "ted_planos_acao_pkey" PRIMARY KEY ("id_plano_acao");

ALTER TABLE ONLY "public"."ted_termos_execucao"
    ADD CONSTRAINT "ted_termos_execucao_pkey" PRIMARY KEY ("id_termo");

ALTER TABLE ONLY "public"."timeline_events"
    ADD CONSTRAINT "timeline_events_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."tribunais"
    ADD CONSTRAINT "tribunais_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."tribunais"
    ADD CONSTRAINT "tribunais_sigla_key" UNIQUE ("sigla");

ALTER TABLE ONLY "public"."tse_bens_agg"
    ADD CONSTRAINT "tse_bens_agg_pkey" PRIMARY KEY ("sq_candidato", "ano_eleicao");

ALTER TABLE ONLY "public"."tse_bens_candidatos"
    ADD CONSTRAINT "tse_bens_candidatos_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."tse_bens_candidatos"
    ADD CONSTRAINT "tse_bens_candidatos_sq_candidato_ano_eleicao_nr_ordem_key" UNIQUE ("sq_candidato", "ano_eleicao", "nr_ordem");

ALTER TABLE ONLY "public"."tse_candidatos"
    ADD CONSTRAINT "tse_candidatos_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."tse_candidatos_receitas_agg"
    ADD CONSTRAINT "tse_candidatos_receitas_agg_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."tse_candidatos_receitas_agg"
    ADD CONSTRAINT "tse_candidatos_receitas_agg_sq_candidato_ano_eleicao_key" UNIQUE ("sq_candidato", "ano_eleicao");

ALTER TABLE ONLY "public"."tse_conta_despesa"
    ADD CONSTRAINT "tse_conta_despesa_pkey" PRIMARY KEY ("id_hash");

ALTER TABLE ONLY "public"."tse_conta_extrato"
    ADD CONSTRAINT "tse_conta_extrato_pkey" PRIMARY KEY ("id_hash");

ALTER TABLE ONLY "public"."tse_conta_notafiscal"
    ADD CONSTRAINT "tse_conta_notafiscal_pkey" PRIMARY KEY ("id_hash");

ALTER TABLE ONLY "public"."tse_conta_receita"
    ADD CONSTRAINT "tse_conta_receita_pkey" PRIMARY KEY ("id_hash");

ALTER TABLE ONLY "public"."tse_despesas"
    ADD CONSTRAINT "tse_despesas_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."tse_ingest_log"
    ADD CONSTRAINT "tse_ingest_log_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."tse_receitas_brutas"
    ADD CONSTRAINT "tse_receitas_brutas_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."tse_receitas_brutas"
    ADD CONSTRAINT "tse_receitas_brutas_sq_receita_ano_eleicao_key" UNIQUE ("sq_receita", "ano_eleicao");

ALTER TABLE ONLY "public"."tse_receitas"
    ADD CONSTRAINT "tse_receitas_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."tuss_procedimentos"
    ADD CONSTRAINT "tuss_procedimentos_pkey" PRIMARY KEY ("codigo");

ALTER TABLE ONLY "public"."gastos_parlamentares"
    ADD CONSTRAINT "uq_gastos_parlamentares_nota" UNIQUE ("parlamentar_id", "ano", "mes", "num_documento", "cnpj_cpf", "categoria", "valor_bruto");

ALTER TABLE ONLY "public"."mg_empresas_sancionadas"
    ADD CONSTRAINT "uq_mg_sancionadas_sei" UNIQUE ("sei");

ALTER TABLE ONLY "public"."emendas_rp9_apoiamento"
    ADD CONSTRAINT "uq_rp9_apoiamento" UNIQUE ("numero_emenda", "codigo_apoiador", "cnpj_favorecido", "ne_atual");

ALTER TABLE ONLY "public"."usa_agencias"
    ADD CONSTRAINT "usa_agencias_pkey" PRIMARY KEY ("codigo");

ALTER TABLE ONLY "public"."usa_contratos"
    ADD CONSTRAINT "usa_contratos_pkey" PRIMARY KEY ("award_id");

ALTER TABLE ONLY "public"."usa_transacoes"
    ADD CONSTRAINT "usa_transacoes_pkey" PRIMARY KEY ("transacao_id");

ALTER TABLE ONLY "public"."user_profiles"
    ADD CONSTRAINT "user_profiles_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."viagens"
    ADD CONSTRAINT "viagens_id_portal_key" UNIQUE ("id_portal");

ALTER TABLE ONLY "public"."viagens"
    ADD CONSTRAINT "viagens_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."voos_senado"
    ADD CONSTRAINT "voos_senado_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."votacoes_brutas"
    ADD CONSTRAINT "votacoes_brutas_deputado_id_externo_id_votacao_key" UNIQUE ("deputado_id_externo", "id_votacao");

ALTER TABLE ONLY "public"."votacoes_brutas"
    ADD CONSTRAINT "votacoes_brutas_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."votacoes_orientacoes"
    ADD CONSTRAINT "votacoes_orientacoes_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."votacoes_orientacoes"
    ADD CONSTRAINT "votacoes_orientacoes_votacao_id_sigla_bancada_key" UNIQUE ("votacao_id", "sigla_bancada");

ALTER TABLE ONLY "public"."votacoes"
    ADD CONSTRAINT "votacoes_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."votacoes_senado"
    ADD CONSTRAINT "votacoes_senado_parlamentar_id_id_sessao_key" UNIQUE ("parlamentar_id", "id_sessao");

ALTER TABLE ONLY "public"."votacoes_senado"
    ADD CONSTRAINT "votacoes_senado_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."watchlist_items"
    ADD CONSTRAINT "watchlist_items_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."watchlists"
    ADD CONSTRAINT "watchlists_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "bcb"."if_balanco"
    ADD CONSTRAINT "if_balanco_cod_inst_fkey" FOREIGN KEY ("cod_inst") REFERENCES "bcb"."if_cadastro"("cod_inst") ON DELETE CASCADE;

ALTER TABLE ONLY "cidadania_ai"."cases"
    ADD CONSTRAINT "cases_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "cidadania_ai"."generated_docs"
    ADD CONSTRAINT "generated_docs_case_id_fkey" FOREIGN KEY ("case_id") REFERENCES "cidadania_ai"."cases"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "cidadania_ai"."generated_docs"
    ADD CONSTRAINT "generated_docs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "cidadania_ai"."messages"
    ADD CONSTRAINT "messages_case_id_fkey" FOREIGN KEY ("case_id") REFERENCES "cidadania_ai"."cases"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "cidadania_ai"."messages"
    ADD CONSTRAINT "messages_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "homabrasil"."desastres_historico"
    ADD CONSTRAINT "desastres_historico_municipio_id_fkey" FOREIGN KEY ("municipio_id") REFERENCES "homabrasil"."municipios"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "homabrasil"."homa_score"
    ADD CONSTRAINT "homa_score_municipio_id_fkey" FOREIGN KEY ("municipio_id") REFERENCES "homabrasil"."municipios"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "homabrasil"."infraestrutura"
    ADD CONSTRAINT "infraestrutura_municipio_id_fkey" FOREIGN KEY ("municipio_id") REFERENCES "homabrasil"."municipios"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "homabrasil"."qualidade_vida"
    ADD CONSTRAINT "qualidade_vida_municipio_id_fkey" FOREIGN KEY ("municipio_id") REFERENCES "homabrasil"."municipios"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "homabrasil"."risco_climatico"
    ADD CONSTRAINT "risco_climatico_municipio_id_fkey" FOREIGN KEY ("municipio_id") REFERENCES "homabrasil"."municipios"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "portal_transparencia"."cartoes_pagamento"
    ADD CONSTRAINT "cartoes_pagamento_cnpj_estabelecimento_fkey" FOREIGN KEY ("cnpj_estabelecimento") REFERENCES "portal_transparencia"."favorecidos"("cnpj_cpf") ON UPDATE CASCADE;

ALTER TABLE ONLY "portal_transparencia"."notas_fiscais"
    ADD CONSTRAINT "notas_fiscais_cnpj_destinatario_fkey" FOREIGN KEY ("cnpj_destinatario") REFERENCES "portal_transparencia"."favorecidos"("cnpj_cpf") ON UPDATE CASCADE;

ALTER TABLE ONLY "portal_transparencia"."notas_fiscais"
    ADD CONSTRAINT "notas_fiscais_cnpj_emitente_fkey" FOREIGN KEY ("cnpj_emitente") REFERENCES "portal_transparencia"."favorecidos"("cnpj_cpf") ON UPDATE CASCADE;

ALTER TABLE ONLY "portal_transparencia"."notas_fiscais_itens"
    ADD CONSTRAINT "notas_fiscais_itens_chave_nfe_fkey" FOREIGN KEY ("chave_nfe") REFERENCES "portal_transparencia"."notas_fiscais"("chave_nfe") ON DELETE CASCADE;

ALTER TABLE ONLY "portal_transparencia"."sancoes"
    ADD CONSTRAINT "sancoes_cnpj_cpf_sancionado_fkey" FOREIGN KEY ("cnpj_cpf_sancionado") REFERENCES "portal_transparencia"."favorecidos"("cnpj_cpf") ON UPDATE CASCADE;

ALTER TABLE ONLY "public"."ale_parlamentares"
    ADD CONSTRAINT "ale_parlamentares_casa_id_fkey" FOREIGN KEY ("casa_id") REFERENCES "public"."ale_casas"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."ale_proposicoes"
    ADD CONSTRAINT "ale_proposicoes_casa_id_fkey" FOREIGN KEY ("casa_id") REFERENCES "public"."ale_casas"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."ale_votacoes"
    ADD CONSTRAINT "ale_votacoes_casa_id_fkey" FOREIGN KEY ("casa_id") REFERENCES "public"."ale_casas"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."ale_votos"
    ADD CONSTRAINT "ale_votos_votacao_id_fkey" FOREIGN KEY ("votacao_id") REFERENCES "public"."ale_votacoes"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."autores_orcamentarios"
    ADD CONSTRAINT "autores_orcamentarios_parlamentar_id_fkey" FOREIGN KEY ("parlamentar_id") REFERENCES "public"."parlamentares"("id");

ALTER TABLE ONLY "public"."autores_parlamentares_map"
    ADD CONSTRAINT "autores_parlamentares_map_parlamentar_id_fkey" FOREIGN KEY ("parlamentar_id") REFERENCES "public"."parlamentares"("id");

ALTER TABLE ONLY "public"."cam_comissoes_membros"
    ADD CONSTRAINT "cam_comissoes_membros_comissao_id_fkey" FOREIGN KEY ("comissao_id") REFERENCES "public"."cam_comissoes"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."cam_frentes_membros"
    ADD CONSTRAINT "cam_frentes_membros_frente_id_fkey" FOREIGN KEY ("frente_id") REFERENCES "public"."cam_frentes"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."camara_frente_membro"
    ADD CONSTRAINT "camara_frente_membro_id_frente_fkey" FOREIGN KEY ("id_frente") REFERENCES "public"."camara_frente"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."ceaps_ranking"
    ADD CONSTRAINT "ceaps_ranking_deputado_id_externo_fkey" FOREIGN KEY ("deputado_id_externo") REFERENCES "public"."deputados_brutas"("id_externo") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."codigos_acesso"
    ADD CONSTRAINT "codigos_acesso_usado_por_fkey" FOREIGN KEY ("usado_por") REFERENCES "auth"."users"("id");

ALTER TABLE ONLY "public"."comissoes_parlamentares"
    ADD CONSTRAINT "comissoes_parlamentares_parlamentar_id_fkey" FOREIGN KEY ("parlamentar_id") REFERENCES "public"."parlamentares"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."comissoes_senado"
    ADD CONSTRAINT "comissoes_senado_parlamentar_id_fkey" FOREIGN KEY ("parlamentar_id") REFERENCES "public"."parlamentares"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."cota_despesa"
    ADD CONSTRAINT "cota_despesa_id_deputado_fkey" FOREIGN KEY ("id_deputado") REFERENCES "public"."cota_deputado"("id_camara");

ALTER TABLE ONLY "public"."cvm_acusados"
    ADD CONSTRAINT "cvm_acusados_nup_fkey" FOREIGN KEY ("nup") REFERENCES "public"."cvm_processos"("nup");

ALTER TABLE ONLY "public"."declaracao_bens"
    ADD CONSTRAINT "declaracao_bens_parlamentar_id_fkey" FOREIGN KEY ("parlamentar_id") REFERENCES "public"."parlamentares"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."discursos_camara"
    ADD CONSTRAINT "discursos_camara_parlamentar_id_fkey" FOREIGN KEY ("parlamentar_id") REFERENCES "public"."parlamentares"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."discursos"
    ADD CONSTRAINT "discursos_parlamentar_id_fkey" FOREIGN KEY ("parlamentar_id") REFERENCES "public"."parlamentares"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."discursos_senado"
    ADD CONSTRAINT "discursos_senado_parlamentar_id_fkey" FOREIGN KEY ("parlamentar_id") REFERENCES "public"."parlamentares"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."ele2026_alertas"
    ADD CONSTRAINT "ele2026_alertas_parlamentar_id_fkey" FOREIGN KEY ("parlamentar_id") REFERENCES "public"."parlamentares"("id");

ALTER TABLE ONLY "public"."ele2026_candidatos"
    ADD CONSTRAINT "ele2026_candidatos_parlamentar_id_fkey" FOREIGN KEY ("parlamentar_id") REFERENCES "public"."parlamentares"("id");

ALTER TABLE ONLY "public"."emendas_api_documentos"
    ADD CONSTRAINT "emendas_api_documentos_emenda_codigo_fkey" FOREIGN KEY ("emenda_codigo") REFERENCES "public"."emendas_api"("codigo") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."emendas_financeiro"
    ADD CONSTRAINT "emendas_financeiro_parlamentar_id_fkey" FOREIGN KEY ("parlamentar_id") REFERENCES "public"."parlamentares"("id") ON DELETE SET NULL;

ALTER TABLE ONLY "public"."emendas"
    ADD CONSTRAINT "emendas_mandato_id_fkey" FOREIGN KEY ("mandato_id") REFERENCES "public"."mandatos"("id");

ALTER TABLE ONLY "public"."emendas"
    ADD CONSTRAINT "emendas_ministerio_id_fkey" FOREIGN KEY ("ministerio_id") REFERENCES "public"."ministerios"("id");

ALTER TABLE ONLY "public"."emendas"
    ADD CONSTRAINT "emendas_municipio_id_fkey" FOREIGN KEY ("municipio_id") REFERENCES "public"."municipios"("id");

ALTER TABLE ONLY "public"."emendas"
    ADD CONSTRAINT "emendas_orgao_id_fkey" FOREIGN KEY ("orgao_id") REFERENCES "public"."orgaos_federais"("id");

ALTER TABLE ONLY "public"."emendas"
    ADD CONSTRAINT "emendas_parlamentar_id_fkey" FOREIGN KEY ("parlamentar_id") REFERENCES "public"."parlamentares"("id");

ALTER TABLE ONLY "public"."execucoes_pipeline_etapas"
    ADD CONSTRAINT "execucoes_pipeline_etapas_execucao_id_fkey" FOREIGN KEY ("execucao_id") REFERENCES "public"."execucoes_pipeline"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."financiamento_eleitoral"
    ADD CONSTRAINT "financiamento_eleitoral_parlamentar_id_fkey" FOREIGN KEY ("parlamentar_id") REFERENCES "public"."parlamentares"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."emendas"
    ADD CONSTRAINT "fk_emenda_autor" FOREIGN KEY ("autor_orcamentario_id") REFERENCES "public"."autores_orcamentarios"("id");

ALTER TABLE ONLY "public"."mandatos"
    ADD CONSTRAINT "fk_mandato_autor" FOREIGN KEY ("autor_orcamentario_id") REFERENCES "public"."autores_orcamentarios"("id");

ALTER TABLE ONLY "public"."parlamentar_identidade"
    ADD CONSTRAINT "fk_parlamentar" FOREIGN KEY ("parlamentar_id") REFERENCES "public"."parlamentares"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."fundacoes_embeddings"
    ADD CONSTRAINT "fundacoes_embeddings_cnpj_fkey" FOREIGN KEY ("cnpj") REFERENCES "public"."fundacoes_partidarias"("cnpj") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."gastos_parlamentares"
    ADD CONSTRAINT "gastos_parlamentares_casa_id_fkey" FOREIGN KEY ("casa_id") REFERENCES "public"."casas"("id");

ALTER TABLE ONLY "public"."gastos_parlamentares"
    ADD CONSTRAINT "gastos_parlamentares_parlamentar_id_fkey" FOREIGN KEY ("parlamentar_id") REFERENCES "public"."parlamentares_estaduais"("id");

ALTER TABLE ONLY "public"."ibge_indicadores"
    ADD CONSTRAINT "ibge_indicadores_codigo_ibge_fkey" FOREIGN KEY ("codigo_ibge") REFERENCES "public"."ibge_municipios"("codigo_ibge");

ALTER TABLE ONLY "public"."indicadores"
    ADD CONSTRAINT "indicadores_institution_id_fkey" FOREIGN KEY ("institution_id") REFERENCES "public"."institutions"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."indicadores"
    ADD CONSTRAINT "indicadores_observatorio_id_fkey" FOREIGN KEY ("observatorio_id") REFERENCES "public"."observatorios"("id");

ALTER TABLE ONLY "public"."institutions"
    ADD CONSTRAINT "institutions_observatorio_id_fkey" FOREIGN KEY ("observatorio_id") REFERENCES "public"."observatorios"("id");

ALTER TABLE ONLY "public"."judiciario_highlights"
    ADD CONSTRAINT "judiciario_highlights_processo_id_fkey" FOREIGN KEY ("processo_id") REFERENCES "public"."judiciario_processos"("id") ON DELETE SET NULL;

ALTER TABLE ONLY "public"."judiciario_highlights"
    ADD CONSTRAINT "judiciario_highlights_tribunal_id_fkey" FOREIGN KEY ("tribunal_id") REFERENCES "public"."tribunais"("id");

ALTER TABLE ONLY "public"."judiciario_processos"
    ADD CONSTRAINT "judiciario_processos_tribunal_id_fkey" FOREIGN KEY ("tribunal_id") REFERENCES "public"."tribunais"("id");

ALTER TABLE ONLY "public"."mandatos"
    ADD CONSTRAINT "mandatos_parlamentar_id_fkey" FOREIGN KEY ("parlamentar_id") REFERENCES "public"."parlamentares"("id");

ALTER TABLE ONLY "public"."midia_kantar_releases"
    ADD CONSTRAINT "midia_kantar_releases_evento_id_fkey" FOREIGN KEY ("evento_id") REFERENCES "public"."midia_eventos"("id");

ALTER TABLE ONLY "public"."midia_kantar_releases"
    ADD CONSTRAINT "midia_kantar_releases_veiculo_id_fkey" FOREIGN KEY ("veiculo_id") REFERENCES "public"."midia_veiculos"("id");

ALTER TABLE ONLY "public"."midia_secom_verbas"
    ADD CONSTRAINT "midia_secom_verbas_veiculo_id_fkey" FOREIGN KEY ("veiculo_id") REFERENCES "public"."midia_veiculos"("id");

ALTER TABLE ONLY "public"."midia_youtube_eventos"
    ADD CONSTRAINT "midia_youtube_eventos_evento_id_fkey" FOREIGN KEY ("evento_id") REFERENCES "public"."midia_eventos"("id");

ALTER TABLE ONLY "public"."midia_youtube_eventos"
    ADD CONSTRAINT "midia_youtube_eventos_veiculo_id_fkey" FOREIGN KEY ("veiculo_id") REFERENCES "public"."midia_veiculos"("id");

ALTER TABLE ONLY "public"."narrativas"
    ADD CONSTRAINT "narrativas_institution_id_fkey" FOREIGN KEY ("institution_id") REFERENCES "public"."institutions"("id") ON DELETE SET NULL;

ALTER TABLE ONLY "public"."narrativas"
    ADD CONSTRAINT "narrativas_observatorio_id_fkey" FOREIGN KEY ("observatorio_id") REFERENCES "public"."observatorios"("id");

ALTER TABLE ONLY "public"."newsletter_sends"
    ADD CONSTRAINT "newsletter_sends_subscriber_id_fkey" FOREIGN KEY ("subscriber_id") REFERENCES "public"."newsletter_subscribers"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."parlamentar_contratos_cache"
    ADD CONSTRAINT "parlamentar_contratos_cache_parlamentar_id_fkey" FOREIGN KEY ("parlamentar_id") REFERENCES "public"."parlamentares"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."parlamentar_financiamento_cache"
    ADD CONSTRAINT "parlamentar_financiamento_cache_parlamentar_id_fkey" FOREIGN KEY ("parlamentar_id") REFERENCES "public"."parlamentares"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."parlamentar_inteligencia"
    ADD CONSTRAINT "parlamentar_inteligencia_parlamentar_id_fkey" FOREIGN KEY ("parlamentar_id") REFERENCES "public"."parlamentares"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."parlamentar_sancoes_cache"
    ADD CONSTRAINT "parlamentar_sancoes_cache_parlamentar_id_fkey" FOREIGN KEY ("parlamentar_id") REFERENCES "public"."parlamentares"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."parlamentares_estaduais"
    ADD CONSTRAINT "parlamentares_estaduais_casa_id_fkey" FOREIGN KEY ("casa_id") REFERENCES "public"."casas"("id");

ALTER TABLE ONLY "public"."patrimonio_tse"
    ADD CONSTRAINT "patrimonio_tse_parlamentar_id_fkey" FOREIGN KEY ("parlamentar_id") REFERENCES "public"."parlamentares"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."plen_orientacoes"
    ADD CONSTRAINT "plen_orientacoes_votacao_id_fkey" FOREIGN KEY ("votacao_id") REFERENCES "public"."plen_votacoes"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."plen_votos"
    ADD CONSTRAINT "plen_votos_votacao_id_fkey" FOREIGN KEY ("votacao_id") REFERENCES "public"."plen_votacoes"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."ranking_parlamentar_build"
    ADD CONSTRAINT "ranking_parlamentar_build_parlamentar_id_fkey" FOREIGN KEY ("parlamentar_id") REFERENCES "public"."parlamentares"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."ranking_parlamentar"
    ADD CONSTRAINT "ranking_parlamentar_parlamentar_id_fkey" FOREIGN KEY ("parlamentar_id") REFERENCES "public"."parlamentares"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."scores"
    ADD CONSTRAINT "scores_institution_id_fkey" FOREIGN KEY ("institution_id") REFERENCES "public"."institutions"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."scores"
    ADD CONSTRAINT "scores_observatorio_id_fkey" FOREIGN KEY ("observatorio_id") REFERENCES "public"."observatorios"("id");

ALTER TABLE ONLY "public"."senado_orientacao"
    ADD CONSTRAINT "senado_orientacao_id_sve_fkey" FOREIGN KEY ("id_sve") REFERENCES "public"."senado_votacao"("id_sve") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."senado_voto"
    ADD CONSTRAINT "senado_voto_id_sve_fkey" FOREIGN KEY ("id_sve") REFERENCES "public"."senado_votacao"("id_sve") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."siafi_empenho"
    ADD CONSTRAINT "siafi_empenho_cnpj_favorecido_fkey" FOREIGN KEY ("cnpj_favorecido") REFERENCES "public"."siafi_fornecedor"("cnpj_cpf") DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE ONLY "public"."siafi_item_empenho"
    ADD CONSTRAINT "siafi_item_empenho_id_empenho_fkey" FOREIGN KEY ("id_empenho") REFERENCES "public"."siafi_empenho"("id_empenho") ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE ONLY "public"."siafi_liquidacao"
    ADD CONSTRAINT "siafi_liquidacao_cnpj_favorecido_fkey" FOREIGN KEY ("cnpj_favorecido") REFERENCES "public"."siafi_fornecedor"("cnpj_cpf") DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE ONLY "public"."siafi_pagamento"
    ADD CONSTRAINT "siafi_pagamento_cnpj_favorecido_fkey" FOREIGN KEY ("cnpj_favorecido") REFERENCES "public"."siafi_fornecedor"("cnpj_cpf") DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE ONLY "public"."siafi_pagamento_favorecido_final"
    ADD CONSTRAINT "siafi_pagamento_favorecido_final_cnpj_favorecido_final_fkey" FOREIGN KEY ("cnpj_favorecido_final") REFERENCES "public"."siafi_fornecedor"("cnpj_cpf") DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE ONLY "public"."stf_assinaturas"
    ADD CONSTRAINT "stf_assinaturas_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."stf_gastos"
    ADD CONSTRAINT "stf_gastos_ministro_id_fkey" FOREIGN KEY ("ministro_id") REFERENCES "public"."stf_ministros"("id");

ALTER TABLE ONLY "public"."stf_processos_politicos"
    ADD CONSTRAINT "stf_processos_politicos_relator_id_fkey" FOREIGN KEY ("relator_id") REFERENCES "public"."stf_ministros"("id");

ALTER TABLE ONLY "public"."stf_repercussao_geral"
    ADD CONSTRAINT "stf_repercussao_geral_relator_id_fkey" FOREIGN KEY ("relator_id") REFERENCES "public"."stf_ministros"("id");

ALTER TABLE ONLY "public"."stf_votacoes"
    ADD CONSTRAINT "stf_votacoes_ministro_id_fkey" FOREIGN KEY ("ministro_id") REFERENCES "public"."stf_ministros"("id");

ALTER TABLE ONLY "public"."sub_alertas"
    ADD CONSTRAINT "sub_alertas_dossie_id_fkey" FOREIGN KEY ("dossie_id") REFERENCES "public"."sub_dossies"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."sub_cnpjs_monitorados"
    ADD CONSTRAINT "sub_cnpjs_monitorados_cliente_id_fkey" FOREIGN KEY ("cliente_id") REFERENCES "public"."sub_clientes"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."sub_dossies"
    ADD CONSTRAINT "sub_dossies_cliente_id_fkey" FOREIGN KEY ("cliente_id") REFERENCES "public"."sub_clientes"("id");

ALTER TABLE ONLY "public"."sub_envios"
    ADD CONSTRAINT "sub_envios_cliente_id_fkey" FOREIGN KEY ("cliente_id") REFERENCES "public"."sub_clientes"("id");

ALTER TABLE ONLY "public"."sub_envios"
    ADD CONSTRAINT "sub_envios_dossie_id_fkey" FOREIGN KEY ("dossie_id") REFERENCES "public"."sub_dossies"("id");

ALTER TABLE ONLY "public"."ted_termos_execucao"
    ADD CONSTRAINT "ted_termos_execucao_id_plano_acao_fkey" FOREIGN KEY ("id_plano_acao") REFERENCES "public"."ted_planos_acao"("id_plano_acao");

ALTER TABLE ONLY "public"."usa_contratos"
    ADD CONSTRAINT "usa_contratos_agencia_codigo_fkey" FOREIGN KEY ("agencia_codigo") REFERENCES "public"."usa_agencias"("codigo") ON DELETE SET NULL;

ALTER TABLE ONLY "public"."user_profiles"
    ADD CONSTRAINT "user_profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."viagens"
    ADD CONSTRAINT "viagens_parlamentar_id_fkey" FOREIGN KEY ("parlamentar_id") REFERENCES "public"."parlamentares"("id");

ALTER TABLE ONLY "public"."votacoes_senado"
    ADD CONSTRAINT "votacoes_senado_parlamentar_id_fkey" FOREIGN KEY ("parlamentar_id") REFERENCES "public"."parlamentares"("id") ON DELETE CASCADE;
-- bloco 07_functions — gerado por split_baseline.py (ordem interna = ordem do dump)
CREATE OR REPLACE FUNCTION "cidadania_ai"."match_cidadania_docs"("query_embedding" "public"."vector", "match_count" integer DEFAULT 8, "match_collection" "text" DEFAULT NULL::"text") RETURNS TABLE("id" "uuid", "collection" "text", "title" "text", "source" "text", "content" "text", "tags" "jsonb", "similarity" double precision)
    LANGUAGE "sql" STABLE
    AS $$
  select
    d.id,
    d.collection,
    d.title,
    d.source,
    d.content,
    d.tags,
    1 - (d.embedding <=> query_embedding) as similarity
  from cidadania_ai.library_docs d
  where d.embedding is not null
    and (match_collection is null or d.collection = match_collection)
  order by d.embedding <=> query_embedding
  limit match_count;
$$;

CREATE OR REPLACE FUNCTION "cidadania_ai"."set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  new.updated_at = now();
  return new;
end;
$$;

CREATE OR REPLACE FUNCTION "public"."alerta_audiencias_semana"() RETURNS TABLE("id" "text", "data" "date", "data_hora_inicio" timestamp with time zone, "tipo_evento" "text", "situacao" "text", "descricao" "text", "local" "text", "comissoes" "text"[], "url_pauta" "text", "url_video" "text")
    LANGUAGE "sql" SECURITY DEFINER
    AS $$
    select
        id,
        data_inicio_date,
        data_hora_inicio,
        tipo_evento,
        situacao,
        descricao,
        local_nome,
        orgaos_siglas,
        url_documento_pauta,
        url_registro
    from agenda_camara_eventos
    where data_inicio_date >= current_date - 7
      and (
          tipo_evento ilike '%audiência pública%'
       or tipo_evento ilike '%audiencia publica%'
      )
    order by data_hora_inicio desc;
$$;

CREATE OR REPLACE FUNCTION "public"."alerta_combo_sancao_emenda"() RETURNS TABLE("compromisso_id" "text", "data_inicio" "date", "hora_inicio" "text", "orgao_sigla" "text", "autoridade_nome" "text", "assunto" "text", "participante_nome" "text", "cnpj_participante" "text", "instituicao" "text", "tipo_cadastro_sancao" "text", "tipo_sancao" "text", "total_emendas" numeric)
    LANGUAGE "sql" SECURITY DEFINER
    AS $$
    with privados as (
        select
            c.id                                                            as compromisso_id,
            c.data_inicio,
            c.hora_inicio,
            c.orgao_sigla,
            c.autoridade_nome,
            c.assunto,
            p->>'nome'                                                      as participante_nome,
            regexp_replace(p->>'cnpj_instituicao', '[^0-9]', '', 'g')      as cnpj,
            p->>'cnpj_instituicao'                                          as cnpj_raw,
            p->>'nome_instituicao'                                          as instituicao
        from agenda_executivo_compromissos c,
             jsonb_array_elements(c.participantes_privados) p
        where c.tem_participantes_privados = true
          and c.data_inicio >= current_date - 30
          and p->>'cnpj_instituicao' is not null
    ),
    com_sancao as (
        select p.*, s.tipo_sancao, s.cadastro
        from privados p
        join sancoes s on s.cpf_cnpj = p.cnpj
        where length(p.cnpj) >= 14
    ),
    com_emenda as (
        select p.cnpj, sum(ef.valor_recebido) as total_emendas
        from privados p
        join emendas_favorecidos ef on ef.codigo_favorecido = p.cnpj
        where length(p.cnpj) >= 14
        group by p.cnpj
    )
    select
        cs.compromisso_id,
        cs.data_inicio,
        cs.hora_inicio,
        cs.orgao_sigla,
        cs.autoridade_nome,
        cs.assunto,
        cs.participante_nome,
        cs.cnpj_raw,
        cs.instituicao,
        cs.cadastro,
        cs.tipo_sancao,
        ce.total_emendas
    from com_sancao cs
    join com_emenda ce on ce.cnpj = cs.cnpj
    order by ce.total_emendas desc;
$$;

CREATE OR REPLACE FUNCTION "public"."alerta_ministerio_emenda"() RETURNS TABLE("compromisso_id" "text", "data_inicio" "date", "hora_inicio" "text", "orgao_sigla" "text", "autoridade_nome" "text", "autoridade_cargo" "text", "assunto" "text", "local" "text", "participante_nome" "text", "cnpj_participante" "text", "instituicao" "text", "autor_emenda" "text", "tipo_emenda" "text", "ano_emenda" integer, "total_recebido_emendas" numeric, "n_emendas" bigint)
    LANGUAGE "sql" SECURITY DEFINER
    AS $$
    with privados as (
        select
            c.id                                                            as compromisso_id,
            c.data_inicio,
            c.hora_inicio,
            c.orgao_sigla,
            c.autoridade_nome,
            c.autoridade_cargo,
            c.assunto,
            c.local,
            p->>'nome'                                                      as participante_nome,
            regexp_replace(p->>'cnpj_instituicao', '[^0-9]', '', 'g')      as cnpj,
            p->>'cnpj_instituicao'                                          as cnpj_raw,
            p->>'nome_instituicao'                                          as instituicao
        from agenda_executivo_compromissos c,
             jsonb_array_elements(c.participantes_privados) p
        where c.tem_participantes_privados = true
          and c.data_inicio >= current_date - 30
          and p->>'cnpj_instituicao' is not null
          and p->>'cnpj_instituicao' != ''
    )
    select
        p.compromisso_id,
        p.data_inicio,
        p.hora_inicio,
        p.orgao_sigla,
        p.autoridade_nome,
        p.autoridade_cargo,
        p.assunto,
        p.local,
        p.participante_nome,
        p.cnpj_raw,
        p.instituicao,
        ef.nome_autor,
        ef.tipo_emenda,
        ef.ano_emenda,
        sum(ef.valor_recebido),
        count(*)
    from privados p
    join emendas_favorecidos ef on ef.codigo_favorecido = p.cnpj
    where length(p.cnpj) >= 14
    group by
        p.compromisso_id, p.data_inicio, p.hora_inicio,
        p.orgao_sigla, p.autoridade_nome, p.autoridade_cargo,
        p.assunto, p.local, p.participante_nome, p.cnpj_raw,
        p.instituicao, ef.nome_autor, ef.tipo_emenda, ef.ano_emenda
    having sum(ef.valor_recebido) > 100000
    order by sum(ef.valor_recebido) desc;
$$;

CREATE OR REPLACE FUNCTION "public"."alerta_ministerio_sancao"() RETURNS TABLE("compromisso_id" "text", "data_inicio" "date", "hora_inicio" "text", "orgao_sigla" "text", "autoridade_nome" "text", "autoridade_cargo" "text", "assunto" "text", "local" "text", "participante_nome" "text", "cnpj_participante" "text", "instituicao" "text", "cargo_inst" "text", "tipo_sancao" "text", "cadastro" "text", "descricao_sancao" "text", "data_inicio_sancao" "text", "data_fim_sancao" "text", "orgao_sancao" "text", "nome_sancionado" "text")
    LANGUAGE "sql" SECURITY DEFINER
    AS $$
    with privados as (
        select
            c.id                                                            as compromisso_id,
            c.data_inicio,
            c.hora_inicio,
            c.orgao_sigla,
            c.autoridade_nome,
            c.autoridade_cargo,
            c.assunto,
            c.local,
            p->>'nome'                                                      as participante_nome,
            p->>'cnpj_instituicao'                                          as cnpj_raw,
            regexp_replace(p->>'cnpj_instituicao', '[^0-9]', '', 'g')      as cnpj,
            p->>'nome_instituicao'                                          as instituicao,
            p->>'cargo_instituicao'                                         as cargo_inst
        from agenda_executivo_compromissos c,
             jsonb_array_elements(c.participantes_privados) p
        where c.tem_participantes_privados = true
          and c.data_inicio >= current_date - 30
          and p->>'cnpj_instituicao' is not null
          and p->>'cnpj_instituicao' != ''
    )
    select
        p.compromisso_id,
        p.data_inicio,
        p.hora_inicio,
        p.orgao_sigla,
        p.autoridade_nome,
        p.autoridade_cargo,
        p.assunto,
        p.local,
        p.participante_nome,
        p.cnpj_raw,
        p.instituicao,
        p.cargo_inst,
        s.tipo_sancao,
        s.cadastro,
        s.descricao_sancao,
        s.data_inicio::text,
        s.data_fim::text,
        s.orgao_nome,
        s.nome
    from privados p
    join sancoes s on s.cpf_cnpj = p.cnpj
    where length(p.cnpj) >= 14
    order by p.data_inicio desc, p.orgao_sigla;
$$;

CREATE OR REPLACE FUNCTION "public"."alerta_ranking_privados"() RETURNS TABLE("orgao_sigla" "text", "autoridade_nome" "text", "autoridade_cargo" "text", "n_compromissos_privados" bigint, "total_participantes_privados" bigint, "primeira_reuniao" "date", "ultima_reuniao" "date")
    LANGUAGE "sql" SECURITY DEFINER
    AS $$
    select
        orgao_sigla,
        autoridade_nome,
        autoridade_cargo,
        count(*)                        as n_compromissos_privados,
        sum(n_participantes_privados)   as total_participantes_privados,
        min(data_inicio)                as primeira_reuniao,
        max(data_inicio)                as ultima_reuniao
    from agenda_executivo_compromissos
    where tem_participantes_privados = true
      and data_inicio >= current_date - 7
    group by orgao_sigla, autoridade_nome, autoridade_cargo
    order by count(*) desc
    limit 10;
$$;

CREATE OR REPLACE FUNCTION "public"."ask_quota_check_increment"("p_user_id" "uuid", "p_limit" integer) RETURNS TABLE("count" integer, "allowed" boolean)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_count integer;
BEGIN
  -- Garante que existe a linha para hoje
  INSERT INTO public.ask_quota (user_id, date, count)
  VALUES (p_user_id, CURRENT_DATE, 0)
  ON CONFLICT (user_id, date) DO NOTHING;

  -- Incrementa atomicamente apenas se dentro do limite
  UPDATE public.ask_quota
  SET    count = CASE
                  WHEN ask_quota.count < p_limit THEN ask_quota.count + 1
                  ELSE ask_quota.count
                END
  WHERE  user_id = p_user_id
    AND  date    = CURRENT_DATE
  RETURNING ask_quota.count INTO v_count;

  RETURN QUERY SELECT v_count, (v_count <= p_limit);
END;
$$;

CREATE OR REPLACE FUNCTION "public"."buscar_emendas_municipio"("p_uf" "text", "p_slug" "text") RETURNS TABLE("id" "uuid", "codigo_emenda" "text", "autor_nome" "text", "tipo" "text", "subtipo" "text", "ano" integer, "ministerio" "text", "valor_empenhado" numeric, "valor_pago" numeric, "parlamentar_id" "uuid")
    LANGUAGE "sql" STABLE
    AS $$
  SELECT id, codigo_emenda, autor_nome, tipo, subtipo, ano, ministerio,
         valor_empenhado, valor_pago, parlamentar_id
  FROM public.emendas
  WHERE UPPER(uf_destino) = UPPER(p_uf)
    AND unaccent(lower(COALESCE(municipio_nome, '')))
        ILIKE '%' || unaccent(lower(replace(p_slug, '-', ' '))) || '%'
  ORDER BY valor_pago DESC NULLS LAST
  LIMIT 500;
$$;

CREATE OR REPLACE FUNCTION "public"."buscar_processos"("q" "text", "p_tribunal" "text" DEFAULT NULL::"text", "p_classe" "text" DEFAULT NULL::"text", "p_relator" "text" DEFAULT NULL::"text", "p_data_inicio" "date" DEFAULT NULL::"date", "p_data_fim" "date" DEFAULT NULL::"date", "p_page" integer DEFAULT 0, "p_page_size" integer DEFAULT 50) RETURNS TABLE("id" "uuid", "tribunal" "text", "classe" "text", "classe_processual" "text", "numero_processo" "text", "relator" "text", "orgao_julgador" "text", "tipo_decisao" "text", "data_decisao" "date", "tema" "text", "ementa" "text", "link_oficial" "text", "fonte" "text", "data_coleta" timestamp with time zone, "total_count" bigint)
    LANGUAGE "sql" STABLE
    AS $$
  WITH filtrados AS (
    SELECT
      p.id,
      t.sigla                         AS tribunal,
      p.classe,
      (p.metadata->>'classe_codigo')  AS classe_processual,
      p.numero_processo,
      p.relator,
      p.orgao_julgador,
      p.tipo_decisao,
      p.data_decisao,
      p.tema,
      p.ementa,
      p.link_oficial,
      p.fonte,
      p.data_coleta,
      CASE
        WHEN q IS NULL OR q = '' THEN 0::real
        ELSE ts_rank(p.search_vector, websearch_to_tsquery('portuguese', q))
      END AS rank
    FROM public.judiciario_processos p
    JOIN public.tribunais t ON t.id = p.tribunal_id
    WHERE
      (q IS NULL OR q = '' OR p.search_vector @@ websearch_to_tsquery('portuguese', q))
      AND (p_tribunal    IS NULL OR t.sigla = upper(p_tribunal))
      AND (p_classe      IS NULL OR p.classe = p_classe)
      AND (p_relator     IS NULL OR p.relator ILIKE '%' || p_relator || '%')
      AND (p_data_inicio IS NULL OR p.data_decisao >= p_data_inicio)
      AND (p_data_fim    IS NULL OR p.data_decisao <= p_data_fim)
  )
  SELECT
    f.id,
    f.tribunal,
    f.classe,
    f.classe_processual,
    f.numero_processo,
    f.relator,
    f.orgao_julgador,
    f.tipo_decisao,
    f.data_decisao,
    f.tema,
    f.ementa,
    f.link_oficial,
    f.fonte,
    f.data_coleta,
    count(*) OVER() AS total_count
  FROM filtrados f
  ORDER BY
    CASE WHEN q IS NULL OR q = '' THEN 0 ELSE 1 END,
    f.rank DESC,
    f.data_decisao DESC NULLS LAST,
    f.data_coleta DESC
  LIMIT p_page_size OFFSET p_page * p_page_size;
$$;

CREATE OR REPLACE FUNCTION "public"."buscar_processos_judiciario"("q" "text", "p_tribunal" "text" DEFAULT NULL::"text", "p_classe" "text" DEFAULT NULL::"text", "p_limit" integer DEFAULT 50, "p_offset" integer DEFAULT 0) RETURNS TABLE("id" "uuid", "tribunal" "text", "classe" "text", "numero_processo" "text", "relator" "text", "orgao_julgador" "text", "tipo_decisao" "text", "data_decisao" "date", "tema" "text", "ementa" "text", "link_oficial" "text", "fonte" "text", "data_coleta" timestamp with time zone, "rank" real)
    LANGUAGE "sql" STABLE
    AS $$
  SELECT
    p.id,
    t.sigla         AS tribunal,
    p.classe,
    p.numero_processo,
    p.relator,
    p.orgao_julgador,
    p.tipo_decisao,
    p.data_decisao,
    p.tema,
    p.ementa,
    p.link_oficial,
    p.fonte,
    p.data_coleta,
    CASE
      WHEN q IS NULL OR q = '' THEN 0::real
      ELSE ts_rank(p.search_vector, websearch_to_tsquery('portuguese', q))
    END AS rank
  FROM public.judiciario_processos p
  JOIN public.tribunais t ON t.id = p.tribunal_id
  WHERE
    (q IS NULL OR q = '' OR p.search_vector @@ websearch_to_tsquery('portuguese', q))
    AND (p_tribunal IS NULL OR t.sigla = upper(p_tribunal))
    AND (p_classe   IS NULL OR p.classe = p_classe)
  ORDER BY
    CASE WHEN q IS NULL OR q = '' THEN 0 ELSE 1 END,
    rank DESC,
    p.data_decisao DESC NULLS LAST,
    p.data_coleta DESC
  LIMIT p_limit OFFSET p_offset;
$$;

CREATE OR REPLACE FUNCTION "public"."computar_votacoes_agg"("p_legislatura" integer DEFAULT 57) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_total_votacoes      INT;  -- total votações nominais (excluindo simbólicas)
  v_deputados_inseridos INT;
BEGIN
  -- Conta apenas votações com pelo menos 1 voto individual registrado
  SELECT COUNT(DISTINCT pv.votacao_id) INTO v_total_votacoes
  FROM plen_votos pv
  JOIN plen_votacoes v ON v.id = pv.votacao_id AND v.id_legislatura = p_legislatura;

  DELETE FROM plen_deputado_agg WHERE id_legislatura = p_legislatura;

  INSERT INTO plen_deputado_agg (
    deputado_id, id_legislatura, nome, sigla_partido, sigla_uf, url_foto,
    total_votacoes, presencas, ausencias,
    votos_sim, votos_nao, votos_abstencao, votos_obstrucao, votos_artigo17,
    pct_presenca, concordancia_partido,
    posicao, posicao_partido, por_tipo_voto, atualizado_em
  )
  SELECT
    sub.deputado_id,
    p_legislatura,
    sub.nome,
    sub.sigla_partido,
    sub.sigla_uf,
    sub.url_foto,
    v_total_votacoes                                                AS total_votacoes,
    sub.presencas,
    v_total_votacoes - sub.presencas                               AS ausencias,
    sub.votos_sim,
    sub.votos_nao,
    sub.votos_abstencao,
    sub.votos_obstrucao,
    sub.votos_artigo17,
    ROUND(sub.presencas * 100.0 / NULLIF(v_total_votacoes, 0), 2) AS pct_presenca,
    conc.concordancia_partido,
    ROW_NUMBER() OVER (ORDER BY sub.presencas DESC)                AS posicao,
    ROW_NUMBER() OVER (
      PARTITION BY sub.sigla_partido ORDER BY sub.presencas DESC
    )                                                              AS posicao_partido,
    jsonb_build_object(
      'Sim',       sub.votos_sim,
      'Não',       sub.votos_nao,
      'Abstenção', sub.votos_abstencao,
      'Obstrução', sub.votos_obstrucao,
      'Art. 17',   sub.votos_artigo17
    )                                                              AS por_tipo_voto,
    NOW()
  FROM (
    SELECT
      pv.deputado_id,
      MAX(pv.nome)          AS nome,
      MAX(pv.sigla_partido) AS sigla_partido,
      MAX(pv.sigla_uf)      AS sigla_uf,
      MAX(pv.url_foto)      AS url_foto,
      COUNT(*)                                                             AS presencas,
      SUM(CASE WHEN pv.tipo_voto = 'Sim'       THEN 1 ELSE 0 END)        AS votos_sim,
      SUM(CASE WHEN pv.tipo_voto = 'Não'       THEN 1 ELSE 0 END)        AS votos_nao,
      SUM(CASE WHEN pv.tipo_voto = 'Abstenção' THEN 1 ELSE 0 END)        AS votos_abstencao,
      SUM(CASE WHEN pv.tipo_voto = 'Obstrução' THEN 1 ELSE 0 END)        AS votos_obstrucao,
      SUM(CASE WHEN pv.tipo_voto = 'Art. 17'   THEN 1 ELSE 0 END)        AS votos_artigo17
    FROM plen_votos pv
    JOIN plen_votacoes v ON v.id = pv.votacao_id AND v.id_legislatura = p_legislatura
    GROUP BY pv.deputado_id
  ) sub
  LEFT JOIN (
    -- Concordância: % votações onde o dep. seguiu orientação do partido
    -- (exclui "Liberado" e "Art. 17" — sem orientação vinculante)
    SELECT
      pv.deputado_id,
      ROUND(
        SUM(CASE WHEN pv.tipo_voto = o.orientacao THEN 1.0 ELSE 0.0 END)
        / NULLIF(COUNT(*), 0) * 100,
        2
      ) AS concordancia_partido
    FROM plen_votos pv
    JOIN plen_votacoes v    ON v.id = pv.votacao_id AND v.id_legislatura = p_legislatura
    JOIN plen_orientacoes o
      ON  o.votacao_id    = pv.votacao_id
      AND o.sigla_bancada = pv.sigla_partido
      AND o.orientacao NOT IN ('Liberado', 'Art. 17')
    GROUP BY pv.deputado_id
  ) conc ON conc.deputado_id = sub.deputado_id;

  GET DIAGNOSTICS v_deputados_inseridos = ROW_COUNT;

  RETURN jsonb_build_object(
    'status',                'sucesso',
    'legislatura',           p_legislatura,
    'total_votacoes_nominais', v_total_votacoes,
    'deputados_processados', v_deputados_inseridos
  );
END;
$$;

CREATE OR REPLACE FUNCTION "public"."cvm_fip_monopolio_historico"("p_cnpj" "text") RETURNS TABLE("dt_comptc" "date", "vl_patrim_liq" numeric, "vl_cap_integr" numeric, "vl_cap_compr" numeric, "nr_cotst" integer, "pr_pf" numeric, "qt_cota" numeric)
    LANGUAGE "sql" STABLE
    AS $$
  select
    dt_comptc,
    max(vl_patrim_liq)  as vl_patrim_liq,
    max(vl_cap_integr)  as vl_cap_integr,
    max(vl_cap_compr)   as vl_cap_compr,
    min(nr_cotst)       as nr_cotst,
    max(pr_pf)          as pr_pf,
    max(qt_cota)        as qt_cota
  from cvm_fip_informe
  where cnpj_norm = regexp_replace(coalesce(p_cnpj, ''), '\D', '', 'g')
  group by dt_comptc
  order by dt_comptc;
$$;

CREATE OR REPLACE FUNCTION "public"."cvm_grafo_vizinhanca"("p_cnpj" "text", "p_prof" integer DEFAULT 3) RETURNS TABLE("cnpj_origem" "text", "cnpj_destino" "text", "denom_destino" "text", "vl_merc" numeric, "profundidade" integer, "direcao" "text")
    LANGUAGE "sql" STABLE
    AS $$
  with recursive
  base as (
    select regexp_replace(coalesce(p_cnpj,''), '\D', '', 'g') as c
  ),
  -- downstream: seed → o que ele detém → ...
  down as (
    select e.cnpj_fundo as cnpj_origem, e.cnpj_ativo as cnpj_destino,
           e.denom_ativo as denom_destino, e.vl_merc, 1 as profundidade
    from cvm_carteira_edge e, base
    where e.cnpj_fundo = base.c
    union all
    select e.cnpj_fundo, e.cnpj_ativo, e.denom_ativo, e.vl_merc, d.profundidade + 1
    from cvm_carteira_edge e
    join down d on e.cnpj_fundo = d.cnpj_destino
    where d.profundidade < p_prof
  ),
  -- upstream: quem detém o seed → quem detém esse → ...
  up as (
    select e.cnpj_fundo as cnpj_origem, e.cnpj_ativo as cnpj_destino,
           e.denom_ativo as denom_destino, e.vl_merc, 1 as profundidade
    from cvm_carteira_edge e, base
    where e.cnpj_ativo = base.c
    union all
    select e.cnpj_fundo, e.cnpj_ativo, e.denom_ativo, e.vl_merc, u.profundidade + 1
    from cvm_carteira_edge e
    join up u on e.cnpj_ativo = u.cnpj_origem
    where u.profundidade < p_prof
  )
  select cnpj_origem, cnpj_destino, denom_destino, vl_merc, profundidade, 'downstream' from down
  union all
  select cnpj_origem, cnpj_destino, denom_destino, vl_merc, profundidade, 'upstream' from up;
$$;

CREATE OR REPLACE FUNCTION "public"."detect_narrative_events"() RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
begin

insert into narrative_events (
  tipo_evento,
  parlamentar,
  valor_total,
  narrativa,
  impacto_publico
)

select
  'ASCENSAO_ORCAMENTARIA',
  parlamentar,
  valor_total,

  parlamentar || ' entrou entre os maiores executores de recursos federais em emendas parlamentares.',

  'Alta influência orçamentária nacional.'

from indice_poder_orcamentario
where valor_total >
(
  select percentile_cont(0.9)
  within group (order by valor_total)
  from indice_poder_orcamentario
);

end;
$$;

CREATE OR REPLACE FUNCTION "public"."distinct_dates"("p_table" "text", "p_date_col" "text", "p_since" "date") RETURNS TABLE("d" "date")
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $_$
begin
  perform set_config('statement_timeout', '60000', true);

  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = p_table and column_name = p_date_col
  ) then
    raise exception 'Coluna % não existe em public.%', p_date_col, p_table;
  end if;

  return query execute format(
    'select distinct %I::date as d from public.%I where %I >= $1 order by 1',
    p_date_col, p_table, p_date_col
  ) using p_since;
end;
$_$;

CREATE OR REPLACE FUNCTION "public"."exec_readonly_query"("sql_query" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$
declare
  result jsonb;
  safe_query text;
begin
  set local transaction_read_only = on;
  set local statement_timeout = '25s';
  set local lock_timeout = '2s';
  set local idle_in_transaction_session_timeout = '30s';
  set local work_mem = '64MB';

  safe_query := trim(sql_query);
  if right(safe_query, 1) = ';' then
    safe_query := left(safe_query, length(safe_query) - 1);
  end if;

  -- Word boundary em PG ARE: \m (begin) e \M (end). NÃO usar \b
  -- (em PG é backspace, não boundary).
  if upper(safe_query) !~ '\mLIMIT\M' then
    safe_query := safe_query || ' LIMIT 200';
  end if;

  execute format('select coalesce(jsonb_agg(t), ''[]''::jsonb) from (%s) t', safe_query)
  into result;

  return result;
exception
  when query_canceled then
    raise exception 'SQL execution: query demorou mais que 25s. Tente filtrar por ano, partido ou tipo de despesa específico.';
  when others then
    raise exception 'SQL execution: %', sqlerrm;
end;
$$;

CREATE OR REPLACE FUNCTION "public"."execute_sql"("query" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  result JSONB;
BEGIN
  EXECUTE 'SELECT jsonb_agg(row_to_json(t)) FROM (' || query || ') t'
  INTO result;
  RETURN COALESCE(result, '[]'::jsonb);
END;
$$;

CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, plano)
  VALUES (NEW.id, NEW.email, 'free')
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION "public"."limpar_ask_cache_expirado"() RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  deletadas int;
begin
  delete from ask_cache where expires_at < now();
  get diagnostics deletadas = row_count;
  return deletadas;
end;
$$;

CREATE OR REPLACE FUNCTION "public"."months_present"("p_table" "text", "p_date_col" "text") RETURNS TABLE("ano_mes" "text", "n" bigint)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  perform set_config('statement_timeout', '60000', true);

  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = p_table and column_name = p_date_col
  ) then
    raise exception 'Coluna % não existe em public.%', p_date_col, p_table;
  end if;

  return query execute format(
    'select to_char(date_trunc(''month'', %I), ''YYYY-MM'') as ano_mes, count(*)::bigint as n
     from public.%I
     where %I is not null
     group by 1
     order by 1',
    p_date_col, p_table, p_date_col
  );
end;
$$;

CREATE OR REPLACE FUNCTION "public"."premium_aggregate"("p_source" "text", "p_sum_col" "text", "p_filters" "jsonb" DEFAULT '{}'::"jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_allowed   JSONB := '{
    "pbh_despesas_orcamentarias": ["vl_pago","vl_empenhado","vl_liquidado"],
    "mg_siafi_execucao":          ["valor_pago","valor_empenhado","valor_liquidado"],
    "rs_despesas":                ["valor"],
    "alesc_despesas":             ["valor"],
    "mg_supersalarios":           ["valor_excedente","remuneracao_bruta"],
    "mg_obras_paradas":           ["valor_total","total_medido"],
    "mg_cruzamento_emendas":      ["total_pago_mg","total_emendas_fed"],
    "tse_despesas":               ["valor_despesa"],
    "tse_receitas":               ["valor"],
    "v_sancao_emenda":            ["valor_emenda"],
    "tse_conta_receita":          ["vr_receita"],
    "tse_conta_despesa":          ["vr_despesa"],
    "tse_conta_extrato":          ["vr_lancamento"],
    "tse_conta_notafiscal":       ["vr_documento"]
  }'::jsonb;
  v_allowed_cols JSONB;
  v_key   TEXT;
  v_val   TEXT;
  v_where TEXT := '';
  v_sql   TEXT;
  v_result JSONB;
BEGIN
  v_allowed_cols := v_allowed -> p_source;
  IF v_allowed_cols IS NULL THEN
    RAISE EXCEPTION 'source não permitido: %', p_source;
  END IF;
  IF NOT (v_allowed_cols @> to_jsonb(p_sum_col)) THEN
    RAISE EXCEPTION 'coluna não permitida: %', p_sum_col;
  END IF;
  FOR v_key, v_val IN
    SELECT key, value #>> '{}'
    FROM jsonb_each(p_filters)
    WHERE value #>> '{}' IS NOT NULL AND value #>> '{}' <> ''
  LOOP
    v_where := v_where || format(' AND %I = %L', v_key, v_val);
  END LOOP;
  v_sql := format(
    'SELECT count(*)::int AS total_count, coalesce(sum(%I),0)::numeric AS total_sum FROM %I WHERE TRUE %s',
    p_sum_col, p_source, v_where
  );
  EXECUTE v_sql INTO v_result;
  RETURN v_result;
END;
$$;

CREATE OR REPLACE FUNCTION "public"."refresh_almg_fornecedores_intersetados"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_config('statement_timeout', '180000', false);
  REFRESH MATERIALIZED VIEW CONCURRENTLY public.almg_fornecedores_intersetados;
END;
$$;

CREATE OR REPLACE FUNCTION "public"."refresh_ask_views"() RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
begin
  refresh materialized view ask_ceap_fornecedor_agg;
  refresh materialized view ask_ceap_tipo_ano_agg;
  refresh materialized view ask_ceap_deputado_ano_agg;
  refresh materialized view ask_emendas_autor_ano_agg;
end;
$$;

CREATE OR REPLACE FUNCTION "public"."refresh_cota_cnpj_ranking"() RETURNS "void"
    LANGUAGE "sql"
    AS $$
  REFRESH MATERIALIZED VIEW CONCURRENTLY public.cota_cnpj_ranking;
$$;

CREATE OR REPLACE FUNCTION "public"."refresh_fornecedores_intersetados"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_config('statement_timeout', '180000', false);
  REFRESH MATERIALIZED VIEW CONCURRENTLY public.fornecedores_intersetados;
END;
$$;

CREATE OR REPLACE FUNCTION "public"."refresh_indice_poder"() RETURNS "void"
    LANGUAGE "sql"
    AS $$
refresh materialized view indice_poder_orcamentario;
$$;

CREATE OR REPLACE FUNCTION "public"."refresh_judiciario_stats"() RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY public.judiciario_stats_por_tribunal;
  REFRESH MATERIALIZED VIEW CONCURRENTLY public.judiciario_stats_por_ano_tribunal;
  REFRESH MATERIALIZED VIEW CONCURRENTLY public.judiciario_stats_por_classe_tribunal;
  REFRESH MATERIALIZED VIEW CONCURRENTLY public.judiciario_stats_por_relator;
END;
$$;

CREATE OR REPLACE FUNCTION "public"."refresh_mv_cota_fornecedor"() RETURNS "void"
    LANGUAGE "sql"
    AS $$
  REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_cota_fornecedor;
$$;

CREATE OR REPLACE FUNCTION "public"."refresh_mv_execucao_emendas"() RETURNS "void"
    LANGUAGE "sql"
    AS $$
refresh materialized view analytics.mv_execucao_emendas_parlamentares_v2;
$$;

CREATE OR REPLACE FUNCTION "public"."refresh_mv_scorecard_cnpj"() RETURNS "void"
    LANGUAGE "plpgsql"
    SET "statement_timeout" TO '0'
    SET "lock_timeout" TO '0'
    AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_scorecard_cnpj;
END;
$$;

CREATE OR REPLACE FUNCTION "public"."refresh_mv_tse_ads_digitais"() RETURNS "void"
    LANGUAGE "sql"
    AS $$
  REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_tse_ads_digitais;
$$;

CREATE OR REPLACE FUNCTION "public"."refresh_stats"() RETURNS "void"
    LANGUAGE "sql"
    AS $$
  SELECT public.refresh_judiciario_stats();
$$;

CREATE OR REPLACE FUNCTION "public"."search_fundacoes"("termo" "text" DEFAULT NULL::"text", "partido" "text" DEFAULT NULL::"text", "so_alertas" boolean DEFAULT false, "limite" integer DEFAULT 25) RETURNS TABLE("cnpj" "text", "nome_popular" "text", "partido_sigla" "text", "presidente_nome" "text", "total_repassado_2024" numeric, "pct_q4_2024" numeric, "total_aluguel_2024" numeric, "mesmo_endereco_partido" boolean, "score_alertas" integer, "relevancia" real)
    LANGUAGE "sql" STABLE
    AS $$
  SELECT
    r.cnpj,
    r.nome_popular,
    r.partido_sigla,
    r.presidente_nome,
    r.total_repassado_2024,
    r.pct_q4_2024,
    r.total_aluguel_2024,
    r.mesmo_endereco_partido,
    r.score_alertas,
    CASE
      WHEN termo IS NOT NULL THEN
        ts_rank(
          to_tsvector('portuguese',
            coalesce(r.nome_popular,'') || ' ' ||
            coalesce(r.partido_sigla,'') || ' ' ||
            coalesce(r.presidente_nome,'')),
          plainto_tsquery('portuguese', termo)
        )
      ELSE 1.0
    END AS relevancia
  FROM fundacoes_ranking_publico r
  WHERE
    (termo IS NULL OR to_tsvector('portuguese',
      coalesce(r.nome_popular,'') || ' ' ||
      coalesce(r.partido_sigla,'') || ' ' ||
      coalesce(r.presidente_nome,''))
      @@ plainto_tsquery('portuguese', termo))
    AND (partido IS NULL OR upper(r.partido_sigla) = upper(partido))
    AND (NOT so_alertas OR r.score_alertas > 0)
  ORDER BY relevancia DESC, r.total_repassado_2024 DESC
  LIMIT LEAST(limite, 100);
$$;

CREATE OR REPLACE FUNCTION "public"."set_cnpjs_limit"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  new.cnpjs_limit := case new.plan
    when 'essencial'    then 10
    when 'profissional' then 50
    else 999999
  end;
  new.updated_at := now();
  return new;
end;
$$;

CREATE OR REPLACE FUNCTION "public"."siafi_stats"() RETURNS TABLE("total_cnpjs" bigint, "total_pagamentos" bigint, "soma_brl" numeric)
    LANGUAGE "sql" STABLE
    AS $$
  SELECT
    COUNT(*)::bigint,
    SUM(n_pagamentos)::bigint,
    SUM(valor_total)
  FROM mv_siafi_fornecedores;
$$;

CREATE OR REPLACE FUNCTION "public"."stf_refresh_matviews"() RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY stf_ministros_perfil;
    REFRESH MATERIALIZED VIEW CONCURRENTLY stf_tendencia_classe;
    REFRESH MATERIALIZED VIEW CONCURRENTLY stf_tendencia_orgao;
END;
$$;
-- bloco 08_views_e_matviews — COMBINADO: dependências existem nas duas
-- direções (view→MV e MV→view); a ordem original do pg_dump é topológica.

CREATE OR REPLACE VIEW "analytics"."vw_emendas_classificadas" AS
 SELECT "id",
    "mandato_id",
    "municipio_id",
    "tipo",
    "valor",
    "ano",
    "data_liberacao",
    "ministerio",
    "objeto",
    "created_at",
    "valor_empenhado",
    "valor_liquidado",
    "valor_pago",
    "codigo_emenda",
    "funcao",
    "subfuncao",
    "municipio",
    "uf",
    "autor_orcamentario_id",
    "uf_destino",
    "municipio_nome",
    "parlamentar_id",
    "ministerio_id",
    "orgao_id",
        CASE
            WHEN ("mandato_id" IS NOT NULL) THEN 'parlamentar'::"text"
            WHEN ("parlamentar_id" IS NOT NULL) THEN 'parlamentar'::"text"
            ELSE 'institucional'::"text"
        END AS "tipo_emenda"
   FROM "public"."emendas" "e";



CREATE OR REPLACE VIEW "analytics"."vw_execucao_emendas_parlamentares" AS
 SELECT "m"."parlamentar_uid",
    "sum"(COALESCE("e"."valor_pago", (0)::numeric)) AS "valor_pago_emendas"
   FROM ("analytics"."vw_emendas_classificadas" "e"
     JOIN "public"."mandatos" "m" ON (("m"."id" = "e"."mandato_id")))
  WHERE ("e"."tipo_emenda" = 'parlamentar'::"text")
  GROUP BY "m"."parlamentar_uid";



CREATE MATERIALIZED VIEW "analytics"."mv_execucao_emendas_parlamentares" AS
 SELECT "parlamentar_uid",
    "valor_pago_emendas"
   FROM "analytics"."vw_execucao_emendas_parlamentares"
  WITH NO DATA;



CREATE MATERIALIZED VIEW "analytics"."mv_execucao_emendas_parlamentares_v2" AS
 SELECT "parlamentar_uid",
    "valor_pago_emendas"
   FROM "analytics"."vw_execucao_emendas_parlamentares"
  WITH NO DATA;



CREATE OR REPLACE VIEW "analytics"."vw_emendas_resolvidas" AS
 WITH "mandato_via_data" AS (
         SELECT "e_1"."id" AS "emenda_id",
            "m"."id" AS "mandato_id_resolvido",
            "m"."parlamentar_uid" AS "parlamentar_uid_resolvido",
            "row_number"() OVER (PARTITION BY "e_1"."id" ORDER BY "m"."ativo" DESC, "m"."legislatura" DESC, "m"."inicio" DESC, "m"."id" DESC) AS "rn"
           FROM ("public"."emendas" "e_1"
             JOIN "public"."mandatos" "m" ON ((("m"."parlamentar_id" = "e_1"."parlamentar_id") AND ("e_1"."data_liberacao" IS NOT NULL) AND ("e_1"."data_liberacao" >= "m"."inicio") AND ("e_1"."data_liberacao" <= COALESCE("m"."fim", 'infinity'::"date")))))
          WHERE ("e_1"."mandato_id" IS NULL)
        ), "mandato_fallback" AS (
         SELECT "e_1"."id" AS "emenda_id",
            "m"."id" AS "mandato_id_resolvido",
            "m"."parlamentar_uid" AS "parlamentar_uid_resolvido",
            "row_number"() OVER (PARTITION BY "e_1"."id" ORDER BY "m"."ativo" DESC, "m"."legislatura" DESC, "m"."inicio" DESC, "m"."id" DESC) AS "rn"
           FROM ("public"."emendas" "e_1"
             JOIN "public"."mandatos" "m" ON (("m"."parlamentar_id" = "e_1"."parlamentar_id")))
          WHERE (("e_1"."mandato_id" IS NULL) AND ("e_1"."data_liberacao" IS NULL))
        ), "uid_via_mandato" AS (
         SELECT "e_1"."id" AS "emenda_id",
            "m"."id" AS "mandato_id_resolvido",
            "m"."parlamentar_uid" AS "parlamentar_uid_resolvido"
           FROM ("public"."emendas" "e_1"
             JOIN "public"."mandatos" "m" ON (("m"."id" = "e_1"."mandato_id")))
        )
 SELECT "e"."id",
    "e"."mandato_id",
    "e"."municipio_id",
    "e"."tipo",
    "e"."valor",
    "e"."ano",
    "e"."data_liberacao",
    "e"."ministerio",
    "e"."objeto",
    "e"."created_at",
    "e"."valor_empenhado",
    "e"."valor_liquidado",
    "e"."valor_pago",
    "e"."codigo_emenda",
    "e"."funcao",
    "e"."subfuncao",
    "e"."municipio",
    "e"."uf",
    "e"."autor_orcamentario_id",
    "e"."uf_destino",
    "e"."municipio_nome",
    "e"."parlamentar_id",
    "e"."ministerio_id",
    "e"."orgao_id",
    COALESCE("uvm"."mandato_id_resolvido", "mvd"."mandato_id_resolvido", "mf"."mandato_id_resolvido") AS "mandato_resolvido_id",
    COALESCE("uvm"."parlamentar_uid_resolvido", "mvd"."parlamentar_uid_resolvido", "mf"."parlamentar_uid_resolvido") AS "parlamentar_uid_resolvido"
   FROM ((("public"."emendas" "e"
     LEFT JOIN "uid_via_mandato" "uvm" ON (("uvm"."emenda_id" = "e"."id")))
     LEFT JOIN "mandato_via_data" "mvd" ON ((("mvd"."emenda_id" = "e"."id") AND ("mvd"."rn" = 1))))
     LEFT JOIN "mandato_fallback" "mf" ON ((("mf"."emenda_id" = "e"."id") AND ("mf"."rn" = 1))));



CREATE OR REPLACE VIEW "analytics"."vw_execucao_emendas_por_parlamentar" AS
 SELECT "m"."parlamentar_uid",
    "sum"(COALESCE("e"."valor_pago", (0)::numeric)) AS "valor_pago_emendas"
   FROM ("public"."emendas" "e"
     JOIN "public"."mandatos" "m" ON (("m"."id" = "e"."mandato_id")))
  WHERE ("m"."parlamentar_uid" IS NOT NULL)
  GROUP BY "m"."parlamentar_uid";



CREATE OR REPLACE VIEW "analytics"."vw_execucao_emendas_por_uid" AS
 SELECT "parlamentar_uid_resolvido" AS "parlamentar_uid",
    "sum"(COALESCE("valor_pago", (0)::numeric)) AS "valor_pago_emendas"
   FROM "analytics"."vw_emendas_resolvidas" "e"
  WHERE ("parlamentar_uid_resolvido" IS NOT NULL)
  GROUP BY "parlamentar_uid_resolvido";



CREATE OR REPLACE VIEW "analytics"."vw_fato_execucao_emendas" AS
 SELECT "parlamentar_uid",
    "valor_pago_emendas"
   FROM "analytics"."mv_execucao_emendas_parlamentares_v2";



CREATE OR REPLACE VIEW "analytics"."vw_integridade_pipeline_emendas" AS
 SELECT "count"(*) AS "total_emendas",
    "count"(*) FILTER (WHERE ("e"."mandato_id" IS NULL)) AS "emendas_sem_mandato_id",
    "count"(*) FILTER (WHERE (("e"."mandato_id" IS NOT NULL) AND ("m"."id" IS NULL))) AS "emendas_com_mandato_inexistente",
    "count"(*) FILTER (WHERE (("m"."id" IS NOT NULL) AND ("m"."parlamentar_uid" IS NULL))) AS "mandatos_sem_parlamentar_uid",
    "count"(*) FILTER (WHERE ("m"."parlamentar_uid" IS NOT NULL)) AS "emendas_com_uid_valido"
   FROM ("public"."emendas" "e"
     LEFT JOIN "public"."mandatos" "m" ON (("m"."id" = "e"."mandato_id")));



CREATE OR REPLACE VIEW "analytics"."vw_mandato_referencia" AS
 SELECT DISTINCT ON ("parlamentar_uid") "parlamentar_uid",
    "id" AS "mandato_id_referencia",
    "parlamentar_id"
   FROM "public"."mandatos" "m"
  WHERE ("parlamentar_uid" IS NOT NULL)
  ORDER BY "parlamentar_uid", "id" DESC;



CREATE OR REPLACE VIEW "analytics"."vw_obs_base_emendas" AS
 SELECT "f"."parlamentar_uid",
    "f"."valor_pago_emendas",
    "mr"."mandato_id_referencia"
   FROM ("analytics"."vw_fato_execucao_emendas" "f"
     LEFT JOIN "analytics"."vw_mandato_referencia" "mr" ON (("mr"."parlamentar_uid" = "f"."parlamentar_uid")));



CREATE OR REPLACE VIEW "analytics"."vw_obs_parlamentares_sem_execucao" AS
 SELECT "mr"."parlamentar_uid",
    "mr"."mandato_id_referencia"
   FROM ("analytics"."vw_mandato_referencia" "mr"
     LEFT JOIN "analytics"."vw_fato_execucao_emendas" "f" ON (("f"."parlamentar_uid" = "mr"."parlamentar_uid")))
  WHERE ("f"."parlamentar_uid" IS NULL);



CREATE OR REPLACE VIEW "analytics"."vw_perda_financeira_pipeline" AS
 SELECT "sum"(COALESCE("e"."valor_pago", (0)::numeric)) AS "valor_total_emendas",
    "sum"(
        CASE
            WHEN ("m"."parlamentar_uid" IS NULL) THEN COALESCE("e"."valor_pago", (0)::numeric)
            ELSE (0)::numeric
        END) AS "valor_perdido_sem_uid",
    "sum"(
        CASE
            WHEN ("m"."parlamentar_uid" IS NOT NULL) THEN COALESCE("e"."valor_pago", (0)::numeric)
            ELSE (0)::numeric
        END) AS "valor_valido_ranking"
   FROM ("public"."emendas" "e"
     LEFT JOIN "public"."mandatos" "m" ON (("m"."id" = "e"."mandato_id")));



CREATE OR REPLACE VIEW "analytics"."vw_public_ranking_source_compat" AS
 SELECT "parlamentar_uid" AS "parlamentar_id",
    NULL::numeric AS "total_emendas",
    NULL::numeric AS "valor_total_emendas",
    "valor_pago_emendas"
   FROM "analytics"."mv_execucao_emendas_parlamentares_v2";



CREATE OR REPLACE VIEW "public_api"."vw_public_ranking" AS
 WITH "ranked" AS (
         SELECT "s"."parlamentar_id",
            "s"."total_emendas",
            "s"."valor_total_emendas",
            "s"."valor_pago_emendas",
            "rank"() OVER (ORDER BY "s"."valor_pago_emendas" DESC NULLS LAST) AS "posicao_nacional"
           FROM "analytics"."vw_public_ranking_source_compat" "s"
        )
 SELECT "r"."parlamentar_id",
    COALESCE("p"."nome", 'PARLAMENTAR NÃO RESOLVIDO'::"text") AS "nome",
    "p"."nome_parlamentar",
    COALESCE("p"."partido_atual", "p"."partido") AS "partido",
    "p"."uf",
    "p"."foto_url",
    "r"."posicao_nacional",
    "r"."total_emendas",
    "r"."valor_total_emendas",
    "r"."valor_pago_emendas"
   FROM ("ranked" "r"
     LEFT JOIN "public"."parlamentares" "p" ON (("p"."parlamentar_uid" = "r"."parlamentar_id")));



CREATE OR REPLACE VIEW "analytics"."vw_sanity_duplicacao_ranking" AS
 SELECT ( SELECT "count"(*) AS "count"
           FROM "analytics"."vw_fato_execucao_emendas") AS "linhas_fato",
    ( SELECT "count"(*) AS "count"
           FROM "public_api"."vw_public_ranking") AS "linhas_publicas",
    ( SELECT "sum"("vw_fato_execucao_emendas"."valor_pago_emendas") AS "sum"
           FROM "analytics"."vw_fato_execucao_emendas") AS "soma_fato",
    ( SELECT "sum"("vw_public_ranking"."valor_pago_emendas") AS "sum"
           FROM "public_api"."vw_public_ranking") AS "soma_publica";



CREATE OR REPLACE VIEW "analytics"."vw_sanity_emendas" AS
 SELECT ( SELECT "sum"("vw_emendas_classificadas"."valor_pago") AS "sum"
           FROM "analytics"."vw_emendas_classificadas") AS "total_emendas",
    ( SELECT "sum"("vw_execucao_emendas_parlamentares"."valor_pago_emendas") AS "sum"
           FROM "analytics"."vw_execucao_emendas_parlamentares") AS "total_parlamentares",
    ( SELECT "sum"("vw_emendas_classificadas"."valor_pago") AS "sum"
           FROM "analytics"."vw_emendas_classificadas"
          WHERE ("vw_emendas_classificadas"."tipo_emenda" = 'institucional'::"text")) AS "total_institucionais";



CREATE OR REPLACE VIEW "bcb"."v_emendas_x_sicor" AS
 SELECT "ic"."cnpj_lider",
    "ic"."nome_instituicao",
    "ic"."segmento",
    "ic"."uf" AS "uf_sede_if",
    "sum"("ef"."valor_recebido") AS "total_emendas_recebido",
    "count"(DISTINCT "ef"."id") AS "qt_emendas",
    "count"(DISTINCT "ef"."nome_autor") AS "qt_autores_emendas",
    "sum"("sr"."vl_total") AS "total_credito_rural",
    "sum"("sr"."qt_contratos") AS "qt_contratos_rurais"
   FROM (("bcb"."if_cadastro" "ic"
     JOIN "bcb"."sicor_credito_rural" "sr" ON (("sr"."cnpj_if" = "left"("ic"."cnpj_lider", 8))))
     LEFT JOIN "public"."emendas_favorecidos" "ef" ON (("left"("ef"."codigo_favorecido", 8) = "left"("ic"."cnpj_lider", 8))))
  GROUP BY "ic"."cnpj_lider", "ic"."nome_instituicao", "ic"."segmento", "ic"."uf";



CREATE OR REPLACE VIEW "bcb"."v_scr_resumo_uf" AS
 SELECT "data_base",
    "uf",
    "segmento",
    "cliente",
    "sum"("numero_de_operacoes") AS "total_operacoes",
    "sum"("carteira_ativa") AS "carteira_ativa",
    "sum"("carteira_inadimplencia") AS "carteira_inadimplencia",
    "round"((("sum"("carteira_inadimplencia") / NULLIF("sum"("carteira_ativa"), (0)::numeric)) * (100)::numeric), 2) AS "pct_inadimplencia",
    "sum"("ativo_problematico") AS "ativo_problematico"
   FROM "bcb"."scr_operacoes"
  GROUP BY "data_base", "uf", "segmento", "cliente";



CREATE OR REPLACE VIEW "homabrasil"."v_municipio_card" AS
 SELECT "m"."codigo_ibge",
    "m"."nome",
    "m"."uf",
    "m"."regiao",
    "m"."populacao",
    "m"."lat",
    "m"."lng",
    "s"."homa_score",
    "s"."tier",
    "s"."score_qualidade_vida",
    "s"."score_infraestrutura",
    "s"."score_clima",
    "qv"."idhm",
    "qv"."renda_per_capita",
    "rc"."risco_enchente",
    "rc"."risco_seca",
    "rc"."risco_deslizamento",
    "rc"."monitorado_cemaden",
    "rc"."total_decretos_10anos",
    "rc"."total_mortos_10anos"
   FROM ((("homabrasil"."municipios" "m"
     LEFT JOIN "homabrasil"."homa_score" "s" ON ((("s"."municipio_id" = "m"."id") AND ("s"."ano_ref" = 2024))))
     LEFT JOIN "homabrasil"."qualidade_vida" "qv" ON ((("qv"."municipio_id" = "m"."id") AND ("qv"."ano" = 2010))))
     LEFT JOIN "homabrasil"."risco_climatico" "rc" ON ((("rc"."municipio_id" = "m"."id") AND ("rc"."ano_ref" = 2024))));



CREATE OR REPLACE VIEW "portal_transparencia"."alerta_sancionado_recebendo" AS
 SELECT "s"."cnpj_cpf_sancionado" AS "cnpj_cpf",
    "f"."razao_social",
    "s"."cadastro",
    "s"."tipo_sancao",
    "s"."orgao_sancionador",
    "s"."data_inicio_sancao",
    "s"."data_final_sancao",
    ( SELECT "count"(*) AS "count"
           FROM "portal_transparencia"."notas_fiscais" "nf"
          WHERE (("nf"."cnpj_emitente" = "s"."cnpj_cpf_sancionado") AND ("nf"."data_emissao" >= "s"."data_inicio_sancao") AND (("s"."data_final_sancao" IS NULL) OR ("nf"."data_emissao" <= "s"."data_final_sancao")))) AS "nf_durante_sancao_qtd",
    ( SELECT COALESCE("sum"("nf"."valor_total"), (0)::numeric) AS "coalesce"
           FROM "portal_transparencia"."notas_fiscais" "nf"
          WHERE (("nf"."cnpj_emitente" = "s"."cnpj_cpf_sancionado") AND ("nf"."data_emissao" >= "s"."data_inicio_sancao") AND (("s"."data_final_sancao" IS NULL) OR ("nf"."data_emissao" <= "s"."data_final_sancao")))) AS "nf_durante_sancao_valor",
    ( SELECT "count"(*) AS "count"
           FROM "portal_transparencia"."cartoes_pagamento" "c"
          WHERE (("c"."cnpj_estabelecimento" = "s"."cnpj_cpf_sancionado") AND ("c"."data_transacao" >= "s"."data_inicio_sancao") AND (("s"."data_final_sancao" IS NULL) OR ("c"."data_transacao" <= "s"."data_final_sancao")))) AS "cartoes_durante_sancao_qtd"
   FROM ("portal_transparencia"."sancoes" "s"
     JOIN "portal_transparencia"."favorecidos" "f" ON (("f"."cnpj_cpf" = "s"."cnpj_cpf_sancionado")));



CREATE OR REPLACE VIEW "portal_transparencia"."ficha_favorecido" AS
 SELECT "cnpj_cpf",
    "tipo",
    "razao_social",
    "uf",
    "municipio_nome",
    ( SELECT "count"(*) AS "count"
           FROM "portal_transparencia"."sancoes" "s"
          WHERE (("s"."cnpj_cpf_sancionado" = "f"."cnpj_cpf") AND ("s"."data_inicio_sancao" <= CURRENT_DATE) AND (("s"."data_final_sancao" IS NULL) OR ("s"."data_final_sancao" >= CURRENT_DATE)))) AS "sancoes_ativas_qtd",
    ( SELECT "count"(*) AS "count"
           FROM "portal_transparencia"."notas_fiscais" "nf"
          WHERE ("nf"."cnpj_emitente" = "f"."cnpj_cpf")) AS "nf_emitidas_qtd",
    ( SELECT COALESCE("sum"("nf"."valor_total"), (0)::numeric) AS "coalesce"
           FROM "portal_transparencia"."notas_fiscais" "nf"
          WHERE ("nf"."cnpj_emitente" = "f"."cnpj_cpf")) AS "nf_emitidas_valor",
    ( SELECT "max"("nf"."data_emissao") AS "max"
           FROM "portal_transparencia"."notas_fiscais" "nf"
          WHERE ("nf"."cnpj_emitente" = "f"."cnpj_cpf")) AS "nf_ultima_emissao",
    ( SELECT "count"(*) AS "count"
           FROM "portal_transparencia"."cartoes_pagamento" "c"
          WHERE ("c"."cnpj_estabelecimento" = "f"."cnpj_cpf")) AS "cartoes_transacoes_qtd",
    ( SELECT COALESCE("sum"("c"."valor"), (0)::numeric) AS "coalesce"
           FROM "portal_transparencia"."cartoes_pagamento" "c"
          WHERE ("c"."cnpj_estabelecimento" = "f"."cnpj_cpf")) AS "cartoes_valor_total"
   FROM "portal_transparencia"."favorecidos" "f";



CREATE OR REPLACE VIEW "portal_transparencia"."top_fornecedores_orgao_12m" AS
 SELECT "c"."codigo_orgao",
    "c"."nome_orgao",
    "c"."cnpj_estabelecimento" AS "cnpj_cpf",
    "f"."razao_social",
    "count"(*) AS "transacoes_qtd",
    "sum"("c"."valor") AS "valor_total"
   FROM ("portal_transparencia"."cartoes_pagamento" "c"
     LEFT JOIN "portal_transparencia"."favorecidos" "f" ON (("f"."cnpj_cpf" = "c"."cnpj_estabelecimento")))
  WHERE (("c"."data_transacao" >= (CURRENT_DATE - '1 year'::interval)) AND ("c"."cnpj_estabelecimento" IS NOT NULL))
  GROUP BY "c"."codigo_orgao", "c"."nome_orgao", "c"."cnpj_estabelecimento", "f"."razao_social";



CREATE OR REPLACE VIEW "public"."agenda_audiencias_publicas" AS
 SELECT 'camara'::"text" AS "casa",
    "id",
    "data_inicio_date" AS "data",
    "data_hora_inicio",
    "descricao",
    "local_nome" AS "local",
    "orgaos_siglas" AS "orgaos",
    "situacao",
    "url_documento_pauta" AS "url_pauta"
   FROM "public"."agenda_camara_eventos"
  WHERE (("tipo_evento" ~~* '%audiência pública%'::"text") OR ("tipo_evento" ~~* '%audiencia publica%'::"text"))
  ORDER BY "data_hora_inicio" DESC;



CREATE OR REPLACE VIEW "public"."agenda_federal_completa" AS
 SELECT 'executivo'::"text" AS "poder",
    "agenda_executivo_compromissos"."orgao_sigla" AS "orgao",
    (("agenda_executivo_compromissos"."data_inicio")::timestamp with time zone +
        CASE
            WHEN ("agenda_executivo_compromissos"."hora_inicio" ~ '^\d{2}:\d{2}$'::"text") THEN ("agenda_executivo_compromissos"."hora_inicio")::interval
            ELSE '00:00:00'::interval
        END) AS "data_hora",
    "agenda_executivo_compromissos"."data_inicio",
    "agenda_executivo_compromissos"."tipo_compromisso" AS "tipo",
    "agenda_executivo_compromissos"."assunto" AS "descricao",
    "agenda_executivo_compromissos"."autoridade_nome" AS "responsavel",
    "agenda_executivo_compromissos"."local",
    "agenda_executivo_compromissos"."tem_participantes_privados" AS "envolve_privado"
   FROM "public"."agenda_executivo_compromissos"
  WHERE ("agenda_executivo_compromissos"."data_inicio" >= (CURRENT_DATE - 30))
UNION ALL
 SELECT 'legislativo_camara'::"text" AS "poder",
    COALESCE("array_to_string"("agenda_camara_eventos"."orgaos_siglas", '/'::"text"), 'PLEN'::"text") AS "orgao",
    "agenda_camara_eventos"."data_hora_inicio" AS "data_hora",
    "agenda_camara_eventos"."data_inicio_date" AS "data_inicio",
    "agenda_camara_eventos"."tipo_evento" AS "tipo",
    "agenda_camara_eventos"."descricao",
    NULL::"text" AS "responsavel",
    "agenda_camara_eventos"."local_nome" AS "local",
    false AS "envolve_privado"
   FROM "public"."agenda_camara_eventos"
  WHERE ("agenda_camara_eventos"."data_inicio_date" >= (CURRENT_DATE - 30))
UNION ALL
 SELECT 'legislativo_senado'::"text" AS "poder",
    "agenda_senado_comissoes"."comissao_sigla" AS "orgao",
    "agenda_senado_comissoes"."data_hora_inicio" AS "data_hora",
    "agenda_senado_comissoes"."data_inicio_date" AS "data_inicio",
    "agenda_senado_comissoes"."tipo_desc" AS "tipo",
    "agenda_senado_comissoes"."descricao",
    NULL::"text" AS "responsavel",
    "agenda_senado_comissoes"."local",
    false AS "envolve_privado"
   FROM "public"."agenda_senado_comissoes"
  WHERE ("agenda_senado_comissoes"."data_inicio_date" >= (CURRENT_DATE - 30))
UNION ALL
 SELECT 'legislativo_senado_plenario'::"text" AS "poder",
    "agenda_senado_plenario"."casa" AS "orgao",
    (((("agenda_senado_plenario"."data_sessao")::"text" || ' '::"text") || COALESCE("agenda_senado_plenario"."hora", '00:00'::"text")))::timestamp with time zone AS "data_hora",
    "agenda_senado_plenario"."data_sessao" AS "data_inicio",
    "agenda_senado_plenario"."tipo_sessao" AS "tipo",
    "agenda_senado_plenario"."evento_desc" AS "descricao",
    NULL::"text" AS "responsavel",
    "agenda_senado_plenario"."local",
    false AS "envolve_privado"
   FROM "public"."agenda_senado_plenario"
  WHERE ("agenda_senado_plenario"."data_sessao" >= (CURRENT_DATE - 30))
  ORDER BY 3;



CREATE OR REPLACE VIEW "public"."agenda_legislativo_semana" AS
 SELECT 'camara'::"text" AS "casa",
    "agenda_camara_eventos"."id",
    "agenda_camara_eventos"."data_inicio_date" AS "data",
    "agenda_camara_eventos"."data_hora_inicio",
    "agenda_camara_eventos"."tipo_evento" AS "tipo",
    "agenda_camara_eventos"."situacao",
    "agenda_camara_eventos"."descricao",
    "agenda_camara_eventos"."local_nome" AS "local",
    NULL::"text" AS "tipo_presenca",
    "agenda_camara_eventos"."orgaos_siglas" AS "orgaos",
    "agenda_camara_eventos"."url_registro" AS "url_video"
   FROM "public"."agenda_camara_eventos"
  WHERE ("agenda_camara_eventos"."data_inicio_date" >= (CURRENT_DATE - 7))
UNION ALL
 SELECT 'senado_comissao'::"text" AS "casa",
    "agenda_senado_comissoes"."id",
    "agenda_senado_comissoes"."data_inicio_date" AS "data",
    "agenda_senado_comissoes"."data_hora_inicio",
    "agenda_senado_comissoes"."tipo_desc" AS "tipo",
    "agenda_senado_comissoes"."situacao",
    "agenda_senado_comissoes"."descricao",
    "agenda_senado_comissoes"."local",
    "agenda_senado_comissoes"."tipo_presenca",
    ARRAY["agenda_senado_comissoes"."comissao_sigla"] AS "orgaos",
    NULL::"text" AS "url_video"
   FROM "public"."agenda_senado_comissoes"
  WHERE ("agenda_senado_comissoes"."data_inicio_date" >= (CURRENT_DATE - 7))
UNION ALL
 SELECT 'senado_plenario'::"text" AS "casa",
    "agenda_senado_plenario"."id",
    "agenda_senado_plenario"."data_sessao" AS "data",
    (((("agenda_senado_plenario"."data_sessao")::"text" || ' '::"text") || COALESCE("agenda_senado_plenario"."hora", '00:00'::"text")))::timestamp with time zone AS "data_hora_inicio",
    "agenda_senado_plenario"."tipo_sessao" AS "tipo",
    "agenda_senado_plenario"."situacao",
    "agenda_senado_plenario"."evento_desc" AS "descricao",
    "agenda_senado_plenario"."local",
    "agenda_senado_plenario"."tipo_presenca",
    NULL::"text"[] AS "orgaos",
    NULL::"text" AS "url_video"
   FROM "public"."agenda_senado_plenario"
  WHERE ("agenda_senado_plenario"."data_sessao" >= (CURRENT_DATE - 7))
  ORDER BY 4;



CREATE OR REPLACE VIEW "public"."agenda_ministerial_semana" AS
 SELECT "orgao_sigla",
    "autoridade_nome",
    "data_inicio",
    "hora_inicio",
    "tipo_compromisso",
    "assunto",
    "local",
    "tem_participantes_privados"
   FROM "public"."agenda_executivo_compromissos"
  WHERE ("data_inicio" >= (CURRENT_DATE - 7))
  ORDER BY "data_inicio", "orgao_sigla", "hora_inicio";



CREATE OR REPLACE VIEW "public"."agenda_ministerial_setor_privado" AS
 SELECT "id",
    "data_inicio",
    "hora_inicio",
    "orgao_sigla",
    "autoridade_nome",
    "autoridade_cargo",
    "tipo_compromisso",
    "assunto",
    "local",
    "n_participantes_privados",
    "participantes_privados",
    "publicado_em",
    "ultima_atualizacao"
   FROM "public"."agenda_executivo_compromissos"
  WHERE ("tem_participantes_privados" = true)
  ORDER BY "data_inicio" DESC, "orgao_sigla";



CREATE OR REPLACE VIEW "public"."alesp_deputados" AS
 SELECT "p"."id_externo" AS "matricula",
    "p"."nome",
    "p"."partido",
    "p"."tag_localizacao",
    "p"."foto_url",
    "p"."ativo",
    "p"."legislatura",
    "p"."metadata",
    "p"."ingested_at",
    "p"."updated_at"
   FROM ("public"."parlamentares_estaduais" "p"
     JOIN "public"."casas" "c" ON (("c"."id" = "p"."casa_id")))
  WHERE ("c"."sigla" = 'ALESP'::"text");



CREATE OR REPLACE VIEW "public"."ale_parlamentares_reconciliado" AS
 SELECT "p"."id" AS "ale_parlamentar_id",
    "p"."casa_id",
    "p"."nome",
    "p"."partido",
    "p"."slug",
    ("p"."raw" ->> 'Matricula'::"text") AS "matricula",
    "ad"."matricula" AS "gastos_matricula",
    ("ad"."matricula" IS NOT NULL) AS "tem_dados_gastos"
   FROM ("public"."ale_parlamentares" "p"
     LEFT JOIN "public"."alesp_deputados" "ad" ON ((("p"."casa_id" = 'alesp'::"text") AND (("p"."raw" ->> 'Matricula'::"text") = "ad"."matricula"))));



CREATE OR REPLACE VIEW "public"."alepe_deputados" AS
 SELECT ("p"."id_externo")::integer AS "id_alepe",
    "p"."nome",
    "p"."partido",
    "p"."ativo",
    "p"."legislatura",
    "p"."metadata",
    "p"."ingested_at",
    "p"."updated_at"
   FROM ("public"."parlamentares_estaduais" "p"
     JOIN "public"."casas" "c" ON (("c"."id" = "p"."casa_id")))
  WHERE ("c"."sigla" = 'ALEPE'::"text");



CREATE OR REPLACE VIEW "public"."alepe_verba_indenizatoria" AS
 SELECT "g"."id",
    ("p"."id_externo")::integer AS "id_alepe",
    "g"."ano",
    "g"."mes",
    "g"."cod_categoria",
    "g"."categoria",
    "g"."fornecedor",
    "g"."cnpj_cpf",
    "g"."data_emissao",
    "g"."valor_bruto" AS "valor",
    "g"."metadata",
    "g"."ingested_at"
   FROM (("public"."gastos_parlamentares" "g"
     JOIN "public"."parlamentares_estaduais" "p" ON (("p"."id" = "g"."parlamentar_id")))
     JOIN "public"."casas" "c" ON (("c"."id" = "p"."casa_id")))
  WHERE ("c"."sigla" = 'ALEPE'::"text");



CREATE OR REPLACE VIEW "public"."alepe_verba_resumo_mensal" AS
 SELECT ("p"."id_externo")::integer AS "id_alepe",
    "p"."nome",
    "p"."partido",
    "p"."ativo",
    "p"."legislatura",
    "g"."ano",
    "g"."mes",
    "count"(*) AS "qtd_notas",
    "count"(DISTINCT "g"."cnpj_cpf") AS "qtd_fornecedores",
    "sum"("g"."valor_bruto") AS "total"
   FROM (("public"."gastos_parlamentares" "g"
     JOIN "public"."parlamentares_estaduais" "p" ON (("p"."id" = "g"."parlamentar_id")))
     JOIN "public"."casas" "c" ON (("c"."id" = "p"."casa_id")))
  WHERE ("c"."sigla" = 'ALEPE'::"text")
  GROUP BY "p"."id_externo", "p"."nome", "p"."partido", "p"."ativo", "p"."legislatura", "g"."ano", "g"."mes";



CREATE OR REPLACE VIEW "public"."alesp_despesas_gabinete" AS
 SELECT "g"."id",
    "p"."id_externo" AS "matricula",
    "g"."ano",
    "g"."mes",
    "g"."cod_categoria",
    "g"."categoria",
    "g"."fornecedor",
    "g"."cnpj_cpf",
    "g"."num_documento",
    "g"."data_emissao",
    "g"."valor_bruto" AS "valor",
    "g"."url_origem",
    "g"."metadata",
    "g"."ingested_at"
   FROM (("public"."gastos_parlamentares" "g"
     JOIN "public"."parlamentares_estaduais" "p" ON (("p"."id" = "g"."parlamentar_id")))
     JOIN "public"."casas" "c" ON (("c"."id" = "p"."casa_id")))
  WHERE ("c"."sigla" = 'ALESP'::"text");



CREATE OR REPLACE VIEW "public"."alesp_despesas_resumo_mensal" AS
 SELECT "p"."id_externo" AS "matricula",
    "p"."nome",
    "p"."partido",
    "p"."ativo",
    "p"."legislatura",
    "g"."ano",
    "g"."mes",
    "count"(*) AS "qtd_despesas",
    "count"(DISTINCT "g"."cnpj_cpf") AS "qtd_fornecedores",
    "sum"("g"."valor_bruto") AS "total"
   FROM (("public"."gastos_parlamentares" "g"
     JOIN "public"."parlamentares_estaduais" "p" ON (("p"."id" = "g"."parlamentar_id")))
     JOIN "public"."casas" "c" ON (("c"."id" = "p"."casa_id")))
  WHERE ("c"."sigla" = 'ALESP'::"text")
  GROUP BY "p"."id_externo", "p"."nome", "p"."partido", "p"."ativo", "p"."legislatura", "g"."ano", "g"."mes";



CREATE OR REPLACE VIEW "public"."almg_deputados" AS
 SELECT ("p"."id_externo")::integer AS "id_almg",
    "p"."nome",
    "p"."partido",
    "p"."tag_localizacao",
    "p"."foto_url",
    "p"."ativo",
    "p"."legislatura",
    "p"."ingested_at",
    "p"."updated_at"
   FROM ("public"."parlamentares_estaduais" "p"
     JOIN "public"."casas" "c" ON (("c"."id" = "p"."casa_id")))
  WHERE ("c"."sigla" = 'ALMG'::"text");



CREATE MATERIALIZED VIEW "public"."almg_fornecedores_intersetados" AS
 WITH "almg" AS (
         SELECT "g"."cnpj_cpf" AS "cnpj",
            "max"("g"."fornecedor") AS "nome",
            "round"("sum"("g"."valor_bruto"), 2) AS "total",
            "count"(*) AS "notas",
            "count"(DISTINCT "g"."parlamentar_id") AS "deputados"
           FROM (("public"."gastos_parlamentares" "g"
             JOIN "public"."parlamentares_estaduais" "p" ON (("p"."id" = "g"."parlamentar_id")))
             JOIN "public"."casas" "c_1" ON (("c_1"."id" = "p"."casa_id")))
          WHERE (("c_1"."sigla" = 'ALMG'::"text") AND ("length"("g"."cnpj_cpf") = 14) AND ("g"."cnpj_cpf" !~ "similar_to_escape"('[0]{14}'::"text")))
          GROUP BY "g"."cnpj_cpf"
        ), "alesp" AS (
         SELECT "g"."cnpj_cpf" AS "cnpj",
            "max"("g"."fornecedor") AS "nome",
            "round"("sum"("g"."valor_bruto"), 2) AS "total",
            "count"(*) AS "notas",
            "count"(DISTINCT "g"."parlamentar_id") AS "deputados"
           FROM (("public"."gastos_parlamentares" "g"
             JOIN "public"."parlamentares_estaduais" "p" ON (("p"."id" = "g"."parlamentar_id")))
             JOIN "public"."casas" "c_1" ON (("c_1"."id" = "p"."casa_id")))
          WHERE (("c_1"."sigla" = 'ALESP'::"text") AND ("length"("g"."cnpj_cpf") = 14) AND ("g"."cnpj_cpf" !~ "similar_to_escape"('[0]{14}'::"text")))
          GROUP BY "g"."cnpj_cpf"
        ), "camara" AS (
         SELECT "ceaps_brutas"."cnpj_cpf_fornecedor" AS "cnpj",
            "max"("ceaps_brutas"."nome_fornecedor") AS "nome",
            "round"("sum"("ceaps_brutas"."valor_liquido"), 2) AS "total",
            "count"(*) AS "notas",
            "count"(DISTINCT "ceaps_brutas"."deputado_id_externo") AS "deputados"
           FROM "public"."ceaps_brutas"
          WHERE (("length"("ceaps_brutas"."cnpj_cpf_fornecedor") = 14) AND ("ceaps_brutas"."cnpj_cpf_fornecedor" !~ "similar_to_escape"('[0]{14}'::"text")))
          GROUP BY "ceaps_brutas"."cnpj_cpf_fornecedor"
        )
 SELECT "a"."cnpj",
    "upper"(COALESCE("a"."nome", "al"."nome", "c"."nome")) AS "nome",
    "a"."total" AS "total_almg",
    "a"."notas" AS "notas_almg",
    "a"."deputados" AS "deps_almg",
    "al"."total" AS "total_alesp",
    "al"."notas" AS "notas_alesp",
    "al"."deputados" AS "deps_alesp",
    "c"."total" AS "total_camara",
    "c"."notas" AS "notas_camara",
    "c"."deputados" AS "deps_camara",
    true AS "em_almg",
    ("al"."cnpj" IS NOT NULL) AS "em_alesp",
    ("c"."cnpj" IS NOT NULL) AS "em_camara",
    ((1 + (("al"."cnpj" IS NOT NULL))::integer) + (("c"."cnpj" IS NOT NULL))::integer) AS "n_casas",
    "round"((("a"."total" + COALESCE("al"."total", (0)::numeric)) + COALESCE("c"."total", (0)::numeric)), 2) AS "total_geral"
   FROM (("almg" "a"
     LEFT JOIN "alesp" "al" ON (("a"."cnpj" = "al"."cnpj")))
     LEFT JOIN "camara" "c" ON (("a"."cnpj" = "c"."cnpj")))
  WHERE (("al"."cnpj" IS NOT NULL) OR ("c"."cnpj" IS NOT NULL))
  WITH NO DATA;



CREATE OR REPLACE VIEW "public"."almg_verba_indenizatoria" AS
 SELECT "g"."id",
    ("p"."id_externo")::integer AS "deputado_id_almg",
    "g"."ano",
    "g"."mes",
    (NULLIF("g"."cod_categoria", ''::"text"))::integer AS "cod_categoria",
    "g"."categoria",
    "g"."categoria_total",
    "g"."fornecedor" AS "emitente",
    "g"."cnpj_cpf",
    "g"."num_documento",
    "g"."data_emissao",
    "g"."valor_bruto" AS "valor_despesa",
    "g"."valor_reembolso",
    "g"."url_origem",
    "g"."ingested_at"
   FROM (("public"."gastos_parlamentares" "g"
     JOIN "public"."parlamentares_estaduais" "p" ON (("p"."id" = "g"."parlamentar_id")))
     JOIN "public"."casas" "c" ON (("c"."id" = "p"."casa_id")))
  WHERE ("c"."sigla" = 'ALMG'::"text");



CREATE OR REPLACE VIEW "public"."almg_verba_resumo_mensal" AS
 SELECT ("p"."id_externo")::integer AS "id_almg",
    "p"."nome",
    "p"."partido",
    "g"."ano",
    "g"."mes",
    "count"(*) AS "qtd_notas",
    "count"(DISTINCT "g"."cnpj_cpf") AS "qtd_fornecedores",
    "sum"("g"."valor_reembolso") AS "total_reembolsado",
    "sum"("g"."valor_bruto") AS "total_despesa"
   FROM (("public"."gastos_parlamentares" "g"
     JOIN "public"."parlamentares_estaduais" "p" ON (("p"."id" = "g"."parlamentar_id")))
     JOIN "public"."casas" "c" ON (("c"."id" = "p"."casa_id")))
  WHERE ("c"."sigla" = 'ALMG'::"text")
  GROUP BY "p"."id_externo", "p"."nome", "p"."partido", "g"."ano", "g"."mes";



CREATE MATERIALIZED VIEW "public"."ask_ceap_deputado_ano_agg" AS
 SELECT "c"."deputado_id_externo",
    "r"."nome",
    "r"."sigla_partido",
    "r"."sigla_uf",
    "c"."ano",
    "count"(*) AS "total_transacoes",
    "sum"("c"."valor_liquido") AS "total_valor",
    "sum"(
        CASE
            WHEN ("c"."tipo_despesa" ~~* '%passagem%'::"text") THEN "c"."valor_liquido"
            ELSE (0)::numeric
        END) AS "passagens",
    "sum"(
        CASE
            WHEN ("c"."tipo_despesa" ~~* '%combusti%'::"text") THEN "c"."valor_liquido"
            ELSE (0)::numeric
        END) AS "combustivel",
    "sum"(
        CASE
            WHEN ("c"."tipo_despesa" ~~* '%divulga%'::"text") THEN "c"."valor_liquido"
            ELSE (0)::numeric
        END) AS "divulgacao",
    "sum"(
        CASE
            WHEN ("c"."tipo_despesa" ~~* '%loca%'::"text") THEN "c"."valor_liquido"
            ELSE (0)::numeric
        END) AS "locacao_veiculos"
   FROM ("public"."ceaps_brutas" "c"
     LEFT JOIN "public"."cam_parlamentar_risco" "r" ON ((("r"."deputado_id")::"text" = "c"."deputado_id_externo")))
  WHERE ("c"."valor_liquido" > (0)::numeric)
  GROUP BY "c"."deputado_id_externo", "r"."nome", "r"."sigla_partido", "r"."sigla_uf", "c"."ano"
  WITH NO DATA;



CREATE MATERIALIZED VIEW "public"."ask_ceap_fornecedor_agg" AS
 SELECT "nome_fornecedor",
    "cnpj_cpf_fornecedor",
    "count"(*) AS "total_transacoes",
    "count"(DISTINCT "deputado_id_externo") AS "total_deputados",
    "sum"("valor_liquido") AS "total_valor",
    "min"("ano") AS "ano_inicio",
    "max"("ano") AS "ano_fim"
   FROM "public"."ceaps_brutas"
  WHERE (("nome_fornecedor" IS NOT NULL) AND ("valor_liquido" > (0)::numeric))
  GROUP BY "nome_fornecedor", "cnpj_cpf_fornecedor"
  WITH NO DATA;



CREATE MATERIALIZED VIEW "public"."ask_ceap_tipo_ano_agg" AS
 SELECT "tipo_despesa",
    "ano",
    "count"(*) AS "total_transacoes",
    "count"(DISTINCT "deputado_id_externo") AS "total_deputados",
    "sum"("valor_liquido") AS "total_valor",
    "avg"("valor_liquido") AS "media_valor"
   FROM "public"."ceaps_brutas"
  WHERE (("tipo_despesa" IS NOT NULL) AND ("valor_liquido" > (0)::numeric))
  GROUP BY "tipo_despesa", "ano"
  WITH NO DATA;



CREATE MATERIALIZED VIEW "public"."ask_emendas_autor_ano_agg" AS
 SELECT "autor_nome",
    "uf",
    "ano",
    "tipo_emenda",
    "count"(*) AS "total_emendas",
    "sum"("valor_empenhado") AS "total_empenhado",
    "sum"("valor_pago") AS "total_pago",
    "count"(
        CASE
            WHEN "eh_rp9" THEN 1
            ELSE NULL::integer
        END) AS "total_rp9",
    "sum"(
        CASE
            WHEN "eh_rp9" THEN "valor_pago"
            ELSE (0)::numeric
        END) AS "valor_rp9_pago"
   FROM "public"."emendas_completas"
  WHERE ("autor_nome" IS NOT NULL)
  GROUP BY "autor_nome", "uf", "ano", "tipo_emenda"
  WITH NO DATA;



CREATE OR REPLACE VIEW "public"."ask_perguntas_populares" AS
 SELECT "pergunta_original",
    "pergunta_hash",
    "count"(*) AS "total_buscas",
    "count"(*) FILTER (WHERE "cache_hit") AS "cache_hits",
    "count"(*) FILTER (WHERE ("success" = false)) AS "falhas",
    "max"("created_at") AS "ultima_busca"
   FROM "public"."ask_log"
  WHERE ("created_at" > ("now"() - '30 days'::interval))
  GROUP BY "pergunta_original", "pergunta_hash"
 HAVING ("count"(*) >= 3)
  ORDER BY ("count"(*)) DESC;



CREATE OR REPLACE VIEW "public"."cbf_institutos_emendas" AS
 SELECT "v"."cnpj_completo",
    "v"."razao_social",
    "v"."natureza_juridica",
    "v"."uf",
    "v"."nome_socio",
    "v"."qualificacao",
    "v"."cnpj_federacao_ref",
    "s"."nome_federacao",
    "v"."total_emendas",
    "v"."atualizado_em"
   FROM ("public"."cbf_cnpjs_vinculados" "v"
     JOIN "public"."cbf_socios_federacoes" "s" ON ((("s"."cpf_socio" = "v"."cpf_socio") AND ("s"."cnpj_federacao" = "v"."cnpj_federacao_ref"))))
  WHERE ("v"."tem_emenda" = true)
  ORDER BY "v"."total_emendas" DESC;



CREATE OR REPLACE VIEW "public"."ceaf_ranking_orgaos" AS
 SELECT "orgao_nome",
    "orgao_pasta_sigla" AS "pasta",
    "uf_lotacao",
    "count"(*) AS "total_expulsoes",
    "count"(*) FILTER (WHERE ("tipo_punicao" ~~* '%demiss%'::"text")) AS "demissoes",
    "count"(*) FILTER (WHERE (("tipo_punicao" ~~* '%cassacao%'::"text") OR ("tipo_punicao" ~~* '%cassação%'::"text"))) AS "cassacoes_aposentadoria",
    "min"("data_publicacao") AS "primeira_expulsao",
    "max"("data_publicacao") AS "ultima_expulsao"
   FROM "public"."ceaf_expulsoes"
  GROUP BY "orgao_nome", "orgao_pasta_sigla", "uf_lotacao"
  ORDER BY ("count"(*)) DESC NULLS LAST;



CREATE OR REPLACE VIEW "public"."ceaf_serie_temporal" AS
 SELECT (EXTRACT(year FROM "data_publicacao"))::integer AS "ano",
    "tipo_punicao",
    "count"(*) AS "n_expulsoes",
    "count"(DISTINCT "orgao_nome") AS "n_orgaos"
   FROM "public"."ceaf_expulsoes"
  WHERE ("data_publicacao" IS NOT NULL)
  GROUP BY ((EXTRACT(year FROM "data_publicacao"))::integer), "tipo_punicao"
  ORDER BY ((EXTRACT(year FROM "data_publicacao"))::integer) DESC;



CREATE OR REPLACE VIEW "public"."ceaf_x_cgu_pad" AS
 SELECT "e"."id" AS "ceaf_id",
    "e"."nome_punido",
    "e"."cpf_punido",
    "e"."tipo_punicao",
    "e"."cargo_efetivo",
    "e"."orgao_nome",
    "e"."uf_lotacao",
    "e"."data_publicacao",
    "e"."portaria",
    "e"."numero_processo",
    "p"."tipo_processo",
    "p"."assuntos" AS "assuntos_pad",
    "p"."n_investigados",
    "p"."n_expulsivas" AS "total_expulsivas_processo",
    "p"."data_instauracao",
    "p"."fase_atual"
   FROM ("public"."ceaf_expulsoes" "e"
     LEFT JOIN "public"."cgu_pad_processos" "p" ON (("e"."numero_processo" = "p"."numero_processo")))
  WHERE ("e"."numero_processo" IS NOT NULL);



CREATE OR REPLACE VIEW "public"."cgu_pad_ranking_orgaos" AS
 SELECT "entidade",
    ( SELECT "p2"."pasta"
           FROM "public"."cgu_pad_processos" "p2"
          WHERE (("p2"."entidade" = "p"."entidade") AND ("p2"."pasta" IS NOT NULL))
          GROUP BY "p2"."pasta"
          ORDER BY ("count"(*)) DESC
         LIMIT 1) AS "ministerio",
    "count"(*) AS "total_processos",
    "count"(DISTINCT "uf") AS "n_ufs",
    "sum"("n_investigados") AS "total_investigados",
    "sum"("n_expulsivas") AS "total_expulsivas",
    "sum"("n_suspensoes") AS "total_suspensoes",
    "sum"("n_advertencias") AS "total_advertencias",
    "round"(((100.0 * ("sum"("n_expulsivas"))::numeric) / (NULLIF("count"(*), 0))::numeric), 1) AS "pct_expulsivas"
   FROM "public"."cgu_pad_processos" "p"
  WHERE ("fase_atual" = 'Processo Julgado'::"text")
  GROUP BY "entidade"
  ORDER BY ("sum"("n_expulsivas")) DESC NULLS LAST;



CREATE OR REPLACE VIEW "public"."cgu_pad_serie_temporal" AS
 SELECT (EXTRACT(year FROM "data_instauracao"))::integer AS "ano",
    "tipo_processo",
    "count"(*) AS "n_processos",
    "sum"("n_expulsivas") AS "n_expulsivas"
   FROM "public"."cgu_pad_processos"
  WHERE ("data_instauracao" IS NOT NULL)
  GROUP BY ((EXTRACT(year FROM "data_instauracao"))::integer), "tipo_processo"
  ORDER BY ((EXTRACT(year FROM "data_instauracao"))::integer) DESC, ("count"(*)) DESC;



CREATE OR REPLACE VIEW "public"."cnes_emendas" AS
 SELECT "c"."codigo_cnes",
    "c"."nome_razao_social",
    "c"."nome_fantasia",
    "c"."codigo_tipo_unidade",
    "c"."descricao_esfera_administrativa",
    "c"."uf",
    "c"."codigo_municipio",
    "c"."atende_sus",
    "c"."possui_atendimento_hospitalar",
    "count"(DISTINCT "e"."id") AS "total_transacoes",
    "count"(DISTINCT "e"."nome_autor") AS "total_autores",
    "sum"("e"."valor_recebido") AS "total_recebido",
    "min"("e"."ano_emenda") AS "ano_primeira_emenda",
    "max"("e"."ano_emenda") AS "ano_ultima_emenda"
   FROM ("public"."cnes_estabelecimentos" "c"
     JOIN "public"."emendas_favorecidos" "e" ON (("e"."codigo_favorecido" = "c"."numero_cnpj")))
  GROUP BY "c"."codigo_cnes", "c"."nome_razao_social", "c"."nome_fantasia", "c"."codigo_tipo_unidade", "c"."descricao_esfera_administrativa", "c"."uf", "c"."codigo_municipio", "c"."atende_sus", "c"."possui_atendimento_hospitalar";



CREATE MATERIALIZED VIEW "public"."cnes_emendas_por_cnpj" AS
 WITH "emendas_agg" AS (
         SELECT "emendas_favorecidos"."codigo_favorecido",
            "sum"("emendas_favorecidos"."valor_recebido") AS "total_recebido",
            "count"(DISTINCT "emendas_favorecidos"."id") AS "total_transacoes",
            "count"(DISTINCT "emendas_favorecidos"."nome_autor") AS "total_autores",
            "array_agg"(DISTINCT "emendas_favorecidos"."nome_autor" ORDER BY "emendas_favorecidos"."nome_autor") AS "autores",
            "min"("emendas_favorecidos"."ano_emenda") AS "ano_primeira_emenda",
            "max"("emendas_favorecidos"."ano_emenda") AS "ano_ultima_emenda"
           FROM "public"."emendas_favorecidos"
          WHERE ("emendas_favorecidos"."codigo_favorecido" IS NOT NULL)
          GROUP BY "emendas_favorecidos"."codigo_favorecido"
        )
 SELECT "c"."numero_cnpj",
    "min"("c"."nome_razao_social") AS "nome_favorecido",
    "c"."uf",
    "count"(DISTINCT "c"."codigo_cnes") AS "total_unidades_cnes",
    "bool_or"("c"."possui_atendimento_hospitalar") AS "tem_hospital",
    "bool_or"("c"."atende_sus") AS "atende_sus",
    "e"."total_recebido",
    "e"."total_transacoes",
    "e"."total_autores",
    "e"."autores",
    "e"."ano_primeira_emenda",
    "e"."ano_ultima_emenda"
   FROM ("public"."cnes_estabelecimentos" "c"
     JOIN "emendas_agg" "e" ON (("e"."codigo_favorecido" = "c"."numero_cnpj")))
  GROUP BY "c"."numero_cnpj", "c"."uf", "e"."total_recebido", "e"."total_transacoes", "e"."total_autores", "e"."autores", "e"."ano_primeira_emenda", "e"."ano_ultima_emenda"
  WITH NO DATA;



CREATE MATERIALIZED VIEW "public"."cota_cnpj_ranking" AS
 SELECT "cnpj_cpf_fornecedor" AS "cnpj",
    "nome_fornecedor",
    "count"(DISTINCT "id_deputado") AS "n_deputados",
    "count"(*) AS "n_notas",
    "sum"("valor_liquido") AS "total_liquido_brl",
    "min"("data_emissao") AS "primeira_nota",
    "max"("data_emissao") AS "ultima_nota"
   FROM "public"."cota_despesa"
  WHERE (("cnpj_cpf_fornecedor" IS NOT NULL) AND ("cnpj_cpf_fornecedor" <> ''::"text"))
  GROUP BY "cnpj_cpf_fornecedor", "nome_fornecedor"
  WITH NO DATA;



CREATE OR REPLACE VIEW "public"."cota_emenda_cruzamento" AS
 SELECT "c"."cnpj_norm" AS "cnpj",
    "c"."nome_fornecedor" AS "nome_na_cota",
    "count"(DISTINCT "c"."id_deputado") AS "dep_cota",
    "sum"("c"."valor_liquido") AS "total_cota_brl",
    "e"."favorecido" AS "nome_na_emenda",
    "e"."valor_total" AS "total_emenda_brl",
    "e"."n_autores" AS "autores_emenda"
   FROM ("public"."cota_despesa" "c"
     JOIN ( SELECT "emendas_favorecidos"."codigo_favorecido",
            "max"("emendas_favorecidos"."favorecido") AS "favorecido",
            "sum"("emendas_favorecidos"."valor_recebido") AS "valor_total",
            "count"(DISTINCT "emendas_favorecidos"."codigo_autor") AS "n_autores"
           FROM "public"."emendas_favorecidos"
          WHERE (("emendas_favorecidos"."codigo_favorecido" IS NOT NULL) AND ("emendas_favorecidos"."codigo_favorecido" <> ''::"text"))
          GROUP BY "emendas_favorecidos"."codigo_favorecido") "e" ON (("e"."codigo_favorecido" = "c"."cnpj_norm")))
  WHERE (("c"."cnpj_norm" IS NOT NULL) AND ("c"."cnpj_norm" <> ''::"text"))
  GROUP BY "c"."cnpj_norm", "c"."nome_fornecedor", "e"."favorecido", "e"."valor_total", "e"."n_autores"
  ORDER BY ("sum"("c"."valor_liquido") + "e"."valor_total") DESC NULLS LAST;



CREATE MATERIALIZED VIEW "public"."mv_cota_fornecedor" AS
 WITH "norm" AS (
         SELECT NULLIF("regexp_replace"(COALESCE("cota_despesa"."cnpj_norm", ''::"text"), '\D'::"text", ''::"text", 'g'::"text"), ''::"text") AS "cnpj_d",
            "cota_despesa"."nome_fornecedor" AS "nome",
            "regexp_replace"(COALESCE("cota_despesa"."nome_fornecedor", ''::"text"), '[^[:ascii:]]'::"text", ''::"text", 'g'::"text") AS "ascii_skel",
            "cota_despesa"."id_deputado",
            "cota_despesa"."valor_liquido",
            "cota_despesa"."data_emissao"
           FROM "public"."cota_despesa"
        )
 SELECT COALESCE("cnpj_d", ('AEREA:'::"text" || "ascii_skel")) AS "chave",
    "cnpj_d" AS "cnpj_norm",
    "mode"() WITHIN GROUP (ORDER BY "norm"."nome") AS "nome",
    ("cnpj_d" IS NULL) AS "is_aerea",
    "round"("sum"("valor_liquido"), 2) AS "total_liquido",
    ("count"(DISTINCT "id_deputado"))::integer AS "n_deputados",
    "count"(*) AS "n_notas",
    "min"("data_emissao") AS "primeira_nota",
    "max"("data_emissao") AS "ultima_nota"
   FROM "norm"
  GROUP BY COALESCE("cnpj_d", ('AEREA:'::"text" || "ascii_skel")), "cnpj_d", ("cnpj_d" IS NULL)
  WITH NO DATA;



CREATE OR REPLACE VIEW "public"."cota_fornecedor_resumo" AS
 SELECT ("count"(*))::integer AS "fornecedores",
    ("count"(*) FILTER (WHERE (NOT "is_aerea")))::integer AS "n_empresas",
    ("count"(*) FILTER (WHERE "is_aerea"))::integer AS "n_aereas",
    COALESCE("sum"("total_liquido"), (0)::numeric) AS "total_geral",
    COALESCE("sum"("n_notas"), (0)::numeric) AS "n_notas",
    "min"("primeira_nota") AS "desde",
    "max"("ultima_nota") AS "ate"
   FROM "public"."mv_cota_fornecedor";



CREATE OR REPLACE VIEW "public"."cvm_cruzamento_emendas" AS
 SELECT "a"."nome_acusado" AS "cvm_nome",
    "a"."situacao" AS "cvm_situacao",
    "p"."fase_atual" AS "cvm_fase",
    "p"."data_abertura" AS "cvm_data_abertura",
    "p"."nup" AS "cvm_nup",
    "f"."codigo_favorecido" AS "favorecido_cnpj",
    "f"."favorecido" AS "favorecido_nome",
    "f"."uf_favorecido" AS "uf",
    "sum"("f"."valor_recebido") AS "total_emendas",
    "count"(DISTINCT "f"."nome_autor") AS "n_parlamentares",
    "count"(*) AS "n_transacoes"
   FROM (("public"."cvm_acusados" "a"
     JOIN "public"."cvm_processos" "p" ON (("p"."nup" = "a"."nup")))
     JOIN "public"."emendas_favorecidos" "f" ON (("upper"("regexp_replace"("f"."favorecido", '[^A-Za-z√Ä-√ø0-9 ]'::"text", ''::"text", 'g'::"text")) = "a"."nome_normalizado")))
  GROUP BY "a"."nome_acusado", "a"."situacao", "p"."fase_atual", "p"."data_abertura", "p"."nup", "f"."codigo_favorecido", "f"."favorecido", "f"."uf_favorecido"
  ORDER BY ("sum"("f"."valor_recebido")) DESC;



CREATE OR REPLACE VIEW "public"."cvm_emissor_sancionado" AS
 WITH "emissores" AS (
         SELECT "cvm_oferta"."cnpj_emissor",
            "max"("cvm_oferta"."nome_emissor") AS "nome_emissor",
            "count"(*) AS "n_ofertas",
            "sum"("cvm_oferta"."valor") AS "valor_total",
            "max"("cvm_oferta"."data_oferta") AS "ultima_oferta",
            "array_agg"(DISTINCT "cvm_oferta"."tipo_ativo") FILTER (WHERE ("cvm_oferta"."tipo_ativo" IS NOT NULL)) AS "tipos_ativo"
           FROM "public"."cvm_oferta"
          WHERE (("cvm_oferta"."cnpj_emissor" IS NOT NULL) AND ("length"("cvm_oferta"."cnpj_emissor") = 14))
          GROUP BY "cvm_oferta"."cnpj_emissor"
        )
 SELECT "e"."cnpj_emissor",
    "e"."nome_emissor",
    "e"."n_ofertas",
    "e"."valor_total",
    "e"."ultima_oferta",
    "e"."tipos_ativo",
    'federal'::"text" AS "origem_sancao",
    "s"."tipo_registro" AS "sancao_tipo",
    "s"."tipo_sancao" AS "sancao_detalhe",
    "s"."orgao_nome" AS "sancao_orgao",
    "s"."ativo" AS "sancao_ativa",
    true AS "condenada"
   FROM ("emissores" "e"
     JOIN "public"."portal_sancionados" "s" ON (("regexp_replace"("s"."cpf_cnpj", '\D'::"text", ''::"text", 'g'::"text") = "e"."cnpj_emissor")))
UNION ALL
 SELECT "e"."cnpj_emissor",
    "e"."nome_emissor",
    "e"."n_ofertas",
    "e"."valor_total",
    "e"."ultima_oferta",
    "e"."tipos_ativo",
    'MG'::"text" AS "origem_sancao",
    "m"."fase" AS "sancao_tipo",
    "m"."conduta" AS "sancao_detalhe",
    "m"."orgao_lesado" AS "sancao_orgao",
    NULL::boolean AS "sancao_ativa",
    (("m"."decisao" IS NOT NULL) AND ("m"."decisao" !~* 'arquiv|absolv'::"text")) AS "condenada"
   FROM ("emissores" "e"
     JOIN "public"."mg_empresas_sancionadas" "m" ON (("m"."cnpj_norm" = "e"."cnpj_emissor")));



CREATE OR REPLACE VIEW "public"."cvm_fip_monopolio" AS
 WITH "latest" AS (
         SELECT "cvm_fip_informe"."cnpj_norm",
            "max"("cvm_fip_informe"."dt_comptc") AS "dt_max"
           FROM "public"."cvm_fip_informe"
          WHERE (("cvm_fip_informe"."nr_cotst" = 1) AND ("cvm_fip_informe"."pr_pf" = (100)::numeric) AND ("cvm_fip_informe"."vl_cap_integr" > (10000000)::numeric))
          GROUP BY "cvm_fip_informe"."cnpj_norm"
        ), "informe_atual" AS (
         SELECT DISTINCT ON ("i"."cnpj_norm") "i"."cnpj_norm",
            "i"."denom",
            "i"."tipo",
            "i"."dt_comptc",
            "i"."vl_patrim_liq",
            "i"."vl_cap_integr",
            "i"."vl_cap_compr",
            "i"."nr_cotst",
            "i"."pr_pf",
            "i"."qt_cota"
           FROM ("public"."cvm_fip_informe" "i"
             JOIN "latest" "l" ON ((("l"."cnpj_norm" = "i"."cnpj_norm") AND ("l"."dt_max" = "i"."dt_comptc"))))
          ORDER BY "i"."cnpj_norm", "i"."vl_patrim_liq" DESC NULLS LAST
        )
 SELECT "ia"."cnpj_norm",
    "ia"."denom",
    "ia"."tipo",
    "ia"."dt_comptc",
    "ia"."vl_patrim_liq",
    "ia"."vl_cap_integr",
    "ia"."vl_cap_compr",
    "ia"."nr_cotst",
    "ia"."pr_pf",
    "ia"."qt_cota",
    "f"."situacao",
    "f"."classe",
    "f"."classe_anbima",
    "f"."admin",
    "f"."gestor",
    "f"."controlador",
    "f"."cnpj_admin",
    "f"."cnpj_gestor",
    (EXISTS ( SELECT 1
           FROM "public"."cvm_carteira_edge" "e"
          WHERE (("e"."cnpj_fundo" = "ia"."cnpj_norm") OR ("e"."cnpj_ativo" = "ia"."cnpj_norm")))) AS "tem_aresta_grafo",
    (EXISTS ( SELECT 1
           FROM "public"."cvm_oferta" "o"
          WHERE ("regexp_replace"(COALESCE("o"."cnpj_emissor", ''::"text"), '\D'::"text", ''::"text", 'g'::"text") = "ia"."cnpj_norm"))) AS "tem_oferta",
    (EXISTS ( SELECT 1
           FROM "public"."cnpj_socios" "s"
          WHERE (("regexp_replace"(("s"."cnpj_basico" || '0001'::"text"), '\D'::"text", ''::"text", 'g'::"text") = "ia"."cnpj_norm") AND (EXISTS ( SELECT 1
                   FROM "public"."cam_parlamentar_risco" "p"
                  WHERE (TRIM(BOTH FROM "regexp_replace"("regexp_replace"("upper"("public"."unaccent"("p"."nome")), '[^A-Z0-9 ]'::"text", ' '::"text", 'g'::"text"), '\s+'::"text", ' '::"text", 'g'::"text")) = "s"."nome_norm")))))) AS "tem_politico"
   FROM ("informe_atual" "ia"
     LEFT JOIN "public"."cvm_fundo" "f" ON (("f"."cnpj_norm" = "ia"."cnpj_norm")));



CREATE OR REPLACE VIEW "public"."cvm_socio_politico" AS
 WITH "pol" AS (
         SELECT ("cam_parlamentar_risco"."deputado_id")::"text" AS "politico_id",
            "cam_parlamentar_risco"."nome" AS "politico",
            "cam_parlamentar_risco"."sigla_partido",
            "cam_parlamentar_risco"."sigla_uf",
            "cam_parlamentar_risco"."score_total",
            TRIM(BOTH FROM "regexp_replace"("regexp_replace"("upper"("public"."unaccent"("cam_parlamentar_risco"."nome")), '[^A-Z0-9 ]'::"text", ' '::"text", 'g'::"text"), '\s+'::"text", ' '::"text", 'g'::"text")) AS "nome_norm",
            "regexp_replace"(COALESCE("cam_parlamentar_risco"."cpf", ''::"text"), '\D'::"text", ''::"text", 'g'::"text") AS "cpf_digits",
            'deputado'::"text" AS "tipo_parlamentar"
           FROM "public"."cam_parlamentar_risco"
        UNION ALL
         SELECT "sen_senadores"."codigo" AS "politico_id",
            "sen_senadores"."nome_completo" AS "politico",
            "sen_senadores"."partido" AS "sigla_partido",
            "sen_senadores"."uf" AS "sigla_uf",
            NULL::numeric AS "score_total",
            "sen_senadores"."nome_norm",
            ''::"text" AS "cpf_digits",
            'senador'::"text" AS "tipo_parlamentar"
           FROM "public"."sen_senadores"
        ), "socios_pf" AS (
         SELECT "s"."cnpj_basico",
            "s"."nome_socio",
            "s"."nome_norm",
            "s"."cpf_cnpj_socio",
            "s"."qualificacao",
            "regexp_replace"(COALESCE("s"."cpf_cnpj_socio", ''::"text"), '\D'::"text", ''::"text", 'g'::"text") AS "cpf_vis",
            "reverse"("split_part"("reverse"("s"."nome_norm"), ' '::"text", 1)) AS "sobrenome_socio",
            "e"."capital_social"
           FROM ("public"."cnpj_socios" "s"
             LEFT JOIN "public"."cnpj_empresa" "e" ON (("e"."cnpj_basico" = "s"."cnpj_basico")))
          WHERE (("s"."identificador" = '2'::"text") AND ("s"."nome_norm" IS NOT NULL) AND ("length"("s"."nome_norm") > 6))
        )
 SELECT "p"."politico_id",
    "p"."politico",
    "p"."sigla_partido",
    "p"."sigla_uf",
    "p"."score_total",
    "p"."tipo_parlamentar",
    "sp"."cnpj_basico",
    "e"."razao_social" AS "empresa",
    "e"."capital_social",
    "sp"."qualificacao" AS "papel_societario",
    "sp"."cpf_cnpj_socio" AS "cpf_socio_mascarado",
    (("length"("p"."cpf_digits") = 11) AND (NULLIF("sp"."cpf_vis", ''::"text") = "substr"("p"."cpf_digits", 4, 6))) AS "cpf_confirma",
    false AS "familiar"
   FROM (("socios_pf" "sp"
     JOIN "pol" "p" ON (("p"."nome_norm" = "sp"."nome_norm")))
     LEFT JOIN "public"."cnpj_empresa" "e" ON (("e"."cnpj_basico" = "sp"."cnpj_basico")))
UNION ALL
 SELECT "p"."politico_id",
    "p"."politico",
    "p"."sigla_partido",
    "p"."sigla_uf",
    "p"."score_total",
    "p"."tipo_parlamentar",
    "sp"."cnpj_basico",
    "e"."razao_social" AS "empresa",
    "e"."capital_social",
    "sp"."qualificacao" AS "papel_societario",
    "sp"."cpf_cnpj_socio" AS "cpf_socio_mascarado",
    false AS "cpf_confirma",
    true AS "familiar"
   FROM (("socios_pf" "sp"
     JOIN "pol" "p" ON ((("p"."nome_norm" <> "sp"."nome_norm") AND ("reverse"("split_part"("reverse"("p"."nome_norm"), ' '::"text", 1)) = "sp"."sobrenome_socio"))))
     LEFT JOIN "public"."cnpj_empresa" "e" ON (("e"."cnpj_basico" = "sp"."cnpj_basico")))
  WHERE (("length"("sp"."sobrenome_socio") >= 6) AND (NOT ("sp"."sobrenome_socio" IN ( SELECT "sobrenome_blocklist"."sobrenome"
           FROM "public"."sobrenome_blocklist"))) AND (COALESCE("sp"."capital_social", (0)::numeric) < (1000000000)::numeric));



CREATE OR REPLACE VIEW "public"."despesas_gabinete" AS
 SELECT NULL::"uuid" AS "parlamentar_id",
    (0)::numeric AS "valor_total"
  WHERE false;



CREATE OR REPLACE VIEW "public"."ele26_v_alertas_painel" AS
 SELECT "a"."id",
    "a"."nome",
    "a"."uf",
    "a"."cargo_interesse",
    "a"."motivos",
    "a"."descricao",
    "a"."tem_sancao",
    "a"."emenda_total_hist",
    "a"."candidatura_entrou",
    "a"."financiamento_entrou",
    "a"."alerta_ativo",
    "c"."id" AS "candidatura_id",
    "c"."sigla_partido",
    "c"."situacao_candidatura",
    "c"."eleito",
    "sum"("f"."valor") AS "total_arrecadado_2026",
    "count"(DISTINCT "f"."cpf_cnpj_doador") AS "n_doadores_2026"
   FROM (("public"."ele2026_alertas" "a"
     LEFT JOIN "public"."ele2026_candidatos" "c" ON (("c"."cpf" = "a"."cpf")))
     LEFT JOIN "public"."ele2026_financiamento" "f" ON (("f"."cpf_candidato" = "a"."cpf")))
  WHERE ("a"."alerta_ativo" = true)
  GROUP BY "a"."id", "a"."nome", "a"."uf", "a"."cargo_interesse", "a"."motivos", "a"."descricao", "a"."tem_sancao", "a"."emenda_total_hist", "a"."candidatura_entrou", "a"."financiamento_entrou", "a"."alerta_ativo", "c"."id", "c"."sigla_partido", "c"."situacao_candidatura", "c"."eleito"
  ORDER BY "a"."emenda_total_hist" DESC NULLS LAST;



CREATE OR REPLACE VIEW "public"."ele26_v_candidato_emendas" AS
 SELECT "c"."nome" AS "candidato",
    "c"."cargo",
    "c"."sigla_partido",
    "c"."uf",
    "ef"."codigo_favorecido" AS "cnpj_favorecido",
    "ef"."municipio_favorecido",
    "ef"."uf_favorecido",
    "ef"."valor_recebido",
    "ef"."ano_emenda",
    "ef"."tipo_emenda",
    "ef"."subtipo"
   FROM (("public"."ele2026_candidatos" "c"
     JOIN "public"."parlamentares" "p" ON (("p"."cpf" = "c"."cpf")))
     JOIN "public"."emendas_favorecidos" "ef" ON ((("ef"."codigo_autor")::integer = "p"."id_camara")))
  WHERE ("c"."cpf" IS NOT NULL);



CREATE OR REPLACE VIEW "public"."ele26_v_financiamento_sancoes" AS
 SELECT 'doador'::"text" AS "papel",
    "f"."nome_candidato" AS "candidato",
    "f"."sigla_partido",
    "f"."uf",
    "f"."cpf_cnpj_doador" AS "cpf_cnpj",
    "f"."nome_doador" AS "nome_empresa",
    "f"."valor" AS "valor_campanha",
    "f"."tipo_doador",
    "s"."cadastro" AS "sancao_cadastro",
    "s"."tipo_sancao",
    "s"."data_inicio" AS "sancao_inicio",
    "s"."data_fim" AS "sancao_fim",
    "s"."orgao_nome" AS "orgao_sancionador"
   FROM ("public"."ele2026_financiamento" "f"
     JOIN "public"."sancoes" "s" ON (("s"."cpf_cnpj" = "f"."cpf_cnpj_doador")))
  WHERE ("f"."cpf_cnpj_doador" IS NOT NULL)
UNION ALL
 SELECT 'fornecedor'::"text" AS "papel",
    "g"."nome_candidato" AS "candidato",
    "g"."sigla_partido",
    "g"."uf",
    "g"."cpf_cnpj_fornecedor" AS "cpf_cnpj",
    "g"."nome_fornecedor" AS "nome_empresa",
    "g"."valor_despesa" AS "valor_campanha",
    NULL::"text" AS "tipo_doador",
    "s"."cadastro" AS "sancao_cadastro",
    "s"."tipo_sancao",
    "s"."data_inicio" AS "sancao_inicio",
    "s"."data_fim" AS "sancao_fim",
    "s"."orgao_nome" AS "orgao_sancionador"
   FROM ("public"."ele2026_gastos" "g"
     JOIN "public"."sancoes" "s" ON (("s"."cpf_cnpj" = "g"."cpf_cnpj_fornecedor")))
  WHERE ("g"."cpf_cnpj_fornecedor" IS NOT NULL);



CREATE OR REPLACE VIEW "public"."ele26_v_historico_eleitoral" AS
 SELECT "c"."nome" AS "candidato",
    "c"."cpf",
    "c"."cargo" AS "cargo_2026",
    "c"."uf",
    "c"."sigla_partido" AS "partido_2026",
    "h"."ano_eleicao",
    "h"."cargo" AS "cargo_hist",
    "h"."sigla_partido" AS "partido_hist",
    "h"."situacao_turno" AS "resultado_hist",
    "h"."limite_despesa" AS "limite_hist"
   FROM ("public"."ele2026_candidatos" "c"
     JOIN "public"."tse_candidatos" "h" ON (("h"."cpf" = "c"."cpf")))
  WHERE ("c"."cpf" IS NOT NULL)
  ORDER BY "c"."nome", "h"."ano_eleicao" DESC;



CREATE OR REPLACE VIEW "public"."fip_saf_resumo" AS
 WITH "ultimo" AS (
         SELECT DISTINCT ON ("cvm_fip_informe"."cnpj_norm") "cvm_fip_informe"."cnpj_norm",
            "cvm_fip_informe"."dt_comptc",
            "cvm_fip_informe"."vl_patrim_liq",
            "cvm_fip_informe"."vl_cap_integr",
            "cvm_fip_informe"."vl_cap_compr",
            "cvm_fip_informe"."nr_cotst",
            "cvm_fip_informe"."pr_pf",
            "cvm_fip_informe"."pr_pj_nfin",
            "cvm_fip_informe"."pr_banco",
            "cvm_fip_informe"."pr_pj_fin",
            "cvm_fip_informe"."pr_rpps",
            "cvm_fip_informe"."pr_efpc"
           FROM "public"."cvm_fip_informe"
          WHERE ("cvm_fip_informe"."cnpj_norm" IN ( SELECT "cvm_fip_saf"."cnpj_fip"
                   FROM "public"."cvm_fip_saf"))
          ORDER BY "cvm_fip_informe"."cnpj_norm", "cvm_fip_informe"."dt_comptc" DESC
        )
 SELECT "fs"."clube",
    "fs"."papel",
    "fs"."confirmado",
    "fs"."nome_fip",
    "fs"."cnpj_fip",
    "u"."dt_comptc" AS "ultimo_informe",
    "u"."vl_patrim_liq" AS "pl",
    "u"."vl_cap_integr" AS "cap_integralizado",
    "u"."vl_cap_compr" AS "cap_comprometido",
    "u"."nr_cotst" AS "cotistas",
    "u"."pr_pf" AS "pct_pf",
    "u"."pr_pj_nfin" AS "pct_pj_nfin",
    "u"."pr_banco" AS "pct_banco",
    "u"."pr_efpc" AS "pct_efpc",
    "fs"."vinculo",
    "fs"."obs"
   FROM ("public"."cvm_fip_saf" "fs"
     LEFT JOIN "ultimo" "u" ON (("u"."cnpj_norm" = "fs"."cnpj_fip")))
  ORDER BY COALESCE("u"."vl_patrim_liq", (0)::numeric) DESC;



CREATE OR REPLACE VIEW "public"."folha_gabinete_atual" AS
 SELECT "f"."id",
    "f"."casa",
    "f"."snapshot_date",
    "f"."chave_natural",
    "f"."secretario_nome",
    "f"."secretario_id_externo",
    "f"."cargo",
    "f"."funcao",
    "f"."vinculo",
    "f"."parlamentar_id_externo",
    "f"."parlamentar_nome",
    "f"."gabinete_codigo",
    "f"."gabinete_raw",
    "f"."data_nomeacao",
    "f"."data_admissao",
    "f"."valor_remuneracao",
    "f"."dados",
    "f"."created_at",
    "f"."updated_at"
   FROM ("public"."folha_gabinete" "f"
     JOIN ( SELECT "folha_gabinete"."casa",
            "max"("folha_gabinete"."snapshot_date") AS "snapshot_date"
           FROM "public"."folha_gabinete"
          GROUP BY "folha_gabinete"."casa") "ultimo" ON ((("ultimo"."casa" = "f"."casa") AND ("ultimo"."snapshot_date" = "f"."snapshot_date"))));



CREATE MATERIALIZED VIEW "public"."fornecedores_intersetados" AS
 WITH "alepe" AS (
         SELECT "g"."cnpj_cpf" AS "cnpj",
            "max"("g"."fornecedor") AS "nome",
            "round"("sum"("g"."valor_bruto"), 2) AS "total",
            "count"(*) AS "notas",
            "count"(DISTINCT "g"."parlamentar_id") AS "deputados"
           FROM (("public"."gastos_parlamentares" "g"
             JOIN "public"."parlamentares_estaduais" "p" ON (("p"."id" = "g"."parlamentar_id")))
             JOIN "public"."casas" "c_1" ON (("c_1"."id" = "p"."casa_id")))
          WHERE (("c_1"."sigla" = 'ALEPE'::"text") AND ("length"("g"."cnpj_cpf") = 14) AND ("g"."cnpj_cpf" !~ "similar_to_escape"('[0]{14}'::"text")))
          GROUP BY "g"."cnpj_cpf"
        ), "alesp" AS (
         SELECT "g"."cnpj_cpf" AS "cnpj",
            "max"("g"."fornecedor") AS "nome",
            "round"("sum"("g"."valor_bruto"), 2) AS "total",
            "count"(*) AS "notas",
            "count"(DISTINCT "g"."parlamentar_id") AS "deputados"
           FROM (("public"."gastos_parlamentares" "g"
             JOIN "public"."parlamentares_estaduais" "p" ON (("p"."id" = "g"."parlamentar_id")))
             JOIN "public"."casas" "c_1" ON (("c_1"."id" = "p"."casa_id")))
          WHERE (("c_1"."sigla" = 'ALESP'::"text") AND ("length"("g"."cnpj_cpf") = 14) AND ("g"."cnpj_cpf" !~ "similar_to_escape"('[0]{14}'::"text")))
          GROUP BY "g"."cnpj_cpf"
        ), "camara" AS (
         SELECT "ceaps_brutas"."cnpj_cpf_fornecedor" AS "cnpj",
            "max"("ceaps_brutas"."nome_fornecedor") AS "nome",
            "round"("sum"("ceaps_brutas"."valor_liquido"), 2) AS "total",
            "count"(*) AS "notas",
            "count"(DISTINCT "ceaps_brutas"."deputado_id_externo") AS "deputados"
           FROM "public"."ceaps_brutas"
          WHERE (("length"("ceaps_brutas"."cnpj_cpf_fornecedor") = 14) AND ("ceaps_brutas"."cnpj_cpf_fornecedor" !~ "similar_to_escape"('[0]{14}'::"text")))
          GROUP BY "ceaps_brutas"."cnpj_cpf_fornecedor"
        )
 SELECT "a"."cnpj",
    "upper"(COALESCE("a"."nome", "al"."nome", "c"."nome")) AS "nome",
    "a"."total" AS "total_alepe",
    "a"."notas" AS "notas_alepe",
    "a"."deputados" AS "deps_alepe",
    "al"."total" AS "total_alesp",
    "al"."notas" AS "notas_alesp",
    "al"."deputados" AS "deps_alesp",
    "c"."total" AS "total_camara",
    "c"."notas" AS "notas_camara",
    "c"."deputados" AS "deps_camara",
    true AS "em_alepe",
    ("al"."cnpj" IS NOT NULL) AS "em_alesp",
    ("c"."cnpj" IS NOT NULL) AS "em_camara",
    ((1 + (("al"."cnpj" IS NOT NULL))::integer) + (("c"."cnpj" IS NOT NULL))::integer) AS "n_casas",
    "round"((("a"."total" + COALESCE("al"."total", (0)::numeric)) + COALESCE("c"."total", (0)::numeric)), 2) AS "total_geral"
   FROM (("alepe" "a"
     LEFT JOIN "alesp" "al" ON (("a"."cnpj" = "al"."cnpj")))
     LEFT JOIN "camara" "c" ON (("a"."cnpj" = "c"."cnpj")))
  WHERE (("al"."cnpj" IS NOT NULL) OR ("c"."cnpj" IS NOT NULL))
  WITH NO DATA;



CREATE OR REPLACE VIEW "public"."fundacoes_resumo" AS
 SELECT "r"."cnpj_fundacao",
    "f"."nome_popular",
    "f"."razao_social",
    "r"."sg_partido",
    "r"."aa_exercicio",
    "count"(*) AS "qtd_repasses",
    "sum"("r"."vr_pagamento") AS "total_repassado",
    "avg"("r"."vr_pagamento") AS "media_por_repasse",
    "sum"("r"."vr_pagamento") FILTER (WHERE ("r"."tipo_repasse" = 'fundacao_partidaria'::"text")) AS "total_fundacao_partidaria",
    "sum"("r"."vr_pagamento") FILTER (WHERE ("r"."tipo_repasse" = 'aluguel'::"text")) AS "total_aluguel",
    "sum"("r"."vr_pagamento") FILTER (WHERE ("r"."tipo_repasse" = 'servico'::"text")) AS "total_servico",
    "count"(DISTINCT "date_trunc"('month'::"text", ("r"."dt_pagamento")::timestamp with time zone)) AS "meses_com_repasse",
    "sum"("r"."vr_pagamento") FILTER (WHERE (EXTRACT(month FROM "r"."dt_pagamento") = ANY (ARRAY[(10)::numeric, (11)::numeric, (12)::numeric]))) AS "total_q4",
    "round"(((100.0 * "sum"("r"."vr_pagamento") FILTER (WHERE (EXTRACT(month FROM "r"."dt_pagamento") = ANY (ARRAY[(10)::numeric, (11)::numeric, (12)::numeric])))) / NULLIF("sum"("r"."vr_pagamento"), (0)::numeric)), 1) AS "pct_q4",
    "f"."mesmo_endereco_partido",
    "f"."presidente_nome"
   FROM ("public"."fundacoes_repasses" "r"
     LEFT JOIN "public"."fundacoes_partidarias" "f" ON (("f"."cnpj" = "r"."cnpj_fundacao")))
  GROUP BY "r"."cnpj_fundacao", "f"."nome_popular", "f"."razao_social", "r"."sg_partido", "r"."aa_exercicio", "f"."mesmo_endereco_partido", "f"."presidente_nome";



CREATE OR REPLACE VIEW "public"."fundacoes_alertas" AS
 SELECT "f"."cnpj",
    "f"."nome_popular",
    "f"."partido_sigla",
    "f"."presidente_nome",
    "f"."mesmo_endereco_partido" AS "alerta_sede_compartilhada",
    (COALESCE("r"."total_aluguel", (0)::numeric) > (0)::numeric) AS "alerta_aluguel_circular",
    COALESCE("r"."total_aluguel", (0)::numeric) AS "valor_aluguel_anual",
    (COALESCE("r"."pct_q4", (0)::numeric) > (40)::numeric) AS "alerta_concentracao_q4",
    COALESCE("r"."pct_q4", (0)::numeric) AS "pct_q4",
    (("f"."razao_social" !~~* '%fundaç%'::"text") AND ("f"."razao_social" !~~* '%fundac%'::"text") AND ("f"."razao_social" !~~* '%instituto%'::"text")) AS "alerta_natureza_juridica_suspeita",
    COALESCE("r"."total_repassado", (0)::numeric) AS "total_repassado",
    COALESCE("r"."qtd_repasses", (0)::bigint) AS "qtd_repasses",
    "r"."aa_exercicio",
    (((("f"."mesmo_endereco_partido")::integer + ((COALESCE("r"."total_aluguel", (0)::numeric) > (0)::numeric))::integer) + ((COALESCE("r"."pct_q4", (0)::numeric) > (40)::numeric))::integer) + ((("f"."razao_social" !~~* '%fundaç%'::"text") AND ("f"."razao_social" !~~* '%fundac%'::"text") AND ("f"."razao_social" !~~* '%instituto%'::"text")))::integer) AS "score_alertas"
   FROM ("public"."fundacoes_partidarias" "f"
     LEFT JOIN "public"."fundacoes_resumo" "r" ON (("r"."cnpj_fundacao" = "f"."cnpj")))
  ORDER BY (((("f"."mesmo_endereco_partido")::integer + ((COALESCE("r"."total_aluguel", (0)::numeric) > (0)::numeric))::integer) + ((COALESCE("r"."pct_q4", (0)::numeric) > (40)::numeric))::integer) + ((("f"."razao_social" !~~* '%fundaç%'::"text") AND ("f"."razao_social" !~~* '%fundac%'::"text") AND ("f"."razao_social" !~~* '%instituto%'::"text")))::integer) DESC, COALESCE("r"."total_repassado", (0)::numeric) DESC;



CREATE OR REPLACE VIEW "public"."fundacoes_fornecedores_ranking" AS
 SELECT "nf"."sg_partido",
    "nf"."cnpj_fornecedor",
    "nf"."aa_exercicio",
    "f"."nome_popular" AS "nome_fundacao",
    "nf"."ds_tipo_despesa",
    "nf"."eh_repasse_fundacao",
    "count"(*) AS "qtd_nfs",
    "sum"("nf"."vr_documento") AS "total_pago",
    "min"("nf"."dt_pagamento") AS "primeiro_pagamento",
    "max"("nf"."dt_pagamento") AS "ultimo_pagamento",
    "count"("nf"."url_pdf") FILTER (WHERE ("nf"."url_pdf" IS NOT NULL)) AS "qtd_pdfs_disponiveis"
   FROM ("public"."fundacoes_nf_partidos" "nf"
     LEFT JOIN "public"."fundacoes_partidarias" "f" ON (("f"."cnpj" = "nf"."fundacao_cnpj")))
  GROUP BY "nf"."sg_partido", "nf"."cnpj_fornecedor", "nf"."aa_exercicio", "f"."nome_popular", "nf"."ds_tipo_despesa", "nf"."eh_repasse_fundacao"
  ORDER BY ("sum"("nf"."vr_documento")) DESC;



CREATE OR REPLACE VIEW "public"."fundacoes_ranking_publico" AS
 SELECT "f"."cnpj",
    "f"."nome_popular",
    "f"."partido_sigla",
    "f"."presidente_nome",
    "f"."presidente_desde",
    "f"."municipio",
    "f"."uf",
    "f"."data_abertura",
    "f"."mesmo_endereco_partido",
    "f"."mesmo_telefone_partido",
    COALESCE("r"."total_repassado", (0)::numeric) AS "total_repassado_2024",
    COALESCE("r"."qtd_repasses", (0)::bigint) AS "qtd_repasses_2024",
    COALESCE("r"."total_aluguel", (0)::numeric) AS "total_aluguel_2024",
    COALESCE("r"."pct_q4", (0)::numeric) AS "pct_q4_2024",
    COALESCE("a"."score_alertas", 0) AS "score_alertas"
   FROM (("public"."fundacoes_partidarias" "f"
     LEFT JOIN "public"."fundacoes_resumo" "r" ON ((("r"."cnpj_fundacao" = "f"."cnpj") AND ("r"."aa_exercicio" = 2024))))
     LEFT JOIN "public"."fundacoes_alertas" "a" ON ((("a"."cnpj" = "f"."cnpj") AND ("a"."aa_exercicio" = 2024))))
  ORDER BY COALESCE("r"."total_repassado", (0)::numeric) DESC;



CREATE OR REPLACE VIEW "public"."fundacoes_vazio_prestacao" AS
 SELECT "f"."cnpj",
    "f"."nome_popular",
    "f"."partido_sigla",
    "f"."presidente_nome",
    "r"."total_repassado_2024",
    (EXISTS ( SELECT 1
           FROM "public"."fundacoes_nf_partidos" "nf2"
          WHERE (("nf2"."cnpj_partido" = "f"."cnpj") AND ("nf2"."aa_exercicio" = 2024)))) AS "presta_contas_proprias",
    COALESCE(( SELECT "count"(*) AS "count"
           FROM "public"."fundacoes_nf_partidos" "nf3"
          WHERE (("nf3"."fundacao_cnpj" = "f"."cnpj") AND ("nf3"."aa_exercicio" = 2024))), (0)::bigint) AS "qtd_nfs_recebidas_do_partido"
   FROM ("public"."fundacoes_partidarias" "f"
     LEFT JOIN "public"."fundacoes_ranking_publico" "r" ON (("r"."cnpj" = "f"."cnpj")));



CREATE OR REPLACE VIEW "public"."highlights" AS
 SELECT "h"."id",
    "h"."titulo_curto",
    "h"."resumo",
    "t"."sigla" AS "tribunal",
    "h"."tema",
    "h"."link_externo",
    "h"."posicao",
    "h"."semana_referencia",
    "h"."processo_id",
    "p"."numero_processo",
    "p"."classe",
    "p"."relator",
    "p"."data_decisao",
    "h"."ativo",
    "h"."created_at",
    "h"."updated_at"
   FROM (("public"."judiciario_highlights" "h"
     LEFT JOIN "public"."tribunais" "t" ON (("t"."id" = "h"."tribunal_id")))
     LEFT JOIN "public"."judiciario_processos" "p" ON (("p"."id" = "h"."processo_id")));



CREATE OR REPLACE VIEW "public"."highlights_publico" AS
 SELECT "id",
    "titulo_curto",
    "resumo",
    "tribunal",
    "tema",
    "link_externo",
    "posicao",
    "semana_referencia",
    "processo_id",
    "numero_processo",
    "classe",
    "relator",
    "data_decisao"
   FROM "public"."highlights"
  WHERE ("ativo" = true)
  ORDER BY "semana_referencia" DESC, "posicao";



CREATE OR REPLACE VIEW "public"."ibge_municipios_enriquecidos" AS
 SELECT "m"."codigo_ibge",
    "m"."nome",
    "m"."uf",
    "m"."nome_uf",
    "m"."nome_regiao",
    "m"."nome_mesorregiao",
    "pib"."valor" AS "pib_total_mil_reais",
    "pib"."ano" AS "pib_ano",
        CASE
            WHEN ("pop"."valor" > (0)::numeric) THEN "round"((("pib"."valor" * 1000.0) / "pop"."valor"), 2)
            ELSE NULL::numeric
        END AS "pib_percapita_calculado",
    "pop"."valor" AS "populacao",
    "pop"."ano" AS "populacao_ano"
   FROM (("public"."ibge_municipios" "m"
     LEFT JOIN "public"."ibge_indicadores" "pib" ON ((("pib"."codigo_ibge" = "m"."codigo_ibge") AND ("pib"."pesquisa_id" = 'pib-municipios'::"text") AND ("pib"."variavel_id" = 'pib_total_mil_reais'::"text") AND ("pib"."ano" = ( SELECT "max"("ibge_indicadores"."ano") AS "max"
           FROM "public"."ibge_indicadores"
          WHERE (("ibge_indicadores"."codigo_ibge" = "m"."codigo_ibge") AND ("ibge_indicadores"."pesquisa_id" = 'pib-municipios'::"text") AND ("ibge_indicadores"."variavel_id" = 'pib_total_mil_reais'::"text")))))))
     LEFT JOIN "public"."ibge_indicadores" "pop" ON ((("pop"."codigo_ibge" = "m"."codigo_ibge") AND ("pop"."pesquisa_id" = 'censo-2022'::"text") AND ("pop"."variavel_id" = 'populacao'::"text") AND ("pop"."ano" = 2022))));



CREATE MATERIALIZED VIEW "public"."indice_poder_orcamentario" AS
 SELECT "e"."ano",
    "p"."id" AS "parlamentar_id",
    "p"."nome_parlamentar" AS "parlamentar",
    COALESCE("sum"("e"."valor_empenhado"), (0)::numeric) AS "valor_total",
    COALESCE("sum"("e"."valor_pago"), (0)::numeric) AS "valor_pago",
        CASE
            WHEN ("sum"("e"."valor_empenhado") > (0)::numeric) THEN "round"((("sum"("e"."valor_pago") / "sum"("e"."valor_empenhado")) * (100)::numeric), 2)
            ELSE (0)::numeric
        END AS "execucao_percentual",
    "count"(DISTINCT "e"."municipio_nome") AS "municipios_atendidos",
    'emendas'::"text" AS "tipo"
   FROM ("public"."emendas" "e"
     JOIN "public"."parlamentares" "p" ON (("p"."id" = "e"."parlamentar_id")))
  GROUP BY "e"."ano", "p"."id", "p"."nome_parlamentar"
  WITH NO DATA;



CREATE MATERIALIZED VIEW "public"."parlamentar_activity_monthly" AS
 SELECT "parlamentar_uid",
    "date_trunc"('month'::"text", ("event_date")::timestamp with time zone) AS "mes",
    "count"(*) AS "total_eventos",
    "sum"(COALESCE((("metadata" ->> 'valor_pago'::"text"))::numeric, (0)::numeric)) AS "volume_orcamentario"
   FROM "public"."timeline_events"
  GROUP BY "parlamentar_uid", ("date_trunc"('month'::"text", ("event_date")::timestamp with time zone))
  WITH NO DATA;



CREATE MATERIALIZED VIEW "public"."influence_velocity" AS
 SELECT "parlamentar_uid",
    "mes",
    "total_eventos",
    "volume_orcamentario",
    ("total_eventos" - "lag"("total_eventos") OVER (PARTITION BY "parlamentar_uid" ORDER BY "mes")) AS "delta_eventos",
    ("volume_orcamentario" - "lag"("volume_orcamentario") OVER (PARTITION BY "parlamentar_uid" ORDER BY "mes")) AS "delta_orcamento"
   FROM "public"."parlamentar_activity_monthly"
  WITH NO DATA;



CREATE MATERIALIZED VIEW "public"."influence_velocity_score" AS
 SELECT "parlamentar_uid",
    "mes",
    (((COALESCE("delta_eventos", (0)::bigint))::numeric * 0.4) + (COALESCE("delta_orcamento", (0)::numeric) * 0.6)) AS "ive_score"
   FROM "public"."influence_velocity"
  WITH NO DATA;



CREATE MATERIALIZED VIEW "public"."ipi_base_power" AS
 SELECT "parlamentar_uid",
    "count"(*) AS "total_eventos"
   FROM "public"."timeline_events"
  GROUP BY "parlamentar_uid"
  WITH NO DATA;



CREATE MATERIALIZED VIEW "public"."ipi_budget_power" AS
 SELECT "parlamentar_uid",
    "sum"(COALESCE((("metadata" ->> 'valor_pago'::"text"))::numeric, (0)::numeric)) AS "volume_total"
   FROM "public"."timeline_events"
  WHERE ("event_type" = 'budget_execution'::"text")
  GROUP BY "parlamentar_uid"
  WITH NO DATA;



CREATE MATERIALIZED VIEW "public"."ipi_experience" AS
 SELECT "parlamentar_uid",
    "count"(*) AS "total_mandatos",
    "sum"((EXTRACT(year FROM COALESCE(("fim")::timestamp with time zone, "now"())) - EXTRACT(year FROM "inicio"))) AS "anos_experiencia"
   FROM "public"."mandatos"
  GROUP BY "parlamentar_uid"
  WITH NO DATA;



CREATE MATERIALIZED VIEW "public"."ipi_velocity" AS
 SELECT "parlamentar_uid",
    "avg"("ive_score") AS "velocidade_media"
   FROM "public"."influence_velocity_score"
  GROUP BY "parlamentar_uid"
  WITH NO DATA;



CREATE MATERIALIZED VIEW "public"."institutional_power_index" AS
 SELECT "p"."parlamentar_uid",
    (((((COALESCE("b"."total_eventos", (0)::bigint))::numeric * 0.25) + (COALESCE("e"."anos_experiencia", (0)::numeric) * 0.20)) + (COALESCE("bp"."volume_total", (0)::numeric) * 0.35)) + (COALESCE("v"."velocidade_media", (0)::numeric) * 0.20)) AS "ipi_score"
   FROM (((("public"."parlamentares" "p"
     LEFT JOIN "public"."ipi_base_power" "b" USING ("parlamentar_uid"))
     LEFT JOIN "public"."ipi_experience" "e" USING ("parlamentar_uid"))
     LEFT JOIN "public"."ipi_budget_power" "bp" USING ("parlamentar_uid"))
     LEFT JOIN "public"."ipi_velocity" "v" USING ("parlamentar_uid"))
  WITH NO DATA;



CREATE MATERIALIZED VIEW "public"."judiciario_stats_por_ano_tribunal" AS
 SELECT "t"."id" AS "tribunal_id",
    "t"."sigla" AS "tribunal",
    (EXTRACT(year FROM "p"."data_decisao"))::integer AS "ano",
    "count"(*) AS "total"
   FROM ("public"."tribunais" "t"
     JOIN "public"."judiciario_processos" "p" ON (("p"."tribunal_id" = "t"."id")))
  WHERE ("p"."data_decisao" IS NOT NULL)
  GROUP BY "t"."id", "t"."sigla", (EXTRACT(year FROM "p"."data_decisao"))
  WITH NO DATA;



CREATE MATERIALIZED VIEW "public"."judiciario_stats_por_classe_tribunal" AS
 SELECT "t"."id" AS "tribunal_id",
    "t"."sigla" AS "tribunal",
    "p"."classe",
    "count"(*) AS "total"
   FROM ("public"."tribunais" "t"
     JOIN "public"."judiciario_processos" "p" ON (("p"."tribunal_id" = "t"."id")))
  WHERE ("p"."classe" IS NOT NULL)
  GROUP BY "t"."id", "t"."sigla", "p"."classe"
  WITH NO DATA;



CREATE MATERIALIZED VIEW "public"."judiciario_stats_por_relator" AS
 SELECT "t"."id" AS "tribunal_id",
    "t"."sigla" AS "tribunal",
    "p"."relator",
    "count"(*) AS "processos",
    "count"(*) FILTER (WHERE ("p"."data_decisao" IS NOT NULL)) AS "com_decisao",
    "max"("p"."data_decisao") AS "ultima_decisao",
    ( SELECT "p2"."classe"
           FROM "public"."judiciario_processos" "p2"
          WHERE (("p2"."tribunal_id" = "t"."id") AND ("p2"."relator" = "p"."relator"))
          GROUP BY "p2"."classe"
          ORDER BY ("count"(*)) DESC NULLS LAST
         LIMIT 1) AS "classe_principal"
   FROM ("public"."tribunais" "t"
     JOIN "public"."judiciario_processos" "p" ON (("p"."tribunal_id" = "t"."id")))
  WHERE (("p"."relator" IS NOT NULL) AND ("p"."relator" <> ''::"text"))
  GROUP BY "t"."id", "t"."sigla", "p"."relator"
  WITH NO DATA;



CREATE MATERIALIZED VIEW "public"."judiciario_stats_por_tribunal" AS
 SELECT "t"."id" AS "tribunal_id",
    "t"."sigla" AS "tribunal",
    "count"(*) AS "total",
    "count"(*) FILTER (WHERE ("p"."data_decisao" IS NOT NULL)) AS "com_decisao",
    "count"(DISTINCT "p"."relator") FILTER (WHERE ("p"."relator" IS NOT NULL)) AS "qtd_relatores",
    "count"(DISTINCT "p"."classe") FILTER (WHERE ("p"."classe" IS NOT NULL)) AS "qtd_classes",
    "max"("p"."data_decisao") AS "ultima_decisao",
    "max"("p"."data_coleta") AS "ultima_coleta"
   FROM ("public"."tribunais" "t"
     LEFT JOIN "public"."judiciario_processos" "p" ON (("p"."tribunal_id" = "t"."id")))
  GROUP BY "t"."id", "t"."sigla"
  WITH NO DATA;



CREATE OR REPLACE VIEW "public"."mandato_raiox" AS
 SELECT "m"."id" AS "mandato_id",
    "p"."nome",
    "p"."nome_parlamentar",
    "p"."partido",
    "p"."uf",
    "p"."foto_url",
    "m"."legislatura",
    "m"."ativo",
    "count"("e"."id") AS "total_emendas",
    COALESCE("sum"("e"."valor_empenhado"), (0)::numeric) AS "valor_empenhado",
    COALESCE("sum"("e"."valor_liquidado"), (0)::numeric) AS "valor_liquidado",
    COALESCE("sum"("e"."valor_pago"), (0)::numeric) AS "valor_pago"
   FROM (("public"."mandatos" "m"
     JOIN "public"."parlamentares" "p" ON (("p"."id" = "m"."parlamentar_id")))
     LEFT JOIN "public"."emendas" "e" ON (("e"."mandato_id" = "m"."id")))
  GROUP BY "m"."id", "p"."nome", "p"."nome_parlamentar", "p"."partido", "p"."uf", "p"."foto_url", "m"."legislatura", "m"."ativo";



CREATE OR REPLACE VIEW "public"."mg_compras_fornecedor_total" AS
 SELECT "cnpj_norm",
    "max"("nome") AS "nome",
    "sum"("vr_homologado") AS "vr_homologado",
    "sum"("n_contratos") AS "n_contratos"
   FROM "public"."mg_compras_fornecedor"
  GROUP BY "cnpj_norm";



CREATE OR REPLACE VIEW "public"."mg_compras_resumo" AS
 SELECT "sum"("vr_homologado") AS "total",
    ("count"(*))::integer AS "fornecedores",
    ("sum"("n_contratos"))::bigint AS "contratos"
   FROM "public"."mg_compras_fornecedor_total";



CREATE OR REPLACE VIEW "public"."mg_contratos_sancionados" AS
 SELECT "c"."nome_fornecedor" AS "fornecedor",
    "s"."cnpj_fmt",
    "c"."nome_orgao" AS "orgao",
    "c"."objeto",
    "c"."valor_total",
    "c"."numero_contrato",
    "c"."situacao",
    "c"."data_assinatura",
    "c"."data_termino_vigencia" AS "data_termino",
    "s"."conduta",
    "s"."decisao",
    "s"."fase",
    "s"."valor_multa",
    "s"."orgao_lesado",
    "s"."data_publicacao_decisao",
    (("s"."decisao" IS NOT NULL) AND ("s"."decisao" !~* 'arquiv'::"text") AND ("s"."decisao" !~* 'absolv'::"text")) AS "condenada",
    "regexp_replace"("c"."cnpj_cpf_fornecedor", '\D'::"text", ''::"text", 'g'::"text") AS "cnpj_norm"
   FROM ("public"."mg_contratos" "c"
     JOIN "public"."mg_empresas_sancionadas" "s" ON ((("s"."cnpj_norm" = "regexp_replace"("c"."cnpj_cpf_fornecedor", '\D'::"text", ''::"text", 'g'::"text")) AND ("length"("regexp_replace"(COALESCE("c"."cnpj_cpf_fornecedor", ''::"text"), '\D'::"text", ''::"text", 'g'::"text")) = 14))))
  ORDER BY (("s"."decisao" IS NOT NULL) AND ("s"."decisao" !~* 'arquiv'::"text") AND ("s"."decisao" !~* 'absolv'::"text")) DESC, "c"."valor_total" DESC NULLS LAST;



CREATE OR REPLACE VIEW "public"."mg_convenios_sancionados" AS
 SELECT "cv"."convenio_id",
    "cv"."ano",
    "cv"."convenente",
    "cv"."convenente_cnpj",
    "cv"."orgao_id",
    "cv"."vr_total",
    "cv"."vr_emenda_parl",
    "s"."conduta",
    "s"."decisao",
    "s"."fase",
    (("s"."decisao" IS NOT NULL) AND ("s"."decisao" !~* 'arquiv'::"text") AND ("s"."decisao" !~* 'absolv'::"text")) AS "condenada"
   FROM ("public"."mg_convenios" "cv"
     JOIN "public"."mg_empresas_sancionadas" "s" ON ((("s"."cnpj_norm" = "cv"."convenente_cnpj") AND ("length"(COALESCE("cv"."convenente_cnpj", ''::"text")) = 14))))
  ORDER BY "cv"."vr_total" DESC NULLS LAST;



CREATE OR REPLACE VIEW "public"."mg_covid_sancionados" AS
 SELECT "cc"."contratado",
    "cc"."cnpj_norm",
    "cc"."orgao_demandante",
    "cc"."objeto",
    "cc"."valor_homologado",
    "cc"."procedimento",
    "s"."conduta",
    "s"."decisao",
    "s"."fase",
    (("s"."decisao" IS NOT NULL) AND ("s"."decisao" !~* 'arquiv'::"text") AND ("s"."decisao" !~* 'absolv'::"text")) AS "condenada"
   FROM ("public"."mg_covid_compras" "cc"
     JOIN "public"."mg_empresas_sancionadas" "s" ON ((("s"."cnpj_norm" = "cc"."cnpj_norm") AND ("length"(COALESCE("cc"."cnpj_norm", ''::"text")) = 14))))
  ORDER BY "cc"."valor_homologado" DESC NULLS LAST;



CREATE OR REPLACE VIEW "public"."mg_covid_sobrepreco" AS
 SELECT "contratado",
    "cnpj_norm",
    "orgao_demandante",
    "objeto",
    "item",
    "procedimento",
    "quantidade",
    "valor_ref_unit",
    "valor_hom_unit",
    "valor_homologado",
    "round"(("valor_hom_unit" - "valor_ref_unit"), 2) AS "sobrepreco_unit",
    "round"(((("valor_hom_unit" - "valor_ref_unit") / NULLIF("valor_ref_unit", (0)::numeric)) * (100)::numeric), 1) AS "sobrepreco_pct"
   FROM "public"."mg_covid_compras"
  WHERE (("valor_ref_unit" > (0)::numeric) AND ("valor_hom_unit" > "valor_ref_unit"))
  ORDER BY (("valor_hom_unit" - "valor_ref_unit") * COALESCE("quantidade", (1)::numeric)) DESC NULLS LAST;



CREATE OR REPLACE VIEW "public"."mg_cruzamento_emendas" AS
 WITH "mg_agg" AS (
         SELECT "mg_empenhos"."cnpj_cpf_credor",
            "max"("mg_empenhos"."razao_social_credor") AS "razao_social_mg",
            "count"(DISTINCT "mg_empenhos"."id") AS "n_empenhos_mg",
            "sum"("mg_empenhos"."valor_pago") AS "total_pago_mg"
           FROM "public"."mg_empenhos"
          WHERE ("mg_empenhos"."cnpj_cpf_credor" IS NOT NULL)
          GROUP BY "mg_empenhos"."cnpj_cpf_credor"
        ), "fed_agg" AS (
         SELECT "regexp_replace"("emendas_favorecidos"."codigo_favorecido", '[^0-9]'::"text", ''::"text", 'g'::"text") AS "cnpj_digits",
            "count"(DISTINCT "emendas_favorecidos"."id") AS "n_transacoes_emendas_fed",
            "sum"("emendas_favorecidos"."valor_recebido") AS "total_emendas_fed"
           FROM "public"."emendas_favorecidos"
          WHERE ("emendas_favorecidos"."codigo_favorecido" IS NOT NULL)
          GROUP BY ("regexp_replace"("emendas_favorecidos"."codigo_favorecido", '[^0-9]'::"text", ''::"text", 'g'::"text"))
        )
 SELECT "m"."cnpj_cpf_credor" AS "cnpj",
    "m"."razao_social_mg",
    "m"."n_empenhos_mg",
    "m"."total_pago_mg",
    "f"."n_transacoes_emendas_fed",
    "f"."total_emendas_fed"
   FROM ("mg_agg" "m"
     JOIN "fed_agg" "f" ON (("regexp_replace"("m"."cnpj_cpf_credor", '[^0-9]'::"text", ''::"text", 'g'::"text") = "f"."cnpj_digits")))
  ORDER BY "m"."total_pago_mg" DESC NULLS LAST;



CREATE OR REPLACE VIEW "public"."mg_emendas_estaduais_por_autor" AS
 SELECT COALESCE("autor", '(não informado)'::"text") AS "autor",
    ("count"(*))::integer AS "n",
    "sum"("vr_emenda") AS "total"
   FROM "public"."mg_emendas_estaduais"
  GROUP BY COALESCE("autor", '(não informado)'::"text");



CREATE OR REPLACE VIEW "public"."mg_emendas_estaduais_resumo" AS
 SELECT "sum"("vr_emenda") AS "total",
    ("count"(*))::integer AS "emendas",
    ("count"(DISTINCT "autor"))::integer AS "autores"
   FROM "public"."mg_emendas_estaduais";



CREATE OR REPLACE VIEW "public"."mg_licitacao_sobrepreco_rel" AS
 SELECT "id",
    "ano",
    "numero_processo",
    "numero_item",
    "orgao",
    "objeto",
    "fornecedor",
    "cnpj_norm",
    "item_descricao",
    "elemento",
    "situacao",
    "quantidade",
    "vr_unit_referencia",
    "vr_unit_homologado",
    "vr_total_referencia",
    "vr_total_homologado",
    "sobrepreco_valor",
    "sobrepreco_pct",
    "created_at"
   FROM "public"."mg_licitacao_sobrepreco"
  WHERE (("sobrepreco_pct" IS NOT NULL) AND ("sobrepreco_pct" <= (1000)::numeric) AND ("sobrepreco_valor" > (0)::numeric));



CREATE OR REPLACE VIEW "public"."mg_notas_fornecedor_total" AS
 SELECT "cnpj_norm",
    "max"("nome") AS "nome",
    "sum"("valor_total") AS "valor_total",
    "sum"("n_notas") AS "n_notas"
   FROM "public"."mg_notas_fornecedor"
  GROUP BY "cnpj_norm";



CREATE OR REPLACE VIEW "public"."mg_fornecedor_perfil" AS
 WITH "contratos_agg" AS (
         SELECT "regexp_replace"("mg_contratos"."cnpj_cpf_fornecedor", '\D'::"text", ''::"text", 'g'::"text") AS "cnpj_norm",
            "max"("mg_contratos"."nome_fornecedor") AS "nome_contrato",
            ("count"(*))::integer AS "n_contratos",
            "sum"("mg_contratos"."valor_total") AS "valor_contratado",
            ("count"(DISTINCT "mg_contratos"."nome_orgao"))::integer AS "n_orgaos"
           FROM "public"."mg_contratos"
          WHERE ("length"("regexp_replace"(COALESCE("mg_contratos"."cnpj_cpf_fornecedor", ''::"text"), '\D'::"text", ''::"text", 'g'::"text")) = 14)
          GROUP BY ("regexp_replace"("mg_contratos"."cnpj_cpf_fornecedor", '\D'::"text", ''::"text", 'g'::"text"))
        ), "contratos_top_orgao" AS (
         SELECT DISTINCT ON (("regexp_replace"("mg_contratos"."cnpj_cpf_fornecedor", '\D'::"text", ''::"text", 'g'::"text"))) "regexp_replace"("mg_contratos"."cnpj_cpf_fornecedor", '\D'::"text", ''::"text", 'g'::"text") AS "cnpj_norm",
            "mg_contratos"."nome_orgao" AS "orgao_principal",
            "sum"("mg_contratos"."valor_total") AS "valor_orgao_principal"
           FROM "public"."mg_contratos"
          WHERE (("length"("regexp_replace"(COALESCE("mg_contratos"."cnpj_cpf_fornecedor", ''::"text"), '\D'::"text", ''::"text", 'g'::"text")) = 14) AND ("mg_contratos"."nome_orgao" IS NOT NULL))
          GROUP BY ("regexp_replace"("mg_contratos"."cnpj_cpf_fornecedor", '\D'::"text", ''::"text", 'g'::"text")), "mg_contratos"."nome_orgao"
          ORDER BY ("regexp_replace"("mg_contratos"."cnpj_cpf_fornecedor", '\D'::"text", ''::"text", 'g'::"text")), ("sum"("mg_contratos"."valor_total")) DESC NULLS LAST
        ), "sobrepreco_agg" AS (
         SELECT "mg_licitacao_sobrepreco_rel"."cnpj_norm",
            ("count"(*))::integer AS "sobrepreco_itens",
            "sum"("mg_licitacao_sobrepreco_rel"."sobrepreco_valor") AS "sobrepreco_valor"
           FROM "public"."mg_licitacao_sobrepreco_rel"
          WHERE ("length"(COALESCE("mg_licitacao_sobrepreco_rel"."cnpj_norm", ''::"text")) = 14)
          GROUP BY "mg_licitacao_sobrepreco_rel"."cnpj_norm"
        ), "empenho_agg" AS (
         SELECT "mg_empenhos_sancionados"."cnpj_norm",
            "sum"("mg_empenhos_sancionados"."valor_pago") AS "valor_pago_sancionado",
            ("count"(*))::integer AS "n_empenhos"
           FROM "public"."mg_empenhos_sancionados"
          WHERE ("length"(COALESCE("mg_empenhos_sancionados"."cnpj_norm", ''::"text")) = 14)
          GROUP BY "mg_empenhos_sancionados"."cnpj_norm"
        ), "sanc" AS (
         SELECT DISTINCT ON ("mg_empresas_sancionadas"."cnpj_norm") "mg_empresas_sancionadas"."cnpj_norm",
            "mg_empresas_sancionadas"."empresa" AS "nome_sancao",
            "mg_empresas_sancionadas"."conduta",
            "mg_empresas_sancionadas"."decisao",
            "mg_empresas_sancionadas"."fase",
            "mg_empresas_sancionadas"."valor_multa",
            (("mg_empresas_sancionadas"."decisao" IS NOT NULL) AND ("mg_empresas_sancionadas"."decisao" !~* 'arquiv'::"text") AND ("mg_empresas_sancionadas"."decisao" !~* 'absolv'::"text")) AS "condenada"
           FROM "public"."mg_empresas_sancionadas"
          WHERE ("length"(COALESCE("mg_empresas_sancionadas"."cnpj_norm", ''::"text")) = 14)
          ORDER BY "mg_empresas_sancionadas"."cnpj_norm", (("mg_empresas_sancionadas"."decisao" IS NOT NULL) AND ("mg_empresas_sancionadas"."decisao" !~* 'arquiv'::"text") AND ("mg_empresas_sancionadas"."decisao" !~* 'absolv'::"text")) DESC, "mg_empresas_sancionadas"."valor_multa" DESC NULLS LAST
        ), "terc" AS (
         SELECT "mg_terceirizados"."cnpj_norm",
            "max"("mg_terceirizados"."empresa") AS "nome_terc",
            "max"("mg_terceirizados"."qtd_trabalhadores") AS "terc_qtd_max",
            "max"("mg_terceirizados"."mes_referencia") AS "terc_ultimo_mes"
           FROM "public"."mg_terceirizados"
          WHERE ("length"(COALESCE("mg_terceirizados"."cnpj_norm", ''::"text")) = 14)
          GROUP BY "mg_terceirizados"."cnpj_norm"
        ), "os" AS (
         SELECT DISTINCT ON ("mg_os_parcerias"."cnpj_norm") "mg_os_parcerias"."cnpj_norm",
            "mg_os_parcerias"."entidade" AS "nome_os",
            "mg_os_parcerias"."tipo_instrumento" AS "os_tipo"
           FROM "public"."mg_os_parcerias"
          WHERE ("length"(COALESCE("mg_os_parcerias"."cnpj_norm", ''::"text")) = 14)
          ORDER BY "mg_os_parcerias"."cnpj_norm", "mg_os_parcerias"."vr_repasse_atualizado" DESC NULLS LAST
        ), "base" AS (
         SELECT "contratos_agg"."cnpj_norm"
           FROM "contratos_agg"
        UNION
         SELECT "mg_compras_fornecedor_total"."cnpj_norm"
           FROM "public"."mg_compras_fornecedor_total"
          WHERE ("length"(COALESCE("mg_compras_fornecedor_total"."cnpj_norm", ''::"text")) = 14)
        UNION
         SELECT "mg_notas_fornecedor_total"."cnpj_norm"
           FROM "public"."mg_notas_fornecedor_total"
          WHERE ("length"(COALESCE("mg_notas_fornecedor_total"."cnpj_norm", ''::"text")) = 14)
        ), "joined" AS (
         SELECT "b"."cnpj_norm",
            "regexp_replace"("b"."cnpj_norm", '(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})'::"text", '\1.\2.\3/\4-\5'::"text") AS "cnpj_fmt",
            COALESCE("n"."nome", "co"."nome", "c"."nome_contrato", "s"."nome_sancao", "t"."nome_terc", "o"."nome_os") AS "fornecedor",
            COALESCE("c"."valor_contratado", (0)::numeric) AS "valor_contratado",
            COALESCE("c"."n_contratos", 0) AS "n_contratos",
            COALESCE("co"."vr_homologado", (0)::numeric) AS "valor_compras_siad",
            COALESCE("co"."n_contratos", (0)::bigint) AS "n_compras",
            COALESCE("n"."valor_total", (0)::numeric) AS "valor_notas",
            COALESCE("n"."n_notas", (0)::bigint) AS "n_notas",
            GREATEST(COALESCE("c"."valor_contratado", (0)::numeric), COALESCE("co"."vr_homologado", (0)::numeric), COALESCE("n"."valor_total", (0)::numeric)) AS "valor_faturado",
            COALESCE("c"."n_orgaos", 0) AS "n_orgaos",
            "cto"."orgao_principal",
                CASE
                    WHEN (COALESCE("c"."valor_contratado", (0)::numeric) > (0)::numeric) THEN "round"(("cto"."valor_orgao_principal" / "c"."valor_contratado"), 4)
                    ELSE NULL::numeric
                END AS "concentracao_orgao",
            COALESCE("ea"."valor_pago_sancionado", (0)::numeric) AS "valor_pago_sancionado",
            COALESCE("ea"."n_empenhos", 0) AS "n_empenhos_sancionado",
            COALESCE("sp"."sobrepreco_itens", 0) AS "sobrepreco_itens",
            COALESCE("sp"."sobrepreco_valor", (0)::numeric) AS "sobrepreco_valor",
            ("s"."cnpj_norm" IS NOT NULL) AS "processada",
            COALESCE("s"."condenada", false) AS "condenada",
            "s"."conduta",
            "s"."decisao",
            "s"."fase",
            "s"."valor_multa",
            ("t"."cnpj_norm" IS NOT NULL) AS "terceirizada",
            "t"."terc_qtd_max",
            ("o"."cnpj_norm" IS NOT NULL) AS "organizacao_social",
            "o"."os_tipo"
           FROM ((((((((("base" "b"
             LEFT JOIN "contratos_agg" "c" ON (("c"."cnpj_norm" = "b"."cnpj_norm")))
             LEFT JOIN "contratos_top_orgao" "cto" ON (("cto"."cnpj_norm" = "b"."cnpj_norm")))
             LEFT JOIN "public"."mg_compras_fornecedor_total" "co" ON (("co"."cnpj_norm" = "b"."cnpj_norm")))
             LEFT JOIN "public"."mg_notas_fornecedor_total" "n" ON (("n"."cnpj_norm" = "b"."cnpj_norm")))
             LEFT JOIN "sobrepreco_agg" "sp" ON (("sp"."cnpj_norm" = "b"."cnpj_norm")))
             LEFT JOIN "empenho_agg" "ea" ON (("ea"."cnpj_norm" = "b"."cnpj_norm")))
             LEFT JOIN "sanc" "s" ON (("s"."cnpj_norm" = "b"."cnpj_norm")))
             LEFT JOIN "terc" "t" ON (("t"."cnpj_norm" = "b"."cnpj_norm")))
             LEFT JOIN "os" "o" ON (("o"."cnpj_norm" = "b"."cnpj_norm")))
        )
 SELECT "cnpj_norm",
    "cnpj_fmt",
    "fornecedor",
    "valor_contratado",
    "n_contratos",
    "valor_compras_siad",
    "n_compras",
    "valor_notas",
    "n_notas",
    "valor_faturado",
    "n_orgaos",
    "orgao_principal",
    "concentracao_orgao",
    "valor_pago_sancionado",
    "n_empenhos_sancionado",
    "sobrepreco_itens",
    "sobrepreco_valor",
    "processada",
    "condenada",
    "conduta",
    "decisao",
    "fase",
    "valor_multa",
    "terceirizada",
    "terc_qtd_max",
    "organizacao_social",
    "os_tipo",
        CASE
            WHEN "condenada" THEN 50
            ELSE 0
        END AS "risco_condenada",
        CASE
            WHEN ("sobrepreco_valor" >= (1000000)::numeric) THEN 30
            WHEN ("sobrepreco_valor" > (0)::numeric) THEN 15
            ELSE 0
        END AS "risco_sobrepreco",
        CASE
            WHEN (("valor_contratado" >= (1000000)::numeric) AND ("concentracao_orgao" >= 0.95)) THEN 15
            WHEN (("valor_contratado" >= (1000000)::numeric) AND ("concentracao_orgao" >= 0.80)) THEN 10
            WHEN (("valor_contratado" >= (1000000)::numeric) AND ("concentracao_orgao" >= 0.60)) THEN 5
            ELSE 0
        END AS "risco_concentracao",
    LEAST(100, ((
        CASE
            WHEN "condenada" THEN 50
            ELSE 0
        END +
        CASE
            WHEN ("sobrepreco_valor" >= (1000000)::numeric) THEN 30
            WHEN ("sobrepreco_valor" > (0)::numeric) THEN 15
            ELSE 0
        END) +
        CASE
            WHEN (("valor_contratado" >= (1000000)::numeric) AND ("concentracao_orgao" >= 0.95)) THEN 15
            WHEN (("valor_contratado" >= (1000000)::numeric) AND ("concentracao_orgao" >= 0.80)) THEN 10
            WHEN (("valor_contratado" >= (1000000)::numeric) AND ("concentracao_orgao" >= 0.60)) THEN 5
            ELSE 0
        END)) AS "risco_score",
        CASE
            WHEN "condenada" THEN 'alto'::"text"
            WHEN ((
            CASE
                WHEN ("sobrepreco_valor" >= (1000000)::numeric) THEN 30
                WHEN ("sobrepreco_valor" > (0)::numeric) THEN 15
                ELSE 0
            END +
            CASE
                WHEN (("valor_contratado" >= (1000000)::numeric) AND ("concentracao_orgao" >= 0.95)) THEN 15
                WHEN (("valor_contratado" >= (1000000)::numeric) AND ("concentracao_orgao" >= 0.80)) THEN 10
                WHEN (("valor_contratado" >= (1000000)::numeric) AND ("concentracao_orgao" >= 0.60)) THEN 5
                ELSE 0
            END) >= 25) THEN 'medio'::"text"
            WHEN ((
            CASE
                WHEN ("sobrepreco_valor" >= (1000000)::numeric) THEN 30
                WHEN ("sobrepreco_valor" > (0)::numeric) THEN 15
                ELSE 0
            END +
            CASE
                WHEN (("valor_contratado" >= (1000000)::numeric) AND ("concentracao_orgao" >= 0.95)) THEN 15
                WHEN (("valor_contratado" >= (1000000)::numeric) AND ("concentracao_orgao" >= 0.80)) THEN 10
                WHEN (("valor_contratado" >= (1000000)::numeric) AND ("concentracao_orgao" >= 0.60)) THEN 5
                ELSE 0
            END) >= 10) THEN 'baixo'::"text"
            ELSE NULL::"text"
        END AS "risco_label"
   FROM "joined" "j";



CREATE OR REPLACE VIEW "public"."mg_fornecedor_perfil_resumo" AS
 SELECT ("count"(*))::integer AS "fornecedores",
    ("count"(*) FILTER (WHERE "condenada"))::integer AS "condenadas_faturando",
    COALESCE("sum"("valor_pago_sancionado") FILTER (WHERE "condenada"), (0)::numeric) AS "pago_a_condenadas",
    ("count"(*) FILTER (WHERE ("sobrepreco_valor" > (0)::numeric)))::integer AS "com_sobrepreco",
    COALESCE("sum"("sobrepreco_valor"), (0)::numeric) AS "sobrepreco_total",
    ("count"(*) FILTER (WHERE ("risco_label" = 'alto'::"text")))::integer AS "risco_alto",
    COALESCE("max"("valor_faturado"), (0)::numeric) AS "maior_faturamento"
   FROM "public"."mg_fornecedor_perfil";



CREATE OR REPLACE VIEW "public"."mg_licitacao_sobrepreco_por_ano" AS
 SELECT "ano",
    ("count"(*))::integer AS "n",
    "sum"("sobrepreco_valor") AS "total"
   FROM "public"."mg_licitacao_sobrepreco_rel"
  GROUP BY "ano"
  ORDER BY "ano";



CREATE OR REPLACE VIEW "public"."mg_licitacao_sobrepreco_por_orgao" AS
 SELECT "orgao",
    ("count"(*))::integer AS "n",
    "sum"("sobrepreco_valor") AS "total"
   FROM "public"."mg_licitacao_sobrepreco_rel"
  GROUP BY "orgao"
  ORDER BY ("sum"("sobrepreco_valor")) DESC;



CREATE OR REPLACE VIEW "public"."mg_notas_resumo" AS
 SELECT "sum"("valor_total") AS "total",
    ("count"(*))::integer AS "fornecedores",
    ("sum"("n_notas"))::bigint AS "notas"
   FROM "public"."mg_notas_fornecedor_total";



CREATE OR REPLACE VIEW "public"."mg_obras_paradas" AS
 SELECT "contrato",
    "objeto",
    "empresa",
    "orgao",
    "municipios",
    "situacao",
    "dias_paralisados",
    "valor_total",
    "total_medido",
    "percentual_execucao"
   FROM "public"."mg_obras"
  WHERE ("dias_paralisados" > 0)
  ORDER BY "valor_total" DESC NULLS LAST;



CREATE OR REPLACE VIEW "public"."mg_obras_sancionadas" AS
 SELECT "o"."contrato",
    "o"."objeto",
    "o"."empresa",
    "o"."cnpj_norm",
    "o"."orgao",
    "o"."valor_total",
    "o"."situacao",
    "o"."dias_paralisados",
    "o"."percentual_execucao",
    "s"."conduta",
    "s"."decisao",
    "s"."fase",
    (("s"."decisao" IS NOT NULL) AND ("s"."decisao" !~* 'arquiv'::"text") AND ("s"."decisao" !~* 'absolv'::"text")) AS "condenada"
   FROM ("public"."mg_obras" "o"
     JOIN "public"."mg_empresas_sancionadas" "s" ON ((("s"."cnpj_norm" = "o"."cnpj_norm") AND ("length"(COALESCE("o"."cnpj_norm", ''::"text")) = 14))))
  ORDER BY "o"."valor_total" DESC NULLS LAST;



CREATE OR REPLACE VIEW "public"."mg_pagamentos_condenadas" AS
 SELECT "e"."id",
    "e"."ano",
    "e"."numero_empenho",
    "e"."orgao",
    "e"."credor",
    "e"."cnpj_norm",
    "e"."elemento_despesa",
    "e"."fonte_recurso",
    "e"."data_registro",
    "e"."numero_processo",
    "e"."valor_empenhado",
    "e"."valor_liquidado",
    "e"."valor_pago",
    "s"."empresa" AS "empresa_sancao",
    "s"."conduta",
    "s"."decisao",
    "s"."fase",
    "s"."valor_multa"
   FROM ("public"."mg_empenhos_sancionados" "e"
     JOIN "public"."mg_empresas_sancionadas" "s" ON (("s"."cnpj_norm" = "e"."cnpj_norm")))
  WHERE (("s"."decisao" IS NOT NULL) AND ("s"."decisao" !~* 'arquiv'::"text") AND ("s"."decisao" !~* 'absolv'::"text"));



CREATE OR REPLACE VIEW "public"."mg_remuneracao_atual" AS
 SELECT "r"."id",
    "r"."snapshot_mes",
    "r"."ano",
    "r"."mes",
    "r"."poder",
    "r"."orgao",
    "r"."servidor_nome",
    "r"."servidor_id_externo",
    "r"."cargo",
    "r"."funcao",
    "r"."situacao",
    "r"."carga_horaria",
    "r"."remuneracao_bruta",
    "r"."descontos",
    "r"."remuneracao_liquida",
    "r"."remuneracao_base",
    "r"."teto_referencia",
    "r"."dados",
    "r"."url_origem",
    "r"."created_at",
    "r"."updated_at",
    "r"."abate_teto",
    "r"."acima_teto",
    "r"."valor_excedente"
   FROM ("public"."mg_remuneracao" "r"
     JOIN ( SELECT "max"("mg_remuneracao"."snapshot_mes") AS "snapshot_mes"
           FROM "public"."mg_remuneracao") "u" ON (("u"."snapshot_mes" = "r"."snapshot_mes")));



CREATE OR REPLACE VIEW "public"."mg_supersalarios" AS
 SELECT "orgao",
    "servidor_nome",
    "cargo",
    "situacao",
    "remuneracao_bruta",
    "remuneracao_liquida",
    "abate_teto",
    "abate_teto" AS "valor_excedente",
    "servidor_id_externo",
    "ano",
    "mes",
    "snapshot_mes"
   FROM "public"."mg_remuneracao_atual"
  WHERE (COALESCE("abate_teto", (0)::numeric) > (0)::numeric)
  ORDER BY "abate_teto" DESC;



CREATE OR REPLACE VIEW "public"."mg_terceirizados_sancionados" AS
 SELECT "t"."empresa",
    "t"."cnpj_norm",
    "t"."orgao",
    "t"."mes_referencia",
    "t"."qtd_trabalhadores",
    "s"."conduta",
    "s"."decisao",
    "s"."fase",
    (("s"."decisao" IS NOT NULL) AND ("s"."decisao" !~* 'arquiv'::"text") AND ("s"."decisao" !~* 'absolv'::"text")) AS "condenada"
   FROM ("public"."mg_terceirizados" "t"
     JOIN "public"."mg_empresas_sancionadas" "s" ON ((("s"."cnpj_norm" = "t"."cnpj_norm") AND ("length"(COALESCE("t"."cnpj_norm", ''::"text")) = 14))))
  ORDER BY "t"."qtd_trabalhadores" DESC NULLS LAST;



CREATE OR REPLACE VIEW "public"."midia_v_evento_comparativo" AS
 SELECT "e"."slug" AS "evento_slug",
    "e"."nome" AS "evento_nome",
    "e"."data_inicio",
    "v"."slug" AS "veiculo_slug",
    "v"."nome_comercial" AS "veiculo_nome",
    "v"."grupo",
    "max"("k"."audiencia_absoluta") AS "kantar_pico_absoluto",
    "max"("k"."audiencia_media_pct") AS "kantar_media_pct",
    "max"(("k"."metodologia")::"text") AS "kantar_metodologia",
    "max"("y"."views_acumulados") AS "yt_views_acumulados",
    "max"("y"."pico_simultaneos_declarado") AS "yt_pico_declarado",
    "sum"("s"."valor") AS "secom_verba_ano",
        CASE
            WHEN (("max"("y"."pico_simultaneos_declarado") > 0) AND ("max"("k"."audiencia_absoluta") > 0)) THEN "round"((((("max"("y"."pico_simultaneos_declarado"))::numeric / ("max"("k"."audiencia_absoluta"))::numeric) - (1)::numeric) * (100)::numeric), 1)
            ELSE NULL::numeric
        END AS "delta_yt_vs_kantar_pct"
   FROM (((("public"."midia_eventos" "e"
     LEFT JOIN "public"."midia_kantar_releases" "k" ON (("k"."evento_id" = "e"."id")))
     LEFT JOIN "public"."midia_veiculos" "v" ON (("v"."id" = "k"."veiculo_id")))
     LEFT JOIN "public"."midia_youtube_eventos" "y" ON ((("y"."evento_id" = "e"."id") AND ("y"."veiculo_id" = "v"."id"))))
     LEFT JOIN "public"."midia_secom_verbas" "s" ON ((("s"."veiculo_id" = "v"."id") AND ("s"."ano" = (EXTRACT(year FROM "e"."data_inicio"))::smallint))))
  GROUP BY "e"."slug", "e"."nome", "e"."data_inicio", "v"."slug", "v"."nome_comercial", "v"."grupo";



CREATE OR REPLACE VIEW "public"."midia_v_secom_por_grupo" AS
 SELECT "v"."grupo",
    "v"."categoria",
    "s"."ano",
    "sum"("s"."valor") AS "verba_total",
    "count"(DISTINCT "s"."cnpj") AS "cnpjs_beneficiados"
   FROM ("public"."midia_secom_verbas" "s"
     JOIN "public"."midia_veiculos" "v" ON (("v"."id" = "s"."veiculo_id")))
  GROUP BY "v"."grupo", "v"."categoria", "s"."ano"
  ORDER BY "s"."ano" DESC, ("sum"("s"."valor")) DESC;



CREATE OR REPLACE VIEW "public"."midia_v_share_historico" AS
 SELECT "ano",
    "categoria",
    "investimento_total",
    "share_pct",
    "variacao_anual_pct",
    "sum"("investimento_total") OVER (PARTITION BY "ano") AS "mercado_total_ano"
   FROM "public"."midia_inter_meios"
  ORDER BY "ano", "share_pct" DESC;



CREATE OR REPLACE VIEW "public"."vw_contratos_doadores_federal" AS
 WITH "contratos" AS (
         SELECT "contratos_federais"."fornecedor_cnpj" AS "cnpj",
            "max"("contratos_federais"."fornecedor_nome") AS "nome_fornecedor",
            "count"(*) AS "qtd_contratos",
            "sum"("contratos_federais"."valor_total") AS "valor_contratos",
            "min"("contratos_federais"."data_inicio_vigencia") AS "primeiro_contrato",
            "max"("contratos_federais"."data_inicio_vigencia") AS "ultimo_contrato",
            "count"(DISTINCT "contratos_federais"."orgao_descricao") AS "orgaos_distintos"
           FROM "public"."contratos_federais"
          WHERE ("contratos_federais"."fornecedor_cnpj" IS NOT NULL)
          GROUP BY "contratos_federais"."fornecedor_cnpj"
        ), "tse" AS (
         SELECT "regexp_replace"("tse_receitas_brutas"."nr_cpf_cnpj_doador", '[^0-9]'::"text", ''::"text", 'g'::"text") AS "cnpj",
            "count"(*) AS "qtd_doacoes",
            "sum"("tse_receitas_brutas"."vr_receita") AS "valor_doado",
            "count"(DISTINCT "tse_receitas_brutas"."nr_cpf_candidato") AS "candidatos_distintos",
            "count"(DISTINCT "tse_receitas_brutas"."ano_eleicao") AS "eleicoes_distintas",
            "min"("tse_receitas_brutas"."ano_eleicao") AS "primeira_eleicao_doada",
            "max"("tse_receitas_brutas"."ano_eleicao") AS "ultima_eleicao_doada",
            "string_agg"(DISTINCT "tse_receitas_brutas"."nm_candidato", ' | '::"text" ORDER BY "tse_receitas_brutas"."nm_candidato") FILTER (WHERE ("tse_receitas_brutas"."nm_candidato" IS NOT NULL)) AS "candidatos_sample"
           FROM "public"."tse_receitas_brutas"
          WHERE ("length"("regexp_replace"("tse_receitas_brutas"."nr_cpf_cnpj_doador", '[^0-9]'::"text", ''::"text", 'g'::"text")) = 14)
          GROUP BY ("regexp_replace"("tse_receitas_brutas"."nr_cpf_cnpj_doador", '[^0-9]'::"text", ''::"text", 'g'::"text"))
        ), "sancs" AS (
         SELECT "regexp_replace"("portal_sancionados"."cpf_cnpj", '[^0-9]'::"text", ''::"text", 'g'::"text") AS "cnpj",
            "count"(*) AS "qtd_sancoes",
            "sum"(
                CASE
                    WHEN "portal_sancionados"."ativo" THEN 1
                    ELSE 0
                END) AS "sancoes_ativas"
           FROM "public"."portal_sancionados"
          WHERE ("length"("regexp_replace"("portal_sancionados"."cpf_cnpj", '[^0-9]'::"text", ''::"text", 'g'::"text")) = 14)
          GROUP BY ("regexp_replace"("portal_sancionados"."cpf_cnpj", '[^0-9]'::"text", ''::"text", 'g'::"text"))
        )
 SELECT "c"."cnpj",
    "c"."nome_fornecedor",
    "c"."qtd_contratos",
    "c"."valor_contratos",
    "c"."primeiro_contrato",
    "c"."ultimo_contrato",
    "c"."orgaos_distintos",
    "t"."qtd_doacoes",
    "t"."valor_doado",
    "t"."candidatos_distintos",
    "t"."eleicoes_distintas",
    "t"."primeira_eleicao_doada",
    "t"."ultima_eleicao_doada",
    "t"."candidatos_sample",
    ("t"."cnpj" IS NOT NULL) AS "is_doador_tse",
    "s"."qtd_sancoes",
    "s"."sancoes_ativas",
    ("s"."cnpj" IS NOT NULL) AS "is_sancionado",
    ("s"."sancoes_ativas" > 0) AS "is_sancionado_ativo",
    (
        CASE
            WHEN ("t"."cnpj" IS NOT NULL) THEN 1
            ELSE 0
        END +
        CASE
            WHEN ("s"."sancoes_ativas" > 0) THEN 2
            ELSE 0
        END) AS "risk_score"
   FROM (("contratos" "c"
     LEFT JOIN "tse" "t" ON (("t"."cnpj" = "c"."cnpj")))
     LEFT JOIN "sancs" "s" ON (("s"."cnpj" = "c"."cnpj")))
  ORDER BY (
        CASE
            WHEN ("t"."cnpj" IS NOT NULL) THEN 1
            ELSE 0
        END +
        CASE
            WHEN ("s"."sancoes_ativas" > 0) THEN 2
            ELSE 0
        END) DESC, "c"."valor_contratos" DESC NULLS LAST;



CREATE MATERIALIZED VIEW "public"."mv_contratos_doadores_federal" AS
 SELECT "cnpj",
    "nome_fornecedor",
    "qtd_contratos",
    "valor_contratos",
    "primeiro_contrato",
    "ultimo_contrato",
    "orgaos_distintos",
    "qtd_doacoes",
    "valor_doado",
    "candidatos_distintos",
    "eleicoes_distintas",
    "primeira_eleicao_doada",
    "ultima_eleicao_doada",
    "candidatos_sample",
    "is_doador_tse",
    "qtd_sancoes",
    "sancoes_ativas",
    "is_sancionado",
    "is_sancionado_ativo",
    "risk_score"
   FROM "public"."vw_contratos_doadores_federal"
  WITH NO DATA;



CREATE OR REPLACE VIEW "public"."vw_parlamentar_analitico" AS
 WITH "emendas_agg" AS (
         SELECT "m"."parlamentar_id",
            "count"("e"."id") AS "total_emendas",
            COALESCE("sum"("e"."valor_empenhado"), (0)::numeric) AS "valor_total_emendas",
            COALESCE("sum"("e"."valor_pago"), (0)::numeric) AS "valor_pago_emendas",
                CASE
                    WHEN (COALESCE("sum"("e"."valor_empenhado"), (0)::numeric) > (0)::numeric) THEN "round"(((COALESCE("sum"("e"."valor_pago"), (0)::numeric) / COALESCE("sum"("e"."valor_empenhado"), (1)::numeric)) * (100)::numeric), 1)
                    ELSE (0)::numeric
                END AS "taxa_execucao_emendas",
            "count"(DISTINCT "e"."municipio_nome") FILTER (WHERE ("e"."municipio_nome" IS NOT NULL)) AS "num_municipios",
            "count"(DISTINCT "e"."uf_destino") FILTER (WHERE ("e"."uf_destino" IS NOT NULL)) AS "num_ufs_destino"
           FROM ("public"."mandatos" "m"
             LEFT JOIN "public"."emendas" "e" ON (("e"."mandato_id" = "m"."id")))
          GROUP BY "m"."parlamentar_id"
        ), "base" AS (
         SELECT "p"."id" AS "parlamentar_id",
            "p"."nome",
            "p"."nome_parlamentar",
            "p"."partido",
            "p"."uf",
            "p"."foto_url",
            COALESCE("ea"."total_emendas", (0)::bigint) AS "total_emendas",
            COALESCE("ea"."valor_total_emendas", (0)::numeric) AS "valor_total_emendas",
            COALESCE("ea"."valor_pago_emendas", (0)::numeric) AS "valor_pago_emendas",
            COALESCE("ea"."taxa_execucao_emendas", (0)::numeric) AS "taxa_execucao_emendas",
            (0)::numeric AS "total_despesas_gabinete",
            (0)::numeric AS "total_beneficios",
            0 AS "quantidade_assessores",
            (0)::numeric AS "custo_total_parlamentar",
            0 AS "total_proposicoes",
            0 AS "total_votacoes",
            0 AS "total_presencas",
            (0)::numeric AS "taxa_presenca",
            0 AS "total_transferencias",
            (0)::numeric AS "valor_transferencias",
            COALESCE("ea"."num_municipios", (0)::bigint) AS "num_municipios",
            COALESCE("ea"."num_ufs_destino", (0)::bigint) AS "num_ufs_destino"
           FROM ("public"."parlamentares" "p"
             LEFT JOIN "emendas_agg" "ea" ON (("ea"."parlamentar_id" = "p"."id")))
        ), "ranges" AS (
         SELECT GREATEST("max"("base"."valor_pago_emendas"), (1)::numeric) AS "max_orcamento",
            GREATEST("max"("base"."num_municipios"), (1)::bigint) AS "max_territorial"
           FROM "base"
        )
 SELECT "b"."parlamentar_id",
    "b"."nome",
    "b"."nome_parlamentar",
    "b"."partido",
    "b"."uf",
    "b"."foto_url",
    "b"."total_emendas",
    "b"."valor_total_emendas",
    "b"."valor_pago_emendas",
    "b"."taxa_execucao_emendas",
    "b"."total_despesas_gabinete",
    "b"."total_beneficios",
    "b"."quantidade_assessores",
    "b"."custo_total_parlamentar",
    "b"."total_proposicoes",
    "b"."total_votacoes",
    "b"."total_presencas",
    "b"."taxa_presenca",
    "b"."total_transferencias",
    "b"."valor_transferencias",
    "round"((("b"."valor_pago_emendas" / "r"."max_orcamento") * (100)::numeric), 1) AS "score_orcamento",
    (0)::numeric AS "score_custo",
    (0)::numeric AS "score_produtividade",
    "round"(((("b"."num_municipios")::numeric / ("r"."max_territorial")::numeric) * (100)::numeric), 1) AS "score_influencia",
    "round"((((0.60 * ("b"."valor_pago_emendas" / "r"."max_orcamento")) * (100)::numeric) + ((0.40 * (("b"."num_municipios")::numeric / ("r"."max_territorial")::numeric)) * (100)::numeric)), 1) AS "indice_poder_parlamentar"
   FROM ("base" "b"
     CROSS JOIN "ranges" "r");



CREATE MATERIALIZED VIEW "public"."mv_ranking_parlamentar" AS
 SELECT "parlamentar_id",
    "nome",
    "nome_parlamentar",
    "partido",
    "uf",
    "foto_url",
    "total_emendas",
    "valor_total_emendas",
    "valor_pago_emendas",
    "taxa_execucao_emendas",
    "total_despesas_gabinete",
    "total_beneficios",
    "quantidade_assessores",
    "custo_total_parlamentar",
    "total_proposicoes",
    "total_votacoes",
    "total_presencas",
    "taxa_presenca",
    "total_transferencias",
    "valor_transferencias",
    "score_orcamento",
    "score_custo",
    "score_produtividade",
    "score_influencia",
    "indice_poder_parlamentar",
    "rank"() OVER (ORDER BY "indice_poder_parlamentar" DESC) AS "posicao_nacional",
    "rank"() OVER (PARTITION BY "uf" ORDER BY "indice_poder_parlamentar" DESC) AS "posicao_uf",
    "rank"() OVER (PARTITION BY "partido" ORDER BY "indice_poder_parlamentar" DESC) AS "posicao_partido"
   FROM "public"."vw_parlamentar_analitico"
  ORDER BY "indice_poder_parlamentar" DESC
  WITH NO DATA;



CREATE OR REPLACE VIEW "public"."vw_scorecard_cnpj" AS
 WITH "contratos" AS (
         SELECT "contratos_federais"."fornecedor_cnpj" AS "cnpj",
            "max"("contratos_federais"."fornecedor_nome") AS "nome",
            "count"(*) AS "qtd_contratos",
            "sum"("contratos_federais"."valor_total") AS "valor_contratos",
            "min"("contratos_federais"."data_inicio_vigencia") AS "primeiro_contrato",
            "max"("contratos_federais"."data_inicio_vigencia") AS "ultimo_contrato",
            "count"(DISTINCT "contratos_federais"."orgao_descricao") AS "orgaos_contratos"
           FROM "public"."contratos_federais"
          WHERE ("contratos_federais"."fornecedor_cnpj" IS NOT NULL)
          GROUP BY "contratos_federais"."fornecedor_cnpj"
        ), "convenios" AS (
         SELECT "regexp_replace"("convenios"."convenente_cnpj", '[^0-9]'::"text", ''::"text", 'g'::"text") AS "cnpj",
            "max"("convenios"."convenente_nome") AS "nome",
            "count"(*) AS "qtd_convenios",
            "sum"("convenios"."valor") AS "valor_convenios",
            "sum"("convenios"."valor_liberado") AS "valor_liberado_convenios",
            "min"("convenios"."data_publicacao") AS "primeiro_convenio",
            "max"("convenios"."data_publicacao") AS "ultimo_convenio",
            "count"(DISTINCT "convenios"."orgao_maximo_codigo") AS "orgaos_convenios"
           FROM "public"."convenios"
          WHERE (("convenios"."convenente_cnpj" IS NOT NULL) AND ("length"("regexp_replace"("convenios"."convenente_cnpj", '[^0-9]'::"text", ''::"text", 'g'::"text")) = 14))
          GROUP BY ("regexp_replace"("convenios"."convenente_cnpj", '[^0-9]'::"text", ''::"text", 'g'::"text"))
        ), "pncp" AS (
         SELECT "regexp_replace"("pncp_resultados"."ni_fornecedor", '[^0-9]'::"text", ''::"text", 'g'::"text") AS "cnpj",
            "max"("pncp_resultados"."nome_fornecedor") AS "nome",
            "count"(*) AS "qtd_licitacoes_vencidas",
            "sum"("pncp_resultados"."valor_total_homologado") AS "valor_licitacoes",
            "min"("pncp_resultados"."data_resultado_pncp") AS "primeira_licitacao",
            "max"("pncp_resultados"."data_resultado_pncp") AS "ultima_licitacao",
            "count"(DISTINCT "pncp_resultados"."orgao_cnpj") AS "orgaos_licitacoes"
           FROM "public"."pncp_resultados"
          WHERE (("pncp_resultados"."ni_fornecedor" IS NOT NULL) AND ("length"("regexp_replace"("pncp_resultados"."ni_fornecedor", '[^0-9]'::"text", ''::"text", 'g'::"text")) = 14))
          GROUP BY ("regexp_replace"("pncp_resultados"."ni_fornecedor", '[^0-9]'::"text", ''::"text", 'g'::"text"))
        ), "sancs" AS (
         SELECT "regexp_replace"("portal_sancionados"."cpf_cnpj", '[^0-9]'::"text", ''::"text", 'g'::"text") AS "cnpj",
            "count"(*) AS "qtd_sancoes",
            "sum"(
                CASE
                    WHEN "portal_sancionados"."ativo" THEN 1
                    ELSE 0
                END) AS "sancoes_ativas",
            "min"("portal_sancionados"."data_inicio") AS "primeira_sancao",
            "max"("portal_sancionados"."data_inicio") AS "ultima_sancao",
            "string_agg"(DISTINCT "portal_sancionados"."tipo_sancao", ', '::"text") FILTER (WHERE ("portal_sancionados"."tipo_sancao" IS NOT NULL)) AS "tipos_sancao"
           FROM "public"."portal_sancionados"
          WHERE ("length"("regexp_replace"("portal_sancionados"."cpf_cnpj", '[^0-9]'::"text", ''::"text", 'g'::"text")) = 14)
          GROUP BY ("regexp_replace"("portal_sancionados"."cpf_cnpj", '[^0-9]'::"text", ''::"text", 'g'::"text"))
        ), "tse" AS (
         SELECT "regexp_replace"("tse_receitas_brutas"."nr_cpf_cnpj_doador", '[^0-9]'::"text", ''::"text", 'g'::"text") AS "cnpj",
            "count"(*) AS "qtd_doacoes",
            "sum"("tse_receitas_brutas"."vr_receita") AS "valor_doado",
            "count"(DISTINCT "tse_receitas_brutas"."nr_cpf_candidato") AS "candidatos_distintos",
            "count"(DISTINCT "tse_receitas_brutas"."ano_eleicao") AS "eleicoes_distintas",
            "min"("tse_receitas_brutas"."ano_eleicao") AS "primeira_eleicao_doada",
            "max"("tse_receitas_brutas"."ano_eleicao") AS "ultima_eleicao_doada",
            "string_agg"(DISTINCT "tse_receitas_brutas"."nm_candidato", ' | '::"text" ORDER BY "tse_receitas_brutas"."nm_candidato") FILTER (WHERE ("tse_receitas_brutas"."nm_candidato" IS NOT NULL)) AS "candidatos_sample"
           FROM "public"."tse_receitas_brutas"
          WHERE ("length"("regexp_replace"("tse_receitas_brutas"."nr_cpf_cnpj_doador", '[^0-9]'::"text", ''::"text", 'g'::"text")) = 14)
          GROUP BY ("regexp_replace"("tse_receitas_brutas"."nr_cpf_cnpj_doador", '[^0-9]'::"text", ''::"text", 'g'::"text"))
        ), "todos" AS (
         SELECT "contratos"."cnpj",
            "contratos"."nome"
           FROM "contratos"
        UNION
         SELECT "convenios"."cnpj",
            "convenios"."nome"
           FROM "convenios"
        UNION
         SELECT "pncp"."cnpj",
            "pncp"."nome"
           FROM "pncp"
        ), "nomes" AS (
         SELECT DISTINCT ON ("todos"."cnpj") "todos"."cnpj",
            "todos"."nome"
           FROM "todos"
          WHERE ("todos"."nome" IS NOT NULL)
          ORDER BY "todos"."cnpj", "todos"."nome"
        )
 SELECT "n"."cnpj",
    "n"."nome" AS "nome_fornecedor",
    "c"."qtd_contratos",
    "c"."valor_contratos",
    "c"."primeiro_contrato",
    "c"."ultimo_contrato",
    "c"."orgaos_contratos",
    "v"."qtd_convenios",
    "v"."valor_convenios",
    "v"."valor_liberado_convenios",
    "v"."primeiro_convenio",
    "v"."ultimo_convenio",
    "v"."orgaos_convenios",
    "p"."qtd_licitacoes_vencidas",
    "p"."valor_licitacoes",
    "p"."primeira_licitacao",
    "p"."ultima_licitacao",
    "p"."orgaos_licitacoes",
    ((COALESCE("c"."valor_contratos", (0)::numeric) + COALESCE("v"."valor_liberado_convenios", (0)::numeric)) + COALESCE("p"."valor_licitacoes", (0)::numeric)) AS "valor_total_recebido",
    "s"."qtd_sancoes",
    "s"."sancoes_ativas",
    "s"."primeira_sancao",
    "s"."ultima_sancao",
    "s"."tipos_sancao",
    ("s"."cnpj" IS NOT NULL) AS "is_sancionado",
    ("s"."sancoes_ativas" > 0) AS "is_sancionado_ativo",
    "t"."qtd_doacoes",
    "t"."valor_doado",
    "t"."candidatos_distintos",
    "t"."eleicoes_distintas",
    "t"."primeira_eleicao_doada",
    "t"."ultima_eleicao_doada",
    "t"."candidatos_sample",
    ("t"."cnpj" IS NOT NULL) AS "is_doador_tse",
    ((
        CASE
            WHEN ("t"."cnpj" IS NOT NULL) THEN 1
            ELSE 0
        END +
        CASE
            WHEN ("s"."cnpj" IS NOT NULL) THEN 1
            ELSE 0
        END) +
        CASE
            WHEN ("s"."sancoes_ativas" > 0) THEN 2
            ELSE 0
        END) AS "risk_score"
   FROM ((((("nomes" "n"
     LEFT JOIN "contratos" "c" ON (("c"."cnpj" = "n"."cnpj")))
     LEFT JOIN "convenios" "v" ON (("v"."cnpj" = "n"."cnpj")))
     LEFT JOIN "pncp" "p" ON (("p"."cnpj" = "n"."cnpj")))
     LEFT JOIN "sancs" "s" ON (("s"."cnpj" = "n"."cnpj")))
     LEFT JOIN "tse" "t" ON (("t"."cnpj" = "n"."cnpj")));



CREATE MATERIALIZED VIEW "public"."mv_scorecard_cnpj" AS
 SELECT "cnpj",
    "nome_fornecedor",
    "qtd_contratos",
    "valor_contratos",
    "primeiro_contrato",
    "ultimo_contrato",
    "orgaos_contratos",
    "qtd_convenios",
    "valor_convenios",
    "valor_liberado_convenios",
    "primeiro_convenio",
    "ultimo_convenio",
    "orgaos_convenios",
    "qtd_licitacoes_vencidas",
    "valor_licitacoes",
    "primeira_licitacao",
    "ultima_licitacao",
    "orgaos_licitacoes",
    "valor_total_recebido",
    "qtd_sancoes",
    "sancoes_ativas",
    "primeira_sancao",
    "ultima_sancao",
    "tipos_sancao",
    "is_sancionado",
    "is_sancionado_ativo",
    "qtd_doacoes",
    "valor_doado",
    "candidatos_distintos",
    "eleicoes_distintas",
    "primeira_eleicao_doada",
    "ultima_eleicao_doada",
    "candidatos_sample",
    "is_doador_tse",
    "risk_score"
   FROM "public"."vw_scorecard_cnpj"
  WITH NO DATA;



CREATE OR REPLACE VIEW "public"."vw_scorecard_fornecedor_federal" AS
 WITH "convs" AS (
         SELECT "regexp_replace"("convenios"."convenente_cnpj", '[^0-9]'::"text", ''::"text", 'g'::"text") AS "cnpj",
            "max"("convenios"."convenente_nome") AS "convenente_nome",
            "count"(*) AS "qtd_convenios",
            "sum"("convenios"."valor") AS "valor_total",
            "sum"("convenios"."valor_liberado") AS "valor_liberado",
            "min"("convenios"."data_publicacao") AS "primeiro_convenio",
            "max"("convenios"."data_publicacao") AS "ultimo_convenio",
            "count"(DISTINCT "convenios"."uf") AS "ufs_distintas",
            "count"(DISTINCT "convenios"."orgao_maximo_codigo") AS "orgaos_distintos"
           FROM "public"."convenios"
          WHERE (("convenios"."convenente_cnpj" IS NOT NULL) AND ("length"("regexp_replace"("convenios"."convenente_cnpj", '[^0-9]'::"text", ''::"text", 'g'::"text")) = 14))
          GROUP BY ("regexp_replace"("convenios"."convenente_cnpj", '[^0-9]'::"text", ''::"text", 'g'::"text"))
        ), "sancs" AS (
         SELECT "regexp_replace"("portal_sancionados"."cpf_cnpj", '[^0-9]'::"text", ''::"text", 'g'::"text") AS "cnpj",
            "count"(*) AS "qtd_sancoes",
            "sum"(
                CASE
                    WHEN "portal_sancionados"."ativo" THEN 1
                    ELSE 0
                END) AS "sancoes_ativas",
            "min"("portal_sancionados"."data_inicio") AS "primeira_sancao",
            "max"("portal_sancionados"."data_inicio") AS "ultima_sancao"
           FROM "public"."portal_sancionados"
          WHERE ("length"("regexp_replace"("portal_sancionados"."cpf_cnpj", '[^0-9]'::"text", ''::"text", 'g'::"text")) = 14)
          GROUP BY ("regexp_replace"("portal_sancionados"."cpf_cnpj", '[^0-9]'::"text", ''::"text", 'g'::"text"))
        ), "tse" AS (
         SELECT "regexp_replace"("tse_receitas_brutas"."nr_cpf_cnpj_doador", '[^0-9]'::"text", ''::"text", 'g'::"text") AS "cnpj",
            "count"(*) AS "qtd_doacoes",
            "sum"("tse_receitas_brutas"."vr_receita") AS "valor_doado",
            "count"(DISTINCT "tse_receitas_brutas"."nr_cpf_candidato") AS "candidatos_distintos",
            "count"(DISTINCT "tse_receitas_brutas"."ano_eleicao") AS "eleicoes_distintas",
            "min"("tse_receitas_brutas"."ano_eleicao") AS "primeira_eleicao_doada",
            "max"("tse_receitas_brutas"."ano_eleicao") AS "ultima_eleicao_doada",
            "string_agg"(DISTINCT "tse_receitas_brutas"."nm_candidato", ' | '::"text" ORDER BY "tse_receitas_brutas"."nm_candidato") FILTER (WHERE ("tse_receitas_brutas"."nm_candidato" IS NOT NULL)) AS "candidatos_sample"
           FROM "public"."tse_receitas_brutas"
          WHERE ("length"("regexp_replace"("tse_receitas_brutas"."nr_cpf_cnpj_doador", '[^0-9]'::"text", ''::"text", 'g'::"text")) = 14)
          GROUP BY ("regexp_replace"("tse_receitas_brutas"."nr_cpf_cnpj_doador", '[^0-9]'::"text", ''::"text", 'g'::"text"))
        )
 SELECT "c"."cnpj",
    "c"."convenente_nome",
    "c"."qtd_convenios",
    "c"."valor_total",
    "c"."valor_liberado",
    "c"."primeiro_convenio",
    "c"."ultimo_convenio",
    "c"."ufs_distintas",
    "c"."orgaos_distintos",
    "s"."qtd_sancoes",
    "s"."sancoes_ativas",
    "s"."primeira_sancao",
    "s"."ultima_sancao",
    ("s"."cnpj" IS NOT NULL) AS "is_sancionado",
    ("s"."sancoes_ativas" > 0) AS "is_sancionado_ativo",
    "t"."qtd_doacoes",
    "t"."valor_doado",
    "t"."candidatos_distintos",
    "t"."eleicoes_distintas",
    "t"."primeira_eleicao_doada",
    "t"."ultima_eleicao_doada",
    "t"."candidatos_sample",
    ("t"."cnpj" IS NOT NULL) AS "is_doador_tse"
   FROM (("convs" "c"
     LEFT JOIN "sancs" "s" ON (("s"."cnpj" = "c"."cnpj")))
     LEFT JOIN "tse" "t" ON (("t"."cnpj" = "c"."cnpj")))
  ORDER BY "c"."valor_total" DESC NULLS LAST;



CREATE MATERIALIZED VIEW "public"."mv_scorecard_fornecedor_federal" AS
 SELECT "cnpj",
    "convenente_nome",
    "qtd_convenios",
    "valor_total",
    "valor_liberado",
    "primeiro_convenio",
    "ultimo_convenio",
    "ufs_distintas",
    "orgaos_distintos",
    "qtd_sancoes",
    "sancoes_ativas",
    "primeira_sancao",
    "ultima_sancao",
    "is_sancionado",
    "is_sancionado_ativo",
    "qtd_doacoes",
    "valor_doado",
    "candidatos_distintos",
    "eleicoes_distintas",
    "primeira_eleicao_doada",
    "ultima_eleicao_doada",
    "candidatos_sample",
    "is_doador_tse"
   FROM "public"."vw_scorecard_fornecedor_federal"
  WITH NO DATA;



CREATE MATERIALIZED VIEW "public"."mv_siafi_fornecedores" AS
 SELECT "cnpj_favorecido",
    "nome_favorecido",
    "count"(*) AS "n_pagamentos",
    "sum"("valor_pagamento_brl") AS "valor_total",
    "min"("data_emissao") AS "primeira_aparicao",
    "max"("data_emissao") AS "ultima_aparicao"
   FROM "public"."siafi_pagamento"
  WHERE ("length"("cnpj_favorecido") = 14)
  GROUP BY "cnpj_favorecido", "nome_favorecido"
  ORDER BY ("sum"("valor_pagamento_brl")) DESC
  WITH NO DATA;



CREATE MATERIALIZED VIEW "public"."mv_tse_ads_digitais" AS
 SELECT "cpf_candidato",
    "max"("nome_candidato") AS "nome_candidato",
    "max"("cargo") AS "cargo",
    "max"("sigla_partido") AS "sigla_partido",
    "max"("uf") AS "uf",
    "ano_eleicao",
        CASE
            WHEN ("cpf_cnpj_fornecedor" = '13347016000117'::"text") THEN 'Meta/Facebook'::"text"
            WHEN ("cpf_cnpj_fornecedor" = '06990590000123'::"text") THEN 'Google Ads'::"text"
            ELSE NULL::"text"
        END AS "plataforma",
    "count"(*) AS "n_transacoes",
    "sum"("valor_despesa") AS "total_gasto"
   FROM "public"."tse_despesas"
  WHERE ("cpf_cnpj_fornecedor" = ANY (ARRAY['13347016000117'::"text", '06990590000123'::"text"]))
  GROUP BY "cpf_candidato", "ano_eleicao",
        CASE
            WHEN ("cpf_cnpj_fornecedor" = '13347016000117'::"text") THEN 'Meta/Facebook'::"text"
            WHEN ("cpf_cnpj_fornecedor" = '06990590000123'::"text") THEN 'Google Ads'::"text"
            ELSE NULL::"text"
        END
  WITH NO DATA;



CREATE MATERIALIZED VIEW "public"."parlamentar_dossier_live" AS
 SELECT "p"."parlamentar_uid",
    "p"."nome_parlamentar",
    "i"."ipi_score",
    "v"."velocidade_media",
    "count"("f"."id") AS "sinais_recentes"
   FROM ((("public"."parlamentares" "p"
     LEFT JOIN "public"."institutional_power_index" "i" USING ("parlamentar_uid"))
     LEFT JOIN "public"."ipi_velocity" "v" USING ("parlamentar_uid"))
     LEFT JOIN "public"."political_intelligence_feed" "f" USING ("parlamentar_uid"))
  GROUP BY "p"."parlamentar_uid", "p"."nome_parlamentar", "i"."ipi_score", "v"."velocidade_media"
  WITH NO DATA;



CREATE OR REPLACE VIEW "public"."pgfn_divida_federacoes_resumo" AS
 SELECT "cnpj",
    "nome",
    "uf",
    "trimestre",
    "sum"("total_divida") AS "divida_total",
    "sum"("total_inscricoes") AS "inscricoes",
    "sum"("total_ajuizadas") AS "ajuizadas",
    "max"("atualizado_em") AS "atualizado_em"
   FROM "public"."pgfn_divida_federacoes"
  GROUP BY "cnpj", "nome", "uf", "trimestre"
  ORDER BY ("sum"("total_divida")) DESC;



CREATE OR REPLACE VIEW "public"."pif_live_feed" AS
 SELECT "f"."id",
    "f"."parlamentar_uid",
    "f"."event_id",
    "f"."event_type",
    "f"."signal_type",
    "f"."signal_strength",
    "f"."headline",
    "f"."summary",
    "f"."created_at",
    "p"."nome_parlamentar"
   FROM ("public"."political_intelligence_feed" "f"
     JOIN "public"."parlamentares" "p" USING ("parlamentar_uid"))
  ORDER BY "f"."created_at" DESC;



CREATE OR REPLACE VIEW "public"."pr_ex_presidentes_custo_anual" AS
 SELECT "ex_presidente_slug",
    "centro_custo_nome" AS "ex_presidente",
    "ano_emissao" AS "ano",
    "sum"("custo_valor") AS "custo_total",
    "sum"(
        CASE
            WHEN ("grupo_despesa_nome" ~~* '%PESSOAL%'::"text") THEN "custo_valor"
            ELSE (0)::numeric
        END) AS "custo_pessoal",
    "sum"(
        CASE
            WHEN ("grupo_despesa_nome" ~~* '%OUTRAS%'::"text") THEN "custo_valor"
            ELSE (0)::numeric
        END) AS "custo_outras_despesas",
    "count"(*) AS "n_transacoes"
   FROM "public"."pr_ex_presidentes_custos"
  GROUP BY "ex_presidente_slug", "centro_custo_nome", "ano_emissao"
  ORDER BY "ano_emissao", ("sum"("custo_valor")) DESC;



CREATE OR REPLACE VIEW "public"."pr_ex_presidentes_por_natureza" AS
 SELECT "ex_presidente_slug",
    "centro_custo_nome" AS "ex_presidente",
    "ano_emissao" AS "ano",
    "natureza_despesa_nome",
    "sum"("custo_valor") AS "custo_total",
    "count"(*) AS "n_transacoes"
   FROM "public"."pr_ex_presidentes_custos"
  WHERE ("natureza_despesa_nome" IS NOT NULL)
  GROUP BY "ex_presidente_slug", "centro_custo_nome", "ano_emissao", "natureza_despesa_nome"
  ORDER BY "ano_emissao", "ex_presidente_slug", ("sum"("custo_valor")) DESC;



CREATE OR REPLACE VIEW "public"."processos" AS
 SELECT "p"."id",
    "t"."sigla" AS "tribunal",
    "p"."classe",
    "p"."numero_processo",
    "p"."relator",
    "p"."orgao_julgador",
    "p"."tipo_decisao",
    "p"."data_decisao",
    "p"."tema",
    "p"."ementa",
    "p"."link_oficial",
    "p"."fonte",
    "p"."identificador_externo",
    "p"."metadata",
    "p"."data_coleta",
    ("p"."metadata" ->> 'classe_codigo'::"text") AS "classe_processual"
   FROM ("public"."judiciario_processos" "p"
     JOIN "public"."tribunais" "t" ON (("t"."id" = "p"."tribunal_id")));



CREATE OR REPLACE VIEW "public"."processos_publico" AS
 SELECT "id",
    "tribunal",
    "classe",
    "numero_processo",
    "relator",
    "orgao_julgador",
    "tipo_decisao",
    "data_decisao",
    "tema",
    "ementa",
    "link_oficial",
    "fonte",
    "identificador_externo",
    "metadata",
    "data_coleta",
    "classe_processual"
   FROM "public"."processos";



CREATE OR REPLACE VIEW "public"."ranking_federal" AS
 SELECT "orgao",
    "count"(*) AS "operacoes",
    "sum"("valor") AS "valor_total",
    "rank"() OVER (ORDER BY ("sum"("valor")) DESC) AS "posicao"
   FROM "public"."execucao_financeira_transferencias"
  GROUP BY "orgao";



CREATE OR REPLACE VIEW "public"."ranking_nacional" AS
 SELECT "mr"."mandato_id",
    "mr"."nome",
    "mr"."partido",
    "mr"."uf",
    "count"("e"."codigo_emenda") AS "total_emendas",
    COALESCE("sum"("e"."valor_empenhado"), (0)::numeric) AS "total_empenhado",
    COALESCE("sum"("e"."valor_pago"), (0)::numeric) AS "total_pago",
    "round"(((COALESCE("sum"("e"."valor_pago"), (0)::numeric) / NULLIF("sum"("e"."valor_empenhado"), (0)::numeric)) * (100)::numeric), 2) AS "taxa_execucao"
   FROM ("public"."mandato_raiox" "mr"
     LEFT JOIN "public"."emendas" "e" ON (("e"."mandato_id" = "mr"."mandato_id")))
  GROUP BY "mr"."mandato_id", "mr"."nome", "mr"."partido", "mr"."uf";



CREATE OR REPLACE VIEW "public"."ranking_parlamentares" AS
 SELECT "m"."mandato_id",
    "m"."nome",
    "count"("e"."codigo_emenda") AS "total_emendas",
    "sum"("e"."valor_pago") AS "total_pago",
    "sum"("e"."valor_empenhado") AS "total_empenhado",
    "round"((("sum"("e"."valor_pago") / NULLIF("sum"("e"."valor_empenhado"), (0)::numeric)) * (100)::numeric), 2) AS "taxa_execucao"
   FROM ("public"."mandato_raiox" "m"
     LEFT JOIN "public"."emendas" "e" ON (("e"."mandato_id" = "m"."mandato_id")))
  GROUP BY "m"."mandato_id", "m"."nome";



CREATE OR REPLACE VIEW "public"."ranking_score" AS
 SELECT "mandato_id",
    "nome",
    "partido",
    "uf",
    "total_emendas",
    "total_empenhado",
    "total_pago",
    "taxa_execucao",
    ((("total_pago" / (1000000)::numeric) + ("taxa_execucao" * (10)::numeric)) + (("total_emendas" * 2))::numeric) AS "score_sistema"
   FROM "public"."ranking_nacional";



CREATE OR REPLACE VIEW "public"."saf_ecossistema_cvm" AS
 SELECT "s"."clube",
    "s"."serie",
    "s"."investidor",
    "o"."cnpj_emissor",
    "o"."nome_emissor",
    "o"."tipo_ativo",
    "o"."valor",
    "o"."data_oferta",
    "o"."situacao",
    "o"."rito",
    "o"."id_oferta",
    'direta'::"text" AS "relacao",
    NULL::"text" AS "papel_entidade"
   FROM ("public"."cvm_saf" "s"
     JOIN "public"."cvm_oferta" "o" ON (("o"."cnpj_emissor" = "s"."cnpj_norm")))
UNION ALL
 SELECT "e"."clube",
    COALESCE("s"."serie", '?'::"text") AS "serie",
    COALESCE("s"."investidor", "e"."descricao") AS "investidor",
    "o"."cnpj_emissor",
    "o"."nome_emissor",
    "o"."tipo_ativo",
    "o"."valor",
    "o"."data_oferta",
    "o"."situacao",
    "o"."rito",
    "o"."id_oferta",
    'ecossistema'::"text" AS "relacao",
    "e"."descricao" AS "papel_entidade"
   FROM (("public"."cvm_saf_entidade_relacionada" "e"
     JOIN "public"."cvm_oferta" "o" ON (("o"."cnpj_emissor" = "e"."cnpj_norm")))
     LEFT JOIN "public"."cvm_saf" "s" ON (("s"."clube" = "e"."clube")));



CREATE OR REPLACE VIEW "public"."saf_oferta" AS
 SELECT "s"."clube",
    "s"."serie",
    "s"."investidor",
    "o"."cnpj_emissor",
    "o"."nome_emissor",
    "o"."tipo_ativo",
    "o"."valor",
    "o"."data_oferta",
    "o"."situacao",
    "o"."rito",
    "o"."id_oferta",
    'direta'::"text" AS "relacao"
   FROM ("public"."cvm_saf" "s"
     JOIN "public"."cvm_oferta" "o" ON (("o"."cnpj_emissor" = "s"."cnpj_norm")));



CREATE OR REPLACE VIEW "public"."saf_quadro_societario" AS
 SELECT "s"."clube",
    "s"."serie",
    "s"."status",
    "s"."investidor",
    "s"."cnpj_norm" AS "cnpj_saf",
    "left"("s"."cnpj_norm", 8) AS "cnpj_basico",
    "so"."nome_socio",
    "so"."identificador",
    "so"."cpf_cnpj_socio",
    "so"."qualificacao",
    "so"."data_entrada",
    "so"."faixa_etaria",
    "emp"."razao_social" AS "razao_social_socio",
    "emp"."capital_social" AS "capital_social_socio",
    "emp"."porte" AS "porte_socio",
    "saf_emp"."razao_social" AS "razao_social_saf",
    "saf_emp"."capital_social" AS "capital_social_saf",
    "saf_emp"."natureza_juridica"
   FROM ((("public"."cvm_saf" "s"
     LEFT JOIN "public"."cnpj_socios" "so" ON (("so"."cnpj_basico" = "left"("s"."cnpj_norm", 8))))
     LEFT JOIN "public"."cnpj_empresa" "saf_emp" ON (("saf_emp"."cnpj_basico" = "left"("s"."cnpj_norm", 8))))
     LEFT JOIN "public"."cnpj_empresa" "emp" ON ((("emp"."cnpj_basico" = "left"("regexp_replace"(COALESCE("so"."cpf_cnpj_socio", ''::"text"), '\D'::"text", ''::"text", 'g'::"text"), 8)) AND ("so"."identificador" = '1'::"text"))));



CREATE OR REPLACE VIEW "public"."senado_ceaps_emenda_cruzamento" AS
 SELECT "c"."cpf_cnpj" AS "cnpj",
    "c"."nome_fornecedor" AS "nome_na_ceaps",
    "count"(DISTINCT "c"."cod_senador") AS "senadores_ceaps",
    "sum"("c"."valor_reembolsado") AS "total_ceaps_brl",
    "e"."favorecido" AS "nome_na_emenda",
    "e"."valor_total" AS "total_emenda_brl",
    "e"."n_autores" AS "autores_emenda"
   FROM ("public"."senado_ceaps_despesa" "c"
     JOIN ( SELECT "emendas_favorecidos"."codigo_favorecido",
            "max"("emendas_favorecidos"."favorecido") AS "favorecido",
            "sum"("emendas_favorecidos"."valor_recebido") AS "valor_total",
            "count"(DISTINCT "emendas_favorecidos"."codigo_autor") AS "n_autores"
           FROM "public"."emendas_favorecidos"
          WHERE (("emendas_favorecidos"."codigo_favorecido" IS NOT NULL) AND ("emendas_favorecidos"."codigo_favorecido" <> ''::"text"))
          GROUP BY "emendas_favorecidos"."codigo_favorecido") "e" ON (("e"."codigo_favorecido" = "c"."cpf_cnpj")))
  WHERE (("c"."cpf_cnpj" IS NOT NULL) AND ("c"."cpf_cnpj" <> ''::"text"))
  GROUP BY "c"."cpf_cnpj", "c"."nome_fornecedor", "e"."favorecido", "e"."valor_total", "e"."n_autores"
  ORDER BY ("sum"("c"."valor_reembolsado") + "e"."valor_total") DESC NULLS LAST;



CREATE OR REPLACE VIEW "public"."senado_dissidencia" AS
 SELECT "v"."id_sve",
    "v"."cod_parlamentar",
    "v"."nome_parlamentar",
    "v"."sigla_partido",
    "v"."sigla_uf",
    "v"."voto" AS "voto_real",
    "o"."orientacao" AS "orientacao_partido",
    "vot"."data_sessao",
    "vot"."descricao",
    "vot"."sigla_materia",
    "vot"."numero_materia",
    "vot"."ano_materia"
   FROM (("public"."senado_voto" "v"
     JOIN "public"."senado_orientacao" "o" ON ((("o"."id_sve" = "v"."id_sve") AND ("o"."sigla_partido" = "v"."sigla_partido"))))
     JOIN "public"."senado_votacao" "vot" ON (("vot"."id_sve" = "v"."id_sve")))
  WHERE (("o"."orientacao" <> ALL (ARRAY['Liberado'::"text", 'Abstenção'::"text"])) AND ("v"."voto" <> ALL (ARRAY['Abstenção'::"text", 'P-OD'::"text", 'NCom'::"text"])) AND ("v"."voto" <> "o"."orientacao"));



CREATE OR REPLACE VIEW "public"."sp_despesas_por_credor" AS
 SELECT "cnpj_credor",
    "nome_credor",
    "ano",
    "count"(*) AS "total_empenhos",
    "sum"("valor_empenhado") AS "total_empenhado",
    "sum"("valor_liquidado") AS "total_liquidado",
    "sum"("valor_pago") AS "total_pago",
    "array_agg"(DISTINCT "nome_orgao" ORDER BY "nome_orgao") FILTER (WHERE ("nome_orgao" IS NOT NULL)) AS "orgaos"
   FROM "public"."sp_despesas"
  WHERE ("cnpj_credor" IS NOT NULL)
  GROUP BY "cnpj_credor", "nome_credor", "ano";



CREATE OR REPLACE VIEW "public"."stats_por_ano_tribunal" AS
 SELECT "tribunal",
    "ano",
    "total"
   FROM "public"."judiciario_stats_por_ano_tribunal";



CREATE OR REPLACE VIEW "public"."stats_por_classe_tribunal" AS
 SELECT "tribunal",
    "classe",
    "total"
   FROM "public"."judiciario_stats_por_classe_tribunal";



CREATE OR REPLACE VIEW "public"."stats_por_relator" AS
 SELECT "tribunal",
    "relator",
    "processos",
    "com_decisao",
    "ultima_decisao",
    "classe_principal"
   FROM "public"."judiciario_stats_por_relator";



CREATE OR REPLACE VIEW "public"."stats_por_tribunal" AS
 SELECT "tribunal",
    "total",
    "com_decisao",
    "qtd_relatores",
    "qtd_classes",
    "ultima_decisao",
    "ultima_coleta"
   FROM "public"."judiciario_stats_por_tribunal";



CREATE OR REPLACE VIEW "public"."stf_v_ministros_scores" AS
SELECT
    NULL::"uuid" AS "id",
    NULL::"text" AS "nome",
    NULL::"text" AS "iniciais",
    NULL::"date" AS "data_posse",
    NULL::"text" AS "indicado_por",
    NULL::"text" AS "partido_indicante",
    NULL::boolean AS "ativo",
    NULL::numeric AS "score_geral",
    NULL::numeric AS "score_direitos_civis",
    NULL::numeric AS "score_lib_imprensa",
    NULL::numeric AS "score_seg_publica",
    NULL::numeric AS "score_economico",
    NULL::numeric AS "score_democracia",
    NULL::bigint AS "total_votos",
    NULL::bigint AS "votos_favor",
    NULL::bigint AS "votos_contra";



CREATE OR REPLACE VIEW "public"."sub_v_criticos_mes" WITH ("security_invoker"='true') AS
 SELECT "a"."cnpj",
    "d"."razao_social",
    "c"."nome" AS "cliente",
    "c"."email" AS "email_cliente",
    "a"."fonte",
    "a"."titulo",
    "a"."descricao",
    "a"."valor_brl",
    "a"."data_evento",
    "a"."url_fonte",
    "d"."ciclo"
   FROM (("public"."sub_alertas" "a"
     JOIN "public"."sub_dossies" "d" ON (("d"."id" = "a"."dossie_id")))
     JOIN "public"."sub_clientes" "c" ON (("c"."id" = "d"."cliente_id")))
  WHERE (("a"."severidade" = 'critico'::"text") AND ("d"."ciclo" = "to_char"("now"(), 'YYYY-MM'::"text")))
  ORDER BY "a"."valor_brl" DESC NULLS LAST;



CREATE OR REPLACE VIEW "public"."sub_v_resumo_clientes" WITH ("security_invoker"='true') AS
 SELECT "c"."id",
    "c"."nome",
    "c"."empresa",
    "c"."plano",
    "c"."status",
    "count"(DISTINCT "m"."cnpj") AS "cnpjs_ativos",
    "c"."max_cnpjs",
    "count"(DISTINCT "d"."id") AS "total_dossies",
    "max"("d"."generated_at") AS "ultimo_dossie",
    "sum"(
        CASE
            WHEN ("a"."severidade" = 'critico'::"text") THEN 1
            ELSE 0
        END) AS "alertas_criticos"
   FROM ((("public"."sub_clientes" "c"
     LEFT JOIN "public"."sub_cnpjs_monitorados" "m" ON ((("m"."cliente_id" = "c"."id") AND "m"."ativo")))
     LEFT JOIN "public"."sub_dossies" "d" ON (("d"."cliente_id" = "c"."id")))
     LEFT JOIN "public"."sub_alertas" "a" ON (("a"."dossie_id" = "d"."id")))
  GROUP BY "c"."id", "c"."nome", "c"."empresa", "c"."plano", "c"."status", "c"."max_cnpjs";



CREATE OR REPLACE VIEW "public"."top_100_congresso" AS
 SELECT "mandato_id",
    "nome",
    "partido",
    "uf",
    "total_emendas",
    "total_empenhado",
    "total_pago",
    "taxa_execucao",
    "score_sistema"
   FROM "public"."ranking_score"
  ORDER BY "score_sistema" DESC
 LIMIT 100;



CREATE OR REPLACE VIEW "public"."transferencias_federais" AS
 SELECT "id",
    "ano",
    "mes",
    "orgao",
    "favorecido",
    "municipio",
    "uf",
    "valor",
    "tipo_transferencia",
    "fonte_dado",
    "created_at",
    "updated_at"
   FROM "public"."execucao_financeira_transferencias";



CREATE OR REPLACE VIEW "public"."tse_v_doador_emenda" AS
 WITH "doador_agg" AS (
         SELECT "tse_receitas"."cpf_cnpj_doador" AS "cnpj",
            "count"(*) AS "qtd_doacoes",
            "sum"("tse_receitas"."valor") AS "valor_total_doado",
            "count"(DISTINCT "tse_receitas"."cpf_candidato") AS "candidatos_distintos",
            "string_agg"(DISTINCT ("tse_receitas"."ano_eleicao")::"text", ','::"text" ORDER BY ("tse_receitas"."ano_eleicao")::"text") AS "eleicoes_doadas",
            "string_agg"(DISTINCT "tse_receitas"."nome_doador", ' | '::"text") AS "nome_doador_sample",
            "string_agg"(DISTINCT "tse_receitas"."setor_economico_doador", ' | '::"text") FILTER (WHERE ("tse_receitas"."setor_economico_doador" IS NOT NULL)) AS "setor_doador_sample"
           FROM "public"."tse_receitas"
          WHERE ("length"("tse_receitas"."cpf_cnpj_doador") = 14)
          GROUP BY "tse_receitas"."cpf_cnpj_doador"
        )
 SELECT "ef"."codigo_autor" AS "autor_codigo",
    "ef"."nome_autor" AS "autor_nome",
    "ef"."ano_emenda",
    "ef"."tipo_emenda",
    "ef"."subtipo",
    "ef"."codigo_favorecido" AS "cnpj_favorecido",
    "ef"."favorecido" AS "nome_favorecido",
    "ef"."natureza_juridica" AS "natureza_juridica_favorecido",
    "ef"."municipio_favorecido",
    "ef"."uf_favorecido",
    "ef"."valor_recebido" AS "valor_emenda",
    "d"."qtd_doacoes",
    "d"."valor_total_doado",
    "d"."candidatos_distintos",
    "d"."eleicoes_doadas",
    "d"."nome_doador_sample",
    "d"."setor_doador_sample"
   FROM ("public"."emendas_favorecidos" "ef"
     JOIN "doador_agg" "d" ON (("d"."cnpj" = "ef"."codigo_favorecido")))
  WHERE ("length"("ef"."codigo_favorecido") = 14);



CREATE OR REPLACE VIEW "public"."tse_v_dossie_doador" AS
 SELECT "r"."ano_eleicao",
    "r"."cpf_cnpj_doador",
    "r"."nome_doador",
    "r"."tipo_doador",
    "r"."setor_economico_doador",
    "r"."nome_candidato",
    "r"."cargo",
    "r"."sigla_partido",
    "r"."uf",
    "r"."cpf_cnpj_doador_originario",
    "r"."nome_doador_originario",
    "r"."valor",
    "r"."data_receita",
    "r"."natureza_receita",
    "r"."origem_receita",
    "c"."id" AS "tse_candidato_id",
    "c"."situacao_turno" AS "resultado_eleicao",
    "p"."id" AS "parlamentar_id",
    "p"."id_camara",
    "p"."partido_atual"
   FROM (("public"."tse_receitas" "r"
     LEFT JOIN "public"."tse_candidatos" "c" ON ((("c"."cpf" = "r"."cpf_candidato") AND ("c"."ano_eleicao" = "r"."ano_eleicao") AND ("length"("r"."cpf_candidato") >= 11))))
     LEFT JOIN "public"."parlamentares" "p" ON ((("p"."cpf" = "r"."cpf_candidato") AND ("length"("r"."cpf_candidato") >= 11))));



CREATE OR REPLACE VIEW "public"."tse_v_financiadores_parlamentar" AS
 SELECT "cpf_candidato",
    "nome_candidato",
    "sigla_partido",
    "uf",
    "ano_eleicao",
    "cpf_cnpj_doador",
    "nome_doador",
    "tipo_doador",
    "setor_economico_doador",
    "sum"("valor") AS "total_recebido",
    "count"(*) AS "n_transacoes",
    "min"("data_receita") AS "primeira_doacao",
    "max"("data_receita") AS "ultima_doacao"
   FROM "public"."tse_receitas" "r"
  WHERE ("cpf_candidato" IS NOT NULL)
  GROUP BY "cpf_candidato", "nome_candidato", "sigla_partido", "uf", "ano_eleicao", "cpf_cnpj_doador", "nome_doador", "tipo_doador", "setor_economico_doador"
  ORDER BY ("sum"("valor")) DESC;



CREATE OR REPLACE VIEW "public"."tse_v_receptor_top" AS
 SELECT "r"."cpf_cnpj_doador",
    "r"."nome_doador",
    "r"."nome_candidato",
    "r"."cargo",
    "r"."sigla_partido",
    "r"."uf",
    "count"(*) AS "n_transacoes",
    "sum"("r"."valor") AS "total_doado",
    "min"("r"."ano_eleicao") AS "primeiro_ano",
    "max"("r"."ano_eleicao") AS "ultimo_ano",
    "string_agg"(DISTINCT ("r"."ano_eleicao")::"text", ', '::"text" ORDER BY ("r"."ano_eleicao")::"text") AS "anos",
    "p"."id_camara",
    "p"."ativo" AS "parlamentar_ativo"
   FROM ("public"."tse_receitas" "r"
     LEFT JOIN "public"."parlamentares" "p" ON ((("p"."cpf" = "r"."cpf_candidato") AND ("length"("r"."cpf_candidato") >= 11))))
  GROUP BY "r"."cpf_cnpj_doador", "r"."nome_doador", "r"."nome_candidato", "r"."cargo", "r"."sigla_partido", "r"."uf", "p"."id_camara", "p"."ativo";



CREATE OR REPLACE VIEW "public"."tse_v_rede_financiamento" AS
 WITH "doadores_parlamentar" AS (
         SELECT DISTINCT "r"."cpf_candidato",
            "r"."cpf_cnpj_doador",
            "r"."nome_doador"
           FROM "public"."tse_receitas" "r"
          WHERE ("r"."cpf_cnpj_doador" IS NOT NULL)
        )
 SELECT "dp"."cpf_candidato" AS "cpf_parlamentar_alvo",
    "dp"."cpf_cnpj_doador",
    "dp"."nome_doador",
    "r2"."cpf_candidato" AS "cpf_outro_parlamentar",
    "r2"."nome_candidato" AS "nome_outro_parlamentar",
    "r2"."sigla_partido" AS "partido_outro",
    "r2"."uf" AS "uf_outro",
    "r2"."ano_eleicao",
    "r2"."valor"
   FROM ("doadores_parlamentar" "dp"
     JOIN "public"."tse_receitas" "r2" ON ((("r2"."cpf_cnpj_doador" = "dp"."cpf_cnpj_doador") AND ("r2"."cpf_candidato" <> "dp"."cpf_candidato"))))
  ORDER BY "dp"."cpf_candidato", "r2"."valor" DESC;



CREATE OR REPLACE VIEW "public"."usa_v_metricas_transparencia" AS
 SELECT "tipo",
    "count"(*) AS "total_contratos",
    "round"("avg"("valor_obrigado_usd"), 2) AS "valor_medio_usd",
    "sum"("valor_obrigado_usd") AS "valor_total_usd",
    "avg"(("data_fim" - "data_inicio")) AS "duracao_media_dias",
    "avg"((("ingested_at")::"date" - "data_assinatura")) AS "lag_publicacao_dias_aprox",
    "min"("data_inicio") AS "periodo_inicio",
    "max"("data_fim") AS "periodo_fim"
   FROM "public"."usa_contratos"
  WHERE ("data_assinatura" IS NOT NULL)
  GROUP BY "tipo"
  ORDER BY ("sum"("valor_obrigado_usd")) DESC NULLS LAST;



CREATE OR REPLACE VIEW "public"."usa_v_top_beneficiarios" AS
 SELECT "beneficiario_nome",
    "beneficiario_uei",
    "count"(*) AS "total_contratos",
    "sum"("valor_obrigado_usd") AS "valor_total_usd",
    "array_agg"(DISTINCT "tipo") AS "tipos",
    "array_agg"(DISTINCT "agencia_nome" ORDER BY "agencia_nome") AS "agencias"
   FROM "public"."usa_contratos"
  WHERE ("beneficiario_nome" IS NOT NULL)
  GROUP BY "beneficiario_nome", "beneficiario_uei"
  ORDER BY ("sum"("valor_obrigado_usd")) DESC NULLS LAST
 LIMIT 1000;



CREATE OR REPLACE VIEW "public"."v_bets_doadores_campanha" AS
 SELECT "b"."cnpj",
    "b"."nome" AS "operadora",
    "b"."marcas",
    "r"."ano_eleicao",
    "r"."cpf_candidato",
    "r"."nome_candidato",
    "r"."cargo",
    "r"."sigla_partido",
    "r"."uf",
    "sum"("r"."valor") AS "total_doado",
    "count"(*) AS "num_doacoes"
   FROM ("public"."bets_licenciadas" "b"
     JOIN "public"."tse_receitas" "r" ON (("r"."cpf_cnpj_doador" = ("b"."cnpj")::"text")))
  GROUP BY "b"."cnpj", "b"."nome", "b"."marcas", "r"."ano_eleicao", "r"."cpf_candidato", "r"."nome_candidato", "r"."cargo", "r"."sigla_partido", "r"."uf"
  ORDER BY ("sum"("r"."valor")) DESC;



CREATE OR REPLACE VIEW "public"."v_bets_favorecidas_emendas" AS
 SELECT "b"."cnpj",
    "b"."nome" AS "operadora",
    "b"."marcas",
    "f"."nome_autor" AS "parlamentar",
    "f"."codigo_autor",
    "sum"("f"."valor_recebido") AS "total_emendas",
    "count"(*) AS "num_transferencias"
   FROM ("public"."bets_licenciadas" "b"
     JOIN "public"."emendas_favorecidos" "f" ON (("f"."codigo_favorecido" = ("b"."cnpj")::"text")))
  GROUP BY "b"."cnpj", "b"."nome", "b"."marcas", "f"."nome_autor", "f"."codigo_autor"
  ORDER BY ("sum"("f"."valor_recebido")) DESC;



CREATE OR REPLACE VIEW "public"."v_bets_circuito_completo" AS
 SELECT "d"."cnpj",
    "d"."operadora",
    "d"."marcas",
    "d"."nome_candidato" AS "candidato_financiado",
    "d"."cargo",
    "d"."sigla_partido",
    "d"."uf",
    "d"."ano_eleicao",
    "d"."total_doado",
    "e"."total_emendas",
    "e"."num_transferencias" AS "num_emendas_recebidas"
   FROM (("public"."v_bets_doadores_campanha" "d"
     JOIN "public"."parlamentares" "p" ON (("p"."cpf" = "d"."cpf_candidato")))
     JOIN "public"."v_bets_favorecidas_emendas" "e" ON ((("e"."cnpj" = "d"."cnpj") AND ("e"."codigo_autor" = ("p"."id_camara")::"text"))))
  ORDER BY ("d"."total_doado" + COALESCE("e"."total_emendas", (0)::numeric)) DESC;



CREATE OR REPLACE VIEW "public"."v_bets_socios_peps" AS
 SELECT "b"."cnpj" AS "bet_cnpj",
    "b"."nome" AS "bet_nome",
    "b"."marcas",
    "s"."nome_socio",
    "s"."qualificacao",
    "p"."nome" AS "pep_nome",
    "p"."descricao_funcao" AS "pep_cargo",
    "p"."orgao_nome",
    "p"."cpf"
   FROM (("public"."bets_licenciadas" "b"
     JOIN "public"."cnpj_socios" "s" ON (("left"(("b"."cnpj")::"text", 8) = "s"."cnpj_basico")))
     JOIN "public"."peps" "p" ON (("p"."nome" ~~* "s"."nome_norm")));



CREATE OR REPLACE VIEW "public"."v_bets_socios_tse" AS
 SELECT "b"."cnpj" AS "bet_cnpj",
    "b"."nome" AS "bet_nome",
    "b"."marcas",
    "s"."nome_socio",
    "s"."qualificacao",
    "s"."faixa_etaria",
    "r"."ano_eleicao",
    "r"."nome_candidato",
    "r"."cargo",
    "r"."sigla_partido",
    "r"."uf",
    "sum"("r"."valor") AS "total_doado",
    "count"(*) AS "num_doacoes"
   FROM (("public"."bets_licenciadas" "b"
     JOIN "public"."cnpj_socios" "s" ON (("left"(("b"."cnpj")::"text", 8) = "s"."cnpj_basico")))
     JOIN "public"."tse_receitas" "r" ON (("r"."nome_doador" ~~* "s"."nome_norm")))
  GROUP BY "b"."cnpj", "b"."nome", "b"."marcas", "s"."nome_socio", "s"."qualificacao", "s"."faixa_etaria", "r"."ano_eleicao", "r"."nome_candidato", "r"."cargo", "r"."sigla_partido", "r"."uf"
  ORDER BY ("sum"("r"."valor")) DESC;



CREATE OR REPLACE VIEW "public"."v_emenda_autor_favorecido" AS
 SELECT "ea"."codigo",
    "ea"."ano",
    "ea"."tipo",
    "ea"."autor_nome",
    "ea"."autor_partido",
    "ea"."autor_uf",
    "ea"."funcao_descricao",
    "ea"."subfuncao_descricao",
    "ea"."localidade_descricao",
    "ea"."valor_empenhado",
    "ef"."codigo_favorecido",
    "ef"."favorecido",
    "ef"."valor_recebido",
    "ef"."uf_favorecido",
    "ef"."municipio_favorecido"
   FROM ("public"."emendas_api" "ea"
     JOIN "public"."emendas_favorecidos" "ef" ON (("ea"."codigo" = "ef"."codigo_emenda")));



CREATE OR REPLACE VIEW "public"."v_empresa_emenda_contrato" AS
 WITH "agg_contratos" AS (
         SELECT "contratos_federais"."fornecedor_cnpj",
            "max"("contratos_federais"."fornecedor_razao_social") AS "razao_social",
            "count"(*) AS "total_contratos",
            "sum"("contratos_federais"."valor_total") AS "valor_total_contratos"
           FROM "public"."contratos_federais"
          GROUP BY "contratos_federais"."fornecedor_cnpj"
        ), "agg_emendas" AS (
         SELECT "emendas_favorecidos"."codigo_favorecido",
            "count"(DISTINCT "emendas_favorecidos"."codigo_emenda") AS "total_emendas",
            "sum"("emendas_favorecidos"."valor_recebido") AS "valor_total_emendas"
           FROM "public"."emendas_favorecidos"
          GROUP BY "emendas_favorecidos"."codigo_favorecido"
        )
 SELECT "c"."fornecedor_cnpj" AS "cnpj",
    "c"."razao_social",
    "c"."total_contratos",
    "c"."valor_total_contratos",
    COALESCE("e"."total_emendas", (0)::bigint) AS "total_emendas",
    COALESCE("e"."valor_total_emendas", (0)::numeric) AS "valor_total_emendas"
   FROM ("agg_contratos" "c"
     LEFT JOIN "agg_emendas" "e" ON (("c"."fornecedor_cnpj" = "e"."codigo_favorecido")));



CREATE OR REPLACE VIEW "public"."v_indicadores_atuais" AS
 SELECT DISTINCT ON ("nome") "nome",
    "valor",
    "capturado_em"
   FROM "public"."indicadores_macroeconomicos"
  ORDER BY "nome", "capturado_em" DESC;



CREATE OR REPLACE VIEW "public"."v_midia_doadora_emenda" AS
 SELECT "r"."cpf_cnpj_doador" AS "cnpj",
    "r"."nome_doador" AS "nome_empresa",
    "r"."setor_economico_doador" AS "setor_tse",
    "sum"("r"."valor") AS "total_doado_campanha_brl",
    "count"(DISTINCT "r"."nome_candidato") AS "n_candidatos_beneficiados",
    "count"(DISTINCT "r"."ano_eleicao") AS "n_eleicoes",
    "sum"("ef"."valor_recebido") AS "total_emendas_recebidas_brl",
    "count"(DISTINCT "ef"."numero_emenda") AS "n_emendas_recebidas",
    ("array_agg"(DISTINCT "ef"."numero_emenda" ORDER BY "ef"."numero_emenda"))[1:10] AS "emendas_amostra"
   FROM ("public"."tse_receitas" "r"
     JOIN "public"."emendas_favorecidos" "ef" ON (("ef"."codigo_favorecido" = "r"."cpf_cnpj_doador")))
  WHERE (("r"."tipo_doador" = 'PJ'::"text") AND (("r"."setor_economico_doador" ~~* '%comunicação%'::"text") OR ("r"."setor_economico_doador" ~~* '%comunicacao%'::"text") OR ("r"."setor_economico_doador" ~~* '%publicidade%'::"text") OR ("r"."setor_economico_doador" ~~* '%radiodifusão%'::"text") OR ("r"."setor_economico_doador" ~~* '%radiodifusao%'::"text") OR ("r"."setor_economico_doador" ~~* '%televisão%'::"text") OR ("r"."setor_economico_doador" ~~* '%televisao%'::"text") OR ("r"."setor_economico_doador" ~~* '%rádio%'::"text") OR ("r"."setor_economico_doador" ~~* '%radio%'::"text") OR ("r"."setor_economico_doador" ~~* '%mídia%'::"text") OR ("r"."setor_economico_doador" ~~* '%midia%'::"text")))
  GROUP BY "r"."cpf_cnpj_doador", "r"."nome_doador", "r"."setor_economico_doador"
  ORDER BY ("sum"("r"."valor")) DESC NULLS LAST;



CREATE OR REPLACE VIEW "public"."v_parlamentar_socio_emenda" AS
 SELECT "p"."nome" AS "parlamentar",
    "p"."partido",
    "p"."uf",
    "cs"."cnpj_basico",
    "ce"."razao_social",
    "ce"."porte_empresa",
    "cs"."qualificacao",
    "cs"."data_entrada",
    "sum"("ef"."valor_recebido") AS "total_emendas",
    "count"(DISTINCT "ef"."codigo_emenda") AS "qtd_emendas",
    "max"("ef"."ano_emenda") AS "ultimo_ano"
   FROM ((("public"."cnpj_socios" "cs"
     LEFT JOIN "public"."cnpj_empresas" "ce" ON ((("ce"."cnpj_basico")::"text" = "cs"."cnpj_basico")))
     JOIN "public"."parlamentares" "p" ON (("p"."cpf" = "cs"."cpf_cnpj_socio")))
     JOIN "public"."emendas_favorecidos" "ef" ON (("substring"("ef"."codigo_favorecido", 1, 8) = "cs"."cnpj_basico")))
  WHERE ("length"("cs"."cpf_cnpj_socio") = 11)
  GROUP BY "p"."nome", "p"."partido", "p"."uf", "cs"."cnpj_basico", "ce"."razao_social", "ce"."porte_empresa", "cs"."qualificacao", "cs"."data_entrada"
  ORDER BY ("sum"("ef"."valor_recebido")) DESC NULLS LAST;



CREATE OR REPLACE VIEW "public"."v_pncp_pub_por_fornecedor" AS
 SELECT "cnpj_fornecedor",
    "nome_fornecedor",
    "count"(*) AS "n_contratos",
    "count"(DISTINCT "ano_contrato") AS "n_anos",
    "count"(DISTINCT "cnpj_orgao") AS "n_orgaos_clientes",
    "sum"("valor_global") AS "total_brl",
    "max"("valor_global") AS "maior_contrato_brl",
    "min"("data_assinatura") AS "primeiro_contrato",
    "max"("data_assinatura") AS "ultimo_contrato",
    ("array_agg"(DISTINCT "nome_orgao" ORDER BY "nome_orgao"))[1:10] AS "orgaos_clientes_amostra"
   FROM "public"."pncp_publicidade"
  WHERE (("cnpj_fornecedor" IS NOT NULL) AND ("cnpj_fornecedor" <> ''::"text"))
  GROUP BY "cnpj_fornecedor", "nome_fornecedor"
  ORDER BY ("sum"("valor_global")) DESC NULLS LAST;



CREATE OR REPLACE VIEW "public"."v_pncp_pub_por_orgao" AS
 SELECT "ano_contrato",
    "cnpj_orgao",
    "nome_orgao",
    "uf_orgao",
    "count"(*) AS "n_contratos",
    "sum"("valor_global") AS "total_brl",
    "avg"("valor_global") AS "media_contrato_brl",
    "max"("valor_global") AS "maior_contrato_brl",
    "count"(DISTINCT "cnpj_fornecedor") AS "n_fornecedores_distintos",
    "array_agg"(DISTINCT "nome_fornecedor" ORDER BY "nome_fornecedor") FILTER (WHERE ("nome_fornecedor" IS NOT NULL)) AS "fornecedores"
   FROM "public"."pncp_publicidade"
  GROUP BY "ano_contrato", "cnpj_orgao", "nome_orgao", "uf_orgao"
  ORDER BY ("sum"("valor_global")) DESC NULLS LAST;



CREATE OR REPLACE VIEW "public"."v_sancao_doacao" AS
 SELECT "s"."cadastro",
    "s"."cpf_cnpj",
    "s"."nome" AS "nome_sancionado",
    "s"."tipo_sancao",
    "s"."data_inicio" AS "sancao_inicio",
    "r"."nome_candidato" AS "candidato",
    "r"."sigla_partido",
    "r"."uf",
    "r"."cargo",
    "r"."ano_eleicao",
    "r"."valor" AS "valor_doacao",
    "r"."origem_receita"
   FROM ("public"."sancoes" "s"
     JOIN "public"."tse_receitas" "r" ON (("r"."cpf_cnpj_doador" = "s"."cpf_cnpj")))
  WHERE ("length"("s"."cpf_cnpj") = 14)
  ORDER BY "r"."valor" DESC NULLS LAST;



CREATE OR REPLACE VIEW "public"."v_sancao_emenda" AS
 SELECT "s"."cadastro",
    "s"."cpf_cnpj",
    "s"."nome" AS "nome_sancionado",
    "s"."tipo_sancao",
    "s"."data_inicio" AS "sancao_inicio",
    "s"."data_fim" AS "sancao_fim",
    "s"."orgao_nome" AS "orgao_sancionador",
    "s"."orgao_uf",
    "ef"."valor_recebido" AS "valor_emenda",
    "ef"."ano_emenda",
    "ef"."nome_autor" AS "parlamentar",
    "ef"."municipio_favorecido",
    "ef"."uf_favorecido",
    "ef"."tipo_emenda",
    "ef"."subtipo"
   FROM ("public"."sancoes" "s"
     JOIN "public"."emendas_favorecidos" "ef" ON (("ef"."codigo_favorecido" = "s"."cpf_cnpj")))
  WHERE ("length"("s"."cpf_cnpj") = 14)
  ORDER BY "ef"."valor_recebido" DESC NULLS LAST;



CREATE OR REPLACE VIEW "public"."vw_autor_publico" WITH ("security_invoker"='true') AS
 WITH "autor_emendas" AS (
         SELECT "a_1"."id" AS "autor_id",
            "count"("e"."id") AS "total_emendas",
            COALESCE("sum"("e"."valor_empenhado"), (0)::numeric) AS "valor_empenhado",
            COALESCE("sum"("e"."valor_liquidado"), (0)::numeric) AS "valor_liquidado",
            COALESCE("sum"("e"."valor_pago"), (0)::numeric) AS "valor_pago",
            "count"(DISTINCT "e"."municipio_nome") FILTER (WHERE ("e"."municipio_nome" IS NOT NULL)) AS "num_municipios",
            "count"(DISTINCT "e"."uf_destino") FILTER (WHERE ("e"."uf_destino" IS NOT NULL)) AS "num_ufs_destino",
            "count"(DISTINCT "e"."ano") FILTER (WHERE ("e"."ano" IS NOT NULL)) AS "anos_ativos"
           FROM (("public"."autores_orcamentarios" "a_1"
             LEFT JOIN "public"."mandatos" "m_1" ON (("m_1"."autor_orcamentario_id" = "a_1"."id")))
             LEFT JOIN "public"."emendas" "e" ON (("e"."mandato_id" = "m_1"."id")))
          GROUP BY "a_1"."id"
        ), "score_raw" AS (
         SELECT "ae"."autor_id",
            "ae"."total_emendas",
            "ae"."valor_empenhado",
            "ae"."valor_liquidado",
            "ae"."valor_pago",
            "ae"."num_municipios",
            "ae"."num_ufs_destino",
            "ae"."anos_ativos",
                CASE
                    WHEN ("ae"."valor_empenhado" > (0)::numeric) THEN LEAST(("ae"."valor_pago" / "ae"."valor_empenhado"), (1)::numeric)
                    ELSE (0)::numeric
                END AS "taxa_execucao",
            ((((LEAST((("ae"."total_emendas")::numeric / (NULLIF(( SELECT "max"("autor_emendas"."total_emendas") AS "max"
                   FROM "autor_emendas"), 0))::numeric), (1)::numeric) * (35)::numeric) +
                CASE
                    WHEN ("ae"."valor_empenhado" > (0)::numeric) THEN (LEAST(("ae"."valor_pago" / "ae"."valor_empenhado"), (1)::numeric) * (25)::numeric)
                    ELSE (0)::numeric
                END) + (LEAST((("ae"."num_municipios")::numeric / (NULLIF(( SELECT "max"("autor_emendas"."num_municipios") AS "max"
                   FROM "autor_emendas"), 0))::numeric), (1)::numeric) * (20)::numeric)) + (LEAST((("ae"."anos_ativos")::numeric / (NULLIF(( SELECT "max"("autor_emendas"."anos_ativos") AS "max"
                   FROM "autor_emendas"), 0))::numeric), (1)::numeric) * (20)::numeric)) AS "raw_score"
           FROM "autor_emendas" "ae"
        ), "score_norm" AS (
         SELECT "s"."autor_id",
            "s"."total_emendas",
            "s"."valor_empenhado",
            "s"."valor_liquidado",
            "s"."valor_pago",
            "s"."num_municipios",
            "s"."num_ufs_destino",
            "s"."anos_ativos",
            "s"."taxa_execucao",
            "s"."raw_score",
                CASE
                    WHEN (( SELECT "max"("score_raw"."raw_score") AS "max"
                       FROM "score_raw") > (0)::numeric) THEN "round"((("s"."raw_score" / ( SELECT "max"("score_raw"."raw_score") AS "max"
                       FROM "score_raw")) * (100)::numeric), 1)
                    ELSE (0)::numeric
                END AS "score_influencia"
           FROM "score_raw" "s"
        )
 SELECT "a"."id" AS "autor_id",
    "a"."nome_oficial" AS "nome",
    "a"."tipo_autor",
    "p"."partido",
    "p"."uf",
    "p"."foto_url",
    "m"."legislatura",
    "a"."ativo",
    COALESCE("sn"."total_emendas", (0)::bigint) AS "total_emendas",
    COALESCE("sn"."valor_empenhado", (0)::numeric) AS "valor_empenhado",
    COALESCE("sn"."valor_liquidado", (0)::numeric) AS "valor_liquidado",
    COALESCE("sn"."valor_pago", (0)::numeric) AS "valor_pago",
    COALESCE("sn"."num_municipios", (0)::bigint) AS "num_municipios",
    COALESCE("sn"."num_ufs_destino", (0)::bigint) AS "num_ufs_destino",
    COALESCE("sn"."anos_ativos", (0)::bigint) AS "anos_ativos",
    "round"((COALESCE("sn"."taxa_execucao", (0)::numeric) * (100)::numeric), 1) AS "taxa_execucao",
    COALESCE("sn"."score_influencia", (0)::numeric) AS "score_influencia",
    "rank"() OVER (ORDER BY COALESCE("sn"."valor_pago", (0)::numeric) DESC) AS "ranking_execucao",
    "rank"() OVER (ORDER BY COALESCE("sn"."score_influencia", (0)::numeric) DESC) AS "ranking_influencia"
   FROM ((("public"."autores_orcamentarios" "a"
     LEFT JOIN "public"."parlamentares" "p" ON (("a"."parlamentar_id" = "p"."id")))
     LEFT JOIN "public"."mandatos" "m" ON (("m"."autor_orcamentario_id" = "a"."id")))
     LEFT JOIN "score_norm" "sn" ON (("sn"."autor_id" = "a"."id")));



CREATE OR REPLACE VIEW "public"."vw_ciclo_analitico" AS
 SELECT ("count"(*))::integer AS "ciclo_analitico",
    ("max"("finished_at"))::"text" AS "ultimo_ciclo"
   FROM "public"."cron_execution_log"
  WHERE ("status" = 'success'::"text");



CREATE OR REPLACE VIEW "public"."vw_data_completeness" AS
 SELECT "job_name",
    "count"(*) AS "total_runs",
    "count"(*) FILTER (WHERE ("status" = 'success'::"text")) AS "successful_runs",
    "count"(*) FILTER (WHERE ("status" <> 'success'::"text")) AS "failed_runs",
    "round"("avg"(COALESCE("records_processed", 0)), 0) AS "avg_completeness",
    COALESCE("sum"("records_processed"), (0)::bigint) AS "total_rows_imported",
    0 AS "total_validation_errors",
    "max"("started_at") AS "last_run",
    "round"("avg"(COALESCE("duration_ms", 0)), 0) AS "avg_duration_ms"
   FROM "public"."cron_execution_log"
  GROUP BY "job_name";



CREATE OR REPLACE VIEW "public"."vw_emendas_companhias_abertas" AS
 SELECT "ef"."codigo_favorecido",
    "ef"."favorecido",
    "ef"."uf_favorecido",
    "ef"."municipio_favorecido",
    "count"(*) AS "num_transacoes",
    "sum"("ef"."valor_recebido") AS "total_recebido",
    "b3"."nome_empresa",
    "b3"."ticker",
    "b3"."segmento",
    "b3"."mercado",
    "b3"."data_listagem"
   FROM ("public"."emendas_favorecidos" "ef"
     JOIN "public"."b3_empresas_listadas" "b3" ON (("ef"."codigo_favorecido" = "b3"."cnpj")))
  WHERE (("b3"."cnpj" IS NOT NULL) AND ("ef"."codigo_favorecido" IS NOT NULL))
  GROUP BY "ef"."codigo_favorecido", "ef"."favorecido", "ef"."uf_favorecido", "ef"."municipio_favorecido", "b3"."nome_empresa", "b3"."ticker", "b3"."segmento", "b3"."mercado", "b3"."data_listagem"
  ORDER BY ("sum"("ef"."valor_recebido")) DESC;



CREATE OR REPLACE VIEW "public"."vw_narrativas_publicas" AS
 SELECT "created_at",
    "tipo_evento",
    "parlamentar",
    "narrativa",
    "impacto_publico"
   FROM "public"."narrative_events"
  ORDER BY "created_at" DESC;



CREATE OR REPLACE VIEW "public"."vw_observatorio_status" AS
 SELECT "max"("finished_at") AS "ultimo_refresh",
    (EXTRACT(epoch FROM ("now"() - "max"("finished_at"))) / (3600)::numeric) AS "horas_desde_atualizacao",
        CASE
            WHEN ("max"("finished_at") > ("now"() - '24:00:00'::interval)) THEN 'operacional'::"text"
            ELSE 'desatualizado'::"text"
        END AS "status_operacional",
        CASE
            WHEN ("max"("finished_at") > ("now"() - '24:00:00'::interval)) THEN 'ok'::"text"
            ELSE 'atenção'::"text"
        END AS "classificacao",
    ("count"(*))::integer AS "total_execucoes",
    ("count"(*) FILTER (WHERE ("status" = 'success'::"text")))::integer AS "execucoes_sucesso",
    ("count"(*) FILTER (WHERE ("status" <> 'success'::"text")))::integer AS "execucoes_erro",
    ( SELECT "cron_execution_log_1"."job_name"
           FROM "public"."cron_execution_log" "cron_execution_log_1"
          ORDER BY "cron_execution_log_1"."finished_at" DESC
         LIMIT 1) AS "ultima_fonte",
    ( SELECT "cron_execution_log_1"."duration_ms"
           FROM "public"."cron_execution_log" "cron_execution_log_1"
          ORDER BY "cron_execution_log_1"."finished_at" DESC
         LIMIT 1) AS "ultimo_duration_ms"
   FROM "public"."cron_execution_log";



CREATE OR REPLACE VIEW "public"."vw_relatorio_nacional" AS
 SELECT "now"() AS "atualizado_em",
    ( SELECT "count"(*) AS "count"
           FROM "public"."parlamentares") AS "parlamentares_indexados",
    ( SELECT "count"(*) AS "count"
           FROM "public"."emendas") AS "total_emendas",
    ( SELECT COALESCE("sum"("emendas"."valor_pago"), (0)::numeric) AS "coalesce"
           FROM "public"."emendas") AS "volume_pago_total",
    ( SELECT "count"(*) AS "count"
           FROM "public"."narrative_events"
          WHERE ("narrative_events"."created_at" > ("now"() - '24:00:00'::interval))) AS "eventos_ultimas_24h";



CREATE OR REPLACE VIEW "public"."vw_rp9_favorecidos_sancionados" AS
 SELECT "r"."nome_apoiador",
    "r"."cargo_apoiador",
    "r"."ano_emenda",
    "r"."numero_emenda",
    "r"."cnpj_favorecido",
    "r"."nome_favorecido",
    "r"."orgao_uge_nome",
    "r"."ne_atual",
    "s"."tipo_registro",
    "s"."tipo_sancao",
    "s"."data_inicio",
    "s"."data_fim",
    "s"."orgao_nome" AS "orgao_sancionador"
   FROM ("public"."emendas_rp9_apoiamento" "r"
     JOIN "public"."portal_sancionados" "s" ON (("regexp_replace"("s"."cpf_cnpj", '\D'::"text", ''::"text", 'g'::"text") = "r"."cnpj_favorecido")))
  WHERE (("r"."cnpj_favorecido" IS NOT NULL) AND ("length"("r"."cnpj_favorecido") = 14));



CREATE OR REPLACE VIEW "public"."vw_rp9_ranking_sancionados" AS
 SELECT "nome_apoiador",
    "cargo_apoiador",
    "count"(DISTINCT "cnpj_favorecido") AS "favorecidos_sancionados",
    "count"(*) AS "vinculos_sancionados"
   FROM "public"."vw_rp9_favorecidos_sancionados"
  GROUP BY "nome_apoiador", "cargo_apoiador"
  ORDER BY ("count"(DISTINCT "cnpj_favorecido")) DESC;



CREATE OR REPLACE VIEW "public"."vw_sebrae_cnpj_emendas" AS
 SELECT "cnpj_cpf",
    "razao_social",
    "uf",
    "count"(*) AS "qtd_contratos",
    "sum"(("replace"("replace"("valor_contrato", '.'::"text", ''::"text"), ','::"text", '.'::"text"))::numeric) AS "valor_total_contratos"
   FROM "public"."sebrae_contratos" "sc"
  WHERE (("cnpj_cpf" IS NOT NULL) AND ("cnpj_cpf" <> '-'::"text"))
  GROUP BY "cnpj_cpf", "razao_social", "uf";



CREATE OR REPLACE VIEW "public"."vw_senac_cnpj_emendas" AS
 SELECT "cnpj_cpf",
    "favorecido",
    "regional",
    "count"(*) AS "qtd_contratos",
    "sum"("valor_total") AS "valor_total_contratos",
    "sum"("valor_pago") AS "valor_total_pago"
   FROM "public"."senac_contratos"
  WHERE (("cnpj_cpf" IS NOT NULL) AND ("cnpj_cpf" <> ALL (ARRAY[''::"text", '-'::"text"])))
  GROUP BY "cnpj_cpf", "favorecido", "regional";



CREATE OR REPLACE VIEW "public"."vw_senar_cnpj_emendas" AS
 SELECT COALESCE("c"."cnpj", "t"."cnpj") AS "cnpj",
    COALESCE("c"."nome_contratada", "t"."nome_beneficiario") AS "nome",
    "count"(DISTINCT "c"."id") AS "qtd_contratos",
    "count"(DISTINCT "t"."id") AS "qtd_transferencias",
    "sum"(("replace"("replace"("c"."valor_contrato", '.'::"text", ''::"text"), ','::"text", '.'::"text"))::numeric) AS "valor_total_contratos",
    "sum"(("replace"("replace"("t"."valor_transferido", '.'::"text", ''::"text"), ','::"text", '.'::"text"))::numeric) AS "valor_total_transferencias"
   FROM ("public"."senar_contratos" "c"
     FULL JOIN "public"."senar_transferencias" "t" ON (("c"."cnpj" = "t"."cnpj")))
  WHERE ((COALESCE("c"."cnpj", "t"."cnpj") IS NOT NULL) AND (COALESCE("c"."cnpj", "t"."cnpj") <> ALL (ARRAY[''::"text", '-'::"text"])))
  GROUP BY COALESCE("c"."cnpj", "t"."cnpj"), COALESCE("c"."nome_contratada", "t"."nome_beneficiario");



CREATE OR REPLACE VIEW "public"."vw_sesc_cnpj_emendas" AS
 SELECT "cnpj_cpf",
    "favorecido",
    "portal",
    "count"(*) AS "qtd_contratos",
    "sum"(("replace"("replace"("valor_contrato", '.'::"text", ''::"text"), ','::"text", '.'::"text"))::numeric) AS "valor_total_contratos"
   FROM "public"."sesc_contratos"
  WHERE (("cnpj_cpf" IS NOT NULL) AND ("cnpj_cpf" <> ALL (ARRAY[''::"text", '-'::"text"])))
  GROUP BY "cnpj_cpf", "favorecido", "portal";



CREATE OR REPLACE VIEW "public"."vw_sisi_cnpj_emendas" AS
 SELECT "cpf_cnpj",
    "nome_razao_social",
    "entidade",
    "departamento",
    "count"(*) AS "qtd_contratos",
    "sum"(("replace"("replace"("valor_contrato", '.'::"text", ''::"text"), ','::"text", '.'::"text"))::numeric) AS "valor_total_contratos"
   FROM "public"."sisi_contratos"
  WHERE (("cpf_cnpj" IS NOT NULL) AND ("cpf_cnpj" <> ALL (ARRAY[''::"text", '-'::"text"])))
  GROUP BY "cpf_cnpj", "nome_razao_social", "entidade", "departamento";



CREATE OR REPLACE VIEW "public"."vw_transferencias_por_uf" AS
 SELECT "uf",
    "count"(*) AS "total_transferencias",
    "sum"("valor") AS "valor_total",
    "avg"("valor") AS "valor_medio"
   FROM "public"."execucao_financeira_transferencias"
  GROUP BY "uf"
  ORDER BY ("sum"("valor")) DESC;



CREATE OR REPLACE VIEW "public_api"."vw_public_ingestion_status" AS
 SELECT "pipeline_name",
    "started_at",
    "finished_at",
    "status",
    "source",
    "records_processed",
    "records_inserted",
    "records_updated",
    "error_message"
   FROM "public"."ingestion_runs"
  ORDER BY "started_at" DESC;



CREATE OR REPLACE VIEW "public_api"."vw_public_obs_cobertura_emendas" AS
 SELECT ( SELECT "count"(*) AS "count"
           FROM "analytics"."vw_mandato_referencia") AS "parlamentares_dimensao",
    ( SELECT "count"(*) AS "count"
           FROM "analytics"."vw_fato_execucao_emendas") AS "parlamentares_com_execucao",
    ( SELECT "count"(*) AS "count"
           FROM "analytics"."vw_obs_parlamentares_sem_execucao") AS "parlamentares_sem_execucao",
    ( SELECT "sum"("vw_fato_execucao_emendas"."valor_pago_emendas") AS "sum"
           FROM "analytics"."vw_fato_execucao_emendas") AS "total_pago_parlamentar";



CREATE OR REPLACE VIEW "public_api"."vw_public_parlamentares_min" AS
 SELECT DISTINCT "parlamentar_uid"
   FROM "public"."mandatos" "m"
  WHERE ("parlamentar_uid" IS NOT NULL);



CREATE OR REPLACE VIEW "public_api"."vw_public_ranking_new" AS
 WITH "ranked" AS (
         SELECT "s"."parlamentar_id",
            "s"."total_emendas",
            "s"."valor_total_emendas",
            "s"."valor_pago_emendas",
            "rank"() OVER (ORDER BY "s"."valor_pago_emendas" DESC NULLS LAST) AS "posicao_nacional"
           FROM "analytics"."vw_public_ranking_source_compat" "s"
        )
 SELECT "r"."parlamentar_id",
    COALESCE("p"."nome", 'PARLAMENTAR NÃO RESOLVIDO'::"text") AS "nome",
    "p"."nome_parlamentar",
    COALESCE("p"."partido_atual", "p"."partido") AS "partido",
    "p"."uf",
    "p"."foto_url",
    "r"."posicao_nacional",
    "r"."total_emendas",
    "r"."valor_total_emendas",
    "r"."valor_pago_emendas"
   FROM ("ranked" "r"
     LEFT JOIN "public"."parlamentares" "p" ON (("p"."parlamentar_uid" = "r"."parlamentar_id")));



CREATE OR REPLACE VIEW "public_api"."vw_public_top_parlamentares" AS
 SELECT "parlamentar_uid" AS "parlamentar_id",
    "valor_pago_emendas",
    "rank"() OVER (ORDER BY "valor_pago_emendas" DESC) AS "posicao_nacional"
   FROM "analytics"."mv_execucao_emendas_parlamentares_v2"
  ORDER BY ("rank"() OVER (ORDER BY "valor_pago_emendas" DESC))
 LIMIT 50;



CREATE OR REPLACE VIEW "public"."stf_v_ministros_scores" AS
 SELECT "m"."id",
    "m"."nome",
    "m"."iniciais",
    "m"."data_posse",
    "m"."indicado_por",
    "m"."partido_indicante",
    "m"."ativo",
    COALESCE("m"."score_geral", 5.0) AS "score_geral",
    COALESCE("m"."score_direitos_civis", 5.0) AS "score_direitos_civis",
    COALESCE("m"."score_lib_imprensa", 5.0) AS "score_lib_imprensa",
    COALESCE("m"."score_seg_publica", 5.0) AS "score_seg_publica",
    COALESCE("m"."score_economico", 5.0) AS "score_economico",
    COALESCE("m"."score_democracia", 5.0) AS "score_democracia",
    "count"("v"."id") AS "total_votos",
    "count"("v"."id") FILTER (WHERE ("v"."voto" = 'favor'::"text")) AS "votos_favor",
    "count"("v"."id") FILTER (WHERE ("v"."voto" = 'contra'::"text")) AS "votos_contra"
   FROM ("public"."stf_ministros" "m"
     LEFT JOIN "public"."stf_votacoes" "v" ON (("v"."ministro_id" = "m"."id")))
  GROUP BY "m"."id";



-- bloco 10_indexes — gerado por split_baseline.py (ordem interna = ordem do dump)
CREATE INDEX "idx_mv_exec_emendas_rank" ON "analytics"."mv_execucao_emendas_parlamentares_v2" USING "btree" ("valor_pago_emendas" DESC);

CREATE INDEX "idx_mv_exec_emendas_v2_uid" ON "analytics"."mv_execucao_emendas_parlamentares" USING "btree" ("parlamentar_uid");

CREATE INDEX "idx_mv_exec_emendas_v2_valor_desc" ON "analytics"."mv_execucao_emendas_parlamentares" USING "btree" ("valor_pago_emendas" DESC);

CREATE INDEX "idx_ifbal_ano_mes" ON "bcb"."if_balanco" USING "btree" ("ano_mes");

CREATE INDEX "idx_ifbal_inst" ON "bcb"."if_balanco" USING "btree" ("cod_inst");

CREATE INDEX "idx_ifbal_relat" ON "bcb"."if_balanco" USING "btree" ("nome_relatorio");

CREATE INDEX "idx_ifcad_cnpj" ON "bcb"."if_cadastro" USING "btree" ("cnpj_lider");

CREATE INDEX "idx_ifcad_segmento" ON "bcb"."if_cadastro" USING "btree" ("segmento");

CREATE INDEX "idx_scr_cliente" ON "bcb"."scr_operacoes" USING "btree" ("cliente");

CREATE INDEX "idx_scr_data_base" ON "bcb"."scr_operacoes" USING "btree" ("data_base");

CREATE INDEX "idx_scr_modalidade" ON "bcb"."scr_operacoes" USING "btree" ("modalidade");

CREATE INDEX "idx_scr_segmento" ON "bcb"."scr_operacoes" USING "btree" ("segmento");

CREATE INDEX "idx_scr_uf" ON "bcb"."scr_operacoes" USING "btree" ("uf");

CREATE INDEX "idx_sicor_ano_mes" ON "bcb"."sicor_credito_rural" USING "btree" ("ano_emissao", "mes_emissao");

CREATE INDEX "idx_sicor_cnpj_if" ON "bcb"."sicor_credito_rural" USING "btree" ("cnpj_if");

CREATE INDEX "idx_sicor_finalidade" ON "bcb"."sicor_credito_rural" USING "btree" ("finalidade");

CREATE INDEX "idx_sicor_municipio" ON "bcb"."sicor_credito_rural" USING "btree" ("cd_municipio_ibge");

CREATE INDEX "idx_sicor_uf" ON "bcb"."sicor_credito_rural" USING "btree" ("uf");

CREATE INDEX "idx_cases_user_id" ON "cidadania_ai"."cases" USING "btree" ("user_id");

CREATE INDEX "idx_docs_case_id" ON "cidadania_ai"."generated_docs" USING "btree" ("case_id");

CREATE INDEX "idx_library_docs_collection" ON "cidadania_ai"."library_docs" USING "btree" ("collection");

CREATE INDEX "idx_library_docs_embedding" ON "cidadania_ai"."library_docs" USING "ivfflat" ("embedding" "public"."vector_cosine_ops") WITH ("lists"='100');

CREATE INDEX "idx_messages_case_id" ON "cidadania_ai"."messages" USING "btree" ("case_id");

CREATE INDEX "idx_desastres_ano" ON "homabrasil"."desastres_historico" USING "btree" ("ano");

CREATE INDEX "idx_desastres_municipio" ON "homabrasil"."desastres_historico" USING "btree" ("municipio_id");

CREATE INDEX "idx_desastres_tipo" ON "homabrasil"."desastres_historico" USING "btree" ("tipo_desastre");

CREATE INDEX "idx_homa_score_score" ON "homabrasil"."homa_score" USING "btree" ("homa_score" DESC);

CREATE INDEX "idx_homa_score_tier" ON "homabrasil"."homa_score" USING "btree" ("tier");

CREATE INDEX "idx_municipios_nome" ON "homabrasil"."municipios" USING "btree" ("nome");

CREATE INDEX "idx_municipios_uf" ON "homabrasil"."municipios" USING "btree" ("uf");

CREATE INDEX "idx_cartoes_estabelecimento" ON "portal_transparencia"."cartoes_pagamento" USING "btree" ("cnpj_estabelecimento", "data_transacao" DESC);

CREATE INDEX "idx_cartoes_orgao_data" ON "portal_transparencia"."cartoes_pagamento" USING "btree" ("codigo_orgao", "data_transacao" DESC);

CREATE INDEX "idx_cartoes_portador" ON "portal_transparencia"."cartoes_pagamento" USING "btree" ("cpf_portador_mascarado", "data_transacao" DESC);

CREATE INDEX "idx_favorecidos_razao_trgm" ON "portal_transparencia"."favorecidos" USING "gin" ("razao_social" "public"."gin_trgm_ops");

CREATE INDEX "idx_favorecidos_uf_mun" ON "portal_transparencia"."favorecidos" USING "btree" ("uf", "municipio_ibge");

CREATE INDEX "idx_ingest_runs_base_comp" ON "portal_transparencia"."ingest_runs" USING "btree" ("base", "competencia" DESC);

CREATE INDEX "idx_nf_data" ON "portal_transparencia"."notas_fiscais" USING "btree" ("data_emissao" DESC);

CREATE INDEX "idx_nf_destinatario_data" ON "portal_transparencia"."notas_fiscais" USING "btree" ("cnpj_destinatario", "data_emissao" DESC);

CREATE INDEX "idx_nf_emitente_data" ON "portal_transparencia"."notas_fiscais" USING "btree" ("cnpj_emitente", "data_emissao" DESC);

CREATE INDEX "idx_nf_itens_descricao_trgm" ON "portal_transparencia"."notas_fiscais_itens" USING "gin" ("descricao" "public"."gin_trgm_ops");

CREATE INDEX "idx_sancoes_cnpj_cpf" ON "portal_transparencia"."sancoes" USING "btree" ("cnpj_cpf_sancionado");

CREATE INDEX "idx_sancoes_data_inicio" ON "portal_transparencia"."sancoes" USING "btree" ("data_inicio_sancao" DESC);

CREATE INDEX "idx_sancoes_vigencia" ON "portal_transparencia"."sancoes" USING "btree" ("cnpj_cpf_sancionado", "data_inicio_sancao", "data_final_sancao");

CREATE INDEX "agenda_cam_data_idx" ON "public"."agenda_camara_eventos" USING "btree" ("data_inicio_date");

CREATE INDEX "agenda_cam_orgaos_idx" ON "public"."agenda_camara_eventos" USING "gin" ("orgaos_siglas");

CREATE INDEX "agenda_cam_sit_idx" ON "public"."agenda_camara_eventos" USING "btree" ("situacao");

CREATE INDEX "agenda_cam_tipo_idx" ON "public"."agenda_camara_eventos" USING "btree" ("tipo_evento");

CREATE INDEX "agenda_sen_com_data_idx" ON "public"."agenda_senado_comissoes" USING "btree" ("data_inicio_date");

CREATE INDEX "agenda_sen_com_sig_idx" ON "public"."agenda_senado_comissoes" USING "btree" ("comissao_sigla");

CREATE INDEX "agenda_sen_com_sit_idx" ON "public"."agenda_senado_comissoes" USING "btree" ("situacao");

CREATE INDEX "agenda_sen_plen_data_idx" ON "public"."agenda_senado_plenario" USING "btree" ("data_sessao");

CREATE INDEX "agenda_sen_plen_sit_idx" ON "public"."agenda_senado_plenario" USING "btree" ("situacao");

CREATE INDEX "agenda_sen_plen_tipo_idx" ON "public"."agenda_senado_plenario" USING "btree" ("tipo_sessao");

CREATE INDEX "agex_apo_idx" ON "public"."agenda_executivo_compromissos" USING "btree" ("apo_id");

CREATE INDEX "agex_data_idx" ON "public"."agenda_executivo_compromissos" USING "btree" ("data_inicio");

CREATE INDEX "agex_orgao_idx" ON "public"."agenda_executivo_compromissos" USING "btree" ("orgao_sigla");

CREATE INDEX "agex_priv_idx" ON "public"."agenda_executivo_compromissos" USING "btree" ("tem_participantes_privados") WHERE ("tem_participantes_privados" = true);

CREATE INDEX "agex_tipo_idx" ON "public"."agenda_executivo_compromissos" USING "btree" ("tipo_compromisso");

CREATE UNIQUE INDEX "almg_fornecedores_intersetados_cnpj_idx" ON "public"."almg_fornecedores_intersetados" USING "btree" ("cnpj");

CREATE INDEX "almg_fornecedores_intersetados_n_casas_idx" ON "public"."almg_fornecedores_intersetados" USING "btree" ("n_casas" DESC);

CREATE INDEX "almg_fornecedores_intersetados_total_idx" ON "public"."almg_fornecedores_intersetados" USING "btree" ("total_geral" DESC);

CREATE INDEX "cbf_socios_cnpj" ON "public"."cbf_socios_federacoes" USING "btree" ("cnpj_federacao");

CREATE INDEX "cbf_socios_cpf" ON "public"."cbf_socios_federacoes" USING "btree" ("cpf_socio");

CREATE INDEX "cbf_vinc_cnpj" ON "public"."cbf_cnpjs_vinculados" USING "btree" ("cnpj_basico");

CREATE INDEX "cbf_vinc_cpf" ON "public"."cbf_cnpjs_vinculados" USING "btree" ("cpf_socio");

CREATE INDEX "cbf_vinc_emenda" ON "public"."cbf_cnpjs_vinculados" USING "btree" ("tem_emenda");

CREATE INDEX "cnes_cnpj" ON "public"."cnes_estabelecimentos" USING "btree" ("numero_cnpj") WHERE ("numero_cnpj" IS NOT NULL);

CREATE INDEX "cnes_emendas_cnpj_hub" ON "public"."cnes_emendas_por_cnpj" USING "btree" ("total_autores", "total_unidades_cnes");

CREATE INDEX "cnes_emendas_cnpj_valor" ON "public"."cnes_emendas_por_cnpj" USING "btree" ("total_recebido" DESC);

CREATE INDEX "cnes_municipio" ON "public"."cnes_estabelecimentos" USING "btree" ("codigo_municipio");

CREATE INDEX "cnes_tipo" ON "public"."cnes_estabelecimentos" USING "btree" ("codigo_tipo_unidade");

CREATE INDEX "cnes_uf" ON "public"."cnes_estabelecimentos" USING "btree" ("codigo_uf");

CREATE INDEX "contratos_data_assinatura_idx" ON "public"."contratos_federais" USING "btree" ("data_assinatura");

CREATE INDEX "contratos_fornecedor_cnpj_idx" ON "public"."contratos_federais" USING "btree" ("fornecedor_cnpj");

CREATE INDEX "contratos_orgao_idx" ON "public"."contratos_federais" USING "btree" ("orgao_codigo");

CREATE INDEX "contratos_valor_total_idx" ON "public"."contratos_federais" USING "btree" ("valor_total" DESC);

CREATE INDEX "cota_cnpj_ranking_cnpj" ON "public"."cota_cnpj_ranking" USING "btree" ("cnpj");

CREATE UNIQUE INDEX "cota_cnpj_ranking_pk" ON "public"."cota_cnpj_ranking" USING "btree" ("cnpj", COALESCE("nome_fornecedor", ''::"text"));

CREATE INDEX "cota_cnpj_ranking_valor" ON "public"."cota_cnpj_ranking" USING "btree" ("total_liquido_brl" DESC NULLS LAST);

CREATE INDEX "cpgf_ano_mes_idx" ON "public"."cpgf_transacoes" USING "btree" ("ano_mes");

CREATE INDEX "cpgf_favorecido_idx" ON "public"."cpgf_transacoes" USING "btree" ("cpf_cnpj_favorecido");

CREATE INDEX "cpgf_portador_idx" ON "public"."cpgf_transacoes" USING "btree" ("cpf_portador");

CREATE INDEX "cpgf_uf_idx" ON "public"."cpgf_transacoes" USING "btree" ("uf");

CREATE INDEX "cpgf_valor_idx" ON "public"."cpgf_transacoes" USING "btree" ("valor");

CREATE INDEX "cvm_acusados_nome_idx" ON "public"."cvm_acusados" USING "btree" ("nome_normalizado");

CREATE INDEX "cvm_acusados_nup_idx" ON "public"."cvm_acusados" USING "btree" ("nup");

CREATE INDEX "cvm_processos_abertura_idx" ON "public"."cvm_processos" USING "btree" ("data_abertura");

CREATE INDEX "cvm_processos_fase_idx" ON "public"."cvm_processos" USING "btree" ("fase_atual");

CREATE INDEX "dou_alertas_data_idx" ON "public"."dou_alertas_cruzamento" USING "btree" ("data_publicacao" DESC);

CREATE INDEX "dou_alertas_match_idx" ON "public"."dou_alertas_cruzamento" USING "btree" ("tipo_match", "valor_match");

CREATE INDEX "dou_publicacoes_assinante_idx" ON "public"."dou_publicacoes" USING "btree" ("assinante");

CREATE INDEX "dou_publicacoes_cnpjs_idx" ON "public"."dou_publicacoes" USING "gin" ("cnpjs_extraidos");

CREATE INDEX "dou_publicacoes_cpfs_idx" ON "public"."dou_publicacoes" USING "gin" ("cpfs_extraidos");

CREATE INDEX "dou_publicacoes_data_idx" ON "public"."dou_publicacoes" USING "btree" ("data_publicacao" DESC);

CREATE INDEX "dou_publicacoes_secao_idx" ON "public"."dou_publicacoes" USING "btree" ("secao");

CREATE INDEX "emendas_api_ano_idx" ON "public"."emendas_api" USING "btree" ("ano");

CREATE INDEX "emendas_api_autor_cpf_idx" ON "public"."emendas_api" USING "btree" ("autor_cpf");

CREATE INDEX "emendas_api_autor_uf_idx" ON "public"."emendas_api" USING "btree" ("autor_uf");

CREATE INDEX "emendas_api_funcao_idx" ON "public"."emendas_api" USING "btree" ("funcao_codigo");

CREATE INDEX "emendas_api_localidade_idx" ON "public"."emendas_api" USING "btree" ("localidade_ibge");

CREATE UNIQUE INDEX "emendas_codigo_unique" ON "public"."emendas" USING "btree" ("codigo_emenda");

CREATE INDEX "emendas_docs_emenda_idx" ON "public"."emendas_api_documentos" USING "btree" ("emenda_codigo");

CREATE INDEX "emendas_docs_favorecido_idx" ON "public"."emendas_api_documentos" USING "btree" ("favorecido_cnpj");

CREATE UNIQUE INDEX "emendas_unique_id" ON "public"."emendas" USING "btree" ("id");

CREATE UNIQUE INDEX "fornecedores_intersetados_cnpj_idx" ON "public"."fornecedores_intersetados" USING "btree" ("cnpj");

CREATE INDEX "fornecedores_intersetados_n_casas_idx" ON "public"."fornecedores_intersetados" USING "btree" ("n_casas" DESC);

CREATE INDEX "fornecedores_intersetados_total_idx" ON "public"."fornecedores_intersetados" USING "btree" ("total_geral" DESC);

CREATE INDEX "ibama_cpf_cnpj_idx" ON "public"."ibama_autuacoes" USING "btree" ("cpf_cnpj_infrator");

CREATE INDEX "ibama_dat_idx" ON "public"."ibama_autuacoes" USING "btree" ("dat_infracao");

CREATE INDEX "ibama_municipio_idx" ON "public"."ibama_autuacoes" USING "btree" ("municipio");

CREATE INDEX "ibama_tp_pessoa_idx" ON "public"."ibama_autuacoes" USING "btree" ("tp_pessoa");

CREATE INDEX "ibama_uf_idx" ON "public"."ibama_autuacoes" USING "btree" ("uf");

CREATE INDEX "ibama_val_idx" ON "public"."ibama_autuacoes" USING "btree" ("val_auto_infracao");

CREATE INDEX "ibge_indicadores_municipio" ON "public"."ibge_indicadores" USING "btree" ("codigo_ibge");

CREATE INDEX "ibge_indicadores_pesquisa" ON "public"."ibge_indicadores" USING "btree" ("pesquisa_id", "variavel_id", "ano");

CREATE INDEX "ibge_municipios_nome" ON "public"."ibge_municipios" USING "btree" ("nome");

CREATE INDEX "ibge_municipios_uf" ON "public"."ibge_municipios" USING "btree" ("uf");

CREATE INDEX "idx_ale_ingest_runs_casa" ON "public"."ale_ingest_runs" USING "btree" ("casa_id", "started_at" DESC);

CREATE INDEX "idx_ale_parlamentares_casa" ON "public"."ale_parlamentares" USING "btree" ("casa_id");

CREATE INDEX "idx_ale_parlamentares_partido" ON "public"."ale_parlamentares" USING "btree" ("partido");

CREATE INDEX "idx_ale_parlamentares_slug" ON "public"."ale_parlamentares" USING "btree" ("slug");

CREATE INDEX "idx_ale_proposicoes_ano" ON "public"."ale_proposicoes" USING "btree" ("ano");

CREATE INDEX "idx_ale_proposicoes_casa" ON "public"."ale_proposicoes" USING "btree" ("casa_id");

CREATE INDEX "idx_ale_proposicoes_data" ON "public"."ale_proposicoes" USING "btree" ("data_apresentacao");

CREATE INDEX "idx_ale_proposicoes_tipo" ON "public"."ale_proposicoes" USING "btree" ("tipo");

CREATE INDEX "idx_ale_votacoes_casa" ON "public"."ale_votacoes" USING "btree" ("casa_id");

CREATE INDEX "idx_ale_votacoes_data" ON "public"."ale_votacoes" USING "btree" ("data");

CREATE INDEX "idx_ale_votacoes_proposicao" ON "public"."ale_votacoes" USING "btree" ("proposicao_id");

CREATE INDEX "idx_ale_votos_deputado" ON "public"."ale_votos" USING "btree" ("deputado_id");

CREATE INDEX "idx_aleba_dep_partido" ON "public"."aleba_deputados" USING "btree" ("partido");

CREATE INDEX "idx_aleba_desp_ano" ON "public"."aleba_despesas" USING "btree" ("ano");

CREATE INDEX "idx_aleba_desp_deputado" ON "public"."aleba_despesas" USING "btree" ("id_aleba");

CREATE INDEX "idx_aleba_desp_favorecido" ON "public"."aleba_despesas" USING "btree" ("favorecido");

CREATE INDEX "idx_aleba_desp_valor" ON "public"."aleba_despesas" USING "btree" ("valor");

CREATE INDEX "idx_alertas_email" ON "public"."alertas_processo" USING "btree" ("email");

CREATE INDEX "idx_alesc_dep_partido" ON "public"."alesc_deputados" USING "btree" ("partido");

CREATE INDEX "idx_alesc_desp_ano" ON "public"."alesc_despesas" USING "btree" ("ano");

CREATE INDEX "idx_alesc_desp_deputado" ON "public"."alesc_despesas" USING "btree" ("id_alesc");

CREATE INDEX "idx_alesc_desp_favorecido" ON "public"."alesc_despesas" USING "btree" ("favorecido");

CREATE INDEX "idx_alesc_desp_valor" ON "public"."alesc_despesas" USING "btree" ("valor");

CREATE INDEX "idx_ask_cache_expires" ON "public"."ask_cache" USING "btree" ("expires_at");

CREATE INDEX "idx_ask_cache_hash" ON "public"."ask_cache" USING "btree" ("pergunta_hash");

CREATE INDEX "idx_ask_ceap_dep_passagens" ON "public"."ask_ceap_deputado_ano_agg" USING "btree" ("passagens" DESC);

CREATE INDEX "idx_ask_ceap_dep_valor" ON "public"."ask_ceap_deputado_ano_agg" USING "btree" ("total_valor" DESC);

CREATE INDEX "idx_ask_ceap_forn_valor" ON "public"."ask_ceap_fornecedor_agg" USING "btree" ("total_valor" DESC);

CREATE INDEX "idx_ask_ceap_tipo_valor" ON "public"."ask_ceap_tipo_ano_agg" USING "btree" ("total_valor" DESC);

CREATE INDEX "idx_ask_emendas_autor_rp9" ON "public"."ask_emendas_autor_ano_agg" USING "btree" ("valor_rp9_pago" DESC);

CREATE INDEX "idx_ask_emendas_autor_valor" ON "public"."ask_emendas_autor_ano_agg" USING "btree" ("total_pago" DESC);

CREATE INDEX "idx_ask_log_created" ON "public"."ask_log" USING "btree" ("created_at" DESC);

CREATE INDEX "idx_ask_log_pergunta" ON "public"."ask_log" USING "gin" ("to_tsvector"('"portuguese"'::"regconfig", "pergunta_original"));

CREATE INDEX "idx_ask_log_success" ON "public"."ask_log" USING "btree" ("success", "created_at" DESC);

CREATE UNIQUE INDEX "idx_autores_id_camara" ON "public"."autores_orcamentarios" USING "btree" ("id_camara") WHERE ("id_camara" IS NOT NULL);

CREATE UNIQUE INDEX "idx_autores_id_senado" ON "public"."autores_orcamentarios" USING "btree" ("id_senado") WHERE ("id_senado" IS NOT NULL);

CREATE UNIQUE INDEX "idx_autores_nome_normalizado" ON "public"."autores_orcamentarios" USING "btree" ("nome_normalizado");

CREATE INDEX "idx_b3_cnpj" ON "public"."b3_empresas_listadas" USING "btree" ("cnpj") WHERE (("cnpj" IS NOT NULL) AND ("cnpj" <> '0'::"text"));

CREATE INDEX "idx_b3_ticker" ON "public"."b3_tickers" USING "btree" ("ticker");

CREATE INDEX "idx_banks_codigo" ON "public"."banks" USING "btree" ("codigo");

CREATE INDEX "idx_bets_licenciadas_cnpj" ON "public"."bets_licenciadas" USING "btree" ("cnpj");

CREATE INDEX "idx_cam_parlamentar_risco_cpf" ON "public"."cam_parlamentar_risco" USING "btree" ("cpf") WHERE ("cpf" IS NOT NULL);

CREATE INDEX "idx_cam_prop_agg_partido" ON "public"."cam_proposicoes_agg" USING "btree" ("sigla_partido");

CREATE INDEX "idx_cam_prop_agg_total" ON "public"."cam_proposicoes_agg" USING "btree" ("total_substantivo" DESC);

CREATE INDEX "idx_cam_prop_agg_uf" ON "public"."cam_proposicoes_agg" USING "btree" ("sigla_uf");

CREATE INDEX "idx_cam_prop_ano" ON "public"."cam_proposicoes" USING "btree" ("ano" DESC);

CREATE INDEX "idx_cam_prop_deputado" ON "public"."cam_proposicoes" USING "btree" ("deputado_id");

CREATE INDEX "idx_cam_prop_tipo" ON "public"."cam_proposicoes" USING "btree" ("sigla_tipo");

CREATE INDEX "idx_camara_fm_dep" ON "public"."camara_frente_membro" USING "btree" ("id_deputado");

CREATE INDEX "idx_camara_fm_partido" ON "public"."camara_frente_membro" USING "btree" ("sigla_partido");

CREATE INDEX "idx_camara_frente_leg" ON "public"."camara_frente" USING "btree" ("id_legislatura");

CREATE INDEX "idx_camara_frente_titulo" ON "public"."camara_frente" USING "gin" ("to_tsvector"('"portuguese"'::"regconfig", "titulo"));

CREATE INDEX "idx_camara_ocup_dep" ON "public"."camara_ocupacao" USING "btree" ("id_deputado");

CREATE INDEX "idx_camara_ocup_titulo" ON "public"."camara_ocupacao" USING "gin" ("to_tsvector"('"portuguese"'::"regconfig", "titulo"));

CREATE INDEX "idx_casas_esfera" ON "public"."casas" USING "btree" ("esfera");

CREATE INDEX "idx_casas_sigla" ON "public"."casas" USING "btree" ("sigla");

CREATE INDEX "idx_ceaf_data_pub" ON "public"."ceaf_expulsoes" USING "btree" ("data_publicacao" DESC NULLS LAST);

CREATE INDEX "idx_ceaf_nome" ON "public"."ceaf_expulsoes" USING "gin" ("to_tsvector"('"portuguese"'::"regconfig", COALESCE("nome_punido", ''::"text")));

CREATE INDEX "idx_ceaf_orgao" ON "public"."ceaf_expulsoes" USING "btree" ("orgao_nome");

CREATE INDEX "idx_ceaf_processo" ON "public"."ceaf_expulsoes" USING "btree" ("numero_processo") WHERE ("numero_processo" IS NOT NULL);

CREATE INDEX "idx_ceaf_tipo" ON "public"."ceaf_expulsoes" USING "btree" ("tipo_punicao");

CREATE INDEX "idx_ceaf_uf" ON "public"."ceaf_expulsoes" USING "btree" ("uf_lotacao");

CREATE INDEX "idx_ceaps_brutas_ano" ON "public"."ceaps_brutas" USING "btree" ("ano");

CREATE INDEX "idx_ceaps_brutas_deputado" ON "public"."ceaps_brutas" USING "btree" ("deputado_id_externo");

CREATE INDEX "idx_ceaps_brutas_deputado_ano" ON "public"."ceaps_brutas" USING "btree" ("deputado_id_externo", "ano");

CREATE INDEX "idx_ceaps_brutas_fornecedor" ON "public"."ceaps_brutas" USING "btree" ("cnpj_cpf_fornecedor");

CREATE INDEX "idx_ceaps_brutas_tipo" ON "public"."ceaps_brutas" USING "btree" ("tipo_despesa");

CREATE INDEX "idx_ceaps_ranking_ano_posicao" ON "public"."ceaps_ranking" USING "btree" ("ano", "posicao");

CREATE INDEX "idx_ceaps_senado_ano" ON "public"."ceaps_senado_brutas" USING "btree" ("ano");

CREATE INDEX "idx_ceaps_senado_forn" ON "public"."ceaps_senado_brutas" USING "btree" ("cnpj_cpf");

CREATE INDEX "idx_ceaps_senado_rank_ano" ON "public"."ceaps_senado_ranking" USING "btree" ("ano");

CREATE INDEX "idx_ceaps_senado_rank_pos" ON "public"."ceaps_senado_ranking" USING "btree" ("posicao", "ano");

CREATE INDEX "idx_ceaps_senado_rank_total" ON "public"."ceaps_senado_ranking" USING "btree" ("total_reembolsado" DESC, "ano");

CREATE INDEX "idx_ceaps_senado_senador" ON "public"."ceaps_senado_brutas" USING "btree" ("senador_normalizado", "ano");

CREATE INDEX "idx_ceaps_senado_tipo" ON "public"."ceaps_senado_brutas" USING "btree" ("tipo_despesa", "ano");

CREATE INDEX "idx_cnpj_emp_porte" ON "public"."cnpj_empresas" USING "btree" ("porte_empresa");

CREATE INDEX "idx_cnpj_enriquecido_cnae" ON "public"."cnpj_enriquecido" USING "btree" ("cnae_principal_codigo");

CREATE INDEX "idx_cnpj_enriquecido_situacao" ON "public"."cnpj_enriquecido" USING "btree" ("situacao_cadastral");

CREATE INDEX "idx_cnpj_enriquecido_uf" ON "public"."cnpj_enriquecido" USING "btree" ("uf");

CREATE INDEX "idx_cnpj_socios_basico" ON "public"."cnpj_socios" USING "btree" ("cnpj_basico");

CREATE INDEX "idx_cnpj_socios_nome" ON "public"."cnpj_socios" USING "btree" ("nome_norm") WHERE ("nome_norm" IS NOT NULL);

CREATE INDEX "idx_comissoes_membros_deputado" ON "public"."cam_comissoes_membros" USING "btree" ("deputado_id");

CREATE INDEX "idx_comissoes_parlamentar_id" ON "public"."comissoes_parlamentares" USING "btree" ("parlamentar_id");

CREATE INDEX "idx_comissoes_senado_parlamentar" ON "public"."comissoes_senado" USING "btree" ("parlamentar_id");

CREATE INDEX "idx_comissoes_senado_situacao" ON "public"."comissoes_senado" USING "btree" ("situacao");

CREATE INDEX "idx_comissoes_senado_tipo" ON "public"."comissoes_senado" USING "btree" ("tipo_funcao");

CREATE INDEX "idx_convenios_convenente_cnpj" ON "public"."convenios" USING "btree" ("convenente_cnpj");

CREATE INDEX "idx_convenios_municipio" ON "public"."convenios" USING "btree" ("municipio_ibge");

CREATE UNIQUE INDEX "idx_convenios_numero" ON "public"."convenios" USING "btree" ("numero") WHERE ("numero" IS NOT NULL);

CREATE INDEX "idx_convenios_orgao_maximo" ON "public"."convenios" USING "btree" ("orgao_maximo_codigo");

CREATE INDEX "idx_convenios_situacao" ON "public"."convenios" USING "btree" ("situacao");

CREATE INDEX "idx_convenios_uf" ON "public"."convenios" USING "btree" ("uf");

CREATE INDEX "idx_convenios_vigencia" ON "public"."convenios" USING "btree" ("data_inicio_vigencia", "data_final_vigencia");

CREATE INDEX "idx_cota_dep_partido" ON "public"."cota_deputado" USING "btree" ("partido");

CREATE INDEX "idx_cota_dep_uf" ON "public"."cota_deputado" USING "btree" ("uf");

CREATE INDEX "idx_cota_desp_ano_mes" ON "public"."cota_despesa" USING "btree" ("ano", "mes");

CREATE INDEX "idx_cota_desp_cnpj" ON "public"."cota_despesa" USING "btree" ("cnpj_cpf_fornecedor") WHERE (("cnpj_cpf_fornecedor" IS NOT NULL) AND ("cnpj_cpf_fornecedor" <> ''::"text"));

CREATE INDEX "idx_cota_desp_cnpj_norm" ON "public"."cota_despesa" USING "btree" ("cnpj_norm") WHERE (("cnpj_norm" IS NOT NULL) AND ("cnpj_norm" <> ''::"text"));

CREATE INDEX "idx_cota_desp_deputado" ON "public"."cota_despesa" USING "btree" ("id_deputado");

CREATE INDEX "idx_cota_desp_fornecedor_nome" ON "public"."cota_despesa" USING "gin" ("to_tsvector"('"portuguese"'::"regconfig", COALESCE("nome_fornecedor", ''::"text")));

CREATE INDEX "idx_cota_desp_tipo" ON "public"."cota_despesa" USING "btree" ("tipo_despesa");

CREATE INDEX "idx_cota_lookup_norm" ON "public"."cota_cnpj_lookup" USING "btree" ("cnpj_norm");

CREATE INDEX "idx_cron_log_job_name" ON "public"."cron_execution_log" USING "btree" ("job_name");

CREATE INDEX "idx_cron_log_started_at" ON "public"."cron_execution_log" USING "btree" ("started_at" DESC);

CREATE INDEX "idx_cvm_corretoras_status" ON "public"."cvm_corretoras" USING "btree" ("status");

CREATE INDEX "idx_cvm_corretoras_uf" ON "public"."cvm_corretoras" USING "btree" ("uf");

CREATE INDEX "idx_cvm_edge_ativo" ON "public"."cvm_carteira_edge" USING "btree" ("cnpj_ativo");

CREATE INDEX "idx_cvm_edge_fundo" ON "public"."cvm_carteira_edge" USING "btree" ("cnpj_fundo");

CREATE INDEX "idx_cvm_fip_cnpj" ON "public"."cvm_fip_informe" USING "btree" ("cnpj_norm");

CREATE INDEX "idx_cvm_fip_part_emp" ON "public"."cvm_fip_participacao" USING "btree" ("cnpj_empresa") WHERE ("cnpj_empresa" IS NOT NULL);

CREATE INDEX "idx_cvm_fundo_admin" ON "public"."cvm_fundo" USING "btree" ("cnpj_admin") WHERE ("cnpj_admin" IS NOT NULL);

CREATE INDEX "idx_cvm_fundo_controlador" ON "public"."cvm_fundo" USING "btree" ("cnpj_controlador") WHERE ("cnpj_controlador" IS NOT NULL);

CREATE INDEX "idx_cvm_fundo_gestor" ON "public"."cvm_fundo" USING "btree" ("cnpj_gestor") WHERE ("cnpj_gestor" IS NOT NULL);

CREATE INDEX "idx_cvm_fundo_tipo" ON "public"."cvm_fundo" USING "btree" ("tipo");

CREATE INDEX "idx_cvm_oferta_emissor" ON "public"."cvm_oferta" USING "btree" ("cnpj_emissor") WHERE ("cnpj_emissor" IS NOT NULL);

CREATE INDEX "idx_cvm_saf_clube" ON "public"."cvm_saf" USING "btree" ("clube");

CREATE INDEX "idx_declaracao_bens_parlamentar" ON "public"."declaracao_bens" USING "btree" ("parlamentar_id");

CREATE INDEX "idx_deputados_brutas_id_externo" ON "public"."deputados_brutas" USING "btree" ("id_externo");

CREATE INDEX "idx_deputados_brutas_partido" ON "public"."deputados_brutas" USING "btree" ("sigla_partido");

CREATE INDEX "idx_deputados_brutas_uf" ON "public"."deputados_brutas" USING "btree" ("sigla_uf");

CREATE INDEX "idx_deputados_brutas_uf_partido" ON "public"."deputados_brutas" USING "btree" ("sigla_uf", "sigla_partido");

CREATE INDEX "idx_despesas_raw_ano2" ON "public"."despesas_gabinete_raw" USING "btree" ("ano");

CREATE INDEX "idx_despesas_raw_deputado" ON "public"."despesas_gabinete_raw" USING "btree" ("deputado_id");

CREATE INDEX "idx_despesas_raw_parl_uid" ON "public"."despesas_gabinete_raw" USING "btree" ("parlamentar_uid");

CREATE INDEX "idx_despesas_raw_tipo_trgm" ON "public"."despesas_gabinete_raw" USING "gin" ("tipo_despesa" "public"."gin_trgm_ops");

CREATE INDEX "idx_discursos_camara_data" ON "public"."discursos_camara" USING "btree" ("data_hora");

CREATE INDEX "idx_discursos_camara_fase" ON "public"."discursos_camara" USING "btree" ("fase_evento");

CREATE INDEX "idx_discursos_camara_parlamentar" ON "public"."discursos_camara" USING "btree" ("parlamentar_id");

CREATE INDEX "idx_discursos_camara_transcricao_fts" ON "public"."discursos_camara" USING "gin" ("to_tsvector"('"portuguese"'::"regconfig", ((COALESCE("transcricao", ''::"text") || ' '::"text") || COALESCE("sumario", ''::"text"))));

CREATE INDEX "idx_discursos_data" ON "public"."discursos" USING "btree" ("data_hora_inicio" DESC);

CREATE INDEX "idx_discursos_parlamentar" ON "public"."discursos" USING "btree" ("parlamentar_id");

CREATE INDEX "idx_discursos_senado_data" ON "public"."discursos_senado" USING "btree" ("data_hora");

CREATE INDEX "idx_discursos_senado_fase" ON "public"."discursos_senado" USING "btree" ("fase");

CREATE INDEX "idx_discursos_senado_parlamentar" ON "public"."discursos_senado" USING "btree" ("parlamentar_id");

CREATE INDEX "idx_ele26_alert_ativo" ON "public"."ele2026_alertas" USING "btree" ("alerta_ativo") WHERE ("alerta_ativo" = true);

CREATE INDEX "idx_ele26_alert_cpf" ON "public"."ele2026_alertas" USING "btree" ("cpf") WHERE ("cpf" IS NOT NULL);

CREATE INDEX "idx_ele26_cand_cargo" ON "public"."ele2026_candidatos" USING "btree" ("cd_cargo");

CREATE INDEX "idx_ele26_cand_cpf" ON "public"."ele2026_candidatos" USING "btree" ("cpf") WHERE ("cpf" IS NOT NULL);

CREATE INDEX "idx_ele26_cand_parlamentar" ON "public"."ele2026_candidatos" USING "btree" ("parlamentar_id") WHERE ("parlamentar_id" IS NOT NULL);

CREATE INDEX "idx_ele26_cand_partido" ON "public"."ele2026_candidatos" USING "btree" ("sigla_partido");

CREATE INDEX "idx_ele26_cand_uf" ON "public"."ele2026_candidatos" USING "btree" ("uf");

CREATE INDEX "idx_ele26_fin_cnpj_doador" ON "public"."ele2026_financiamento" USING "btree" ("cpf_cnpj_doador") WHERE ("cpf_cnpj_doador" IS NOT NULL);

CREATE INDEX "idx_ele26_fin_cpf_cand" ON "public"."ele2026_financiamento" USING "btree" ("cpf_candidato") WHERE ("cpf_candidato" IS NOT NULL);

CREATE UNIQUE INDEX "idx_ele26_fin_recibo" ON "public"."ele2026_financiamento" USING "btree" ("numero_recibo") WHERE ("numero_recibo" IS NOT NULL);

CREATE INDEX "idx_ele26_fin_uf" ON "public"."ele2026_financiamento" USING "btree" ("uf");

CREATE INDEX "idx_ele26_gast_cnpj_forn" ON "public"."ele2026_gastos" USING "btree" ("cpf_cnpj_fornecedor") WHERE ("cpf_cnpj_fornecedor" IS NOT NULL);

CREATE INDEX "idx_ele26_gast_cpf_cand" ON "public"."ele2026_gastos" USING "btree" ("cpf_candidato") WHERE ("cpf_candidato" IS NOT NULL);

CREATE INDEX "idx_ele26_gast_tipo" ON "public"."ele2026_gastos" USING "btree" ("tipo_despesa");

CREATE INDEX "idx_emendas_ano_subtipo" ON "public"."emendas" USING "btree" ("ano", "subtipo");

CREATE INDEX "idx_emendas_autor_nome" ON "public"."emendas" USING "btree" ("autor_nome");

CREATE INDEX "idx_emendas_autor_orcamentario" ON "public"."emendas" USING "btree" ("autor_orcamentario_id");

CREATE INDEX "idx_emendas_brutas_ano" ON "public"."emendas_brutas" USING "btree" ("ano");

CREATE INDEX "idx_emendas_coletivas_ano" ON "public"."emendas_coletivas" USING "btree" ("ano");

CREATE INDEX "idx_emendas_coletivas_tipo" ON "public"."emendas_coletivas" USING "btree" ("tipo_autor");

CREATE INDEX "idx_emendas_completas_ano" ON "public"."emendas_completas" USING "btree" ("ano");

CREATE INDEX "idx_emendas_completas_autor" ON "public"."emendas_completas" USING "btree" ("autor_nome", "ano");

CREATE INDEX "idx_emendas_completas_funcao" ON "public"."emendas_completas" USING "btree" ("funcao", "ano");

CREATE INDEX "idx_emendas_completas_rp9" ON "public"."emendas_completas" USING "btree" ("eh_rp9", "ano");

CREATE INDEX "idx_emendas_completas_tipo" ON "public"."emendas_completas" USING "btree" ("tipo_emenda", "ano");

CREATE INDEX "idx_emendas_completas_uf_ano" ON "public"."emendas_completas" USING "btree" ("uf", "ano");

CREATE INDEX "idx_emendas_convenios_codigo" ON "public"."emendas_convenios" USING "btree" ("codigo_emenda");

CREATE INDEX "idx_emendas_convenios_conv" ON "public"."emendas_convenios" USING "btree" ("convenente");

CREATE INDEX "idx_emendas_convenios_data" ON "public"."emendas_convenios" USING "btree" ("data_publicacao");

CREATE INDEX "idx_emendas_favorecidos_ano_emenda" ON "public"."emendas_favorecidos" USING "btree" ("ano_emenda");

CREATE INDEX "idx_emendas_favorecidos_codigo_emenda" ON "public"."emendas_favorecidos" USING "btree" ("codigo_emenda");

CREATE INDEX "idx_emendas_favorecidos_codigo_favorecido" ON "public"."emendas_favorecidos" USING "btree" ("codigo_favorecido");

CREATE INDEX "idx_emendas_favorecidos_nome_autor" ON "public"."emendas_favorecidos" USING "btree" ("nome_autor");

CREATE INDEX "idx_emendas_favorecidos_subtipo" ON "public"."emendas_favorecidos" USING "btree" ("subtipo");

CREATE INDEX "idx_emendas_favorecidos_uf_favorecido" ON "public"."emendas_favorecidos" USING "btree" ("uf_favorecido");

CREATE INDEX "idx_emendas_favorecidos_valor" ON "public"."emendas_favorecidos" USING "btree" ("valor_recebido" DESC);

CREATE INDEX "idx_emendas_financeiro_ano" ON "public"."emendas_financeiro" USING "btree" ("ano");

CREATE INDEX "idx_emendas_financeiro_parlamentar" ON "public"."emendas_financeiro" USING "btree" ("parlamentar_id");

CREATE INDEX "idx_emendas_municipio" ON "public"."emendas" USING "btree" ("municipio_nome");

CREATE INDEX "idx_emendas_subtipo" ON "public"."emendas" USING "btree" ("subtipo");

CREATE INDEX "idx_emendas_uf_destino" ON "public"."emendas" USING "btree" ("uf_destino");

CREATE INDEX "idx_exec_fin_ano" ON "public"."execucao_financeira_siafi" USING "btree" ("ano");

CREATE INDEX "idx_exec_fin_favorecido" ON "public"."execucao_financeira_siafi" USING "btree" ("favorecido");

CREATE INDEX "idx_exec_fin_orgao" ON "public"."execucao_financeira_siafi" USING "btree" ("orgao");

CREATE INDEX "idx_exec_fin_uf" ON "public"."execucao_financeira_siafi" USING "btree" ("uf");

CREATE INDEX "idx_execucoes_pipeline_etapas_execucao" ON "public"."execucoes_pipeline_etapas" USING "btree" ("execucao_id");

CREATE INDEX "idx_execucoes_pipeline_job_iniciado" ON "public"."execucoes_pipeline" USING "btree" ("job_nome", "iniciado_em" DESC);

CREATE INDEX "idx_faf_planos_cnpj_rec" ON "public"."faf_planos_acao" USING "btree" ("cnpj_ente_recebedor");

CREATE INDEX "idx_faf_planos_ibge" ON "public"."faf_planos_acao" USING "btree" ("ibge_recebedor");

CREATE INDEX "idx_faf_planos_orgao" ON "public"."faf_planos_acao" USING "btree" ("sigla_orgao_repassador");

CREATE INDEX "idx_faf_planos_situacao" ON "public"."faf_planos_acao" USING "btree" ("situacao");

CREATE INDEX "idx_faf_planos_uf" ON "public"."faf_planos_acao" USING "btree" ("uf_recebedor");

CREATE INDEX "idx_financiamento_ano" ON "public"."financiamento_eleitoral" USING "btree" ("ano_eleicao");

CREATE INDEX "idx_financiamento_cpf" ON "public"."financiamento_eleitoral" USING "btree" ("cpf_candidato");

CREATE INDEX "idx_financiamento_parlamentar" ON "public"."financiamento_eleitoral" USING "btree" ("parlamentar_id");

CREATE INDEX "idx_folha_custo_casa_soma" ON "public"."folha_custo_gabinete" USING "btree" ("casa", "soma_salarios" DESC);

CREATE INDEX "idx_folha_doador_leads_parlamentar" ON "public"."folha_doador_leads" USING "btree" ("parlamentar_id_externo");

CREATE INDEX "idx_folha_gabinete_casa_snapshot" ON "public"."folha_gabinete" USING "btree" ("casa", "snapshot_date");

CREATE INDEX "idx_folha_gabinete_parlamentar" ON "public"."folha_gabinete" USING "btree" ("parlamentar_id_externo");

CREATE INDEX "idx_folha_gabinete_parlamentar_nome" ON "public"."folha_gabinete" USING "btree" ("parlamentar_nome");

CREATE INDEX "idx_folha_gabinete_secretario_nome" ON "public"."folha_gabinete" USING "btree" ("secretario_nome");

CREATE INDEX "idx_folha_nepotismo_leads_sobrenome" ON "public"."folha_nepotismo_leads" USING "btree" ("sobrenome");

CREATE INDEX "idx_frentes_membros_deputado" ON "public"."cam_frentes_membros" USING "btree" ("deputado_id");

CREATE INDEX "idx_fundacoes_emb_cnpj" ON "public"."fundacoes_embeddings" USING "btree" ("cnpj");

CREATE INDEX "idx_fundacoes_emb_vec" ON "public"."fundacoes_embeddings" USING "ivfflat" ("embedding" "public"."vector_cosine_ops") WITH ("lists"='10');

CREATE INDEX "idx_fundacoes_endereco" ON "public"."fundacoes_partidarias" USING "btree" ("mesmo_endereco_partido");

CREATE INDEX "idx_fundacoes_fts" ON "public"."fundacoes_partidarias" USING "gin" ("to_tsvector"('"portuguese"'::"regconfig", ((((COALESCE("nome_popular", ''::"text") || ' '::"text") || COALESCE("razao_social", ''::"text")) || ' '::"text") || COALESCE("partido_sigla", ''::"text"))));

CREATE INDEX "idx_fundacoes_partido" ON "public"."fundacoes_partidarias" USING "btree" ("partido_sigla");

CREATE INDEX "idx_fundacoes_uf" ON "public"."fundacoes_partidarias" USING "btree" ("uf");

CREATE INDEX "idx_gastos_casa_periodo" ON "public"."gastos_parlamentares" USING "btree" ("casa_id", "ano", "mes");

CREATE INDEX "idx_gastos_categoria" ON "public"."gastos_parlamentares" USING "btree" ("categoria");

CREATE INDEX "idx_gastos_cnpj" ON "public"."gastos_parlamentares" USING "btree" ("cnpj_cpf") WHERE ("cnpj_cpf" <> ''::"text");

CREATE INDEX "idx_gastos_data_emissao" ON "public"."gastos_parlamentares" USING "btree" ("data_emissao");

CREATE INDEX "idx_gastos_parlamentar_periodo" ON "public"."gastos_parlamentares" USING "btree" ("parlamentar_id", "ano", "mes");

CREATE INDEX "idx_glossario_tech_lang" ON "public"."glossario_tech" USING "btree" ("lang");

CREATE INDEX "idx_glossario_tech_tags" ON "public"."glossario_tech" USING "gin" ("tags");

CREATE INDEX "idx_impacto_fed_ano" ON "public"."impacto_federativo" USING "btree" ("ano");

CREATE INDEX "idx_impacto_fed_uf" ON "public"."impacto_federativo" USING "btree" ("uf");

CREATE INDEX "idx_indicadores_inst" ON "public"."indicadores" USING "btree" ("institution_id");

CREATE INDEX "idx_indicadores_nome_data" ON "public"."indicadores_macroeconomicos" USING "btree" ("nome", "capturado_em" DESC);

CREATE INDEX "idx_indicadores_obs" ON "public"."indicadores" USING "btree" ("observatorio_id");

CREATE UNIQUE INDEX "idx_indicadores_unique" ON "public"."indicadores" USING "btree" ("institution_id", "observatorio_id", "indicador");

CREATE INDEX "idx_indice_poder" ON "public"."indice_poder_orcamentario" USING "btree" ("ano", "valor_total" DESC);

CREATE INDEX "idx_ingestion_runs_started_at" ON "public"."ingestion_runs" USING "btree" ("started_at" DESC);

CREATE INDEX "idx_institutions_obs" ON "public"."institutions" USING "btree" ("observatorio_id");

CREATE INDEX "idx_institutions_uf" ON "public"."institutions" USING "btree" ("uf");

CREATE INDEX "idx_jud_hl_semana_ativo" ON "public"."judiciario_highlights" USING "btree" ("semana_referencia" DESC, "ativo");

CREATE INDEX "idx_jud_hl_tribunal" ON "public"."judiciario_highlights" USING "btree" ("tribunal_id");

CREATE INDEX "idx_jud_proc_classe" ON "public"."judiciario_processos" USING "btree" ("classe") WHERE ("classe" IS NOT NULL);

CREATE INDEX "idx_jud_proc_data_coleta" ON "public"."judiciario_processos" USING "btree" ("data_coleta" DESC);

CREATE INDEX "idx_jud_proc_data_decisao" ON "public"."judiciario_processos" USING "btree" ("data_decisao" DESC NULLS LAST);

CREATE INDEX "idx_jud_proc_fts" ON "public"."judiciario_processos" USING "gin" ("search_vector");

CREATE INDEX "idx_jud_proc_numero" ON "public"."judiciario_processos" USING "btree" ("numero_processo");

CREATE INDEX "idx_jud_proc_relator" ON "public"."judiciario_processos" USING "btree" ("relator") WHERE ("relator" IS NOT NULL);

CREATE INDEX "idx_jud_proc_tribunal" ON "public"."judiciario_processos" USING "btree" ("tribunal_id");

CREATE INDEX "idx_kantar_evento" ON "public"."midia_kantar_releases" USING "btree" ("evento_id");

CREATE INDEX "idx_kantar_semana" ON "public"."midia_kantar_releases" USING "btree" ("semana_inicio");

CREATE INDEX "idx_kantar_veiculo" ON "public"."midia_kantar_releases" USING "btree" ("veiculo_id");

CREATE INDEX "idx_leiloes_leilo_cnpj" ON "public"."leiloes_leiloeiros" USING "btree" ("cnpj_completo");

CREATE INDEX "idx_leiloes_leilo_municipio" ON "public"."leiloes_leiloeiros" USING "btree" ("municipio_codigo");

CREATE INDEX "idx_leiloes_leilo_situacao" ON "public"."leiloes_leiloeiros" USING "btree" ("situacao_cadastral");

CREATE INDEX "idx_leiloes_leilo_uf" ON "public"."leiloes_leiloeiros" USING "btree" ("uf");

CREATE INDEX "idx_leiloes_proc_ajuiz" ON "public"."leiloes_processos" USING "btree" ("data_ajuizamento");

CREATE INDEX "idx_leiloes_proc_classe" ON "public"."leiloes_processos" USING "btree" ("classe_codigo");

CREATE INDEX "idx_leiloes_proc_dt_upd" ON "public"."leiloes_processos" USING "btree" ("data_ultima_atualizacao");

CREATE INDEX "idx_leiloes_proc_municipio" ON "public"."leiloes_processos" USING "btree" ("municipio_ibge");

CREATE INDEX "idx_leiloes_proc_tribunal" ON "public"."leiloes_processos" USING "btree" ("tribunal");

CREATE INDEX "idx_mandatos_autor_orcamentario" ON "public"."mandatos" USING "btree" ("autor_orcamentario_id");

CREATE INDEX "idx_mg_compras_forn_ano" ON "public"."mg_compras_fornecedor" USING "btree" ("ano");

CREATE INDEX "idx_mg_compras_forn_cnpj" ON "public"."mg_compras_fornecedor" USING "btree" ("cnpj_norm");

CREATE INDEX "idx_mg_conv_entrada_ano" ON "public"."mg_convenios_entrada" USING "btree" ("ano");

CREATE INDEX "idx_mg_convenios_ano" ON "public"."mg_convenios" USING "btree" ("ano");

CREATE INDEX "idx_mg_convenios_cnpj" ON "public"."mg_convenios" USING "btree" ("convenente_cnpj");

CREATE INDEX "idx_mg_covid_cnpj" ON "public"."mg_covid_compras" USING "btree" ("cnpj_norm");

CREATE INDEX "idx_mg_diarias_orgao_ano" ON "public"."mg_diarias_orgao" USING "btree" ("ano");

CREATE INDEX "idx_mg_divida_tipo_ano" ON "public"."mg_divida_tipo" USING "btree" ("ano");

CREATE UNIQUE INDEX "idx_mg_doacoes_dedupe" ON "public"."mg_doacoes" USING "btree" ("dedupe_key");

CREATE INDEX "idx_mg_doacoes_orgao" ON "public"."mg_doacoes" USING "btree" ("orgao_recebedor");

CREATE INDEX "idx_mg_emendas_ano" ON "public"."mg_emendas_federais" USING "btree" ("ano");

CREATE INDEX "idx_mg_emendas_est_ano" ON "public"."mg_emendas_estaduais" USING "btree" ("ano");

CREATE INDEX "idx_mg_emendas_fed_ano" ON "public"."mg_emendas_federais" USING "btree" ("ano");

CREATE UNIQUE INDEX "idx_mg_emendas_fed_dedupe" ON "public"."mg_emendas_federais" USING "btree" ("dedupe_key");

CREATE INDEX "idx_mg_emendas_fed_mod" ON "public"."mg_emendas_federais" USING "btree" ("modalidade");

CREATE INDEX "idx_mg_emendas_numero" ON "public"."mg_emendas_federais" USING "btree" ("numero_emenda");

CREATE INDEX "idx_mg_emendas_pix_cnpj" ON "public"."mg_emendas_pix" USING "btree" ("cnpj_favorecido");

CREATE INDEX "idx_mg_emendas_pix_emenda" ON "public"."mg_emendas_pix" USING "btree" ("numero_emenda");

CREATE INDEX "idx_mg_emendas_siafi" ON "public"."mg_emendas_federais" USING "btree" ("codigo_siafi");

CREATE UNIQUE INDEX "idx_mg_empenhos_dedupe" ON "public"."mg_empenhos_sancionados" USING "btree" ("dedupe_key");

CREATE INDEX "idx_mg_empenhos_sanc_cnpj" ON "public"."mg_empenhos_sancionados" USING "btree" ("cnpj_norm");

CREATE INDEX "idx_mg_ipsemg_cnpj" ON "public"."mg_ipsemg_contratos" USING "btree" ("cnpj_norm");

CREATE INDEX "idx_mg_lic_sobrepreco_ano" ON "public"."mg_licitacao_sobrepreco" USING "btree" ("ano");

CREATE INDEX "idx_mg_lic_sobrepreco_orgao" ON "public"."mg_licitacao_sobrepreco" USING "btree" ("orgao");

CREATE INDEX "idx_mg_lrf_limites_ano" ON "public"."mg_lrf_limites" USING "btree" ("ano_ref");

CREATE INDEX "idx_mg_lrf_pessoal_ord" ON "public"."mg_lrf_pessoal" USING "btree" ("ano", "mes");

CREATE INDEX "idx_mg_notas_forn_ano" ON "public"."mg_notas_fornecedor" USING "btree" ("ano");

CREATE INDEX "idx_mg_notas_forn_cnpj" ON "public"."mg_notas_fornecedor" USING "btree" ("cnpj_norm");

CREATE INDEX "idx_mg_obras_cnpj" ON "public"."mg_obras" USING "btree" ("cnpj_norm");

CREATE INDEX "idx_mg_obras_paralisad" ON "public"."mg_obras" USING "btree" ("dias_paralisados") WHERE ("dias_paralisados" > 0);

CREATE INDEX "idx_mg_os_cnpj" ON "public"."mg_os_parcerias" USING "btree" ("cnpj_norm");

CREATE INDEX "idx_mg_remuneracao_acima_teto" ON "public"."mg_remuneracao" USING "btree" ("snapshot_mes") WHERE "acima_teto";

CREATE INDEX "idx_mg_remuneracao_orgao" ON "public"."mg_remuneracao" USING "btree" ("orgao");

CREATE INDEX "idx_mg_remuneracao_servidor" ON "public"."mg_remuneracao" USING "btree" ("servidor_nome");

CREATE INDEX "idx_mg_remuneracao_snapshot" ON "public"."mg_remuneracao" USING "btree" ("snapshot_mes");

CREATE INDEX "idx_mg_restos_orgao_ano" ON "public"."mg_restos_orgao" USING "btree" ("ano");

CREATE INDEX "idx_mg_sancionadas_cnpj" ON "public"."mg_empresas_sancionadas" USING "btree" ("cnpj_norm");

CREATE INDEX "idx_mg_siafi_ano" ON "public"."mg_siafi_execucao" USING "btree" ("ano_exercicio");

CREATE INDEX "idx_mg_siafi_cnpj" ON "public"."mg_siafi_execucao" USING "btree" ("cnpj_cpf_credor");

CREATE INDEX "idx_mg_siafi_empenho" ON "public"."mg_siafi_execucao" USING "btree" ("numero_empenho");

CREATE INDEX "idx_mg_siafi_orgao" ON "public"."mg_siafi_execucao" USING "btree" ("orgao_codigo");

CREATE INDEX "idx_mg_terceir_cnpj" ON "public"."mg_terceirizados" USING "btree" ("cnpj_norm");

CREATE INDEX "idx_mg_vale_anomes" ON "public"."mg_despesa_pessoal_vale" USING "btree" ("ano_mes");

CREATE INDEX "idx_mg_voos_data" ON "public"."mg_voos_governador" USING "btree" ("data_voo");

CREATE INDEX "idx_midia_veiculos_categoria" ON "public"."midia_veiculos" USING "btree" ("categoria");

CREATE INDEX "idx_midia_veiculos_cnpjs" ON "public"."midia_veiculos" USING "gin" ("cnpjs");

CREATE INDEX "idx_municipios_nome" ON "public"."municipios_ibge" USING "btree" ("nome");

CREATE INDEX "idx_municipios_uf" ON "public"."municipios_ibge" USING "btree" ("uf");

CREATE UNIQUE INDEX "idx_mv_contratos_doad_cnpj" ON "public"."mv_contratos_doadores_federal" USING "btree" ("cnpj");

CREATE INDEX "idx_mv_contratos_doad_doador" ON "public"."mv_contratos_doadores_federal" USING "btree" ("is_doador_tse") WHERE ("is_doador_tse" = true);

CREATE INDEX "idx_mv_contratos_doad_risk" ON "public"."mv_contratos_doadores_federal" USING "btree" ("risk_score" DESC);

CREATE UNIQUE INDEX "idx_mv_cota_fornecedor_chave" ON "public"."mv_cota_fornecedor" USING "btree" ("chave");

CREATE INDEX "idx_mv_cota_fornecedor_cnpj" ON "public"."mv_cota_fornecedor" USING "btree" ("cnpj_norm") WHERE ("cnpj_norm" IS NOT NULL);

CREATE INDEX "idx_mv_cota_fornecedor_total" ON "public"."mv_cota_fornecedor" USING "btree" ("total_liquido" DESC);

CREATE INDEX "idx_mv_ranking_indice" ON "public"."mv_ranking_parlamentar" USING "btree" ("indice_poder_parlamentar" DESC);

CREATE UNIQUE INDEX "idx_mv_ranking_parlamentar_id" ON "public"."mv_ranking_parlamentar" USING "btree" ("parlamentar_id");

CREATE UNIQUE INDEX "idx_mv_scorecard_cnpj_cnpj" ON "public"."mv_scorecard_cnpj" USING "btree" ("cnpj");

CREATE INDEX "idx_mv_scorecard_cnpj_doador" ON "public"."mv_scorecard_cnpj" USING "btree" ("is_doador_tse") WHERE ("is_doador_tse" = true);

CREATE INDEX "idx_mv_scorecard_cnpj_risk" ON "public"."mv_scorecard_cnpj" USING "btree" ("risk_score" DESC);

CREATE INDEX "idx_mv_scorecard_cnpj_sancionado" ON "public"."mv_scorecard_cnpj" USING "btree" ("is_sancionado_ativo") WHERE ("is_sancionado_ativo" = true);

CREATE INDEX "idx_mv_scorecard_cnpj_valor" ON "public"."mv_scorecard_cnpj" USING "btree" ("valor_total_recebido" DESC NULLS LAST);

CREATE UNIQUE INDEX "idx_mv_scorecard_fed_cnpj" ON "public"."mv_scorecard_fornecedor_federal" USING "btree" ("cnpj");

CREATE INDEX "idx_mv_scorecard_fed_doador" ON "public"."mv_scorecard_fornecedor_federal" USING "btree" ("is_doador_tse") WHERE ("is_doador_tse" = true);

CREATE INDEX "idx_mv_scorecard_fed_sancionado" ON "public"."mv_scorecard_fornecedor_federal" USING "btree" ("is_sancionado_ativo") WHERE ("is_sancionado_ativo" = true);

CREATE INDEX "idx_narrativas_obs" ON "public"."narrativas" USING "btree" ("observatorio_id");

CREATE INDEX "idx_narrativas_relevancia" ON "public"."narrativas" USING "btree" ("nivel_relevancia" DESC);

CREATE INDEX "idx_news_sub_email" ON "public"."newsletter_subscribers" USING "btree" ("email");

CREATE INDEX "idx_nf_exercicio" ON "public"."fundacoes_nf_partidos" USING "btree" ("aa_exercicio");

CREATE INDEX "idx_nf_fornecedor" ON "public"."fundacoes_nf_partidos" USING "btree" ("cnpj_fornecedor");

CREATE INDEX "idx_nf_fundacao" ON "public"."fundacoes_nf_partidos" USING "btree" ("fundacao_cnpj") WHERE ("fundacao_cnpj" IS NOT NULL);

CREATE INDEX "idx_nf_partido" ON "public"."fundacoes_nf_partidos" USING "btree" ("sg_partido", "aa_exercicio");

CREATE INDEX "idx_nf_tipo_despesa" ON "public"."fundacoes_nf_partidos" USING "btree" ("ds_tipo_despesa");

CREATE INDEX "idx_pad_assuntos" ON "public"."cgu_pad_processos" USING "gin" ("assuntos");

CREATE INDEX "idx_pad_data_inst" ON "public"."cgu_pad_processos" USING "btree" ("data_instauracao" DESC NULLS LAST);

CREATE INDEX "idx_pad_entidade_tsvec" ON "public"."cgu_pad_processos" USING "gin" ("to_tsvector"('"portuguese"'::"regconfig", ((COALESCE("entidade", ''::"text") || ' '::"text") || COALESCE("pasta", ''::"text"))));

CREATE INDEX "idx_pad_expulsiva" ON "public"."cgu_pad_processos" USING "btree" ("tem_expulsiva") WHERE ("tem_expulsiva" = true);

CREATE INDEX "idx_pad_fase" ON "public"."cgu_pad_processos" USING "btree" ("fase_atual");

CREATE INDEX "idx_pad_tipo" ON "public"."cgu_pad_processos" USING "btree" ("tipo_processo");

CREATE INDEX "idx_pad_uf" ON "public"."cgu_pad_processos" USING "btree" ("uf");

CREATE INDEX "idx_parl_est_ativo" ON "public"."parlamentares_estaduais" USING "btree" ("ativo");

CREATE INDEX "idx_parl_est_casa" ON "public"."parlamentares_estaduais" USING "btree" ("casa_id");

CREATE INDEX "idx_parl_est_casa_legislatura" ON "public"."parlamentares_estaduais" USING "btree" ("casa_id", "legislatura");

CREATE INDEX "idx_parl_est_nome" ON "public"."parlamentares_estaduais" USING "btree" ("nome");

CREATE INDEX "idx_parl_est_partido" ON "public"."parlamentares_estaduais" USING "btree" ("partido");

CREATE INDEX "idx_parl_intel_parlamentar_id" ON "public"."parlamentar_inteligencia" USING "btree" ("parlamentar_id");

CREATE INDEX "idx_parl_nome_trgm" ON "public"."parlamentares" USING "gin" ("nome_parlamentar" "public"."gin_trgm_ops");

CREATE INDEX "idx_patrimonio_cpf" ON "public"."patrimonio_tse" USING "btree" ("cpf");

CREATE INDEX "idx_patrimonio_parlamentar" ON "public"."patrimonio_tse" USING "btree" ("parlamentar_id");

CREATE INDEX "idx_pbh_desp_ano" ON "public"."pbh_despesas_orcamentarias" USING "btree" ("ano_exercicio");

CREATE INDEX "idx_pbh_desp_cnpj" ON "public"."pbh_despesas_orcamentarias" USING "btree" ("cnpj_cpf_credor");

CREATE INDEX "idx_pbh_desp_credor" ON "public"."pbh_despesas_orcamentarias" USING "btree" ("nome_credor");

CREATE INDEX "idx_pbh_desp_emenda" ON "public"."pbh_despesas_orcamentarias" USING "btree" ("numero_emenda");

CREATE INDEX "idx_pbh_desp_empenho" ON "public"."pbh_despesas_orcamentarias" USING "btree" ("numero_empenho");

CREATE INDEX "idx_pbh_desp_fonte" ON "public"."pbh_despesas_orcamentarias" USING "btree" ("fonte");

CREATE INDEX "idx_pgfn_cnpj_ciclo" ON "public"."pgfn_divida_ativa" USING "btree" ("cpf_cnpj", "ciclo");

CREATE INDEX "idx_pgfn_situacao" ON "public"."pgfn_divida_ativa" USING "btree" ("situacao", "ciclo");

CREATE INDEX "idx_pipeline_logs_run" ON "public"."data_pipeline_logs" USING "btree" ("pipeline_run_id");

CREATE INDEX "idx_pipeline_logs_time" ON "public"."data_pipeline_logs" USING "btree" ("executed_at" DESC);

CREATE INDEX "idx_plen_dep_agg_partido" ON "public"."plen_deputado_agg" USING "btree" ("sigla_partido");

CREATE INDEX "idx_plen_dep_agg_posicao" ON "public"."plen_deputado_agg" USING "btree" ("posicao");

CREATE INDEX "idx_plen_dep_agg_presenca" ON "public"."plen_deputado_agg" USING "btree" ("pct_presenca" DESC);

CREATE INDEX "idx_plen_orientacoes_bancada" ON "public"."plen_orientacoes" USING "btree" ("sigla_bancada");

CREATE INDEX "idx_plen_orientacoes_votacao" ON "public"."plen_orientacoes" USING "btree" ("votacao_id");

CREATE INDEX "idx_plen_votacoes_aprovacao" ON "public"."plen_votacoes" USING "btree" ("aprovacao");

CREATE INDEX "idx_plen_votacoes_data" ON "public"."plen_votacoes" USING "btree" ("data" DESC);

CREATE INDEX "idx_plen_votacoes_legislatura" ON "public"."plen_votacoes" USING "btree" ("id_legislatura");

CREATE INDEX "idx_plen_votos_deputado" ON "public"."plen_votos" USING "btree" ("deputado_id");

CREATE INDEX "idx_plen_votos_partido" ON "public"."plen_votos" USING "btree" ("sigla_partido");

CREATE INDEX "idx_plen_votos_tipo" ON "public"."plen_votos" USING "btree" ("tipo_voto");

CREATE INDEX "idx_plen_votos_votacao" ON "public"."plen_votos" USING "btree" ("votacao_id");

CREATE INDEX "idx_pncp_data_pub" ON "public"."pncp_licitacoes" USING "btree" ("data_publicacao_pncp");

CREATE INDEX "idx_pncp_emenda" ON "public"."pncp_licitacoes" USING "btree" ("emenda_parlamentar") WHERE ("emenda_parlamentar" = true);

CREATE INDEX "idx_pncp_modalidade" ON "public"."pncp_licitacoes" USING "btree" ("modalidade_id");

CREATE INDEX "idx_pncp_orgao_cnpj" ON "public"."pncp_licitacoes" USING "btree" ("orgao_cnpj");

CREATE INDEX "idx_pncp_pub_ano" ON "public"."pncp_publicidade" USING "btree" ("ano_contrato");

CREATE INDEX "idx_pncp_pub_fornecedor" ON "public"."pncp_publicidade" USING "btree" ("cnpj_fornecedor");

CREATE INDEX "idx_pncp_pub_objeto" ON "public"."pncp_publicidade" USING "gin" ("to_tsvector"('"portuguese"'::"regconfig", "objeto_contrato"));

CREATE INDEX "idx_pncp_pub_orgao" ON "public"."pncp_publicidade" USING "btree" ("cnpj_orgao");

CREATE INDEX "idx_pncp_pub_uf" ON "public"."pncp_publicidade" USING "btree" ("uf_orgao");

CREATE INDEX "idx_pncp_res_compra" ON "public"."pncp_resultados" USING "btree" ("numero_controle_pncp_compra");

CREATE INDEX "idx_pncp_res_data" ON "public"."pncp_resultados" USING "btree" ("data_resultado_pncp");

CREATE INDEX "idx_pncp_res_fornecedor" ON "public"."pncp_resultados" USING "btree" ("ni_fornecedor");

CREATE INDEX "idx_pncp_res_orgao_cnpj" ON "public"."pncp_resultados" USING "btree" ("orgao_cnpj");

CREATE INDEX "idx_pncp_res_uf" ON "public"."pncp_resultados" USING "btree" ("uf");

CREATE INDEX "idx_pncp_res_valor" ON "public"."pncp_resultados" USING "btree" ("valor_total_homologado");

CREATE INDEX "idx_pncp_situacao" ON "public"."pncp_licitacoes" USING "btree" ("situacao_id");

CREATE INDEX "idx_pncp_uf" ON "public"."pncp_licitacoes" USING "btree" ("uf");

CREATE INDEX "idx_pncp_valor" ON "public"."pncp_licitacoes" USING "btree" ("valor_estimado");

CREATE INDEX "idx_ranking_cache_indice" ON "public"."ranking_cache" USING "btree" ("indice_poder_parlamentar" DESC);

CREATE INDEX "idx_ranking_cache_parlamentar" ON "public"."ranking_cache" USING "btree" ("parlamentar_uid");

CREATE INDEX "idx_ranking_cache_posicao" ON "public"."ranking_cache" USING "btree" ("posicao");

CREATE INDEX "idx_ranking_cache_posicao_nacional" ON "public"."ranking_cache" USING "btree" ("posicao_nacional");

CREATE INDEX "idx_ranking_parlamentar_ano" ON "public"."ranking_parlamentar" USING "btree" ("ano");

CREATE INDEX "idx_ranking_parlamentar_build_build" ON "public"."ranking_parlamentar_build" USING "btree" ("build_id");

CREATE INDEX "idx_ranking_parlamentar_build_parlamentar_ano" ON "public"."ranking_parlamentar_build" USING "btree" ("parlamentar_id", "ano");

CREATE INDEX "idx_ranking_parlamentar_posicao_ano" ON "public"."ranking_parlamentar" USING "btree" ("ano", "posicao");

CREATE INDEX "idx_ranking_snapshot_calculation_date" ON "public"."ranking_snapshot" USING "btree" ("calculation_date" DESC);

CREATE INDEX "idx_ranking_snapshot_snapshot_id" ON "public"."ranking_snapshot" USING "btree" ("snapshot_id");

CREATE INDEX "idx_repasses_exercicio" ON "public"."fundacoes_repasses" USING "btree" ("aa_exercicio");

CREATE INDEX "idx_repasses_fts" ON "public"."fundacoes_repasses" USING "gin" ("to_tsvector"('"portuguese"'::"regconfig", ((COALESCE("nm_fundacao", ''::"text") || ' '::"text") || COALESCE("ds_gasto", ''::"text"))));

CREATE INDEX "idx_repasses_fundacao" ON "public"."fundacoes_repasses" USING "btree" ("cnpj_fundacao", "aa_exercicio");

CREATE INDEX "idx_repasses_pagamento" ON "public"."fundacoes_repasses" USING "btree" ("dt_pagamento");

CREATE INDEX "idx_repasses_partido" ON "public"."fundacoes_repasses" USING "btree" ("sg_partido", "aa_exercicio");

CREATE INDEX "idx_repasses_tipo" ON "public"."fundacoes_repasses" USING "btree" ("tipo_repasse");

CREATE INDEX "idx_risco_partido" ON "public"."cam_parlamentar_risco" USING "btree" ("sigla_partido");

CREATE INDEX "idx_risco_score" ON "public"."cam_parlamentar_risco" USING "btree" ("score_total" DESC);

CREATE INDEX "idx_risco_uf" ON "public"."cam_parlamentar_risco" USING "btree" ("sigla_uf");

CREATE INDEX "idx_rp9_apoiamento_ano" ON "public"."emendas_rp9_apoiamento" USING "btree" ("ano_emenda");

CREATE INDEX "idx_rp9_apoiamento_apoiador" ON "public"."emendas_rp9_apoiamento" USING "btree" ("nome_apoiador");

CREATE INDEX "idx_rp9_apoiamento_cnpj" ON "public"."emendas_rp9_apoiamento" USING "btree" ("cnpj_favorecido");

CREATE INDEX "idx_rp9_apoiamento_emenda" ON "public"."emendas_rp9_apoiamento" USING "btree" ("numero_emenda");

CREATE INDEX "idx_rp9_apoiamento_orgao" ON "public"."emendas_rp9_apoiamento" USING "btree" ("orgao_uge_codigo");

CREATE INDEX "idx_sancionados_ativo" ON "public"."portal_sancionados" USING "btree" ("ativo");

CREATE INDEX "idx_sancionados_cpf_cnpj" ON "public"."portal_sancionados" USING "btree" ("cpf_cnpj");

CREATE INDEX "idx_sancionados_tipo" ON "public"."portal_sancionados" USING "btree" ("tipo_registro");

CREATE INDEX "idx_sancoes_cadastro_data" ON "public"."sancoes" USING "btree" ("cadastro", "data_inicio", "data_fim");

CREATE INDEX "idx_sancoes_cpf_cnpj" ON "public"."sancoes" USING "btree" ("cpf_cnpj") WHERE ("cpf_cnpj" IS NOT NULL);

CREATE INDEX "idx_sancoes_nome" ON "public"."sancoes" USING "gin" ("to_tsvector"('"portuguese"'::"regconfig", ((COALESCE("nome", ''::"text") || ' '::"text") || COALESCE("razao_social", ''::"text"))));

CREATE INDEX "idx_scores_indice" ON "public"."scores" USING "btree" ("indice_geral" DESC);

CREATE INDEX "idx_scores_inst" ON "public"."scores" USING "btree" ("institution_id");

CREATE INDEX "idx_scores_obs" ON "public"."scores" USING "btree" ("observatorio_id");

CREATE UNIQUE INDEX "idx_scores_unique" ON "public"."scores" USING "btree" ("institution_id", "observatorio_id", "dimensao");

CREATE INDEX "idx_sebrae_contratos_ano" ON "public"."sebrae_contratos" USING "btree" ("ano");

CREATE INDEX "idx_sebrae_contratos_cnpj" ON "public"."sebrae_contratos" USING "btree" ("cnpj_cpf");

CREATE INDEX "idx_sebrae_contratos_uf" ON "public"."sebrae_contratos" USING "btree" ("uf");

CREATE INDEX "idx_sebrae_convenios_cnpj" ON "public"."sebrae_convenios" USING "btree" ("cnpj_cpf");

CREATE INDEX "idx_sebrae_convenios_uf" ON "public"."sebrae_convenios" USING "btree" ("uf");

CREATE INDEX "idx_sebrae_licitacoes_cnpj" ON "public"."sebrae_licitacoes" USING "btree" ("cnpj_fornecedor");

CREATE INDEX "idx_sebrae_licitacoes_uf" ON "public"."sebrae_licitacoes" USING "btree" ("uf");

CREATE INDEX "idx_secom_verbas_ano_mes" ON "public"."midia_secom_verbas" USING "btree" ("ano", "mes");

CREATE INDEX "idx_secom_verbas_cnpj" ON "public"."midia_secom_verbas" USING "btree" ("cnpj");

CREATE INDEX "idx_secom_verbas_veiculo" ON "public"."midia_secom_verbas" USING "btree" ("veiculo_id");

CREATE INDEX "idx_sen_senadores_nome" ON "public"."sen_senadores" USING "btree" ("nome_norm") WHERE ("nome_norm" IS NOT NULL);

CREATE INDEX "idx_senac_contratos_cnpj" ON "public"."senac_contratos" USING "btree" ("cnpj_cpf");

CREATE INDEX "idx_senac_contratos_regional" ON "public"."senac_contratos" USING "btree" ("regional");

CREATE INDEX "idx_senac_contratos_tipo" ON "public"."senac_contratos" USING "btree" ("tipo");

CREATE INDEX "idx_senac_licitacoes_regional" ON "public"."senac_licitacoes" USING "btree" ("regional");

CREATE INDEX "idx_senado_ceaps_ano_mes" ON "public"."senado_ceaps_despesa" USING "btree" ("ano", "mes");

CREATE INDEX "idx_senado_ceaps_cnpj" ON "public"."senado_ceaps_despesa" USING "btree" ("cpf_cnpj") WHERE (("cpf_cnpj" IS NOT NULL) AND ("cpf_cnpj" <> ''::"text"));

CREATE INDEX "idx_senado_ceaps_senador" ON "public"."senado_ceaps_despesa" USING "btree" ("cod_senador");

CREATE INDEX "idx_senado_ceaps_tipo" ON "public"."senado_ceaps_despesa" USING "btree" ("tipo_despesa");

CREATE INDEX "idx_senado_ori_partido" ON "public"."senado_orientacao" USING "btree" ("sigla_partido");

CREATE INDEX "idx_senado_vot_data" ON "public"."senado_votacao" USING "btree" ("data_sessao");

CREATE INDEX "idx_senado_vot_materia" ON "public"."senado_votacao" USING "btree" ("cod_materia") WHERE ("cod_materia" IS NOT NULL);

CREATE INDEX "idx_senado_vot_resultado" ON "public"."senado_votacao" USING "btree" ("resultado");

CREATE INDEX "idx_senado_voto_parl" ON "public"."senado_voto" USING "btree" ("cod_parlamentar");

CREATE INDEX "idx_senado_voto_partido" ON "public"."senado_voto" USING "btree" ("sigla_partido");

CREATE INDEX "idx_senado_voto_voto" ON "public"."senado_voto" USING "btree" ("voto");

CREATE INDEX "idx_senadores_brutas_partido" ON "public"."senadores_brutas" USING "btree" ("sigla_partido");

CREATE INDEX "idx_senadores_brutas_uf" ON "public"."senadores_brutas" USING "btree" ("sigla_uf");

CREATE INDEX "idx_senar_contratos_cnpj" ON "public"."senar_contratos" USING "btree" ("cnpj");

CREATE INDEX "idx_senar_contratos_periodo" ON "public"."senar_contratos" USING "btree" ("periodo_id");

CREATE INDEX "idx_senar_licitacoes_ano" ON "public"."senar_licitacoes" USING "btree" ("ano");

CREATE INDEX "idx_senar_trans_cnpj" ON "public"."senar_transferencias" USING "btree" ("cnpj");

CREATE INDEX "idx_senar_trans_periodo" ON "public"."senar_transferencias" USING "btree" ("periodo_id");

CREATE INDEX "idx_sesc_contratos_ano" ON "public"."sesc_contratos" USING "btree" ("exercicio");

CREATE INDEX "idx_sesc_contratos_cnpj" ON "public"."sesc_contratos" USING "btree" ("cnpj_cpf");

CREATE INDEX "idx_sesc_contratos_portal" ON "public"."sesc_contratos" USING "btree" ("portal");

CREATE INDEX "idx_sesc_convenios_cnpj" ON "public"."sesc_convenios" USING "btree" ("cnpj_cpf");

CREATE INDEX "idx_sesc_convenios_portal" ON "public"."sesc_convenios" USING "btree" ("portal");

CREATE INDEX "idx_siafi_empenho_autor_emenda" ON "public"."siafi_empenho" USING "btree" ("autor_emenda") WHERE ("autor_emenda" <> 'SEM EMENDA'::"text");

CREATE INDEX "idx_siafi_empenho_codigo" ON "public"."siafi_empenho" USING "btree" ("codigo_empenho");

CREATE INDEX "idx_siafi_empenho_convenio" ON "public"."siafi_empenho" USING "btree" ("cod_convenio") WHERE ("cod_convenio" <> ALL (ARRAY[''::"text", '-1'::"text", 'NAO SE APLICA'::"text"]));

CREATE INDEX "idx_siafi_empenho_data_emissao" ON "public"."siafi_empenho" USING "btree" ("data_emissao");

CREATE INDEX "idx_siafi_empenho_favorecido" ON "public"."siafi_empenho" USING "btree" ("cnpj_favorecido");

CREATE INDEX "idx_siafi_empenho_observacao_tsv" ON "public"."siafi_empenho" USING "gin" ("to_tsvector"('"portuguese"'::"regconfig", COALESCE("observacao", ''::"text")));

CREATE INDEX "idx_siafi_empenho_orgao_sup" ON "public"."siafi_empenho" USING "btree" ("cod_orgao_superior");

CREATE INDEX "idx_siafi_empenho_snapshot" ON "public"."siafi_empenho" USING "btree" ("snapshot_date");

CREATE INDEX "idx_siafi_exec_autor_emenda" ON "public"."siafi_execucao_mensal" USING "btree" ("cod_autor_emenda") WHERE ("cod_autor_emenda" <> '-1'::"text");

CREATE INDEX "idx_siafi_exec_competencia" ON "public"."siafi_execucao_mensal" USING "btree" ("competencia");

CREATE INDEX "idx_siafi_exec_orgao_sup" ON "public"."siafi_execucao_mensal" USING "btree" ("cod_orgao_superior");

CREATE INDEX "idx_siafi_exec_programa" ON "public"."siafi_execucao_mensal" USING "btree" ("cod_programa_orcamentario");

CREATE INDEX "idx_siafi_fornecedor_nome" ON "public"."siafi_fornecedor" USING "gin" ("to_tsvector"('"portuguese"'::"regconfig", "nome"));

CREATE INDEX "idx_siafi_fornecedor_tipo" ON "public"."siafi_fornecedor" USING "btree" ("tipo_pessoa");

CREATE INDEX "idx_siafi_item_descricao_tsv" ON "public"."siafi_item_empenho" USING "gin" ("to_tsvector"('"portuguese"'::"regconfig", COALESCE("descricao", ''::"text")));

CREATE INDEX "idx_siafi_item_subelem" ON "public"."siafi_item_empenho" USING "btree" ("cod_subelemento_despesa");

CREATE INDEX "idx_siafi_liq_data_emissao" ON "public"."siafi_liquidacao" USING "btree" ("data_emissao");

CREATE INDEX "idx_siafi_liq_favorecido" ON "public"."siafi_liquidacao" USING "btree" ("cnpj_favorecido");

CREATE INDEX "idx_siafi_liq_snapshot" ON "public"."siafi_liquidacao" USING "btree" ("snapshot_date");

CREATE INDEX "idx_siafi_log_competencia" ON "public"."siafi_ingestao_log" USING "btree" ("competencia");

CREATE INDEX "idx_siafi_log_ingested" ON "public"."siafi_ingestao_log" USING "btree" ("ingested_at" DESC);

CREATE INDEX "idx_siafi_log_status" ON "public"."siafi_ingestao_log" USING "btree" ("status") WHERE ("status" <> 'ok'::"text");

CREATE INDEX "idx_siafi_log_stream" ON "public"."siafi_ingestao_log" USING "btree" ("stream");

CREATE INDEX "idx_siafi_pag_data_emissao" ON "public"."siafi_pagamento" USING "btree" ("data_emissao");

CREATE INDEX "idx_siafi_pag_favorecido" ON "public"."siafi_pagamento" USING "btree" ("cnpj_favorecido");

CREATE INDEX "idx_siafi_pag_orgao_sup" ON "public"."siafi_pagamento" USING "btree" ("cod_orgao_superior");

CREATE INDEX "idx_siafi_pag_snapshot" ON "public"."siafi_pagamento" USING "btree" ("snapshot_date");

CREATE INDEX "idx_siafi_pe_empenho" ON "public"."siafi_pagamento_empenho" USING "btree" ("codigo_empenho");

CREATE INDEX "idx_siafi_pe_pagamento" ON "public"."siafi_pagamento_empenho" USING "btree" ("codigo_pagamento");

CREATE INDEX "idx_siafi_pff_favorecido" ON "public"."siafi_pagamento_favorecido_final" USING "btree" ("cnpj_favorecido_final");

CREATE INDEX "idx_siafi_pff_pagamento" ON "public"."siafi_pagamento_favorecido_final" USING "btree" ("codigo_pagamento");

CREATE INDEX "idx_sisi_contratos_ano" ON "public"."sisi_contratos" USING "btree" ("ano");

CREATE INDEX "idx_sisi_contratos_cnpj" ON "public"."sisi_contratos" USING "btree" ("cpf_cnpj");

CREATE INDEX "idx_sisi_contratos_depto" ON "public"."sisi_contratos" USING "btree" ("departamento");

CREATE INDEX "idx_sisi_contratos_entidade" ON "public"."sisi_contratos" USING "btree" ("entidade");

CREATE INDEX "idx_sisi_convenios_ano" ON "public"."sisi_convenios" USING "btree" ("ano");

CREATE INDEX "idx_sisi_convenios_cnpj" ON "public"."sisi_convenios" USING "btree" ("cnpj");

CREATE INDEX "idx_sisi_convenios_depto" ON "public"."sisi_convenios" USING "btree" ("departamento");

CREATE INDEX "idx_sisi_convenios_entidade" ON "public"."sisi_convenios" USING "btree" ("entidade");

CREATE INDEX "idx_sisi_licitacoes_ano" ON "public"."sisi_licitacoes" USING "btree" ("ano");

CREATE INDEX "idx_sisi_licitacoes_depto" ON "public"."sisi_licitacoes" USING "btree" ("departamento");

CREATE INDEX "idx_sisi_licitacoes_entidade" ON "public"."sisi_licitacoes" USING "btree" ("entidade");

CREATE INDEX "idx_sisi_part_cnpj" ON "public"."sisi_licitacoes_participantes" USING "btree" ("cnpj_cpf");

CREATE INDEX "idx_sisi_part_licitacao" ON "public"."sisi_licitacoes_participantes" USING "btree" ("licitacao_codigo");

CREATE INDEX "idx_snapshots_ranking_ano" ON "public"."snapshots_ranking" USING "btree" ("ano");

CREATE INDEX "idx_snapshots_ranking_build_em" ON "public"."snapshots_ranking" USING "btree" ("build_em" DESC);

CREATE INDEX "idx_sp_contratos_cnpj" ON "public"."sp_contratos" USING "btree" ("cnpj_contratado");

CREATE INDEX "idx_sp_contratos_orgao" ON "public"."sp_contratos" USING "btree" ("orgao");

CREATE INDEX "idx_sp_contratos_valor" ON "public"."sp_contratos" USING "btree" ("valor_global" DESC);

CREATE INDEX "idx_sub_alertas_cnpj" ON "public"."sub_alertas" USING "btree" ("cnpj", "ciclo");

CREATE INDEX "idx_sub_alertas_dossie" ON "public"."sub_alertas" USING "btree" ("dossie_id");

CREATE INDEX "idx_sub_alertas_sev" ON "public"."sub_alertas" USING "btree" ("severidade");

CREATE INDEX "idx_sub_aneel_cnpj" ON "public"."sub_aneel_autos" USING "btree" ("cnpj");

CREATE INDEX "idx_sub_aneel_num" ON "public"."sub_aneel_autos" USING "btree" ("num_auto_infracao");

CREATE INDEX "idx_sub_ans_cnpj" ON "public"."sub_ans_operadoras" USING "btree" ("cnpj");

CREATE INDEX "idx_sub_ans_registro" ON "public"."sub_ans_operadoras" USING "btree" ("registro_ans");

CREATE INDEX "idx_sub_ceis_cnpj" ON "public"."sub_ceis" USING "btree" ("cnpj_cpf");

CREATE INDEX "idx_sub_cepim_cnpj" ON "public"."sub_cepim" USING "btree" ("cnpj");

CREATE INDEX "idx_sub_cnep_cnpj" ON "public"."sub_cnep" USING "btree" ("cnpj_cpf");

CREATE INDEX "idx_sub_cnpjs_cliente" ON "public"."sub_cnpjs_monitorados" USING "btree" ("cliente_id");

CREATE INDEX "idx_sub_cnpjs_cnpj" ON "public"."sub_cnpjs_monitorados" USING "btree" ("cnpj");

CREATE INDEX "idx_sub_cvm_pas_cnpj" ON "public"."sub_cvm_pas" USING "btree" ("cpf_cnpj");

CREATE INDEX "idx_sub_cvm_pas_num" ON "public"."sub_cvm_pas" USING "btree" ("num_pas");

CREATE INDEX "idx_sub_dossies_ciclo" ON "public"."sub_dossies" USING "btree" ("ciclo");

CREATE INDEX "idx_sub_dossies_cnpj" ON "public"."sub_dossies" USING "btree" ("cnpj");

CREATE INDEX "idx_sub_ibama_auto" ON "public"."sub_ibama" USING "btree" ("num_auto_infracao");

CREATE INDEX "idx_sub_ibama_cnpj" ON "public"."sub_ibama" USING "btree" ("cpf_cnpj_infrator");

CREATE INDEX "idx_sub_lista_suja_doc" ON "public"."sub_lista_suja" USING "btree" ("cpf_cnpj");

CREATE INDEX "idx_sub_mte_autos_cnpj" ON "public"."sub_mte_autos" USING "btree" ("cnpj");

CREATE INDEX "idx_sub_mte_autos_num" ON "public"."sub_mte_autos" USING "btree" ("num_ait");

CREATE INDEX "idx_sub_snapshots_lookup" ON "public"."sub_snapshots" USING "btree" ("cnpj", "fonte", "ciclo");

CREATE INDEX "idx_sync_jobs_ano" ON "public"."sync_jobs" USING "btree" ("ano");

CREATE INDEX "idx_sync_jobs_status" ON "public"."sync_jobs" USING "btree" ("status");

CREATE INDEX "idx_ted_planos_ano" ON "public"."ted_planos_acao" USING "btree" ("ano");

CREATE INDEX "idx_ted_planos_situacao" ON "public"."ted_planos_acao" USING "btree" ("situacao");

CREATE INDEX "idx_ted_termos_plano" ON "public"."ted_termos_execucao" USING "btree" ("id_plano_acao");

CREATE INDEX "idx_ted_termos_situacao" ON "public"."ted_termos_execucao" USING "btree" ("situacao");

CREATE INDEX "idx_transf_ano" ON "public"."execucao_financeira_transferencias" USING "btree" ("ano");

CREATE INDEX "idx_transf_favorecido" ON "public"."execucao_financeira_transferencias" USING "btree" ("favorecido");

CREATE INDEX "idx_transf_orgao" ON "public"."execucao_financeira_transferencias" USING "btree" ("orgao");

CREATE INDEX "idx_transf_uf" ON "public"."execucao_financeira_transferencias" USING "btree" ("uf");

CREATE INDEX "idx_tribunais_categoria" ON "public"."tribunais" USING "btree" ("categoria");

CREATE INDEX "idx_tribunais_sigla" ON "public"."tribunais" USING "btree" ("sigla");

CREATE INDEX "idx_tse_agg_ano" ON "public"."tse_candidatos_receitas_agg" USING "btree" ("ano_eleicao");

CREATE INDEX "idx_tse_agg_cargo" ON "public"."tse_candidatos_receitas_agg" USING "btree" ("cd_cargo", "ano_eleicao");

CREATE INDEX "idx_tse_agg_partido" ON "public"."tse_candidatos_receitas_agg" USING "btree" ("sg_partido", "ano_eleicao");

CREATE INDEX "idx_tse_agg_posicao" ON "public"."tse_candidatos_receitas_agg" USING "btree" ("posicao", "ano_eleicao");

CREATE INDEX "idx_tse_agg_total" ON "public"."tse_candidatos_receitas_agg" USING "btree" ("total_receitas" DESC, "ano_eleicao");

CREATE INDEX "idx_tse_agg_uf" ON "public"."tse_candidatos_receitas_agg" USING "btree" ("sg_uf", "ano_eleicao");

CREATE INDEX "idx_tse_bens_agg_patrimonio" ON "public"."tse_bens_agg" USING "btree" ("total_patrimonio" DESC);

CREATE INDEX "idx_tse_bens_ds_tipo" ON "public"."tse_bens_candidatos" USING "btree" ("ds_tipo");

CREATE INDEX "idx_tse_bens_sq" ON "public"."tse_bens_candidatos" USING "btree" ("sq_candidato", "ano_eleicao");

CREATE INDEX "idx_tse_cand_ano_cargo" ON "public"."tse_candidatos" USING "btree" ("ano_eleicao", "cd_cargo");

CREATE INDEX "idx_tse_cand_cpf" ON "public"."tse_candidatos" USING "btree" ("cpf") WHERE ("cpf" IS NOT NULL);

CREATE INDEX "idx_tse_cand_partido" ON "public"."tse_candidatos" USING "btree" ("sigla_partido");

CREATE INDEX "idx_tse_cand_uf" ON "public"."tse_candidatos" USING "btree" ("uf");

CREATE INDEX "idx_tse_desp_ano" ON "public"."tse_despesas" USING "btree" ("ano_eleicao");

CREATE INDEX "idx_tse_desp_cnpj_ano" ON "public"."tse_despesas" USING "btree" ("cpf_cnpj_fornecedor", "ano_eleicao") WHERE ("cpf_cnpj_fornecedor" IS NOT NULL);

CREATE INDEX "idx_tse_desp_cnpj_fornecedor" ON "public"."tse_despesas" USING "btree" ("cpf_cnpj_fornecedor") WHERE ("cpf_cnpj_fornecedor" IS NOT NULL);

CREATE INDEX "idx_tse_desp_cpf_cand" ON "public"."tse_despesas" USING "btree" ("cpf_candidato") WHERE ("cpf_candidato" IS NOT NULL);

CREATE INDEX "idx_tse_desp_tipo" ON "public"."tse_despesas" USING "btree" ("tipo_despesa");

CREATE INDEX "idx_tse_receitas_ano" ON "public"."tse_receitas_brutas" USING "btree" ("ano_eleicao");

CREATE INDEX "idx_tse_receitas_cand" ON "public"."tse_receitas_brutas" USING "btree" ("sq_candidato", "ano_eleicao");

CREATE INDEX "idx_tse_receitas_cargo" ON "public"."tse_receitas_brutas" USING "btree" ("cd_cargo", "ano_eleicao");

CREATE INDEX "idx_tse_receitas_cnpj_doador" ON "public"."tse_receitas" USING "btree" ("cpf_cnpj_doador") WHERE ("cpf_cnpj_doador" IS NOT NULL);

CREATE INDEX "idx_tse_receitas_cpf_cand" ON "public"."tse_receitas" USING "btree" ("cpf_candidato") WHERE ("cpf_candidato" IS NOT NULL);

CREATE INDEX "idx_tse_receitas_doador" ON "public"."tse_receitas_brutas" USING "btree" ("nr_cpf_cnpj_doador");

CREATE INDEX "idx_tse_receitas_fonte" ON "public"."tse_receitas_brutas" USING "btree" ("cd_fonte_receita", "ano_eleicao");

CREATE INDEX "idx_tse_receitas_nome_doador_originario_trgm" ON "public"."tse_receitas" USING "gin" ("nome_doador_originario" "public"."gin_trgm_ops") WHERE ("nome_doador_originario" IS NOT NULL);

CREATE INDEX "idx_tse_receitas_nome_doador_trgm" ON "public"."tse_receitas" USING "gin" ("nome_doador" "public"."gin_trgm_ops") WHERE ("nome_doador" IS NOT NULL);

CREATE INDEX "idx_tse_receitas_partido" ON "public"."tse_receitas_brutas" USING "btree" ("sg_partido", "ano_eleicao");

CREATE UNIQUE INDEX "idx_tse_receitas_recibo_ano" ON "public"."tse_receitas" USING "btree" ("numero_recibo", "ano_eleicao");

CREATE INDEX "idx_tse_receitas_uf" ON "public"."tse_receitas_brutas" USING "btree" ("sg_uf", "ano_eleicao");

CREATE INDEX "idx_usa_contratos_agencia" ON "public"."usa_contratos" USING "btree" ("agencia_codigo");

CREATE INDEX "idx_usa_contratos_beneficiario" ON "public"."usa_contratos" USING "btree" ("beneficiario_nome");

CREATE INDEX "idx_usa_contratos_data_inicio" ON "public"."usa_contratos" USING "btree" ("data_inicio");

CREATE INDEX "idx_usa_contratos_naics" ON "public"."usa_contratos" USING "btree" ("naics_code");

CREATE INDEX "idx_usa_contratos_tipo" ON "public"."usa_contratos" USING "btree" ("tipo");

CREATE INDEX "idx_usa_contratos_valor" ON "public"."usa_contratos" USING "btree" ("valor_obrigado_usd" DESC);

CREATE INDEX "idx_usa_transacoes_award_id" ON "public"."usa_transacoes" USING "btree" ("award_id");

CREATE INDEX "idx_usa_transacoes_data_acao" ON "public"."usa_transacoes" USING "btree" ("data_acao");

CREATE INDEX "idx_usa_transacoes_tipo" ON "public"."usa_transacoes" USING "btree" ("tipo_acao");

CREATE INDEX "idx_user_profiles_stripe_customer_id" ON "public"."user_profiles" USING "btree" ("stripe_customer_id") WHERE ("stripe_customer_id" IS NOT NULL);

CREATE INDEX "idx_vcsa_companhia" ON "public"."voos_senado_companhia_senador_agg" USING "btree" ("companhia");

CREATE INDEX "idx_vcsa_trechos" ON "public"."voos_senado_companhia_senador_agg" USING "btree" ("n_trechos" DESC);

CREATE INDEX "idx_viagens_ano" ON "public"."viagens" USING "btree" ("ano");

CREATE INDEX "idx_viagens_beneficiario" ON "public"."viagens" USING "btree" ("nome_beneficiario");

CREATE INDEX "idx_viagens_destino_uf" ON "public"."viagens" USING "btree" ("destino_uf");

CREATE UNIQUE INDEX "idx_viagens_id_portal" ON "public"."viagens" USING "btree" ("id_portal");

CREATE INDEX "idx_viagens_nome" ON "public"."viagens" USING "btree" ("beneficiario_nome");

CREATE INDEX "idx_viagens_orgao" ON "public"."viagens" USING "btree" ("orgao_codigo");

CREATE INDEX "idx_viagens_origem_uf" ON "public"."viagens" USING "btree" ("origem_uf");

CREATE INDEX "idx_viagens_parlamentar" ON "public"."viagens" USING "btree" ("parlamentar_id");

CREATE INDEX "idx_viagens_pcdp" ON "public"."viagens" USING "btree" ("pcdp");

CREATE INDEX "idx_viagens_periodo" ON "public"."viagens" USING "btree" ("data_inicio");

CREATE INDEX "idx_voos_cam_comp_agg_ano" ON "public"."voos_camara_companhia_agg" USING "btree" ("ano");

CREATE INDEX "idx_voos_cam_comp_agg_gasto" ON "public"."voos_camara_companhia_agg" USING "btree" ("total_gasto" DESC);

CREATE INDEX "idx_voos_cam_dep_agg_ano" ON "public"."voos_camara_deputado_agg" USING "btree" ("ano");

CREATE INDEX "idx_voos_cam_dep_agg_gasto" ON "public"."voos_camara_deputado_agg" USING "btree" ("total_gasto" DESC);

CREATE INDEX "idx_voos_comp_agg_ano" ON "public"."voos_senado_companhia_agg" USING "btree" ("ano");

CREATE INDEX "idx_voos_comp_agg_gasto" ON "public"."voos_senado_companhia_agg" USING "btree" ("total_gasto" DESC);

CREATE INDEX "idx_voos_parl_agg_ano" ON "public"."voos_senado_parlamentar_agg" USING "btree" ("ano");

CREATE INDEX "idx_voos_parl_agg_gasto" ON "public"."voos_senado_parlamentar_agg" USING "btree" ("total_gasto" DESC);

CREATE INDEX "idx_voos_senado_ano" ON "public"."voos_senado" USING "btree" ("ano");

CREATE INDEX "idx_voos_senado_companhia" ON "public"."voos_senado" USING "btree" ("companhia");

CREATE INDEX "idx_voos_senado_doc" ON "public"."voos_senado" USING "btree" ("cod_documento");

CREATE INDEX "idx_voos_senado_senador" ON "public"."voos_senado" USING "btree" ("senador_normalizado");

CREATE INDEX "idx_voos_senado_terceiro" ON "public"."voos_senado" USING "btree" ("eh_parlamentar");

CREATE INDEX "idx_voos_terc_agg_trechos" ON "public"."voos_senado_terceiros_agg" USING "btree" ("n_trechos" DESC);

CREATE INDEX "idx_votacoes_brutas_deputado" ON "public"."votacoes_brutas" USING "btree" ("deputado_id_externo");

CREATE INDEX "idx_votacoes_brutas_votacao" ON "public"."votacoes_brutas" USING "btree" ("id_votacao");

CREATE INDEX "idx_votacoes_orientacoes_bancada" ON "public"."votacoes_orientacoes" USING "btree" ("sigla_bancada");

CREATE INDEX "idx_votacoes_orientacoes_data" ON "public"."votacoes_orientacoes" USING "btree" ("data_votacao");

CREATE INDEX "idx_votacoes_orientacoes_votacao" ON "public"."votacoes_orientacoes" USING "btree" ("votacao_id");

CREATE INDEX "idx_votacoes_senado_parlamentar" ON "public"."votacoes_senado" USING "btree" ("parlamentar_id");

CREATE INDEX "idx_vra_companhia" ON "public"."voos_senado_rota_agg" USING "btree" ("companhia");

CREATE INDEX "idx_vra_trechos" ON "public"."voos_senado_rota_agg" USING "btree" ("n_trechos" DESC);

CREATE INDEX "idx_yt_evento" ON "public"."midia_youtube_eventos" USING "btree" ("evento_id");

CREATE INDEX "idx_yt_veiculo" ON "public"."midia_youtube_eventos" USING "btree" ("veiculo_id");

CREATE INDEX "ix_despesa_exerc_uf" ON "public"."tse_conta_despesa" USING "btree" ("aa_exercicio", "sg_uf");

CREATE INDEX "ix_despesa_forn" ON "public"."tse_conta_despesa" USING "btree" ("cpf_cnpj_fornecedor");

CREATE INDEX "ix_despesa_prest" ON "public"."tse_conta_despesa" USING "btree" ("cnpj_prestador");

CREATE INDEX "ix_extrato_contrap" ON "public"."tse_conta_extrato" USING "btree" ("cpf_cnpj_contraparte");

CREATE INDEX "ix_extrato_partido" ON "public"."tse_conta_extrato" USING "btree" ("cnpj_partido");

CREATE INDEX "ix_extrato_ref" ON "public"."tse_conta_extrato" USING "btree" ("aa_referencia");

CREATE INDEX "ix_nf_forn" ON "public"."tse_conta_notafiscal" USING "btree" ("cpf_cnpj_fornecedor");

CREATE INDEX "ix_nf_prest_sq" ON "public"."tse_conta_notafiscal" USING "btree" ("cnpj_prestador", "sq_despesa");

CREATE INDEX "ix_parlamentar_identidade_fonte" ON "public"."parlamentar_identidade" USING "btree" ("fonte_orcamentaria_id");

CREATE INDEX "ix_parlamentar_identidade_id_camara" ON "public"."parlamentar_identidade" USING "btree" ("id_camara");

CREATE INDEX "ix_parlamentar_identidade_id_senado" ON "public"."parlamentar_identidade" USING "btree" ("id_senado");

CREATE INDEX "ix_receita_doador" ON "public"."tse_conta_receita" USING "btree" ("cpf_cnpj_doador");

CREATE INDEX "ix_receita_exerc_uf" ON "public"."tse_conta_receita" USING "btree" ("aa_exercicio", "sg_uf");

CREATE INDEX "ix_receita_prest" ON "public"."tse_conta_receita" USING "btree" ("cnpj_prestador");

CREATE INDEX "ix_sen_proposicoes_codigo" ON "public"."sen_proposicoes" USING "btree" ("senador_codigo");

CREATE INDEX "licit_part_cnpj_idx" ON "public"."licitacoes_participantes" USING "btree" ("cnpj");

CREATE INDEX "licit_part_licitacao_idx" ON "public"."licitacoes_participantes" USING "btree" ("licitacao_id");

CREATE INDEX "licitacoes_data_publicacao_idx" ON "public"."licitacoes" USING "btree" ("data_publicacao");

CREATE INDEX "licitacoes_modalidade_idx" ON "public"."licitacoes" USING "btree" ("modalidade_codigo");

CREATE INDEX "licitacoes_orgao_idx" ON "public"."licitacoes" USING "btree" ("orgao_codigo");

CREATE INDEX "mg_contratos_ano_idx" ON "public"."mg_contratos" USING "btree" ("ano_assinatura");

CREATE INDEX "mg_contratos_cnpj_idx" ON "public"."mg_contratos" USING "btree" ("cnpj_cpf_fornecedor");

CREATE INDEX "mg_contratos_proc_idx" ON "public"."mg_contratos" USING "btree" ("procedimento_contratacao");

CREATE INDEX "mg_empenhos_ano_idx" ON "public"."mg_empenhos" USING "btree" ("ano_exercicio");

CREATE INDEX "mg_empenhos_cnpj_idx" ON "public"."mg_empenhos" USING "btree" ("cnpj_cpf_credor");

CREATE INDEX "mg_empenhos_elemento_idx" ON "public"."mg_empenhos" USING "btree" ("elemento_despesa_codigo");

CREATE INDEX "mg_empenhos_uo_idx" ON "public"."mg_empenhos" USING "btree" ("unidade_orcamentaria_codigo");

CREATE UNIQUE INDEX "mv_siafi_fornecedores_pk" ON "public"."mv_siafi_fornecedores" USING "btree" ("cnpj_favorecido", "nome_favorecido");

CREATE INDEX "mv_siafi_fornecedores_valor" ON "public"."mv_siafi_fornecedores" USING "btree" ("valor_total" DESC);

CREATE INDEX "mv_tse_ads_digitais_idx" ON "public"."mv_tse_ads_digitais" USING "btree" ("cpf_candidato", "plataforma", "ano_eleicao");

CREATE UNIQUE INDEX "mv_tse_ads_digitais_pk" ON "public"."mv_tse_ads_digitais" USING "btree" (COALESCE("cpf_candidato", ''::"text"), "ano_eleicao", "plataforma");

CREATE INDEX "nf_data_emissao_idx" ON "public"."notas_fiscais" USING "btree" ("data_emissao");

CREATE INDEX "nf_destinatario_cnpj_idx" ON "public"."notas_fiscais" USING "btree" ("destinatario_cnpj");

CREATE INDEX "nf_emitente_cnpj_idx" ON "public"."notas_fiscais" USING "btree" ("emitente_cnpj");

CREATE INDEX "nf_emitente_uf_idx" ON "public"."notas_fiscais" USING "btree" ("emitente_uf");

CREATE INDEX "peps_cpf_idx" ON "public"."peps" USING "btree" ("cpf");

CREATE INDEX "peps_data_inicio_idx" ON "public"."peps" USING "btree" ("data_inicio_exercicio");

CREATE INDEX "peps_nome_idx" ON "public"."peps" USING "gin" ("to_tsvector"('"portuguese"'::"regconfig", COALESCE("nome", ''::"text")));

CREATE INDEX "pgfn_div_fed_cnpj" ON "public"."pgfn_divida_federacoes" USING "btree" ("cnpj");

CREATE INDEX "pgfn_div_fed_trimestre" ON "public"."pgfn_divida_federacoes" USING "btree" ("trimestre");

CREATE INDEX "pr_exp_ano_idx" ON "public"."pr_ex_presidentes_custos" USING "btree" ("ano_emissao");

CREATE INDEX "pr_exp_grupo_idx" ON "public"."pr_ex_presidentes_custos" USING "btree" ("grupo_despesa_nome");

CREATE INDEX "pr_exp_nat_idx" ON "public"."pr_ex_presidentes_custos" USING "btree" ("natureza_despesa_nome");

CREATE INDEX "pr_exp_slug_idx" ON "public"."pr_ex_presidentes_custos" USING "btree" ("ex_presidente_slug");

CREATE INDEX "pr_pessoal_dimensao_idx" ON "public"."pr_pessoal_diversidade" USING "btree" ("dimensao");

CREATE INDEX "pr_pessoal_orgao_idx" ON "public"."pr_pessoal_diversidade" USING "btree" ("orgao");

CREATE INDEX "pr_pessoal_periodo_idx" ON "public"."pr_pessoal_diversidade" USING "btree" ("periodo");

CREATE INDEX "rs_despesas_ano_idx" ON "public"."rs_despesas" USING "btree" ("ano_exercicio");

CREATE INDEX "rs_despesas_cnpj_idx" ON "public"."rs_despesas" USING "btree" ("cnpj");

CREATE INDEX "rs_despesas_fase_idx" ON "public"."rs_despesas" USING "btree" ("fase_gasto");

CREATE INDEX "rs_despesas_municipio_idx" ON "public"."rs_despesas" USING "btree" ("municipio");

CREATE INDEX "sp_despesas_ano_orgao_idx" ON "public"."sp_despesas" USING "btree" ("ano", "cod_orgao");

CREATE INDEX "sp_despesas_cnpj_credor_idx" ON "public"."sp_despesas" USING "btree" ("cnpj_credor");

CREATE INDEX "sp_despesas_cod_credor_idx" ON "public"."sp_despesas" USING "btree" ("cod_credor");

CREATE INDEX "stf_gastos_ministro_id_ano_mes_idx" ON "public"."stf_gastos" USING "btree" ("ministro_id", "ano", "mes");

CREATE INDEX "stf_votacoes_ministro_id_data_idx" ON "public"."stf_votacoes" USING "btree" ("ministro_id", "data" DESC);

CREATE INDEX "sub_cnpjs_cliente_idx" ON "public"."sub_cnpjs_monitorados" USING "btree" ("cliente_id");

CREATE INDEX "subscriptions_status_idx" ON "public"."subscriptions" USING "btree" ("status");

CREATE INDEX "subscriptions_stripe_customer_idx" ON "public"."subscriptions" USING "btree" ("stripe_customer_id");

CREATE INDEX "subscriptions_stripe_sub_idx" ON "public"."subscriptions" USING "btree" ("stripe_subscription_id");

CREATE UNIQUE INDEX "timeline_unique_event" ON "public"."timeline_events" USING "btree" ("reference_table", "reference_id", "event_type");

CREATE INDEX "tse_despesas_ano_idx" ON "public"."tse_despesas" USING "btree" ("ano_eleicao");

CREATE UNIQUE INDEX "uq_jud_stats_ano_tribunal" ON "public"."judiciario_stats_por_ano_tribunal" USING "btree" ("tribunal_id", "ano");

CREATE UNIQUE INDEX "uq_jud_stats_classe_tribunal" ON "public"."judiciario_stats_por_classe_tribunal" USING "btree" ("tribunal_id", "classe");

CREATE UNIQUE INDEX "uq_jud_stats_relator" ON "public"."judiciario_stats_por_relator" USING "btree" ("tribunal_id", "relator");

CREATE UNIQUE INDEX "uq_jud_stats_tribunal" ON "public"."judiciario_stats_por_tribunal" USING "btree" ("tribunal_id");

CREATE UNIQUE INDEX "ux_parlamentar_identidade_parlamentar_id" ON "public"."parlamentar_identidade" USING "btree" ("parlamentar_id");
-- bloco 11_triggers — gerado por split_baseline.py (ordem interna = ordem do dump)
CREATE OR REPLACE TRIGGER "trg_cases_updated_at" BEFORE UPDATE ON "cidadania_ai"."cases" FOR EACH ROW EXECUTE FUNCTION "cidadania_ai"."set_updated_at"();

CREATE OR REPLACE TRIGGER "trg_library_docs_updated_at" BEFORE UPDATE ON "cidadania_ai"."library_docs" FOR EACH ROW EXECUTE FUNCTION "cidadania_ai"."set_updated_at"();

CREATE OR REPLACE TRIGGER "trg_set_cnpjs_limit" BEFORE INSERT OR UPDATE ON "public"."subscriptions" FOR EACH ROW EXECUTE FUNCTION "public"."set_cnpjs_limit"();
-- bloco 12_rls — gerado por split_baseline.py (ordem interna = ordem do dump)
ALTER TABLE "bcb"."if_balanco" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "bcb"."if_cadastro" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "bcb"."scr_operacoes" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "bcb"."sicor_credito_rural" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "cidadania_ai"."cases" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "cidadania_ai"."generated_docs" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "cidadania_ai"."library_docs" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "cidadania_ai"."messages" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "homabrasil"."desastres_historico" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "homabrasil"."homa_score" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "homabrasil"."infraestrutura" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "homabrasil"."municipios" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "homabrasil"."qualidade_vida" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "homabrasil"."risco_climatico" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "portal_transparencia"."cartoes_pagamento" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "portal_transparencia"."favorecidos" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "portal_transparencia"."ingest_runs" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "portal_transparencia"."notas_fiscais" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "portal_transparencia"."notas_fiscais_itens" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "portal_transparencia"."sancoes" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."agenda_camara_eventos" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."agenda_executivo_compromissos" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."agenda_ingest_log" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."agenda_senado_comissoes" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."agenda_senado_plenario" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."ale_casas" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."ale_ingest_runs" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."ale_parlamentares" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."ale_proposicoes" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."ale_votacoes" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."ale_votos" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."alertas_processo" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."alerts_history" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."alesc_despesas" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."ask_quota" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."authority_metrics" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."auto_briefings" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."autores_orcamentarios" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."b3_empresas_listadas" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."b3_tickers" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."banks" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."cam_parlamentar_risco" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."cam_proposicoes" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."cam_proposicoes_agg" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."camara_frente" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."camara_frente_membro" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."camara_ocupacao" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."cambio_cotacoes" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."cambio_moedas" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."casas" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."cbf_cnpjs_vinculados" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."cbf_socios_federacoes" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."ceaf_expulsoes" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."ceaf_ingest_log" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."ceaps_ranking" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."ceaps_senado_ranking" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."cgu_pad_ingest_log" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."cgu_pad_processos" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."cnes_estabelecimentos" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."cnpj_empresas" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."cnpj_enriquecido" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."cnpj_ingest_log" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."codigos_acesso" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."comissoes_senado" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."contratos_federais" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."contratos_ingest_log" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."cota_cnpj_lookup" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."cota_deputado" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."cota_despesa" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."cpgf_transacoes" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."cptec_cidades" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."cron_execution_log" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."cvm_acusados" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."cvm_corretoras" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."cvm_fundos" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."cvm_ingest_log" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."cvm_processos" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."discursos_camara" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."discursos_senado" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."ele2026_alertas" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."ele2026_candidatos" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."ele2026_financiamento" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."ele2026_gastos" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."ele2026_ingest_log" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."emendas_api" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."emendas_api_documentos" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."emendas_api_ingest_log" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."emendas_completas" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."emendas_favorecidos" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."emendas_rp9_apoiamento" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."execucao_financeira_siafi" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."execucao_financeira_transferencias" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."financiamento_eleitoral" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."fipe_tabelas" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."folha_doador_leads" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."folha_gabinete" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."folha_nepotismo_leads" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."gastos_parlamentares" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."glossario_tech" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."ibama_autuacoes" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."ibge_indicadores" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."ibge_municipios" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."impacto_federativo" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."indicadores" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."indicadores_macroeconomicos" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."institutions" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."intelligence_notes" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."judiciario_highlights" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."judiciario_processos" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."leiloes_leiloeiros" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."leiloes_processos" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."licitacoes" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."licitacoes_ingest_log" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."licitacoes_participantes" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."media_briefings" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."mg_contratos" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."mg_convenios" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."mg_convenios_entrada" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."mg_covid_compras" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."mg_diarias_orgao" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."mg_doacoes" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."mg_emendas_estaduais" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."mg_emendas_federais" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."mg_emendas_pix" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."mg_empenhos" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."mg_empenhos_sancionados" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."mg_empresas_sancionadas" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."mg_ingest_log" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."mg_lrf_limites" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."mg_lrf_pessoal" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."mg_obras" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."mg_os_parcerias" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."mg_reparacao_vale" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."mg_restos_orgao" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."mg_siafi_execucao" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."mg_terceirizados" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."mg_voos_governador" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."midia_eventos" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."midia_inter_meios" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."midia_kantar_releases" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."midia_secom_verbas" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."midia_veiculos" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."midia_youtube_eventos" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."municipios_ibge" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."narrativas" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."ncm" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."newsletter_sends" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."newsletter_subscribers" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."notas_fiscais" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."notas_fiscais_ingest_log" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."observatorios" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."parlamentar_contratos_cache" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."parlamentar_financiamento_cache" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."parlamentar_inteligencia" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."parlamentar_sancoes_cache" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."parlamentares" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."parlamentares_estaduais" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."pbh_despesas_orcamentarias" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."peps" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."peps_ingest_log" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."pgfn_divida_federacoes" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."pix_participantes" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."plen_deputado_agg" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."pncp_publicidade" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."portal_sancionados" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."pr_ex_presidentes_custos" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."pr_ingest_log" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."pr_pessoal_diversidade" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."ranking_cache" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."ranking_parlamentar" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."rs_despesas" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."rs_ingest_log" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."sancoes" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."sancoes_ingest_log" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."scores" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."sebrae_contratos" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."sebrae_convenios" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."sebrae_emendas_contratos" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."sebrae_emendas_convenios" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."sebrae_licitacoes" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."sebrae_patrocinios" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."sen_parlamentar_risco" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."sen_proposicoes" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."senado_ceaps_despesa" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."senado_orientacao" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."senado_votacao" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."senado_voto" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."siafi_empenho" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."siafi_execucao_mensal" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."siafi_fornecedor" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."siafi_ingestao_log" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."siafi_item_empenho" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."siafi_liquidacao" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."siafi_pagamento" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."siafi_pagamento_empenho" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."siafi_pagamento_favorecido_final" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."sp_despesas" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."stf_assinaturas" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."stf_ingestao_log" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."sub_alertas" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."sub_clientes" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."sub_cnpjs_monitorados" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."sub_dossies" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."sub_envios" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."sub_pf_consultas" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."sub_snapshots" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."subscriptions" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."tribunais" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."tse_bens_candidatos" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."tse_candidatos" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."tse_conta_despesa" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."tse_conta_extrato" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."tse_conta_notafiscal" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."tse_conta_receita" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."tse_despesas" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."tse_ingest_log" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."tse_receitas" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."tuss_procedimentos" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."usa_agencias" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."usa_contratos" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."usa_transacoes" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."user_profiles" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."viagens" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."votacoes_orientacoes" ENABLE ROW LEVEL SECURITY;
-- bloco 13_policies — gerado por split_baseline.py (ordem interna = ordem do dump)
CREATE POLICY "public_read_ifbal" ON "bcb"."if_balanco" FOR SELECT TO "anon" USING (true);

CREATE POLICY "public_read_ifcad" ON "bcb"."if_cadastro" FOR SELECT TO "anon" USING (true);

CREATE POLICY "public_read_scr" ON "bcb"."scr_operacoes" FOR SELECT TO "anon" USING (true);

CREATE POLICY "public_read_sicor" ON "bcb"."sicor_credito_rural" FOR SELECT TO "anon" USING (true);

CREATE POLICY "cases_delete_own" ON "cidadania_ai"."cases" FOR DELETE TO "authenticated" USING (("auth"."uid"() = "user_id"));

CREATE POLICY "cases_insert_own" ON "cidadania_ai"."cases" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));

CREATE POLICY "cases_select_own" ON "cidadania_ai"."cases" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));

CREATE POLICY "cases_update_own" ON "cidadania_ai"."cases" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));

CREATE POLICY "docs_delete_own" ON "cidadania_ai"."generated_docs" FOR DELETE TO "authenticated" USING (("auth"."uid"() = "user_id"));

CREATE POLICY "docs_insert_own" ON "cidadania_ai"."generated_docs" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));

CREATE POLICY "docs_select_own" ON "cidadania_ai"."generated_docs" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));

CREATE POLICY "messages_delete_own" ON "cidadania_ai"."messages" FOR DELETE TO "authenticated" USING (("auth"."uid"() = "user_id"));

CREATE POLICY "messages_insert_own" ON "cidadania_ai"."messages" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));

CREATE POLICY "messages_select_own" ON "cidadania_ai"."messages" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));

CREATE POLICY "public_read_cartoes" ON "portal_transparencia"."cartoes_pagamento" FOR SELECT TO "anon" USING (true);

CREATE POLICY "public_read_favorecidos" ON "portal_transparencia"."favorecidos" FOR SELECT TO "anon" USING (true);

CREATE POLICY "public_read_nf" ON "portal_transparencia"."notas_fiscais" FOR SELECT TO "anon" USING (true);

CREATE POLICY "public_read_nf_itens" ON "portal_transparencia"."notas_fiscais_itens" FOR SELECT TO "anon" USING (true);

CREATE POLICY "public_read_sancoes" ON "portal_transparencia"."sancoes" FOR SELECT TO "anon" USING (true);

CREATE POLICY "Public read" ON "public"."cron_execution_log" FOR SELECT USING (true);

CREATE POLICY "Public read alerts_history" ON "public"."alerts_history" FOR SELECT USING (true);

CREATE POLICY "Public read authority_metrics" ON "public"."authority_metrics" FOR SELECT USING (true);

CREATE POLICY "Public read auto_briefings" ON "public"."auto_briefings" FOR SELECT USING (true);

CREATE POLICY "Public read autores_orcamentarios" ON "public"."autores_orcamentarios" FOR SELECT USING (true);

CREATE POLICY "Public read casas" ON "public"."casas" FOR SELECT USING (true);

CREATE POLICY "Public read comissoes_senado" ON "public"."comissoes_senado" FOR SELECT USING (true);

CREATE POLICY "Public read discursos_camara" ON "public"."discursos_camara" FOR SELECT USING (true);

CREATE POLICY "Public read discursos_senado" ON "public"."discursos_senado" FOR SELECT USING (true);

CREATE POLICY "Public read emendas_favorecidos" ON "public"."emendas_favorecidos" FOR SELECT USING (true);

CREATE POLICY "Public read gastos_parlamentares" ON "public"."gastos_parlamentares" FOR SELECT USING (true);

CREATE POLICY "Public read impacto_federativo" ON "public"."impacto_federativo" FOR SELECT USING (true);

CREATE POLICY "Public read indicadores" ON "public"."indicadores" FOR SELECT USING (true);

CREATE POLICY "Public read institutions" ON "public"."institutions" FOR SELECT USING (true);

CREATE POLICY "Public read intelligence_notes" ON "public"."intelligence_notes" FOR SELECT USING (true);

CREATE POLICY "Public read judiciario_highlights" ON "public"."judiciario_highlights" FOR SELECT USING (("ativo" = true));

CREATE POLICY "Public read judiciario_processos" ON "public"."judiciario_processos" FOR SELECT USING (true);

CREATE POLICY "Public read media_briefings" ON "public"."media_briefings" FOR SELECT USING (true);

CREATE POLICY "Public read narrativas" ON "public"."narrativas" FOR SELECT USING (true);

CREATE POLICY "Public read observatorios" ON "public"."observatorios" FOR SELECT USING (true);

CREATE POLICY "Public read parlamentar_inteligencia" ON "public"."parlamentar_inteligencia" FOR SELECT USING (true);

CREATE POLICY "Public read parlamentares_estaduais" ON "public"."parlamentares_estaduais" FOR SELECT USING (true);

CREATE POLICY "Public read scores" ON "public"."scores" FOR SELECT USING (true);

CREATE POLICY "Public read tribunais" ON "public"."tribunais" FOR SELECT USING (true);

CREATE POLICY "Public read viagens" ON "public"."viagens" FOR SELECT USING (true);

CREATE POLICY "Public read votacoes_orientacoes" ON "public"."votacoes_orientacoes" FOR SELECT USING (true);

CREATE POLICY "Service all judiciario_highlights" ON "public"."judiciario_highlights" USING (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text")) WITH CHECK (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text"));

CREATE POLICY "Service full access transferencias" ON "public"."execucao_financeira_transferencias" USING (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text"));

CREATE POLICY "Service insert casas" ON "public"."casas" FOR INSERT WITH CHECK (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text"));

CREATE POLICY "Service insert comissoes_senado" ON "public"."comissoes_senado" FOR INSERT WITH CHECK (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text"));

CREATE POLICY "Service insert discursos_camara" ON "public"."discursos_camara" FOR INSERT WITH CHECK (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text"));

CREATE POLICY "Service insert discursos_senado" ON "public"."discursos_senado" FOR INSERT WITH CHECK (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text"));

CREATE POLICY "Service insert emendas_favorecidos" ON "public"."emendas_favorecidos" FOR INSERT WITH CHECK (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text"));

CREATE POLICY "Service insert gastos_parlamentares" ON "public"."gastos_parlamentares" FOR INSERT WITH CHECK (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text"));

CREATE POLICY "Service insert judiciario_processos" ON "public"."judiciario_processos" FOR INSERT WITH CHECK (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text"));

CREATE POLICY "Service insert parlamentares_estaduais" ON "public"."parlamentares_estaduais" FOR INSERT WITH CHECK (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text"));

CREATE POLICY "Service insert tribunais" ON "public"."tribunais" FOR INSERT WITH CHECK (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text"));

CREATE POLICY "Service insert viagens" ON "public"."viagens" FOR INSERT WITH CHECK (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text"));

CREATE POLICY "Service insert votacoes_orientacoes" ON "public"."votacoes_orientacoes" FOR INSERT WITH CHECK (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text"));

CREATE POLICY "Service role can insert autores_orcamentarios" ON "public"."autores_orcamentarios" FOR INSERT WITH CHECK (true);

CREATE POLICY "Service role can update autores_orcamentarios" ON "public"."autores_orcamentarios" FOR UPDATE USING (true);

CREATE POLICY "Service update casas" ON "public"."casas" FOR UPDATE USING (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text"));

CREATE POLICY "Service update comissoes_senado" ON "public"."comissoes_senado" FOR UPDATE USING (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text"));

CREATE POLICY "Service update discursos_camara" ON "public"."discursos_camara" FOR UPDATE USING (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text"));

CREATE POLICY "Service update discursos_senado" ON "public"."discursos_senado" FOR UPDATE USING (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text"));

CREATE POLICY "Service update emendas_favorecidos" ON "public"."emendas_favorecidos" FOR UPDATE USING (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text"));

CREATE POLICY "Service update gastos_parlamentares" ON "public"."gastos_parlamentares" FOR UPDATE USING (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text"));

CREATE POLICY "Service update judiciario_processos" ON "public"."judiciario_processos" FOR UPDATE USING (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text"));

CREATE POLICY "Service update parlamentares_estaduais" ON "public"."parlamentares_estaduais" FOR UPDATE USING (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text"));

CREATE POLICY "Service update tribunais" ON "public"."tribunais" FOR UPDATE USING (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text"));

CREATE POLICY "Service update viagens" ON "public"."viagens" FOR UPDATE USING (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text"));

CREATE POLICY "Service update votacoes_orientacoes" ON "public"."votacoes_orientacoes" FOR UPDATE USING (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text"));

CREATE POLICY "anon: public read" ON "public"."cam_parlamentar_risco" FOR SELECT TO "anon" USING (true);

CREATE POLICY "anon: public read" ON "public"."cam_proposicoes" FOR SELECT TO "anon" USING (true);

CREATE POLICY "anon: public read" ON "public"."cam_proposicoes_agg" FOR SELECT TO "anon" USING (true);

CREATE POLICY "anon: public read" ON "public"."ceaps_ranking" FOR SELECT TO "anon" USING (true);

CREATE POLICY "anon: public read" ON "public"."ceaps_senado_ranking" FOR SELECT TO "anon" USING (true);

CREATE POLICY "anon: public read" ON "public"."emendas_completas" FOR SELECT TO "anon" USING (true);

CREATE POLICY "anon: public read" ON "public"."mg_convenios" FOR SELECT TO "anon" USING (true);

CREATE POLICY "anon: public read" ON "public"."mg_convenios_entrada" FOR SELECT TO "anon" USING (true);

CREATE POLICY "anon: public read" ON "public"."mg_covid_compras" FOR SELECT TO "anon" USING (true);

CREATE POLICY "anon: public read" ON "public"."mg_diarias_orgao" FOR SELECT TO "anon" USING (true);

CREATE POLICY "anon: public read" ON "public"."mg_doacoes" FOR SELECT TO "anon" USING (true);

CREATE POLICY "anon: public read" ON "public"."mg_emendas_estaduais" FOR SELECT TO "anon" USING (true);

CREATE POLICY "anon: public read" ON "public"."mg_emendas_federais" FOR SELECT TO "anon" USING (true);

CREATE POLICY "anon: public read" ON "public"."mg_empenhos_sancionados" FOR SELECT TO "anon" USING (true);

CREATE POLICY "anon: public read" ON "public"."mg_empresas_sancionadas" FOR SELECT TO "anon" USING (true);

CREATE POLICY "anon: public read" ON "public"."mg_lrf_limites" FOR SELECT TO "anon" USING (true);

CREATE POLICY "anon: public read" ON "public"."mg_lrf_pessoal" FOR SELECT TO "anon" USING (true);

CREATE POLICY "anon: public read" ON "public"."mg_obras" FOR SELECT TO "anon" USING (true);

CREATE POLICY "anon: public read" ON "public"."mg_os_parcerias" FOR SELECT TO "anon" USING (true);

CREATE POLICY "anon: public read" ON "public"."mg_reparacao_vale" FOR SELECT TO "anon" USING (true);

CREATE POLICY "anon: public read" ON "public"."mg_restos_orgao" FOR SELECT TO "anon" USING (true);

CREATE POLICY "anon: public read" ON "public"."mg_terceirizados" FOR SELECT TO "anon" USING (true);

CREATE POLICY "anon: public read" ON "public"."mg_voos_governador" FOR SELECT TO "anon" USING (true);

CREATE POLICY "anon: public read" ON "public"."parlamentares" FOR SELECT TO "anon" USING (true);

CREATE POLICY "anon: public read" ON "public"."plen_deputado_agg" FOR SELECT TO "anon" USING (true);

CREATE POLICY "anon: public read" ON "public"."ranking_parlamentar" FOR SELECT TO "anon" USING (true);

CREATE POLICY "escrita_service_role" ON "public"."pncp_publicidade" TO "service_role" USING (true);

CREATE POLICY "financiamento_insert_service" ON "public"."financiamento_eleitoral" FOR INSERT WITH CHECK (true);

CREATE POLICY "financiamento_select_public" ON "public"."financiamento_eleitoral" FOR SELECT USING (true);

CREATE POLICY "leitura publica" ON "public"."midia_eventos" FOR SELECT USING (true);

CREATE POLICY "leitura publica" ON "public"."midia_inter_meios" FOR SELECT USING (true);

CREATE POLICY "leitura publica" ON "public"."midia_kantar_releases" FOR SELECT USING (true);

CREATE POLICY "leitura publica" ON "public"."midia_secom_verbas" FOR SELECT USING (true);

CREATE POLICY "leitura publica" ON "public"."midia_veiculos" FOR SELECT USING (true);

CREATE POLICY "leitura publica" ON "public"."midia_youtube_eventos" FOR SELECT USING (true);

CREATE POLICY "leitura_publica" ON "public"."pncp_publicidade" FOR SELECT USING (true);

CREATE POLICY "public read contratos" ON "public"."parlamentar_contratos_cache" FOR SELECT USING (true);

CREATE POLICY "public read financiamento" ON "public"."parlamentar_financiamento_cache" FOR SELECT USING (true);

CREATE POLICY "public read parlamentares" ON "public"."parlamentares" FOR SELECT TO "anon" USING (true);

CREATE POLICY "public read sancoes" ON "public"."parlamentar_sancoes_cache" FOR SELECT USING (true);

CREATE POLICY "public_read_ale_casas" ON "public"."ale_casas" FOR SELECT USING (true);

CREATE POLICY "public_read_ale_ingest_runs" ON "public"."ale_ingest_runs" FOR SELECT USING (true);

CREATE POLICY "public_read_ale_parlamentares" ON "public"."ale_parlamentares" FOR SELECT USING (true);

CREATE POLICY "public_read_ale_proposicoes" ON "public"."ale_proposicoes" FOR SELECT USING (true);

CREATE POLICY "public_read_ale_votacoes" ON "public"."ale_votacoes" FOR SELECT USING (true);

CREATE POLICY "public_read_ale_votos" ON "public"."ale_votos" FOR SELECT USING (true);

CREATE POLICY "public_read_camara_frente" ON "public"."camara_frente" FOR SELECT USING (true);

CREATE POLICY "public_read_camara_frente_membro" ON "public"."camara_frente_membro" FOR SELECT USING (true);

CREATE POLICY "public_read_camara_ocupacao" ON "public"."camara_ocupacao" FOR SELECT USING (true);

CREATE POLICY "public_read_ceaf_ingest_log" ON "public"."ceaf_ingest_log" FOR SELECT USING (true);

CREATE POLICY "public_read_cgu_pad_ingest_log" ON "public"."cgu_pad_ingest_log" FOR SELECT USING (true);

CREATE POLICY "public_read_cgu_pad_processos" ON "public"."cgu_pad_processos" FOR SELECT USING (true);

CREATE POLICY "public_read_cnpj_empresas" ON "public"."cnpj_empresas" FOR SELECT USING (true);

CREATE POLICY "public_read_cnpj_ingest_log" ON "public"."cnpj_ingest_log" FOR SELECT USING (true);

CREATE POLICY "public_read_cota_deputado" ON "public"."cota_deputado" FOR SELECT USING (true);

CREATE POLICY "public_read_cota_despesa" ON "public"."cota_despesa" FOR SELECT USING (true);

CREATE POLICY "public_read_ele2026_alertas" ON "public"."ele2026_alertas" FOR SELECT USING (true);

CREATE POLICY "public_read_ele2026_candidatos" ON "public"."ele2026_candidatos" FOR SELECT USING (true);

CREATE POLICY "public_read_ele2026_financiamento" ON "public"."ele2026_financiamento" FOR SELECT USING (true);

CREATE POLICY "public_read_ele2026_gastos" ON "public"."ele2026_gastos" FOR SELECT USING (true);

CREATE POLICY "public_read_ele2026_ingest_log" ON "public"."ele2026_ingest_log" FOR SELECT USING (true);

CREATE POLICY "public_read_sancoes" ON "public"."sancoes" FOR SELECT USING (true);

CREATE POLICY "public_read_sancoes_ingest_log" ON "public"."sancoes_ingest_log" FOR SELECT USING (true);

CREATE POLICY "public_read_senado_ceaps_despesa" ON "public"."senado_ceaps_despesa" FOR SELECT USING (true);

CREATE POLICY "public_read_senado_orientacao" ON "public"."senado_orientacao" FOR SELECT USING (true);

CREATE POLICY "public_read_senado_votacao" ON "public"."senado_votacao" FOR SELECT USING (true);

CREATE POLICY "public_read_senado_voto" ON "public"."senado_voto" FOR SELECT USING (true);

CREATE POLICY "public_read_siafi_empenho" ON "public"."siafi_empenho" FOR SELECT USING (true);

CREATE POLICY "public_read_siafi_execucao_mensal" ON "public"."siafi_execucao_mensal" FOR SELECT USING (true);

CREATE POLICY "public_read_siafi_fornecedor" ON "public"."siafi_fornecedor" FOR SELECT USING (true);

CREATE POLICY "public_read_siafi_ingestao_log" ON "public"."siafi_ingestao_log" FOR SELECT USING (true);

CREATE POLICY "public_read_siafi_item_empenho" ON "public"."siafi_item_empenho" FOR SELECT USING (true);

CREATE POLICY "public_read_siafi_liquidacao" ON "public"."siafi_liquidacao" FOR SELECT USING (true);

CREATE POLICY "public_read_siafi_pagamento" ON "public"."siafi_pagamento" FOR SELECT USING (true);

CREATE POLICY "public_read_siafi_pagamento_empenho" ON "public"."siafi_pagamento_empenho" FOR SELECT USING (true);

CREATE POLICY "public_read_siafi_pagamento_favorecido_final" ON "public"."siafi_pagamento_favorecido_final" FOR SELECT USING (true);

CREATE POLICY "public_read_tse_ingest_log" ON "public"."tse_ingest_log" FOR SELECT USING (true);

CREATE POLICY "ranking_cache_read" ON "public"."ranking_cache" FOR SELECT USING (true);

CREATE POLICY "ranking_cache_write" ON "public"."ranking_cache" USING (true) WITH CHECK (true);

CREATE POLICY "rp9_apoiamento_public_read" ON "public"."emendas_rp9_apoiamento" FOR SELECT USING (true);

CREATE POLICY "rp9_apoiamento_service_write" ON "public"."emendas_rp9_apoiamento" TO "service_role" USING (true) WITH CHECK (true);

CREATE POLICY "service_role full access" ON "public"."subscriptions" USING (("auth"."role"() = 'service_role'::"text"));

CREATE POLICY "service_role_all" ON "public"."execucao_financeira_siafi" USING (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text"));

CREATE POLICY "service_write_ale_casas" ON "public"."ale_casas" USING (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text")) WITH CHECK (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text"));

CREATE POLICY "service_write_ale_ingest_runs" ON "public"."ale_ingest_runs" USING (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text")) WITH CHECK (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text"));

CREATE POLICY "service_write_ale_parlamentares" ON "public"."ale_parlamentares" USING (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text")) WITH CHECK (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text"));

CREATE POLICY "service_write_ale_proposicoes" ON "public"."ale_proposicoes" USING (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text")) WITH CHECK (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text"));

CREATE POLICY "service_write_ale_votacoes" ON "public"."ale_votacoes" USING (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text")) WITH CHECK (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text"));

CREATE POLICY "service_write_ale_votos" ON "public"."ale_votos" USING (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text")) WITH CHECK (((("current_setting"('request.jwt.claims'::"text", true))::"jsonb" ->> 'role'::"text") = 'service_role'::"text"));

CREATE POLICY "user reads own subscription" ON "public"."subscriptions" FOR SELECT USING (("auth"."email"() = "email"));

CREATE POLICY "users can read own quota" ON "public"."ask_quota" FOR SELECT USING (("user_id" = "auth"."uid"()));

CREATE POLICY "users can update own quota" ON "public"."ask_quota" FOR UPDATE USING (("user_id" = "auth"."uid"()));

CREATE POLICY "users can upsert own quota" ON "public"."ask_quota" FOR INSERT WITH CHECK (("user_id" = "auth"."uid"()));

CREATE POLICY "usuario ve propria assinatura" ON "public"."stf_assinaturas" FOR SELECT USING (("auth"."uid"() = "user_id"));
-- bloco 14_comments — gerado por split_baseline.py (ordem interna = ordem do dump)
COMMENT ON SCHEMA "public" IS 'standard public schema';

COMMENT ON FUNCTION "public"."buscar_processos"("q" "text", "p_tribunal" "text", "p_classe" "text", "p_relator" "text", "p_data_inicio" "date", "p_data_fim" "date", "p_page" integer, "p_page_size" integer) IS 'Wrapper compat (Fase 4) — assinatura idêntica ao RPC do projeto legado corklqwtrblervixxtan. Front Vite chama via supabase.rpc(''buscar_processos'', {q, p_tribunal, p_classe, p_relator, p_data_inicio, p_data_fim, p_page, p_page_size}). Retorna total_count via window count.';

COMMENT ON FUNCTION "public"."buscar_processos_judiciario"("q" "text", "p_tribunal" "text", "p_classe" "text", "p_limit" integer, "p_offset" integer) IS 'FTS sobre judiciario_processos via search_vector + websearch_to_tsquery. Aceita AND, OR, -NOT, "frase exata".';

COMMENT ON FUNCTION "public"."exec_readonly_query"("sql_query" "text") IS 'Executa SELECT arbitrário em transaction_read_only com timeout 25s e LIMIT 200 automático. Usado pela edge function ask/.';

COMMENT ON FUNCTION "public"."execute_sql"("query" "text") IS 'RPC helper para scripts analíticos. Aceita SQL arbitrário, retorna JSONB. Restrito a service_role — nunca exposto ao anon/authenticated.';

COMMENT ON FUNCTION "public"."limpar_ask_cache_expirado"() IS 'Limpa entradas expiradas do ask_cache. Agendar via pg_cron diário.';

COMMENT ON FUNCTION "public"."refresh_judiciario_stats"() IS 'Refresh CONCURRENTLY das 4 MVs. Chamado pela edge function sync-datajud ao final do batch.';

COMMENT ON FUNCTION "public"."refresh_stats"() IS 'Wrapper compat — edge function sync-datajud antiga chama via .rpc(''refresh_stats''). Delega pra refresh_judiciario_stats.';

COMMENT ON FUNCTION "public"."search_fundacoes"("termo" "text", "partido" "text", "so_alertas" boolean, "limite" integer) IS 'Busca full-text em fundações com filtros opcionais. Usada pela caixa de pesquisa do /fundacoes.';

COMMENT ON COLUMN "public"."emendas"."valor_resto_inscrito" IS 'Valor inscrito em Restos a Pagar (não pago no ano de empenho).';

COMMENT ON COLUMN "public"."emendas"."valor_resto_cancelado" IS 'Valor de Restos a Pagar cancelado em anos posteriores.';

COMMENT ON COLUMN "public"."emendas"."valor_resto_pago" IS 'Valor pago via Restos a Pagar em anos posteriores ao empenho. CRÍTICO para análise do orçamento secreto.';

COMMENT ON VIEW "public_api"."vw_public_ranking" IS 'Ranking público nacional de parlamentares baseado na execução de emendas (fonte analítica)';

COMMENT ON TABLE "public"."emendas_favorecidos" IS 'Execução de emendas parlamentares por favorecido — origem: CSV bulk CGU EmendasParlamentares_PorFavorecido.csv';

COMMENT ON COLUMN "public"."emendas_favorecidos"."subtipo" IS 'Classificação interna do tipo de emenda derivada do campo tipo_emenda da CGU';

COMMENT ON COLUMN "public"."emendas_favorecidos"."ano_emenda" IS 'Ano da emenda (4 primeiros dígitos do codigo_emenda) — diferente de ano_mes_pagamento, que é da execução';

COMMENT ON TABLE "public"."agenda_camara_eventos" IS 'Eventos da Câmara dos Deputados (reuniões, audiências, sessões plenárias). Fonte: dadosabertos.camara.leg.br/api/v2/eventos. Histórico desde 2013.';

COMMENT ON VIEW "public"."agenda_audiencias_publicas" IS 'Todas as audiências públicas da Câmara — filtro editorial de alto valor.';

COMMENT ON TABLE "public"."agenda_executivo_compromissos" IS 'Compromissos dos ministros e cúpula do Executivo Federal (e-Agendas/CGU). Decreto nº 10.889/2021 — publicação obrigatória em até 10 dias. Cobertura: PR, VPR, Casa Civil + 37 ministérios.';

COMMENT ON TABLE "public"."agenda_senado_comissoes" IS 'Reuniões de comissões do Senado Federal. Fonte: legis.senado.leg.br/dadosabertos/comissao/agenda. Limite: 1 mês/req.';

COMMENT ON TABLE "public"."agenda_senado_plenario" IS 'Sessões plenárias do Senado Federal e Congresso Nacional. Fonte: legis.senado.leg.br/dadosabertos/plenario/agenda/dia.';

COMMENT ON VIEW "public"."agenda_federal_completa" IS 'Agenda unificada dos 3 poderes (Executivo + Câmara + Senado) — últimos 30 dias. Base para o feed de agenda do BR Insider.';

COMMENT ON VIEW "public"."agenda_legislativo_semana" IS 'Agenda consolidada dos últimos 7 dias: Câmara + comissões Senado + plenário Senado.';

COMMENT ON VIEW "public"."agenda_ministerial_semana" IS 'Agenda da semana por ministério — visão editorial rápida.';

COMMENT ON VIEW "public"."agenda_ministerial_setor_privado" IS 'Compromissos do Executivo com representantes do setor privado — insumo primário para investigação de lobby e captura regulatória.';

COMMENT ON TABLE "public"."casas" IS 'Casas legislativas cobertas pela plataforma (federal e estaduais).';

COMMENT ON TABLE "public"."parlamentares_estaduais" IS 'Parlamentares cobertos pela plataforma. `id_externo` é o ID da casa de origem (TEXT pra acomodar variações).';

COMMENT ON COLUMN "public"."parlamentares_estaduais"."id_externo" IS 'ID nativo da casa (ex.: ALMG = INTEGER convertido pra TEXT; ALESP = a confirmar).';

COMMENT ON VIEW "public"."alesp_deputados" IS 'Deputados ALESP via tabela canônica `parlamentares_estaduais`. Inclui ativos da legislatura corrente e fantasmas (ativo=false) de legislaturas anteriores criados via backfill de despesas históricas.';

COMMENT ON VIEW "public"."ale_parlamentares_reconciliado" IS 'Reconcilia ale_parlamentares (atividade) com <casa>_deputados (gastos). Cobre ALESP via Matricula; estender por casa.';

COMMENT ON VIEW "public"."alepe_deputados" IS 'Deputados ALEPE via tabela canônica `parlamentares_estaduais`. 49 ativos (leg=17) + 114 históricos (leg=-16).';

COMMENT ON TABLE "public"."gastos_parlamentares" IS 'Gastos de gabinete/verba indenizatória de parlamentares. 1 linha = 1 nota fiscal.';

COMMENT ON COLUMN "public"."gastos_parlamentares"."valor_bruto" IS 'Valor da nota fiscal (ALMG = valor_despesa). Pode ser > valor_reembolso em reembolsos parciais.';

COMMENT ON COLUMN "public"."gastos_parlamentares"."valor_reembolso" IS 'Valor efetivamente pago pela casa. NULL quando a casa não distingue (caso ALESP a confirmar).';

COMMENT ON VIEW "public"."alepe_verba_indenizatoria" IS 'Notas de verba indenizatória ALEPE — 1 linha = 1 nota fiscal. Inclui data_emissao (disponível na API ALEPE, diferente da ALESP).';

COMMENT ON VIEW "public"."alepe_verba_resumo_mensal" IS 'Resumo mensal por deputado ALEPE — equivalente ao almg_verba_resumo_mensal. Inclui ativo+legislatura pra filtrar históricos no front.';

COMMENT ON VIEW "public"."alesp_despesas_gabinete" IS 'Despesas de gabinete ALESP (1 linha = 1 despesa). Granularidade: ano+mês, sem data exata nem nº documento — limitações da fonte ALESP.';

COMMENT ON VIEW "public"."alesp_despesas_resumo_mensal" IS 'Resumo mensal por deputado ALESP — equivalente ao almg_verba_resumo_mensal. Inclui ativo+legislatura pra filtrar fantasmas de legislaturas anteriores no front.';

COMMENT ON VIEW "public"."almg_deputados" IS 'View compat: deputados ALMG na tabela canônica `parlamentares`. Mantida pra preservar consumers existentes da rota /almg.';

COMMENT ON TABLE "public"."ceaps_brutas" IS 'Lançamentos brutos da Cota para Exercício da Atividade Parlamentar (CEAP).';

COMMENT ON MATERIALIZED VIEW "public"."almg_fornecedores_intersetados" IS 'Fornecedores (CNPJ) presentes na ALMG e em ≥1 outra casa (ALESP ou Câmara Federal). 2.362 CNPJs: 2.352 ALMG+Câmara, 83 ALMG+ALESP, 73 nas 3 casas. Chamar refresh_almg_fornecedores_intersetados() após cada ingestão mensal.';

COMMENT ON VIEW "public"."almg_verba_indenizatoria" IS 'View compat: verba indenizatória ALMG na tabela canônica `gastos_parlamentares`.';

COMMENT ON VIEW "public"."almg_verba_resumo_mensal" IS 'View compat: resumo mensal ALMG (consumido por /almg/ranking). Colunas idênticas à versão pré-canônica.';

COMMENT ON TABLE "public"."ask_cache" IS 'Cache de perguntas em linguagem natural processadas pela edge function ask. TTL 7 dias.';

COMMENT ON TABLE "public"."emendas_completas" IS 'Emendas parlamentares de todos os tipos (Individual, Bancada, Comissão, Relator/RP9) — Portal da Transparência.';

COMMENT ON COLUMN "public"."emendas_completas"."eh_rp9" IS 'Gerado automaticamente: true quando tipo_emenda contém "relator" (orçamento secreto).';

COMMENT ON TABLE "public"."ask_log" IS 'Log de todas as buscas. Usar pra: ver perguntas populares, detectar abuso, calcular custo real.';

COMMENT ON VIEW "public"."ask_perguntas_populares" IS 'Perguntas com 3+ buscas nos últimos 30 dias — input pros botões de sugestão da home.';

COMMENT ON TABLE "public"."bets_licenciadas" IS 'Operadoras autorizadas pela SPA/MF a explorar apostas de quota fixa. Fonte: gov.br/fazenda/spa, planilha-de-autorizacoes-13-05-2026.csv (81 operadoras, 186 marcas).';

COMMENT ON TABLE "public"."cgu_pad_processos" IS 'Processos Administrativos Disciplinares (CGU-PAD). Uma linha por processo. Campo assuntos é array parseado do CSV. Cruzar entidade com siafi_fornecedor e emendas_favorecidos para achados.';

COMMENT ON TABLE "public"."ceaps_ranking" IS 'Ranking de despesas CEAP por deputado e ano — gerado pelo job_ceaps_ranking.';

COMMENT ON VIEW "public"."cnes_emendas" IS 'Cruzamento CNES × emendas_favorecidos por CNPJ. Base para investigação de destinação de emendas para setor saúde.';

COMMENT ON TABLE "public"."cnpj_empresas" IS 'Dados cadastrais básicos das empresas favorecidas (Receita Federal, dump mensal). cnpj_basico (8 dígitos) é chave de join com emendas_favorecidos via substring(codigo_favorecido,1,8).';

COMMENT ON TABLE "public"."cobertura_dados" IS 'Metadados de cobertura por ano; usado pela ingestão e pela API de status.';

COMMENT ON TABLE "public"."convenios" IS 'Convênios federais do Portal da Transparência. Cobertura nacional via iteração por UF (27 estados + DF). Chave natural: id_portal (classPK da API).';

COMMENT ON VIEW "public"."cota_emenda_cruzamento" IS 'Empresas que aparecem nos dois fluxos: cota parlamentar + emendas. Join por cnpj_norm (apenas dígitos) para compatibilidade entre fontes.';

COMMENT ON MATERIALIZED VIEW "public"."mv_cota_fornecedor" IS 'Ranking de fornecedores do CEAP Câmara (cota_despesa, 2008-2026) por cnpj_norm; aéreas agrupadas por esqueleto ASCII do nome. Refresh: REFRESH MATERIALIZED VIEW CONCURRENTLY mv_cota_fornecedor (após ingestão de cota). Nome cru — reparo de mojibake no layer da aplicação.';

COMMENT ON TABLE "public"."cpgf_transacoes" IS 'Gastos com Cartão de Pagamento do Governo Federal — Portal da Transparência. Cruzável com cota_parlamentar (CEAP), viagens_scdp e doadores TSE.';

COMMENT ON VIEW "public"."cvm_cruzamento_emendas" IS 'Favorecidos de emendas parlamentares que figuram como acusados em processos sancionadores da CVM. Join por nome normalizado ‚Äî validar CNPJs manualmente antes de publicar.';

COMMENT ON TABLE "public"."mg_empresas_sancionadas" IS 'Empresas sancionadas pela Lei Anticorrupção em MG (CGE). cnpj_norm = chave de cruzamento.';

COMMENT ON VIEW "public"."cvm_fip_monopolio" IS 'FIPs com 1 cotista PF (100%) e capital integralizado > R$10M — padrão Galo Forte. Um registro por fundo, competência mais recente.';

COMMENT ON TABLE "public"."cvm_fip_saf" IS 'FIPs com participação confirmada ou inferida em SAFs brasileiras. Carteira de FIP é confidencial; vínculo estabelecido por nome, cotistas e fontes públicas.';

COMMENT ON TABLE "public"."cvm_saf" IS 'Lista-semente das SAFs brasileiras constituídas. Serve de universo para ingestão QSA (Receita) e cruzamento CVM.';

COMMENT ON TABLE "public"."cvm_saf_entidade_relacionada" IS 'Holdings, FIDCs e fundos intermediários vinculados às SAFs. Incluídos no universo QSA para revelar a cadeia de controle além da SAF direta.';

COMMENT ON TABLE "public"."deputados_brutas" IS 'Dados brutos dos deputados federais (API Câmara /deputados).';

COMMENT ON TABLE "public"."ele2026_alertas" IS 'Candidatos de interesse editorial pré-cadastrados para monitoramento em 2026. Alimentado manualmente antes dos dados chegarem. candidatura_entrou e financiamento_entrou marcados pelo conector na ingestão. motivos: array de tags (emenda_xcmg, sancao_ceis, investigado, etc.).';

COMMENT ON TABLE "public"."ele2026_candidatos" IS 'Candidatos federais e estaduais (eleições outubro 2026). Tabela vazia até TSE liberar dados (~agosto 2026). cpf cruza com parlamentares.cpf (mandato anterior) e tse_candidatos.cpf (histórico). parlamentar_id preenchido na ingestão para candidatos que são deputados/senadores ativos.';

COMMENT ON TABLE "public"."ele2026_financiamento" IS 'Receitas de campanha 2026 (TSE). cpf_cnpj_doador cruza com emendas_favorecidos.codigo_favorecido e sancoes.cpf_cnpj. Dedup por numero_recibo. Tabela vazia até prestação de contas (~out/nov 2026).';

COMMENT ON TABLE "public"."ele2026_gastos" IS 'Despesas de campanha 2026 (TSE). cpf_cnpj_fornecedor cruza com emendas_favorecidos e sancoes. Tabela vazia até prestação de contas (~out/nov 2026).';

COMMENT ON VIEW "public"."ele26_v_alertas_painel" IS 'Painel dos candidatos monitorados — estado de entrada no banco + arrecadação. Atualiza automaticamente conforme dados chegam. Ordenado por emenda_total_hist DESC para priorizar os de maior rastro.';

COMMENT ON VIEW "public"."ele26_v_candidato_emendas" IS 'Emendas destinadas por candidatos 2026 em seus mandatos anteriores. Retorna vazio até ele2026_candidatos ser preenchido (agosto 2026). Filtrar por candidato ou cnpj_favorecido para investigar.';

COMMENT ON TABLE "public"."sancoes" IS 'CEIS + CNEP unificados (Portal da Transparência). cpf_cnpj (só dígitos) cruza com emendas_favorecidos.codigo_favorecido, tse_receitas.cpf_cnpj_doador e tse_despesas.cpf_cnpj_fornecedor.';

COMMENT ON VIEW "public"."ele26_v_financiamento_sancoes" IS 'Empresas sancionadas (CEIS/CNEP) que aparecem como doadores ou fornecedores de campanha 2026. UNION de ele2026_financiamento + ele2026_gastos × sancoes. papel = "doador" (receitas) ou "fornecedor" (despesas).';

COMMENT ON TABLE "public"."tse_candidatos" IS 'Candidatos federais e estaduais (TSE, 2022+2024). Chave cpf permite cruzamento com parlamentares.cpf. Filtrado para CD_CARGO IN (1,3,5,6,7).';

COMMENT ON VIEW "public"."ele26_v_historico_eleitoral" IS 'Histórico eleitoral (2022+2024) de candidatos que também concorrem em 2026. Join por CPF. Retorna vazio até ele2026_candidatos ser preenchido.';

COMMENT ON TABLE "public"."emendas_brutas" IS 'Dados crus da ingestão (Portal da Transparência); upsert por (ano, id_externo).';

COMMENT ON TABLE "public"."emendas_financeiro" IS 'Emendas com valores empenhado/liquidado/pago; resultado do enriquecimento.';

COMMENT ON TABLE "public"."emendas_rp9_apoiamento" IS 'Ofícios de apoiamento RP-9 (orçamento secreto) da CMO. Vínculo apoiador->favorecido->empenho que o portal não consolida. Ver LAIs 2026052200000016/017.';

COMMENT ON TABLE "public"."execucoes_pipeline" IS 'Registro de cada execução de job; base da observabilidade.';

COMMENT ON TABLE "public"."execucoes_pipeline_etapas" IS 'Etapas dentro de uma execução; rastreabilidade fina.';

COMMENT ON VIEW "public"."fip_saf_resumo" IS 'FIPs do ecossistema SAF com último informe CVM disponível. confirmado=true: vínculo comprovado. false: inferido por nome/estrutura.';

COMMENT ON TABLE "public"."folha_custo_gabinete" IS 'Custo de pessoal por parlamentar. Senado: salário exato; Câmara: estimado por nível (salario_tipo).';

COMMENT ON TABLE "public"."folha_doador_leads" IS 'Leads: secretário parlamentar que consta como top-doador da campanha do próprio chefe. Match por nome — verificar antes de publicar.';

COMMENT ON TABLE "public"."folha_gabinete" IS 'Staff de gabinete federal (Câmara: secretários parlamentares; Senado: comissionados GABSEN). Fase 1 sem salário.';

COMMENT ON COLUMN "public"."folha_gabinete"."parlamentar_id_externo" IS 'Referência soft (sem FK) a deputados_brutas.id_externo. Câmara apenas; Senado liga por parlamentar_nome.';

COMMENT ON COLUMN "public"."folha_gabinete"."valor_remuneracao" IS 'NULL na Fase 1. Preenchido na Fase 2 (remuneração individual em bulk).';

COMMENT ON VIEW "public"."folha_gabinete_atual" IS 'Último snapshot de folha_gabinete por casa.';

COMMENT ON TABLE "public"."folha_nepotismo_leads" IS 'Leads de nepotismo cruzado: secretário com sobrenome de parlamentar de outro gabinete. Sinal fraco — sobrenomes comuns excluídos. Verificar parentesco.';

COMMENT ON MATERIALIZED VIEW "public"."fornecedores_intersetados" IS 'Fornecedores (CNPJ) presentes na ALEPE e em ≥1 outra casa (ALESP ou Câmara Federal). Chamar refresh_fornecedores_intersetados() após cada ingestão mensal.';

COMMENT ON TABLE "public"."fundacoes_partidarias" IS 'Cadastro das 26 fundações e institutos partidários registrados no TSE. Enriquecido com QSA e endereço da Receita Federal via BrasilAPI.';

COMMENT ON TABLE "public"."fundacoes_repasses" IS 'Repasses de partidos para suas fundações/institutos. Fonte: dataset despesa_anual_{ANO}_BR.csv do TSE (Dados Abertos). Filtro: NR_CPF_CNPJ_FORNECEDOR = CNPJ de fundação conhecida.';

COMMENT ON COLUMN "public"."fundacoes_repasses"."tipo_repasse" IS 'fundacao_partidaria = classificado pelo TSE como tal; aluguel = locação de imóvel; servico = outro serviço; outros = demais.';

COMMENT ON VIEW "public"."fundacoes_resumo" IS 'Agregado por fundação por exercício. Inclui concentração Q4, breakdown por tipo de repasse e flags de mesmo endereço.';

COMMENT ON VIEW "public"."fundacoes_alertas" IS 'Sinais de risco por fundação: sede compartilhada, aluguel circular, concentração Q4 > 40%, natureza jurídica suspeita. Score 0-4.';

COMMENT ON TABLE "public"."fundacoes_nf_partidos" IS 'Notas fiscais dos diretórios nacionais dos partidos (dataset TSE). Cobre TODOS os fornecedores — não só fundações. NM_URL contém link direto ao PDF em spcadownload.tse.jus.br.';

COMMENT ON VIEW "public"."fundacoes_fornecedores_ranking" IS 'Agregado de NFs por partido × fornecedor × tipo de despesa. Permite identificar fornecedores recorrentes e volumes por categoria.';

COMMENT ON VIEW "public"."fundacoes_vazio_prestacao" IS 'Mostra quais fundações prestam contas próprias vs. quais só aparecem como beneficiárias. O vazio de prestação de contas É a notícia.';

COMMENT ON TABLE "public"."judiciario_highlights" IS 'Decisões em destaque, curadas manualmente via edge function admin-highlights. Máximo lógico de 5 ativos por semana_referencia (não enforced no DB).';

COMMENT ON TABLE "public"."judiciario_processos" IS 'Decisões judiciais (acórdãos e decisões monocráticas) coletadas via DataJud CNJ + portais próprios (TCU). 1 linha = 1 processo.';

COMMENT ON COLUMN "public"."judiciario_processos"."identificador_externo" IS 'ID estável da fonte (DataJud _id prefixado com sigla do tribunal). Garante idempotência do upsert.';

COMMENT ON COLUMN "public"."judiciario_processos"."search_vector" IS 'tsvector português stored — usado pelo RPC buscar_processos_judiciario via índice GIN.';

COMMENT ON TABLE "public"."tribunais" IS 'Tribunais cobertos pelo Observatório Judiciário — STF/STJ/TST/TCU + 6 TRFs + 27 TJs.';

COMMENT ON VIEW "public"."highlights" IS 'View compat — superfície idêntica à tabela `highlights` original.';

COMMENT ON VIEW "public"."highlights_publico" IS 'View compat — somente highlights ativos, ordenado por semana mais recente.';

COMMENT ON TABLE "public"."ibama_autuacoes" IS 'Autos de infração do IBAMA — PF e PJ. Cruzável com doadores TSE, beneficiários de emendas, contratos PNCP e patrimônio TSE.';

COMMENT ON TABLE "public"."leiloes_leiloeiros" IS 'Leiloeiros independentes credenciados — CNAE 8299-7/04 (código RFB: 8299704). Fonte: Receita Federal dadosabertos.rfb.gov.br/CNPJ/ (Estabelecimentos + Empresas). Cruzamento direto com emendas_favorecidos e tse_receitas via cnpj_completo. Atualização: mensal (cron dia 5, 02h UTC).';

COMMENT ON TABLE "public"."leiloes_processos" IS 'Processos de execução fiscal e de título extrajudicial — DataJud/CNJ. Classes: 159 (Exec. Título Extraj.), 1116 (Exec. Fiscal), 1028 (Exec. Cível), 154 (Cumprimento de Sentença). LIMITAÇÃO: campo partes (CPF/CNPJ) não disponível na API pública CNJ. Atualização: mensal (cron dia 5, 02h UTC).';

COMMENT ON TABLE "public"."mg_compras_fornecedor" IS 'Compras SIAD por fornecedor (CNPJ) e ano — total contratado homologado/atualizado, nº de contratos. 1 linha por contrato reduzida. CKAN.';

COMMENT ON VIEW "public"."mg_compras_fornecedor_total" IS 'Compras SIAD somadas por fornecedor (CNPJ), todos os anos.';

COMMENT ON VIEW "public"."mg_contratos_sancionados" IS 'Contratos do Estado de MG cujo fornecedor (CNPJ normalizado de cnpj_cpf_fornecedor) foi processado por sanção. condenada=true exclui arquivados/absolvidos — usar este recorte para publicar nomes.';

COMMENT ON TABLE "public"."mg_convenios_entrada" IS 'Convênios de entrada de recursos no Estado de MG (concedente→proponente). 1 linha por convênio. CKAN.';

COMMENT ON TABLE "public"."mg_despesa_pessoal_vale" IS 'Pessoal pago com o Acordo Judicial Vale/Brumadinho (nominativo, servidores). CKAN/LAI.';

COMMENT ON TABLE "public"."mg_diarias_orgao" IS 'Diárias por unidade orçamentária e ano (agregado), Executivo MG. CKAN.';

COMMENT ON TABLE "public"."mg_divida_tipo" IS 'Serviço da dívida (juros+amortização) por tipo e ano, Executivo MG. CKAN.';

COMMENT ON TABLE "public"."mg_doacoes" IS 'Doações e comodatos ao Estado de MG (Casa Civil). Valor em faixa, sem CNPJ do doador.';

COMMENT ON TABLE "public"."mg_emendas_estaduais" IS 'Emendas ao orçamento estadual de MG (LOA): autor (deputado) → valor → objeto → órgão. 1 linha/emenda. CKAN.';

COMMENT ON VIEW "public"."mg_emendas_estaduais_por_autor" IS 'Emendas estaduais somadas por autor (deputado/comissão/bloco).';

COMMENT ON TABLE "public"."mg_emendas_federais" IS 'Emendas federais executadas por MG (entrada). Autoria, valor indicado/repassado, objeto, órgão executor. Inclui transferências especiais (PIX).';

COMMENT ON TABLE "public"."mg_empenhos_sancionados" IS 'Empenhos (pagamentos) do Estado de MG a empresas que constam na lista de sancionadas — filtrado na ingestão. Cruzar fase/decisão p/ separar condenada de arquivada.';

COMMENT ON TABLE "public"."mg_licitacao_sobrepreco" IS 'Itens de licitação (MG, fora COVID) homologados acima do preço de referência. Sinal de sobrepreço; órgão = responsável pela homologação.';

COMMENT ON VIEW "public"."mg_licitacao_sobrepreco_rel" IS 'Sobrepreço em licitações com teto de 1000% (exclui erro de referência). Sinal de apuração, não prova.';

COMMENT ON TABLE "public"."mg_notas_fornecedor" IS 'Notas fiscais recebidas pelo Estado de MG, agregadas por fornecedor (CNPJ) e ano. Nominativo. CKAN.';

COMMENT ON VIEW "public"."mg_notas_fornecedor_total" IS 'Notas fiscais somadas por fornecedor (CNPJ), todos os anos.';

COMMENT ON TABLE "public"."mg_os_parcerias" IS 'Termos de Parceria e Contratos de Gestão (organizações sociais) de MG. Entidade + CNPJ + repasses. CKAN.';

COMMENT ON TABLE "public"."mg_terceirizados" IS 'Terceirizados AGREGADOS por empresa/órgão/mês (headcount). Nomes individuais NÃO são armazenados (LGPD / sem interesse público nominal).';

COMMENT ON VIEW "public"."mg_fornecedor_perfil" IS 'Scorecard por fornecedor (cnpj_norm derivado de mg_contratos.cnpj_cpf_fornecedor) do Executivo de MG: faturamento contratos/SIAD/notas, pago a sancionadas, sobrepreço, sanção (condenada≠arquivada), terceirizada, OS, score 0–100. valor_faturado = maior valor em UM sistema (não soma). Score/sobrepreço = sinal a apurar.';

COMMENT ON VIEW "public"."mg_fornecedor_perfil_resumo" IS 'KPIs do scorecard de fornecedores MG: nº de fornecedores, condenadas faturando, pago a condenadas, com sobrepreço, score alto.';

COMMENT ON TABLE "public"."mg_ipsemg_contratos" IS 'Credenciados/contratos vigentes do IPSEMG (saúde), nominativo + CNPJ. Sem valor na fonte. CKAN.';

COMMENT ON TABLE "public"."mg_lrf_limites" IS 'DTP x RCL ajustada e limites legais da LRF (janela móvel 12m), Executivo MG.';

COMMENT ON TABLE "public"."mg_lrf_pessoal" IS 'Despesa de pessoal do Executivo MG mês a mês (LRF). Fonte CGE/Tesouro, CKAN.';

COMMENT ON VIEW "public"."mg_pagamentos_condenadas" IS 'Empenhos pagos a empresas CONDENADAS (transitado/condenatório, exclui arquivadas). Pagamento efetivo, não só contrato.';

COMMENT ON TABLE "public"."mg_remuneracao" IS 'Remuneração de servidores do Executivo de MG (CKAN/CGE, CC-BY-4.0). Snapshot mensal; foco em supersalários.';

COMMENT ON COLUMN "public"."mg_remuneracao"."remuneracao_base" IS 'Valor comparado ao teto p/ flag de supersalário (em geral remuneracao_bruta).';

COMMENT ON COLUMN "public"."mg_remuneracao"."teto_referencia" IS 'Teto constitucional da competência. DEFAULT 46366.19 (STF 2025/26) — CONFIRMAR por ano no job de ingestão.';

COMMENT ON COLUMN "public"."mg_remuneracao"."abate_teto" IS 'Valor do abate-teto aplicado (coluna `teto` da fonte). > 0 ⇒ servidor excedeu o teto constitucional.';

COMMENT ON VIEW "public"."mg_remuneracao_atual" IS 'Último snapshot de mg_remuneracao.';

COMMENT ON TABLE "public"."mg_reparacao_vale" IS 'Iniciativas e valores do acordo judicial de reparação Vale/Brumadinho (SEPLAG-MG).';

COMMENT ON TABLE "public"."mg_restos_orgao" IS 'Restos a pagar por órgão e ano (inscrito/pago/saldo), Executivo MG. CKAN.';

COMMENT ON VIEW "public"."mg_supersalarios" IS 'Servidores do Executivo de MG com abate-teto > 0 (corte oficial por exceder o teto), último snapshot. Ordenado pelo valor cortado.';

COMMENT ON TABLE "public"."mg_voos_governador" IS 'Voos oficiais do Governador de MG: passageiro, cargo, rota, aeronave, horas. CKAN.';

COMMENT ON TABLE "public"."tse_despesas" IS 'Despesas de campanha por candidato (TSE). cpf_cnpj_fornecedor cruza com emendas_favorecidos (fornecedor de campanha = favorecido de emenda). Reload completo por ano_eleicao (dados estáticos pós-eleição).';

COMMENT ON TABLE "public"."pncp_publicidade" IS 'Contratos federais de publicidade/comunicação coletados do PNCP. Filtro: objetoContrato contém palavras-chave de publicidade + esferaId = F. Cobertura: 2023–atual. Atualizado semanalmente pelo cron pncp-publicidade.';

COMMENT ON TABLE "public"."pr_ex_presidentes_custos" IS 'Transações SIC de custos das equipes de segurança e apoio a ex-presidentes (Lei nº 7.474/1986), 2021–2026. Fonte: dadosabertos.presidencia.gov.br.';

COMMENT ON VIEW "public"."pr_ex_presidentes_custo_anual" IS 'Custo anual por ex-presidente: total, pessoal vs outras despesas.';

COMMENT ON VIEW "public"."processos" IS 'View compat — superfície idêntica à tabela `processos` original do projeto isolado `corklqwtrblervixxtan`. Suportada enquanto o front Vite não migrar pras tabelas canônicas.';

COMMENT ON VIEW "public"."processos_publico" IS 'View compat espelho de `processos`. No projeto antigo era a fronteira anon — aqui é só alias, já que `judiciario_processos` tem public read via RLS.';

COMMENT ON TABLE "public"."ranking_cache" IS 'DEPRECATED — cache legado da arquitetura anterior de ranking. Mantido apenas para contingência, rollback e auditoria.';

COMMENT ON TABLE "public"."ranking_parlamentar_build" IS 'Ranking por build; staging antes da publicação.';

COMMENT ON TABLE "public"."ranking_snapshot" IS 'DEPRECATED — objeto legado preservado apenas para rollback e referência histórica. Desde a Fase 6/7, o caminho principal de ranking usa public_api.vw_public_ranking.';

COMMENT ON VIEW "public"."saf_ecossistema_cvm" IS 'Emissões CVM ligadas às SAFs: diretas (cnpj da SAF) + ecossistema (holdings, FIDCs, FIPs mapeados em cvm_saf_entidade_relacionada). Sem fuzzy match por nome — evita falsos positivos históricos.';

COMMENT ON VIEW "public"."saf_oferta" IS 'Emissões CVM feitas diretamente pelas SAFs (match por CNPJ). Apenas Atlético-MG, Cruzeiro e Cuiabá aparecem (jun/2026).';

COMMENT ON VIEW "public"."saf_quadro_societario" IS 'Quadro societário das SAFs brasileiras: join cvm_saf × cnpj_socios × cnpj_empresa. Requer ingestão QSA com universo expandido (SAFs incluídas).';

COMMENT ON TABLE "public"."sebrae_contratos" IS 'Contratos do Sistema SEBRAE por UF. ~480k linhas. Fonte: Qlik Engine API paineis-lai.sebrae.com.br (App e2407c39).';

COMMENT ON TABLE "public"."sebrae_convenios" IS 'Convênios do Sistema SEBRAE por UF. ~2.8k linhas. Fonte: Qlik Engine API paineis-lai.sebrae.com.br.';

COMMENT ON TABLE "public"."sebrae_emendas_contratos" IS 'Contratos do SEBRAE provenientes de emendas parlamentares. Fonte: Qlik Engine API paineis-lai.sebrae.com.br.';

COMMENT ON TABLE "public"."sebrae_emendas_convenios" IS 'Convênios do SEBRAE provenientes de emendas parlamentares. Fonte: Qlik Engine API paineis-lai.sebrae.com.br.';

COMMENT ON TABLE "public"."sebrae_licitacoes" IS 'Licitações do Sistema SEBRAE por UF. ~21k linhas. Fonte: Qlik Engine API paineis-lai.sebrae.com.br.';

COMMENT ON TABLE "public"."sebrae_patrocinios" IS 'Patrocínios do Sistema SEBRAE por UF. ~1.9k linhas. Fonte: Qlik Engine API paineis-lai.sebrae.com.br.';

COMMENT ON TABLE "public"."senac_contratos" IS 'Contratos, parcerias, convênios, acordos e patrocínios SENAC por DR. Tipo: 1=contrato 2=acordo 3=convenio 4=parceria 5=patrocinio. Fonte: transparencia.senac.br/service/api/contratos-parcerias?regional={sigla} (sem auth). DN + 27 regionais estaduais.';

COMMENT ON TABLE "public"."senac_licitacoes" IS 'Licitações SENAC por DR. Fonte: transparencia.senac.br/service/api/licitacoes/regional/{sigla} (sem auth). DN + 27 regionais estaduais.';

COMMENT ON TABLE "public"."senar_contratos" IS 'Contratos SENAR nacional por período trimestral. Fonte: app3.cna.org.br/transparencia/?gestaoContratosCsv-SENAR-{periodo_id}';

COMMENT ON TABLE "public"."senar_licitacoes" IS 'Licitações SENAR nacional por ano civil. Fonte: app3.cna.org.br/transparencia/?gestaoLicitacaoCsv-SENAR-{ano}';

COMMENT ON TABLE "public"."senar_transferencias" IS 'Transferências de recursos SENAR — federações e convênios. Sufixo -9 (união completa). Fonte: app3.cna.org.br/transparencia/?gestaoTransferenciaRecursosCsv-SENAR-{periodo_id}-9';

COMMENT ON TABLE "public"."sesc_contratos" IS 'Contratos SESC por DR e exercício. Dataset 178 (firmados) e 179 (com pagamento). Fonte: transparencia-[uf].sesc.com.br/transparencia/dados/download/{id}/csv (sem auth). 28 portais (DN + 27 UFs).';

COMMENT ON TABLE "public"."sesc_convenios" IS 'Convênios SESC por DR e exercício. Dataset 180 (firmados) e 183 (com pagamento). Fonte: transparencia-[uf].sesc.com.br/transparencia/dados/download/{id}/csv (sem auth).';

COMMENT ON TABLE "public"."sisi_contratos" IS 'Contratos e patrocínios do Sistema Indústria (SESI + SENAI) por DR e ano. Fonte: sistematransparenciaweb.com.br/api-contratos (REST, sem auth). Dados desde 2022.';

COMMENT ON TABLE "public"."sisi_convenios" IS 'Convênios do Sistema Indústria (SESI + SENAI) por DR e ano. Fonte: sistematransparenciaweb.com.br/api-convenios (REST, sem auth). Dados desde 2022.';

COMMENT ON TABLE "public"."sisi_licitacoes" IS 'Licitações do Sistema Indústria (SESI + SENAI) por DR e ano. Fonte: sistematransparenciaweb.com.br/api-licitacoes (REST, sem auth). Dados desde 2022.';

COMMENT ON TABLE "public"."sisi_licitacoes_participantes" IS 'Participantes (proponentes) por licitação SESI/SENAI — quem disputou e com qual preço. Permite detectar direcionamento e comparar preços entre DRs.';

COMMENT ON TABLE "public"."snapshots_ranking" IS 'Snapshots históricos do ranking; auditoria e série temporal.';

COMMENT ON TABLE "public"."tse_receitas" IS 'Receitas de campanha por candidato (TSE, 2022+2024). cpf_cnpj_doador permite cruzamento com emendas_favorecidos.cnpj_favorecido. Inclui doações PF, PJ, partido e recursos próprios.';

COMMENT ON VIEW "public"."tse_v_doador_emenda" IS 'Emendas PJ-favorecidas cruzadas com perfil de doação eleitoral do CNPJ agregado de tse_receitas. NÃO amarra ao mesmo parlamentar (cruzamento amplo, semelhante a mv_contratos_doadores_federal). Definição anterior filtrava por tipo_doador ILIKE ''%%jurídica%%'' — sem matches pós-reforma 2015. Reescrita em 2026-06-17 (migration 20260618010000).';

COMMENT ON VIEW "public"."tse_v_dossie_doador" IS 'Todas as doações de um CPF/CNPJ ou nome. Filtrar por cpf_cnpj_doador (exato) ou nome_doador ILIKE. JOIN com parlamentares permite ver se candidato foi eleito e está ativo.';

COMMENT ON VIEW "public"."tse_v_financiadores_parlamentar" IS 'Todos os financiadores de um parlamentar, por ano. Filtrar por cpf_candidato ou nome_candidato ILIKE. Agregado: total recebido de cada doador.';

COMMENT ON VIEW "public"."tse_v_receptor_top" IS 'Ranking de candidatos que receberam de um doador. Filtrar por cpf_cnpj_doador. Agrega 2022+2024.';

COMMENT ON VIEW "public"."tse_v_rede_financiamento" IS 'Para um parlamentar (cpf_parlamentar_alvo), mostra os doadores em comum com outros candidatos. Filtre por cpf_parlamentar_alvo = CPF do parlamentar. Útil para mapear redes de influência de um financiador.';

COMMENT ON VIEW "public"."v_midia_doadora_emenda" IS 'Empresas de comunicação (classificadas pelo TSE) que financiaram campanhas E receberam emendas parlamentares — potencial conflito de interesse. Produto: "A mídia que depende de emenda e financia quem decide emendas."';

COMMENT ON VIEW "public"."v_parlamentar_socio_emenda" IS 'Parlamentar que é sócio de empresa que recebeu emenda. Cruza cnpj_socios.cpf_cnpj_socio × parlamentares.cpf × emendas_favorecidos.';

COMMENT ON VIEW "public"."v_pncp_pub_por_fornecedor" IS 'Ranking de fornecedores de publicidade federal. Produto: "Quem são as agências que vivem do governo?"';

COMMENT ON VIEW "public"."v_pncp_pub_por_orgao" IS 'Ranking de gastos com publicidade por órgão federal (PNCP). Produto: "Quem mais gasta com publicidade no governo federal?"';

COMMENT ON VIEW "public"."v_sancao_doacao" IS 'Empresas sancionadas (CEIS/CNEP) que doaram para campanhas eleitorais. Cruza sancoes.cpf_cnpj com tse_receitas.cpf_cnpj_doador.';

COMMENT ON VIEW "public"."v_sancao_emenda" IS 'Empresas sancionadas (CEIS/CNEP) que receberam emendas parlamentares. Cruza sancoes.cpf_cnpj com emendas_favorecidos.codigo_favorecido. Alerta: não considera vigência da sanção vs. data da emenda — filtrar se necessário.';

COMMENT ON TABLE "public"."voos_senado" IS 'Passagens aéreas da cota do Senado, nível-perna, parseadas de ceaps_senado_brutas.detalhamento. valor_reembolsado_doc é por documento (cod_documento) — agregações de gasto devem deduplicar por documento.';

COMMENT ON VIEW "public"."vw_sebrae_cnpj_emendas" IS 'Fornecedores SEBRAE agrupados por CNPJ/UF — base para cruzamento com emendas parlamentares e TSE.';

COMMENT ON VIEW "public"."vw_senac_cnpj_emendas" IS 'Fornecedores SENAC agrupados por CNPJ/regional — base para cruzamento com emendas e doações TSE.';

COMMENT ON VIEW "public"."vw_senar_cnpj_emendas" IS 'Fornecedores e beneficiários SENAR agrupados por CNPJ — base para cruzamento com emendas e doações TSE.';

COMMENT ON VIEW "public"."vw_sesc_cnpj_emendas" IS 'Fornecedores SESC agrupados por CNPJ/portal — base para cruzamento com emendas e doações TSE.';

COMMENT ON VIEW "public"."vw_sisi_cnpj_emendas" IS 'Fornecedores SESI/SENAI agrupados por CNPJ — base para cruzamento com emendas parlamentares e doações TSE.';
-- bloco 15_grants — gerado por split_baseline.py (ordem interna = ordem do dump)
GRANT USAGE ON SCHEMA "bcb" TO "service_role";

GRANT USAGE ON SCHEMA "bcb" TO "anon";

GRANT USAGE ON SCHEMA "bcb" TO "authenticated";

GRANT USAGE ON SCHEMA "public" TO "postgres";

GRANT USAGE ON SCHEMA "public" TO "anon";

GRANT USAGE ON SCHEMA "public" TO "authenticated";

GRANT USAGE ON SCHEMA "public" TO "service_role";

GRANT USAGE ON SCHEMA "public_api" TO "anon";

GRANT USAGE ON SCHEMA "public_api" TO "authenticated";

GRANT USAGE ON SCHEMA "public_api" TO "service_role";

GRANT ALL ON FUNCTION "public"."alerta_audiencias_semana"() TO "service_role";

GRANT ALL ON FUNCTION "public"."alerta_combo_sancao_emenda"() TO "service_role";

GRANT ALL ON FUNCTION "public"."alerta_ministerio_emenda"() TO "service_role";

GRANT ALL ON FUNCTION "public"."alerta_ministerio_sancao"() TO "service_role";

GRANT ALL ON FUNCTION "public"."alerta_ranking_privados"() TO "service_role";

REVOKE ALL ON FUNCTION "public"."ask_quota_check_increment"("p_user_id" "uuid", "p_limit" integer) FROM PUBLIC;

GRANT ALL ON FUNCTION "public"."ask_quota_check_increment"("p_user_id" "uuid", "p_limit" integer) TO "anon";

GRANT ALL ON FUNCTION "public"."ask_quota_check_increment"("p_user_id" "uuid", "p_limit" integer) TO "authenticated";

GRANT ALL ON FUNCTION "public"."ask_quota_check_increment"("p_user_id" "uuid", "p_limit" integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."buscar_emendas_municipio"("p_uf" "text", "p_slug" "text") TO "anon";

GRANT ALL ON FUNCTION "public"."buscar_emendas_municipio"("p_uf" "text", "p_slug" "text") TO "authenticated";

GRANT ALL ON FUNCTION "public"."buscar_emendas_municipio"("p_uf" "text", "p_slug" "text") TO "service_role";

GRANT ALL ON FUNCTION "public"."buscar_processos"("q" "text", "p_tribunal" "text", "p_classe" "text", "p_relator" "text", "p_data_inicio" "date", "p_data_fim" "date", "p_page" integer, "p_page_size" integer) TO "anon";

GRANT ALL ON FUNCTION "public"."buscar_processos"("q" "text", "p_tribunal" "text", "p_classe" "text", "p_relator" "text", "p_data_inicio" "date", "p_data_fim" "date", "p_page" integer, "p_page_size" integer) TO "authenticated";

GRANT ALL ON FUNCTION "public"."buscar_processos"("q" "text", "p_tribunal" "text", "p_classe" "text", "p_relator" "text", "p_data_inicio" "date", "p_data_fim" "date", "p_page" integer, "p_page_size" integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."buscar_processos_judiciario"("q" "text", "p_tribunal" "text", "p_classe" "text", "p_limit" integer, "p_offset" integer) TO "anon";

GRANT ALL ON FUNCTION "public"."buscar_processos_judiciario"("q" "text", "p_tribunal" "text", "p_classe" "text", "p_limit" integer, "p_offset" integer) TO "authenticated";

GRANT ALL ON FUNCTION "public"."buscar_processos_judiciario"("q" "text", "p_tribunal" "text", "p_classe" "text", "p_limit" integer, "p_offset" integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."computar_votacoes_agg"("p_legislatura" integer) TO "anon";

GRANT ALL ON FUNCTION "public"."computar_votacoes_agg"("p_legislatura" integer) TO "authenticated";

GRANT ALL ON FUNCTION "public"."computar_votacoes_agg"("p_legislatura" integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."cvm_fip_monopolio_historico"("p_cnpj" "text") TO "anon";

GRANT ALL ON FUNCTION "public"."cvm_fip_monopolio_historico"("p_cnpj" "text") TO "authenticated";

GRANT ALL ON FUNCTION "public"."cvm_fip_monopolio_historico"("p_cnpj" "text") TO "service_role";

GRANT ALL ON FUNCTION "public"."cvm_grafo_vizinhanca"("p_cnpj" "text", "p_prof" integer) TO "anon";

GRANT ALL ON FUNCTION "public"."cvm_grafo_vizinhanca"("p_cnpj" "text", "p_prof" integer) TO "authenticated";

GRANT ALL ON FUNCTION "public"."cvm_grafo_vizinhanca"("p_cnpj" "text", "p_prof" integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."detect_narrative_events"() TO "anon";

GRANT ALL ON FUNCTION "public"."detect_narrative_events"() TO "authenticated";

GRANT ALL ON FUNCTION "public"."detect_narrative_events"() TO "service_role";

REVOKE ALL ON FUNCTION "public"."distinct_dates"("p_table" "text", "p_date_col" "text", "p_since" "date") FROM PUBLIC;

GRANT ALL ON FUNCTION "public"."distinct_dates"("p_table" "text", "p_date_col" "text", "p_since" "date") TO "anon";

GRANT ALL ON FUNCTION "public"."distinct_dates"("p_table" "text", "p_date_col" "text", "p_since" "date") TO "authenticated";

GRANT ALL ON FUNCTION "public"."distinct_dates"("p_table" "text", "p_date_col" "text", "p_since" "date") TO "service_role";

REVOKE ALL ON FUNCTION "public"."exec_readonly_query"("sql_query" "text") FROM PUBLIC;

GRANT ALL ON FUNCTION "public"."exec_readonly_query"("sql_query" "text") TO "service_role";

REVOKE ALL ON FUNCTION "public"."execute_sql"("query" "text") FROM PUBLIC;

GRANT ALL ON FUNCTION "public"."execute_sql"("query" "text") TO "anon";

GRANT ALL ON FUNCTION "public"."execute_sql"("query" "text") TO "authenticated";

GRANT ALL ON FUNCTION "public"."execute_sql"("query" "text") TO "service_role";

GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";

GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";

GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";

GRANT ALL ON FUNCTION "public"."limpar_ask_cache_expirado"() TO "anon";

GRANT ALL ON FUNCTION "public"."limpar_ask_cache_expirado"() TO "authenticated";

GRANT ALL ON FUNCTION "public"."limpar_ask_cache_expirado"() TO "service_role";

REVOKE ALL ON FUNCTION "public"."months_present"("p_table" "text", "p_date_col" "text") FROM PUBLIC;

GRANT ALL ON FUNCTION "public"."months_present"("p_table" "text", "p_date_col" "text") TO "anon";

GRANT ALL ON FUNCTION "public"."months_present"("p_table" "text", "p_date_col" "text") TO "authenticated";

GRANT ALL ON FUNCTION "public"."months_present"("p_table" "text", "p_date_col" "text") TO "service_role";

REVOKE ALL ON FUNCTION "public"."premium_aggregate"("p_source" "text", "p_sum_col" "text", "p_filters" "jsonb") FROM PUBLIC;

GRANT ALL ON FUNCTION "public"."premium_aggregate"("p_source" "text", "p_sum_col" "text", "p_filters" "jsonb") TO "service_role";

GRANT ALL ON FUNCTION "public"."refresh_almg_fornecedores_intersetados"() TO "anon";

GRANT ALL ON FUNCTION "public"."refresh_almg_fornecedores_intersetados"() TO "authenticated";

GRANT ALL ON FUNCTION "public"."refresh_almg_fornecedores_intersetados"() TO "service_role";

GRANT ALL ON FUNCTION "public"."refresh_ask_views"() TO "anon";

GRANT ALL ON FUNCTION "public"."refresh_ask_views"() TO "authenticated";

GRANT ALL ON FUNCTION "public"."refresh_ask_views"() TO "service_role";

GRANT ALL ON FUNCTION "public"."refresh_cota_cnpj_ranking"() TO "anon";

GRANT ALL ON FUNCTION "public"."refresh_cota_cnpj_ranking"() TO "authenticated";

GRANT ALL ON FUNCTION "public"."refresh_cota_cnpj_ranking"() TO "service_role";

GRANT ALL ON FUNCTION "public"."refresh_fornecedores_intersetados"() TO "anon";

GRANT ALL ON FUNCTION "public"."refresh_fornecedores_intersetados"() TO "authenticated";

GRANT ALL ON FUNCTION "public"."refresh_fornecedores_intersetados"() TO "service_role";

GRANT ALL ON FUNCTION "public"."refresh_indice_poder"() TO "anon";

GRANT ALL ON FUNCTION "public"."refresh_indice_poder"() TO "authenticated";

GRANT ALL ON FUNCTION "public"."refresh_indice_poder"() TO "service_role";

GRANT ALL ON FUNCTION "public"."refresh_judiciario_stats"() TO "anon";

GRANT ALL ON FUNCTION "public"."refresh_judiciario_stats"() TO "authenticated";

GRANT ALL ON FUNCTION "public"."refresh_judiciario_stats"() TO "service_role";

GRANT ALL ON FUNCTION "public"."refresh_mv_cota_fornecedor"() TO "anon";

GRANT ALL ON FUNCTION "public"."refresh_mv_cota_fornecedor"() TO "authenticated";

GRANT ALL ON FUNCTION "public"."refresh_mv_cota_fornecedor"() TO "service_role";

GRANT ALL ON FUNCTION "public"."refresh_mv_execucao_emendas"() TO "anon";

GRANT ALL ON FUNCTION "public"."refresh_mv_execucao_emendas"() TO "authenticated";

GRANT ALL ON FUNCTION "public"."refresh_mv_execucao_emendas"() TO "service_role";

GRANT ALL ON FUNCTION "public"."refresh_mv_scorecard_cnpj"() TO "anon";

GRANT ALL ON FUNCTION "public"."refresh_mv_scorecard_cnpj"() TO "authenticated";

GRANT ALL ON FUNCTION "public"."refresh_mv_scorecard_cnpj"() TO "service_role";

GRANT ALL ON FUNCTION "public"."refresh_mv_tse_ads_digitais"() TO "anon";

GRANT ALL ON FUNCTION "public"."refresh_mv_tse_ads_digitais"() TO "authenticated";

GRANT ALL ON FUNCTION "public"."refresh_mv_tse_ads_digitais"() TO "service_role";

GRANT ALL ON FUNCTION "public"."refresh_stats"() TO "anon";

GRANT ALL ON FUNCTION "public"."refresh_stats"() TO "authenticated";

GRANT ALL ON FUNCTION "public"."refresh_stats"() TO "service_role";

GRANT ALL ON FUNCTION "public"."search_fundacoes"("termo" "text", "partido" "text", "so_alertas" boolean, "limite" integer) TO "anon";

GRANT ALL ON FUNCTION "public"."search_fundacoes"("termo" "text", "partido" "text", "so_alertas" boolean, "limite" integer) TO "authenticated";

GRANT ALL ON FUNCTION "public"."search_fundacoes"("termo" "text", "partido" "text", "so_alertas" boolean, "limite" integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."set_cnpjs_limit"() TO "anon";

GRANT ALL ON FUNCTION "public"."set_cnpjs_limit"() TO "authenticated";

GRANT ALL ON FUNCTION "public"."set_cnpjs_limit"() TO "service_role";

GRANT ALL ON FUNCTION "public"."siafi_stats"() TO "anon";

GRANT ALL ON FUNCTION "public"."siafi_stats"() TO "authenticated";

GRANT ALL ON FUNCTION "public"."siafi_stats"() TO "service_role";

GRANT ALL ON FUNCTION "public"."stf_refresh_matviews"() TO "anon";

GRANT ALL ON FUNCTION "public"."stf_refresh_matviews"() TO "authenticated";

GRANT ALL ON FUNCTION "public"."stf_refresh_matviews"() TO "service_role";

GRANT ALL ON TABLE "public"."emendas" TO "anon";

GRANT ALL ON TABLE "public"."emendas" TO "authenticated";

GRANT ALL ON TABLE "public"."emendas" TO "service_role";

GRANT ALL ON TABLE "public"."mandatos" TO "anon";

GRANT ALL ON TABLE "public"."mandatos" TO "authenticated";

GRANT ALL ON TABLE "public"."mandatos" TO "service_role";

GRANT ALL ON TABLE "public"."parlamentares" TO "anon";

GRANT ALL ON TABLE "public"."parlamentares" TO "authenticated";

GRANT ALL ON TABLE "public"."parlamentares" TO "service_role";

GRANT SELECT ON TABLE "public_api"."vw_public_ranking" TO "anon";

GRANT SELECT ON TABLE "public_api"."vw_public_ranking" TO "authenticated";

GRANT SELECT ON TABLE "public_api"."vw_public_ranking" TO "service_role";

GRANT ALL ON TABLE "bcb"."if_balanco" TO "service_role";

GRANT SELECT ON TABLE "bcb"."if_balanco" TO "anon";

GRANT SELECT ON TABLE "bcb"."if_balanco" TO "authenticated";

GRANT SELECT,USAGE ON SEQUENCE "bcb"."if_balanco_id_seq" TO "service_role";

GRANT ALL ON TABLE "bcb"."if_cadastro" TO "service_role";

GRANT SELECT ON TABLE "bcb"."if_cadastro" TO "anon";

GRANT SELECT ON TABLE "bcb"."if_cadastro" TO "authenticated";

GRANT ALL ON TABLE "bcb"."scr_operacoes" TO "service_role";

GRANT SELECT ON TABLE "bcb"."scr_operacoes" TO "anon";

GRANT SELECT ON TABLE "bcb"."scr_operacoes" TO "authenticated";

GRANT SELECT,USAGE ON SEQUENCE "bcb"."scr_operacoes_id_seq" TO "service_role";

GRANT ALL ON TABLE "bcb"."sicor_credito_rural" TO "service_role";

GRANT SELECT ON TABLE "bcb"."sicor_credito_rural" TO "anon";

GRANT SELECT ON TABLE "bcb"."sicor_credito_rural" TO "authenticated";

GRANT SELECT,USAGE ON SEQUENCE "bcb"."sicor_credito_rural_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."emendas_favorecidos" TO "anon";

GRANT ALL ON TABLE "public"."emendas_favorecidos" TO "authenticated";

GRANT ALL ON TABLE "public"."emendas_favorecidos" TO "service_role";

GRANT ALL ON TABLE "bcb"."v_emendas_x_sicor" TO "service_role";

GRANT SELECT ON TABLE "bcb"."v_emendas_x_sicor" TO "anon";

GRANT SELECT ON TABLE "bcb"."v_emendas_x_sicor" TO "authenticated";

GRANT ALL ON TABLE "bcb"."v_scr_resumo_uf" TO "service_role";

GRANT SELECT ON TABLE "bcb"."v_scr_resumo_uf" TO "anon";

GRANT SELECT ON TABLE "bcb"."v_scr_resumo_uf" TO "authenticated";

GRANT ALL ON TABLE "public"."agenda_camara_eventos" TO "anon";

GRANT ALL ON TABLE "public"."agenda_camara_eventos" TO "authenticated";

GRANT ALL ON TABLE "public"."agenda_camara_eventos" TO "service_role";

GRANT ALL ON TABLE "public"."agenda_audiencias_publicas" TO "anon";

GRANT ALL ON TABLE "public"."agenda_audiencias_publicas" TO "authenticated";

GRANT ALL ON TABLE "public"."agenda_audiencias_publicas" TO "service_role";

GRANT ALL ON TABLE "public"."agenda_executivo_compromissos" TO "anon";

GRANT ALL ON TABLE "public"."agenda_executivo_compromissos" TO "authenticated";

GRANT ALL ON TABLE "public"."agenda_executivo_compromissos" TO "service_role";

GRANT ALL ON TABLE "public"."agenda_senado_comissoes" TO "anon";

GRANT ALL ON TABLE "public"."agenda_senado_comissoes" TO "authenticated";

GRANT ALL ON TABLE "public"."agenda_senado_comissoes" TO "service_role";

GRANT ALL ON TABLE "public"."agenda_senado_plenario" TO "anon";

GRANT ALL ON TABLE "public"."agenda_senado_plenario" TO "authenticated";

GRANT ALL ON TABLE "public"."agenda_senado_plenario" TO "service_role";

GRANT ALL ON TABLE "public"."agenda_federal_completa" TO "anon";

GRANT ALL ON TABLE "public"."agenda_federal_completa" TO "authenticated";

GRANT ALL ON TABLE "public"."agenda_federal_completa" TO "service_role";

GRANT ALL ON TABLE "public"."agenda_ingest_log" TO "anon";

GRANT ALL ON TABLE "public"."agenda_ingest_log" TO "authenticated";

GRANT ALL ON TABLE "public"."agenda_ingest_log" TO "service_role";

GRANT ALL ON TABLE "public"."agenda_legislativo_semana" TO "anon";

GRANT ALL ON TABLE "public"."agenda_legislativo_semana" TO "authenticated";

GRANT ALL ON TABLE "public"."agenda_legislativo_semana" TO "service_role";

GRANT ALL ON TABLE "public"."agenda_ministerial_semana" TO "anon";

GRANT ALL ON TABLE "public"."agenda_ministerial_semana" TO "authenticated";

GRANT ALL ON TABLE "public"."agenda_ministerial_semana" TO "service_role";

GRANT ALL ON TABLE "public"."agenda_ministerial_setor_privado" TO "anon";

GRANT ALL ON TABLE "public"."agenda_ministerial_setor_privado" TO "authenticated";

GRANT ALL ON TABLE "public"."agenda_ministerial_setor_privado" TO "service_role";

GRANT ALL ON TABLE "public"."ale_casas" TO "anon";

GRANT ALL ON TABLE "public"."ale_casas" TO "authenticated";

GRANT ALL ON TABLE "public"."ale_casas" TO "service_role";

GRANT ALL ON TABLE "public"."ale_ingest_runs" TO "anon";

GRANT ALL ON TABLE "public"."ale_ingest_runs" TO "authenticated";

GRANT ALL ON TABLE "public"."ale_ingest_runs" TO "service_role";

GRANT ALL ON TABLE "public"."ale_parlamentares" TO "anon";

GRANT ALL ON TABLE "public"."ale_parlamentares" TO "authenticated";

GRANT ALL ON TABLE "public"."ale_parlamentares" TO "service_role";

GRANT ALL ON TABLE "public"."casas" TO "anon";

GRANT ALL ON TABLE "public"."casas" TO "authenticated";

GRANT ALL ON TABLE "public"."casas" TO "service_role";

GRANT ALL ON TABLE "public"."parlamentares_estaduais" TO "anon";

GRANT ALL ON TABLE "public"."parlamentares_estaduais" TO "authenticated";

GRANT ALL ON TABLE "public"."parlamentares_estaduais" TO "service_role";

GRANT ALL ON TABLE "public"."alesp_deputados" TO "anon";

GRANT ALL ON TABLE "public"."alesp_deputados" TO "authenticated";

GRANT ALL ON TABLE "public"."alesp_deputados" TO "service_role";

GRANT ALL ON TABLE "public"."ale_parlamentares_reconciliado" TO "anon";

GRANT ALL ON TABLE "public"."ale_parlamentares_reconciliado" TO "authenticated";

GRANT ALL ON TABLE "public"."ale_parlamentares_reconciliado" TO "service_role";

GRANT ALL ON TABLE "public"."ale_proposicoes" TO "anon";

GRANT ALL ON TABLE "public"."ale_proposicoes" TO "authenticated";

GRANT ALL ON TABLE "public"."ale_proposicoes" TO "service_role";

GRANT ALL ON TABLE "public"."ale_votacoes" TO "anon";

GRANT ALL ON TABLE "public"."ale_votacoes" TO "authenticated";

GRANT ALL ON TABLE "public"."ale_votacoes" TO "service_role";

GRANT ALL ON TABLE "public"."ale_votos" TO "anon";

GRANT ALL ON TABLE "public"."ale_votos" TO "authenticated";

GRANT ALL ON TABLE "public"."ale_votos" TO "service_role";

GRANT ALL ON TABLE "public"."aleba_deputados" TO "anon";

GRANT ALL ON TABLE "public"."aleba_deputados" TO "authenticated";

GRANT ALL ON TABLE "public"."aleba_deputados" TO "service_role";

GRANT ALL ON TABLE "public"."aleba_despesas" TO "anon";

GRANT ALL ON TABLE "public"."aleba_despesas" TO "authenticated";

GRANT ALL ON TABLE "public"."aleba_despesas" TO "service_role";

GRANT ALL ON SEQUENCE "public"."aleba_despesas_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."aleba_despesas_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."aleba_despesas_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."alepe_deputados" TO "anon";

GRANT ALL ON TABLE "public"."alepe_deputados" TO "authenticated";

GRANT ALL ON TABLE "public"."alepe_deputados" TO "service_role";

GRANT ALL ON TABLE "public"."gastos_parlamentares" TO "anon";

GRANT ALL ON TABLE "public"."gastos_parlamentares" TO "authenticated";

GRANT ALL ON TABLE "public"."gastos_parlamentares" TO "service_role";

GRANT ALL ON TABLE "public"."alepe_verba_indenizatoria" TO "anon";

GRANT ALL ON TABLE "public"."alepe_verba_indenizatoria" TO "authenticated";

GRANT ALL ON TABLE "public"."alepe_verba_indenizatoria" TO "service_role";

GRANT ALL ON TABLE "public"."alepe_verba_resumo_mensal" TO "anon";

GRANT ALL ON TABLE "public"."alepe_verba_resumo_mensal" TO "authenticated";

GRANT ALL ON TABLE "public"."alepe_verba_resumo_mensal" TO "service_role";

GRANT ALL ON TABLE "public"."alertas_processo" TO "anon";

GRANT ALL ON TABLE "public"."alertas_processo" TO "authenticated";

GRANT ALL ON TABLE "public"."alertas_processo" TO "service_role";

GRANT ALL ON TABLE "public"."alerts_history" TO "anon";

GRANT ALL ON TABLE "public"."alerts_history" TO "authenticated";

GRANT ALL ON TABLE "public"."alerts_history" TO "service_role";

GRANT ALL ON TABLE "public"."alesc_deputados" TO "anon";

GRANT ALL ON TABLE "public"."alesc_deputados" TO "authenticated";

GRANT ALL ON TABLE "public"."alesc_deputados" TO "service_role";

GRANT ALL ON TABLE "public"."alesc_despesas" TO "anon";

GRANT ALL ON TABLE "public"."alesc_despesas" TO "authenticated";

GRANT ALL ON TABLE "public"."alesc_despesas" TO "service_role";

GRANT ALL ON SEQUENCE "public"."alesc_despesas_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."alesc_despesas_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."alesc_despesas_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."alesp_despesas_gabinete" TO "anon";

GRANT ALL ON TABLE "public"."alesp_despesas_gabinete" TO "authenticated";

GRANT ALL ON TABLE "public"."alesp_despesas_gabinete" TO "service_role";

GRANT ALL ON TABLE "public"."alesp_despesas_resumo_mensal" TO "anon";

GRANT ALL ON TABLE "public"."alesp_despesas_resumo_mensal" TO "authenticated";

GRANT ALL ON TABLE "public"."alesp_despesas_resumo_mensal" TO "service_role";

GRANT ALL ON TABLE "public"."almg_deputados" TO "anon";

GRANT ALL ON TABLE "public"."almg_deputados" TO "authenticated";

GRANT ALL ON TABLE "public"."almg_deputados" TO "service_role";

GRANT ALL ON TABLE "public"."ceaps_brutas" TO "anon";

GRANT ALL ON TABLE "public"."ceaps_brutas" TO "authenticated";

GRANT ALL ON TABLE "public"."ceaps_brutas" TO "service_role";

GRANT ALL ON TABLE "public"."almg_fornecedores_intersetados" TO "anon";

GRANT ALL ON TABLE "public"."almg_fornecedores_intersetados" TO "authenticated";

GRANT ALL ON TABLE "public"."almg_fornecedores_intersetados" TO "service_role";

GRANT ALL ON TABLE "public"."almg_verba_indenizatoria" TO "anon";

GRANT ALL ON TABLE "public"."almg_verba_indenizatoria" TO "authenticated";

GRANT ALL ON TABLE "public"."almg_verba_indenizatoria" TO "service_role";

GRANT ALL ON TABLE "public"."almg_verba_resumo_mensal" TO "anon";

GRANT ALL ON TABLE "public"."almg_verba_resumo_mensal" TO "authenticated";

GRANT ALL ON TABLE "public"."almg_verba_resumo_mensal" TO "service_role";

GRANT ALL ON TABLE "public"."api_rate_state" TO "anon";

GRANT ALL ON TABLE "public"."api_rate_state" TO "authenticated";

GRANT ALL ON TABLE "public"."api_rate_state" TO "service_role";

GRANT ALL ON TABLE "public"."ask_cache" TO "anon";

GRANT ALL ON TABLE "public"."ask_cache" TO "authenticated";

GRANT ALL ON TABLE "public"."ask_cache" TO "service_role";

GRANT ALL ON TABLE "public"."cam_parlamentar_risco" TO "anon";

GRANT ALL ON TABLE "public"."cam_parlamentar_risco" TO "authenticated";

GRANT ALL ON TABLE "public"."cam_parlamentar_risco" TO "service_role";

GRANT ALL ON TABLE "public"."ask_ceap_deputado_ano_agg" TO "anon";

GRANT ALL ON TABLE "public"."ask_ceap_deputado_ano_agg" TO "authenticated";

GRANT ALL ON TABLE "public"."ask_ceap_deputado_ano_agg" TO "service_role";

GRANT ALL ON TABLE "public"."ask_ceap_fornecedor_agg" TO "anon";

GRANT ALL ON TABLE "public"."ask_ceap_fornecedor_agg" TO "authenticated";

GRANT ALL ON TABLE "public"."ask_ceap_fornecedor_agg" TO "service_role";

GRANT ALL ON TABLE "public"."ask_ceap_tipo_ano_agg" TO "anon";

GRANT ALL ON TABLE "public"."ask_ceap_tipo_ano_agg" TO "authenticated";

GRANT ALL ON TABLE "public"."ask_ceap_tipo_ano_agg" TO "service_role";

GRANT ALL ON TABLE "public"."emendas_completas" TO "anon";

GRANT ALL ON TABLE "public"."emendas_completas" TO "authenticated";

GRANT ALL ON TABLE "public"."emendas_completas" TO "service_role";

GRANT ALL ON TABLE "public"."ask_emendas_autor_ano_agg" TO "anon";

GRANT ALL ON TABLE "public"."ask_emendas_autor_ano_agg" TO "authenticated";

GRANT ALL ON TABLE "public"."ask_emendas_autor_ano_agg" TO "service_role";

GRANT ALL ON TABLE "public"."ask_log" TO "anon";

GRANT ALL ON TABLE "public"."ask_log" TO "authenticated";

GRANT ALL ON TABLE "public"."ask_log" TO "service_role";

GRANT ALL ON TABLE "public"."ask_perguntas_populares" TO "anon";

GRANT ALL ON TABLE "public"."ask_perguntas_populares" TO "authenticated";

GRANT ALL ON TABLE "public"."ask_perguntas_populares" TO "service_role";

GRANT ALL ON TABLE "public"."ask_quota" TO "anon";

GRANT ALL ON TABLE "public"."ask_quota" TO "authenticated";

GRANT ALL ON TABLE "public"."ask_quota" TO "service_role";

GRANT ALL ON TABLE "public"."assessores" TO "anon";

GRANT ALL ON TABLE "public"."assessores" TO "authenticated";

GRANT ALL ON TABLE "public"."assessores" TO "service_role";

GRANT ALL ON SEQUENCE "public"."assessores_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."assessores_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."assessores_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."authority_metrics" TO "anon";

GRANT ALL ON TABLE "public"."authority_metrics" TO "authenticated";

GRANT ALL ON TABLE "public"."authority_metrics" TO "service_role";

GRANT ALL ON TABLE "public"."auto_briefings" TO "anon";

GRANT ALL ON TABLE "public"."auto_briefings" TO "authenticated";

GRANT ALL ON TABLE "public"."auto_briefings" TO "service_role";

GRANT ALL ON TABLE "public"."autores_orcamentarios" TO "anon";

GRANT ALL ON TABLE "public"."autores_orcamentarios" TO "authenticated";

GRANT ALL ON TABLE "public"."autores_orcamentarios" TO "service_role";

GRANT ALL ON TABLE "public"."autores_parlamentares_map" TO "anon";

GRANT ALL ON TABLE "public"."autores_parlamentares_map" TO "authenticated";

GRANT ALL ON TABLE "public"."autores_parlamentares_map" TO "service_role";

GRANT ALL ON SEQUENCE "public"."autores_parlamentares_map_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."autores_parlamentares_map_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."autores_parlamentares_map_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."b3_empresas_listadas" TO "anon";

GRANT ALL ON TABLE "public"."b3_empresas_listadas" TO "authenticated";

GRANT ALL ON TABLE "public"."b3_empresas_listadas" TO "service_role";

GRANT ALL ON TABLE "public"."b3_tickers" TO "anon";

GRANT ALL ON TABLE "public"."b3_tickers" TO "authenticated";

GRANT ALL ON TABLE "public"."b3_tickers" TO "service_role";

GRANT ALL ON TABLE "public"."banks" TO "anon";

GRANT ALL ON TABLE "public"."banks" TO "authenticated";

GRANT ALL ON TABLE "public"."banks" TO "service_role";

GRANT ALL ON TABLE "public"."beneficios_parlamentares" TO "anon";

GRANT ALL ON TABLE "public"."beneficios_parlamentares" TO "authenticated";

GRANT ALL ON TABLE "public"."beneficios_parlamentares" TO "service_role";

GRANT ALL ON TABLE "public"."bets_licenciadas" TO "anon";

GRANT ALL ON TABLE "public"."bets_licenciadas" TO "authenticated";

GRANT ALL ON TABLE "public"."bets_licenciadas" TO "service_role";

GRANT ALL ON SEQUENCE "public"."bets_licenciadas_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."bets_licenciadas_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."bets_licenciadas_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."cam_comissoes" TO "anon";

GRANT ALL ON TABLE "public"."cam_comissoes" TO "authenticated";

GRANT ALL ON TABLE "public"."cam_comissoes" TO "service_role";

GRANT ALL ON TABLE "public"."cam_comissoes_membros" TO "anon";

GRANT ALL ON TABLE "public"."cam_comissoes_membros" TO "authenticated";

GRANT ALL ON TABLE "public"."cam_comissoes_membros" TO "service_role";

GRANT ALL ON TABLE "public"."cam_frentes" TO "anon";

GRANT ALL ON TABLE "public"."cam_frentes" TO "authenticated";

GRANT ALL ON TABLE "public"."cam_frentes" TO "service_role";

GRANT ALL ON TABLE "public"."cam_frentes_membros" TO "anon";

GRANT ALL ON TABLE "public"."cam_frentes_membros" TO "authenticated";

GRANT ALL ON TABLE "public"."cam_frentes_membros" TO "service_role";

GRANT ALL ON TABLE "public"."cam_proposicoes" TO "anon";

GRANT ALL ON TABLE "public"."cam_proposicoes" TO "authenticated";

GRANT ALL ON TABLE "public"."cam_proposicoes" TO "service_role";

GRANT ALL ON TABLE "public"."cam_proposicoes_agg" TO "anon";

GRANT ALL ON TABLE "public"."cam_proposicoes_agg" TO "authenticated";

GRANT ALL ON TABLE "public"."cam_proposicoes_agg" TO "service_role";

GRANT ALL ON TABLE "public"."camara_frente" TO "anon";

GRANT ALL ON TABLE "public"."camara_frente" TO "authenticated";

GRANT ALL ON TABLE "public"."camara_frente" TO "service_role";

GRANT ALL ON TABLE "public"."camara_frente_membro" TO "anon";

GRANT ALL ON TABLE "public"."camara_frente_membro" TO "authenticated";

GRANT ALL ON TABLE "public"."camara_frente_membro" TO "service_role";

GRANT ALL ON TABLE "public"."camara_ocupacao" TO "anon";

GRANT ALL ON TABLE "public"."camara_ocupacao" TO "authenticated";

GRANT ALL ON TABLE "public"."camara_ocupacao" TO "service_role";

GRANT ALL ON TABLE "public"."cambio_cotacoes" TO "anon";

GRANT ALL ON TABLE "public"."cambio_cotacoes" TO "authenticated";

GRANT ALL ON TABLE "public"."cambio_cotacoes" TO "service_role";

GRANT ALL ON TABLE "public"."cambio_moedas" TO "anon";

GRANT ALL ON TABLE "public"."cambio_moedas" TO "authenticated";

GRANT ALL ON TABLE "public"."cambio_moedas" TO "service_role";

GRANT ALL ON SEQUENCE "public"."casas_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."casas_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."casas_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."cbf_cnpjs_vinculados" TO "anon";

GRANT ALL ON TABLE "public"."cbf_cnpjs_vinculados" TO "authenticated";

GRANT ALL ON TABLE "public"."cbf_cnpjs_vinculados" TO "service_role";

GRANT ALL ON SEQUENCE "public"."cbf_cnpjs_vinculados_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."cbf_cnpjs_vinculados_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."cbf_cnpjs_vinculados_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."cbf_socios_federacoes" TO "anon";

GRANT ALL ON TABLE "public"."cbf_socios_federacoes" TO "authenticated";

GRANT ALL ON TABLE "public"."cbf_socios_federacoes" TO "service_role";

GRANT ALL ON TABLE "public"."cbf_institutos_emendas" TO "anon";

GRANT ALL ON TABLE "public"."cbf_institutos_emendas" TO "authenticated";

GRANT ALL ON TABLE "public"."cbf_institutos_emendas" TO "service_role";

GRANT ALL ON SEQUENCE "public"."cbf_socios_federacoes_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."cbf_socios_federacoes_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."cbf_socios_federacoes_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."ceaf_expulsoes" TO "anon";

GRANT ALL ON TABLE "public"."ceaf_expulsoes" TO "authenticated";

GRANT ALL ON TABLE "public"."ceaf_expulsoes" TO "service_role";

GRANT ALL ON TABLE "public"."ceaf_ingest_log" TO "anon";

GRANT ALL ON TABLE "public"."ceaf_ingest_log" TO "authenticated";

GRANT ALL ON TABLE "public"."ceaf_ingest_log" TO "service_role";

GRANT ALL ON SEQUENCE "public"."ceaf_ingest_log_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."ceaf_ingest_log_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."ceaf_ingest_log_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."ceaf_ranking_orgaos" TO "anon";

GRANT ALL ON TABLE "public"."ceaf_ranking_orgaos" TO "authenticated";

GRANT ALL ON TABLE "public"."ceaf_ranking_orgaos" TO "service_role";

GRANT ALL ON TABLE "public"."ceaf_serie_temporal" TO "anon";

GRANT ALL ON TABLE "public"."ceaf_serie_temporal" TO "authenticated";

GRANT ALL ON TABLE "public"."ceaf_serie_temporal" TO "service_role";

GRANT ALL ON TABLE "public"."cgu_pad_processos" TO "anon";

GRANT ALL ON TABLE "public"."cgu_pad_processos" TO "authenticated";

GRANT ALL ON TABLE "public"."cgu_pad_processos" TO "service_role";

GRANT ALL ON TABLE "public"."ceaf_x_cgu_pad" TO "anon";

GRANT ALL ON TABLE "public"."ceaf_x_cgu_pad" TO "authenticated";

GRANT ALL ON TABLE "public"."ceaf_x_cgu_pad" TO "service_role";

GRANT ALL ON TABLE "public"."ceaps_ranking" TO "anon";

GRANT ALL ON TABLE "public"."ceaps_ranking" TO "authenticated";

GRANT ALL ON TABLE "public"."ceaps_ranking" TO "service_role";

GRANT ALL ON TABLE "public"."ceaps_senado_brutas" TO "anon";

GRANT ALL ON TABLE "public"."ceaps_senado_brutas" TO "authenticated";

GRANT ALL ON TABLE "public"."ceaps_senado_brutas" TO "service_role";

GRANT ALL ON TABLE "public"."ceaps_senado_ranking" TO "anon";

GRANT ALL ON TABLE "public"."ceaps_senado_ranking" TO "authenticated";

GRANT ALL ON TABLE "public"."ceaps_senado_ranking" TO "service_role";

GRANT ALL ON TABLE "public"."cgu_pad_ingest_log" TO "anon";

GRANT ALL ON TABLE "public"."cgu_pad_ingest_log" TO "authenticated";

GRANT ALL ON TABLE "public"."cgu_pad_ingest_log" TO "service_role";

GRANT ALL ON SEQUENCE "public"."cgu_pad_ingest_log_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."cgu_pad_ingest_log_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."cgu_pad_ingest_log_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."cgu_pad_ranking_orgaos" TO "anon";

GRANT ALL ON TABLE "public"."cgu_pad_ranking_orgaos" TO "authenticated";

GRANT ALL ON TABLE "public"."cgu_pad_ranking_orgaos" TO "service_role";

GRANT ALL ON TABLE "public"."cgu_pad_serie_temporal" TO "anon";

GRANT ALL ON TABLE "public"."cgu_pad_serie_temporal" TO "authenticated";

GRANT ALL ON TABLE "public"."cgu_pad_serie_temporal" TO "service_role";

GRANT ALL ON TABLE "public"."cnes_estabelecimentos" TO "anon";

GRANT ALL ON TABLE "public"."cnes_estabelecimentos" TO "authenticated";

GRANT ALL ON TABLE "public"."cnes_estabelecimentos" TO "service_role";

GRANT ALL ON TABLE "public"."cnes_emendas" TO "anon";

GRANT ALL ON TABLE "public"."cnes_emendas" TO "authenticated";

GRANT ALL ON TABLE "public"."cnes_emendas" TO "service_role";

GRANT ALL ON TABLE "public"."cnes_emendas_por_cnpj" TO "anon";

GRANT ALL ON TABLE "public"."cnes_emendas_por_cnpj" TO "authenticated";

GRANT ALL ON TABLE "public"."cnes_emendas_por_cnpj" TO "service_role";

GRANT ALL ON TABLE "public"."cnpj_empresa" TO "anon";

GRANT ALL ON TABLE "public"."cnpj_empresa" TO "authenticated";

GRANT ALL ON TABLE "public"."cnpj_empresa" TO "service_role";

GRANT ALL ON TABLE "public"."cnpj_empresas" TO "anon";

GRANT ALL ON TABLE "public"."cnpj_empresas" TO "authenticated";

GRANT ALL ON TABLE "public"."cnpj_empresas" TO "service_role";

GRANT ALL ON TABLE "public"."cnpj_enriquecido" TO "anon";

GRANT ALL ON TABLE "public"."cnpj_enriquecido" TO "authenticated";

GRANT ALL ON TABLE "public"."cnpj_enriquecido" TO "service_role";

GRANT ALL ON TABLE "public"."cnpj_ingest_log" TO "anon";

GRANT ALL ON TABLE "public"."cnpj_ingest_log" TO "authenticated";

GRANT ALL ON TABLE "public"."cnpj_ingest_log" TO "service_role";

GRANT ALL ON SEQUENCE "public"."cnpj_ingest_log_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."cnpj_ingest_log_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."cnpj_ingest_log_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."cnpj_socios" TO "anon";

GRANT ALL ON TABLE "public"."cnpj_socios" TO "authenticated";

GRANT ALL ON TABLE "public"."cnpj_socios" TO "service_role";

GRANT ALL ON TABLE "public"."cobertura_dados" TO "anon";

GRANT ALL ON TABLE "public"."cobertura_dados" TO "authenticated";

GRANT ALL ON TABLE "public"."cobertura_dados" TO "service_role";

GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."codigos_acesso" TO "anon";

GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."codigos_acesso" TO "authenticated";

GRANT ALL ON TABLE "public"."codigos_acesso" TO "service_role";

GRANT ALL ON TABLE "public"."comissoes_parlamentares" TO "anon";

GRANT ALL ON TABLE "public"."comissoes_parlamentares" TO "authenticated";

GRANT ALL ON TABLE "public"."comissoes_parlamentares" TO "service_role";

GRANT ALL ON TABLE "public"."comissoes_senado" TO "anon";

GRANT ALL ON TABLE "public"."comissoes_senado" TO "authenticated";

GRANT ALL ON TABLE "public"."comissoes_senado" TO "service_role";

GRANT ALL ON TABLE "public"."contratos_federais" TO "anon";

GRANT ALL ON TABLE "public"."contratos_federais" TO "authenticated";

GRANT ALL ON TABLE "public"."contratos_federais" TO "service_role";

GRANT ALL ON TABLE "public"."contratos_ingest_log" TO "anon";

GRANT ALL ON TABLE "public"."contratos_ingest_log" TO "authenticated";

GRANT ALL ON TABLE "public"."contratos_ingest_log" TO "service_role";

GRANT ALL ON SEQUENCE "public"."contratos_ingest_log_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."contratos_ingest_log_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."contratos_ingest_log_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."convenios" TO "anon";

GRANT ALL ON TABLE "public"."convenios" TO "authenticated";

GRANT ALL ON TABLE "public"."convenios" TO "service_role";

GRANT ALL ON SEQUENCE "public"."convenios_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."convenios_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."convenios_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."cota_cnpj_lookup" TO "anon";

GRANT ALL ON TABLE "public"."cota_cnpj_lookup" TO "authenticated";

GRANT ALL ON TABLE "public"."cota_cnpj_lookup" TO "service_role";

GRANT ALL ON TABLE "public"."cota_despesa" TO "anon";

GRANT ALL ON TABLE "public"."cota_despesa" TO "authenticated";

GRANT ALL ON TABLE "public"."cota_despesa" TO "service_role";

GRANT ALL ON TABLE "public"."cota_cnpj_ranking" TO "anon";

GRANT ALL ON TABLE "public"."cota_cnpj_ranking" TO "authenticated";

GRANT ALL ON TABLE "public"."cota_cnpj_ranking" TO "service_role";

GRANT ALL ON TABLE "public"."cota_deputado" TO "anon";

GRANT ALL ON TABLE "public"."cota_deputado" TO "authenticated";

GRANT ALL ON TABLE "public"."cota_deputado" TO "service_role";

GRANT ALL ON TABLE "public"."cota_emenda_cruzamento" TO "anon";

GRANT ALL ON TABLE "public"."cota_emenda_cruzamento" TO "authenticated";

GRANT ALL ON TABLE "public"."cota_emenda_cruzamento" TO "service_role";

GRANT ALL ON TABLE "public"."mv_cota_fornecedor" TO "anon";

GRANT ALL ON TABLE "public"."mv_cota_fornecedor" TO "authenticated";

GRANT ALL ON TABLE "public"."mv_cota_fornecedor" TO "service_role";

GRANT ALL ON TABLE "public"."cota_fornecedor_resumo" TO "anon";

GRANT ALL ON TABLE "public"."cota_fornecedor_resumo" TO "authenticated";

GRANT ALL ON TABLE "public"."cota_fornecedor_resumo" TO "service_role";

GRANT ALL ON TABLE "public"."cpgf_transacoes" TO "anon";

GRANT ALL ON TABLE "public"."cpgf_transacoes" TO "authenticated";

GRANT ALL ON TABLE "public"."cpgf_transacoes" TO "service_role";

GRANT ALL ON SEQUENCE "public"."cpgf_transacoes_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."cpgf_transacoes_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."cpgf_transacoes_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."cptec_cidades" TO "anon";

GRANT ALL ON TABLE "public"."cptec_cidades" TO "authenticated";

GRANT ALL ON TABLE "public"."cptec_cidades" TO "service_role";

GRANT ALL ON TABLE "public"."cron_execution_log" TO "anon";

GRANT ALL ON TABLE "public"."cron_execution_log" TO "authenticated";

GRANT ALL ON TABLE "public"."cron_execution_log" TO "service_role";

GRANT ALL ON TABLE "public"."cvm_acusados" TO "anon";

GRANT ALL ON TABLE "public"."cvm_acusados" TO "authenticated";

GRANT ALL ON TABLE "public"."cvm_acusados" TO "service_role";

GRANT ALL ON TABLE "public"."cvm_carteira_edge" TO "anon";

GRANT ALL ON TABLE "public"."cvm_carteira_edge" TO "authenticated";

GRANT ALL ON TABLE "public"."cvm_carteira_edge" TO "service_role";

GRANT ALL ON TABLE "public"."cvm_corretoras" TO "anon";

GRANT ALL ON TABLE "public"."cvm_corretoras" TO "authenticated";

GRANT ALL ON TABLE "public"."cvm_corretoras" TO "service_role";

GRANT ALL ON TABLE "public"."cvm_processos" TO "anon";

GRANT ALL ON TABLE "public"."cvm_processos" TO "authenticated";

GRANT ALL ON TABLE "public"."cvm_processos" TO "service_role";

GRANT ALL ON TABLE "public"."cvm_cruzamento_emendas" TO "anon";

GRANT ALL ON TABLE "public"."cvm_cruzamento_emendas" TO "authenticated";

GRANT ALL ON TABLE "public"."cvm_cruzamento_emendas" TO "service_role";

GRANT ALL ON TABLE "public"."cvm_oferta" TO "anon";

GRANT ALL ON TABLE "public"."cvm_oferta" TO "authenticated";

GRANT ALL ON TABLE "public"."cvm_oferta" TO "service_role";

GRANT ALL ON TABLE "public"."mg_empresas_sancionadas" TO "anon";

GRANT ALL ON TABLE "public"."mg_empresas_sancionadas" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_empresas_sancionadas" TO "service_role";

GRANT ALL ON TABLE "public"."portal_sancionados" TO "anon";

GRANT ALL ON TABLE "public"."portal_sancionados" TO "authenticated";

GRANT ALL ON TABLE "public"."portal_sancionados" TO "service_role";

GRANT ALL ON TABLE "public"."cvm_emissor_sancionado" TO "anon";

GRANT ALL ON TABLE "public"."cvm_emissor_sancionado" TO "authenticated";

GRANT ALL ON TABLE "public"."cvm_emissor_sancionado" TO "service_role";

GRANT ALL ON TABLE "public"."cvm_fip_informe" TO "anon";

GRANT ALL ON TABLE "public"."cvm_fip_informe" TO "authenticated";

GRANT ALL ON TABLE "public"."cvm_fip_informe" TO "service_role";

GRANT ALL ON TABLE "public"."cvm_fundo" TO "anon";

GRANT ALL ON TABLE "public"."cvm_fundo" TO "authenticated";

GRANT ALL ON TABLE "public"."cvm_fundo" TO "service_role";

GRANT ALL ON TABLE "public"."cvm_fip_monopolio" TO "anon";

GRANT ALL ON TABLE "public"."cvm_fip_monopolio" TO "authenticated";

GRANT ALL ON TABLE "public"."cvm_fip_monopolio" TO "service_role";

GRANT ALL ON TABLE "public"."cvm_fip_participacao" TO "anon";

GRANT ALL ON TABLE "public"."cvm_fip_participacao" TO "authenticated";

GRANT ALL ON TABLE "public"."cvm_fip_participacao" TO "service_role";

GRANT ALL ON TABLE "public"."cvm_fip_saf" TO "anon";

GRANT ALL ON TABLE "public"."cvm_fip_saf" TO "authenticated";

GRANT ALL ON TABLE "public"."cvm_fip_saf" TO "service_role";

GRANT ALL ON TABLE "public"."cvm_fundos" TO "anon";

GRANT ALL ON TABLE "public"."cvm_fundos" TO "authenticated";

GRANT ALL ON TABLE "public"."cvm_fundos" TO "service_role";

GRANT ALL ON TABLE "public"."cvm_ingest_log" TO "anon";

GRANT ALL ON TABLE "public"."cvm_ingest_log" TO "authenticated";

GRANT ALL ON TABLE "public"."cvm_ingest_log" TO "service_role";

GRANT ALL ON TABLE "public"."cvm_saf" TO "anon";

GRANT ALL ON TABLE "public"."cvm_saf" TO "authenticated";

GRANT ALL ON TABLE "public"."cvm_saf" TO "service_role";

GRANT ALL ON TABLE "public"."cvm_saf_entidade_relacionada" TO "anon";

GRANT ALL ON TABLE "public"."cvm_saf_entidade_relacionada" TO "authenticated";

GRANT ALL ON TABLE "public"."cvm_saf_entidade_relacionada" TO "service_role";

GRANT ALL ON TABLE "public"."sen_senadores" TO "anon";

GRANT ALL ON TABLE "public"."sen_senadores" TO "authenticated";

GRANT ALL ON TABLE "public"."sen_senadores" TO "service_role";

GRANT ALL ON TABLE "public"."sobrenome_blocklist" TO "anon";

GRANT ALL ON TABLE "public"."sobrenome_blocklist" TO "authenticated";

GRANT ALL ON TABLE "public"."sobrenome_blocklist" TO "service_role";

GRANT ALL ON TABLE "public"."cvm_socio_politico" TO "anon";

GRANT ALL ON TABLE "public"."cvm_socio_politico" TO "authenticated";

GRANT ALL ON TABLE "public"."cvm_socio_politico" TO "service_role";

GRANT ALL ON TABLE "public"."data_governance_log" TO "anon";

GRANT ALL ON TABLE "public"."data_governance_log" TO "authenticated";

GRANT ALL ON TABLE "public"."data_governance_log" TO "service_role";

GRANT ALL ON TABLE "public"."data_pipeline_logs" TO "anon";

GRANT ALL ON TABLE "public"."data_pipeline_logs" TO "authenticated";

GRANT ALL ON TABLE "public"."data_pipeline_logs" TO "service_role";

GRANT ALL ON TABLE "public"."data_pipeline_status" TO "anon";

GRANT ALL ON TABLE "public"."data_pipeline_status" TO "authenticated";

GRANT ALL ON TABLE "public"."data_pipeline_status" TO "service_role";

GRANT ALL ON TABLE "public"."data_sources_registry" TO "anon";

GRANT ALL ON TABLE "public"."data_sources_registry" TO "authenticated";

GRANT ALL ON TABLE "public"."data_sources_registry" TO "service_role";

GRANT ALL ON TABLE "public"."declaracao_bens" TO "anon";

GRANT ALL ON TABLE "public"."declaracao_bens" TO "authenticated";

GRANT ALL ON TABLE "public"."declaracao_bens" TO "service_role";

GRANT ALL ON TABLE "public"."deputados_brutas" TO "anon";

GRANT ALL ON TABLE "public"."deputados_brutas" TO "authenticated";

GRANT ALL ON TABLE "public"."deputados_brutas" TO "service_role";

GRANT ALL ON TABLE "public"."despesas_gabinete" TO "anon";

GRANT ALL ON TABLE "public"."despesas_gabinete" TO "authenticated";

GRANT ALL ON TABLE "public"."despesas_gabinete" TO "service_role";

GRANT ALL ON TABLE "public"."despesas_gabinete_raw" TO "anon";

GRANT ALL ON TABLE "public"."despesas_gabinete_raw" TO "authenticated";

GRANT ALL ON TABLE "public"."despesas_gabinete_raw" TO "service_role";

GRANT ALL ON TABLE "public"."discursos" TO "anon";

GRANT ALL ON TABLE "public"."discursos" TO "authenticated";

GRANT ALL ON TABLE "public"."discursos" TO "service_role";

GRANT ALL ON TABLE "public"."discursos_camara" TO "anon";

GRANT ALL ON TABLE "public"."discursos_camara" TO "authenticated";

GRANT ALL ON TABLE "public"."discursos_camara" TO "service_role";

GRANT ALL ON TABLE "public"."discursos_senado" TO "anon";

GRANT ALL ON TABLE "public"."discursos_senado" TO "authenticated";

GRANT ALL ON TABLE "public"."discursos_senado" TO "service_role";

GRANT ALL ON TABLE "public"."dou_alertas_cruzamento" TO "anon";

GRANT ALL ON TABLE "public"."dou_alertas_cruzamento" TO "authenticated";

GRANT ALL ON TABLE "public"."dou_alertas_cruzamento" TO "service_role";

GRANT ALL ON SEQUENCE "public"."dou_alertas_cruzamento_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."dou_alertas_cruzamento_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."dou_alertas_cruzamento_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."dou_publicacoes" TO "anon";

GRANT ALL ON TABLE "public"."dou_publicacoes" TO "authenticated";

GRANT ALL ON TABLE "public"."dou_publicacoes" TO "service_role";

GRANT ALL ON SEQUENCE "public"."dou_publicacoes_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."dou_publicacoes_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."dou_publicacoes_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."ele2026_alertas" TO "anon";

GRANT ALL ON TABLE "public"."ele2026_alertas" TO "authenticated";

GRANT ALL ON TABLE "public"."ele2026_alertas" TO "service_role";

GRANT ALL ON SEQUENCE "public"."ele2026_alertas_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."ele2026_alertas_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."ele2026_alertas_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."ele2026_candidatos" TO "anon";

GRANT ALL ON TABLE "public"."ele2026_candidatos" TO "authenticated";

GRANT ALL ON TABLE "public"."ele2026_candidatos" TO "service_role";

GRANT ALL ON TABLE "public"."ele2026_financiamento" TO "anon";

GRANT ALL ON TABLE "public"."ele2026_financiamento" TO "authenticated";

GRANT ALL ON TABLE "public"."ele2026_financiamento" TO "service_role";

GRANT ALL ON SEQUENCE "public"."ele2026_financiamento_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."ele2026_financiamento_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."ele2026_financiamento_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."ele2026_gastos" TO "anon";

GRANT ALL ON TABLE "public"."ele2026_gastos" TO "authenticated";

GRANT ALL ON TABLE "public"."ele2026_gastos" TO "service_role";

GRANT ALL ON SEQUENCE "public"."ele2026_gastos_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."ele2026_gastos_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."ele2026_gastos_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."ele2026_ingest_log" TO "anon";

GRANT ALL ON TABLE "public"."ele2026_ingest_log" TO "authenticated";

GRANT ALL ON TABLE "public"."ele2026_ingest_log" TO "service_role";

GRANT ALL ON SEQUENCE "public"."ele2026_ingest_log_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."ele2026_ingest_log_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."ele2026_ingest_log_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."ele26_v_alertas_painel" TO "anon";

GRANT ALL ON TABLE "public"."ele26_v_alertas_painel" TO "authenticated";

GRANT ALL ON TABLE "public"."ele26_v_alertas_painel" TO "service_role";

GRANT ALL ON TABLE "public"."ele26_v_candidato_emendas" TO "anon";

GRANT ALL ON TABLE "public"."ele26_v_candidato_emendas" TO "authenticated";

GRANT ALL ON TABLE "public"."ele26_v_candidato_emendas" TO "service_role";

GRANT ALL ON TABLE "public"."sancoes" TO "anon";

GRANT ALL ON TABLE "public"."sancoes" TO "authenticated";

GRANT ALL ON TABLE "public"."sancoes" TO "service_role";

GRANT ALL ON TABLE "public"."ele26_v_financiamento_sancoes" TO "anon";

GRANT ALL ON TABLE "public"."ele26_v_financiamento_sancoes" TO "authenticated";

GRANT ALL ON TABLE "public"."ele26_v_financiamento_sancoes" TO "service_role";

GRANT ALL ON TABLE "public"."tse_candidatos" TO "anon";

GRANT ALL ON TABLE "public"."tse_candidatos" TO "authenticated";

GRANT ALL ON TABLE "public"."tse_candidatos" TO "service_role";

GRANT ALL ON TABLE "public"."ele26_v_historico_eleitoral" TO "anon";

GRANT ALL ON TABLE "public"."ele26_v_historico_eleitoral" TO "authenticated";

GRANT ALL ON TABLE "public"."ele26_v_historico_eleitoral" TO "service_role";

GRANT ALL ON TABLE "public"."emendas_api" TO "anon";

GRANT ALL ON TABLE "public"."emendas_api" TO "authenticated";

GRANT ALL ON TABLE "public"."emendas_api" TO "service_role";

GRANT ALL ON TABLE "public"."emendas_api_documentos" TO "anon";

GRANT ALL ON TABLE "public"."emendas_api_documentos" TO "authenticated";

GRANT ALL ON TABLE "public"."emendas_api_documentos" TO "service_role";

GRANT ALL ON SEQUENCE "public"."emendas_api_documentos_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."emendas_api_documentos_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."emendas_api_documentos_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."emendas_api_ingest_log" TO "anon";

GRANT ALL ON TABLE "public"."emendas_api_ingest_log" TO "authenticated";

GRANT ALL ON TABLE "public"."emendas_api_ingest_log" TO "service_role";

GRANT ALL ON SEQUENCE "public"."emendas_api_ingest_log_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."emendas_api_ingest_log_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."emendas_api_ingest_log_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."emendas_brutas" TO "anon";

GRANT ALL ON TABLE "public"."emendas_brutas" TO "authenticated";

GRANT ALL ON TABLE "public"."emendas_brutas" TO "service_role";

GRANT ALL ON TABLE "public"."emendas_coletivas" TO "anon";

GRANT ALL ON TABLE "public"."emendas_coletivas" TO "authenticated";

GRANT ALL ON TABLE "public"."emendas_coletivas" TO "service_role";

GRANT ALL ON TABLE "public"."emendas_convenios" TO "anon";

GRANT ALL ON TABLE "public"."emendas_convenios" TO "authenticated";

GRANT ALL ON TABLE "public"."emendas_convenios" TO "service_role";

GRANT ALL ON TABLE "public"."emendas_financeiro" TO "anon";

GRANT ALL ON TABLE "public"."emendas_financeiro" TO "authenticated";

GRANT ALL ON TABLE "public"."emendas_financeiro" TO "service_role";

GRANT ALL ON TABLE "public"."emendas_metricas" TO "anon";

GRANT ALL ON TABLE "public"."emendas_metricas" TO "authenticated";

GRANT ALL ON TABLE "public"."emendas_metricas" TO "service_role";

GRANT ALL ON TABLE "public"."emendas_rp9_apoiamento" TO "anon";

GRANT ALL ON TABLE "public"."emendas_rp9_apoiamento" TO "authenticated";

GRANT ALL ON TABLE "public"."emendas_rp9_apoiamento" TO "service_role";

GRANT ALL ON TABLE "public"."emendas_transparencia" TO "anon";

GRANT ALL ON TABLE "public"."emendas_transparencia" TO "authenticated";

GRANT ALL ON TABLE "public"."emendas_transparencia" TO "service_role";

GRANT ALL ON TABLE "public"."estados" TO "anon";

GRANT ALL ON TABLE "public"."estados" TO "authenticated";

GRANT ALL ON TABLE "public"."estados" TO "service_role";

GRANT ALL ON SEQUENCE "public"."estados_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."estados_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."estados_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."execucao_financeira_siafi" TO "anon";

GRANT ALL ON TABLE "public"."execucao_financeira_siafi" TO "authenticated";

GRANT ALL ON TABLE "public"."execucao_financeira_siafi" TO "service_role";

GRANT ALL ON SEQUENCE "public"."execucao_financeira_siafi_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."execucao_financeira_siafi_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."execucao_financeira_siafi_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."execucao_financeira_transferencias" TO "anon";

GRANT ALL ON TABLE "public"."execucao_financeira_transferencias" TO "authenticated";

GRANT ALL ON TABLE "public"."execucao_financeira_transferencias" TO "service_role";

GRANT ALL ON SEQUENCE "public"."execucao_financeira_transferencias_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."execucao_financeira_transferencias_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."execucao_financeira_transferencias_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."execucoes_pipeline" TO "anon";

GRANT ALL ON TABLE "public"."execucoes_pipeline" TO "authenticated";

GRANT ALL ON TABLE "public"."execucoes_pipeline" TO "service_role";

GRANT ALL ON TABLE "public"."execucoes_pipeline_etapas" TO "anon";

GRANT ALL ON TABLE "public"."execucoes_pipeline_etapas" TO "authenticated";

GRANT ALL ON TABLE "public"."execucoes_pipeline_etapas" TO "service_role";

GRANT ALL ON TABLE "public"."faf_planos_acao" TO "anon";

GRANT ALL ON TABLE "public"."faf_planos_acao" TO "authenticated";

GRANT ALL ON TABLE "public"."faf_planos_acao" TO "service_role";

GRANT ALL ON TABLE "public"."financiamento_eleitoral" TO "anon";

GRANT ALL ON TABLE "public"."financiamento_eleitoral" TO "authenticated";

GRANT ALL ON TABLE "public"."financiamento_eleitoral" TO "service_role";

GRANT ALL ON TABLE "public"."fip_saf_resumo" TO "anon";

GRANT ALL ON TABLE "public"."fip_saf_resumo" TO "authenticated";

GRANT ALL ON TABLE "public"."fip_saf_resumo" TO "service_role";

GRANT ALL ON TABLE "public"."fipe_tabelas" TO "anon";

GRANT ALL ON TABLE "public"."fipe_tabelas" TO "authenticated";

GRANT ALL ON TABLE "public"."fipe_tabelas" TO "service_role";

GRANT ALL ON TABLE "public"."folha_custo_gabinete" TO "anon";

GRANT ALL ON TABLE "public"."folha_custo_gabinete" TO "authenticated";

GRANT ALL ON TABLE "public"."folha_custo_gabinete" TO "service_role";

GRANT ALL ON TABLE "public"."folha_doador_leads" TO "anon";

GRANT ALL ON TABLE "public"."folha_doador_leads" TO "authenticated";

GRANT ALL ON TABLE "public"."folha_doador_leads" TO "service_role";

GRANT ALL ON TABLE "public"."folha_gabinete" TO "anon";

GRANT ALL ON TABLE "public"."folha_gabinete" TO "authenticated";

GRANT ALL ON TABLE "public"."folha_gabinete" TO "service_role";

GRANT ALL ON TABLE "public"."folha_gabinete_atual" TO "anon";

GRANT ALL ON TABLE "public"."folha_gabinete_atual" TO "authenticated";

GRANT ALL ON TABLE "public"."folha_gabinete_atual" TO "service_role";

GRANT ALL ON TABLE "public"."folha_nepotismo_leads" TO "anon";

GRANT ALL ON TABLE "public"."folha_nepotismo_leads" TO "authenticated";

GRANT ALL ON TABLE "public"."folha_nepotismo_leads" TO "service_role";

GRANT ALL ON TABLE "public"."fornecedores_intersetados" TO "anon";

GRANT ALL ON TABLE "public"."fornecedores_intersetados" TO "authenticated";

GRANT ALL ON TABLE "public"."fornecedores_intersetados" TO "service_role";

GRANT ALL ON TABLE "public"."fundacoes_partidarias" TO "anon";

GRANT ALL ON TABLE "public"."fundacoes_partidarias" TO "authenticated";

GRANT ALL ON TABLE "public"."fundacoes_partidarias" TO "service_role";

GRANT ALL ON TABLE "public"."fundacoes_repasses" TO "anon";

GRANT ALL ON TABLE "public"."fundacoes_repasses" TO "authenticated";

GRANT ALL ON TABLE "public"."fundacoes_repasses" TO "service_role";

GRANT ALL ON TABLE "public"."fundacoes_resumo" TO "anon";

GRANT ALL ON TABLE "public"."fundacoes_resumo" TO "authenticated";

GRANT ALL ON TABLE "public"."fundacoes_resumo" TO "service_role";

GRANT ALL ON TABLE "public"."fundacoes_alertas" TO "anon";

GRANT ALL ON TABLE "public"."fundacoes_alertas" TO "authenticated";

GRANT ALL ON TABLE "public"."fundacoes_alertas" TO "service_role";

GRANT ALL ON TABLE "public"."fundacoes_embeddings" TO "anon";

GRANT ALL ON TABLE "public"."fundacoes_embeddings" TO "authenticated";

GRANT ALL ON TABLE "public"."fundacoes_embeddings" TO "service_role";

GRANT ALL ON TABLE "public"."fundacoes_nf_partidos" TO "anon";

GRANT ALL ON TABLE "public"."fundacoes_nf_partidos" TO "authenticated";

GRANT ALL ON TABLE "public"."fundacoes_nf_partidos" TO "service_role";

GRANT ALL ON TABLE "public"."fundacoes_fornecedores_ranking" TO "anon";

GRANT ALL ON TABLE "public"."fundacoes_fornecedores_ranking" TO "authenticated";

GRANT ALL ON TABLE "public"."fundacoes_fornecedores_ranking" TO "service_role";

GRANT ALL ON TABLE "public"."fundacoes_ranking_publico" TO "anon";

GRANT ALL ON TABLE "public"."fundacoes_ranking_publico" TO "authenticated";

GRANT ALL ON TABLE "public"."fundacoes_ranking_publico" TO "service_role";

GRANT ALL ON TABLE "public"."fundacoes_vazio_prestacao" TO "anon";

GRANT ALL ON TABLE "public"."fundacoes_vazio_prestacao" TO "authenticated";

GRANT ALL ON TABLE "public"."fundacoes_vazio_prestacao" TO "service_role";

GRANT ALL ON TABLE "public"."glossario_tech" TO "anon";

GRANT ALL ON TABLE "public"."glossario_tech" TO "authenticated";

GRANT ALL ON TABLE "public"."glossario_tech" TO "service_role";

GRANT ALL ON TABLE "public"."judiciario_highlights" TO "anon";

GRANT ALL ON TABLE "public"."judiciario_highlights" TO "authenticated";

GRANT ALL ON TABLE "public"."judiciario_highlights" TO "service_role";

GRANT ALL ON TABLE "public"."judiciario_processos" TO "anon";

GRANT ALL ON TABLE "public"."judiciario_processos" TO "authenticated";

GRANT ALL ON TABLE "public"."judiciario_processos" TO "service_role";

GRANT ALL ON TABLE "public"."tribunais" TO "anon";

GRANT ALL ON TABLE "public"."tribunais" TO "authenticated";

GRANT ALL ON TABLE "public"."tribunais" TO "service_role";

GRANT ALL ON TABLE "public"."highlights" TO "anon";

GRANT ALL ON TABLE "public"."highlights" TO "authenticated";

GRANT ALL ON TABLE "public"."highlights" TO "service_role";

GRANT ALL ON TABLE "public"."highlights_publico" TO "anon";

GRANT ALL ON TABLE "public"."highlights_publico" TO "authenticated";

GRANT ALL ON TABLE "public"."highlights_publico" TO "service_role";

GRANT ALL ON TABLE "public"."ibama_autuacoes" TO "anon";

GRANT ALL ON TABLE "public"."ibama_autuacoes" TO "authenticated";

GRANT ALL ON TABLE "public"."ibama_autuacoes" TO "service_role";

GRANT ALL ON SEQUENCE "public"."ibama_autuacoes_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."ibama_autuacoes_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."ibama_autuacoes_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."ibge_indicadores" TO "anon";

GRANT ALL ON TABLE "public"."ibge_indicadores" TO "authenticated";

GRANT ALL ON TABLE "public"."ibge_indicadores" TO "service_role";

GRANT ALL ON SEQUENCE "public"."ibge_indicadores_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."ibge_indicadores_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."ibge_indicadores_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."ibge_municipios" TO "anon";

GRANT ALL ON TABLE "public"."ibge_municipios" TO "authenticated";

GRANT ALL ON TABLE "public"."ibge_municipios" TO "service_role";

GRANT ALL ON TABLE "public"."ibge_municipios_enriquecidos" TO "anon";

GRANT ALL ON TABLE "public"."ibge_municipios_enriquecidos" TO "authenticated";

GRANT ALL ON TABLE "public"."ibge_municipios_enriquecidos" TO "service_role";

GRANT ALL ON TABLE "public"."identity_audit_results" TO "anon";

GRANT ALL ON TABLE "public"."identity_audit_results" TO "authenticated";

GRANT ALL ON TABLE "public"."identity_audit_results" TO "service_role";

GRANT ALL ON TABLE "public"."identity_review_queue" TO "anon";

GRANT ALL ON TABLE "public"."identity_review_queue" TO "authenticated";

GRANT ALL ON TABLE "public"."identity_review_queue" TO "service_role";

GRANT ALL ON TABLE "public"."impacto_federativo" TO "anon";

GRANT ALL ON TABLE "public"."impacto_federativo" TO "authenticated";

GRANT ALL ON TABLE "public"."impacto_federativo" TO "service_role";

GRANT ALL ON TABLE "public"."indicadores" TO "anon";

GRANT ALL ON TABLE "public"."indicadores" TO "authenticated";

GRANT ALL ON TABLE "public"."indicadores" TO "service_role";

GRANT ALL ON TABLE "public"."indicadores_macroeconomicos" TO "anon";

GRANT ALL ON TABLE "public"."indicadores_macroeconomicos" TO "authenticated";

GRANT ALL ON TABLE "public"."indicadores_macroeconomicos" TO "service_role";

GRANT ALL ON SEQUENCE "public"."indicadores_macroeconomicos_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."indicadores_macroeconomicos_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."indicadores_macroeconomicos_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."indice_poder_orcamentario" TO "anon";

GRANT ALL ON TABLE "public"."indice_poder_orcamentario" TO "authenticated";

GRANT ALL ON TABLE "public"."indice_poder_orcamentario" TO "service_role";

GRANT ALL ON TABLE "public"."timeline_events" TO "anon";

GRANT ALL ON TABLE "public"."timeline_events" TO "authenticated";

GRANT ALL ON TABLE "public"."timeline_events" TO "service_role";

GRANT ALL ON TABLE "public"."parlamentar_activity_monthly" TO "anon";

GRANT ALL ON TABLE "public"."parlamentar_activity_monthly" TO "authenticated";

GRANT ALL ON TABLE "public"."parlamentar_activity_monthly" TO "service_role";

GRANT ALL ON TABLE "public"."influence_velocity" TO "anon";

GRANT ALL ON TABLE "public"."influence_velocity" TO "authenticated";

GRANT ALL ON TABLE "public"."influence_velocity" TO "service_role";

GRANT ALL ON TABLE "public"."influence_velocity_score" TO "anon";

GRANT ALL ON TABLE "public"."influence_velocity_score" TO "authenticated";

GRANT ALL ON TABLE "public"."influence_velocity_score" TO "service_role";

GRANT ALL ON TABLE "public"."ingestion_runs" TO "anon";

GRANT ALL ON TABLE "public"."ingestion_runs" TO "authenticated";

GRANT ALL ON TABLE "public"."ingestion_runs" TO "service_role";

GRANT ALL ON TABLE "public"."institucional_power_index" TO "anon";

GRANT ALL ON TABLE "public"."institucional_power_index" TO "authenticated";

GRANT ALL ON TABLE "public"."institucional_power_index" TO "service_role";

GRANT ALL ON TABLE "public"."ipi_base_power" TO "anon";

GRANT ALL ON TABLE "public"."ipi_base_power" TO "authenticated";

GRANT ALL ON TABLE "public"."ipi_base_power" TO "service_role";

GRANT ALL ON TABLE "public"."ipi_budget_power" TO "anon";

GRANT ALL ON TABLE "public"."ipi_budget_power" TO "authenticated";

GRANT ALL ON TABLE "public"."ipi_budget_power" TO "service_role";

GRANT ALL ON TABLE "public"."ipi_experience" TO "anon";

GRANT ALL ON TABLE "public"."ipi_experience" TO "authenticated";

GRANT ALL ON TABLE "public"."ipi_experience" TO "service_role";

GRANT ALL ON TABLE "public"."ipi_velocity" TO "anon";

GRANT ALL ON TABLE "public"."ipi_velocity" TO "authenticated";

GRANT ALL ON TABLE "public"."ipi_velocity" TO "service_role";

GRANT ALL ON TABLE "public"."institutional_power_index" TO "anon";

GRANT ALL ON TABLE "public"."institutional_power_index" TO "authenticated";

GRANT ALL ON TABLE "public"."institutional_power_index" TO "service_role";

GRANT ALL ON TABLE "public"."institutions" TO "anon";

GRANT ALL ON TABLE "public"."institutions" TO "authenticated";

GRANT ALL ON TABLE "public"."institutions" TO "service_role";

GRANT ALL ON TABLE "public"."intelligence_alerts" TO "anon";

GRANT ALL ON TABLE "public"."intelligence_alerts" TO "authenticated";

GRANT ALL ON TABLE "public"."intelligence_alerts" TO "service_role";

GRANT ALL ON TABLE "public"."intelligence_notes" TO "anon";

GRANT ALL ON TABLE "public"."intelligence_notes" TO "authenticated";

GRANT ALL ON TABLE "public"."intelligence_notes" TO "service_role";

GRANT ALL ON TABLE "public"."intelligence_queue" TO "anon";

GRANT ALL ON TABLE "public"."intelligence_queue" TO "authenticated";

GRANT ALL ON TABLE "public"."intelligence_queue" TO "service_role";

GRANT ALL ON TABLE "public"."judiciario_stats_por_ano_tribunal" TO "anon";

GRANT ALL ON TABLE "public"."judiciario_stats_por_ano_tribunal" TO "authenticated";

GRANT ALL ON TABLE "public"."judiciario_stats_por_ano_tribunal" TO "service_role";

GRANT ALL ON TABLE "public"."judiciario_stats_por_classe_tribunal" TO "anon";

GRANT ALL ON TABLE "public"."judiciario_stats_por_classe_tribunal" TO "authenticated";

GRANT ALL ON TABLE "public"."judiciario_stats_por_classe_tribunal" TO "service_role";

GRANT ALL ON TABLE "public"."judiciario_stats_por_relator" TO "anon";

GRANT ALL ON TABLE "public"."judiciario_stats_por_relator" TO "authenticated";

GRANT ALL ON TABLE "public"."judiciario_stats_por_relator" TO "service_role";

GRANT ALL ON TABLE "public"."judiciario_stats_por_tribunal" TO "anon";

GRANT ALL ON TABLE "public"."judiciario_stats_por_tribunal" TO "authenticated";

GRANT ALL ON TABLE "public"."judiciario_stats_por_tribunal" TO "service_role";

GRANT ALL ON TABLE "public"."leiloes_leiloeiros" TO "anon";

GRANT ALL ON TABLE "public"."leiloes_leiloeiros" TO "authenticated";

GRANT ALL ON TABLE "public"."leiloes_leiloeiros" TO "service_role";

GRANT ALL ON SEQUENCE "public"."leiloes_leiloeiros_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."leiloes_leiloeiros_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."leiloes_leiloeiros_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."leiloes_processos" TO "anon";

GRANT ALL ON TABLE "public"."leiloes_processos" TO "authenticated";

GRANT ALL ON TABLE "public"."leiloes_processos" TO "service_role";

GRANT ALL ON SEQUENCE "public"."leiloes_processos_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."leiloes_processos_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."leiloes_processos_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."licitacoes" TO "anon";

GRANT ALL ON TABLE "public"."licitacoes" TO "authenticated";

GRANT ALL ON TABLE "public"."licitacoes" TO "service_role";

GRANT ALL ON TABLE "public"."licitacoes_ingest_log" TO "anon";

GRANT ALL ON TABLE "public"."licitacoes_ingest_log" TO "authenticated";

GRANT ALL ON TABLE "public"."licitacoes_ingest_log" TO "service_role";

GRANT ALL ON SEQUENCE "public"."licitacoes_ingest_log_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."licitacoes_ingest_log_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."licitacoes_ingest_log_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."licitacoes_participantes" TO "anon";

GRANT ALL ON TABLE "public"."licitacoes_participantes" TO "authenticated";

GRANT ALL ON TABLE "public"."licitacoes_participantes" TO "service_role";

GRANT ALL ON SEQUENCE "public"."licitacoes_participantes_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."licitacoes_participantes_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."licitacoes_participantes_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."mandato_raiox" TO "anon";

GRANT ALL ON TABLE "public"."mandato_raiox" TO "authenticated";

GRANT ALL ON TABLE "public"."mandato_raiox" TO "service_role";

GRANT ALL ON TABLE "public"."media_briefings" TO "anon";

GRANT ALL ON TABLE "public"."media_briefings" TO "authenticated";

GRANT ALL ON TABLE "public"."media_briefings" TO "service_role";

GRANT ALL ON TABLE "public"."mg_compras_fornecedor" TO "anon";

GRANT ALL ON TABLE "public"."mg_compras_fornecedor" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_compras_fornecedor" TO "service_role";

GRANT ALL ON TABLE "public"."mg_compras_fornecedor_total" TO "anon";

GRANT ALL ON TABLE "public"."mg_compras_fornecedor_total" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_compras_fornecedor_total" TO "service_role";

GRANT ALL ON TABLE "public"."mg_compras_resumo" TO "anon";

GRANT ALL ON TABLE "public"."mg_compras_resumo" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_compras_resumo" TO "service_role";

GRANT ALL ON TABLE "public"."mg_contratos" TO "anon";

GRANT ALL ON TABLE "public"."mg_contratos" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_contratos" TO "service_role";

GRANT ALL ON TABLE "public"."mg_contratos_sancionados" TO "anon";

GRANT ALL ON TABLE "public"."mg_contratos_sancionados" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_contratos_sancionados" TO "service_role";

GRANT ALL ON TABLE "public"."mg_convenios" TO "anon";

GRANT ALL ON TABLE "public"."mg_convenios" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_convenios" TO "service_role";

GRANT ALL ON TABLE "public"."mg_convenios_entrada" TO "anon";

GRANT ALL ON TABLE "public"."mg_convenios_entrada" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_convenios_entrada" TO "service_role";

GRANT ALL ON TABLE "public"."mg_convenios_sancionados" TO "anon";

GRANT ALL ON TABLE "public"."mg_convenios_sancionados" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_convenios_sancionados" TO "service_role";

GRANT ALL ON TABLE "public"."mg_covid_compras" TO "anon";

GRANT ALL ON TABLE "public"."mg_covid_compras" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_covid_compras" TO "service_role";

GRANT ALL ON TABLE "public"."mg_covid_sancionados" TO "anon";

GRANT ALL ON TABLE "public"."mg_covid_sancionados" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_covid_sancionados" TO "service_role";

GRANT ALL ON TABLE "public"."mg_covid_sobrepreco" TO "anon";

GRANT ALL ON TABLE "public"."mg_covid_sobrepreco" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_covid_sobrepreco" TO "service_role";

GRANT ALL ON TABLE "public"."mg_empenhos" TO "anon";

GRANT ALL ON TABLE "public"."mg_empenhos" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_empenhos" TO "service_role";

GRANT ALL ON TABLE "public"."mg_cruzamento_emendas" TO "anon";

GRANT ALL ON TABLE "public"."mg_cruzamento_emendas" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_cruzamento_emendas" TO "service_role";

GRANT ALL ON TABLE "public"."mg_despesa_pessoal_vale" TO "anon";

GRANT ALL ON TABLE "public"."mg_despesa_pessoal_vale" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_despesa_pessoal_vale" TO "service_role";

GRANT ALL ON TABLE "public"."mg_diarias_orgao" TO "anon";

GRANT ALL ON TABLE "public"."mg_diarias_orgao" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_diarias_orgao" TO "service_role";

GRANT ALL ON TABLE "public"."mg_divida_tipo" TO "anon";

GRANT ALL ON TABLE "public"."mg_divida_tipo" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_divida_tipo" TO "service_role";

GRANT ALL ON TABLE "public"."mg_doacoes" TO "anon";

GRANT ALL ON TABLE "public"."mg_doacoes" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_doacoes" TO "service_role";

GRANT ALL ON TABLE "public"."mg_emendas_estaduais" TO "anon";

GRANT ALL ON TABLE "public"."mg_emendas_estaduais" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_emendas_estaduais" TO "service_role";

GRANT ALL ON TABLE "public"."mg_emendas_estaduais_por_autor" TO "anon";

GRANT ALL ON TABLE "public"."mg_emendas_estaduais_por_autor" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_emendas_estaduais_por_autor" TO "service_role";

GRANT ALL ON TABLE "public"."mg_emendas_estaduais_resumo" TO "anon";

GRANT ALL ON TABLE "public"."mg_emendas_estaduais_resumo" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_emendas_estaduais_resumo" TO "service_role";

GRANT ALL ON TABLE "public"."mg_emendas_federais" TO "anon";

GRANT ALL ON TABLE "public"."mg_emendas_federais" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_emendas_federais" TO "service_role";

GRANT ALL ON TABLE "public"."mg_emendas_pix" TO "anon";

GRANT ALL ON TABLE "public"."mg_emendas_pix" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_emendas_pix" TO "service_role";

GRANT ALL ON TABLE "public"."mg_empenhos_sancionados" TO "anon";

GRANT ALL ON TABLE "public"."mg_empenhos_sancionados" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_empenhos_sancionados" TO "service_role";

GRANT ALL ON TABLE "public"."mg_licitacao_sobrepreco" TO "anon";

GRANT ALL ON TABLE "public"."mg_licitacao_sobrepreco" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_licitacao_sobrepreco" TO "service_role";

GRANT ALL ON TABLE "public"."mg_licitacao_sobrepreco_rel" TO "anon";

GRANT ALL ON TABLE "public"."mg_licitacao_sobrepreco_rel" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_licitacao_sobrepreco_rel" TO "service_role";

GRANT ALL ON TABLE "public"."mg_notas_fornecedor" TO "anon";

GRANT ALL ON TABLE "public"."mg_notas_fornecedor" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_notas_fornecedor" TO "service_role";

GRANT ALL ON TABLE "public"."mg_notas_fornecedor_total" TO "anon";

GRANT ALL ON TABLE "public"."mg_notas_fornecedor_total" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_notas_fornecedor_total" TO "service_role";

GRANT ALL ON TABLE "public"."mg_os_parcerias" TO "anon";

GRANT ALL ON TABLE "public"."mg_os_parcerias" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_os_parcerias" TO "service_role";

GRANT ALL ON TABLE "public"."mg_terceirizados" TO "anon";

GRANT ALL ON TABLE "public"."mg_terceirizados" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_terceirizados" TO "service_role";

GRANT ALL ON TABLE "public"."mg_fornecedor_perfil" TO "anon";

GRANT ALL ON TABLE "public"."mg_fornecedor_perfil" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_fornecedor_perfil" TO "service_role";

GRANT ALL ON TABLE "public"."mg_fornecedor_perfil_resumo" TO "anon";

GRANT ALL ON TABLE "public"."mg_fornecedor_perfil_resumo" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_fornecedor_perfil_resumo" TO "service_role";

GRANT ALL ON TABLE "public"."mg_ingest_log" TO "anon";

GRANT ALL ON TABLE "public"."mg_ingest_log" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_ingest_log" TO "service_role";

GRANT ALL ON TABLE "public"."mg_ipsemg_contratos" TO "anon";

GRANT ALL ON TABLE "public"."mg_ipsemg_contratos" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_ipsemg_contratos" TO "service_role";

GRANT ALL ON TABLE "public"."mg_licitacao_sobrepreco_por_ano" TO "anon";

GRANT ALL ON TABLE "public"."mg_licitacao_sobrepreco_por_ano" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_licitacao_sobrepreco_por_ano" TO "service_role";

GRANT ALL ON TABLE "public"."mg_licitacao_sobrepreco_por_orgao" TO "anon";

GRANT ALL ON TABLE "public"."mg_licitacao_sobrepreco_por_orgao" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_licitacao_sobrepreco_por_orgao" TO "service_role";

GRANT ALL ON TABLE "public"."mg_lrf_limites" TO "anon";

GRANT ALL ON TABLE "public"."mg_lrf_limites" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_lrf_limites" TO "service_role";

GRANT ALL ON TABLE "public"."mg_lrf_pessoal" TO "anon";

GRANT ALL ON TABLE "public"."mg_lrf_pessoal" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_lrf_pessoal" TO "service_role";

GRANT ALL ON TABLE "public"."mg_notas_resumo" TO "anon";

GRANT ALL ON TABLE "public"."mg_notas_resumo" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_notas_resumo" TO "service_role";

GRANT ALL ON TABLE "public"."mg_obras" TO "anon";

GRANT ALL ON TABLE "public"."mg_obras" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_obras" TO "service_role";

GRANT ALL ON TABLE "public"."mg_obras_paradas" TO "anon";

GRANT ALL ON TABLE "public"."mg_obras_paradas" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_obras_paradas" TO "service_role";

GRANT ALL ON TABLE "public"."mg_obras_sancionadas" TO "anon";

GRANT ALL ON TABLE "public"."mg_obras_sancionadas" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_obras_sancionadas" TO "service_role";

GRANT ALL ON TABLE "public"."mg_pagamentos_condenadas" TO "anon";

GRANT ALL ON TABLE "public"."mg_pagamentos_condenadas" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_pagamentos_condenadas" TO "service_role";

GRANT ALL ON TABLE "public"."mg_remuneracao" TO "anon";

GRANT ALL ON TABLE "public"."mg_remuneracao" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_remuneracao" TO "service_role";

GRANT ALL ON TABLE "public"."mg_remuneracao_atual" TO "anon";

GRANT ALL ON TABLE "public"."mg_remuneracao_atual" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_remuneracao_atual" TO "service_role";

GRANT ALL ON TABLE "public"."mg_reparacao_vale" TO "anon";

GRANT ALL ON TABLE "public"."mg_reparacao_vale" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_reparacao_vale" TO "service_role";

GRANT ALL ON TABLE "public"."mg_restos_orgao" TO "anon";

GRANT ALL ON TABLE "public"."mg_restos_orgao" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_restos_orgao" TO "service_role";

GRANT ALL ON TABLE "public"."mg_siafi_execucao" TO "anon";

GRANT ALL ON TABLE "public"."mg_siafi_execucao" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_siafi_execucao" TO "service_role";

GRANT ALL ON TABLE "public"."mg_supersalarios" TO "anon";

GRANT ALL ON TABLE "public"."mg_supersalarios" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_supersalarios" TO "service_role";

GRANT ALL ON TABLE "public"."mg_terceirizados_sancionados" TO "anon";

GRANT ALL ON TABLE "public"."mg_terceirizados_sancionados" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_terceirizados_sancionados" TO "service_role";

GRANT ALL ON TABLE "public"."mg_voos_governador" TO "anon";

GRANT ALL ON TABLE "public"."mg_voos_governador" TO "authenticated";

GRANT ALL ON TABLE "public"."mg_voos_governador" TO "service_role";

GRANT ALL ON TABLE "public"."midia_eventos" TO "anon";

GRANT ALL ON TABLE "public"."midia_eventos" TO "authenticated";

GRANT ALL ON TABLE "public"."midia_eventos" TO "service_role";

GRANT ALL ON TABLE "public"."midia_inter_meios" TO "anon";

GRANT ALL ON TABLE "public"."midia_inter_meios" TO "authenticated";

GRANT ALL ON TABLE "public"."midia_inter_meios" TO "service_role";

GRANT ALL ON SEQUENCE "public"."midia_inter_meios_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."midia_inter_meios_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."midia_inter_meios_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."midia_kantar_releases" TO "anon";

GRANT ALL ON TABLE "public"."midia_kantar_releases" TO "authenticated";

GRANT ALL ON TABLE "public"."midia_kantar_releases" TO "service_role";

GRANT ALL ON SEQUENCE "public"."midia_kantar_releases_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."midia_kantar_releases_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."midia_kantar_releases_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."midia_secom_verbas" TO "anon";

GRANT ALL ON TABLE "public"."midia_secom_verbas" TO "authenticated";

GRANT ALL ON TABLE "public"."midia_secom_verbas" TO "service_role";

GRANT ALL ON SEQUENCE "public"."midia_secom_verbas_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."midia_secom_verbas_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."midia_secom_verbas_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."midia_veiculos" TO "anon";

GRANT ALL ON TABLE "public"."midia_veiculos" TO "authenticated";

GRANT ALL ON TABLE "public"."midia_veiculos" TO "service_role";

GRANT ALL ON TABLE "public"."midia_youtube_eventos" TO "anon";

GRANT ALL ON TABLE "public"."midia_youtube_eventos" TO "authenticated";

GRANT ALL ON TABLE "public"."midia_youtube_eventos" TO "service_role";

GRANT ALL ON TABLE "public"."midia_v_evento_comparativo" TO "anon";

GRANT ALL ON TABLE "public"."midia_v_evento_comparativo" TO "authenticated";

GRANT ALL ON TABLE "public"."midia_v_evento_comparativo" TO "service_role";

GRANT ALL ON TABLE "public"."midia_v_secom_por_grupo" TO "anon";

GRANT ALL ON TABLE "public"."midia_v_secom_por_grupo" TO "authenticated";

GRANT ALL ON TABLE "public"."midia_v_secom_por_grupo" TO "service_role";

GRANT ALL ON TABLE "public"."midia_v_share_historico" TO "anon";

GRANT ALL ON TABLE "public"."midia_v_share_historico" TO "authenticated";

GRANT ALL ON TABLE "public"."midia_v_share_historico" TO "service_role";

GRANT ALL ON SEQUENCE "public"."midia_youtube_eventos_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."midia_youtube_eventos_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."midia_youtube_eventos_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."ministerios" TO "anon";

GRANT ALL ON TABLE "public"."ministerios" TO "authenticated";

GRANT ALL ON TABLE "public"."ministerios" TO "service_role";

GRANT ALL ON SEQUENCE "public"."ministerios_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."ministerios_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."ministerios_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."municipios" TO "anon";

GRANT ALL ON TABLE "public"."municipios" TO "authenticated";

GRANT ALL ON TABLE "public"."municipios" TO "service_role";

GRANT ALL ON TABLE "public"."municipios_ibge" TO "anon";

GRANT ALL ON TABLE "public"."municipios_ibge" TO "authenticated";

GRANT ALL ON TABLE "public"."municipios_ibge" TO "service_role";

GRANT ALL ON TABLE "public"."tse_receitas_brutas" TO "anon";

GRANT ALL ON TABLE "public"."tse_receitas_brutas" TO "authenticated";

GRANT ALL ON TABLE "public"."tse_receitas_brutas" TO "service_role";

GRANT ALL ON TABLE "public"."vw_contratos_doadores_federal" TO "anon";

GRANT ALL ON TABLE "public"."vw_contratos_doadores_federal" TO "authenticated";

GRANT ALL ON TABLE "public"."vw_contratos_doadores_federal" TO "service_role";

GRANT ALL ON TABLE "public"."mv_contratos_doadores_federal" TO "anon";

GRANT ALL ON TABLE "public"."mv_contratos_doadores_federal" TO "authenticated";

GRANT ALL ON TABLE "public"."mv_contratos_doadores_federal" TO "service_role";

GRANT ALL ON TABLE "public"."vw_parlamentar_analitico" TO "anon";

GRANT ALL ON TABLE "public"."vw_parlamentar_analitico" TO "authenticated";

GRANT ALL ON TABLE "public"."vw_parlamentar_analitico" TO "service_role";

GRANT ALL ON TABLE "public"."mv_ranking_parlamentar" TO "anon";

GRANT ALL ON TABLE "public"."mv_ranking_parlamentar" TO "authenticated";

GRANT ALL ON TABLE "public"."mv_ranking_parlamentar" TO "service_role";

GRANT ALL ON TABLE "public"."pncp_resultados" TO "anon";

GRANT ALL ON TABLE "public"."pncp_resultados" TO "authenticated";

GRANT ALL ON TABLE "public"."pncp_resultados" TO "service_role";

GRANT ALL ON TABLE "public"."vw_scorecard_cnpj" TO "anon";

GRANT ALL ON TABLE "public"."vw_scorecard_cnpj" TO "authenticated";

GRANT ALL ON TABLE "public"."vw_scorecard_cnpj" TO "service_role";

GRANT ALL ON TABLE "public"."mv_scorecard_cnpj" TO "anon";

GRANT ALL ON TABLE "public"."mv_scorecard_cnpj" TO "authenticated";

GRANT ALL ON TABLE "public"."mv_scorecard_cnpj" TO "service_role";

GRANT ALL ON TABLE "public"."vw_scorecard_fornecedor_federal" TO "anon";

GRANT ALL ON TABLE "public"."vw_scorecard_fornecedor_federal" TO "authenticated";

GRANT ALL ON TABLE "public"."vw_scorecard_fornecedor_federal" TO "service_role";

GRANT ALL ON TABLE "public"."mv_scorecard_fornecedor_federal" TO "anon";

GRANT ALL ON TABLE "public"."mv_scorecard_fornecedor_federal" TO "authenticated";

GRANT ALL ON TABLE "public"."mv_scorecard_fornecedor_federal" TO "service_role";

GRANT ALL ON TABLE "public"."siafi_pagamento" TO "anon";

GRANT ALL ON TABLE "public"."siafi_pagamento" TO "authenticated";

GRANT ALL ON TABLE "public"."siafi_pagamento" TO "service_role";

GRANT ALL ON TABLE "public"."mv_siafi_fornecedores" TO "anon";

GRANT ALL ON TABLE "public"."mv_siafi_fornecedores" TO "authenticated";

GRANT ALL ON TABLE "public"."mv_siafi_fornecedores" TO "service_role";

GRANT ALL ON TABLE "public"."tse_despesas" TO "anon";

GRANT ALL ON TABLE "public"."tse_despesas" TO "authenticated";

GRANT ALL ON TABLE "public"."tse_despesas" TO "service_role";

GRANT ALL ON TABLE "public"."mv_tse_ads_digitais" TO "anon";

GRANT ALL ON TABLE "public"."mv_tse_ads_digitais" TO "authenticated";

GRANT ALL ON TABLE "public"."mv_tse_ads_digitais" TO "service_role";

GRANT ALL ON TABLE "public"."narrativas" TO "anon";

GRANT ALL ON TABLE "public"."narrativas" TO "authenticated";

GRANT ALL ON TABLE "public"."narrativas" TO "service_role";

GRANT ALL ON TABLE "public"."narrative_events" TO "anon";

GRANT ALL ON TABLE "public"."narrative_events" TO "authenticated";

GRANT ALL ON TABLE "public"."narrative_events" TO "service_role";

GRANT ALL ON TABLE "public"."ncm" TO "anon";

GRANT ALL ON TABLE "public"."ncm" TO "authenticated";

GRANT ALL ON TABLE "public"."ncm" TO "service_role";

GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."newsletter_sends" TO "anon";

GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."newsletter_sends" TO "authenticated";

GRANT ALL ON TABLE "public"."newsletter_sends" TO "service_role";

GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."newsletter_subscribers" TO "anon";

GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."newsletter_subscribers" TO "authenticated";

GRANT ALL ON TABLE "public"."newsletter_subscribers" TO "service_role";

GRANT ALL ON TABLE "public"."notas_fiscais" TO "anon";

GRANT ALL ON TABLE "public"."notas_fiscais" TO "authenticated";

GRANT ALL ON TABLE "public"."notas_fiscais" TO "service_role";

GRANT ALL ON TABLE "public"."notas_fiscais_ingest_log" TO "anon";

GRANT ALL ON TABLE "public"."notas_fiscais_ingest_log" TO "authenticated";

GRANT ALL ON TABLE "public"."notas_fiscais_ingest_log" TO "service_role";

GRANT ALL ON SEQUENCE "public"."notas_fiscais_ingest_log_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."notas_fiscais_ingest_log_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."notas_fiscais_ingest_log_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."noticias" TO "anon";

GRANT ALL ON TABLE "public"."noticias" TO "authenticated";

GRANT ALL ON TABLE "public"."noticias" TO "service_role";

GRANT ALL ON TABLE "public"."observatorios" TO "anon";

GRANT ALL ON TABLE "public"."observatorios" TO "authenticated";

GRANT ALL ON TABLE "public"."observatorios" TO "service_role";

GRANT ALL ON TABLE "public"."orgaos_federais" TO "anon";

GRANT ALL ON TABLE "public"."orgaos_federais" TO "authenticated";

GRANT ALL ON TABLE "public"."orgaos_federais" TO "service_role";

GRANT ALL ON SEQUENCE "public"."orgaos_federais_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."orgaos_federais_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."orgaos_federais_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."parlamentar_contratos_cache" TO "anon";

GRANT ALL ON TABLE "public"."parlamentar_contratos_cache" TO "authenticated";

GRANT ALL ON TABLE "public"."parlamentar_contratos_cache" TO "service_role";

GRANT ALL ON TABLE "public"."political_intelligence_feed" TO "anon";

GRANT ALL ON TABLE "public"."political_intelligence_feed" TO "authenticated";

GRANT ALL ON TABLE "public"."political_intelligence_feed" TO "service_role";

GRANT ALL ON TABLE "public"."parlamentar_dossier_live" TO "anon";

GRANT ALL ON TABLE "public"."parlamentar_dossier_live" TO "authenticated";

GRANT ALL ON TABLE "public"."parlamentar_dossier_live" TO "service_role";

GRANT ALL ON TABLE "public"."parlamentar_financiamento_cache" TO "anon";

GRANT ALL ON TABLE "public"."parlamentar_financiamento_cache" TO "authenticated";

GRANT ALL ON TABLE "public"."parlamentar_financiamento_cache" TO "service_role";

GRANT ALL ON TABLE "public"."parlamentar_identidade" TO "anon";

GRANT ALL ON TABLE "public"."parlamentar_identidade" TO "authenticated";

GRANT ALL ON TABLE "public"."parlamentar_identidade" TO "service_role";

GRANT ALL ON TABLE "public"."parlamentar_identity_map" TO "anon";

GRANT ALL ON TABLE "public"."parlamentar_identity_map" TO "authenticated";

GRANT ALL ON TABLE "public"."parlamentar_identity_map" TO "service_role";

GRANT ALL ON TABLE "public"."parlamentar_inteligencia" TO "anon";

GRANT ALL ON TABLE "public"."parlamentar_inteligencia" TO "authenticated";

GRANT ALL ON TABLE "public"."parlamentar_inteligencia" TO "service_role";

GRANT ALL ON TABLE "public"."parlamentar_sancoes_cache" TO "anon";

GRANT ALL ON TABLE "public"."parlamentar_sancoes_cache" TO "authenticated";

GRANT ALL ON TABLE "public"."parlamentar_sancoes_cache" TO "service_role";

GRANT ALL ON TABLE "public"."patrimonio_tse" TO "anon";

GRANT ALL ON TABLE "public"."patrimonio_tse" TO "authenticated";

GRANT ALL ON TABLE "public"."patrimonio_tse" TO "service_role";

GRANT ALL ON TABLE "public"."pbh_despesas_orcamentarias" TO "anon";

GRANT ALL ON TABLE "public"."pbh_despesas_orcamentarias" TO "authenticated";

GRANT ALL ON TABLE "public"."pbh_despesas_orcamentarias" TO "service_role";

GRANT ALL ON TABLE "public"."peps" TO "anon";

GRANT ALL ON TABLE "public"."peps" TO "authenticated";

GRANT ALL ON TABLE "public"."peps" TO "service_role";

GRANT ALL ON SEQUENCE "public"."peps_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."peps_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."peps_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."peps_ingest_log" TO "anon";

GRANT ALL ON TABLE "public"."peps_ingest_log" TO "authenticated";

GRANT ALL ON TABLE "public"."peps_ingest_log" TO "service_role";

GRANT ALL ON SEQUENCE "public"."peps_ingest_log_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."peps_ingest_log_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."peps_ingest_log_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."pgfn_divida_ativa" TO "anon";

GRANT ALL ON TABLE "public"."pgfn_divida_ativa" TO "authenticated";

GRANT ALL ON TABLE "public"."pgfn_divida_ativa" TO "service_role";

GRANT ALL ON SEQUENCE "public"."pgfn_divida_ativa_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."pgfn_divida_ativa_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."pgfn_divida_ativa_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."pgfn_divida_federacoes" TO "anon";

GRANT ALL ON TABLE "public"."pgfn_divida_federacoes" TO "authenticated";

GRANT ALL ON TABLE "public"."pgfn_divida_federacoes" TO "service_role";

GRANT ALL ON SEQUENCE "public"."pgfn_divida_federacoes_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."pgfn_divida_federacoes_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."pgfn_divida_federacoes_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."pgfn_divida_federacoes_resumo" TO "anon";

GRANT ALL ON TABLE "public"."pgfn_divida_federacoes_resumo" TO "authenticated";

GRANT ALL ON TABLE "public"."pgfn_divida_federacoes_resumo" TO "service_role";

GRANT ALL ON TABLE "public"."pif_live_feed" TO "anon";

GRANT ALL ON TABLE "public"."pif_live_feed" TO "authenticated";

GRANT ALL ON TABLE "public"."pif_live_feed" TO "service_role";

GRANT ALL ON TABLE "public"."pix_participantes" TO "anon";

GRANT ALL ON TABLE "public"."pix_participantes" TO "authenticated";

GRANT ALL ON TABLE "public"."pix_participantes" TO "service_role";

GRANT ALL ON TABLE "public"."plen_deputado_agg" TO "anon";

GRANT ALL ON TABLE "public"."plen_deputado_agg" TO "authenticated";

GRANT ALL ON TABLE "public"."plen_deputado_agg" TO "service_role";

GRANT ALL ON TABLE "public"."plen_orientacoes" TO "anon";

GRANT ALL ON TABLE "public"."plen_orientacoes" TO "authenticated";

GRANT ALL ON TABLE "public"."plen_orientacoes" TO "service_role";

GRANT ALL ON TABLE "public"."plen_votacoes" TO "anon";

GRANT ALL ON TABLE "public"."plen_votacoes" TO "authenticated";

GRANT ALL ON TABLE "public"."plen_votacoes" TO "service_role";

GRANT ALL ON TABLE "public"."plen_votos" TO "anon";

GRANT ALL ON TABLE "public"."plen_votos" TO "authenticated";

GRANT ALL ON TABLE "public"."plen_votos" TO "service_role";

GRANT ALL ON TABLE "public"."pncp_licitacoes" TO "anon";

GRANT ALL ON TABLE "public"."pncp_licitacoes" TO "authenticated";

GRANT ALL ON TABLE "public"."pncp_licitacoes" TO "service_role";

GRANT ALL ON TABLE "public"."pncp_publicidade" TO "anon";

GRANT ALL ON TABLE "public"."pncp_publicidade" TO "authenticated";

GRANT ALL ON TABLE "public"."pncp_publicidade" TO "service_role";

GRANT ALL ON SEQUENCE "public"."portal_sancionados_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."portal_sancionados_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."portal_sancionados_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."pr_ex_presidentes_custos" TO "anon";

GRANT ALL ON TABLE "public"."pr_ex_presidentes_custos" TO "authenticated";

GRANT ALL ON TABLE "public"."pr_ex_presidentes_custos" TO "service_role";

GRANT ALL ON TABLE "public"."pr_ex_presidentes_custo_anual" TO "anon";

GRANT ALL ON TABLE "public"."pr_ex_presidentes_custo_anual" TO "authenticated";

GRANT ALL ON TABLE "public"."pr_ex_presidentes_custo_anual" TO "service_role";

GRANT ALL ON TABLE "public"."pr_ex_presidentes_por_natureza" TO "anon";

GRANT ALL ON TABLE "public"."pr_ex_presidentes_por_natureza" TO "authenticated";

GRANT ALL ON TABLE "public"."pr_ex_presidentes_por_natureza" TO "service_role";

GRANT ALL ON TABLE "public"."pr_ingest_log" TO "anon";

GRANT ALL ON TABLE "public"."pr_ingest_log" TO "authenticated";

GRANT ALL ON TABLE "public"."pr_ingest_log" TO "service_role";

GRANT ALL ON TABLE "public"."pr_pessoal_diversidade" TO "anon";

GRANT ALL ON TABLE "public"."pr_pessoal_diversidade" TO "authenticated";

GRANT ALL ON TABLE "public"."pr_pessoal_diversidade" TO "service_role";

GRANT ALL ON TABLE "public"."presencas" TO "anon";

GRANT ALL ON TABLE "public"."presencas" TO "authenticated";

GRANT ALL ON TABLE "public"."presencas" TO "service_role";

GRANT ALL ON TABLE "public"."processos" TO "anon";

GRANT ALL ON TABLE "public"."processos" TO "authenticated";

GRANT ALL ON TABLE "public"."processos" TO "service_role";

GRANT ALL ON TABLE "public"."processos_publico" TO "anon";

GRANT ALL ON TABLE "public"."processos_publico" TO "authenticated";

GRANT ALL ON TABLE "public"."processos_publico" TO "service_role";

GRANT ALL ON TABLE "public"."public_reports" TO "anon";

GRANT ALL ON TABLE "public"."public_reports" TO "authenticated";

GRANT ALL ON TABLE "public"."public_reports" TO "service_role";

GRANT ALL ON TABLE "public"."ranking_cache" TO "anon";

GRANT ALL ON TABLE "public"."ranking_cache" TO "authenticated";

GRANT ALL ON TABLE "public"."ranking_cache" TO "service_role";

GRANT ALL ON TABLE "public"."ranking_federal" TO "anon";

GRANT ALL ON TABLE "public"."ranking_federal" TO "authenticated";

GRANT ALL ON TABLE "public"."ranking_federal" TO "service_role";

GRANT ALL ON TABLE "public"."ranking_nacional" TO "anon";

GRANT ALL ON TABLE "public"."ranking_nacional" TO "authenticated";

GRANT ALL ON TABLE "public"."ranking_nacional" TO "service_role";

GRANT ALL ON TABLE "public"."ranking_parlamentar" TO "anon";

GRANT ALL ON TABLE "public"."ranking_parlamentar" TO "authenticated";

GRANT ALL ON TABLE "public"."ranking_parlamentar" TO "service_role";

GRANT ALL ON TABLE "public"."ranking_parlamentar_build" TO "anon";

GRANT ALL ON TABLE "public"."ranking_parlamentar_build" TO "authenticated";

GRANT ALL ON TABLE "public"."ranking_parlamentar_build" TO "service_role";

GRANT ALL ON TABLE "public"."ranking_parlamentares" TO "anon";

GRANT ALL ON TABLE "public"."ranking_parlamentares" TO "authenticated";

GRANT ALL ON TABLE "public"."ranking_parlamentares" TO "service_role";

GRANT ALL ON TABLE "public"."ranking_score" TO "anon";

GRANT ALL ON TABLE "public"."ranking_score" TO "authenticated";

GRANT ALL ON TABLE "public"."ranking_score" TO "service_role";

GRANT ALL ON TABLE "public"."ranking_snapshot" TO "anon";

GRANT ALL ON TABLE "public"."ranking_snapshot" TO "authenticated";

GRANT ALL ON TABLE "public"."ranking_snapshot" TO "service_role";

GRANT ALL ON TABLE "public"."rs_despesas" TO "anon";

GRANT ALL ON TABLE "public"."rs_despesas" TO "authenticated";

GRANT ALL ON TABLE "public"."rs_despesas" TO "service_role";

GRANT ALL ON TABLE "public"."rs_ingest_log" TO "anon";

GRANT ALL ON TABLE "public"."rs_ingest_log" TO "authenticated";

GRANT ALL ON TABLE "public"."rs_ingest_log" TO "service_role";

GRANT ALL ON TABLE "public"."saf_ecossistema_cvm" TO "anon";

GRANT ALL ON TABLE "public"."saf_ecossistema_cvm" TO "authenticated";

GRANT ALL ON TABLE "public"."saf_ecossistema_cvm" TO "service_role";

GRANT ALL ON TABLE "public"."saf_oferta" TO "anon";

GRANT ALL ON TABLE "public"."saf_oferta" TO "authenticated";

GRANT ALL ON TABLE "public"."saf_oferta" TO "service_role";

GRANT ALL ON TABLE "public"."saf_quadro_societario" TO "anon";

GRANT ALL ON TABLE "public"."saf_quadro_societario" TO "authenticated";

GRANT ALL ON TABLE "public"."saf_quadro_societario" TO "service_role";

GRANT ALL ON TABLE "public"."sancoes_ingest_log" TO "anon";

GRANT ALL ON TABLE "public"."sancoes_ingest_log" TO "authenticated";

GRANT ALL ON TABLE "public"."sancoes_ingest_log" TO "service_role";

GRANT ALL ON SEQUENCE "public"."sancoes_ingest_log_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."sancoes_ingest_log_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."sancoes_ingest_log_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."scores" TO "anon";

GRANT ALL ON TABLE "public"."scores" TO "authenticated";

GRANT ALL ON TABLE "public"."scores" TO "service_role";

GRANT ALL ON TABLE "public"."sebrae_contratos" TO "anon";

GRANT ALL ON TABLE "public"."sebrae_contratos" TO "authenticated";

GRANT ALL ON TABLE "public"."sebrae_contratos" TO "service_role";

GRANT ALL ON SEQUENCE "public"."sebrae_contratos_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."sebrae_contratos_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."sebrae_contratos_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."sebrae_convenios" TO "anon";

GRANT ALL ON TABLE "public"."sebrae_convenios" TO "authenticated";

GRANT ALL ON TABLE "public"."sebrae_convenios" TO "service_role";

GRANT ALL ON SEQUENCE "public"."sebrae_convenios_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."sebrae_convenios_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."sebrae_convenios_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."sebrae_emendas_contratos" TO "anon";

GRANT ALL ON TABLE "public"."sebrae_emendas_contratos" TO "authenticated";

GRANT ALL ON TABLE "public"."sebrae_emendas_contratos" TO "service_role";

GRANT ALL ON SEQUENCE "public"."sebrae_emendas_contratos_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."sebrae_emendas_contratos_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."sebrae_emendas_contratos_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."sebrae_emendas_convenios" TO "anon";

GRANT ALL ON TABLE "public"."sebrae_emendas_convenios" TO "authenticated";

GRANT ALL ON TABLE "public"."sebrae_emendas_convenios" TO "service_role";

GRANT ALL ON SEQUENCE "public"."sebrae_emendas_convenios_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."sebrae_emendas_convenios_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."sebrae_emendas_convenios_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."sebrae_licitacoes" TO "anon";

GRANT ALL ON TABLE "public"."sebrae_licitacoes" TO "authenticated";

GRANT ALL ON TABLE "public"."sebrae_licitacoes" TO "service_role";

GRANT ALL ON SEQUENCE "public"."sebrae_licitacoes_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."sebrae_licitacoes_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."sebrae_licitacoes_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."sebrae_patrocinios" TO "anon";

GRANT ALL ON TABLE "public"."sebrae_patrocinios" TO "authenticated";

GRANT ALL ON TABLE "public"."sebrae_patrocinios" TO "service_role";

GRANT ALL ON SEQUENCE "public"."sebrae_patrocinios_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."sebrae_patrocinios_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."sebrae_patrocinios_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."sen_parlamentar_risco" TO "anon";

GRANT ALL ON TABLE "public"."sen_parlamentar_risco" TO "authenticated";

GRANT ALL ON TABLE "public"."sen_parlamentar_risco" TO "service_role";

GRANT ALL ON TABLE "public"."sen_proposicoes" TO "anon";

GRANT ALL ON TABLE "public"."sen_proposicoes" TO "authenticated";

GRANT ALL ON TABLE "public"."sen_proposicoes" TO "service_role";

GRANT ALL ON SEQUENCE "public"."sen_proposicoes_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."sen_proposicoes_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."sen_proposicoes_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."senac_contratos" TO "anon";

GRANT ALL ON TABLE "public"."senac_contratos" TO "authenticated";

GRANT ALL ON TABLE "public"."senac_contratos" TO "service_role";

GRANT ALL ON SEQUENCE "public"."senac_contratos_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."senac_contratos_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."senac_contratos_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."senac_licitacoes" TO "anon";

GRANT ALL ON TABLE "public"."senac_licitacoes" TO "authenticated";

GRANT ALL ON TABLE "public"."senac_licitacoes" TO "service_role";

GRANT ALL ON SEQUENCE "public"."senac_licitacoes_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."senac_licitacoes_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."senac_licitacoes_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."senado_ceaps_despesa" TO "anon";

GRANT ALL ON TABLE "public"."senado_ceaps_despesa" TO "authenticated";

GRANT ALL ON TABLE "public"."senado_ceaps_despesa" TO "service_role";

GRANT ALL ON TABLE "public"."senado_ceaps_emenda_cruzamento" TO "anon";

GRANT ALL ON TABLE "public"."senado_ceaps_emenda_cruzamento" TO "authenticated";

GRANT ALL ON TABLE "public"."senado_ceaps_emenda_cruzamento" TO "service_role";

GRANT ALL ON TABLE "public"."senado_orientacao" TO "anon";

GRANT ALL ON TABLE "public"."senado_orientacao" TO "authenticated";

GRANT ALL ON TABLE "public"."senado_orientacao" TO "service_role";

GRANT ALL ON TABLE "public"."senado_votacao" TO "anon";

GRANT ALL ON TABLE "public"."senado_votacao" TO "authenticated";

GRANT ALL ON TABLE "public"."senado_votacao" TO "service_role";

GRANT ALL ON TABLE "public"."senado_voto" TO "anon";

GRANT ALL ON TABLE "public"."senado_voto" TO "authenticated";

GRANT ALL ON TABLE "public"."senado_voto" TO "service_role";

GRANT ALL ON TABLE "public"."senado_dissidencia" TO "anon";

GRANT ALL ON TABLE "public"."senado_dissidencia" TO "authenticated";

GRANT ALL ON TABLE "public"."senado_dissidencia" TO "service_role";

GRANT ALL ON TABLE "public"."senadores_brutas" TO "anon";

GRANT ALL ON TABLE "public"."senadores_brutas" TO "authenticated";

GRANT ALL ON TABLE "public"."senadores_brutas" TO "service_role";

GRANT ALL ON TABLE "public"."senar_contratos" TO "anon";

GRANT ALL ON TABLE "public"."senar_contratos" TO "authenticated";

GRANT ALL ON TABLE "public"."senar_contratos" TO "service_role";

GRANT ALL ON SEQUENCE "public"."senar_contratos_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."senar_contratos_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."senar_contratos_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."senar_licitacoes" TO "anon";

GRANT ALL ON TABLE "public"."senar_licitacoes" TO "authenticated";

GRANT ALL ON TABLE "public"."senar_licitacoes" TO "service_role";

GRANT ALL ON SEQUENCE "public"."senar_licitacoes_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."senar_licitacoes_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."senar_licitacoes_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."senar_transferencias" TO "anon";

GRANT ALL ON TABLE "public"."senar_transferencias" TO "authenticated";

GRANT ALL ON TABLE "public"."senar_transferencias" TO "service_role";

GRANT ALL ON SEQUENCE "public"."senar_transferencias_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."senar_transferencias_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."senar_transferencias_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."sesc_contratos" TO "anon";

GRANT ALL ON TABLE "public"."sesc_contratos" TO "authenticated";

GRANT ALL ON TABLE "public"."sesc_contratos" TO "service_role";

GRANT ALL ON SEQUENCE "public"."sesc_contratos_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."sesc_contratos_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."sesc_contratos_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."sesc_convenios" TO "anon";

GRANT ALL ON TABLE "public"."sesc_convenios" TO "authenticated";

GRANT ALL ON TABLE "public"."sesc_convenios" TO "service_role";

GRANT ALL ON SEQUENCE "public"."sesc_convenios_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."sesc_convenios_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."sesc_convenios_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."siafi_empenho" TO "anon";

GRANT ALL ON TABLE "public"."siafi_empenho" TO "authenticated";

GRANT ALL ON TABLE "public"."siafi_empenho" TO "service_role";

GRANT ALL ON TABLE "public"."siafi_execucao_mensal" TO "anon";

GRANT ALL ON TABLE "public"."siafi_execucao_mensal" TO "authenticated";

GRANT ALL ON TABLE "public"."siafi_execucao_mensal" TO "service_role";

GRANT ALL ON TABLE "public"."siafi_fornecedor" TO "anon";

GRANT ALL ON TABLE "public"."siafi_fornecedor" TO "authenticated";

GRANT ALL ON TABLE "public"."siafi_fornecedor" TO "service_role";

GRANT ALL ON TABLE "public"."siafi_ingestao_log" TO "anon";

GRANT ALL ON TABLE "public"."siafi_ingestao_log" TO "authenticated";

GRANT ALL ON TABLE "public"."siafi_ingestao_log" TO "service_role";

GRANT ALL ON SEQUENCE "public"."siafi_ingestao_log_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."siafi_ingestao_log_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."siafi_ingestao_log_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."siafi_item_empenho" TO "anon";

GRANT ALL ON TABLE "public"."siafi_item_empenho" TO "authenticated";

GRANT ALL ON TABLE "public"."siafi_item_empenho" TO "service_role";

GRANT ALL ON TABLE "public"."siafi_liquidacao" TO "anon";

GRANT ALL ON TABLE "public"."siafi_liquidacao" TO "authenticated";

GRANT ALL ON TABLE "public"."siafi_liquidacao" TO "service_role";

GRANT ALL ON TABLE "public"."siafi_pagamento_empenho" TO "anon";

GRANT ALL ON TABLE "public"."siafi_pagamento_empenho" TO "authenticated";

GRANT ALL ON TABLE "public"."siafi_pagamento_empenho" TO "service_role";

GRANT ALL ON TABLE "public"."siafi_pagamento_favorecido_final" TO "anon";

GRANT ALL ON TABLE "public"."siafi_pagamento_favorecido_final" TO "authenticated";

GRANT ALL ON TABLE "public"."siafi_pagamento_favorecido_final" TO "service_role";

GRANT ALL ON TABLE "public"."sisi_contratos" TO "anon";

GRANT ALL ON TABLE "public"."sisi_contratos" TO "authenticated";

GRANT ALL ON TABLE "public"."sisi_contratos" TO "service_role";

GRANT ALL ON SEQUENCE "public"."sisi_contratos_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."sisi_contratos_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."sisi_contratos_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."sisi_convenios" TO "anon";

GRANT ALL ON TABLE "public"."sisi_convenios" TO "authenticated";

GRANT ALL ON TABLE "public"."sisi_convenios" TO "service_role";

GRANT ALL ON SEQUENCE "public"."sisi_convenios_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."sisi_convenios_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."sisi_convenios_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."sisi_licitacoes" TO "anon";

GRANT ALL ON TABLE "public"."sisi_licitacoes" TO "authenticated";

GRANT ALL ON TABLE "public"."sisi_licitacoes" TO "service_role";

GRANT ALL ON SEQUENCE "public"."sisi_licitacoes_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."sisi_licitacoes_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."sisi_licitacoes_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."sisi_licitacoes_participantes" TO "anon";

GRANT ALL ON TABLE "public"."sisi_licitacoes_participantes" TO "authenticated";

GRANT ALL ON TABLE "public"."sisi_licitacoes_participantes" TO "service_role";

GRANT ALL ON SEQUENCE "public"."sisi_licitacoes_participantes_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."sisi_licitacoes_participantes_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."sisi_licitacoes_participantes_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."snapshots_ranking" TO "anon";

GRANT ALL ON TABLE "public"."snapshots_ranking" TO "authenticated";

GRANT ALL ON TABLE "public"."snapshots_ranking" TO "service_role";

GRANT ALL ON TABLE "public"."sp_contratos" TO "anon";

GRANT ALL ON TABLE "public"."sp_contratos" TO "authenticated";

GRANT ALL ON TABLE "public"."sp_contratos" TO "service_role";

GRANT ALL ON SEQUENCE "public"."sp_contratos_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."sp_contratos_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."sp_contratos_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."sp_despesas" TO "anon";

GRANT ALL ON TABLE "public"."sp_despesas" TO "authenticated";

GRANT ALL ON TABLE "public"."sp_despesas" TO "service_role";

GRANT ALL ON SEQUENCE "public"."sp_despesas_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."sp_despesas_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."sp_despesas_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."sp_despesas_por_credor" TO "anon";

GRANT ALL ON TABLE "public"."sp_despesas_por_credor" TO "authenticated";

GRANT ALL ON TABLE "public"."sp_despesas_por_credor" TO "service_role";

GRANT ALL ON TABLE "public"."stats_por_ano_tribunal" TO "anon";

GRANT ALL ON TABLE "public"."stats_por_ano_tribunal" TO "authenticated";

GRANT ALL ON TABLE "public"."stats_por_ano_tribunal" TO "service_role";

GRANT ALL ON TABLE "public"."stats_por_classe_tribunal" TO "anon";

GRANT ALL ON TABLE "public"."stats_por_classe_tribunal" TO "authenticated";

GRANT ALL ON TABLE "public"."stats_por_classe_tribunal" TO "service_role";

GRANT ALL ON TABLE "public"."stats_por_relator" TO "anon";

GRANT ALL ON TABLE "public"."stats_por_relator" TO "authenticated";

GRANT ALL ON TABLE "public"."stats_por_relator" TO "service_role";

GRANT ALL ON TABLE "public"."stats_por_tribunal" TO "anon";

GRANT ALL ON TABLE "public"."stats_por_tribunal" TO "authenticated";

GRANT ALL ON TABLE "public"."stats_por_tribunal" TO "service_role";

GRANT ALL ON TABLE "public"."stf_assinaturas" TO "anon";

GRANT ALL ON TABLE "public"."stf_assinaturas" TO "authenticated";

GRANT ALL ON TABLE "public"."stf_assinaturas" TO "service_role";

GRANT ALL ON TABLE "public"."stf_gastos" TO "anon";

GRANT ALL ON TABLE "public"."stf_gastos" TO "authenticated";

GRANT ALL ON TABLE "public"."stf_gastos" TO "service_role";

GRANT ALL ON TABLE "public"."stf_ingestao_log" TO "anon";

GRANT ALL ON TABLE "public"."stf_ingestao_log" TO "authenticated";

GRANT ALL ON TABLE "public"."stf_ingestao_log" TO "service_role";

GRANT ALL ON SEQUENCE "public"."stf_ingestao_log_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."stf_ingestao_log_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."stf_ingestao_log_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."stf_ministros" TO "anon";

GRANT ALL ON TABLE "public"."stf_ministros" TO "authenticated";

GRANT ALL ON TABLE "public"."stf_ministros" TO "service_role";

GRANT ALL ON TABLE "public"."stf_processos_politicos" TO "anon";

GRANT ALL ON TABLE "public"."stf_processos_politicos" TO "authenticated";

GRANT ALL ON TABLE "public"."stf_processos_politicos" TO "service_role";

GRANT ALL ON TABLE "public"."stf_repercussao_geral" TO "anon";

GRANT ALL ON TABLE "public"."stf_repercussao_geral" TO "authenticated";

GRANT ALL ON TABLE "public"."stf_repercussao_geral" TO "service_role";

GRANT ALL ON TABLE "public"."stf_v_ministros_scores" TO "anon";

GRANT ALL ON TABLE "public"."stf_v_ministros_scores" TO "authenticated";

GRANT ALL ON TABLE "public"."stf_v_ministros_scores" TO "service_role";

GRANT ALL ON TABLE "public"."stf_votacoes" TO "anon";

GRANT ALL ON TABLE "public"."stf_votacoes" TO "authenticated";

GRANT ALL ON TABLE "public"."stf_votacoes" TO "service_role";

GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."sub_alertas" TO "anon";

GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."sub_alertas" TO "authenticated";

GRANT ALL ON TABLE "public"."sub_alertas" TO "service_role";

GRANT ALL ON TABLE "public"."sub_aneel_autos" TO "anon";

GRANT ALL ON TABLE "public"."sub_aneel_autos" TO "authenticated";

GRANT ALL ON TABLE "public"."sub_aneel_autos" TO "service_role";

GRANT ALL ON SEQUENCE "public"."sub_aneel_autos_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."sub_aneel_autos_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."sub_aneel_autos_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."sub_ans_operadoras" TO "anon";

GRANT ALL ON TABLE "public"."sub_ans_operadoras" TO "authenticated";

GRANT ALL ON TABLE "public"."sub_ans_operadoras" TO "service_role";

GRANT ALL ON SEQUENCE "public"."sub_ans_operadoras_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."sub_ans_operadoras_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."sub_ans_operadoras_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."sub_ceis" TO "anon";

GRANT ALL ON TABLE "public"."sub_ceis" TO "authenticated";

GRANT ALL ON TABLE "public"."sub_ceis" TO "service_role";

GRANT ALL ON TABLE "public"."sub_cepim" TO "anon";

GRANT ALL ON TABLE "public"."sub_cepim" TO "authenticated";

GRANT ALL ON TABLE "public"."sub_cepim" TO "service_role";

GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."sub_clientes" TO "anon";

GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."sub_clientes" TO "authenticated";

GRANT ALL ON TABLE "public"."sub_clientes" TO "service_role";

GRANT ALL ON TABLE "public"."sub_cnep" TO "anon";

GRANT ALL ON TABLE "public"."sub_cnep" TO "authenticated";

GRANT ALL ON TABLE "public"."sub_cnep" TO "service_role";

GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."sub_cnpjs_monitorados" TO "anon";

GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."sub_cnpjs_monitorados" TO "authenticated";

GRANT ALL ON TABLE "public"."sub_cnpjs_monitorados" TO "service_role";

GRANT ALL ON TABLE "public"."sub_cvm_pas" TO "anon";

GRANT ALL ON TABLE "public"."sub_cvm_pas" TO "authenticated";

GRANT ALL ON TABLE "public"."sub_cvm_pas" TO "service_role";

GRANT ALL ON SEQUENCE "public"."sub_cvm_pas_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."sub_cvm_pas_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."sub_cvm_pas_id_seq" TO "service_role";

GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."sub_dossies" TO "anon";

GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."sub_dossies" TO "authenticated";

GRANT ALL ON TABLE "public"."sub_dossies" TO "service_role";

GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."sub_envios" TO "anon";

GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."sub_envios" TO "authenticated";

GRANT ALL ON TABLE "public"."sub_envios" TO "service_role";

GRANT ALL ON TABLE "public"."sub_ibama" TO "anon";

GRANT ALL ON TABLE "public"."sub_ibama" TO "authenticated";

GRANT ALL ON TABLE "public"."sub_ibama" TO "service_role";

GRANT ALL ON SEQUENCE "public"."sub_ibama_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."sub_ibama_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."sub_ibama_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."sub_lista_suja" TO "anon";

GRANT ALL ON TABLE "public"."sub_lista_suja" TO "authenticated";

GRANT ALL ON TABLE "public"."sub_lista_suja" TO "service_role";

GRANT ALL ON SEQUENCE "public"."sub_lista_suja_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."sub_lista_suja_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."sub_lista_suja_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."sub_mte_autos" TO "anon";

GRANT ALL ON TABLE "public"."sub_mte_autos" TO "authenticated";

GRANT ALL ON TABLE "public"."sub_mte_autos" TO "service_role";

GRANT ALL ON SEQUENCE "public"."sub_mte_autos_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."sub_mte_autos_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."sub_mte_autos_id_seq" TO "service_role";

GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."sub_pf_consultas" TO "anon";

GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."sub_pf_consultas" TO "authenticated";

GRANT ALL ON TABLE "public"."sub_pf_consultas" TO "service_role";

GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."sub_snapshots" TO "anon";

GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."sub_snapshots" TO "authenticated";

GRANT ALL ON TABLE "public"."sub_snapshots" TO "service_role";

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "public"."sub_v_criticos_mes" TO "anon";

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "public"."sub_v_criticos_mes" TO "authenticated";

GRANT ALL ON TABLE "public"."sub_v_criticos_mes" TO "service_role";

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "public"."sub_v_resumo_clientes" TO "anon";

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "public"."sub_v_resumo_clientes" TO "authenticated";

GRANT ALL ON TABLE "public"."sub_v_resumo_clientes" TO "service_role";

GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."subscriptions" TO "anon";

GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."subscriptions" TO "authenticated";

GRANT ALL ON TABLE "public"."subscriptions" TO "service_role";

GRANT ALL ON TABLE "public"."sync_jobs" TO "anon";

GRANT ALL ON TABLE "public"."sync_jobs" TO "authenticated";

GRANT ALL ON TABLE "public"."sync_jobs" TO "service_role";

GRANT ALL ON TABLE "public"."sync_progress" TO "anon";

GRANT ALL ON TABLE "public"."sync_progress" TO "authenticated";

GRANT ALL ON TABLE "public"."sync_progress" TO "service_role";

GRANT ALL ON TABLE "public"."system_state" TO "anon";

GRANT ALL ON TABLE "public"."system_state" TO "authenticated";

GRANT ALL ON TABLE "public"."system_state" TO "service_role";

GRANT ALL ON TABLE "public"."ted_planos_acao" TO "anon";

GRANT ALL ON TABLE "public"."ted_planos_acao" TO "authenticated";

GRANT ALL ON TABLE "public"."ted_planos_acao" TO "service_role";

GRANT ALL ON TABLE "public"."ted_termos_execucao" TO "anon";

GRANT ALL ON TABLE "public"."ted_termos_execucao" TO "authenticated";

GRANT ALL ON TABLE "public"."ted_termos_execucao" TO "service_role";

GRANT ALL ON TABLE "public"."top_100_congresso" TO "anon";

GRANT ALL ON TABLE "public"."top_100_congresso" TO "authenticated";

GRANT ALL ON TABLE "public"."top_100_congresso" TO "service_role";

GRANT ALL ON TABLE "public"."transferencias_federais" TO "anon";

GRANT ALL ON TABLE "public"."transferencias_federais" TO "authenticated";

GRANT ALL ON TABLE "public"."transferencias_federais" TO "service_role";

GRANT ALL ON SEQUENCE "public"."tribunais_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."tribunais_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."tribunais_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."tse_bens_agg" TO "anon";

GRANT ALL ON TABLE "public"."tse_bens_agg" TO "authenticated";

GRANT ALL ON TABLE "public"."tse_bens_agg" TO "service_role";

GRANT ALL ON TABLE "public"."tse_bens_candidatos" TO "anon";

GRANT ALL ON TABLE "public"."tse_bens_candidatos" TO "authenticated";

GRANT ALL ON TABLE "public"."tse_bens_candidatos" TO "service_role";

GRANT ALL ON SEQUENCE "public"."tse_bens_candidatos_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."tse_bens_candidatos_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."tse_bens_candidatos_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."tse_candidatos_receitas_agg" TO "anon";

GRANT ALL ON TABLE "public"."tse_candidatos_receitas_agg" TO "authenticated";

GRANT ALL ON TABLE "public"."tse_candidatos_receitas_agg" TO "service_role";

GRANT ALL ON TABLE "public"."tse_conta_despesa" TO "anon";

GRANT ALL ON TABLE "public"."tse_conta_despesa" TO "authenticated";

GRANT ALL ON TABLE "public"."tse_conta_despesa" TO "service_role";

GRANT ALL ON TABLE "public"."tse_conta_extrato" TO "anon";

GRANT ALL ON TABLE "public"."tse_conta_extrato" TO "authenticated";

GRANT ALL ON TABLE "public"."tse_conta_extrato" TO "service_role";

GRANT ALL ON TABLE "public"."tse_conta_notafiscal" TO "anon";

GRANT ALL ON TABLE "public"."tse_conta_notafiscal" TO "authenticated";

GRANT ALL ON TABLE "public"."tse_conta_notafiscal" TO "service_role";

GRANT ALL ON TABLE "public"."tse_conta_receita" TO "anon";

GRANT ALL ON TABLE "public"."tse_conta_receita" TO "authenticated";

GRANT ALL ON TABLE "public"."tse_conta_receita" TO "service_role";

GRANT ALL ON SEQUENCE "public"."tse_despesas_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."tse_despesas_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."tse_despesas_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."tse_ingest_log" TO "anon";

GRANT ALL ON TABLE "public"."tse_ingest_log" TO "authenticated";

GRANT ALL ON TABLE "public"."tse_ingest_log" TO "service_role";

GRANT ALL ON SEQUENCE "public"."tse_ingest_log_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."tse_ingest_log_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."tse_ingest_log_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."tse_receitas" TO "anon";

GRANT ALL ON TABLE "public"."tse_receitas" TO "authenticated";

GRANT ALL ON TABLE "public"."tse_receitas" TO "service_role";

GRANT ALL ON SEQUENCE "public"."tse_receitas_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."tse_receitas_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."tse_receitas_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."tse_v_doador_emenda" TO "anon";

GRANT ALL ON TABLE "public"."tse_v_doador_emenda" TO "authenticated";

GRANT ALL ON TABLE "public"."tse_v_doador_emenda" TO "service_role";

GRANT ALL ON TABLE "public"."tse_v_dossie_doador" TO "anon";

GRANT ALL ON TABLE "public"."tse_v_dossie_doador" TO "authenticated";

GRANT ALL ON TABLE "public"."tse_v_dossie_doador" TO "service_role";

GRANT ALL ON TABLE "public"."tse_v_financiadores_parlamentar" TO "anon";

GRANT ALL ON TABLE "public"."tse_v_financiadores_parlamentar" TO "authenticated";

GRANT ALL ON TABLE "public"."tse_v_financiadores_parlamentar" TO "service_role";

GRANT ALL ON TABLE "public"."tse_v_receptor_top" TO "anon";

GRANT ALL ON TABLE "public"."tse_v_receptor_top" TO "authenticated";

GRANT ALL ON TABLE "public"."tse_v_receptor_top" TO "service_role";

GRANT ALL ON TABLE "public"."tse_v_rede_financiamento" TO "anon";

GRANT ALL ON TABLE "public"."tse_v_rede_financiamento" TO "authenticated";

GRANT ALL ON TABLE "public"."tse_v_rede_financiamento" TO "service_role";

GRANT ALL ON TABLE "public"."tuss_procedimentos" TO "anon";

GRANT ALL ON TABLE "public"."tuss_procedimentos" TO "authenticated";

GRANT ALL ON TABLE "public"."tuss_procedimentos" TO "service_role";

GRANT ALL ON TABLE "public"."usa_agencias" TO "anon";

GRANT ALL ON TABLE "public"."usa_agencias" TO "authenticated";

GRANT ALL ON TABLE "public"."usa_agencias" TO "service_role";

GRANT ALL ON TABLE "public"."usa_contratos" TO "anon";

GRANT ALL ON TABLE "public"."usa_contratos" TO "authenticated";

GRANT ALL ON TABLE "public"."usa_contratos" TO "service_role";

GRANT ALL ON TABLE "public"."usa_transacoes" TO "anon";

GRANT ALL ON TABLE "public"."usa_transacoes" TO "authenticated";

GRANT ALL ON TABLE "public"."usa_transacoes" TO "service_role";

GRANT ALL ON TABLE "public"."usa_v_metricas_transparencia" TO "anon";

GRANT ALL ON TABLE "public"."usa_v_metricas_transparencia" TO "authenticated";

GRANT ALL ON TABLE "public"."usa_v_metricas_transparencia" TO "service_role";

GRANT ALL ON TABLE "public"."usa_v_top_beneficiarios" TO "anon";

GRANT ALL ON TABLE "public"."usa_v_top_beneficiarios" TO "authenticated";

GRANT ALL ON TABLE "public"."usa_v_top_beneficiarios" TO "service_role";

GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."user_profiles" TO "anon";

GRANT REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."user_profiles" TO "authenticated";

GRANT ALL ON TABLE "public"."user_profiles" TO "service_role";

GRANT ALL ON TABLE "public"."v_bets_doadores_campanha" TO "anon";

GRANT ALL ON TABLE "public"."v_bets_doadores_campanha" TO "authenticated";

GRANT ALL ON TABLE "public"."v_bets_doadores_campanha" TO "service_role";

GRANT ALL ON TABLE "public"."v_bets_favorecidas_emendas" TO "anon";

GRANT ALL ON TABLE "public"."v_bets_favorecidas_emendas" TO "authenticated";

GRANT ALL ON TABLE "public"."v_bets_favorecidas_emendas" TO "service_role";

GRANT ALL ON TABLE "public"."v_bets_circuito_completo" TO "anon";

GRANT ALL ON TABLE "public"."v_bets_circuito_completo" TO "authenticated";

GRANT ALL ON TABLE "public"."v_bets_circuito_completo" TO "service_role";

GRANT ALL ON TABLE "public"."v_bets_socios_peps" TO "anon";

GRANT ALL ON TABLE "public"."v_bets_socios_peps" TO "authenticated";

GRANT ALL ON TABLE "public"."v_bets_socios_peps" TO "service_role";

GRANT ALL ON TABLE "public"."v_bets_socios_tse" TO "anon";

GRANT ALL ON TABLE "public"."v_bets_socios_tse" TO "authenticated";

GRANT ALL ON TABLE "public"."v_bets_socios_tse" TO "service_role";

GRANT ALL ON TABLE "public"."v_emenda_autor_favorecido" TO "anon";

GRANT ALL ON TABLE "public"."v_emenda_autor_favorecido" TO "authenticated";

GRANT ALL ON TABLE "public"."v_emenda_autor_favorecido" TO "service_role";

GRANT ALL ON TABLE "public"."v_empresa_emenda_contrato" TO "anon";

GRANT ALL ON TABLE "public"."v_empresa_emenda_contrato" TO "authenticated";

GRANT ALL ON TABLE "public"."v_empresa_emenda_contrato" TO "service_role";

GRANT ALL ON TABLE "public"."v_indicadores_atuais" TO "anon";

GRANT ALL ON TABLE "public"."v_indicadores_atuais" TO "authenticated";

GRANT ALL ON TABLE "public"."v_indicadores_atuais" TO "service_role";

GRANT ALL ON TABLE "public"."v_midia_doadora_emenda" TO "anon";

GRANT ALL ON TABLE "public"."v_midia_doadora_emenda" TO "authenticated";

GRANT ALL ON TABLE "public"."v_midia_doadora_emenda" TO "service_role";

GRANT ALL ON TABLE "public"."v_parlamentar_socio_emenda" TO "anon";

GRANT ALL ON TABLE "public"."v_parlamentar_socio_emenda" TO "authenticated";

GRANT ALL ON TABLE "public"."v_parlamentar_socio_emenda" TO "service_role";

GRANT ALL ON TABLE "public"."v_pncp_pub_por_fornecedor" TO "anon";

GRANT ALL ON TABLE "public"."v_pncp_pub_por_fornecedor" TO "authenticated";

GRANT ALL ON TABLE "public"."v_pncp_pub_por_fornecedor" TO "service_role";

GRANT ALL ON TABLE "public"."v_pncp_pub_por_orgao" TO "anon";

GRANT ALL ON TABLE "public"."v_pncp_pub_por_orgao" TO "authenticated";

GRANT ALL ON TABLE "public"."v_pncp_pub_por_orgao" TO "service_role";

GRANT ALL ON TABLE "public"."v_sancao_doacao" TO "anon";

GRANT ALL ON TABLE "public"."v_sancao_doacao" TO "authenticated";

GRANT ALL ON TABLE "public"."v_sancao_doacao" TO "service_role";

GRANT ALL ON TABLE "public"."v_sancao_emenda" TO "anon";

GRANT ALL ON TABLE "public"."v_sancao_emenda" TO "authenticated";

GRANT ALL ON TABLE "public"."v_sancao_emenda" TO "service_role";

GRANT ALL ON TABLE "public"."viagens" TO "anon";

GRANT ALL ON TABLE "public"."viagens" TO "authenticated";

GRANT ALL ON TABLE "public"."viagens" TO "service_role";

GRANT ALL ON TABLE "public"."voos_camara_companhia_agg" TO "anon";

GRANT ALL ON TABLE "public"."voos_camara_companhia_agg" TO "authenticated";

GRANT ALL ON TABLE "public"."voos_camara_companhia_agg" TO "service_role";

GRANT ALL ON TABLE "public"."voos_camara_deputado_agg" TO "anon";

GRANT ALL ON TABLE "public"."voos_camara_deputado_agg" TO "authenticated";

GRANT ALL ON TABLE "public"."voos_camara_deputado_agg" TO "service_role";

GRANT ALL ON TABLE "public"."voos_senado" TO "anon";

GRANT ALL ON TABLE "public"."voos_senado" TO "authenticated";

GRANT ALL ON TABLE "public"."voos_senado" TO "service_role";

GRANT ALL ON TABLE "public"."voos_senado_companhia_agg" TO "anon";

GRANT ALL ON TABLE "public"."voos_senado_companhia_agg" TO "authenticated";

GRANT ALL ON TABLE "public"."voos_senado_companhia_agg" TO "service_role";

GRANT ALL ON TABLE "public"."voos_senado_companhia_senador_agg" TO "anon";

GRANT ALL ON TABLE "public"."voos_senado_companhia_senador_agg" TO "authenticated";

GRANT ALL ON TABLE "public"."voos_senado_companhia_senador_agg" TO "service_role";

GRANT ALL ON SEQUENCE "public"."voos_senado_id_seq" TO "anon";

GRANT ALL ON SEQUENCE "public"."voos_senado_id_seq" TO "authenticated";

GRANT ALL ON SEQUENCE "public"."voos_senado_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."voos_senado_parlamentar_agg" TO "anon";

GRANT ALL ON TABLE "public"."voos_senado_parlamentar_agg" TO "authenticated";

GRANT ALL ON TABLE "public"."voos_senado_parlamentar_agg" TO "service_role";

GRANT ALL ON TABLE "public"."voos_senado_rota_agg" TO "anon";

GRANT ALL ON TABLE "public"."voos_senado_rota_agg" TO "authenticated";

GRANT ALL ON TABLE "public"."voos_senado_rota_agg" TO "service_role";

GRANT ALL ON TABLE "public"."voos_senado_terceiros_agg" TO "anon";

GRANT ALL ON TABLE "public"."voos_senado_terceiros_agg" TO "authenticated";

GRANT ALL ON TABLE "public"."voos_senado_terceiros_agg" TO "service_role";

GRANT ALL ON TABLE "public"."votacoes" TO "anon";

GRANT ALL ON TABLE "public"."votacoes" TO "authenticated";

GRANT ALL ON TABLE "public"."votacoes" TO "service_role";

GRANT ALL ON TABLE "public"."votacoes_brutas" TO "anon";

GRANT ALL ON TABLE "public"."votacoes_brutas" TO "authenticated";

GRANT ALL ON TABLE "public"."votacoes_brutas" TO "service_role";

GRANT ALL ON TABLE "public"."votacoes_orientacoes" TO "anon";

GRANT ALL ON TABLE "public"."votacoes_orientacoes" TO "authenticated";

GRANT ALL ON TABLE "public"."votacoes_orientacoes" TO "service_role";

GRANT ALL ON TABLE "public"."votacoes_senado" TO "anon";

GRANT ALL ON TABLE "public"."votacoes_senado" TO "authenticated";

GRANT ALL ON TABLE "public"."votacoes_senado" TO "service_role";

GRANT ALL ON TABLE "public"."vw_autor_publico" TO "anon";

GRANT ALL ON TABLE "public"."vw_autor_publico" TO "authenticated";

GRANT ALL ON TABLE "public"."vw_autor_publico" TO "service_role";

GRANT ALL ON TABLE "public"."vw_ciclo_analitico" TO "anon";

GRANT ALL ON TABLE "public"."vw_ciclo_analitico" TO "authenticated";

GRANT ALL ON TABLE "public"."vw_ciclo_analitico" TO "service_role";

GRANT ALL ON TABLE "public"."vw_data_completeness" TO "anon";

GRANT ALL ON TABLE "public"."vw_data_completeness" TO "authenticated";

GRANT ALL ON TABLE "public"."vw_data_completeness" TO "service_role";

GRANT ALL ON TABLE "public"."vw_emendas_companhias_abertas" TO "anon";

GRANT ALL ON TABLE "public"."vw_emendas_companhias_abertas" TO "authenticated";

GRANT ALL ON TABLE "public"."vw_emendas_companhias_abertas" TO "service_role";

GRANT ALL ON TABLE "public"."vw_narrativas_publicas" TO "anon";

GRANT ALL ON TABLE "public"."vw_narrativas_publicas" TO "authenticated";

GRANT ALL ON TABLE "public"."vw_narrativas_publicas" TO "service_role";

GRANT ALL ON TABLE "public"."vw_observatorio_status" TO "anon";

GRANT ALL ON TABLE "public"."vw_observatorio_status" TO "authenticated";

GRANT ALL ON TABLE "public"."vw_observatorio_status" TO "service_role";

GRANT ALL ON TABLE "public"."vw_relatorio_nacional" TO "anon";

GRANT ALL ON TABLE "public"."vw_relatorio_nacional" TO "authenticated";

GRANT ALL ON TABLE "public"."vw_relatorio_nacional" TO "service_role";

GRANT ALL ON TABLE "public"."vw_rp9_favorecidos_sancionados" TO "anon";

GRANT ALL ON TABLE "public"."vw_rp9_favorecidos_sancionados" TO "authenticated";

GRANT ALL ON TABLE "public"."vw_rp9_favorecidos_sancionados" TO "service_role";

GRANT ALL ON TABLE "public"."vw_rp9_ranking_sancionados" TO "anon";

GRANT ALL ON TABLE "public"."vw_rp9_ranking_sancionados" TO "authenticated";

GRANT ALL ON TABLE "public"."vw_rp9_ranking_sancionados" TO "service_role";

GRANT ALL ON TABLE "public"."vw_sebrae_cnpj_emendas" TO "anon";

GRANT ALL ON TABLE "public"."vw_sebrae_cnpj_emendas" TO "authenticated";

GRANT ALL ON TABLE "public"."vw_sebrae_cnpj_emendas" TO "service_role";

GRANT ALL ON TABLE "public"."vw_senac_cnpj_emendas" TO "anon";

GRANT ALL ON TABLE "public"."vw_senac_cnpj_emendas" TO "authenticated";

GRANT ALL ON TABLE "public"."vw_senac_cnpj_emendas" TO "service_role";

GRANT ALL ON TABLE "public"."vw_senar_cnpj_emendas" TO "anon";

GRANT ALL ON TABLE "public"."vw_senar_cnpj_emendas" TO "authenticated";

GRANT ALL ON TABLE "public"."vw_senar_cnpj_emendas" TO "service_role";

GRANT ALL ON TABLE "public"."vw_sesc_cnpj_emendas" TO "anon";

GRANT ALL ON TABLE "public"."vw_sesc_cnpj_emendas" TO "authenticated";

GRANT ALL ON TABLE "public"."vw_sesc_cnpj_emendas" TO "service_role";

GRANT ALL ON TABLE "public"."vw_sisi_cnpj_emendas" TO "anon";

GRANT ALL ON TABLE "public"."vw_sisi_cnpj_emendas" TO "authenticated";

GRANT ALL ON TABLE "public"."vw_sisi_cnpj_emendas" TO "service_role";

GRANT ALL ON TABLE "public"."vw_transferencias_por_uf" TO "anon";

GRANT ALL ON TABLE "public"."vw_transferencias_por_uf" TO "authenticated";

GRANT ALL ON TABLE "public"."vw_transferencias_por_uf" TO "service_role";

GRANT ALL ON TABLE "public"."watchlist_items" TO "anon";

GRANT ALL ON TABLE "public"."watchlist_items" TO "authenticated";

GRANT ALL ON TABLE "public"."watchlist_items" TO "service_role";

GRANT ALL ON TABLE "public"."watchlists" TO "anon";

GRANT ALL ON TABLE "public"."watchlists" TO "authenticated";

GRANT ALL ON TABLE "public"."watchlists" TO "service_role";
-- bloco 16_default_privileges — gerado por split_baseline.py (ordem interna = ordem do dump)
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";
-- bloco 17_hardening — pós-baseline: NÃO preservar grants perigosos TSE
-- (espelha db/migrations/0047; aplicado por último, sobrepõe o bloco 15).
--
-- Correção PROVA 1B (2026-07-19): faltava REVOKE MAINTAIN, presente em 0047
-- desde o commit 3791b59 (mergeado em main via d308f9a antes deste bloco ter
-- sido escrito) — omissão de transcrição manual, achado pela PROVA 1.
revoke insert, update, delete, truncate, references, trigger
  on table public.tse_receitas from anon, authenticated;
revoke insert, update, delete, truncate, references, trigger
  on table public.tse_despesas from anon, authenticated;
revoke maintain
  on table public.tse_receitas, public.tse_despesas from anon, authenticated;
revoke usage, update on sequence public.tse_receitas_id_seq from anon, authenticated;
revoke usage, update on sequence public.tse_despesas_id_seq from anon, authenticated;
