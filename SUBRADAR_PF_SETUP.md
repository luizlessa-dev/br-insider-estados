# Subradar PF — Setup Completo

## Arquitetura

```
Lovable Frontend (dossie-maker.lovable.app)
    ↓
    POST /dossiee_process (Supabase Edge Function)
    ↓
    HTTP localhost:8000/consulta (Python Runner API)
    ↓
    Runner PF (29 conectores)
    ↓
    Supabase (sub_pf_resultados + sub_pf_alertas)
    ↓
    POST /dossiee (Supabase Edge Function)
    ↓
    PDF + Email (Resend)
```

## Setup — 3 Passos

### 1️⃣ Inicie o Python Runner API

```bash
cd /Users/luizlessa/brasilia-insider
python3 -m ingestao.subradar.runner_pf_api --port 8000
```

**Output esperado:**
```
2026-08-08 12:34:56 [INFO] subradar.runner_pf_api: Servidor Subradar PF API escutando em http://127.0.0.1:8000
2026-08-08 12:34:56 [INFO] subradar.runner_pf_api: Endpoint: POST /consulta
```

### 2️⃣ Deploy Edge Functions

```bash
# Deploy dossiee_process
supabase functions deploy dossiee_process --no-verify-jwt

# Deploy dossiee (já existente)
supabase functions deploy dossiee --no-verify-jwt
```

### 3️⃣ Configure Environment Variables

No Supabase Dashboard → Edge Functions → dossiee_process, defina:

```
RUNNER_PF_URL=http://localhost:8000
DOSSIEE_URL=https://[YOUR-PROJECT].supabase.co/functions/v1/dossiee
SUPABASE_URL=https://[YOUR-PROJECT].supabase.co
SUPABASE_SERVICE_ROLE_KEY=[SUA-CHAVE]
RESEND_API_KEY=[SUA-CHAVE-RESEND]
```

## Fluxo End-to-End

### Usuário submete CPF via Lovable

```javascript
// Lovable frontend (React)
const response = await fetch('https://[PROJECT].supabase.co/functions/v1/dossiee_process', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    cpf: '123.456.789-00',
    nome: 'João Silva',
    email: 'joao@email.com'
  })
});
```

### Edge Function dossiee_process

1. Recebe CPF + nome + email
2. Chama Python runner via HTTP (localhost:8000/consulta)
3. Runner executa 29 conectores
4. Popula `sub_pf_resultados` com score 0-100 e faixa
5. Popula `sub_pf_alertas` com ocorrências encontradas
6. Chama `/dossiee` para gerar PDF + enviar email
7. Retorna sucesso ao frontend

### Scoring Proprietário (já implementado)

Score 0-100 baseado em:
- **Pesos**: crítico=30 pts, atenção=10 pts, info=2 pts
- **Bônus**: +10 judicial, +10 internacional, +5 CGU
- **Faixas**:
  - 0–20: VERDE (sem risco)
  - 21–50: AMARELO (atenção)
  - 51–80: LARANJA (risco elevado)
  - 81–100: VERMELHO (crítico)

### Alertas Inteligentes (já estruturados)

Cada alerta tem:
- `titulo` — descrição breve
- `descricao` — detalhamento
- `severidade` — critico | atencao | info
- `fonte` — nome do conector
- `categoria` — judicial, sanções, crédito, etc

## Testes

### Teste dry-run (sem gravar)

```bash
python3 -m ingestao.subradar.runner_pf --cpf 123.456.789-00 --dry-run
```

### Teste com dados reais

```bash
python3 -m ingestao.subradar.runner_pf \
  --cpf 123.456.789-00 \
  --nome "João Silva" \
  --cliente-id "00000000-0000-0000-0000-000000000000"
```

### Teste API HTTP

```bash
curl -X POST http://localhost:8000/consulta \
  -H "Content-Type: application/json" \
  -d '{
    "cpf": "123.456.789-00",
    "nome": "João Silva",
    "cliente_id": "00000000-0000-0000-0000-000000000000"
  }'
```

## Troubleshooting

### Python runner retorna erro

1. Verificar se conectores têm credenciais corretas (APIs externas)
2. Rodar com `--dry-run` para testar localmente
3. Verificar logs no Supabase → Edge Functions

### Edge Function timeout

1. Aumentar timeout no `supabase.json`
2. Considerar rodar runner de forma assíncrona (job queue)

### PDF não anexado

1. Verificar formato base64 em `sub_pf_resultados`
2. Confirmar que Resend API key está válida
3. Verificar domínio verificado no Resend

## Próximos Passos

- [ ] Job queue assíncrona (para não bloquear Edge Function)
- [ ] Webhooks para notificar frontend quando pronto
- [ ] Cache de resultados (não re-consultar em 24h)
- [ ] Dashboard de monitoramento (% de sucesso, tempo médio)
- [ ] Integração com pagamento Stripe

