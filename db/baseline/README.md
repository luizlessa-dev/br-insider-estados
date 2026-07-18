# Baseline reproduzível do schema (CANDIDATO)

**Status: CANDIDATO versionado. NÃO é o baseline ativo. NÃO foi registrado em
`supabase_migrations.schema_migrations`. Nenhuma migration foi aplicada em
produção a partir deste pacote.**

Reconstrução determinística e verificável dos 7 schemas de aplicação de
produção (`public, public_api, analytics, bcb, cidadania_ai, homabrasil,
portal_transparencia`), capturada em 2026-07-18 (`BASELINE_CUTOFF=
20260718000000`). Motivação: o histórico remoto (23 migrations) não é
autossuficiente — o replay de branch Supabase falha em banco vazio
(`MIGRATIONS_FAILED`, diagnóstico de 2026-07-18). Este pacote é o insumo do
futuro registro formal de baseline.

## Conteúdo

| Item | Descrição |
|---|---|
| `BASELINE_METADATA.md` | proveniência, cutoff, 23 migrations absorvidas, decisões |
| `MANIFEST_BLOCOS.md` | os 17 blocos: ordem, classe, dependências, checksums |
| `blocks/` | DDL canonicalizado em 17 blocos ordenados |
| `digests_esperados.txt` | 11 digests estruturais canônicos (prova de equivalência) |
| `tools/` | scripts de captura (manual), split, montagem, digest e verificação |
| `snapshot/` (fora do Git) | dump bruto imutável, sha256 `2f28c841…` — ver metadata |

## Verificação local (sem nenhuma conexão remota)

```bash
cd db/baseline && ./tools/50_baseline_verify.sh
```

Sobe um Postgres descartável na imagem de produção
(`supabase/postgres:17.6.1.063`), aplica os 17 blocos na ordem do manifesto,
valida o hardening TSE e compara os 11 digests estruturais com
`digests_esperados.txt`. Sai com código ≠ 0 em qualquer divergência e remove o
container em sucesso ou falha. Requer apenas Docker.

`tools/10_captura.sh` é **ferramenta de manutenção manual** (recaptura remota,
somente leitura): exige `BASELINE_CAPTURA_CONFIRMO=sim`, recusa sobrescrever
snapshots e nunca é chamada pela verificação.

## Divergências conhecidas e intencionais

- `public.mg_remuneracao`: ordinais renumerados (produção tem 2 colunas
  dropadas na história; conteúdo idêntico). Não reproduzimos attnums de
  colunas removidas.
- Grants TSE: o bloco `17_hardening` remove os privilégios perigosos de
  `anon/authenticated` (espelha `db/migrations/0047`).
- Omitidos por design: jobs `pg_cron` (dados), valores correntes de sequences,
  Vault, schemas gerenciados (auth/storage/realtime), internals de extensões.
