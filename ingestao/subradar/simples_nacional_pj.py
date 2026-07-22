"""
Conector: Simples Nacional / MEI — situação tributária da PJ via RFB

API primária:
  GET https://www.receita.fazenda.gov.br/pessoajuridica/simples/cnpj/{cnpj14}.json
  (pública, sem autenticação)

Resposta esperada:
  {
    "cnpj": "...",
    "razao_social": "...",
    "opcao_pelo_simples": true/false,
    "data_opcao_simples": "YYYY-MM-DD",
    "data_exclusao_simples": "YYYY-MM-DD",   # preenchido se excluído
    "opcao_pelo_mei": true/false
  }

Lógica de alertas (informacional — sem sinalização de risco):
  - Optante ativo pelo Simples ou MEI  → [] (positivo, sem alerta)
  - Exclusão recente do Simples (≤ 12 meses) → info (mudança de regime)
  - CNPJ de porte ME/EPP nunca optante  → info (possível exclusão antiga ou não adesão)
  - API indisponível                    → [] gracioso
"""
from __future__ import annotations

import logging
import re
from datetime import date, datetime

import requests

from .base import SubradarSource, _ciclo_atual, snapshot_changed, upsert

logger = logging.getLogger("subradar.simples_nacional")

_API_BASE   = "https://www.receita.fazenda.gov.br/pessoajuridica/simples/cnpj"
_URL_PORTAL = "https://www8.receita.fazenda.gov.br/SimplesNacional/"

# Portes que deveriam (potencialmente) aderir ao Simples
_PORTES_ELEGIVEIS = {"ME", "EPP"}


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", cnpj)


