-- =============================================================================
-- 0020b_alertas_rpc.sql
-- Funções RPC para alertas investigativos — BR Insider
-- Permite executar as queries de alerta via API REST do Supabase
-- sem necessidade de conexão direta ao banco (psycopg2).
-- =============================================================================

-- Alerta 1: ministro reuniu com empresa sancionada
create or replace function alerta_ministerio_sancao()
returns table (
    compromisso_id      text,
    data_inicio         date,
    hora_inicio         text,
    orgao_sigla         text,
    autoridade_nome     text,
    autoridade_cargo    text,
    assunto             text,
    local               text,
    participante_nome   text,
    cnpj_participante   text,
    instituicao         text,
    cargo_inst          text,
    tipo_sancao         text,
    cadastro            text,
    descricao_sancao    text,
    data_inicio_sancao  text,
    data_fim_sancao     text,
    orgao_sancao        text,
    nome_sancionado     text
)
language sql security definer
as $$
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
        s.data_inicio_sancao::text,
        s.data_fim_sancao::text,
        s.orgao_nome,
        s.nome
    from privados p
    join sancoes s on s.cpf_cnpj = p.cnpj
    where length(p.cnpj) >= 14
    order by p.data_inicio desc, p.orgao_sigla;
$$;

-- Alerta 2: ministro reuniu com empresa que recebeu emenda > R$100k
create or replace function alerta_ministerio_emenda()
returns table (
    compromisso_id          text,
    data_inicio             date,
    hora_inicio             text,
    orgao_sigla             text,
    autoridade_nome         text,
    autoridade_cargo        text,
    assunto                 text,
    local                   text,
    participante_nome       text,
    cnpj_participante       text,
    instituicao             text,
    autor_emenda            text,
    tipo_emenda             text,
    ano_emenda              integer,
    total_recebido_emendas  numeric,
    n_emendas               bigint
)
language sql security definer
as $$
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

-- Alerta 3: combo — sancionada E recebeu emenda (máxima prioridade)
create or replace function alerta_combo_sancao_emenda()
returns table (
    compromisso_id          text,
    data_inicio             date,
    hora_inicio             text,
    orgao_sigla             text,
    autoridade_nome         text,
    assunto                 text,
    participante_nome       text,
    cnpj_participante       text,
    instituicao             text,
    tipo_cadastro_sancao    text,
    tipo_sancao             text,
    total_emendas           numeric
)
language sql security definer
as $$
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

-- Alerta 4: audiências públicas na Câmara — últimos 7 dias
create or replace function alerta_audiencias_semana()
returns table (
    id                  text,
    data                date,
    data_hora_inicio    timestamptz,
    tipo_evento         text,
    situacao            text,
    descricao           text,
    local               text,
    comissoes           text[],
    url_pauta           text,
    url_video           text
)
language sql security definer
as $$
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

-- Alerta 5: ranking ministros com mais reuniões privadas (7 dias)
create or replace function alerta_ranking_privados()
returns table (
    orgao_sigla                 text,
    autoridade_nome             text,
    autoridade_cargo            text,
    n_compromissos_privados     bigint,
    total_participantes_privados bigint,
    primeira_reuniao            date,
    ultima_reuniao              date
)
language sql security definer
as $$
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

-- Permissões (service_role executa, anon não acessa)
revoke execute on function alerta_ministerio_sancao() from anon, authenticated;
revoke execute on function alerta_ministerio_emenda() from anon, authenticated;
revoke execute on function alerta_combo_sancao_emenda() from anon, authenticated;
revoke execute on function alerta_audiencias_semana() from anon, authenticated;
revoke execute on function alerta_ranking_privados() from anon, authenticated;

grant execute on function alerta_ministerio_sancao() to service_role;
grant execute on function alerta_ministerio_emenda() to service_role;
grant execute on function alerta_combo_sancao_emenda() to service_role;
grant execute on function alerta_audiencias_semana() to service_role;
grant execute on function alerta_ranking_privados() to service_role;
