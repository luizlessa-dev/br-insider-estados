"""
Conector: SICONV / Plataforma +Brasil — Convênios Federais

API: Portal da Transparência — /api-de-dados/convenios
Auth: chave-api-dados (mesmo token do pipeline BR Insider)
Filtro: por CNPJ do convenente (beneficiário).

Relevância compliance:
  - Situação "Inadimplente" → critico
  - Situação "Rescindido" / "Inadimplente por ausência de prestação de contas" → critico
  - Situação "Em execução" / "Prestação de contas" → info
"""
from __future__ import annotations

import logging
import os
import re

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.siconv")

PT_BASE = "https://api.portaldatransparencia.gov.br/api-de-dados"
PT_KEY  = os.environ.get("PORTAL_TRANSPARENCIA_API_KEY", "")

SITUACOES_CRITICO = {
    "inadimplente",
    "inadimplente por ausência de prestação de contas",
    "rescindido",
    "cancelado",
    "instauração de tomada de contas especial",
    "aguardando instauração de tomada de contas especial",
}
SITUACOES_ATENCAO = {
    "prestação de contas em análise",
    "com pendências",
    "prestação de contas enviada para análise",
}


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", cnpj)


def _fmt(cnpj: str) -> str:
    c = _strip(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _situacao_severity(situacao: str) -> str:
    s = situacao.lower().strip()
    if s in SITUACOES_CRITICO:
        return "critico"
    if s in SITUACOES_ATENCAO:
        return "atencao"
    return "info"


class SICONVConnector(SubradarSource):
    fonte       = "siconv"
    base_url    = PT_BASE
    request_delay = 0.3

    def _headers(self) -> dict:
        return {"chave-api-dados": PT_KEY, "Accept": "application/json"}

    def _buscar_convenios(self, cnpj_limpo: str) -> list[dict]:
        """Pagina todos os convênios do CNPJ convenente."""
        todos: list[dict] = []
        pagina = 1
        while True:
            try:
                data = self._get(
                    f"{PT_BASE}/convenios",
                    params={"convenente": cnpj_limpo, "pagina": pagina},
                    headers=self._headers(),
                )
            except Exception as e:
                logger.warning("SICONV API erro p.%d: %s", pagina, e)
                break

            items = data if isinstance(data, list) else []
            if not items:
                break
            todos.extend(items)
            if len(items) < 500:
                break
            pagina += 1

        return todos

    def consultar_cnpj(self, cnpj: str, razao_social: str | None = None) -> list[dict]:
        if not PT_KEY:
            logger.warning("SICONV: PORTAL_TRANSPARENCIA_API_KEY ausente")
            return []

        cnpj_limpo = _strip(cnpj)
        cnpj_fmt   = _fmt(cnpj_limpo)
        ciclo      = _ciclo_atual()

        convenios = self._buscar_convenios(cnpj_limpo)

        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, convenios)
        if not mudou:
            logger.info("SICONV: sem mudanças para %s", cnpj_fmt)
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt, "fonte": self.fonte, "ciclo": ciclo,
            "hash_dados": hash_novo, "dados": {"total": len(convenios)},
        }])

        if not convenios:
            return [{
                "cnpj": cnpj_fmt, "ciclo": ciclo, "fonte": self.fonte,
                "categoria": "convenios", "severidade": "ok",
                "titulo": "Sem convênios federais identificados",
                "descricao": "CNPJ não encontrado como convenente/beneficiário na base de convênios federais.",
                "is_novo": True,
            }]

        alertas = []
        for c in convenios:
            num        = c.get("numero") or c.get("nrConvenio") or ""
            situacao   = (
                c.get("situacaoConvenio")
                or c.get("situacao", {}).get("descricao")
                or c.get("situacao")
                or "N/D"
            )
            if isinstance(situacao, dict):
                situacao = situacao.get("descricao", "N/D")
            concedente = (
                c.get("orgaoConcedente")
                or c.get("concedente", {}).get("nome")
                or "N/D"
            )
            if isinstance(concedente, dict):
                concedente = concedente.get("nome", "N/D")
            objeto       = (c.get("objeto") or "")[:200]
            valor_global = c.get("valorGlobal") or c.get("valorTotal") or ""
            dt_inicio    = c.get("dataVigenciaInicio") or c.get("dataInicio") or ""
            dt_fim       = c.get("dataVigenciaFim") or c.get("dataFim") or ""

            severidade = _situacao_severity(str(situacao))

            try:
                vg = f"R$ {float(str(valor_global).replace(',','.').replace(' ','')) :,.2f}"
            except Exception:
                vg = str(valor_global)

            alertas.append({
                "cnpj": cnpj_fmt, "ciclo": ciclo, "fonte": self.fonte,
                "categoria": "convenios",
                "severidade": severidade,
                "titulo": f"Convênio {num} — {situacao}",
                "descricao": (
                    f"Concedente: {concedente}. "
                    f"Situação: {situacao}. "
                    f"Valor: {vg}. "
                    f"Vigência: {dt_inicio} a {dt_fim}. "
                    f"Objeto: {objeto}."
                ),
                "referencia_id": str(num),
                "contraparte": str(concedente),
                "data_evento": _parse_date(str(dt_inicio)),
                "url_fonte": (
                    f"https://portaldatransparencia.gov.br/convenios/{num}"
                    if num else "https://portaldatransparencia.gov.br/convenios"
                ),
                "is_novo": True,
            })

        logger.info("SICONV: %d alertas para %s", len(alertas), cnpj_fmt)
        return alertas


def _parse_date(s: str) -> str | None:
    if not s:
        return None
    for fmt in ("%d/%m/%Y", "%Y-%m-%d"):
        try:
            from datetime import datetime
            return datetime.strptime(s.strip(), fmt).date().isoformat()
        except ValueError:
            continue
    return None
