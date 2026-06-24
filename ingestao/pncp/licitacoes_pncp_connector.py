"""
Conector PNCP — Licitações (Portal Nacional de Compras Públicas)

API: pncp.gov.br/api/consulta/v1/contratacoes/publicacao
     GET ?dataInicial=YYYYMMDD&dataFinal=YYYYMMDD
         &codigoModalidadeContratacao=<int>
         &pagina=<int>&tamanhoPagina=<int>

Modalidades:
  1 = Leilão / Leilão Eletrônico
  2 = Diálogo Competitivo
  3 = Concurso
  4 = Concorrência / Concorrência Eletrônica
  5 = Concorrência - Presencial   (mais usada para obras)
  6 = Pregão Eletrônico
  7 = Pregão Presencial
  8 = Dispensa de Licitação Eletrônica
  9 = Dispensa de Licitação
 10 = Inexigibilidade
 13 = Regime Diferenciado de Contratações Públicas

Estratégia investigativa: filtrar por CNPJ do orgão que tem contratos com empresas investigadas.
A API PNCP NÃO aceita filtro por CNPJ de participante/fornecedor.
Fluxo: org CNPJ → /api/consulta/v1/orgaos/{cnpj}/compras/{ano}/{seq} (detalhe)
       OU: varrre publicacoes por data e filtra localmente por CNPJ.
"""
from __future__ import annotations

import logging
import time
from dataclasses import dataclass, field
from datetime import date, datetime
from typing import Iterator

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

logger = logging.getLogger("pncp.licitacoes")

BASE_URL = "https://pncp.gov.br/api/consulta/v1/contratacoes/publicacao"
BASE_ORGAO_URL = "https://pncp.gov.br/api/consulta/v1/orgaos/{cnpj}/compras"

# Modalidades relevantes para investigação de obras/serviços com emendas
MODALIDADES_INVESTIGATIVAS = [4, 5, 6, 7, 8, 9]

PAGE_SIZE = 50
THROTTLE_S = 2.0  # PNCP rate limit: ~30 req/min sustentável


@dataclass
class LicitacaoPncp:
    numero_controle_pncp: str          # PK natural
    cnpj_orgao:           str | None
    razao_social_orgao:   str | None
    esfera_orgao:         str | None   # 'F', 'E', 'M'
    uf_unidade:           str | None
    municipio_unidade:    str | None
    ano_compra:           int | None
    sequencial_compra:    int | None
    numero:               str | None   # numeroCompra
    objeto:               str | None
    data_publicacao:      date | None
    data_abertura:        date | None
    modalidade_codigo:    str | None
    modalidade_descricao: str | None
    valor_estimado:       float | None
    valor_homologado:     float | None
    numero_processo:      str | None
    situacao_codigo:      str | None
    situacao_descricao:   str | None


def _parse_date(v: str | None) -> date | None:
    if not v:
        return None
    for fmt in ("%Y-%m-%dT%H:%M:%S", "%Y-%m-%d"):
        try:
            return datetime.strptime(v[:19], fmt).date()
        except ValueError:
            continue
    return None


def _parse_float(v) -> float | None:
    try:
        return float(v) if v is not None else None
    except (TypeError, ValueError):
        return None


def _esfera(codigo: str | None) -> str | None:
    return {"F": "Federal", "E": "Estadual", "M": "Municipal"}.get(codigo or "", codigo)


