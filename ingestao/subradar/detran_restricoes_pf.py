"""
Conector: Infosimples — DETRAN Restrições (Pessoa Física)

Consulta restrições veiculares unificadas (RENAVAM/PLACA) para PF.
Cobertura: Nacional (todos os estados via integração Infosimples-DETRAN).
Custo: R$ 0,25/consulta (mensalidade mínima R$ 100/mês).

Tipos de restrição:
  - Judicial (bloqueio por decisão judicial)
  - Administrativa (licenciamento vencido, débito de multa, etc.)
  - Segurança (veículo roubado/furtado, suspeita de fraude)
  - Gravame (financiamento não quitado)

Env var: INFOSIMPLES_TOKEN
Documentação: https://infosimples.com/consultas/

Retorna alerta se encontrar restrições ativas.
Ausência de restrição não gera alerta (retorna resumo com status "limpo").
"""
from __future__ import annotations

import logging
import os
import re

import requests

from .base import SubradarSource

logger = logging.getLogger("subradar.detran_restricoes_pf")

TOKEN = os.environ.get("INFOSIMPLES_TOKEN", "")

_BASE = "https://api.infosimples.com/api/v2/consultas"
_ENDPOINT_PLACA = f"{_BASE}/detran/veiculo/placa"
_ENDPOINT_RENAVAM = f"{_BASE}/detran/veiculo/renavam"


def _strip_doc(s: str) -> str:
    """Remove caracteres não-numéricos."""
    return re.sub(r"\D", "", s)


def _consultar_detran(placa: str | None = None, renavam: str | None = None) -> dict:
    """Consulta restrições DETRAN na Infosimples."""
    if not TOKEN:
        return {}

    # Tentar por PLACA primeiro (formato: ABC-1234)
    if placa:
        placa_fmt = placa.upper().replace("-", "")
        if len(placa_fmt) == 7:
            try:
                resp = requests.get(
                    _ENDPOINT_PLACA,
                    params={
                        "token": TOKEN,
                        "placa": placa_fmt,
                        "timeout": 600,
                    },
                    timeout=30,
                )
                if resp.ok:
                    data = resp.json()
                    if data.get("code") == 200:
                        return data.get("data", {})
            except Exception as e:
                logger.debug("Infosimples DETRAN/placa: %s", e)

    # Fallback: RENAVAM (11 dígitos)
    if renavam:
        renavam_limpo = _strip_doc(renavam)
        if len(renavam_limpo) == 11:
            try:
                resp = requests.get(
                    _ENDPOINT_RENAVAM,
                    params={
                        "token": TOKEN,
                        "renavam": renavam_limpo,
                        "timeout": 600,
                    },
                    timeout=30,
                )
                if resp.ok:
                    data = resp.json()
                    if data.get("code") == 200:
                        return data.get("data", {})
            except Exception as e:
                logger.debug("Infosimples DETRAN/renavam: %s", e)

    return {}


class DetranRestricoesConnector(SubradarSource):
    """
    Consulta restrições DETRAN (unificadas) para PF via Infosimples.
    Gracioso se INFOSIMPLES_TOKEN não estiver configurado.
    """
    fonte = "infosimples_detran_restricoes"
    request_delay = 0.5

    def consultar_cnpj(self, cnpj_or_cpf: str, razao_social: str | None = None, **_) -> list[dict]:
        """Interface CNPJ não aplicável para este conector PF."""
        return []

    def resumo_pf(
        self,
        cpf: str,
        nome: str | None = None,
        placa: str | None = None,
        renavam: str | None = None,
    ) -> dict | None:
        """
        Retorna resumo de restrições DETRAN para PF.

        Args:
            cpf: CPF da pessoa física
            nome: Nome (não usado na consulta, apenas para log)
            placa: Placa do veículo (opcional)
            renavam: RENAVAM do veículo (opcional)

        Returns:
            dict com status "limpo" ou "alerta"
            None se TOKEN ausente ou sem placa/RENAVAM
        """
        if not TOKEN:
            logger.debug("detran_restricoes: INFOSIMPLES_TOKEN ausente — pulando")
            return None

        if not placa and not renavam:
            logger.debug("detran_restricoes: nenhuma placa ou RENAVAM fornecidos")
            return None

        resultado = _consultar_detran(placa=placa, renavam=renavam)

        # Resposta esperada:
        # {
        #   "tem_restricoes": bool,
        #   "restricoes": [{"tipo": "...", "motivo": "...", "data": "..."}, ...],
        #   "veiculo": {"placa": "...", "renavam": "...", "modelo": "...", ...}
        # }

        restricoes = resultado.get("restricoes", [])
        tem_restricoes = resultado.get("tem_restricoes", False) or bool(restricoes)
        veiculo_info = resultado.get("veiculo", {})

        placa_info = (placa or veiculo_info.get("placa") or "N/D").upper()
        modelo = veiculo_info.get("modelo", "N/D")

        if not tem_restricoes:
            logger.info("DETRAN Restrições: %s — sem restrições", placa_info)
            return {
                "fonte": self.fonte,
                "categoria": "trânsito",
                "status": "limpo",
                "titulo_secao": "Restrições DETRAN",
                "resumo": f"Nenhuma restrição encontrada ({placa_info})",
                "detalhes": {
                    "total_restricoes": 0,
                    "placa": placa_info,
                    "modelo": modelo,
                },
            }

        # Se houver restrições
        n_restricoes = len(restricoes)
        tipos = set()
        tem_judicial = False

        for r in restricoes:
            tipo = r.get("tipo", "").lower()
            tipos.add(tipo)
            if "judicial" in tipo:
                tem_judicial = True

        severidade = "critico" if tem_judicial else "atencao"
        tipos_txt = ", ".join(sorted(tipos)) if tipos else "Indefinida"

        logger.warning(
            "DETRAN Restrições: %s (%s) — %d restrição(ões) [%s]",
            placa_info, modelo, n_restricoes, tipos_txt,
        )

        return {
            "fonte": self.fonte,
            "categoria": "trânsito",
            "status": "alerta",
            "severidade": severidade,
            "titulo_secao": "Restrições DETRAN",
            "resumo": f"{n_restricoes} restrição(ões) — {tipos_txt}",
            "detalhes": {
                "total_restricoes": n_restricoes,
                "placa": placa_info,
                "modelo": modelo,
                "tipos": list(tipos),
                "restricoes": restricoes[:10],  # Top 10
            },
        }
