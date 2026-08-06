# Complete Setup Guide

Step-by-step instructions for getting Subradar PF up and running.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Local Development](#local-development)
3. [Testing](#testing)
4. [Production Deployment](#production-deployment)
5. [Lovable Integration](#lovable-integration)
6. [Verification](#verification)

---

## Prerequisites

### System Requirements

- **Python**: 3.9 or higher
- **pip**: Package manager for Python
- **Git**: For version control

Check your versions:

```bash
python3 --version  # Should be 3.9+
pip3 --version     # Should be recent
git --version      # Should be recent
```

### API Keys & Credentials

You'll need:
1. **Supabase**
   - Project URL: `https://xxxxx.supabase.co`
   - Service Role Key: `eyJhbGc...` (keep secret!)

2. **Resend** (for email)
   - API Key: `re_xxxxx...` (keep secret!)

If you don't have these:
- Supabase: Create free account at https://supabase.com
- Resend: Create free account at https://resend.com

---

## Local Development

### Step 1: Clone Repository

```bash
cd ~/projects
git clone https://github.com/yourusername/brasilia-insider.git
cd brasilia-insider
```

### Step 2: Navigate to Scripts Directory

```bash
cd .github/scripts
```

### Step 3: Create Python Virtual Environment

```bash
# Create virtual environment
python3 -m venv venv

# Activate it (macOS/Linux)
source venv/bin/activate

# Activate it (Windows)
# venv\Scripts\activate
```

You should see `(venv)` prefix in your terminal.

### Step 4: Install Dependencies

```bash
pip install -r requirements-server.txt
```

This installs:
- Flask (web framework)
- Flask-CORS (cross-origin requests)
- Flask-Limiter (rate limiting)
- ReportLab (PDF generation)
- requests (HTTP library)
- pytest (testing)

### Step 5: Configure Environment

Create `.env` file in `.github/scripts/`:

```bash
cat > .env << 'EOF'
# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGc...

# Resend
RESEND_API_KEY=re_xxxxx...

# Flask
FLASK_ENV=development
SUBRADAR_PORT=5000
SUBRADAR_HOST=0.0.0.0
EOF
```

Replace with your actual values:
- Get `SUPABASE_URL` from Supabase dashboard
- Get `SUPABASE_SERVICE_ROLE_KEY` from Settings → API → Service Role Key
- Get `RESEND_API_KEY` from Resend dashboard

### Step 6: Load Environment

```bash
source .env
# or
export $(cat .env | xargs)
```

### Step 7: Start Development Server

```bash
python3 subradar_server.py
```

You should see:

```
2026-08-06 11:30:45 [subradar_server] INFO: Starting Subradar PF API server on 0.0.0.0:5000
2026-08-06 11:30:45 [subradar_server] INFO: Environment: development
```

### Step 8: Test Connection

In a new terminal:

```bash
# Health check
curl http://localhost:5000/

# Should return:
# {
#   "service": "Subradar PF API",
#   "status": "online",
#   ...
# }
```

---

## Testing

### Run All Tests

```bash
# From .github/scripts directory
./run_tests.sh
```

This runs:
- 38 unit tests
- Input validation tests
- API endpoint tests
- Error handling tests
- Rate limiting tests

All tests should pass ✅

### Run Specific Tests

```bash
# Only validation tests
pytest test_subradar.py::TestCPFValidation -v

# Only API tests
pytest test_subradar.py::TestAPIEndpoint -v

# With coverage report
pytest test_subradar.py --cov=subradar_server --cov-report=html
```

### Manual Testing

Test with curl:

```bash
# Generate PDF
curl -X POST http://localhost:5000/api/subradar/dossiee \
  -H "Content-Type: application/json" \
  -d '{
    "cpf": "12345678901",
    "nome": "João da Silva",
    "email": "joao@example.com",
    "action": "generate"
  }'

# Send via email
curl -X POST http://localhost:5000/api/subradar/dossiee \
  -H "Content-Type: application/json" \
  -d '{
    "cpf": "12345678901",
    "nome": "João da Silva",
    "email": "joao@example.com",
    "action": "send"
  }'
```

---

## Production Deployment

### Option A: Railway.app

1. **Create account**: https://railway.app
2. **Connect GitHub**: Link your repo
3. **Create project**: Select new project
4. **Add Python service**:
   - Build command: `pip install -r .github/scripts/requirements-server.txt`
   - Start command: `python3 .github/scripts/subradar_server.py`
5. **Add environment variables**:
   - `SUPABASE_URL`
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `RESEND_API_KEY`
   - `FLASK_ENV=production`
6. **Deploy**: Railway auto-deploys on git push

### Option B: Render.com

1. **Create account**: https://render.com
2. **New Web Service**:
   - Build: `pip install -r .github/scripts/requirements-server.txt`
   - Start: `python3 .github/scripts/subradar_server.py`
   - Auto-deploys from GitHub
3. **Add environment variables** in Render dashboard
4. **Set Python version**: 3.11 or higher

### Option C: Your Own Server

1. **SSH into server**:
   ```bash
   ssh user@your-server.com
   ```

2. **Install Python**:
   ```bash
   sudo apt-get update
   sudo apt-get install python3.11 python3-pip
   ```

3. **Clone repository**:
   ```bash
   git clone https://github.com/yourusername/brasilia-insider.git
   cd brasilia-insider/.github/scripts
   ```

4. **Install dependencies**:
   ```bash
   pip install -r requirements-server.txt
   ```

5. **Create systemd service** (`/etc/systemd/system/subradar.service`):
   ```ini
   [Unit]
   Description=Subradar PF API
   After=network.target

   [Service]
   Type=simple
   User=www-data
   WorkingDirectory=/path/to/brasilia-insider/.github/scripts
   Environment="SUPABASE_URL=..."
   Environment="SUPABASE_SERVICE_ROLE_KEY=..."
   Environment="RESEND_API_KEY=..."
   Environment="FLASK_ENV=production"
   ExecStart=/usr/bin/python3 subradar_server.py
   Restart=always
   RestartSec=10

   [Install]
   WantedBy=multi-user.target
   ```

6. **Enable and start**:
   ```bash
   sudo systemctl enable subradar
   sudo systemctl start subradar
   sudo systemctl status subradar
   ```

### Common Production Setup

```bash
# Use a production WSGI server (Gunicorn)
pip install gunicorn

# Run with 4 workers
gunicorn -w 4 -b 0.0.0.0:5000 subradar_server:app
```

### Configure Nginx Reverse Proxy

```nginx
# /etc/nginx/sites-available/subradar
server {
    listen 443 ssl;
    server_name api.subradar.com.br;

    ssl_certificate /path/to/certificate.crt;
    ssl_certificate_key /path/to/key.key;

    location / {
        proxy_pass http://localhost:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 60s;
    }
}
```

Enable:
```bash
sudo ln -s /etc/nginx/sites-available/subradar /etc/nginx/sites-enabled/
sudo systemctl restart nginx
```

---

## Lovable Integration

### Step 1: Update Lovable Environment

In Lovable project settings, add:

```
REACT_APP_SUBRADAR_API_URL=http://localhost:5000  # local
# OR
REACT_APP_SUBRADAR_API_URL=https://api.subradar.com.br  # production
```

### Step 2: Add API Client

Copy example from `LOVABLE-INTEGRATION.md` → `2. Lovable Configuration` → `In Lovable Frontend Code`

### Step 3: Add Form Component

Copy DossieeForm component from integration guide

### Step 4: Test Connection

```bash
# From Lovable frontend console
fetch('http://localhost:5000/health')
  .then(r => r.json())
  .then(console.log)
```

Should return:
```json
{ "status": "healthy", "timestamp": "2026-08-06T..." }
```

---

## Verification

### Checklist

- [ ] Server starts without errors
- [ ] Health check returns 200 OK
- [ ] All 38 tests pass
- [ ] Generate PDF works (action: generate)
- [ ] Send email works (action: send) — check inbox!
- [ ] Invalid CPF returns 400 error
- [ ] Rate limiting works (10 req/min)
- [ ] Lovable can reach API
- [ ] Form submits successfully
- [ ] Email arrives with PDF

### Quick Health Check

```bash
# 1. Check server is running
curl http://localhost:5000/

# 2. Check health endpoint
curl http://localhost:5000/health

# 3. Test API
curl -X POST http://localhost:5000/api/subradar/dossiee \
  -H "Content-Type: application/json" \
  -d '{"cpf":"12345678901","nome":"Test","email":"test@example.com","action":"generate"}'

# Should get 200 response with score
```

### Troubleshooting

**"Connection refused"**
- Is server running? Check `python3 subradar_server.py`
- Is port 5000 free? `lsof -i :5000`

**"Module not found"**
- Install dependencies: `pip install -r requirements-server.txt`
- Activate virtual env: `source venv/bin/activate`

**"API key not set"**
- Check `.env` file exists: `cat .env`
- Load environment: `source .env`
- Verify: `echo $SUPABASE_URL`

**"Supabase error"**
- Check URL format: `https://xxxxx.supabase.co`
- Verify key is service role key (not anon key)
- Check database tables exist

**"Resend error"**
- Verify API key format: `re_xxxxx...`
- Check Resend quota (free tier has limits)
- Verify sender email is verified

---

## Next Steps

1. **Test locally** with this guide
2. **Run test suite** to verify everything works
3. **Configure Lovable** to connect to API
4. **Deploy to production** using one of the options
5. **Monitor** using deployment platform's tools

For more details:
- API docs: See `openapi.yaml`
- Server setup: See `README-SERVER.md`
- Lovable integration: See `LOVABLE-INTEGRATION.md`
- Deployment: See `DEPLOYMENT-CHECKLIST.md`

---

## Support

If something doesn't work:
1. Check error message carefully
2. Look in troubleshooting section above
3. Check logs: `tail -f server.log`
4. Re-read this guide from the beginning
5. Verify environment variables are set
6. Run test suite: `./run_tests.sh`

Questions? Contact: support@subradar.com.br
