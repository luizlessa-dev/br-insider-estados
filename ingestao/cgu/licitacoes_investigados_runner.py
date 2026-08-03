"""
Licitações — runner focado nos CNPJs investigados

Estratégia: para cada UG que já tem contratos com os CNPJs investigados,
consulta licitações do período investigado e salva no banco.
A API exige codigoOrgao obrigatório — por isso iteramos por UG/órgão.

Uso:
  cd /Users/luizlessa/brasilia-insider
  source .venv/bin/activate
  python -m ingestao.cgu.licitacoes_investigados_runner
"""
from __future__ import annotations

import calendar
import logging
import os
import sys
from datetime import date

from supabase import create_client

from .licitacoes_connector import LicitacoesConnector
from .licitacoes_persistence import LicitacoesWriter

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(name)s %(levelname)s %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("licitacoes.investigados")

CNPJS_INVESTIGADOS = [
    "03093776000191", "05794898000130", "07373055000196",
    "11417606000143", "12187936000152", "14534281000177",
    "14707364000110", "15513036000146", "15546569000124",
    "17405747000122", "19983065000122", "27772554000163",
    "33973468000167", "34507823000100", "36532189000100",
    "41731338000109", "47149673000171", "47260451000121",
]

ANO_INICIO = 2022
MES_INICIO = 1


def _janelas_mensais(ano_ini: int, mes_ini: int) -> list[tuple[date, date]]:
    hoje = date.today()
    janelas = []
    ano, mes = ano_ini, mes_ini
    while (ano, mes) <= (hoje.year, hoje.month):
        ultimo = calendar.monthrange(ano, mes)[1]
        ini = date(ano, mes, 1)
        fim = date(ano, mes, min(ultimo, hoje.day if (ano, mes) == (hoje.year, hoje.month) else ultimo))
        janelas.append((ini, fim))
        mes += 1
        if mes > 12:
            mes = 1
            ano += 1
    return janelas


def _get_ugs(supabase_url: str, service_key: str) -> list[dict]:
    """Retorna UGs distintas com contratos dos CNPJs investigados."""
    client = create_client(supabase_url, service_key)
    cnpjs_fmt = ",".join(f"'{c}'" for c in CNPJS_INVESTIGADOS)
    resp = client.rpc("execute_sql", {
        "query": f"""
            SELECT DISTINCT ug_codigo, orgao_codigo, orgao_descricao
            FROM contratos_federais
            WHERE fornecedor_cnpj IN ({cnpjs_fmt})
            ORDER BY orgao_codigo, ug_codigo
        """
    }).execute()
    return resp.data or []


def main() -> None:
    api_key  = os.environ.get("PORTAL_TRANSPARENCIA_API_KEY")
    supa_url = os.environ.get("SUPABASE_URL")
    supa_key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

    if not api_key or not supa_url or not supa_key:
        logger.error("Variáveis de ambiente ausentes.")
        sys.exit(1)

    ugs = _get_ugs(supa_url, supa_key)
    logger.info("%d UGs identificadas nos contratos investigados", len(ugs))

    connector = LicitacoesConnector(api_key)
    writer    = LicitacoesWriter.from_env()
    if not writer:
        logger.error("Credenciais Supabase ausentes.")
        sys.exit(1)

    janelas = _janelas_mensais(ANO_INICIO, MES_INICIO)
    logger.info("%d janelas mensais × %d órgãos distintos", len(janelas), len({u["orgao_codigo"] for u in ugs}))

    total = 0
    erros = 0
    orgaos_distintos = list({u["orgao_codigo"]: u for u in ugs}.values())

    for ug in orgaos_distintos:
        orgao = ug["orgao_codigo"]
        logger.info("Órgão %s — %s", orgao, ug["orgao_descricao"])
        orgao_total = 0
        for ini, fim in janelas:
            try:
                lics = connector.iter_por_periodo(ini, fim, codigo_orgao=orgao)
                n = writer.upsert_licitacoes(lics)
                orgao_total += n
                total += n
            except Exception as exc:
                logger.warning("  %s %s→%s ERRO: %s", orgao, ini, fim, exc)
                erros += 1
        if orgao_total:
            logger.info("  → %d licitações", orgao_total)

    logger.info("Concluído: %d licitações totais, %d erros", total, erros)


if __name__ == "__main__":
    main()
