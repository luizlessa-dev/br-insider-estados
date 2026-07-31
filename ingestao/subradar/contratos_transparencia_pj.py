"""
Conector: Contratos Federais — PNCP (Portal Nacional de Contratações Públicas)

Verifica contratos federais pelo CNPJ do fornecedor contratado.

API: https://pncp.gov.br/api/consulta/v1/contratos
Sem autenticação. Janela de 365 dias corridos até hoje.

Severidade:
  - info     → contratos ativos normais (empresa é fornecedora federal)
  - atencao  → situação rescindida / anulada / irregularidade detectada
  - ok       → nenhum contrato encontrado (silencioso)
"""
from __future__ import annotations

import logging
import re
from datetime import date, timedelta
from typing import Any

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.contratos_transparencia_pj")

PNCP_BASE = "https://pncp.gov.br/api/consulta/v1"
PNCP_WEB  = "https://pncp.gov.br/app/contratos"

SITUACOES_ATENCAO = {
    "rescindido", "rescindida", "rescisão", "rescisao",
    "anulado", "anulada", "anulação", "anulacao",
    "suspenso", "suspensa", "suspensão", "suspensao",
    "irregularidade", "inadimplente",
}


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", cnpj)


def _fmt(cnpj: str) -> str:
    c = _strip(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _situacao_severity(situacao: str) -> str:
    s = situacao.lower()
    for kw in SITUACOES_ATENCAO:
        if kw in s:
            return "atencao"
    return "info"


def _fmt_valor(valor: Any) -> str:
    if valor is None:
        return "N/D"
    try:
        return f"R$ {float(str(valor).replace(',', '.')):,.2f}"
    except Exception:
        return str(valor)


class ContratosTransparenciaPJConnector(SubradarSource):
    """
    Busca contratos federais pelo CNPJ fornecedor via PNCP.
    Sem autenticação. Janela de 365 dias corridos.
    """
    fonte         = "contratos_transparencia"
    request_delay = 1.0
    timeout       = 30

    def _buscar_pncp(self, cnpj14: str) -> list[dict]:
        hoje      = date.today()
        inicio    = hoje - timedelta(days=365)
        di        = inicio.strftime("%Y%m%d")
        df        = hoje.strftime("%Y%m%d")

        todos: list[dict] = []
        pagina = 1
        while True:
            try:
                data = self._get(
                    f"{PNCP_BASE}/contratos",
                    params={
                        "cnpjFornecedor": cnpj14,
                        "dataInicial":    di,
                        "dataFinal":      df,
                        "pagina":         pagina,
                        "tamanhoPagina":  10,
                    },
                    headers={"Accept": "application/json", "User-Agent": "Subradar/1.0"},
                )
            except Exception as e:
                logger.warning("PNCP contratos erro p.%d: %s", pagina, e)
                break

            items = data.get("data", []) if isinstance(data, dict) else (data if isinstance(data, list) else [])
            if not items:
                break
            # Filtra client-side: niFornecedor deve bater com cnpj14
            filtered = [c for c in items if re.sub(r"\D", "", str(c.get("niFornecedor", ""))) == cnpj14]
            todos.extend(filtered)
            total_pages = data.get("totalPaginas") if isinstance(data, dict) else None
            if total_pages and pagina >= total_pages:
                break
            if len(items) < 10:
                break
            # Para de paginar se não encontrou nada na página (evita varredura infinita)
            if not filtered and pagina > 3:
                logger.info("PNCP: sem contratos para %s após p.%d — parando", cnpj14, pagina)
                break
            pagina += 1

        return todos

    def _alertas(self, contratos: list[dict], cnpj_fmt: str, ciclo: str) -> list[dict]:
        alertas: list[dict] = []
        for c in contratos:
            num     = c.get("numeroControlePncpCompra") or c.get("numeroContratoEmpenho") or ""
            orgao   = (c.get("orgaoEntidade") or {}).get("razaoSocial") or "N/D"
            objeto  = (c.get("objetoContrato") or c.get("categoriaProcesso", {}).get("nome") or "")[:200]
            valor   = c.get("valorGlobal") or c.get("valorInicial")
            dt_ini  = c.get("dataVigenciaInicio") or c.get("dataAssinatura") or ""
            dt_fim  = c.get("dataVigenciaFim") or ""
            tipo    = (c.get("tipoContrato") or {}).get("nome") or "Contrato"
            situacao = c.get("situacaoContrato") or tipo

            severidade = _situacao_severity(str(situacao))

            alertas.append({
                "cnpj":          cnpj_fmt,
                "ciclo":         ciclo,
                "fonte":         self.fonte,
                "categoria":     "licitacao",
                "severidade":    severidade,
                "titulo":        f"PNCP — Contrato federal ({tipo}): {cnpj_fmt}",
                "descricao": (
                    f"Órgão: {orgao}. "
                    f"Tipo: {tipo}. "
                    f"Valor: {_fmt_valor(valor)}. "
                    f"Vigência: {dt_ini[:10] if dt_ini else 'N/D'} a {dt_fim[:10] if dt_fim else 'N/D'}. "
                    f"Objeto: {objeto}."
                ),
                "referencia_id": num or None,
                "contraparte":   orgao,
                "data_evento":   dt_ini[:10] if dt_ini else None,
                "url_fonte":     PNCP_WEB,
                "is_novo":       True,
            })
        return alertas

    def consultar_cnpj(self, cnpj: str, razao_social: str | None = None) -> list[dict]:
        cnpj14 = _strip(cnpj)
        if len(cnpj14) != 14:
            return []

        cnpj_fmt = _fmt(cnpj14)
        ciclo    = _ciclo_atual()

        contratos = self._buscar_pncp(cnpj14)

        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, contratos)
        if not mudou:
            logger.info("contratos_transparencia: sem mudanças para %s", cnpj_fmt)
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt, "fonte": self.fonte, "ciclo": ciclo,
            "hash_dados": hash_novo,
            "dados": {"total": len(contratos)},
        }])

        if not contratos:
            logger.info("contratos_transparencia: nenhum contrato (365d) para %s", cnpj_fmt)
            return []

        alertas = self._alertas(contratos, cnpj_fmt, ciclo)
        logger.info("contratos_transparencia: %d alerta(s) para %s", len(alertas), cnpj_fmt)
        return alertas
