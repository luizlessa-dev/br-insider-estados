"""
Runner CNES — grava estabelecimentos de saúde no Supabase.

Uso:
  python -m ingestao.cnes_runner                  # todas as UFs
  python -m ingestao.cnes_runner --uf MG          # só Minas Gerais
  python -m ingestao.cnes_runner --uf MG SP RJ    # múltiplas UFs
  python -m ingestao.cnes_runner --dry-run        # sem gravar

Env vars necessárias:
  SUPABASE_URL
  SUPABASE_SERVICE_ROLE_KEY (ou INTERNAL_SUPABASE_SERVICE_ROLE_KEY)
"""
from __future__ import annotations

import argparse
import json
import logging
import os
import sys
import time
from dataclasses import asdict
from datetime import date, datetime
from typing import Any

import requests

from .cnes_connector import Estabelecimento, UFS, fetch_todos

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s — %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("cnes_runner")

CHUNK = 200
TABLE = "cnes_estabelecimentos"


# ── Supabase helpers ──────────────────────────────────────────────────────

def _supabase_session() -> tuple[str, requests.Session]:
    url = os.environ.get("SUPABASE_URL", "").rstrip("/")
    key = (
        os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
        or os.environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY")
        or ""
    )
    if not url or not key:
        raise SystemExit("Faltando SUPABASE_URL e/ou SUPABASE_SERVICE_ROLE_KEY")

    sess = requests.Session()
    sess.headers.update({
        "apikey": key,
        "Authorization": f"Bearer {key}",
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates,return=minimal",
    })
    return url, sess


def _jsonable(value: Any) -> Any:
    if isinstance(value, (date, datetime)):
        return value.isoformat()
    if isinstance(value, dict):
        return {k: _jsonable(v) for k, v in value.items()}
    if isinstance(value, (list, tuple)):
        return [_jsonable(v) for v in value]
    return value


def _upsert_batch(url: str, sess: requests.Session, rows: list[dict]) -> None:
    resp = sess.post(
        f"{url}/rest/v1/{TABLE}",
        data=json.dumps([_jsonable(r) for r in rows]),
        timeout=30,
    )
    if not resp.ok:
        logger.error("Erro upsert: %s — %s", resp.status_code, resp.text[:300])
        resp.raise_for_status()


def _estab_to_row(e: Estabelecimento) -> dict:
    return {
        "codigo_cnes": e.codigo_cnes,
        "numero_cnpj": e.numero_cnpj,
        "nome_razao_social": e.nome_razao_social,
        "nome_fantasia": e.nome_fantasia,
        "codigo_tipo_unidade": e.codigo_tipo_unidade,
        "tipo_gestao": e.tipo_gestao,
        "descricao_esfera_administrativa": e.descricao_esfera_administrativa,
        "descricao_natureza_juridica": e.descricao_natureza_juridica,
        "codigo_uf": e.codigo_uf,
        "uf": e.uf,
        "codigo_municipio": e.codigo_municipio,
        "codigo_cep": e.codigo_cep,
        "endereco": e.endereco,
        "numero": e.numero,
        "bairro": e.bairro,
        "latitude": float(e.latitude) if e.latitude is not None else None,
        "longitude": float(e.longitude) if e.longitude is not None else None,
        "telefone": e.telefone,
        "email": e.email,
        "atende_sus": e.atende_sus,
        "possui_centro_cirurgico": e.possui_centro_cirurgico,
        "possui_atendimento_hospitalar": e.possui_atendimento_hospitalar,
        "possui_atendimento_ambulatorial": e.possui_atendimento_ambulatorial,
        "data_atualizacao": e.data_atualizacao,
        "ingerido_em": datetime.utcnow().isoformat() + "Z",
    }


# ── Main ──────────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(description="Ingere CNES no Supabase")
    parser.add_argument("--uf", nargs="+", metavar="UF",
                        help="Siglas das UFs a ingerir (ex: MG SP). Padrão: todas.")
    parser.add_argument("--dry-run", action="store_true",
                        help="Busca os dados mas não grava no banco.")
    args = parser.parse_args()

    ufs_filtradas = UFS
    if args.uf:
        siglas = {u.upper() for u in args.uf}
        ufs_filtradas = [(cod, sig) for cod, sig in UFS if sig in siglas]
        if not ufs_filtradas:
            raise SystemExit(f"UFs não reconhecidas: {args.uf}")

    if args.dry_run:
        logger.info("Modo dry-run — nenhum dado será gravado.")
        supabase_url, supabase_sess = None, None
    else:
        supabase_url, supabase_sess = _supabase_session()

    total_gravados = 0
    buffer: list[dict] = []
    t0 = time.monotonic()

    for uf_sigla, estab in fetch_todos(ufs=ufs_filtradas):
        buffer.append(_estab_to_row(estab))

        if len(buffer) >= CHUNK:
            # Deduplicar por codigo_cnes antes de upsert (API pode retornar duplicatas)
            seen: dict[int, dict] = {}
            for row in buffer:
                seen[row["codigo_cnes"]] = row
            deduped = list(seen.values())
            if not args.dry_run:
                _upsert_batch(supabase_url, supabase_sess, deduped)
            total_gravados += len(deduped)
            logger.info("✓ %d registros gravados (total: %d)", len(deduped), total_gravados)
            buffer.clear()

    # flush final
    if buffer:
        seen = {}
        for row in buffer:
            seen[row["codigo_cnes"]] = row
        deduped = list(seen.values())
        if not args.dry_run:
            _upsert_batch(supabase_url, supabase_sess, deduped)
        total_gravados += len(deduped)

    elapsed = time.monotonic() - t0
    logger.info(
        "CNES concluído: %d estabelecimentos em %.1fs",
        total_gravados, elapsed,
    )

    if args.dry_run:
        logger.info("(dry-run: nada foi gravado)")


if __name__ == "__main__":
    main()
