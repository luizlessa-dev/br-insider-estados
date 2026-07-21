# PROVA 1C — Revalidação Contemporânea do Baseline (2026-07-21)

> **Distinção em relação à evidência histórica**: este documento é uma
> **revalidação contemporânea**, produzida em 2026-07-21, do pacote de
> baseline preservado no commit `f1a308f9`. Ele **não substitui** nem altera
> `PROVA1C_PORTABILIDADE_E_DRIFT.md` (evidência histórica da PROVA 1C
> original). Os dois documentos coexistem: aquele registra o estado no
> momento da criação do baseline; este registra sua reexecução, meses
> depois, num ambiente local independente, com uma correção pontual de
> whitespace tratada como artefato derivado. Esta revalidação **não é a
> PROVA 2** — é uma reexecução de gates já definidos, não uma nova rodada de
> critérios.

## 1. Identificação

- **Data/hora da revalidação**: 2026-07-21 (horário local America/Sao_Paulo).
- **Commit canônico de entrada**: `f1a308f9da37b926da9ee6bbb38138fb492bc72a`
  ("chore(db): preserve audited baseline patch before revalidation").
- **Parent**: `844741bebb085c658c8a16bdcb1376bd1590f697`.
- **Branch de preservação**: `prova/baseline-local-20260718-c` (aponta
  exatamente para o commit acima — confirmado por `git rev-parse`).
- **Branch de trabalho desta revalidação**: `prova/baseline-local-20260718-revalidacao`.
- **Estado com correção de whitespace**: aplicado no working tree desta
  branch, sobre o commit canônico, e consolidado no commit local descrito na
  Seção 14 deste mesmo documento (código do commit só é conhecido após ele
  ser criado — ver `git log -1` na branch de revalidação para o SHA final).

## 2. Ambiente

| Item | Versão/estado |
|---|---|
| SO | macOS 26.4.1 (build 25E253), Darwin 25.4.0, arm64 |
| Git | 2.50.1 (Apple Git-155) |
| Supabase CLI | 2.109.0 |
| Docker | 29.6.1 (build 8900f1d) |
| Docker daemon | responsivo (iniciado nesta sessão via `open -a Docker`) |

## 3. Worktree estável

- **Caminho absoluto**: `/Users/luizlessa/br-insider-worktrees/prova1c-revalidacao`
  (fora de `/tmp`, `/private/tmp` e de qualquer diretório `scratchpad`).
- Criado com `git worktree add -b prova/baseline-local-20260718-revalidacao
  <caminho> f1a308f9da37b926da9ee6bbb38138fb492bc72a`.
- HEAD original = `f1a308f9da37b926da9ee6bbb38138fb492bc72a`; parent =
  `844741bebb085c658c8a16bdcb1376bd1590f697`.
- Sem upstream configurado (`git rev-parse @{u}` retorna erro esperado).
- Checkout principal (`/Users/luizlessa/brasilia-insider`, branch
  `pr-b-tse-safe-pipeline`, com trabalho não relacionado em andamento) não
  foi tocado em nenhum momento.
- Um worktree órfão pré-existente em `/private/tmp/.../scratchpad/wt-prova1c`
  (marcado `prunable`, diretório já inexistente) foi limpo via
  `git worktree prune` antes da criação do worktree estável — nenhum dado
  foi perdido, pois o diretório já não existia.

## 4. Preflight ambiental

- Disco no início: `/System/Volumes/Data` com **11 GiB livres** (acima do
  piso de 8 GiB exigido, mas com margem apertada).
- Disco ao final: **7,6 GiB livres**. A queda (~3,4 GiB) **não é atribuível a
  esta prova**: o `docker system df` mostra o mesmo total de imagens
  (8,653 GB) e um total de volumes praticamente idêntico (123,8 MB ao final
  vs 125 MB no início) ao comparar início e fim — nenhum volume/imagem novo
  ficou retido. A variação reflete atividade do sistema operacional alheia a
  este processo (não identificada em detalhe; ver Seção 15 — Limitações).
