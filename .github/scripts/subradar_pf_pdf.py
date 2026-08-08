"""
Gerador de dossiê PDF para Subradar PF (Pessoa Física).

Uso standalone:
    python subradar_pf_pdf.py --cpf 12345678901 --output /tmp

Uso integrado (chamado pela API):
    from subradar_pf_pdf import gerar_dossie_pf_base64
    pdf_b64 = gerar_dossie_pf_base64(cpf, nome, score, faixa, dados_dict)
"""
from __future__ import annotations

import argparse
import base64
import io
import logging
import os
import re
from datetime import date
from pathlib import Path

logger = logging.getLogger("subradar.pf.pdf")

try:
    from reportlab.lib import colors as rl_colors
    from reportlab.lib.pagesizes import A4
    from reportlab.lib.units import cm
    from reportlab.lib.styles import ParagraphStyle
    from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_RIGHT
    from reportlab.platypus import (
        BaseDocTemplate, Frame, PageTemplate,
        Paragraph, Spacer, Table, TableStyle,
        HRFlowable, KeepTogether,
    )
    _HAS_REPORTLAB = True
except ImportError:
    _HAS_REPORTLAB = False

# ── Paleta fiel ao site ──────────────────────────────────────────────────
SLATE900 = rl_colors.HexColor("#0f172a")   # navy principal
RED600   = rl_colors.HexColor("#dc2626")   # accent vermelho
CREAM    = rl_colors.HexColor("#f8f7f4")   # fundo off-white
SLATE400 = rl_colors.HexColor("#94a3b8")   # texto secundário
SLATE500 = rl_colors.HexColor("#64748b")   # texto médio
SLATE600 = rl_colors.HexColor("#475569")   # texto título
SLATE200 = rl_colors.HexColor("#e2e8f0")   # bordas
GREEN700 = rl_colors.HexColor("#15803d")   # OK / BAIXO
AMBER600 = rl_colors.HexColor("#d97706")   # ATENÇÃO / MÉDIO
ORANGE600 = rl_colors.HexColor("#ea580c")  # ALTO
RED50    = rl_colors.HexColor("#fef2f2")
GREEN50  = rl_colors.HexColor("#f0fdf4")
AMBER50  = rl_colors.HexColor("#fffbeb")
WHITE    = rl_colors.white
BLACK    = rl_colors.black


def fmt_cpf(cpf: str) -> str:
    """Formata CPF para XXX.XXX.XXX-XX"""
    d = re.sub(r"\D", "", cpf).zfill(11)[:11]
    return f"{d[0:3]}.{d[3:6]}.{d[6:9]}-{d[9:11]}"


def _ps(name, size=9, bold=False, color=None, align="LEFT", space_after=2):
    """Cria ParagraphStyle com defaults."""
    _align = {"LEFT": TA_LEFT, "CENTER": TA_CENTER, "RIGHT": TA_RIGHT}.get(align, TA_LEFT)
    return ParagraphStyle(
        name,
        fontName="Helvetica-Bold" if bold else "Helvetica",
        fontSize=size,
        leading=round(size * 1.4, 1),
        textColor=color or BLACK,
        alignment=_align,
        spaceAfter=space_after,
    )


def _risk_theme(faixa: str) -> tuple[str, rl_colors.Color, rl_colors.Color]:
    """Retorna (label, color, bg_color) baseado na faixa de risco."""
    themes = {
        "BAIXO": ("BAIXO", GREEN700, GREEN50),
        "MÉDIO": ("MÉDIO", AMBER600, AMBER50),
        "ALTO": ("ALTO", ORANGE600, rl_colors.HexColor("#fed7aa")),
        "CRÍTICO": ("CRÍTICO", RED600, RED50),
    }
    return themes.get(faixa.upper(), ("N/D", SLATE500, CREAM))


