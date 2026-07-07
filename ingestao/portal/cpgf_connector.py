"""
CPGF — Cartão de Pagamento do Governo Federal
The BR Insider

Fonte: Portal da Transparência
  https://portaldatransparencia.gov.br/download-de-dados/cpgf/{ano}
  Retorna ZIP com CSV de ~1,5M linhas/ano (encoding latin-1, sep=";").

Colunas CSV:
  Ano e Mês do Lançamento | CPF Portador | Nome Portador
  CPF ou CNPJ do Favorecido | Nome do Favorecido | Transação
  Estabelecimento | Município - UF | Valor da Transação

Uso:
  python -m ingestao.portal.cpgf_connector            # ano corrente + anterior
  python -m ingestao.portal.cpgf_connector 2022 2023  # anos específicos
  python -m ingestao.portal.cpgf_connector --backfill # desde 2003

Tabela: cpgf_transacoes
"""
from __future__ import annotations

import csv
import io
import logging
import os
import re
import sys
import time
import zipfile
from datetime import date
from typing import Optional

import requests

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("cpgf")

BASE_URL   = "https://portaldatransparencia.gov.br/download-de-dados/cpgf"
TABLE      = "cpgf_transacoes"
BATCH_SIZE = 500
ANO_INICIO = 2003

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SUPABASE_KEY = (
    os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    or os.environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY")
    or ""
)

# Mapeamento de cabeçalhos CSV (normalizados) → campos da tabela
COL_ANO_MES    = "ANO E MÊS DO LANÇAMENTO"
COL_CPF_PORT   = "CPF PORTADOR"
COL_NOME_PORT  = "NOME PORTADOR"
COL_FAV_DOC    = "CPF OU CNPJ DO FAVORECIDO"
COL_FAV_NOME   = "NOME DO FAVORECIDO"
COL_TRANSACAO  = "TRANSAÇÃO"
COL_ESTAB      = "ESTABELECIMENTO"
COL_MUN_UF     = "MUNICÍPIO - UF"
COL_VALOR      = "VALOR DA TRANSAÇÃO"


# ── helpers ───────────────────────────────────────────────────────────────

def _headers_api() -> dict:
    return {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "resolution=ignore-duplicates,return=minimal",
    }


def _strip_doc(v: str) -> str:
    return re.sub(r"\D", "", v or "")


def _float_br(v: str) -> Optional[float]:
    v = v.strip().replace("\xa0", "").replace(" ", "")
    if not v:
        return None
    if "," in v:
        v = v.replace(".", "").replace(",", ".")
    try:
        return float(v)
    except ValueError:
        return None


def _parse_ano_mes(v: str) -> tuple[str, int, int]:
    """'01/2024' ou '2024-01' → ('2024-01', 2024, 1)."""
    v = v.strip()
    if "/" in v:
        mes, ano = v.split("/", 1)
        return f"{ano}-{mes.zfill(2)}", int(ano), int(mes)
    if "-" in v:
        ano, mes = v.split("-", 1)
        return f"{ano}-{mes.zfill(2)}", int(ano), int(mes)
    return v, 0, 0


def _parse_mun_uf(v: str) -> tuple[Optional[str], Optional[str]]:
    """'SÃO PAULO - SP' → ('SÃO PAULO', 'SP')."""
    v = v.strip()
    if " - " in v:
        parts = v.rsplit(" - ", 1)
        return parts[0].strip() or None, parts[1].strip()[:2] or None
    return v or None, None


# ── download ──────────────────────────────────────────────────────────────

def _download_zip(ano: int) -> bytes:
    url = f"{BASE_URL}/{ano}"
    logger.info("Baixando CPGF %d … (%s)", ano, url)
    # CGU exige Referer do portal para liberar o redirect ao dadosabertos-download
    req_headers = {
        "User-Agent": "Mozilla/5.0 (compatible; BRInsider/1.0; contato@thebrinsider.com)",
        "Referer": "https://portaldatransparencia.gov.br/",
        "Accept": "application/zip,application/octet-stream,*/*",
    }
    for attempt in range(4):
        try:
            r = requests.get(url, timeout=300, headers=req_headers, allow_redirects=True)
            if r.status_code == 404:
                logger.warning("Ano %d não disponível (404)", ano)
                return b""
            r.raise_for_status()
            logger.info("Download OK — %.1f MB", len(r.content) / 1_048_576)
            return r.content
        except requests.RequestException as exc:
            if attempt == 3:
                raise
            wait = 2 ** attempt
            logger.warning("Tentativa %d falhou (%s), aguardando %ds", attempt + 1, exc, wait)
            time.sleep(wait)
    return b""


