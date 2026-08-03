"""
Seed CNPJ — The Brasilia Insider
Enriquece cnpj_empresas com dados cadastrais da Receita Federal (dump mensal).

Uso:
  python -m ingestao.rfb.seed_cnpj              # empresas (padrão)
  python -m ingestao.rfb.seed_cnpj --socios     # + QSA (mais pesado)
  python -m ingestao.rfb.seed_cnpj --dry-run    # mostra contagem, não grava
"""
from __future__ import annotations

import argparse
import logging
import os
import re
import sys
import tempfile
from pathlib import Path

from dotenv import load_dotenv

load_dotenv(Path(__file__).parents[2] / ".env")

sys.path.insert(0, str(Path(__file__).parents[2]))
from ingestao.rfb.cnpj_connector import CNPJConnector, _cnpj_basico

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s — %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("seed_cnpj")

BATCH_UPSERT = 500


def get_target_cnpjs(sb) -> set[str]:
    """Coleta CNPJs-alvo do banco: emendas_favorecidos (PJ) + cnpj_socios."""
    cnpjs: set[str] = set()

    # 1. emendas_favorecidos — empresas privadas e públicas com CNPJ válido
    offset, batch = 0, 1000
    while True:
        r = (
            sb.table("emendas_favorecidos")
            .select("codigo_favorecido")
            .neq("tipo_favorecido", "Pessoa Física")
            .range(offset, offset + batch - 1)
            .execute()
        )
        if not r.data:
            break
        for x in r.data:
            c = re.sub(r"\D", "", x.get("codigo_favorecido") or "")
            if len(c) == 14:
                cnpjs.add(c)
        offset += batch
        if len(r.data) < batch:
            break

    # 2. cnpj_socios já existentes (garante cobertura do QSA)
    r2 = sb.table("cnpj_socios").select("cnpj_basico").execute()
    for x in r2.data:
        b = x.get("cnpj_basico", "")
        if b and len(b) == 8:
            cnpjs.add(b.ljust(14, "0"))  # placeholder para _cnpj_basico funcionar

    logger.info("Total CNPJs-alvo coletados: %d", len(cnpjs))
    return cnpjs


def upsert_empresas(sb, rows: list[dict]) -> int:
    """Upsert em lotes em cnpj_empresas. Retorna total inserido/atualizado."""
    total = 0
    for i in range(0, len(rows), BATCH_UPSERT):
        batch = rows[i : i + BATCH_UPSERT]
        payload = [
            {
                "cnpj_basico": r["cnpj_basico"],
                "razao_social": r.get("razao_social"),
                "natureza_juridica": r.get("natureza_juridica"),
                "capital_social": r.get("capital_social"),
                "porte_empresa": r.get("porte_empresa"),
            }
            for r in batch
        ]
        sb.table("cnpj_empresas").upsert(payload, on_conflict="cnpj_basico").execute()
        total += len(payload)
    return total


def upsert_socios(sb, rows: list[dict]) -> int:
    """Upsert em lotes em cnpj_socios."""
    total = 0
    for i in range(0, len(rows), BATCH_UPSERT):
        batch = rows[i : i + BATCH_UPSERT]
        payload = [
            {
                "cnpj_basico": r["cnpj_basico"],
                "identificador": r.get("identificador_socio"),
                "nome_socio": r.get("nome_socio"),
                "nome_norm": (r.get("nome_socio") or "").upper().strip(),
                "cpf_cnpj_socio": re.sub(r"\D", "", r.get("cnpj_cpf_socio") or ""),
                "qualificacao": r.get("qualificacao_socio"),
                "data_entrada": r.get("data_entrada") or None,
                "faixa_etaria": r.get("faixa_etaria"),
            }
            for r in batch
        ]
        # ignora linhas sem cnpj_basico
        payload = [p for p in payload if p["cnpj_basico"]]
        if payload:
            sb.table("cnpj_socios").upsert(
                payload, on_conflict="cnpj_basico,cpf_cnpj_socio"
            ).execute()
            total += len(payload)
    return total


def main() -> None:
    parser = argparse.ArgumentParser(description="Seed CNPJ Receita Federal")
    parser.add_argument("--socios", action="store_true", help="Também ingerir QSA (sócios)")
    parser.add_argument("--dry-run", action="store_true", help="Apenas mostra contagem, não grava")
    parser.add_argument("--workdir", default=None, help="Pasta para ZIPs temporários")
    args = parser.parse_args()

    from supabase import create_client

    sb = create_client(
        os.environ["SUPABASE_URL"],
        os.environ["SUPABASE_SERVICE_ROLE_KEY"],
    )

    target_cnpjs = get_target_cnpjs(sb)

    if args.dry_run:
        basicos = {_cnpj_basico(c) for c in target_cnpjs}
        logger.info("[dry-run] %d CNPJ_BASICO únicos a buscar. Encerrando.", len(basicos))
        return

    workdir = args.workdir or tempfile.gettempdir()
    connector = CNPJConnector(workdir=workdir)

    # ── Empresas ────────────────────────────────────────────────────────────────
    logger.info("=== Iniciando seed de cnpj_empresas ===")
    buffer: list[dict] = []
    total_emp = 0

    for row in connector.iter_empresas(target_cnpjs):
        buffer.append(row)
        if len(buffer) >= BATCH_UPSERT * 4:
            total_emp += upsert_empresas(sb, buffer)
            logger.info("  Empresas gravadas até agora: %d", total_emp)
            buffer.clear()

    if buffer:
        total_emp += upsert_empresas(sb, buffer)

    logger.info("=== cnpj_empresas concluído: %d registros ===", total_emp)

    # ── Sócios (opcional) ────────────────────────────────────────────────────────
    if args.socios:
        logger.info("=== Iniciando seed de cnpj_socios ===")
        buffer_s: list[dict] = []
        total_soc = 0

        for row in connector.iter_socios(target_cnpjs):
            buffer_s.append(row)
            if len(buffer_s) >= BATCH_UPSERT * 4:
                total_soc += upsert_socios(sb, buffer_s)
                logger.info("  Sócios gravados até agora: %d", total_soc)
                buffer_s.clear()

        if buffer_s:
            total_soc += upsert_socios(sb, buffer_s)

        logger.info("=== cnpj_socios concluído: %d registros ===", total_soc)

    logger.info("Seed finalizado.")


if __name__ == "__main__":
    main()
