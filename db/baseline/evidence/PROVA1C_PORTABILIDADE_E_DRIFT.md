# PROVA 1C — portabilidade e proteção contra drift

**Classificação: APROVADA LOCALMENTE**

Não commitado. Não aplicado remotamente. Nenhuma ação em produção.

## 1. Incidente ENOSPC

Durante a primeira tentativa da PARTE F (validação final), a ferramenta de
shell começou a falhar com `ENOSPC: no space left on device` — inclusive
para comandos triviais (`true`). Trabalho parado, sem limpeza cega, conforme
guardrail. Retomado em uma nova sessão de trabalho, começando por MISSÃO 1
(confirmação de shell disponível) antes de qualquer diagnóstico.

## 2. Causa confirmada

`df -h` mostrou `/System/Volumes/Data` (volume real de dados do macOS —
onde ficam `/Users`, `/private/tmp`, e a imagem de disco do Docker Desktop)
em **100% de capacidade, 266Mi livres**. Confirmado por `df -i` que era
limite de **bytes**, não de inodes (inodes só 54% usados). `docker ps -a`
e `docker system df -v` ficaram travados por minutos — o daemon do Docker
estava vivo (processos `com.docker.backend` presentes) mas não respondia,
consistente com inanição de I/O sob disco quase zero. `du -sh` no diretório
do Docker Desktop confirmou `Docker.raw` (imagem de disco virtual) em
**14GB**. Reiniciar o Docker Desktop (quit + reopen, **sem** "Purge data")
por si só liberou **7,7GB** (266Mi→8,0Gi livres) — espaço temporário/cache
do próprio daemon, descartado no restart.

## 3. Recursos protegidos (`gastronomizae`)

- **Containers (12):** `supabase_db_gastronomizae`, `supabase_studio_gastronomizae`,
  `supabase_pg_meta_gastronomizae`, `supabase_edge_runtime_gastronomizae`
  (parado há 6 dias, pré-existente — não é resíduo desta sessão),
  `supabase_storage_gastronomizae`, `supabase_rest_gastronomizae`,
  `supabase_realtime_gastronomizae`, `supabase_inbucket_gastronomizae`,
  `supabase_auth_gastronomizae`, `supabase_kong_gastronomizae`,
  `supabase_vector_gastronomizae`, `supabase_analytics_gastronomizae`.
- **Volumes (3):** `supabase_db_gastronomizae` (dados Postgres reais),
  `supabase_storage_gastronomizae`, `supabase_edge_runtime_gastronomizae`.
- **Network:** `supabase_network_gastronomizae`.
- **Imagens em uso ativo:** `postgres:17.6.1.141`, `studio:2026.06.29-sha-20290c7`,
  `postgres-meta:v0.96.6`, `edge-runtime:v1.74.2`, `storage-api:v1.65.1`,
  `postgrest:v14.5`, `realtime:v2.112.1`, `mailpit:v1.30.2`, `gotrue:v2.193.0`,
  `kong:2.8.1`, `vector:0.53.0-alpine`, `logflare:1.45.6`.

Confirmado intacto em **4 pontos distintos** da missão (antes da limpeza,
depois da remoção do órfão, depois da remoção de imagens, e ao final da
retomada da PARTE F) — mesmos 12 nomes, mesmos status, em todas as checagens.

## 4. Limpeza executada (cirúrgica, por nome/tag exato)

- Container órfão `supabase_db_br-insider-estados` (resíduo da tentativa
  interrompida de PARTE F anterior — `project_id` idêntico ao usado naquela
  tentativa) — removido.
- Volume órfão `supabase_db_br-insider-estados` (109,4MB) — removido.
- Network órfã `supabase_network_br-insider-estados` — removida.
- 5 imagens não usadas (0 containers, sem overlap com `gastronomizae`):
  `postgres:17.6.1.063` (3,05GB — mecanismo ad-hoc antigo, substituído pela
  correção da PROVA 1B), `storage-api:v1.61.7` (396,7MB), `postgrest:v14.14`
  (484,4MB), `gotrue:v2.192.0` (47,77MB), `imgproxy:v3.8.0` (162,3MB) —
  removidas por tag exata, uma a uma (nenhum `prune` amplo).

**Nenhum `docker system prune --volumes`, `docker volume prune`, "Purge
data" ou remoção com filtro impreciso foi usado.**

## 5. Espaço antes e depois

| Momento | Livre em `/System/Volumes/Data` |
|---|---|
| No incidente (ENOSPC) | 266Mi |
| Após restart do Docker Desktop (sem purge) | 8,0Gi |
| Após remoção do órfão | 7,0Gi (variação normal de uso concorrente do sistema) |
| Após remoção das 5 imagens | 12Gi |
| Ao final de toda a missão (pós-retomada da PARTE F) | 11Gi |

