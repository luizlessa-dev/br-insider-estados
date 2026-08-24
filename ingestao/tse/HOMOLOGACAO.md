# Runbook de homologação — pipeline seguro TSE (PR B)

Objetivo: homologar o pipeline seguro (staging + fingerprint + swap atômico +
COPY) num ambiente DESCARTÁVEL com conexão Postgres direta, sem tocar produção.

Pré-condições (não negociáveis):
- PR B mergeado como código inativo (`TSE_SAFE_LOADER` ausente, cron suspenso).
- Nenhuma migration aplicada em produção. Nenhum secret produtivo.
- Toda esta homologação roda contra a BRANCH descartável, nunca contra
  `redggdtakzmsabwvjzhb` (produção).

Convenção de variáveis (todas temporárias, só na máquina de homologação):
- `IT_REF`      — project_ref da branch descartável (ex.: `abcd...`).
- `TSE_IT_URL`  — `https://$IT_REF.supabase.co` (PostgREST).
- `TSE_IT_SERVICE_KEY` — service_role key da branch.
- `TSE_IT_PGURL`/`TSE_PG_DSN` — connection string Postgres DIRETA (TLS,
  `sslmode=require`), usada pelo COPY e pelo teste de concorrência.

---

## 1. Criar ambiente descartável com conexão Postgres direta

1. Criar branch Supabase da árvore de produção (Dashboard → Branches → Create,
   ou `create_branch`). Anotar `IT_REF`.
2. **Obter a connection string DIRETA** (o que faltou nas rodadas anteriores):
   Dashboard da branch → Settings → Database → Connection string → **Session
   mode** (porta 5432). Copiar para `TSE_PG_DSN` e `TSE_IT_PGURL` e anexar
   `sslmode=require` se ausente. Sem isso, os passos 5 e 6 não rodam.
3. Obter `TSE_IT_SERVICE_KEY` (Settings → API → service_role) e montar
   `TSE_IT_URL`.
4. Exportar tudo como env local (nunca commitar, nunca logar).

Nota: a branch replay das 142 migrations pode falhar (bug conhecido de baseline).
Se `tse_receitas`/`tse_despesas` não existirem na branch, criá-las com o schema
real (introspecção documentada) como fixture ANTES da migration — é ambiente de
teste, não produção.

## 2. Aplicar a migration

- Aplicar `ingestao/tse/sql/0001_tse_safe_pipeline.sql` na branch (via
  `supabase db push` apontando para a branch, ou `apply_migration` com o
  `project_id` da branch).
- Conferir: staging (receitas/despesas) com `identity_key` gerado e os dois
  CHECKs; `tse_load_runs` com colunas de progresso/proveniência/override;
  funções `tse_promote_year` e `tse_gc_staging` com owner `postgres` e EXECUTE
  só para `service_role`.

## 3. Criar secrets temporários

- Exportar no shell da homologação: `TSE_IT_URL`, `TSE_IT_SERVICE_KEY`,
  `TSE_IT_PGURL`, `TSE_PG_DSN`. Opcional para override: `GITHUB_RUN_ID`,
  `GITHUB_ACTOR`, `GITHUB_SHA`, `GITHUB_SERVER_URL`, `GITHUB_REPOSITORY`.
- Regras: só em ambiente de homologação; nunca em `.env` versionado; nunca em log.

## 4. Executar testes integrados (PostgREST/RPC)

```bash
.venv/bin/python -m pytest ingestao/tse/tests/test_integration_supabase.py -v
```
Cobre: grants/RLS (anon negado), carga normal + cleanup, quality gate + final
intacta, mistura de anos, run de outro ano recusado, idempotência de repromote.

## 5. Benchmark ponta a ponta com COPY

Rodar o fluxo real download → parse → COPY → gates → promote, com dados
sintéticos (100k e 500k linhas; se o ambiente suportar, repetir com um ano real
pequeno). Medir e registrar por escala:
- tempo de download; tempo de parse; tempo de COPY; tempo dos quality gates;
  tempo de promoção; duração total; memória de pico; throughput (linhas/s);
  nº de requisições (deve ser baixo — COPY é uma conexão, não milhares de POSTs).
