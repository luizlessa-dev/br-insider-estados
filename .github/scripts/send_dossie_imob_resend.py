"""
Enviar dossiê Imob via Resend após pipeline.
Uso: python3 send_dossie_imob_resend.py --consulta-id <UUID> --email <email>
"""
import argparse
import logging
import sys
from datetime import datetime
import requests

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
)
logger = logging.getLogger("send_dossie_imob")


def enviar_resend(
    consulta_id: str,
    email_cliente: str,
    resend_api_key: str,
    base_url: str,
) -> bool:
    """
    Envia dossiê via Resend.
    
    Args:
      consulta_id: UUID da consulta (identificador do dossiê)
      email_cliente: Email para envio
      resend_api_key: Chave API Resend (variável de ambiente)
      base_url: URL base do site (ex: https://subradar.dev)
    
    Returns:
      True se enviado com sucesso
    """
    if not resend_api_key:
        logger.error("RESEND_API_KEY não configurada")
        return False

    dossie_url = f"{base_url}/imob/dossie/{consulta_id}"

    html_body = f"""
    <h1>Seu Dossiê Subradar Imob está pronto! 🎉</h1>
    <p>Olá,</p>
    <p>Sua consulta de compliance imobiliário foi processada com sucesso.</p>
    <p><strong>Acesse seu dossiê:</strong></p>
    <p><a href="{dossie_url}" style="background-color: #2563eb; color: white; padding: 12px 24px; border-radius: 6px; text-decoration: none; display: inline-block;">
      Ver Dossiê Completo
    </a></p>
    <p>O dossiê inclui:</p>
    <ul>
      <li>Score de risco (0-100)</li>
      <li>Alertas consolidados</li>
      <li>Análise detalhada por categoria</li>
      <li>Ações judiciais, dívida ativa, e mais</li>
    </ul>
    <p style="color: #666; font-size: 12px; margin-top: 24px;">
      Dúvidas? Fale conosco: <a href="mailto:luiz@gastronomizae.com">luiz@gastronomizae.com</a>
    </p>
    <p style="color: #999; font-size: 11px;">
      Subradar Imob — Compliance imobiliário por matrícula e endereço
    </p>
    """

    try:
        response = requests.post(
            "https://api.resend.com/emails",
            headers={
                "Authorization": f"Bearer {resend_api_key}",
                "Content-Type": "application/json",
            },
            json={
                "from": "Subradar <noreply@subradar.dev>",
                "to": email_cliente,
                "subject": "Seu Dossiê Subradar Imob está pronto",
                "html": html_body,
            },
            timeout=10,
        )

        if response.status_code == 200:
            data = response.json()
            logger.info(f"Email enviado com sucesso: {data.get('id')}")
            return True
        else:
            logger.error(
                f"Erro Resend: {response.status_code} {response.text}"
            )
            return False

    except Exception as e:
        logger.exception(f"Erro ao enviar email: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(
        description="Enviar dossiê Imob via Resend"
    )
    parser.add_argument("--consulta-id", required=True, help="UUID da consulta")
    parser.add_argument("--email", required=True, help="Email do cliente")
    parser.add_argument(
        "--base-url",
        default="https://subradar.dev",
        help="URL base do site",
    )

    args = parser.parse_args()

    # Resend API key deve estar em variável de ambiente
    resend_api_key = __import__("os").environ.get("RESEND_API_KEY")

    if enviar_resend(args.consulta_id, args.email, resend_api_key, args.base_url):
        logger.info("✅ Dossiê enviado com sucesso")
        sys.exit(0)
    else:
        logger.error("❌ Falha ao enviar dossiê")
        sys.exit(1)


if __name__ == "__main__":
    main()
