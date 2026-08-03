"""
Doadores da campanha Tarcísio de Freitas — Governador SP 2022
Fontes: TSE DivulgaCandContas, Agência Pública, CNN Brasil, Metrópoles, Repórter Brasil

Para cada doador PF identificado, mapeamos as empresas (PJ) a ele vinculadas
que podem ter obtido contratos/concessões do governo SP 2023-2026.

Estrutura:
    DOADORES_PF  — CPFs e dados do doador individual (para busca TSE)
    EMPRESAS_PJ  — CNPJs das empresas ligadas a cada doador
    CNPJS_FLAT   — lista plana de CNPJs para cruzamento

Nota: CNPJs marcados com needs_verification=True foram derivados por pesquisa
secundária e devem ser confirmados na Receita Federal antes de publicação.
"""

from __future__ import annotations
from dataclasses import dataclass, field

# ---------------------------------------------------------------------------
# Estrutura de dados
# ---------------------------------------------------------------------------

@dataclass
class EmpresaDoador:
    cnpj: str                    # XX.XXX.XXX/XXXX-XX ou sem formatação
    razao_social: str
    setor: str
    vinculo_ao_doador: str       # como a empresa se liga ao doador
    needs_verification: bool = False  # True = confirmar CNPJ na RFB antes de publicar
    notas: str = ""


@dataclass
class DoadorCampanha:
    nome: str
    cpf: str                     # para busca no TSE (DivulgaCandContas)
    valor_doado: float
    rank_doador: int             # posição entre doadores de Tarcísio 2022
    status_investigativo: str    # "limpo" | "investigado" | "preso"
    operacao: str = ""
    empresas: list[EmpresaDoador] = field(default_factory=list)


# ---------------------------------------------------------------------------
# Doadores individuais + empresas vinculadas
# ---------------------------------------------------------------------------

