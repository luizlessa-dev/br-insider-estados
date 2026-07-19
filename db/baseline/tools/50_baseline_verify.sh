#!/usr/bin/env bash
# baseline-verify: prova local e SEM CONEXÃO REMOTA de que o baseline
# canonicalizado (1) aplica do zero, (2) contém o hardening TSE e (3) produz
# exatamente os digests estruturais esperados. Retorna != 0 em divergência.
# Uso: ./50_baseline_verify.sh   (a partir de db/baseline/)
set -euo pipefail
cd "$(dirname "$0")/.."
IMG="${BASELINE_IMAGE:-public.ecr.aws/supabase/postgres:17.6.1.063}"
CT="baseline-verify-$$"
cleanup() { docker rm -f "$CT" >/dev/null 2>&1 || true; }
trap cleanup EXIT

./tools/30_montar.sh blocks /tmp/baseline_verify_$$.sql >/dev/null
docker run -d --name "$CT" -e POSTGRES_PASSWORD=postgres "$IMG" >/dev/null
# A imagem Supabase REINICIA o Postgres durante o bootstrap; um único
# pg_isready pode passar na primeira subida e a conexão cair no restart.
# Exigimos 5 sondas OK consecutivas (com select 1) espaçadas de 2s.
ok=0
for i in $(seq 1 90); do
  if docker exec "$CT" psql -U postgres -Atc 'select 1' >/dev/null 2>&1; then
    ok=$((ok+1)); [ "$ok" -ge 5 ] && break
  else
    ok=0
  fi
  sleep 2
done
[ "$ok" -ge 5 ] || { echo "FALHA: Postgres não estabilizou"; exit 1; }
# 1. aplica do zero (db postgres recém-provisionado = ambiente fiel de branch)
docker exec -i "$CT" psql -U postgres -d postgres -v ON_ERROR_STOP=1 -f - \
  < /tmp/baseline_verify_$$.sql > /tmp/baseline_verify_$$.log 2>&1 \
  || { echo "FALHA: aplicação abortou"; tail -5 /tmp/baseline_verify_$$.log; exit 1; }
# 2. hardening TSE efetivo (o bloco 17 é parte do baseline aplicado acima)
docker exec "$CT" psql -U postgres -d postgres -Atc \
  "select has_table_privilege('anon','public.tse_receitas','TRUNCATE') or
          has_table_privilege('anon','public.tse_receitas','INSERT') or
          has_table_privilege('authenticated','public.tse_despesas','TRUNCATE')" \
  | grep -qx f || { echo "FALHA: hardening TSE ausente"; exit 1; }
# 3. digests estruturais == manifesto esperado
docker exec -i "$CT" psql -U postgres -d postgres -At -F' ' \
  < tools/40_digest_estrutural.sql | sort > /tmp/baseline_verify_$$.digests
if diff -u digests_esperados.txt /tmp/baseline_verify_$$.digests; then
  echo "baseline-verify: OK (aplicação limpa + hardening + digests idênticos)"
else
  echo "baseline-verify: DIVERGÊNCIA nos digests"; exit 1
fi
rm -f /tmp/baseline_verify_$$.sql /tmp/baseline_verify_$$.log /tmp/baseline_verify_$$.digests
