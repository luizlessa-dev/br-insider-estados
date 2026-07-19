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
