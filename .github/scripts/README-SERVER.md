# Subradar PF — API Server

Production-grade Flask server for Subradar dossiê generation.

## Components

- **subradar_pf_api.py**: Core logic (PDF generation, email send)
- **subradar_server.py**: Flask HTTP API server
- **requirements-server.txt**: Python dependencies

## Setup

### 1. Install Dependencies

```bash
pip install -r requirements-server.txt
```

### 2. Configure Environment

```bash
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_SERVICE_ROLE_KEY="eyJhbGc..."
export RESEND_API_KEY="re_xxx..."
export FLASK_ENV="production"
export SUBRADAR_PORT="5000"
export SUBRADAR_HOST="0.0.0.0"
```

### 3. Run Server

```bash
python3 subradar_server.py
```

Server will start on `http://0.0.0.0:5000`

## API Endpoints

### Health Check

```bash
GET /
GET /health
```

Returns server status.

### Generate Dossiê

```bash
POST /api/subradar/dossiee
Content-Type: application/json

{
  "cpf": "12345678901",
  "nome": "João da Silva",
  "email": "joao@example.com",
  "action": "send"
}
```

**Parameters:**
- `cpf`: CPF (11 digits or formatted)
- `nome`: Full name (3-200 characters)
- `email`: Email address
- `action`: `send` (send email) or `generate` (return PDF as base64)

**Response (success, 200):**

```json
{
  "success": true,
  "score": 42,
  "faixa": "MÉDIO",
  "message": "Dossiê enviado para joao@example.com"
}
```

**Response (generate, 200):**

```json
{
  "success": true,
  "score": 42,
  "faixa": "MÉDIO",
  "pdf": "JVBERi0xLjQK..."
}
```

**Response (error):**

```json
{
  "success": false,
  "error": "Error message"
}
```

## HTTP Status Codes

| Code | Meaning | Action |
|------|---------|--------|
| 200 | Success | Dossiê generated/sent |
| 400 | Bad Request | Invalid input (validation error) |
| 429 | Too Many Requests | Rate limited (10/min per IP) |
| 500 | Internal Server Error | Server error |
| 503 | Service Unavailable | External API error (Supabase/Resend) |
| 504 | Gateway Timeout | Request took too long |

## Rate Limiting

- **10 requests per minute** per IP address
- **200 requests per day** per IP address (global limit)

## Caching

Successful requests are cached for **5 minutes** to avoid duplicate processing.

Cache key: `{cpf}:{action}`

## Logging

All requests and errors are logged with timestamps:

```
2026-08-06 11:30:45 [subradar_server] INFO: Request from 192.168.1.100: 12345678901
2026-08-06 11:30:46 [subradar_server] INFO: Calling API: cpf=123.456.789-01, action=send
```

## Error Handling

Each error includes a descriptive message:

```json
{
  "success": false,
  "error": "CPF deve conter 11 dígitos"
}
```

Common errors:
- `"Campo obrigatório ausente: {field}"` — Missing required field
- `"CPF deve conter 11 dígitos"` — Invalid CPF format
- `"Email inválido"` — Invalid email format
- `"Ação inválida: {action}"` — Invalid action (must be send or generate)
- `"Supabase não configurado"` — Missing env vars
- `"Resend não configurado"` — Missing RESEND_API_KEY
- `"Timeout ao processar requisição"` — Request took >60 seconds

## Deployment

### Local Development

```bash
FLASK_ENV=development python3 subradar_server.py
```

### Production (Docker)

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements-server.txt .
RUN pip install -r requirements-server.txt

COPY subradar_pf_api.py subradar_server.py ./

ENV FLASK_ENV=production
EXPOSE 5000

CMD ["python3", "subradar_server.py"]
```

### Production (Railway, Render, etc)

1. Set environment variables in platform dashboard
2. Deploy with `python3 subradar_server.py`
3. Platform will expose HTTP port (usually PORT env var)

## Testing Locally

### 1. Start server

```bash
python3 subradar_server.py
```

### 2. Test health check

```bash
curl http://localhost:5000/
```

### 3. Test dossiê generation

```bash
curl -X POST http://localhost:5000/api/subradar/dossiee \
  -H "Content-Type: application/json" \
  -d '{
    "cpf": "12345678901",
    "nome": "João Silva",
    "email": "joao@example.com",
    "action": "generate"
  }'
```

## Configuration Reference

| Env Var | Default | Description |
|---------|---------|-------------|
| SUBRADAR_PORT | 5000 | HTTP port |
| SUBRADAR_HOST | 0.0.0.0 | Bind address |
| FLASK_ENV | production | development or production |
| SUPABASE_URL | — | Supabase project URL (required) |
| SUPABASE_SERVICE_ROLE_KEY | — | Supabase service role key (required) |
| RESEND_API_KEY | — | Resend API key (required for send action) |

## Troubleshooting

### "Supabase não configurado"

Set `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` environment variables.

### "Resend não configurado"

Set `RESEND_API_KEY` environment variable. Only needed if using `action: send`.

### "Timeout ao processar requisição"

The request took more than 60 seconds. This usually means:
- Supabase is slow (check network)
- Too many dados records (>1000)
- Resend API is down

Check server logs for details.

### Server won't start

```bash
python3 subradar_server.py
```

Check:
1. Port is not in use (`lsof -i :5000`)
2. subradar_pf_api.py exists in same directory
3. All dependencies installed (`pip list`)

## Performance

- Typical request time: 2-3 seconds
- PDF generation: ~1 second
- Email send: ~1 second
- Supabase queries: ~0.5 seconds

Cached requests return in <100ms.

## Security

- CORS enabled for all origins (change in production)
- Rate limiting: 10 req/min per IP
- No sensitive data in logs
- Subprocess runs with explicit environment (no shell injection)
- Input validation on all fields

For production, consider:
- API key authentication
- HTTPS only
- Restrict CORS to specific origins
- WAF (Web Application Firewall)
- Monitoring/alerting

## Support

For issues, check:
1. Logs: Look for `[ERROR]` messages
2. Exit codes: See subradar_pf_api.py docstring
3. Request format: Ensure JSON is valid
4. Environment: Verify all env vars are set
