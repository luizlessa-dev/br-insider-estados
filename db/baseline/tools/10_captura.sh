#!/usr/bin/env bash
# FERRAMENTA DE MANUTENÇÃO MANUAL — captura remota do dump schema-only.
#
# NÃO faz parte do baseline-verify (que é 100% local e nunca chama este
# script). Use apenas para RECAPTURAR o baseline após mudança autorizada de
# schema em produção.
#
# Segurança:
#   - conexão remota SOMENTE leitura, via supabase CLI autenticado/linkado
#     (credencial no keyring do CLI — nunca passa por aqui, nunca é impressa);
#   - exige confirmação explícita: BASELINE_CAPTURA_CONFIRMO=sim;
#   - exige destino explícito e RECUSA sobrescrever arquivo existente
#     (recapturas geram novo arquivo datado; snapshots são imutáveis).
#
# Uso:
#   BASELINE_CAPTURA_CONFIRMO=sim ./10_captura.sh snapshot/dump_bruto_YYYYMMDD.sql
set -euo pipefail

OUT="${1:?uso: BASELINE_CAPTURA_CONFIRMO=sim 10_captura.sh <arquivo_saida.sql>}"

if [ "${BASELINE_CAPTURA_CONFIRMO:-}" != "sim" ]; then
  echo "RECUSADO: captura remota exige BASELINE_CAPTURA_CONFIRMO=sim (ferramenta manual)." >&2
  exit 2
fi
if [ -e "$OUT" ]; then
  echo "RECUSADO: '$OUT' já existe — snapshots são imutáveis; use um novo nome datado." >&2
  exit 3
fi

SCHEMAS="public,public_api,analytics,bcb,cidadania_ai,homabrasil,portal_transparencia"
supabase db dump -f "$OUT" --schema "$SCHEMAS"
shasum -a 256 "$OUT"