def _draw_header_hero(canvas, doc, cpf: str, nome: str, score: int, faixa: str):
    """Desenha cabeçalho + hero section na primeira página."""
    W, H = doc.pagesize
    MARGIN = 1.8 * cm

    # ── Cabeçalho escuro ──────────────────────────────────────────────────
    HDR_H = 1.6 * cm
    canvas.saveState()
    canvas.setFillColor(SLATE900)
    canvas.rect(0, H - HDR_H, W, HDR_H, fill=1, stroke=0)

    # Wordmark
    text_x = MARGIN + 0.5 * cm
    mid_y = H - HDR_H + HDR_H / 2
    canvas.setFillColor(WHITE)
    canvas.setFont("Helvetica-Bold", 12)
    canvas.drawString(text_x, mid_y + 1, "SUBRADAR")
    canvas.setFillColor(SLATE400)
    canvas.setFont("Helvetica", 6.5)
    canvas.drawString(text_x, mid_y - 8, "COMPLIANCE PF")

    # Data à direita
    canvas.setFillColor(SLATE400)
    canvas.setFont("Helvetica-Bold", 7)
    label = f"DOSSIÊ DE COMPLIANCE  ·  {date.today().strftime('%d/%m/%Y')}"
    canvas.drawRightString(W - MARGIN, H - HDR_H + HDR_H * 0.38, label)
    canvas.restoreState()

    # ── Faixa hero vermelha ───────────────────────────────────────────────
    label_faixa, color_faixa, _ = _risk_theme(faixa)
    HERO_H = 2.5 * cm
    hero_y = H - HDR_H - HERO_H

    canvas.saveState()
    canvas.setFillColor(RED600)
    canvas.rect(0, hero_y, W, HERO_H, fill=1, stroke=0)

    # Nome
    canvas.setFillColor(WHITE)
    canvas.setFont("Helvetica-Bold", 14)
    canvas.drawString(MARGIN, hero_y + HERO_H * 0.65, nome[:50])

    # CPF
    canvas.setFillColor(rl_colors.HexColor("#fca5a5"))
    canvas.setFont("Helvetica", 8)
    canvas.drawString(MARGIN, hero_y + HERO_H * 0.32, f"CPF  {fmt_cpf(cpf)}")

    # Score (número grande)
    score_x = W * 0.68
    canvas.setFillColor(WHITE)
    canvas.setFont("Helvetica-Bold", 36)
    canvas.drawCentredString(score_x, hero_y + HERO_H * 0.42, str(score))
    canvas.setFont("Helvetica-Bold", 8)
    canvas.setFillColor(rl_colors.HexColor("#fca5a5"))
    canvas.drawCentredString(score_x, hero_y + HERO_H * 0.15, label_faixa)

    canvas.restoreState()


