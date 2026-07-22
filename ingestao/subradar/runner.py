"""
Subradar Runner — processa fontes externas para um ou todos os CNPJs monitorados.

Uso:
  # Processar todos os CNPJs ativos
  python -m ingestao.subradar.runner

  # Processar CNPJ específico
  python -m ingestao.subradar.runner --cnpj 12.345.678/0001-90

  # Testar sem gravar no Supabase
  python -m ingestao.subradar.runner --dry-run
"""
from __future__ import annotations

import argparse
import logging
import os
import re
import sys

import requests

from .base import SUPABASE_URL, SUPABASE_KEY, upsert, _supabase_headers
from .divida_ativa import DividaAtivaConnector
from .bndes import BNDESConnector
from .opensanctions import OpenSanctionsConnector
from .leniencia import LenienciaConnector
from .societario import SocietarioConnector
from .dou import DOUConnector
from .sancoes import CEISConnector, CNEPConnector, CEPIMConnector
from .ibama import IBAMAConnector
from .cvm import CVMConnector
from .siconv import SICONVConnector
from .anvisa import ANVISAConnector
from .lista_suja import ListaSujaConnector
from .situacao_cadastral import SituacaoCadastralConnector
from .bacen import BACENConnector
from .mte_autos import MTEAutosConnector
from .aneel import ANEELConnector
from .ans import ANSConnector
from .datajud import DataJudConnector
from .tcu import TCUConnector
from .antt import ANTTConnector
from .anatel import ANATELConnector
from .protestos import ProtestosConnector
from .ofac import OFACConnector
from .uk_sanctions import UKSanctionsConnector
from .protestos_nacional import ProtestosNacionalConnector
from .eu_sanctions import EUSanctionsConnector
from .un_sanctions import UNSanctionsConnector
from .worldbank_debarment import WorldBankDebarmentConnector
from .cade import CADEConnector
from .procon import PROCONConnector
from .susep import SUSEPConnector
from .anp import ANPConnector
from .antaq import ANTAQConnector
from .jucesp import JUCESPConnector
from .sicaf import SICAFConnector
from .previc import PREVICConnector
from .anac import ANACConnector
from .ana import ANAConnector
from .escavador import EscavadorConnector
from .opensanctions_pro import OpenSanctionsProConnector
from .cndt_tst_pj import CNDTTrabalhiPJConnector
from .crf_fgts_pj import CRFFGTSPJConnector
from .simples_nacional_pj import SimplesNacionalConnector
from .cnd_federal_pj import CNDFederalPJConnector
from .sefaz_estadual_pj import SEFAZEstadualPJConnector
from .iss_municipal_pj import ISSMunicipalPJConnector
from .tce_estaduais_pj import TCEEstaduaisPJConnector
from .contratos_transparencia_pj import ContratosTransparenciaPJConnector
from .inpi_marcas_pj import INPIMarcasConnector
from .midia_adversa_pj import MidiaAdversaPJConnector
from .doe_estaduais_pj import DOEEstaduaisPJConnector
from .grafo_socios_pj import GrafoSociosPJConnector
from .infosimples_cnd_estadual_pj import InfosimplesCNDEstadualPJConnector
from .bndes_devedores_pj import BNDESDevedoresPJConnector
from .directdata import DirectDataConnector
from .bigdatacorp import BigDataCorpConnector, BigDataCorpScoreConnector
from .socios_compliance import SociosComplianceConnector

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
)
logger = logging.getLogger("subradar.runner")

