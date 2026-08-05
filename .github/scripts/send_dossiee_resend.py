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

y = height - 50

# Cabeçalho profissional
c.setFont("Helvetica-Bold", 18)
c.setFillColor(color_dark)
c.drawString(50, y, "SUBRADAR")
y -= 22

c.setFont("Helvetica", 10)
c.setFillColor(HexColor("#64748b"))
c.drawString(50, y, "INTELIGÊNCIA CORPORATIVA")
y -= 40

# Banner colorido com dados principais
banner_top = y
c.setFillColor(color_red)
c.rect(0, y - 100, width, 100, fill=True, stroke=False)

# Score grande no banner (esquerda)
c.setFont("Helvetica-Bold", 56)
c.setFillColor(HexColor("#ffffff"))
c.drawString(60, y - 60, str(score))

# Faixa de risco (abaixo do score)
c.setFont("Helvetica-Bold", 13)
faixa_upper = faixa.upper()
c.setFillColor(HexColor("#ffffff"))
c.drawString(60, y - 82, faixa_upper)

# Info no banner (direita)
c.setFont("Helvetica-Bold", 12)
c.setFillColor(HexColor("#ffffff"))
c.drawString(300, y - 50, f"{nome}")

c.setFont("Helvetica", 11)
c.drawString(300, y - 68, f"CPF: {cpf_fmt}")
c.drawString(300, y - 86, f"Data: {date.today().strftime('%d/%m/%Y')}")

y -= 120

# Resumo KPIs
c.setFont("Helvetica-Bold", 11)
c.setFillColor(color_dark)
c.drawString(50, y, "RESUMO")
y -= 25

# Tabela de KPIs
col_width = 120
kpis = [("FONTES", "34"), ("ALERTAS", str(len(alertas))), ("CRÍTICOS", str(n_criticos))]

for i, (label, value) in enumerate(kpis):
    x = 50 + (i * col_width)

    # Fundo
    c.setFillColor(HexColor("#f8fafc"))
    c.rect(x, y - 60, col_width - 5, 60, fill=True, stroke=True)
    c.setStrokeColor(HexColor("#cbd5e1"))
    c.setLineWidth(1)

    # Valor grande
    c.setFont("Helvetica-Bold", 28)
    c.setFillColor(color_dark)
    c.drawString(x + 30, y - 28, value)

    # Label
    c.setFont("Helvetica-Bold", 9)
    c.setFillColor(HexColor("#475569"))
    c.drawString(x + 15, y - 50, label)

y -= 85

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
    y -= 22

    c.setFont("Helvetica", 9)
    for cat, items in sorted(categorias.items()):
        cat_label = cat.replace('_', ' ').title()

        # Cabeçalho da categoria
        c.setFillColor(HexColor("#e8eef7"))
        c.rect(50, y - 22, 500, 22, fill=True, stroke=True)
        c.setStrokeColor(HexColor("#cbd5e1"))
        c.setLineWidth(0.5)

        c.setFont("Helvetica-Bold", 10)
        c.setFillColor(color_dark)
        c.drawString(60, y - 15, cat_label)

        y -= 28

        # Itens da categoria
        for item in items[:3]:
            status = item.get('status', 'N/A')
            status_upper = status.upper()

            if status_upper == 'LIMPO':
                status_color = color_green
            elif status_upper == 'CRITICO':
                status_color = color_red
            else:
                status_color = color_orange

            c.setFont("Helvetica", 9)
            c.setFillColor(color_dark)
            c.drawString(70, y, f"• {item.get('titulo_secao', 'N/A')[:48]}")

            c.setFont("Helvetica-Bold", 9)
            c.setFillColor(status_color)
            c.drawString(430, y, status_upper)

            y -= 16

        y -= 8

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
