"""
Gerador de dossiê PDF para o Subradar.

Uso standalone:
    python -m ingestao.subradar.pdf --dossie-id <uuid> --output /tmp/dossie.pdf

Uso integrado (chamado pelo runner após processar um CNPJ):
    from ingestao.subradar.pdf import gerar_dossie
    path = gerar_dossie(dossie_id, output_dir="/tmp")
"""
from __future__ import annotations

import argparse
import logging
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

try:
    from reportlab.lib import colors as rl_colors
    # ── Paleta fiel ao site ──────────────────────────────────────────────────
    SLATE900 = rl_colors.HexColor("#0f172a")   # navy principal
    RED600   = rl_colors.HexColor("#dc2626")   # accent vermelho
    CREAM    = rl_colors.HexColor("#f8f7f4")   # fundo off-white
    SLATE400 = rl_colors.HexColor("#94a3b8")   # texto secundário
    SLATE500 = rl_colors.HexColor("#64748b")   # texto médio
    SLATE600 = rl_colors.HexColor("#475569")
    SLATE200 = rl_colors.HexColor("#e2e8f0")   # bordas
    GREEN700 = rl_colors.HexColor("#15803d")   # OK
    AMBER600 = rl_colors.HexColor("#d97706")   # atenção
    RED50    = rl_colors.HexColor("#fef2f2")
    GREEN50  = rl_colors.HexColor("#f0fdf4")
    AMBER50  = rl_colors.HexColor("#fffbeb")
    SLATE100 = rl_colors.HexColor("#f1f5f9")   # fundo "não consultada"
    SLATE700 = rl_colors.HexColor("#334155")   # texto "não consultada"
    WHITE    = rl_colors.white
    BLACK    = rl_colors.black
    _HAS_REPORTLAB = True
except ImportError:
    _HAS_REPORTLAB = False


# ── Catálogo completo de fontes ──────────────────────────────────────────────

FONTES_PJ: list[tuple[str, str]] = [
    # Fiscal
    ("pgfn",                   "PGFN — Dívida Ativa Federal"),
    ("cnd_federal",            "CND Federal — Certidão Negativa"),
    ("sefaz_estadual",         "SEFAZ Estadual — Certidão Negativa"),
    ("iss_municipal",          "ISS Municipal — Certidão Negativa"),
    ("infosimples_cnd_estadual", "CND Estadual (Infosimples)"),
    # Cadastral
    ("situacao_cadastral",     "Situação Cadastral RFB"),
    ("simples_nacional",       "Simples Nacional / MEI"),
    ("rfb_societario",         "Quadro Societário RFB"),
    ("jucesp",                 "Junta Comercial (JUCESP/MG/RJ)"),
    # Sanções CGU
    ("ceis",                   "CEIS — Empresas Inidôneas (CGU)"),
    ("cnep",                   "CNEP — Lei Anticorrupção (CGU)"),
    ("cepim",                  "CEPIM — Convênios Impedidos (CGU)"),
    ("leniencia",              "Acordos de Leniência CGU"),
    ("lista_suja_mte",         "Lista Suja — Trabalho Escravo (MTE)"),
    ("sicaf",                  "SICAF — Cadastro Federal de Fornecedores"),
    # Trabalhista
    ("cndt_tst_pj",            "CNDT/TST — Débitos Trabalhistas"),
    ("crf_fgts",               "CRF — Regularidade FGTS"),
    ("mte_autos",              "MTE — Autos de Infração"),
    # Contratos / Convênios
    ("contratos_transparencia", "Contratos Públicos (PNCP)"),
    ("pncp",                   "PNCP — Portal Nacional de Contratos"),
    ("siconv",                 "SICONV — Convênios Federais"),
    ("bndes_devedores",        "BNDES — Devedores"),
    # Judicial / Regulatório
    ("datajud",                "DataJud/CNJ — Processos e Falências"),
    ("tcu",                    "TCU — Certidão"),
    ("cade",                   "CADE — Processos Antitruste"),
    ("cvm_pas",                "CVM — Processos Sancionadores"),
    ("bacen",                  "BACEN — Entidades Supervisionadas"),
    # Ambiental / Setorial
    ("ibama",                  "IBAMA — Autos de Infração Ambiental"),
    ("aneel",                  "ANEEL — Autos Elétricos"),
    ("ans",                    "ANS — Operadoras de Saúde"),
    ("anvisa",                 "ANVISA — Licenças e Registros"),
    ("antt",                   "ANTT — Transportes Terrestres"),
    ("anatel",                 "ANATEL — Telecomunicações"),
    ("anac",                   "ANAC — Aviação Civil"),
    ("anp",                    "ANP — Petróleo e Gás"),
    ("antaq",                  "ANTAQ — Aquaviário"),
    ("ana",                    "ANA — Recursos Hídricos"),
    ("susep",                  "SUSEP — Seguros e Previdência Privada"),
    ("previc",                 "PREVIC — Fundos de Pensão"),
    # Protestos / Crédito
    ("protestos_sp",           "Protestos Cartoriais SP"),
    ("protestos_nacional",     "Protestos Cartoriais Nacional (BDC)"),
    ("bigdatacorp",            "BigDataCorp — Negativações / Processos de Sócios"),
    ("socios_compliance",      "Compliance dos Sócios"),
    ("grafo_socios",           "Grafo de Relacionamentos Societários"),
    ("inpi_marcas",            "INPI — Marcas e Patentes"),
    # Diários Oficiais
    ("dou",                    "DOU — Diário Oficial da União"),
    ("doe_estaduais_pj",       "DOE — Diários Oficiais Estaduais"),
    # Consumidor
    ("procon",                 "PROCON — Reclamações Fundamentadas"),
    # Listas internacionais
    ("ofac_sdn",               "OFAC SDN — Lista Negra EUA"),
    ("uk_sanctions",           "UK Sanctions (FCDO)"),
    ("eu_sanctions",           "EU Sanctions — Lista Europeia"),
    ("un_sanctions",           "ONU — Conselho de Segurança"),
    ("worldbank_debarment",    "Banco Mundial — Debarment"),
    ("opensanctions",          "OpenSanctions — PEPs e Sanções"),
    ("opensanctions_pro",      "OpenSanctions Pro — INTERPOL / 400+ listas"),
    # Tribunais estaduais
    ("tce_estaduais_pj",       "TCE Estaduais — Irregularidades"),
]

