-- Migration 0042 — FRED: séries macro econômicas (câmbio, inflação, PIB)
-- The Brasilia Insider · 2026-07-06

CREATE TABLE IF NOT EXISTS public.macro_fred (
    series_id   text        NOT NULL,   -- ex: DEXBZUS, BRACPIALLMINMEI, BRAGDPNADSMEI
    date        date        NOT NULL,
    value       float,
    updated_at  timestamptz DEFAULT now(),
    PRIMARY KEY (series_id, date)
);

CREATE INDEX IF NOT EXISTS macro_fred_series_date ON public.macro_fred (series_id, date DESC);

CREATE TABLE IF NOT EXISTS public.macro_fred_ingest_log (
    id          serial PRIMARY KEY,
    series_id   text,
    status      text,
    n_novos     integer DEFAULT 0,
    erro        text,
    started_at  timestamptz DEFAULT now(),
    finished_at timestamptz
);

COMMENT ON TABLE public.macro_fred IS
    'Séries macroeconômicas do FRED (Federal Reserve Bank of St. Louis). '
    'Usadas como contexto editorial: câmbio BRL/USD, inflação e PIB do Brasil.';
