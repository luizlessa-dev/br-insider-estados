"""
Notifier — BR Insider Alertas Investigativos
Envia resultados das queries para Slack e/ou email.

Variáveis de ambiente:
  SLACK_WEBHOOK_URL   — webhook do canal #alertas-investigativos
  ALERT_EMAIL_TO      — email de destino (opcional)
  SMTP_HOST / SMTP_PORT / SMTP_USER / SMTP_PASS — para email (opcional)
"""
from __future__ import annotations

import json
import logging
import os
import smtplib
from datetime import date
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

import requests

logger = logging.getLogger(__name__)


# ── Formatação das mensagens ───────────────────────────────────────────────────

def _formatar_reais(valor) -> str:
    try:
        return f"R$ {float(valor):,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")
    except Exception:
        return str(valor)


def formatar_alerta_slack(meta: dict, rows: list[dict]) -> list[dict]:
    """
    Converte linhas de resultado em blocos Slack (Block Kit).
    Retorna lista de blocos prontos para POST no webhook.
    """
    if not rows:
        return []

    emoji = meta["emoji"]
    titulo = meta["titulo"]
    prioridade = meta["prioridade"]

    blocos = [
        {
            "type": "header",
            "text": {"type": "plain_text", "text": f"{emoji} {titulo}", "emoji": True},
        },
        {
            "type": "context",
            "elements": [
                {"type": "mrkdwn", "text": f"*Prioridade:* {prioridade} · *{len(rows)} ocorrência(s)* · {date.today().isoformat()}"}
            ],
        },
        {"type": "divider"},
    ]

    # Limitar a 5 resultados por alerta (Slack tem limite de blocos)
    for row in rows[:5]:
        texto = _formatar_row(meta, row)
        blocos.append({
            "type": "section",
            "text": {"type": "mrkdwn", "text": texto},
        })
        blocos.append({"type": "divider"})

    if len(rows) > 5:
        blocos.append({
            "type": "context",
            "elements": [
                {"type": "mrkdwn", "text": f"_... e mais {len(rows) - 5} ocorrência(s). Ver banco para lista completa._"}
            ],
        })

    return blocos


def _formatar_row(meta: dict, row: dict) -> str:
    """Formata uma linha de resultado em texto Markdown Slack."""
    chave = next(iter(meta))  # nome da query — não usado diretamente
    titulo = meta["titulo"]

    # Campos comuns
    data = row.get("data_inicio") or row.get("data") or ""
    hora = row.get("hora_inicio") or ""
    orgao = row.get("orgao_sigla") or row.get("orgao") or ""
    autoridade = row.get("autoridade_nome") or row.get("autoridade") or ""
    assunto = row.get("assunto") or row.get("descricao") or ""
    participante = row.get("participante_nome") or ""
    instituicao = row.get("instituicao") or ""
    cnpj = row.get("cnpj_participante") or ""

    linhas = []

    # Cabeçalho do item
    if autoridade:
        linhas.append(f"*{orgao}* — {autoridade}")
    elif orgao:
        linhas.append(f"*{orgao}*")

    if data:
        linhas.append(f"📅 {data}" + (f" às {hora}" if hora else ""))

    if assunto:
        linhas.append(f"📋 _{assunto[:120]}_")

    # Participante privado
    if participante or instituicao:
        inst_str = f" ({instituicao})" if instituicao else ""
        linhas.append(f"👤 {participante}{inst_str}")
    if cnpj:
        linhas.append(f"🏢 CNPJ: `{cnpj}`")

    # Campos específicos por tipo
    if "tipo_sancao" in row and row["tipo_sancao"]:
        linhas.append(f"⚠️ *Sanção:* {row['tipo_sancao']} ({row.get('cadastro') or row.get('tipo_cadastro_sancao', '')})")
    if "orgao_sancao" in row and row["orgao_sancao"]:
        linhas.append(f"🏛️ Órgão sancionador: {row['orgao_sancao']}")
    if "data_inicio_sancao" in row and row["data_inicio_sancao"]:
        linhas.append(f"📆 Sanção vigente desde: {row['data_inicio_sancao']}")

    if "total_recebido_emendas" in row and row["total_recebido_emendas"]:
        linhas.append(f"💸 *Total em emendas recebidas:* {_formatar_reais(row['total_recebido_emendas'])}")
    if "n_emendas" in row:
        linhas.append(f"📑 Emendas: {row['n_emendas']} · Autor(es): {row.get('autor_emenda', '?')}")

    # Ranking privados
    if "n_compromissos_privados" in row:
        linhas.append(f"🤝 {row['n_compromissos_privados']} reuniões · {row.get('total_participantes_privados', 0)} participantes privados")
        assuntos = row.get("assuntos") or []
        if assuntos:
            linhas.append(f"📋 Pautas: {', '.join(str(a)[:40] for a in assuntos[:3])}")

    # Audiências públicas
    if "comissoes" in row:
        comissoes = row.get("comissoes") or []
        linhas.append(f"🏛️ Comissões: {', '.join(comissoes)}")
    if "url_registro" in row and row.get("url_registro"):
        linhas.append(f"🎥 <{row['url_registro']}|Ver vídeo>")

    return "\n".join(linhas)


