#!/usr/bin/env python3
"""
Gera PDF profissional do briefing Nano Bits usando ReportLab.
"""

import re
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.units import cm
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_JUSTIFY
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    HRFlowable, KeepTogether
)
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas as pdfgen_canvas

# ── Cores ──────────────────────────────────────────────────────────────────
NAVY = colors.HexColor('#1a2744')
LIGHT_GRAY = colors.HexColor('#e8e8e8')
MID_GRAY = colors.HexColor('#cccccc')
BLACK = colors.black
WHITE = colors.white

# ── Margens ────────────────────────────────────────────────────────────────
MARGIN = 2.5 * cm

PAGE_W, PAGE_H = A4


# ── Cabeçalho / Rodapé ─────────────────────────────────────────────────────
class HeaderFooterCanvas(pdfgen_canvas.Canvas):
    def __init__(self, *args, **kwargs):
        pdfgen_canvas.Canvas.__init__(self, *args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_header_footer(num_pages)
            pdfgen_canvas.Canvas.showPage(self)
        pdfgen_canvas.Canvas.save(self)

    def draw_header_footer(self, page_count):
        page_num = self._pageNumber
        w, h = A4

        # Cabeçalho
        self.saveState()
        self.setFont('Helvetica', 7)
        self.setFillColor(colors.HexColor('#888888'))
        self.drawString(MARGIN, h - 1.5 * cm, 'THE BR INSIDER')
        # Linha fina sob o cabeçalho
        self.setStrokeColor(MID_GRAY)
        self.setLineWidth(0.5)
        self.line(MARGIN, h - 1.7 * cm, w - MARGIN, h - 1.7 * cm)

        # Rodapé
        self.setFont('Helvetica', 8)
        self.setFillColor(colors.HexColor('#888888'))
        footer_text = f'Página {page_num} de {page_count}'
        self.drawRightString(w - MARGIN, 1.2 * cm, footer_text)
        self.line(MARGIN, 1.8 * cm, w - MARGIN, 1.8 * cm)
        self.restoreState()


# ── Estilos ────────────────────────────────────────────────────────────────
def make_styles():
    base = dict(fontName='Helvetica', fontSize=10, leading=14,
                textColor=BLACK, spaceAfter=4)

    styles = {
        'h1': ParagraphStyle('h1', fontName='Helvetica-Bold', fontSize=20,
                             leading=26, alignment=TA_CENTER,
                             textColor=NAVY, spaceAfter=12, spaceBefore=6),
        'h2': ParagraphStyle('h2', fontName='Helvetica-Bold', fontSize=13,
                             leading=18, textColor=NAVY,
                             spaceAfter=4, spaceBefore=14),
        'h3': ParagraphStyle('h3', fontName='Helvetica-Bold', fontSize=11,
                             leading=15, textColor=NAVY,
                             spaceAfter=4, spaceBefore=10),
        'body': ParagraphStyle('body', **base, alignment=TA_JUSTIFY),
        'bullet': ParagraphStyle('bullet', fontName='Helvetica', fontSize=10,
                                 leading=14, leftIndent=14, spaceAfter=3,
                                 bulletIndent=0),
        'meta': ParagraphStyle('meta', fontName='Helvetica', fontSize=9,
                               leading=13, textColor=colors.HexColor('#555555'),
                               spaceAfter=3),
        'note': ParagraphStyle('note', fontName='Helvetica-Oblique', fontSize=8,
                               leading=12, textColor=colors.HexColor('#555555'),
                               spaceAfter=3),
        'table_header': ParagraphStyle('table_header', fontName='Helvetica-Bold',
                                       fontSize=9, leading=12, textColor=BLACK),
        'table_cell': ParagraphStyle('table_cell', fontName='Helvetica',
                                     fontSize=9, leading=12, textColor=BLACK),
    }
    return styles


# ── Processamento de inline markdown ───────────────────────────────────────
def process_inline(text, style_name='body'):
    """Converte **bold**, *italic*, [link](url) e [ ] para markup ReportLab."""
    # Escapa & < > que não sejam tags já presentes
    text = text.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')

    # Checkbox [ ] → ☐  (antes de processar bold/italic para não conflitar)
    text = re.sub(r'\[ \]', '&#9744;', text)
    text = re.sub(r'\[x\]', '&#9745;', text, flags=re.IGNORECASE)

    # Links [texto](url)
    def link_repl(m):
        anchor = m.group(1)
        url = m.group(2)
        return f'{anchor} ({url})'
    text = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', link_repl, text)

    # Bold **texto**
    text = re.sub(r'\*\*(.+?)\*\*', r'<b>\1</b>', text)

    # Italic *texto* (não duplo)
    text = re.sub(r'(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)', r'<i>\1</i>', text)

    return text


# ── Parser de markdown → flowables ─────────────────────────────────────────
def parse_markdown(md_text, styles):
    lines = md_text.splitlines()
    story = []
    i = 0

    while i < len(lines):
        line = lines[i]

        # H1
        if line.startswith('# ') and not line.startswith('## '):
            text = process_inline(line[2:].strip())
            story.append(Paragraph(text, styles['h1']))
            story.append(Spacer(1, 0.3 * cm))
            i += 1
            continue

        # H2
        if line.startswith('## ') and not line.startswith('### '):
            text = process_inline(line[3:].strip())
            story.append(Spacer(1, 0.2 * cm))
            story.append(Paragraph(text, styles['h2']))
            story.append(HRFlowable(width='100%', thickness=1,
                                    color=NAVY, spaceAfter=6))
            i += 1
            continue

        # H3
        if line.startswith('### '):
            text = process_inline(line[4:].strip())
            story.append(Paragraph(text, styles['h3']))
            i += 1
            continue

        # Linha HR ---
        if re.match(r'^-{3,}$', line.strip()):
            story.append(Spacer(1, 0.15 * cm))
            story.append(HRFlowable(width='100%', thickness=0.5,
                                    color=MID_GRAY, spaceAfter=6))
            i += 1
            continue

        # Tabela markdown: linha começa com |
        if line.startswith('|'):
            table_lines = []
            while i < len(lines) and lines[i].startswith('|'):
                table_lines.append(lines[i])
                i += 1
            story.append(build_table(table_lines, styles))
            story.append(Spacer(1, 0.3 * cm))
            continue

        # Linha de nota em itálico (começa com *)
        if line.startswith('*') and line.endswith('*') and not line.startswith('**'):
            inner = line[1:-1]
            story.append(Paragraph(process_inline(inner), styles['note']))
            i += 1
            continue

        # Lista com checkbox - [ ]
        if re.match(r'^- \[[ x]\]', line):
            text = re.sub(r'^- ', '', line)
            text = process_inline(text)
            story.append(Paragraph(f'&#9744; {text[7:]}' if '&#9744;' in text
                                   else text, styles['bullet']))
            i += 1
            continue

        # Lista com marcador -
        if line.startswith('- '):
            text = process_inline(line[2:].strip())
            story.append(Paragraph(f'• {text}', styles['bullet']))
            i += 1
            continue

        # Lista numerada 1. 2. etc
        m = re.match(r'^(\d+)\.\s+(.*)', line)
        if m:
            num = m.group(1)
            text = process_inline(m.group(2).strip())
            story.append(Paragraph(f'{num}. {text}', styles['bullet']))
            i += 1
            continue

        # Linha de metadados (começa com **Produzido**, **Data** etc)
        if line.startswith('**') and ':' in line:
            story.append(Paragraph(process_inline(line), styles['meta']))
            i += 1
            continue

        # Parágrafo normal
        if line.strip():
            story.append(Paragraph(process_inline(line.strip()), styles['body']))
            i += 1
            continue

        # Linha em branco
        story.append(Spacer(1, 0.2 * cm))
        i += 1

    return story


def build_table(table_lines, styles):
    """Constrói uma Table ReportLab a partir de linhas markdown de tabela."""
    rows = []
    is_header_row = True
    sep_seen = False

    for line in table_lines:
        # Linha separadora |---|---|
        if re.match(r'^\|[-| :]+\|$', line.strip()):
            sep_seen = True
            continue
        cells = [c.strip() for c in line.strip('|').split('|')]
        rows.append(cells)

    if not rows:
        return Spacer(1, 0.1 * cm)

    # Calcula largura disponível
    avail_w = PAGE_W - 2 * MARGIN
    num_cols = max(len(r) for r in rows)
    col_w = avail_w / num_cols

    # Normaliza rows para mesmo nº de colunas
    norm_rows = []
    for r in rows:
        while len(r) < num_cols:
            r.append('')
        norm_rows.append(r[:num_cols])

    # Converte células para Paragraphs
    data = []
    for ri, row in enumerate(norm_rows):
        style = styles['table_header'] if ri == 0 else styles['table_cell']
        data.append([Paragraph(process_inline(cell), style) for cell in row])

    col_widths = [col_w] * num_cols

    t = Table(data, colWidths=col_widths, repeatRows=1)
    t.setStyle(TableStyle([
        # Cabeçalho
        ('BACKGROUND', (0, 0), (-1, 0), LIGHT_GRAY),
        ('TEXTCOLOR', (0, 0), (-1, 0), BLACK),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 9),
        # Corpo
        ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
        ('FONTSIZE', (0, 1), (-1, -1), 9),
        # Grid
        ('GRID', (0, 0), (-1, -1), 0.5, MID_GRAY),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
        ('RIGHTPADDING', (0, 0), (-1, -1), 6),
        # Linhas alternadas leves
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [WHITE, colors.HexColor('#f7f7f7')]),
    ]))
    return t


# ── Main ───────────────────────────────────────────────────────────────────
def main():
    input_path = '/Users/luizlessa/brasilia-insider/editorial/briefing_nano_bits_externo.md'
    output_path = '/Users/luizlessa/brasilia-insider/editorial/briefing_nano_bits_externo.pdf'

    with open(input_path, 'r', encoding='utf-8') as f:
        md_text = f.read()

    styles = make_styles()

    doc = SimpleDocTemplate(
        output_path,
        pagesize=A4,
        leftMargin=MARGIN,
        rightMargin=MARGIN,
        topMargin=2.8 * cm,
        bottomMargin=2.5 * cm,
        title='Briefing Editorial — Nano Bits',
        author='The BR Insider',
    )

    story = parse_markdown(md_text, styles)

    doc.build(story, canvasmaker=HeaderFooterCanvas)
    print(f'PDF gerado: {output_path}')


if __name__ == '__main__':
    main()
