"""
Gerador de dossiê PDF para o Subradar.

Uso standalone:
    python -m ingestao.subradar.pdf --dossie-id <uuid> --output /tmp/dossie.pdf

Uso integrado (chamado pelo runner após processar um CNPJ):
    from ingestao.subradar.pdf import gerar_dossie
    path = gerar_dossie(dossie_id, output_dir="/tmp")
"""
from __future__ import annotations

import logging
import math
import os
import re
from datetime import date
from pathlib import Path

import requests

logger = logging.getLogger("subradar.pdf")

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SUPABASE_KEY = (
    os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    or os.environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY")
    or ""
)

# ── Cores ──────────────────────────────────────────────────────────────────────
try:
    from reportlab.lib import colors as rl_colors
    NAVY  = rl_colors.HexColor("#1a2e4a")
    RUST  = rl_colors.HexColor("#c0392b")
    GREEN = rl_colors.HexColor("#1a6b3c")
    AMBER = rl_colors.HexColor("#c07000")
    STEEL = rl_colors.HexColor("#4a6fa5")
    CREAM = rl_colors.HexColor("#f8f4ef")
    LGRAY = rl_colors.HexColor("#e0e0e0")
    MGRAY = rl_colors.HexColor("#888888")
    WHITE = rl_colors.white
    BLACK = rl_colors.black
    RUST_L = rl_colors.HexColor("#fdf0ee")
    _HAS_REPORTLAB = True
except ImportError:
    _HAS_REPORTLAB = False


def _hdrs() -> dict:
    return {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Accept": "application/json",
    }


def _buscar_dossie(dossie_id: str) -> dict | None:
    r = requests.get(
        f"{SUPABASE_URL}/rest/v1/sub_dossies",
        params={"id": f"eq.{dossie_id}", "select": "*"},
        headers=_hdrs(), timeout=15,
    )
    rows = r.json() if r.ok else []
    return rows[0] if rows else None


def _buscar_alertas(dossie_id: str) -> list[dict]:
    r = requests.get(
        f"{SUPABASE_URL}/rest/v1/sub_alertas",
        params={"dossie_id": f"eq.{dossie_id}", "select": "*", "order": "severidade.asc"},
        headers=_hdrs(), timeout=15,
    )
    return r.json() if r.ok else []


def _sev_to_status(sev: str) -> str:
    return {"critico": "CRÍTICO", "atencao": "ATENÇÃO", "info": "INFO", "ok": "OK"}.get(sev, "N/A")


def _sev_to_color(sev: str):
    return {"critico": RUST, "atencao": AMBER, "info": STEEL, "ok": GREEN}.get(sev, STEEL)


def _status_color(status: str):
    return {"CRÍTICO": RUST, "ATENÇÃO": AMBER, "INFO": STEEL, "OK": GREEN, "N/A": STEEL}.get(status, STEEL)


def _ps(name, size=9, bold=False, color=None, align=None, leading=None, space_after=3):
    from reportlab.lib.styles import ParagraphStyle
    from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_RIGHT
    if color is None:
        color = BLACK
    if align is None:
        align = TA_LEFT
    return ParagraphStyle(
        name,
        fontName="Helvetica-Bold" if bold else "Helvetica",
        fontSize=size,
        leading=leading or size * 1.4,
        textColor=color,
        alignment=align,
        spaceAfter=space_after,
    )


def _make_logo(size=72):
    from reportlab.graphics.shapes import Drawing, Circle, ArcPath, Line
    from reportlab.graphics import renderPDF
    from reportlab.platypus import Flowable

    cx = cy = size / 2
    d = Drawing(size, size)
    bg = Circle(cx, cy, size / 2 - 1)
    bg.fillColor = NAVY; bg.strokeColor = None
    d.add(bg)
    for r, sw in [(size * 0.40, 1.2), (size * 0.27, 1.0), (size * 0.14, 0.8)]:
        a = ArcPath()
        a.addArc(cx, cy, r, 45, 315, moveTo=True)
        a.strokeColor = rl_colors.HexColor("#8aafd0"); a.strokeWidth = sw; a.fillColor = None
        d.add(a)
    angle_rad = math.radians(65)
    rx = cx + math.cos(angle_rad) * size * 0.41
    ry = cy + math.sin(angle_rad) * size * 0.41
    sweep = Line(cx, cy, rx, ry)
    sweep.strokeColor = RUST; sweep.strokeWidth = 1.8
    d.add(sweep)
    blip = Circle(rx, ry, size * 0.045)
    blip.fillColor = RUST; blip.strokeColor = None
    d.add(blip)
    dot = Circle(cx, cy, size * 0.04)
    dot.fillColor = WHITE; dot.strokeColor = None
    d.add(dot)

    class _F(Flowable):
        def __init__(self, drw):
            super().__init__()
            self.drawing = drw
            self.width = drw.width; self.height = drw.height
        def draw(self):
            renderPDF.draw(self.drawing, self.canv, 0, 0)
    return _F(d)


