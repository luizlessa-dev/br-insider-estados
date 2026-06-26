"""
Seed mensal da tabela sub_ibama a partir do bulk CSV do IBAMA.

Uso:
    python -m ingestao.subradar.ibama_seeder

Arquivo: ~130 MB descomprimido, ~500k linhas.
Encoding: latin-1  Separador: ;
"""
from __future__ import annotations

import io
import logging
import os
import re
import time
import zipfile

import requests

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("ibama_seeder")

URL = (
    "https://stibamadadosabertosprd.blob.core.windows.net"
    "/dados-abertos/dados/SIFISC/auto_infracao/auto_infracao/auto_infracao_csv.zip"
)

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SUPABASE_KEY = (
    os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    or os.environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY")
    or ""
)

BATCH_SIZE = 400
TABLE = "sub_ibama"

# Colunas que nos interessam (subset do CSV completo)
# Nome das colunas pode variar — detectado dinamicamente
CNPJ_COLS = ["CPF_CNPJ_INFRATOR", "CPF_CNPJ", "CNPJ_INFRATOR"]


def _headers():
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
        r = requests.post(url, json=rows, headers=_headers(), timeout=90)
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

    logger.info("Baixando bulk CSV IBAMA...")
    r = requests.get(URL, stream=True, timeout=300)
    r.raise_for_status()
    content = r.content
    logger.info("Download OK — %d MB", len(content) // 1_048_576)

    with zipfile.ZipFile(io.BytesIO(content)) as z:
        csv_name = next(n for n in z.namelist() if n.endswith(".csv"))
        logger.info("Processando %s", csv_name)
        raw = z.read(csv_name).decode("latin-1")

    lines = raw.splitlines()
    if not lines:
        raise SystemExit("CSV vazio")

    header = [c.strip().upper() for c in lines[0].split(";")]
    logger.info("Colunas: %s", header[:10])

    # Detectar coluna de CNPJ
    cnpj_col = next((c for c in CNPJ_COLS if c in header), None)
    if not cnpj_col:
        raise SystemExit(f"Coluna CNPJ não encontrada. Colunas disponíveis: {header}")

    idx = {c: i for i, c in enumerate(header)}

    def get(row: list, col: str) -> str:
        i = idx.get(col)
        return row[i].strip() if i is not None and i < len(row) else ""

    batch: list[dict] = []
    total = inserted = 0

    for line in lines[1:]:
        total += 1
        cols = line.split(";")
        cpf_cnpj_raw = get(cols, cnpj_col)
        cpf_cnpj     = _strip(cpf_cnpj_raw)

        # Só interessam CNPJs (14 dígitos)
        if len(cpf_cnpj) != 14:
            continue

        row = {
            "cpf_cnpj_infrator":    cpf_cnpj,
            "num_auto_infracao":    get(cols, "NUM_AUTO_INFRACAO"),
            "des_situacao_auto":    get(cols, "DES_SITUACAO_AUTO"),
            "dat_auto_de_infracao": get(cols, "DAT_AUTO_DE_INFRACAO"),
            "des_infracao":         get(cols, "DES_INFRACAO"),
            "val_auto_infracao":    get(cols, "VAL_AUTO_INFRACAO") or None,
            "nom_municipio":        get(cols, "NOM_MUNICIPIO"),
            "sig_uf":               get(cols, "SIG_UF"),
            "num_processo":         get(cols, "NUM_PROCESSO"),
            "nom_infrator":         get(cols, "NOME_INFRATOR"),
        }
        batch.append(row)
        inserted += 1

        if len(batch) >= BATCH_SIZE:
            _upsert(batch)
            batch.clear()
            if inserted % 10_000 == 0:
                logger.info("  %d CNPJs inseridos (de %d linhas)", inserted, total)

    if batch:
        _upsert(batch)

    logger.info("Seed IBAMA concluído: %d CNPJs de %d linhas totais", inserted, total)


if __name__ == "__main__":
    run()
