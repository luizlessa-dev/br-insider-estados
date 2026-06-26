"""
Conector: ANVISA — Autorização de Funcionamento de Empresa (AFE/AE)

Endpoint: https://api.anvisa.gov.br/consultas-externas/funcionamento-empresa-nacional
Auth: Bearer token gov.br (OAuth2 interno ANVISA).

Estratégia de fallback:
  1. Tenta API com token (ANVISA_TOKEN env var)
  2. Se 401/403 → retorna alerta de cobertura indisponível (não falha o pipeline)

Env vars:
  ANVISA_TOKEN — Bearer token obtido via portal gov.br empresarial
"""
from __future__ import annotations

import logging
import os
import re

import requests as req

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.anvisa")

ANVISA_BASE  = "https://api.anvisa.gov.br/consultas-externas"
ANVISA_TOKEN = os.environ.get("ANVISA_TOKEN", "")

SITUACOES_CRITICO = {"cancelada", "cassada", "interdita", "suspensa", "interditada"}
SITUACOES_ATENCAO = {"em análise", "em análise de renovação", "em revisão"}


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
    if "ativa" in s or "vigente" in s:
        return "ok"
    return "info"


class ANVISAConnector(SubradarSource):
    fonte       = "anvisa"
    base_url    = ANVISA_BASE
    request_delay = 0.5

    def _headers(self) -> dict:
        return {
            "Authorization": f"Bearer {ANVISA_TOKEN}",
            "Accept": "application/json",
        }

    def _consultar_api(self, cnpj_limpo: str) -> dict | None:
        """Tenta a API ANVISA. Retorna None se não autorizado ou indisponível."""
        if not ANVISA_TOKEN:
            return None
        try:
            r = req.get(
                f"{ANVISA_BASE}/funcionamento-empresa-nacional",
                params={"cnpj": cnpj_limpo},
                headers=self._headers(),
                timeout=20,
            )
            if r.status_code in (401, 403):
                logger.warning("ANVISA: token inválido ou sem permissão (HTTP %s)", r.status_code)
                return None
            if r.status_code == 404:
                return {}   # empresa não encontrada
            r.raise_for_status()
            return r.json()
        except req.exceptions.Timeout:
            logger.warning("ANVISA: timeout na consulta")
            return None
        except Exception as e:
            logger.warning("ANVISA: erro na consulta: %s", e)
            return None

    def consultar_cnpj(self, cnpj: str, razao_social: str | None = None) -> list[dict]:
        cnpj_limpo = _strip(cnpj)
        cnpj_fmt   = _fmt(cnpj_limpo)
        ciclo      = _ciclo_atual()

        dados = self._consultar_api(cnpj_limpo)

        if dados is None:
            # Token ausente ou inválido — alerta de cobertura, não falha
            logger.info("ANVISA: cobertura indisponível para %s (token ausente/inválido)", cnpj_fmt)
            mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, {"status": "sem_cobertura"})
            if not mudou:
                return []
            upsert("sub_snapshots", [{
                "cnpj": cnpj_fmt, "fonte": self.fonte, "ciclo": ciclo,
                "hash_dados": hash_novo, "dados": {"status": "sem_cobertura"},
            }])
            return [{
                "cnpj": cnpj_fmt, "ciclo": ciclo, "fonte": self.fonte,
                "categoria": "sanitario", "severidade": "info",
                "titulo": "ANVISA: cobertura indisponível",
                "descricao": (
                    "Consulta ANVISA requer token OAuth2 do portal gov.br empresarial. "
                    "Configure ANVISA_TOKEN para habilitar esta fonte. "
                    "Interdições e cancelamentos de AFE/AE não verificados."
                ),
                "is_novo": True,
            }]

        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, dados)
        if not mudou:
            logger.info("ANVISA: sem mudanças para %s", cnpj_fmt)
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt, "fonte": self.fonte, "ciclo": ciclo,
            "hash_dados": hash_novo, "dados": dados or {},
        }])

        if not dados:
            return [{
                "cnpj": cnpj_fmt, "ciclo": ciclo, "fonte": self.fonte,
                "categoria": "sanitario", "severidade": "ok",
                "titulo": "Sem registros de AFE/AE na ANVISA",
                "descricao": "CNPJ não encontrado na base de Autorização de Funcionamento de Empresa da ANVISA.",
                "is_novo": True,
            }]

        # Processar resposta da API
        # A API pode retornar lista ou objeto único
        registros = dados if isinstance(dados, list) else [dados]
        alertas   = []

        for emp in registros:
            situacao  = (emp.get("situacao") or emp.get("descricaoSituacao") or emp.get("des_situacao") or "N/D")
            tipo_afe  = (emp.get("tipoAfe") or emp.get("tipo") or "")
            num_afe   = (emp.get("numeroAfe") or emp.get("numero") or "")
            dt_venc   = (emp.get("dataVencimento") or emp.get("dataValidade") or "")
            razao_api = (emp.get("razaoSocial") or emp.get("nome") or razao_social or "")

            sev = _severity(str(situacao))

            alertas.append({
                "cnpj": cnpj_fmt, "ciclo": ciclo, "fonte": self.fonte,
                "categoria": "sanitario",
                "severidade": sev,
                "titulo": f"ANVISA AFE/AE — Situação: {situacao}",
                "descricao": (
                    f"Empresa: {razao_api}. "
                    f"Tipo: {tipo_afe}. Número AFE: {num_afe}. "
                    f"Situação: {situacao}. Vencimento: {dt_venc}."
                ),
                "referencia_id": str(num_afe),
                "data_evento": _parse_date(str(dt_venc)),
                "url_fonte": "https://consultas.anvisa.gov.br/",
                "is_novo": True,
            })

        logger.info("ANVISA: %d alertas para %s", len(alertas), cnpj_fmt)
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
