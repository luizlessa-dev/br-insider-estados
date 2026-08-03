"""
Seed sócios das operadoras de apostas licenciadas pela SPA/MF.
Fonte: BrasilAPI /cnpj/v1/{cnpj} para as 81 empresas em bets_licenciadas.

Uso:
  python -m ingestao.bets.seed_bets_socios
  python -m ingestao.bets.seed_bets_socios --dry-run
"""
from __future__ import annotations

import argparse
import logging
import os
import time
from pathlib import Path

import requests
from dotenv import load_dotenv
from supabase import create_client

load_dotenv(Path(__file__).parents[2] / ".env")

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s — %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("bets_socios")

BRASILAPI = "https://brasilapi.com.br/api/cnpj/v1/{cnpj}"
DELAY = 0.5  # segundos entre chamadas


def fetch_cnpj(cnpj: str, session: requests.Session) -> dict | None:
    try:
        r = session.get(BRASILAPI.format(cnpj=cnpj), timeout=15)
        if r.status_code == 429:
            logger.warning("Rate limit — aguardando 10s")
            time.sleep(10)
            r = session.get(BRASILAPI.format(cnpj=cnpj), timeout=15)
        r.raise_for_status()
        return r.json()
    except Exception as e:
        logger.error("Erro CNPJ %s: %s", cnpj, e)
        return None


def main(dry_run: bool = False) -> None:
    sb = create_client(os.environ["SUPABASE_URL"], os.environ["SUPABASE_SERVICE_ROLE_KEY"])
    session = requests.Session()
    session.headers["User-Agent"] = "BR-Insider/1.0 (luiz@thebrinsider.com)"

    # Busca CNPJs das bets licenciadas
    r = sb.table("bets_licenciadas").select("cnpj, nome, marcas").execute()
    bets = r.data
    logger.info("Bets licenciadas: %d", len(bets))

    empresas_rows = []
    socios_rows = []

    for bet in bets:
        cnpj = bet["cnpj"]
        logger.info("Consultando %s (%s)", bet["nome"], cnpj)
        data = fetch_cnpj(cnpj, session)
        time.sleep(DELAY)

        if not data:
            continue

        # Dados cadastrais da empresa
        empresas_rows.append({
            "cnpj_basico": cnpj[:8],
            "razao_social": data.get("razao_social"),
            "capital_social": data.get("capital_social"),
            "porte_empresa": data.get("porte"),
        })

        # QSA — quadro societário
        for s in data.get("qsa") or []:
            cpf_cnpj = s.get("cnpj_cpf_do_socio", "")
            nome = s.get("nome_socio", "")
            socios_rows.append({
                "cnpj_basico": cnpj[:8],
                "identificador": s.get("identificador_de_socio", 1),
                "nome_socio": nome,
                "nome_norm": nome.upper().strip() if nome else None,
                "cpf_cnpj_socio": cpf_cnpj,
                "qualificacao": s.get("qualificacao_socio"),
                "data_entrada": s.get("data_entrada_sociedade"),
                "faixa_etaria": s.get("faixa_etaria"),
            })

    logger.info("Empresas: %d | Sócios: %d", len(empresas_rows), len(socios_rows))

    if dry_run:
        logger.info("DRY RUN — nada gravado")
        for s in socios_rows[:10]:
            logger.info("  %s | %s | %s", s["cnpj_basico"], s["nome_socio"], s["qualificacao"])
        return

    # Upsert empresas
    if empresas_rows:
        sb.table("cnpj_empresas").upsert(empresas_rows, on_conflict="cnpj_basico").execute()
        logger.info("cnpj_empresas upserted: %d", len(empresas_rows))

    # Upsert sócios
    if socios_rows:
        sb.table("cnpj_socios").upsert(
            socios_rows, on_conflict="cnpj_basico,nome_socio,cpf_cnpj_socio"
        ).execute()
        logger.info("cnpj_socios upserted: %d", len(socios_rows))

    logger.info("Concluído.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    main(dry_run=args.dry_run)
