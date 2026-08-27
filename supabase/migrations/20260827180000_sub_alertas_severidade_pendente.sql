-- Subradar PJ — libera a severidade "pendente" em sub_alertas.
--
-- Motivo: até aqui um conector que não conseguia consultar a fonte devolvia
-- lista vazia, e lista vazia virava ausência de risco no dossiê. Não havia como
-- registrar "não consegui consultar" — só "consultei e não achei" (severidade
-- "ok") ou nada. A auditoria de 27/08/2026 encontrou 22 fontes nessa situação.
--
-- "pendente" registra a falha de consulta como um fato do dossiê: aparece para
-- o cliente, mas não pontua no score (ausência de resposta não é ausência de
-- registro, e também não é evidência de risco).

ALTER TABLE sub_alertas DROP CONSTRAINT IF EXISTS sub_alertas_severidade_check;

ALTER TABLE sub_alertas ADD CONSTRAINT sub_alertas_severidade_check
  CHECK (severidade = ANY (ARRAY['critico'::text, 'atencao'::text, 'ok'::text,
                                 'info'::text, 'pendente'::text]));

COMMENT ON COLUMN sub_alertas.severidade IS
  'critico | atencao | ok | info | pendente. "ok" = fonte consultada com sucesso, '
  'nada encontrado. "pendente" = não foi possível consultar a fonte (erro HTTP, '
  'credencial ausente, endpoint fora do ar). Nem "ok" nem "pendente" pontuam no score.';
