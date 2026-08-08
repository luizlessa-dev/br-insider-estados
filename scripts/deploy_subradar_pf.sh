#!/bin/bash
# Deploy Subradar PF — Edge Functions
# Uso: ./scripts/deploy_subradar_pf.sh

set -e

echo "════════════════════════════════════════════════════════════"
echo "  SUBRADAR PF — Deploy Edge Functions"
echo "════════════════════════════════════════════════════════════"
echo ""

# Verifica se Supabase CLI está instalado
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI não encontrado. Instale com:"
    echo "   npm install -g supabase"
    exit 1
fi

# Deploy dossiee_process
echo "1️⃣  Deployando dossiee_process..."
supabase functions deploy dossiee_process --no-verify-jwt
if [ $? -eq 0 ]; then
    echo "✅ dossiee_process deployado com sucesso"
else
    echo "❌ Erro ao fazer deploy de dossiee_process"
    exit 1
fi

echo ""

# Deploy dossiee (PDF generator)
echo "2️⃣  Deployando dossiee..."
supabase functions deploy dossiee --no-verify-jwt
if [ $? -eq 0 ]; then
    echo "✅ dossiee deployado com sucesso"
else
    echo "❌ Erro ao fazer deploy de dossiee"
    exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ DEPLOY CONCLUÍDO COM SUCESSO"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Próximos passos:"
echo "1. Configure environment variables no Supabase Dashboard"
echo "2. Atualize Lovable frontend para chamar /dossiee_process"
echo "3. Teste o fluxo end-to-end"
echo ""
