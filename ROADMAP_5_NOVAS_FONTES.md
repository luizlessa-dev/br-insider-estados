# Roadmap: 5 Novas Fontes — 3-4 Dias

## 📅 Timeline

```
DIA 1 (8 horas)
├─ CNPI (Banco Central)        — Gratuito, API pública
├─ CCF (Cheque Sem Fundo)      — Gratuito, API pública
└─ Alienação RENAJUD           — Gratuito, portal público

DIA 2 (8 horas)
├─ Cartório de Imóveis         — Cofiex API, pago ($5/consulta)
└─ Integração + Testes

DIA 3 (8 horas)
├─ SERASA Score                — API paga ($100-200/consulta)
└─ Scoring + Weighting

DIA 4 (4 horas)
├─ Testes E2E
├─ Documentação
└─ Deploy
```

---

## 🔧 Detalhamento por Fonte

### **DIA 1 — CNPI (Banco Central)**

**O que faz:**
- Consulta Cadastro de Inadimplentes de Pessoas Físicas
- Identifica caloteiros severos do Banco Central
- Gratuito e público

**API:**
- Endpoint: BC publica dados via FTP/HTTP
- Formato: XML/JSON
- Rate limit: Nenhum
- Autenticação: Nenhuma

**Implementação:**
- [ ] Criar `cnpi_pf.py`
- [ ] Parser de XML/JSON do BC
- [ ] Alertas: CRÍTICO se presente
- [ ] Teste com CPF real

**Arquivo:** `ingestao/subradar/cnpi_pf.py`

```python
class CNPIPFConnector:
    fonte = "cnpi_banco_central"
    
    def consultar_cpf(self, cpf: str, **kwargs):
        # Buscar em base CNPI do BC
        # Retornar alertas se encontrado
```

---

### **DIA 1 — CCF (Cheque Sem Fundo)**

**O que faz:**
- Consulta Base de Cheques Sem Fundo
- Banco Central mantém registro público
- Identifica fraude por cheque

**API:**
- Sistema: Banco Central disponibiliza via portal
- Formato: CSV/API
- Rate limit: Nenhum
- Autenticação: Nenhuma

**Implementação:**
- [ ] Criar `ccf_pf.py`
- [ ] Download/parse de base CCF
- [ ] Alertas: ATENÇÃO se presente
- [ ] Teste com CPF

**Arquivo:** `ingestao/subradar/ccf_pf.py`

```python
class CCFConnector:
    fonte = "ccf_cheque_sem_fundo"
    
    def consultar_cpf(self, cpf: str, **kwargs):
        # Buscar CPF em base de cheques sem fundo
        # Retornar alertas se encontrado
```

---

### **DIA 1 — Alienação RENAJUD**

**O que faz:**
- Consulta se veículo está alienado/penhorado
- RENAJUD = Registro Nacional de Automóveis Roubados
- Gratuito (portal Polícia Federal)

**API:**
- Sistema: Polícia Federal publica dados
- Formato: Web scraping ou API (precisa verificar)
- Rate limit: Moderado
- Autenticação: Nenhuma

**Implementação:**
- [ ] Criar `alienacao_renajud_pf.py`
- [ ] Integrar com banco de dados RENAJUD
- [ ] Alertas: ATENÇÃO se veículo penhorado
- [ ] Teste com placas conhecidas

**Arquivo:** `ingestao/subradar/alienacao_renajud_pf.py`

```python
class AlienacaoRENAJUDConnector:
    fonte = "alienacao_renajud"
    
    def consultar_cpf(self, cpf: str, **kwargs):
        # Buscar veículos alienados em nome de CPF
        # Retornar alertas se encontrado
```

---

### **DIA 2 — Cartório de Imóveis (Cofiex)**

**O que faz:**
- Consulta imóveis registrados em nome da pessoa
- Integra com Cartório Online via Cofiex
- OURO PURO para Imobiliária

**API:**
- Endpoint: Cofiex (privado, requer cadastro)
- Formato: JSON/SOAP
- Rate limit: 10 req/min
- Autenticação: Token + Certificado

**Implementação:**
- [ ] Criar `cartorio_imoveis_cofiex.py`
- [ ] Autenticação com Cofiex
- [ ] Parser de imóveis
- [ ] Alertas: INFO (listagem de bens)
- [ ] Teste com CNPJ/CPF

**Arquivo:** `ingestao/subradar/cartorio_imoveis_cofiex.py`

```python
class CartorioImoveisCofiexConnector:
    fonte = "cartorio_imoveis_cofiex"
    
    def consultar_cpf(self, cpf: str, **kwargs):
        # Buscar imóveis registrados em cartório
        # Retornar lista de bens imóveis
```

**Credenciais Necessárias:**
```
COFIEX_API_KEY=xxx
COFIEX_CERT_PATH=/path/to/cert.pem
```

---

### **DIA 3 — SERASA Score (API Paga)**

**O que faz:**
- Consulta Score de crédito oficial da Serasa
- Premium: Cobrar $100-200 por consulta
- Complementa nosso score proprietário

