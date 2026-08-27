"""Entrega do dossiê Subradar PF: monta o PDF e envia ao cliente.

Regra central: laudo com fonte pendente não é entregue. Um dossiê de background
check que diz "nada consta" numa fonte que não respondeu vale menos que nenhum
laudo — foi assim que a primeira venda real quase saiu afirmando ausência de
processos para alguém com oito, incluindo ação penal em curso.

Quando há pendência, a entrega é retida, o motivo fica em
sub_pf_consultas.entrega_bloqueio e o operador é avisado.
"""
from __future__ import annotations

import base64
import io
import logging
import os
from datetime import date

import requests

logger = logging.getLogger("subradar.entrega_pf")

SB_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SB_KEY = (
    os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    or os.environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY")
    or ""
)
RESEND_KEY = os.environ.get("RESEND_API_KEY", "")
REMETENTE = os.environ.get("SUBRADAR_FROM", "retorno@subradar.com.br")
OPERADOR = os.environ.get("SUBRADAR_OPERADOR", "luiz@lessalabs.com")

# Status que significam "esta fonte não respondeu". Laudo com qualquer um deles
# não vai para o cliente.
STATUS_INCOMPLETO = {"pendente", "erro"}


def _hdrs() -> dict:
    return {"apikey": SB_KEY, "Authorization": f"Bearer {SB_KEY}", "Content-Type": "application/json"}


def _get(tabela: str, params: dict) -> list:
    r = requests.get(f"{SB_URL}/rest/v1/{tabela}", headers=_hdrs(), params=params, timeout=30)
    return r.json() if r.ok else []


def fontes_pendentes(cpf_fmt: str, ciclo: str) -> list[str]:
    """Seções que não puderam ser consultadas nesta apuração."""
    dados = _get("sub_pf_dados", {"cpf": f"eq.{cpf_fmt}", "ciclo": f"eq.{ciclo}",
                                  "select": "fonte,status,titulo_secao"})
    return [
        d.get("titulo_secao") or d.get("fonte")
        for d in dados
        if str(d.get("status") or "").strip().lower() in STATUS_INCOMPLETO
    ]


