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
