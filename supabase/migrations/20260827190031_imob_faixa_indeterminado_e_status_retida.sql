-- Subradar Imob — faixa 'indeterminado' e status 'retida'
-- Complemento de 20260827185611: os dois CHECKs restantes rejeitavam os
-- valores que a trava de completude precisa gravar.

-- Faixa de risco 'indeterminado': é o que sai quando alguma fonte não
-- respondeu. Sem ela o pipeline calculava a faixa e morria na gravação — o
-- primeiro run real terminou com HTTP 400 exatamente aqui.
alter table public.sub_imob_resultados
  drop constraint if exists sub_imob_resultados_faixa_risco_check;

alter table public.sub_imob_resultados
  add constraint sub_imob_resultados_faixa_risco_check
  check (faixa_risco in ('verde','amarelo','laranja','vermelho','indeterminado'));

-- Status 'retida': pipeline concluído, entrega segurada por laudo incompleto.
-- Sem esse valor a retenção não teria como ser registrada.
alter table public.sub_imob_consultas
  drop constraint if exists sub_imob_consultas_status_check;

alter table public.sub_imob_consultas
  add constraint sub_imob_consultas_status_check
  check (status in ('pendente','processando','concluido','retida','erro'));
