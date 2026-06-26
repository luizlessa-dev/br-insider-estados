"""
Seed da tabela sub_ans_operadoras — operadoras ativas ANS.

Uso:
    python -m ingestao.subradar.ans_seeder

CSV: dadosabertos.ans.gov.br — Relatorio_cadop.csv
Colunas: REGISTRO_OPERADORA;CNPJ;Razao_Social;Modalidade;Situacao;...
"""
from __future__ import annotations

import logging
import os
import re
import time

import requests

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("ans_seeder")

CSV_URL = (
    "https://dadosabertos.ans.gov.br/FTP/PDA/operadoras_de_plano_de_saude_ativas/"
    "Relatorio_cadop.csv"
)

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SUPABASE_KEY = (
    os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    or os.environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY")
    or ""
)

TABLE      = "sub_ans_operadoras"
BATCH_SIZE = 500


def _headers_sb():
    return {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "resolution=ignore-duplicates,return=minimal",
    }


def _strip(v: str) -> str:
    return re.sub(r"\D", "", str(v or ""))


def _upsert(rows: list[dict]) -> None:
    if not rows:
        return
    url = f"{SUPABASE_URL}/rest/v1/{TABLE}"
    for attempt in range(4):
        r = requests.post(url, json=rows, headers=_headers_sb(), timeout=90)
        if r.ok:
            return
        if r.status_code in (429, 503):
            time.sleep(2 ** attempt)
            continue
        logger.error("upsert falhou: %s %s", r.status_code, r.text[:300])
        r.raise_for_status()


def run() -> None:
    if not SUPABASE_URL or not SUPABASE_KEY:
        raise SystemExit("SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY ausentes")

    logger.info("Baixando CSV ANS operadoras...")
    r = requests.get(CSV_URL, timeout=120, headers={"User-Agent": "Mozilla/5.0"})
    r.raise_for_status()

    try:
        raw = r.content.decode("utf-8")
    except Exception:
        raw = r.content.decode("latin-1", errors="replace")

    lines = raw.splitlines()
    logger.info("Linhas brutas: %d", len(lines))

    sep = ";" if ";" in lines[0] else ","
    header = [c.strip().strip('"') for c in lines[0].split(sep)]
    idx    = {c.upper(): i for i, c in enumerate(header)}

    def get(cols: list, *names: str) -> str:
        for n in names:
            i = idx.get(n.upper())
            if i is not None and i < len(cols):
                v = cols[i].strip().strip('"')
                if v:
                    return v
        return ""

    batch: list[dict] = []
    total = inserted = 0

    for line in lines[1:]:
        if not line.strip():
            continue
        total += 1
        cols = line.split(sep)
        cnpj = _strip(get(cols, "CNPJ"))
        if len(cnpj) != 14:
            continue

        inserted += 1
        batch.append({
            "cnpj":           cnpj,
            "registro_ans":   get(cols, "REGISTRO_OPERADORA"),
            "razao_social":   get(cols, "Razao_Social", "RAZAO_SOCIAL")[:300],
            "nome_fantasia":  get(cols, "Nome_Fantasia", "NOME_FANTASIA")[:300],
            "modalidade":     get(cols, "Modalidade", "MODALIDADE"),
            "situacao":       get(cols, "Situacao", "SITUACAO"),
            "uf":             get(cols, "UF"),
            "municipio":      get(cols, "Cidade", "MUNICIPIO"),
            "regiao":         get(cols, "Regiao_de_Comercializacao", "REGIAO"),
            "dat_registro":   get(cols, "Data_Registro_ANS", "DATA_REGISTRO_ANS")[:10] or None,
        })

        if len(batch) >= BATCH_SIZE:
            _upsert(batch)
            batch.clear()

    if batch:
        _upsert(batch)

    logger.info("Seed ANS concluído: %d operadoras de %d linhas", inserted, total)


if __name__ == "__main__":
    run()