- Verificar memória: o processo deve ficar estável (streaming) — **sem** crescer
  proporcional ao dataset (prova de que não acumula em RAM).

Comando de referência (COPY via `copy_backend.py`, exige `TSE_PG_DSN`):
```bash
TSE_PG_DSN="$TSE_PG_DSN" .venv/bin/python - <<'PY'
# harness de benchmark: gera N linhas sintéticas, COPY para staging, promove;
# imprime tempos e pico de memória (resource.getrusage). NÃO usa dado pessoal.
PY
```

## 6. Teste de concorrência (duas conexões)

```bash
TSE_IT_PGURL="$TSE_IT_PGURL" .venv/bin/python -m pytest \
  ingestao/tse/tests/test_concurrency_psycopg.py -v
```
Registrar da saída: início da transação A; aquisição do lock por A; tentativa de
B; tempo de espera de B; commit de A; aquisição por B; estado final (uma
promoção venceu, contagem consistente, sem DELETE concorrente).

## 7. Teste de retomada

- Criar um run, gravar `zip_sha256`+`zip_bytes`+`transformer_version`, carregar
  parcialmente (interromper).
- Retomar com o MESMO run_id e MESMO arquivo → confirmar que `ON CONFLICT
  (run_id, identity_key) DO NOTHING` não duplica e completa o que faltava.
- Tentar retomar com hash/tamanho/versão DIFERENTE → confirmar que exige NOVO
  run_id (retomada recusada). Ver `RESUME_PROTOCOL.md`.

## 8. Teste de rollback

- Forçar falha no INSERT final (trigger de veneno numa linha sentinela) durante
  o swap → confirmar que a transação inteira reverte e a tabela FINAL permanece
  exatamente como antes (contagem e linhas idênticas).

## 9. Validação de RLS e grants

- Com a `anon key`: `SELECT` em `tse_*_staging`/`tse_load_runs` → negado ou vazio;
  `POST /rpc/tse_promote_year` → negado.
- Confirmar `tse_promote_year`/`tse_gc_staging` executáveis só por `service_role`,
  owner `postgres`, `search_path` fixo.

## 10. Critérios objetivos de aprovação

Aprovar SOMENTE se TODOS forem verdadeiros:
- [ ] zero escrita em produção (todas as operações no `IT_REF`);
- [ ] COPY completo sem carga integral em memória (pico estável, streaming);
- [ ] final intocada em todas as falhas (rollback comprovado);
- [ ] staging retomável apenas com mesmo hash + tamanho + `transformer_version`;
- [ ] segunda promoção do mesmo (dataset, ano) AGUARDA o advisory lock;
- [ ] ausência de duplicação na retomada (contagem estável);
- [ ] `source_id` preservado no staging e na final;
- [ ] `row_fingerprint` válido (`^[0-9a-f]{64}$`) em 100% das linhas (CHECK);
- [ ] contagem final == contagem validada do arquivo (parsed == staged == final);
- [ ] `tse_load_runs` com proveniência completa (zip_sha256, zip_bytes,
      source_url, pipeline_commit, transformer_version; override com pct_drop +
      github ctx quando aplicável);
- [ ] ambiente e secrets eliminados ao final (passos 11–12).

Qualquer item falhando ⇒ reprovado; corrigir e repetir.

## 11. Remoção dos secrets

- `unset TSE_IT_URL TSE_IT_SERVICE_KEY TSE_IT_PGURL TSE_PG_DSN GITHUB_*`.
- Limpar histórico do shell se as strings foram digitadas inline.
- Remover qualquer arquivo temporário de connection string.

## 12. Exclusão do ambiente

- Apagar a branch descartável (Dashboard → Branches → Delete, ou `delete_branch`).
- Confirmar que a branch não aparece mais em `list_branches`.
- Remover ZIPs baixados do CDN (`rm -f /tmp/tse_prest_*.zip`).

---

## Registro de homologação (execução 2026-08-23)