- Inodes: sem risco (uso <5%).
- Supabase CLI 2.109.0, Docker 29.6.1, daemon respondendo.
- Containers/volumes/network pré-existentes no início, todos com sufixo
  `gastronomizae` — **classificados como protegidos** e nunca parados,
  reiniciados, removidos ou alterados:
  - Containers: `supabase_db_gastronomizae`, `supabase_studio_gastronomizae`,
    `supabase_pg_meta_gastronomizae`, `supabase_edge_runtime_gastronomizae`
    (já estava `Exited` desde antes desta prova), `supabase_storage_gastronomizae`,
    `supabase_rest_gastronomizae`, `supabase_realtime_gastronomizae`,
    `supabase_inbucket_gastronomizae`, `supabase_auth_gastronomizae`,
    `supabase_kong_gastronomizae`, `supabase_vector_gastronomizae`,
    `supabase_analytics_gastronomizae`.
  - Volumes: `supabase_db_gastronomizae`, `supabase_edge_runtime_gastronomizae`,
    `supabase_storage_gastronomizae`.
  - Network: `supabase_network_gastronomizae`.
  - Portas ocupadas por essa stack permanente: 54321 (API), 54322 (DB), 54323
    (Studio), 54324 (Inbucket), 54327 (Analytics) — por isso a stack
    temporária desta prova usou uma faixa totalmente distinta (58xxx).
- Ao final da prova, os mesmos 12 containers, 3 volumes e 1 network
  `gastronomizae` seguem presentes e intactos (confirmado por nova consulta
  Docker).

## 5. Auditoria do commit de entrada

Confirmada a presença dos 11 arquivos do pacote preservado:
`db/baseline/blocks/17_hardening.sql`, `db/baseline/MANIFEST_BLOCOS.md`,
`db/baseline/digests_esperados.txt`, `db/baseline/tools/30_montar.sh`,
`db/baseline/tools/40_digest_estrutural.sql`,
`db/baseline/tools/50_baseline_verify.sh`,
`db/baseline/tools/60_drift_check.sh`,
`db/baseline/evidence/PROVA1C_PORTABILIDADE_E_DRIFT.md`,
`supabase/config.toml`, `supabase/.gitignore`,
`supabase/migrations/20260718000000_baseline.sql`.

SHA-256 (completo) de cada arquivo, no estado do commit `f1a308f9` (antes da
correção de whitespace descrita na Seção 6):

```
b6392349ceb94b1bb2c051144f440c9f52276912e842bc869af2b82554c2d39f  db/baseline/blocks/17_hardening.sql
2676779934a36cac0d2280a98803ad29dad7c51bfd4b73118f67cc33f3ecf44c  db/baseline/MANIFEST_BLOCOS.md
7813c85cfd7fc1898a6e094bbe3c1fa2241c4e3631e7df1c8dd2549c53ff87b5  db/baseline/digests_esperados.txt
5e3352129f7ff766f447a790353c6e119b455aaca71e4d757fdeb9387cc28b27  db/baseline/tools/30_montar.sh
952fd7e22760cd7924a591e614a8b2ca208d85a81743e0c448947918e2adb2ae  db/baseline/tools/40_digest_estrutural.sql
9ea62f540e81401b3884999835f57c4399a3c89ae7461237969b386ecee08efc  db/baseline/tools/50_baseline_verify.sh
5822066098dcd234e933a5c8903b661de51f3de20b0e3ab23b0ec7be11762edb  db/baseline/tools/60_drift_check.sh
9e1b736aa8dd9b9d55d595141cd6d90de00ef11b383f8ebfa2c7c379331f6ed4  db/baseline/evidence/PROVA1C_PORTABILIDADE_E_DRIFT.md
dffc63c6fe33ba069601833cc66523cfb8a9b3301fdf6a9403d8dd95166b7ffe  supabase/config.toml
507699eb91144818edf61d3a079212cacf31d8db520eae428e3b48fcf0d6919c  supabase/.gitignore
54961dba4faab2ffd97edc7981b3f3b7a46d8a25af0ae16653698f4b142218eb  supabase/migrations/20260718000000_baseline.sql
```