def _build_pdf_pf(cpf: str, nome: str, score: int, faixa: str,
                  alertas: list[dict] | None = None,
                  output_path: str = "/tmp/subradar_pf.pdf") -> None:
    """Constrói PDF profissional para Subradar PF."""
    if alertas is None:
        alertas = []

    W, H = A4
    MARGIN = 1.8 * cm
    INNER = W - 2 * MARGIN

    HDR_H = 1.6 * cm
    HERO_H = 2.5 * cm
    TOP_RESERVED = HDR_H + HERO_H - MARGIN + 0.25 * cm

    label_faixa, color_faixa, bg_faixa = _risk_theme(faixa)

    def P(text, **kw):
        return Paragraph(str(text or ""), _ps("_", **kw))

    story = []

    # ════════════════════════════════════════════════════════════════════════
    # RESUMO EXECUTIVO
    # ════════════════════════════════════════════════════════════════════════

    story.append(P(f"Resultado da avaliação", size=9, bold=True, color=SLATE600, space_after=4))
    story.append(P(
        f"O titular <b>{nome}</b> (CPF {fmt_cpf(cpf)}) obteve score de <b>{score}/100</b>, "
        f"classificado na faixa <b>{label_faixa}</b>.",
        size=8.5, color=SLATE600, space_after=10,
    ))

    # Resumo conforme faixa
    resumos = {
        "BAIXO": "Nenhum indício relevante de risco foi identificado para o titular.",
        "MÉDIO": "Foram identificados pontos de atenção que recomendam monitoramento periódico.",
        "ALTO": "Indícios relevantes de risco exigem diligência reforçada.",
        "CRÍTICO": "Risco crítico identificado. Recomenda-se apuração jurídica antes de qualquer contratação.",
    }
    resumo_txt = resumos.get(faixa.upper(), "Status de risco indeterminado.")
    story.append(P(resumo_txt, size=8.5, color=SLATE500, space_after=12))

    story.append(P("Escala de risco", size=7, bold=True, color=SLATE500, space_after=4))

    # Tabela faixas
    faixa_data = [["FAIXA", "SCORE", "DESCRIÇÃO"]]
    faixas_info = [
        ("BAIXO", GREEN700, "0 – 20", "Sem ocorrências significativas"),
        ("MÉDIO", AMBER600, "21 – 50", "Atenção — verificar contexto"),
        ("ALTO", ORANGE600, "51 – 80", "Risco elevado — documentar"),
        ("CRÍTICO", RED600, "81 – 100", "Contraindicado sem apuração"),
    ]
    for label, _, pts, desc in faixas_info:
        faixa_data.append([label, pts, desc])

    faixa_t = Table(faixa_data, colWidths=[INNER * 0.12, INNER * 0.10, INNER * 0.78])
    faixa_style = [
        ("BACKGROUND", (0, 0), (-1, 0), SLATE900),
        ("TEXTCOLOR", (0, 0), (-1, 0), WHITE),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("FONTSIZE", (0, 0), (-1, 0), 7.5),
        ("GRID", (0, 0), (-1, -1), 0.3, SLATE200),
        ("FONTSIZE", (0, 1), (-1, -1), 8),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
        ("LEFTPADDING", (0, 0), (-1, -1), 7),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [WHITE, CREAM]),
    ]
    for i, (_, cor, _, _) in enumerate(faixas_info, 1):
        faixa_style += [
            ("BACKGROUND", (0, i), (0, i), cor),
            ("TEXTCOLOR", (0, i), (0, i), WHITE),
            ("FONTNAME", (0, i), (0, i), "Helvetica-Bold"),
        ]
    faixa_t.setStyle(TableStyle(faixa_style))
    story.append(faixa_t)

    story.append(Spacer(1, 0.5 * cm))

    # ════════════════════════════════════════════════════════════════════════
    # ALERTAS (se houver)
    # ════════════════════════════════════════════════════════════════════════

    if alertas:
        story.append(P("Ocorrências encontradas", size=9, bold=True, color=SLATE600, space_after=4))

        for i, alerta in enumerate(alertas[:10]):  # máx 10 alertas
            sev = alerta.get("severidade", "info").lower()
            sev_color = {"critico": RED600, "atencao": AMBER600, "info": SLATE400}.get(sev, SLATE400)
            sev_bg = {"critico": RED50, "atencao": AMBER50, "info": CREAM}.get(sev, CREAM)
            sev_label = {"critico": "CRÍTICO", "atencao": "ATENÇÃO", "info": "INFO"}.get(sev, "INFO")

            # Cabeçalho do alerta
            alerta_hdr = Table(
                [[P(alerta.get("titulo", "Alerta"), size=8, bold=True, color=WHITE),
                  P(sev_label, size=7, bold=True, color=WHITE, align="RIGHT")]],
                colWidths=[INNER * 0.75, INNER * 0.25],
                rowHeights=[0.4 * cm],
            )
            alerta_hdr.setStyle(TableStyle([
                ("BACKGROUND", (0, 0), (-1, -1), sev_color),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("LEFTPADDING", (0, 0), (-1, -1), 8),
                ("RIGHTPADDING", (0, 0), (-1, -1), 8),
                ("TOPPADDING", (0, 0), (-1, -1), 2),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 2),
            ]))

            # Corpo do alerta
            descricao = alerta.get("descricao", "Sem detalhes")
            alerta_body = Table(
                [[P(descricao[:300], size=7.5, color=SLATE600)]],
                colWidths=[INNER],
            )
            alerta_body.setStyle(TableStyle([
                ("BACKGROUND", (0, 0), (-1, -1), sev_bg),
                ("BOX", (0, 0), (-1, -1), 0.3, SLATE200),
                ("TOPPADDING", (0, 0), (-1, -1), 5),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
                ("LEFTPADDING", (0, 0), (-1, -1), 8),
                ("RIGHTPADDING", (0, 0), (-1, -1), 8),
            ]))

            story.append(KeepTogether([alerta_hdr, alerta_body, Spacer(1, 0.2 * cm)]))
    else:
        story.append(P(
            "✓ Nenhuma ocorrência significativa encontrada.",
            size=8.5, color=GREEN700, space_after=12,
        ))

    story.append(Spacer(1, 0.4 * cm))

    # ════════════════════════════════════════════════════════════════════════
    # METODOLOGIA
    # ════════════════════════════════════════════════════════════════════════

    story.append(P("Metodologia", size=8, bold=True, color=SLATE600, space_after=4))
    story.append(P(
        "O score de risco avalia a pessoa física através de consulta a bases públicas: "
        "CPF (RFB), órgãos reguladores, diários oficiais, cadastros de sanções e listas de restrição. "
        "A pontuação reflete a materialidade dos indícios encontrados no ciclo consultado.",
        size=8, color=SLATE500, space_after=8,
    ))

    # Rodapé
    footer = Table(
        [[P("Subradar  ·  Lessa Labs Tecnologia Ltda", size=7, color=SLATE400),
          P(f"Gerado em {date.today().strftime('%d/%m/%Y')}", size=7, color=SLATE400, align="RIGHT")]],
        colWidths=[INNER * 0.6, INNER * 0.4],
    )
    footer.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), SLATE900),
        ("LEFTPADDING", (0, 0), (-1, -1), 12),
        ("RIGHTPADDING", (0, 0), (-1, -1), 12),
        ("TOPPADDING", (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
    ]))
    story.append(footer)

    # ════════════════════════════════════════════════════════════════════════
    # BUILD DOC
    # ════════════════════════════════════════════════════════════════════════

    def _on_first(canvas, doc):
        _draw_header_hero(canvas, doc, cpf, nome, score, faixa)

    def _on_later(canvas, doc):
        from reportlab.lib.units import cm
        _HDR = 1.4 * cm
        W, H = doc.pagesize
        canvas.saveState()
        canvas.setFillColor(SLATE900)
        canvas.rect(0, H - _HDR, W, _HDR, fill=1, stroke=0)
        canvas.setFillColor(WHITE)
        canvas.setFont("Helvetica-Bold", 9)
        canvas.drawString(1.8 * cm, H - _HDR + _HDR * 0.38, "SUBRADAR")
        canvas.restoreState()

    first_frame = Frame(
        MARGIN, MARGIN,
        INNER, H - MARGIN * 2 - TOP_RESERVED,
        id="first",
    )
    later_frame = Frame(
        MARGIN, MARGIN,
        INNER, H - MARGIN * 2 - HDR_H - 0.3 * cm,
        id="later",
    )

    doc = BaseDocTemplate(
        output_path, pagesize=A4,
        title=f"Subradar PF — {nome}",
        author="Lessa Labs Tecnologia Ltda",
    )
    doc.addPageTemplates([
        PageTemplate(id="First", frames=[first_frame], onPage=_on_first),
        PageTemplate(id="Later", frames=[later_frame], onPage=_on_later),
    ])

    doc.build(story)


