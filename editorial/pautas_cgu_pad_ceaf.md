# Pautas editoriais — CGU-PAD × CEAF
> The BR Insider · Luiz Lessa · jun/2026
> Dados: cgu_pad_processos (90.460 processos) + ceaf_expulsoes (a ingerir)

---

## PAUTA 1 — "O hospital federal que mais demitiu durante a pandemia"
**Grupo Hospitalar Conceição (Porto Alegre, RS)**
**Nível de interesse:** nacional · saúde pública · pandemia

### O dado
De 2015 a 2019: 92 processos instaurados, 8 expulsivas.
Em 2020–2021 (pandemia): **159 processos, 128 expulsivas** — 16x mais demissões em 2 anos.
Taxa de expulsivas: **54,6%** — maior entre todos os órgãos com mais de 100 processos.
Assunto dominante: **inassiduidade habitual e abandono de cargo** (112 ocorrências).

### A pauta
Servidores do único hospital federal do RS abandonaram o posto em massa nos anos mais críticos
da saúde pública brasileira. Quem foram? O que motivou o abandono — medo, falta de EPIs,
gestão caótica, ou os três? O GHC foi um dos hospitais que mais atendeu Covid grave no Sul.

### Apuração
1. Via CEAF: nomes e CPFs de quem foi demitido em 2020–2021 no GHC
2. Via DOU: portarias de demissão — todas são públicas e nominais
3. Entrevista: sindicato dos servidores de saúde do RS (SINDISPREV-RS)
4. Cruzar com dados de internações Covid no GHC (DATASUS/SIHSUS) no mesmo período

### Ângulo alternativo
Se os processos apontarem assédio moral ou conduta de conotação sexual (há ocorrências),
a pauta vira: "hospital federal investigou mais servidores por assédio do que por abandono".

### Queries de apuração
```sql
-- Nomes dos demitidos no GHC em 2020-2021 (após ingestão CEAF)
SELECT nome_punido, cargo_efetivo, tipo_punicao, data_publicacao, portaria
FROM ceaf_expulsoes
WHERE orgao_nome ILIKE '%Conceição%'
  AND data_publicacao BETWEEN '2020-01-01' AND '2021-12-31'
ORDER BY data_publicacao;

-- Assuntos dos processos do GHC
SELECT assuntos, COUNT(*) as n, SUM(n_expulsivas) as exp
FROM cgu_pad_processos
WHERE entidade ILIKE '%Conceição%'
GROUP BY assuntos ORDER BY n DESC;
```

---

## PAUTA 2 — "IBAMA: o desmonte tem data, e está nos processos disciplinares"
**Instituto Brasileiro do Meio Ambiente (nacional)**
**Nível de interesse:** nacional · meio ambiente · política

### O dado
IBAMA: 1.007 processos, 197 expulsivas (19,6% de taxa).
Pico histórico: **2006 (118 processos, 50 expulsivas)** — maior série anual.
Queda brusca: **2017 (20 processos)** — mínimo histórico pós-2004.
Anomalia: **2018 saltou para 21 expulsivas** com apenas 27 processos — taxa de 77%.
Assunto dominante: **recebimento de propina / utilização indevida de recursos públicos** (112 ocorrências).

### A pauta
A linha do tempo disciplinar do IBAMA é um mapa do desmonte institucional.
O pico de 2006 coincide com a Operação Curupira (PF) contra grilagem e tráfico de madeira.
A queda de 2017–2019 pode indicar menos fiscalização, menos irregularidades encontradas —
ou menos vontade política de instaurar processos.
A anomalia de 2018: poucos processos, alta taxa de expulsão. Foco cirúrgico? Ou expurgo?

### Apuração
1. Via CEAF: quem foi expulso do IBAMA em 2018 e por quê (cargo, UF, fundamento)
2. Cruzar série disciplinar com: (a) dados de desmatamento PRODES/INPE por ano,
   (b) gestões dos ministros do Meio Ambiente
3. Via DOU: portarias de demissão — identificar se são da mesma UF ou espalhadas
4. Entrevista: ex-auditores fiscais ambientais, ISA, IMAZON

### Queries de apuração
```sql
-- Série temporal completa IBAMA
SELECT
  EXTRACT(YEAR FROM data_instauracao)::int AS ano,
  COUNT(*) AS processos,
  SUM(n_expulsivas) AS expulsivas,
  ROUND(100.0 * SUM(n_expulsivas) / COUNT(*), 1) AS taxa_pct
FROM cgu_pad_processos
WHERE entidade ILIKE '%IBAMA%'
  OR entidade ILIKE '%Meio Ambiente e dos Recursos%'
GROUP BY ano ORDER BY ano;

-- Expulsões IBAMA 2018 com nome (após CEAF)
SELECT nome_punido, cargo_efetivo, uf_lotacao, portaria, fundamentacao
FROM ceaf_expulsoes
WHERE orgao_nome ILIKE '%IBAMA%'
  AND EXTRACT(YEAR FROM data_publicacao) = 2018;
```

