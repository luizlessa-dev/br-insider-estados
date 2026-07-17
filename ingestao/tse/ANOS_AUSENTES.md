# Classificação dos anos ausentes de tse_receitas / tse_despesas

Correção da redação anterior (que registrava genericamente "2018–2020 perda
confirmada de 20/jun"). Cada ano é classificado pelo que a EVIDÊNCIA sustenta.

Base factual disponível:
- Log real da run `ingest-tse.yml` de 2026-06-20 (id 27855284753): mostra
  `tse_receitas: deletadas linhas do ano 2014`, `tse_despesas: deletadas 2014`,
  `tse_receitas: deletadas 2018`, `tse_despesas: deletadas 2018`, seguidos de
  falha de download (CDN timeout) — nenhuma reposição.
- Estado atual (produção): `tse_receitas`/`tse_despesas` contêm SÓ 2022 e 2024.
- `tse_candidatos` (upsert, sem delete) contém 2014/2016/2018/2020/2022/2024.
- NÃO há snapshot/backup consultado que prove o conteúdo anterior de
  receitas/despesas por ano.

| Ano | DELETE comprovado (20/jun)? | Vazio hoje? | Existência anterior confirmada? | Causa da ausência |
|-----|-----|-----|-----|-----|
| 2014 | **Sim** (log explícito, receitas+despesas) | Sim | **Não provada** (sem backup) | DELETE em 20/jun; se havia dado, foi apagado sem reposição |
| 2016 | Não (não processado nessa run) | Sim | Não provada | **Desconhecida** — pode nunca ter sido carregado, ou apagado em run anterior não auditada |
| 2018 | **Sim** (log explícito, receitas+despesas) | Sim | **Não provada** (sem backup) | DELETE em 20/jun; idem 2014 |
| 2020 | Não (não processado nessa run) | Sim | Não provada | **Desconhecida** — idem 2016 |
| 2022 | Não | Não (presente) | Sim (presente) | n/a |
| 2024 | Não | Não (presente) | Sim (presente) | n/a |

## Leitura honesta

- **DELETE comprovado**: 2014 e 2018 (receitas e despesas) — o log mostra o
  DELETE tendo rodado antes da falha de download.
- **Perda de dados confirmada**: **nenhuma** ainda, porque não há prova de que
  esses anos TINHAM dado antes do DELETE. O DELETE de uma partição vazia não
  perde nada. Confirmar exige backup/PITR (pendência aberta).
- **Causa desconhecida**: 2016 e 2020 — vazios, sem DELETE observado na run
  auditada. Podem nunca ter sido ingeridos (receitas/despesas historicamente só
  cobriam 2022/2024 no pipeline TS) ou apagados em run anterior não auditada.

## Ação pendente (não bloqueia o PR B)

Consultar backup/PITR do Supabase para 2014/2016/2018/2020 e determinar se
existiu dado antes — só então classificar como "perda confirmada" ou
"nunca carregado". Até lá, não afirmar perda.
