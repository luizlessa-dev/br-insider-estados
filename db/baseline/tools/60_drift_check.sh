#!/usr/bin/env bash
# drift-check: prova determinística de que a migration materializada em
# supabase/migrations/ é EXATAMENTE o que os 17 blocos produzem hoje.
#
# Reusa 30_montar.sh sem duplicar a lógica de concatenação. Não sobrescreve a
# migration versionada — monta em arquivo temporário e compara byte a byte.
# Sem rede, sem banco, sem Docker — só leitura de arquivos locais. Funciona
# idêntico local e em CI.
#
# Uso: ./60_drift_check.sh (a partir de db/baseline/)
# Override opcional (não usado por padrão): DRIFT_CHECK_MIGRATION=<caminho>
set -euo pipefail
cd "$(dirname "$0")/.."   # db/baseline/

MIGRATION="${DRIFT_CHECK_MIGRATION:-../../supabase/migrations/20260718000000_baseline.sql}"

if [ ! -f "$MIGRATION" ]; then
  echo "FALHA: migration versionada não encontrada em $MIGRATION"
  exit 1
fi

TMP=$(mktemp -t drift-check-XXXXXX.sql)
cleanup() { rm -f "$TMP"; }
trap cleanup EXIT

./tools/30_montar.sh blocks "$TMP" >/dev/null

if cmp -s "$MIGRATION" "$TMP"; then
  echo "drift-check: OK — migration versionada idêntica aos 17 blocos ($(shasum -a 256 "$MIGRATION" | cut -c1-16)…)"
  exit 0
else
  echo "drift-check: DRIFT DETECTADO entre os blocos e a migration versionada"
  echo "  versionada ($MIGRATION):"
  shasum -a 256 "$MIGRATION"
  wc -c "$MIGRATION"
  echo "  gerada agora dos blocos:"
  shasum -a 256 "$TMP"
  wc -c "$TMP"
  echo "  primeira diferença:"
  cmp "$MIGRATION" "$TMP" || true
  exit 1
fi
