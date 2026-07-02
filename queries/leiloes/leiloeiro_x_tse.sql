-- BR Insider — Leiloeiros × Doações TSE
-- Cruzamento: leiloeiro CNPJ × doações eleitorais recebidas ou efetuadas
-- Valor jornalístico: leiloeiro financia campanha do mesmo parlamentar que lhe repassa emendas

SELECT
    ll.cnpj_completo,
    COALESCE(ll.razao_social, ll.nome_fantasia)     AS nome_leiloeiro,
    ll.uf,
    -- Doações recebidas pelo leiloeiro (como candidato PJ — raro, mas existe)
    COUNT(DISTINCT r.id)                            AS total_receitas_tse,
    SUM(r.valor_receita)                            AS total_recebido_tse,
    -- Doações feitas pelo leiloeiro (como doador)
    COUNT(DISTINCT d.id)                            AS total_doacoes_feitas,
    SUM(d.valor_despesa)                            AS total_doado_tse
FROM public.leiloes_leiloeiros ll
LEFT JOIN public.tse_receitas r
    ON r.cnpj_doador = ll.cnpj_completo
LEFT JOIN public.tse_despesas d
    ON d.cnpj_fornecedor = ll.cnpj_completo
WHERE ll.situacao_cadastral = 2
  AND (r.id IS NOT NULL OR d.id IS NOT NULL)
GROUP BY ll.cnpj_completo, ll.razao_social, ll.nome_fantasia, ll.uf
ORDER BY total_doado_tse DESC NULLS LAST
LIMIT 100;
