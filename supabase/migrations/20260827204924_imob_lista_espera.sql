-- Subradar Imob descontinuado como produto pago em 27/08/2026.
-- A venda parou porque, sem contrato ONR, a unica fonte que responde consulta o
-- CPF/CNPJ do proprietario — o que PF e PJ ja fazem. A matricula era coletada e
-- nao usada por nenhuma fonte.
-- Esta tabela troca o funil de compra por um sinal de demanda, que nunca
-- existiu: o formulario antigo rejeitava toda matricula valida e o disparo caia
-- em 404, entao "zero pedidos" nao media interesse nenhum.
create table if not exists public.sub_imob_lista_espera (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  perfil text,
  observacao text,
  origem text default 'site',
  created_at timestamptz default now(),
  unique (email)
);

alter table public.sub_imob_lista_espera enable row level security;

-- Sem policy: so a service_role (usada pela rota do servidor) escreve.
-- Cliente anonimo nao le nem grava direto.

comment on table public.sub_imob_lista_espera is
  'Interessados no Subradar Imob enquanto o produto esta descontinuado. Sinal de demanda para decidir sobre o contrato ONR.';
