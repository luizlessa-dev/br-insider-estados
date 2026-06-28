"""
Conector: ANTAQ — Agência Nacional de Transportes Aquaviários (Processos Sancionadores)

Fonte: dadosabertos.antaq.gov.br (CKAN)
URL CKAN: http://dadosabertos.antaq.gov.br/api/3/action/package_search?q=sancion
Formato: CSV/JSON via CKAN
Frequência: cache de 12h

Alertas gerados:
  - Multa aplicada (ATENÇÃO)
  - Cancelamento de habilitação/outorga (CRÍTICO)
"""
from __future__ import annotations

import logging
import re
import time

import requests

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.antaq")

CKAN_SEARCH_URL = "http://dadosabertos.antaq.gov.br/api/3/action/package_search?q=sancion"

_cache: list[dict] | None = None
_cache_ts: float = 0.0
_CACHE_TTL = 3600 * 12  # 12h

_CRITICO_TERMS = ("CANCELAMENTO", "CASSAÇÃO", "CASSACAO", "REVOGAÇÃO", "REVOGACAO", "INABILITAÇÃO", "INABILITACAO")


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", str(cnpj or ""))


def _fmt(cnpj: str) -> str:
    c = _strip(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _fetch_csv_urls() -> list[str]:
    urls = []
    try:
        resp = requests.get(
            CKAN_SEARCH_URL,
            timeout=20,
            headers={"User-Agent": "Subradar/1.0"},
        )
        if not resp.ok:
            return urls
        results = resp.json().get("result", {}).get("results", [])
        for pkg in results[:5]:
            for resource in pkg.get("resources", []):
                if resource.get("format", "").upper() in ("CSV", "XLS", "XLSX", "JSON"):
                    urls.append(resource["url"])
    except Exception as e:
        logger.warning("ANTAQ: falha ao buscar CKAN: %s", e)
    return urls


def _load_antaq() -> list[dict]:
    global _cache, _cache_ts
    if _cache is not None and time.monotonic() - _cache_ts < _CACHE_TTL:
        return _cache

    urls = _fetch_csv_urls()
    rows: list[dict] = []

    for url in urls[:5]:
        try:
            logger.info("ANTAQ: baixando %s", url)
            resp = requests.get(url, timeout=60, headers={"User-Agent": "Subradar/1.0"})
            if not resp.ok:
                continue

            fmt = url.split(".")[-1].upper()

            if fmt == "JSON" or "json" in resp.headers.get("Content-Type", ""):
                data = resp.json()
                if isinstance(data, list):
                    for item in data:
                        cnpj_raw = (
                            item.get("cnpj") or item.get("nr_cnpj") or
                            item.get("cpf_cnpj") or ""
                        )
                        cnpj_d = _strip(str(cnpj_raw))
                        if len(cnpj_d) not in (11, 14):
                            continue
                        rows.append({
                            "cnpj": cnpj_d,
                            "razao_social": item.get("razao_social") or item.get("nome") or "",
                            "tipo_irregularidade": item.get("tipo_infracao") or item.get("tipo") or item.get("descricao") or "",
                            "decisao": item.get("decisao") or item.get("situacao") or "",
                            "valor": str(item.get("valor_multa") or item.get("valor") or ""),
                            "numero_processo": str(item.get("numero_processo") or item.get("processo") or ""),
                        })
            else:
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
                    cnpj_raw = col(r, "cnpj", "nr_cnpj", "cpf_cnpj", "nu_cnpj")
                    if not cnpj_raw:
                        continue
                    cnpj_d = _strip(cnpj_raw)
                    if len(cnpj_d) not in (11, 14):
                        continue
                    rows.append({
                        "cnpj": cnpj_d,
                        "razao_social": col(r, "razao_social", "nome", "empresa"),
                        "tipo_irregularidade": col(r, "tipo_infracao", "tipo", "descricao", "irregularidade"),
                        "decisao": col(r, "decisao", "situacao", "resultado"),
                        "valor": col(r, "valor_multa", "valor", "vl_multa"),
                        "numero_processo": col(r, "numero_processo", "processo", "nr_processo"),
                    })

            if rows:
                break
        except Exception as e:
            logger.warning("ANTAQ: erro ao processar %s: %s", url, e)
            continue

    _cache = rows
    _cache_ts = time.monotonic()
    logger.info("ANTAQ: %d registros indexados", len(rows))
    return rows


class ANTAQConnector(SubradarSource):
    fonte = "antaq"
    request_delay = 0.0

    def consultar_cnpj(self, cnpj: str) -> list[dict]:
        cnpj_digits = _strip(cnpj)
        cnpj_fmt = _fmt(cnpj_digits)
        ciclo = _ciclo_atual()

        dados = _load_antaq()
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
            tipo = (h.get("tipo_irregularidade") or "").upper()
            decisao = (h.get("decisao") or "").upper()
            combined = f"{tipo} {decisao}"

            if any(t in combined for t in _CRITICO_TERMS):
                severidade = "critico"
                categoria_titulo = "Cancelamento de habilitação"
            else:
                severidade = "atencao"
                categoria_titulo = "Multa/Sanção"

            valor = h.get("valor", "")
            valor_str = f" — R$ {valor}" if valor and valor not in ("0", "") else ""
            processo = h.get("numero_processo", "")

            alertas.append({
                "cnpj": cnpj_fmt,
                "ciclo": ciclo,
                "fonte": self.fonte,
                "categoria": "regulatorio",
                "severidade": severidade,
                "titulo": f"ANTAQ — {categoria_titulo}{valor_str}",
                "descricao": (
                    f"Processo sancionador ANTAQ. "
                    f"Irregularidade: {h.get('tipo_irregularidade', 'N/I')}. "
                    f"Decisão: {h.get('decisao', 'N/I')}."
                    + (f" Processo: {processo}." if processo else "")
                ),
                "referencia_id": processo or None,
                "url_fonte": "http://portal.antaq.gov.br/",
                "is_novo": True,
            })

        logger.info("ANTAQ: %d alertas para %s", len(alertas), cnpj_fmt)
        return alertas
