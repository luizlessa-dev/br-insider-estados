# Validação de SQ_RECEITA / SQ_DESPESA — parsing real (sem escrita no Supabase)

Método: download do ZIP oficial do CDN do TSE + parsing com o próprio connector
(`iter_receitas`/`iter_despesas`), contando `source_id` (SQ_*). Nenhuma linha foi
gravada em banco. Sem reprodução de conteúdo pessoal (só contagens).

| Ano/dataset | Coluna oficial | Total | Preenchidos | Nulos | Distintos | Duplicados | % dup | Arquivo (layout) |
|---|---|---|---|---|---|---|---|---|
| 2018 receitas | SQ_RECEITA | 313.472 | 313.472 | 0 | 300.470 | 13.002 | 4,1% | receitas_candidatos_2018 |
| 2018 despesas | SQ_DESPESA | 1.648.077 | 1.648.077 | 0 | 1.349.554 | 298.523 | 18,1% | despesas_contratadas_candidatos_2018 |
| 2022 receitas | SQ_RECEITA | 271.352 | 271.352 | 0 | 259.148 | 12.204 | 4,5% | receitas_candidatos_doador_originario_2022 |
| 2022 despesas | SQ_DESPESA | 2.133.846 | 2.133.846 | 0 | 1.762.666 | 371.180 | 17,4% | despesas_contratadas_candidatos_2022 |
| 2024 receitas | SQ_RECEITA | 2.040.964 | 2.040.964 | 0 | 1.831.377 | 209.587 | 10,3% | receitas_candidatos_2024 |
| 2024 despesas | SQ_DESPESA | 4.451.809 | 4.451.809 | 0 | 2.966.193 | 1.485.616 | 33,4% | despesas_contratadas_candidatos_2024 |

## Colunas SQ_* nos headers

- Receitas: `SQ_PRESTADOR_CONTAS`, `SQ_RECEITA` (+ `SQ_CANDIDATO`, `SQ_CANDIDATO_DOADOR` em 2018/2024).
- Despesas: `SQ_PRESTADOR_CONTAS`, `SQ_CANDIDATO`, `SQ_CANDIDATO_FORNECEDOR`, `SQ_DESPESA`.

## Diferenças de layout

- Receitas 2018/2024 usam o arquivo `receitas_candidatos_<ano>`; 2022 usa a
  variante `receitas_candidatos_doador_originario_<ano>` (explode por doador
  originário). O connector seleciona o arquivo por prefixo — a variante escolhida
  muda a granularidade e a taxa de duplicação de SQ_RECEITA.
- Despesas mantêm `despesas_contratadas_candidatos_<ano>` nos três anos.

## Conclusões

1. **SQ_RECEITA/SQ_DESPESA existem e são 100% preenchidos** (0 nulos) em
   2018/2022/2024. Os campos que o pipeline usava como "id"
   (`numero_recibo`/`numero_documento`) é que são nulos — não o SQ_*.
2. **SQ_* NÃO é único**: 4–10% (receitas) e 17–33% (despesas) de duplicatas, por
   denormalização do CSV. Portanto **não serve como chave única** nem como base
   de `UNIQUE(ano, source_id)` — o índice parcial proposto foi marcado NÃO VIÁVEL.
3. **Identidade permanece o `row_fingerprint`** (conteúdo + ordinal), que
   distingue as linhas denormalizadas legítimas. `source_id` é preservado como
   dado e entra no conteúdo do fingerprint (integridade/detecção de alteração).
4. **Fallback por fingerprint é necessário em todos os anos** para as linhas onde
   o SQ_* repete — ou seja, a identidade efetiva é sempre o fingerprint.
