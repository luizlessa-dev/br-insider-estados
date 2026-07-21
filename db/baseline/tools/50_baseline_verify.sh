#!/usr/bin/env bash
# baseline-verify: prova local e SEM CONEXÃO REMOTA de que o baseline
# canonicalizado (1) aplica do zero, (2) contém o hardening TSE (inclusive
# MAINTAIN) e (3) produz exatamente os digests estruturais esperados.
# Retorna != 0 em divergência. Uso: ./50_baseline_verify.sh (a partir de db/baseline/)
#
# AMBIENTE CANÔNICO (correção PROVA 1B, 2026-07-19): usa o próprio Supabase
# CLI (supabase init/start/db reset) — o MESMO mecanismo que valida a
# linhagem padrão em supabase/migrations/. Antes, este script usava um
# container Docker ad-hoc cujo bootstrap introduzia grants extras em 14
# tabelas não-TSE (achado da PROVA 1: 10/11 digests batiam, mas
# `grants_tabelas` divergia do que o supabase db reset realmente produz).
# `tse_receitas`/`tse_despesas` nunca foram afetadas por essa contaminação
# específica, mas o oráculo de digests não podia continuar vindo de um
# ambiente diferente do real. Nenhum acesso remoto foi adicionado; o único
# tráfego de rede possível é o pull de imagem do próprio CLI, se ausente
# localmente (idêntico em espírito ao comportamento anterior).
set -euo pipefail
cd "$(dirname "$0")/.."   # db/baseline/

# Deslocamento de portas para reduzir colisão com outras stacks Supabase
# locais já em uso na máquina (ex.: outro projeto rodando via `supabase
# start`). Ajustável via BASELINE_VERIFY_PORT_OFFSET se colidir.
OFFSET="${BASELINE_VERIFY_PORT_OFFSET:-1500}"

TMPDIR=$(mktemp -d -t baseline-verify-XXXXXX)
cleanup() {
  (cd "$TMPDIR" 2>/dev/null && supabase stop --no-backup >/dev/null 2>&1) || true
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

# 0. monta o baseline a partir dos blocos versionados (ferramenta oficial)
./tools/30_montar.sh blocks "$TMPDIR/baseline.sql" >/dev/null

# 1. projeto Supabase CLI descartável e isolado (nome único via mktemp)
(cd "$TMPDIR" && supabase init --force --yes >/dev/null)
mkdir -p "$TMPDIR/supabase/migrations"
mv "$TMPDIR/baseline.sql" "$TMPDIR/supabase/migrations/99999999999999_baseline_verify.sql"

# desloca todas as portas de 5 dígitos do config.toml gerado (api/db/studio/
# inbucket/pooler) pelo mesmo OFFSET — evita colisão sem hardcodar portas.
awk -v off="$OFFSET" '
  /^port = [0-9]{5}$/ { split($0, a, " = "); print "port = " (a[2] + off); next }
  { print }
' "$TMPDIR/supabase/config.toml" > "$TMPDIR/supabase/config.toml.new"
mv "$TMPDIR/supabase/config.toml.new" "$TMPDIR/supabase/config.toml"

# 2. inicialização + reset via CLI (ambiente canônico)
(cd "$TMPDIR" && supabase start) > "$TMPDIR/start.log" 2>&1 \
  || { echo "FALHA: supabase start"; tail -10 "$TMPDIR/start.log"; exit 1; }

DB_PORT=$(awk '/^\[db\]$/{f=1} f && /^port = /{print $3; exit}' "$TMPDIR/supabase/config.toml")

(cd "$TMPDIR" && supabase db reset) > "$TMPDIR/reset.log" 2>&1 \
  || { echo "FALHA: supabase db reset"; tail -10 "$TMPDIR/reset.log"; exit 1; }
# Só falha em erro real do psql/Postgres ("ERROR:") ou ausência da linha de
# conclusão — NÃO em qualquer ocorrência textual de "error"/"fail": o CLI
# emite avisos benignos (ex. cache de catálogo de outro projeto local
# concorrente falhando por porta em uso) que contêm essas palavras sem
# indicar falha do reset em si. Achado desta correção (PROVA 1B): a checagem
# anterior (grep amplo) gerava falso positivo nessa situação.
grep -q "^ERROR:" "$TMPDIR/reset.log" \
  && { echo "FALHA: reset com erro"; tail -10 "$TMPDIR/reset.log"; exit 1; }
grep -q "Finished supabase db reset" "$TMPDIR/reset.log" \
  || { echo "FALHA: reset não confirmou conclusão"; tail -10 "$TMPDIR/reset.log"; exit 1; }

export PGPASSWORD=postgres

# 3. hardening TSE efetivo — inclui MAINTAIN explicitamente (achado da PROVA 1B:
#    a checagem anterior não cobria MAINTAIN e não teria detectado a regressão).
HARD=$(psql -h 127.0.0.1 -p "$DB_PORT" -U postgres -d postgres -Atc \
  "select bool_or(has_table_privilege(r,t,p))
     from unnest(array['anon','authenticated']) r
     cross join unnest(array['public.tse_receitas','public.tse_despesas']) t
     cross join unnest(array['INSERT','UPDATE','DELETE','TRUNCATE','REFERENCES','TRIGGER','MAINTAIN']) p")
[ "$HARD" = "f" ] || { echo "FALHA: hardening TSE ausente (inclui verificação de MAINTAIN)"; exit 1; }

# 4. digests estruturais == manifesto esperado
psql -h 127.0.0.1 -p "$DB_PORT" -U postgres -d postgres -At -F' ' \
  -f tools/40_digest_estrutural.sql | sort > "$TMPDIR/digests.txt"
if diff -u digests_esperados.txt "$TMPDIR/digests.txt"; then
  echo "baseline-verify: OK (aplicação limpa + hardening inclusive MAINTAIN + digests idênticos) [ambiente canônico: supabase db reset]"
else
  echo "baseline-verify: DIVERGÊNCIA nos digests"; exit 1
fi
