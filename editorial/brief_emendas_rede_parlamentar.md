# BRIEFING DE APURAÇÃO
## Rede de captura de emendas parlamentares — BR Insider
**Produzido em:** jun/2026
**Origem:** análise cruzada de 165k+ transações da base emendas_favorecidos × B3 × TSE

---

## CONTEXTO

A ingestão da lista de empresas listadas na B3 (3.436 CNPJs) abriu um cruzamento com a base de emendas parlamentares. O que começou como checagem de companhias abertas beneficiárias se expandiu para o mapeamento de quatro ecossistemas distintos de captura sistêmica de emendas — cada um com padrão, atores e mecanismo próprios.

**Total mapeado nesta investigação:** R$ 900M+ em transações com anomalias identificadas.

---

## ECOSSISTEMA 1 — MAQUINÁRIO ESTRANGEIRO
### Prioridade editorial: ALTA | Apuração: campo + LAI
### Status: **CAMADA ESTADUAL CONFIRMADA** (atualizado 2026-06-04)

### O dado — federal
- **XCMG Brasil Indústria Ltda** (Contagem/MG, capital chinês): **R$ 311,8M** de **66 autores**, 184 transações
- **Yanmar South America** (Indaiatuba/SP, capital japonês): **R$ 85,1M** de **58 parlamentares**, 70 emendas
- **Liugong Latin America** (dois CNPJs): **R$ 28,9M** de 17 autores
- **CNH Industrial Brasil** (Case/New Holland): **R$ 23,5M** de 10 autores
- **Total maquinário estrangeiro via emendas: ~R$ 449M**

### O dado — camada estadual MG (novo, 2026-06-04)
Cruzamento `mg_empenhos` × `emendas_favorecidos` revelou camada estadual da XCMG:
- **Secretaria de Agricultura MG:** R$ 19,5M — processo `1231021 000057/2025`
- **IDENE (Instituto de Desenvolvimento do Norte e Nordeste de MG):** R$ 5,5M — processo `2421020 000004/2022`
- **Total empenhos estaduais MG: R$ 25M** (3 empenhos, todos "Tratores, Similares e Implementos")
- **Exposição combinada em MG: ~R$ 336M** (federal + estadual)

### Mapa de autores federais XCMG — destaques
| Autor | Tipo | Total | Período |
|---|---|---|---|
| Bancada do RS | Bancada | **R$ 102M** | 2024–2025 |
| Bancada de PE | Bancada | R$ 32M | 2024–2025 |
| Com. Agricultura e Reforma Agrária | Comissão | R$ 29M | 2025–2026 |
| Bancada de SE | Bancada | R$ 17M | 2024–2025 |
| Bancada da BA | Bancada | R$ 16M | 2024–2025 |
| Com. Integração Nacional e Des. Regional | Comissão | R$ 13M | 2024–2025 |
| Roberta Roma (PL/BA) | Individual | R$ 3,2M | 2025 |
| Diego Coronel (PP/RS) | Individual | R$ 1,9M | 2024–2025 |
| Carlos Viana (Mobiliza/MG) | Individual | R$ 1,5M | 2024–2025 |
| Aécio Neves (PSDB/MG) | Individual | R$ 724k | 2024 |
| Sergio Moro (Podemos/PR) | Individual | R$ 680k | 2025 |
| Jaques Wagner (PT/BA) | Individual | R$ 622k | 2025 |
| Glauber Braga (PSOL/RJ) | Individual | R$ 90k | 2026 |

**Padrão transpartidário confirmado:** PT, PSOL, PL, PSDB, Podemos, Novo, PP — toda a câmara comprando o mesmo produto da mesma empresa chinesa.

**Anomalia bancada RS:** R$ 102M de uma única bancada estadual para uma fabricante de outro estado é concentração atípica. A bancada gaúcha sozinha responde por 1/3 de toda a receita federal da XCMG.

### O que torna anômalo
XCMG é a #1 receptora privada de emendas parlamentares de toda a base. R$ 311M de 66 autores diferentes — praticamente todas as bancadas estaduais + dezenas de individuais. É maior que qualquer hospital universitário, qualquer OSC, qualquer empresa de TI encontrada. É uma empresa de maquinário pesado chinês que capturou simultaneamente o canal federal de emendas e os contratos diretos do estado de MG.

