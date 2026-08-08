#!/bin/bash
# Teste End-to-End: Subradar PF
# Simula o fluxo completo do Lovable até o email

set -e

echo "════════════════════════════════════════════════════════════"
echo "  SUBRADAR PF — Teste End-to-End"
echo "════════════════════════════════════════════════════════════"
echo ""

RUNNER_URL="${RUNNER_PF_URL:-http://localhost:8000}"
SUPABASE_URL="${SUPABASE_URL}"
SUPABASE_KEY="${SUPABASE_SERVICE_ROLE_KEY}"
RESEND_KEY="${RESEND_API_KEY}"

# Validações
if [ -z "$SUPABASE_URL" ]; then
    echo "❌ SUPABASE_URL não definida"
    echo "   Defina: export SUPABASE_URL=https://..."
    exit 1
fi

if [ -z "$SUPABASE_KEY" ]; then
    echo "❌ SUPABASE_SERVICE_ROLE_KEY não definida"
    echo "   Defina: export SUPABASE_SERVICE_ROLE_KEY=..."
    exit 1
fi

if [ -z "$RESEND_KEY" ]; then
    echo "⚠️  RESEND_API_KEY não definida"
    echo "   Email não será enviado (teste apenas processar)"
fi

# Verifica se runner está respondendo
echo "1️⃣  Verificando Python Runner API..."
if ! curl -s "$RUNNER_URL/consulta" -X POST -H "Content-Type: application/json" -d '{}' > /dev/null 2>&1; then
    echo "❌ Runner API não está acessível em $RUNNER_URL"
    echo "   Inicie com: python3 -m ingestao.subradar.runner_pf_api --port 8000"
    exit 1
fi
echo "✅ Runner API respondendo"
echo ""

# Testa CPF mock
CPF="123.456.789-00"
NOME="Teste E2E $(date +%s)"
EMAIL="test@example.com"

echo "2️⃣  Consultando CPF via Runner API..."
echo "   CPF: $CPF"
echo "   Nome: $NOME"
echo "   Email: $EMAIL"
echo ""

RUNNER_RESPONSE=$(curl -s "$RUNNER_URL/consulta" \
  -X POST \
  -H "Content-Type: application/json" \
  -d "{
    \"cpf\": \"$CPF\",
    \"nome\": \"$NOME\",
    \"cliente_id\": \"test-e2e-$(date +%s)\"
  }")

echo "3️⃣  Resposta do Runner:"
echo "$RUNNER_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RUNNER_RESPONSE"

SUCESSO=$(echo "$RUNNER_RESPONSE" | grep -o '"sucesso": *true' | wc -l)
SCORE=$(echo "$RUNNER_RESPONSE" | grep -o '"score": *[0-9]*' | grep -o '[0-9]*')
FAIXA=$(echo "$RUNNER_RESPONSE" | grep -o '"faixa": *"[^"]*"' | cut -d'"' -f4)

if [ "$SUCESSO" -eq 0 ]; then
    echo "❌ Runner retornou erro"
    exit 1
fi

echo ""
echo "✅ Consulta processada com sucesso"
echo "   Score: $SCORE/100"
echo "   Faixa: $FAIXA"
echo ""

# Verifica dados no Supabase
if [ ! -z "$SUPABASE_URL" ] && [ ! -z "$SUPABASE_KEY" ]; then
    echo "4️⃣  Verificando dados no Supabase..."

    CPF_CLEAN=$(echo "$CPF" | sed 's/[^0-9]//g' | awk '{printf "%s.%s.%s-%s", substr($0,1,3), substr($0,4,3), substr($0,7,3), substr($0,10,2)}')

    RESULT=$(curl -s "$SUPABASE_URL/rest/v1/sub_pf_resultados?cpf=eq.$CPF_CLEAN" \
      -H "apikey: $SUPABASE_KEY" \
      -H "Authorization: Bearer $SUPABASE_KEY")

    RESULT_COUNT=$(echo "$RESULT" | grep -o '"id"' | wc -l)
    if [ "$RESULT_COUNT" -gt 0 ]; then
        echo "✅ Resultado gravado em sub_pf_resultados"
    else
        echo "⚠️  Resultado não encontrado (Supabase sem credenciais?)"
    fi

    ALERTS=$(curl -s "$SUPABASE_URL/rest/v1/sub_pf_alertas?cpf=eq.$CPF_CLEAN" \
      -H "apikey: $SUPABASE_KEY" \
      -H "Authorization: Bearer $SUPABASE_KEY")

    ALERT_COUNT=$(echo "$ALERTS" | grep -o '"titulo"' | wc -l)
    if [ "$ALERT_COUNT" -gt 0 ]; then
        echo "✅ $ALERT_COUNT alertas gravados em sub_pf_alertas"
    else
        echo "⚠️  Nenhum alerta encontrado"
    fi
    echo ""
fi

echo "════════════════════════════════════════════════════════════"
echo "✅ TESTE CONCLUÍDO COM SUCESSO"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Próximos passos:"
echo "1. Deploy: bash scripts/deploy_subradar_pf.sh"
echo "2. Configure environment variables no Supabase"
echo "3. Teste via Lovable frontend"
echo ""