def montar_pdf(cpf: str, nome: str, tipo: str = "completa") -> tuple[bytes, int, dict]:
    """Monta o dossiê. Devolve (pdf, num_paginas, indicadores)."""
    from reportlab.pdfgen import canvas
    from reportlab.lib.pagesizes import A4
    from reportlab.lib.colors import HexColor

    cpf = "".join(ch for ch in str(cpf) if ch.isdigit())
    ciclo = date.today().strftime("%Y-%m")
    cpf_fmt = f"{cpf[:3]}.{cpf[3:6]}.{cpf[6:9]}-{cpf[9:11]}"
    today = date.today().strftime("%d/%m/%Y")
    sb_url, sb_key, hdrs = SB_URL, SB_KEY, _hdrs()

    r = requests.get(f"{sb_url}/rest/v1/sub_pf_resultados?cpf=eq.{cpf_fmt}&ciclo=eq.{ciclo}", headers=hdrs, timeout=20)
    resultado = r.json()[0] if r.ok and r.json() else {}
    score = resultado.get("score_risco", 0)
    faixa = resultado.get("faixa_risco", "desconhecida")

    r = requests.get(f"{sb_url}/rest/v1/sub_pf_alertas?cpf=eq.{cpf_fmt}&ciclo=eq.{ciclo}", headers=hdrs, timeout=20)
    alertas = r.json() if r.ok else []

    def _sev(a):
        return (a.get("severidade") or "").strip().lower()

    n_criticos = sum(1 for a in alertas if _sev(a) == "critico")
    n_atencao = sum(1 for a in alertas if _sev(a) == "atencao")
    achados = [a for a in alertas if _sev(a) in ("critico", "atencao")]

    r = requests.get(f"{sb_url}/rest/v1/sub_pf_dados?cpf=eq.{cpf_fmt}&ciclo=eq.{ciclo}", headers=hdrs, timeout=20)
    dados = r.json() if r.ok else []

    fontes_ok = sum(1 for d in dados if d.get("status", "").upper() == "LIMPO")
    fontes_pendente = sum(1 for d in dados if d.get("status", "").upper() == "PENDENTE")
    fontes_critico = sum(1 for d in dados if d.get("status", "").upper() == "CRITICO")
    total_fontes = len(dados)

    def get_banner_color(score_val):
        if score_val <= 20:
            return HexColor("#16a34a")
        elif score_val <= 50:
            return HexColor("#d97706")
        elif score_val <= 80:
            return HexColor("#dc2626")
        return HexColor("#7f1d1d")

    def get_faixa_color(score_val):
        if score_val <= 20:
            return "BAIXO"
        elif score_val <= 50:
            return "MÉDIO"
        elif score_val <= 80:
            return "ALTO"
        return "CRÍTICO"

    banner_color = get_banner_color(score)
    FAIXA_LABEL = {"VERDE": "BAIXO", "AMARELO": "MÉDIO", "LARANJA": "ALTO", "VERMELHO": "CRÍTICO"}
    faixa_label = FAIXA_LABEL.get(str(faixa).upper(), get_faixa_color(score))

    color_dark_bg = HexColor("#0f172a")
    color_green = HexColor("#16a34a")
    color_orange = HexColor("#d97706")
    color_red = HexColor("#dc2626")
    color_gray_dark = HexColor("#1f2937")
    color_gray_light = HexColor("#f3f4f6")
    color_gray_text = HexColor("#6b7280")
    color_white = HexColor("#ffffff")

    pdf_buffer = io.BytesIO()
    c = canvas.Canvas(pdf_buffer, pagesize=A4)
    width, height = A4
    page_num = 0
    y = height

    def new_page():
        nonlocal page_num, y
        if page_num > 0:
            c.showPage()
        page_num += 1
        y = height
        draw_header()
        y -= 60

    def draw_header():
        c.setFillColor(color_dark_bg)
        c.rect(0, height - 50, width, 50, fill=True, stroke=False)
        c.setFont("Helvetica-Bold", 14)
        c.setFillColor(color_white)
        c.drawString(50, height - 30, "SUBRADAR")
        c.setFont("Helvetica", 9)
        c.setFillColor(color_gray_text)
        c.drawString(50, height - 42, "INTELIGÊNCIA CORPORATIVA")
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
    kpi_str = f"{total_fontes} FONTES  {fontes_ok} OK  {len(achados)} ACHADO(S)"
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
    c.drawString(330, y - 15, "PENDENTE")
    c.drawString(420, y - 15, "N/A")
    c.drawString(480, y - 15, "CRÍTICO")

    y -= 20

    # Agrupar por categoria
    CAT_LABEL = {
        "cadastral": "Cadastral",
        "societario": "Vínculos societários",
        "judicial": "Judicial",
        "penal": "Penal",
        "trabalhista": "Trabalhista",
        "sancao": "Sanções e restrições",
        "divida": "Dívidas",
        "financeiro": "Financeiro",
        "credito": "Crédito",
        "dou": "Diários oficiais",
        "controle": "Controle externo",
        "mercado_capitais": "Mercado de capitais",
        "internacional": "Listas internacionais",
        "reputacao": "Reputação e mídia",
    }

    categorias = {}
    for d in dados:
        cat = d.get("categoria", "outro")
        if cat not in categorias:
            categorias[cat] = {"limpo": 0, "pendente": 0, "na": 0, "critico": 0}
        status = d.get("status", "pendente").lower()
        if status == "limpo":
            categorias[cat]["limpo"] += 1
        elif status == "critico":
            categorias[cat]["critico"] += 1
        elif status in ("nao_aplicavel", "n/a", "na"):
            # Fonte que não cobre o caso não é pendência — somá-la a "pendente"
            # fazia o laudo parecer mais incompleto do que é.
            categorias[cat]["na"] += 1
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
        c.drawString(60, y - 12, CAT_LABEL.get(cat, cat.replace("_", " ").capitalize()))
        c.drawString(250, y - 12, str(counts["limpo"]))
        c.drawString(330, y - 12, str(counts["pendente"]))
        c.drawString(420, y - 12, str(counts["na"]))
        c.drawString(480, y - 12, str(counts["critico"]))

        y -= 18
        row_num += 1

        if y < 100:
            new_page()

    # Achados — o que efetivamente foi encontrado
    y -= 24

    def wrap(texto, fonte, tamanho, largura):
        """Quebra texto na largura disponível do canvas."""
        linhas, atual = [], ""
        for palavra in texto.split():
            teste = f"{atual} {palavra}".strip()
            if c.stringWidth(teste, fonte, tamanho) <= largura:
                atual = teste
            else:
                if atual:
                    linhas.append(atual)
                atual = palavra
        if atual:
            linhas.append(atual)
        return linhas

    if y < 140:
        new_page()

    c.setFont("Helvetica-Bold", 12)
    c.setFillColor(color_dark_bg)
    c.drawString(50, y, "ACHADOS")
    y -= 8
    c.setFont("Helvetica", 9)
    c.setFillColor(color_gray_text)
    c.drawString(50, y - 8, "Ocorrências que pedem análise. Fontes sem ocorrência aparecem no detalhamento abaixo.")
    y -= 28

    if not achados:
        c.setFillColor(HexColor("#f0fdf4"))
        c.rect(50, y - 34, width - 100, 34, fill=True, stroke=False)
        c.setFont("Helvetica-Bold", 10)
        c.setFillColor(color_green)
        c.drawString(62, y - 15, "Nenhuma ocorrência encontrada nas fontes consultadas.")
        c.setFont("Helvetica", 8)
        c.setFillColor(color_gray_text)
        c.drawString(62, y - 27, "Verifique as fontes pendentes no detalhamento a seguir.")
        y -= 46
    else:
        for a in sorted(achados, key=lambda x: 0 if _sev(x) == "critico" else 1):
            sev = _sev(a)
            cor = color_red if sev == "critico" else color_orange
            titulo_a = (a.get("titulo") or "Achado").strip()
            desc_a = (a.get("descricao") or "").strip()
            fonte_a = (a.get("fonte") or "").replace("_", " ").upper()
            url_a = (a.get("url_fonte") or "").strip()

            linhas = wrap(desc_a, "Helvetica", 9, width - 130) if desc_a else []
            altura = 34 + len(linhas) * 11 + (12 if url_a else 0)

            if y < altura + 30:
                new_page()

            c.setFillColor(HexColor("#fffbeb") if sev != "critico" else HexColor("#fef2f2"))
            c.rect(50, y - altura, width - 100, altura, fill=True, stroke=False)
            c.setFillColor(cor)
            c.rect(50, y - altura, 4, altura, fill=True, stroke=False)

            c.setFont("Helvetica-Bold", 8)
            c.setFillColor(cor)
            c.drawString(62, y - 14, f"{'CRÍTICO' if sev == 'critico' else 'ATENÇÃO'} · {fonte_a}")

            c.setFont("Helvetica-Bold", 10)
            c.setFillColor(color_dark_bg)
            c.drawString(62, y - 28, titulo_a[:88])

            yy = y - 40
            c.setFont("Helvetica", 9)
            c.setFillColor(color_gray_dark)
            for linha in linhas:
                c.drawString(62, yy, linha)
                yy -= 11

            if url_a:
                c.setFont("Helvetica-Oblique", 8)
                c.setFillColor(color_gray_text)
                c.drawString(62, yy, f"Fonte: {url_a[:95]}")

            y -= altura + 10

    # Página 2+: Lista completa de fontes
    y -= 20

    if y < 90:
        new_page()

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

        # Determinar cor e rótulo do status
        STATUS_LABEL = {
            "LIMPO": "LIMPO",
            "CRITICO": "CRÍTICO",
            "ALERTA": "ATENÇÃO",
            "PENDENTE": "PENDENTE",
            "NAO_APLICAVEL": "NÃO APLICÁVEL",
        }
        if status == "LIMPO":
            status_color = color_green
        elif status == "CRITICO":
            status_color = color_red
        elif status == "NAO_APLICAVEL":
            status_color = color_gray_text
        else:
            status_color = color_orange
        status = STATUS_LABEL.get(status, status.replace("_", " "))

        # Calcular altura da linha (pode ter múltiplas linhas se descrição for longa)
        # Cortar em 60 chars truncava no meio ("cobertura: BA, CE, ES, MG, MS, MT,
        # PA, P"). Quebra na largura real da coluna.
        desc_linhas = wrap(descricao, "Helvetica", 8, 320) if descricao else []
        desc_linhas = desc_linhas[:2]
        line_height = 18 + len(desc_linhas) * 10

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
        if desc_linhas:
            c.setFont("Helvetica", 8)
            c.setFillColor(color_gray_text)
            yy_desc = y - 24
            for linha in desc_linhas:
                c.drawString(60, yy_desc, linha)
                yy_desc -= 10

        y -= line_height
        row_num += 1

    # Escopo e limitações — o cliente precisa saber o que NÃO foi verificado.
    y -= 30
    if y < 150:
        new_page()
        y -= 20

    c.setFont("Helvetica-Bold", 12)
    c.setFillColor(color_dark_bg)
    c.drawString(50, y, "ESCOPO E LIMITAÇÕES")
    y -= 20

    pendentes = [d for d in dados if (d.get("status") or "").lower() == "pendente"]
    nao_aplicaveis = [d for d in dados if (d.get("status") or "").lower() == "nao_aplicavel"]

    notas = [
        f"Consulta realizada em {today}, com consentimento registrado do titular.",
        "As seções que informam número de certidão (CNDT/TST e Antecedentes Criminais da Polícia Federal) "
        "trazem certidão oficial emitida nesta data e conferível na origem.",
        "Nas demais, \"limpo\" significa ausência de registro na fonte na data da consulta — é resultado de "
        "pesquisa em base pública ou privada, não certidão.",
    ]
    if pendentes:
        nomes = "; ".join((d.get("titulo_secao") or d.get("fonte") or "") for d in pendentes)
        notas.append(f"Fontes não consultadas nesta apuração ({len(pendentes)}): {nomes}.")
    if nao_aplicaveis:
        nomes = "; ".join((d.get("titulo_secao") or d.get("fonte") or "") for d in nao_aplicaveis)
        notas.append(f"Fontes fora de cobertura para este caso: {nomes}.")

    c.setFont("Helvetica", 8)
    for nota in notas:
        for linha in wrap(nota, "Helvetica", 8, width - 110):
            if y < 70:
                new_page()
                c.setFont("Helvetica", 8)
            c.setFillColor(color_gray_dark)
            c.drawString(50, y, linha)
            y -= 11
        y -= 4

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
    return pdf_buffer.getvalue(), page_num, {
        "score": score, "faixa": faixa, "faixa_label": faixa_label,
        "total_fontes": total_fontes, "fontes_ok": fontes_ok,
        "fontes_pendente": fontes_pendente, "achados": len(achados),
        "criticos": n_criticos, "atencao": n_atencao,
        "cpf_fmt": cpf_fmt, "ciclo": ciclo, "today": today,
    }


