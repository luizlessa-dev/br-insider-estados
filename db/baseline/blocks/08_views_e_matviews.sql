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



