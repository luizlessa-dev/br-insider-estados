"""
Contratos Federais — Favorecidos de emendas × contratos federais
The BR Insider

Ingere contratos via endpoint /contratos/cpf-cnpj para CNPJs que:
  a) receberam emendas parlamentares (modo: --modo emendas)
  b) são explicitamente listados (modo: --cnpjs)

O endpoint por órgão da API não retorna contratos da Defesa corretamente —
a única rota confiável é a busca por CNPJ do fornecedor.

Uso:
  cd /Users/luizlessa/brasilia-insider
  source .venv/bin/activate

  # Ingere contratos de todos os CNPJs que receberam emendas de Pazuello:
  python -m ingestao.cgu.contratos_defesa_runner --autor "pazuello"

  # CNPJs específicos:
  python -m ingestao.cgu.contratos_defesa_runner --cnpjs 43619143000199,15656953000180

  # Top-N favorecidos de emendas por valor (exige SUPABASE_*):
  python -m ingestao.cgu.contratos_defesa_runner --top 50
"""
from __future__ import annotations

import argparse
import logging
import os
import sys

import requests

from .contratos_connector import ContratosConnector
from .contratos_persistence import ContratosWriter

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(name)s %(levelname)s %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("contratos.cnpj")


def _cnpjs_do_autor(supa_url: str, supa_key: str, autor: str) -> list[str]:
    """Retorna CNPJs únicos que receberam emendas do autor informado."""
    session = requests.Session()
    session.headers.update({
        "apikey": supa_key,
        "Authorization": f"Bearer {supa_key}",
    })
    resp = session.get(
        f"{supa_url}/rest/v1/emendas_favorecidos",
        params={
            "nome_autor": f"ilike.*{autor}*",
            "select": "codigo_favorecido",
            "codigo_favorecido": "not.is.null",
            "limit": 1000,
        },
        timeout=30,
    )
    resp.raise_for_status()
    cnpjs = list({r["codigo_favorecido"] for r in resp.json()
                  if r.get("codigo_favorecido") and len(r["codigo_favorecido"]) == 14})
    logger.info("CNPJs para '%s': %d encontrados", autor, len(cnpjs))
    return cnpjs


def _cnpjs_top(supa_url: str, supa_key: str, n: int) -> list[str]:
    """Top-N CNPJs por valor total recebido em emendas."""
    session = requests.Session()
    session.headers.update({
        "apikey": supa_key,
        "Authorization": f"Bearer {supa_key}",
    })
    resp = session.get(
        f"{supa_url}/rest/v1/rpc/execute_sql",
        json={"query": f"""
            SELECT codigo_favorecido
            FROM emendas_favorecidos
            WHERE length(codigo_favorecido) = 14
            GROUP BY codigo_favorecido
            ORDER BY SUM(valor_recebido) DESC
            LIMIT {n}
        """},
        timeout=30,
    )
    resp.raise_for_status()
    return [r["codigo_favorecido"] for r in resp.json()]


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Ingere contratos federais por CNPJ do fornecedor"
    )
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--autor", help="Nome parcial do autor da emenda (ex: pazuello)")
    group.add_argument("--cnpjs", help="CNPJs separados por vírgula (só dígitos)")
    group.add_argument("--top", type=int, help="Top-N CNPJs por valor de emenda")
    args = parser.parse_args()

    api_key  = os.environ.get("PORTAL_TRANSPARENCIA_API_KEY")
    supa_url = (os.environ.get("SUPABASE_URL") or "").rstrip("/")
    supa_key = (
        os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
        or os.environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY")
        or ""
    )

    if not api_key:
        logger.error("PORTAL_TRANSPARENCIA_API_KEY não definida.")
        sys.exit(1)

    # Resolver lista de CNPJs
    if args.cnpjs:
        cnpjs = [c.strip() for c in args.cnpjs.split(",") if c.strip()]
    elif args.autor:
        if not supa_url or not supa_key:
            logger.error("SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY necessários para --autor.")
            sys.exit(1)
        cnpjs = _cnpjs_do_autor(supa_url, supa_key, args.autor)
    else:
        if not supa_url or not supa_key:
            logger.error("SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY necessários para --top.")
            sys.exit(1)
        cnpjs = _cnpjs_top(supa_url, supa_key, args.top)

    if not cnpjs:
        logger.warning("Nenhum CNPJ para processar.")
        sys.exit(0)

    writer    = ContratosWriter.from_env()
    connector = ContratosConnector(api_key)

    logger.info("Iniciando ingestão para %d CNPJs", len(cnpjs))
    total = 0
    erros = 0

    for cnpj in cnpjs:
        try:
            contratos = list(connector.iter_por_cnpj(cnpj))
            if contratos:
                n = writer.upsert_contratos(iter(contratos))
                logger.info("  %s → %d contratos (R$ %.0f total)", cnpj, n,
                            sum(c.valor_total or 0 for c in contratos))
                total += n
        except Exception as exc:
            logger.warning("  %s ERRO: %s", cnpj, exc)
            erros += 1

    logger.info("Concluído: %d contratos ingeridos, %d CNPJs com erro", total, erros)


if __name__ == "__main__":
    main()
