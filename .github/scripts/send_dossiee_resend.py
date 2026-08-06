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

r = requests.get(f"{sb_url}/rest/v1/sub_pf_dados?cpf=eq.{cpf_fmt}&ciclo=eq.{ciclo}", headers=hdrs, timeout=20)
dados = r.json() if r.ok else []

# Contar fontes por status
fontes_ok = sum(1 for d in dados if d.get("status", "").upper() == "LIMPO")
fontes_pendente = sum(1 for d in dados if d.get("status", "").upper() == "PENDENTE")
fontes_critico = sum(1 for d in dados if d.get("status", "").upper() == "CRITICO")
total_fontes = len(dados)

# Definir cor do banner baseado no score
def get_banner_color(score_val):
    if score_val <= 20:
        return HexColor("#16a34a")  # VERDE
    elif score_val <= 50:
        return HexColor("#d97706")  # AMARELO/LARANJA
    elif score_val <= 80:
        return HexColor("#dc2626")  # VERMELHO
    else:
        return HexColor("#7f1d1d")  # VERMELHO ESCURO (CRÍTICO)

def get_faixa_color(score_val):
    if score_val <= 20:
        return "BAIXO"
    elif score_val <= 50:
        return "MÉDIO"
    elif score_val <= 80:
        return "ALTO"
    else:
        return "CRÍTICO"

banner_color = get_banner_color(score)
faixa_label = get_faixa_color(score)

# Cores
color_dark_bg = HexColor("#0f172a")
color_green = HexColor("#16a34a")
color_orange = HexColor("#d97706")
color_red = HexColor("#dc2626")
color_gray_dark = HexColor("#1f2937")
color_gray_light = HexColor("#f3f4f6")
color_gray_text = HexColor("#6b7280")
color_white = HexColor("#ffffff")

# Gerar PDF multi-página
pdf_buffer = io.BytesIO()
c = canvas.Canvas(pdf_buffer, pagesize=A4)
width, height = A4
page_num = 0
y = height

def new_page():
    global page_num, y
    if page_num > 0:
        c.showPage()
    page_num += 1
    y = height
    draw_header()
    y -= 60

def draw_header():
    """Header dark com logo e data"""
    c.setFillColor(color_dark_bg)
    c.rect(0, height - 50, width, 50, fill=True, stroke=False)

    c.setFont("Helvetica-Bold", 14)
    c.setFillColor(color_white)
    c.drawString(50, height - 30, "SUBRADAR")

    c.setFont("Helvetica", 9)
    c.setFillColor(color_gray_text)
    c.drawString(50, height - 42, "INTELIGÊNCIA CORPORATIVA")

    c.setFont("Helvetica", 9)
    c.setFillColor(color_gray_text)
    c.drawRightString(width - 50, height - 30, "DOSSIÊ DE COMPLIANCE")
    c.drawRightString(width - 50, height - 42, today)

# Página 1: Banner + Resumo
new_page()

# Banner colorido com cor dinâmica
c.setFillColor(banner_color)
c.rect(0, y - 120, width, 120, fill=True, stroke=False)

c.setFont("Helvetica-Bold", 16)
c.setFillColor(color_white)
c.drawString(50, y - 40, nome.upper())

c.setFont("Helvetica", 11)
c.drawString(50, y - 58, f"CPF {cpf_fmt} · Ciclo {ciclo}")

# Score grande (direita)
c.setFont("Helvetica-Bold", 56)
c.drawRightString(width - 50, y - 50, str(score))

# Faixa (direita, embaixo do score)
c.setFont("Helvetica-Bold", 13)
c.drawRightString(width - 50, y - 85, faixa_label)

# KPIs (direita, embaixo)
c.setFont("Helvetica", 10)
kpi_str = f"{total_fontes} FONTES  {fontes_ok} OK  {len(alertas)} ALERTAS"
c.drawRightString(width - 50, y - 105, kpi_str)

y -= 140

# Resumo de categorias
c.setFont("Helvetica-Bold", 12)
c.setFillColor(color_dark_bg)
c.drawString(50, y, "RESUMO DAS FONTES CONSULTADAS")
y -= 20

# Tabela de categorias
c.setFillColor(color_gray_dark)
c.rect(50, y - 20, width - 100, 20, fill=True, stroke=False)

