"""
Conector: Contratos Federais — Portal da Transparência

Verifica contratos federais ativos pelo CNPJ do contratado.

Objetivo: enriquecer dossiê com volume de negócios com o governo federal e
detectar anomalias (rescisões por inadimplência). Ter contratos com o governo
é informação neutra/positiva por padrão — sinalizado como "info".

API: https://api.portaldatransparencia.gov.br/api-de-dados/contratos
Auth: chave-api header (PORTAL_TRANSPARENCIA_API_KEY)
Fallback: scraping da versão web sem auth

Severidade:
  - info     → contratos ativos normais (empresa é fornecedora federal)
  - atencao  → situação rescindida / irregularidade detectada
  - ok       → nenhum contrato encontrado (silencioso)
"""
from __future__ import annotations

import logging
import os
import re
from html.parser import HTMLParser
from typing import Any

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.contratos_transparencia_pj")

PT_BASE   = "https://api.portaldatransparencia.gov.br/api-de-dados"
PT_WEB    = "https://portaldatransparencia.gov.br"
PT_KEY    = os.environ.get("PORTAL_TRANSPARENCIA_API_KEY", "")

# Situações que indicam problema contratual
SITUACOES_ATENCAO = {
    "rescindido",
    "rescindido unilateralmente",
    "rescisão amigável",
    "anulado",
    "irregularidade",
    "inadimplente",
    "suspenso",
}


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", cnpj)