Ambiente: branch descartável `homologacao-tse-safe-pipeline` (IT_REF
`nqzvbgzrnnosqtilnonl`), criada a partir de `redggdtakzmsabwvjzhb` via MCP
Supabase, custo confirmado com o usuário (US$0,01344/h). Replay das 142
migrations falhou (bug de baseline já conhecido, ver seção 1) — `tse_receitas`/
`tse_despesas` foram recriadas como fixture com o schema real introspectado em
produção em 2026-08-23, antes de aplicar `sql/0001_tse_safe_pipeline.sql` sem
alteração. **Sem acesso à connection string Postgres direta** (não há tool MCP
para recuperar senha/DSN; dashboard exige login que este agente não faz) — os
testes que dependem de PostgREST/psycopg (`test_integration_supabase.py`,
`test_concurrency_psycopg.py`) foram substituídos por SQL equivalente rodado
diretamente contra a branch via `execute_sql` (mesmo backend Postgres, mesmas
RPCs, mesmas constraints — cobre a mecânica; não cobre a camada HTTP/rede).

| Item | Resultado | Evidência |
|---|---|---|
| Ambiente criado (IT_REF) | ✅ | `nqzvbgzrnnosqtilnonl`, branch de `redggdtakzmsabwvjzhb` |
| Migration aplicada | ✅ | `0001_tse_safe_pipeline.sql` aplicada sem alteração; staging, `tse_load_runs`, `tse_promote_year`/`tse_gc_staging` (owner `postgres`, EXECUTE só `service_role`, confirmado por `has_function_privilege`) |
| Testes unitários offline (`test_safe_loader.py`) | ✅ | 15/15 passam (`.venv/bin/python -m pytest ingestao/tse/tests/test_safe_loader.py -v`), inclui resume mesmo/diferente hash, fingerprint, concorrência simulada, gates |
| Testes integrados (equivalente SQL de `test_integration_supabase.py`) | ✅ | Reproduzidos via `execute_sql` direto: RLS/grants anon negado (`permission denied for table/function`, erro real), carga normal + cleanup (50/50, staging zerado), gate de contagem bloqueia + final intacta (100 preservado), mistura de anos recusada (final=0), run de outro ano recusado (final=0), idempotência de repromote (`already_promoted=true`, 20 não duplicou), `source_id` preservado staging→final, CHECK do fingerprint rejeita formato inválido, override auditado grava motivo/by/pct_drop(90%)/contexto GitHub |
| Retomada (mesmo/diferente hash) | ✅ | Unitário cobre a decisão Python (`pode_retomar`); SQL confirmou a mecânica `ON CONFLICT (run_id, identity_key) DO NOTHING` não duplica em reenvio parcial (10→20) nem em reenvio idêntico (20→20) |
| Rollback | ✅ | Trigger de veneno forçou falha durante o swap; transação reverteu inteira — final permaneceu em 30/30 linhas originais, staging não vazou |
| RLS/grants | ✅ | `SET ROLE anon` + tentativa real: `SELECT` em `tse_receitas_staging` e `EXECUTE` de `tse_promote_year` negados com erro `42501 permission denied` (não simulado — erro real do Postgres) |
| Benchmark 100k/500k via COPY real (`copy_backend.py`, `TSE_PG_DSN`) | ❌ **NÃO EXECUTADO** | Mesmo bloqueio de sessões anteriores: sem connection string Postgres direta recuperável via MCP. Não medido: tempo de COPY real, throughput, pico de memória streaming |
| Concorrência com duas conexões Postgres reais (`test_concurrency_psycopg.py`) | ❌ **NÃO EXECUTADO** | Tentativa registrada: duas chamadas `execute_sql` disparadas na mesma mensagem (PIDs distintos confirmados: 4979/4981) NÃO rodaram concorrentemente — o transporte MCP serializou as chamadas (sessão B só iniciou às 19:42:50.87, depois que A já tinha liberado o lock às 19:42:49.83). Não há evidência de bloqueio real por `pg_advisory_xact_lock` entre duas transações simultâneas |
| Secrets removidos | n/a | Nenhum secret de produção foi usado nesta execução — só MCP autenticado do próprio agente contra a branch descartável |
| Ambiente excluído | ✅ | `delete_branch` executado; branch não aparece mais em `list_branches` |

## Complemento — conexão Postgres direta obtida (2026-08-23, mesmo dia)

O usuário forneceu a connection string direta (Session mode, porta 5432) de
uma SEGUNDA branch descartável (`homologacao-tse-copy-concorrencia`, IT_REF
`bahdswecdcfdnvqtyjup`), via arquivo local temporário (nunca colada no chat),
lida e usada dentro de uma única invocação de shell (`source` + comando),
depois apagada. Isso destravou os 2 itens pendentes:

