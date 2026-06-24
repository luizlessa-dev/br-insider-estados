"""
Licitações do Poder Executivo Federal · The Brasilia Insider

APIs utilizadas:
  GET /api-de-dados/licitacoes                  — lista paginada de licitações
  GET /api-de-dados/licitacoes/participantes     — participantes de uma licitação
  GET /api-de-dados/licitacoes/itens-licitados   — itens de uma licitação

Autenticação: header "chave-api-dados".

Parâmetros (/licitacoes):
  dataPublicacaoInicio / dataPublicacaoFim — DD/MM/AAAA
  codigoOrgao
  pagina

Parâmetros (/licitacoes/participantes):
  codigoLicitacao   — ID da licitação
  pagina

Campos retornados (/licitacoes):
  id, numero, objeto,
  dataAbertura, dataPublicacao,
  situacao.{codigo, descricao},
  modalidade.{codigo, descricao},
  unidadeGestora.{codigo, descricao, orgao.{codigo, descricao}},
  valorEstimado,
  tipoLicitacao.descricao,
  numeroProcesso

Campos (/participantes):
  cnpj, cpf, nome, situacaoParticipante,
  situacaoFornecedor.{codigo, descricao},
  valorProposta

Cruzamento estratégico:
  licitacoes_participantes.cnpj × emendas_favorecidos.codigo_favorecido
    → empresa perdeu licitação mas recebeu emenda do mesmo órgão (direcionamento)
  licitacoes_participantes.cnpj × sancoes.cpf_cnpj
    → empresa sancionada participou de licitação
  licitacoes.orgao_codigo × contratos_federais.orgao_codigo
    → licitação sem contrato vinculado (dispensa irregular?)
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

logger = logging.getLogger("cgu.licitacoes")

BASE_URL              = "https://api.portaldatransparencia.gov.br/api-de-dados/licitacoes"
BASE_URL_PARTICIPANTES = "https://api.portaldatransparencia.gov.br/api-de-dados/licitacoes/participantes"
BASE_URL_ITENS        = "https://api.portaldatransparencia.gov.br/api-de-dados/licitacoes/itens-licitados"

PAGE_DELAY = 0.4


# ─── Modelos ──────────────────────────────────────────────────────────────────

@dataclass
class Participante:
    licitacao_id: int
    cnpj: Optional[str]              # só dígitos
    cpf: Optional[str]
    nome: Optional[str]
    situacao_participante: Optional[str]
    situacao_fornecedor: Optional[str]
    valor_proposta: Optional[float]


@dataclass
class Licitacao:
    id: int
    numero: Optional[str]
    objeto: Optional[str]
    data_abertura: Optional[date]
    data_publicacao: Optional[date]
    situacao_codigo: Optional[str]
    situacao_descricao: Optional[str]
    modalidade_codigo: Optional[str]
    modalidade_descricao: Optional[str]
    ug_codigo: Optional[str]
    ug_descricao: Optional[str]
    orgao_codigo: Optional[str]
    orgao_descricao: Optional[str]
    valor_estimado: Optional[float]
    tipo_licitacao: Optional[str]
    numero_processo: Optional[str]
    participantes: list[Participante] = field(default_factory=list)


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


def _parse_licitacao(raw: dict) -> Licitacao:
    sit   = raw.get("situacao") or {}
    modal = raw.get("modalidade") or {}
    ug    = raw.get("unidadeGestora") or {}
    orgao = ug.get("orgao") or {}
    tipo  = raw.get("tipoLicitacao") or {}

    return Licitacao(
        id=raw.get("id"),
        numero=raw.get("numero"),
        objeto=raw.get("objeto"),
        data_abertura=_parse_date(raw.get("dataAbertura")),
        data_publicacao=_parse_date(raw.get("dataPublicacao")),
        situacao_codigo=str(sit.get("codigo")) if sit.get("codigo") else None,
        situacao_descricao=sit.get("descricao"),
        modalidade_codigo=str(modal.get("codigo")) if modal.get("codigo") else None,
        modalidade_descricao=modal.get("descricao"),
        ug_codigo=str(ug.get("codigo")) if ug.get("codigo") else None,
        ug_descricao=ug.get("descricao"),
        orgao_codigo=str(orgao.get("codigo")) if orgao.get("codigo") else None,
        orgao_descricao=orgao.get("descricao"),
        valor_estimado=_parse_float(raw.get("valorEstimado")),
        tipo_licitacao=tipo.get("descricao"),
        numero_processo=raw.get("numeroProcesso"),
    )


def _parse_participante(raw: dict, licitacao_id: int) -> Participante:
    sit_forn = raw.get("situacaoFornecedor") or {}
    return Participante(
        licitacao_id=licitacao_id,
        cnpj=_strip_digits(raw.get("cnpj")),
        cpf=_strip_digits(raw.get("cpf")),
        nome=raw.get("nome"),
        situacao_participante=raw.get("situacaoParticipante"),
        situacao_fornecedor=sit_forn.get("descricao"),
        valor_proposta=_parse_float(raw.get("valorProposta")),
    )


# ─── Conector ─────────────────────────────────────────────────────────────────

class LicitacoesConnector:
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
        # A API rejeita barras URL-encoded (%2F) nas datas — monta query string manualmente.
        qs = "&".join(f"{k}={v}" for k, v in params.items())
        full_url = f"{url}?{qs}"
        resp = self.session.get(full_url, timeout=45)
        if resp.status_code == 401:
            raise PermissionError("Chave da API inválida.")
        resp.raise_for_status()
        data = resp.json()
        return data if isinstance(data, list) else []

    def iter_participantes(self, licitacao_id: int) -> list[Participante]:
        """Busca todos os participantes de uma licitação."""
        pagina = 1
        participantes = []
        while True:
            records = self._fetch_page(
                BASE_URL_PARTICIPANTES, pagina, codigoLicitacao=licitacao_id
            )
            if not records:
                break
            for r in records:
                participantes.append(_parse_participante(r, licitacao_id))
            pagina += 1
        return participantes

    def iter_por_periodo(self, data_inicio: date, data_fim: date,
                         codigo_orgao: str | None = None,
                         com_participantes: bool = False) -> Iterator[Licitacao]:
        """
        Itera licitações de um período.
        Se com_participantes=True, enriquece cada licitação com sua lista de participantes
        (mais chamadas à API, usar para investigações pontuais).
        """
        params: dict = {
            "dataPublicacaoInicio": data_inicio.strftime("%d/%m/%Y"),
            "dataPublicacaoFim":    data_fim.strftime("%d/%m/%Y"),
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
                licit = _parse_licitacao(r)
                if com_participantes and licit.id:
                    licit.participantes = self.iter_participantes(licit.id)
                yield licit
                total += 1
            pagina += 1
        logger.info("Licitações %s→%s: %d registros", data_inicio, data_fim, total)

    def iter_participantes_cnpj(self, cnpj: str,
                                data_inicio: date, data_fim: date) -> Iterator[tuple[Licitacao, Participante]]:
        """
        Para uso investigativo: retorna todos os (licitação, participação) onde
        o CNPJ aparece como participante. Itera licitações do período e filtra.
        """
        cnpj_digits = _strip_digits(cnpj) or cnpj
        for licit in self.iter_por_periodo(data_inicio, data_fim, com_participantes=True):
            for p in licit.participantes:
                if p.cnpj == cnpj_digits:
                    yield licit, p
