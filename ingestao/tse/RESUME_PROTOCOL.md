# Protocolo de retomada — pipeline seguro TSE

Um `run` corresponde a **exatamente um arquivo** (dataset + ano + ZIP específico).
O staging de um arquivo **nunca** pode ser reutilizado por outro arquivo.

## Identidade do arquivo (registrada em `tse_load_runs`)

| Campo | Papel |
|---|---|
| `run_id` (uuid) | identidade lógica do run; chave de particionamento do staging |
| `dataset`, `ano` | o alvo (receitas/despesas, ano eleitoral) |
| `zip_sha256` | SHA-256 do ZIP baixado — identidade do CONTEÚDO do arquivo |
| `zip_bytes` | tamanho do ZIP (checagem barata antes do hash) |
| `source_url` | URL de origem no CDN do TSE |
| `pipeline_commit` | commit SHA do pipeline que gerou o run |
| `transformer_version` | versão do transformador (parser) — muda a semântica das linhas |
| `ultimo_batch_confirmado` | progresso: último batch persistido com sucesso |

## Condições que PERMITEM retomar (mesmo run_id)

Todas verdadeiras:
1. `status = 'running'` e `phase in ('staging','staged')` (não `promovido`).
2. `zip_sha256` do arquivo atual == o registrado no run.
3. `zip_bytes` igual.
4. `dataset` e `ano` iguais.
5. `transformer_version` igual (a mesma versão produz os mesmos fingerprints).

Na retomada, `stage_rows(..., resume=True)` re-envia desde o começo do arquivo;
o `ON CONFLICT (run_id, row_fingerprint) DO NOTHING` ignora o que já entrou
(idempotente) e insere só o que falta. As linhas ignoradas são contadas e
registradas (`linhas_ignoradas`) — na retomada isso é ESPERADO, não erro.

## Condições que OBRIGAM um novo run (novo run_id)

Qualquer uma:
- `zip_sha256` diferente → o TSE republicou o arquivo (conteúdo mudou). Reutilizar
  o staging antigo misturaria versões. **Novo run.**
- `zip_bytes` diferente (mesmo antes de hashear).
- `transformer_version` diferente → os fingerprints mudam de significado; o
  staging antigo é incompatível. **Novo run.**
- `dataset`/`ano` diferentes.
- Run já `promovido` → concluído; recarregar é um novo run.

## Garantia "um staging por arquivo"

O staging é particionado por `run_id`, e o `run_id` está amarrado a
`(dataset, ano, zip_sha256, transformer_version)` em `tse_load_runs`. A promoção
(`tse_promote_year`) valida que o run pertence a `(dataset, ano)`. Um arquivo
diferente → hash diferente → **exige** novo run_id → staging isolado. Nunca há
reaproveitamento cruzado.

## Runs abandonados

`tse_gc_staging(interval)` marca runs `running` mais velhos que o intervalo como
`erro/falha`, agenda expiração do staging (default 7 dias) e limpa o staging
expirado. Preserva o staging na janela para diagnóstico antes de coletar.
