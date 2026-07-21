"""
Subradar PF — pipeline de compliance para Pessoa Física (CPF)

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
import re
import sys

from .base import upsert, _ciclo_atual, SUPABASE_URL, SUPABASE_KEY

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
from .dou_pf import DOUPFConnector
from .cepim_pf import CEPIMRepresentantePFConnector
from .opensanctions_pro import OpenSanctionsProPFConnector

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
    CPFSituacaoConnector(),        # Situação cadastral do CPF na RFB — verificação base
    QSAReversoConnector(),         # Empresas onde o CPF é sócio + situação delas
    ConselhosProfissionaisConnector(), # Registro em conselhos de classe (CREA, CRM, OAB…)
    CFCContadoresConnector(),      # CFC — contador ativo/inativo (API pública gratuita)
    InfosimplesConselhosPFConnector(), # CRO/CRF/CFM/CFMV/CFP/CFBM/COREN via Infosimples
    CEPIMRepresentantePFConnector(),   # CEPIM — sócio de entidade impedida de receber convênios
    DOUPFConnector(),                  # DOU — menções do nome nos últimos 30 dias (DO1/DO2/DO3)
    CEISConnector(),               # CEIS — sanções PF
    CNEPConnector(),               # CNEP — punições PF
    ListaSujaConnector(),          # MTE lista suja — trabalho escravo
    DividaAtivaConnector(),        # PGFN dívida ativa PF
    OFACConnector(),               # OFAC SDN — busca por nome
    UKSanctionsConnector(),        # UK Sanctions — busca por nome
    EUSanctionsConnector(),        # EU Sanctions — busca por nome
    UNSanctionsConnector(),        # ONU — busca por nome
    WorldBankDebarmentConnector(), # World Bank — busca por nome
    OpenSanctionsProPFConnector(), # OpenSanctions Pro — PEPs, INTERPOL, 400+ listas (R$0,60/query)
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

FONTES_PF_AVULSA = FONTES_PF + [f for f in [_BDC_SCORE_PF, _ESCAVADOR_PF] if f]


def _strip(cpf: str) -> str:
    return re.sub(r"\D", "", str(cpf or ""))


def _fmt_cpf(cpf: str) -> str:
    c = _strip(cpf)
    return f"{c[:3]}.{c[3:6]}.{c[6:9]}-{c[9:11]}" if len(c) == 11 else cpf


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

    logger.info("Subradar PF — %s | %d fontes | dry_run=%s avulsa=%s",
                cpf_fmt, len(fontes), dry_run, avulsa)

    todos_alertas: list[dict] = []

    for fonte in fontes:
        try:
            # Conectores de listas internacionais aceitam razao_social como nome
            if hasattr(fonte, "consultar_cnpj"):
                alertas = fonte.consultar_cnpj(cpf_digits, razao_social=nome)
            else:
                alertas = []

            if alertas:
                logger.info("  ✓ %s — %d alerta(s)", fonte.fonte, len(alertas))
                todos_alertas.extend(alertas)
            else:
                logger.debug("  - %s — sem alertas", fonte.fonte)

        except Exception as e:
            logger.error("  ✗ %s — erro: %s", getattr(fonte, "fonte", "?"), e)

    if dry_run:
        logger.info("DRY RUN — %d alerta(s) encontrado(s), não gravado(s)", len(todos_alertas))
        for a in todos_alertas:
            sev = a.get("severidade", "?").upper()
            print(f"  [{sev}] {a.get('titulo', '')} — {a.get('fonte', '')}")
        return todos_alertas

    # Grava alertas no Supabase
    if todos_alertas and SUPABASE_URL and SUPABASE_KEY:
        for alerta in todos_alertas:
            alerta["cliente_id"] = cliente_id
        upsert("sub_alertas", todos_alertas)
        logger.info("Gravados %d alertas para %s", len(todos_alertas), cpf_fmt)

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
    sys.exit(1 if criticos else 0)


if __name__ == "__main__":
    main()