Parada deliberada ao atingir espaço suficiente — sem buscar limpeza máxima,
conforme instruído.

## 6. Recursos órfãos encontrados

Container, volume e network `*-br-insider-estados` (item 4) — único conjunto
de recursos órfãos identificado, com causa clara (tentativa de PARTE F
interrompida pelo ENOSPC antes da limpeza normal do `trap` do script poder
rodar).

## 7. Configuração portátil (`supabase/config.toml`)

Alterações em relação ao boilerplate de `supabase init`:

```diff
-project_id = "wt-prova1b"           (ou nome do worktree local, não-portátil)
+project_id = "br-insider-estados"

 [db.seed]
+# Desabilitado deliberadamente: "zero dados" é requisito validado (PROVA 1B).
-enabled = true
+enabled = false

 [experimental]
 orioledb_version = ""
-s3_host = "env(S3_HOST)"
-s3_region = "env(S3_REGION)"
-s3_access_key = "env(S3_ACCESS_KEY)"
-s3_secret_key = "env(S3_SECRET_KEY)"
+# bloco S3 removido — feature não exercitada por nada neste repositório
```

Portas mantidas no padrão do CLI (54321/54322/54320/54329/54323/54324/54327)
— **nenhuma porta deslocada no arquivo permanente**. Todo o restante do
boilerplate (auth, storage, realtime, edge_runtime, `experimental.pgdelta`)
mantido — necessário para `supabase start`/`db reset` funcionarem e
compatível com o `major_version = 17` já validado (imagem CLI `17.6.1.140`).

## 8. Ausência de segredos

`grep -ni "wt-prova1\|luizlessa\|/Users/\|redggdtakzmsabwvjzhb"` sobre o
arquivo final: **zero ocorrências**. Todos os campos sensíveis usam
indireção `env(VAR)` (padrão documentado da própria Supabase) — nenhum
valor literal de senha, token ou chave.

## 9. Drift-check implementado

`db/baseline/tools/60_drift_check.sh` (novo — `30_montar.sh` não precisou
ser alterado, já aceitava destino como argumento obrigatório). Monta em
arquivo temporário (`mktemp`), compara byte a byte via `cmp` contra
`supabase/migrations/20260718000000_baseline.sql`, exibe checksums de
ambos em caso de divergência, `exit 1` em drift, limpa o temporário via
`trap`. Zero rede, zero banco — só leitura de arquivos locais.

## 10. Testes já realizados nas PARTES D–E (não repetidos nesta retomada)

4/4: (1) arquivo idêntico → PASS; (2) cópia com 1 byte alterado → FAIL,
checksums exibidos; (3) blocos divergentes em cópia temporária (`/tmp`,
nunca o repositório real) → FAIL; (4) restauração confirmada — bloco real
sem a mutação de teste, nenhum artefato remanescente. Não repetidos nesta
retomada porque nenhum arquivo mudou de conteúdo desde então — reconfirmado
apenas o teste positivo (item 9) após a recriação do worktree.

## 11. Diretório temporário da validação final

`prova1c-partef-XXXXXX` (via `mktemp -d`), contendo **exclusivamente**
`supabase/config.toml` (cópia da versão portátil) e
`supabase/migrations/20260718000000_baseline.sql` — nada mais copiado.

## 12. Portas (validação final)

`project_id = "prova1c-validacao-temp"` (nome temporário inequívoco, não
usado em nenhuma tentativa anterior — evita repetir a colisão de nome que
gerou o órfão do item 4). Portas deslocadas **só nesta cópia temporária**
por offset +2000: 56321/56322/56329/56323/56324/56327 — confirmadas livres
antes do uso. O `config.toml` permanente nunca foi tocado para isso.

## 13. Reset

```
Resetting local database...
Recreating database...
Initialising schema...
Seeding globals from roles.sql...
Applying migration 20260718000000_baseline.sql...
Restarting containers...
Finished supabase db reset on branch main.
```
Sem `WARN` de seed (ausente pela primeira vez — confirma que `db.seed.enabled
= false` funciona). Zero `ERROR:` real.

## 14. 11/11 digests

`diff -u db/baseline/digests_esperados.txt <(digests calculados)` — saída
vazia, 11/11 idênticos.

## 15. Hardening

28/28 combinações (7 privilégios proibidos × `tse_receitas`/`tse_despesas` ×
`anon`/`authenticated`, **incluindo MAINTAIN**) = `false`.

## 16. Sequences

`tse_receitas_id_seq`/`tse_despesas_id_seq` × `anon`/`authenticated` ×
USAGE/UPDATE = 0/8 `true`.

## 17. RLS

`tse_receitas`/`tse_despesas`: `relrowsecurity = true` nas duas.

## 18. Policies

`select count(*) from pg_policies where tablename in (...)` = 0.

## 19. Owners

