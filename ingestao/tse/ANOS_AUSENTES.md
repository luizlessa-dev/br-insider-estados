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

### Tentativa de verificação (2026-08-23)

Não há ferramenta MCP do Supabase para listar retenção de backup/PITR, e o
dashboard exige login que este agente não faz (fora do escopo de ação
autônoma). Org `qsbrxkxtcizkievgtira` está no plano **pro**.

Raciocínio circunstancial, independente da configuração exata: o DELETE
comprovado (2014/2018) ocorreu em **2026-06-20**; esta verificação foi feita em
**2026-08-23** — **64 dias depois**. Nenhum tier padrão de PITR do Supabase
(7/14/28 dias, add-on pago no plano pro) cobre uma janela de 64 dias. Ou seja,
mesmo que PITR estivesse ativo no momento do incidente, é muito provável que
a janela de retenção **já não alcance mais** 2026-06-20 — a menos que exista
configuração não padrão (Enterprise/retenção customizada).

**Pendência real**: precisa de confirmação humana em Dashboard → Database →
Backups → Point in time (janela de retenção atual e se cobria 20/jun quando o
incidente ocorreu). Até essa confirmação, a classificação da tabela acima
("perda não provada") permanece a mais honesta — não upgradar para "perda
confirmada" nem para "descartado" sem essa evidência.

### Confirmação humana (2026-08-24)

Luiz conferiu Dashboard → Database → Backups → Point in time em
`redggdtakzmsabwvjzhb`: a janela de retenção **não cobre** 20/06/2026, como o
raciocínio circunstancial já indicava.

**Isso NÃO promove 2014/2018 para "perda confirmada"** — a ausência de PITR
prova que a pergunta "havia dado antes do DELETE?" é **inverificável
permanentemente**, não que havia dado. A classificação correta agora é:

| Ano | Status final |
|---|---|
| 2014 | DELETE comprovado (20/jun) + existência anterior **inverificável para sempre** (sem backup na janela). Trata-se como "carga nova" ao reingerir — não há como saber se está reparando uma perda ou populando pela primeira vez. |
| 2018 | Idem 2014. |
| 2016 | Causa desconhecida, sem DELETE comprovado, também sem como verificar existência anterior — mesma situação prática de 2014/2018 para efeito de decisão. |
| 2020 | Idem 2016. |

**Implicação prática**: para efeito de decidir COMO reingerir, os 4 anos são
equivalentes — tratam-se como carga nova via pipeline seguro (staging + swap),
não como "restauração". Isso não muda a ordem de risco entre eles (2016/2018
seguem legados/bloqueados por outros motivos — ver runner.py `ANOS_LEGADOS`;
2020 continua o candidato mais seguro pro primeiro teste real).