c.setFont("Helvetica-Bold", 10)
c.setFillColor(color_white)
c.drawString(60, y - 15, "CATEGORIA")
c.drawString(250, y - 15, "LIMPO")
c.drawString(350, y - 15, "PENDENTE")
c.drawString(450, y - 15, "CRÍTICO")

y -= 20

# Agrupar por categoria
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

row_num = 0
for cat in sorted(categorias.keys()):
    counts = categorias[cat]

    bg_color = color_gray_light if row_num % 2 == 0 else color_white
    c.setFillColor(bg_color)
    c.rect(50, y - 18, width - 100, 18, fill=True, stroke=False)

    c.setLineWidth(0.5)
    c.setStrokeColor(HexColor("#e5e7eb"))
    c.rect(50, y - 18, width - 100, 18, fill=False, stroke=True)

    c.setFont("Helvetica", 9)
    c.setFillColor(color_dark_bg)
    c.drawString(60, y - 12, cat.replace("_", " ").title())
    c.drawString(250, y - 12, str(counts["limpo"]))
    c.drawString(350, y - 12, str(counts["pendente"]))
    c.drawString(450, y - 12, str(counts["critico"]))

    y -= 18
    row_num += 1

    if y < 100:
        new_page()

# Página 2+: Lista completa de fontes
y -= 20

c.setFont("Helvetica-Bold", 12)
c.setFillColor(color_dark_bg)
c.drawString(50, y, "DETALHAMENTO DAS FONTES CONSULTADAS")
y -= 20

# Header tabela de fontes
c.setFillColor(color_gray_dark)
c.rect(50, y - 20, width - 100, 20, fill=True, stroke=False)

c.setFont("Helvetica-Bold", 10)
c.setFillColor(color_white)
c.drawString(60, y - 15, "FONTE")
c.drawString(400, y - 15, "STATUS")

y -= 20

# Listar todas as fontes
row_num = 0
for d in sorted(dados, key=lambda x: (x.get("categoria", ""), x.get("titulo_secao", ""))):
    titulo = d.get("titulo_secao", "N/A")
    status = d.get("status", "PENDENTE").upper()
    descricao = d.get("resumo", "") or d.get("descricao", "") or d.get("resultado", "") or ""

    # Determinar cor do status
    if status == "LIMPO":
        status_color = color_green
    elif status == "CRITICO":
        status_color = color_red
    else:
        status_color = color_orange

    # Calcular altura da linha (pode ter múltiplas linhas se descrição for longa)
    desc_text = descricao[:60] if descricao else "—"
    line_height = 18
    if descricao:  # Mostrar descrição para qualquer status com dados
        line_height = 28

    # Check se precisa nova página
    if y < (line_height + 20):
        new_page()

    # Linha da tabela
    bg_color = color_gray_light if row_num % 2 == 0 else color_white
    c.setFillColor(bg_color)
    c.rect(50, y - line_height, width - 100, line_height, fill=True, stroke=False)

    c.setLineWidth(0.5)
    c.setStrokeColor(HexColor("#e5e7eb"))
    c.rect(50, y - line_height, width - 100, line_height, fill=False, stroke=True)

    # Fonte
    c.setFont("Helvetica", 9)
    c.setFillColor(color_dark_bg)
    c.drawString(60, y - 12, titulo[:50])

    # Status
    c.setFont("Helvetica-Bold", 9)
    c.setFillColor(status_color)
    c.drawString(400, y - 12, status)

    # Descrição/Resumo (se houver)
    if descricao:
        c.setFont("Helvetica", 8)
        c.setFillColor(color_gray_text)
        c.drawString(60, y - 24, desc_text)

    y -= line_height
    row_num += 1

# Footer na última página
y -= 10
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
      <p style="margin:4px 0"><strong>Score de Risco:</strong> <span style="font-size:24px;font-weight:bold">{score}</span>/100 ({faixa_label})</p>
      <p style="margin:4px 0"><strong>Fontes consultadas:</strong> {total_fontes}</p>
      <p style="margin:4px 0"><strong>Data:</strong> {today}</p>
    </div>
    <div style="padding:12px;background:#f0f9ff;border-radius:6px;margin-bottom:16px;border-left:4px solid #3b82f6">
      <p style="margin:0;font-size:12px;color:#1e40af">📎 <strong>PDF profissional com {page_num} página(s) anexado</strong></p>
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
    "subject": f"Subradar PF — {nome} · Score {score} ({faixa_label})",
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
