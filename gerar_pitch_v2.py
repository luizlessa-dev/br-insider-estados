from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import cm
from reportlab.lib.colors import HexColor
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, HRFlowable
from reportlab.lib.enums import TA_LEFT, TA_JUSTIFY

MARGIN = 2.2 * cm

doc = SimpleDocTemplate(
    "editorial/Frias_armaria_pitch_v2.pdf",
    pagesize=A4,
    leftMargin=MARGIN, rightMargin=MARGIN,
    topMargin=2.5*cm, bottomMargin=2.5*cm,
)

CINZA_ESCURO = HexColor("#1a1a1a")
CINZA_LEVE   = HexColor("#888888")
LINHA        = HexColor("#cccccc")

base = ParagraphStyle("base",
    fontName="Helvetica", fontSize=10.5, leading=16,
    textColor=CINZA_ESCURO, alignment=TA_JUSTIFY, spaceAfter=10)

titulo_style = ParagraphStyle("titulo",
    fontName="Helvetica-Bold", fontSize=15, leading=20,
    textColor=CINZA_ESCURO, alignment=TA_LEFT, spaceAfter=6)

subtitulo_style = ParagraphStyle("subtitulo",
    fontName="Helvetica", fontSize=10, leading=14,
    textColor=CINZA_LEVE, alignment=TA_LEFT, spaceAfter=18)

secao_style = ParagraphStyle("secao",
    fontName="Helvetica-Bold", fontSize=10, leading=14,
    textColor=CINZA_ESCURO, spaceBefore=14, spaceAfter=4)

bullet_style = ParagraphStyle("bullet",
    fontName="Helvetica", fontSize=10, leading=15,
    textColor=CINZA_ESCURO, alignment=TA_LEFT,
    leftIndent=16, spaceAfter=5)

rodape_style = ParagraphStyle("rodape",
    fontName="Helvetica", fontSize=8.5, leading=12,
    textColor=CINZA_LEVE, alignment=TA_LEFT)

story = []

story.append(Paragraph(
    'A armaria que virou “locadora”: como Mário Frias gastou a cota parlamentar com o rei do tiro paulista',
    titulo_style))
story.append(Paragraph(
    'Briefing investigativo · junho de 2026 · confidencial',
    subtitulo_style))
story.append(HRFlowable(width="100%", thickness=0.5, color=LINHA, spaceAfter=16))

story.append(Paragraph(
    'Mário Frias, deputado federal pelo PL-SP e ex-secretário especial da Cultura de Bolsonaro, fez o contribuinte pagar <b>R$ 91.200 a uma loja de armas e munições</b> — registrados como “locação de veículos”.',
    base))

story.append(Paragraph('ENTENDA O MECANISMO', secao_style))
story.append(Paragraph(
    'Todo deputado tem a CEAP, a Cota para o Exercício da Atividade Parlamentar: um teto mensal de verba pública (para São Paulo, R$ 42.837,33/mês em 2024) que a Câmara usa para ressarcir despesas do mandato — combustível, passagem, aluguel de escritório, locação de veículo, divulgação. Não é dinheiro do bolso do deputado. O fornecedor emite a nota fiscal, o gabinete apresenta à Câmara, e a Câmara <b>paga com dinheiro do orçamento</b>. Ou seja: cada um desses R$ 7.600 saiu do bolso do contribuinte, não do de Frias. E o que a Câmara ressarciu como “aluguel de carro” foi faturado por uma armaria.',
    base))

story.append(Paragraph('A EMPRESA', secao_style))
story.append(Paragraph(
    'A empresa: <b>L.D.P Comércio de Produtos Controlados Ltda.</b> (CNPJ 36.532.189/0001-00), registrada também como <b>L.L.D.P. Comércio de Armas e Munições</b>. CNAE principal: comércio varejista de armas e munições. Doze notas, R$ 7.600 cada, mês a mês, de março de 2023 a fevereiro de 2024.',
    base))

story.append(Paragraph('NÃO É CASO ISOLADO', secao_style))
story.append(Paragraph(
    'A mesma armaria faturou R$ 29.150 para outro deputado do PL paulista, o <b>Delegado Bilynskyj</b>. Dois parlamentares, o mesmo partido, a mesma loja de armas posando de locadora de carros.',
    base))

story.append(Paragraph('AS NOTAS NÃO FECHAM', secao_style))
story.append(Paragraph(
    'Três delas têm a mesma data de emissão — 15 de junho de 2023 — cobrindo abril, maio e junho. Locação real não é faturada assim, retroativa e em bloco. A loja só tem o CNAE de “locação de automóveis” como atividade <i>secundária</i>, colada a uma lista de armas, artigos de caça e tiro esportivo — com cara de ter sido incluído só pra passar pela cota. E a prova mais dura: <b>quatro recibos consecutivos têm assinatura digital idêntica ao segundo</b> — todos carimbados em 25/10/2023 às 20h28. Locação mensal real gera documento mês a mês; a assinatura idêntica prova que foram fabricados em lote.',
    base))