FONTES_PF: list[tuple[str, str]] = [
    # Cadastral
    ("cpf_situacao_rfb",       "Situação Cadastral CPF (RFB)"),
    ("qsa_reverso_rfb",        "Empresas Vinculadas ao CPF (RFB)"),
    # Judicial / Penal
    ("bnmp_cnj",               "BNMP/CNJ — Mandados de Prisão Ativos"),
    ("cndt_tst",               "CNDT/TST — Débitos Trabalhistas PF"),
    ("escavador_pf",           "Escavador — Processos Judiciais PF"),
    # Eleitoral
    ("tse_situacao_eleitoral", "TSE — Quitação Eleitoral"),
    # Conselhos Profissionais
    ("crea_confea",            "CREA/CONFEA — Engenheiros e Agrônomos"),
    ("cau_br",                 "CAU-BR — Arquitetos e Urbanistas"),
    ("conselhos_profissionais", "Implanta API — CREA, CRM, OAB…"),
    ("cfc_contadores",         "CFC — Contadores (Ativo / Inativo)"),
    ("infosimples_conselhos",  "Infosimples — CRO, CRF, CFM, CFMV, CFP"),
    # Sanções CGU / Federal
    ("cepim_pf",               "CEPIM — Sócio de Entidade Impedida"),
    ("ceis",                   "CEIS — Inidôneos CGU"),
    ("cnep",                   "CNEP — Punidos CGU"),
    ("lista_suja_mte",         "Lista Suja — Trabalho Escravo (MTE)"),
    ("pgfn",                   "PGFN — Dívida Ativa Federal PF"),
    # Diários Oficiais
    ("dou_pf",                 "DOU — Menções nos Últimos 30 dias"),
    ("doe_estaduais",          "DOE — SP, MG e RJ (90 dias)"),
    # Controle e Tribunais
    ("tce_estaduais",          "TCE Estaduais — Irregularidades PF"),
    ("cvm_pas_pf",             "CVM — Processos Sancionadores PF"),
    # Listas internacionais
    ("ofac_sdn",               "OFAC SDN — Lista Negra EUA"),
    ("uk_sanctions",           "UK Sanctions (FCDO)"),
    ("eu_sanctions",           "EU Sanctions — Lista Europeia"),
    ("un_sanctions",           "ONU — Conselho de Segurança"),
    ("worldbank_debarment",    "Banco Mundial — Debarment"),
    ("opensanctions_pro_pf",   "OpenSanctions Pro — PEPs / INTERPOL / 400+ listas"),
    # Mídia
    ("midia_adversa",          "Mídia Adversa — Monitoramento de Imprensa"),
]


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


# Severidade desconhecida NUNCA cai em "ok": um valor que o PDF não reconhece
# é tratado como fonte não consultada. O contrário já pintou de verde alerta
# "pendente" gravado pelo conector.
_NAO_CONSULTADA = {"pendente", "erro"}

# Ordem de gravidade. "pendente" fica acima de info/ok: não saber é pior que
# saber que está limpo.
_ORDEM_SEV = {"critico": 0, "atencao": 1, "pendente": 2, "erro": 2, "info": 3,
              "ok": 4, "nenhum": 4}


def _sev_color(sev: str):
    return {"critico": RED600, "atencao": AMBER600, "info": SLATE400,
            "ok": GREEN700, "nenhum": GREEN700,
            "pendente": SLATE700, "erro": SLATE700}.get(sev, SLATE700)


