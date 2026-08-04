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
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
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
color_dark = HexColor("#0f172a")
color_red = HexColor("#dc2626")
color_green = HexColor("#16a34a")
color_orange = HexColor("#d97706")
color_light_bg = HexColor("#f8fafc")

y = height - 40

# Cabeçalho profissional
c.setFont("Helvetica-Bold", 16)
c.setFillColor(color_dark)
c.drawString(50, y, "SUBRADAR")
y -= 18

c.setFont("Helvetica", 9)
c.setFillColor(HexColor("#64748b"))
c.drawString(50, y, "INTELIGÊNCIA CORPORATIVA")
y -= 35

# Banner colorido com dados principais
c.setFillColor(color_red)
c.rect(0, y - 80, width, 80, fill=True, stroke=False)

# Score grande no banner
c.setFont("Helvetica-Bold", 48)
c.setFillColor(HexColor("#ffffff"))
c.drawString(50, y - 45, str(score))

# Faixa de risco
c.setFont("Helvetica-Bold", 11)
faixa_upper = faixa.upper()
c.drawString(50, y - 65, faixa_upper)

# Info no banner
c.setFont("Helvetica", 10)
c.drawString(280, y - 45, f"{nome}")
c.drawString(280, y - 60, f"CPF: {cpf_fmt}")
c.drawString(280, y - 75, f"Data: {date.today().strftime('%d/%m/%Y')}")

y -= 90

# Resumo KPIs
c.setFont("Helvetica-Bold", 10)
c.setFillColor(color_dark)
c.drawString(50, y, "RESUMO")
y -= 20

# Tabela de KPIs
col_width = 100
kpis = [("FONTES", "34"), ("ALERTAS", str(len(alertas))), ("CRÍTICOS", str(n_criticos))]

for i, (label, value) in enumerate(kpis):
    x = 50 + (i * col_width)

    # Fundo
    c.setFillColor(HexColor("#f1f5f9"))
    c.rect(x, y - 50, col_width - 10, 50, fill=True, stroke=True)
    c.setStrokeColor(HexColor("#e2e8f0"))

    # Valor grande
    c.setFont("Helvetica-Bold", 24)
    c.setFillColor(color_dark)
    c.drawString(x + 25, y - 25, value)

    # Label
    c.setFont("Helvetica", 9)
    c.setFillColor(HexColor("#64748b"))
    c.drawString(x + 10, y - 42, label)

y -= 70

# Seção de alertas
if alertas:
    c.setFont("Helvetica-Bold", 11)
    c.setFillColor(color_dark)
    c.drawString(50, y, "ALERTAS ENCONTRADOS")
    y -= 20

    c.setFont("Helvetica", 9)
    for alerta in alertas[:5]:
        sev = alerta.get('severidade', 'info').upper()
        cor = color_red if sev == 'CRITICO' else color_orange

        c.setFillColor(cor)
        c.drawString(50, y, f"• {alerta.get('titulo', 'N/A')[:55]}")
        y -= 15

        if y < 100:
            c.showPage()
            y = height - 50

    y -= 10
else:
    c.setFont("Helvetica-Bold", 11)
    c.setFillColor(color_green)
    c.drawString(50, y, "✓ Nenhum alerta encontrado")
    y -= 30

# Dados por categoria
categorias = {}
for d in dados:
    cat = d.get("categoria", "outro")
    if cat not in categorias:
        categorias[cat] = []
    categorias[cat].append(d)

if categorias:
    c.setFont("Helvetica-Bold", 11)
    c.setFillColor(color_dark)
    c.drawString(50, y, "RESUMO POR CATEGORIA")
    y -= 18

    c.setFont("Helvetica", 9)
    for cat, items in sorted(categorias.items()):
        cat_label = cat.replace('_', ' ').title()

        c.setFillColor(HexColor("#f1f5f9"))
        c.rect(50, y - 18, 500, 18, fill=True, stroke=True)
        c.setStrokeColor(HexColor("#e2e8f0"))

        c.setFont("Helvetica-Bold", 9)
        c.setFillColor(color_dark)
        c.drawString(55, y - 12, cat_label)

        y -= 22

        for item in items[:2]:
            status = item.get('status', 'N/A')
            status_color = color_green if status.upper() == 'LIMPO' else color_orange

            c.setFont("Helvetica", 8)
            c.setFillColor(color_dark)
            c.drawString(65, y, f"• {item.get('titulo_secao', 'N/A')[:50]}")

            c.setFillColor(status_color)
            c.drawString(450, y, status.upper())

            y -= 12

        y -= 5

# Rodapé
c.setLineWidth(1)
c.setStrokeColor(HexColor("#e2e8f0"))
c.line(50, 50, width - 50, 50)

c.setFont("Helvetica", 8)
c.setFillColor(HexColor("#94a3b8"))
c.drawString(50, 35, "Dossiê gerado automaticamente pelo Subradar")
c.drawString(50, 22, "Lessa Labs Tecnologia Ltda • CNPJ 65.659.055/0001-53")

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