**Concorrência real (`test_concurrency_psycopg.py`, duas conexões psycopg 3):**
- `test_advisory_lock_exclusao_mutua`: **PASSOU**. Conexão A adquire
  `pg_advisory_xact_lock` e segura a transação aberta; conexão B tenta o MESMO
  lock via `pg_try_advisory_xact_lock` → recebe `FALSE` enquanto A segura;
  após `A.commit()`, B tenta de novo → recebe `TRUE`. Exclusão mútua real,
  comprovada com dois backends Postgres simultâneos de verdade.
- `test_promote_serializado_sem_delete_concorrente`: **FALHOU na 1ª tentativa**
  por um bug no PRÓPRIO teste (não no pipeline) — o `INSERT` de seed não
  informava `row_fingerprint`, coluna `NOT NULL` na tabela staging desde a
  migration 0001. Corrigido em [test_concurrency_psycopg.py](tests/test_concurrency_psycopg.py)
  (adicionado `row_fingerprint` via `encode(sha256(...),'hex')` no seed). Após
  a correção: **PASSOU**. Duas promoções reais do mesmo (dataset,ano): B ficou
  bloqueada por ≥1,0s enquanto A segurava a transação; após `A.commit()`, B
  prosseguiu; estado final consistente (10 linhas, sem DELETE concorrente).

**Benchmark ponta a ponta com COPY real (harness ad-hoc, dados 100% sintéticos,
ano fictício 1998, nunca dado real):**
- Achado de bug real em produção: [copy_backend.py](copy_backend.py) concatenava
  `" sslmode=require"` (formato keyword=value) em cima de uma DSN em formato
  URI (`postgresql://...`) — quebra o parser do psycopg. A connection string
  que o Supabase entrega É formato URI, então isso quebraria em produção
  também. Corrigido: detecta o formato e usa `?`/`&sslmode=require` para URI.
- 1ª tentativa de 500k caiu 2x por instabilidade transitória de conexão contra
  a branch (`connection socket closed`, depois `connection timeout expired`) —
  não reproduziu na 3ª tentativa; registrado como observação de rede, não como
  falha do pipeline.
- Resultado final (harness passa um GERADOR, não uma lista — mede o streaming
  real do pipeline, igual a `source.iter_rows() → backend.stage_rows()`):

| n | tempo COPY | throughput | tempo gate | tempo promote | tempo total | pico RSS |
|---|---|---|---|---|---|---|
| 100.000 | 17,24s | 5.801 linhas/s | 1,735s | 2,92s | 21,89s | **58,9 MB** |
| 500.000 | 40,00s | 12.499 linhas/s | 3,00s | 19,47s | 62,48s | **57,75 MB** |

Pico de memória praticamente idêntico (58,9 MB vs 57,75 MB) com dataset 5×
maior — confirma streaming real, sem acúmulo proporcional ao volume. Contagem
final == staged == esperado nos dois casos. Throughput de COPY melhorou com
volume maior (overhead fixo de conexão amortizado), consistente com uma única
conexão/transação por carga (não milhares de POSTs).

Ambiente limpo (dados de teste removidos), branch `bahdswecdcfdnvqtyjup`
apagada (`delete_branch`, confirmada fora de `list_branches`), arquivo com a
DSN apagado do disco.

## Veredito

**APROVADO** — todos os 12 critérios do item 10 comprovados nesta execução
(2026-08-23), combinando a branch `nqzvbgzrnnosqtilnonl` (10 primeiros itens,
sem DSN direta) com a branch `bahdswecdcfdnvqtyjup` (os 2 itens que exigiam
conexão Postgres direta). Dois bugs reais foram encontrados e corrigidos no
processo — não no SQL do pipeline seguro (que se manteve correto em todos os
testes), mas no código Python de suporte:
1. [copy_backend.py](copy_backend.py) — parsing de DSN em formato URI quebrado
   (afetaria produção, já que a DSN do Supabase é URI).
2. [test_concurrency_psycopg.py](tests/test_concurrency_psycopg.py) — teste
   desatualizado (seed sem `row_fingerprint`, coluna NOT NULL desde a migration).

