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
