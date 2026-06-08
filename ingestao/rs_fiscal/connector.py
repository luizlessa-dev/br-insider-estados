"""
RS Fiscal Connector — The BR Insider
Fonte: Portal de Dados Abertos do Rio Grande do Sul — dados.rs.gov.br
Organização: Contadoria e Auditoria-Geral do Estado (CAGE/RS)

Dataset: Despesa do Estado — arquivos mensais ZIP/CSV
  Cobertura: 2012–presente (usamos 2022–atual)
  Encoding: latin-1  |  Delimitador: ;  |  Granularidade: por transação

Campos-chave para cruzamento:
  CNPJ       — cruzamento com emendas_favorecidos (key field)
  Municipio  — destino final do gasto (diferencial vs MG — já vem no CSV)
  FaseGasto  — Empenho | Liquidação | Pagamento
  ProcedimentoLicitatorio — tipo de licitação (Pregão, Dispensa, etc.)

Estratégia de ingestão:
  - CKAN API para descobrir resource_ids dinamicamente (sem hardcode por mês)
  - Download ZIP → extrai CSV → streaming linha a linha
  - Throttle entre requisições para não derrubar o portal (rate limit detectado)

Dataset slugs por ano:
  2022 → despesas-do-estado-2022
  2023 → despesas-2023
  2024 → 2024-despesas-do-estado
  2025 → 2025-despesa-do-estado
  2026 → 2026-despesa-do-estado
"""
from __future__ import annotations

import csv
import io
import logging
import time
import zipfile
from dataclasses import dataclass, field
from datetime import date, datetime
from typing import Iterator, Optional

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

logger = logging.getLogger("rs_fiscal")

ENCODING   = "latin-1"
DELIMITER  = ";"
PAGE_DELAY = 2.0   # segundos entre downloads (portal tem rate limit agressivo)

CKAN_API = "https://dados.rs.gov.br/api/3/action"

# Slugs dos datasets por ano (verificados em 2026-06-05)
_DATASET_SLUGS: dict[int, str] = {
    2022: "despesas-do-estado-2022",
    2023: "despesas-2023",
    2024: "2024-despesas-do-estado",
    2025: "2025-despesa-do-estado",
    2026: "2026-despesa-do-estado",
}


# ── Modelo ─────────────────────────────────────────────────────────────────────

@dataclass
class DespesaRS:
    """Uma linha de despesa estadual do RS."""
    id: str                          # "rs_<ano><mes>_<empenho>_<fase>"

    ano_exercicio: int
    mes: Optional[int]
    fase_gasto: Optional[str]        # Empenho | Liquidação | Pagamento
    tipo_gasto: Optional[str]

    numero_empenho: Optional[str]
    numero_processo: Optional[str]
    numero_contrato: Optional[str]

    cod_credor: Optional[str]
    favorecido: Optional[str]
    cnpj: Optional[str]              # chave de cruzamento — pode ser CPF mascarado

    orgao: Optional[str]
    uo: Optional[str]                # unidade orçamentária
    elemento: Optional[str]
    modalidade: Optional[str]
    procedimento_licitatorio: Optional[str]
    tipo_procedimento: Optional[str]

    municipio: Optional[str]         # destino do gasto — campo único vs MG
    cod_municipio: Optional[str]

    data_gasto: Optional[date]
    valor: Optional[float]

    funcao: Optional[str]
    subfuncao: Optional[str]
    programa: Optional[str]
    acao: Optional[str]


# ── HTTP session ───────────────────────────────────────────────────────────────

def _build_session() -> requests.Session:
    session = requests.Session()
    retry = Retry(
        total=4,
        backoff_factor=2.0,
        status_forcelist=[429, 500, 502, 503, 504],
        allowed_methods=["GET"],
    )
    adapter = HTTPAdapter(max_retries=retry)
    session.mount("https://", adapter)
    session.mount("http://", adapter)
    session.headers["User-Agent"] = (
        "BRInsider/1.0 (bot de dados públicos; contato@thebrinsider.com)"
    )
    return session


_session = _build_session()


# ── Helpers ────────────────────────────────────────────────────────────────────

def _parse_date(value: str | None) -> Optional[date]:
    if not value:
        return None
    for fmt in ("%d/%m/%Y", "%Y-%m-%d"):
        try:
            return datetime.strptime(value.strip(), fmt).date()
        except ValueError:
            continue
    return None


def _parse_float(value: str | None) -> Optional[float]:
    if not value:
        return None
    try:
        return float(value.strip().replace(".", "").replace(",", "."))
    except ValueError:
        return None


def _parse_int(value: str | None) -> Optional[int]:
    if not value:
        return None
    try:
        return int(value.strip())
    except ValueError:
        return None


