#!/usr/bin/env python3
"""Send Subradar PF dossiê via Resend email API with professional PDF."""

import os
import sys
import requests
import base64
from datetime import date
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from reportlab.lib.colors import HexColor
import io

cpf = sys.argv[1] if len(sys.argv) > 1 else ""
nome = sys.argv[2] if len(sys.argv) > 2 else ""
tipo = sys.argv[3] if len(sys.argv) > 3 else ""
email_cliente = sys.argv[4] if len(sys.argv) > 4 else ""
consulta_id = sys.argv[5] if len(sys.argv) > 5 else ""

if not all([cpf, nome, email_cliente]):
    sys.exit(1)

ciclo = date.today().strftime("%Y-%m")
cpf_fmt = f"{cpf[:3]}.{cpf[3:6]}.{cpf[6:9]}-{cpf[9:11]}"

# Buscar dados do Supabase
sb_url = os.environ.get("SUPABASE_URL", "")
sb_key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")
hdrs = {"apikey": sb_key, "Authorization": f"Bearer {sb_key}"}

r = requests.get(f"{sb_url}/rest/v1/sub_pf_resultados?cpf=eq.{cpf_fmt}&ciclo=eq.{ciclo}", headers=hdrs, timeout=20)
resultado = r.json()[0] if r.ok and r.json() else {}
score = resultado.get("score_risco", 0)
faixa = resultado.get("faixa_risco", "desconhecida")

r = requests.get(f"{sb_url}/rest/v1/sub_pf_alertas?cpf=eq.{cpf_fmt}&ciclo=eq.{ciclo}", headers=hdrs, timeout=20)
alertas = r.json() if r.ok else []
n_criticos = sum(1 for a in alertas if a.get("severidade") == "critico")
n_atencao = sum(1 for a in alertas if a.get("severidade") == "atencao")

r = requests.get(f"{sb_url}/rest/v1/sub_pf_dados?cpf=eq.{cpf_fmt}&ciclo=eq.{ciclo}", headers=hdrs, timeout=20)
dados = r.json() if r.ok else []

# Gerar PDF profissional
pdf_buffer = io.BytesIO()
c = canvas.Canvas(pdf_buffer, pagesize=A4)
width, height = A4

# Cores
color_header = HexColor("#0f172a")
color_accent = HexColor("#3b82f6")
color_danger = HexColor("#dc2626")
color_warning = HexColor("#d97706")
color_success = HexColor("#16a34a")
color_bg = HexColor("#f8fafc")

y = height - 50

# Cabeçalho
c.setFont("Helvetica-Bold", 20)
c.setFillColor(color_header)
c.drawString(50, y, "SUBRADAR PF")
y -= 25

c.setFont("Helvetica", 11)
c.setFillColor(HexColor("#64748b"))
c.drawString(50, y, "Dossiê de Compliance Pessoal")
y -= 35

# Divisor
c.setStrokeColor(HexColor("#e2e8f0"))
c.setLineWidth(1)
c.line(50, y, width - 50, y)
y -= 20

# Info básica
c.setFont("Helvetica", 10)
c.setFillColor(color_header)
c.drawString(50, y, f"Consultado: {nome}")
y -= 15
c.drawString(50, y, f"CPF: {cpf_fmt}")
y -= 15
c.drawString(50, y, f"Tipo de Consulta: {tipo.upper()}")
y -= 15
c.drawString(50, y, f"Data: {date.today().strftime('%d/%m/%Y')}")
y -= 30

# Score destacado
score_color = color_success if score < 40 else color_warning if score < 70 else color_danger
score_label = "RISCO BAIXO" if score < 40 else "RISCO MÉDIO" if score < 70 else "RISCO ALTO"

# Fundo do score
c.setFillColor(HexColor("#f1f5f9"))
c.rect(50, y - 60, 150, 60, fill=True, stroke=False)

c.setFont("Helvetica-Bold", 32)
c.setFillColor(score_color)
c.drawString(65, y - 40, str(score))

c.setFont("Helvetica-Bold", 10)
c.setFillColor(score_color)
c.drawString(65, y - 55, score_label)

# Info do score
c.setFont("Helvetica", 9)
c.setFillColor(color_header)
c.drawString(220, y - 40, f"Faixa de Risco: {faixa.upper()}")
c.drawString(220, y - 55, f"Alertas Críticos: {n_criticos}")

y -= 90

# Seção de alertas
c.setFont("Helvetica-Bold", 12)
c.setFillColor(color_header)
c.drawString(50, y, "RESUMO DE ALERTAS")
y -= 20