def _fmt(cnpj: str) -> str:
    c = _strip(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _parse_date(valor: str | None) -> date | None:
    if not valor:
        return None
    for fmt in ("%Y-%m-%d", "%d/%m/%Y", "%Y%m%d"):
        try:
            return datetime.strptime(valor, fmt).date()
        except (ValueError, TypeError):
            continue
    return None


def _exclusao_recente(data_exclusao: date | None, meses: int = 12) -> bool:
    if data_exclusao is None:
        return False
    hoje = date.today()
    delta = (hoje - data_exclusao).days
    return 0 <= delta <= meses * 30


class SimplesNacionalConnector(SubradarSource):
    """Verifica situação no Simples Nacional e MEI via API pública da RFB."""

    fonte         = "simples_nacional"
    request_delay = 1.5
    timeout       = 20

    # -----------------------------------------------------------------
    # Busca
    # -----------------------------------------------------------------

    def _fetch_api(self, cnpj14: str) -> dict | None:
        """Consulta a API JSON da RFB. Retorna dict, {} (não encontrado) ou None (erro)."""
        url = f"{_API_BASE}/{cnpj14}.json"
        try:
            r = self._session.get(url, timeout=self.timeout, headers={"Accept": "application/json"})
            if r.status_code == 404:
                return {}
            if r.status_code in (503, 504, 429):
                logger.warning("Simples Nacional: API indisponível (%d) para %s", r.status_code, cnpj14)
                return None
            r.raise_for_status()
            return r.json()
        except requests.exceptions.Timeout:
            logger.warning("Simples Nacional: timeout para %s", cnpj14)
            return None
        except requests.exceptions.RequestException as exc:
            logger.warning("Simples Nacional: erro de rede para %s — %s", cnpj14, exc)
            return None

    # -----------------------------------------------------------------
    # Interface principal
    # -----------------------------------------------------------------

    def consultar_cnpj(
        self,
        cnpj: str,
        razao_social: str | None = None,
        porte: str | None = None,
        **_,
    ) -> list[dict]:
        """
        Parâmetros extras (opcionais):
          razao_social — nome da empresa (para enriquecer descrição)
          porte        — sigla do porte ("ME", "EPP", "DEMAIS", …); quando fornecido,
                         permite alertar sobre ME/EPP nunca optantes
        """
        cnpj14   = _strip(cnpj)
        cnpj_fmt = _fmt(cnpj14)
        ciclo    = _ciclo_atual()

        dados = self._fetch_api(cnpj14)

        if dados is None:
            # Serviço indisponível — retorna graciosamente
            return []

        # -----------------------------------------------------------------
        # Snapshot — evita reprocessar ciclos sem mudança
        # -----------------------------------------------------------------
        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, dados)
        if not mudou:
            logger.info("Simples Nacional: sem mudanças para %s", cnpj_fmt)
            return []

        upsert("sub_snapshots", [{
            "cnpj":       cnpj_fmt,
            "fonte":      self.fonte,
            "ciclo":      ciclo,
            "hash_dados": hash_novo,
            "dados":      dados,
        }])

        if not dados:
            logger.info("Simples Nacional: CNPJ %s não encontrado", cnpj_fmt)
            return []

        # -----------------------------------------------------------------
        # Extrai campos
        # -----------------------------------------------------------------
        nome              = dados.get("razao_social") or razao_social or cnpj_fmt
        optante_simples   = bool(dados.get("opcao_pelo_simples"))
        optante_mei       = bool(dados.get("opcao_pelo_mei"))
        data_opt_simples  = _parse_date(dados.get("data_opcao_simples"))
        data_excl_simples = _parse_date(dados.get("data_exclusao_simples"))

        porte_norm = (porte or "").upper().strip()

        # -----------------------------------------------------------------
        # Lógica de alertas
        # -----------------------------------------------------------------

        # 1. Optante ativo pelo Simples ou MEI → nada a destacar
        if optante_simples and not data_excl_simples:
            logger.info("Simples Nacional: %s optante ativo pelo Simples", cnpj_fmt)
            return []

        if optante_mei:
            logger.info("Simples Nacional: %s optante MEI", cnpj_fmt)
            return []

        alertas: list[dict] = []

        # 2. Exclusão recente do Simples
        if data_excl_simples and _exclusao_recente(data_excl_simples):
            dt_excl_str = data_excl_simples.isoformat()
            descricao = (
                f"A empresa '{nome}' foi excluída do Simples Nacional em {dt_excl_str}, "
                f"nos últimos 12 meses. Isso indica mudança de regime tributário — "
                f"a empresa pode ter migrado para Lucro Presumido ou Real."
            )
            if data_opt_simples:
                descricao += f" Era optante desde {data_opt_simples.isoformat()}."
            alertas.append({
                "cnpj":         cnpj_fmt,
                "ciclo":        ciclo,
                "fonte":        self.fonte,
                "categoria":    "cadastral",
                "severidade":   "info",
                "titulo":       "Exclusão recente do Simples Nacional",
                "descricao":    descricao,
                "data_evento":  dt_excl_str,
                "url_fonte":    _URL_PORTAL,
                "referencia_id": f"excl_simples_{cnpj14}_{dt_excl_str}",
                "is_novo":      True,
            })

        # 3. Porte ME/EPP nunca optante (ou excluído há mais de 12 meses)
        elif porte_norm in _PORTES_ELEGIVEIS and not optante_simples:
            motivo = (
                "nunca aderiu ao Simples Nacional"
                if not data_excl_simples
                else f"foi excluída do Simples em {data_excl_simples.isoformat()}"
            )
            descricao = (
                f"A empresa '{nome}' tem porte {porte_norm} mas {motivo}. "
                f"Empresas de pequeno porte elegíveis que não optam pelo Simples "
                f"ou foram excluídas geralmente operam sob regime de Lucro Presumido "
                f"ou possuem algum impeditivo legal (débitos, atividade vedada, etc.)."
            )
            alertas.append({
                "cnpj":         cnpj_fmt,
                "ciclo":        ciclo,
                "fonte":        self.fonte,
                "categoria":    "cadastral",
                "severidade":   "info",
                "titulo":       f"Empresa {porte_norm} não optante pelo Simples Nacional",
                "descricao":    descricao,
                "data_evento":  (data_excl_simples.isoformat() if data_excl_simples else None),
                "url_fonte":    _URL_PORTAL,
                "referencia_id": f"nao_optante_{cnpj14}",
                "is_novo":      True,
            })

        return alertas
