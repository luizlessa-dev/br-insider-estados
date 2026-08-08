# Integração Lovable → Subradar PF

## Endpoint Anterior (❌ Remove)

```javascript
// OLD — chamava /dossiee diretamente
fetch('https://[PROJECT].supabase.co/functions/v1/dossiee', {
  method: 'POST',
  body: JSON.stringify({
    cpf, nome, email,
    action: 'send'
  })
})
```

## Novo Fluxo (✅ Implement)

### 1. Chamar dossiee_process para processar CPF

```javascript
const startConsulta = async (cpf, nome, email) => {
  try {
    // Inicia processamento (chama runner + gera PDF)
    const response = await fetch(
      `https://${process.env.REACT_APP_SUPABASE_URL}/functions/v1/dossiee_process`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ cpf, nome, email })
      }
    );

    const result = await response.json();

    if (result.sucesso) {
      return {
        sucesso: true,
        score: result.score,
        faixa: result.faixa,
        mensagem: result.mensagem
      };
    } else {
      throw new Error(result.erro || 'Erro ao processar');
    }
  } catch (err) {
    console.error('Erro na consulta:', err);
    throw err;
  }
};
```

### 2. Dados Retornados

```typescript
interface ConsultaResult {
  sucesso: boolean;
  mensagem: string;           // "Consulta processada e email enviado"
  score: number;              // 0-100
  faixa: string;              // "VERDE" | "AMARELO" | "LARANJA" | "VERMELHO"
  erro?: string;              // Se houver erro
}
```

### 3. Estados da Consulta

```javascript
// Estado inicial — enviando formulário
setStatus({ tipo: 'processando', mensagem: 'Processando sua consulta...' });

// Sucesso — PDF sendo gerado
setStatus({
  tipo: 'sucesso',
  score: 25,
  faixa: 'VERDE',
  mensagem: 'Consulta concluída! Email será enviado em breve.'
});

// Erro
setStatus({
  tipo: 'erro',
  mensagem: 'Erro ao processar sua consulta. Tente novamente.'
});
```

### 4. Componente React Exemplo

```javascript
import { useState } from 'react';

export default function ConsultaCPF() {
  const [formData, setFormData] = useState({ cpf: '', nome: '', email: '' });
  const [status, setStatus] = useState(null);
  const [resultado, setResultado] = useState(null);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setStatus({ tipo: 'processando' });

    try {
      const response = await fetch(
        `${process.env.REACT_APP_SUPABASE_URL}/functions/v1/dossiee_process`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(formData)
        }
      );

      const result = await response.json();

      if (result.sucesso) {
        setResultado({
          score: result.score,
          faixa: result.faixa,
          mensagem: `Seu score é ${result.score}/100 (${result.faixa})`
        });
        setStatus({ tipo: 'sucesso' });
      } else {
        setStatus({ tipo: 'erro', mensagem: result.erro });
      }
    } catch (err) {
      setStatus({ tipo: 'erro', mensagem: err.message });
    }
  };

  return (
    <div>
      <form onSubmit={handleSubmit}>
        <input
          type="text"
          placeholder="CPF"
          value={formData.cpf}
          onChange={(e) => setFormData({ ...formData, cpf: e.target.value })}
        />
        <input
          type="text"
          placeholder="Nome completo"
          value={formData.nome}
          onChange={(e) => setFormData({ ...formData, nome: e.target.value })}
        />
        <input
          type="email"
          placeholder="Email"
          value={formData.email}
          onChange={(e) => setFormData({ ...formData, email: e.target.value })}
        />
        <button type="submit" disabled={status?.tipo === 'processando'}>
          {status?.tipo === 'processando' ? 'Processando...' : 'Consultar'}
        </button>
      </form>

      {resultado && (
        <div className="resultado">
          <h2>Score: {resultado.score}/100</h2>
          <p>Faixa: {resultado.faixa}</p>
          <p>{resultado.mensagem}</p>
          <p>✅ Email enviado com seu dossiê</p>
        </div>
      )}

      {status?.tipo === 'erro' && (
        <div className="erro">
          ❌ {status.mensagem}
        </div>
      )}
    </div>
  );
}
```

## Environment Variables (Lovable)

Adicione no `.env.local` ou configuração do projeto:

```
REACT_APP_SUPABASE_URL=https://[PROJECT].supabase.co
REACT_APP_SUPABASE_ANON_KEY=[ANON-KEY]
```

## Resumo de Mudanças

| Item | Antes | Depois |
|------|-------|--------|
| Endpoint | `/dossiee` | `/dossiee_process` |
| Processamento | Síncrono | Síncrono (runner HTTP) → PDF assíncrono |
| Score | Mock (25) | Real (0-100, algoritmo proprietário) |
| Alertas | Nenhum | 29 fontes consultadas |
| Email | Sem PDF | Com PDF estruturado |
| Tempo | ~2s | ~10-30s (depende das APIs) |

## Verificação

1. ✅ Lovable chamando novo endpoint
2. ✅ Python runner rodando em localhost:8000
3. ✅ Supabase Edge Functions deployadas
4. ✅ Email recebido com PDF