**API:**
- Endpoint: Serasa API (https://developers.serasa.com.br)
- Formato: JSON/REST
- Rate limit: 1000 req/dia
- Autenticação: OAuth2 + Bearer Token

**Implementação:**
- [ ] Criar `serasa_score_pf.py`
- [ ] Autenticação OAuth2
- [ ] Parser de score
- [ ] Alertas: Nenhum (apenas dados)
- [ ] Weighting com score proprietário

**Arquivo:** `ingestao/subradar/serasa_score_pf.py`

```python
class SerasaScorePFConnector:
    fonte = "serasa_score_oficial"
    
    def consultar_cpf(self, cpf: str, **kwargs):
        # Consultar score Serasa
        # Retornar score + faixa + análise
```

**Credenciais Necessárias:**
```
SERASA_CLIENT_ID=xxx
SERASA_CLIENT_SECRET=xxx
SERASA_API_KEY=xxx
```

**Custo:**
- $100-200 por consulta (passar para usuário)

---

## 🧪 Testes por Fonte

### CNPI
```bash
python3 -m ingestao.subradar.cnpi_pf --cpf 123.456.789-00
# Esperado: Sem alertas (CPF mock)
```

### CCF
```bash
python3 -m ingestao.subradar.ccf_pf --cpf 123.456.789-00
# Esperado: Sem alertas
```

### Alienação
```bash
python3 -m ingestao.subradar.alienacao_renajud_pf --cpf 123.456.789-00
# Esperado: Sem alertas
```

### Cartório
```bash
python3 -m ingestao.subradar.cartorio_imoveis_cofiex --cpf 123.456.789-00
# Esperado: "Nenhum imóvel encontrado" ou lista vazia
```

### SERASA
```bash
python3 -m ingestao.subradar.serasa_score_pf --cpf 123.456.789-00
# Esperado: Score Serasa + Faixa
```

---

## 📊 Integração ao Runner

### Adicionar ao runner_pf_consumer.py

```python
from .cnpi_pf import CNPIPFConnector
from .ccf_pf import CCFConnector
from .alienacao_renajud_pf import AlienacaoRENAJUDConnector
from .cartorio_imoveis_cofiex import CartorioImoveisCofiexConnector
from .serasa_score_pf import SerasaScorePFConnector

FONTES_PF_CONSUMER_EXTENDED = FONTES_PF_CONSUMER + [
    CNPIPFConnector(),
    CCFConnector(),
    AlienacaoRENAJUDConnector(),
    CartorioImoveisCofiexConnector(),
    SerasaScorePFConnector(),
]
```

---

## 📈 Novo Scoring com SERASA

### Weighting Algorithm

```python
def calcular_score_com_serasa(alertas, serasa_score):
    """
    Combina score proprietário + Serasa oficial
    
    Score Final = (Score_Proprietario * 0.6) + (Serasa_Score * 0.4)
    
    Exemplo:
      Score_Proprietario = 25
      Serasa_Score = 300 (Serasa usa escala 0-1000)
      Serasa_Normalizado = 300/1000 * 100 = 30
      Score_Final = (25 * 0.6) + (30 * 0.4) = 15 + 12 = 27/100
    """
```

---

## 💰 Pricing Strategy

### Consumer (Gratuito)
- CNPI ✅
- CCF ✅
- Alienação ✅
- Cartório ❌ (Cofiex cobra)
- SERASA ❌ (Premium)

### Enterprise (Pago)
- CNPI ✅
- CCF ✅
- Alienação ✅
- Cartório ✅ ($5 + nossa margem)
- SERASA ✅ ($100-200 + nossa margem)

---

## 📝 Documentação a Criar

- [ ] NOVAS_FONTES_INTEGRACAO.md
- [ ] API_CREDENCIAIS.md
- [ ] SCORING_SERASA_INTEGRATION.md
- [ ] PRICING_NOVAS_FONTES.md

---

## ✅ Checklist Final

### Dia 1
- [ ] CNPI implementada
- [ ] CCF implementada
- [ ] Alienação implementada
- [ ] Testes básicos

### Dia 2
- [ ] Cartório implementada
- [ ] Autenticação Cofiex
- [ ] Testes cartório
- [ ] Integração ao runner

### Dia 3
- [ ] SERASA implementada
- [ ] Autenticação OAuth2
- [ ] Weighting algorithm
- [ ] Scoring normalizado

### Dia 4
- [ ] Testes E2E completo (com 5 fontes)
- [ ] Documentação
- [ ] Deploy em staging
- [ ] Validação final

---

## 🎯 Expected Outcome

**Novo Sistema:**
- ✅ 25 fontes → 30 fontes (20% mais cobertura)
- ✅ Score proprietário + Score Serasa oficial
- ✅ Patrimonial (imóveis) + Crédito real
- ✅ Capacidade de faturar $100-200/consulta premium

**Pricing:**
- Consumer: $0 (gratuito)
- Enterprise: +$105-205/consulta (5 novas fontes)

**ROI:**
- 100-500 consultasumas/mês × $150 = $15-75K/mês extra

---

Bora começar? 🚀