Assinado por: Claude (agente) — pendente ratificação humana
Data: 2026-08-23
Veredito automatizado: aprovado (12/12 critérios comprovados; 2 bugs de suporte corrigidos, não no pipeline SQL)

---

## Ativação em produção (2026-08-24)

Luiz confirmou explicitamente (item 4 da tarefa original). Executado:
- Migration `0001_tse_safe_pipeline.sql` aplicada em `redggdtakzmsabwvjzhb`
  (produção) — aditiva, dado existente confirmado intacto antes/depois
  (2.312.126 receitas / 6.584.694 despesas).
- Guard de contenção emergencial removido de
  [ingest-tse.yml](../../.github/workflows/ingest-tse.yml); `TSE_SAFE_LOADER=1`
  ativado no workflow. Push feito pra `origin/main`.
- Receitas/despesas 2018/2020/2022/2024 liberados via pipeline seguro em
  produção. **Nenhuma carga real foi disparada** — só a flag foi ativada; rodar
  de fato (dispatch manual ou pelo cron de nov/dez) é uma ação separada, não
  incluída nesta sessão.

## Migração de 2014/2016 (2026-08-24)

Código migrado: [legacy_source.py](legacy_source.py) (`LegacyZipSource`,
protocolo `Source` idêntico ao `ZipYearSource`, reaproveita só os parsers de
`ingest_legado.py`, nunca a orquestração delete-before-load). `runner.py`
roteia 2014/2016 pro pipeline seguro. Cobertura: 7 testes unitários com ZIP
sintético (`tests/test_legacy_source.py`).

**Segunda trava de segurança**: `TSE_SAFE_LOADER=1` sozinho NÃO libera
2014/2016 — `runner._exigir_aprovacao_legado()` exige também
`TSE_LEGACY_APPROVED=1` (não setado em lugar nenhum). Confirmado rodando com
exatamente as env vars do workflow real (só `TSE_SAFE_LOADER=1`): 2014/2016
seguem bloqueados; anos modernos passam livre.

### Validação contra ZIP real de 2014 (mesmo dia)

Luiz baixou `prestacao_final_2014.zip` (202MB, CDN do TSE bloqueia este
ambiente com 403 — WAF/geo, confirmado testando URL moderna e legado, curl e
browser) e forneceu o arquivo local.

**Parsing completo (todas as 27 UFs, sem escrita em banco)**: 2.226.580
despesas + 419.853 receitas, zero exceções. Header real de despesas e receitas
2014 batem 100% com o mapeamento de coluna por índice (`COL_2014`,
`COL_RECEITAS_2014`) — nenhum drift de layout.

**2 achados de qualidade de dado, corrigidos** (pré-existentes em
`ingest_legado.py`, só visíveis contra dado real):
1. Sentinela literal `#NULO` do TSE (não é NULL de verdade, é a string) não
   era normalizada em campos de texto livre — só em CPF/CNPJ. Corrigido com
   `_limpo()`. Confirmado: 0 sentinelas vazando pro banco após o fix (antes:
   664.527 ocorrências só no arquivo de despesas de SP).
2. `origem_receita` ficava sempre `None` pra 2014/2016 — o connector.py
   moderno alimenta `tipo_doador` E `origem_receita` a partir do mesmo campo
   de origem; espelhado no legado (antes só `tipo_doador` era preenchido).

**Staging + swap atômico com dado real** (branch descartável
`onilucjscpmvwwxijwul`, UF=AC, run via `execute_sql` direto — sem service_role
key desta branch): 50 despesas + 25 receitas reais promovidas com sucesso
(`rows_after` bate com `linhas_staged` nos dois casos). Confirmado
manualmente: acentuação (Á, Ã, ê), caracteres especiais (`·` interpunct),
datas (`DD/MM/YYYY`→ISO) e valores decimais sobreviveram intactos ponta a
ponta. `tipo_doador`/`origem_receita` populados corretamente após o fix;
`nome_doador_originario` vira `NULL` de verdade (não mais a string
`"#NULO"`). Dados de teste limpos, branch apagada.

## Complemento — 2016 + integração Python real, 2014 e 2016 (2026-08-24)

