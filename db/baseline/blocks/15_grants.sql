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