def _sev_bg(sev: str):
    return {"critico": RED50, "atencao": AMBER50, "info": CREAM,
            "ok": GREEN50, "nenhum": GREEN50,
            "pendente": SLATE100, "erro": SLATE100}.get(sev, SLATE100)


def _sev_label(sev: str) -> str:
    return {"critico": "CRÍTICO", "atencao": "ATENÇÃO", "info": "INFO",
            "ok": "OK", "nenhum": "OK"}.get(sev, "NÃO CONSULTADA")


def _pior(alertas: list[dict]) -> str:
    return min(
        alertas,
        key=lambda a: _ORDEM_SEV.get(a.get("severidade", "ok"), 2),
    ).get("severidade", "ok")


def _ps(name, size=9, bold=False, color=None, align="LEFT", leading=None, space_after=2):
    from reportlab.lib.styles import ParagraphStyle
    from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_RIGHT
    _align = {"LEFT": TA_LEFT, "CENTER": TA_CENTER, "RIGHT": TA_RIGHT}.get(align, TA_LEFT)
    return ParagraphStyle(
        name,
        fontName="Helvetica-Bold" if bold else "Helvetica",
        fontSize=size,
        leading=leading or round(size * 1.4, 1),
        textColor=color or BLACK,
        alignment=_align,
        spaceAfter=space_after,
    )


def _make_logo_drawing(width=160, height=36):
    """
    Replica o logo SVG do site:
      - Retângulo com cantos arredondados (stroke #0f172a)
      - Linha EKG: polyline 7,20 13,20 15,10 19,30 23,20 33,20
      - Círculo vermelho no pico (15, 10)
      - Wordmark "SUBRADAR" + "INTELIGÊNCIA CORPORATIVA"

    SVG viewBox 0 0 220 40 → escala para (width, height).
    ReportLab: origem bottom-left, Y invertido em relação ao SVG.
    """
    from reportlab.graphics.shapes import (
        Drawing, Rect, PolyLine, Circle, String, Group,
    )
    from reportlab.lib.colors import HexColor

    SVG_W, SVG_H = 220.0, 40.0
    sx = width / SVG_W
    sy = height / SVG_H

    def tx(x):  return x * sx
    def ty(y):  return height - y * sy  # inverte Y

    d = Drawing(width, height)

    # Retângulo ícone (SVG: x=2 y=2 w=36 h=36 rx=6)
    icon_w = 36 * sx
    icon_h = 36 * sy
    rect = Rect(tx(2), ty(2 + 36), icon_w, icon_h, rx=6 * sx, ry=6 * sy)
    rect.fillColor = None
    rect.strokeColor = HexColor("#0f172a")
    rect.strokeWidth = 1.5 * sx
    d.add(rect)

    # Linha EKG: SVG pts (x,y) → RL (tx, ty)
    svg_pts = [7, 20, 13, 20, 15, 10, 19, 30, 23, 20, 33, 20]
    rl_pts = []
    for i in range(0, len(svg_pts), 2):
        rl_pts += [tx(svg_pts[i]), ty(svg_pts[i + 1])]
    ekg = PolyLine(rl_pts)
    ekg.strokeColor = HexColor("#0f172a")
    ekg.strokeWidth = 1.8 * sx
    ekg.strokeLineCap = 1  # round
    ekg.strokeLineJoin = 1
    d.add(ekg)

    # Círculo vermelho no pico (SVG: cx=15 cy=10 r=2.5)
    dot = Circle(tx(15), ty(10), 2.5 * sx)
    dot.fillColor = HexColor("#dc2626")
    dot.strokeColor = None
    d.add(dot)

    # Wordmark (SVG: x=48)
    wm_x = tx(48)
    s1 = String(wm_x, ty(17) - 9, "SUBRADAR")
    s1.fontName = "Helvetica-Bold"
    s1.fontSize = 13 * sy
    s1.fillColor = HexColor("#0f172a")
    d.add(s1)

    s2 = String(wm_x, ty(30) - 7.5 * sy, "INTELIGÊNCIA CORPORATIVA")
    s2.fontName = "Helvetica"
    s2.fontSize = 7.5 * sy
    s2.fillColor = HexColor("#94a3b8")
    d.add(s2)

    return d


def _logo_flowable(width=160, height=36):
    from reportlab.platypus import Flowable
    from reportlab.graphics import renderPDF

    drw = _make_logo_drawing(width, height)

    class _F(Flowable):
        def __init__(self):
            super().__init__()
            self.width = drw.width
            self.height = drw.height

        def draw(self):
            renderPDF.draw(drw, self.canv, 0, 0)

    return _F()


