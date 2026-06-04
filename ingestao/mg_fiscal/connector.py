"""
MG Fiscal Connector — The BR Insider
Fonte: Portal de Dados Abertos de Minas Gerais — dados.mg.gov.br
Organização: Secretaria de Estado de Fazenda (SEF/MG)

Datasets ingeridos (todos CSV público, sem autenticação):
  empenho     — despesa por empenho, 2022–ano_atual
                campos: CNPJ/CPF + razão social do credor, elemento de despesa,
                        valores empenhado/liquidado/pago
  contratos   — contratos + itens, 2022–ano_atual
  convenios   — convênios de saída (repasse estado→município/entidade), diário

Estratégia de ingestão:
  - Download direto de CSV por ano (sem paginação; arquivos ~10–80 MB)
  - Encoding UTF-8 (verificado no datapackage.json)
  - Delimitador vírgula padrão (frictionless)
  - Streaming linha a linha para não explodir RAM

Atualização das fontes: semanal (empenho/contratos), diária (convênios).

URLs canônicas (obtidas via datapackage.json):
  https://dados.mg.gov.br/dataset/portal_despesa_empenho
  https://dados.mg.gov.br/dataset/portal_contratos
  https://dados.mg.gov.br/dataset/convenios-saida
"""
from __future__ import annotations

import csv
import io
import logging
import time
from dataclasses import dataclass, field
from datetime import date, datetime
from typing import Iterator, Optional

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

logger = logging.getLogger("mg_fiscal")

# ── URLs de download direto (confirmadas via datapackage.json em 2026-06-04) ──
_EMPENHO_URL = (
    "https://dados.mg.gov.br/dataset/8a9482f1-8d9e-49bd-8c58-d1574cb2843b"
    "/resource/{resource_id}/download/empenho{ano}.csv"
)

# Resource IDs por ano (do datapackage.json)
_EMPENHO_RESOURCE_IDS: dict[int, str] = {
    2022: "c8757609-bd2e-4864-a75e-f39c72d025f4",
    2023: "ab2a08af-7db8-407a-a4b4-a91e942eef55",
    2024: "38eafdd6-bc1e-4bf9-bc39-bf5842380d6c",
    2025: "2ef02d2b-655e-44a0-aaeb-bdac5c222871",
    2026: "c5edcee8-e67f-4352-b499-d578625669b4",
}

# Contratos: IDs obtidos via página do dataset (padrão igual ao empenho)
_CONTRATOS_BASE = "https://dados.mg.gov.br/dataset/portal_contratos"

# Para convênios de saída o arquivo principal é o fato central
_CONVENIOS_SAIDA_URL = (
    "https://dados.mg.gov.br/dataset/convenios-saida"
    "/resource/{resource_id}/download/convenio-saida.csv.gz"
)

ENCODING = "utf-8-sig"   # utf-8-sig remove BOM automaticamente
DELIMITER = ";"          # CSVs do dados.mg.gov.br usam ponto-e-vírgula
PAGE_DELAY = 0.3


# ── Modelos ────────────────────────────────────────────────────────────────────

@dataclass
class Empenho:
    """Representa uma linha do CSV de empenho estadual MG."""
    id: str                              # "<ano>_<unidade_codigo>_<numero_empenho>"
    ano_exercicio: int
    unidade_orcamentaria_codigo: Optional[int]
    unidade_orcamentaria_sigla: Optional[str]
    unidade_orcamentaria_nome: Optional[str]
    ano_empenho: Optional[int]
    numero_empenho: Optional[int]
    data_registro: Optional[date]
    numero_processo_compra: Optional[str]
    elemento_despesa_codigo: Optional[int]
    elemento_despesa_descricao: Optional[str]
    item_despesa_codigo: Optional[int]
    item_despesa_descricao: Optional[str]
    fonte_recurso_codigo: Optional[int]
    fonte_recurso_descricao: Optional[str]
    razao_social_credor: Optional[str]
    cnpj_cpf_credor: Optional[str]       # chave de cruzamento com emendas_favorecidos
    valor_empenhado: Optional[float]
    valor_liquidado: Optional[float]
    valor_pago: Optional[float]


@dataclass
class Contrato:
    """Representa um contrato do Portal da Transparência MG."""
    id: str                              # gerado pelo conector
    ano: int
    numero_contrato: Optional[str]
    orgao_nome: Optional[str]
    fornecedor_nome: Optional[str]
    cnpj_cpf_fornecedor: Optional[str]
    objeto: Optional[str]
    valor_inicial: Optional[float]
    data_inicio_vigencia: Optional[date]
    data_fim_vigencia: Optional[date]
    situacao: Optional[str]
    raw: dict = field(default_factory=dict)