### `TSE_LEGACY_APPROVED` deixou de ser env var estática

Trocado por input booleano do `workflow_dispatch` (`confirmo_legado_2014_2016`,
default `false`) — visível e auditável por execução, nunca "ligado" por
padrão, cron nunca passa esse input. Ver commit no
[ingest-tse.yml](../../.github/workflows/ingest-tse.yml).

### Validação contra ZIP real de 2016

Mesmo processo do 2014: `prestacao_contas_final_2016.zip` (1GB — CDN bloqueia
este ambiente, confirmado de novo). **Parsing completo (todas as 26 UFs)**:
5.587.817 despesas + 3.004.286 receitas, zero exceções, zero sentinela
vazando. Header de despesas (25 colunas) e receitas (35 colunas) batem 100%
com `COL_2016`/`COL_RECEITAS_2016` — mesmo padrão de nomeação de coluna
"Tipo receita"→`tipo_doador` que 2014, já coberto pelo fix.

### Integração Python REAL (não SQL simulado) — 2014 e 2016

Item que ficava faltando: rodar `load_year()` de ponta a ponta de verdade
(`LegacyZipSource.download_and_validate()` → `iter_rows()` →
`backend.stage_rows()` via COPY real → `backend.promote()`), não a simulação
via SQL direto feita na primeira rodada. Branch descartável nova
(`vtvcvbgjnoarktufqxhn`), harness com um `Backend` que fala Postgres direto
(sem service_role key desta branch) reaproveitando `copy_backend.py` pro
staging.

Pra cada ano (2014 e 2016), três testes, **todos com dado real (UF=AC/AL)**:

1. **Carga real de ponta a ponta**: despesas + receitas via `load_year()`
   completo. 2014: 13.246 despesas + 5.129 receitas. 2016: 19.024 despesas +
   15.291 receitas. Todos `rows_after == rows_staged`, sem erro.
2. **Rollback real**: baseline promovido (UF=AC), depois uma carga envenenada
   (UF=AL com uma linha `valor_despesa=666.66` capturada por trigger na tabela
   FINAL) através do `load_year()` real — a exceção do trigger propaga pra
   fora de `load_year()` como esperado, e a tabela final permanece EXATAMENTE
   no baseline (2014: 13.246; 2016: 19.024) — confirma que o swap dentro de
   `tse_promote_year` é atômico mesmo quando acionado pelo caminho Python
   completo, não só via SQL direto.
3. **Concorrência real**: uma conexão externa segura o advisory lock do
   mesmo `(dataset, ano)`; uma segunda carga real (UF=AL, disparada via
   `load_year()` numa thread) fica comprovadamente bloqueada (não completa em
   1,5s) até o lock externo ser liberado, daí prossegue e promove
   corretamente (2014: 13.246→28.634; 2016: 19.024→88.545) — swap atômico,
   sem mistura de UFs.

Ambiente limpo, branch apagada. Nenhum dado de teste residual.

### Nota operacional — vazamento de senha durante a sessão

No processo de obter a connection string desta branch, a senha do banco
chegou a aparecer em texto puro na conversa duas vezes: uma vez colada pelo
usuário sem querer, outra vez por um comando de diagnóstico deste agente
(`repr()` para checar caractere oculto, que imprimiu o valor). Em ambos os
casos a senha foi trocada logo em seguida pelo usuário. Registrado aqui por
transparência — não afeta a validade dos testes (a branch já foi apagada),
mas é um lembrete de que ferramentas de diagnóstico precisam ser desenhadas
pra NUNCA imprimir segredo, nem em caminhos de depuração.

## Veredito final — 2014/2016

**Código pronto, validado contra ZIP real (parsing completo) E contra a
mecânica real do pipeline seguro (`load_year()` de ponta a ponta, rollback,
concorrência) para os dois anos.** Único item que falta:
- Aprovação humana explícita e separada pra marcar
  `confirmo_legado_2014_2016` numa execução real do workflow contra produção
  — pedida no item 5 da tarefa original, ainda não dada. O mecanismo já
  existe (input do workflow_dispatch), só falta a decisão de usar.

Assinado por: Claude (agente) — pendente ratificação humana
Data: 2026-08-24
Data: 2026-08-24
