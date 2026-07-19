# ADR 002 — Plano de ativação do baseline de schema

**Status:** proposto (2026-07-19) — nenhuma ação remota executada
**Autor:** Luiz Lessa (com assistência Claude)
**Contexto:** BR Insider — homologação TSE bloqueada por `MIGRATIONS_FAILED`
em branch Supabase; pacote de baseline reproduzível já mergeado
([PR #9](https://github.com/luizlessa-dev/br-insider-estados/pull/9),
commit `e1cba9b`) como candidato, ainda não ativo.

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
encontrou 13 objetos TSE adicionais com o mesmo padrão de risco, não cobertos
por este bloco — a decisão de expandir o bloco 17 (ou criar um bloco 18) é
tratada em §7, não decidida aqui.

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
- **Risco:** MÉDIO. Sem ferramenta oficial validando o formato exato do array `statements` — erro de formatação não quebra produção (a tabela é só metadado), mas pode quebrar o *replay* em branch de forma silenciosa (branch nasceria com erro tardio, não na criação).
- **Rollback:** `DELETE` da linha inserida — trivial, metadado puro.
- **Efeito em branches:** ainda depende de como a Branching sem GitHub integration monta as filas de replay — **não documentado publicamente com precisão suficiente para prever com certeza** (as instruções do plano deste ADR exigem citar isso como incerteza, não como fato).
- **Efeito no CLI:** `supabase migration list` passaria a listar a nova versão como remota; sem arquivo local correspondente, o CLI reportaria divergência local↔remoto até `supabase db pull` recriar o arquivo local.
- **Efeito em migrations futuras:** nenhum — novas migrations continuam com timestamp posterior, sem conflito.
- **As 23 linhas antigas:** para eliminar o replay quebrado do `initial_schema`, estas 23 linhas precisariam ser **removidas ou substituídas** — e remover/alterar linhas de `supabase_migrations.schema_migrations` é **exatamente a ação vetada nesta sessão** (`NÃO altere schema_migrations`). Portanto A, para funcionar de verdade, **exige uma etapa futura e separadamente autorizada** que toca o histórico existente — não é uma operação apenas aditiva.

### B. Nova linhagem de migrations com baseline (aditiva, sem tocar as 23 antigas)

**Mecanismo:** criar um novo diretório `supabase/migrations/` no repo, com **um único arquivo** `20260718000000_baseline.sql` contendo o DDL canonicalizado, e adotar o CLI/GitHub integration a partir daqui — sem remover nem alterar as 23 entradas já existentes no histórico remoto.

- **Comandos:** `supabase init` (cria `supabase/config.toml`), copiar `db/baseline/baseline_canonicalizado.sql` para `supabase/migrations/20260718000000_baseline.sql`, `supabase link --project-ref redggdtakzmsabwvjzhb`, depois `supabase migration repair 20260718000000 --status applied` (marca a nova versão como aplicada no histórico remoto **sem executá-la** — documentado oficialmente, ver §2.4).
- **Objetos remotos alterados:** 1 linha nova em `schema_migrations` (via `repair`, não via `push`). As 23 linhas antigas **permanecem intocadas**.
- **Risco:** BAIXO para produção (não mexe nas 23 linhas nem no schema). MÉDIO para o objetivo de branching: como as 23 entradas antigas continuam no histórico com timestamp anterior a `20260718000000`, uma branch cujo replay siga ordem cronológica ainda tentaria `initial_schema` primeiro e falharia **antes** de alcançar o baseline — **B sozinho não resolve o `MIGRATIONS_FAILED`**, só evita mexer no passado.
- **Rollback:** `supabase migration repair 20260718000000 --status reverted` (documentado, remove a linha).
- **Efeito em branches:** nulo enquanto as 23 antigas continuarem na frente da fila — seria necessário também revertê-las (o que reintroduz o mesmo obstáculo de A).
- **Efeito no CLI:** habilita `supabase db push`/`db pull`/`migration list` corretamente pela primeira vez neste repositório (hoje ausentes).
- **Efeito em migrations futuras:** positivo — estabelece a convenção `supabase/migrations/` daqui em diante, elimina a duplicidade com `db/migrations/`.

### C. Projeto ou repositório canônico separado

**Mecanismo:** provisionar um **novo projeto Supabase** (novo project_ref), aplicar o baseline como sua migration 1 (schema limpo, sem histórico legado), e migrar a aplicação para apontar para o novo projeto — ou manter o mesmo projeto de produção mas mover a fonte-da-verdade de migrations para um repositório Git dedicado com `supabase/migrations/` correto desde o início, ligado via GitHub integration.

- **Comandos:** `create_project` (novo projeto) **ou** reorganização de repositório; `supabase link`; `supabase db push` (aqui a execução do DDL **é** necessária, mas contra um projeto **novo e vazio** — não contra produção existente).
- **Objetos remotos alterados:** um projeto Supabase inteiro novo (variante "novo projeto") — troca de `project_ref`, de API URL, de todas as chaves; ou nenhum objeto de produção (variante "repo canônico separado", que só reorganiza onde o Git rastreia migrations, sem tocar o projeto).
- **Risco:** ALTO na variante "novo projeto" (cutover de aplicação inteira, DNS/env vars, downtime potencial, USD adicional). BAIXO-MÉDIO na variante "repo canônico" (só reorganização de tooling, mas ainda deixa as 23 entradas do projeto atual sem solução).
- **Rollback:** variante "novo projeto" — difícil (múltiplos sistemas dependem do project_ref atual: GHA secrets, Vercel, etc. — reverter é outro cutover). Variante "repo" — trivial (é só onde o Git aponta).
- **Efeito em branches:** variante "novo projeto" resolve 100% (branch nasce de um histórico limpo). Variante "repo" não resolve sozinha (mesmo obstáculo de B).
- **Efeito no CLI:** variante "novo projeto" exige relink completo de todas as automações.
- **Efeito em migrations futuras:** variante "novo projeto" é a mudança mais disruptiva da lista — desproporcional ao problema (o schema de produção está correto; o problema é só o histórico de *como chegamos lá*).

### D. Mecanismo oficialmente recomendado (Supabase CLI atual)

**Confirmado via documentação oficial** (`supabase-migration-squash`,
`supabase-migration-repair`): o Supabase CLI tem comandos dedicados
exatamente a este cenário.

1. **`supabase migration squash`** — "Squashes local schema migrations to a
   single migration file. The squashed migration is equivalent to a schema
   only dump ... after applying existing migration files." Documentado
   explicitamente: **omite** DML, cron jobs, storage buckets e secrets do
   Vault (idêntico ao que o pacote `db/baseline` já faz manualmente) — "You
   will have to add them back manually."
2. **`supabase migration repair <version> --status reverted`** — remove uma
   entrada específica do histórico remoto (documentado: "Marking as
   `reverted` will delete an existing record").
3. **`supabase migration repair <version> --status applied`** — insere uma
   entrada no histórico remoto marcando-a aplicada, **sem executar SQL**
   (documentado: "will insert a new record").

**Sequência oficial completa** (não executada nesta etapa):
```
supabase init
# copiar db/baseline/baseline_canonicalizado.sql (ajustado) para
# supabase/migrations/20260718000000_baseline_tse_homologacao.sql
supabase link --project-ref redggdtakzmsabwvjzhb
supabase migration repair 20250313120000 --status reverted   # ×23, uma por versão
supabase migration repair 20260718000000 --status applied
supabase migration list   # confirma LOCAL == REMOTE, só a versão do baseline
```

- **Objetos remotos alterados:** exclusivamente `supabase_migrations.schema_migrations` — as 23 linhas antigas removidas, 1 linha nova inserida. **Nenhum DDL de schema é executado** (repair não roda `statements`; squash só toca arquivos locais).
- **Risco:** BAIXO-MÉDIO. É o caminho testado e documentado pela própria Supabase para "local e remoto fora de sincronia" — mas ainda envolve **remover as 23 entradas antigas**, ação vetada nesta sessão e que exige autorização própria numa etapa futura.
- **Rollback:** `supabase migration repair <version> --status applied` para cada uma das 23 (reinserir) + `repair 20260718000000 --status reverted` (remover o baseline) — documentado, simétrico.
- **Efeito em branches:** este é o único mecanismo com **suporte oficial documentado** para o cenário — branches criadas com GitHub integration ativa replicam a partir dos arquivos em `supabase/migrations/` (não do histórico remoto bruto), então uma única migration-baseline correta resolve o `MIGRATIONS_FAILED` na raiz.
- **Efeito no CLI:** estabelece pela primeira vez o fluxo CLI padrão (`push`/`pull`/`migration list`) neste repositório, hoje inexistente.
- **Efeito em migrations futuras:** positivo — é o modelo que a documentação da Supabase assume para todo o resto do produto (branching, deploy automático, etc.); manter o `db/migrations/` legado em paralelo deixaria de fazer sentido após a transição.

**Pré-requisito não avaliado nesta etapa:** D pressupõe **GitHub integration
ativa** (hoje confirmada inativa) para que a criação de branch replique a
partir dos arquivos Git em vez do histórico bruto de `schema_migrations` — se
a integração permanecer inativa, D reduz-se operacionalmente a A/B (ainda
melhora a higiene do CLI, mas não garante sozinho a correção do replay em
Branching via Dashboard). **Confirmar isso operacionalmente é o primeiro
passo da sequência futura (§7), antes de qualquer `repair`.**

### Comparação resumida

| | A — insert direto | B — nova linhagem aditiva | C — projeto/repo separado | D — squash + repair oficial |
|---|---|---|---|---|
| Resolve o replay sozinho | Incerto | Não | Sim (variante projeto novo) | Sim, com GitHub integration |
| Toca as 23 linhas antigas | Sim (implícito, não documentado) | Não | Não | Sim (explícito, documentado) |
| Ferramenta oficial | Não | Parcial (`repair`) | Não | **Sim** |
| Risco operacional | Médio | Baixo (mas ineficaz sozinho) | Alto (projeto novo) / Baixo (repo) | Baixo-médio |
| Reversibilidade | Trivial | Trivial | Difícil / Trivial | Trivial (documentada) |

---

## 3. Opção tecnicamente preferível

**Opção D**, condicionada a confirmar (passo 0, read-only) se a GitHub
integration pode ser ativada para este repositório e projeto. É a única
apoiada por comandos oficiais e documentados para exatamente este cenário
("local e remoto fora de sincronia"), com efeito previsível em branches e
caminho de rollback simétrico e documentado. A/B/C ficam como alternativas
de contingência caso a GitHub integration não seja viável.

---

## 4. Estratégia para as 23 migrations antigas

| Tratamento | Decisão proposta |
|---|---|
| Arquivos em `db/migrations/` (linhagem legada, `0001`–`0047`) | **Mantidos** no repositório, sem exclusão — são o registro histórico de como o schema evoluiu; continuam relevantes para leitura/auditoria (inclusive esta própria auditoria os usou). |
| Entradas em `supabase_migrations.schema_migrations` (as 23) | **Marcadas como absorvidas** pelo baseline (`BASELINE_CUTOFF=20260718000000`) — a ação de removê-las do histórico remoto (via `repair --status reverted`) é a etapa que **exige nova autorização explícita**, não incluída nesta missão. |
| Relacionamento com o cutoff | Todas as 23 têm timestamp **anterior** a `20260718000000` — nenhuma é posterior, nenhuma fica "pendente" após a ativação. |
| Exclusão do replay | Só ocorre no momento em que forem marcadas `reverted` — até lá, continuam no caminho de replay e continuam causando o `MIGRATIONS_FAILED` documentado. |

---

## 5. Teste futuro em branch descartável (definição, não execução)

| Campo | Valor |
|---|---|
| Nome da branch | `tse-homologacao-baseline-<YYYYMMDD>` (nunca reaproveitar nome de branch anterior) |
| `with_data` | `false` (obrigatório — nenhuma branch de teste deve nascer com dados) |
| Dados esperados | **zero** linhas em todas as tabelas de aplicação logo após criação (branches nascem vazias por design da plataforma) |
| Migrations esperadas | exatamente **1** entrada em `supabase_migrations.schema_migrations` da branch: a versão do baseline (`20260718000000`) — nenhuma das 23 antigas, nenhum `MIGRATIONS_FAILED` |
| Digests esperados | os 11 digests de `db/baseline/digests_esperados.txt`, recalculados na branch e comparados byte a byte |
| Cron esperado | **zero** jobs em `cron.job` (branches não herdam jobs; se algum aparecer, é um vazamento de configuração a investigar) |
| Secrets esperados | **zero** — nenhum Vault secret de produção deve aparecer na branch |
| Schemas esperados | exatamente os 7 de aplicação + os gerenciados pela plataforma (auth/storage/realtime/etc.) — nenhum schema extra, nenhum faltando |
| Critérios de falha | qualquer desvio de qualquer linha acima; `status` diferente de saudável; qualquer contagem de dados > 0; qualquer cron job presente; qualquer secret presente |
| Política de exclusão | branch é **descartável por definição** — excluir imediatamente após o teste (sucesso ou falha), nunca promover a persistente sem uma decisão explícita separada |

---

## 6. Gates obrigatórios (definição — critérios de PASS/FAIL)

| Gate | Critério de PASS |
|---|---|
| `HISTORY_GATE` | `supabase migration list` mostra LOCAL == REMOTE, sem entradas órfãs de nenhum dos dois lados |
| `BASELINE_CHECKSUM_GATE` | SHA-256 do arquivo de migration aplicado bate com o registrado em `MANIFEST_BLOCOS.md`/`BASELINE_METADATA.md` no momento do `repair` |
| `BRANCH_REPLAY_GATE` | criação de branch descartável termina com `status` saudável (não `MIGRATIONS_FAILED`), replay usa exclusivamente a versão do baseline |
| `SCHEMA_DIGEST_GATE` | os 11 digests da branch == os 11 digests de `digests_esperados.txt`, sem nenhuma divergência não documentada (a única exceção pré-aprovada é `mg_remuneracao`, já registrada) |
| `ZERO_DATA_GATE` | `count(*)` = 0 em todas as tabelas de aplicação da branch |
| `ZERO_CRON_GATE` | `select count(*) from cron.job` = 0 na branch |
| `SECRET_HYGIENE_GATE` | nenhum valor de Vault/secret de produção acessível ou presente na branch |
| `TSE_SCHEMA_GATE` | `tse_receitas`/`tse_despesas` (e demais objetos TSE do inventário) existem na branch com a mesma estrutura de produção, **e** com os grants pós-hardening (0047 no mínimo; idealmente o hardening completo de §7 do documento de auditoria) |

Todos os 8 gates devem passar antes de a branch ser usada para qualquer
homologação. Falha em qualquer um ⇒ excluir a branch, não prosseguir.

---

## 7. Tratamento dos default ACLs

Duas opções, nenhuma executada:

**A. Baseline fiel + hardening posterior** (a postura atual do pacote
mergeado — bloco `16_default_privileges` é fiel a produção, bloco `17`
aplica só o hardening já decidido/aplicado via 0047):
- Consequência para uma branch nova: nasce com o **mesmo** default ACL
  vulnerável de produção (toda tabela nova criada por `postgres` continua
  gravável por anon/authenticated) — a branch reproduz fielmente o estado
  atual, incluindo o problema sistêmico do achado CRITICAL da auditoria.
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
em `AUDITORIA_PRIVILEGIOS_GLOBAL.md` §5 (bloco 5 daquele documento —
`ALTER DEFAULT PRIVILEGES`) aplicada **tanto em produção quanto refletida
no bloco 16 do baseline** como uma atualização subsequente e explícita do
pacote, não como uma normalização silenciosa agora.
