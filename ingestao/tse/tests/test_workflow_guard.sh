#!/usr/bin/env bash
# Teste da guarda de contenção emergencial do workflow ingest-tse.yml.
# Reproduz exatamente a lógica do step "Guarda de segurança" e verifica que:
#   - receitas / despesas / todos  -> BLOQUEIA (exit 1)
#   - candidatos                   -> LIBERA  (exit 0)
#   - qualquer outro               -> BLOQUEIA (exit 1)
#
# Uso: bash ingestao/tse/tests/test_workflow_guard.sh
set -u

guard() {
  # Cópia fiel do case do workflow. Recebe o dataset em $1.
  local DATASET="$1"
  case "$DATASET" in
    receitas|despesas|todos)
      return 1
      ;;
    candidatos)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

fail=0
assert_block() {
  guard "$1"
  if [ $? -eq 0 ]; then echo "FALHOU: '$1' deveria BLOQUEAR mas passou"; fail=1;
  else echo "ok: '$1' bloqueado"; fi
}
assert_allow() {
  guard "$1"
  if [ $? -ne 0 ]; then echo "FALHOU: '$1' deveria LIBERAR mas bloqueou"; fail=1;
  else echo "ok: '$1' liberado"; fi
}

assert_block receitas
assert_block despesas
assert_block todos
assert_block ""            # default vazio cai no '*' -> bloqueia (seguro)
assert_block lixo
assert_allow candidatos

if [ $fail -eq 0 ]; then
  echo "TODOS OS TESTES DE GUARDA PASSARAM"
  exit 0
else
  echo "HÁ FALHAS NA GUARDA"
  exit 1
fi
