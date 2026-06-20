"""
Emendas Parlamentares via API · The Brasilia Insider

APIs utilizadas:
  GET /api-de-dados/emendas                    — lista paginada de emendas
  GET /api-de-dados/emendas/documentos/{codigo} — documentos/empenhos vinculados a uma emenda

Autenticação: header "chave-api-dados".

DIFERENÇA vs CSV (emendas_favorecidos):
  - CSV: favorecidos com CNPJ e valores recebidos (agregado por transação)
  - API: estrutura completa da emenda (autor, tipo, função, subfunção, localização)
         + documentos vinculados (empenhos SIAFI, liquidações, pagamentos)
  Junção: emendas_api.codigo_emenda = emendas_favorecidos.codigo_emenda

Parâmetros (/emendas):
  codigoEmenda   — código da emenda (ex: "20249999")
  nomeAutor      — nome parcial do parlamentar
  codigoAutor    — código do autor
  tipoEmenda     — IND/COL/BAN/REL
  anoEmenda      — ano de apresentação (AAAA)
  pagina         — 1-based

Campos retornados:
  codigo, ano, tipo, subtipo,
  autor.{nome, cpf, siglaPartido, ufRepresentacao, codigoPortal},
  funcao.{codigo, descricao},
  subfuncao.{codigo, descricao},
  localidadeGasto.{ibge, descricao},
  valorEmpenhado, valorLiquidado, valorPago,
  valorRestoAPagar,
  codigoEmenda (chave de cruzamento com CSV)

Campos (/documentos/{codigo}):
  lista de empenhos/documentos SIAFI vinculados à emenda:
  codigo, tipo, data, valor, orgao, acao, favorecido

Cruzamento estratégico:
  emendas_api.codigo_emenda = emendas_favorecidos.codigo_emenda
    → liga autor + função + localidade ao favorecido e valor recebido
  emendas_api.autor_cpf × tse_candidatos.cpf
    → parlamentar que indicou emenda × financiamento de campanha
  emendas_api.documentos × siafi_empenho
    → rastrear empenho individual até o favorecido final
"""
from __future__ import annotations

import logging
import re
import time
from dataclasses import dataclass, field
from datetime import date, datetime
from typing import Iterator, Optional

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

logger = logging.getLogger("cgu.emendas_api")

BASE_URL       = "https://api.portaldatransparencia.gov.br/api-de-dados/emendas"
BASE_URL_DOCS  = "https://api.portaldatransparencia.gov.br/api-de-dados/emendas/documentos"

FIRST_YEAR = 2014   # emendas têm dados consistentes a partir de 2014
PAGE_DELAY = 0.4


# ─── Modelos ──────────────────────────────────────────────────────────────────

@dataclass
class DocumentoEmenda:
    emenda_codigo: str
    codigo_documento: Optional[str]
    tipo_documento: Optional[str]
    data: Optional[date]
    valor: Optional[float]
    orgao: Optional[str]
    acao: Optional[str]
    favorecido_cnpj: Optional[str]
    favorecido_nome: Optional[str]


@dataclass
class EmendaApi:
    codigo: str                       # PK — chave de cruzamento com CSV
    ano: Optional[int]
    tipo: Optional[str]               # IND / COL / BAN / REL
    subtipo: Optional[str]
    autor_nome: Optional[str]
    autor_cpf: Optional[str]          # só dígitos
    autor_partido: Optional[str]
    autor_uf: Optional[str]
    autor_codigo_portal: Optional[str]
    funcao_codigo: Optional[str]
    funcao_descricao: Optional[str]
    subfuncao_codigo: Optional[str]
    subfuncao_descricao: Optional[str]
    localidade_ibge: Optional[str]
    localidade_descricao: Optional[str]
    valor_empenhado: Optional[float]
    valor_liquidado: Optional[float]
    valor_pago: Optional[float]
    valor_resto_pagar: Optional[float]
    documentos: list[DocumentoEmenda] = field(default_factory=list)


# ─── Utilitários ──────────────────────────────────────────────────────────────

def _strip_digits(v: str | None) -> Optional[str]:
    if not v:
        return None
    d = re.sub(r"\D", "", v.strip())
    return d or None


def _parse_date(v: str | None) -> Optional[date]:
    if not v:
        return None
    for fmt in ("%d/%m/%Y", "%Y-%m-%d"):
        try:
            return datetime.strptime(v.strip()[:10], fmt).date()
        except ValueError:
            continue
    return None


def _parse_float(v) -> Optional[float]:
    if v is None:
        return None
    try:
        return float(str(v).replace(",", "."))
    except (ValueError, TypeError):
        return None


def _build_session(api_key: str) -> requests.Session:
    session = requests.Session()
    retry = Retry(
        total=5, backoff_factor=2.0,
        status_forcelist=[429, 500, 502, 503, 504],
        allowed_methods=["GET"],
    )
    session.mount("https://", HTTPAdapter(max_retries=retry))
    session.headers.update({
        "chave-api-dados": api_key,
        "Accept": "application/json",
        "User-Agent": "BRInsider/1.0 (contato@thebrinsider.com)",
    })
    return session