def _clean_cnpj(value: str | None) -> Optional[str]:
    """Normaliza CNPJ/CPF para só dígitos. CPF mascarado (000.000.000-00) retorna None."""
    if not value:
        return None
    digits = "".join(c for c in value if c.isdigit())
    if len(digits) == 14:
        return digits
    # CPF: retorna como está (pode ser útil para pessoas físicas)
    if len(digits) == 11:
        return digits
    return None


# ── CKAN API ───────────────────────────────────────────────────────────────────

def _get_resources(ano: int) -> list[dict]:
    """Retorna lista de resources do dataset do ano via CKAN API."""
    slug = _DATASET_SLUGS.get(ano)
    if not slug:
        raise ValueError(f"Ano {ano} não mapeado em _DATASET_SLUGS")

    time.sleep(PAGE_DELAY)
    resp = _session.get(
        f"{CKAN_API}/package_show",
        params={"id": slug},
        timeout=30,
    )
    resp.raise_for_status()
    return resp.json()["result"]["resources"]


def _download_zip_csv(url: str) -> Iterator[dict]:
    """Baixa ZIP, extrai o CSV interno e itera linha a linha."""
    logger.info("Baixando %s", url)
    time.sleep(PAGE_DELAY)
    resp = _session.get(url, timeout=120)
    resp.raise_for_status()

    with zipfile.ZipFile(io.BytesIO(resp.content)) as z:
        csv_name = next(n for n in z.namelist() if n.lower().endswith(".csv"))
        content = z.read(csv_name).decode(ENCODING, errors="replace")

    reader = csv.DictReader(io.StringIO(content), delimiter=DELIMITER)
    yield from reader


# ── Ingestão principal ─────────────────────────────────────────────────────────

def iter_despesas(
    ano: int,
    meses: list[int] | None = None,
    apenas_pagamentos: bool = False,
) -> Iterator[DespesaRS]:
    """
    Itera despesas do ano informado, mês a mês.

    Args:
        ano: ano de exercício (2022–2026)
        meses: lista de meses a ingerir (1–12). None = todos disponíveis.
        apenas_pagamentos: se True, filtra só FaseGasto == "Pagamento"
                           (reduz volume ~3x pois cada transação tem 3 fases)
    """
    resources = _get_resources(ano)
    logger.info("RS %d: %d recursos encontrados", ano, len(resources))

    seen: set[str] = set()

    for res in resources:
        # Nome do resource contém o mês (ex: "Janeiro", "Fevereiro")
        # URL contém YYYYMM — usamos para extrair o mês
        url = res["url"]
        # Extrai YYYYMM da URL (ex: gasto-rs-202601.zip)
        import re
        match = re.search(r"(\d{6})\.zip", url, re.IGNORECASE)
        if not match:
            logger.warning("URL sem padrão YYYYMM: %s", url)
            continue

        ano_mes = match.group(1)
        mes_num = int(ano_mes[4:6])

        if meses and mes_num not in meses:
            continue

        logger.info("RS %d-%02d: baixando...", ano, mes_num)

        try:
            for row in _download_zip_csv(url):
                row = {k.strip(): (v.strip() if v else "") for k, v in row.items() if k}

                fase = row.get("FaseGasto", "")
                if apenas_pagamentos and fase != "Pagamento":
                    continue

                emp = row.get("Empenho", "")
                proc = row.get("Processo", "")
                rec_id = f"rs_{ano_mes}_{emp}_{fase[:3]}"

                if rec_id in seen:
                    continue
                seen.add(rec_id)

                yield DespesaRS(
                    id=rec_id,
                    ano_exercicio=_parse_int(row.get("Exercicio")) or ano,
                    mes=mes_num,
                    fase_gasto=fase or None,
                    tipo_gasto=row.get("TipoGasto") or None,
                    numero_empenho=emp or None,
                    numero_processo=proc or None,
                    numero_contrato=row.get("Cod_Contrato") or None,
                    cod_credor=row.get("Cod_Credor") or None,
                    favorecido=row.get("Favorecido") or None,
                    cnpj=_clean_cnpj(row.get("CNPJ")),
                    orgao=row.get("Orgao") or None,
                    uo=row.get("UO") or None,
                    elemento=row.get("Elemento") or None,
                    modalidade=row.get("Modalidade") or None,
                    procedimento_licitatorio=row.get("ProcedimentoLicitatorio") or None,
                    tipo_procedimento=row.get("TipoProcedimento") or None,
                    municipio=row.get("Municipio") or None,
                    cod_municipio=row.get("Cod_Municipio") or None,
                    data_gasto=_parse_date(row.get("Data")),
                    valor=_parse_float(row.get("Valor")),
                    funcao=row.get("Funcao") or None,
                    subfuncao=row.get("Subfuncao") or None,
                    programa=row.get("Programa") or None,
                    acao=row.get("Acao") or None,
                )

        except Exception as e:
            logger.error("RS %d-%02d: erro — %s", ano, mes_num, e)
            continue


def anos_disponiveis() -> list[int]:
    return sorted(_DATASET_SLUGS.keys())
