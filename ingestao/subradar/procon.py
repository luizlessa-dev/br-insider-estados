"""
Conector: SENACON/SINDEC — Cadastro Nacional de Reclamações Fundamentadas (PROCON)

Fonte: Ministério da Justiça — dados.mj.gov.br (CKAN)
URL CKAN: https://dados.mj.gov.br/api/3/action/package_show?id=cadastro-nacional-de-reclamacoes-fundamentadas-procons-sindec
Formato: CSV público
Frequência: cache de 24h

Alertas gerados:
  - >100 reclamações fundamentadas (CRÍTICO)
  - >20 reclamações fundamentadas (ATENÇÃO)
  - >0 reclamações fundamentadas (INFO)
"""
from __future__ import annotations

import csv
import io
import logging
import re
import time
from collections import defaultdict

import requests

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.procon")

CKAN_URL = (
    "https://dados.mj.gov.br/api/3/action/package_show"
    "?id=cadastro-nacional-de-reclamacoes-fundamentadas-procons-sindec"
)
CKAN_FALLBACK_URL = (
    "https://dados.gov.br/api/3/action/package_show"
    "?id=cadastro-nacional-de-reclamacoes-fundamentadas-procons-sindec"
)

_cache: dict[str, int] | None = None  # cnpj_digits -> total_reclamações
_cache_ts: float = 0.0
_CACHE_TTL = 3600 * 24  # 24h


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", str(cnpj or ""))


def _fmt(cnpj: str) -> str:
    c = _strip(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _fetch_csv_urls() -> list[str]:
    for ckan_url in [CKAN_URL, CKAN_FALLBACK_URL]:
        try:
            resp = requests.get(ckan_url, timeout=20, headers={"User-Agent": "Subradar/1.0"})
            if not resp.ok:
                continue
            data = resp.json()
            resources = data.get("result", {}).get("resources", [])
            urls = [r["url"] for r in resources if r.get("format", "").upper() in ("CSV", "XLS", "XLSX")]
            if urls:
                return urls
        except Exception as e:
            logger.warning("PROCON: CKAN %s falhou: %s", ckan_url, e)
    return []


def _load_procon() -> dict[str, int]:
    global _cache, _cache_ts
    if _cache is not None and time.monotonic() - _cache_ts < _CACHE_TTL:
        return _cache

    urls = _fetch_csv_urls()
    # Use most recent (assume sorted or take last few)
    totais: dict[str, int] = defaultdict(int)

    for url in urls[-3:]:  # últimas 3 (mais recentes geralmente ao final)
        try:
            logger.info("PROCON: baixando %s", url)
            resp = requests.get(url, timeout=120, headers={"User-Agent": "Subradar/1.0"})
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
                cnpj_raw = col(r, "cnpj_fornecedor", "cnpj", "nr_cnpj", "nu_cnpj_fornecedor")
                if not cnpj_raw:
                    continue
                cnpj_d = _strip(cnpj_raw)
                if len(cnpj_d) != 14:
                    continue

                # Número de reclamações na linha
                qtd_raw = col(r, "quantidade_reclamacoes", "quantidade", "total_reclamacoes", "qtd_reclamacoes", "count")
                try:
                    qtd = int(float(qtd_raw or "1"))
                except ValueError:
                    qtd = 1

                totais[cnpj_d] += qtd

        except Exception as e:
            logger.warning("PROCON: erro ao processar %s: %s", url, e)
            continue

    result = dict(totais)
    _cache = result
    _cache_ts = time.monotonic()
    logger.info("PROCON: %d CNPJs indexados", len(result))
    return result


class PROCONConnector(SubradarSource):
    fonte = "procon"
    request_delay = 0.0

    def consultar_cnpj(self, cnpj: str) -> list[dict]:
        cnpj_digits = _strip(cnpj)
        cnpj_fmt = _fmt(cnpj_digits)
        ciclo = _ciclo_atual()

        dados = _load_procon()
        total = dados.get(cnpj_digits, 0)

        if total == 0:
            return []

        hit = {"cnpj": cnpj_digits, "total_reclamacoes": total}
        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, hit)
        if not mudou:
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt,
            "fonte": self.fonte,
            "ciclo": ciclo,
            "hash_dados": hash_novo,
            "dados": hit,
        }])

        if total > 100:
            severidade = "critico"
        elif total > 20:
            severidade = "atencao"
        else:
            severidade = "info"

        alerta = {
            "cnpj": cnpj_fmt,
            "ciclo": ciclo,
            "fonte": self.fonte,
            "categoria": "consumidor",
            "severidade": severidade,
            "titulo": f"PROCON/SINDEC: {total} reclamação(ões) fundamentada(s)",
            "descricao": (
                f"O CNPJ possui {total} reclamação(ões) fundamentada(s) no "
                f"Cadastro Nacional PROCON/SINDEC. "
                f"Reclamações fundamentadas indicam que o fornecedor não resolveu a queixa do consumidor."
            ),
            "referencia_id": None,
            "url_fonte": "https://www.consumidor.gov.br/",
            "is_novo": True,
        }

        logger.info("PROCON: %d alerta(s) para %s (total=%d)", 1, cnpj_fmt, total)
        return [alerta]