`pg_get_userbyid(relowner)` = `postgres` nas duas tabelas.
(FORCE RLS: `relforcerowsecurity = false` nas duas — conforme especificação.)

## 20. Dados

`tse_receitas=0`, `tse_despesas=0`.

## 21. Cron

`pg_cron` instalado (schema `cron` existe), `cron.job` = 0 linhas — zero
ativação operacional.

## 22. Verificador final

```
$ ./tools/50_baseline_verify.sh
baseline-verify: OK (aplicação limpa + hardening inclusive MAINTAIN + digests idênticos) [ambiente canônico: supabase db reset]
```
`EXIT=0`.

## 23. Limpeza final

`supabase --workdir <tmp> stop --no-backup` + remoção do diretório
temporário. Confirmado: nenhum container/volume/network `br-insider-estados`
ou `prova1c-validacao-temp` remanescente.

## 24. Preservação de `gastronomizae`

12 containers, mesmos nomes/status, confirmados imediatamente após a
limpeza final. Banco (`supabase_db_gastronomizae`) e demais serviços
seguem `Up`/`healthy`.

## 25. Arquivos modificados

Todos no worktree, **nenhum commitado**:
- `db/baseline/blocks/17_hardening.sql` (reaplicação da correção MAINTAIN — PROVA 1B)
- `db/baseline/MANIFEST_BLOCOS.md` (reaplicação — PROVA 1B)
- `db/baseline/digests_esperados.txt` (reaplicação — PROVA 1B)
- `db/baseline/tools/50_baseline_verify.sh` (reaplicação — PROVA 1B)
- `db/baseline/tools/60_drift_check.sh` (novo — PROVA 1C)
- `supabase/config.toml` (versão portátil — PROVA 1C)
- `supabase/migrations/20260718000000_baseline.sql` (montado — inalterado no conteúdo)
- Este arquivo de evidência

## 26. Riscos residuais

1. **Recorrência do worktree perdido:** esta é a **terceira vez** nesta série
   de missões que o diretório do worktree é apagado entre reconexões de
   sessão (scratchpad não-persistente). Todas as reaplicações produziram
   checksums **idênticos** aos anteriores (determinismo reconfirmado
   independentemente 3×), mas o padrão em si é um risco operacional
   recorrente — recomenda-se commitar o conteúdo validado assim que
   autorizado, para não depender da sobrevivência do worktree.
2. `Docker.raw` (14GB) continua sendo o maior consumidor Docker do disco —
   monitorar se volta a crescer em sessões futuras longas com muitos pulls
   de imagem.
3. Uma versão portátil de `supabase/config.toml` ainda depende de decisão
   humana sobre se `[api].schemas` deveria eventualmente incluir os outros
   6 schemas de aplicação (não testado nesta prova, fora do escopo).

## 27. Veredito

## **APROVADA LOCALMENTE**

Todos os critérios exigidos foram atendidos: causa do ENOSPC diagnosticada
(disco do volume de dados a 100%, Docker Desktop consumindo 14GB, daemon
inanido por I/O); limpeza segura concluída (cirúrgica, por nome/tag exato,
sem `prune`/"Purge data"); `gastronomizae` preservada (confirmada em 4
pontos); config portátil validado (`project_id` estável, portas padrão,
zero referência a worktree/usuário/segredo); drift-check aprovado (positivo
+ os 2 testes negativos das PARTES D-E); reset aprovado; 11/11 digests;
hardening aprovado (incluindo MAINTAIN); zero dados; zero cron; verificador
com `exit 0`; stack temporária removida por completo; nenhuma ação remota
em nenhum momento.

**A aprovação da PROVA 1C não autoriza PROVA 2, migration repair, alteração do histórico remoto, aplicação do baseline, criação de branch Supabase, GitHub integration ou qualquer ação em produção.**

## Nota posterior de proveniência e auditabilidade

Este documento registra uma execução histórica local. Os logs primários
completos das execuções não foram persistidos no repositório.

Uma auditoria posterior confirmou materialmente:

- o diff mínimo de `REVOKE MAINTAIN`;
- a coerência do manifesto;
- a alteração exclusiva de `grants_tabelas`;
- a sintaxe dos scripts;
- a portabilidade do `supabase/config.toml`;
- a ausência de drift entre os 17 blocos e a migration materializada.

A auditoria posterior **não** reexecutou:

- `supabase db reset`;
- os 11 digests no banco reconstruído;
- os 28 privilégios;
- RLS, policies e owners;
- zero dados;
- zero cron;
- o verificador integrado fim a fim.

Esses gates deverão ser repetidos a partir do commit local de preservação.

`supabase/.gitignore` também integra o patch preservado e havia sido omitido
da lista original de arquivos.

Não existem arquivos persistidos das PROVAS 1 e 1B.

Qualquer documento futuro sobre PROVA 1 ou PROVA 1B deverá ser rotulado como
reconstrução retrospectiva.
