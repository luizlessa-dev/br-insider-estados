"""
B3 — Empresas Listadas
Fonte: sistemaswebb3-listados.b3.com.br (API pública, sem autenticação)

Endpoint único retorna ~3.400 companhias com CNPJ, ticker, segmento e status.
O payload é paginado mas o endpoint aceita page=-1 para retornar tudo de uma vez.
"""
from __future__ import annotations

import base64
import json
import logging
from dataclasses import dataclass
from datetime import date, datetime
from typing import Optional

import requests

logger = logging.getLogger("b3_connector")

BASE_URL = "https://sistemaswebb3-listados.b3.com.br/listedCompaniesProxy/CompanyCall/GetInitialCompanies"
USER_AGENT = "BRInsider/1.0 (bot de dados públicos; contato@thebrinsider.com)"


@dataclass
class EmpresaListada:
    codigo_cvm: str
    cnpj: Optional[str]
    ticker: Optional[str]
    nome_empresa: str
    nome_negociacao: Optional[str]
    segmento: Optional[str]
    segmento_en: Optional[str]
    tipo_valor: Optional[str]
    tipo_bdr: Optional[str]
    mercado: Optional[str]
    market_indicator: Optional[str]
    data_listagem: Optional[date]
    status: Optional[str]


def _parse_date(val: str) -> Optional[date]:
    if not val or val.strip() in ("", "31/12/9999"):
        return None
    for fmt in ("%d/%m/%Y", "%Y-%m-%d"):
        try:
            return datetime.strptime(val.strip(), fmt).date()
        except ValueError:
            continue
    return None


def _clean_cnpj(val: str) -> Optional[str]:
    """Remove formatação; retorna None se for '0' ou vazio."""
    cleaned = val.strip() if val else ""
    if not cleaned or cleaned == "0":
        return None
    return cleaned.replace(".", "").replace("/", "").replace("-", "")


def _build_payload(language: str = "pt-br") -> str:
    """Gera o token base64 que o endpoint espera como path param."""
    return base64.b64encode(json.dumps({"language": language}, separators=(",", ":")).encode()).decode()


def fetch_empresas(timeout: int = 30) -> list[EmpresaListada]:
    """Baixa a lista completa de empresas listadas na B3."""
    token = _build_payload()
    url = f"{BASE_URL}/{token}"

    session = requests.Session()
    session.headers.update({
        "User-Agent": (
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
            "AppleWebKit/537.36 (KHTML, like Gecko) "
            "Chrome/124.0.0.0 Safari/537.36"
        ),
        "Referer": "https://www.b3.com.br/pt_br/produtos-e-servicos/negociacao/renda-variavel/empresas-listadas.htm",
        "Origin": "https://www.b3.com.br",
        "Accept": "application/json, text/plain, */*",
    })

    logger.info("Buscando empresas listadas B3…")
    resp = session.get(url, timeout=timeout)
    resp.raise_for_status()

    data = resp.json()
    results = data.get("results", [])
    total = data.get("page", {}).get("totalRecords", len(results))
    logger.info("Recebidos %d/%d registros", len(results), total)

    empresas = []
    for row in results:
        codigo = str(row.get("codeCVM", "")).strip()
        if not codigo:
            continue
        empresas.append(EmpresaListada(
            codigo_cvm=codigo,
            cnpj=_clean_cnpj(str(row.get("cnpj", ""))),
            ticker=row.get("issuingCompany", "").strip() or None,
            nome_empresa=row.get("companyName", "").strip(),
            nome_negociacao=row.get("tradingName", "").strip() or None,
            segmento=row.get("segment", "").strip() or None,
            segmento_en=row.get("segmentEng", "").strip() or None,
            tipo_valor=str(row.get("type", "")).strip() or None,
            tipo_bdr=row.get("typeBDR", "").strip() or None,
            mercado=row.get("market", "").strip() or None,
            market_indicator=str(row.get("marketIndicator", "")).strip() or None,
            data_listagem=_parse_date(str(row.get("dateListing", ""))),
            status=row.get("status", "").strip() or None,
        ))

    logger.info("Parsed: %d empresas (%d com CNPJ)",
                len(empresas),
                sum(1 for e in empresas if e.cnpj))
    return empresas
