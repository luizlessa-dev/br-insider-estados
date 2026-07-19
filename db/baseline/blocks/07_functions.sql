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
