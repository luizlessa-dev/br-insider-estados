# Lovable Integration Guide

Integration instructions for the Lovable frontend to connect with Subradar PF backend.

## Overview

The Lovable frontend (TypeScript/React) calls the Subradar PF backend API to:
1. Generate compliance dossiês
2. Send them via email
3. Display results to users

This guide covers:
- API endpoint configuration
- Request/response handling
- Error handling
- Deployment workflow

## 1. Backend Setup

### Option A: Local Development

Start the Flask server locally:

```bash
cd .github/scripts
pip install -r requirements-server.txt
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_SERVICE_ROLE_KEY="eyJhbGc..."
export RESEND_API_KEY="re_xxx..."
python3 subradar_server.py
```

Server runs on `http://localhost:5000`

### Option B: Production Deployment

Deploy to Railway, Render, or your preferred platform:

1. Push code to GitHub
2. Connect to deployment platform
3. Set environment variables:
   - `SUPABASE_URL`
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `RESEND_API_KEY`
   - `SUBRADAR_PORT` (optional, default: 5000)
   - `SUBRADAR_HOST` (optional, default: 0.0.0.0)
   - `FLASK_ENV=production`

4. Deploy with: `python3 .github/scripts/subradar_server.py`

## 2. Lovable Configuration

### In Lovable Project Settings

1. Add environment variables:
   ```
   SUBRADAR_API_URL=http://localhost:5000  # local
   # OR
   SUBRADAR_API_URL=https://api.subradar.com.br  # production
   ```

2. Add optional API key (if using auth):
   ```
   SUBRADAR_API_KEY=your-api-key-here
   ```

3. Set CORS headers (if needed):
   - API is already CORS-enabled
   - No additional configuration needed

### In Lovable Frontend Code

#### 1. Create API client

```typescript
// api/subradar.ts
const API_URL = process.env.REACT_APP_SUBRADAR_API_URL || 'http://localhost:5000';
const API_KEY = process.env.REACT_APP_SUBRADAR_API_KEY;

interface DossieeRequest {
  cpf: string;
  nome: string;
  email: string;
  action: 'send' | 'generate';
}

interface DossieeResponse {
  success: boolean;
  score?: number;
  faixa?: string;
  message?: string;
  pdf?: string;
  error?: string;
}

export async function generateDossiee(
  request: DossieeRequest
): Promise<DossieeResponse> {
  const headers: HeadersInit = {
    'Content-Type': 'application/json',
  };

  if (API_KEY) {
    headers['Authorization'] = `Bearer ${API_KEY}`;
  }

  const response = await fetch(`${API_URL}/api/subradar/dossiee`, {
    method: 'POST',
    headers,
    body: JSON.stringify(request),
  });

  const data = await response.json();

  if (!response.ok) {
    throw new Error(data.error || 'Erro ao processar dossiê');
  }

  return data;
}

export async function checkHealth(): Promise<boolean> {
  try {
    const response = await fetch(`${API_URL}/health`);
    return response.ok;
  } catch {
    return false;
  }
}
```

#### 2. Create form component

```typescript
// components/DossieeForm.tsx
import { useState } from 'react';
import { generateDossiee } from '../api/subradar';

export function DossieeForm() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const [result, setResult] = useState<any>(null);

  const [formData, setFormData] = useState({
    cpf: '',
    nome: '',
    email: '',
    action: 'send' as const,
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setSuccess(false);

    try {
      const response = await generateDossiee(formData);

      if (response.success) {
        setSuccess(true);
        setResult(response);

        // If PDF generated, offer download
        if (response.pdf) {
          const link = document.createElement('a');
          link.href = `data:application/pdf;base64,${response.pdf}`;
          link.download = `dossiee_${formData.cpf.replace(/\D/g, '')}.pdf`;
          link.click();
        }
      } else {
        setError(response.error || 'Erro desconhecido');
      }
    } catch (err) {
      setError(
        err instanceof Error ? err.message : 'Erro ao processar requisição'
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="max-w-md mx-auto p-6">
      <h1 className="text-2xl font-bold mb-6">Subradar PF</h1>

      {/* CPF Input */}
      <input
        type="text"
        placeholder="CPF (11 dígitos)"
        value={formData.cpf}
        onChange={(e) => {
          const value = e.target.value.replace(/\D/g, '');
          setFormData({ ...formData, cpf: value });
        }}
        maxLength="11"
        className="w-full p-2 border rounded mb-4"
        required
      />

      {/* Name Input */}
      <input
        type="text"
        placeholder="Nome completo"
        value={formData.nome}
        onChange={(e) =>
          setFormData({ ...formData, nome: e.target.value })
        }
        className="w-full p-2 border rounded mb-4"
        required
      />

      {/* Email Input */}
      <input
        type="email"
        placeholder="Email"
        value={formData.email}
        onChange={(e) =>
          setFormData({ ...formData, email: e.target.value })
        }
        className="w-full p-2 border rounded mb-4"
        required
      />

      {/* Action Select */}
      <select
        value={formData.action}
        onChange={(e) =>
          setFormData({
            ...formData,
            action: e.target.value as 'send' | 'generate',
          })
        }
        className="w-full p-2 border rounded mb-6"
      >
        <option value="send">Enviar por email</option>
        <option value="generate">Baixar PDF</option>
      </select>

      {/* Submit Button */}
      <button
        type="submit"
        disabled={loading}
        className="w-full bg-blue-600 text-white p-2 rounded hover:bg-blue-700 disabled:bg-gray-400"
      >
        {loading ? 'Processando...' : 'Gerar Dossiê'}
      </button>

      {/* Error Message */}
      {error && (
        <div className="mt-4 p-4 bg-red-50 border border-red-200 rounded text-red-700">
          {error}
        </div>
      )}

      {/* Success Message */}
      {success && result && (
        <div className="mt-4 p-4 bg-green-50 border border-green-200 rounded">
          <h3 className="font-bold text-green-700">Sucesso!</h3>
          <p className="text-green-600">Score: {result.score}/100</p>
          <p className="text-green-600">Risco: {result.faixa}</p>
          {result.message && (
            <p className="text-green-600 mt-2">{result.message}</p>
          )}
        </div>
      )}
    </form>
  );
}
```