- `bash -n` sem erro em `30_montar.sh`, `50_baseline_verify.sh`,
  `60_drift_check.sh`.
- Drift-check positivo (pré-correção): migration versionada idêntica aos 17
  blocos (`54961dba4faab2ff…`).
- Busca por segredos/DSNs/refs remotas/`--linked`/`--db-url` restrita aos 11
  arquivos do pacote: **nenhuma ocorrência real**. A única linha capturada
  foi um comentário de documentação (`supabase/config.toml:2`, URL de docs
  oficial do Supabase). Uma busca ampla no restante do repositório (fora do
  pacote de 11 arquivos) encontrou apenas nomes de variáveis de ambiente
  (`SUPABASE_SERVICE_ROLE_KEY`) usadas via `os.environ.get(...)` em
  conectores de ingestão não relacionados ao baseline — nenhum valor de
  segredo hardcoded.

## 6. Trailing whitespace

- `git diff-tree --check --root f1a308f9...` apontou **uma única ocorrência**:
  `supabase/migrations/20260718000000_baseline.sql:8933` (espaço antes de
  quebra de linha).
- Origem localizada no bloco-fonte
  [`db/baseline/blocks/07_functions.sql:260`](../blocks/07_functions.sql),
  dentro do corpo `LANGUAGE "sql" AS $$ ... $$` da função
  `buscar_emendas_municipio`.
- Scan de todos os 17 blocos confirmou tratar-se de ocorrência única em todo
  o pacote.
- **Classificação**: correção segura, sem alteração de semântica — o espaço
  removido ficava entre dois tokens SQL já separados por quebra de linha
  (`'')))`  e `ILIKE`); qualquer parser SQL trata essa sequência de
  whitespace como equivalente com ou sem o espaço extra.
- **Ação tomada**:
  1. Corrigido o bloco-fonte (`07_functions.sql`, removida a trailing
     whitespace da linha 260).
  2. Migration remontada via `./tools/30_montar.sh blocks
     ../../supabase/migrations/20260718000000_baseline.sql`. Novo SHA-256
     completo: `604ad11b895d53230a70d6b1b98908b698aa937b2a50f91cb0e377649398e0b8`.
  3. `MANIFEST_BLOCOS.md` atualizado: checksum do bloco `07_functions`
     mudou de `ae25eab7695f0a0b` para `719eea5d42d4e1cd` (16 hex).
  4. Drift-check reexecutado: **OK** — migration idêntica aos blocos
     corrigidos (`604ad11b895d5323…`).
  5. **Efeito colateral esperado e verificado**: como a função usa
     `LANGUAGE "sql"` com corpo de string literal, `pg_get_functiondef()`
     ecoa o texto de `prosrc` verbatim — a correção de whitespace altera
     esse texto em 1 caractere e, portanto, altera o digest estrutural
     `functions`. Isso foi confirmado empiricamente (Seção 7): o digest
     `functions` mudou de `50854bb1abddb9f248e7f7cede44e878` (esperado
     anterior) para `72bc32efd43ea1e3821f77716cb9e70d` (real, pós-correção).
     `digests_esperados.txt` foi atualizado com o novo valor, como artefato
     derivado obrigatório da correção — os demais 10/11 digests **não**
     mudaram.
- Diff resultante (confirmado com `git diff`) é **exclusivamente** a
  correção de whitespace e seus três artefatos derivados obrigatórios:
  `db/baseline/blocks/07_functions.sql`,
  `supabase/migrations/20260718000000_baseline.sql`,
  `db/baseline/MANIFEST_BLOCOS.md`, `db/baseline/digests_esperados.txt`.
  Nenhum outro arquivo foi alterado.

## 7. Configuração temporária (stack isolada)

Duas instâncias temporárias e totalmente isoladas foram criadas, uma por
ciclo, como cópias fora do worktree (`/Users/luizlessa/br-insider-worktrees/
prova1c-stack-ciclo{1,2}/`), cada uma com `project_id` próprio, sem
`supabase link`, sem `.temp/` (nenhum vínculo remoto), com
`[db.migrations] enabled = true` e `[db.seed] enabled = false` herdados
inalterados do `config.toml` do pacote.

