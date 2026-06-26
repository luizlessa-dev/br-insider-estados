"""
Seed mensal da tabela sub_mte_autos — Autos de Infração Trabalhista MTE.

Uso:
    python -m ingestao.subradar.mte_autos_seeder

Fonte: dados.mte.gov.br — CSV anual, encoding latin-1, sep ;
Cobre autos de infração lavrados pelos Auditores Fiscais do Trabalho.
"""
from __future__ import annotations

import io
import logging
import os
import re
import time
import zipfile
from datetime import date

import requests

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("mte_autos_seeder")

# URL base dos dados abertos MTE — arquivos anuais de AITs
# Padrão: https://dados.mte.gov.br/dataset/ait/resource/{id}
# Usamos a URL de download direto do portal dados.gov.br
BASE_URL = "https://dadosabertos.mte.gov.br/dataset/ait"

# Fallback: CKAN API para descobrir recursos
CKAN_API  = "https://dados.mte.gov.br/api/3/action/package_show?id=ait"

# Anos para seed (foco nos últimos 10 anos)
ANO_INICIO = date.today().year - 10
ANO_FIM    = date.today().year

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SUPABASE_KEY = (
    os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    or os.environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY")
    or ""
)

TABLE      = "sub_mte_autos"
BATCH_SIZE = 400


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


def _discover_urls() -> list[str]:
    """Tenta descobrir URLs dos CSVs via API CKAN do MTE."""
    try:
        r = requests.get(CKAN_API, timeout=20)
        if r.ok:
            resources = r.json().get("result", {}).get("resources", [])
            urls = [
                res["url"] for res in resources
                if res.get("format", "").upper() in ("CSV", "ZIP")
                and res.get("url")
            ]
            if urls:
                logger.info("CKAN: %d recursos encontrados", len(urls))
                return urls
    except Exception as e:
        logger.warning("CKAN discovery falhou: %s", e)

    # Fallback: construção manual de URLs por ano
    urls = []
    for ano in range(ANO_FIM, ANO_INICIO - 1, -1):
        urls.append(
            f"https://dados.mte.gov.br/sites/default/files/datasets/ait_{ano}.zip"
        )
    logger.info("Usando URLs construídas manualmente: %d anos", len(urls))
    return urls


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

    def get(row: list, *cols: str) -> str:
        for col in cols:
            i = idx.get(col)
            if i is not None and i < len(row):
                v = row[i].strip()
                if v:
                    return v
        return ""

    # Detectar coluna de CNPJ
    cnpj_col = next(
        (c for c in ["CNPJ", "CPF_CNPJ", "CPF_CNPJ_ESTAB", "NR_CNPJ"] if c in idx),
        None
    )
    if not cnpj_col:
        logger.debug("Colunas disponíveis: %s", header[:15])
        return

    for line in lines[1:]:
        if not line.strip():
            continue
        counters["total"] += 1
        cols     = line.split(";")
        cnpj_raw = get(cols, cnpj_col)
        cnpj     = _strip(cnpj_raw)

        if len(cnpj) != 14:
            continue

        val_raw = get(cols, "VAL_MULTA", "VL_MULTA", "VALOR_MULTA").replace(",", ".") or None
        try:
            val_num = float(val_raw) if val_raw else None
        except ValueError:
            val_num = None

        batch.append({
            "cnpj":         cnpj,
            "num_ait":      get(cols, "NUM_AIT", "NR_AIT", "NR_AUTO"),
            "des_situacao": get(cols, "DES_SITUACAO", "DS_SITUACAO", "SIT_AIT"),
            "des_infracao": get(cols, "DES_INFRACAO", "DS_INFRACAO", "DS_TIPO_INFRACAO")[:500],
            "val_multa":    val_num,
            "dat_ait":      get(cols, "DAT_AIT", "DT_AIT", "DATA_AIT")[:10] or None,
            "sig_uf":       get(cols, "SIG_UF", "UF", "SG_UF"),
            "nom_municipio": get(cols, "NOM_MUNICIPIO", "MUNICIPIO", "DS_MUNICIPIO"),
            "nom_razao_social": get(cols, "NOM_RAZAO_SOCIAL", "RAZAO_SOCIAL", "NOME_EMPRESA")[:300],
        })
        counters["inserted"] += 1


def run() -> None:
    if not SUPABASE_URL or not SUPABASE_KEY:
        raise SystemExit("SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY ausentes")

    urls   = _discover_urls()
    batch: list[dict]  = []
    counters = {"total": 0, "inserted": 0}
    ok_count = 0

    for url in urls:
        try:
            logger.info("Baixando: %s", url)
            r = requests.get(url, timeout=120)
            if not r.ok:
                logger.warning("  HTTP %s — pulando", r.status_code)
                continue

            content = r.content
            # Detecta se é ZIP ou CSV direto
            if content[:2] == b"PK":
                with zipfile.ZipFile(io.BytesIO(content)) as z:
                    for name in z.namelist():
                        if name.endswith(".csv"):
                            _process_csv(z.read(name), batch, counters)
            else:
                _process_csv(content, batch, counters)

            ok_count += 1
            logger.info("  acumulado: %d AITs", counters["inserted"])

            while len(batch) >= BATCH_SIZE:
                _upsert(batch[:BATCH_SIZE])
                del batch[:BATCH_SIZE]

        except Exception as e:
            logger.warning("Erro ao processar %s: %s", url, e)

    if batch:
        _upsert(batch)

    if ok_count == 0:
        logger.warning(
            "Nenhum arquivo MTE baixado com sucesso. "
            "Verificar URLs em dados.mte.gov.br ou dados.gov.br/dados/conjuntos-dados/ait"
        )
    else:
        logger.info("Seed MTE Autos concluído: %d AITs de %d linhas (%d arquivos)",
                    counters["inserted"], counters["total"], ok_count)


if __name__ == "__main__":
    run()