def _build_pdf(dossie: dict, alertas: list[dict], output_path: str) -> None:
    from reportlab.lib.pagesizes import A4
    from reportlab.lib.units import cm
    from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_RIGHT
    from reportlab.platypus import (
        SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
        HRFlowable, KeepTogether, PageBreak,
    )

    W, H = A4
    MARGIN = 2.0 * cm
    INNER = W - 2 * MARGIN
    COL_L = INNER * 0.16
    COL_R = INNER * 0.84

    def HR(color=LGRAY, thick=0.5):
        return HRFlowable(width="100%", thickness=thick, color=color, spaceAfter=6, spaceBefore=2)

    def cell(text, style):
        return Paragraph(str(text or ""), style)

    P_TITLE = _ps("title", 18, True, NAVY, TA_CENTER, 24, 4)
    P_SUBT  = _ps("subt",  10, False, STEEL, TA_CENTER, 14, 4)
    P_DATE  = _ps("pdate", 8,  False, MGRAY, TA_CENTER, 11, 16)
    P_H1    = _ps("h1",    14, True, NAVY, TA_LEFT, 18, 6)
    P_H2    = _ps("h2",    10, True, STEEL, TA_LEFT, 14, 4)
    P_BODY  = _ps("body",  9,  False, BLACK, TA_LEFT, 13, 4)
    P_SMALL = _ps("small", 8,  False, MGRAY, TA_LEFT, 11, 2)
    P_LABEL = _ps("label", 8,  True,  MGRAY, TA_LEFT, 11, 2)
    P_FOOT  = _ps("foot",  7,  False, MGRAY, TA_CENTER, 10, 0)

    # Agrupa alertas por fonte
    por_fonte: dict[str, list[dict]] = {}
    for a in alertas:
        por_fonte.setdefault(a.get("fonte", "?"), []).append(a)

    # Scores e status
    score_num   = dossie.get("score_num", 0)
    score_texto = (dossie.get("score_texto") or "baixo").upper()
    razao       = dossie.get("razao_social") or "Empresa Monitorada"
    cnpj        = dossie.get("cnpj", "")
    ciclo       = dossie.get("ciclo", "")
    score_color = {"CRITICO": RUST, "ALTO": AMBER, "MEDIO": STEEL, "BAIXO": GREEN}.get(score_texto, STEEL)
    score_label = {"CRITICO": "CRÍTICO", "ALTO": "ALTO", "MEDIO": "MÉDIO", "BAIXO": "BAIXO"}.get(score_texto, score_texto)

    story = []

    # ── CAPA ─────────────────────────────────────────────────────────────────
    icon = _make_logo(56)
    wm = Table(
        [[Paragraph("SUBRADAR", _ps("wb", 28, True, NAVY, TA_LEFT, 34))],
         [Paragraph("Inteligência Corporativa", _ps("ws", 9, False, STEEL, TA_LEFT, 12))]],
        colWidths=[INNER - 56 - 0.4 * cm],
    )
    wm.setStyle(TableStyle([
        ("LEFTPADDING", (0, 0), (-1, -1), 0), ("TOPPADDING", (0, 0), (-1, -1), 2),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 0), ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
    ]))
    logo_t = Table([[icon, wm]], colWidths=[56 + 0.4 * cm, INNER - 56 - 0.4 * cm], rowHeights=[56])
    logo_t.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("LEFTPADDING", (0, 0), (-1, -1), 0), ("RIGHTPADDING", (0, 0), (-1, -1), 0),
        ("TOPPADDING", (0, 0), (-1, -1), 0), ("BOTTOMPADDING", (0, 0), (-1, -1), 0)]))

    story.append(Spacer(1, 2.0 * cm))
    story.append(logo_t)
    story.append(Spacer(1, 0.3 * cm))
    story.append(HR(NAVY, 2))
    story.append(Spacer(1, 0.5 * cm))
    story.append(Paragraph("Dossiê de Inteligência Corporativa", P_TITLE))
    story.append(Paragraph("Monitoramento contínuo de risco regulatório, fiscal e reputacional", P_SUBT))
    story.append(Paragraph(f"Ciclo {ciclo} · {date.today().strftime('%d/%m/%Y')}", P_DATE))
    story.append(Spacer(1, 0.8 * cm))

    # Bloco empresa
    emp_t = Table(
        [[cell("EMPRESA MONITORADA", P_LABEL), ""],
         [cell(razao, _ps("en", 18, True, NAVY)), ""],
         [cell(f"CNPJ {cnpj}", P_SMALL), cell(f"Ciclo: {ciclo}", _ps("ec", 8, False, MGRAY, TA_RIGHT))]],
        colWidths=[INNER * 0.65, INNER * 0.35],
    )
    emp_t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), CREAM), ("BOX", (0, 0), (-1, -1), 1, NAVY),
        ("LEFTPADDING", (0, 0), (-1, -1), 12), ("RIGHTPADDING", (0, 0), (-1, -1), 12),
        ("TOPPADDING", (0, 0), (-1, -1), 8), ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
    ]))
    story.append(emp_t)
    story.append(Spacer(1, 0.7 * cm))

    # Score
    score_t = Table(
        [[cell("SCORE DE RISCO", P_LABEL),
          cell(str(score_num), _ps("sn", 36, True, score_color, TA_CENTER, 40)),
          cell(score_label, _ps("sl", 16, True, score_color, TA_RIGHT, 20))]],
        colWidths=[INNER * 0.38, INNER * 0.24, INNER * 0.38],
        rowHeights=[1.5 * cm],
    )
    score_bg = rl_colors.HexColor("#fff5f5") if score_color == RUST else rl_colors.HexColor("#fafafa")
    score_t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), score_bg),
        ("BOX", (0, 0), (-1, -1), 1.5, score_color),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("LEFTPADDING", (0, 0), (-1, -1), 12), ("RIGHTPADDING", (0, 0), (-1, -1), 12),
    ]))
    story.append(score_t)
    story.append(Spacer(1, 0.7 * cm))

    # Tabela resumo por fonte
    FONTES_ORDEM = [
        "pgfn", "ceis", "cnep", "cepim", "leniencia", "rfb_societario",
        "pncp", "opensanctions", "dou", "ibama", "cvm_pas", "siconv",
        "anvisa", "lista_suja_mte", "situacao_cadastral", "bacen",
        "mte_autos", "aneel", "ans", "datajud", "tcu",
    ]
    FONTE_NOME = {
        "pgfn": "PGFN — Dívida Ativa",
        "ceis": "CEIS — Empresas Inidôneas",
        "cnep": "CNEP — Lei Anticorrupção",
        "cepim": "CEPIM — Convênios Impedidos",
        "leniencia": "Acordos de Leniência",
        "rfb_societario": "Societário RFB",
        "pncp": "Contratos / Emendas (PNCP)",
        "opensanctions": "OpenSanctions",
        "dou": "DOU — Últimos 30 dias",
        "ibama": "IBAMA — Autos Ambientais",
        "cvm_pas": "CVM — Processos PAS",
        "siconv": "SICONV — Convênios Federais",
        "anvisa": "ANVISA — Licenças",
        "lista_suja_mte": "Lista Suja MTE",
        "situacao_cadastral": "Situação Cadastral RFB",
        "bacen": "BACEN — Entid. Supervisionadas",
        "mte_autos": "MTE — Autos de Infração",
        "aneel": "ANEEL — Autos Elétricos",
        "ans": "ANS — Operadoras de Saúde",
        "datajud": "DataJud/CNJ — Falências",
        "tcu": "TCU — Certidão",
    }

    r_data = [["FONTE", "STATUS", "RESULTADO"]]
    resumo_rows = []
    for fonte_key in FONTES_ORDEM:
        if fonte_key not in por_fonte:
            continue
        alertas_fonte = por_fonte[fonte_key]
        # Pega o alerta mais grave
        pior = min(alertas_fonte, key=lambda a: {"critico": 0, "atencao": 1, "info": 2, "ok": 3}.get(a.get("severidade", "ok"), 3))
        sev = pior.get("severidade", "ok")
        status = _sev_to_status(sev)
        resultado = pior.get("titulo", "")
        resultado = re.sub(r"^[^—]+—\s*", "", resultado)[:80]
        r_data.append([FONTE_NOME.get(fonte_key, fonte_key), status, resultado])
        resumo_rows.append((fonte_key, sev))

    r_t = Table(r_data, colWidths=[INNER * 0.38, INNER * 0.15, INNER * 0.47])
    r_style = [
        ("BACKGROUND", (0, 0), (-1, 0), NAVY), ("TEXTCOLOR", (0, 0), (-1, 0), WHITE),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"), ("FONTSIZE", (0, 0), (-1, 0), 8),
        ("FONTSIZE", (0, 1), (-1, -1), 8), ("FONTNAME", (0, 1), (-1, -1), "Helvetica"),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [WHITE, CREAM]),
        ("GRID", (0, 0), (-1, -1), 0.3, LGRAY),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"), ("ALIGN", (1, 0), (1, -1), "CENTER"),
        ("TOPPADDING", (0, 0), (-1, -1), 4), ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
        ("LEFTPADDING", (0, 0), (-1, -1), 7), ("RIGHTPADDING", (0, 0), (-1, -1), 7),
    ]
    for i, (_, sev) in enumerate(resumo_rows, 1):
        sc = _sev_to_color(sev)
        r_style += [("BACKGROUND", (1, i), (1, i), sc), ("TEXTCOLOR", (1, i), (1, i), WHITE),
                    ("FONTNAME", (1, i), (1, i), "Helvetica-Bold")]
    r_t.setStyle(TableStyle(r_style))
    story.append(r_t)
    story.append(Spacer(1, 0.6 * cm))
    story.append(HR(NAVY))
    story.append(Paragraph(
        "Documento gerado automaticamente pelo Subradar a partir de fontes públicas. "
        "Não substitui parecer jurídico.",
        P_FOOT,
    ))

    # ── DETALHAMENTO ──────────────────────────────────────────────────────────
    story.append(Spacer(1, 0.5 * cm))
    story.append(Paragraph("Detalhamento por Fonte", P_H1))
    story.append(HR(NAVY, 1.5))
    story.append(Spacer(1, 0.2 * cm))

    for fonte_key in FONTES_ORDEM:
        if fonte_key not in por_fonte:
            continue
        alertas_fonte = por_fonte[fonte_key]
        pior = min(alertas_fonte, key=lambda a: {"critico": 0, "atencao": 1, "info": 2, "ok": 3}.get(a.get("severidade", "ok"), 3))
        sev = pior.get("severidade", "ok")
        sc = _sev_to_color(sev)
        status = _sev_to_status(sev)
        nome = FONTE_NOME.get(fonte_key, fonte_key)

        # Consolida resultado
        titulos = [a.get("titulo", "") for a in alertas_fonte]
        result_str = titulos[0] if len(titulos) == 1 else f"{len(titulos)} ocorrências — " + titulos[0]
        descs = "\n".join(a.get("descricao", "") for a in alertas_fonte[:3])

        hdr = Table(
            [[nome, status]],
            colWidths=[INNER * 0.78, INNER * 0.22], rowHeights=[0.65 * cm],
        )
        hdr.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (-1, -1), sc), ("TEXTCOLOR", (0, 0), (-1, -1), WHITE),
            ("FONTNAME", (0, 0), (-1, -1), "Helvetica-Bold"), ("FONTSIZE", (0, 0), (-1, -1), 8.5),
            ("ALIGN", (1, 0), (1, 0), "RIGHT"), ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
            ("LEFTPADDING", (0, 0), (-1, -1), 9), ("RIGHTPADDING", (0, 0), (-1, -1), 9),
        ]))
        body = Table(
            [
                [cell("Resultado", P_LABEL), cell(result_str[:150], _ps("rb", 9, True, BLACK))],
                [cell("", P_LABEL), cell(descs[:600], P_BODY)],
            ],
            colWidths=[COL_L, COL_R],
        )
        body.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (-1, -1), rl_colors.HexColor("#fafafa")),
            ("BOX", (0, 0), (-1, -1), 0.3, LGRAY),
            ("LINEBELOW", (0, 0), (-1, -2), 0.2, LGRAY),
            ("TOPPADDING", (0, 0), (-1, -1), 4), ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
            ("LEFTPADDING", (0, 0), (-1, -1), 9), ("RIGHTPADDING", (0, 0), (-1, -1), 9),
            ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ]))
        story.append(KeepTogether([hdr, body, Spacer(1, 0.35 * cm)]))

    # ── METODOLOGIA ──────────────────────────────────────────────────────────
    story.append(PageBreak())
    story.append(Paragraph("Metodologia e Score de Risco", P_H1))
    story.append(HR(NAVY, 1.5))
    story.append(Spacer(1, 0.2 * cm))
    story.append(Paragraph(
        "O score é calculado somando os pontos de cada alerta (máx. 100). "
        "Todas as fontes ativas são consultadas a cada ciclo mensal.",
        P_BODY,
    ))
    story.append(Spacer(1, 0.4 * cm))

    pt_data = [["CLASSIFICAÇÃO", "PONTOS / ALERTA", "EXEMPLOS"]] + [
        ("CRÍTICO",     "40 pts", "Dívida ajuizada, CEIS, CNEP, leniência, IBAMA ativo, Lista Suja"),
        ("ATENÇÃO",     "15 pts", "CEIS expirado, situação SUSPENSA/INAPTA, notificação DOU"),
        ("INFORMATIVO", "2 pts",  "Contrato público, convênio, publicação rotineira DOU"),
        ("OK",          "0 pts",  "Sem registros nesta fonte"),
    ]
    pt_t = Table(pt_data, colWidths=[INNER * 0.16, INNER * 0.16, INNER * 0.68])
    pt_style = [
        ("BACKGROUND", (0, 0), (-1, 0), NAVY), ("TEXTCOLOR", (0, 0), (-1, 0), WHITE),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"), ("FONTSIZE", (0, 0), (-1, 0), 8),
        ("GRID", (0, 0), (-1, -1), 0.3, LGRAY), ("FONTSIZE", (0, 1), (-1, -1), 8),
        ("TOPPADDING", (0, 0), (-1, -1), 5), ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
        ("LEFTPADDING", (0, 0), (-1, -1), 7), ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
    ]
    for i, cor in enumerate([RUST, AMBER, STEEL, GREEN], 1):
        pt_style += [("BACKGROUND", (0, i), (0, i), cor), ("TEXTCOLOR", (0, i), (0, i), WHITE),
                     ("FONTNAME", (0, i), (0, i), "Helvetica-Bold")]
    pt_t.setStyle(TableStyle(pt_style))
    story.append(pt_t)
    story.append(Spacer(1, 0.5 * cm))

    story.append(HR(NAVY))
    story.append(Paragraph(
        f"Subradar · Lessa Labs Tecnologia Ltda · CNPJ 65.659.055/0001-53 · "
        f"Gerado em {date.today().strftime('%d/%m/%Y')} · {len(alertas)} alertas · Ciclo {ciclo}",
        P_FOOT,
    ))

    doc = SimpleDocTemplate(
        output_path, pagesize=A4,
        leftMargin=MARGIN, rightMargin=MARGIN,
        topMargin=MARGIN, bottomMargin=MARGIN,
        title=f"Subradar — {razao} — {ciclo}",
        author="Lessa Labs Tecnologia Ltda",
    )
    doc.build(story)


