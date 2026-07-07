"""
IBAMA Autos de Infração — Tabela Editorial (ibama_autuacoes)
The BR Insider

Diferente de sub_ibama (Subradar, somente PJ):
  - Inclui PF e PJ
  - Campos adicionais para cruzamentos editoriais
  - Tabela independente: ibama_autuacoes

Fonte:
  https://stibamadadosabertosprd.blob.core.windows.net/dados-abertos/dados/SIFISC/
  auto_infracao/auto_infracao/auto_infracao_csv.zip
  ZIP com ~49 CSVs anuais (1977–atual) | ~114 MB comprimido | encoding latin-1

Uso:
  python -m ingestao.portal.ibama_bulk

Tabela: ibama_autuacoes
"""
from __future__ import annotations

import io
import logging
import os
import re
import time
import zipfile
from datetime import datetime
from typing import Optional

import requests

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("ibama_bulk")

URL = (
    "https://stibamadadosabertosprd.blob.core.windows.net"
    "/dados-abertos/dados/SIFISC/auto_infracao/auto_infracao/auto_infracao_csv.zip"
)

TABLE      = "ibama_autuacoes"
BATCH_SIZE = 400

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SUPABASE_KEY = (
    os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    or os.environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY")
    or ""
)

# Colunas possíveis por versão do CSV
CNPJ_COLS = ["CPF_CNPJ_INFRATOR", "CPF_CNPJ", "CNPJ_INFRATOR"]


# ── helpers ───────────────────────────────────────────────────────────────

def _headers_api() -> dict:
    return {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "resolution=ignore-duplicates,return=minimal",
    }


def _strip(v: str) -> str:
    return re.sub(r"\D", "", str(v or ""))


def _float_val(v: str) -> Optional[float]:
    v = v.strip().replace(",", ".").replace(" ", "")
    try:
        return float(v) if v else None
    except ValueError:
        return None


def _parse_date(v: str) -> Optional[str]:
    """Aceita 'dd/mm/yyyy', 'yyyy-mm-dd' ou 'yyyy-mm-ddThh:mm:ss'."""
    v = v.strip()[:10]
    if not v:
        return None
    for fmt in ("%d/%m/%Y", "%Y-%m-%d"):
        try:
            return datetime.strptime(v, fmt).date().isoformat()
        except ValueError:
            continue
    return None


def _tp_pessoa(cpf_cnpj_digits: str, tp_raw: str) -> str:
    if tp_raw.upper() in ("PF", "PJ"):
        return tp_raw.upper()
    return "PF" if len(cpf_cnpj_digits) == 11 else "PJ"


# ── parse ─────────────────────────────────────────────────────────────────

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
        return

    for line in lines[1:]:
        if not line.strip():
            continue
        counters["total"] += 1
        cols = line.split(";")

        cpf_cnpj = _strip(get(cols, cnpj_col))
        if len(cpf_cnpj) not in (11, 14):
            continue

        tp_raw   = get(cols, "TP_PESSOA_INFRATOR")
        tp       = _tp_pessoa(cpf_cnpj, tp_raw)

        val_raw  = get(cols, "VAL_AUTO_INFRACAO")
        dat_raw  = get(cols, "DAT_HORA_AUTO_INFRACAO") or get(cols, "DT_FATO_INFRACIONAL")
        num_auto = get(cols, "NUM_AUTO_INFRACAO")

        if not num_auto:
            continue

        batch.append({
            "num_auto_infracao":  num_auto,
            "tp_pessoa":          tp,
            "cpf_cnpj_infrator":  cpf_cnpj,
            "nome_infrator":      get(cols, "NOME_INFRATOR") or None,
            "des_infracao":       get(cols, "DES_INFRACAO") or None,
            "des_situacao":       get(cols, "DS_SIT_AUTO_AIE") or get(cols, "DES_STATUS_FORMULARIO") or None,
            "val_auto_infracao":  _float_val(val_raw),
            "dat_infracao":       _parse_date(dat_raw),
            "municipio":          get(cols, "MUNICIPIO") or None,
            "uf":                 get(cols, "UF")[:2] or None,
            "num_processo":       get(cols, "NU_PROCESSO_FORMATADO") or get(cols, "NUM_PROCESSO") or None,
        })
        counters["inserted"] += 1


# ── upsert ────────────────────────────────────────────────────────────────

def _upsert(rows: list[dict]) -> None:
    if not rows:
        return
    url = f"{SUPABASE_URL}/rest/v1/{TABLE}"
    for attempt in range(4):
        r = requests.post(url, json=rows, headers=_headers_api(), timeout=90)
        if r.ok:
            return
        if r.status_code in (429, 503):
            time.sleep(2 ** attempt)
            continue
        logger.error("upsert falhou: %s %s", r.status_code, r.text[:300])
        r.raise_for_status()


# ── entry point ───────────────────────────────────────────────────────────

def run() -> None:
    if not SUPABASE_URL or not SUPABASE_KEY:
        raise SystemExit("SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY ausentes")

    logger.info("Baixando bulk CSV IBAMA (~114 MB)…")
    r = requests.get(URL, timeout=300, headers={
        "User-Agent": "BRInsider/1.0 (contato@thebrinsider.com)"
    })
    r.raise_for_status()
    logger.info("Download OK — %.0f MB", len(r.content) / 1_048_576)

    batch:    list[dict] = []
    counters: dict       = {"total": 0, "inserted": 0}

    with zipfile.ZipFile(io.BytesIO(r.content)) as z:
        csv_names = sorted(n for n in z.namelist() if n.endswith(".csv"))
        logger.info("%d CSVs no ZIP", len(csv_names))

        for csv_name in csv_names:
            _process_csv(z.read(csv_name), batch, counters)

            while len(batch) >= BATCH_SIZE:
                _upsert(batch[:BATCH_SIZE])
                del batch[:BATCH_SIZE]

            logger.debug("  %s — acumulado: %d autos", csv_name, counters["inserted"])

        if batch:
            _upsert(batch)

    logger.info(
        "IBAMA bulk concluído: %d autos de %d linhas totais (PF+PJ)",
        counters["inserted"],
        counters["total"],
    )


if __name__ == "__main__":
    run()
