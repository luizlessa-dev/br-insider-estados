# Subradar PF — Production-Ready API

Complete documentation index for the Subradar PF compliance dossiê system.

## 📋 Quick Links

### For Developers
- **Setup**: [SETUP-GUIDE.md](SETUP-GUIDE.md) — Step-by-step local development setup
- **API Docs**: [openapi.yaml](openapi.yaml) — Full OpenAPI 3.0 specification
- **Server Docs**: [README-SERVER.md](README-SERVER.md) — Flask server configuration & usage
- **Testing**: [test_subradar.py](test_subradar.py) — 38 automated tests

### For Frontend Developers
- **Integration**: [LOVABLE-INTEGRATION.md](LOVABLE-INTEGRATION.md) — Lovable frontend integration guide
- **API Examples**: See LOVABLE-INTEGRATION.md → TypeScript client examples
- **Form Component**: See LOVABLE-INTEGRATION.md → React form component

### For DevOps / Deployment
- **Checklist**: [DEPLOYMENT-CHECKLIST.md](DEPLOYMENT-CHECKLIST.md) — Pre/post deployment verification
- **Setup Guide**: [SETUP-GUIDE.md](SETUP-GUIDE.md) → Production Deployment section
- **Server Config**: [README-SERVER.md](README-SERVER.md) → Deployment section

---

## 📁 File Structure

```
.github/scripts/
├── subradar_pf_api.py          # Core logic (PDF generation, email, validation)
├── subradar_server.py          # Flask HTTP API server
├── test_subradar.py            # 38 unit & integration tests
├── run_tests.sh                # Test runner script
├── requirements-server.txt     # Python dependencies
├── pytest.ini                  # Pytest configuration
│
├── openapi.yaml                # OpenAPI 3.0 specification
├── README-SERVER.md            # Server documentation
├── SETUP-GUIDE.md              # Step-by-step setup instructions
├── LOVABLE-INTEGRATION.md      # Frontend integration guide
├── DEPLOYMENT-CHECKLIST.md     # Pre/post deployment checklist
└── INDEX.md                    # This file
```

---

## 🚀 Getting Started

### I Want to...

#### Run Locally
→ Follow [SETUP-GUIDE.md](SETUP-GUIDE.md) → Local Development (8 steps)

#### Deploy to Production
→ Follow [SETUP-GUIDE.md](SETUP-GUIDE.md) → Production Deployment section

#### Integrate with Lovable Frontend
→ Follow [LOVABLE-INTEGRATION.md](LOVABLE-INTEGRATION.md)

#### Run Tests
→ From `.github/scripts/`: `./run_tests.sh`

#### Understand the API
→ Read [openapi.yaml](openapi.yaml) or [README-SERVER.md](README-SERVER.md) → API Endpoints

#### Configure Server
→ Read [README-SERVER.md](README-SERVER.md) → Configuration Reference

#### Deploy & Verify
→ Follow [DEPLOYMENT-CHECKLIST.md](DEPLOYMENT-CHECKLIST.md) step-by-step

---

## 📊 Project Stats

### Code

| Component | Size | Tests | Status |
|-----------|------|-------|--------|
| subradar_pf_api.py | 451 lines | ✅ 13 | Production-grade |
| subradar_server.py | 370 lines | ✅ 7 | Production-grade |
| test_subradar.py | 644 lines | ✅ 38 | Comprehensive |
| **Total** | **1,465 lines** | **38 tests** | **✅ All pass** |

### Documentation

| Document | Length | Purpose |
|----------|--------|---------|
| SETUP-GUIDE.md | ~500 lines | Complete step-by-step setup |
| LOVABLE-INTEGRATION.md | ~450 lines | Frontend integration with TypeScript examples |
| DEPLOYMENT-CHECKLIST.md | ~400 lines | Pre/post deployment verification |
| README-SERVER.md | ~200 lines | Server configuration & API reference |
| openapi.yaml | ~350 lines | OpenAPI 3.0 specification |
| **Total** | **~1,900 lines** | **Complete coverage** |

### Test Coverage

- **Input Validation**: 13 tests
  - CPF format, email format, name validation
  - Edge cases: empty, too short, too long, special chars

- **Request Validation**: 8 tests
  - Missing fields, invalid formats, boundary conditions

- **API Endpoints**: 7 tests
  - Health checks, CORS, POST endpoint behavior

- **Caching**: 3 tests
  - Cache key generation, set/get, TTL expiry

- **Integration**: 2 tests
  - End-to-end flows (generate, send)

- **Error Handling**: 4 tests
  - Subprocess errors, timeouts, invalid responses

