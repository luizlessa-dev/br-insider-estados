-- 20260723030044_harden_stf_tables_rls.sql
--
-- Hardening definitivo do domínio STF — contenção de escrita e leitura pública controlada.
--
-- Escopo (seis objetos, nenhum outro):
--   public.stf_gastos
--   public.stf_ministros
--   public.stf_votacoes
--   public.stf_repercussao_geral
--   public.stf_processos_politicos
--   public.stf_v_ministros_scores
--
-- Baseline (2026-07-23, origin/main): as cinco tabelas têm GRANT ALL para anon e
-- authenticated e RLS desabilitada; nenhuma policy versionada nelas. Escrita
-- legítima é feita exclusivamente por service_role. Consumo público confirmado
-- (frontend observatorio-stf, role anon) em stf_gastos, stf_ministros,
-- stf_votacoes e stf_repercussao_geral; sem consumidor confirmado para
-- stf_processos_politicos e stf_v_ministros_scores.
--
-- Desenho final:
--   * quatro tabelas com consumidor confirmado: RLS habilitada + policy pública
--     de SELECT (anon, authenticated); privilégios de escrita e estruturais
--     revogados de anon/authenticated.
--   * stf_processos_politicos: RLS habilitada, nenhuma policy, SELECT também
--     revogado de anon/authenticated — RLS sem policy nega tudo por padrão;
--     a revogação de SELECT é redundante mas explícita (defesa em profundidade
--     caso RLS seja desabilitada por engano no futuro). Acesso vira
--     exclusivamente backend (service_role/postgres).
--   * stf_v_ministros_scores: security_invoker=true (para que a RLS de
--     stf_ministros/stf_votacoes passe a valer também via a view) +
--     privilégios não-SELECT revogados de anon/authenticated; SELECT preservado.
--
-- Não usa FORCE ROW LEVEL SECURITY: o owner (postgres) e service_role
-- continuam operando sem restrição de policy, coerente com o comportamento
-- operacional já confirmado nas auditorias (PR #12, PR #13). O objetivo desta
-- migration é bloquear clientes públicos, não alterar a semântica do owner.
--
-- Rollback (conceitual, não executável neste arquivo):
--   Reverter para o estado anterior significa manter RLS habilitada e apenas
--   remover ou corrigir as policies criadas aqui, se necessário. A escrita
--   pública (GRANT ALL a anon/authenticated) nunca deve ser restaurada
--   automaticamente — qualquer necessidade de escrita de cliente exige
--   desenho novo e revisão humana explícita.

BEGIN;

-- ============================================================================
-- 1. PRECONDITIONS — validação de catálogo, sem leitura de dados de aplicação
-- ============================================================================
DO $$
DECLARE
  v_owner text;
  v_relkind "char";
  v_policy record;
  v_expected_owner text := 'postgres';
  v_tables text[] := ARRAY[
    'stf_gastos',
    'stf_ministros',
    'stf_votacoes',
    'stf_repercussao_geral',
    'stf_processos_politicos'
  ];
  v_tbl text;
BEGIN
  -- 1.1 As cinco tabelas devem existir em public, como tabela (relkind 'r')
  FOREACH v_tbl IN ARRAY v_tables LOOP
    SELECT c.relkind, pg_get_userbyid(c.relowner)
      INTO v_relkind, v_owner
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = 'public' AND c.relname = v_tbl;

    IF v_relkind IS NULL THEN
      RAISE EXCEPTION 'PRECONDITION FALHOU: public.% não existe', v_tbl;
    END IF;

    IF v_relkind <> 'r' THEN
      RAISE EXCEPTION 'PRECONDITION FALHOU: public.% não é uma tabela (relkind=%)', v_tbl, v_relkind;
    END IF;

    IF v_owner <> v_expected_owner THEN
      RAISE EXCEPTION 'PRECONDITION FALHOU: public.% tem owner % (esperado %)', v_tbl, v_owner, v_expected_owner;
    END IF;

    -- 1.2 Nenhuma policy deve existir hoje nas cinco tabelas
    FOR v_policy IN
      SELECT polname FROM pg_policy p
      JOIN pg_class c ON c.oid = p.polrelid
      JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = 'public' AND c.relname = v_tbl
    LOOP
      RAISE EXCEPTION 'PRECONDITION FALHOU: public.% já possui policy "%" — revisão humana necessária', v_tbl, v_policy.polname;
    END LOOP;
  END LOOP;

  -- 1.3 A view deve existir como view (relkind 'v'), com owner esperado
  SELECT c.relkind, pg_get_userbyid(c.relowner)
    INTO v_relkind, v_owner
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relname = 'stf_v_ministros_scores';

  IF v_relkind IS NULL THEN
    RAISE EXCEPTION 'PRECONDITION FALHOU: public.stf_v_ministros_scores não existe';
  END IF;

  IF v_relkind <> 'v' THEN
    RAISE EXCEPTION 'PRECONDITION FALHOU: public.stf_v_ministros_scores não é uma view (relkind=%)', v_relkind;
  END IF;

  IF v_owner <> v_expected_owner THEN
    RAISE EXCEPTION 'PRECONDITION FALHOU: public.stf_v_ministros_scores tem owner % (esperado %)', v_owner, v_expected_owner;
  END IF;

  -- 1.4 Assinatura de colunas da view deve corresponder exatamente à consolidada
  --     e aprovada (nome, ordem e tipo) — checagem por catálogo, não por texto
  --     de pg_get_viewdef, que varia em formatação entre versões do PostgreSQL
  --     sem indicar divergência real de definição.
  IF (
    SELECT array_agg(format('%s:%s', a.attname, format_type(a.atttypid, a.atttypmod)) ORDER BY a.attnum)
    FROM pg_attribute a
    WHERE a.attrelid = 'public.stf_v_ministros_scores'::regclass
      AND a.attnum > 0
      AND NOT a.attisdropped
  ) IS DISTINCT FROM ARRAY[
    'id:uuid',
    'nome:text',
    'iniciais:text',
    'data_posse:date',
    'indicado_por:text',
    'partido_indicante:text',
    'ativo:boolean',
    'score_geral:numeric',
    'score_direitos_civis:numeric',
    'score_lib_imprensa:numeric',
    'score_seg_publica:numeric',
    'score_economico:numeric',
    'score_democracia:numeric',
    'total_votos:bigint',
    'votos_favor:bigint',
    'votos_contra:bigint'
  ] THEN
    RAISE EXCEPTION 'PRECONDITION FALHOU: colunas de public.stf_v_ministros_scores divergem da definição consolidada e aprovada';
  END IF;
END $$;

-- ============================================================================
-- 2. REVOGAÇÃO DE PRIVILÉGIOS — tabelas
-- ============================================================================

-- stf_gastos, stf_ministros, stf_votacoes, stf_repercussao_geral: leitura pública
-- preservada (SELECT não é tocado); escrita e privilégios estruturais removidos.
REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN
  ON TABLE public.stf_gastos
  FROM anon, authenticated;

REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN
  ON TABLE public.stf_ministros
  FROM anon, authenticated;

REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN
  ON TABLE public.stf_votacoes
  FROM anon, authenticated;

REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN
  ON TABLE public.stf_repercussao_geral
  FROM anon, authenticated;

-- stf_processos_politicos: sem consumidor confirmado — vira backend-only.
-- Revoga também SELECT, além dos privilégios de escrita/estruturais.
REVOKE SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN
  ON TABLE public.stf_processos_politicos
  FROM anon, authenticated;

-- ============================================================================
-- 3. HABILITAÇÃO DE RLS
-- ============================================================================

ALTER TABLE public.stf_gastos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stf_ministros ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stf_votacoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stf_repercussao_geral ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stf_processos_politicos ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 4. POLICIES PÚBLICAS DE SELECT
-- ============================================================================
-- Uma policy por tabela com consumidor confirmado. Nenhuma policy em
-- stf_processos_politicos — RLS habilitada sem policy nega todo acesso de
-- cliente (deny-by-default), coerente com a revogação de SELECT acima.

CREATE POLICY stf_gastos_select_public
  ON public.stf_gastos
  FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY stf_ministros_select_public
  ON public.stf_ministros
  FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY stf_votacoes_select_public
  ON public.stf_votacoes
  FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY stf_repercussao_geral_select_public
  ON public.stf_repercussao_geral
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- ============================================================================
-- 5. HARDENING DA VIEW
-- ============================================================================
-- security_invoker=true: a view passa a executar com os privilégios e as
-- policies RLS do papel que consulta, em vez do owner — assim a RLS recém
-- habilitada em stf_ministros/stf_votacoes também vale para quem lê a view.
ALTER VIEW public.stf_v_ministros_scores
  SET (security_invoker = true);

-- MAINTAIN não é um privilégio aplicável a views (só a tabelas e matviews);
-- omitido aqui de propósito, não por omissão.
REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
  ON TABLE public.stf_v_ministros_scores
  FROM anon, authenticated;

-- ============================================================================
-- 6. POSTCONDITIONS — validação de catálogo do estado final
-- ============================================================================
DO $$
DECLARE
  v_rls_enabled boolean;
  v_policy_count integer;
  v_bad_policy record;
  v_priv text;
  v_tbl text;
  v_public_tables text[] := ARRAY[
    'stf_gastos',
    'stf_ministros',
    'stf_votacoes',
    'stf_repercussao_geral'
  ];
BEGIN
  -- 6.1 RLS habilitada nas cinco tabelas
  FOREACH v_tbl IN ARRAY (v_public_tables || ARRAY['stf_processos_politicos']) LOOP
    SELECT c.relrowsecurity INTO v_rls_enabled
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = 'public' AND c.relname = v_tbl;

    IF NOT v_rls_enabled THEN
      RAISE EXCEPTION 'POSTCONDITION FALHOU: RLS não habilitada em public.%', v_tbl;
    END IF;
  END LOOP;

  -- 6.2 Exatamente quatro policies no total, todas SELECT, todas anon+authenticated, todas USING true-equivalente
  SELECT count(*) INTO v_policy_count
    FROM pg_policy p
    JOIN pg_class c ON c.oid = p.polrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relname = ANY (v_public_tables);

  IF v_policy_count <> 4 THEN
    RAISE EXCEPTION 'POSTCONDITION FALHOU: esperado exatamente 4 policies nas tabelas públicas, encontrado %', v_policy_count;
  END IF;

  FOR v_bad_policy IN
    SELECT c.relname, p.polname, p.polcmd, p.polroles, pg_get_expr(p.polqual, p.polrelid) AS qual_expr
      FROM pg_policy p
      JOIN pg_class c ON c.oid = p.polrelid
      JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = 'public' AND c.relname = ANY (v_public_tables)
  LOOP
    IF v_bad_policy.polcmd <> 'r' THEN
      RAISE EXCEPTION 'POSTCONDITION FALHOU: policy % em % não é FOR SELECT (polcmd=%)', v_bad_policy.polname, v_bad_policy.relname, v_bad_policy.polcmd;
    END IF;

    IF v_bad_policy.polroles <> ARRAY[
      (SELECT oid FROM pg_roles WHERE rolname = 'anon'),
      (SELECT oid FROM pg_roles WHERE rolname = 'authenticated')
    ]::oid[]
    AND v_bad_policy.polroles <> ARRAY[
      (SELECT oid FROM pg_roles WHERE rolname = 'authenticated'),
      (SELECT oid FROM pg_roles WHERE rolname = 'anon')
    ]::oid[] THEN
      RAISE EXCEPTION 'POSTCONDITION FALHOU: policy % em % não está restrita a anon+authenticated', v_bad_policy.polname, v_bad_policy.relname;
    END IF;

    IF v_bad_policy.qual_expr IS DISTINCT FROM 'true' THEN
      RAISE EXCEPTION 'POSTCONDITION FALHOU: policy % em % não usa USING (true) (encontrado: %)', v_bad_policy.polname, v_bad_policy.relname, v_bad_policy.qual_expr;
    END IF;
  END LOOP;

  -- 6.3 Nenhuma policy em stf_processos_politicos
  SELECT count(*) INTO v_policy_count
    FROM pg_policy p
    JOIN pg_class c ON c.oid = p.polrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relname = 'stf_processos_politicos';

  IF v_policy_count <> 0 THEN
    RAISE EXCEPTION 'POSTCONDITION FALHOU: stf_processos_politicos não deveria ter policy, encontrado %', v_policy_count;
  END IF;

  -- 6.4 anon/authenticated sem INSERT/UPDATE/DELETE/TRUNCATE/REFERENCES/TRIGGER nas 5 tabelas + view
  FOREACH v_tbl IN ARRAY (v_public_tables || ARRAY['stf_processos_politicos', 'stf_v_ministros_scores']) LOOP
    FOREACH v_priv IN ARRAY ARRAY['INSERT', 'UPDATE', 'DELETE', 'TRUNCATE', 'REFERENCES', 'TRIGGER'] LOOP
      IF has_table_privilege('anon', 'public.' || quote_ident(v_tbl), v_priv) THEN
        RAISE EXCEPTION 'POSTCONDITION FALHOU: anon ainda tem % em public.%', v_priv, v_tbl;
      END IF;
      IF has_table_privilege('authenticated', 'public.' || quote_ident(v_tbl), v_priv) THEN
        RAISE EXCEPTION 'POSTCONDITION FALHOU: authenticated ainda tem % em public.%', v_priv, v_tbl;
      END IF;
    END LOOP;
  END LOOP;

  -- 6.5 anon/authenticated sem MAINTAIN nas cinco tabelas (view não suporta MAINTAIN)
  FOREACH v_tbl IN ARRAY (v_public_tables || ARRAY['stf_processos_politicos']) LOOP
    IF has_table_privilege('anon', 'public.' || quote_ident(v_tbl), 'MAINTAIN') THEN
      RAISE EXCEPTION 'POSTCONDITION FALHOU: anon ainda tem MAINTAIN em public.%', v_tbl;
    END IF;
    IF has_table_privilege('authenticated', 'public.' || quote_ident(v_tbl), 'MAINTAIN') THEN
      RAISE EXCEPTION 'POSTCONDITION FALHOU: authenticated ainda tem MAINTAIN em public.%', v_tbl;
    END IF;
  END LOOP;

  -- 6.6 anon/authenticated sem SELECT em stf_processos_politicos
  IF has_table_privilege('anon', 'public.stf_processos_politicos', 'SELECT') THEN
    RAISE EXCEPTION 'POSTCONDITION FALHOU: anon ainda tem SELECT em public.stf_processos_politicos';
  END IF;
  IF has_table_privilege('authenticated', 'public.stf_processos_politicos', 'SELECT') THEN
    RAISE EXCEPTION 'POSTCONDITION FALHOU: authenticated ainda tem SELECT em public.stf_processos_politicos';
  END IF;

  -- 6.7 SELECT preservado nas quatro tabelas públicas e na view
  FOREACH v_tbl IN ARRAY (v_public_tables || ARRAY['stf_v_ministros_scores']) LOOP
    IF NOT has_table_privilege('anon', 'public.' || quote_ident(v_tbl), 'SELECT') THEN
      RAISE EXCEPTION 'POSTCONDITION FALHOU: anon perdeu SELECT em public.%', v_tbl;
    END IF;
    IF NOT has_table_privilege('authenticated', 'public.' || quote_ident(v_tbl), 'SELECT') THEN
      RAISE EXCEPTION 'POSTCONDITION FALHOU: authenticated perdeu SELECT em public.%', v_tbl;
    END IF;
  END LOOP;

  -- 6.8 security_invoker=true na view
  IF NOT EXISTS (
    SELECT 1
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = 'stf_v_ministros_scores'
      AND c.reloptions IS NOT NULL
      AND 'security_invoker=true' = ANY (c.reloptions)
  ) THEN
    RAISE EXCEPTION 'POSTCONDITION FALHOU: public.stf_v_ministros_scores sem security_invoker=true';
  END IF;

  -- 6.9 service_role e postgres não tiveram privilégios reduzidos (grant permanece ALL)
  -- Verificação individual por privilégio: has_table_privilege com lista agregada
  -- ('SELECT, INSERT, UPDATE, DELETE') tem semântica OR e aprovaria mesmo faltando privilégios.
  FOREACH v_tbl IN ARRAY (v_public_tables || ARRAY['stf_processos_politicos', 'stf_v_ministros_scores']) LOOP
    FOREACH v_priv IN ARRAY ARRAY['SELECT', 'INSERT', 'UPDATE', 'DELETE'] LOOP
      IF NOT has_table_privilege('service_role', 'public.' || quote_ident(v_tbl), v_priv) THEN
        RAISE EXCEPTION 'POSTCONDITION FALHOU: service_role perdeu privilégio % em public.%', v_priv, v_tbl;
      END IF;
      IF NOT has_table_privilege('postgres', 'public.' || quote_ident(v_tbl), v_priv) THEN
        RAISE EXCEPTION 'POSTCONDITION FALHOU: postgres (owner) perdeu privilégio % em public.%', v_priv, v_tbl;
      END IF;
    END LOOP;
  END LOOP;
END $$;

COMMIT;
