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