FONTES = [
    DividaAtivaConnector(),    # pgfn — dívida ativa (tabela local)
    BNDESConnector(),          # pncp + emendas (tabela interna BR Insider)
    LenienciaConnector(),      # acordos de leniência (Portal Transparência)
    SocietarioConnector(),     # qsa + capital social (rfb interno)
    OpenSanctionsConnector(),  # sanções internacionais (só com sócio estrangeiro)
    DOUConnector(),            # Diário Oficial da União (30 dias, DO1+DO3)
    CEISConnector(),           # CEIS — empresas inidôneas e suspensas
    CNEPConnector(),           # CNEP — punidas pela Lei Anticorrupção
    CEPIMConnector(),          # CEPIM — entidades impedidas de convênios
    IBAMAConnector(),          # IBAMA — autos de infração ambiental (tabela local)
    CVMConnector(),            # CVM — processos administrativos sancionadores (tabela local)
    SICONVConnector(),         # SICONV — convênios federais (Portal Transparência)
    ANVISAConnector(),         # ANVISA — AFE/AE (token gov.br opcional)
    ListaSujaConnector(),      # Lista Suja MTE — trabalho análogo à escravidão
    SituacaoCadastralConnector(), # Situação Cadastral RFB — ativo/suspenso/inapto/baixado
    SimplesNacionalConnector(),         # Simples Nacional — regime tributário e exclusões recentes
    CNDTTrabalhiPJConnector(),          # CNDT/TST — débitos trabalhistas como empregadora
    CRFFGTSPJConnector(),               # CRF/FGTS — Certificado de Regularidade FGTS (Caixa)
    CNDFederalPJConnector(),            # CND Federal — certidão RFB+PGFN consolidada
    SEFAZEstadualPJConnector(),         # SEFAZ — dívida ativa estadual (SP/MG/RJ)
    ISSMunicipalPJConnector(),          # ISS — dívida ativa municipal (SP/BH/RJ)
    TCEEstaduaisPJConnector(),          # TCE-SP/MG/RJ — irregularidades em contratos públicos
    ContratosTransparenciaPJConnector(), # Portal Transparência — contratos federais ativos/rescindidos
    BACENConnector(),          # BACEN — entidades supervisionadas (bancos, fintechs)
    MTEAutosConnector(),       # MTE — autos de infração trabalhista
    ANEELConnector(),          # ANEEL — autos de infração setor elétrico
    ANSConnector(),            # ANS — operadoras de plano de saúde (situação)
    DataJudConnector(),        # DataJud/CNJ — falências, RJ, execuções fiscais, improbidade
    TCUConnector(),            # TCU — certidão de regularidade + acórdãos (Playwright)
    ANTTConnector(),           # ANTT — habilitação transporte rodoviário interestadual
    ANATELConnector(),         # ANATEL — sanções administrativas e processos sancionadores
    ProtestosConnector(),         # Protestos — CENPROT-SP (cobertura SP, gratuito, scraping)
    ProtestosNacionalConnector(), # Protestos — Direct Data/IEPTB (cobertura nacional, pago, DIRECT_DATA_TOKEN)
    OFACConnector(),              # OFAC SDN — sanções EUA (XML oficial, diário)
    UKSanctionsConnector(),       # UK Sanctions List — FCDO (CSV oficial, contínuo)
    EUSanctionsConnector(),       # EU Financial Sanctions — Comissão Europeia (XML, 6h)
    UNSanctionsConnector(),       # UN SC Consolidated List — ONU (XML, 6h)
    WorldBankDebarmentConnector(), # World Bank Debarment — OpenSanctions (CSV, 12h)
    CADEConnector(),              # CADE — contencioso antitruste (CSV, 24h)
    PROCONConnector(),            # PROCON/SINDEC — reclamações fundamentadas (CSV, 24h)
    SUSEPConnector(),             # SUSEP — corretoras/sociedades irregulares (CSV, 12h)
    ANPConnector(),               # ANP — multas e processos sancionadores (CSV, 12h)
    ANTAQConnector(),             # ANTAQ — processos sancionadores aquaviários (CSV, 12h)
    JUCESPConnector(),            # JUCESP/RFB — mudanças societárias relevantes (snapshot diff)
    SICAFConnector(),             # SICAF — fornecedores impedidos/suspensos para contratos federais
    PREVICConnector(),            # PREVIC — medidas administrativas em fundos de pensão
    ANACConnector(),              # ANAC — infrações e sanções em aviação civil
    ANAConnector(),               # ANA — sanções em recursos hídricos e saneamento
    EscavadorConnector(),         # Escavador — processos judiciais nacionais (ESCAVADOR_API_KEY)
    OpenSanctionsProConnector(),  # OpenSanctions Pro — 400+ listas globais (OPENSANCTIONS_PRO_KEY)
    BigDataCorpConnector(),       # BigDataCorp — protestos cartoriais + processos sócios (BIGDATA_CORP_TOKEN)
    SociosComplianceConnector(),  # Sócios PF — CEIS/CNEP/MTE/PGFN/sanções internacionais por CPF
    GrafoSociosPJConnector(),              # Grafo de sócios — vínculos cruzados, paraíso fiscal, concentração
    INPIMarcasConnector(),                 # INPI — marcas registradas, oposições e nulidades
    MidiaAdversaPJConnector(),             # Mídia adversa — NewsAPI + Haiku (razão social, 90 dias)
    DOEEstaduaisPJConnector(),             # DOE estaduais — SP/MG/RJ (interdição, embargo, autuação)
    InfosimplesCNDEstadualPJConnector(),   # Infosimples — CND estadual 27 UFs (INFOSIMPLES_TOKEN)
    BNDESDevedoresPJConnector(),           # BNDES — lista de inadimplentes (portal público)
]

