"""
Conector: IBAMA — Autos de Infração Ambiental

Estratégia: bulk seed mensal (ZIP → CSV, ~130 MB descomprimido).
Sem autenticação. Filtro por CNPJ feito localmente na tabela sub_ibama.

Seed: python -m ingestao.subradar.ibama_seeder
Tabela local: sub_ibama
"""
from __future__ import annotations

import logging
import re

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.ibama")

SUPABASE_URL = __import__("os").environ.get("SUPABASE_URL", "").rstrip("/")
SUPABASE_KEY = (
    __import__("os").environ.get("SUPABASE_SERVICE_ROLE_KEY")
    or __import__("os").environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY")
    or ""
)


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", cnpj)


def _fmt(cnpj: str) -> str:
    c = _strip(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _query_local(cnpj_digits: str) -> list[dict]:
    """Consulta sub_ibama por CPF_CNPJ_INFRATOR (dígitos)."""
    if not SUPABASE_URL or not SUPABASE_KEY:
        return []
    import requests as req
    url = f"{SUPABASE_URL}/rest/v1/sub_ibama"
    headers = {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Accept": "application/json",
    }
    r = req.get(url, params={"cpf_cnpj_infrator": f"eq.{cnpj_digits}"}, headers=headers, timeout=15)
    return r.json() if r.ok and isinstance(r.json(), list) else []


class IBAMAConnector(SubradarSource):
    fonte = "ibama"

    def consultar_cnpj(self, cnpj: str, razao_social: str | None = None) -> list[dict]:
        cnpj_limpo  = _strip(cnpj)
        cnpj_fmt    = _fmt(cnpj_limpo)
        ciclo       = _ciclo_atual()

        # dedup por num_auto_infracao (mesmo auto pode aparecer em múltiplos registros)
        raw = _query_local(cnpj_limpo)
        seen: set[str] = set()
        registros = []
        for r in raw:
            key = r.get("num_auto_infracao") or str(r.get("id", ""))
            if key not in seen:
                seen.add(key)
                registros.append(r)

        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, registros)
        if not mudou:
            logger.info("IBAMA: sem mudanças para %s", cnpj_fmt)
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt, "fonte": self.fonte, "ciclo": ciclo,
            "hash_dados": hash_novo, "dados": {"total": len(registros)},
        }])

        if not registros:
            return [{
                "cnpj": cnpj_fmt, "ciclo": ciclo, "fonte": self.fonte,
                "categoria": "ambiental", "severidade": "ok",
                "titulo": "Sem autos de infração no IBAMA",
                "descricao": "CNPJ não encontrado na base de autos de infração ambiental do IBAMA.",
                "is_novo": True,
            }]

        alertas = []
        for r in registros:
            situacao   = (r.get("des_situacao_auto") or "").strip()
            valor      = r.get("val_auto_infracao") or ""
            numero     = r.get("num_auto_infracao") or ""
            data_auto  = r.get("dat_auto_de_infracao") or ""
            infração   = r.get("des_infracao") or ""
            uf         = r.get("sig_uf") or ""
            municipio  = r.get("nom_municipio") or ""
            processo   = r.get("num_processo") or ""

            situacao_lower = situacao.lower()
            if any(k in situacao_lower for k in ["ativo", "embargado", "lavrado", "julgado procedente"]):
                severidade = "critico"
            elif any(k in situacao_lower for k in ["recurso", "pendente", "sobrestado"]):
                severidade = "atencao"
            else:
                severidade = "info"

            valor_fmt = f"R$ {float(valor):,.2f}".replace(",", "X").replace(".", ",").replace("X", ".") if valor else "N/D"

            alertas.append({
                "cnpj": cnpj_fmt, "ciclo": ciclo, "fonte": self.fonte,
                "categoria": "ambiental",
                "severidade": severidade,
                "titulo": f"Auto de Infração IBAMA nº {numero} — {situacao}",
                "descricao": (
                    f"Auto lavrado em {data_auto} em {municipio}/{uf}. "
                    f"Infração: {infração[:200]}. "
                    f"Valor: {valor_fmt}. Processo: {processo}."
                ),
                "referencia_id": numero,
                "data_evento": _parse_date(data_auto),
                "url_fonte": "https://www.ibama.gov.br/fiscalizacao/auto-de-infracao",
                "is_novo": True,
            })

        logger.info("IBAMA: %d alertas para %s", len(alertas), cnpj_fmt)
        return alertas


def _parse_date(s: str) -> str | None:
    if not s:
        return None
    for fmt in ("%d/%m/%Y", "%Y-%m-%d", "%Y/%m/%d"):
        try:
            from datetime import datetime
            return datetime.strptime(s.strip(), fmt).date().isoformat()
        except ValueError:
            continue
    return None
