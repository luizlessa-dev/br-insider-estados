"""
Conector: CVM — Processos Administrativos Sancionadores (PAS)

Estratégia: bulk seed diário (ZIP → 2 CSVs: processo + acusados).
Sem autenticação. Filtro por CNPJ feito localmente na tabela sub_cvm_pas.

Seed: python -m ingestao.subradar.cvm_seeder
Tabela local: sub_cvm_pas
"""
from __future__ import annotations

import logging
import re

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.cvm")

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
    if not SUPABASE_URL or not SUPABASE_KEY:
        return []
    import requests as req
    url = f"{SUPABASE_URL}/rest/v1/sub_cvm_pas"
    headers = {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Accept": "application/json",
    }
    r = req.get(url, params={"cpf_cnpj": f"eq.{cnpj_digits}"}, headers=headers, timeout=15)
    return r.json() if r.ok and isinstance(r.json(), list) else []


class CVMConnector(SubradarSource):
    fonte = "cvm_pas"

    def consultar_cnpj(self, cnpj: str, razao_social: str | None = None) -> list[dict]:
        cnpj_limpo = _strip(cnpj)
        cnpj_fmt   = _fmt(cnpj_limpo)
        ciclo      = _ciclo_atual()

        registros = _query_local(cnpj_limpo)

        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, registros)
        if not mudou:
            logger.info("CVM PAS: sem mudanças para %s", cnpj_fmt)
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt, "fonte": self.fonte, "ciclo": ciclo,
            "hash_dados": hash_novo, "dados": {"total": len(registros)},
        }])

        if not registros:
            return [{
                "cnpj": cnpj_fmt, "ciclo": ciclo, "fonte": self.fonte,
                "categoria": "mercado_capitais", "severidade": "ok",
                "titulo": "Sem processos sancionadores na CVM",
                "descricao": "CNPJ não encontrado na base de Processos Administrativos Sancionadores da CVM.",
                "is_novo": True,
            }]

        alertas = []
        for r in registros:
            num_pas    = r.get("num_pas") or ""
            fase       = (r.get("des_fase") or "").strip()
            tipo_irr   = (r.get("des_tipo_irregularidade") or "").strip()
            sancao     = (r.get("des_sancao") or "").strip()
            val_multa  = r.get("val_multa")
            dt_julg    = r.get("dat_julgamento") or ""
            nome_ac    = r.get("nom_acusado") or ""
            orgao      = r.get("des_orgao_julgador") or "CVM"

            fase_lower = fase.lower()
            sancao_lower = sancao.lower()
            if any(k in sancao_lower for k in ["inabilitação", "proibição", "suspensão", "multa"]):
                severidade = "critico"
            elif any(k in fase_lower for k in ["julgamento", "acusação", "citação"]):
                severidade = "atencao"
            else:
                severidade = "info"

            multa_fmt = ""
            if val_multa:
                try:
                    multa_fmt = f" Multa: R$ {float(val_multa):,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")
                except Exception:
                    multa_fmt = f" Multa: {val_multa}"

            alertas.append({
                "cnpj": cnpj_fmt, "ciclo": ciclo, "fonte": self.fonte,
                "categoria": "mercado_capitais",
                "severidade": severidade,
                "titulo": f"PAS CVM {num_pas} — {fase} ({sancao or 'Em andamento'})",
                "descricao": (
                    f"Acusado: {nome_ac}. "
                    f"Irregularidade: {tipo_irr[:200]}. "
                    f"Fase: {fase}. Julgamento: {dt_julg}.{multa_fmt} "
                    f"Órgão: {orgao}."
                ),
                "referencia_id": num_pas,
                "data_evento": _parse_date(dt_julg),
                "url_fonte": f"https://sistemas.cvm.gov.br/?PAS&NumPAS={num_pas}" if num_pas else "https://dados.cvm.gov.br/dataset/processo-sancionador",
                "is_novo": True,
            })

        logger.info("CVM PAS: %d alertas para %s", len(alertas), cnpj_fmt)
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
