"""
Carregador de EmendasParlamentares_Convenios.csv → tabela emendas_convenios.

Uso:
    python -m ingestao.cgu.emendas_convenios /caminho/EmendasParlamentares_Convenios.csv

O arquivo é o bulk export CGU disponível em:
  portaldatransparencia.gov.br/download-de-dados/emendas
"""
from __future__ import annotations

import csv
import logging
import os
import sys
from datetime import datetime, date
from pathlib import Path
from typing import Iterator

import requests

logger = logging.getLogger("cgu.emendas_convenios")

CHUNK = 500
TABLE = "emendas_convenios"


def _parse_date(s: str) -> str | None:
    s = s.strip()
    if not s:
        return None
    for fmt in ("%d/%m/%Y", "%Y-%m-%d"):
        try:
            return datetime.strptime(s, fmt).date().isoformat()
        except ValueError:
            continue
    return None


def _parse_valor(s: str) -> float | None:
    s = s.strip().replace(".", "").replace(",", ".")
    try:
        return float(s)
    except ValueError:
        return None


def iter_rows(path: Path) -> Iterator[dict]:
    with open(path, encoding="latin-1", newline="") as f:
        reader = csv.DictReader(f, delimiter=";")
        for row in reader:
            numero = row.get("Número Convênio", "").strip()
            if not numero:
                continue
            yield {
                "numero_convenio":  numero,
                "codigo_emenda":    row.get("Código da Emenda", "").strip(),
                "codigo_funcao":    row.get("Código Função", "").strip() or None,
                "nome_funcao":      row.get("Nome Função", "").strip() or None,
                "codigo_subfuncao": row.get("Código Subfunção", "").strip() or None,
                "nome_subfuncao":   row.get("Nome Subfunção", "").strip() or None,
                "localidade_gasto": row.get("Localidade do gasto", "").strip() or None,
                "tipo_emenda":      row.get("Tipo de Emenda", "").strip() or None,
                "data_publicacao":  _parse_date(row.get("Data Publicação Convênio", "")),
                "convenente":       row.get("Convenente", "").strip() or None,
                "objeto":           row.get("Objeto Convênio", "").strip() or None,
                "valor":            _parse_valor(row.get("Valor Convênio", "")),
            }


def load(csv_path: str | Path) -> int:
    url = (os.environ.get("SUPABASE_URL") or "").rstrip("/")
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY") or ""
    if not url or not key:
        raise RuntimeError("SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY são obrigatórios.")

    session = requests.Session()
    session.headers.update({
        "apikey": key,
        "Authorization": f"Bearer {key}",
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates,return=minimal",
    })

    batch: list[dict] = []
    total = 0

    def flush():
        nonlocal total
        if not batch:
            return
        # dedup por numero_convenio dentro do chunk (PostgreSQL rejeita duplicatas no mesmo comando)
        seen: dict[str, dict] = {}
        for r in batch:
            seen[r["numero_convenio"]] = r
        deduped = list(seen.values())
        resp = session.post(
            f"{url}/rest/v1/{TABLE}",
            params={"on_conflict": "numero_convenio"},
            json=deduped,
            timeout=60,
        )
        if resp.status_code >= 300:
            raise RuntimeError(f"upsert {TABLE}: HTTP {resp.status_code} — {resp.text[:300]}")
        total += len(deduped)
        batch.clear()

    for row in iter_rows(Path(csv_path)):
        batch.append(row)
        if len(batch) >= CHUNK:
            flush()
            print(f"\r  {total} linhas gravadas...", end="", flush=True)

    flush()
    print()
    return total


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(name)s — %(message)s")
    if len(sys.argv) < 2:
        print(f"Uso: python -m ingestao.cgu.emendas_convenios <caminho_csv>")
        sys.exit(1)
    n = load(sys.argv[1])
    print(f"✅ {n} convênios gravados em {TABLE}")
