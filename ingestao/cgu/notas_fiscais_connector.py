"""
Notas Fiscais Eletrônicas · The Brasilia Insider

API: GET https://api.portaldatransparencia.gov.br/api-de-dados/notas-fiscais
     GET https://api.portaldatransparencia.gov.br/api-de-dados/notas-fiscais-por-chave

Autenticação: header "chave-api-dados".

Parâmetros (/notas-fiscais — todos opcionais exceto pagina):
  cnpjEmitente   — CNPJ do emitente (sem formatação)
  cnpjDestinatario
  dataEmissaoInicio / dataEmissaoFim — DD/MM/AAAA
  ufEmitente     — sigla UF
  pagina         — 1-based

Parâmetros (/notas-fiscais-por-chave):
  chaveNotaFiscal — chave de 44 dígitos

Campos retornados:
  chaveNotaFiscal (PK), numeroNotaFiscal, serieNotaFiscal,
  dataEmissao, dataProcessamento,
  emitente.{cnpj, razaoSocial, uf, municipio},
  destinatario.{cnpj, cpf, razaoSocial, uf},
  valorNota, naturezaOperacao,
  situacao.descricao

Cruzamento estratégico:
  notas_fiscais.emitente_cnpj × emendas_favorecidos.codigo_favorecido
    → NF emitida por empresa que recebeu emenda (caso Mário Frias: armaria L.D.P.)
  notas_fiscais.emitente_cnpj × sancoes.cpf_cnpj
    → NF de empresa sancionada em circulação
"""
from __future__ import annotations

import logging
import re
import time
from dataclasses import dataclass
from datetime import date, datetime
from typing import Iterator, Optional

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

logger = logging.getLogger("cgu.notas_fiscais")

BASE_URL      = "https://api.portaldatransparencia.gov.br/api-de-dados/notas-fiscais"
BASE_URL_CHAVE = "https://api.portaldatransparencia.gov.br/api-de-dados/notas-fiscais-por-chave"
PAGE_DELAY = 0.4


# ─── Modelos ──────────────────────────────────────────────────────────────────

@dataclass
class NotaFiscal:
    chave: str                     # 44 dígitos — PK
    numero: Optional[str]
    serie: Optional[str]
    data_emissao: Optional[date]
    data_processamento: Optional[date]
    emitente_cnpj: Optional[str]   # só dígitos
    emitente_razao_social: Optional[str]
    emitente_uf: Optional[str]
    emitente_municipio: Optional[str]
    destinatario_cnpj: Optional[str]
    destinatario_cpf: Optional[str]
    destinatario_razao_social: Optional[str]
    destinatario_uf: Optional[str]
    valor_nota: Optional[float]
    natureza_operacao: Optional[str]
    situacao: Optional[str]


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


def _parse_record(raw: dict) -> NotaFiscal:
    emit = raw.get("emitente") or {}
    dest = raw.get("destinatario") or {}
    sit  = raw.get("situacao") or {}
    return NotaFiscal(
        chave=raw.get("chaveNotaFiscal") or "",
        numero=raw.get("numeroNotaFiscal"),
        serie=raw.get("serieNotaFiscal"),
        data_emissao=_parse_date(raw.get("dataEmissao")),
        data_processamento=_parse_date(raw.get("dataProcessamento")),
        emitente_cnpj=_strip_digits(emit.get("cnpj")),
        emitente_razao_social=emit.get("razaoSocial"),
        emitente_uf=emit.get("uf"),
        emitente_municipio=emit.get("municipio"),
        destinatario_cnpj=_strip_digits(dest.get("cnpj")),
        destinatario_cpf=_strip_digits(dest.get("cpf")),
        destinatario_razao_social=dest.get("razaoSocial"),
        destinatario_uf=dest.get("uf"),
        valor_nota=_parse_float(raw.get("valorNota")),
        natureza_operacao=raw.get("naturezaOperacao"),
        situacao=sit.get("descricao"),
    )


# ─── Conector ─────────────────────────────────────────────────────────────────

class NotasFiscaisConnector:
    """
    Consulta notas fiscais por CNPJ emitente ou período.
    Uso principal: buscar todas as NFs emitidas por um CNPJ investigado.
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
            raise PermissionError("Chave da API inválida ou expirada.")
        resp.raise_for_status()
        data = resp.json()
        return data if isinstance(data, list) else []

    def iter_por_cnpj(self, cnpj: str,
                      data_inicio: date | None = None,
                      data_fim: date | None = None) -> Iterator[NotaFiscal]:
        """Itera sobre todas as NFs emitidas por um CNPJ."""
        cnpj_digits = _strip_digits(cnpj) or cnpj
        params: dict = {"cnpjEmitente": cnpj_digits}
        if data_inicio:
            params["dataEmissaoInicio"] = data_inicio.strftime("%d/%m/%Y")
        if data_fim:
            params["dataEmissaoFim"] = data_fim.strftime("%d/%m/%Y")
        pagina = 1
        total = 0
        while True:
            records = self._fetch_page(pagina, **params)
            if not records:
                break
            for r in records:
                yield _parse_record(r)
                total += 1
            pagina += 1
        logger.info("NFs CNPJ %s: %d registros", cnpj_digits, total)

    def iter_por_periodo(self, data_inicio: date, data_fim: date,
                         uf: str | None = None) -> Iterator[NotaFiscal]:
        """Itera sobre NFs de um período, opcionalmente filtrado por UF."""
        params: dict = {
            "dataEmissaoInicio": data_inicio.strftime("%d/%m/%Y"),
            "dataEmissaoFim":    data_fim.strftime("%d/%m/%Y"),
        }
        if uf:
            params["ufEmitente"] = uf.upper()
        pagina = 1
        total = 0
        while True:
            records = self._fetch_page(pagina, **params)
            if not records:
                break
            for r in records:
                yield _parse_record(r)
                total += 1
            pagina += 1
        logger.info("NFs %s→%s: %d registros", data_inicio, data_fim, total)

    def fetch_por_chave(self, chave: str) -> NotaFiscal | None:
        """Busca NF pela chave de 44 dígitos."""
        self._throttle()
        resp = self.session.get(BASE_URL_CHAVE, params={"chaveNotaFiscal": chave}, timeout=30)
        if resp.status_code == 404:
            return None
        resp.raise_for_status()
        raw = resp.json()
        if isinstance(raw, list):
            return _parse_record(raw[0]) if raw else None
        return _parse_record(raw) if raw else None

    def iter_cnpjs_investigados(self, cnpjs: list[str]) -> Iterator[NotaFiscal]:
        """Busca NFs para uma lista de CNPJs investigados (ex: casos Mário Frias, XCMG)."""
        for cnpj in cnpjs:
            logger.info("Buscando NFs para CNPJ %s", cnpj)
            yield from self.iter_por_cnpj(cnpj)
