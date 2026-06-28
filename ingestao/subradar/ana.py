"""
Conector: ANA — Agência Nacional de Águas e Saneamento Básico

Fonte: dados.gov.br (CKAN) ou dadosabertos.ana.gov.br
Dataset: processos sancionadores / autos de infração / sanções em outorgas

Estratégia:
  1. _load_ana() tenta package_search no dados.gov.br: "ana sancoes outorgas"
  2. Baixa CSV de sanções/multas e indexa por CNPJ/CPF
  3. Cache 24h

Alertas gerados por:
  - suspensao / cassacao → critico
  - multa / autuacao → atencao
  - advertencia → info

Nota: os dados de sanções da ANA em formato aberto e estruturado por CNPJ são limitados.
Se nenhum dataset for encontrado, retorna [] graciosamente. O caminho investigado:
  - dados.gov.br CKAN: queries "ana sancoes", "ana outorgas infracao", "ana multas"
  - dadosabertos.ana.gov.br: API CKAN própria da ANA
  - Consulta direta: https://www.snirh.gov.br/portal/snirh (SNIRH — não estruturado por CNPJ)
"""
from __future__ import annotations

import csv
import io
import logging
import re
import time
from typing import Any

import requests

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.ana")

CKAN_FEDERAL = "https://dados.gov.br/api/3/action/package_search"
CKAN_ANA = "https://dadosabertos.ana.gov.br/api/3/action/package_search"

_cache_index: dict[str, list[dict]] | None = None
_cache_ts: float = 0.0
_CACHE_TTL = 3600 * 24  # 24h


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", str(cnpj or ""))