| Serviço | Porta permanente (`gastronomizae`, não usada) | Porta temporária da prova |
|---|---|---|
| API (Kong) | 54321 | **58321** |
| DB (Postgres) | 54322 | **58322** |
| Shadow DB | 54320 | **58320** |
| Studio | 54323 | **58323** |
| Inbucket/Mailpit | 54324 | **58324** |
| Analytics | 54327 | **58327** |
| Pooler (desabilitado) | 54329 | 58329 (não usado — `enabled = false`) |
| Edge runtime inspector | 8083 | 58083 |

`project_id` do Ciclo 1: `prova1c-revalidacao-ciclo1-tmp`.
`project_id` do Ciclo 2: `prova1c-revalidacao-ciclo2-tmp`.

Credenciais: apenas as **credenciais locais padrão/efêmeras** do Supabase
CLI (ANON_KEY, SERVICE_ROLE_KEY, JWT_SECRET de demonstração, idênticas em
qualquer instalação local do CLI) — nenhum segredo real foi usado ou
registrado.

## 8. Ciclo 1

- `supabase start`: sucesso, todas as imagens já em cache local (nenhum pull
  adicional). `supabase db reset`: **exit 0**.
- Seed permaneceu desativado (nenhuma menção a `seed.sql` no log; apenas
  `Seeding globals from roles.sql`, mecanismo interno do CLI para roles,
  não o `seed.sql` do projeto — que nem existe neste repositório).
- Migration materializada aplicada integralmente (sem erro no reset).
- **11/11 digests estruturais conferem** contra o `digests_esperados.txt`
  já corrigido (Seção 6).
- Privilégios proibidos de `anon`/`authenticated` em `tse_receitas` e
  `tse_despesas`: **todas `false`** para INSERT, UPDATE, DELETE, TRUNCATE,
  REFERENCES, TRIGGER e MAINTAIN (28/28 combinações verificadas).
- SELECT público preservado: `true` para `anon` e `authenticated` em ambas
  as tabelas.
- `service_role` e `postgres`: acesso completo confirmado (SELECT, INSERT,
  UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN — todas `true`).
- Owners: `postgres` em ambas as tabelas.
- RLS: `relrowsecurity = true`, `relforcerowsecurity = false` em ambas —
  consistente com o digest `rls_flags`, que bateu 1:1 com o esperado.
- Policies: 0 policies explícitas em `tse_receitas`/`tse_despesas` —
  consistente com o digest `policies`, que bateu 1:1 com o esperado.
- Zero linhas em `tse_receitas` e `tse_despesas`.
- Sequences `tse_receitas_id_seq` e `tse_despesas_id_seq`: sem `USAGE` nem
  `UPDATE` para `anon`/`authenticated`.
- Nenhum cron job relacionado a TSE (`cron.job` com 0 linhas no total —
  nenhum job de nenhuma espécie).
- `./tools/50_baseline_verify.sh`: **exit 0** (ambiente descartável próprio
  do script, hardening incluindo MAINTAIN confirmado, digests idênticos).

## 9. Ciclo 2

- Stack do Ciclo 1 destruída (`supabase stop --no-backup`) e confirmada sem
  resíduos (containers/volumes/networks pós-stop mostravam apenas recursos
  `gastronomizae`) antes de iniciar o Ciclo 2.
- Stack recriada do zero em diretório novo, `project_id`
  `prova1c-revalidacao-ciclo2-tmp`, mesma faixa de portas 58xxx (liberada
  após o teardown do Ciclo 1).
- `supabase start` + `supabase db reset`: **exit 0**.
- Todos os gates da Seção 8 foram repetidos **com resultado idêntico**:
  11/11 digests, 28/28 privilégios proibidos em `false`, SELECT público
  preservado, `service_role`/`postgres` com acesso completo, owners
  `postgres`, RLS/FORCE RLS idênticos, 0 policies, 0 linhas em ambas as
  tabelas, sequences restritas, 0 cron jobs.
- `./tools/60_drift_check.sh` e `./tools/50_baseline_verify.sh`:
  reexecutados, **exit 0** em ambos.

