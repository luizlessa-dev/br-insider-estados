"""
Conector: ANS — Operadoras de Planos de Saúde (situação cadastral + irregularidades)

Tabela local: sub_ans_operadoras (seed via CSV)
Também consulta em tempo real a API pública ANS para verificar situação atual.

CSV: dadosabertos.ans.gov.br/FTP/PDA/operadoras_de_plano_de_saude_ativas/Relatorio_cadop.csv
API tempo real: www.ans.gov.br/planos-de-saude-e-operadoras/

Relevante para: hospitais, clínicas, planos de saúde, administradoras de benefícios.
"""
from __future__ import annotations

import logging
import os
import re

import requests as req

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.ans")

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SUPABASE_KEY = (
    os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    or os.environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY")
    or ""
)

# API pública ANS por número de registro (não por CNPJ diretamente)
ANS_API = "https://www.ans.gov.br/planos-de-saude-e-operadoras/informacoes-e-avaliacoes-de-operadoras/situacao-das-operadoras"

SITUACOES_CRITICO = {
    "cancelada", "cancelado", "em liquidação extrajudicial",
    "em regime de direção fiscal", "intervenção", "massa falida",
}
SITUACOES_ATENCAO = {
    "em processo de cancelamento", "sob monitoramento especial",
    "em funcionamento precário", "suspensa",
}


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", str(cnpj or ""))


def _fmt(cnpj: str) -> str:
    c = _strip(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _query_local(cnpj_digits: str) -> list[dict]:
    if not SUPABASE_URL or not SUPABASE_KEY:
        return []
    r = req.get(
        f"{SUPABASE_URL}/rest/v1/sub_ans_operadoras",
        params={"cnpj": f"eq.{cnpj_digits}"},
        headers={
            "apikey": SUPABASE_KEY,
            "Authorization": f"Bearer {SUPABASE_KEY}",
            "Accept": "application/json",
        },
        timeout=15,
    )
    return r.json() if r.ok and isinstance(r.json(), list) else []


def _severity(situacao: str) -> str:
    s = situacao.lower().strip()
    if any(k in s for k in SITUACOES_CRITICO):
        return "critico"
    if any(k in s for k in SITUACOES_ATENCAO):
        return "atencao"
    return "ok"


class ANSConnector(SubradarSource):
    fonte = "ans"

    def consultar_cnpj(self, cnpj: str, razao_social: str | None = None) -> list[dict]:
        cnpj_limpo = _strip(cnpj)
        cnpj_fmt   = _fmt(cnpj_limpo)
        ciclo      = _ciclo_atual()

        registros = _query_local(cnpj_limpo)

        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, registros)
        if not mudou:
            logger.info("ANS: sem mudanças para %s", cnpj_fmt)
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt, "fonte": self.fonte, "ciclo": ciclo,
            "hash_dados": hash_novo, "dados": {"total": len(registros)},
        }])

        if not registros:
            return [{
                "cnpj": cnpj_fmt, "ciclo": ciclo, "fonte": self.fonte,
                "categoria": "regulatorio", "severidade": "ok",
                "titulo": "Sem registro como operadora de plano de saúde (ANS)",
                "descricao": "CNPJ não encontrado no cadastro de operadoras ativas da ANS.",
                "url_fonte": "https://www.ans.gov.br/planos-de-saude-e-operadoras",
                "is_novo": True,
            }]

        alertas = []
        for r in registros:
            situacao  = r.get("situacao") or "N/D"
            modalidade = r.get("modalidade") or ""
            registro  = r.get("registro_ans") or ""
            nome      = r.get("razao_social") or razao_social or cnpj_fmt
            sev       = _severity(situacao)

            alertas.append({
                "cnpj": cnpj_fmt, "ciclo": ciclo, "fonte": self.fonte,
                "categoria": "regulatorio",
                "severidade": sev,
                "titulo": f"ANS — {nome} ({modalidade}) — Situação: {situacao}",
                "descricao": (
                    f"Operadora de plano de saúde registrada na ANS. "
                    f"Registro ANS: {registro}. Modalidade: {modalidade}. "
                    f"Situação: {situacao}. Região: {r.get('regiao','N/D')}."
                ),
                "referencia_id": registro,
                "url_fonte": f"https://www.ans.gov.br/planos-de-saude-e-operadoras/informacoes-e-avaliacoes-de-operadoras/situacao-das-operadoras",
                "is_novo": True,
            })

        logger.info("ANS: %d registros para %s", len(alertas), cnpj_fmt)
        return alertas
