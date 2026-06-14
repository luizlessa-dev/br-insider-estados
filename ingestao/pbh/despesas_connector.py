"""
PBH Despesas Orçamentárias Connector — The BR Insider
Fonte: ckan.pbh.gov.br — dataset despesas-orcamentarias + despesas-orcamentarias-cmbh

Colunas-chave:
  DT_MOVIMENTO; UNIDADE_ORCAMENTARIA; NUMERO_EMPENHO; FUNCAO; SUBFUNCAO;
  PROGRAMA; ACAO; ELEMENTO_DESPESA; NATUREZA_DESPESA; NOME_CREDOR;
  NUM_DOCUMENTO_CREDOR; MODALIDADE_LICITACAO; NUMERO_LICITACAO; NUMERO_EMENDA;
  VL_EMPENHADO; VL_LIQUIDADO; VL_PAGO; VL_LIQUIDADO_RESTO_PAGAR; VL_PAGO_RESTO_PAGAR

Encoding: utf-8-sig  |  Delimitador: ;
"""
from __future__ import annotations

import csv
import hashlib
import io
import logging
import time
from dataclasses import dataclass
from datetime import date, datetime
from typing import Iterator, Optional

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

logger = logging.getLogger("pbh.despesas")

ENCODING  = "utf-8-sig"
DELIMITER = ";"

_DATASET_PBH  = "8617b167-e051-4ea9-a10b-39a5f1bc97ac"
_DATASET_CMBH = "369a6120-215e-4e1c-b4de-6127daf9caf9"
_BASE = "https://ckan.pbh.gov.br/dataset"

URLS_PBH: dict[int, str] = {
    2026: f"{_BASE}/{_DATASET_PBH}/resource/10079e7b-95a4-44fe-a154-022cff8376c2/download/dados_abertos_despesas_orcamentarias_2026.csv",
    2025: f"{_BASE}/{_DATASET_PBH}/resource/34739965-f23a-4728-9e1b-aee623e8ff9b/download/dados_abertos_despesas_orcamentarias_2025.csv",
    2024: f"{_BASE}/{_DATASET_PBH}/resource/7e0f4857-6701-4b5b-ad11-43a8c639e23a/download/dados_abertos_despesas_orcamentarias_2024.csv",
    2023: f"{_BASE}/{_DATASET_PBH}/resource/4d75f3ba-9c31-4585-8dbf-eec8610a611d/download/dados_abertos_despesas_orcamentarias_2023.csv",
    2022: f"{_BASE}/{_DATASET_PBH}/resource/824cc3d5-b764-488e-a4e8-edba1736faa5/download/dados_abertos_despesas_orcamentarias_2022.csv",
    2021: f"{_BASE}/{_DATASET_PBH}/resource/9ca0d3cb-c943-43ba-ae22-a412f7128d7c/download/dados_abertos_despesas_orcamentarias_2021.csv",
    2020: f"{_BASE}/{_DATASET_PBH}/resource/ab70704d-f4c9-4e43-8464-d1516486edd1/download/dados_abertos_despesas_orcamentarias_2020.csv",
}

URL_CMBH = f"{_BASE}/{_DATASET_CMBH}/resource/8630914d-1cde-4232-9256-1a607c608ba0/download/cmbh_dados_abertos_despesas_orcamentarias.csv"

ANOS_DISPONIVEIS = sorted(URLS_PBH.keys())


@dataclass
class DespesaPBH:
    id: str
    fonte: str                          # "pbh" ou "cmbh"
    ano_exercicio: int
    dt_movimento: Optional[date]
    unidade_orcamentaria: Optional[str]
    numero_empenho: Optional[str]
    funcao: Optional[str]
    subfuncao: Optional[str]
    programa: Optional[str]
    acao: Optional[str]
    elemento_despesa: Optional[str]
    natureza_despesa: Optional[str]
    nome_credor: Optional[str]
    cnpj_cpf_credor: Optional[str]
    modalidade_licitacao: Optional[str]
    numero_licitacao: Optional[str]
    numero_emenda: Optional[str]
    exercicio_emenda: Optional[int]
    vl_empenhado: float
    vl_liquidado: float
    vl_pago: float
    vl_liquidado_resto: float
    vl_pago_resto: float


def _build_session() -> requests.Session:
    s = requests.Session()
    retry = Retry(total=3, backoff_factor=1.5, status_forcelist=[429, 500, 502, 503, 504])
    s.mount("https://", HTTPAdapter(max_retries=retry))
    s.headers["User-Agent"] = "BRInsider/1.0 (dados@thebrinsider.com)"
    return s


