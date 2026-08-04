#!/usr/bin/env python3
"""Send Subradar PF dossiê via Resend email API with professional PDF."""

import os
import sys
import requests
import base64
import io
from datetime import date

try:
    from reportlab.lib.pagesizes import A4, letter
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib.units import inch, cm
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, Image
    from reportlab.lib import colors
    HAS_REPORTLAB = True
except ImportError:
    HAS_REPORTLAB = False

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

# Gerar PDF se reportlab disponível
pdf_base64 = None
if HAS_REPORTLAB:
    try:
        pdf_buffer = io.BytesIO()
        doc = SimpleDocTemplate(pdf_buffer, pagesize=A4, topMargin=1*cm, bottomMargin=1*cm, leftMargin=1.5*cm, rightMargin=1.5*cm)
        story = []
        styles = getSampleStyleSheet()

        # Estilos customizados
        title_style = ParagraphStyle('Title', parent=styles['Heading1'], fontSize=24, textColor=colors.HexColor('#0f172a'), fontName='Helvetica-Bold', spaceAfter=6, alignment=1)
        subtitle_style = ParagraphStyle('Subtitle', parent=styles['Normal'], fontSize=10, textColor=colors.HexColor('#64748b'), spaceAfter=16, alignment=1)
        section_style = ParagraphStyle('Section', parent=styles['Heading2'], fontSize=13, textColor=colors.HexColor('#ffffff'), fontName='Helvetica-Bold', spaceAfter=8, backColor=colors.HexColor('#0f172a'), leftIndent=6, rightIndent=6, topPadding=6, bottomPadding=6)
        normal_style = ParagraphStyle('Normal', parent=styles['Normal'], fontSize=9, textColor=colors.HexColor('#0f172a'), spaceAfter=4)
        footer_style = ParagraphStyle('Footer', parent=styles['Normal'], fontSize=7, textColor=colors.HexColor('#94a3b8'), spaceAfter=0)

        # Cabeçalho
        story.append(Paragraph("SUBRADAR PF", title_style))
        story.append(Paragraph("Dossiê de Compliance Pessoal", subtitle_style))
        story.append(Spacer(1, 12))

        # Info básica
        info_data = [
            ['CONSULTADO', 'CPF', 'TIPO DE CONSULTA', 'DATA'],
            [nome, cpf_fmt, tipo.upper(), date.today().strftime("%d/%m/%Y")]
        ]
        info_table = Table(info_data, colWidths=[3*cm, 3*cm, 3*cm, 3*cm])
        info_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#f1f5f9')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.HexColor('#0f172a')),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 9),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 8),
            ('BACKGROUND', (0, 1), (-1, 1), colors.HexColor('#ffffff')),
            ('TEXTCOLOR', (0, 1), (-1, 1), colors.HexColor('#0f172a')),
            ('FONTSIZE', (0, 1), (-1, 1), 9),
            ('TOPPADDING', (0, 1), (-1, 1), 6),
            ('BOTTOMPADDING', (0, 1), (-1, 1), 6),
            ('GRID', (0, 0), (-1, -1), 1, colors.HexColor('#e2e8f0')),
        ]))
        story.append(info_table)
        story.append(Spacer(1, 16))

        # Score de Risco (destaque visual)
        score_color = colors.HexColor('#16a34a') if score < 40 else colors.HexColor('#d97706') if score < 70 else colors.HexColor('#dc2626')
        score_label = 'RISCO BAIXO' if score < 40 else 'RISCO MÉDIO' if score < 70 else 'RISCO ALTO'

        story.append(Paragraph('SCORE DE RISCO', section_style))
        story.append(Spacer(1, 8))

        score_data = [
            [f'{score}', f'{score_label}', f'Faixa: {faixa.upper()}']
        ]
        score_table = Table(score_data, colWidths=[2*cm, 4*cm, 4*cm])
        score_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (0, 0), score_color),
            ('TEXTCOLOR', (0, 0), (0, 0), colors.HexColor('#ffffff')),
            ('FONTNAME', (0, 0), (0, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (0, 0), 32),
            ('ALIGN', (0, 0), (0, 0), 'CENTER'),
            ('VALIGN', (0, 0), (-1, 0), 'MIDDLE'),
            ('TOPPADDING', (0, 0), (0, 0), 12),
            ('BOTTOMPADDING', (0, 0), (0, 0), 12),
            ('BACKGROUND', (1, 0), (-1, 0), colors.HexColor('#f8fafc')),
            ('TEXTCOLOR', (1, 0), (-1, 0), colors.HexColor('#0f172a')),
            ('FONTSIZE', (1, 0), (-1, 0), 10),
            ('FONTNAME', (1, 0), (-1, 0), 'Helvetica-Bold'),
            ('ALIGN', (1, 0), (-1, 0), 'LEFT'),
            ('VALIGN', (1, 0), (-1, 0), 'MIDDLE'),
            ('TOPPADDING', (1, 0), (-1, 0), 10),
            ('BOTTOMPADDING', (1, 0), (-1, 0), 10),
            ('GRID', (0, 0), (-1, -1), 1, colors.HexColor('#e2e8f0')),
        ]))
        story.append(score_table)
        story.append(Spacer(1, 16))

        # Resumo de alertas
        story.append(Paragraph('RESUMO DE ALERTAS', section_style))
        story.append(Spacer(1, 8))

        alerts_data = [
            ['CRÍTICOS', 'ATENÇÃO', 'TOTAL'],
            [str(n_criticos), str(n_atencao), str(len(alertas))]
        ]
        alerts_table = Table(alerts_data, colWidths=[3*cm, 3*cm, 3*cm])
        alerts_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#0f172a')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.HexColor('#ffffff')),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 9),
            ('ALIGN', (0, 0), (-1, 0), 'CENTER'),
            ('TOPPADDING', (0, 0), (-1, 0), 8),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 8),
            ('BACKGROUND', (0, 1), (-1, 1), colors.HexColor('#f8fafc')),
            ('TEXTCOLOR', (0, 1), (-1, 1), colors.HexColor('#0f172a')),
            ('FONTSIZE', (0, 1), (-1, 1), 10),
            ('FONTNAME', (0, 1), (-1, 1), 'Helvetica-Bold'),
            ('ALIGN', (0, 1), (-1, 1), 'CENTER'),
            ('TOPPADDING', (0, 1), (-1, 1), 8),
            ('BOTTOMPADDING', (0, 1), (-1, 1), 8),
            ('GRID', (0, 0), (-1, -1), 1, colors.HexColor('#e2e8f0')),
        ]))
        story.append(alerts_table)
        story.append(Spacer(1, 16))

        # Alertas detalhados
        if alertas:
            story.append(Paragraph('ALERTAS DETALHADOS', section_style))
            story.append(Spacer(1, 8))

            for alerta in alertas[:15]:  # Limita a 15 alertas
                severidade = alerta.get('severidade', 'info').upper()
                cor_sev = colors.HexColor('#dc2626') if severidade == 'CRITICO' else colors.HexColor('#d97706')

                story.append(Paragraph(f"<b>• {alerta.get('titulo', 'N/A')}</b>", ParagraphStyle('AlertTitle', parent=normal_style, textColor=cor_sev, spaceAfter=2)))
                story.append(Paragraph(alerta.get('descricao', ''), ParagraphStyle('AlertDesc', parent=normal_style, fontSize=8, leftIndent=12, spaceAfter=8)))

            story.append(Spacer(1, 16))

        # Dados por categoria
        categorias = {}
        for d in dados:
            cat = d.get("categoria", "outro")
            if cat not in categorias:
                categorias[cat] = []
            categorias[cat].append(d)

        if categorias:
            story.append(Paragraph('RESUMO POR CATEGORIA', section_style))
            story.append(Spacer(1, 8))

            for cat, items in sorted(categorias.items()):
                cat_label = cat.replace('_', ' ').title()
                story.append(Paragraph(f"<b>{cat_label}</b>", ParagraphStyle('CatTitle', parent=normal_style, fontSize=10, spaceAfter=4)))

                for item in items[:3]:  # Limita a 3 itens por categoria
                    status = item.get('status', 'n/a').upper()
                    status_color = colors.HexColor('#16a34a') if status == 'LIMPO' else colors.HexColor('#d97706')
                    story.append(Paragraph(f"  • {item.get('titulo_secao', 'N/A')}: <font color='#{status_color[1:]}'>{status}</font>", ParagraphStyle('CatItem', parent=normal_style, fontSize=8, spaceAfter=3)))

                story.append(Spacer(1, 8))

        # Rodapé
        story.append(Spacer(1, 20))
        story.append(Paragraph('_' * 100, footer_style))
        story.append(Spacer(1, 6))
        story.append(Paragraph(f"Dossiê gerado em {date.today().strftime('%d/%m/%Y às %H:%M')} pelo Subradar PF.", footer_style))
        story.append(Paragraph("As informações são obtidas de fontes públicas autorizadas. Lessa Labs Tecnologia Ltda · CNPJ 65.659.055/0001-53", footer_style))
        story.append(Paragraph("Este dossiê é confidencial e destinado apenas ao consultante.", footer_style))

        doc.build(story)
        pdf_buffer.seek(0)
        pdf_bytes = pdf_buffer.getvalue()
        pdf_size = len(pdf_bytes)
        pdf_base64 = base64.b64encode(pdf_bytes).decode('utf-8')
        print(f"DEBUG: PDF gerado: {pdf_size} bytes, base64: {len(pdf_base64)} chars", flush=True)
    except Exception as e:
        print(f"DEBUG: Erro ao gerar PDF: {e}", flush=True)

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
      <p style="margin:0;font-size:12px;color:#1e40af">📎 <strong>PDF profissional anexado</strong> com análise completa</p>
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
}

if pdf_base64:
    payload["attachments"] = [{
        "filename": f"subradar_pf_{cpf_fmt.replace('.', '').replace('-', '')}.pdf",
        "content": pdf_base64,
    }]
    print(f"DEBUG: Anexo adicionado ao payload", flush=True)
else:
    print(f"DEBUG: Nenhum PDF para anexar", flush=True)

resp = requests.post(
    "https://api.resend.com/emails",
    json=payload,
    headers={"Authorization": f"Bearer {resend_key}"},
    timeout=30,
)

if resp.ok:
    print(f"✅ Email enviado para {email_cliente}", flush=True)
    sys.exit(0)
else:
    print(f"❌ Erro Resend: {resp.status_code} - {resp.text}", flush=True)
    sys.exit(1)
