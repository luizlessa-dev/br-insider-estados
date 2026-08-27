"""
Subradar PF — pipeline de compliance para Pessoa Física (CPF)

*** ESTE é o pipeline de produção. *** Chamado por runner_pf_api.py (API Lambda
usada por subradar-web/app/api/pf/submit) e por .github/workflows/subradar-pf-runner.yml
(fallback manual). Qualquer outro runner_pf_*.py no diretório wip_5_fontes/ é
experimental/não-promovido — ver wip_5_fontes/README.md antes de editar.

Mercados alvo:
  - Imobiliárias: checagem de locatário
  - RH corporativo: background check de candidatos (com consentimento)
  - Credenciamento de MEIs / autônomos / prestadores PF
  - Due diligence de sócios (use socios_compliance.py para via CNPJ)

LGPD: consulta requer consentimento do titular (art. 7º, I) ou
      interesse legítimo documentado do contratante (art. 7º, IX).
      O produto deve coletar e armazenar o consentimento antes de rodar.

Uso:
  # Dry-run (não grava no Supabase)
  python3 -m ingestao.subradar.runner_pf --cpf 123.456.789-00 --dry-run

  # Run real com cliente
  python3 -m ingestao.subradar.runner_pf --cpf 123.456.789-00 --cliente-id <UUID>

  # Dossiê avulso completo (inclui BigDataCorp score PF)
  python3 -m ingestao.subradar.runner_pf --cpf 123.456.789-00 --cliente-id <UUID> --avulsa
"""
from __future__ import annotations

import argparse
import logging
import os
import re
import sys
import time
import inspect
from concurrent.futures import ThreadPoolExecutor, as_completed

from .base import limpar_memo, upsert, _ciclo_atual, SUPABASE_URL, SUPABASE_KEY

# Fontes compatíveis com PF
from .sancoes import CEISConnector, CNEPConnector
from .lista_suja import ListaSujaConnector
from .divida_ativa import DividaAtivaConnector
from .ofac import OFACConnector
from .uk_sanctions import UKSanctionsConnector
from .eu_sanctions import EUSanctionsConnector
from .un_sanctions import UNSanctionsConnector
from .worldbank_debarment import WorldBankDebarmentConnector
from .cpf_situacao import CPFSituacaoConnector
from .qsa_reverso import QSAReversoConnector
from .conselhos_profissionais import ConselhosProfissionaisConnector
from .cfc_contadores import CFCContadoresConnector
from .infosimples_conselhos import InfosimplesConselhosPFConnector
from .antecedentes_criminais_pf import AntecedentesHCrimosPFConnector
from .detran_restricoes_pf import DetranRestricoesConnector
from .processos_infosimples_pf import ProcessosInfosimplesPFConnector
from .dou_pf import DOUPFConnector
from .cepim_pf import CEPIMRepresentantePFConnector
from .improbidade_cnj_pf import ImprobidadeCNJPFConnector
from .protestos_cenprot_pf import ProtestosCenprotPFConnector
from .opensanctions_pro import OpenSanctionsProPFConnector
from .bnmp_pf import BNMPMandadosPrisaoPFConnector
from .tse_situacao_pf import TSESituacaoEleitoralPFConnector
from .crea_cau_pf import CREACONFEAPFConnector, CAUBRPFConnector
from .cndt_tst_pf import CNDTTrabalhiPFConnector
from .midia_adversa_gdelt_pf import MidiaAdversaGDELTPFConnector
from .doe_estaduais_pf import DOEEstaduaisPFConnector
from .cvm_insider_pf import CVMInsiderPFConnector
from .tce_estaduais_pf import TCEEstaduaisPFConnector
from .escavador_pf import EscavadorPFConnector
from .bdc_ondemand_async import submit_ondemand_pf
from .bigdatacorp_negativacoes import (
    BDCNegativacoesPFConnector, BDCProcessosPFConnector, BDCFinanceiroPFConnector,
    BDCVinculosPFConnector, BDCKycPFConnector,
)
from .protestos_nacional import ProtestosNacionalPFConnector
from .policia_federal_pf import PoliciaFederalPFConnector
from .policia_civil_pf import PolicíaCivilPFConnector

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
)
logger = logging.getLogger("subradar.runner_pf")

