#!/usr/bin/env python3
"""
Subradar PF — Production-grade API backend for dossiê generation.

Usage:
  python3 subradar_pf_api.py <cpf> <nome> <email> <action>

Actions:
  - send: Generate PDF and send via email
  - generate: Generate PDF only (returns base64)

Environment variables:
  - SUPABASE_URL: Supabase project URL
  - SUPABASE_SERVICE_ROLE_KEY: Service role key (for authenticated access)
  - RESEND_API_KEY: Resend email API key

Exit codes:
  0: Success
  1: Invalid input or configuration error
  2: Data fetch error (Supabase/API)
  3: PDF generation error
  4: Email send error
"""
import os
import sys
import json
import re
import base64
import logging
from datetime import date
from io import BytesIO
from typing import Optional, Dict, Any

import requests
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from reportlab.lib.colors import HexColor

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)
logger = logging.getLogger(__name__)

# Configuration from environment
SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")
RESEND_API_KEY = os.environ.get("RESEND_API_KEY", "")

# Constants
CPF_REGEX = r"^\d{11}$"
CICLO_FORMAT = "%Y-%m"
TIMEOUT_SUPABASE = 20
TIMEOUT_RESEND = 30


class ValidationError(Exception):
    """Raised when input validation fails"""
    pass


class DataFetchError(Exception):
    """Raised when Supabase fetch fails"""
    pass


class PDFGenerationError(Exception):
    """Raised when PDF generation fails"""
    pass


class EmailSendError(Exception):
    """Raised when email send fails"""
    pass


def validate_cpf(cpf: str) -> str:
    """
    Validate and normalize CPF to 11 digits.

    Args:
        cpf: CPF with or without formatting

    Returns:
        11-digit CPF string

    Raises:
        ValidationError: If CPF is invalid
    """
    # Remove non-digits
    cpf_digits = re.sub(r"\D", "", cpf or "")

    if not re.match(CPF_REGEX, cpf_digits):
        raise ValidationError(f"CPF inválido: deve conter 11 dígitos (recebido: {cpf})")

    # Basic CPF validation (Luhn check would go here for full validation)
    # For now, just ensure it's not all same digits (invalid CPF)
    if len(set(cpf_digits)) == 1:
        raise ValidationError(f"CPF inválido: todos os dígitos são iguais")

    return cpf_digits


def validate_email(email: str) -> str:
    """
    Validate email format.

    Args:
        email: Email address

    Returns:
        Normalized email

    Raises:
        ValidationError: If email is invalid
    """
    email = (email or "").strip()

    if not email or "@" not in email:
        raise ValidationError(f"Email inválido: {email}")

    if len(email) > 255:
        raise ValidationError(f"Email muito longo: {len(email)} caracteres")

    return email


def validate_nome(nome: str) -> str:
    """
    Validate person name.

    Args:
        nome: Full name

    Returns:
        Normalized name

    Raises:
        ValidationError: If name is invalid
    """
    nome = (nome or "").strip()

    if not nome or len(nome) < 3:
        raise ValidationError(f"Nome inválido: mínimo 3 caracteres (recebido: {nome})")

    if len(nome) > 200:
        raise ValidationError(f"Nome muito longo: {len(nome)} caracteres")

    return nome


def fmt_cpf(cpf_digits: str) -> str:
    """Format 11-digit CPF to XXX.XXX.XXX-XX"""
    if len(cpf_digits) != 11:
        raise ValidationError(f"CPF deve ter 11 dígitos, recebido {len(cpf_digits)}")
    return f"{cpf_digits[:3]}.{cpf_digits[3:6]}.{cpf_digits[6:9]}-{cpf_digits[9:11]}"


