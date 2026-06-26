"""
Conector: Situação Cadastral RFB — CNPJ ativo/suspenso/inapto/baixado

API: publica.cnpj.ws (sem auth, 3 req/min por IP)
Rate limit: backoff automático em 429.

Situações críticas para compliance:
  4 = INAPTA   → critico (RFB suspendeu por omissão de declarações)
  8 = BAIXADA  → critico (encerrada)
  3 = SUSPENSA → atencao
  2 = ATIVA    → ok
"""
from __future__ import annotations

import logging
import re
import time

import requests as req

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.situacao_cadastral")

CNPJWS_BASE = "https://publica.cnpj.ws/cnpj"

SITUACAO_MAP = {
    1: ("NULA",     "critico"),
    2: ("ATIVA",    "ok"),
    3: ("SUSPENSA", "atencao"),
    4: ("INAPTA",   "critico"),
    8: ("BAIXADA",  "critico"),
}


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", cnpj)


def _fmt(cnpj: str) -> str:
    c = _strip(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


class SituacaoCadastralConnector(SubradarSource):
    fonte         = "situacao_cadastral"
    request_delay = 20.0   # 3 req/min = 1 req/20s

    def _fetch(self, cnpj_limpo: str) -> dict | None:
        for attempt in range(3):
            try:
                r = req.get(
                    f"{CNPJWS_BASE}/{cnpj_limpo}",
                    timeout=20,
                    headers={"Accept": "application/json"},
                )
                if r.status_code == 429:
                    wait = 65 + attempt * 30
                    logger.warning("Situação Cadastral: rate limit — aguardando %ds", wait)
                    time.sleep(wait)
                    continue
                if r.status_code == 404:
                    return {}
                r.raise_for_status()
                return r.json()
            except req.exceptions.Timeout:
                logger.warning("Situação Cadastral: timeout (tentativa %d)", attempt + 1)
                if attempt < 2:
                    time.sleep(5)
        return None

    def consultar_cnpj(self, cnpj: str, razao_social: str | None = None) -> list[dict]:
        cnpj_limpo = _strip(cnpj)
        cnpj_fmt   = _fmt(cnpj_limpo)
        ciclo      = _ciclo_atual()

        dados = self._fetch(cnpj_limpo)

        if dados is None:
            logger.warning("Situação Cadastral: não foi possível consultar %s", cnpj_fmt)
            return []

        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, dados)
        if not mudou:
            logger.info("Situação Cadastral: sem mudanças para %s", cnpj_fmt)
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt, "fonte": self.fonte, "ciclo": ciclo,
            "hash_dados": hash_novo,
            "dados": {k: dados.get(k) for k in (
                "situacao_cadastral", "descricao_situacao_cadastral",
                "data_situacao_cadastral", "motivo_situacao_cadastral",
                "descricao_motivo_situacao_cadastral", "razao_social",
            )},
        }])

        if not dados:
            return [{
                "cnpj": cnpj_fmt, "ciclo": ciclo, "fonte": self.fonte,
                "categoria": "cadastral", "severidade": "atencao",
                "titulo": "CNPJ não encontrado na RFB",
                "descricao": "CNPJ não localizado na base da Receita Federal (publica.cnpj.ws).",
                "url_fonte": f"https://solucoes.receita.fazenda.gov.br/Servicos/cnpjreva/Cnpjreva_Solicitacao.asp",
                "is_novo": True,
            }]

        cod_sit  = dados.get("situacao_cadastral") or 2
        sit_nome, severidade = SITUACAO_MAP.get(int(cod_sit), ("DESCONHECIDA", "atencao"))
        motivo   = dados.get("descricao_motivo_situacao_cadastral") or "Sem motivo informado"
        dt_sit   = dados.get("data_situacao_cadastral") or ""
        razao_api = dados.get("razao_social") or razao_social or cnpj_fmt
        try:
            capital = float(dados.get("capital_social") or 0)
        except (TypeError, ValueError):
            capital = 0.0
        porte    = (dados.get("porte") or {}).get("descricao") or ""
        dt_ini   = dados.get("data_inicio_atividade") or ""

        # Sócios — resumo para o alerta
        socios_raw = dados.get("socios") or []
        socios_nomes = "; ".join(
            s.get("nome") or s.get("razao_social") or ""
            for s in socios_raw[:5]
        )

        if severidade == "ok":
            descricao = (
                f"Empresa '{razao_api}' com situação cadastral ATIVA na RFB. "
                f"Porte: {porte}. Capital social: R$ {capital:,.2f}. "
                f"Início de atividade: {dt_ini}."
            )
        else:
            descricao = (
                f"Empresa '{razao_api}' com situação {sit_nome} na RFB. "
                f"Motivo: {motivo}. Data da situação: {dt_sit}. "
                f"Porte: {porte}. Capital social: R$ {capital:,.2f}."
            )

        if socios_nomes:
            descricao += f" Sócios: {socios_nomes}."

        logger.info("Situação Cadastral: %s — %s (%s)", cnpj_fmt, sit_nome, severidade)
        return [{
            "cnpj": cnpj_fmt, "ciclo": ciclo, "fonte": self.fonte,
            "categoria": "cadastral",
            "severidade": severidade,
            "titulo": f"Situação Cadastral RFB — {sit_nome}",
            "descricao": descricao,
            "data_evento": dt_sit or None,
            "url_fonte": f"https://solucoes.receita.fazenda.gov.br/Servicos/cnpjreva/Cnpjreva_Solicitacao.asp",
            "is_novo": True,
        }]