# ---------------------------------------------------------------------------
# Pipeline PF — fontes gratuitas (monitoramento e avulsa)
# ---------------------------------------------------------------------------

FONTES_PF = [
    # ── Cadastral ────────────────────────────────────────────────────────────
    CPFSituacaoConnector(),             # Situação cadastral do CPF na RFB
    BDCVinculosPFConnector(),           # Vínculos societários e empregatícios (business_relationships)

    # ── Judicial / Penal ─────────────────────────────────────────────────────
    BNMPMandadosPrisaoPFConnector(),    # BNMP/CNJ — mandados de prisão ativos
    PoliciaFederalPFConnector(),        # BDC Ondemand — antecedentes PF (nacional)
    PolicíaCivilPFConnector(),          # BDC Ondemand — antecedentes PC (12 estados)
    AntecedentesHCrimosPFConnector(),   # Infosimples — antecedentes criminais (Polícia Federal)
    CNDTTrabalhiPFConnector(),          # CNDT/TST — débitos trabalhistas como empregador
    # EscavadorPFConnector() saiu do fluxo PF: BDCProcessosPFConnector (dataset
    # "processes") cobre processos judiciais e a conta Escavador está com saldo
    # bloqueado. Reativar só se a cobertura do BDC se mostrar insuficiente.
    ProcessosInfosimplesPFConnector(),  # Infosimples — processos TRF/TRT (fallback Escavador)

    # ── Eleitoral / Idoneidade ───────────────────────────────────────────────
    # TSESituacaoEleitoralPFConnector() — PAUSADO em 27/08/2026.
    # A certidão do TSE é serviço restrito na Infosimples; a habilitação foi
    # solicitada e está em análise. Enquanto pendente, a fonte sairia como
    # "pendente" em todo dossiê e a trava de completude reteria TODAS as
    # entregas. Reativar assim que a Infosimples confirmar a habilitação:
    # basta descomentar a linha abaixo.
    # TSESituacaoEleitoralPFConnector(),

    # ── Conselhos profissionais ──────────────────────────────────────────────
    CREACONFEAPFConnector(),            # CREA/CONFEA — engenheiros e agrônomos (nacional)
    CAUBRPFConnector(),                 # CAU-BR — arquitetos e urbanistas
    ConselhosProfissionaisConnector(),  # Conselhos via Implanta API (CREA, CRM, OAB…)
    CFCContadoresConnector(),           # CFC — contador ativo/inativo (API oficial)
    InfosimplesConselhosPFConnector(),  # CRO/CRF/CFM/CFMV/CFP/CFBM/COREN via Infosimples

    # ── Sanções e restrições federais ────────────────────────────────────────
    CEPIMRepresentantePFConnector(),    # CEPIM — sócio de entidade impedida
    ImprobidadeCNJPFConnector(),        # CNJ/CNIA — improbidade administrativa e inelegibilidade
    ProtestosCenprotPFConnector(),      # CENPROT/IEPTB — protestos em cartório
    CEISConnector(),                    # CEIS — inidôneos CGU
    CNEPConnector(),                    # CNEP — punidos CGU
    ListaSujaConnector(),               # MTE — trabalho escravo
    DividaAtivaConnector(),             # PGFN — dívida ativa PF (portal público)

    # ── Diários Oficiais ─────────────────────────────────────────────────────
    DOUPFConnector(),                   # DOU — menções nos últimos 30 dias (DO1/DO2/DO3)
    DOEEstaduaisPFConnector(),          # DOE — SP, MG e RJ (90 dias)

    # ── Controle e tribunais ─────────────────────────────────────────────────
    TCEEstaduaisPFConnector(),          # TCE-SP, TCE-MG, TCE-RJ — irregularidades
    CVMInsiderPFConnector(),            # CVM — processos sancionadores (insider, fraude)

    # ── Crédito / Negativações / Protestos ─────────────────────────────────
    BDCNegativacoesPFConnector(),        # BigDataCorp — negativações/restrições bureaus PF (negative_data)
    BDCProcessosPFConnector(),           # BigDataCorp — processos judiciais PF (process_data; já no plano)
    BDCFinanceiroPFConnector(),          # BigDataCorp — dados financeiros estimados PF (financial_data)
    ProtestosNacionalPFConnector(),      # Direct Data — protestos IEPTB/CENPROT por CPF (pay-per-use)

    # ── Trânsito ─────────────────────────────────────────────────────────
    DetranRestricoesConnector(),         # Infosimples — restrições DETRAN (requer placa/RENAVAM)

    # ── Reputação / Mídia ────────────────────────────────────────────────────
    MidiaAdversaGDELTPFConnector(),      # Mídia adversa PF — GDELT Doc API (gratuito, sem chave)

    # ── Listas internacionais ────────────────────────────────────────────────
    OFACConnector(),                    # OFAC SDN — EUA
    UKSanctionsConnector(),             # UK Sanctions (FCDO)
    EUSanctionsConnector(),             # EU Sanctions
    UNSanctionsConnector(),             # ONU — Conselho de Segurança
    WorldBankDebarmentConnector(),      # Banco Mundial — Debarment
    OpenSanctionsProPFConnector(),      # OpenSanctions Pro — PEPs, INTERPOL, 400+ listas
    BDCKycPFConnector(),                # BigDataCorp KYC — PEP e sanções (match >= 85%)
]

