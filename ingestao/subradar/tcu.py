"""
Conector: TCU — Certidão de Regularidade

Situação (jun/2026):
  - certificados.tcu.gov.br: sem DNS externo (intranet TCU)
  - pesquisa.apps.tcu.gov.br: busca full-text não retorna resultados por CNPJ numérico
  - API REST interna: bloqueada por WAF para User-Agents não-browser

Estratégia atual: gera alerta `info` com link direto para verificação manual.
O analista acessa o portal TCU e emite a certidão com o CNPJ.
"""
from __future__ import annotations

import logging
import re

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.tcu")

PORTAL_URL = "https://pesquisa.apps.tcu.gov.br/#/juris"
CERT_MANUAL = "https://portal.tcu.gov.br/transparencia/certidao/"


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", str(cnpj or ""))


def _fmt(cnpj: str) -> str:
    c = _strip(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


class TCUConnector(SubradarSource):
    fonte         = "tcu"
    request_delay = 0.0

    def consultar_cnpj(self, cnpj: str, razao_social: str | None = None) -> list[dict]:
        cnpj_limpo = _strip(cnpj)
        cnpj_fmt   = _fmt(cnpj_limpo)
        ciclo      = _ciclo_atual()

        dados = {"cnpj": cnpj_fmt, "verificacao": "manual"}
        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, dados)
        if not mudou:
            logger.info("TCU: sem mudanças para %s", cnpj_fmt)
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt, "fonte": self.fonte, "ciclo": ciclo,
            "hash_dados": hash_novo,
            "dados": {"status": "verificacao_manual"},
        }])

        return [{
            "cnpj": cnpj_fmt, "ciclo": ciclo, "fonte": self.fonte,
            "categoria": "judicial",
            "severidade": "info",
            "titulo": "TCU — Certidão requer verificação manual",
            "descricao": (
                f"A certidão de regularidade junto ao TCU não é acessível via API pública. "
                f"Verifique manualmente: acesse {CERT_MANUAL}, informe o CNPJ {cnpj_fmt} "
                f"e emita a certidão. Busca de acórdãos disponível em {PORTAL_URL}."
            ),
            "url_fonte": CERT_MANUAL,
            "is_novo": True,
        }]
