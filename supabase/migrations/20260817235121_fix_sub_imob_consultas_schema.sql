-- ============================================================================
-- Subradar Imob — corrige drift de schema em sub_imob_consultas
-- ============================================================================
-- app/api/imob/submit/route.ts (subradar-web) grava session_id e
-- proprietario_cpf_cnpj desde a criação do endpoint, mas essas colunas nunca
-- existiam na tabela — todo insert falhava com 42703 (column does not exist).
-- cliente_id era uuid not null sem nenhuma FK e sem default; o código
-- inseria o literal 'system' (não é UUID válido), gerando 22P02 no mesmo
-- insert. Confirmado via teste em transação com ROLLBACK, tabela com 0
-- linhas (nenhum pedido real chegou a persistir).
--
-- O runner (ingestao/subradar/runner_imob.py) usa "cliente_id" apenas como
-- nome de parâmetro para o próprio id da linha em sub_imob_consultas
-- (_buscar_proprietario_cpf_cnpj faz WHERE id = cliente_id) — não é uma FK
-- para um cliente separado, mesmo padrão do fluxo self-serve de
-- sub_pf_consultas, que não tem coluna cliente_id nenhuma.

alter table sub_imob_consultas
  add column session_id text,
  add column proprietario_cpf_cnpj text;

alter table sub_imob_consultas
  alter column cliente_id drop not null;
