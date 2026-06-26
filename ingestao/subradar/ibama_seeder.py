"""
Seed mensal da tabela sub_ibama a partir do bulk CSV do IBAMA.

Uso:
    python -m ingestao.subradar.ibama_seeder

ZIP contém 49 CSVs anuais (1977–2026). Só PJs (14 dígitos) são inseridas.
Encoding: latin-1  Separador: ;  Tamanho: ~114 MB comprimido
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
TABLE      = "sub_ibama"
CNPJ_COLS  = ["CPF_CNPJ_INFRATOR", "CPF_CNPJ", "CNPJ_INFRATOR"]


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


def _process_csv(raw_bytes: bytes, batch: list, counters: dict) -> None:
    try:
        raw = raw_bytes.decode("latin-1")
    except Exception:
        raw = raw_bytes.decode("utf-8", errors="replace")

    lines = raw.splitlines()
    if len(lines) < 2:
        return

    header = [c.strip().upper() for c in lines[0].split(";")]
    idx    = {c: i for i, c in enumerate(header)}

    def get(row: list, col: str) -> str:
        i = idx.get(col)
        return row[i].strip() if i is not None and i < len(row) else ""

    cnpj_col = next((c for c in CNPJ_COLS if c in idx), None)
    if not cnpj_col:
        return  # CSV antigo sem coluna CNPJ

    for line in lines[1:]:
        if not line.strip():
            continue
        counters["total"] += 1
        cols    = line.split(";")
        tp_pess = get(cols, "TP_PESSOA_INFRATOR").upper()
        if tp_pess and tp_pess not in ("PJ", ""):
            continue

        cpf_cnpj = _strip(get(cols, cnpj_col))
        if len(cpf_cnpj) != 14:
            continue

        val_raw = get(cols, "VAL_AUTO_INFRACAO").replace(",", ".").replace(" ", "") or None
        try:
            val_num = float(val_raw) if val_raw else None
        except ValueError:
            val_num = None

        batch.append({
            "cpf_cnpj_infrator":    cpf_cnpj,
            "num_auto_infracao":    get(cols, "NUM_AUTO_INFRACAO"),
            "des_situacao_auto":    get(cols, "DS_SIT_AUTO_AIE") or get(cols, "DES_STATUS_FORMULARIO"),
            "dat_auto_de_infracao": (get(cols, "DAT_HORA_AUTO_INFRACAO") or get(cols, "DT_FATO_INFRACIONAL"))[:10] or None,
            "des_infracao":         get(cols, "DES_INFRACAO"),
            "val_auto_infracao":    val_num,
            "nom_municipio":        get(cols, "MUNICIPIO"),
            "sig_uf":               get(cols, "UF"),
            "num_processo":         get(cols, "NU_PROCESSO_FORMATADO") or get(cols, "NUM_PROCESSO"),
            "nom_infrator":         get(cols, "NOME_INFRATOR"),
        })
        counters["inserted"] += 1


def run() -> None:
    if not SUPABASE_URL or not SUPABASE_KEY:
        raise SystemExit("SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY ausentes")

    logger.info("Baixando bulk CSV IBAMA (~114 MB)...")
    r = requests.get(URL, timeout=300)
    r.raise_for_status()
    logger.info("Download OK — %d MB", len(r.content) // 1_048_576)

    batch:    list[dict] = []
    counters: dict       = {"total": 0, "inserted": 0}

    with zipfile.ZipFile(io.BytesIO(r.content)) as z:
        csv_names = sorted(n for n in z.namelist() if n.endswith(".csv"))
        logger.info("%d arquivos CSV no ZIP", len(csv_names))

        for csv_name in csv_names:
            _process_csv(z.read(csv_name), batch, counters)

            while len(batch) >= BATCH_SIZE:
                _upsert(batch[:BATCH_SIZE])
                del batch[:BATCH_SIZE]

            logger.debug("  %s — acumulado: %d PJs", csv_name, counters["inserted"])

        if batch:
            _upsert(batch)

    logger.info("Seed IBAMA concluído: %d CNPJs de %d linhas totais",
                counters["inserted"], counters["total"])


if __name__ == "__main__":
    run()