def fetch_data(cpf_fmt: str, ciclo: str) -> Dict[str, Any]:
    """
    Fetch compliance data from Supabase.

    Args:
        cpf_fmt: Formatted CPF (XXX.XXX.XXX-XX)
        ciclo: Cycle in YYYY-MM format

    Returns:
        Dict with score, faixa, alertas, dados

    Raises:
        DataFetchError: If any Supabase query fails
    """
    if not SUPABASE_URL or not SUPABASE_KEY:
        raise DataFetchError("Supabase não configurado: SUPABASE_URL ou SUPABASE_SERVICE_ROLE_KEY ausentes")

    hdrs = {"apikey": SUPABASE_KEY, "Authorization": f"Bearer {SUPABASE_KEY}"}

    try:
        # Resultado (score)
        logger.info(f"Consultando score para {cpf_fmt}")
        r = requests.get(
            f"{SUPABASE_URL}/rest/v1/sub_pf_resultados?cpf=eq.{cpf_fmt}&ciclo=eq.{ciclo}",
            headers=hdrs,
            timeout=TIMEOUT_SUPABASE
        )
        r.raise_for_status()
        resultado = r.json()[0] if r.json() else {}

        # Alertas
        logger.info(f"Consultando alertas para {cpf_fmt}")
        r = requests.get(
            f"{SUPABASE_URL}/rest/v1/sub_pf_alertas?cpf=eq.{cpf_fmt}&ciclo=eq.{ciclo}",
            headers=hdrs,
            timeout=TIMEOUT_SUPABASE
        )
        r.raise_for_status()
        alertas = r.json()

        # Dados estruturados
        logger.info(f"Consultando dados estruturados para {cpf_fmt}")
        r = requests.get(
            f"{SUPABASE_URL}/rest/v1/sub_pf_dados?cpf=eq.{cpf_fmt}&ciclo=eq.{ciclo}",
            headers=hdrs,
            timeout=TIMEOUT_SUPABASE
        )
        r.raise_for_status()
        dados = r.json()

        logger.info(f"Dados recuperados: score={resultado.get('score_risco')}, "
                   f"alertas={len(alertas)}, dados={len(dados)}")

        return {
            "score": resultado.get("score_risco", 0),
            "faixa": resultado.get("faixa_risco", "desconhecida"),
            "alertas": alertas,
            "dados": dados,
        }

    except requests.exceptions.RequestException as e:
        logger.error(f"Erro ao consultar Supabase: {e}")
        raise DataFetchError(f"Falha ao consultar Supabase: {str(e)}")
    except (json.JSONDecodeError, IndexError, KeyError) as e:
        logger.error(f"Erro ao processar resposta Supabase: {e}")
        raise DataFetchError(f"Resposta inválida de Supabase: {str(e)}")


def get_banner_color(score: int) -> HexColor:
    """Get banner color based on risk score"""
    if score <= 20:
        return HexColor("#16a34a")  # VERDE
    elif score <= 50:
        return HexColor("#d97706")  # AMARELO
    elif score <= 80:
        return HexColor("#dc2626")  # VERMELHO
    else:
        return HexColor("#7f1d1d")  # CRÍTICO


def get_faixa_label(score: int) -> str:
    """Get risk level label based on score"""
    if score <= 20:
        return "BAIXO"
    elif score <= 50:
        return "MÉDIO"
    elif score <= 80:
        return "ALTO"
    else:
        return "CRÍTICO"


def generate_pdf(nome: str, cpf_fmt: str, score: int, dados: list) -> bytes:
    """
    Generate professional PDF dossiê.

    Args:
        nome: Full name
        cpf_fmt: Formatted CPF
        score: Risk score (0-100)
        dados: List of compliance data records

    Returns:
        PDF as bytes

    Raises:
        PDFGenerationError: If PDF generation fails
    """
    try:
        logger.info(f"Gerando PDF para {cpf_fmt}")

        faixa_label = get_faixa_label(score)
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
            status = (d.get("status", "") or "").upper()
            resumo = (d.get("resumo", "") or "").strip()

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
        pdf_bytes = pdf_buffer.getvalue()
        logger.info(f"PDF gerado: {len(pdf_bytes)} bytes")

        return pdf_bytes

    except Exception as e:
        logger.error(f"Erro ao gerar PDF: {e}")
        raise PDFGenerationError(f"Falha ao gerar PDF: {str(e)}")