# Fontes exclusivas para consulta avulsa (dossiê pontual R$ 197).
# Não incluídas no ciclo de monitoramento — cobram por consulta.
FONTES_AVULSA = FONTES + [
    DirectDataConnector(),        # Direct Data — dossiê PJ completo 22 APIs (~R$ 15,70/consulta)
    BigDataCorpScoreConnector(),  # BigDataCorp Score Quod/Boa Vista PJ (~R$ 2,41/consulta)
]


def _buscar_cnpjs_ativos() -> list[dict]:
    """Busca todos os CNPJs ativos em sub_cnpjs_monitorados."""
    if not SUPABASE_URL or not SUPABASE_KEY:
        logger.error("SUPABASE_URL/KEY não configurados")
        return []
    url = f"{SUPABASE_URL}/rest/v1/sub_cnpjs_monitorados"
    params = {"ativo": "eq.true", "select": "cnpj,razao_social,cliente_id"}
    r = requests.get(url, params=params, headers=_supabase_headers(), timeout=15)
    if not r.ok:
        logger.error("Erro ao buscar CNPJs: %s", r.text[:200])
        return []
    return r.json()


def _buscar_ou_criar_dossie(cliente_id: str, cnpj: str, razao_social: str | None, ciclo: str) -> str | None:
    """Garante que existe um dossiê para o CNPJ no ciclo. Retorna o id."""
    if not SUPABASE_URL or not SUPABASE_KEY:
        return None
    url = f"{SUPABASE_URL}/rest/v1/sub_dossies"

    # Busca existente
    params = {"cliente_id": f"eq.{cliente_id}", "cnpj": f"eq.{cnpj}", "ciclo": f"eq.{ciclo}"}
    r = requests.get(url, params=params, headers=_supabase_headers(), timeout=15)
    rows = r.json() if r.ok else []
    if rows:
        return rows[0]["id"]

    # Cria novo
    payload = [{
        "cliente_id": cliente_id,
        "cnpj": cnpj,
        "razao_social": razao_social,
        "ciclo": ciclo,
        "score_num": 0,
        "score_texto": "baixo",
        "status": "gerado",
    }]
    headers = {**_supabase_headers(), "Prefer": "return=representation"}
    r = requests.post(url, json=payload, headers=headers, timeout=15)
    if r.ok:
        return r.json()[0]["id"]
    logger.error("Erro ao criar dossiê: %s", r.text[:200])
    return None


_PESOS_PJ = {"critico": 30, "atencao": 10, "info": 2}
_CAT_JUDICIAL_PJ   = {"datajud", "tcu", "cade", "tce_estaduais_pj", "cndt_tst_pj"}
_CAT_INTL_PJ       = {"ofac", "uk_sanctions", "eu_sanctions", "un_sanctions",
                       "worldbank_debarment", "opensanctions_pro", "opensanctions"}
