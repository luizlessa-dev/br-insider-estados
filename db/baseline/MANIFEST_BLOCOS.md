# Manifesto dos blocos do baseline canonicalizado

Ordem de aplicação = ordem numérica. Checksums SHA-256 (16 hex iniciais).

| # | Arquivo | Classe de objeto | Depende de | Stmts | SHA-256 (16) |
|---|---------|------------------|------------|-------|--------------|
| 00_prelude | blocks/00_prelude.sql | SETs de sessão pg_dump | — | 12 | `77e6ad879d45a126` |
| 01_extensions | blocks/01_extensions.sql | extensões (cria schemas cron/net) | 00 | 12 | `123ed81523b301d3` |
| 02_schemas | blocks/02_schemas.sql | schemas de aplicação | 00 | 7 | `eb8b2bac82f44ea8` |
| 03_types_domains | blocks/03_types_domains.sql | types/domains | 02 | 6 | `433b042261775a21` |
| 04_sequences | blocks/04_sequences.sql | sequences | 02 | 86 | `471970c282980a88` |
| 05_tables | blocks/05_tables.sql | tabelas (+col defaults) | 01,02,03,04 | 456 | `f6073a48ef4ff5e3` |
| 06_constraints | blocks/06_constraints.sql | PK/UNIQUE/CHECK/FK + seq OWNED BY | 05 | 699 | `cb43a8ac914aca64` |
| 07_functions | blocks/07_functions.sql | funções/procedures | 05 | 156 | `ae25eab7695f0a0b` |
| 08_views_e_matviews | blocks/08_views_e_matviews.sql | views+MVs COMBINADAS (deps bidirecionais; ordem pg_dump) | 05,06,07 | 193 | `25c1a55921d59203` |
| 10_indexes | blocks/10_indexes.sql | índices não-constraint | 05,08,01(pg_trgm) | 785 | `5da0c88e3ea342c4` |
| 11_triggers | blocks/11_triggers.sql | triggers | 05,07 | 3 | `14d13a4f5778a065` |
| 12_rls | blocks/12_rls.sql | ENABLE RLS | 05 | 224 | `3fcd0feb2541d93d` |
| 13_policies | blocks/13_policies.sql | policies | 12,07 | 165 | `20a478247799a9b9` |
| 14_comments | blocks/14_comments.sql | comments | 05,08 | 188 | `0d3d50f00a4341e2` |
| 15_grants | blocks/15_grants.sql | grants (fiel a produção) | 05,08 | 1892 | `e9830202f2f9d4f1` |
| 16_default_privileges | blocks/16_default_privileges.sql | default ACLs (fiel; decisão A/B pendente) | 02 | 12 | `03477512ceecdde5` |
| 17_hardening | blocks/17_hardening.sql | hardening TSE (espelha 0047, corrigido na PROVA 1B: inclui REVOKE MAINTAIN) | 15 | 5 | `b6392349ceb94b1b` |
