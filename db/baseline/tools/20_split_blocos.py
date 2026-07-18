#!/usr/bin/env python3
"""Canonicaliza o dump bruto em blocos ordenados e determinísticos.

Entrada: dump pg_dump schema-only (bruto). Saída: db/baseline/blocks/NN_*.sql
Normalizações: remove ALTER ... OWNER TO (uniformiza no role executor),
dedup de SETs no prelude, classificação por tipo com ordem interna preservada.
Statements são delimitados por ';' fora de aspas/dollar-quoting.
"""
import re
import sys
import hashlib

RAW = sys.argv[1]
OUT = sys.argv[2]

src = open(RAW, encoding="utf-8").read()

# --- tokenizador de statements (respeita $tag$..$tag$, '..', ".." e comentários) ---
stmts, buf, i, n = [], [], 0, len(src)
dollar = None
while i < n:
    ch = src[i]
    if dollar:
        if src.startswith(dollar, i):
            buf.append(dollar); i += len(dollar); dollar = None
        else:
            buf.append(ch); i += 1
        continue
    if ch == "$":
        m = re.match(r"\$[A-Za-z_0-9]*\$", src[i:])
        if m:
            dollar = m.group(0); buf.append(dollar); i += len(dollar); continue
    if ch == "'":
        j = i + 1
        while j < n:
            if src[j] == "'" and not (j + 1 < n and src[j + 1] == "'"):
                break
            j += 2 if src[j] == "'" else 1
        buf.append(src[i:j + 1]); i = j + 1; continue
    if ch == '"':
        j = src.index('"', i + 1)
        buf.append(src[i:j + 1]); i = j + 1; continue
    if src.startswith("--", i):
        j = src.find("\n", i)
        j = n if j == -1 else j
        buf.append(src[i:j]); i = j; continue
    if ch == ";":
        buf.append(";")
        stmts.append("".join(buf).strip()); buf = []
        i += 1; continue
    buf.append(ch); i += 1
tail = "".join(buf).strip()
if tail:
    stmts.append(tail)

BLOCKS = {
    "00_prelude": [], "02_schemas": [], "03_types_domains": [],
    "04_sequences": [], "05_tables": [], "06_constraints": [],
    "07_functions": [], "08_views": [], "09_materialized_views": [],
    "10_indexes": [], "11_triggers": [], "12_rls": [], "13_policies": [],
    "14_comments": [], "15_grants": [], "16_default_privileges": [],
    "99_unclassified": [],
}
owners_removed = 0

def head(s):
    # primeira linha útil sem comentários
    for line in s.splitlines():
        t = line.strip()
        if t and not t.startswith("--"):
            return t.upper()
    return ""

for s in stmts:
    h = head(s)
    if not h:
        continue
    if re.match(r"ALTER (TABLE|SCHEMA|VIEW|MATERIALIZED VIEW|FUNCTION|SEQUENCE|TYPE|DOMAIN).* OWNER TO ", h):
        owners_removed += 1
        continue
    if h.startswith("SET ") or h.startswith("SELECT PG_CATALOG.SET_CONFIG"):
        if s not in BLOCKS["00_prelude"]:
            BLOCKS["00_prelude"].append(s)
    elif h.startswith("CREATE SCHEMA"):
        BLOCKS["02_schemas"].append(s)
    elif h.startswith(("CREATE TYPE", "CREATE DOMAIN", "ALTER TYPE", "ALTER DOMAIN")):
        BLOCKS["03_types_domains"].append(s)
    elif h.startswith("CREATE SEQUENCE"):
        BLOCKS["04_sequences"].append(s)
    elif h.startswith("ALTER SEQUENCE") and " OWNED BY " in h:
        BLOCKS["06_constraints"].append(s)   # pós-tabelas por dependência
    elif h.startswith("ALTER SEQUENCE"):
        BLOCKS["04_sequences"].append(s)
    elif h.startswith("CREATE TABLE") or h.startswith("CREATE UNLOGGED TABLE"):
        BLOCKS["05_tables"].append(s)
    elif h.startswith("ALTER TABLE") and (" ADD CONSTRAINT" in s.upper() or " ATTACH PARTITION" in h):
        BLOCKS["06_constraints"].append(s)
    elif h.startswith("ALTER TABLE") and ("SET DEFAULT" in h or "ALTER COLUMN" in h):
        BLOCKS["05_tables"].append(s)
    elif h.startswith("ALTER TABLE") and ("ROW LEVEL SECURITY" in h):
        BLOCKS["12_rls"].append(s)
    elif h.startswith(("CREATE FUNCTION", "CREATE OR REPLACE FUNCTION", "CREATE PROCEDURE", "CREATE AGGREGATE")):
        BLOCKS["07_functions"].append(s)
    elif h.startswith("CREATE MATERIALIZED VIEW"):
        BLOCKS["09_materialized_views"].append(s)
    elif h.startswith(("CREATE VIEW", "CREATE OR REPLACE VIEW")):
        BLOCKS["08_views"].append(s)
    elif h.startswith(("CREATE INDEX", "CREATE UNIQUE INDEX")):
        BLOCKS["10_indexes"].append(s)
    elif h.startswith(("CREATE TRIGGER", "CREATE OR REPLACE TRIGGER", "CREATE CONSTRAINT TRIGGER")):
        BLOCKS["11_triggers"].append(s)
    elif h.startswith("CREATE POLICY") or h.startswith("ALTER POLICY"):
        BLOCKS["13_policies"].append(s)
    elif h.startswith("COMMENT ON"):
        BLOCKS["14_comments"].append(s)
    elif h.startswith("ALTER DEFAULT PRIVILEGES"):
        BLOCKS["16_default_privileges"].append(s)
    elif h.startswith(("GRANT ", "REVOKE ")):
        BLOCKS["15_grants"].append(s)
    else:
        BLOCKS["99_unclassified"].append(s)

import os
os.makedirs(OUT, exist_ok=True)
for name, items in BLOCKS.items():
    if name == "99_unclassified" and not items:
        continue
    with open(os.path.join(OUT, name + ".sql"), "w", encoding="utf-8") as f:
        f.write(f"-- bloco {name} — gerado por split_baseline.py (ordem interna = ordem do dump)\n")
        f.write("\n\n".join(items) + ("\n" if items else ""))
print(f"statements={len(stmts)} owners_removidos={owners_removed}")
for name, items in BLOCKS.items():
    print(f"{name}={len(items)}")
sha = hashlib.sha256(src.encode()).hexdigest()
print(f"sha256_dump_bruto={sha}")