- **Rate Limiting**: 1 test
  - 429 response on limit exceeded

---

## 🔧 Technology Stack

### Backend
- **Framework**: Flask 2.3.3
- **PDF Generation**: ReportLab 4.0.7
- **Email API**: Resend
- **Database**: Supabase (PostgreSQL)
- **Rate Limiting**: Flask-Limiter 3.5.0
- **CORS**: Flask-CORS 4.0.0

### Frontend (via Lovable)
- **Language**: TypeScript/React
- **UI Framework**: Tailwind CSS + shadcn/ui
- **Form State**: React hooks

### Testing
- **Framework**: pytest 7.4.0
- **Mocking**: pytest-mock 3.11.1
- **Coverage**: pytest-cov 4.1.0

### Deployment
- **Platforms**: Railway, Render, self-hosted (systemd)
- **HTTP Server**: Gunicorn (production)
- **Reverse Proxy**: Nginx
- **Container**: Optional Docker support

---

## 📈 Performance Targets

- **Typical request**: 2-3 seconds
- **Cached request**: <100ms
- **Rate limit**: 10 requests/min per IP
- **Timeout**: 60 seconds (subprocess)
- **Max payload size**: ~50MB (PDF)

---

## 🔒 Security

- **Input Validation**: Strict (CPF, email, name format)
- **Rate Limiting**: 10 req/min per IP
- **CORS**: Configurable per environment
- **Subprocess**: Safe execution (no shell injection)
- **Error Messages**: Don't leak internal details
- **Logging**: No sensitive data in logs
- **HTTPS**: Required in production
- **Environment Variables**: All secrets via env vars

---

## 📝 API Quick Reference

### Health Check
```bash
GET /health
# Response: 200 OK
# { "status": "healthy", "timestamp": "2026-08-06T..." }
```

### Generate/Send Dossiê
```bash
POST /api/subradar/dossiee
Content-Type: application/json

{
  "cpf": "12345678901",
  "nome": "João da Silva",
  "email": "joao@example.com",
  "action": "send"  # or "generate"
}

# Response: 200 OK
# {
#   "success": true,
#   "score": 42,
#   "faixa": "MÉDIO",
#   "message": "Dossiê enviado para joao@example.com"
# }
```

---

## 🐛 Troubleshooting

### Common Issues

**"Module not found"**
- Install dependencies: `pip install -r requirements-server.txt`

**"API key not set"**
- Load env vars: `source .env`

**"Connection refused"**
- Check server is running: `ps aux | grep subradar_server`
- Check port: `lsof -i :5000`

**"Supabase error"**
- Verify URL format: `https://xxxxx.supabase.co`
- Verify key is service role key (not anon)

**"Resend error"**
- Check API key format: `re_xxxxx...`
- Verify sender email is verified

See [SETUP-GUIDE.md](SETUP-GUIDE.md) → Troubleshooting for more issues.

---

## 📚 Documentation Map

```
Start Here
    ↓
Is it your first time?
    ├→ YES: Read SETUP-GUIDE.md
    └→ NO: What do you need?
           ├→ Run tests: ./run_tests.sh
           ├→ Deploy: DEPLOYMENT-CHECKLIST.md
           ├→ Integrate frontend: LOVABLE-INTEGRATION.md
           ├→ API reference: openapi.yaml
           └→ Server config: README-SERVER.md
```

---

## 🎯 Project Status

- ✅ **Phase 1**: Production-grade API script (451 lines)
- ✅ **Phase 2**: Flask HTTP server (370 lines)
- ✅ **Phase 3**: Test suite (38 tests, all passing)
- ✅ **Phase 4**: Complete documentation (~1,900 lines)

**All production-ready and fully documented.**

---

## 📞 Support

For issues or questions:
1. Check [SETUP-GUIDE.md](SETUP-GUIDE.md) → Troubleshooting
2. Read relevant documentation for your task
3. Run tests: `./run_tests.sh`
4. Check server logs for error details

---

## 📄 License

Proprietary — Lessa Labs Tecnologia Ltda

---

## 🚀 Next Steps

1. **Clone & Setup**: Follow [SETUP-GUIDE.md](SETUP-GUIDE.md)
2. **Test Locally**: `./run_tests.sh`
3. **Deploy**: Use [DEPLOYMENT-CHECKLIST.md](DEPLOYMENT-CHECKLIST.md)
4. **Integrate Frontend**: Follow [LOVABLE-INTEGRATION.md](LOVABLE-INTEGRATION.md)
5. **Monitor**: Set up logging & alerts

---

Last updated: 2026-08-06  
Version: 1.0.0  
Status: Production-ready ✅