# Fontes pagas — somente modo avulsa
try:
    from .bigdatacorp import BigDataCorpScoreConnector
    _BDC_SCORE_PF = BigDataCorpScoreConnector()
except ImportError:
    _BDC_SCORE_PF = None

try:
    from .escavador import EscavadorConnector
    _ESCAVADOR_PF = EscavadorConnector()
except ImportError:
    _ESCAVADOR_PF = None

from .bdc_marketplace_pf import (
    BDCRestritivosQuodPFConnector,
    BDCRestritevosBiroPFConnector,
    BDCFlagsNegativosQuodPFConnector,
    BDCSegurancaPublicaPFConnector,
    BDCScoreQuodPFConnector,
    BDCDadosFinanceirosPFConnector,   # incluso no plano base
    BDCNegativacoesPFConnectorV2,     # dataset name confirmado
    BDCScoreQuodPFConnectorV2,        # dataset name confirmado
)
from .directdata_pf_enriquecimento import DirectDataPFEnriquecimentoConnector
from .directdata_monitorapp import DirectDataMonitorAppConnector

FONTES_PF_AVULSA = FONTES_PF + [f for f in [_BDC_SCORE_PF] if f] + [
    BDCNegativacoesPFConnectorV2(),        # Negativações Quod (partner_quod_credit_risk_details_person)
    BDCScoreQuodPFConnectorV2(),           # Score Quod PF 300-1000 (partner_quod_credit_score_person)
    BDCFlagsNegativosQuodPFConnector(),    # Flags Negativos (marketplace_partner_quod_credit_risk_person)
    BDCSegurancaPublicaPFConnector(),      # Segurança Pública (on-demand, contato comercial)
    # BDCDadosFinanceirosPFConnector() removido: declara a mesma fonte
    # ("bdc_financeiro_pf") que BDCFinanceiroPFConnector. Como a chave única
    # de sub_pf_dados é (cpf, ciclo, fonte), as duas linhas no mesmo lote
    # faziam o Postgres recusar o INSERT inteiro (21000) e o dossiê morria.
    DirectDataPFEnriquecimentoConnector(), # Direct Data — enriquecimento PF: nome da mãe, prog. sociais
    DirectDataMonitorAppConnector(),       # Direct Data MonitorApp — eventos push PF cadastradas
]