---

## PAUTA 3 — "Banco da Amazônia: 38% de taxa de demissão, sem interrupção há 12 anos"
**Banco da Amazônia S.A. (PA, AM, RO, AC, RR, AP, TO)**
**Nível de interesse:** regional forte · nacional moderado · poder/dinheiro

### O dado
BASA: 375 processos, 71 expulsivas, **38,6% de taxa**.
Atividade disciplinar **ininterrupta de 2011 a 2022** (nunca menos de 10 processos/ano).
UFs de origem: concentradas no Pará e Amazonas (a confirmar com CEAF).
Assunto dominante: "irregularidades em regulamentos de empresa pública" (199 ocorrências) +
"recebimento de propina / utilização indevida de recursos" (14 ocorrências).

### A pauta
O Banco da Amazônia é o principal instrumento de crédito e financiamento de emendas
parlamentares na região Norte. Com 38,6% de taxa de demissão disciplinar e atividade
contínua há 12 anos, a pergunta é: o problema é estrutural ou os controles melhoraram
e passaram a pegar mais?

Cruzamento explosivo: quais parlamentares direcionaram emendas para beneficiários do BASA
no mesmo período em que o banco registrava mais irregularidades internas?

### Apuração
1. Via CEAF: nomes dos 71 expulsos — cargo, UF, tipo de punição
2. Via `emendas_favorecidos`: CNPJs que receberam emendas e têm conta/crédito no BASA
3. Via BASA (LAI se necessário): relatórios de auditoria interna 2015–2022
4. Entrevista: MPF-PA (procuradoria que mais atua em casos de fraude financeira na Amazônia)

### Queries de apuração
```sql
-- Série BASA
SELECT EXTRACT(YEAR FROM data_instauracao)::int AS ano,
       COUNT(*) AS processos, SUM(n_expulsivas) AS expulsivas
FROM cgu_pad_processos
WHERE entidade ILIKE '%Amazônia%'
GROUP BY ano ORDER BY ano;

-- Expulsos do BASA por UF (após CEAF)
SELECT uf_lotacao, COUNT(*) AS n, tipo_punicao
FROM ceaf_expulsoes
WHERE orgao_nome ILIKE '%Amazônia%'
GROUP BY uf_lotacao, tipo_punicao ORDER BY n DESC;
```

---

## PAUTA 4 — "INSS: 1.231 demissões disciplinares. A máquina que frauda também é punida — mas devagar"
**Instituto Nacional do Seguro Social (nacional)**
**Nível de interesse:** nacional máximo · previdência · fraude

### O dado
INSS: 4.753 processos, 1.231 expulsivas (25,9% de taxa) — maior volume absoluto do país.
Pico histórico: **2007–2008** (345 e 278 processos/ano).
Assunto dominante: **concessão irregular de benefícios** (em linha com fraudes previdenciárias).
Nota: os dados do CGU-PAD para INSS no banco parecem incompletos (paginação da API limitou).
Estimativa real: volume muito maior.

### A pauta
O INSS é o órgão mais investigado e o que mais demite disciplinarmente no Brasil.
Com os dados do CEAF, é possível mapear a distribuição geográfica das demissões —
quais agências do INSS concentram mais irregularidades?

O timing é perfeito: a CPI do INSS de 2025 expôs fraudes em benefícios.
Os dados disciplinares são a trilha histórica que antecedeu e documenta o problema.

### Apuração
1. Via CEAF: listar todos os expulsos do INSS por UF e ano — identificar clusters geográficos
2. Cruzar com: municípios com maior concentração de benefícios irregulares (auditoria AGU/CGU)
3. Via DOU: portarias de demissão por "concessão irregular" — há padrão de cargo? (técnico? perito médico?)
4. Entrevista: FENASPS (federação dos servidores da previdência), MPF

