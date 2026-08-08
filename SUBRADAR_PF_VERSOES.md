# Subradar PF — Duas Versões

## 📊 Comparação

### **Versão Enterprise** (runner_pf.py)
- **Público**: B2B — Empresas / Agências
- **Fontes**: 36 conectores (inclui intermediários)
- **Cobertura**: 100% + redundância
- **Dados**: Primários + secundários + enriquecimento
- **Custo**: Maior (múltiplas APIs pagas)
- **Velocidade**: ~30s (paralelo, muitas APIs)
- **Cobertura Negativações**: BigDataCorp Quod, Score, Financeiro, Protestos
- **Integração**: Para B2B, agências, consultórios jurídicos

### **Versão Consumer** (runner_pf_consumer.py) ✨ NOVO
- **Público**: B2C — Consumidor Final / Indivíduo
- **Fontes**: 20 conectores (apenas APIs oficiais diretas)
- **Cobertura**: Compilado, sem intermediários
- **Dados**: Apenas dados primários oficiais
- **Custo**: Menor (gratuito + RFB + CGU + Oficiais)
- **Velocidade**: ~15s (mais rápido)
- **Cobertura Negativações**: Apenas PGFN (dívida ativa)
- **Integração**: Para consumidor, imobiliárias, RH

---

## 🔍 Fontes por Versão

### Consumer (20 — Apenas Oficiais Diretas)

```
CADASTRAL (2):
  • CPF Situação (RFB) ✅
  • QSA Reverso (RFB) ✅

JUDICIAL (3):
  • BNMP/CNJ ✅
  • CNDT/TST ✅
  • Escavador ✅

ELEITORAL (1):
  • TSE ✅

CONSELHOS (3):
  • CREA/CONFEA ✅
  • CAU-BR ✅
  • CFC ✅

SANÇÕES (5):
  • CEPIM ✅
  • CEIS ✅
  • CNEP ✅
  • Lista Suja MTE ✅
  • PGFN ✅

DIÁRIOS (2):
  • DOU ✅
  • DOE (SP/MG/RJ) ✅

TRIBUNAIS (2):
  • TCE (SP/MG/RJ) ✅
  • CVM ✅

MÍDIA (1):
  • GDELT (Mídia Adversa) ✅

INTERNACIONAL (6):
  • OFAC ✅
  • UK Sanctions ✅
  • EU Sanctions ✅
  • ONU ✅
  • Banco Mundial ✅
  • OpenSanctions Pro (400+) ✅

TOTAL: 20 fontes oficiais
```

### Enterprise (36 — Inclui Intermediários)

```
(TUDO ACIMA) + 16 intermediários:

  + Infosimples:
    • Antecedentes Criminais ✅
    • Processos TRF/TRT ✅
    • DETRAN ✅
    • Conselhos (CRO/CRF/CFM/CFMV/CFP/CFBM/COREN) ✅

  + BigDataCorp:
    • Polícia Federal (antecedentes) ✅
    • Polícia Civil (antecedentes) ✅
    • Negativações (Quod) ✅
    • Processos Judiciais ✅
    • Dados Financeiros ✅

  + DirectData:
    • Protestos Nacionais ✅

  + Implanta:
    • Conselhos Profissionais ✅

TOTAL: 36 fontes (primárias + secundárias)
```

---

## 💰 Custo Comparado

### Consumer (20 fontes)

| Item | Custo | Observação |
|------|-------|-----------|
| RFB (CPF + QSA) | Gratuito | APIs públicas |
| BNMP/CNJ | Gratuito | API pública |
| CNDT/TST | Gratuito | API pública |
| Escavador | $5-50/mês | Plano básico B2C |
| TSE/CEPIM/CEIS/etc | Gratuito | APIs públicas CGU |
| DOU/DOE | Gratuito | Diários oficiais |
| GDELT | Gratuito | Janela 90 dias |
| Sanções Internacionais | Gratuito | APIs públicas + OpenSanctions |
| **TOTAL MENSAL** | **~$5-50** | **Escalável** |

### Enterprise (36 fontes)

| Item | Custo | Observação |
|------|-------|-----------|
| Consumer (acima) | ~$5-50 | Base |
| Infosimples | $500-2000/mês | Múltiplos conectores |
| BigDataCorp | $2000-5000/mês | Score + Negativações |
| DirectData | $500-1000/mês | Protestos |
| Implanta | $300-500/mês | Conselhos redundante |
| **TOTAL MENSAL** | **~$3000-8000** | **Infraestrutura B2B** |

---

## 🎯 Quando Usar Cada Uma

### Usar **Consumer** quando:
- ✅ Vender para consumidor individual
- ✅ Imobiliária checando locatário
- ✅ RH consultando candidato
- ✅ Credenciamento de MEI/autônomo
- ✅ Want lower cost + faster queries
- ✅ Dados suficientes para decisão

### Usar **Enterprise** quando:
- ✅ Agência de compliance / due diligence
- ✅ Consultório jurídico
- ✅ Banco / Fintech
- ✅ Auditor externo
- ✅ Precisa máxima cobertura + redundância
- ✅ Dispõe de orçamento B2B

---

## 📝 Implementação Consumer

### Usar runner_pf_consumer.py

```python
from ingestao.subradar.runner_pf_consumer import processar_cpf

alertas = processar_cpf(
    cpf="123.456.789-00",
    cliente_id="consumer-001",
    nome="João Silva",
    dry_run=True,
)
```

### Output (Idêntico, mas de 20 fontes)

```json
{
  "sucesso": true,
  "score": 25,
  "faixa": "AMARELO",
  "total_alertas": 5,
  "criticos": 0,
  "atencao": 1,
  "fontes_consultadas": 20
}
```

### Integração com Edge Function

```typescript
// Usar mesmo dossiee_process, mas chamar runner_pf_consumer
// Basta mudar import:
// from .runner_pf_consumer import processar_cpf
```

---

## 🚀 Roadmap

```
Hoje:
  ✅ Consumer (20 fontes) — Pronto
  ✅ Enterprise (36 fontes) — Pronto

Próximo:
  □ Switchear automaticamente Consumer/Enterprise por plano
  □ Consumer: Lovable frontend
  □ Enterprise: Dashboard B2B customizado
  □ Billing integrado (por consulta)
```

---

## ✨ Resumo

**Consumer**: Solução enxuta, rápida e barata para B2C  
**Enterprise**: Solução completa, redundante para B2B  
**Mesmo código**: Diferem apenas na lista de conectores  
**Mesmo scoring**: Algoritmo proprietário idêntico

---

Qual versão quer usar como padrão no Lovable? **Consumer** ou **Enterprise**?