## 10. Determinismo

- Comparação byte a byte dos 11 digests estruturais do Ciclo 1 vs Ciclo 2:
  **idênticos** (`diff` vazio).
- Comparação de ambos os ciclos contra o oráculo `digests_esperados.txt`
  atualizado: **11/11 conferem em ambos os ciclos**.
- Todos os demais gates (privilégios, RLS, policies, owners, zero dados,
  cron) produziram saída textualmente idêntica em ambos os ciclos.
- Nenhuma diferença não explicada foi observada. **Determinismo confirmado.**

## 11. Testes negativos de drift-check

Executados em cópias temporárias (`/Users/luizlessa/br-insider-worktrees/
prova1c-drift-negtest/`, removida ao final), sem alterar nenhum arquivo
versionado:

| Teste | Cenário | Exit esperado | Exit observado |
|---|---|---|---|
| 1 | Migration idêntica aos blocos | 0 | **0** |
| 2 | Migration com 1 byte alterado (blocos intactos) | ≠0 | **1** |
| 3 | Bloco divergente (migration restaurada, 1 bloco com linha extra) | ≠0 | **1** |

Todas as cópias temporárias da Parte H foram removidas
(`rm -rf .../prova1c-drift-negtest`), confirmado por listagem do diretório
pai.

## 12. Limpeza final

- Stack do Ciclo 2 destruída (`supabase stop --no-backup`, exit 0).
- Diretórios `prova1c-stack-ciclo1/` e `prova1c-stack-ciclo2/` removidos.
- Estado final do Docker: **apenas os 12 containers, 3 volumes e 1 network
  `gastronomizae`** permanecem — idênticos em identidade e composição ao
  estado inicial (Seção 4). Nenhum recurso temporário desta prova
  permaneceu.
- Espaço em disco final: 7,6 GiB livres (ver observação na Seção 4 e
  limitação na Seção 15).
- Worktree estável (`prova1c-revalidacao/`) íntegro: `git status --short`
  mostra exatamente os 4 arquivos alterados pela correção de whitespace
  (Seção 6) — nenhum outro resíduo.

## 13. Verificador exit 0

`db/baseline/tools/50_baseline_verify.sh` executado com sucesso (exit 0) em
**três ocasiões**: uma vez no Ciclo 1, e duas vezes no Ciclo 2 (antes e
depois do teste de determinismo do drift-check), sempre com ambiente
descartável próprio criado pelo script via `mktemp`.

## 14. Limitações

- A variação de espaço em disco (11 GiB → 7,6 GiB) durante a sessão não foi
  atribuída a uma causa raiz específica; foi tecnicamente descartado o
  Docker (footprint de imagens e volumes praticamente inalterado) como
  causa, mas nenhuma outra investigação de sistema (Spotlight, snapshots,
  logs) foi realizada — está fora do escopo desta prova.
- Os testes negativos (Parte H) cobrem os 3 cenários pedidos, mas não
  esgotam todas as formas possíveis de drift (ex.: reordenação de blocos,
  múltiplos bytes alterados simultaneamente).
- Esta revalidação reexecuta os gates já definidos pela PROVA 1B/1C; não
  introduz novos critérios de aceitação nem constitui uma auditoria de
  segurança mais ampla do schema.

## 15. Ações não executadas (por desenho da missão)

Nenhum push, PR, merge, rebase, amend do commit canônico, tag, `supabase
link`, `supabase db push`, uso de `--linked`/`--db-url`/DSN remoto,
configuração de `TSE_PG_DSN`/`TSE_SAFE_LOADER`, execução de loader, cron ou
ingestão, `migration repair`, alteração de
`supabase_migrations.schema_migrations`, criação de projeto/branch Supabase
remoto, ativação de GitHub integration, alteração de produção, ou remoção
de recursos `gastronomizae`.

---

**A revalidação contemporânea da PROVA 1C não autoriza push, PR, PROVA 2,
migration repair, alteração do histórico remoto, aplicação do baseline,
criação de branch Supabase, GitHub integration ou qualquer ação em
produção.**