_CAT_CGU_PJ        = {"ceis", "cnep", "cepim", "lista_suja", "sicaf", "leniencia"}
_CAT_FISCAL_PJ     = {"cnd_federal", "crf_fgts", "sefaz_estadual", "divida_ativa"}

_FAIXAS_PJ = [
    (0,  20,  "VERDE",    "Sem ocorrências significativas"),
    (21, 50,  "AMARELO",  "Atenção — verificar contexto antes de contratar"),
    (51, 80,  "LARANJA",  "Risco elevado — due diligence aprofundada recomendada"),
    (81, 100, "VERMELHO", "Risco crítico — contraindicado sem apuração especializada"),
]


def _calcular_score(alertas: list[dict]) -> tuple[int, str]:
    """Calcula score de risco proprietário 0-100 com bônus por categoria."""
    score = sum(_PESOS_PJ.get(a.get("severidade", ""), 0) for a in alertas)

    fontes = {(a.get("fonte") or "").lower() for a in alertas}
    if fontes & _CAT_JUDICIAL_PJ:
        score += 10
    if fontes & _CAT_INTL_PJ:
        score += 10
    if fontes & _CAT_CGU_PJ:
        score += 5
    if fontes & _CAT_FISCAL_PJ:
        score += 5

    score = min(score, 100)

    for lo, hi, cor, _ in _FAIXAS_PJ:
        if lo <= score <= hi:
            return score, cor.lower()
    return score, "vermelho"


def _atualizar_dossie(dossie_id: str, alertas: list[dict]) -> None:
    """Atualiza score e total de alertas no dossiê."""
    if not SUPABASE_URL or not SUPABASE_KEY or not dossie_id:
        return
    score_num, score_texto = _calcular_score(alertas)
    url = f"{SUPABASE_URL}/rest/v1/sub_dossies"
    params = {"id": f"eq.{dossie_id}"}
    payload = {
        "score_num": score_num,
        "score_texto": score_texto,
        "total_alertas": len(alertas),
        "status": "gerado",
    }
    headers = {**_supabase_headers(), "Prefer": "return=minimal"}
    requests.patch(url, json=payload, params=params, headers=headers, timeout=15)


def processar_cnpj(
    cnpj: str,
    cliente_id: str,
    razao_social: str | None,
    dry_run: bool = False,
    avulsa: bool = False,
) -> int:
    """
    Processa todas as fontes para um CNPJ.

    avulsa=True → usa FONTES_AVULSA (inclui Direct Data, para dossiê pontual R$ 197).
    avulsa=False → usa FONTES (monitoramento contínuo, sem custo por consulta Direct Data).
    Retorna total de alertas gerados.
    """
    from .base import _ciclo_atual
    ciclo = _ciclo_atual()
    todos_alertas = []

    fontes_ativas = FONTES_AVULSA if avulsa else FONTES
    for fonte in fontes_ativas:
        try:
            alertas = fonte.consultar_cnpj(cnpj)
            todos_alertas.extend(alertas)
        except Exception as e:
            logger.error("Fonte %s falhou para %s: %s", fonte.fonte, cnpj, e)

    if not todos_alertas:
        logger.info("%s: sem alertas em nenhuma fonte", cnpj)
        return 0

    if dry_run:
        logger.info("[DRY-RUN] %s: %d alertas — não gravando", cnpj, len(todos_alertas))
        for a in todos_alertas:
            print(f"  [{a['severidade'].upper()}] {a['fonte']}: {a['titulo']}")
        return len(todos_alertas)

    # Garante dossiê existe
    dossie_id = _buscar_ou_criar_dossie(cliente_id, cnpj, razao_social, ciclo)
    if not dossie_id:
        logger.error("Não foi possível criar dossiê para %s", cnpj)
        return 0

    # Adiciona dossie_id em todos os alertas
    for a in todos_alertas:
        a["dossie_id"] = dossie_id

    # Persiste alertas
    upsert("sub_alertas", todos_alertas)

    # Atualiza score no dossiê
    _atualizar_dossie(dossie_id, todos_alertas)

    # Gera PDF do dossiê
    pdf_dir = os.environ.get("SUBRADAR_PDF_DIR", "/tmp/subradar")
    os.makedirs(pdf_dir, exist_ok=True)
    try:
        from .pdf import gerar_dossie as _gerar_pdf
        from .pdf_upload import upload_pdf as _upload_pdf
        pdf_path = _gerar_pdf(dossie_id, output_dir=pdf_dir)
        if pdf_path:
            logger.info("%s: PDF gerado → %s", cnpj, pdf_path)
            _upload_pdf(pdf_path)
    except Exception as e:
        logger.warning("%s: falha ao gerar/upload PDF (não bloqueante): %s", cnpj, e)

    logger.info("%s: %d alertas gravados (dossiê %s)", cnpj, len(todos_alertas), dossie_id)
    return len(todos_alertas)