def _strip(cpf: str) -> str:
    return re.sub(r"\D", "", str(cpf or ""))


def _fmt_cpf(cpf: str) -> str:
    c = _strip(cpf)
    return f"{c[:3]}.{c[3:6]}.{c[6:9]}-{c[9:11]}" if len(c) == 11 else cpf


# ---------------------------------------------------------------------------
# Score Proprietário de Risco — 0 (sem risco) a 100 (risco máximo)
# ---------------------------------------------------------------------------
#
# Metodologia:
#   Cada alerta contribui com pontos de risco proporcional à sua severidade.
#   Pesos: critico=30 · atencao=10 · info=2
#   Bônus por categoria de alto impacto:
#     +10 se houver alerta judicial (bnmp, cndt, processos)
#     +10 se houver sanção internacional (ofac, uk, eu, onu, worldbank, opensanctions)
#     +5  se houver sanção CGU (ceis, cnep, lista_suja)
#   Score final clamped em [0, 100].
#
# Faixas de risco:
#   0–20  → VERDE  — sem ocorrências significativas
#   21–50 → AMARELO — atenção, verificar contexto
#   51–80 → LARANJA — risco elevado, documentar antes de contratar
#   81–100 → VERMELHO — risco crítico, contraindicado sem apuração aprofundada

_PESO_CRITICO = 30
_PESO_ATENCAO = 10
_PESO_INFO = 2

_CAT_JUDICIAL = {"bnmp_cnj", "cndt_tst", "judicial", "trabalhista"}
_CAT_INTERNACIONAL = {"ofac", "uk_sanctions", "eu_sanctions", "un_sanctions",
                      "worldbank_debarment", "opensanctions_pro"}
_CAT_CGU = {"ceis", "cnep", "lista_suja", "cepim_representante"}

_FAIXAS = [
    (0,  20,  "VERDE",    "Sem ocorrências significativas"),
    (21, 50,  "AMARELO",  "Atenção — verificar contexto antes de contratar"),
    (51, 80,  "LARANJA",  "Risco elevado — documentar justificativa antes de contratar"),
    (81, 100, "VERMELHO", "Risco crítico — contraindicado sem apuração aprofundada"),
]


def calcular_score_risco(alertas: list[dict]) -> dict:
    """
    Calcula o score de risco proprietário a partir dos alertas coletados.
    Retorna um dicionário com score, faixa, cor e detalhamento por categoria.
    """
    score = 0
    por_categoria: dict[str, int] = {}

    for a in alertas:
        sev = (a.get("severidade") or "").lower()
        fonte = (a.get("fonte") or "").lower()
        cat = (a.get("categoria") or "").lower()

        if sev == "critico":
            pts = _PESO_CRITICO
        elif sev == "atencao":
            pts = _PESO_ATENCAO
        elif sev == "info":
            pts = _PESO_INFO
        else:
            continue

        score += pts
        grupo = cat if cat else fonte
        por_categoria[grupo] = por_categoria.get(grupo, 0) + pts

    # Bônus por categorias de alto impacto — só conta achado que pontuou.
    # Alertas "ok" (fonte consultada, nada encontrado) também trazem fonte e
    # categoria; incluí-los fazia o score subir a cada fonte limpa a mais.
    pontuaram = [a for a in alertas if (a.get("severidade") or "").lower() in ("critico", "atencao")]
    fontes_ativas = {(a.get("fonte") or "").lower() for a in pontuaram}
    cats_ativas = {(a.get("categoria") or "").lower() for a in pontuaram}

    if fontes_ativas & _CAT_JUDICIAL or cats_ativas & {"judicial", "trabalhista"}:
        score += 10
    if fontes_ativas & _CAT_INTERNACIONAL or cats_ativas & {"internacional"}:
        score += 10
    # Os conectores gravam a categoria como "sancao"; "sanções" nunca casava.
    if fontes_ativas & _CAT_CGU or cats_ativas & {"sancao", "sancoes", "sanções"}:
        score += 5

    score = min(score, 100)

    # Determina faixa
    faixa_cor = "VERDE"
    faixa_desc = "Sem ocorrências significativas"
    for lo, hi, cor, desc in _FAIXAS:
        if lo <= score <= hi:
            faixa_cor = cor
            faixa_desc = desc
            break

    n_criticos = sum(1 for a in alertas if (a.get("severidade") or "").lower() == "critico")
    n_atencao = sum(1 for a in alertas if (a.get("severidade") or "").lower() == "atencao")

    return {
        "score": score,
        "faixa": faixa_cor,
        "descricao": faixa_desc,
        "total_alertas": len(alertas),
        "criticos": n_criticos,
        "atencao": n_atencao,
        "por_categoria": por_categoria,
    }


