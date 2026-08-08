-- Tabela de resultados (scores)
CREATE TABLE IF NOT EXISTS sub_pf_resultados (
  id TEXT PRIMARY KEY,
  cpf TEXT NOT NULL,
  cliente_id TEXT,
  ciclo TEXT NOT NULL,
  score_risco INTEGER,
  faixa_risco TEXT,
  total_alertas INTEGER,
  score_detalhes JSONB,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(cpf, ciclo)
);

-- Tabela de alertas
CREATE TABLE IF NOT EXISTS sub_pf_alertas (
  id TEXT PRIMARY KEY,
  cpf TEXT NOT NULL,
  ciclo TEXT NOT NULL,
  fonte TEXT,
  severidade TEXT,
  titulo TEXT,
  descricao TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Tabela de dados estruturados
CREATE TABLE IF NOT EXISTS sub_pf_dados (
  id TEXT PRIMARY KEY,
  cpf TEXT NOT NULL,
  ciclo TEXT NOT NULL,
  fonte TEXT,
  categoria TEXT,
  status TEXT,
  titulo_secao TEXT,
  resumo TEXT,
  detalhes JSONB,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_sub_pf_resultados_cpf_ciclo ON sub_pf_resultados(cpf, ciclo);
CREATE INDEX IF NOT EXISTS idx_sub_pf_alertas_cpf_ciclo ON sub_pf_alertas(cpf, ciclo);
CREATE INDEX IF NOT EXISTS idx_sub_pf_dados_cpf_ciclo ON sub_pf_dados(cpf, ciclo);