def _draw_header_hero(canvas, doc, dossie, n_fontes, n_ok, n_alertas,
                      sc_label, sc_color, doc_tipo, fontes_lista, n_pendentes=0):
    """Desenha cabeçalho e hero na primeira página via canvas (pixel-perfect)."""
    from reportlab.lib.units import cm
    from reportlab.lib.colors import HexColor
    from reportlab.graphics.shapes import Drawing, Rect, PolyLine, Circle
    from reportlab.graphics import renderPDF

    W, H = doc.pagesize
    MARGIN = 1.8 * cm
    PINK = HexColor("#fca5a5")

    # ── Cabeçalho escuro ──────────────────────────────────────────────────
    HDR_H = 1.6 * cm
    canvas.saveState()
    canvas.setFillColor(SLATE900)
    canvas.rect(0, H - HDR_H, W, HDR_H, fill=1, stroke=0)

    # Ícone EKG — 1.0 cm, centralizado verticalmente no header
    ICON_SZ = 1.0 * cm
    icon_x = MARGIN
    icon_y = H - HDR_H + (HDR_H - ICON_SZ) / 2

    # Retângulo com cantos arredondados (borda branca)
    canvas.setStrokeColor(WHITE)
    canvas.setLineWidth(1.4)
    canvas.roundRect(icon_x, icon_y, ICON_SZ, ICON_SZ, radius=4, fill=0, stroke=1)

    # Linha EKG: SVG pts relativos ao rect 36×36 dentro de viewBox 40×40
    # offset SVG = (2,2); escala = ICON_SZ / 36
    s = ICON_SZ / 36.0
    svg_pts = [(7,20),(13,20),(15,10),(19,30),(23,20),(33,20)]
    p = canvas.beginPath()
    def _pt(xsvg, ysvg):
        return (icon_x + (xsvg - 2) * s,
                icon_y + ICON_SZ - (ysvg - 2) * s)
    x0, y0 = _pt(*svg_pts[0])
    p.moveTo(x0, y0)
    for xp, yp in svg_pts[1:]:
        p.lineTo(*_pt(xp, yp))
    canvas.setStrokeColor(WHITE)
    canvas.setLineWidth(1.4)
    canvas.drawPath(p, stroke=1, fill=0)

    # Ponto vermelho no pico (SVG cx=15, cy=10)
    px, py = _pt(15, 10)
    canvas.setFillColor(RED600)
    canvas.circle(px, py, 2.5, fill=1, stroke=0)

    # Wordmark
    text_x = icon_x + ICON_SZ + 7
    mid_y   = H - HDR_H + HDR_H / 2
    canvas.setFillColor(WHITE)
    canvas.setFont("Helvetica-Bold", 12)
    canvas.drawString(text_x, mid_y + 1, "SUBRADAR")
    canvas.setFillColor(SLATE400)
    canvas.setFont("Helvetica", 6.5)
    canvas.drawString(text_x, mid_y - 8, "INTELIGÊNCIA CORPORATIVA")

    # Data + tipo à direita
    canvas.setFillColor(SLATE400)
    canvas.setFont("Helvetica-Bold", 7)
    label = f"DOSSIÊ DE COMPLIANCE  ·  {__import__('datetime').date.today().strftime('%d/%m/%Y')}"
    canvas.drawRightString(W - MARGIN, H - HDR_H + HDR_H * 0.38, label)
    canvas.restoreState()

    # ── Faixa hero vermelha ───────────────────────────────────────────────
    razao   = dossie.get("razao_social") or "Monitorado"
    cnpj    = dossie.get("cnpj", "")
    ciclo   = dossie.get("ciclo", "")
    score   = str(dossie.get("score_num", 0))
    HERO_H  = 3.0 * cm
    hero_y  = H - HDR_H - HERO_H

    canvas.saveState()
    canvas.setFillColor(RED600)
    canvas.rect(0, hero_y, W, HERO_H, fill=1, stroke=0)

    # Razão social
    canvas.setFillColor(WHITE)
    canvas.setFont("Helvetica-Bold", 14)
    canvas.drawString(MARGIN, hero_y + HERO_H * 0.60, razao[:55])

    # CNPJ / ciclo
    canvas.setFillColor(PINK)
    canvas.setFont("Helvetica", 8)
    canvas.drawString(MARGIN, hero_y + HERO_H * 0.28,
                      f"{doc_tipo}  {cnpj}   ·   Ciclo {ciclo}")

    # Score (número grande, centro-direita)
    score_x = W * 0.70
    canvas.setFillColor(WHITE)
    canvas.setFont("Helvetica-Bold", 32)
    canvas.drawCentredString(score_x, hero_y + HERO_H * 0.38, score)
    canvas.setFont("Helvetica-Bold", 8)
    canvas.setFillColor(PINK)
    canvas.drawCentredString(score_x, hero_y + HERO_H * 0.18, sc_label)

    # Contadores (FONTES / OK / ALERTAS). O número de fontes não consultadas
    # não cabe aqui ao lado do score — vai numa tarja acima da tabela-resumo,
    # que é onde o leitor procura o resultado.
    ctrs = [
        (str(n_fontes), "FONTES"),
        (str(n_ok), "OK"),
        (str(n_alertas), "ALERTAS"),
    ]
    ctrs_start = score_x + MARGIN * 0.6
    ctrs_end   = W - MARGIN
    col_w = (ctrs_end - ctrs_start) / len(ctrs)
    for i, (val, lbl) in enumerate(ctrs):
        cx = ctrs_start + col_w * i + col_w / 2
        canvas.setFillColor(WHITE)
        canvas.setFont("Helvetica-Bold", 16)
        canvas.drawCentredString(cx, hero_y + HERO_H * 0.52, val)
        canvas.setFillColor(PINK)
        canvas.setFont("Helvetica", 6.5)
        canvas.drawCentredString(cx, hero_y + HERO_H * 0.24, lbl)

    canvas.restoreState()


