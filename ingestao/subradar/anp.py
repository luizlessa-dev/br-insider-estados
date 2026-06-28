"""
Conector: ANP — Agência Nacional do Petróleo, Gás Natural e Biocombustíveis (Multas e Processos Sancionadores)

Fonte: dados.gov.br (CKAN)
URL CKAN: https://dados.gov.br/api/3/action/package_search?q=ANP+multas
Formato: CSV/JSON via CKAN
Frequência: cache de 12h

Alertas gerados:
  - Multa aplicada (ATENÇÃO)
  - Cassação/revogação de autorização ou licença (CRÍTICO)
"""
from __future__ import annotations

import logging
import re
import time

import requests

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.anp")

CKAN_SEARCH_URL = "https://dados.gov.br/api/3/action/package_search?q=ANP+multas"
CKAN_PACKAGE_URL = "https://dados.gov.br/api/3/action/package_show"

_cache: list[dict] | None = None
_cache_ts: float = 0.0
_CACHE_TTL = 3600 * 12  # 12h

_CASSACAO_TERMS = ("CASSAÇÃO", "CASSACAO", "REVOGAÇÃO", "REVOGACAO", "CANCELAMENTO")


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", str(cnpj or ""))


def _fmt(cnpj: str) -> str:
    c = _strip(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _fetch_csv_urls() -> list[str]:
    urls = []
    try:
        resp = requests.get(CKAN_SEARCH_URL, timeout=20, headers={"User-Agent": "Subradar/1.0"})
        if not resp.ok:
            return urls
        results = resp.json().get("result", {}).get("results", [])
        for pkg in results[:3]:
            for resource in pkg.get("resources", []):
                if resource.get("format", "").upper() in ("CSV", "XLS", "XLSX"):
                    urls.append(resource["url"])
    except Exception as e:
        logger.warning("ANP: falha ao buscar CKAN: %s", e)
    return urls


def _load_anp() -> list[dict]:
    global _cache, _cache_ts
    if _cache is not None and time.monotonic() - _cache_ts < _CACHE_TTL:
        return _cache

    urls = _fetch_csv_urls()
    rows: list[dict] = []

    for url in urls[:3]:
        try:
            logger.info("ANP: baixando %s", url)
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
                cnpj_raw = col(r, "cnpj", "nr_cnpj", "nu_cnpj", "cpf_cnpj", "cnpj_autuado")
                if not cnpj_raw:
                    continue
                cnpj_d = _strip(cnpj_raw)
                if len(cnpj_d) not in (11, 14):
                    continue
                rows.append({
                    "cnpj": cnpj_d,
                    "razao_social": col(r, "razao_social", "nome", "empresa", "autuado"),
                    "numero_auto": col(r, "numero_auto", "nr_auto", "numero_notificacao", "auto_de_infracao"),
                    "valor_multa": col(r, "valor_multa", "valor", "vl_multa"),
                    "data": col(r, "data", "dt_auto", "data_auto", "data_lavratura"),
                    "tipo_infracao": col(r, "tipo_infracao", "descricao", "infracao", "descricao_infracao"),
                    "situacao": col(r, "situacao", "status", "ds_situacao"),
                })
            if rows:
                break
        except Exception as e:
            logger.warning("ANP: erro ao processar %s: %s", url, e)
            continue

    _cache = rows
    _cache_ts = time.monotonic()
    logger.info("ANP: %d registros indexados", len(rows))
    return rows


class ANPConnector(SubradarSource):
    fonte = "anp"
    request_delay = 0.0

    def consultar_cnpj(self, cnpj: str) -> list[dict]:
        cnpj_digits = _strip(cnpj)
        cnpj_fmt = _fmt(cnpj_digits)
        ciclo = _ciclo_atual()

        dados = _load_anp()
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
            "dados": {"total": len(hits), "multas": hits},
        }])

        alertas = []
        for h in hits:
            tipo = (h.get("tipo_infracao") or "").upper()
            situacao = (h.get("situacao") or "").upper()
            combined = f"{tipo} {situacao}"

            if any(t in combined for t in _CASSACAO_TERMS):
                severidade = "critico"
                categoria_titulo = "Cassação/revogação"
            else:
                severidade = "atencao"
                categoria_titulo = "Multa"

            valor = h.get("valor_multa", "")
            valor_str = f" — R$ {valor}" if valor and valor not in ("0", "") else ""
            auto = h.get("numero_auto", "")

            alertas.append({
                "cnpj": cnpj_fmt,
                "ciclo": ciclo,
                "fonte": self.fonte,
                "categoria": "regulatorio",
                "severidade": severidade,
                "titulo": f"ANP — {categoria_titulo}{valor_str}",
                "descricao": (
                    f"Processo sancionador ANP. "
                    f"Tipo de infração: {h.get('tipo_infracao', 'N/I')}. "
                    f"Data: {h.get('data', 'N/I')}. "
                    f"Situação: {h.get('situacao', 'N/I')}."
                    + (f" Auto: {auto}." if auto else "")
                ),
                "referencia_id": auto or None,
                "url_fonte": "https://www.gov.br/anp/pt-br/acesso-a-informacao/fiscalizacao",
                "is_novo": True,
            })

        logger.info("ANP: %d alertas para %s", len(alertas), cnpj_fmt)
        return alertas
