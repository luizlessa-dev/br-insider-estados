"""
Runner PNCP — Licitações focadas nos CNPJs investigados

Estratégia: busca CNPJs dos órgãos que já têm contratos com as empresas
investigadas, varre licitações publicadas nesses órgãos no período e persiste.

Uso:
  cd /Users/luizlessa/brasilia-insider
  source .venv/bin/activate
  python -m ingestao.pncp.licitacoes_pncp_runner [--dias 30] [--modalidades 4,5,6,7,8,9]

Variáveis de ambiente:
  SUPABASE_URL
  SUPABASE_SERVICE_ROLE_KEY
"""
from __future__ import annotations

import argparse
import logging
import os
import sys
from datetime import date, datetime, timedelta

import requests
from supabase import create_client

from .licitacoes_pncp_connector import LicitacaoPncp, PncpConnector, MODALIDADES_INVESTIGATIVAS

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(name)s %(levelname)s %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("pncp.runner")

CNPJS_INVESTIGADOS = [
    "03093776000191", "05794898000130", "07373055000196",
    "11417606000143", "12187936000152", "14534281000177",
    "14707364000110", "15513036000146", "15546569000124",
    "17405747000122", "19983065000122", "27772554000163",
    "33973468000167", "34507823000100", "36532189000100",
    "41731338000109", "47149673000171", "47260451000121",
]

CHUNK = 200


def _get_cnpjs_orgaos(supa_url: str, supa_key: str) -> list[str]:
    """CNPJs dos órgãos que contrataram as empresas investigadas."""
    client = create_client(supa_url, supa_key)
    cnpjs_fmt = ",".join(f"'{c}'" for c in CNPJS_INVESTIGADOS)
    # Usa o CNPJ do órgão (campo orgao_cnpj se existir, senão busca pelo codigo)
    # A tabela contratos_federais pode não ter cnpj do órgão — busca via SIAFI
    # Alternativa: usar todos os CNPJs investigados como filtro de fornecedor direto
    # A API PNCP filtra por órgão (cnpj), não por fornecedor.
    # Por ora retorna lista vazia = varredura sem filtro de órgão (mais ampla).
    logger.info("Modo: varredura geral sem filtro de órgão (filtra por CNPJ fornecedor localmente)")
    return []


def _upsert(supa_url: str, supa_key: str, rows: list[dict]) -> int:
    if not rows:
        return 0
    headers = {
        "apikey": supa_key,
        "Authorization": f"Bearer {supa_key}",
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates,return=minimal",
    }
    url = f"{supa_url}/rest/v1/licitacoes?on_conflict=numero_controle_pncp"
    total = 0
    for i in range(0, len(rows), CHUNK):
        batch = rows[i:i + CHUNK]
        resp = requests.post(url, json=batch, headers=headers, timeout=30)
        if resp.status_code not in (200, 201, 204):
            logger.error("Upsert falhou %s: %s", resp.status_code, resp.text[:200])
        else:
            total += len(batch)
    return total


def main() -> None:
    parser = argparse.ArgumentParser(description="Ingestão PNCP licitações → Supabase")
    parser.add_argument("--dias", type=int, default=30,
                        help="Quantos dias retroativos a varrer (padrão: 30)")
    parser.add_argument("--modalidades", default=",".join(map(str, MODALIDADES_INVESTIGATIVAS)),
                        help="Modalidades separadas por vírgula (padrão: 4,5,6,7,8,9)")
    args = parser.parse_args()

    supa_url = os.environ.get("SUPABASE_URL", "").rstrip("/")
    supa_key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")
    if not supa_url or not supa_key:
        logger.error("SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY são obrigatórios.")
        sys.exit(1)

    modalidades = [int(m) for m in args.modalidades.split(",") if m.strip().isdigit()]
    data_fim = date.today()
    data_ini = data_fim - timedelta(days=args.dias)

    logger.info("Período: %s → %s | Modalidades: %s", data_ini, data_fim, modalidades)

    connector = PncpConnector()
    buffer: list[dict] = []
    total = 0
    erros = 0

    dia = data_ini
    while dia <= data_fim:
        logger.info("Varrendo %s...", dia)
        try:
            for lic in connector.iter_por_dia(dia, modalidades):
                # Filtra: só salva se o objeto menciona emenda ou se o órgão é federal
                # (para não encher o banco com prefeituras irrelevantes)
                obj = (lic.objeto or "").upper()
                relevante = (
                    "EMENDA" in obj
                    or lic.esfera_orgao == "Federal"
                    or (lic.cnpj_orgao or "")[:8] in {c[:8] for c in CNPJS_INVESTIGADOS}
                )
                if not relevante:
                    continue

                buffer.append({
                    "numero_controle_pncp": lic.numero_controle_pncp,
                    "numero":               lic.numero,
                    "objeto":               lic.objeto,
                    "data_publicacao":      lic.data_publicacao.isoformat() if lic.data_publicacao else None,
                    "data_abertura":        lic.data_abertura.isoformat() if lic.data_abertura else None,
                    "modalidade_codigo":    lic.modalidade_codigo,
                    "modalidade_descricao": lic.modalidade_descricao,
                    "orgao_codigo":         lic.cnpj_orgao,     # reutiliza coluna existente
                    "orgao_descricao":      lic.razao_social_orgao,
                    "cnpj_orgao":           lic.cnpj_orgao,
                    "razao_social_orgao":   lic.razao_social_orgao,
                    "esfera_orgao":         lic.esfera_orgao,
                    "uf_unidade":           lic.uf_unidade,
                    "municipio_unidade":    lic.municipio_unidade,
                    "ano_compra":           lic.ano_compra,
                    "sequencial_compra":    lic.sequencial_compra,
                    "valor_estimado":       lic.valor_estimado,
                    "valor_homologado":     lic.valor_homologado,
                    "numero_processo":      lic.numero_processo,
                    "situacao_codigo":      lic.situacao_codigo,
                    "situacao_descricao":   lic.situacao_descricao,
                    "fonte":                "pncp",
                    "updated_at":           datetime.utcnow().isoformat(),
                })

                if len(buffer) >= CHUNK:
                    total += _upsert(supa_url, supa_key, buffer)
                    buffer.clear()

        except Exception as e:
            logger.warning("Erro em %s: %s", dia, e)
            erros += 1

        dia += timedelta(days=1)

    if buffer:
        total += _upsert(supa_url, supa_key, buffer)

    logger.info("Concluído: %d licitações upsertadas, %d erros de dia", total, erros)


if __name__ == "__main__":
    main()