def _build_pdf(dossie: dict, alertas: list[dict], output_path: str) -> None:
    from reportlab.lib.pagesizes import A4
    from reportlab.lib.units import cm
    from reportlab.platypus import (
        BaseDocTemplate, Frame, PageTemplate,
        Paragraph, Spacer, Table, TableStyle,
        HRFlowable, KeepTogether, PageBreak,
    )
    from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_RIGHT
    from functools import partial

    W, H = A4
    MARGIN = 1.8 * cm
    INNER = W - 2 * MARGIN

    def HR(color=SLATE200, thick=0.5, before=2, after=6):
        return HRFlowable(width="100%", thickness=thick, color=color,
                          spaceBefore=before, spaceAfter=after)

    def P(text, **kw):
        return Paragraph(str(text or ""), _ps("_", **kw))

    # ── Metadados ─────────────────────────────────────────────────────────────
    cnpj       = dossie.get("cnpj", "")
    razao      = dossie.get("razao_social") or "Monitorado"
    ciclo      = dossie.get("ciclo", "")
    score_num  = dossie.get("score_num", 0)
    score_txt  = (dossie.get("score_texto") or "baixo").lower()

    digits = re.sub(r"\D", "", cnpj)
    is_pf  = len(digits) == 11
    doc_tipo = "CPF" if is_pf else "CNPJ"
    fontes_lista = FONTES_PF if is_pf else FONTES_PJ

    score_faixa = {
        "baixo":   ("BAIXO",    GREEN700, GREEN50),
        "medio":   ("MÉDIO",    AMBER600, AMBER50),
        "alto":    ("ALTO",     RED600,   RED50),
        "critico": ("CRÍTICO",  RED600,   RED50),
    }.get(score_txt, ("BAIXO", GREEN700, GREEN50))
    sc_label, sc_color, sc_bg = score_faixa

    # Agrupa alertas por fonte
    por_fonte: dict[str, list[dict]] = {}
    for a in alertas:
        por_fonte.setdefault(a.get("fonte", "?"), []).append(a)

    story: list = []

    # ════════════════════════════════════════════════════════════════════════
    # CABEÇALHO — texto puro (Drawing em Table cell falha no ReportLab)
    # ════════════════════════════════════════════════════════════════════════

    n_fontes  = len(fontes_lista)
    # Fonte cujo pior status é "pendente"/"erro" não é alerta nem OK: é fonte
    # que não respondeu. Contada à parte para não inflar nenhum dos dois lados.
    chaves_pendentes = {
        k for k, _ in fontes_lista
        if k in por_fonte and _pior(por_fonte[k]) in _NAO_CONSULTADA
    }
    n_pendentes = len(chaves_pendentes)
    n_alertas = len([
        a for a in alertas
        if a.get("severidade") not in _NAO_CONSULTADA
    ])
    n_ok      = n_fontes - len([k for k, _ in fontes_lista if k in por_fonte])

    # O cabeçalho e hero são desenhados via canvas (on_page callback).
    # O Frame começa LOGO abaixo do hero — sem Spacer na story.
    # Equação: Frame top = H - MARGIN - TOP_RESERVED = H - HDR_H - HERO_H
    # → TOP_RESERVED = HDR_H + HERO_H - MARGIN
    HDR_H  = 1.6 * cm
    HERO_H = 3.0 * cm
    TOP_RESERVED = HDR_H + HERO_H - MARGIN + 0.25 * cm  # +0.25 = margem mínima abaixo do hero

    # ════════════════════════════════════════════════════════════════════════
    # TABELA RESUMO — todas as fontes
    # ════════════════════════════════════════════════════════════════════════

    story.append(P(f"Resumo das {n_fontes} fontes do catálogo",
                   size=9, bold=True, color=SLATE600, space_after=4))

    # Tarja de incompletude: some quando todas as fontes responderam.
    if n_pendentes:
        _av = Table(
            [[P(f"{n_pendentes} fonte(s) não puderam ser consultadas neste ciclo. "
                "O resultado delas é desconhecido — não é ausência de ocorrência.",
                size=8, bold=True, color=WHITE)]],
            colWidths=[INNER],
        )
        _av.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (-1, -1), SLATE700),
            ("LEFTPADDING", (0, 0), (-1, -1), 9),
            ("RIGHTPADDING", (0, 0), (-1, -1), 9),
            ("TOPPADDING", (0, 0), (-1, -1), 5),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
        ]))
        story.append(_av)
        story.append(Spacer(1, 0.15 * cm))

    r_data = [["FONTE", "STATUS", "RESULTADO"]]
    r_sevs = []

    for fonte_key, fonte_nome in fontes_lista:
        if fonte_key in por_fonte:
            sev = _pior(por_fonte[fonte_key])
            titulo = next(
                (a.get("titulo", "") for a in sorted(
                    por_fonte[fonte_key],
                    key=lambda a: _ORDEM_SEV.get(a.get("severidade", ""), 2)
                )),
                "",
            )
            resultado = re.sub(r"^[^—]+—\s*", "", titulo)[:72]
        else:
            sev = "ok"
            resultado = "Sem ocorrências"
        r_data.append([fonte_nome, _sev_label(sev), resultado])
        r_sevs.append(sev)

    r_t = Table(r_data, colWidths=[INNER * 0.38, INNER * 0.19, INNER * 0.43])
    r_style = [
        ("BACKGROUND", (0, 0), (-1, 0), SLATE900),
        ("TEXTCOLOR", (0, 0), (-1, 0), WHITE),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("FONTSIZE", (0, 0), (-1, 0), 7.5),
        ("FONTSIZE", (0, 1), (-1, -1), 7.5),
        ("FONTNAME", (0, 1), (-1, -1), "Helvetica"),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [WHITE, CREAM]),
        ("GRID", (0, 0), (-1, -1), 0.3, SLATE200),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("ALIGN", (1, 0), (1, -1), "CENTER"),
        ("TOPPADDING", (0, 0), (-1, -1), 3),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
        ("LEFTPADDING", (0, 0), (-1, -1), 6),
        ("RIGHTPADDING", (0, 0), (-1, -1), 6),
    ]
    for i, sev in enumerate(r_sevs, 1):
        c = _sev_color(sev)
        r_style += [
            ("BACKGROUND", (1, i), (1, i), c),
            ("TEXTCOLOR", (1, i), (1, i), WHITE),
            ("FONTNAME", (1, i), (1, i), "Helvetica-Bold"),
        ]
    r_t.setStyle(TableStyle(r_style))
    story.append(r_t)

    story.append(Spacer(1, 0.4 * cm))
    story.append(HR(SLATE200))
    story.append(P(
        "Documento gerado automaticamente pelo Subradar a partir de fontes oficiais e bases licenciadas. "
        "Não substitui parecer jurídico.",
        size=7, color=SLATE400, align="CENTER",
    ))

    # ════════════════════════════════════════════════════════════════════════
    # DETALHAMENTO — todas as fontes
    # ════════════════════════════════════════════════════════════════════════

    story.append(PageBreak())

    # Header da pág de detalhamento (replica estilo do site)
    det_hdr = Table(
        [[P("DETALHAMENTO POR FONTE", size=8, bold=True, color=WHITE),
          P(razao, size=8, color=SLATE400, align="RIGHT")]],
        colWidths=[INNER * 0.5, INNER * 0.5],
    )
    det_hdr.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), SLATE900),
        ("LEFTPADDING", (0, 0), (-1, -1), 12),
        ("RIGHTPADDING", (0, 0), (-1, -1), 12),
        ("TOPPADDING", (0, 0), (-1, -1), 8),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
    ]))
    story.append(det_hdr)
    story.append(Spacer(1, 0.3 * cm))

    for fonte_key, fonte_nome in fontes_lista:
        tem = fonte_key in por_fonte

        if tem:
            als = por_fonte[fonte_key]
            sev = _pior(als)
            sc  = _sev_color(sev)
            bg  = _sev_bg(sev)
            titulos = [a.get("titulo", "") for a in als]
            result_str = titulos[0] if len(titulos) == 1 else f"{len(titulos)} ocorrências — {titulos[0]}"
            desc_txt = "\n\n".join(
                a.get("descricao", "") for a in als[:3] if a.get("descricao")
            )
        else:
            sev = "ok"
            sc  = GREEN700
            bg  = GREEN50
            result_str = "Sem ocorrências nesta fonte"
            desc_txt = ""

        # Faixa de cabeçalho da fonte
        src_hdr = Table(
            [[P(fonte_nome, size=8, bold=True, color=WHITE),
              P(_sev_label(sev), size=8, bold=True, color=WHITE, align="RIGHT")]],
            colWidths=[INNER * 0.78, INNER * 0.22],
            rowHeights=[0.55 * cm],
        )
        src_hdr.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (-1, -1), sc),
            ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
            ("LEFTPADDING", (0, 0), (-1, -1), 9),
            ("RIGHTPADDING", (0, 0), (-1, -1), 9),
            ("TOPPADDING", (0, 0), (-1, -1), 0),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 0),
        ]))

        if tem:
            body_rows = [[P("Resultado", size=7, bold=True, color=SLATE500),
                          P(result_str[:200], size=8, bold=True, color=BLACK)]]
            if desc_txt:
                body_rows.append([P("", size=7),
                                  P(desc_txt[:700], size=8, color=SLATE600)])
            src_body = Table(body_rows, colWidths=[INNER * 0.16, INNER * 0.84])
            src_body.setStyle(TableStyle([
                ("BACKGROUND", (0, 0), (-1, -1), bg),
                ("BOX", (0, 0), (-1, -1), 0.3, SLATE200),
                ("LINEBELOW", (0, 0), (-1, -2), 0.2, SLATE200),
                ("TOPPADDING", (0, 0), (-1, -1), 4),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
                ("LEFTPADDING", (0, 0), (-1, -1), 9),
                ("RIGHTPADDING", (0, 0), (-1, -1), 9),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
            ]))
            story.append(KeepTogether([src_hdr, src_body, Spacer(1, 0.22 * cm)]))
        else:
            # OK: bloco compacto de uma linha
            ok_body = Table(
                [[P("Nenhuma ocorrência encontrada nesta fonte no ciclo consultado.",
                    size=7.5, color=GREEN700)]],
                colWidths=[INNER],
            )
            ok_body.setStyle(TableStyle([
                ("BACKGROUND", (0, 0), (-1, -1), GREEN50),
                ("BOX", (0, 0), (-1, -1), 0.3, SLATE200),
                ("TOPPADDING", (0, 0), (-1, -1), 3),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
                ("LEFTPADDING", (0, 0), (-1, -1), 9),
                ("RIGHTPADDING", (0, 0), (-1, -1), 9),
            ]))
            story.append(KeepTogether([src_hdr, ok_body, Spacer(1, 0.15 * cm)]))

    # ════════════════════════════════════════════════════════════════════════
    # METODOLOGIA
    # ════════════════════════════════════════════════════════════════════════

    story.append(PageBreak())

    met_hdr = Table(
        [[P("METODOLOGIA E SCORE DE RISCO", size=8, bold=True, color=WHITE)]],
        colWidths=[INNER],
    )
    met_hdr.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), SLATE900),
        ("LEFTPADDING", (0, 0), (-1, -1), 12),
        ("RIGHTPADDING", (0, 0), (-1, -1), 12),
        ("TOPPADDING", (0, 0), (-1, -1), 8),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
    ]))
    story.append(met_hdr)
    story.append(Spacer(1, 0.3 * cm))
    _nota_ciclo = (
        "O score de risco é calculado somando os pontos de cada alerta encontrado (máximo 100). "
    )
    if n_pendentes:
        _nota_ciclo += (
            f"Neste ciclo, {n_pendentes} fonte(s) não puderam ser consultadas e aparecem "
            "marcadas como NÃO CONSULTADA — o resultado delas é desconhecido, não negativo."
        )
    else:
        _nota_ciclo += "Todas as fontes do catálogo responderam neste ciclo."
    story.append(P(_nota_ciclo, size=8.5, color=SLATE600, space_after=10))

    pt_data = [["CLASSIFICAÇÃO", "PONTOS / ALERTA", "EXEMPLOS"]]
    pt_rows = [
        ("CRÍTICO",     RED600,   "30 pts", "Dívida ajuizada, CEIS, CNEP, leniência, IBAMA ativo, Lista Suja MTE"),
        ("ATENÇÃO",     AMBER600, "10 pts", "Situação suspensa/inapta, notificação DOU, conselho inativo"),
        ("INFORMATIVO", SLATE400, "2 pts",  "Contrato público, convênio, publicação rotineira DOU"),
        ("OK",          GREEN700, "0 pts",  "Sem registros nesta fonte"),
    ]
    for label, _, pts, ex in pt_rows:
        pt_data.append([label, pts, ex])

    pt_t = Table(pt_data, colWidths=[INNER * 0.15, INNER * 0.15, INNER * 0.70])
    pt_style = [
        ("BACKGROUND", (0, 0), (-1, 0), SLATE900),
        ("TEXTCOLOR", (0, 0), (-1, 0), WHITE),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("FONTSIZE", (0, 0), (-1, 0), 7.5),
        ("GRID", (0, 0), (-1, -1), 0.3, SLATE200),
        ("FONTSIZE", (0, 1), (-1, -1), 8),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
        ("LEFTPADDING", (0, 0), (-1, -1), 7),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
    ]
    for i, (_, cor, _, _ex) in enumerate(pt_rows, 1):
        pt_style += [
            ("BACKGROUND", (0, i), (0, i), cor),
            ("TEXTCOLOR", (0, i), (0, i), WHITE),
            ("FONTNAME", (0, i), (0, i), "Helvetica-Bold"),
        ]
    pt_t.setStyle(TableStyle(pt_style))
    story.append(pt_t)
    story.append(Spacer(1, 0.5 * cm))

    # Faixas de risco
    story.append(P("FAIXAS DE RISCO", size=7, bold=True, color=SLATE500, space_after=4))
    faixa_data = [["FAIXA", "SCORE", "DESCRIÇÃO"]]
    faixas = [
        ("BAIXO",    GREEN700, "0 – 20",   "Sem ocorrências significativas"),
        ("MÉDIO",    AMBER600, "21 – 50",  "Atenção — verificar contexto antes de contratar"),
        ("ALTO",     RED600,   "51 – 80",  "Risco elevado — documentar justificativa"),
        ("CRÍTICO",  RED600,   "81 – 100", "Contraindicado sem apuração aprofundada"),
    ]
    for label, _, pts, desc in faixas:
        faixa_data.append([label, pts, desc])
    faixa_t = Table(faixa_data, colWidths=[INNER * 0.15, INNER * 0.12, INNER * 0.73])
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
    for i, (_, cor, _, _) in enumerate(faixas, 1):
        faixa_style += [
            ("BACKGROUND", (0, i), (0, i), cor),
            ("TEXTCOLOR", (0, i), (0, i), WHITE),
            ("FONTNAME", (0, i), (0, i), "Helvetica-Bold"),
        ]
    faixa_t.setStyle(TableStyle(faixa_style))
    story.append(faixa_t)
    story.append(Spacer(1, 0.6 * cm))

    # ── Rodapé metodologia ────────────────────────────────────────────────────
    footer = Table(
        [[P("Subradar  ·  Lessa Labs Tecnologia Ltda  ·  CNPJ 65.659.055/0001-53",
            size=7, color=SLATE400),
          P(f"Gerado em {date.today().strftime('%d/%m/%Y')}  ·  Ciclo {ciclo}  ·  {n_alertas} alerta(s)",
            size=7, color=SLATE400, align="RIGHT")]],
        colWidths=[INNER * 0.6, INNER * 0.4],
    )
    footer.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), SLATE900),
        ("LEFTPADDING", (0, 0), (-1, -1), 12),
        ("RIGHTPADDING", (0, 0), (-1, -1), 12),
        ("TOPPADDING", (0, 0), (-1, -1), 8),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
    ]))
    story.append(footer)

    # Callback de página: desenha cabeçalho+hero via canvas na pág 1,
    # e apenas o cabeçalho nas demais.
    _on_first = partial(
        _draw_header_hero,
        dossie=dossie,
        n_fontes=n_fontes, n_ok=n_ok, n_alertas=n_alertas, n_pendentes=n_pendentes,
        sc_label=sc_label, sc_color=sc_color,
        doc_tipo=doc_tipo, fontes_lista=fontes_lista,
    )

    def _on_later(canvas, doc):
        from reportlab.lib.units import cm
        _HDR = 1.4 * cm
        W, H = doc.pagesize
        canvas.saveState()
        canvas.setFillColor(SLATE900)
        canvas.rect(0, H - _HDR, W, _HDR, fill=1, stroke=0)
        canvas.setFillColor(WHITE)
        canvas.setFont("Helvetica-Bold", 9)
        canvas.drawString(MARGIN, H - _HDR + _HDR * 0.38, "SUBRADAR")
        canvas.setFillColor(SLATE400)
        canvas.setFont("Helvetica", 7)
        canvas.drawRightString(W - MARGIN, H - _HDR + _HDR * 0.38,
                               f"Dossiê de Compliance  ·  {razao[:40]}  ·  Ciclo {ciclo}")
        canvas.restoreState()

    # Frame da primeira página começa abaixo do hero
    first_frame = Frame(
        MARGIN, MARGIN,
        INNER, H - MARGIN * 2 - TOP_RESERVED,
        id="first",
    )
    # Frames das demais páginas começam abaixo do cabeçalho
    later_frame = Frame(
        MARGIN, MARGIN,
        INNER, H - MARGIN * 2 - HDR_H - 0.3 * cm,
        id="later",
    )

    doc = BaseDocTemplate(
        output_path, pagesize=A4,
        title=f"Subradar — {razao} — {ciclo}",
        author="Lessa Labs Tecnologia Ltda",
    )
    doc.addPageTemplates([
        PageTemplate(id="First", frames=[first_frame], onPage=_on_first),
        PageTemplate(id="Later", frames=[later_frame], onPage=_on_later),
    ])

    from reportlab.platypus import NextPageTemplate
    story.insert(0, NextPageTemplate("Later"))

    doc.build(story)


def gerar_dossie(dossie_id: str, output_dir: str = "/tmp") -> str | None:
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
        print(f"PDF gerado: {output_path}")
        return output_path
    except Exception as e:
        logger.error("Erro ao gerar PDF: %s", e)
        import traceback; traceback.print_exc()
        return None


def main() -> None:
    parser = argparse.ArgumentParser(description="Subradar PDF — gerador de dossiê")
    parser.add_argument("--dossie-id", required=True)
    parser.add_argument("--output", default="/tmp", help="Diretório de saída")
    args = parser.parse_args()
    gerar_dossie(args.dossie_id, output_dir=args.output)


if __name__ == "__main__":
    main()