def main() -> None:
    parser = argparse.ArgumentParser(description="Subradar — ingestão de fontes externas")
    parser.add_argument("--cnpj", help="Processar CNPJ específico (formato: 00.000.000/0000-00)")
    parser.add_argument("--cliente-id", help="UUID do cliente (obrigatório com --cnpj)")
    parser.add_argument("--dry-run", action="store_true", help="Não grava no Supabase")
    parser.add_argument(
        "--avulsa",
        action="store_true",
        help="Consulta avulsa: inclui Direct Data (dossiê pontual, custa R$ 15,70/consulta)",
    )
    args = parser.parse_args()

    if args.cnpj:
        if not args.cliente_id and not args.dry_run:
            print("--cliente-id obrigatório com --cnpj (exceto em --dry-run)")
            sys.exit(1)
        from datetime import date, timedelta
        from .dou import INLabsSession, SECOES, INLABS_EMAIL
        if INLABS_EMAIL:
            hoje = date.today()
            datas_dou = [
                (hoje - timedelta(days=d)).isoformat()
                for d in range(30)
                if (hoje - timedelta(days=d)).weekday() < 5
            ][:20]
            logger.info("DOU: pré-aquecendo cache...")
            INLabsSession.warm_cache(datas_dou, SECOES)
        total = processar_cnpj(
            cnpj=args.cnpj,
            cliente_id=args.cliente_id or "00000000-0000-0000-0000-000000000000",
            razao_social=None,
            dry_run=args.dry_run,
            avulsa=args.avulsa,
        )
        print(f"\nTotal: {total} alertas")
        return

    # Modo batch: todos os CNPJs monitorados
    cnpjs = _buscar_cnpjs_ativos()
    if not cnpjs:
        logger.warning("Nenhum CNPJ ativo em sub_cnpjs_monitorados")
        return

    logger.info("Iniciando processamento de %d CNPJs", len(cnpjs))

    # Pré-aquece cache DOU: baixa todos os ZIPs uma única vez para todos os CNPJs
    from datetime import date, timedelta
    from .dou import INLabsSession, SECOES, INLABS_EMAIL
    if INLABS_EMAIL:
        hoje = date.today()
        datas_dou = [
            (hoje - timedelta(days=d)).isoformat()
            for d in range(30)
            if (hoje - timedelta(days=d)).weekday() < 5
        ][:20]
        logger.info("DOU: pré-aquecendo cache (%d datas × %d seções)...", len(datas_dou), len(SECOES))
        INLabsSession.warm_cache(datas_dou, SECOES)

    total_geral = 0
    for row in cnpjs:
        total_geral += processar_cnpj(
            cnpj=row["cnpj"],
            cliente_id=row["cliente_id"],
            razao_social=row.get("razao_social"),
            dry_run=args.dry_run,
        )

    logger.info("Concluído: %d alertas gerados no total", total_geral)


if __name__ == "__main__":
    main()
