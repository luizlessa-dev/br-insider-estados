#!/usr/bin/env python3
"""Send Subradar PF dossiê via Resend email API with PDF attachment."""

import os
import sys
import requests
import base64
import io
from datetime import date
from reportlab.lib.pagesizes import letter, A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak
from reportlab.lib import colors

cpf = sys.argv[1] if len(sys.argv) > 1 else ""
nome = sys.argv[2] if len(sys.argv) > 2 else ""
tipo = sys.argv[3] if len(sys.argv) > 3 else ""
email_cliente = sys.argv[4] if len(sys.argv) > 4 else ""
consulta_id = sys.argv[5] if len(sys.argv) > 5 else ""

if not all([cpf, nome, email_cliente]):
    print("❌ Parâmetros inválidos")
    sys.exit(1)

ciclo = date.today().strftime("%Y-%m")
cpf_fmt = f"{cpf[:3]}.{cpf[3:6]}.{cpf[6:9]}-{cpf[9:11]}"

# Buscar dados do Supabase
sb_url = os.environ.get("SUPABASE_URL", "")
sb_key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")
hdrs = {"apikey": sb_key, "Authorization": f"Bearer {sb_key}"}

# Score
r = requests.get(f"{sb_url}/rest/v1/sub_pf_resultados?cpf=eq.{cpf_fmt}&ciclo=eq.{ciclo}", headers=hdrs, timeout=20)
resultado = r.json()[0] if r.ok and r.json() else {}
score = resultado.get("score_risco", 0)
faixa = resultado.get("faixa_risco", "desconhecida")

# Alertas
r = requests.get(f"{sb_url}/rest/v1/sub_pf_alertas?cpf=eq.{cpf_fmt}&ciclo=eq.{ciclo}", headers=hdrs, timeout=20)
alertas = r.json() if r.ok else []
n_criticos = sum(1 for a in alertas if a.get("severidade") == "critico")
n_atencao = sum(1 for a in alertas if a.get("severidade") == "atencao")

# Dados
r = requests.get(f"{sb_url}/rest/v1/sub_pf_dados?cpf=eq.{cpf_fmt}&ciclo=eq.{ciclo}", headers=hdrs, timeout=20)
dados = r.json() if r.ok else []

# Gerar PDF
pdf_buffer = io.BytesIO()
doc = SimpleDocTemplate(pdf_buffer, pagesize=A4, topMargin=0.5*inch, bottomMargin=0.5*inch)
story = []
styles = getSampleStyleSheet()

# Estilos customizados
title_style = ParagraphStyle(
    'CustomTitle',
    parent=styles['Heading1'],
    fontSize=18,
    textColor=colors.HexColor('#0f172a'),
    fontName='Helvetica-Bold',
    spaceAfter=6,
)
heading_style = ParagraphStyle(
    'CustomHeading',
    parent=styles['Heading2'],
    fontSize=12,
    textColor=colors.HexColor('#0f172a'),
    fontName='Helvetica-Bold',
    spaceAfter=8,
    spaceBefore=10,
)
normal_style = ParagraphStyle(
    'CustomNormal',
    parent=styles['Normal'],
    fontSize=10,
    textColor=colors.HexColor('#0f172a'),
    spaceAfter=4,
)

# Cabeçalho
story.append(Paragraph("SUBRADAR PF — COMPLIANCE PESSOAL", title_style))
story.append(Spacer(1, 6))
story.append(Paragraph(f"<b>{nome}</b>", heading_style))
story.append(Paragraph(f"CPF: {cpf_fmt} • Consulta: {tipo.capitalize()} • Data: {date.today().strftime('%d/%m/%Y')}", normal_style))
story.append(Spacer(1, 12))

# Score
score_label = "Risco Alto" if score >= 70 else "Risco Médio" if score >= 40 else "Risco Baixo"
story.append(Paragraph(f"<b>Score de Risco: {score}/100 ({score_label}) • Faixa: {faixa}</b>", heading_style))
story.append(Spacer(1, 12))

# Resumo de alertas
if n_criticos > 0:
    story.append(Paragraph(f"⚠️ <b>{n_criticos} alerta(s) crítico(s) encontrado(s)</b>", normal_style))
elif n_atencao > 0:
    story.append(Paragraph(f"⚠️ <b>{n_atencao} ponto(s) de atenção identificado(s)</b>", normal_style))
else:
    story.append(Paragraph("✓ <b>Nenhuma ocorrência encontrada</b>", normal_style))
story.append(Spacer(1, 12))

# Dados por categoria
categorias = {}
for d in dados:
    cat = d.get("categoria", "outro")
    if cat not in categorias:
        categorias[cat] = []
    categorias[cat].append(d)

for cat, items in categorias.items():
    story.append(Paragraph(cat.upper(), heading_style))
    for item in items:
        status = item.get("status", "N/A").upper()
        story.append(Paragraph(f"<b>{item.get('titulo_secao', 'N/A')}</b> [{status}]", ParagraphStyle('Item', parent=normal_style, fontSize=9)))
        story.append(Paragraph(item.get("resumo", ""), ParagraphStyle('ItemDetail', parent=normal_style, fontSize=8)))
        story.append(Spacer(1, 4))
    story.append(Spacer(1, 8))

# Rodapé
story.append(Spacer(1, 12))
story.append(Paragraph(
    "Dossiê gerado pelo Subradar em " + date.today().strftime("%d/%m/%Y") +
    ". As informações são obtidas de fontes públicas autorizadas. Lessa Labs Tecnologia Ltda · CNPJ 65.659.055/0001-53",
    ParagraphStyle('Footer', parent=normal_style, fontSize=8, textColor=colors.HexColor('#64748b'))
))

doc.build(story)
pdf_buffer.seek(0)
pdf_base64 = base64.b64encode(pdf_buffer.getvalue()).decode('utf-8')

# HTML para email
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
      <p style="margin:0;font-size:12px;color:#1e40af">📎 <strong>PDF anexado</strong> com todos os detalhes do dossiê</p>
    </div>
    <hr style="border:none;border-top:1px solid #e2e8f0;margin:20px 0">
    <p style="font-size:12px;color:#64748b;margin:0">Dossiê gerado automaticamente pelo Subradar em {date.today().strftime("%d/%m/%Y")}. As informações são obtidas de fontes públicas autorizadas.</p>
  </div>
</body>
</html>"""

# Enviar via Resend
resend_key = os.environ.get("RESEND_API_KEY", "")
if not resend_key:
    print("❌ RESEND_API_KEY não configurada")
    sys.exit(1)

payload = {
    "from": "retorno@subradar.com.br",
    "to": email_cliente,
    "subject": f"Subradar PF — {nome} · Score {score}",
    "html": html,
    "attachments": [
        {
            "filename": f"subradar_pf_{cpf_fmt.replace('.', '').replace('-', '')}.pdf",
            "content": pdf_base64,
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
    print(f"✅ Email com PDF enviado para {email_cliente}")
    sys.exit(0)
else:
    print(f"❌ Erro Resend: {resp.status_code} — {resp.text}")
    sys.exit(1)
