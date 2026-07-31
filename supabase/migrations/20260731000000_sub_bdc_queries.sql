-- Tabela de rastreamento de queries async BDC (ondemand certidões)
-- Fluxo: pipeline submete → guarda queryId → BDC chama webhook → Edge Function processa

CREATE TABLE IF NOT EXISTS public.sub_bdc_queries (
    id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    query_id      text        UNIQUE NOT NULL,          -- queryid{uuid} retornado pelo BDC
    dossie_id     uuid        NOT NULL REFERENCES public.sub_dossies(id) ON DELETE CASCADE,
    cnpj          text        NOT NULL,
    dataset       text        NOT NULL,                 -- ex: ondemand_pgfn
    status        text        NOT NULL DEFAULT 'pending'
                              CHECK (status IN ('pending','received','processed','error')),
    payload       jsonb,                                -- payload bruto do webhook BDC
    alertas_criados int       DEFAULT 0,
    erro          text,
    created_at    timestamptz NOT NULL DEFAULT now(),
    received_at   timestamptz,
    processed_at  timestamptz
);

CREATE INDEX IF NOT EXISTS sub_bdc_queries_dossie_id_idx ON public.sub_bdc_queries(dossie_id);
CREATE INDEX IF NOT EXISTS sub_bdc_queries_status_idx    ON public.sub_bdc_queries(status);
CREATE INDEX IF NOT EXISTS sub_bdc_queries_created_at_idx ON public.sub_bdc_queries(created_at DESC);

-- RLS: somente service_role acessa (pipeline + Edge Function)
ALTER TABLE public.sub_bdc_queries ENABLE ROW LEVEL SECURITY;
