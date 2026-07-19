# ADR 002 — Plano de ativação do baseline de schema

**Status:** proposto (2026-07-19) — nenhuma ação remota executada
**Autor:** Luiz Lessa (com assistência Claude)
**Contexto:** BR Insider — homologação TSE bloqueada por `MIGRATIONS_FAILED`
em branch Supabase; pacote de baseline reproduzível já mergeado
([PR #9](https://github.com/luizlessa-dev/br-insider-estados/pull/9),
commit `e1cba9b`) como candidato, ainda não ativo.

**Nota de precisão metodológica:** este documento distingue explicitamente,
em cada afirmação sobre comportamento da plataforma Supabase, entre (a) fato
confirmado por evidência direta (consulta ao catálogo, documentação oficial
citada literalmente, teste executado), e (b) inferência ou hipótese ainda
não comprovada empiricamente para este projeto. Onde a distinção não estava
clara em versões anteriores deste documento, foi corrigida.

---

## 1. Revisão do pacote mergeado (`db/baseline/`, main `8fb8b15`)

Confirmado por leitura direta dos arquivos em `origin/main`:

| Item | Confirmado |
|---|---|
| `BASELINE_CUTOFF` | `20260718000000` |
| SHA-256 do dump bruto | `2f28c841069fc6bb94fdcd33fdfd35bb44525c37f0eae1b0da214e028433184e` |
| Migrations remotas absorvidas | 23, listadas em `BASELINE_METADATA.md` (`20250313120000`…`20260716163605`) |
| Manifesto de blocos | 17 blocos em `MANIFEST_BLOCOS.md`, com checksum SHA-256 (16 hex) individual por bloco |
| Digests estruturais | 11, em `digests_esperados.txt` (colunas, constraints, índices, functions, views, matviews, triggers, policies, RLS, grants, sequences) |
| CI | `.github/workflows/baseline-verify.yml` — `pull_request` em `db/baseline/**`, `contents: read`, zero secrets, zero acesso remoto, `verify: SUCCESS` no PR #9 |
| Omissões intencionais | jobs `cron.job` (dados), valores correntes de sequences, Vault, schemas gerenciados (auth/storage/realtime), internals de extensões, publications Realtime |

O bloco `17_hardening` do baseline hoje **espelha exatamente o escopo da 0047**
(só `tse_receitas`/`tse_despesas`). A auditoria global de privilégios
([`docs/security/AUDITORIA_PRIVILEGIOS_GLOBAL.md`](../security/AUDITORIA_PRIVILEGIOS_GLOBAL.md))
encontrou 13 objetos TSE adicionais com privilégios não cobertos por este
bloco — a decisão de expandir o bloco 17 (ou criar um bloco 18) é tratada
naquele documento, não decidida aqui.

---

## 2. Mecanismo de ativação — comparação de 4 opções

**Objetivo comum:** fazer com que uma futura branch Supabase reconstrua o
schema correto a partir do histórico, **sem** rodar o DDL do baseline contra
a produção (que já tem o schema — rodar seria redundante na melhor hipótese
e arriscado na pior, por colidir com objetos existentes).

### A. Inserir/reparar o histórico formal diretamente

**Mecanismo:** `INSERT` direto em `supabase_migrations.schema_migrations`
(colunas `version`, `name`, `statements`) com uma linha cujo `statements`
seja o DDL canonicalizado completo (blocos 00–17), **sem executar** esse DDL
— é uma escrita de metadado no catálogo de migrations, não uma aplicação de
schema (os objetos já existem).

- **Comandos:** SQL direto (`INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES (...)`), fora do CLI.
- **Objetos remotos alterados:** somente a tabela `supabase_migrations.schema_migrations` (1 linha nova). Nenhum schema de aplicação tocado.
- **Risco:** MÉDIO. Sem ferramenta oficial validando o formato exato do array `statements` — erro de formatação não quebra produção (a tabela é só metadado), mas pode quebrar o *replay* em branch de forma silenciosa.
- **Rollback:** `DELETE` da linha inserida — trivial, metadado puro, e reversível com segurança porque a própria auditoria já sabe exatamente qual linha foi adicionada (não há necessidade de restaurar estado anterior, já que nada anterior foi removido nesta opção).
- **Efeito em branches:** não confirmado nesta auditoria — depende exatamente do mesmo comportamento de replay discutido no item D abaixo, que **ainda precisa de prova**.
- **Efeito no CLI:** `supabase migration list` passaria a listar a nova versão como remota; sem arquivo local correspondente, o CLI reportaria divergência local↔remoto até `supabase db pull` recriar o arquivo local.
- **Efeito em migrations futuras:** nenhum — novas migrations continuam com timestamp posterior, sem conflito.
- **As 23 linhas antigas:** para eliminar o replay quebrado do `initial_schema`, estas 23 linhas precisariam ser **removidas ou substituídas** — e remover/alterar linhas de `supabase_migrations.schema_migrations` é **exatamente a ação vetada nesta sessão** (`NÃO altere schema_migrations`). Portanto A, para funcionar de verdade, **exige uma etapa futura e separadamente autorizada** que toca o histórico existente — não é uma operação apenas aditiva.

### B. Nova linhagem de migrations com baseline (aditiva, sem tocar as 23 antigas)

**Mecanismo:** criar um novo diretório `supabase/migrations/` no repo, com **um único arquivo** `20260718000000_baseline.sql` contendo o DDL canonicalizado, e adotar o CLI/GitHub integration a partir daqui — sem remover nem alterar as 23 entradas já existentes no histórico remoto.

- **Comandos:** `supabase init` (cria `supabase/config.toml`), copiar `db/baseline/baseline_canonicalizado.sql` para `supabase/migrations/20260718000000_baseline.sql`, `supabase link --project-ref <ref>`, depois `supabase migration repair 20260718000000 --status applied` (ferramenta oficial — ver §2.D sobre o que ela de fato garante).
- **Objetos remotos alterados:** 1 linha nova em `schema_migrations` (via `repair`, não via `push`). As 23 linhas antigas **permanecem intocadas**.
- **Risco:** BAIXO para produção (não mexe nas 23 linhas nem no schema). MÉDIO para o objetivo de branching: como as 23 entradas antigas continuam no histórico com timestamp anterior a `20260718000000`, uma branch cujo replay siga ordem cronológica ainda tentaria `initial_schema` primeiro e falharia **antes** de alcançar o baseline — **B sozinho não resolve o `MIGRATIONS_FAILED`**, só evita mexer no passado.
- **Rollback:** `supabase migration repair 20260718000000 --status reverted` (ferramenta oficial, documentada — remove a linha inserida por `repair`; ver §2.D para as ressalvas sobre reversibilidade quando a operação envolve reinserir dados removidos, que não é o caso aqui).
- **Efeito em branches:** nulo enquanto as 23 antigas continuarem na frente da fila — seria necessário também revertê-las (o que reintroduz o mesmo obstáculo de A).
- **Efeito no CLI:** habilita `supabase db push`/`db pull`/`migration list` corretamente pela primeira vez neste repositório (hoje ausentes).
- **Efeito em migrations futuras:** positivo — estabelece a convenção `supabase/migrations/` daqui em diante, elimina a duplicidade com `db/migrations/`.

### C. Projeto ou repositório canônico separado

**Mecanismo:** provisionar um **novo projeto Supabase** (novo project_ref), aplicar o baseline como sua migration 1 (schema limpo, sem histórico legado), e migrar a aplicação para apontar para o novo projeto — ou manter o mesmo projeto de produção mas mover a fonte-da-verdade de migrations para um repositório Git dedicado com `supabase/migrations/` correto desde o início, ligado via GitHub integration.

- **Comandos:** `create_project` (novo projeto) **ou** reorganização de repositório; `supabase link`; `supabase db push` (aqui a execução do DDL **é** necessária, mas contra um projeto **novo e vazio** — não contra produção existente).
- **Objetos remotos alterados:** um projeto Supabase inteiro novo (variante "novo projeto") — troca de `project_ref`, de API URL, de todas as chaves; ou nenhum objeto de produção (variante "repo canônico separado", que só reorganiza onde o Git rastreia migrations, sem tocar o projeto).
- **Risco:** ALTO na variante "novo projeto" (cutover de aplicação inteira, DNS/env vars, downtime potencial, custo adicional). BAIXO-MÉDIO na variante "repo canônico" (só reorganização de tooling, mas ainda deixa as 23 entradas do projeto atual sem solução).
- **Rollback:** variante "novo projeto" — difícil (múltiplos sistemas dependem do project_ref atual: GHA secrets, Vercel, etc. — reverter é outro cutover). Variante "repo" — trivial (é só onde o Git aponta).
- **Efeito em branches:** variante "novo projeto" resolve 100% (branch nasce de um histórico limpo). Variante "repo" não resolve sozinha (mesmo obstáculo de B).
- **Efeito no CLI:** variante "novo projeto" exige relink completo de todas as automações.
- **Efeito em migrations futuras:** variante "novo projeto" é a mudança mais disruptiva da lista — desproporcional ao problema (o schema de produção está correto; o problema é só o histórico de *como chegamos lá*).

### D. Estratégia baseada em comandos oficiais do Supabase CLI

**Distinção importante (correção metodológica):** `supabase migration squash`
e `supabase migration repair` são, cada um individualmente, **ferramentas
oficiais e documentadas** pela Supabase:

- `supabase migration squash` — documentado: "Squashes local schema
  migrations to a single migration file. The squashed migration is
  equivalent to a schema only dump ... after applying existing migration
  files." Documentado explicitamente: **omite** DML, cron jobs, storage
  buckets e secrets do Vault ("You will have to add them back manually").
- `supabase migration repair <version> --status reverted|applied` —
  documentado: "Marking as `reverted` will delete an existing record from
  the migration history table while marking as `applied` will insert a new
  record." Usado oficialmente para reconciliar histórico local↔remoto fora
  de sincronia.

**O que NÃO é oficial:** a combinação específica proposta abaixo — usar
`repair --status reverted` em 23 versões existentes e substituí-las por uma
única versão de baseline gerada por `squash` de um schema-only dump externo
(não de migrations locais previamente aplicadas passo a passo) — é uma
**estratégia nossa**, montada a partir de peças oficiais, não uma receita
publicada pela Supabase para este cenário específico. A documentação de
`squash` descreve seu uso típico como consolidar migrations **locais que já
foram criadas e aplicadas incrementalmente**, não como importar um dump
schema-only de uma fonte externa como se fosse o resultado de um squash.
Isso não invalida a estratégia, mas significa que ela **precisa de prova
própria** (§4) antes de qualquer aplicação contra o histórico de produção —
não pode ser tratada como "caminho testado pela Supabase para este caso".

**Sequência de comandos** (não executada nesta etapa):
```
supabase init
# copiar db/baseline/baseline_canonicalizado.sql (ajustado) para
# supabase/migrations/20260718000000_baseline_tse_homologacao.sql
supabase link --project-ref <ref>
supabase migration repair 20250313120000 --status reverted   # ×23, uma por versão
supabase migration repair 20260718000000 --status applied
supabase migration list   # confirma LOCAL == REMOTE
```

- **Objetos remotos alterados:** exclusivamente `supabase_migrations.schema_migrations` — as 23 linhas antigas removidas, 1 linha nova inserida. `repair` não executa os `statements` da migration (nem os antigos, ao reverter, nem o novo, ao marcar como aplicado) — é operação de metadado.
- **Risco:** MÉDIO. `repair` e `squash` são individualmente oficiais, mas a combinação para este caso específico (substituir histórico legado quebrado por um baseline externo) não tem receita publicada equivalente — exige validação própria (§4) antes de qualquer aplicação em produção.
- **Rollback:** ver correção detalhada em §5 — não é tão simples quanto "reinserir as 23 versões".
- **Efeito em branches:** sobre GitHub integration, ver a correção abaixo.
- **Efeito no CLI:** estabelece pela primeira vez o fluxo CLI padrão (`push`/`pull`/`migration list`) neste repositório, hoje inexistente.
- **Efeito em migrations futuras:** positivo — alinha o projeto ao modelo que a documentação da Supabase assume para o restante do produto (branching, deploy automático).

**Correção sobre GitHub integration e Branching (item anteriormente
impreciso):**

- **Confirmado:** a GitHub integration, quando ativa, aplica migrations a
  partir do diretório `supabase/migrations/` do repositório Git vinculado —
  isto é comportamento documentado (etapas "Clone"/"Pull"/"Migrate" do fluxo
  de deploy da Supabase).
- **Confirmado:** o **Dashboard Branching também existe sem Git** — não é
  exclusivo de projetos com GitHub integration (documentado: "Branching via
  the dashboard ... currently in public alpha").
- **Confirmado por documentação, mas com comportamento exato não verificado
  empiricamente neste projeto:** sem GitHub integration, a plataforma usa um
  fluxo de **Pull/Migrate a partir do projeto principal** para popular
  branches novas — a doc de troubleshooting relata que "if you have run
  migrations on main, new branches will be created from existing migrations
  instead of a full schema dump", o que é consistente com o
  `MIGRATIONS_FAILED` já diagnosticado. **Mas o comportamento exato deste
  histórico** (se "existing migrations" significa literalmente reexecutar o
  conteúdo de `statements` de cada linha de `schema_migrations`, em que
  ordem, com que tratamento de erro) **precisa de prova empírica** — não foi
  confirmado por teste direto, só por inferência a partir da documentação
  geral e da correspondência com o sintoma observado.
- **Conclusão corrigida:** GitHub integration é **preferível** por dar
  previsibilidade (fonte de verdade = arquivos Git, comportamento
  documentado com mais detalhe), mas **não é requisito absoluto** para
  branching funcionar — Dashboard Branching sem Git é um caminho
  paralelo, com comportamento de replay menos documentado publicamente e
  que, por isso, exige a prova em ambiente descartável descrita em §4 antes
  de se confiar nele para a homologação real.

### Comparação resumida

| | A — insert direto | B — nova linhagem aditiva | C — projeto/repo separado | D — squash + repair (ferramentas oficiais, combinação nossa) |
|---|---|---|---|---|
| Resolve o replay sozinho | Não confirmado | Não | Sim (variante projeto novo) | Não confirmado sem prova prévia (§4) |
| Toca as 23 linhas antigas | Sim (implícito, não documentado) | Não | Não | Sim (explícito, com `repair`) |
| Ferramentas usadas são oficiais | Não (SQL direto) | Parcial (`repair`, sim; combinação, não) | Não | `repair`/`squash` sim; combinação para este caso, não |
| Risco operacional | Médio | Baixo (mas ineficaz sozinho) | Alto (projeto novo) / Baixo (repo) | Médio |
| Reversibilidade | Trivial | Trivial | Difícil / Trivial | Requer backup prévio (§5) — não trivial |

---

## 3. Opção tecnicamente preferível

**Opção D**, com duas condições explícitas antes de qualquer execução:
(1) confirmar operacionalmente, em ambiente descartável, se a GitHub
integration pode ser ativada e se isso muda o comportamento de replay
observado; (2) executar a sequência de prova em duas etapas descrita em §4,
já que — corrigindo a avaliação anterior deste documento — D **não** é uma
receita oficial publicada para este cenário específico, apenas construída a
partir de duas ferramentas que são, cada uma, oficiais. A/B/C ficam como
alternativas de contingência caso D não se confirme viável na prova.

---

## 4. Sequência de prova em duas etapas (obrigatória antes de qualquer ação produtiva)

Nenhuma authorização produtiva deve ser considerada antes de ambas as provas
serem concluídas com sucesso e revisadas.

### PROVA 1 — geração local, zero contato remoto

- Gerar `supabase/migrations/` localmente a partir do baseline canonicalizado.
- Testar `supabase db reset` (ou equivalente local) contra um Postgres
  local/descartável, confirmando que o arquivo único aplica corretamente do
  zero.
- **Zero alteração remota** — nenhum `link`, nenhum `repair`, nenhuma
  conexão a `redgg…jzhb` nesta etapa.
- Critério de sucesso: aplicação limpa local + digests batendo com
  `digests_esperados.txt` (mesma validação que `baseline-verify.sh` já faz,
  reafirmando-a sobre o arquivo squashado real).

### PROVA 2 — projeto Supabase descartável separado (não o de produção)

- Provisionar um **projeto Supabase descartável** (não uma branch do
  projeto de produção — um projeto novo e isolado, para não colocar em
  risco nenhum histórico real durante o experimento).
- **Simular** um histórico equivalente às 23 migrations antigas dentro
  desse projeto descartável (não copiar credenciais nem dados de produção —
  apenas reproduzir a estrutura do problema: um `initial_schema` com
  dependência não satisfeita, seguido de outras migrations).
- Executar `repair --status reverted` nas simuladas + `repair --status
  applied` no baseline, exatamente como se pretende fazer futuramente em
  produção.
- Criar uma branch a partir desse projeto descartável e observar o
  resultado real do replay (prova direta do comportamento descrito em
  §2.D, hoje apoiado só em inferência documental).
- Testar o procedimento de rollback (§5) neste mesmo ambiente descartável.
- Comparar os 11 digests resultantes com `digests_esperados.txt`.
- Critério de sucesso: branch nasce saudável (não `MIGRATIONS_FAILED`),
  digests batem, rollback restaura o estado simulado anterior com sucesso
  comprovado.

**Só depois de PROVA 1 e PROVA 2 concluídas e revisadas:** considerar uma
eventual autorização para aplicar a sequência de `repair` contra o histórico
real de produção — decisão explícita e separada, fora do escopo desta
missão.

---

## 5. Pré-requisito obrigatório antes de qualquer `repair` produtivo

Antes de qualquer `migration repair` contra o histórico real de produção
(mesmo depois de PROVA 1/PROVA 2 bem-sucedidas), é obrigatório:

1. **Exportar** o conteúdo integral de `supabase_migrations.schema_migrations`
   (`SELECT *`) — as 23 linhas completas, incluindo `version`, `name` e
   `statements` de cada uma.
2. **Armazenar fora do Git** (nunca commitado — mesma política já aplicada
   ao snapshot bruto do baseline).
3. **Calcular e registrar o checksum** (SHA-256) desse backup.
4. **Verificar** nomes, versões e conteúdo de `statements` de cada uma das
   23 linhas contra o que se espera antes de qualquer `repair --status
   reverted`.
5. **Preparar o procedimento de restauração** a partir desse backup (não
   apenas descrever — ter o script pronto).
6. **Testar a restauração** desse backup especificamente em um **projeto
   descartável** (não em produção) antes de confiar nele como plano de
   contingência real.

**Correção sobre o rollback via `repair` (item anteriormente impreciso):**
`supabase migration repair <version> --status applied` **reinsere uma
versão** no histórico — mas **não está comprovado que essa reinserção
restaura todos os campos originais** da linha removida (em particular, não
há confirmação documental de que o comando aceita ou preserva o conteúdo
completo de `statements` tal como estava antes de um `--status reverted`
anterior; a documentação oficial descreve `repair` como inserindo "a new
record", sem detalhar se isso inclui reconstrução fiel do `statements`
original). Por isso, o rollback **completo e confiável** depende
inteiramente do backup externo descrito acima (passos 1–6) — não do
comando `repair` sozinho.

---

## 6. Estratégia para as 23 migrations antigas

| Tratamento | Decisão proposta |
|---|---|
| Arquivos em `db/migrations/` (linhagem legada, `0001`–`0047`) | **Mantidos** no repositório, sem exclusão — são o registro histórico de como o schema evoluiu; continuam relevantes para leitura/auditoria (inclusive esta própria auditoria os usou). |
| Entradas em `supabase_migrations.schema_migrations` (as 23) | **Marcadas como absorvidas** pelo baseline (`BASELINE_CUTOFF=20260718000000`) — a ação de removê-las do histórico remoto (via `repair --status reverted`) é a etapa que **exige nova autorização explícita e as provas da §4**, não incluída nesta missão. |
| Relacionamento com o cutoff | Todas as 23 têm timestamp **anterior** a `20260718000000` — nenhuma é posterior, nenhuma fica "pendente" após a ativação. |
| Exclusão do replay | Só ocorre no momento em que forem marcadas `reverted` — até lá, continuam no caminho de replay e continuam causando o `MIGRATIONS_FAILED` documentado. |

---

## 7. Teste em branch descartável (definição — parte da PROVA 2 e de qualquer teste real subsequente)

| Campo | Valor |
|---|---|
| Nome da branch | `tse-homologacao-baseline-<YYYYMMDD>` (nunca reaproveitar nome de branch anterior) |
| `with_data` | `false` (obrigatório — nenhuma branch de teste deve nascer com dados) |
| Dados esperados | **zero** linhas em todas as tabelas de aplicação logo após criação (branches nascem vazias por design da plataforma) |
| Migrations esperadas | **expectativa inicial de exatamente 1 entrada** em `supabase_migrations.schema_migrations` da branch — a versão do baseline — **sujeita à observação experimental**; o comportamento real de replay em Dashboard Branching sem GitHub integration ainda não foi comprovado neste projeto (ver §2.D), então o gate abaixo é definido por critérios de correção, não por uma contagem fixa presumida como certa. |
| Digests esperados | os 11 digests de `db/baseline/digests_esperados.txt`, recalculados na branch e comparados byte a byte |
| Cron esperado | **zero** jobs em `cron.job` (branches não herdam jobs; se algum aparecer, é um vazamento de configuração a investigar) |
| Secrets esperados | **zero** — nenhum Vault secret de produção deve aparecer na branch |
| Schemas esperados | exatamente os 7 de aplicação + os gerenciados pela plataforma (auth/storage/realtime/etc.) — nenhum schema extra, nenhum faltando |
| Critérios de falha | qualquer desvio dos critérios do gate (§8); `status` diferente de saudável; qualquer contagem de dados > 0; qualquer cron job presente; qualquer secret presente |
| Política de exclusão | branch é **descartável por definição** — excluir imediatamente após o teste (sucesso ou falha), nunca promover a persistente sem uma decisão explícita separada |

---

## 8. Gates obrigatórios (definição — critérios de PASS/FAIL)

| Gate | Critério de PASS |
|---|---|
| `HISTORY_GATE` | Baseline presente no histórico da branch; migrations legadas quebradas (as 23 antigas problemáticas) **ausentes**; nenhuma migration inesperada além do baseline; `LOCAL == REMOTE` quando aplicável (fluxo com GitHub integration) |
| `BASELINE_CHECKSUM_GATE` | SHA-256 do arquivo/entrada de migration aplicado bate com o registrado em `MANIFEST_BLOCOS.md`/`BASELINE_METADATA.md` no momento do `repair` |
| `BRANCH_REPLAY_GATE` | criação de branch descartável termina com `status` saudável (não `MIGRATIONS_FAILED`) |
| `SCHEMA_DIGEST_GATE` | os 11 digests da branch == os 11 digests de `digests_esperados.txt`, sem nenhuma divergência não documentada (a única exceção pré-aprovada é `mg_remuneracao`, já registrada) |
| `ZERO_DATA_GATE` | `count(*)` = 0 em todas as tabelas de aplicação da branch |
| `ZERO_CRON_GATE` | `select count(*) from cron.job` = 0 na branch |
| `SECRET_HYGIENE_GATE` | nenhum valor de Vault/secret de produção acessível ou presente na branch |
| `TSE_SCHEMA_GATE` | `tse_receitas`/`tse_despesas` (e demais objetos TSE do inventário) existem na branch com a mesma estrutura de produção, **e** com os grants pós-hardening (0047 no mínimo; idealmente o hardening completo proposto no documento de auditoria) |

Todos os 8 gates devem passar antes de a branch ser usada para qualquer
homologação. Falha em qualquer um ⇒ excluir a branch, não prosseguir.

---

## 9. Tratamento dos default ACLs

Duas opções, nenhuma executada:

**A. Baseline fiel + hardening posterior** (a postura atual do pacote
mergeado — bloco `16_default_privileges` é fiel a produção, bloco `17`
aplica só o hardening já decidido/aplicado via 0047):
- Consequência para uma branch nova: nasce com o **mesmo** default ACL
  vulnerável de produção (toda tabela nova criada por `postgres` continua
  gravável por anon/authenticated) — a branch reproduz fielmente o estado
  atual, incluindo o achado HIGH-sistêmico (elevável a CRITICAL mediante
  prova, ver documento de auditoria §1) do default ACL.
- Vantagem: rastro auditável claro — a decisão de segurança fica em uma
  migration própria e revisável, não escondida dentro do baseline.

**B. Baseline já normalizado** (editar o bloco 16 antes de qualquer
registro formal, aplicando `ALTER DEFAULT PRIVILEGES ... REVOKE ...` também
como parte do próprio baseline):
- Consequência para uma branch nova: nasce **já protegida** — qualquer
  tabela criada dali em diante (inclusive pelo próprio processo de
  homologação TSE) não herdaria automaticamente grants perigosos.
- Desvantagem: mistura fidelidade histórica com política de segurança no
  mesmo artefato — dificulta auditar "o que produção tem hoje" vs "o que
  decidimos que deveria ter".

**Recomendação (não executada):** A para o baseline em si (mantém fidelidade
e auditabilidade), combinada com a migration de hardening completo proposta
em `AUDITORIA_PRIVILEGIOS_GLOBAL.md` §5 (bloco 6 daquele documento —
`ALTER DEFAULT PRIVILEGES`) aplicada **tanto em produção quanto refletida
no bloco 16 do baseline** como uma atualização subsequente e explícita do
pacote, não como uma normalização silenciosa agora.
