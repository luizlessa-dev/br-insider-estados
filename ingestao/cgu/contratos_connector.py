"""
Contratos do Poder Executivo Federal · The Brasilia Insider

APIs utilizadas:
  GET /api-de-dados/contratos/cpf-cnpj   — contratos por fornecedor (CNPJ/CPF)
  GET /api-de-dados/contratos            — todos os contratos (filtros: órgão, período)
  GET /api-de-dados/contratos/id         — contrato específico pelo ID
  GET /api-de-dados/contratos/itens-contratados — itens de um contrato
  GET /api-de-dados/contratos/termo-aditivo     — termos aditivos

Autenticação: header "chave-api-dados".

Parâmetros principais (/contratos/cpf-cnpj):
  cpfOuCnpj   — CPF ou CNPJ do fornecedor (sem formatação)
  pagina      — 1-based

Parâmetros (/contratos):
  dataInicioVigencia / dataFimVigencia — DD/MM/AAAA
  codigoOrgao
  pagina

Campos retornados:
  id, numero, objeto, dataAssinatura, dataPublicacaoTcu,
  dataInicioVigencia, dataFimVigencia,
  valor, valorAditivos, valorTotal,
  situacao.{codigo, descricao},
  fornecedor.{cnpj, cpf, nome, razaoSocial},
  unidadeGestora.{codigo, descricao, orgao.{codigo, descricao, siglaPoder}},
  modalidadeCompra.{codigo, descricao},
  tipoContrato.descricao,
  licitacao.{numero, modalidade}

Cruzamento estratégico:
  contratos.fornecedor_cnpj × emendas_favorecidos.codigo_favorecido
    → empresa recebeu emenda E tem contrato direto (XCMG: R$ 311M)
  contratos.fornecedor_cnpj × sancoes.cpf_cnpj
    → contrato com empresa sancionada
  contratos.fornecedor_cnpj × tse_receitas.cnpj_doador
    → fornecedor que doou para campanha do parlamentar que indicou emenda
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

logger = logging.getLogger("cgu.contratos")

BASE_URL         = "https://api.portaldatransparencia.gov.br/api-de-dados/contratos"
BASE_URL_CNPJ    = "https://api.portaldatransparencia.gov.br/api-de-dados/contratos/cpf-cnpj"
BASE_URL_ID      = "https://api.portaldatransparencia.gov.br/api-de-dados/contratos/id"
BASE_URL_ITENS   = "https://api.portaldatransparencia.gov.br/api-de-dados/contratos/itens-contratados"
BASE_URL_ADITIVO = "https://api.portaldatransparencia.gov.br/api-de-dados/contratos/termo-aditivo"

PAGE_DELAY = 0.4


# ─── Modelos ──────────────────────────────────────────────────────────────────

@dataclass
class ItemContratado:
    descricao: Optional[str]
    quantidade: Optional[float]
    unidade: Optional[str]
    valor_unitario: Optional[float]
    valor_total: Optional[float]


@dataclass
class Contrato:
    id: int                          # PK da API
    numero: Optional[str]
    objeto: Optional[str]
    data_assinatura: Optional[date]
    data_publicacao_tcu: Optional[date]
    data_inicio_vigencia: Optional[date]
    data_fim_vigencia: Optional[date]
    valor: Optional[float]
    valor_aditivos: Optional[float]
    valor_total: Optional[float]
    situacao_codigo: Optional[str]
    situacao_descricao: Optional[str]
    fornecedor_cnpj: Optional[str]   # só dígitos
    fornecedor_cpf: Optional[str]
    fornecedor_nome: Optional[str]
    fornecedor_razao_social: Optional[str]
    ug_codigo: Optional[str]
    ug_descricao: Optional[str]
    orgao_codigo: Optional[str]
    orgao_descricao: Optional[str]
    orgao_poder: Optional[str]
    modalidade_codigo: Optional[str]
    modalidade_descricao: Optional[str]
    tipo_contrato: Optional[str]
    licitacao_numero: Optional[str]
    licitacao_modalidade: Optional[str]
    itens: list[ItemContratado] = field(default_factory=list)


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


def _parse_record(raw: dict) -> Contrato:
    forn  = raw.get("fornecedor") or {}
    ug    = raw.get("unidadeGestora") or {}
    orgao = ug.get("orgaoVinculado") or {}
    orgao_max = ug.get("orgaoMaximo") or {}
    compra = raw.get("compra") or {}

    return Contrato(
        id=raw.get("id"),
        numero=raw.get("numero"),
        objeto=raw.get("objeto"),
        data_assinatura=_parse_date(raw.get("dataAssinatura")),
        data_publicacao_tcu=_parse_date(raw.get("dataPublicacaoDOU")),
        data_inicio_vigencia=_parse_date(raw.get("dataInicioVigencia")),
        data_fim_vigencia=_parse_date(raw.get("dataFimVigencia")),
        valor=_parse_float(raw.get("valorInicialCompra")),
        valor_aditivos=None,
        valor_total=_parse_float(raw.get("valorFinalCompra")),
        situacao_codigo=None,
        situacao_descricao=raw.get("situacaoContrato"),
        fornecedor_cnpj=_strip_digits(forn.get("cnpjFormatado")),
        fornecedor_cpf=_strip_digits(forn.get("cpfFormatado")),
        fornecedor_nome=forn.get("nome"),
        fornecedor_razao_social=forn.get("razaoSocialReceita"),
        ug_codigo=ug.get("codigo"),
        ug_descricao=ug.get("nome"),
        orgao_codigo=orgao.get("codigoSIAFI") or orgao_max.get("codigo"),
        orgao_descricao=orgao.get("nome") or orgao_max.get("nome"),
        orgao_poder=ug.get("descricaoPoder"),
        modalidade_codigo=None,
        modalidade_descricao=raw.get("modalidadeCompra"),
        tipo_contrato=None,
        licitacao_numero=compra.get("numero"),
        licitacao_modalidade=None,
    )


# ─── Conector ─────────────────────────────────────────────────────────────────

class ContratosConnector:
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

    def _fetch_page(self, url: str, pagina: int, **params) -> list[dict]:
        self._throttle()
        params["pagina"] = pagina
        resp = self.session.get(url, params=params, timeout=45)
        if resp.status_code == 401:
            raise PermissionError("Chave da API inválida.")
        resp.raise_for_status()
        data = resp.json()
        return data if isinstance(data, list) else []

    def iter_por_cnpj(self, cnpj: str) -> Iterator[Contrato]:
        """Todos os contratos de um fornecedor por CNPJ/CPF."""
        cnpj_digits = _strip_digits(cnpj) or cnpj
        pagina = 1
        total = 0
        while True:
            records = self._fetch_page(BASE_URL_CNPJ, pagina, cpfCnpj=cnpj_digits)
            if not records:
                break
            for r in records:
                yield _parse_record(r)
                total += 1
            pagina += 1
        logger.info("Contratos CNPJ %s: %d registros", cnpj_digits, total)

    def iter_por_periodo(self, data_inicio: date, data_fim: date,
                         codigo_orgao: str | None = None) -> Iterator[Contrato]:
        """Contratos assinados em um período, opcionalmente por órgão."""
        params: dict = {
            "dataInicioVigencia": data_inicio.strftime("%d/%m/%Y"),
            "dataFimVigencia":    data_fim.strftime("%d/%m/%Y"),
        }
        if codigo_orgao:
            params["codigoOrgao"] = codigo_orgao
        pagina = 1
        total = 0
        while True:
            records = self._fetch_page(BASE_URL, pagina, **params)
            if not records:
                break
            for r in records:
                yield _parse_record(r)
                total += 1
            pagina += 1
        logger.info("Contratos %s→%s: %d registros", data_inicio, data_fim, total)

    def iter_cnpjs_investigados(self, cnpjs: list[str]) -> Iterator[Contrato]:
        """Busca contratos para uma lista de CNPJs investigados, pulando erros pontuais."""
        for cnpj in cnpjs:
            logger.info("Contratos para CNPJ %s", cnpj)
            try:
                yield from self.iter_por_cnpj(cnpj)
            except Exception as e:
                logger.warning("CNPJ %s ignorado: %s", cnpj, e)

    def fetch_itens(self, contrato_id: int) -> list[ItemContratado]:
        """Busca itens contratados de um contrato específico."""
        self._throttle()
        resp = self.session.get(BASE_URL_ITENS, params={"id": contrato_id}, timeout=30)
        if resp.status_code == 404:
            return []
        resp.raise_for_status()
        data = resp.json()
        if not isinstance(data, list):
            return []
        itens = []
        for item in data:
            itens.append(ItemContratado(
                descricao=item.get("descricao"),
                quantidade=_parse_float(item.get("quantidade")),
                unidade=item.get("unidadeMedida"),
                valor_unitario=_parse_float(item.get("valorUnitario")),
                valor_total=_parse_float(item.get("valorTotal")),
            ))
        return itens