DOADORES_PF: list[DoadorCampanha] = [

    DoadorCampanha(
        nome="Fabiano Zettel",
        cpf="027.818.816-86",
        valor_doado=2_000_000.00,
        rank_doador=1,
        status_investigativo="preso",
        operacao="Operação Compliance Zero (PF, jan/2026)",
        empresas=[
            EmpresaDoador(
                cnpj="33.923.798/0001-00",
                razao_social="Banco Master S/A — EM LIQUIDAÇÃO EXTRAJUDICIAL",
                setor="Banco comercial",
                vinculo_ao_doador="Fabiano Zettel é cunhado de Daniel Bueno Vorcaro, presidente formal do banco. "
                                  "Vorcaro consta como Presidente na RFB (desde 01/12/2017).",
                needs_verification=False,  # ✓ confirmado RFB 15/jun/2026
                notas="CNPJ 33923798000100 ✓ Situação: ATIVA mas EM LIQUIDAÇÃO EXTRAJUDICIAL — confirmado RFB 15/jun/2026. "
                      "S.A. FECHADA, capital R$ 3,76 bilhões, sede RJ (Praia de Botafogo 228). "
                      "ZETTEL PRESO: 14/jan/2026 (tentou embarcar Dubai), preventiva 04/mar/2026 — Op. Compliance Zero (PF). "
                      "BANCO EM LIQUIDAÇÃO: o Banco Central decretou liquidação extrajudicial do Banco Master — "
                      "contexto: o BCB estava avaliando absorção parcial pelo BRB (Banco de Brasília) em 2025. "
                      "Vorcaro (presidente) NÃO foi preso — Zettel (cunhado, operador) foi o alvo. "
                      "Verificar se governo SP tinha aplicações financeiras ou operações com o Banco Master.",
            ),
        ],
    ),

    DoadorCampanha(
        nome="Frederico Carlos Gerdau Johannpeter",
        cpf="",  # não divulgado publicamente — buscar por nome no TSE
        valor_doado=1_000_000.00,
        rank_doador=2,
        status_investigativo="limpo",
        empresas=[
            EmpresaDoador(
                cnpj="33.611.500/0001-19",
                razao_social="Gerdau S.A.",
                setor="Produção de laminados longos de aço",
                vinculo_ao_doador="Frederico Gerdau Johannpeter é vice-presidente. "
                                  "NÃO consta na diretoria RFB — controle via família Johannpeter no Conselho. "
                                  "Conselheiros: André Bier, Claudio e Guilherme Chagas Gerdau Johannpeter.",
                needs_verification=False,  # ✓ confirmado RFB 15/jun/2026
                notas="CNPJ 33611500000119 ✓ Ativa, capital R$ 24,3 bilhões, Av. Dra. Ruth Cardoso 8501, SP. "
                      "Empresa operacional do grupo — produção de aço. Checar contratos de fornecimento com governo SP (obras, infraestrutura).",
            ),
            EmpresaDoador(
                cnpj="92.690.783/0001-09",
                razao_social="Metalúrgica Gerdau S.A.",
                setor="Holdings (participações)",
                vinculo_ao_doador="Holding da família Gerdau Johannpeter. Mesmos conselheiros da Gerdau S.A.",
                needs_verification=False,  # ✓ confirmado RFB 15/jun/2026
                notas="CNPJ 92690783000109 ✓ Ativa, capital R$ 10,99 bilhões, mesmo endereço da Gerdau S.A. "
                      "Mesmo email cpg-dteicms@gerdau.com.br. É a holding-mãe — cruzar ambos os CNPJs no PNCP.",
            ),
        ],
    ),

    DoadorCampanha(
        nome="Salim Mattar",
        cpf="",  # buscar por nome no TSE
        valor_doado=800_000.00,
        rank_doador=3,
        status_investigativo="limpo",
        empresas=[
            EmpresaDoador(
                cnpj="16.670.085/0001-55",
                razao_social="Localiza Rent a Car S.A.",
                setor="Locação de automóveis sem condutor",
                vinculo_ao_doador="Salim Mattar é fundador e ex-CEO da Localiza. "
                                  "NÃO consta no quadro societário RFB jun/2026 — saiu da gestão executiva. "
                                  "Também foi Secretário de Desestatização do governo Bolsonaro (2019-2020).",
                needs_verification=False,  # ✓ confirmado RFB 15/jun/2026
                notas="CNPJ 16670085000155 ✓ Ativa, capital R$ 19,97 bilhões, sede BH-MG. "
                      "PORTA GIRATÓRIA: Mattar foi Secretário federal de Desestatização (Bolsonaro) → fundador Localiza → doador de Tarcísio. "
                      "Localiza opera frotas em contratos com governo SP (locação de veículos oficiais, saúde etc.) — cruzar PNCP. "
                      "Mattar não está mais na diretoria formal; verificar se ainda é acionista relevante via CVM.",
            ),
        ],
    ),

    DoadorCampanha(
        nome="Maribel Schmittz Golin",
        cpf="",  # buscar por nome no TSE
        valor_doado=500_000.00,
        rank_doador=6,
        status_investigativo="investigado",
        operacao="Operação Mafiusi (PF, dez/2024) — lavagem para PCC e 'Ndrangheta",
        empresas=[
            EmpresaDoador(
                cnpj="",  # Stall Energy — CNPJ a levantar
                razao_social="Stall Energy (Boituva-SP)",
                setor="Energia",
                vinculo_ao_doador="Co-administradora da empresa",
                needs_verification=True,
                notas="Secretário Jorge Lima (Desenvolvimento Econômico-SP) visitou a Stall Energy "
                      "em Boituva em ago/2024. Empresas de Maribel movimentaram R$ 1,4 bi sem funcionários. "
                      "CNPJ a confirmar na Junta Comercial-SP.",
            ),
        ],
    ),

    DoadorCampanha(
        nome="Rubens Ometto Silveira Mello",
        cpf="",  # buscar por nome no TSE
        valor_doado=200_000.00,
        rank_doador=7,  # rank entre doadores de Tarcísio; foi o maior doador GERAL de 2022 (R$ 8,9M)
        status_investigativo="limpo",
        empresas=[
            EmpresaDoador(
                cnpj="50.746.577/0001-15",
                razao_social="Cosan S.A.",
                setor="Holdings / energia / logística / agronegócio",
                vinculo_ao_doador="Rubens Ometto é controlador histórico da Cosan. "
                                  "Presidente formal (RFB jun/2026): Marcelo Eduardo Martins — Ometto NÃO consta como diretor/presidente no quadro societário atual.",
                needs_verification=False,  # ✓ confirmado RFB 15/jun/2026
                notas="CNPJ 50746577000115 ✓ Ativa, capital R$ 8,18 bilhões, Av. Brig. Faria Lima 4100, SP. "
                      "MESMO email/telefone da Comgás (fiscalizacaocar@raizen.com / (19) 3423-8000) — confirma integração operacional Cosan↔Raízen↔Comgás no mesmo endereço. "
                      "Ometto não aparece no quadro societário RFB — verificar via DRI/CVM se ainda é acionista controlador. "
                      "Controladas relevantes: Comgás (concessão gás SP), Raízen (etanol/energia), Rumo Logística (ferrovias).",
            ),
            EmpresaDoador(
                cnpj="61.856.571/0001-17",
                razao_social="Companhia de Gás de São Paulo — Comgás",
                setor="Distribuição de gás natural (concessão estadual SP)",
                vinculo_ao_doador="Subsidiária da Cosan, opera sob concessão do governo SP. "
                                  "Email institucional fiscalizacaocar@raizen.com confirma integração operacional com Raízen.",
                needs_verification=False,  # ✓ confirmado RFB 15/jun/2026
                notas="CONCESSÃO ESTADUAL ATIVA — prioridade máxima de cruzamento. "
                      "CNPJ 61856571000117 ✓ Ativa, S.A. Aberta, capital R$ 536M, Av. Brig. Faria Lima 3732, SP. "
                      "Email raizen.com confirma elo Cosan→Raízen→Comgás. "
                      "Verificar termos aditivos e renovações de concessão ARSESP no período Tarcísio (2023-2026).",
            ),
            EmpresaDoador(
                cnpj="71.550.388/0001-42",
                razao_social="Rumo Logística Operadora Multimodal S.A.",
                setor="Operador portuário / logística ferroviária",
                vinculo_ao_doador="Rubens Ometto Silveira Mello consta NOMINALMENTE como Conselheiro de Administração (desde 13/08/2015). "
                                  "Empresa pertence ao grupo Cosan.",
                needs_verification=False,  # ✓ confirmado RFB 15/jun/2026
                notas="CNPJ 71550388000142 — situação: BAIXADA (encerrada). NÃO usar para cruzamento PNCP. "
                      "Mesmo telefone/email do grupo Cosan: (19) 3423-8000 / fiscalizacaocar@raizen.com. "
                      "Sede: Av. Cândido Gaffree s/n, Santos-SP (porto). "
                      "ACHADO: Ometto aparece NOMINALMENTE no quadro societário desta empresa — confirma controle direto sobre o grupo. "
                      "A Rumo Logística atual (ferrovias) pode ter CNPJ diferente — levantar na RFB por nome.",
            ),
            # TODO: levantar CNPJ correto da Raízen Energia S.A. (joint venture Cosan × Shell)
            # e da Rumo S.A. (holding ferroviária ativa) na RFB

        ],
    ),

    DoadorCampanha(
        nome="Arnaldo Costa Vargas",
        cpf="",  # buscar por nome no TSE
        valor_doado=200_000.00,
        rank_doador=8,
        status_investigativo="limpo",
        empresas=[
            EmpresaDoador(
                cnpj="",  # CampSeg — a levantar
                razao_social="CampSeg Vigilância e Segurança Patrimonial",
                setor="Segurança privada",
                vinculo_ao_doador="Empresa do sócio de Vargas (Nelson Santini Neto), "
                                  "contratada pela própria campanha por R$ 73.516,04",
                needs_verification=True,
                notas="Conflito de interesse documentado: doador × empresa contratada "
                      "pela campanha. Checar contratos com governo SP pós-2023.",
            ),
            EmpresaDoador(
                cnpj="",  # AutoDefesa Brasil — a levantar
                razao_social="AutoDefesa Brasil",
                setor="Segurança privada",
                vinculo_ao_doador="Empresa de Vargas (diretor)",
                needs_verification=True,
            ),
        ],
    ),

    # Doadores com infrações ambientais — amostra representativa
    DoadorCampanha(
        nome="Luciano Maffra de Vasconcellos",
        cpf="",
        valor_doado=300_000.00,
        rank_doador=9,
        status_investigativo="limpo",
        empresas=[
            EmpresaDoador(
                cnpj="",
                razao_social="Fazendas em BA e GO (nomes a levantar)",
                setor="Agropecuária",
                vinculo_ao_doador="Proprietário",
                needs_verification=True,
                notas="Acumula +R$ 952k em multas IBAMA: desmatamento, agrotóxico, "
                      "alteração de curso d'água. Fonte: Repórter Brasil.",
            ),
        ],
    ),
]


# ---------------------------------------------------------------------------
# Lista plana de CNPJs para cruzamento
# ---------------------------------------------------------------------------

def cnpjs_para_cruzamento(verificados_apenas: bool = False) -> list[dict]:
    """
    Retorna lista de dicts {cnpj, razao_social, setor, doador, valor_doado,
    status_investigativo, needs_verification} prontos para cruzamento.

    Args:
        verificados_apenas: se True, exclui CNPJs com needs_verification=True.
    """
    rows = []
    for doador in DOADORES_PF:
        for emp in doador.empresas:
            if not emp.cnpj:
                continue  # CNPJ ainda não levantado
            if verificados_apenas and emp.needs_verification:
                continue
            rows.append({
                "cnpj": emp.cnpj.replace(".", "").replace("/", "").replace("-", ""),
                "cnpj_fmt": emp.cnpj,
                "razao_social": emp.razao_social,
                "setor": emp.setor,
                "doador_nome": doador.nome,
                "doador_valor": doador.valor_doado,
                "doador_status": doador.status_investigativo,
                "doador_operacao": doador.operacao,
                "needs_verification": emp.needs_verification,
                "notas": emp.notas,
            })
    return rows


CNPJS_FLAT = cnpjs_para_cruzamento()
