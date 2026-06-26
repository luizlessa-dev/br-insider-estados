"""
Conector: BACEN — Entidades Supervisionadas / Autorizações

API: OData público BACEN BcBase v2 — sem autenticação
Endpoint: https://olinda.bcb.gov.br/olinda/servico/BcBase/versao/v2/odata/

Consulta por CNPJ raiz (8 primeiros dígitos).
Verifica situação da entidade supervisionada no sistema financeiro nacional.

Relevante para:
  - Bancos, corretoras, distribuidoras, cooperativas
  - Administradoras de consórcio, seguradoras (via SUSEP)
  - Fintechs com autorização BACEN

Situações críticas: cancelada, em liquidação, em intervenção, falida.
"""
from __future__ import annotations

import logging
import re

import requests as req

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.bacen")

BACEN_ODATA   = "https://olinda.bcb.gov.br/olinda/servico/BcBase/versao/v2/odata"
ENTITY_PATH   = "_EntidadesSupervisionadas"  # BcBase v2 metadata-confirmed entity name

SITUACOES_CRITICO = {
    "cancelada", "cancelado", "em liquidação extrajudicial",
    "em intervenção", "em regime especial", "falida", "falido",
    "liquidada", "liquidado", "em liquidação", "autorização cancelada",
}
SITUACOES_ATENCAO = {
    "em processo de cancelamento", "em revisão", "suspensa", "suspendo",
    "sob supervisão especial",
}


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", cnpj)


def _fmt(cnpj: str) -> str:
    c = _strip(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _severity(situacao: str) -> str:
    s = situacao.lower().strip()
    if any(k in s for k in SITUACOES_CRITICO):
        return "critico"
    if any(k in s for k in SITUACOES_ATENCAO):
        return "atencao"
    return "ok"


class BACENConnector(SubradarSource):
    fonte         = "bacen"
    request_delay = 1.0

    def _fetch(self, cnpj_raiz: str) -> list[dict]:
        """Busca entidades no BACEN pelo CNPJ raiz (8 dígitos)."""
        # BACEN OData: campo CNPJ como string; substringof é mais tolerante
        filter_expr = f"substringof('{cnpj_raiz}',CNPJ)"
        try:
            r = req.get(
                f"{BACEN_ODATA}/{ENTITY_PATH}",
                params={
                    "$format": "json",
                    "$filter": filter_expr,
                    "$top": 50,
                },
                timeout=20,
                headers={"Accept": "application/json"},
            )
            if r.status_code in (400, 404):
                logger.debug("BACEN: filtro retornou %s para raiz %s", r.status_code, cnpj_raiz)
                return []
            r.raise_for_status()
            return r.json().get("value", [])
        except Exception as e:
            logger.warning("BACEN: erro na consulta: %s", e)
            return []

    def consultar_cnpj(self, cnpj: str, razao_social: str | None = None) -> list[dict]:
        cnpj_limpo = _strip(cnpj)
        cnpj_fmt   = _fmt(cnpj_limpo)
        cnpj_raiz  = cnpj_limpo[:8]
        ciclo      = _ciclo_atual()

        entidades = self._fetch(cnpj_raiz)

        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, entidades)
        if not mudou:
            logger.info("BACEN: sem mudanças para %s", cnpj_fmt)
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt, "fonte": self.fonte, "ciclo": ciclo,
            "hash_dados": hash_novo, "dados": {"total": len(entidades)},
        }])

        if not entidades:
            return [{
                "cnpj": cnpj_fmt, "ciclo": ciclo, "fonte": self.fonte,
                "categoria": "financeiro", "severidade": "ok",
                "titulo": "Sem registro de entidade supervisionada no BACEN",
                "descricao": "CNPJ não encontrado como entidade supervisionada pelo Banco Central do Brasil.",
                "url_fonte": "https://www.bcb.gov.br/institucional/autorizacoesbc",
                "is_novo": True,
            }]

        alertas = []
        for e in entidades:
            nome     = e.get("Nome") or e.get("NomeInstituicao") or razao_social or cnpj_fmt
            tipo     = e.get("TipoInstituicao") or e.get("Segmento") or ""
            situacao = e.get("Situacao") or e.get("TipoSituacaoPessoaJuridica") or "N/D"
            dt_sit   = e.get("DataSituacao") or ""
            cnpj_api = e.get("CNPJ") or cnpj_raiz

            sev = _severity(str(situacao))

            alertas.append({
                "cnpj": cnpj_fmt, "ciclo": ciclo, "fonte": self.fonte,
                "categoria": "financeiro",
                "severidade": sev,
                "titulo": f"BACEN — {nome} ({tipo}) — Situação: {situacao}",
                "descricao": (
                    f"Entidade supervisionada pelo BACEN. "
                    f"Tipo: {tipo}. Situação: {situacao}. "
                    f"Data da situação: {dt_sit}. CNPJ raiz: {cnpj_api}."
                ),
                "data_evento": dt_sit[:10] if dt_sit else None,
                "url_fonte": "https://www.bcb.gov.br/institucional/autorizacoesbc",
                "is_novo": True,
            })

        logger.info("BACEN: %d alertas para %s", len(alertas), cnpj_fmt)
        return alertas
