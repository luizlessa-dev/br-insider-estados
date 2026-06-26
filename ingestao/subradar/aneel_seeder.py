"""
Seed da tabela sub_aneel_autos — Autos de Infração ANEEL.

Uso:
    python -m ingestao.subradar.aneel_seeder

CSV único (atualizado periodicamente pela ANEEL):
  https://dadosabertos.aneel.gov.br/.../auto-infracao.csv
  Coluna CNPJ: NumCPFCNPJAgenteFiscalizado (14 dígitos para PJ)
"""
from __future__ import annotations

import io
import logging
import os
import re
import time

import requests

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("aneel_seeder")

CSV_URL = (
    "https://dadosabertos.aneel.gov.br/dataset/4d690c9d-8158-4b04-ae44-7d3de8616271"
    "/resource/f221158a-93a3-423f-b794-4312b6985a24/download/auto-infracao.csv"
)

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SUPABASE_KEY = (
    os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    or os.environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY")
    or ""
)

TABLE      = "sub_aneel_autos"
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

    logger.info("Baixando CSV ANEEL: %s", CSV_URL)
    r = requests.get(CSV_URL, timeout=120, headers={"User-Agent": "Mozilla/5.0"})
    r.raise_for_status()

    try:
        raw = r.content.decode("utf-8")
    except Exception:
        raw = r.content.decode("latin-1", errors="replace")

    lines = raw.splitlines()
    logger.info("Linhas brutas: %d", len(lines))

    header = [c.strip() for c in lines[0].split(";")]
    idx    = {c: i for i, c in enumerate(header)}
    logger.info("Colunas: %s", header[:10])

    def get(cols: list, *names: str) -> str:
        for n in names:
            i = idx.get(n)
            if i is not None and i < len(cols):
                v = cols[i].strip().strip('"')
                if v:
                    return v
        return ""

    batch: list[dict] = []
    total = pj = 0

    for line in lines[1:]:
        if not line.strip():
            continue
        total += 1
        cols = line.split(";")
        doc_raw = get(cols, "NumCPFCNPJAgenteFiscalizado")
        cnpj    = _strip(doc_raw)
        if len(cnpj) != 14:
            continue
        pj += 1

        val_raw = get(cols, "VlrPenalidade").replace(",", ".") or None
        try:
            val_num = float(val_raw) if val_raw else None
        except ValueError:
            val_num = None

        batch.append({
            "cnpj":                    cnpj,
            "num_auto_infracao":       get(cols, "NumAutoInfracao"),
            "nom_agente_fiscalizado":  get(cols, "NomAgenteFiscalizado")[:300],
            "nom_natureza_fiscalizacao": get(cols, "NomNaturezaFiscalizacao"),
            "dsc_tipo_penalidade":     get(cols, "DscTipoPenalidade"),
            "vlr_penalidade":          val_num,
            "dat_lavratura":           _parse_date(get(cols, "DatLavraturaAutoInfracao")),
            "sig_fiscalizador":        get(cols, "SigAgenteFiscalizador"),
            "num_processo":            get(cols, "NumProcessoPunitivo"),
            "dsc_decisao_juizo":       get(cols, "DscDecisaoCompletaJuizo")[:500],
            "dsc_decisao_diretoria":   get(cols, "DscDecisaoCompletaDiretoria")[:500],
        })

        if len(batch) >= BATCH_SIZE:
            _upsert(batch)
            batch.clear()

    if batch:
        _upsert(batch)

    logger.info("Seed ANEEL concluído: %d PJs de %d linhas totais", pj, total)


def _parse_date(s: str) -> str | None:
    if not s:
        return None
    for fmt in ("%Y-%m-%d", "%d/%m/%Y"):
        try:
            from datetime import datetime
            return datetime.strptime(s.strip()[:10], fmt).date().isoformat()
        except ValueError:
            continue
    return None


if __name__ == "__main__":
    run()
