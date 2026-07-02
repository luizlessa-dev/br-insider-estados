-- BR Insider — Leiloeiros × Emendas Parlamentares
-- Cruzamento: leiloeiro com CNPJ ativo × recebimentos de emendas parlamentares
-- Valor jornalístico: leiloeiro que atua em varas de políticos que também lhe repassam emendas

SELECT
    ll.cnpj_completo,
    COALESCE(ll.razao_social, ll.nome_fantasia)     AS nome_leiloeiro,
    ll.uf,
    ll.municipio_codigo,
    ll.situacao_cadastral,
    ll.data_inicio_atividade,
    COUNT(DISTINCT ef.id)                           AS total_emendas,
    SUM(ef.valor_empenhado)                         AS total_empenhado,
    SUM(ef.valor_pago)                              AS total_pago,
    MIN(ef.ano)                                     AS ano_inicio,
    MAX(ef.ano)                                     AS ano_fim,
    COUNT(DISTINCT ef.autor_cpf)                    AS parlamentares_distintos,
    STRING_AGG(DISTINCT ef.autor_nome, '; ' ORDER BY ef.autor_nome)
                                                    AS parlamentares
FROM public.leiloes_leiloeiros ll
JOIN public.emendas_favorecidos ef
    ON REPLACE(REPLACE(ef.cnpj_cpf_beneficiario, '.', ''), '/', '')
        = REPLACE(REPLACE(ll.cnpj_completo, '.', ''), '/', '')
WHERE ll.situacao_cadastral = 2   -- apenas ativos
GROUP BY
    ll.cnpj_completo, ll.razao_social, ll.nome_fantasia,
    ll.uf, ll.municipio_codigo, ll.situacao_cadastral, ll.data_inicio_atividade
HAVING SUM(ef.valor_pago) > 0
ORDER BY total_pago DESC
LIMIT 100;
