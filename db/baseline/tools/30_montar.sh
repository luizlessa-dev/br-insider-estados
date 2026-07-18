#!/usr/bin/env bash
# Monta o baseline canonicalizado a partir dos blocos (ordem numérica fixa).
# Uso: ./30_montar.sh <dir_blocks> <arquivo_saida.sql>
set -euo pipefail
B="${1:?uso: 30_montar.sh <dir_blocks> <saida.sql>}"; OUT="${2:?}"
cat "$B"/00_prelude.sql "$B"/01_extensions.sql "$B"/02_schemas.sql \
    "$B"/03_types_domains.sql "$B"/04_sequences.sql "$B"/05_tables.sql \
    "$B"/06_constraints.sql "$B"/07_functions.sql "$B"/08_views_e_matviews.sql \
    "$B"/10_indexes.sql "$B"/11_triggers.sql "$B"/12_rls.sql "$B"/13_policies.sql \
    "$B"/14_comments.sql "$B"/15_grants.sql "$B"/16_default_privileges.sql \
    "$B"/17_hardening.sql > "$OUT"
shasum -a 256 "$OUT"