### Perguntas para apuração
- Qual o objeto declarado de cada emenda destinada à XCMG? (Portal da Transparência)
- O processo `1231021 000057/2025` da Secretaria de Agricultura MG foi licitação competitiva ou contratação direta? As especificações técnicas excluíam concorrentes?
- Os equipamentos foram entregues e incorporados ao patrimônio público?
- Qual a relação entre a XCMG e os parlamentares com maior volume — cruzar com doações eleitorais TSE?
- Por que a Bancada do RS direcionou R$ 102M para uma empresa sediada em MG?
- Há restrição regulatória de compras de equipamentos chineses via emenda?

### LAI prioritária
**Destinatário:** Secretaria de Estado de Agricultura, Pecuária e Abastecimento de MG
**Processo:** `1231021 000057/2025`
**Solicitar:**
1. Edital completo da licitação/contratação
2. Ata de julgamento e relação de empresas que participaram/foram habilitadas
3. Termo de referência / especificações técnicas do objeto
4. Contrato assinado com a XCMG e eventuais aditivos
5. Notas de empenho e liquidação vinculadas ao processo

**Destinatário 2:** IDENE — processo `2421020 000004/2022`, mesmos documentos.

### CNPJs-chave
- XCMG Brasil: `14707364000110`
- Yanmar: `08263434000196`
- Liugong (CNPJs): `11260925000279` e `11260925000350`
- CNH Industrial: `01844555002398`

---

## ECOSSISTEMA 2 — FRACIONAMENTO 5G (Trindade/GO)
### Prioridade editorial: ALTA | Apuração: CNPJ + campo

### O dado
Dois CNPJs distintos com nomes similares, mesma cidade (Trindade/GO), recebendo da mesma bancada:
- **5G Energia, Comercial Importadora e Exportadora Ltda.** (`19983065000122`): **R$ 39,6M**
- **5G Comércio de Energia Solar, Importação e Exportação Ltda.** (`47149673000171`): **R$ 28,7M**
- **Total combinado: R$ 68,3M**

**PROVA DO FRACIONAMENTO:** A emenda `202571090001` (Bancada do ES, 2025) pagou **ambas as empresas simultaneamente** — R$ 12,878M para uma e R$ 12,300M para a outra. Mesma emenda, dois CNPJs, mesma cidade.

Bancadas financiadoras: Espírito Santo (dominante, R$ 55M+), Rondônia (R$ 10M), Maranhão (R$ 3,3M), Rio de Janeiro, Goiás, Mato Grosso.
Individuais: Vanderlan Cardoso (PL/GO), Tarcísio Motta (PSOL/RJ), Ivan Valente (PSOL/SP), Sâmia Bomfim (PSOL/SP).

### O que torna anômalo
Fracionamento entre CNPJs distintos é mecanismo clássico para: (a) contornar limites de habilitação, (b) diluir rastreabilidade, (c) distribuir risco jurídico. A prova da emenda compartilhada torna o caso diretamente questionável ao TCU sem necessidade de investigação adicional.

A Bancada do ES como maior financiadora (R$ 55M) é o fio principal — por que uma bancada de estado costeiro financia empresa de energia solar em Goiás?

### Perguntas para apuração
- Os sócios das duas 5Gs são os mesmos? (Junta Comercial de GO / CNPJ.ws)
- Qual o objeto declarado das emendas? (Portal da Transparência)
- A empresa tem estrutura real em Trindade/GO? (diligência in loco ou Google Street View)
- Há outros pares de CNPJs com mesmo padrão? (cruzar Junta Comercial)
- Quais deputados do ES compõem a bancada e qual a relação com Trindade?

---

## ECOSSISTEMA 3 — OSCs PRIVADAS DO RIO DE JANEIRO
### Prioridade editorial: ALTA (nomes conhecidos) | Apuração: campo + Junta Comercial

### 3A — Cluster esportivo (centro-direita)
Sete parlamentares financiam **Pró Esporte e Bem Viver simultaneamente** — R$ 81,8M total:

