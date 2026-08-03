-- ============================================================================
-- Subradar Imob Expansion — Pessoas, Transações e Dossiês
-- ============================================================================

-- Tabela de Pessoas Envolvidas (inquilinos, compradores, proprietários, agentes)
create table sub_imob_pessoas (
  id uuid primary key default gen_random_uuid(),
  
  -- Identificação
  tipo text not null check (tipo in ('inquilino', 'comprador', 'proprietario', 'agente')),
  cpf_cnpj text not null,
  nome text not null,
  
  -- Classificação
  categoria_risco text check (categoria_risco in ('baixo', 'medio', 'alto', 'critico', 'pendente')),
  score_risco integer check (score_risco between 0 and 100),
  
  -- Vinculação
  cliente_id uuid not null,
  
  -- Timestamps
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  
  unique(cpf_cnpj, cliente_id)
);

create index ix_sub_imob_pessoas_cpf_cnpj on sub_imob_pessoas(cpf_cnpj);
create index ix_sub_imob_pessoas_tipo on sub_imob_pessoas(tipo);
create index ix_sub_imob_pessoas_cliente on sub_imob_pessoas(cliente_id);

-- Tabela de Transações (histórico de operações)
create table sub_imob_transacoes (
  id uuid primary key default gen_random_uuid(),
  
  -- Identificação
  tipo text not null check (tipo in ('locacao', 'venda', 'transferencia')),
  status text check (status in ('ativa', 'finalizada', 'cancelada')),
  
  -- Participantes
  matricula text not null,
  proprietario_cpf_cnpj text,
  inquilino_cpf_cnpj text,
  comprador_cpf_cnpj text,
  agente_cpf_cnpj text,
  
  -- Detalhes Financeiros
  valor_contrato numeric(12,2),
  valor_aluguel numeric(12,2),
  data_inicio date,
  data_fim date,
  
  -- Dados da Transação
  fonte_dados text,  -- "sigilmovel", "manual", "importacao"
  url_fonte text,
  
  -- Vinculação
  cliente_id uuid not null,
  
  -- Timestamps
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

create index ix_sub_imob_transacoes_matricula on sub_imob_transacoes(matricula);
create index ix_sub_imob_transacoes_tipo on sub_imob_transacoes(tipo);
create index ix_sub_imob_transacoes_cliente on sub_imob_transacoes(cliente_id);
create index ix_sub_imob_transacoes_datas on sub_imob_transacoes(data_inicio, data_fim);

-- Tabela de Dossiês Consolidados (laudo final por tipo)
create table sub_imob_dossies (
  id uuid primary key default gen_random_uuid(),
  
  -- Identificação
  tipo text not null check (tipo in ('locacao', 'venda', 'proprietario', 'agente')),
  ciclo text not null,  -- YYYY-MM
  
  -- Participantes
  matricula text,
  cpf_cnpj_principal text,  -- inquilino, comprador, proprietário ou agente
  
  -- Score Consolidado
  score_risco integer check (score_risco between 0 and 100),
  faixa_risco text check (faixa_risco in ('verde', 'amarelo', 'laranja', 'vermelho')),
  
  -- Recomendação
  recomendacao text check (recomendacao in ('aprovado', 'condicional', 'rejeitado', 'pendente')),
  motivo_rejeicao text,
  
  -- Detalhes
  total_alertas integer default 0,
  alertas_criticos integer default 0,
  
  -- Payload completo (flexibilidade)
  detalhes jsonb,  -- { imovel: {...}, pessoa: {...}, transacao: {...} }
  
  -- Vinculação
  cliente_id uuid not null,
  
  -- Timestamps
  created_at timestamp with time zone default now(),
  expirado_em timestamp with time zone,  -- dossiê expira em 30 dias?
  
  unique(tipo, matricula, cpf_cnpj_principal, ciclo)
);

create index ix_sub_imob_dossies_tipo on sub_imob_dossies(tipo);
create index ix_sub_imob_dossies_matricula on sub_imob_dossies(matricula);
create index ix_sub_imob_dossies_cpf on sub_imob_dossies(cpf_cnpj_principal);
create index ix_sub_imob_dossies_cliente on sub_imob_dossies(cliente_id);
create index ix_sub_imob_dossies_ciclo on sub_imob_dossies(ciclo);

-- RLS: Pessoas
alter table sub_imob_pessoas enable row level security;
create policy "Pessoas vinculadas ao cliente" on sub_imob_pessoas
  for select using (auth.uid() = cliente_id);

-- RLS: Transações
alter table sub_imob_transacoes enable row level security;
create policy "Transações do cliente" on sub_imob_transacoes
  for select using (auth.uid() = cliente_id);

-- RLS: Dossiês
alter table sub_imob_dossies enable row level security;
create policy "Dossiês do cliente" on sub_imob_dossies
  for select using (auth.uid() = cliente_id);
