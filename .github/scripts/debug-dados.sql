-- Verificar dados salvos em sub_pf_dados para CPF 01323507698 em 2026-08
SELECT cpf, fonte, categoria, status, titulo_secao, resumo, detalhes
FROM sub_pf_dados
WHERE cpf = '013.235.076-98' AND ciclo = '2026-08'
ORDER BY fonte;
