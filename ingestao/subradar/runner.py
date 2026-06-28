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


def _calcular_score(alertas: list[dict]) -> tuple[int, str]:
    """Calcula score de risco 0-100 e texto baseado nos alertas."""
    pts = sum(
        {"critico": 40, "atencao": 15, "info": 2, "ok": 0}.get(a.get("severidade", ""), 0)
        for a in alertas
    )
    score = min(pts, 100)
    if score >= 70:
        return score, "critico"
    if score >= 40:
        return score, "alto"
    if score >= 15:
        return score, "medio"
    return score, "baixo"


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


def processar_cnpj(cnpj: str, cliente_id: str, razao_social: str | None, dry_run: bool = False) -> int:
    """
    Processa todas as fontes para um CNPJ.
    Retorna total de alertas gerados.
    """
    from .base import _ciclo_atual
    ciclo = _ciclo_atual()
    todos_alertas = []

    for fonte in FONTES:
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
        pdf_path = _gerar_pdf(dossie_id, output_dir=pdf_dir)
        if pdf_path:
            logger.info("%s: PDF gerado → %s", cnpj, pdf_path)
    except Exception as e:
        logger.warning("%s: falha ao gerar PDF (não bloqueante): %s", cnpj, e)

    logger.info("%s: %d alertas gravados (dossiê %s)", cnpj, len(todos_alertas), dossie_id)
    return len(todos_alertas)


def main() -> None:
    parser = argparse.ArgumentParser(description="Subradar — ingestão de fontes externas")
    parser.add_argument("--cnpj", help="Processar CNPJ específico (formato: 00.000.000/0000-00)")
    parser.add_argument("--cliente-id", help="UUID do cliente (obrigatório com --cnpj)")
    parser.add_argument("--dry-run", action="store_true", help="Não grava no Supabase")
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
