"""
MG Emendas Federais Connector — The BR Insider
Fonte: Portal de Dados Abertos de MG — dados.mg.gov.br
Dataset: emendas_federais (fece3d93-2fd6-46c6-862c-55f3a26924dd)

Arquivos:
  dados_gerais_emendas.csv     — cabeçalho das emendas (modalidade, valor, objeto)
  execucao_transferencias_especiais_pix.csv — emendas PIX executadas
  plano_execucao_emendas_pix.csv            — plano de aplicação

Encoding: utf-8-sig  |  Delimitador: ;

Permite cruzamento: numero_emenda × emendas_favorecidos federal (BR Insider)
"""
from __future__ import annotations

import csv
import io
import logging
import time
from dataclasses import dataclass
from datetime import date, datetime
from typing import Iterator, Optional

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

logger = logging.getLogger("mg_fiscal.emendas")

ENCODING  = "utf-8-sig"
DELIMITER = ";"

_DATASET_ID = "fece3d93-2fd6-46c6-862c-55f3a26924dd"
_BASE = f"https://dados.mg.gov.br/dataset/{_DATASET_ID}/resource"

URLS = {
    "dados_gerais":     f"{_BASE}/b39077cb-dd51-4f3b-8743-d4f4b7221b92/download/dados_gerais_emendas.csv",
    "execucao_pix":     f"{_BASE}/159dfb4d-653d-44f9-807b-65e74995cb96/download/execucao_transferencias_especiais_pix.csv",
    "plano_pix":        f"{_BASE}/0ab41a72-80b5-4173-a837-4bc0150fa90b/download/plano_execucao_emendas_pix.csv",
}


@dataclass
class EmendaMG:
    # Schema real da tabela mg_emendas_federais (criada em jun/2026)
    id: str
    esfera: Optional[str]
    modalidade: Optional[str]
    autoria: Optional[str]           # coluna é "autoria" não "autoridade"
    tipo_instrumento: Optional[str]
    numero_emenda: Optional[str]
    ano: Optional[int]               # coluna é "ano" não "ano_emenda"
    codigo_siafi: Optional[str]
    codigo_sigcon: Optional[str]
    valor_indicado: float
    valor_repassado: float
    objeto: Optional[str]
    funcao_governo: Optional[str]
    orgao_executor: Optional[str]


@dataclass
class ExecucaoPIX:
    id: str
    numero_emenda: Optional[str]
    ano: Optional[int]               # coluna é "ano"
    cnpj_favorecido: Optional[str]
    nome_favorecido: Optional[str]
    municipio: Optional[str]
    valor_pago: float
    data_pagamento: Optional[date]
    objeto: Optional[str]


def _build_session() -> requests.Session:
    s = requests.Session()
    retry = Retry(total=3, backoff_factor=1.0, status_forcelist=[429, 500, 502, 503, 504])
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
    for fmt in ("%Y-%m-%d", "%d/%m/%Y"):
        try:
            return datetime.strptime(v[:10], fmt).date()
        except ValueError:
            continue
    return None


def _normalize_cnpj(v: str | None) -> Optional[str]:
    if not v:
        return None
    return "".join(c for c in v if c.isdigit()) or None


def _fetch_csv(url: str, session: requests.Session) -> list[dict]:
    logger.info("Baixando %s", url)
    resp = session.get(url, timeout=60)
    resp.raise_for_status()
    text = resp.content.decode(ENCODING, errors="replace")
    reader = csv.DictReader(io.StringIO(text), delimiter=DELIMITER)
    rows = []
    for row in reader:
        rows.append({k.strip().lstrip("﻿"): (v or "").strip() for k, v in row.items()})
    logger.info("  %d linhas lidas", len(rows))
    return rows


def stream_emendas(session: requests.Session | None = None) -> Iterator[EmendaMG]:
    sess = session or _build_session()
    rows = _fetch_csv(URLS["dados_gerais"], sess)
    for i, row in enumerate(rows):
        ano_raw = row.get("ano_emenda", "")
        try:
            ano = int(ano_raw)
        except (ValueError, TypeError):
            ano = None
        num = row.get("numero_emenda", "")
        yield EmendaMG(
            id=f"{ano}_{num}" if ano else f"0_{i}",
            esfera=row.get("esfera"),
            modalidade=row.get("modalide") or row.get("modalidade"),
            autoria=row.get("autorida") or row.get("autoridade"),
            tipo_instrumento=row.get("tipo_instrumento_juridico"),
            numero_emenda=num or None,
            ano=ano,
            codigo_siafi=row.get("codigo_siafi"),
            codigo_sigcon=row.get("codigo_sigcon_entrada"),
            valor_indicado=_parse_float(row.get("valor_indicado")),
            valor_repassado=_parse_float(row.get("valor_repassado")),
            objeto=row.get("objeto"),
            funcao_governo=row.get("funcao_governo"),
            orgao_executor=row.get("orgao_executor"),
        )


def stream_execucao_pix(session: requests.Session | None = None) -> Iterator[ExecucaoPIX]:
    sess = session or _build_session()
    rows = _fetch_csv(URLS["execucao_pix"], sess)
    for i, row in enumerate(rows):
        ano_raw = row.get("ano_emenda", "")
        try:
            ano = int(ano_raw)
        except (ValueError, TypeError):
            ano = None
        num = row.get("numero_emenda", "")
        yield ExecucaoPIX(
            id=f"pix_{ano}_{num}_{i}",
            numero_emenda=num or None,
            ano=ano,
            cnpj_favorecido=_normalize_cnpj(row.get("cnpj_favorecido") or row.get("cnpj")),
            nome_favorecido=row.get("nome_favorecido") or row.get("razao_social"),
            municipio=row.get("municipio") or row.get("nome_municipio"),
            valor_pago=_parse_float(row.get("valor_pago") or row.get("valor")),
            data_pagamento=_parse_date(row.get("data_pagamento") or row.get("data")),
            objeto=row.get("objeto"),
        )
