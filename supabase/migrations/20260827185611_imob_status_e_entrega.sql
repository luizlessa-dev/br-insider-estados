-- Subradar Imob — vocabulário de status e trava de entrega
--
-- Contexto: a auditoria de 27/08/2026 encontrou o pipeline Imob afirmando
-- "nada consta" sem ter consultado nada. A correção depende de separar três
-- casos que antes viravam a mesma coisa (seção ausente):
--
--   pendente        a fonte deveria responder e não respondeu  -> retém entrega
--   nao_aplicavel   a fonte não cobre este caso concreto
--   nao_contratada  a fonte não está contratada/implementada   -> lacuna declarada
--
-- 'nao_contratada' é novo e o CHECK atual o rejeitaria, derrubando toda a
-- gravação do laudo.
alter table public.sub_imob_dados
  drop constraint if exists sub_imob_dados_status_check;

alter table public.sub_imob_dados
  add constraint sub_imob_dados_status_check
  check (status in ('limpo','alerta','critico','pendente',
                    'nao_aplicavel','nao_contratada','erro'));

-- Trava de completude: mesmo desenho já em produção no Subradar PF.
-- entrega_bloqueio guarda por que o laudo não foi enviado; entregue_em marca
-- o envio efetivo. Sem essas colunas não há como distinguir "não entregue
-- ainda" de "retido por laudo incompleto".
alter table public.sub_imob_consultas
  add column if not exists entrega_bloqueio text,
  add column if not exists entregue_em timestamptz;

comment on column public.sub_imob_consultas.entrega_bloqueio is
  'Motivo pelo qual a entrega foi retida (fonte pendente, falha no envio). NULL = sem bloqueio.';
comment on column public.sub_imob_consultas.entregue_em is
  'Quando o dossiê foi efetivamente enviado ao cliente.';