def _fmt(cnpj: str) -> str:
    c = _strip(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _situacao_severity(situacao: str) -> str:
    s = situacao.lower().strip()
    for kw in SITUACOES_ATENCAO:
        if kw in s:
            return "atencao"
    return "info"


def _fmt_valor(valor: Any) -> str:
    if valor is None:
        return "N/D"
    try:
        return f"R$ {float(str(valor).replace(',', '.').replace(' ', '')):,.2f}"
    except Exception:
        return str(valor)


def _parse_date(s: str) -> str | None:
    if not s:
        return None
    for fmt in ("%d/%m/%Y", "%Y-%m-%dT%H:%M:%S", "%Y-%m-%d"):
        try:
            from datetime import datetime
            return datetime.strptime(s.strip()[:19], fmt).date().isoformat()
        except ValueError:
            continue
    return None


class _ContadorHTMLParser(HTMLParser):
    """Parser mínimo para extrair total de contratos do HTML de fallback."""
    def __init__(self) -> None:
        super().__init__()
        self.total: int | None = None
        self._in_total = False

    def handle_data(self, data: str) -> None:
        txt = data.strip()
        if self.total is None and re.search(r"\d+ resultado", txt, re.IGNORECASE):
            m = re.search(r"(\d+)", txt)
            if m:
                self.total = int(m.group(1))


class ContratosTransparenciaPJConnector(SubradarSource):
    """
    Busca contratos federais pelo CNPJ contratado via Portal da Transparência.

    Com PORTAL_TRANSPARENCIA_API_KEY → usa API REST (dados completos).
    Sem chave → tenta HEAD na URL web para confirmar existência de contratos.
    """
    fonte          = "contratos_transparencia"
    base_url       = PT_BASE
    request_delay  = 1.0
    timeout        = 30

    # ------------------------------------------------------------------ #
    # Headers                                                              #
    # ------------------------------------------------------------------ #
    def _api_headers(self) -> dict:
        return {
            "chave-api-dados": PT_KEY,
            "Accept": "application/json",
        }

    def _web_headers(self) -> dict:
        return {
            "Accept": "text/html,application/xhtml+xml",
            "Accept-Language": "pt-BR,pt;q=0.9",
        }

    # ------------------------------------------------------------------ #
    # Busca via API                                                        #
    # ------------------------------------------------------------------ #
    def _buscar_via_api(self, cnpj_limpo: str) -> list[dict]:
        todos: list[dict] = []
        pagina = 1
        while True:
            try:
                data = self._get(
                    f"{PT_BASE}/contratos",
                    params={
                        "cnpjContratado": cnpj_limpo,
                        "pagina": pagina,
                        "tamanhoPagina": 10,
                        "ordenarPor": "dataFimVigencia",
                        "direcao": "desc",
                    },
                    headers=self._api_headers(),
                )
            except Exception as e:
                logger.warning("contratos API erro p.%d: %s", pagina, e)
                break

            items = data if isinstance(data, list) else []
            if not items:
                break
            todos.extend(items)
            # tamanhoPagina=10 — se vier menos de 10 é última página
            if len(items) < 10:
                break
            pagina += 1

        return todos

    # ------------------------------------------------------------------ #
    # Fallback scraping (sem chave)                                        #
    # ------------------------------------------------------------------ #
    def _buscar_via_web(self, cnpj_limpo: str) -> list[dict] | None:
        """
        Faz GET na listagem web e retorna lista com um único item sintético
        indicando quantos contratos foram encontrados, ou None em caso de erro.
        """
        url = f"{PT_WEB}/contratos/resultado"
        try:
            import time as _time
            elapsed = _time.monotonic() - self._last
            if elapsed < self.request_delay:
                _time.sleep(self.request_delay - elapsed)
            self._last = _time.monotonic()

            resp = self._session.get(
                url,
                params={"cnpjContratado": cnpj_limpo},
                headers=self._web_headers(),
                timeout=self.timeout,
            )
            resp.raise_for_status()
        except Exception as e:
            logger.warning("contratos web fallback erro: %s", e)
            return None

        parser = _ContadorHTMLParser()
        parser.feed(resp.text)

        if parser.total is None:
            # Tenta checar texto genérico de "nenhum resultado"
            if "nenhum resultado" in resp.text.lower() or "0 resultado" in resp.text.lower():
                return []
            # Não conseguimos interpretar — retornamos None (ignora)
            logger.warning("contratos web: não foi possível extrair total de resultados")
            return None

        if parser.total == 0:
            return []

        # Retorna um stub com o total; sem detalhe individual no fallback
        return [{"_stub": True, "total": parser.total, "cnpjContratado": cnpj_limpo}]

    # ------------------------------------------------------------------ #
    # Montagem de alertas                                                  #
    # ------------------------------------------------------------------ #
    def _alertas_de_contratos(self, contratos: list[dict], cnpj_fmt: str, ciclo: str) -> list[dict]:
        alertas: list[dict] = []

        for c in contratos:
            # --- stub do fallback web ---
            if c.get("_stub"):
                total = c.get("total", "?")
                alertas.append({
                    "cnpj": cnpj_fmt, "ciclo": ciclo,
                    "fonte": self.fonte, "categoria": "licitacao",
                    "severidade": "info",
                    "titulo": f"Fornecedora federal — {total} contrato(s) identificado(s)",
                    "descricao": (
                        f"O CNPJ {cnpj_fmt} possui ao menos {total} contrato(s) registrado(s) "
                        "no Portal da Transparência Federal. "
                        "Para detalhamento utilize PORTAL_TRANSPARENCIA_API_KEY."
                    ),
                    "url_fonte": (
                        f"{PT_WEB}/contratos/resultado"
                        f"?cnpjContratado={_strip(cnpj_fmt)}"
                    ),
                    "is_novo": True,
                })
                continue

            # --- dados completos da API ---
            num_contrato = (
                c.get("numero")
                or c.get("numeroContrato")
                or c.get("id")
                or ""
            )
            situacao_raw = (
                c.get("situacao")
                or c.get("situacaoContrato", {})
            )
            if isinstance(situacao_raw, dict):
                situacao = situacao_raw.get("descricao") or situacao_raw.get("nome") or "N/D"
            else:
                situacao = str(situacao_raw) if situacao_raw else "N/D"

            orgao_raw = (
                c.get("unidadeGestora")
                or c.get("orgao")
                or c.get("orgaoSuperior")
                or {}
            )
            if isinstance(orgao_raw, dict):
                orgao = (
                    orgao_raw.get("descricaoPoder")
                    or orgao_raw.get("nomeOrgao")
                    or orgao_raw.get("nome")
                    or "N/D"
                )
            else:
                orgao = str(orgao_raw) if orgao_raw else "N/D"

            objeto     = (c.get("objeto") or c.get("descricaoObjeto") or "")[:200]
            valor      = c.get("valorInicialCompra") or c.get("valorContrato") or c.get("valor")
            dt_inicio  = c.get("dataInicioVigencia") or c.get("dataAssinatura") or ""
            dt_fim     = c.get("dataFimVigencia") or c.get("dataTerminoVigencia") or ""

            severidade = _situacao_severity(situacao)

            url_contrato = (
                f"{PT_WEB}/contratos/{num_contrato}"
                if num_contrato
                else f"{PT_WEB}/contratos/resultado?cnpjContratado={_strip(cnpj_fmt)}"
            )

            alertas.append({
                "cnpj": cnpj_fmt, "ciclo": ciclo,
                "fonte": self.fonte, "categoria": "licitacao",
                "severidade": severidade,
                "titulo": (
                    f"Contrato {num_contrato} — {situacao}"
                    if num_contrato else f"Contrato federal — {situacao}"
                ),
                "descricao": (
                    f"Órgão contratante: {orgao}. "
                    f"Situação: {situacao}. "
                    f"Valor: {_fmt_valor(valor)}. "
                    f"Vigência: {dt_inicio or 'N/D'} a {dt_fim or 'N/D'}. "
                    f"Objeto: {objeto}."
                ),
                "referencia_id": str(num_contrato) if num_contrato else None,
                "contraparte": orgao,
                "data_evento": _parse_date(str(dt_inicio)),
                "url_fonte": url_contrato,
                "is_novo": True,
            })

        return alertas

    # ------------------------------------------------------------------ #
    # Interface pública                                                    #
    # ------------------------------------------------------------------ #
    def consultar_cnpj(self, cnpj: str, razao_social: str | None = None) -> list[dict]:
        cnpj_limpo = _strip(cnpj)
        if len(cnpj_limpo) != 14:
            logger.warning("contratos_transparencia: CNPJ inválido: %s", cnpj)
            return []

        cnpj_fmt = _fmt(cnpj_limpo)
        ciclo    = _ciclo_atual()

        # --- coleta ---
        if PT_KEY:
            contratos = self._buscar_via_api(cnpj_limpo)
        else:
            logger.warning(
                "contratos_transparencia: PORTAL_TRANSPARENCIA_API_KEY ausente — "
                "usando fallback web (dados limitados)"
            )
            contratos_web = self._buscar_via_web(cnpj_limpo)
            if contratos_web is None:
                return []          # erro de rede / parsing — aborta silenciosamente
            contratos = contratos_web

        # --- snapshot ---
        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, contratos)
        if not mudou:
            logger.info("contratos_transparencia: sem mudanças para %s", cnpj_fmt)
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt, "fonte": self.fonte, "ciclo": ciclo,
            "hash_dados": hash_novo,
            "dados": {"total": len(contratos)},
        }])

        # --- zero contratos → silencioso ---
        if not contratos:
            logger.info("contratos_transparencia: nenhum contrato para %s", cnpj_fmt)
            return []

        alertas = self._alertas_de_contratos(contratos, cnpj_fmt, ciclo)
        logger.info("contratos_transparencia: %d alertas para %s", len(alertas), cnpj_fmt)
        return alertas
