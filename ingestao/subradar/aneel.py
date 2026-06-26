"""
Conector: ANEEL — Autos de Infração do Setor Elétrico

Tabela local: sub_aneel_autos
Seed: python -m ingestao.subradar.aneel_seeder

CSV: dadosabertos.aneel.gov.br — campo NumCPFCNPJAgenteFiscalizado (14 dígitos = CNPJ)
"""
from __future__ import annotations

import logging
import os
import re

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.aneel")

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SUPABASE_KEY = (
    os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    or os.environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY")
    or ""
)

SITUACOES_CRITICO = {
    "multa", "auto lavrado", "em trâmite", "improcedente parcial",
    "procedente", "aplicada",
}
SITUACOES_ATENCAO = {
    "advertência", "notificação", "pendente", "recurso",
}


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", str(cnpj or ""))


def _fmt(cnpj: str) -> str:
    c = _strip(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _query_local(cnpj_digits: str) -> list[dict]:
    if not SUPABASE_URL or not SUPABASE_KEY:
        return []
    import requests as req
    r = req.get(
        f"{SUPABASE_URL}/rest/v1/sub_aneel_autos",
        params={"cnpj": f"eq.{cnpj_digits}"},
        headers={
            "apikey": SUPABASE_KEY,
            "Authorization": f"Bearer {SUPABASE_KEY}",
            "Accept": "application/json",
        },
        timeout=15,
    )
    return r.json() if r.ok and isinstance(r.json(), list) else []


def _severity(decisao: str, penalidade: str) -> str:
    d = (decisao or "").lower()
    p = (penalidade or "").lower()
    combined = d + " " + p
    if any(k in combined for k in SITUACOES_CRITICO):
        return "critico"
    if any(k in combined for k in SITUACOES_ATENCAO):
        return "atencao"
    return "info"


class ANEELConnector(SubradarSource):
    fonte = "aneel"

    def consultar_cnpj(self, cnpj: str, razao_social: str | None = None) -> list[dict]:
        cnpj_limpo = _strip(cnpj)
        cnpj_fmt   = _fmt(cnpj_limpo)
        ciclo      = _ciclo_atual()

        registros = _query_local(cnpj_limpo)

        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, registros)
        if not mudou:
            logger.info("ANEEL: sem mudanças para %s", cnpj_fmt)
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt, "fonte": self.fonte, "ciclo": ciclo,
            "hash_dados": hash_novo, "dados": {"total": len(registros)},
        }])

        if not registros:
            return [{
                "cnpj": cnpj_fmt, "ciclo": ciclo, "fonte": self.fonte,
                "categoria": "regulatorio", "severidade": "ok",
                "titulo": "Sem autos de infração ANEEL",
                "descricao": "CNPJ não encontrado na base de Autos de Infração da ANEEL.",
                "url_fonte": "https://dadosabertos.aneel.gov.br/dataset/auto-de-infracao",
                "is_novo": True,
            }]

        alertas = []
        seen: set[str] = set()
        for r in registros:
            num = r.get("num_auto_infracao") or ""
            if num in seen:
                continue
            seen.add(num)

            penalidade = r.get("dsc_tipo_penalidade") or ""
            decisao    = r.get("dsc_decisao_juizo") or r.get("dsc_decisao_diretoria") or ""
            sev        = _severity(decisao, penalidade)

            val = r.get("vlr_penalidade") or 0
            try:
                val_fmt = f"R$ {float(val):,.2f}" if val else "N/D"
            except Exception:
                val_fmt = str(val)

            alertas.append({
                "cnpj": cnpj_fmt, "ciclo": ciclo, "fonte": self.fonte,
                "categoria": "regulatorio",
                "severidade": sev,
                "titulo": f"Auto de Infração ANEEL nº {num} — {penalidade or 'N/D'}",
                "descricao": (
                    f"Natureza: {r.get('nom_natureza_fiscalizacao','N/D')}. "
                    f"Penalidade: {val_fmt}. "
                    f"Decisão: {decisao[:100] or 'Pendente'}. "
                    f"Data: {r.get('dat_lavratura','N/D')}."
                ),
                "referencia_id": num,
                "data_evento": _parse_date(r.get("dat_lavratura", "")),
                "url_fonte": "https://dadosabertos.aneel.gov.br/dataset/auto-de-infracao",
                "is_novo": True,
            })

        logger.info("ANEEL: %d alertas para %s", len(alertas), cnpj_fmt)
        return alertas


def _parse_date(s: str) -> str | None:
    if not s:
        return None
    for fmt in ("%Y-%m-%d", "%d/%m/%Y"):
        try:
            from datetime import datetime
            return datetime.strptime(s.strip()[:10], fmt).date().isoformat()
        except ValueError:
            continue
    return None