def _parse_record(raw: dict) -> EmendaApi:
    autor   = raw.get("autor") or {}
    funcao  = raw.get("funcao") or {}
    subfunc = raw.get("subfuncao") or {}
    local   = raw.get("localidadeGasto") or {}

    return EmendaApi(
        codigo=str(raw.get("codigoEmenda") or raw.get("codigo") or ""),
        ano=raw.get("anoEmenda") or raw.get("ano"),
        tipo=raw.get("tipoEmenda") or raw.get("tipo"),
        subtipo=raw.get("subtipo"),
        autor_nome=autor.get("nome"),
        autor_cpf=_strip_digits(autor.get("cpf")),
        autor_partido=autor.get("siglaPartido"),
        autor_uf=autor.get("ufRepresentacao"),
        autor_codigo_portal=str(autor.get("codigoPortal")) if autor.get("codigoPortal") else None,
        funcao_codigo=str(funcao.get("codigo")) if funcao.get("codigo") else None,
        funcao_descricao=funcao.get("descricao"),
        subfuncao_codigo=str(subfunc.get("codigo")) if subfunc.get("codigo") else None,
        subfuncao_descricao=subfunc.get("descricao"),
        localidade_ibge=str(local.get("ibge")) if local.get("ibge") else None,
        localidade_descricao=local.get("descricao"),
        valor_empenhado=_parse_float(raw.get("valorEmpenhado")),
        valor_liquidado=_parse_float(raw.get("valorLiquidado")),
        valor_pago=_parse_float(raw.get("valorPago")),
        valor_resto_pagar=_parse_float(raw.get("valorRestoAPagar")),
    )


def _parse_documento(raw: dict, emenda_codigo: str) -> DocumentoEmenda:
    fav = raw.get("favorecido") or {}
    return DocumentoEmenda(
        emenda_codigo=emenda_codigo,
        codigo_documento=raw.get("codigo"),
        tipo_documento=raw.get("tipo"),
        data=_parse_date(raw.get("data")),
        valor=_parse_float(raw.get("valor")),
        orgao=raw.get("orgao"),
        acao=raw.get("acao"),
        favorecido_cnpj=_strip_digits(fav.get("cnpj") or fav.get("cpf")),
        favorecido_nome=fav.get("nome"),
    )


# ─── Conector ─────────────────────────────────────────────────────────────────

class EmendasApiConnector:
    """
    Itera emendas via API com janelas anuais.
    Complementa emendas_favorecidos (CSV) com metadados de autor e função.
    """

    def __init__(self, api_key: str) -> None:
        if not api_key:
            raise ValueError("PORTAL_TRANSPARENCIA_API_KEY é obrigatória.")
        self.session = _build_session(api_key)
        self._last_req: float = 0.0

    def _throttle(self) -> None:
        elapsed = time.monotonic() - self._last_req
        if elapsed < PAGE_DELAY:
            time.sleep(PAGE_DELAY - elapsed)
        self._last_req = time.monotonic()

    def _fetch_page(self, pagina: int, **params) -> list[dict]:
        self._throttle()
        params["pagina"] = pagina
        resp = self.session.get(BASE_URL, params=params, timeout=45)
        if resp.status_code == 401:
            raise PermissionError("Chave da API inválida.")
        resp.raise_for_status()
        data = resp.json()
        return data if isinstance(data, list) else []

    def _iter_ano(self, ano: int) -> Iterator[EmendaApi]:
        pagina = 1
        total = 0
        while True:
            records = self._fetch_page(pagina, anoEmenda=ano)
            if not records:
                break
            for r in records:
                yield _parse_record(r)
                total += 1
            logger.debug("Emendas %d: pág %d → %d acumulados", ano, pagina, total)
            pagina += 1
        if total:
            logger.info("Emendas %d: %d registros", ano, total)

    def iter_all(self, ano_inicio: int = FIRST_YEAR) -> Iterator[EmendaApi]:
        """Itera todas as emendas (histórico por ano)."""
        ano_fim = datetime.utcnow().year
        for ano in range(ano_inicio, ano_fim + 1):
            yield from self._iter_ano(ano)

    def iter_por_ano(self, ano: int) -> Iterator[EmendaApi]:
        """Itera emendas de um ano específico."""
        yield from self._iter_ano(ano)

    def iter_por_autor(self, codigo_autor: str,
                       ano: int | None = None) -> Iterator[EmendaApi]:
        """Busca emendas de um parlamentar específico."""
        params: dict = {"codigoAutor": codigo_autor}
        if ano:
            params["anoEmenda"] = ano
        pagina = 1
        while True:
            records = self._fetch_page(pagina, **params)
            if not records:
                break
            for r in records:
                yield _parse_record(r)
            pagina += 1

    def fetch_documentos(self, emenda_codigo: str) -> list[DocumentoEmenda]:
        """Busca documentos/empenhos SIAFI vinculados a uma emenda."""
        self._throttle()
        resp = self.session.get(f"{BASE_URL_DOCS}/{emenda_codigo}", timeout=30)
        if resp.status_code == 404:
            return []
        resp.raise_for_status()
        data = resp.json()
        if not isinstance(data, list):
            return []
        return [_parse_documento(d, emenda_codigo) for d in data]

    def enrich_documentos(self, emendas: Iterator[EmendaApi]) -> Iterator[EmendaApi]:
        """Enriquece emendas com seus documentos SIAFI (uso investigativo, mais lento)."""
        for e in emendas:
            if e.codigo:
                e.documentos = self.fetch_documentos(e.codigo)
            yield e