def _parse_item(raw: dict) -> LicitacaoPncp | None:
    numero = raw.get("numeroControlePNCP")
    if not numero:
        return None
    orgao = raw.get("orgaoEntidade") or {}
    unidade = raw.get("unidadeOrgao") or {}
    return LicitacaoPncp(
        numero_controle_pncp = numero,
        cnpj_orgao           = orgao.get("cnpj"),
        razao_social_orgao   = orgao.get("razaoSocial"),
        esfera_orgao         = _esfera(orgao.get("esferaId")),
        uf_unidade           = unidade.get("ufSigla"),
        municipio_unidade    = unidade.get("municipioNome"),
        ano_compra           = raw.get("anoCompra"),
        sequencial_compra    = raw.get("sequencialCompra"),
        numero               = raw.get("numeroCompra"),
        objeto               = (raw.get("objetoCompra") or "")[:1000] or None,
        data_publicacao      = _parse_date(raw.get("dataPublicacaoPncp")),
        data_abertura        = _parse_date(raw.get("dataAberturaProposta")),
        modalidade_codigo    = str(raw["modalidadeId"]) if raw.get("modalidadeId") else None,
        modalidade_descricao = raw.get("modalidadeNome"),
        valor_estimado       = _parse_float(raw.get("valorTotalEstimado")),
        valor_homologado     = _parse_float(raw.get("valorTotalHomologado")),
        numero_processo      = raw.get("processo"),
        situacao_codigo      = str(raw["situacaoCompraId"]) if raw.get("situacaoCompraId") else None,
        situacao_descricao   = raw.get("situacaoCompraNome"),
    )


class PncpConnector:
    def __init__(self) -> None:
        retry = Retry(total=4, backoff_factor=1.5, status_forcelist=[429, 500, 502, 503, 504])
        self.session = requests.Session()
        self.session.mount("https://", HTTPAdapter(max_retries=retry))
        self.session.headers.update({"Accept": "application/json"})
        self._last = 0.0

    def _throttle(self) -> None:
        elapsed = time.monotonic() - self._last
        if elapsed < THROTTLE_S:
            time.sleep(THROTTLE_S - elapsed)
        self._last = time.monotonic()

    def _fetch_page(self, modalidade: int, data_ini: str, data_fim: str, pagina: int) -> dict:
        self._throttle()
        url = (
            f"{BASE_URL}"
            f"?dataInicial={data_ini}&dataFinal={data_fim}"
            f"&codigoModalidadeContratacao={modalidade}"
            f"&pagina={pagina}&tamanhoPagina={PAGE_SIZE}"
        )
        resp = self.session.get(url, timeout=30)
        if resp.status_code == 204:
            return {}
        resp.raise_for_status()
        return resp.json()

    def iter_por_dia(self, dia: date, modalidades: list[int] | None = None) -> Iterator[LicitacaoPncp]:
        """Itera todas as licitações publicadas num dia, nas modalidades indicadas."""
        data_str = dia.strftime("%Y%m%d")
        for mod in (modalidades or MODALIDADES_INVESTIGATIVAS):
            pagina = 1
            while True:
                try:
                    payload = self._fetch_page(mod, data_str, data_str, pagina)
                except Exception as e:
                    logger.warning("mod=%d dia=%s p=%d ERRO: %s — pulando restante", mod, dia, pagina, e)
                    time.sleep(5)  # backoff extra após 429
                    break
                if not payload:
                    break
                for raw in payload.get("data") or []:
                    item = _parse_item(raw)
                    if item:
                        yield item
                if pagina >= (payload.get("totalPaginas") or 1):
                    break
                pagina += 1

    def iter_por_cnpj(
        self,
        cnpjs: list[str],
        data_ini: date,
        data_fim: date,
        modalidades: list[int] | None = None,
    ) -> Iterator[LicitacaoPncp]:
        """
        Varre licitações dia a dia no período e filtra localmente pelos CNPJs do órgão.
        Útil para rastrear licitações emitidas por órgãos que contrataram empresas investigadas.
        """
        from datetime import timedelta
        dia = data_ini
        cnpjs_set = {c.replace(".", "").replace("/", "").replace("-", "") for c in cnpjs}
        while dia <= data_fim:
            for lic in self.iter_por_dia(dia, modalidades):
                cnpj_limpo = (lic.cnpj_orgao or "").replace(".", "").replace("/", "").replace("-", "")
                if not cnpjs_set or cnpj_limpo in cnpjs_set:
                    yield lic
            dia += timedelta(days=1)
