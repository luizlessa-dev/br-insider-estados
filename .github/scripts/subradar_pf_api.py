#!/usr/bin/env python3
"""
Subradar PF — Simple API backend for dossiê generation.
Called by Lovable frontend via HTTP.
"""
import os
import sys
import json
import base64
from datetime import date
from io import BytesIO

import requests
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from reportlab.lib.colors import HexColor

# Configuration
SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")
RESEND_API_KEY = os.environ.get("RESEND_API_KEY", "")


def fmt_cpf(cpf_digits: str) -> str:
    """Format 11-digit CPF to XXX.XXX.XXX-XX"""
    return f"{cpf_digits[:3]}.{cpf_digits[3:6]}.{cpf_digits[6:9]}-{cpf_digits[9:11]}"


def fetch_data(cpf_fmt: str, ciclo: str) -> dict:
    """Fetch compliance data from Supabase"""
    hdrs = {"apikey": SUPABASE_KEY, "Authorization": f"Bearer {SUPABASE_KEY}"}

    # Resultado (score)
    r = requests.get(f"{SUPABASE_URL}/rest/v1/sub_pf_resultados?cpf=eq.{cpf_fmt}&ciclo=eq.{ciclo}",
                     headers=hdrs, timeout=20)
    resultado = r.json()[0] if r.ok and r.json() else {}

    # Alertas
    r = requests.get(f"{SUPABASE_URL}/rest/v1/sub_pf_alertas?cpf=eq.{cpf_fmt}&ciclo=eq.{ciclo}",
                     headers=hdrs, timeout=20)
    alertas = r.json() if r.ok else []

    # Dados estruturados
    r = requests.get(f"{SUPABASE_URL}/rest/v1/sub_pf_dados?cpf=eq.{cpf_fmt}&ciclo=eq.{ciclo}",
                     headers=hdrs, timeout=20)
    dados = r.json() if r.ok else []

    return {
        "score": resultado.get("score_risco", 0),
        "faixa": resultado.get("faixa_risco", "desconhecida"),
        "alertas": alertas,
        "dados": dados,
    }


def get_banner_color(score: int) -> HexColor:
    """Dynamic banner color based on score"""
    if score <= 20:
        return HexColor("#16a34a")  # VERDE
    elif score <= 50:
        return HexColor("#d97706")  # AMARELO
    elif score <= 80:
        return HexColor("#dc2626")  # VERMELHO
    else:
        return HexColor("#7f1d1d")  # CRÍTICO


def generate_pdf(nome: str, cpf_fmt: str, score: int, dados: list) -> bytes:
    """Generate PDF dossiê"""
    if score <= 20:
        faixa_label = "BAIXO"
    elif score <= 50:
        faixa_label = "MÉDIO"
    elif score <= 80:
        faixa_label = "ALTO"
    else:
        faixa_label = "CRÍTICO"

    banner_color = get_banner_color(score)
    today = date.today().strftime("%d/%m/%Y")

    # Colors
    color_dark_bg = HexColor("#0f172a")
    color_green = HexColor("#16a34a")
    color_orange = HexColor("#d97706")
    color_red = HexColor("#dc2626")
    color_gray_light = HexColor("#f3f4f6")
    color_gray_text = HexColor("#6b7280")
    color_white = HexColor("#ffffff")

    # PDF setup
    pdf_buffer = BytesIO()
    c = canvas.Canvas(pdf_buffer, pagesize=A4)
    width, height = A4
    y = height - 50

    # Header
    c.setFillColor(color_dark_bg)
    c.rect(0, y - 60, width, 60, fill=True)
    c.setFont("Helvetica-Bold", 18)
    c.setFillColor(color_white)
    c.drawString(50, y - 35, "SUBRADAR PF")
    c.setFont("Helvetica", 10)
    c.drawString(50, y - 50, "Dossiê de Compliance")
    y -= 80

    # Score banner
    c.setFillColor(banner_color)
    c.rect(50, y - 80, width - 100, 80, fill=True)
    c.setFont("Helvetica-Bold", 48)
    c.setFillColor(color_white)
    c.drawString(70, y - 50, str(score))
    c.setFont("Helvetica-Bold", 14)
    c.drawString(200, y - 50, f"{faixa_label} RISCO")
    y -= 100

    # Info box
    c.setFont("Helvetica", 10)
    c.setFillColor(color_gray_text)
    c.drawString(50, y, f"CPF: {cpf_fmt}")
    y -= 15
    c.drawString(50, y, f"Nome: {nome}")
    y -= 15
    c.drawString(50, y, f"Data: {today}")
    y -= 30

    # Data table header
    c.setFont("Helvetica-Bold", 10)
    c.setFillColor(color_dark_bg)
    c.drawString(50, y, "FONTE")
    c.drawString(400, y, "STATUS")
    y -= 20

    # Data rows
    for d in sorted(dados, key=lambda x: x.get("titulo_secao", "")):
        titulo = d.get("titulo_secao", "N/A")[:50]
        status = d.get("status", "").upper()
        resumo = d.get("resumo", "")

        # Status color
        if status == "LIMPO":
            status_color = color_green
        elif status == "CRITICO":
            status_color = color_red
        else:
            status_color = color_orange

        # Row background
        c.setFillColor(color_gray_light)
        c.rect(50, y - 18, width - 100, 18, fill=True)
        c.setLineWidth(0.5)
        c.setStrokeColor(HexColor("#e5e7eb"))
        c.rect(50, y - 18, width - 100, 18, fill=False, stroke=True)

        # Texto
        c.setFont("Helvetica", 9)
        c.setFillColor(color_dark_bg)
        c.drawString(60, y - 12, titulo)
        c.setFont("Helvetica-Bold", 9)
        c.setFillColor(status_color)
        c.drawString(400, y - 12, status)

        # Resumo se houver
        if resumo:
            y -= 18
            c.setFont("Helvetica", 8)
            c.setFillColor(color_gray_text)
            c.drawString(60, y - 12, resumo[:60])

        y -= 18

    # Footer
    y = 50
    c.setLineWidth(0.5)
    c.setStrokeColor(HexColor("#e5e7eb"))
    c.line(50, y, width - 50, y)
    c.setFont("Helvetica", 8)
    c.setFillColor(color_gray_text)
    c.drawString(50, y - 15, "Dossiê gerado automaticamente pelo Subradar")
    c.drawString(50, y - 25, "Lessa Labs Tecnologia Ltda · CNPJ 65.659.055/0001-53")

    c.showPage()
    c.save()

    pdf_buffer.seek(0)
    return pdf_buffer.getvalue()


