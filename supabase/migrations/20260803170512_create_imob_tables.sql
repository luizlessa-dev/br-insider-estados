-- ============================================================================
-- Subradar Imob — Schema de dados para compliance imobiliário
-- ============================================================================

create table sub_imob_consultas (
  id uuid primary key default gen_random_uuid(),
  matricula text,
  cartorio_id text,
  cartorio_nome text,
  endereco_completo text,
  cep text,
  status text check (status in ('pendente', 'processando', 'concluido', 'erro')),
  mensagem_erro text,
  cliente_id uuid not null,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  iniciado_em timestamp with time zone,
  concluido_em timestamp with time zone
);

create index ix_sub_imob_consultas_matricula on sub_imob_consultas(matricula);
create index ix_sub_imob_consultas_cliente on sub_imob_consultas(cliente_id);

create table sub_imob_dados (
  id uuid primary key default gen_random_uuid(),
  matricula text not null,
  ciclo text not null,
  fonte text not null,
  categoria text not null,
  status text check (status in ('limpo', 'alerta', 'critico', 'pendente', 'nao_aplicavel', 'erro')),
  titulo_secao text,
  resumo text,
  detalhes jsonb,
  created_at timestamp with time zone default now(),
  unique(matricula, ciclo, fonte)
);

create index ix_sub_imob_dados_matricula on sub_imob_dados(matricula);
create index ix_sub_imob_dados_ciclo on sub_imob_dados(ciclo);
create index ix_sub_imob_dados_fonte on sub_imob_dados(fonte);

create table sub_imob_alertas (
  id uuid primary key default gen_random_uuid(),
  matricula text not null,
  ciclo text not null,
  fonte text not null,
  categoria text not null,
  severidade text check (severidade in ('critico', 'atencao', 'info')),
  titulo text,
  descricao text,
  url_fonte text,
  created_at timestamp with time zone default now()
);

create index ix_sub_imob_alertas_matricula on sub_imob_alertas(matricula);
create index ix_sub_imob_alertas_ciclo on sub_imob_alertas(ciclo);

create table sub_imob_resultados (
  id uuid primary key default gen_random_uuid(),
  matricula text primary key,
  ciclo text not null,
  score_risco integer check (score_risco between 0 and 100),
  faixa_risco text check (faixa_risco in ('verde', 'amarelo', 'laranja', 'vermelho')),
  total_criticos integer default 0,
  total_alertas integer default 0,
  total_info integer default 0,
  created_at timestamp with time zone default now(),
  unique(matricula, ciclo)
);

create index ix_sub_imob_resultados_matricula on sub_imob_resultados(matricula);

alter table sub_imob_consultas enable row level security;
create policy "Clientes acessam suas consultas" on sub_imob_consultas
  for select using (auth.uid() = cliente_id);

alter table sub_imob_dados enable row level security;
create policy "Dados vinculados a consultas do cliente" on sub_imob_dados
  for select using (
    exists (
      select 1 from sub_imob_consultas
      where matricula = sub_imob_dados.matricula
      and cliente_id = auth.uid()
    )
  );

alter table sub_imob_alertas enable row level security;
create policy "Alertas vinculados a consultas do cliente" on sub_imob_alertas
  for select using (
    exists (
      select 1 from sub_imob_consultas
      where matricula = sub_imob_alertas.matricula
      and cliente_id = auth.uid()
    )
  );

alter table sub_imob_resultados enable row level security;
create policy "Resultados vinculados a consultas do cliente" on sub_imob_resultados
  for select using (
    exists (
      select 1 from sub_imob_consultas
      where matricula = sub_imob_resultados.matricula
      and cliente_id = auth.uid()
    )
  );
