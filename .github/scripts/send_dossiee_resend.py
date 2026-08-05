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
today = date.today().strftime("%d/%m/%Y")

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
n_ok = len(alertas) - n_criticos - n_atencao

r = requests.get(f"{sb_url}/rest/v1/sub_pf_dados?cpf=eq.{cpf_fmt}&ciclo=eq.{ciclo}", headers=hdrs, timeout=20)
dados = r.json() if r.ok else []

# Cores profissionais
color_dark_bg = HexColor("#0f172a")
color_red = HexColor("#dc2626")
color_green = HexColor("#16a34a")
color_orange = HexColor("#d97706")
color_gray_dark = HexColor("#1f2937")
color_gray_light = HexColor("#f3f4f6")
color_gray_text = HexColor("#6b7280")
color_white = HexColor("#ffffff")

# Gerar PDF
pdf_buffer = io.BytesIO()
c = canvas.Canvas(pdf_buffer, pagesize=A4)
width, height = A4

def draw_header():
    """Header dark com logo espaço e data"""
    c.setFillColor(color_dark_bg)
    c.rect(0, height - 50, width, 50, fill=True, stroke=False)

    # Logo placeholder (SUBRADAR)
    c.setFont("Helvetica-Bold", 14)
    c.setFillColor(color_white)
    c.drawString(50, height - 30, "SUBRADAR")

    c.setFont("Helvetica", 9)
    c.setFillColor(color_gray_text)
    c.drawString(50, height - 42, "INTELIGÊNCIA CORPORATIVA")

    # Data
    c.setFont("Helvetica", 9)
    c.setFillColor(color_gray_text)
    c.drawRightString(width - 50, height - 30, "DOSSIÊ DE COMPLIANCE")
    c.drawRightString(width - 50, height - 42, today)

def draw_banner():
    """Banner vermelho com score e KPIs"""
    y = height - 50

    # Banner vermelho
    c.setFillColor(color_red)
    c.rect(0, y - 110, width, 110, fill=True, stroke=False)

    # Nome (esquerda)
    c.setFont("Helvetica-Bold", 16)
    c.setFillColor(color_white)
    c.drawString(50, y - 35, nome.upper())

    c.setFont("Helvetica", 11)
    c.drawString(50, y - 52, f"CPF {cpf_fmt} · Ciclo {ciclo}")

    # Score (direita, grande)
    c.setFont("Helvetica-Bold", 48)
    c.setFillColor(color_white)
    c.drawRightString(width - 50, y - 45, str(score))

    # Faixa
    c.setFont("Helvetica-Bold", 12)
    c.drawRightString(width - 50, y - 72, faixa.upper())

    # KPIs na direita (pequeno)
    c.setFont("Helvetica", 9)
    kpi_text = f"{len(dados)} FONTES  {len(alertas)} OK  {n_criticos} ALERTAS"
    c.drawRightString(width - 50, y - 92, kpi_text)

    return y - 110

def draw_section_title(y, title):
    """Desenha título de seção"""
    c.setFont("Helvetica-Bold", 12)
    c.setFillColor(color_dark_bg)
    c.drawString(50, y, title)
    return y - 20

def draw_table_header(y, cols):
    """Desenha header de tabela"""
    col_width = (width - 100) / len(cols)

    c.setFillColor(color_gray_dark)
    c.rect(50, y - 20, width - 100, 20, fill=True, stroke=False)

    c.setFont("Helvetica-Bold", 10)
    c.setFillColor(color_white)

    x = 55
    for col in cols:
        c.drawString(x, y - 15, col)
        x += col_width

    return y - 20

def draw_table_row(y, values, row_num, bg_color=None):
    """Desenha linha de tabela"""
    if bg_color is None:
        bg_color = color_white if row_num % 2 == 0 else color_gray_light

    col_width = (width - 100) / len(values)

    c.setFillColor(bg_color)
    c.rect(50, y - 20, width - 100, 20, fill=True, stroke=False)

    c.setLineWidth(0.5)
    c.setStrokeColor(HexColor("#e5e7eb"))
    c.rect(50, y - 20, width - 100, 20, fill=False, stroke=True)

    c.setFont("Helvetica", 9)
    c.setFillColor(color_dark_bg)

    x = 55
    for val in values:
        c.drawString(x, y - 14, str(val)[:40])
        x += col_width

    return y - 20

# Desenhar PDF
y = height - 50

# Header
draw_header()

# Banner
y = draw_banner()
y -= 20

# Resumo de categorias
y = draw_section_title(y, "RESUMO DAS FONTES CONSULTADAS")
y -= 10

# Tabela de categorias
categorias = {}
for d in dados:
    cat = d.get("categoria", "outro")
    if cat not in categorias:
        categorias[cat] = {"limpo": 0, "pendente": 0, "critico": 0}
    status = d.get("status", "pendente").lower()
    if status == "limpo":
        categorias[cat]["limpo"] += 1
    elif status == "critico":
        categorias[cat]["critico"] += 1
    else:
        categorias[cat]["pendente"] += 1

if categorias:
    y = draw_table_header(y, ["CATEGORIA", "LIMPO", "PENDENTE", "CRÍTICO"])

    row_num = 0
    for cat in sorted(categorias.keys()):
        counts = categorias[cat]
        values = [cat.replace("_", " ").title(), str(counts["limpo"]), str(counts["pendente"]), str(counts["critico"])]
        y = draw_table_row(y, values, row_num)
        row_num += 1

y -= 15

# Alertas se houver
if alertas:
    y = draw_section_title(y, "ALERTAS ENCONTRADOS")
    y -= 10

    y = draw_table_header(y, ["TÍTULO", "SEVERIDADE"])

    row_num = 0
    for alerta in alertas[:10]:
        sev = alerta.get("severidade", "info").upper()
        values = [alerta.get("titulo", "N/A")[:40], sev]
        y = draw_table_row(y, values, row_num)
        row_num += 1

y -= 15

# Metodologia (se espaço)
if y > 200:
    y = draw_section_title(y, "CLASSIFICAÇÃO DE RISCO")
    y -= 8

    c.setFont("Helvetica", 8)
    c.setFillColor(color_dark_bg)
    c.drawString(50, y, "CRÍTICO (30pts) · ATENÇÃO (10pts) · INFORMATIVO (2pts) · OK (0pts)")

# Footer
c.setLineWidth(0.5)
c.setStrokeColor(HexColor("#e5e7eb"))
c.line(50, 45, width - 50, 45)

c.setFont("Helvetica", 8)
c.setFillColor(color_gray_text)
c.drawString(50, 30, "Dossiê gerado automaticamente pelo Subradar")
c.drawString(50, 18, "Lessa Labs Tecnologia Ltda · CNPJ 65.659.055/0001-53")

c.showPage()
c.save()

pdf_buffer.seek(0)
pdf_bytes = pdf_buffer.getvalue()
pdf_content = base64.b64encode(pdf_bytes).decode('utf-8')

# HTML email
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
      <p style="margin:4px 0"><strong>Faixa:</strong> {faixa.upper()}</p>
      <p style="margin:4px 0"><strong>Data:</strong> {today}</p>
    </div>
    <div style="padding:12px;background:#f0f9ff;border-radius:6px;margin-bottom:16px;border-left:4px solid #3b82f6">
      <p style="margin:0;font-size:12px;color:#1e40af">📎 <strong>PDF profissional anexado</strong></p>
    </div>
    <hr style="border:none;border-top:1px solid #e2e8f0;margin:20px 0">
    <p style="font-size:12px;color:#64748b;margin:0">Dossiê gerado automaticamente pelo Subradar em {today}.</p>
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