#### 3. Error handling

```typescript
// Handle specific HTTP errors
async function handleAPIError(response: Response) {
  const data = await response.json();

  switch (response.status) {
    case 400:
      return `Validação: ${data.error}`;
    case 429:
      return 'Muitas requisições. Tente novamente em alguns minutos.';
    case 503:
      return 'Servidor indisponível. Tente novamente mais tarde.';
    case 504:
      return 'Requisição demorou muito. Tente novamente.';
    default:
      return data.error || 'Erro desconhecido';
  }
}
```

## 3. Environment Variables

### Development (.env.local)

```bash
REACT_APP_SUBRADAR_API_URL=http://localhost:5000
# REACT_APP_SUBRADAR_API_KEY=optional-key
```

### Production (.env.production)

```bash
REACT_APP_SUBRADAR_API_URL=https://api.subradar.com.br
REACT_APP_SUBRADAR_API_KEY=your-production-key
```

## 4. Deployment Workflow

### Step 1: Deploy Backend

```bash
# Deploy to your hosting platform (Railway, Render, etc)
git push origin main
# Platform automatically deploys .github/scripts/subradar_server.py
```

### Step 2: Update Lovable

1. Update API URL in Lovable environment variables
2. Test with health check: `GET /health`
3. Test with generate: `POST /api/subradar/dossiee`

### Step 3: Test End-to-End

```bash
# Test with sample data
curl -X POST https://api.subradar.com.br/api/subradar/dossiee \
  -H "Content-Type: application/json" \
  -d '{
    "cpf": "12345678901",
    "nome": "João da Silva",
    "email": "joao@example.com",
    "action": "generate"
  }'
```

## 5. Troubleshooting

### "Cannot reach API"

- Check backend is running
- Verify `SUBRADAR_API_URL` is correct
- Check network/firewall (CORS should be enabled)
- Try health check: `GET {API_URL}/health`

### "Invalid CPF"

- CPF must be 11 digits
- Remove all formatting before sending
- Validate locally before sending

### "Rate limited (429)"

- Wait 1 minute before retry
- User is sending >10 requests/min
- Implement backoff in frontend

### "Timeout (504)"

- Backend taking >60 seconds
- Check Supabase performance
- Check network latency
- Retry after delay

### "Email not sent"

- Verify `RESEND_API_KEY` is set on backend
- Check email format is valid
- Verify recipient email exists
- Check Resend API quota

## 6. Monitoring

### Health Check

```typescript
// Check API health before showing form
useEffect(() => {
  checkHealth().then(isHealthy => {
    if (!isHealthy) {
      setError('API indisponível');
    }
  });
}, []);
```

### Error Tracking

```typescript
// Log errors to monitoring service
import * as Sentry from "@sentry/react";

try {
  await generateDossiee(formData);
} catch (err) {
  Sentry.captureException(err);
}
```

### Performance Monitoring

```typescript
// Measure request time
const start = performance.now();
const response = await generateDossiee(formData);
const duration = performance.now() - start;
console.log(`Dossiê generated in ${duration.toFixed(0)}ms`);
```

## 7. Security Considerations

### CORS

API allows all origins by default (development). For production:

Edit `subradar_server.py` line ~25:

```python
CORS(app, resources={
    r"/api/*": {
        "origins": ["https://your-lovable-domain.com"],
        "methods": ["POST"],
    }
})
```

### Authentication

Add optional API key authentication:

```python
# In subradar_server.py
@app.before_request
def check_api_key():
    if request.path.startswith('/api/'):
        api_key = request.headers.get('Authorization', '').replace('Bearer ', '')
        expected_key = os.environ.get('API_KEY')
        if expected_key and api_key != expected_key:
            return jsonify({"error": "Unauthorized"}), 401
```

### Rate Limiting

Already built-in (10 req/min per IP). For custom limits:

```python
# In subradar_server.py
limiter.limit("5 per minute")(dossiee)
```

## 8. API Reference

Full OpenAPI/Swagger specification: see `openapi.yaml`

View live docs (if deployed to prod):
- Swagger UI: `https://api.subradar.com.br/docs`
- ReDoc: `https://api.subradar.com.br/redoc`

## Support

For issues:
1. Check health: `GET /health`
2. Check backend logs
3. Verify environment variables
4. Test with curl before testing in Lovable
5. See README-SERVER.md for backend troubleshooting
