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


CNPJ_RE = re.compile(r"\b\d{2}[\.\s]?\d{3}[\.\s]?\d{3}[/\.\s]?\d{4}[\-\.\s]?\d{2}\b")


def _extract_cnpjs(text: str) -> list[str]:
    """Extrai CNPJs em qualquer formato do texto e retorna como dígitos."""
    return list({_strip(m) for m in CNPJ_RE.findall(text) if len(_strip(m)) == 14})


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

        proc_file = next((n for n in names if "acusado" not in n.lower() and n.endswith(".csv")), None)
        acus_file = next((n for n in names if "acusado" in n.lower()), None)

        if not proc_file or not acus_file:
            raise SystemExit(f"Estrutura inesperada no ZIP: {names}")

        proc_header, proc_rows = _parse_csv(z.read(proc_file))
        acus_header, acus_rows = _parse_csv(z.read(acus_file))

    logger.info("Processos: %d linhas | Acusados: %d linhas", len(proc_rows), len(acus_rows))

    p_idx = {c.upper(): i for i, c in enumerate(proc_header)}
    a_idx = {c.upper(): i for i, c in enumerate(acus_header)}

    def pget(row, *cols):
        for col in cols:
            i = p_idx.get(col.upper())
            if i is not None and i < len(row):
                v = row[i].strip()
                if v:
                    return v
        return ""

    def aget(row, *cols):
        for col in cols:
            i = a_idx.get(col.upper())
            if i is not None and i < len(row):
                v = row[i].strip()
                if v:
                    return v
        return ""

    # Índice acusados por NUP
    acus_by_nup: dict[str, list[str]] = {}
    for row in acus_rows:
        nup  = aget(row, "NUP")
        nome = aget(row, "NOME_ACUSADO", "NOM_ACUSADO")
        if nup and nome:
            acus_by_nup.setdefault(nup, []).append(nome)

    batch: list[dict] = []
    inserted = total = 0

    for row in proc_rows:
        total += 1
        nup    = pget(row, "NUP", "NUM_PAS")
        objeto = pget(row, "OBJETO")
        ementa = pget(row, "EMENTA")
        fase   = pget(row, "FASE_ATUAL", "DES_FASE")
        dt_ab  = pget(row, "DATA_ABERTURA", "DAT_JULGAMENTO")

        # Extrai CNPJs mencionados no texto do processo
        texto = f"{objeto} {ementa}"
        cnpjs = _extract_cnpjs(texto)
        nomes_acusados = "; ".join(acus_by_nup.get(nup, []))

        if not cnpjs:
            # Sem CNPJ explícito — armazena sem vinculação por CNPJ
            # Fica disponível para busca por razão social no connector
            cnpjs = ["SEM_CNPJ"]

        for cnpj in cnpjs:
            rec = {
                "cpf_cnpj":              cnpj,
                "nom_acusado":           nomes_acusados[:500],
                "num_pas":               nup,
                "des_sancao":            "",
                "val_multa":             None,
                "des_fase":              fase,
                "des_tipo_irregularidade": ementa[:500] if ementa else objeto[:500],
                "dat_julgamento":        dt_ab or None,
                "des_orgao_julgador":    "CVM",
            }
            batch.append(rec)
            inserted += 1

        if len(batch) >= BATCH_SIZE:
            _upsert(batch)
            batch.clear()
            if inserted % 2_000 == 0:
                logger.info("  %d linhas inseridas", inserted)

    if batch:
        _upsert(batch)

    logger.info("Seed CVM PAS concluído: %d linhas de %d processos", inserted, total)


if __name__ == "__main__":
    run()
