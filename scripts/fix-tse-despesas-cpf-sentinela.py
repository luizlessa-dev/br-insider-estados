"""
Limpa cpf_candidato = '4' em tse_despesas.

O sentinela '-4' do TSE (CPF não divulgável) era transformado em '4' por
re.sub(r"\\D", "", "-4") antes do fix em 2026-06-21. O fix corrige NOVAS
ingestões; este script corrige os dados já gravados.

Anos 2014-2022: foram reingeridos com o conector corrigido → 0 linhas afetadas.
Ano 2024: reingestão tentou DELETE e fez timeout → este script faz a correção
pontual via PATCH em batches de 1000 ids, sem tocar o resto dos dados.

Uso:
  python scripts/fix-tse-despesas-cpf-sentinela.py
  python scripts/fix-tse-despesas-cpf-sentinela.py --dry-run   # apenas conta
"""
from __future__ import annotations

import argparse
import logging
import os
import sys
import time

import requests

# Carrega .env da raiz do projeto se existir (sem dependência de python-dotenv)
_env_path = os.path.join(os.path.dirname(__file__), "..", ".env")
if os.path.exists(_env_path):
    with open(_env_path) as _f:
        for _line in _f:
            _line = _line.strip()
            if _line and not _line.startswith("#") and "=" in _line:
                _k, _, _v = _line.partition("=")
                os.environ.setdefault(_k.strip(), _v.strip().strip('"').strip("'"))

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("fix-cpf-sentinela")

URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")

if not URL or not KEY:
    log.error("SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY são obrigatórios.")
    sys.exit(1)

HEADERS = {
    "apikey": KEY,
    "Authorization": f"Bearer {KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=minimal",
}

BATCH = 1000


def fetch_batch() -> list[int]:
    """Retorna até BATCH ids onde cpf_candidato = '4'."""
    resp = requests.get(
        f"{URL}/rest/v1/tse_despesas",
        headers={**HEADERS, "Prefer": ""},
        params={
            "select": "id",
            "cpf_candidato": "eq.4",
            "limit": str(BATCH),
        },
        timeout=30,
    )
    resp.raise_for_status()
    return [r["id"] for r in resp.json()]


def patch_batch(ids: list[int]) -> None:
    """Seta cpf_candidato = null nos ids fornecidos."""
    id_list = ",".join(str(i) for i in ids)
    resp = requests.patch(
        f"{URL}/rest/v1/tse_despesas",
        headers=HEADERS,
        params={"id": f"in.({id_list})"},
        json={"cpf_candidato": None},
        timeout=60,
    )
    if resp.status_code >= 300:
        raise RuntimeError(f"PATCH falhou: {resp.status_code} — {resp.text[:200]}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", help="Conta mas não altera")
    args = parser.parse_args()

    total = 0
    rodada = 0

    while True:
        rodada += 1
        ids = fetch_batch()
        if not ids:
            break

        if args.dry_run:
            total += len(ids)
            log.info("[dry-run] rodada %d: %d linhas encontradas (total %d)", rodada, len(ids), total)
            if len(ids) < BATCH:
                break
            continue

        patch_batch(ids)
        total += len(ids)
        log.info("Rodada %d: %d linhas corrigidas (total %d)", rodada, len(ids), total)

        if len(ids) < BATCH:
            break

        time.sleep(0.1)  # throttle leve

    if args.dry_run:
        log.info("[dry-run] Total estimado: %d linhas com cpf_candidato='4'", total)
    else:
        log.info("Concluído. Total corrigido: %d linhas.", total)


if __name__ == "__main__":
    main()
