"""
XCMG Notas Fiscais — ingestão por janelas mensais via httpx

Usa httpx em vez de requests para contornar bug SSL do Python 3.14/macOS.
Schema real da API (flat, não nested):
  id, chaveNotaFiscal, numero, serie, dataEmissao,
  cnpjFornecedor, nomeFornecedor, municipioFornecedor,
  codigoOrgaoDestinatario, orgaoDestinatario,
  codigoOrgaoSuperiorDestinatario, orgaoSuperiorDestinatario,
  valorNotaFiscal, tipoEventoMaisRecente, dataTipoEventoMaisRecente

CNPJ: 14707364000110 (XCMG Brasil)
Período: 2020-01 → presente

Uso:
  cd /Users/luizlessa/brasilia-insider
  source .venv/bin/activate
  python -m ingestao.cgu.xcmg_nfs_mensal
"""
from __future__ import annotations

import calendar
import logging
import os
import re
import sys
import time
from datetime import date, datetime
from typing import Optional

import httpx
from supabase import create_client

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(name)s %(levelname)s %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("xcmg.nfs_mensal")

XCMG_CNPJ  = "14707364000110"
ANO_INICIO = 2020
MES_INICIO = 1
BASE_URL   = "https://api.portaldatransparencia.gov.br/api-de-dados/notas-fiscais"
PAGE_DELAY = 0.5
TABLE      = "notas_fiscais"


# ─── helpers ─────────────────────────────────────────────────────────────────

def _strip_digits(v) -> Optional[str]:
    if not v:
        return None
    d = re.sub(r"\D", "", str(v))
    return d or None


def _parse_date(v) -> Optional[str]:
    if not v:
        return None
    for fmt in ("%d/%m/%Y", "%Y-%m-%d"):
        try:
            return datetime.strptime(str(v).strip()[:10], fmt).date().isoformat()
        except ValueError:
            continue
    return None


def _parse_float(v) -> Optional[float]:
    if v is None:
        return None
    try:
        return float(str(v).replace(".", "").replace(",", "."))
    except (ValueError, TypeError):
        return None


def _parse_record(raw: dict) -> dict:
    return {
        "chave":                       raw.get("chaveNotaFiscal") or "",
        "numero":                      str(raw["numero"]) if raw.get("numero") else None,
        "serie":                       str(raw["serie"]) if raw.get("serie") else None,
        "data_emissao":                _parse_date(raw.get("dataEmissao")),
        "data_evento":                 _parse_date(raw.get("dataTipoEventoMaisRecente")),
        "emitente_cnpj":               _strip_digits(raw.get("cnpjFornecedor")),
        "emitente_razao_social":       raw.get("nomeFornecedor"),
        "emitente_municipio":          raw.get("municipioFornecedor"),
        "destinatario_orgao_codigo":   raw.get("codigoOrgaoDestinatario"),
        "destinatario_orgao_descricao": raw.get("orgaoDestinatario"),
        "destinatario_orgao_superior_codigo": raw.get("codigoOrgaoSuperiorDestinatario"),
        "destinatario_orgao_superior_descricao": raw.get("orgaoSuperiorDestinatario"),
        "valor_nota":                  _parse_float(raw.get("valorNotaFiscal")),
        "situacao":                    raw.get("tipoEventoMaisRecente"),
    }


def _janelas_mensais(ano_ini: int, mes_ini: int) -> list[tuple[date, date]]:
    hoje = date.today()
    janelas = []
    ano, mes = ano_ini, mes_ini
    while (ano, mes) <= (hoje.year, hoje.month):
        ultimo = calendar.monthrange(ano, mes)[1]
        ini = date(ano, mes, 1)
        fim = date(ano, mes, ultimo)
        if fim > hoje:
            fim = hoje
        janelas.append((ini, fim))
        mes += 1
        if mes > 12:
            mes = 1
            ano += 1
    return janelas


# ─── ingestão ────────────────────────────────────────────────────────────────

def _fetch_janela(client: httpx.Client, cnpj: str, ini: date, fim: date) -> list[dict]:
    records = []
    pagina = 1
    while True:
        time.sleep(PAGE_DELAY)
        resp = client.get(BASE_URL, params={
            "cnpjEmitente":      cnpj,
            "dataEmissaoInicio": ini.strftime("%d/%m/%Y"),
            "dataEmissaoFim":    fim.strftime("%d/%m/%Y"),
            "pagina":            pagina,
        }, timeout=30)
        if resp.status_code == 404:
            break
        resp.raise_for_status()
        page = resp.json()
        if not isinstance(page, list) or not page:
            break
        records.extend(page)
        pagina += 1
    return records


def _upsert(supabase, rows: list[dict]) -> int:
    if not rows:
        return 0
    supabase.table(TABLE).upsert(rows, on_conflict="chave").execute()
    return len(rows)


def _ensure_table(supabase) -> None:
    """Cria tabela notas_fiscais se não existir."""
    sql = """
    CREATE TABLE IF NOT EXISTS notas_fiscais (
        chave                               TEXT PRIMARY KEY,
        numero                              TEXT,
        serie                               TEXT,
        data_emissao                        DATE,
        data_evento                         DATE,
        emitente_cnpj                       TEXT,
        emitente_razao_social               TEXT,
        emitente_municipio                  TEXT,
        destinatario_orgao_codigo           TEXT,
        destinatario_orgao_descricao        TEXT,
        destinatario_orgao_superior_codigo  TEXT,
        destinatario_orgao_superior_descricao TEXT,
        valor_nota                          NUMERIC(18,2),
        situacao                            TEXT,
        updated_at                          TIMESTAMPTZ DEFAULT now()
    );
    CREATE INDEX IF NOT EXISTS idx_nf_emitente_cnpj ON notas_fiscais(emitente_cnpj);
    CREATE INDEX IF NOT EXISTS idx_nf_data_emissao  ON notas_fiscais(data_emissao);
    """
    supabase.rpc("execute_sql", {"query": sql}).execute()


def main() -> None:
    api_key  = os.environ.get("PORTAL_TRANSPARENCIA_API_KEY")
    supa_url = os.environ.get("SUPABASE_URL")
    supa_key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

    if not api_key or not supa_url or not supa_key:
        logger.error("Variáveis de ambiente ausentes.")
        sys.exit(1)

    supabase = create_client(supa_url, supa_key)
    _ensure_table(supabase)

    janelas = _janelas_mensais(ANO_INICIO, MES_INICIO)
    logger.info("XCMG: %d janelas mensais (%s → %s)", len(janelas),
                janelas[0][0], janelas[-1][1])

    headers = {
        "chave-api-dados": api_key,
        "Accept": "application/json",
        "User-Agent": "BRInsider/1.0 (contato@thebrinsider.com)",
    }

    total = 0
    erros = 0
    with httpx.Client(headers=headers, timeout=30) as client:
        for ini, fim in janelas:
            label = ini.strftime("%Y-%m")
            try:
                raw_records = _fetch_janela(client, XCMG_CNPJ, ini, fim)
                if raw_records:
                    rows = [_parse_record(r) for r in raw_records]
                    n = _upsert(supabase, rows)
                    total += n
                    logger.info("  %s → %d NFs", label, n)
            except Exception as exc:
                logger.warning("  %s → ERRO: %s", label, exc)
                erros += 1

    logger.info("XCMG concluído: %d NFs totais, %d janela(s) com erro", total, erros)


if __name__ == "__main__":
    main()