def _parse_float(v: str | None) -> float:
    if not v:
        return 0.0
    try:
        return float(v.replace(",", ".").replace(" ", ""))
    except ValueError:
        return 0.0


def _parse_date(v: str | None) -> Optional[date]:
    if not v:
        return None
    for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%d", "%d/%m/%Y"):
        try:
            return datetime.strptime(v[:19] if ":" in v else v[:10], fmt).date()
        except ValueError:
            continue
    return None


def _normalize_doc(v: str | None) -> Optional[str]:
    if not v:
        return None
    digits = "".join(c for c in v if c.isdigit())
    return digits if digits else None


def _extract_code(v: str | None) -> Optional[str]:
    """'2302 - FUNDO MUNICIPAL DE SAÚDE' → '2302'"""
    if not v:
        return None
    return v.split(" - ", 1)[0].strip() or None


def _make_id(fonte: str, ano: int, linha: int, empenho: str) -> str:
    key = f"{fonte}:{ano}:{empenho}:{linha}"
    return hashlib.md5(key.encode()).hexdigest()


def _stream_csv(url: str, fonte: str, ano: int,
                session: requests.Session) -> Iterator[DespesaPBH]:
    logger.info("Baixando %s (%d) de %s", fonte, ano, url)
    resp = session.get(url, stream=True, timeout=180)
    resp.raise_for_status()
    text = resp.content.decode(ENCODING, errors="replace")
    reader = csv.DictReader(io.StringIO(text), delimiter=DELIMITER)
    count = 0
    for row in reader:
        row = {k.strip().lstrip("﻿"): (v or "").strip() for k, v in row.items()}
        empenho = row.get("NUMERO_EMPENHO", "")
        rec_id  = _make_id(fonte, ano, count, empenho)

        ex_emenda_raw = row.get("EXERCICIO_EMENDA", "")
        try:
            ex_emenda = int(ex_emenda_raw) if ex_emenda_raw and ex_emenda_raw != "Não se aplica" else None
        except ValueError:
            ex_emenda = None

        yield DespesaPBH(
            id=rec_id,
            fonte=fonte,
            ano_exercicio=ano,
            dt_movimento=_parse_date(row.get("DT_MOVIMENTO")),
            unidade_orcamentaria=row.get("UNIDADE_ORCAMENTARIA"),
            numero_empenho=empenho or None,
            funcao=row.get("FUNCAO"),
            subfuncao=row.get("SUBFUNCAO"),
            programa=row.get("PROGRAMA"),
            acao=row.get("ACAO"),
            elemento_despesa=row.get("ELEMENTO_DESPESA"),
            natureza_despesa=row.get("NATUREZA_DESPESA"),
            nome_credor=row.get("NOME_CREDOR"),
            cnpj_cpf_credor=_normalize_doc(row.get("NUM_DOCUMENTO_CREDOR")),
            modalidade_licitacao=row.get("MODALIDADE_LICITACAO"),
            numero_licitacao=row.get("NUMERO_LICITACAO"),
            numero_emenda=row.get("NUMERO_EMENDA") if row.get("NUMERO_EMENDA") not in ("Não se aplica", "") else None,
            exercicio_emenda=ex_emenda,
            vl_empenhado=_parse_float(row.get("VL_EMPENHADO")),
            vl_liquidado=_parse_float(row.get("VL_LIQUIDADO")),
            vl_pago=_parse_float(row.get("VL_PAGO")),
            vl_liquidado_resto=_parse_float(row.get("VL_LIQUIDADO_RESTO_PAGAR")),
            vl_pago_resto=_parse_float(row.get("VL_PAGO_RESTO_PAGAR")),
        )
        count += 1
        if count % 100_000 == 0:
            logger.info("  %d linhas lidas…", count)

    logger.info("%s %d: %d registros extraídos", fonte.upper(), ano, count)


def stream_pbh(ano: int, session: requests.Session | None = None) -> Iterator[DespesaPBH]:
    if ano not in URLS_PBH:
        raise ValueError(f"Ano {ano} não disponível. Use: {ANOS_DISPONIVEIS}")
    sess = session or _build_session()
    yield from _stream_csv(URLS_PBH[ano], "pbh", ano, sess)


def stream_cmbh(session: requests.Session | None = None) -> Iterator[DespesaPBH]:
    """CMBH não tem separação por ano no arquivo disponível."""
    sess = session or _build_session()
    # Ano inferido do campo DT_MOVIMENTO no parse
    yield from _stream_csv(URL_CMBH, "cmbh", 0, sess)
