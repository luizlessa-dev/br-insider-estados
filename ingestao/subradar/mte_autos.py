"""
Conector: MTE — Autos de Infração Trabalhista

Estratégia: bulk seed mensal via dados abertos do Ministério do Trabalho.
Tabela local: sub_mte_autos

Cobre: horas extras não pagas, ausência de registro, jornada excessiva,
condições insalubres, assédio, trabalho infantil (além da lista suja).

Seed: python -m ingestao.subradar.mte_autos_seeder
URL dos dados: https://dados.mte.gov.br/dataset/ait
"""
from __future__ import annotations

import logging
import re

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.mte_autos")

SUPABASE_URL = __import__("os").environ.get("SUPABASE_URL", "").rstrip("/")
SUPABASE_KEY = (
    __import__("os").environ.get("SUPABASE_SERVICE_ROLE_KEY")
    or __import__("os").environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY")
    or ""
)

SITUACOES_CRITICO = {
    "auto lavrado", "lavrado", "julgado procedente", "multa aplicada",
    "embargado", "interditado",
}
SITUACOES_ATENCAO = {
    "recurso", "em análise", "pendente", "notificação",
}


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", cnpj)


def _fmt(cnpj: str) -> str:
    c = _strip(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _query_local(cnpj_digits: str) -> list[dict]:
    if not SUPABASE_URL or not SUPABASE_KEY:
        return []
    import requests as req
    r = req.get(
        f"{SUPABASE_URL}/rest/v1/sub_mte_autos",
        params={"cnpj": f"eq.{cnpj_digits}"},
        headers={
            "apikey": SUPABASE_KEY,
            "Authorization": f"Bearer {SUPABASE_KEY}",
            "Accept": "application/json",
        },
        timeout=15,
    )
    return r.json() if r.ok and isinstance(r.json(), list) else []


class MTEAutosConnector(SubradarSource):
    fonte = "mte_autos"

    def consultar_cnpj(self, cnpj: str, razao_social: str | None = None) -> list[dict]:
        cnpj_limpo = _strip(cnpj)
        cnpj_fmt   = _fmt(cnpj_limpo)
        ciclo      = _ciclo_atual()

        registros = _query_local(cnpj_limpo)

        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, registros)
        if not mudou:
            logger.info("MTE Autos: sem mudanças para %s", cnpj_fmt)
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt, "fonte": self.fonte, "ciclo": ciclo,
            "hash_dados": hash_novo, "dados": {"total": len(registros)},
        }])

        if not registros:
            return [{
                "cnpj": cnpj_fmt, "ciclo": ciclo, "fonte": self.fonte,
                "categoria": "trabalhista", "severidade": "ok",
                "titulo": "Sem autos de infração trabalhista (MTE)",
                "descricao": "CNPJ não encontrado na base de Autos de Infração Trabalhista do Ministério do Trabalho.",
                "url_fonte": "https://dados.mte.gov.br/dataset/ait",
                "is_novo": True,
            }]

        alertas = []
        seen: set[str] = set()
        for r in registros:
            num_ait  = r.get("num_ait") or ""
            if num_ait in seen:
                continue
            seen.add(num_ait)

            situacao = (r.get("des_situacao") or "").strip().lower()
            if any(k in situacao for k in SITUACOES_CRITICO):
                sev = "critico"
            elif any(k in situacao for k in SITUACOES_ATENCAO):
                sev = "atencao"
            else:
                sev = "info"

            val = r.get("val_multa") or ""
            try:
                val_fmt = f"R$ {float(val):,.2f}" if val else "N/D"
            except Exception:
                val_fmt = str(val)

            alertas.append({
                "cnpj": cnpj_fmt, "ciclo": ciclo, "fonte": self.fonte,
                "categoria": "trabalhista",
                "severidade": sev,
                "titulo": f"Auto de Infração MTE nº {num_ait} — {r.get('des_situacao','N/D')}",
                "descricao": (
                    f"Infração: {(r.get('des_infracao') or '')[:200]}. "
                    f"Multa: {val_fmt}. "
                    f"Data: {r.get('dat_ait','')}. "
                    f"UF: {r.get('sig_uf','')}."
                ),
                "referencia_id": num_ait,
                "data_evento": _parse_date(r.get("dat_ait", "")),
                "url_fonte": "https://dados.mte.gov.br/dataset/ait",
                "is_novo": True,
            })

        logger.info("MTE Autos: %d alertas para %s", len(alertas), cnpj_fmt)
        return alertas


def _parse_date(s: str) -> str | None:
    if not s:
        return None
    for fmt in ("%d/%m/%Y", "%Y-%m-%d"):
        try:
            from datetime import datetime
            return datetime.strptime(s.strip()[:10], fmt).date().isoformat()
        except ValueError:
            continue
    return None