def formatar_email_html(resultados: dict[str, tuple[dict, list]]) -> str:
    """Gera HTML completo do email de alerta diário."""
    partes = ["""
    <html><body style="font-family: Arial, sans-serif; max-width: 700px; margin: 0 auto;">
    <h2 style="color: #1a1a2e; border-bottom: 2px solid #c0392b; padding-bottom: 8px;">
    🔍 BR Insider — Alertas Investigativos</h2>
    <p style="color: #666; font-size: 13px;">""" + date.today().isoformat() + "</p>"]

    for query_key, (meta, rows) in resultados.items():
        if not rows:
            continue

        cor = {"CRÍTICA": "#c0392b", "ALTA": "#e67e22", "MÉDIA": "#f39c12", "INFO": "#2980b9"}.get(
            meta["prioridade"], "#2980b9"
        )

        partes.append(f"""
        <div style="margin: 20px 0; padding: 15px; border-left: 4px solid {cor}; background: #f9f9f9;">
        <h3 style="color: {cor}; margin: 0 0 10px 0;">{meta['titulo']} ({len(rows)})</h3>
        """)

        for row in rows[:10]:
            partes.append("<div style='margin: 10px 0; padding: 10px; background: white; border-radius: 4px;'>")

            data = row.get("data_inicio") or row.get("data") or ""
            orgao = row.get("orgao_sigla") or ""
            autoridade = row.get("autoridade_nome") or ""
            assunto = (row.get("assunto") or row.get("descricao") or "")[:150]
            participante = row.get("participante_nome") or ""
            instituicao = row.get("instituicao") or ""
            cnpj = row.get("cnpj_participante") or ""

            if autoridade:
                partes.append(f"<strong>{orgao}</strong> — {autoridade}<br>")
            if data:
                partes.append(f"📅 {data}<br>")
            if assunto:
                partes.append(f"<em>{assunto}</em><br>")
            if participante or instituicao:
                partes.append(f"👤 {participante} {f'({instituicao})' if instituicao else ''}<br>")
            if cnpj:
                partes.append(f"CNPJ: <code>{cnpj}</code><br>")
            if "tipo_sancao" in row and row["tipo_sancao"]:
                partes.append(f"<span style='color:{cor};'>⚠️ {row['tipo_sancao']}</span><br>")
            if "total_recebido_emendas" in row and row["total_recebido_emendas"]:
                partes.append(f"💸 {_formatar_reais(row['total_recebido_emendas'])} em emendas<br>")

            partes.append("</div>")

        if len(rows) > 10:
            partes.append(f"<p style='color:#666;font-size:12px;'>... e mais {len(rows)-10} ocorrências.</p>")

        partes.append("</div>")

    partes.append("""
    <hr style="margin-top:30px;">
    <p style="color:#999;font-size:11px;">BR Insider · thebrinsider.com · Alertas automáticos</p>
    </body></html>""")

    return "".join(partes)


# ── Envio Slack ────────────────────────────────────────────────────────────────

def enviar_slack(webhook_url: str, blocos: list[dict], texto_fallback: str = "") -> bool:
    """Envia mensagem para o Slack via Incoming Webhook."""
    if not webhook_url:
        logger.warning("SLACK_WEBHOOK_URL não configurado — pulando Slack")
        return False
    try:
        payload = {"text": texto_fallback or "Alerta BR Insider", "blocks": blocos}
        resp = requests.post(webhook_url, json=payload, timeout=15)
        resp.raise_for_status()
        logger.info("Slack: mensagem enviada (%d blocos)", len(blocos))
        return True
    except Exception as e:
        logger.error("Slack: erro ao enviar: %s", e)
        return False


def enviar_slack_simples(webhook_url: str, texto: str) -> bool:
    """Envia texto simples (sem Block Kit) — útil para mensagem de 'sem alertas'."""
    if not webhook_url:
        return False
    try:
        requests.post(webhook_url, json={"text": texto}, timeout=15).raise_for_status()
        return True
    except Exception as e:
        logger.error("Slack simples: %s", e)
        return False


# ── Envio Email ────────────────────────────────────────────────────────────────

def enviar_email(html: str, assunto: str) -> bool:
    """Envia email HTML via SMTP."""
    smtp_host = os.environ.get("SMTP_HOST")
    smtp_port = int(os.environ.get("SMTP_PORT", "587"))
    smtp_user = os.environ.get("SMTP_USER")
    smtp_pass = os.environ.get("SMTP_PASS")
    email_to = os.environ.get("ALERT_EMAIL_TO")

    if not all([smtp_host, smtp_user, smtp_pass, email_to]):
        logger.debug("SMTP não configurado — pulando email")
        return False

    try:
        msg = MIMEMultipart("alternative")
        msg["Subject"] = assunto
        msg["From"] = smtp_user
        msg["To"] = email_to
        msg.attach(MIMEText(html, "html"))

        with smtplib.SMTP(smtp_host, smtp_port) as server:
            server.starttls()
            server.login(smtp_user, smtp_pass)
            server.sendmail(smtp_user, [email_to], msg.as_string())

        logger.info("Email enviado para %s", email_to)
        return True
    except Exception as e:
        logger.error("Email: erro ao enviar: %s", e)
        return False
