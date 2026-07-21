-- bloco 17_hardening — pós-baseline: NÃO preservar grants perigosos TSE
-- (espelha db/migrations/0047; aplicado por último, sobrepõe o bloco 15).
--
-- Correção PROVA 1B (2026-07-19): faltava REVOKE MAINTAIN, presente em 0047
-- desde o commit 3791b59 (mergeado em main via d308f9a antes deste bloco ter
-- sido escrito) — omissão de transcrição manual, achado pela PROVA 1.
revoke insert, update, delete, truncate, references, trigger
  on table public.tse_receitas from anon, authenticated;
revoke insert, update, delete, truncate, references, trigger
  on table public.tse_despesas from anon, authenticated;
revoke maintain
  on table public.tse_receitas, public.tse_despesas from anon, authenticated;
revoke usage, update on sequence public.tse_receitas_id_seq from anon, authenticated;
revoke usage, update on sequence public.tse_despesas_id_seq from anon, authenticated;
