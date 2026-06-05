# Achado: Gilmar Mendes e a virada silenciosa nas ADIs

**Status:** rascunho para validação  
**Fonte primária:** STF Corte Aberta — decisões 2000–2026 (4.750 decisões em ADI, Gilmar Mendes)  
**Produzido por:** BR Insider  
**Data:** 2026-06-04  

---

## O achado em uma frase

Gilmar Mendes, que por 20 anos declarou inconstitucionais mais de 82% das leis contestadas em ADIs sob sua relatoria, caiu para 50% em 2026 — a menor taxa de sua carreira no STF.

---

## Os números

| Período | Taxa de procedência ADI | n |
|---|---|---|
| 2002–2022 (média) | **~84%** | ~640 decisões |
| 2023 | 71,8% | 78 |
| 2024 | 88,2% | 51 |
| 2025 | **67,3%** | 52 |
| 2026 (jan–jun) | **50,0%** | 36 |
| **Últimos 2 anos** | **72,1%** | ~139 |
| **Histórico total** | **82,4%** | 4.750 |

**Queda acumulada (histórico → últimos 2 anos): -10,3 pontos percentuais**

---

## Por que isso importa

Em ADIs, "procedência" significa que o STF declara a lei inconstitucional. Uma taxa de 82% histórica significa que Gilmar, como relator, votou para derrubar leis do Congresso na grande maioria dos casos em que foi sorteado relator.

A queda para 50% em 2026 — se confirmada ao final do ano — representaria uma inversão completa do seu padrão histórico: pela primeira vez, estaria deixando passar tantas leis quanto derrubando.

---

## Contexto e hipóteses a apurar

1. **Composição das ADIs mudou?** — ADIs com requerentes diferentes (oposição vs governo) têm perfis distintos. Checar se a composição dos requerentes mudou em 2025–2026 (dados em `controle_concentrado_legitimados.csv`).

2. **Lula nomeou Zanin (2023) e Dino (2023)** — ambos com taxas de procedência superiores a Gilmar (87,3% e 83,1%). Gilmar pode estar ajustando postura em corte mais progressista?

3. **ADIs contra medidas econômicas do governo Lula** — muitas ADIs recentes contestam medidas fiscais e trabalhistas. Gilmar historicamente próximo ao executivo em determinados temas.

4. **Contraprova:** comparar com outros ministros no mesmo período — Moraes estável (+0,4pp), Barroso ligeiramente menor (-4,9pp), Zanin estável (+0,2pp). **A queda de Gilmar é singular.**

---

## Comparativo 2025–2026 (ministros ativos)

| Ministro | Histórico | Últimos 2a | Variação |
|---|---|---|---|
| Cristiano Zanin | 87,3% | 87,5% | **+0,2pp** |
| Roberto Barroso | 86,7% | 81,8% | -4,9pp |
| Nunes Marques | 86,3% | 82,7% | -3,6pp |
| Flávio Dino | 83,1% | 83,2% | **+0,1pp** |
| **Gilmar Mendes** | **82,4%** | **72,1%** | **-10,3pp** |
| Alexandre de Moraes | 78,8% | 79,2% | +0,4pp |
| André Mendonça | 77,4% | 75,7% | -1,7pp |
| Edson Fachin | 80,5% | 78,2% | -2,3pp |
| Luiz Fux | 76,5% | 72,7% | -3,8pp |
| Dias Toffoli | 80,8% | 77,7% | -3,1pp |

---

## Ângulos de pauta

**Ângulo 1 — comportamental (mais publicável)**  
"Os dados mostram que Gilmar Mendes, nos primeiros 6 meses de 2026, rejeitou tantas ADIs quanto as que aceitou — uma inversão em relação ao padrão que manteve por duas décadas."

**Ângulo 2 — político (requer mais apuração)**  
"A mudança coincide com a chegada de dois ministros indicados por Lula com perfil mais ativista. Gilmar, que era o mais duro derrubador de leis, agora é o que mais as preserva entre os ministros com mandato na era Lula."

**Ângulo 3 — institucional**  
"Com Zanin e Dino votando acima de 83% de procedência, e Gilmar caindo para 72%, o STF vive uma inversão de papéis: o indicado de Lula é hoje mais propenso a derrubar leis do Congresso do que o histórico aliado."

---

## O que falta apurar antes de publicar

- [ ] Cruzar com `controle_concentrado_legitimados`: os requerentes das ADIs de Gilmar em 2025–2026 (partidos, governadores, confederações)
- [ ] Verificar quais legislações específicas Gilmar votou improcedente em 2025–2026
- [ ] Checar se a queda de 2023 (71,8%) foi um outlier ou início da tendência
- [ ] Ouvir constitucionalistas sobre o significado de 50% de procedência
- [ ] Pedido de comentário ao gabinete do ministro

---

## Metodologia

Fonte: STF Corte Aberta, dataset "Decisões" (2000–2026), ~1,8M linhas. Filtro: classe=ADI, ministro=Gilmar Mendes, resultado classificado como "favoravel" (inclui: procedente, procedente em parte, provido) ou "contrario" (inclui: improcedente, não provido, negado seguimento). Taxa = favoravel/(favoravel+contrario). Linhas sem resultado classificável excluídas do denominador. Total: 4.750 decisões de Gilmar em ADI com resultado classificável.