| Parlamentar | Partido | Total |
|---|---|---|
| Bancada do RJ | — | R$ 29,4M |
| Hugo Leal | PSD/RJ | R$ 11,4M |
| Romário | PL/RJ | R$ 9,75M |
| Sostenes Cavalcante | PL/RJ | R$ 8,5M |
| Marcos Tavares | PSD/RJ | R$ 8,4M |
| Sargento Portugal | PSD/RJ | R$ 7,3M |
| Bebeto | SD/RJ | R$ 7M |

Romário, Bebeto e Marcos Tavares são ex-jogadores de futebol com mandato parlamentar.

**CNPJs:** Pró Esporte `09328864000101` | Bem Viver `18685340000169`

### 3B — Instituto Taiwan (Itaperuna/RJ)
**R$ 38M de 10 autores** para instituto em cidade de 100 mil habitantes no Norte Fluminense. Cross-partisan (conservadores + Dimas Gadelha/PT). Maior receptor privado regional.

**CNPJ:** `13105238000123`

### 3C — Comissão de Esporte → Chaya (R$ 16,5M)
Uma comissão parlamentar elegeu sistematicamente o Instituto Servir e Qualificar Chaya como maior beneficiário individual (4 aparições, R$ 16,5M). Padrão incomum para distribuição de comissão.

**CNPJ Chaya:** `05952128000179`

### 3D — IBCAS em Roraima (R$ 22,7M de uma emenda)
Bancada de Roraima → Instituto Brasileiro de Cidadania e Ação Social (Boa Vista/RR): R$ 22,7M de **uma única emenda**. Máxima concentração em OSC obscura.

**CNPJ:** `07026157000135`

### Perguntas para apuração (cluster esportivo)
- Quais os sócios/diretores de Pró Esporte e Bem Viver? (Cartório/Junta RJ)
- Há conexão societária entre as duas organizações?
- O que foi entregue com os R$ 81,8M? Existe prestação de contas no SICONV?
- Existe relação entre os sócios das OSCs e os escritórios dos parlamentares?

---

## ECOSSISTEMA 4 — SAÚDE/UFRJ (PT/PSOL)
### Prioridade editorial: MÉDIA-ALTA | Apuração: LAI + campo universitário

### O dado
Três deputados do PSOL/RJ direcionam 40-45% de seus orçamentos individuais de emendas para o ecossistema FIOTEC/UFRJ:

| Parlamentar | % no ecossistema | Total |
|---|---|---|
| Tarcísio Motta (PSOL/RJ) | **44,7%** | R$ 23,2M |
| Pastor Henrique Vieira (PSOL/RJ) | **42,4%** | R$ 24,9M |
| Erika Kokay (PT/DF) | **40,1%** | R$ 24,7M |

**Lindbergh Farias (PT/RJ)** — senador — destaca-se por concentrar:
- FIOTEC: R$ 20,7M (fundação UFRJ)
- Instituto BR Arte (Fortaleza/CE): R$ 11M ← **senador do RJ mandando R$ 11M para Ceará**
- SOFTEX (Brasília/DF): R$ 6M
- **Total mapeado: R$ 37,9M = 44,2% do portfólio**

O mecanismo: emendas vão para fundações UFRJ (FIOTEC, COPPETEC, Fundação José Bonifácio), que então contratam empresas de TI/saúde como Tamandaré Informática e Datamed.

**CNPJs:** FIOTEC `02385669000174` | Tamandaré `00162720000153` | Datamed `38658399000175`

### Perguntas para apuração
- FIOTEC publicou prestação de contas das emendas? (LAI direto à UFRJ)
- Qual a relação de Tamandaré com o ecossistema REHUF/hospitais universitários?
- O Instituto BR Arte tem conexão com a base política de Lindbergh no Ceará?
- Por que PSOL/PSOL concentra 40%+ em uma única fundação?

---

## ECOSSISTEMA 5 — IRREGULARIDADES FORMAIS
### Prioridade editorial: ALTA (acionável juridicamente)

### 26 empresas em recuperação judicial receberam emendas
Total: ~R$ 23M. Empresas inelegíveis por lei recebendo recursos públicos federais.