# ── parse ─────────────────────────────────────────────────────────────────

def _parse_zip(raw: bytes) -> list[dict]:
    rows: list[dict] = []
    with zipfile.ZipFile(io.BytesIO(raw)) as zf:
        csv_names = [n for n in zf.namelist() if n.lower().endswith(".csv")]
        logger.info("%d CSV(s) no ZIP", len(csv_names))
        for csv_name in csv_names:
            content = zf.read(csv_name)
            try:
                text = content.decode("latin-1")
            except Exception:
                text = content.decode("utf-8", errors="replace")

            reader = csv.DictReader(io.StringIO(text), delimiter=";")
            # normaliza cabeçalhos
            reader.fieldnames = [f.strip().upper() for f in (reader.fieldnames or [])]

            for raw_row in reader:
                row = {k.strip().upper(): (v or "").strip() for k, v in raw_row.items()}
                ano_mes, ano, mes = _parse_ano_mes(row.get(COL_ANO_MES, ""))
                municipio, uf = _parse_mun_uf(row.get(COL_MUN_UF, ""))
                cpf_port = _strip_doc(row.get(COL_CPF_PORT, "")) or None
                if not cpf_port:
                    continue
                rows.append({
                    "ano_mes":              ano_mes,
                    "ano":                  ano,
                    "mes":                  mes,
                    "cpf_portador":         cpf_port,
                    "nome_portador":        row.get(COL_NOME_PORT) or None,
                    "cpf_cnpj_favorecido":  _strip_doc(row.get(COL_FAV_DOC, "")) or None,
                    "nome_favorecido":      row.get(COL_FAV_NOME) or None,
                    "transacao":            row.get(COL_TRANSACAO) or None,
                    "estabelecimento":      row.get(COL_ESTAB) or None,
                    "municipio":            municipio,
                    "uf":                   uf,
                    "valor":                _float_br(row.get(COL_VALOR, "")),
                })
    return rows


# ── upsert ────────────────────────────────────────────────────────────────

def _upsert(rows: list[dict]) -> None:
    if not rows:
        return
    url = f"{SUPABASE_URL}/rest/v1/{TABLE}"
    for i in range(0, len(rows), BATCH_SIZE):
        batch = rows[i : i + BATCH_SIZE]
        for attempt in range(4):
            r = requests.post(url, json=batch, headers=_headers_api(), timeout=60)
            if r.ok:
                break
            if r.status_code in (429, 503):
                time.sleep(2 ** attempt)
                continue
            logger.error("upsert falhou: %s %s", r.status_code, r.text[:300])
            r.raise_for_status()


# ── entry point ───────────────────────────────────────────────────────────

def ingerir_ano(ano: int) -> int:
    raw = _download_zip(ano)
    if not raw:
        return 0
    rows = _parse_zip(raw)
    logger.info("CPGF %d: %d transações parseadas", ano, len(rows))
    _upsert(rows)
    logger.info("CPGF %d: upsert concluído", ano)
    return len(rows)


def main() -> None:
    if not SUPABASE_URL or not SUPABASE_KEY:
        raise SystemExit("SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY ausentes")

    args = sys.argv[1:]
    if "--backfill" in args:
        anos = list(range(ANO_INICIO, date.today().year + 1))
    elif args:
        anos = [int(a) for a in args if a.isdigit()]
    else:
        hoje = date.today()
        anos = [hoje.year - 1, hoje.year]

    total = 0
    for ano in anos:
        total += ingerir_ano(ano)

    logger.info("Sprint 1 CPGF: %d transações totais ingeridas para anos %s", total, anos)


if __name__ == "__main__":
    main()
