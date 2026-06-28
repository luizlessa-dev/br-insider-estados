"""
Conector: CADE — Conselho Administrativo de Defesa Econômica (Contencioso)

Fonte: dados.gov.br (CKAN)
URL CKAN: https://dados.gov.br/api/3/action/package_show?id=dados-de-contencioso-do-cade
Formato: CSV via CKAN
Frequência: cache de 24h

Alertas gerados:
  - Condenado pelo CADE (CRÍTICO)
  - Investigado pelo CADE (ATENÇÃO)
"""
from __future__ import annotations

import csv
import io
import logging
import re
import time

import requests

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.cade")

CKAN_URL = "https://dados.gov.br/api/3/action/package_show?id=dados-de-contencioso-do-cade"

_cache: list[dict] | None = None
_cache_ts: float = 0.0
_CACHE_TTL = 3600 * 24  # 24h


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", str(cnpj or ""))


def _fmt(cnpj: str) -> str:
    c = _strip(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _fetch_csv_urls() -> list[str]:
    try:
        resp = requests.get(CKAN_URL, timeout=20, headers={"User-Agent": "Subradar/1.0"})
        if not resp.ok:
            return []
        data = resp.json()
        resources = data.get("result", {}).get("resources", [])
        return [r["url"] for r in resources if r.get("format", "").upper() in ("CSV", "XLS", "XLSX")]
    except Exception as e:
        logger.warning("CADE: falha ao buscar recursos CKAN: %s", e)
        return []


def _load_cade() -> list[dict]:
    global _cache, _cache_ts
    if _cache is not None and time.monotonic() - _cache_ts < _CACHE_TTL:
        return _cache

    urls = _fetch_csv_urls()
    rows: list[dict] = []

    for url in urls[:3]:
        try:
            logger.info("CADE: baixando %s", url)
            resp = requests.get(url, timeout=60, headers={"User-Agent": "Subradar/1.0"})
            if not resp.ok:
                continue
            content = resp.content.decode("latin-1", errors="replace")
            lines = content.splitlines()
            if len(lines) < 2:
                continue

            sep = ";" if lines[0].count(";") > lines[0].count(",") else ","
            header = [h.strip().lower().replace(" ", "_") for h in lines[0].split(sep)]

            def col(r: list[str], *names: str) -> str:
                for n in names:
                    try:
                        return r[header.index(n)].strip()
                    except (ValueError, IndexError):
                        continue
                return ""

            for line in lines[1:]:
                r = line.split(sep)
                cnpj_raw = col(r, "cnpj", "nr_cnpj", "cpf_cnpj", "nu_cnpj", "cnpj_representado")
                if not cnpj_raw:
                    continue
                cnpj_d = _strip(cnpj_raw)
                if len(cnpj_d) not in (11, 14):
                    continue
                rows.append({
                    "cnpj": cnpj_d,
                    "razao_social": col(r, "razao_social", "nome", "representado", "nome_representado"),
                    "numero_processo": col(r, "numero_processo", "nr_processo", "processo", "numero_pa"),
                    "tipo_processo": col(r, "tipo_processo", "tipo", "classe"),
                    "decisao": col(r, "decisao", "resultado", "situacao"),
                    "valor_multa": col(r, "valor_multa", "valor_condenacao", "multa"),
                    "data_julgamento": col(r, "data_julgamento", "data_decisao", "data"),
                })
            if rows:
                break
        except Exception as e:
            logger.warning("CADE: erro ao processar %s: %s", url, e)
            continue

    _cache = rows
    _cache_ts = time.monotonic()
    logger.info("CADE: %d registros indexados", len(rows))
    return rows


class CADEConnector(SubradarSource):
    fonte = "cade"
    request_delay = 0.0

    def consultar_cnpj(self, cnpj: str) -> list[dict]:
        cnpj_digits = _strip(cnpj)
        cnpj_fmt = _fmt(cnpj_digits)
        ciclo = _ciclo_atual()

        dados = _load_cade()
        hits = [d for d in dados if d["cnpj"] == cnpj_digits]

        if not hits:
            return []

        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, hits)
        if not mudou:
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt,
            "fonte": self.fonte,
            "ciclo": ciclo,
            "hash_dados": hash_novo,
            "dados": {"total": len(hits), "processos": hits},
        }])

        alertas = []
        for h in hits:
            decisao = (h.get("decisao") or "").upper()
            tipo = (h.get("tipo_processo") or "").upper()

            # Condenado = crítico; em investigação = atenção
            if any(t in decisao for t in ("CONDENADO", "CONDENAÇÃO", "CONDENACAO", "MULTA", "INAPTO")):
                severidade = "critico"
                titulo_base = "Condenação CADE"
            else:
                severidade = "atencao"
                titulo_base = "Investigação CADE"

            valor = h.get("valor_multa", "")
            valor_str = f" — R$ {valor}" if valor and valor not in ("0", "") else ""
            processo = h.get("numero_processo", "")

            alertas.append({
                "cnpj": cnpj_fmt,
                "ciclo": ciclo,
                "fonte": self.fonte,
                "categoria": "regulatorio",
                "severidade": severidade,
                "titulo": f"{titulo_base}{valor_str}",
                "descricao": (
                    f"Processo CADE — {tipo}. "
                    f"Decisão: {h.get('decisao', 'N/I')}. "
                    f"Data: {h.get('data_julgamento', 'N/I')}."
                    + (f" Processo: {processo}." if processo else "")
                ),
                "referencia_id": processo or None,
                "url_fonte": "https://sei.cade.gov.br/",
                "is_novo": True,
            })

        logger.info("CADE: %d alertas para %s", len(alertas), cnpj_fmt)
        return alertas
