-- Migration 0043 — RPC para mapa de emendas por município
-- Agrega emendas_api por localidade_ibge e enriquece com lat/lon do ibge_municipios.
-- The Brasilia Insider · 2026-07-06

CREATE OR REPLACE FUNCTION public.emendas_mapa_agregado()
RETURNS TABLE (
    codigo_ibge text,
    nome        text,
    uf          char(2),
    latitude    numeric,
    longitude   numeric,
    total_pago  numeric,
    n_emendas   bigint
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        m.codigo_ibge,
        m.nome,
        m.uf,
        m.latitude,
        m.longitude,
        SUM(ea.valor_pago)  AS total_pago,
        COUNT(*)            AS n_emendas
    FROM public.emendas_api ea
    JOIN public.ibge_municipios m
        ON m.codigo_ibge = ea.localidade_ibge
    WHERE ea.localidade_ibge IS NOT NULL
      AND ea.valor_pago      IS NOT NULL
      AND ea.valor_pago      > 0
      AND m.latitude         IS NOT NULL
    GROUP BY m.codigo_ibge, m.nome, m.uf, m.latitude, m.longitude
    ORDER BY total_pago DESC;
$$;