def gerar_dossie_pf_base64(cpf: str, nome: str, score: int, faixa: str,
                           alertas: list[dict] | None = None) -> str:
    """Gera PDF e retorna como base64 (para API/Edge Function)."""
    if not _HAS_REPORTLAB:
        raise RuntimeError("reportlab não instalado — pip install reportlab")

    pdf_buffer = io.BytesIO()
    _build_pdf_pf(cpf, nome, score, faixa, alertas or [], output_path=None)

    # ReportLab escreve para arquivo, não bytes. Usar canvas direto:
    from reportlab.pdfgen import canvas
    from reportlab.lib.pagesizes import A4

    c = canvas.Canvas(pdf_buffer, pagesize=A4)
    # ... desenha aqui se precisar canvas direto
    # Por enquanto, salvamos em arquivo temp e relemos
    import tempfile
    with tempfile.NamedTemporaryFile(suffix=".pdf", delete=False) as tmp:
        tmp_path = tmp.name

    _build_pdf_pf(cpf, nome, score, faixa, alertas or [], output_path=tmp_path)

    with open(tmp_path, "rb") as f:
        pdf_bytes = f.read()

    os.unlink(tmp_path)
    return base64.b64encode(pdf_bytes).decode("utf-8")


def gerar_dossie_pf_arquivo(cpf: str, nome: str, score: int, faixa: str,
                            alertas: list[dict] | None = None,
                            output_dir: str = "/tmp") -> str:
    """Gera PDF e salva em arquivo."""
    if not _HAS_REPORTLAB:
        raise RuntimeError("reportlab não instalado — pip install reportlab")

    cpf_slug = re.sub(r"\D", "", cpf)
    filename = f"subradar_pf_{cpf_slug}_{date.today().strftime('%Y%m%d')}.pdf"
    output_path = str(Path(output_dir) / filename)

    _build_pdf_pf(cpf, nome, score, faixa, alertas or [], output_path=output_path)
    logger.info(f"PDF gerado: {output_path}")
    return output_path


def main() -> None:
    parser = argparse.ArgumentParser(description="Subradar PF — gerador de dossiê")
    parser.add_argument("--cpf", required=True)
    parser.add_argument("--nome", required=True)
    parser.add_argument("--score", type=int, default=25)
    parser.add_argument("--faixa", default="MÉDIO")
    parser.add_argument("--output", default="/tmp", help="Diretório de saída")
    args = parser.parse_args()

    path = gerar_dossie_pf_arquivo(args.cpf, args.nome, args.score, args.faixa, output_dir=args.output)
    print(f"✓ PDF gerado: {path}")


if __name__ == "__main__":
    main()