def send_email(nome: str, cpf_fmt: str, email: str, pdf_bytes: bytes, score: int) -> bool:
    """Send email via Resend"""
    if score <= 20:
        faixa = "BAIXO"
    elif score <= 50:
        faixa = "MÉDIO"
    elif score <= 80:
        faixa = "ALTO"
    else:
        faixa = "CRÍTICO"

    pdf_b64 = base64.b64encode(pdf_bytes).decode('utf-8')

    payload = {
        "from": "retorno@subradar.com.br",
        "to": email,
        "subject": f"Subradar PF — {nome} · Score {score} ({faixa})",
        "html": f"""
        <html>
        <body style="font-family: system-ui; padding: 20px; background: #f8fafc;">
        <div style="max-width: 600px; margin: auto; background: white; padding: 20px; border-radius: 8px;">
            <h1 style="color: #0f172a;">Subradar PF — Dossiê de Compliance</h1>
            <p><strong>CPF:</strong> {cpf_fmt}</p>
            <p><strong>Score:</strong> {score}/100 ({faixa})</p>
            <p>📎 PDF profissional anexado</p>
        </div>
        </body>
        </html>
        """,
        "attachments": [{
            "filename": f"dossiee_{cpf_fmt.replace('.', '').replace('-', '')}.pdf",
            "content": pdf_b64,
        }]
    }

    resp = requests.post(
        "https://api.resend.com/emails",
        json=payload,
        headers={"Authorization": f"Bearer {RESEND_API_KEY}"},
        timeout=30,
    )

    return resp.ok


def main():
    """Main entry point"""
    if len(sys.argv) < 5:
        print(json.dumps({"error": "Missing arguments"}))
        sys.exit(1)

    cpf_digits = sys.argv[1]  # 11 digits
    nome = sys.argv[2]
    email = sys.argv[3]
    action = sys.argv[4]  # "generate" or "send"

    cpf_fmt = fmt_cpf(cpf_digits)
    ciclo = date.today().strftime("%Y-%m")

    try:
        # Fetch data
        data = fetch_data(cpf_fmt, ciclo)

        # Generate PDF
        pdf_bytes = generate_pdf(nome, cpf_fmt, data["score"], data["dados"])

        if action == "send":
            # Send email
            if send_email(nome, cpf_fmt, email, pdf_bytes, data["score"]):
                print(json.dumps({"success": True, "message": "Email enviado"}))
            else:
                print(json.dumps({"error": "Falha ao enviar email"}))
                sys.exit(1)
        else:
            # Just return PDF as base64
            pdf_b64 = base64.b64encode(pdf_bytes).decode('utf-8')
            print(json.dumps({
                "success": True,
                "pdf": pdf_b64,
                "score": data["score"],
            }))

    except Exception as e:
        print(json.dumps({"error": str(e)}))
        sys.exit(1)


if __name__ == "__main__":
    main()