# Tabela de alertas
c.setFont("Helvetica", 9)
labels = ["CRÍTICOS", "ATENÇÃO", "TOTAL"]
values = [str(n_criticos), str(n_atencao), str(len(alertas))]
col_width = 100

for i, (label, value) in enumerate(zip(labels, values)):
    x = 50 + (i * col_width)

    c.setFillColor(HexColor("#f1f5f9"))
    c.rect(x, y - 25, col_width - 10, 25, fill=True, stroke=True)

    c.setFont("Helvetica-Bold", 10)
    c.setFillColor(color_header)
    c.drawString(x + 30, y - 8, value)

    c.setFont("Helvetica", 8)
    c.setFillColor(HexColor("#64748b"))
    c.drawString(x + 20, y - 18, label)

y -= 45

# Alertas detalhados
if alertas:
    c.setFont("Helvetica-Bold", 12)
    c.setFillColor(color_header)
    c.drawString(50, y, "ALERTAS DETALHADOS")
    y -= 18

    c.setFont("Helvetica", 8)
    for alerta in alertas[:8]:  # Primeiros 8 alertas
        severidade = alerta.get('severidade', 'info').upper()
        cor_sev = color_danger if severidade == 'CRITICO' else color_warning

        c.setFillColor(cor_sev)
        c.drawString(50, y, f"• {alerta.get('titulo', 'N/A')[:60]}")
        y -= 12

        if y < 100:  # Nova página se necessário
            c.showPage()
            y = height - 50

y -= 10

# Rodapé
c.setFont("Helvetica", 8)
c.setFillColor(HexColor("#94a3b8"))
c.drawString(50, 30, "Dossiê gerado automaticamente pelo Subradar.")
c.drawString(50, 20, "Lessa Labs Tecnologia Ltda • CNPJ 65.659.055/0001-53")

c.showPage()
c.save()

pdf_buffer.seek(0)
pdf_bytes = pdf_buffer.getvalue()
pdf_content = base64.b64encode(pdf_bytes).decode('utf-8')

# HTML
html = f"""<!DOCTYPE html>
<html>
<head><title>Dossiê Subradar PF</title></head>
<body style="font-family:system-ui,-apple-system,sans-serif;padding:20px;background:#f8fafc">
  <div style="max-width:600px;margin:auto;background:white;padding:20px;border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,0.1)">
    <h1 style="color:#0f172a;margin:0 0 16px">Subradar PF — Dossiê de Compliance</h1>
    <div style="background:#f1f5f9;padding:12px;border-radius:6px;margin-bottom:16px">
      <p style="margin:4px 0"><strong>Nome:</strong> {nome}</p>
      <p style="margin:4px 0"><strong>CPF:</strong> {cpf_fmt}</p>
      <p style="margin:4px 0"><strong>Score de Risco:</strong> <span style="font-size:24px;color:#dc2626;font-weight:bold">{score}</span>/100</p>
      <p style="margin:4px 0"><strong>Alertas críticos:</strong> {n_criticos}</p>
      <p style="margin:4px 0"><strong>Data:</strong> {date.today().strftime("%d/%m/%Y")}</p>
    </div>
    <div style="padding:12px;background:#f0f9ff;border-radius:6px;margin-bottom:16px;border-left:4px solid #3b82f6">
      <p style="margin:0;font-size:12px;color:#1e40af">📎 <strong>PDF profissional anexado</strong></p>
    </div>
    <hr style="border:none;border-top:1px solid #e2e8f0;margin:20px 0">
    <p style="font-size:12px;color:#64748b;margin:0">Dossiê gerado automaticamente pelo Subradar em {date.today().strftime("%d/%m/%Y")}.</p>
  </div>
</body>
</html>"""

# Enviar via Resend
resend_key = os.environ.get("RESEND_API_KEY", "")
if not resend_key:
    sys.exit(1)

payload = {
    "from": "retorno@subradar.com.br",
    "to": email_cliente,
    "subject": f"Subradar PF — {nome} · Score {score}",
    "html": html,
    "attachments": [
        {
            "filename": f"dossiee_{cpf_fmt.replace('.', '').replace('-', '')}.pdf",
            "content": pdf_content,
        }
    ]
}

resp = requests.post(
    "https://api.resend.com/emails",
    json=payload,
    headers={"Authorization": f"Bearer {resend_key}"},
    timeout=30,
)

if resp.ok:
    print(f"✅ Email enviado", flush=True)
    sys.exit(0)
else:
    print(f"❌ Erro: {resp.status_code}", flush=True)
    sys.exit(1)