story.append(Paragraph('QUEM ESTÁ POR TRÁS DA ARMARIA', secao_style))
story.append(Paragraph(
    'O dono da L.D.P. é <b>Gustavo Pazzini Araujo da Silva</b>, sócio-administrador único. Não é um fornecedor anônimo: é um dos nomes do tiro esportivo paulista, dono do <b>Grupo G16 — “Universidade do Tiro e Caça Premium”</b> —, tocado com o irmão Daniel. No nome dele há uma constelação de empresas do ramo: a <b>Seven Shooting Academia de Tiros</b> (a G16, três filiais), a <b>G16 Representações e Importações</b> (despachante bélico), o <b>Clube Social e Comércio de P.C.E</b>, além da própria L.D.P.',
    base))
story.append(Paragraph(
    'E o Pazzini liga Frias direto ao núcleo armamentista bolsonarista. A G16/Seven Shooting montou uma <b>loja de armas e clube de tiro dentro da Ceagesp</b> — estatal federal de abastecimento — por um <b>contrato de concessão de 20 anos</b>, aluguel de R$ 28.074,28/mês, autorizado na gestão de Ricardo Mello Araújo, coronel da reserva nomeado por Bolsonaro para presidir a Ceagesp. O clube operou de julho a novembro de 2022. E os laços são públicos e documentados: <b>Mário Frias visitou a obra da G16 na Ceagesp em 8 de setembro de 2022 e postou o vídeo no próprio Twitter</b>, celebrando “um dos maiores stands da G16 em São Paulo”. <b>Eduardo Bolsonaro aparece fotografado com os donos</b> — o mesmo Eduardo que doou R$ 74.728 à campanha de Frias naquele ano. Não é relação de mercado entre estranhos. É rede.',
    base))

story.append(Paragraph('TEM MAIS NA COTA', secao_style))
story.append(Paragraph(
    'Frias também pagou R$ 153.750 a um prestador pessoa física, 21 parcelas de R$ 7.500, sob a rubrica de “manutenção de escritório”. A investigação aponta para aluguel de uma sala comercial no 2º andar de um imóvel em Limeira/SP — e três dos recibos de 2026 foram assinados no <b>mesmo segundo exato</b>, no dia 5 de março, cobrindo os meses de janeiro, fevereiro e março retroativamente. A linha de apuração: escritório parlamentar fantasma ou superfaturamento de aluguel no interior paulista.',
    base))

story.append(Paragraph('AS EMENDAS — ONDE CAVAR', secao_style))
story.append(Paragraph(
    'Frias movimentou <b>R$ 68,5 milhões em emendas em 2024-2025</b>. Emenda não é ilegal; o que merece lupa é o destino de algumas. A maior parte vai a fundos municipais de saúde de SP (padrão normal). Mas saltam fora da curva:',
    base))

bullets = [
    '<b>R$ 735 mil para a Associação Paulista dos Rifles</b> — associação de tiro recebendo dinheiro público por emenda, exatamente o fio armamentista que atravessa toda a história.',
    '<b>R$ 2 milhões ao Instituto Conhecer Brasil</b> e centenas de milhares a outras OSCs (Esparatrapo, OMNI) — onde se checa se a ONG tem estrutura real e prestou contas.',
    '<b>R$ 3,2 milhões em Transferências Especiais</b> — a “emenda Pix”, que cai na conta do município sem destino especificado e com rastreabilidade notoriamente frágil.',
]
for b in bullets:
    story.append(Paragraph('• ' + b, bullet_style))

story.append(Paragraph(
    'Nada disso é, hoje, ilegalidade provada — é o mapa de onde a apuração precisa furar.',
    base))

story.append(Paragraph('O QUE JÁ ESTÁ PRETO NO BRANCO', secao_style))
story.append(Paragraph(
    'Os registros oficiais da cota (valores, datas, CNPJ, os dois deputados), o quadro societário da armaria na Receita, as empresas do Pazzini, a visita de Frias (vídeo dele próprio) e o episódio Ceagesp já noticiado por Brasil de Fato e CartaCapital. Tudo de fonte pública, conferido.',
    base))

story.append(Paragraph('A PROVA QUE FECHA A FRAUDE DAS NOTAS', secao_style))
story.append(Paragraph(
    'Pedidos de acesso à informação já protocolados. Um na Câmara, pelas notas e placas dos carros supostamente alugados (protocolo 2026060600000002). Outro no DETRAN-SP, para saber se a L.D.P. tem os veículos registrados (LAI 2026061012510865). Sabe-se que a armaria tem ao menos uma BMW 320i — o que está em xeque é a autenticidade das locações documentadas: <b>quatro recibos têm assinatura digital idêntica ao segundo</b> (25/10/2023, 20h28), provando que foram fabricados em lote, não mês a mês. Respostas previstas para o início de julho.',
    base))

story.append(Spacer(1, 14))
story.append(HRFlowable(width="100%", thickness=0.5, color=LINHA, spaceAfter=10))
story.append(Paragraph(
    'Fontes: Portal da Transparência (CEAP e emendas) · Receita Federal/BrasilAPI (CNPJ) · Brasil de Fato e CartaCapital (Ceagesp, 11/02/2023) · Twitter @mfriasoficial (vídeo 08/09/2022) · Metrópoles · LAIs 2026060600000002 e 2026061012510865',
    rodape_style))

doc.build(story)
print("PDF gerado com sucesso.")