### Queries de apuração
```sql
-- Distribuição geográfica dos expulsos do INSS (após CEAF)
SELECT uf_lotacao, COUNT(*) AS expulsoes,
       COUNT(*) FILTER (WHERE cargo_efetivo ILIKE '%perito%') AS peritos,
       COUNT(*) FILTER (WHERE cargo_efetivo ILIKE '%técnico%') AS tecnicos
FROM ceaf_expulsoes
WHERE orgao_nome ILIKE '%Seguro Social%'
GROUP BY uf_lotacao ORDER BY expulsoes DESC;

-- Cruzar com assuntos de fraude
SELECT p.assuntos, COUNT(*) AS n
FROM cgu_pad_processos p
WHERE p.entidade ILIKE '%Seguro Social%'
  AND p.assuntos && ARRAY['Concessão irregular de benefícios']
GROUP BY p.assuntos ORDER BY n DESC;
```

---

## RELEASES PARA IMPRENSA

### Release Pauta 1 (GHC)
**PARA: editores de saúde / correspondentes no RS**

Hospital federal gaúcho registrou 16 vezes mais demissões disciplinares nos dois anos de pandemia
do que nos cinco anteriores somados, segundo dados do CGU-PAD obtidos pelo The BR Insider.
Em 2020–2021, o Grupo Hospitalar Conceição (GHC) — único hospital federal do Rio Grande do Sul
— instaurou 159 processos disciplinares contra servidores, resultando em 128 sanções expulsivas.
O motivo dominante: abandono de cargo no período de maior pressão sobre o sistema de saúde.
[Dados disponíveis para verificação. Contato: contato@thebrinsider.com]

### Release Pauta 2 (IBAMA)
**PARA: editores de meio ambiente / repórteres especializados**

Levantamento do The BR Insider no banco de dados disciplinares do governo federal revela
que o IBAMA atingiu seu mínimo histórico de processos instaurados em 2017 — mesmo ano
em que os índices de desmatamento na Amazônia começaram a subir. Os dados do CGU-PAD,
sistema da CGU com 90 mil registros desde 2003, mostram que o instituto passou de
118 processos em 2006 para apenas 20 em 2017, recuperando parcialmente em 2020.
[Dados disponíveis para verificação. Contato: contato@thebrinsider.com]

---

## THREADS PARA X/TWITTER

### Thread Pauta 1 — GHC
🧵 O hospital federal que mais demitiu durante a pandemia não está em SP ou RJ.

Fica em Porto Alegre.

E os números são perturbadores. [1/6]

---
O Grupo Hospitalar Conceição (RS) — único hospital federal gaúcho — registrou
**128 sanções expulsivas em 2020–2021**.

Nos 5 anos anteriores: apenas 8.

Aumento de **1.600%**. [2/6]

---
O motivo dominante nos processos: **abandono de cargo**.

Servidores deixaram o posto nos dois anos de maior pressão sobre o sistema de saúde do país.

Em plena pandemia de Covid. [3/6]

---
Como descobrimos? Com o CGU-PAD, banco de dados disciplinares do governo federal.

90.460 processos desde 2003.
5.949 órgãos com sanções expulsivas.

O GHC tem a maior taxa do país entre hospitais: 54,6% dos processos terminam em demissão. [4/6]

---
O próximo passo é cruzar com o CEAF (Cadastro de Expulsões) para ter os nomes.

Quem eram esses servidores? De quais cargos? Em quais unidades?

Os dados são públicos. Estamos apurando. [5/6]

---
Esse é o tipo de dado que o @thebrinsider existe para extrair.

Transparência não é só publicar planilha. É transformar 90k linhas numa pergunta que precisa de resposta.

Acompanhe a apuração. 🔗 [link] [6/6]

### Thread Pauta 2 — IBAMA
🧵 O desmonte do IBAMA não começa nos discursos políticos.

Começa nos números que ninguém olhou.

Os dados disciplinares do próprio governo revelam algo perturbador. [1/5]

---
Em 2006, o IBAMA instaurou **118 processos disciplinares** contra servidores.
A maioria: recebimento de propina e desvio de recursos.

Em 2017: **20 processos**. Mínimo histórico.

O mesmo ano em que o desmatamento voltou a subir. [2/5]

---
Isso pode significar duas coisas muito diferentes:

A) O IBAMA ficou mais limpo.
B) O IBAMA parou de investigar seus próprios servidores.

Os dados do CGU-PAD sozinhos não respondem. Mas fazem a pergunta certa. [3/5]

---
Anomalia de 2018: apenas 27 processos — mas **21 terminaram em demissão**.

Taxa de 77%. A maior da série histórica do órgão.

Quem foram? Por quê concentrou tantas demissões naquele ano? [4/5]

---
Resposta: cruzar com o CEAF (nomes dos demitidos) + portarias do DOU + dados do INPE.

É jornalismo de dados. Leva tempo. Mas os dados existem e são públicos.

@thebrinsider está apurando. [5/5]