def gerar_dossie(dossie_id: str, output_dir: str = "/tmp") -> str | None:
    """
    Busca dossiê e alertas do Supabase e gera PDF.
    Retorna o caminho do arquivo gerado, ou None em caso de erro.
    """
    if not _HAS_REPORTLAB:
        logger.error("reportlab não instalado — pip install reportlab")
        return None

    dossie = _buscar_dossie(dossie_id)
    if not dossie:
        logger.error("Dossiê %s não encontrado", dossie_id)
        return None

    alertas = _buscar_alertas(dossie_id)
    logger.info("PDF: %d alertas para %s (%s)", len(alertas), dossie.get("cnpj"), dossie.get("razao_social"))

    cnpj_slug = re.sub(r"\D", "", dossie.get("cnpj", "unknown"))
    ciclo = dossie.get("ciclo", "0000-00").replace("-", "")
    filename = f"subradar_{cnpj_slug}_{ciclo}.pdf"
    output_path = str(Path(output_dir) / filename)

    try:
        _build_pdf(dossie, alertas, output_path)
        logger.info("PDF gerado: %s", output_path)
        return output_path
    except Exception as e:
        logger.error("Erro ao gerar PDF: %s", e)
        return None


if __name__ == "__main__":
    import argparse, sys
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
    p = argparse.ArgumentParser()
    p.add_argument("--dossie-id", required=True)
    p.add_argument("--output", default="/tmp")
    args = p.parse_args()
    path = gerar_dossie(args.dossie_id, args.output)
    if path:
        print(f"PDF gerado: {path}")
    else:
        sys.exit(1)
