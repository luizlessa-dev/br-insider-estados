"""
Seed diário da tabela sub_cvm_pas a partir do bulk CSV da CVM.

Uso:
    python -m ingestao.subradar.cvm_seeder

Fonte: https://dados.cvm.gov.br/dados/PROCESSO/SANCIONADOR/DADOS/processo_sancionador.zip
Dois CSVs no ZIP:
  - processo_sancionador.csv        — dados do processo
  - processo_sancionador_acusado.csv — acusados (com CPF/CNPJ)
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
logger = logging.getLogger("cvm_seeder")

URL = "https://dados.cvm.gov.br/dados/PROCESSO/SANCIONADOR/DADOS/processo_sancionador.zip"

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SUPABASE_KEY = (
    os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    or os.environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY")
    or ""
)

BATCH_SIZE = 500
TABLE = "sub_cvm_pas"


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


def _parse_csv(raw: bytes, encoding: str = "utf-8") -> tuple[list[str], list[list[str]]]:
    text = raw.decode(encoding, errors="replace")
    lines = text.splitlines()
    if not lines:
        return [], []
    header = [c.strip().upper() for c in lines[0].split(";")]
    rows = [line.split(";") for line in lines[1:] if line.strip()]
    return header, rows


def run() -> None:
    if not SUPABASE_URL or not SUPABASE_KEY:
        raise SystemExit("SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY ausentes")

    logger.info("Baixando PAS CVM...")
    r = requests.get(URL, timeout=120)
    r.raise_for_status()
    logger.info("Download OK — %d KB", len(r.content) // 1024)

    with zipfile.ZipFile(io.BytesIO(r.content)) as z:
        names = z.namelist()
        logger.info("Arquivos no ZIP: %s", names)

        # Processos: num_pas → campos do processo
        proc_file = next((n for n in names if "acusado" not in n.lower() and n.endswith(".csv")), None)
        acus_file = next((n for n in names if "acusado" in n.lower()), None)

        if not proc_file or not acus_file:
            raise SystemExit(f"Estrutura inesperada no ZIP: {names}")

        proc_header, proc_rows = _parse_csv(z.read(proc_file))
        acus_header, acus_rows = _parse_csv(z.read(acus_file))

    logger.info("Processos: %d linhas | Acusados: %d linhas", len(proc_rows), len(acus_rows))

    # Indexar processos por num_pas
    p_idx = {c: i for i, c in enumerate(proc_header)}

    def pget(row, col):
        i = p_idx.get(col)
        return row[i].strip() if i is not None and i < len(row) else ""

    proc_map: dict[str, dict] = {}
    for row in proc_rows:
        num = pget(row, "NUM_PAS") or pget(row, "NUMPAS") or pget(row, "NUMERO_PAS")
        if num:
            proc_map[num] = {
                "num_pas":               num,
                "des_fase":              pget(row, "DES_FASE") or pget(row, "FASE"),
                "des_tipo_irregularidade": pget(row, "DES_TIPO_IRREGULARIDADE") or pget(row, "TIPO_IRREGULARIDADE"),
                "dat_julgamento":        pget(row, "DAT_JULGAMENTO") or pget(row, "DATA_JULGAMENTO"),
                "des_orgao_julgador":    pget(row, "DES_ORGAO_JULGADOR") or pget(row, "ORGAO_JULGADOR"),
            }

    # Acusados — cruzar com processo
    a_idx = {c: i for i, c in enumerate(acus_header)}

    def aget(row, col):
        i = a_idx.get(col)
        return row[i].strip() if i is not None and i < len(row) else ""

    # Detectar coluna CNPJ/CPF nos acusados
    cpf_col = next((c for c in ["CPF_CNPJ", "CNPJ", "CPF", "DOCUMENTO"] if c in a_idx), None)
    if not cpf_col:
        raise SystemExit(f"Coluna CPF/CNPJ não encontrada em acusados: {acus_header}")

    logger.info("Coluna CPF/CNPJ em acusados: %s", cpf_col)

    batch: list[dict] = []
    inserted = total = 0

    for row in acus_rows:
        total += 1
        doc_raw = aget(row, cpf_col)
        doc     = _strip(doc_raw)

        # Só CNPJs (14 dígitos)
        if len(doc) != 14:
            continue

        num_pas = aget(row, "NUM_PAS") or aget(row, "NUMPAS") or aget(row, "NUMERO_PAS")
        proc    = proc_map.get(num_pas, {})

        sancao     = aget(row, "DES_SANCAO") or aget(row, "SANCAO") or ""
        val_multa  = aget(row, "VAL_MULTA") or aget(row, "VALOR_MULTA") or None

        rec = {
            "cpf_cnpj":              doc,
            "nom_acusado":           aget(row, "NOM_ACUSADO") or aget(row, "NOME_ACUSADO") or "",
            "num_pas":               num_pas,
            "des_sancao":            sancao,
            "val_multa":             val_multa or None,
            "des_fase":              proc.get("des_fase", ""),
            "des_tipo_irregularidade": proc.get("des_tipo_irregularidade", ""),
            "dat_julgamento":        proc.get("dat_julgamento", "") or None,
            "des_orgao_julgador":    proc.get("des_orgao_julgador", "CVM"),
        }
        batch.append(rec)
        inserted += 1

        if len(batch) >= BATCH_SIZE:
            _upsert(batch)
            batch.clear()
            if inserted % 5_000 == 0:
                logger.info("  %d CNPJs inseridos", inserted)

    if batch:
        _upsert(batch)

    logger.info("Seed CVM PAS concluído: %d CNPJs de %d linhas de acusados", inserted, total)


if __name__ == "__main__":
    run()