def _patch_consulta(consulta_id: str, campos: dict) -> None:
    requests.patch(
        f"{SB_URL}/rest/v1/sub_pf_consultas",
        headers=_hdrs(), params={"id": f"eq.{consulta_id}"},
        json=campos, timeout=30,
    )


def _email_html(nome: str, ind: dict) -> str:
    return f"""<!DOCTYPE html>
<html><head><title>Dossiê Subradar PF</title></head>
<body style="font-family:system-ui,-apple-system,sans-serif;padding:20px;background:#f8fafc">
  <div style="max-width:600px;margin:auto;background:white;padding:20px;border-radius:8px">
    <h1 style="color:#0f172a;margin:0 0 16px">Subradar PF — Dossiê de Compliance</h1>
    <div style="background:#f1f5f9;padding:12px;border-radius:6px;margin-bottom:16px">
      <p style="margin:4px 0"><strong>Nome:</strong> {nome}</p>
      <p style="margin:4px 0"><strong>CPF:</strong> {ind['cpf_fmt']}</p>
      <p style="margin:4px 0"><strong>Score de Risco:</strong>
         <span style="font-size:24px;font-weight:bold">{ind['score']}</span>/100 ({ind['faixa_label']})</p>
      <p style="margin:4px 0"><strong>Fontes consultadas:</strong> {ind['total_fontes']}</p>
      <p style="margin:4px 0"><strong>Achados:</strong> {ind['achados']}</p>
      <p style="margin:4px 0"><strong>Data:</strong> {ind['today']}</p>
    </div>
    <p style="font-size:12px;color:#64748b;margin:0">
      Dossiê completo em anexo. Dúvidas: {OPERADOR}
    </p>
  </div>
</body></html>"""