def send_email(nome: str, cpf_fmt: str, email: str, pdf_bytes: bytes, score: int) -> bool:
    """
    Send email via Resend.

    Args:
        nome: Full name
        cpf_fmt: Formatted CPF
        email: Recipient email
        pdf_bytes: PDF content
        score: Risk score

    Returns:
        True if email sent successfully

    Raises:
        EmailSendError: If email send fails
    """
    if not RESEND_API_KEY:
        raise EmailSendError("Resend não configurado: RESEND_API_KEY ausente")

    try:
        logger.info(f"Enviando email para {email}")

        faixa = get_faixa_label(score)
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
                <p><strong>Score de Risco:</strong> {score}/100 ({faixa})</p>
                <p>📎 PDF profissional anexado</p>
                <p style="font-size: 12px; color: #666;">Dossiê gerado automaticamente pelo Subradar</p>
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
            timeout=TIMEOUT_RESEND,
        )

        if not resp.ok:
            error_msg = f"Resend API error: {resp.status_code} — {resp.text[:200]}"
            logger.error(error_msg)
            raise EmailSendError(error_msg)

        logger.info(f"Email enviado com sucesso para {email}")
        return True

    except requests.exceptions.RequestException as e:
        logger.error(f"Erro ao enviar email: {e}")
        raise EmailSendError(f"Falha ao enviar email: {str(e)}")


def main():
    """Main entry point"""
    try:
        # Parse arguments
        if len(sys.argv) < 5:
            raise ValidationError("Argumentos insuficientes: cpf nome email action")

        cpf_input = sys.argv[1]
        nome_input = sys.argv[2]
        email_input = sys.argv[3]
        action = sys.argv[4]

        # Validate inputs
        logger.info(f"Validando entrada para CPF {cpf_input}")
        cpf_digits = validate_cpf(cpf_input)
        nome = validate_nome(nome_input)
        email = validate_email(email_input)

        cpf_fmt = fmt_cpf(cpf_digits)
        ciclo = date.today().strftime(CICLO_FORMAT)

        logger.info(f"Iniciando processamento: {cpf_fmt} / {nome} / {email} / action={action}")

        # Fetch data
        data = fetch_data(cpf_fmt, ciclo)

        # Generate PDF
        pdf_bytes = generate_pdf(nome, cpf_fmt, data["score"], data["dados"])

        # Execute action
        if action == "send":
            send_email(nome, cpf_fmt, email, pdf_bytes, data["score"])
            result = {
                "success": True,
                "message": f"Dossiê enviado para {email}",
                "score": data["score"],
                "faixa": data["faixa"],
            }
        elif action == "generate":
            pdf_b64 = base64.b64encode(pdf_bytes).decode('utf-8')
            result = {
                "success": True,
                "pdf": pdf_b64,
                "score": data["score"],
                "faixa": data["faixa"],
            }
        else:
            raise ValidationError(f"Ação inválida: {action} (use 'send' ou 'generate')")

        print(json.dumps(result))
        logger.info("Processamento concluído com sucesso")
        sys.exit(0)

    except ValidationError as e:
        logger.error(f"Erro de validação: {e}")
        print(json.dumps({"success": False, "error": f"Validação: {str(e)}"}))
        sys.exit(1)
    except DataFetchError as e:
        logger.error(f"Erro ao buscar dados: {e}")
        print(json.dumps({"success": False, "error": f"Dados: {str(e)}"}))
        sys.exit(2)
    except PDFGenerationError as e:
        logger.error(f"Erro ao gerar PDF: {e}")
        print(json.dumps({"success": False, "error": f"PDF: {str(e)}"}))
        sys.exit(3)
    except EmailSendError as e:
        logger.error(f"Erro ao enviar email: {e}")
        print(json.dumps({"success": False, "error": f"Email: {str(e)}"}))
        sys.exit(4)
    except Exception as e:
        logger.error(f"Erro inesperado: {e}", exc_info=True)
        print(json.dumps({"success": False, "error": f"Inesperado: {str(e)}"}))
        sys.exit(1)


if __name__ == "__main__":
    main()