# ── HTTP session com retry ─────────────────────────────────────────────────────

def _build_session() -> requests.Session:
    session = requests.Session()
    retry = Retry(
        total=4,
        backoff_factor=1.5,
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


# ── Helpers internos ───────────────────────────────────────────────────────────

def _parse_date(value: str | None) -> Optional[date]:
    if not value:
        return None
    for fmt in ("%Y-%m-%d", "%d/%m/%Y"):
        try:
            return datetime.strptime(value.strip(), fmt).date()
        except ValueError:
            continue
    return None


def _parse_float(value: str | None) -> Optional[float]:
    if not value:
        return None
    try:
        # CSV usa ponto como separador decimal (padrão frictionless)
        return float(value.strip().replace(",", "."))
    except ValueError:
        return None


def _parse_int(value: str | None) -> Optional[int]:
    if not value:
        return None
    try:
        return int(value.strip())
    except ValueError:
        return None


def _stream_csv(url: str, encoding: str = ENCODING) -> Iterator[dict]:
    """Baixa e itera linha a linha sem carregar tudo na memória."""
    logger.info("Baixando %s", url)
    time.sleep(PAGE_DELAY)
    resp = _session.get(url, stream=True, timeout=120)
    resp.raise_for_status()
    # Descomprime gzip automaticamente via requests se Content-Encoding: gzip
    content = resp.content
    try:
        text = content.decode(encoding)
    except UnicodeDecodeError:
        text = content.decode("latin-1")
    # Remove BOM residual se encoding não for utf-8-sig
    if text.startswith("﻿"):
        text = text[1:]
    reader = csv.DictReader(io.StringIO(text), delimiter=DELIMITER)
    yield from reader


# ── Empenho ────────────────────────────────────────────────────────────────────

def _empenho_url(ano: int) -> str:
    resource_id = _EMPENHO_RESOURCE_IDS.get(ano)
    if not resource_id:
        raise ValueError(f"Ano {ano} não mapeado em _EMPENHO_RESOURCE_IDS")
    return _EMPENHO_URL.format(resource_id=resource_id, ano=ano)


def iter_empenhos(ano: int) -> Iterator[Empenho]:
    """
    Itera empenhos do ano informado, linha a linha (streaming).
    Campos-chave para cruzamento com emendas federais:
      cnpj_cpf_credor — idêntico ao cnpj em emendas_favorecidos
    """
    url = _empenho_url(ano)
    seen: set[str] = set()

    for row in _stream_csv(url):
        # Normaliza chaves (o CSV pode ter espaços nos headers)
        row = {k.strip(): v.strip() for k, v in row.items() if k}

        ano_ex = _parse_int(row.get("ano_de_exercicio")) or ano
        uo_cod = _parse_int(row.get("unidade_orcamentaria_codigo"))
        num_emp = _parse_int(row.get("numero_empenho"))

        emp_id = f"mg_{ano_ex}_{uo_cod}_{num_emp}"
        # Evita duplicatas dentro do mesmo CSV (edge case em arquivos cumulativos)
        if emp_id in seen:
            continue
        seen.add(emp_id)

        yield Empenho(
            id=emp_id,
            ano_exercicio=ano_ex,
            unidade_orcamentaria_codigo=uo_cod,
            unidade_orcamentaria_sigla=row.get("unidade_orcamentaria_sigla") or None,
            unidade_orcamentaria_nome=row.get("unidade_orcamentaria_nome") or None,
            ano_empenho=_parse_int(row.get("ano_empenho")),
            numero_empenho=num_emp,
            data_registro=_parse_date(row.get("data_registro_doc_empenho")),
            numero_processo_compra=row.get("numero_processo_compra_siad") or None,
            elemento_despesa_codigo=_parse_int(row.get("elemento_despesa_codigo")),
            elemento_despesa_descricao=row.get("elemento_despesa_descricao") or None,
            item_despesa_codigo=_parse_int(row.get("item_despesa_codigo")),
            item_despesa_descricao=row.get("item_despesa_descricao") or None,
            fonte_recurso_codigo=_parse_int(row.get("fonte_recurso_codigo")),
            fonte_recurso_descricao=row.get("fonte_recurso_descricao") or None,
            razao_social_credor=row.get("razao_social_credor") or None,
            cnpj_cpf_credor=row.get("cnpj_cpf_credor_formatado") or None,
            valor_empenhado=_parse_float(row.get("valor_despesa_empenhada")),
            valor_liquidado=_parse_float(row.get("valor_despesa_liquidada")),
            valor_pago=_parse_float(row.get("valor_pago_financeiro")),
        )


def anos_disponiveis() -> list[int]:
    """Retorna os anos com resource_id mapeado."""
    return sorted(_EMPENHO_RESOURCE_IDS.keys())
