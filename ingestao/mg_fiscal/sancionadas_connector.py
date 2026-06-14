"""
MG Empresas Sancionadas Connector — The BR Insider
Fonte: Portal de Dados Abertos de MG — dados.mg.gov.br
Dataset: empresas_sancionadas (ee4722fd-d58c-4c31-a065-1ed2490ee015)

Lei Anticorrupção estadual MG (Lei 14.184/2002 e federal 12.846/2013).
Permite cruzar CNPJ com fornecedores de emendas, contratos e cota parlamentar.

Encoding: utf-8-sig  |  Delimitador: ;  |  Atualização: eventual
"""
from __future__ import annotations

import csv
import io
import logging
from dataclasses import dataclass
from datetime import date, datetime
from typing import Iterator, Optional

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

logger = logging.getLogger("mg_fiscal.sancionadas")

ENCODING  = "utf-8-sig"
DELIMITER = ";"

_DATASET_ID = "ee4722fd-d58c-4c31-a065-1ed2490ee015"
URL = (
    f"https://dados.mg.gov.br/dataset/{_DATASET_ID}"
    "/resource/f65853bb-4298-4456-a388-736fa9ff5d62"
    "/download/empresas_sancionadas.csv"
)


@dataclass
class EmpresaSancionadaMG:
    id: str                         # sei ou numero_ano
    sei: Optional[str]
    numero: Optional[str]
    ano: Optional[int]
    portaria: Optional[str]
    data_publicacao_portaria: Optional[date]
    orgao_instaurador: Optional[str]
    orgao_lesado: Optional[str]
    empresa: Optional[str]
    tipo_societario: Optional[str]
    cnpj: Optional[str]             # 14 dígitos normalizados
    conduta: Optional[str]
    data_decisao: Optional[date]
    decisao: Optional[str]
    fase: Optional[str]
    valor_multa: float


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
    digits = "".join(c for c in v if c.isdigit())
    return digits if digits else None


def stream_sancionadas(session: requests.Session | None = None) -> Iterator[EmpresaSancionadaMG]:
    sess = session or _build_session()
    logger.info("Baixando empresas sancionadas MG de %s", URL)
    resp = sess.get(URL, timeout=30)
    resp.raise_for_status()
    text = resp.content.decode(ENCODING, errors="replace")

    reader = csv.DictReader(io.StringIO(text), delimiter=DELIMITER)
    count = 0
    for row in reader:
        row = {k.strip().lstrip("﻿"): (v or "").strip() for k, v in row.items()}
        sei = row.get("sei") or ""
        num = row.get("numero") or ""
        ano_raw = row.get("ano") or ""
        try:
            ano = int(ano_raw)
        except (ValueError, TypeError):
            ano = None

        rec_id = sei or f"{ano}_{num}_{count}"

        yield EmpresaSancionadaMG(
            id=rec_id,
            sei=sei or None,
            numero=num or None,
            ano=ano,
            portaria=row.get("portaria"),
            data_publicacao_portaria=_parse_date(row.get("data_publicacao_portaria")),
            orgao_instaurador=row.get("orgao_instaurador"),
            orgao_lesado=row.get("orgao_lesado"),
            empresa=row.get("empresas_processadas"),
            tipo_societario=row.get("tipo_societario"),
            cnpj=_normalize_cnpj(row.get("cnpj")),
            conduta=row.get("conduta"),
            data_decisao=_parse_date(row.get("data_publicacao_decisao")),
            decisao=row.get("decisao"),
            fase=row.get("fase"),
            valor_multa=_parse_float(row.get("valor_multa_aplicada")),
        )
        count += 1

    logger.info("Empresas sancionadas MG: %d registros", count)