**Maiores casos:**
| Empresa | UF | Total | Autores |
|---|---|---|---|
| Tratormaster (BA + SE) | BA/SE | **R$ 8,74M** | Bancada BA + Bancada SE + Arthur Oliveira Maia |
| Fibracampo Produtos de Fibra | MS | R$ 4,6M | 8 autores (Bancada BA, etc.) |
| FATEC em Recuperação Judicial | RS | R$ 3,95M | 7 autores (Hamilton Mourão, Melchionna, Maria do Rosário) |
| ProvAC Terceirização | SP | R$ 2,18M | Bancada RJ + Sâmia Bomfim + Luiza Erundina |
| Eletrodata Engenharia (em recovery) | BA | R$ 350k | Luiza Erundina + Reimont + Sâmia Bomfim |

**Nota:** A emenda de Luiza Erundina inclui **duas** empresas em recuperação judicial (ProvAC + Eletrodata) no mesmo instrumento. Isso é irregularidade documentável sem necessidade de apuração adicional.

**Tratormaster** (CNPJs `02745179000131` e `02745179000212`) é o caso mais grave: R$ 8,74M de duas bancadas estaduais diferentes para a mesma empresa em dois estados — padrão que sugere coordenação entre as bancadas da Bahia e de Sergipe.

**Ação sugerida:** LAI ao TCU/CGU solicitando posição sobre habilitação dessas empresas + notificação ao Ministério Público Federal.

---

## ECOSSISTEMA 6 — OUTROS ACHADOS RELEVANTES

### Avante Brasil Eventos (Brasília/DF) — R$ 21,5M da Bancada do DF
Empresa de eventos e capacitação recebendo R$ 21,5M de bancada estadual. Emenda `202471080005`.
**CNPJ:** `02948952000185` (a confirmar)

### Distribuidora Cummins Minas (BH) — R$ 21M da Comissão de Agricultura
Emenda `202560120002`. A Comissão de Agricultura comprou R$ 21M de motores/geradores de uma distribuidora mineira.

### FAIFCE/Enerugi Engenharia (Brasília/DF) — R$ 28M da Bancada de Rondônia
Fundação de apoio ao IF do Ceará (R$ 23,9M) + Enerugi Engenharia (R$ 4,2M) recebendo da Bancada de Rondônia. Três estados sem conexão.

### Dani Cunha + Federação de Motociclismo RJ — R$ 4,3M
Deputada federal (UB/RJ) mandando R$ 4,3M para federação estadual de motociclismo.

---

## ROTEIRO DE APURAÇÃO RECOMENDADO

### Semana 1 — fontes abertas
- [ ] CNPJ.ws: sócios das duas 5Gs, XCMG, Avante Brasil, Instituto Taiwan, OSCs do cluster esportivo
- [ ] Portal da Transparência: objetos das emendas XCMG, 5G, Avante Brasil
- [ ] Comprasnet/PNCP: contratos das empresas mapeadas com órgãos públicos
- [ ] SICONV/Plataforma +Brasil: prestação de contas das OSCs

### Semana 2 — LAI e institucional
- [ ] LAI → UFRJ: contratos FIOTEC com Tamandaré e Datamed
- [ ] LAI → CGU: habilitação das 26 empresas em recovery
- [ ] LAI → MEC: empenhos REHUF para Tamandaré via hospitais universitários
- [ ] Contato com TCU: verificar se há TC aberto sobre XCMG ou 5G

### Semana 3 — fontes humanas
- [ ] Especialistas em controle público (professor de direito administrativo)
- [ ] Ex-assessores parlamentares (off the record) sobre mecânica das emendas de bancada
- [ ] Contraditório: assessorias dos parlamentares mapeados (Tarcísio Motta, Pastor Henrique Vieira, Romário, Lindbergh Farias, Bancada ES)

---

## NOTAS METODOLÓGICAS

- Base: `emendas_favorecidos` — 165.216 transações 2024-2026 com CNPJ+UF+município, origem CGU/PorFavorecido.csv
- Período: pagamentos executados 2024–2026 (emendas de 2024 e 2025)
- Limitação: não inclui emendas anteriores a 2024; não inclui convênios sem CNPJ do favorecido
- Cruzamentos realizados: B3 empresas listadas, TSE contas partidárias 2023, recuperação judicial (busca textual)
- Todas as queries estão em `/Users/luizlessa/brasilia-insider/` e reproduzíveis

---

*Produzido pelo BR Insider — thebrinsider.com*
*Editor responsável: Luiz Lessa — luiz@thebrinsider.com*
