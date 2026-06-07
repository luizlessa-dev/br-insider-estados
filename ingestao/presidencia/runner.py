"""
Runner de ingestão — Presidência da República
The BR Insider

Subcomandos:
  ex-presidentes   Ingerir custos de ex-presidentes (XLSX anuais)
  pessoal          Ingerir perfil e diversidade do pessoal (CSVs)

Uso:
  python -m ingestao.presidencia.runner ex-presidentes --pasta data/presidencia/ex_presidentes/
  python -m ingestao.presidencia.runner pessoal        --pasta data/presidencia/pessoal/
  python -m ingestao.presidencia.runner ex-presidentes --pasta ... --dry-run
"""
from __future__ import annotations

import argparse
import logging
import os
import sys
from datetime import datetime
from pathlib import Path
from typing import Any

import requests

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s — %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("presidencia.runner")

CHUNK = 200


def _load_env() -> None:
    env_path = Path(__file__).resolve().parents[3] / ".env"
    if not env_path.exists():
        return
    with open(env_path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, _, v = line.partition("=")
            k, v = k.strip(), v.strip().strip('"').strip("'")
            if k not in os.environ:
                os.environ[k] = v


_load_env()


def _supabase_headers() -> dict:
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")
    return {
        "apikey": key,
        "Authorization": f"Bearer {key}",
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates,return=minimal",
    }


def _upsert(table: str, rows: list[dict], dry_run: bool) -> int:
    if dry_run:
        logger.info(f"[dry-run] {table}: {len(rows)} linhas seriam gravadas")
        return len(rows)

    url = os.environ["SUPABASE_URL"]
    headers = _supabase_headers()
    total = 0
    for i in range(0, len(rows), CHUNK):
        chunk = rows[i : i + CHUNK]
        resp = requests.post(
            f"{url}/rest/v1/{table}",
            json=chunk,
            headers=headers,
            timeout=30,
        )
        if resp.status_code not in (200, 201):
            logger.error("Erro upsert %s: %s %s", table, resp.status_code, resp.text[:300])
            resp.raise_for_status()
        total += len(chunk)
        logger.info("  %s: %d/%d gravados", table, total, len(rows))
    return total


def _log_ingestao(dataset: str, arquivo: str, status: str, n_linhas: int, erro: str = None, dry_run: bool = False) -> None:
    if dry_run:
        return
    try:
        url = os.environ.get("SUPABASE_URL", "")
        if not url:
            return
        payload = {
            "dataset": dataset,
            "arquivo": arquivo,
            "status": status,
            "n_linhas": n_linhas,
            "erro": erro,
            "finished_at": datetime.utcnow().isoformat(),
        }
        requests.post(
            f"{url}/rest/v1/pr_ingest_log",
            json=payload,
            headers=_supabase_headers(),
            timeout=10,
        )
    except Exception:
        pass


# ── Ex-presidentes ───────────────────────────────────────────────────────────

def run_ex_presidentes(pasta: Path, dry_run: bool) -> None:
    from .ex_presidentes_connector import carregar_arquivo

    arquivos = sorted(pasta.glob("*.xlsx")) + sorted(pasta.glob("*.XLSX"))
    if not arquivos:
        logger.error("Nenhum arquivo .xlsx encontrado em %s", pasta)
        sys.exit(1)

    total = 0
    for path in arquivos:
        try:
            registros = carregar_arquivo(path)
            if not registros:
                logger.warning("Nenhum registro extraído de %s", path.name)
                continue
            n = _upsert("pr_ex_presidentes_custos", registros, dry_run)
            _log_ingestao("ex_presidentes", path.name, "ok", n, dry_run=dry_run)
            total += n
        except Exception as e:
            logger.exception("Erro em %s: %s", path.name, e)
            _log_ingestao("ex_presidentes", path.name, "erro", 0, str(e), dry_run=dry_run)

    logger.info("Total ex-presidentes: %d registros", total)


# ── Pessoal diversidade ──────────────────────────────────────────────────────

def run_pessoal(pasta: Path, dry_run: bool) -> None:
    from .pessoal_connector import carregar_arquivo

    arquivos = sorted(pasta.glob("*.csv")) + sorted(pasta.glob("*.CSV"))
    if not arquivos:
        logger.error("Nenhum arquivo .csv encontrado em %s", pasta)
        sys.exit(1)

    total = 0
    for path in arquivos:
        try:
            registros = carregar_arquivo(path)
            if not registros:
                logger.warning("Nenhum registro extraído de %s", path.name)
                continue
            n = _upsert("pr_pessoal_diversidade", registros, dry_run)
            _log_ingestao("pessoal_diversidade", path.name, "ok", n, dry_run=dry_run)
            total += n
        except Exception as e:
            logger.exception("Erro em %s: %s", path.name, e)
            _log_ingestao("pessoal_diversidade", path.name, "erro", 0, str(e), dry_run=dry_run)

    logger.info("Total pessoal diversidade: %d registros", total)


# ── CLI ──────────────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Ingestão Presidência da República — BR Insider"
    )
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_exp = sub.add_parser("ex-presidentes", help="Custos de ex-presidentes (XLSX)")
    p_exp.add_argument("--pasta", required=True, type=Path)
    p_exp.add_argument("--dry-run", action="store_true")

    p_pes = sub.add_parser("pessoal", help="Perfil e diversidade do pessoal (CSV)")
    p_pes.add_argument("--pasta", required=True, type=Path)
    p_pes.add_argument("--dry-run", action="store_true")

    args = parser.parse_args()

    if args.cmd == "ex-presidentes":
        run_ex_presidentes(args.pasta, args.dry_run)
    elif args.cmd == "pessoal":
        run_pessoal(args.pasta, args.dry_run)


if __name__ == "__main__":
    main()
