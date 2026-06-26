"""
Conector: Lista Suja MTE — Cadastro de Empregadores com Trabalho Escravo

Estratégia: seed semestral via PDF oficial → tabela local sub_lista_suja.
Filtro por CNPJ feito localmente.

Seed: python -m ingestao.subradar.lista_suja_seeder
Tabela: sub_lista_suja
Frequência: semestral (abril e outubro)
"""
from __future__ import annotations

import logging
import re

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.lista_suja")

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
    r = req.get(
        f"{SUPABASE_URL}/rest/v1/sub_lista_suja",
        params={"cpf_cnpj": f"eq.{cnpj_digits}"},
        headers={
            "apikey": SUPABASE_KEY,
            "Authorization": f"Bearer {SUPABASE_KEY}",
            "Accept": "application/json",
        },
        timeout=15,
    )
    return r.json() if r.ok and isinstance(r.json(), list) else []


class ListaSujaConnector(SubradarSource):
    fonte = "lista_suja_mte"

    def consultar_cnpj(self, cnpj: str, razao_social: str | None = None) -> list[dict]:
        cnpj_limpo = _strip(cnpj)
        cnpj_fmt   = _fmt(cnpj_limpo)
        ciclo      = _ciclo_atual()

        registros = _query_local(cnpj_limpo)

        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, registros)
        if not mudou:
            logger.info("Lista Suja: sem mudanças para %s", cnpj_fmt)
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt, "fonte": self.fonte, "ciclo": ciclo,
            "hash_dados": hash_novo, "dados": {"total": len(registros)},
        }])

        if not registros:
            return [{
                "cnpj": cnpj_fmt, "ciclo": ciclo, "fonte": self.fonte,
                "categoria": "trabalhista", "severidade": "ok",
                "titulo": "Sem registros na Lista Suja do MTE",
                "descricao": "CNPJ não consta no Cadastro de Empregadores que submeteram trabalhadores a condições análogas à escravidão.",
                "url_fonte": "https://www.gov.br/trabalho-e-emprego/pt-br/assuntos/inspecao-do-trabalho/areas-de-atuacao/combate-ao-trabalho-escravo",
                "is_novo": True,
            }]

        alertas = []
        for r in registros:
            nome        = r.get("nome_empregador") or razao_social or cnpj_fmt
            uf          = r.get("uf") or ""
            municipio   = r.get("municipio") or ""
            dt_inclusao = r.get("dat_inclusao") or ""
            trabalhadores = r.get("qtd_trabalhadores") or ""
            decisao     = r.get("decisao_judicial") or ""

            alertas.append({
                "cnpj": cnpj_fmt, "ciclo": ciclo, "fonte": self.fonte,
                "categoria": "trabalhista",
                "severidade": "critico",
                "titulo": f"LISTA SUJA MTE — Trabalho Análogo à Escravidão",
                "descricao": (
                    f"Empregador '{nome}' inscrito no Cadastro de Empregadores do MTE. "
                    f"Local: {municipio}/{uf}. "
                    f"Inclusão: {dt_inclusao}. "
                    f"Trabalhadores resgatados: {trabalhadores}. "
                    f"{decisao}"
                ),
                "data_evento": _parse_date(dt_inclusao),
                "url_fonte": "https://www.gov.br/trabalho-e-emprego/pt-br/assuntos/inspecao-do-trabalho/areas-de-atuacao/combate-ao-trabalho-escravo",
                "is_novo": True,
            })

        logger.info("Lista Suja: %d alertas para %s", len(alertas), cnpj_fmt)
        return alertas


def _parse_date(s: str) -> str | None:
    if not s:
        return None
    for fmt in ("%d/%m/%Y", "%Y-%m-%d", "%m/%Y"):
        try:
            from datetime import datetime
            return datetime.strptime(s.strip(), fmt).date().isoformat()
        except ValueError:
            continue
    return None