def processar_cpf(
    cpf: str,
    cliente_id: str,
    nome: str = "",
    dry_run: bool = False,
    avulsa: bool = False,
) -> list[dict]:
    cpf_digits = _strip(cpf)
    if len(cpf_digits) != 11:
        logger.error("CPF inválido: %s", cpf)
        return []

    cpf_fmt = _fmt_cpf(cpf_digits)
    ciclo = _ciclo_atual()
    fontes = FONTES_PF_AVULSA if avulsa else FONTES_PF

    # Zera o cache de execução: ele existe para evitar consulta repetida
    # dentro de um mesmo CPF, nunca entre CPFs diferentes.
    limpar_memo()

    logger.info("Subradar PF — %s | %d fontes | dry_run=%s avulsa=%s",
                cpf_fmt, len(fontes), dry_run, avulsa)

    # As fontes são I/O puro (HTTP), então rodam em paralelo. Sequencialmente
    # o dossiê levava 640s dos 900s de teto da Lambda, com quatro fontes
    # respondendo por 557s: DOU (217s), BNMP (143s), certidões TRF (116s) e
    # protestos (81s). Bastava uma delas piorar para o processamento morrer no
    # meio. O limite de threads é conservador para não esbarrar em rate limit
    # de BigDataCorp e Infosimples.
    max_workers = int(os.environ.get("SUBRADAR_PF_WORKERS", "6"))

    def _rodar_fonte(fonte) -> tuple[str, list[dict], dict | None, float]:
        nome_fonte = getattr(fonte, "fonte", "?")
        t0 = time.perf_counter()
        alertas: list[dict] = []
        dado = None
        try:
            if hasattr(fonte, "consultar_cpf"):
                fn = fonte.consultar_cpf
            elif hasattr(fonte, "consultar_cnpj"):
                fn = fonte.consultar_cnpj
            else:
                fn = None
            if fn is not None:
                sig = inspect.signature(fn)
                alertas = fn(cpf_digits, nome=nome) if "nome" in sig.parameters else fn(cpf_digits)
                alertas = alertas or []
        except Exception as e:
            logger.error("  ✗ %s — erro: %s", nome_fonte, e)

        if hasattr(fonte, "resumo_pf"):
            try:
                dado = fonte.resumo_pf(cpf_digits, nome=nome)
            except Exception as e_d:
                logger.debug("  resumo_pf %s falhou: %s", nome_fonte, e_d)

        return nome_fonte, alertas, dado, time.perf_counter() - t0

    todos_alertas: list[dict] = []
    todos_dados: list[dict] = []
    resultados: dict[str, tuple] = {}

    t_inicio = time.perf_counter()
    with ThreadPoolExecutor(max_workers=max_workers) as pool:
        futuros = {pool.submit(_rodar_fonte, f): getattr(f, "fonte", "?") for f in fontes}
        for fut in as_completed(futuros):
            nome_fonte = futuros[fut]
            try:
                nome_fonte, alertas, dado, dt = fut.result()
            except Exception as e:
                logger.error("  ✗ %s — falhou no pool: %s", nome_fonte, e)
                continue
            resultados[nome_fonte] = (alertas, dado)
            if alertas:
                logger.info("  ✓ %s — %d alerta(s)", nome_fonte, len(alertas))
            logger.info("TIMING %s: %.1fs", nome_fonte, dt)

    logger.info("Fontes concluídas em %.1fs (%d threads)",
                time.perf_counter() - t_inicio, max_workers)

    # Segunda tentativa nas fontes que não conseguiram consultar.
    #
    # INLabs (DOU) e o CJF (certidões da Justiça Federal) falham de forma
    # intermitente — 502 e 615 que costumam passar minutos depois. Como a trava
    # de entrega retém o dossiê inteiro quando qualquer fonte fica pendente,
    # sem esta retentativa quase todo laudo dependeria de intervenção manual.
    # Só as fontes pendentes são refeitas, e apenas se houver folga de tempo.
    _RETENTAR = {"pendente", "erro"}
    tentativas_extra = int(os.environ.get("SUBRADAR_PF_RETRY", "1"))
    espera = int(os.environ.get("SUBRADAR_PF_RETRY_ESPERA", "20"))
    limite_s = int(os.environ.get("SUBRADAR_PF_RETRY_LIMITE", "600"))

    for tentativa in range(1, tentativas_extra + 1):
        pendentes = [
            f for f in fontes
            if str(((resultados.get(getattr(f, "fonte", "?"), ([], None))[1]) or {})
                   .get("status", "")).lower() in _RETENTAR
        ]
        if not pendentes:
            break
        decorrido = time.perf_counter() - t_inicio
        if decorrido > limite_s:
            logger.warning("Sem folga para retentar (%.0fs decorridos, limite %ds): %s",
                           decorrido, limite_s,
                           ", ".join(getattr(f, "fonte", "?") for f in pendentes))
            break

        logger.info("Retentativa %d/%d em %d fonte(s) pendente(s): %s",
                    tentativa, tentativas_extra, len(pendentes),
                    ", ".join(getattr(f, "fonte", "?") for f in pendentes))
        time.sleep(espera)
        # O cache guardaria a falha anterior e a retentativa seria inócua.
        limpar_memo()

        with ThreadPoolExecutor(max_workers=min(max_workers, len(pendentes))) as pool:
            futuros = {pool.submit(_rodar_fonte, f): getattr(f, "fonte", "?") for f in pendentes}
            for fut in as_completed(futuros):
                nome_fonte = futuros[fut]
                try:
                    nome_fonte, alertas, dado, dt = fut.result()
                except Exception as e:
                    logger.error("  ✗ %s — falhou na retentativa: %s", nome_fonte, e)
                    continue
                novo_status = str((dado or {}).get("status", "")).lower()
                if dado and novo_status not in _RETENTAR:
                    logger.info("  ✓ %s recuperada na retentativa (%.1fs)", nome_fonte, dt)
                    resultados[nome_fonte] = (alertas, dado)
                else:
                    logger.warning("  - %s segue indisponível após retentativa", nome_fonte)

    # Reagrupa depois das retentativas, para o laudo refletir o resultado final.
    todos_alertas.clear()
    todos_dados.clear()
    for fonte in fontes:
        nome_fonte = getattr(fonte, "fonte", "?")
        alertas, dado = resultados.get(nome_fonte, ([], None))
        if alertas:
            todos_alertas.extend(alertas)
        if dado:
            todos_dados.append(dado)

    vistas: set[str] = set()
    dados_unicos: list[dict] = []
    for d in todos_dados:
        f = d.get("fonte") or ""
        if f in vistas:
            logger.warning("Fonte duplicada ignorada na gravação: %s "
                           "(dois conectores declaram o mesmo nome)", f)
            continue
        vistas.add(f)
        dados_unicos.append(d)
    todos_dados = dados_unicos

    score = calcular_score_risco(todos_alertas)
    logger.info(
        "Score de risco: %d/100 [%s] — %d crítico(s), %d atenção",
        score["score"], score["faixa"], score["criticos"], score["atencao"],
    )

    if dry_run:
        logger.info("DRY RUN — %d alerta(s) encontrado(s), não gravado(s)", len(todos_alertas))
        print(f"\n  Score de risco: {score['score']}/100 [{score['faixa']}]")
        print(f"  {score['descricao']}\n")
        for a in todos_alertas:
            sev = a.get("severidade", "?").upper()
            print(f"  [{sev}] {a.get('titulo', '')} — {a.get('fonte', '')}")
        return todos_alertas

    # Grava alertas no Supabase
    if SUPABASE_URL and SUPABASE_KEY:
        if todos_alertas:
            for alerta in todos_alertas:
                alerta["cliente_id"] = cliente_id
                alerta["cpf"] = cpf_fmt
                alerta["ciclo"] = ciclo
            upsert("sub_pf_alertas", todos_alertas)
            logger.info("Gravados %d alertas para %s", len(todos_alertas), cpf_fmt)

        # Grava dados estruturados do laudo (Opção B)
        if todos_dados:
            rows_dados = []
            for d in todos_dados:
                rows_dados.append({
                    "cpf": cpf_fmt,
                    "ciclo": ciclo,
                    "cliente_id": cliente_id,
                    "consulta_id": cliente_id,  # reutiliza até termos campo dedicado
                    "fonte": d.get("fonte", ""),
                    "categoria": d.get("categoria", ""),
                    "status": d.get("status", ""),
                    "titulo_secao": d.get("titulo_secao", ""),
                    "resumo": d.get("resumo", ""),
                    "detalhes": d.get("detalhes"),
                })
            upsert("sub_pf_dados", rows_dados)
            logger.info("Gravados %d blocos de dados para %s", len(rows_dados), cpf_fmt)

        # Grava score na tabela de resultados PF
        import uuid as _uuid
        resultado_id = str(_uuid.uuid5(_uuid.NAMESPACE_DNS, f"{cpf_digits}-{ciclo}"))
        upsert("sub_pf_resultados", [{
            "id": resultado_id,
            "cpf": cpf_fmt,
            "cliente_id": cliente_id,
            "ciclo": ciclo,
            "score_risco": score["score"],
            "faixa_risco": score["faixa"],
            "total_alertas": score["total_alertas"],
            "score_detalhes": score,
        }])

        # Submete queries async BDC on-demand PF (resultado chega via webhook)
        try:
            n_bdc = submit_ondemand_pf(cpf_digits, resultado_id)
            if n_bdc:
                logger.info("%s: %d queries BDC on-demand PF submetidas (async)", cpf_fmt, n_bdc)
        except Exception as e:
            logger.warning("%s: falha ao submeter BDC on-demand PF (não bloqueante): %s", cpf_fmt, e)

    return todos_alertas


def main() -> None:
    parser = argparse.ArgumentParser(description="Subradar PF — compliance de pessoa física")
    parser.add_argument("--cpf", required=True, help="CPF a consultar (com ou sem máscara)")
    parser.add_argument("--nome", default="", help="Nome completo (melhora busca em listas internacionais)")
    parser.add_argument("--cliente-id", default="00000000-0000-0000-0000-000000000000",
                        help="UUID do cliente no Supabase")
    parser.add_argument("--dry-run", action="store_true", help="Não grava no Supabase")
    parser.add_argument("--avulsa", action="store_true",
                        help="Inclui BigDataCorp score + Escavador (custo por consulta)")
    args = parser.parse_args()

    alertas = processar_cpf(
        cpf=args.cpf,
        cliente_id=args.cliente_id,
        nome=args.nome,
        dry_run=args.dry_run,
        avulsa=args.avulsa,
    )

    criticos = sum(1 for a in alertas if a.get("severidade") == "critico")
    atencao = sum(1 for a in alertas if a.get("severidade") == "atencao")
    logger.info("Concluído — %d crítico(s), %d atenção, %d info",
                criticos, atencao, len(alertas) - criticos - atencao)


if __name__ == "__main__":
    main()
