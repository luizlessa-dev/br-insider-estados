-- bloco 17_hardening — pós-baseline: NÃO preservar grants perigosos TSE
-- (espelha db/migrations/0047; aplicado por último, sobrepõe o bloco 15).
revoke insert, update, delete, truncate, references, trigger
  on table public.tse_receitas from anon, authenticated;
revoke insert, update, delete, truncate, references, trigger
  on table public.tse_despesas from anon, authenticated;
revoke usage, update on sequence public.tse_receitas_id_seq from anon, authenticated;
revoke usage, update on sequence public.tse_despesas_id_seq from anon, authenticated;
