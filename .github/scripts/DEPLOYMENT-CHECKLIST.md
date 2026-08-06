# Deployment Checklist

Complete verification before going to production.

## Pre-Deployment (Local Testing)

- [ ] Run test suite: `./run_tests.sh` (all 38 tests pass)
- [ ] Syntax check: `python3 -m py_compile subradar_server.py subradar_pf_api.py`
- [ ] Dependencies installed: `pip install -r requirements-server.txt`
- [ ] Flask server starts without errors: `python3 subradar_server.py`
- [ ] Health check works: `curl http://localhost:5000/health`
- [ ] Test with valid CPF:
  ```bash
  curl -X POST http://localhost:5000/api/subradar/dossiee \
    -H "Content-Type: application/json" \
    -d '{
      "cpf": "12345678901",
      "nome": "Test User",
      "email": "test@example.com",
      "action": "generate"
    }'
  ```
- [ ] Test error handling (invalid CPF):
  ```bash
  curl -X POST http://localhost:5000/api/subradar/dossiee \
    -H "Content-Type: application/json" \
    -d '{"cpf": "123", "nome": "Test", "email": "test@example.com", "action": "generate"}'
  ```
- [ ] Verify all dependencies in requirements-server.txt are pinned to specific versions
- [ ] Check for hardcoded secrets/credentials (should use env vars only)
- [ ] Verify logging doesn't expose sensitive data

## Environment Variables

- [ ] `SUPABASE_URL` configured and tested
- [ ] `SUPABASE_SERVICE_ROLE_KEY` configured and tested
- [ ] `RESEND_API_KEY` configured and tested
- [ ] `FLASK_ENV=production` set
- [ ] `SUBRADAR_PORT` set (or using default 5000)
- [ ] `SUBRADAR_HOST` set (or using default 0.0.0.0)
- [ ] No secrets stored in git history: `git log -S "sk_test" -S "re_" -S "eyJ"`

## Security Review

- [ ] CORS configured for production domain only (not `*`)
- [ ] Rate limiting enabled (10 req/min per IP)
- [ ] No debug mode enabled in production
- [ ] Logging doesn't include sensitive data
- [ ] Input validation is strict (no SQL injection vectors)
- [ ] Subprocess execution is safe (no shell injection)
- [ ] PDF generation doesn't expose system info
- [ ] Error messages don't leak internal details
- [ ] API responses don't include unnecessary metadata

## Database (Supabase)

- [ ] All tables exist and have correct schema:
  - `sub_pf_resultados` (score data)
  - `sub_pf_alertas` (alert list)
  - `sub_pf_dados` (structured data)
- [ ] Service role key has correct permissions (SELECT on tables)
- [ ] Test query works: `SELECT * FROM sub_pf_resultados LIMIT 1`
- [ ] Database is accessible from deployment host
- [ ] Network policy allows connections from server IP

## Email Service (Resend)

- [ ] Resend API key is valid and has quota
- [ ] Test email send from production environment
- [ ] From address (`retorno@subradar.com.br`) is verified in Resend
- [ ] Email template renders correctly
- [ ] PDF attachment is valid in test email
- [ ] No rate limiting issues with Resend API

## Server Infrastructure

- [ ] Production server has Python 3.9+ installed
- [ ] Sufficient disk space for PDF generation (temp files)
- [ ] Sufficient memory (at least 512MB recommended)
- [ ] Server is reachable from Lovable frontend
- [ ] HTTPS is enabled (not HTTP)
- [ ] SSL certificate is valid
- [ ] Firewall allows inbound traffic on port 443 (or custom)

## Monitoring & Logging

- [ ] Logging is configured and working
- [ ] Logs are persisted (not just stdout)
- [ ] Log rotation is enabled (avoid disk full)
- [ ] Monitoring/alerting is set up for:
  - High error rates (>5% failed requests)
  - Slow responses (>10s requests)
  - API quota exceeded
  - Supabase connection failures
  - Resend API failures
- [ ] Health check endpoint is monitored
- [ ] Performance metrics are collected

## Lovable Frontend

- [ ] `REACT_APP_SUBRADAR_API_URL` points to production URL
- [ ] API key is set if using authentication
- [ ] Frontend tests pass
- [ ] Frontend can reach API endpoint
- [ ] CORS headers are correct
- [ ] Form validation matches backend validation
- [ ] Error handling is implemented
- [ ] Success states show correct information
- [ ] Loading states are clear

## End-to-End Testing

- [ ] Test complete flow: fill form → submit → email sent
- [ ] Test with real CPF (get actual result, not empty data)
- [ ] Verify email arrives in inbox (not spam)
- [ ] Verify PDF attachment is valid and readable
- [ ] Test edge cases:
  - Empty database (no results found)
  - Large dataset (many dados records)
  - Special characters in name
  - Gmail, Outlook, custom domains
- [ ] Test error scenarios:
  - Network timeout (simulate slow API)
  - Resend quota exceeded
  - Supabase connection failure
  - Invalid credentials

## Performance

- [ ] Measure typical response time: 2-3 seconds acceptable
- [ ] Measure cache hit time: <100ms acceptable
- [ ] Load test with 10 concurrent requests (no crashes)
- [ ] Monitor memory usage (no leaks)
- [ ] Monitor CPU usage (no spikes)

## Documentation

- [ ] README-SERVER.md is up to date
- [ ] LOVABLE-INTEGRATION.md is up to date
- [ ] openapi.yaml is accurate
- [ ] Code comments are clear
- [ ] Setup instructions are tested
- [ ] Troubleshooting guide covers common issues
- [ ] API documentation is complete

## Git & Version Control

- [ ] All changes committed and pushed
- [ ] Branch is up to date with main
- [ ] No untracked files in production
- [ ] Git tags created for version
- [ ] Release notes prepared
- [ ] .gitignore excludes:
  - `*.pyc`
  - `__pycache__`
  - `.env`
  - `.env.local`
  - `venv/`

## Backup & Recovery

- [ ] Database backups are configured
- [ ] Backup frequency is adequate (daily minimum)
- [ ] Backup restoration is tested
- [ ] Disaster recovery plan documented
- [ ] Contact information for support is documented

## Post-Deployment

- [ ] Health check runs successfully: `curl https://api.subradar.com.br/health`
- [ ] Monitor logs for errors in first 24 hours
- [ ] Monitor API metrics (latency, error rate)
- [ ] Verify email delivery working
- [ ] Test from Lovable frontend
- [ ] Check Supabase query performance
- [ ] Monitor Resend API quota

## Rollback Plan

- [ ] Previous version is tagged and accessible
- [ ] Rollback instructions documented
- [ ] Database schema changes are reversible
- [ ] Environment variables rollback plan exists
- [ ] Communication plan for users (if needed)

## Communication

- [ ] Team notified of deployment
- [ ] Users notified (if downtime expected)
- [ ] Support team has update notes
- [ ] FAQ updated with new features
- [ ] Status page updated

---

## Sign-Off

- Deployment checked by: ________________
- Date: ________________
- Notes: ________________

✅ Ready for production!
