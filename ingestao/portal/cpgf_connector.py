"""
CPGF — Cartão de Pagamento do Governo Federal
The BR Insider

Fonte: Portal da Transparência. O CGU NÃO publica ZIP anual — publica um ZIP
por MÊS, direto no bucket S3 (o endpoint /download-de-dados/cpgf/{ano} do
front-end redireciona pro nome de arquivo anual, que não existe e dá 403):
  https://dadosabertos-download.cgu.gov.br/PortalDaTransparencia/saida/cpgf/{AAAAMM}_CPGF.zip
  Cada ZIP mensal ~1,5M/12 linhas (encoding latin-1, sep=";").

Colunas CSV:
  Ano e Mês do Lançamento | CPF Portador | Nome Portador
  CPF ou CNPJ do Favorecido | Nome do Favorecido | Transação
  Estabelecimento | Município - UF | Valor da Transação

Uso:
  python -m ingestao.portal.cpgf_connector            # ano corrente + anterior
  python -m ingestao.portal.cpgf_connector 2022 2023  # anos específicos
  python -m ingestao.portal.cpgf_connector --backfill # desde 2003

Tabela: cpgf_transacoes (idempotente via UNIQUE ano_mes,cpf_portador,
cpf_cnpj_favorecido,transacao,valor — ver db/migrations/0044_cpgf.sql)
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

BASE_URL   = "https://dadosabertos-download.cgu.gov.br/PortalDaTransparencia/saida/cpgf"
TABLE      = "cpgf_transacoes"
BATCH_SIZE = 500
ANO_INICIO = 2003
ON_CONFLICT = "ano_mes,cpf_portador,cpf_cnpj_favorecido,transacao,valor"

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SUPABASE_KEY = (
    os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    or os.environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY")
    or ""
)

# Mapeamento de cabeçalhos CSV (normalizados) → campos da tabela.
# Validado contra ZIP real (202506_CPGF.csv) em 2026-07-11 — os nomes abaixo
# batem com o cabeçalho de verdade, diferente da versão anterior deste
# arquivo (nunca tinha sido checado contra um CSV real).
COL_ORGSUP_COD = "CÓDIGO ÓRGÃO SUPERIOR"
COL_ORGSUP_NOME = "NOME ÓRGÃO SUPERIOR"
COL_ORG_COD    = "CÓDIGO ÓRGÃO"
COL_ORG_NOME   = "NOME ÓRGÃO"
COL_UG_COD     = "CÓDIGO UNIDADE GESTORA"
COL_UG_NOME    = "NOME UNIDADE GESTORA"
COL_CPF_PORT   = "CPF PORTADOR"
COL_NOME_PORT  = "NOME PORTADOR"
COL_FAV_DOC    = "CNPJ OU CPF FAVORECIDO"
COL_FAV_NOME   = "NOME FAVORECIDO"
COL_TRANSACAO  = "TRANSAÇÃO"
COL_DATA       = "DATA TRANSAÇÃO"
COL_VALOR      = "VALOR TRANSAÇÃO"


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


def _valid_favorecido_doc(v: str) -> Optional[str]:
    """CGU usa sentinelas curtas ('-1', '-2', '-11' = 'NAO SE APLICA') pra
    favorecido não identificado. CPF real tem 11 dígitos, CNPJ 14 — filtra
    qualquer coisa mais curta (o sentinela vira '1'/'2'/'11' após strip)."""
    digits = _strip_doc(v)
    return digits if len(digits) in (11, 14) else None


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


def _parse_data_br(v: str) -> Optional[str]:
    """'20/05/2025' → '2025-05-20'."""
    v = (v or "").strip()
    m = re.match(r"^(\d{2})/(\d{2})/(\d{4})$", v)
    if not m:
        return None
    d, mo, y = m.groups()
    return f"{y}-{mo}-{d}"


# ── download ──────────────────────────────────────────────────────────────

def _download_zip(ano: int, mes: int) -> bytes:
    url = f"{BASE_URL}/{ano}{mes:02d}_CPGF.zip"
    logger.info("Baixando CPGF %04d-%02d … (%s)", ano, mes, url)
    req_headers = {
        "User-Agent": "Mozilla/5.0 (compatible; BRInsider/1.0; contato@thebrinsider.com)",
        "Referer": "https://portaldatransparencia.gov.br/",
        "Accept": "application/zip,application/octet-stream,*/*",
    }
    for attempt in range(4):
        try:
            r = requests.get(url, timeout=300, headers=req_headers)
            if r.status_code in (403, 404):
                # 403 = chave inexistente no bucket (mês ainda não publicado ou fora do range).
                logger.warning("CPGF %04d-%02d não disponível (%d)", ano, mes, r.status_code)
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

def _parse_zip(raw: bytes, ano: int, mes: int) -> list[dict]:
    # ano/mes vêm do nome do arquivo baixado (competência), não do CSV —
    # mais robusto que reparsear um campo de data por linha.
    ano_mes = f"{ano:04d}-{mes:02d}"
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
                cpf_port = _strip_doc(row.get(COL_CPF_PORT, "")) or None
                if not cpf_port:
                    continue
                rows.append({
                    "ano_mes":                  ano_mes,
                    "ano":                      ano,
                    "mes":                      mes,
                    "cpf_portador":             cpf_port,
                    "nome_portador":            row.get(COL_NOME_PORT) or None,
                    "cpf_cnpj_favorecido":      _valid_favorecido_doc(row.get(COL_FAV_DOC, "")),
                    "nome_favorecido":          row.get(COL_FAV_NOME) or None,
                    "transacao":                row.get(COL_TRANSACAO) or None,
                    "data_transacao":           _parse_data_br(row.get(COL_DATA, "")),
                    "codigo_orgao_superior":    row.get(COL_ORGSUP_COD) or None,
                    "nome_orgao_superior":      row.get(COL_ORGSUP_NOME) or None,
                    "codigo_orgao":             row.get(COL_ORG_COD) or None,
                    "nome_orgao":               row.get(COL_ORG_NOME) or None,
                    "codigo_unidade_gestora":   row.get(COL_UG_COD) or None,
                    "nome_unidade_gestora":     row.get(COL_UG_NOME) or None,
                    "valor":                    _float_br(row.get(COL_VALOR, "")),
                })
    return rows


# ── upsert ────────────────────────────────────────────────────────────────

def _upsert(rows: list[dict]) -> None:
    if not rows:
        return
    url = f"{SUPABASE_URL}/rest/v1/{TABLE}"
    params = {"on_conflict": ON_CONFLICT}
    for i in range(0, len(rows), BATCH_SIZE):
        batch = rows[i : i + BATCH_SIZE]
        for attempt in range(4):
            r = requests.post(url, params=params, json=batch, headers=_headers_api(), timeout=60)
            if r.ok:
                break
            if r.status_code in (429, 503):
                time.sleep(2 ** attempt)
                continue
            logger.error("upsert falhou: %s %s", r.status_code, r.text[:300])
            r.raise_for_status()


# ── entry point ───────────────────────────────────────────────────────────

def ingerir_mes(ano: int, mes: int) -> int:
    raw = _download_zip(ano, mes)
    if not raw:
        return 0
    rows = _parse_zip(raw, ano, mes)
    logger.info("CPGF %04d-%02d: %d transações parseadas", ano, mes, len(rows))
    _upsert(rows)
    logger.info("CPGF %04d-%02d: upsert concluído", ano, mes)
    return len(rows)


def ingerir_ano(ano: int) -> int:
    hoje = date.today()
    ultimo_mes = hoje.month if ano == hoje.year else 12
    total = 0
    for mes in range(1, ultimo_mes + 1):
        total += ingerir_mes(ano, mes)
    return total


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

    logger.info("CPGF: %d transações totais ingeridas para anos %s", total, anos)


if __name__ == "__main__":
    main()
