-- Helper RPC: permite rodar SQL arbitrário via PostgREST (service_role only)
-- Usado por scripts analíticos (grupo-empresarial.mjs, etc.)
CREATE OR REPLACE FUNCTION public.execute_sql(query TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  result JSONB;
BEGIN
  EXECUTE 'SELECT jsonb_agg(row_to_json(t)) FROM (' || query || ') t'
  INTO result;
  RETURN COALESCE(result, '[]'::jsonb);
END;
$$;

-- Só service_role pode chamar
REVOKE ALL ON FUNCTION public.execute_sql(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.execute_sql(TEXT) TO service_role;

COMMENT ON FUNCTION public.execute_sql IS
  'RPC helper para scripts analíticos. Aceita SQL arbitrário, retorna JSONB. '
  'Restrito a service_role — nunca exposto ao anon/authenticated.';
