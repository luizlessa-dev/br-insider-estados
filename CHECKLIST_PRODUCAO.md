# Subradar PF — Checklist Produção

## ✅ Componentes Implementados

- [x] **Runner PF** — 29 conectores + scoring 0-100
- [x] **Scoring Proprietário** — Algoritmo com faixas (VERDE/AMARELO/LARANJA/VERMELHO)
- [x] **Alertas Inteligentes** — Estrutura com severidade + categoria
- [x] **API HTTP** — Wrapper Python que expõe runner via HTTP
- [x] **Edge Function** — dossiee_process que coordena tudo
- [x] **Testes** — 3/3 testes passando ✅

## 🚀 Checklist — Siga em Ordem

### FASE 1: Setup Local (Você está aqui ⚡)

- [x] Python Runner API rodando em localhost:8000
  ```bash
  # Terminal 1
  cd /Users/luizlessa/brasilia-insider
  python3 -m ingestao.subradar.runner_pf_api --port 8000
  ```
  
- [ ] Confirmar que está respondendo
  ```bash
  curl -X POST http://localhost:8000/consulta \
    -H "Content-Type: application/json" \
    -d '{"cpf": "123.456.789-00", "nome": "Test", "cliente_id": "test"}'
  ```
  **Esperado**: `"sucesso": true, "score": 25, "faixa": "AMARELO"`

---

### FASE 2: Deploy Supabase (CLI)

- [ ] Verificar credenciais Supabase
  ```bash
  supabase projects list
  ```

- [ ] Deploy Edge Functions
  ```bash
  cd /Users/luizlessa/brasilia-insider
  chmod +x scripts/deploy_subradar_pf.sh
  bash scripts/deploy_subradar_pf.sh
  ```

- [ ] Verificar deploy
  ```bash
  supabase functions list
  # Deve listar: dossiee, dossiee_process
  ```

---

### FASE 3: Environment Variables (Supabase Dashboard)

Acesse: **Supabase Dashboard → Edge Functions → dossiee_process → Settings**

Defina:
```
RUNNER_PF_URL=http://localhost:8000
DOSSIEE_URL=https://[YOUR-PROJECT].supabase.co/functions/v1/dossiee
SUPABASE_URL=https://[YOUR-PROJECT].supabase.co
SUPABASE_SERVICE_ROLE_KEY=[COLE-SUA-CHAVE]
RESEND_API_KEY=[COLE-SUA-CHAVE-RESEND]
```

**Como pegar as chaves:**
- `SUPABASE_URL`: Dashboard → Settings → API → Project URL
- `SUPABASE_SERVICE_ROLE_KEY`: Dashboard → Settings → API → Service role key
- `RESEND_API_KEY`: https://resend.com/api-keys

---

### FASE 4: Atualizar Lovable Frontend

**No Lovable project editor:**

1. Encontre o código que chama `/dossiee`
2. Mude para chamar `/dossiee_process`

```javascript
// Antes (❌)
fetch('https://[PROJECT].supabase.co/functions/v1/dossiee', {
  method: 'POST',
  body: JSON.stringify({ cpf, nome, email, action: 'send' })
})

// Depois (✅)
fetch('https://[PROJECT].supabase.co/functions/v1/dossiee_process', {
  method: 'POST',
  body: JSON.stringify({ cpf, nome, email })
})
```

3. Atualize handling de resposta:

```javascript
// Esperado:
{
  "sucesso": true,
  "score": 25,
  "faixa": "AMARELO",
  "descricao": "Atenção — verificar contexto antes de contratar",
  "total_alertas": 5,
  "mensagem": "Consulta concluída e email enviado"
}
```

---

### FASE 5: Teste End-to-End

**Teste via Lovable Frontend:**

1. Abra: https://dossie-maker.lovable.app
2. Preencha:
   - CPF: 123.456.789-00
   - Nome: Teste Silva
   - Email: seu-email@example.com
3. Clique "Consultar"

**Esperado:**
- ✅ Score exibido (ex: 25/100)
- ✅ Faixa exibida (AMARELO)
- ✅ Email recebido em 30s com PDF anexado

**Se não funcionar:**
- [ ] Verificar logs no Supabase Dashboard → Functions → dossiee_process
- [ ] Verificar se Runner API está rodando em localhost:8000
- [ ] Verificar environment variables
- [ ] Verificar RESEND_API_KEY está válida

---

## 📊 Arquitetura Final

```
Lovable Frontend (dossie-maker.lovable.app)
    ↓
    POST /dossiee_process
    ↓
Edge Function (Supabase)
    ↓
HTTP localhost:8000/consulta (Python Runner API)
    ↓
Runner PF (29 conectores)
    ↓
Supabase Database
  ├─ sub_pf_resultados (score + faixa)
  └─ sub_pf_alertas (ocorrências)
    ↓
Edge Function /dossiee (PDF generator)
    ↓
Resend API (Email + PDF)
```

---

## 📋 Troubleshooting

### Runner API: `Connection refused on localhost:8000`
```bash
# Verifique se está rodando:
lsof -i :8000

# Se não estiver, inicie:
python3 -m ingestao.subradar.runner_pf_api --port 8000
```

### Edge Function timeout: `Error: Function execution timeout`
- Aumentar timeout no `supabase.json`
- Considerar rodar runner de forma assíncrona

### PDF não anexado ao email
- Verificar que Resend domain está verificado
- Verificar format base64 no Edge Function
- Testar via `/dossiee` diretamente

### Score sempre retorna 25
- Confirmar que runner está encontrando alertas
- Testar dry-run: `python3 -m ingestao.subradar.runner_pf --cpf 123.456.789-00 --dry-run`

---

## 🎯 Sucesso?

Se passou em tudo:
- [ ] Usuário submete CPF via Lovable
- [ ] Score + faixa exibidos em tempo real
- [ ] Email recebido com PDF estruturado em 30s
- [ ] PDF contém score, alertas, fontes consultadas

**Parabéns! 🎉 Subradar PF está em produção!**

---

## 📚 Documentação

- `SUBRADAR_PF_SETUP.md` — Setup técnico detalhado
- `LOVABLE_INTEGRATION.md` — Como integrar Lovable
- `.github/scripts/test_subradar_pf_integration.py` — Testes automatizados