def _fmt(cnpj: str) -> str:
    c = _strip(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _parse_valor(v: str) -> float:
    try:
        return float(re.sub(r"[^\d,\.]", "", str(v)).replace(",", "."))
    except Exception:
        return 0.0


def _severidade(tipo: str, valor: float = 0.0) -> str:
    t = tipo.lower()
    if any(k in t for k in ("suspensao", "suspensão", "cassacao", "cassação", "revogacao", "revogação")):
        return "critico"
    if any(k in t for k in ("multa", "autuacao", "autuação", "auto de infracao", "auto de infração")):
        return "atencao"
    if "advertencia" in t or "advertência" in t:
        return "info"
    if valor > 0:
        return "atencao"
    return "info"


def _try_download_csv(url: str) -> str | None:
    try:
        resp = requests.get(
            url, timeout=60,
            headers={"User-Agent": "Subradar/1.0 (dados-publicos; contato@subradar.com.br)"},
        )
        resp.raise_for_status()
        try:
            return resp.content.decode("utf-8")
        except UnicodeDecodeError:
            return resp.content.decode("latin-1", errors="replace")
    except Exception as e:
        logger.debug("ANA: falha ao baixar %s: %s", url, e)
        return None


def _discover_csv_url() -> str | None:
    """Tenta descobrir dataset de sanções da ANA via CKAN federal e portal próprio."""
    queries_federal = [
        "ana sancoes outorgas",
        "ana auto de infracao",
        "ana multas saneamento",
        "agencia nacional aguas infracao",
    ]
    queries_ana = [
        "sancoes",
        "medidas administrativas",
        "auto de infracao",
        "processos sancionadores",
    ]

    # 1. Tenta CKAN federal (dados.gov.br)
    for q in queries_federal:
        try:
            resp = requests.get(
                CKAN_FEDERAL, params={"q": q, "rows": 10}, timeout=20,
                headers={"User-Agent": "Subradar/1.0 (dados-publicos; contato@subradar.com.br)"},
            )
            if not resp.ok:
                continue
            packages = resp.json().get("result", {}).get("results", [])
            for pkg in packages:
                org = pkg.get("organization", {}) or {}
                org_name = (org.get("name", "") + " " + org.get("title", "")).lower()
                pkg_name = (pkg.get("name", "") + " " + pkg.get("title", "")).lower()
                if "ana" not in org_name and "ana" not in pkg_name and "agencia" not in pkg_name:
                    continue
                for resource in pkg.get("resources", []):
                    if resource.get("format", "").upper() == "CSV" and resource.get("url"):
                        logger.info("ANA: resource encontrado via CKAN federal: %s", resource["url"])
                        return resource["url"]
        except Exception as e:
            logger.debug("ANA: CKAN federal query '%s' falhou: %s", q, e)

    # 2. Tenta CKAN próprio da ANA
    for q in queries_ana:
        try:
            resp = requests.get(
                CKAN_ANA, params={"q": q, "rows": 10}, timeout=20,
                headers={"User-Agent": "Subradar/1.0 (dados-publicos; contato@subradar.com.br)"},
            )
            if not resp.ok:
                continue
            packages = resp.json().get("result", {}).get("results", [])
            for pkg in packages:
                for resource in pkg.get("resources", []):
                    if resource.get("format", "").upper() == "CSV" and resource.get("url"):
                        logger.info("ANA: resource encontrado via CKAN ANA: %s", resource["url"])
                        return resource["url"]
        except Exception as e:
            logger.debug("ANA: CKAN ANA query '%s' falhou: %s", q, e)

    # 3. Dados abertos ANA não disponíveis em formato aberto por CNPJ
    # SNIRH (https://www.snirh.gov.br) não oferece dataset de sanções estruturado por CNPJ
    # Sisoutorga (https://www.snirh.gov.br/hidroweb/serieshistoricas) = dados hidrológicos, não sanções
    logger.info(
        "ANA: nenhum dataset de sanções estruturado por CNPJ encontrado. "
        "Caminho investigado: dados.gov.br CKAN + dadosabertos.ana.gov.br CKAN. "
        "SNIRH e Sisoutorga não expõem sanções por CNPJ. Retornando [] graciosamente."
    )
    return None


def _load_ana() -> dict[str, list[dict]]:
    """Baixa CSV e indexa por CNPJ/CPF_CNPJ."""
    global _cache_index, _cache_ts

    now = time.monotonic()
    if _cache_index is not None and now - _cache_ts < _CACHE_TTL:
        return _cache_index

    csv_url = _discover_csv_url()
    if not csv_url:
        # Sem dados disponíveis — retorna index vazio sem travar o cache (tenta de novo no próximo ciclo)
        _cache_index = _cache_index or {}
        _cache_ts = now
        return _cache_index

    logger.info("ANA: baixando dataset de sanções…")
    content = _try_download_csv(csv_url)
    if not content:
        _cache_index = _cache_index or {}
        _cache_ts = now
        return _cache_index

    index: dict[str, list[dict]] = {}
    try:
        sample = content[:1000]
        sep = ";" if sample.count(";") > sample.count(",") else ","
        reader = csv.DictReader(io.StringIO(content), delimiter=sep)
        for row in reader:
            cnpj_raw = (
                row.get("cnpj_cpf") or row.get("cnpj") or row.get("CNPJ") or
                row.get("cpf_cnpj") or row.get("nr_cnpj") or ""
            )
            cnpj_digits = _strip(cnpj_raw)
            if len(cnpj_digits) != 14:
                continue
            valor_raw = row.get("valor_multa") or row.get("vl_multa") or row.get("valor") or ""
            entry = {
                "razao_social": (
                    row.get("razao_social") or row.get("nome") or
                    row.get("nm_empresa") or ""
                ),
                "tipo_infracao": (
                    row.get("tipo_infracao") or row.get("ds_tipo_infracao") or
                    row.get("tipo_sancao") or row.get("tipo") or ""
                ),
                "valor_multa": _parse_valor(valor_raw),
                "data_inicio": (
                    row.get("data_inicio") or row.get("dt_inicio") or
                    row.get("data_publicacao") or ""
                ),
                "situacao": row.get("situacao") or row.get("ds_situacao") or "",
            }
            index.setdefault(cnpj_digits, []).append(entry)
    except Exception as e:
        logger.error("ANA: erro ao parsear CSV: %s", e)

    _cache_index = index
    _cache_ts = now
    logger.info("ANA: %d CNPJs indexados", len(index))
    return index


class ANAConnector(SubradarSource):
    fonte = "ana"
    request_delay = 0.0  # dados locais após cache

    def consultar_cnpj(self, cnpj: str) -> list[dict]:
        cnpj_digits = _strip(cnpj)
        cnpj_fmt = _fmt(cnpj_digits)
        ciclo = _ciclo_atual()

        index = _load_ana()
        sancoes = index.get(cnpj_digits)
        if not sancoes:
            return []

        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, sancoes)
        if not mudou:
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt,
            "fonte": self.fonte,
            "ciclo": ciclo,
            "hash_dados": hash_novo,
            "dados": {"sancoes": sancoes},
        }])

        alertas = []
        for s in sancoes:
            tipo = s.get("tipo_infracao", "SANÇÃO ANA")
            valor = s.get("valor_multa", 0.0)
            data = s.get("data_inicio", "")
            situacao = s.get("situacao", "")
            sev = _severidade(tipo, valor)

            texto = f"ANA — {tipo}"
            if valor:
                texto += f" | Multa: R$ {valor:,.2f}"
            if situacao:
                texto += f" | Situação: {situacao}"
            if data:
                texto += f" | Data: {data}"

            alertas.append({
                "cnpj": cnpj_fmt,
                "ciclo": ciclo,
                "fonte": self.fonte,
                "categoria": "ambiental",
                "severidade": sev,
                "titulo": f"ANA — {tipo}",
                "descricao": texto,
                "url_fonte": "https://dadosabertos.ana.gov.br",
                "is_novo": True,
            })

        return alertas