def _avisar_operador(assunto: str, corpo: str) -> None:
    if not RESEND_KEY:
        logger.error("Sem RESEND_API_KEY — operador não avisado: %s", assunto)
        return
    try:
        requests.post(
            "https://api.resend.com/emails",
            json={"from": REMETENTE, "to": OPERADOR, "subject": assunto,
                  "html": f"<pre style='font-family:monospace'>{corpo}</pre>"},
            headers={"Authorization": f"Bearer {RESEND_KEY}"}, timeout=30,
        )
    except Exception as e:
        logger.error("Falha ao avisar operador: %s", e)


def entregar(consulta_id: str, cpf: str, nome: str, email_cliente: str,
             tipo: str = "completa", forcar: bool = False) -> dict:
    """Monta e envia o dossiê ao cliente, salvo se houver fonte pendente.

    `forcar=True` envia mesmo incompleto — use só em reenvio manual consciente.
    Devolve {"enviado": bool, "motivo": str, "indicadores": dict}.
    """
    cpf_d = "".join(ch for ch in str(cpf) if ch.isdigit())
    ciclo = date.today().strftime("%Y-%m")
    cpf_fmt = f"{cpf_d[:3]}.{cpf_d[3:6]}.{cpf_d[6:9]}-{cpf_d[9:11]}"

    pendentes = fontes_pendentes(cpf_fmt, ciclo)
    if pendentes and not forcar:
        motivo = "fonte(s) não consultada(s): " + "; ".join(pendentes)
        logger.warning("Entrega retida para %s — %s", consulta_id, motivo)
        _patch_consulta(consulta_id, {"entrega_bloqueio": motivo[:500]})
        _avisar_operador(
            f"[Subradar PF] Entrega retida — laudo incompleto ({len(pendentes)} fonte(s))",
            f"Consulta: {consulta_id}\nCPF: {cpf_fmt}\nNome: {nome}\n"
            f"Cliente: {email_cliente}\n\nFontes que não responderam:\n  - "
            + "\n  - ".join(pendentes)
            + "\n\nO dossiê NÃO foi enviado. Destravar a fonte e reprocessar, ou "
              "reenviar com forcar=True se a lacuna for aceitável.",
        )
        return {"enviado": False, "motivo": motivo, "indicadores": {}}

    pdf, paginas, ind = montar_pdf(cpf_d, nome, tipo)

    if not RESEND_KEY:
        _patch_consulta(consulta_id, {"entrega_bloqueio": "RESEND_API_KEY ausente"})
        return {"enviado": False, "motivo": "RESEND_API_KEY ausente", "indicadores": ind}

    resp = requests.post(
        "https://api.resend.com/emails",
        json={
            "from": REMETENTE,
            "to": email_cliente,
            "subject": f"Subradar PF — {nome} · Score {ind['score']} ({ind['faixa_label']})",
            "html": _email_html(nome, ind),
            "attachments": [{
                "filename": f"dossie_subradar_{ind['ciclo']}.pdf",
                "content": base64.b64encode(pdf).decode("utf-8"),
            }],
        },
        headers={"Authorization": f"Bearer {RESEND_KEY}"}, timeout=60,
    )

    if not resp.ok:
        motivo = f"Resend HTTP {resp.status_code}: {resp.text[:200]}"
        logger.error("Falha no envio de %s — %s", consulta_id, motivo)
        _patch_consulta(consulta_id, {"entrega_bloqueio": motivo[:500]})
        _avisar_operador(f"[Subradar PF] Falha no envio — {cpf_fmt}",
                         f"Consulta: {consulta_id}\n{motivo}")
        return {"enviado": False, "motivo": motivo, "indicadores": ind}

    from datetime import datetime, timezone
    _patch_consulta(consulta_id, {
        "entregue_em": datetime.now(timezone.utc).isoformat(),
        "entrega_bloqueio": None,
    })
    logger.info("Dossiê entregue: %s (%d pág, score %s)", email_cliente, paginas, ind["score"])
    return {"enviado": True, "motivo": "", "indicadores": ind}
