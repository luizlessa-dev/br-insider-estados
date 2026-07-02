"""
Conector: ANAC — Infrações Administrativas em Aviação Civil

Fonte: dados.gov.br via CKAN
Dataset: "Infrações Administrativas Aplicadas pela ANAC" ou "Autos de Infração ANAC"

Estratégia:
  1. _load_anac() busca no CKAN dados.gov.br por "anac infracao administrativa"
  2. Baixa resource CSV e indexa por CNPJ (coluna cnpj ou cpf_cnpj)
  3. Cache 12h

Alertas gerados por:
  - cancelamento / cassacao → critico
  - suspensao → atencao
  - multa > R$ 50.000 → atencao
  - outros → info

Fallback: tenta URL direta dados.anac.gov.br se CKAN falhar.
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

logger = logging.getLogger("subradar.anac")

CKAN_BASE = "https://dados.gov.br"
PACKAGE_SEARCH_URL = f"{CKAN_BASE}/api/3/action/package_search"
ANAC_FALLBACK_BASE = "https://sistemas.anac.gov.br/dadosabertos/"

# URL direta descoberta em jul/2026 — atualizada diariamente (~200 processos, aeroportos concedidos)
# Nota: este CSV indexa por nome da concessionária, não por CNPJ.
# A busca é feita por razão social normalizada.
ANAC_CSV_DIRETO = (
    "https://sistemas.anac.gov.br/dadosabertos/fiscalizacao/"
    "Lista%20de%20processos%20administrativos%20sancionadores/"
    "ListaDeProcessosAdministrativosSancionadores.csv"
)

_cache_index: dict[str, list[dict]] | None = None
_cache_ts: float = 0.0
_CACHE_TTL = 3600 * 12  # 12h

_MULTA_ATENCAO = 50_000.0


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", str(cnpj or ""))


def _fmt(cnpj: str) -> str:
    c = _strip(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _parse_valor(v: str) -> float:
    try:
        return float(re.sub(r"[^\d,\.]", "", v).replace(",", "."))
    except Exception:
        return 0.0


def _severidade(tipo: str, valor_multa: float = 0.0) -> str:
    t = tipo.lower()
    if any(k in t for k in ("cancelamento", "cancelação", "cassacao", "cassação", "cassac")):
        return "critico"
    if any(k in t for k in ("suspensao", "suspensão", "suspenc")):
        return "atencao"
    if valor_multa > _MULTA_ATENCAO:
        return "atencao"
    return "info"


def _try_download_csv(url: str) -> str | None:
    """Baixa URL e retorna conteúdo como string, ou None em falha."""
    try:
        resp = requests.get(
            url, timeout=60,
            headers={"User-Agent": "Subradar/1.0 (dados-publicos; contato@subradar.com.br)"},
        )
        resp.raise_for_status()
        # Tenta utf-8 depois latin-1
        try:
            return resp.content.decode("utf-8")
        except UnicodeDecodeError:
            return resp.content.decode("latin-1", errors="replace")
    except Exception as e:
        logger.debug("ANAC: falha ao baixar %s: %s", url, e)
        return None


def _discover_csv_url() -> str | None:
    """Descobre URL do CSV de infrações da ANAC via CKAN."""
    queries = [
        "anac infracao administrativa",
        "anac auto de infracao",
        "infrações administrativas aviação",
    ]
    for q in queries:
        try:
            resp = requests.get(
                PACKAGE_SEARCH_URL,
                params={"q": q, "rows": 10},
                timeout=20,
                headers={"User-Agent": "Subradar/1.0 (dados-publicos; contato@subradar.com.br)"},
            )
            if not resp.ok:
                continue
            packages = resp.json().get("result", {}).get("results", [])
            for pkg in packages:
                name = (pkg.get("name", "") + " " + pkg.get("title", "")).lower()
                if "anac" not in name and "aviacao" not in name and "aviação" not in name and "infracao" not in name:
                    continue
                for resource in pkg.get("resources", []):
                    fmt = resource.get("format", "").upper()
                    url = resource.get("url", "")
                    if fmt == "CSV" and url:
                        logger.info("ANAC: resource encontrado via CKAN: %s", url)
                        return url
        except Exception as e:
            logger.debug("ANAC: CKAN query '%s' falhou: %s", q, e)

    # Fallback: URL direta conhecida (atualizada diariamente em jul/2026)
    logger.info("ANAC: usando URL direta de processos sancionadores")
    return ANAC_CSV_DIRETO


def _load_anac() -> dict[str, list[dict]]:
    """Baixa CSV e indexa por CNPJ."""
    global _cache_index, _cache_ts

    now = time.monotonic()
    if _cache_index is not None and now - _cache_ts < _CACHE_TTL:
        return _cache_index

    csv_url = _discover_csv_url()
    if not csv_url:
        logger.warning("ANAC: não foi possível descobrir URL do CSV de infrações")
        _cache_index = _cache_index or {}
        return _cache_index

    logger.info("ANAC: baixando dataset de infrações administrativas…")
    content = _try_download_csv(csv_url)
    if not content:
        _cache_index = _cache_index or {}
        return _cache_index

    # CSV da ANAC tem linha extra de metadata antes do header real (padrão comum em gov.br)
    lines = content.splitlines()
    header_idx = next(
        (i for i, l in enumerate(lines) if "número" in l.lower() or "processo" in l.lower() or "concession" in l.lower()),
        0,
    )
    content_clean = "\n".join(lines[header_idx:])

    index: dict[str, list[dict]] = {}
    try:
        sample = content_clean[:1000]
        sep = ";" if sample.count(";") > sample.count(",") else ","
        reader = csv.DictReader(io.StringIO(content_clean), delimiter=sep)
        for row in reader:
            # Formato atual: "Concessionária" (nome da empresa, sem CNPJ direto)
            # Indexa por CNPJ se disponível; caso contrário por nome normalizado
            cnpj_raw = (
                row.get("cnpj") or row.get("CNPJ") or
                row.get("cpf_cnpj") or row.get("nr_cnpj") or
                row.get("nu_cnpj") or ""
            )
            cnpj_digits = _strip(cnpj_raw)

            # Nome da concessionária para indexação por razão social
            nome_empresa = (
                row.get("Concessionária") or row.get("concessionária") or
                row.get("razao_social") or row.get("nome") or
                row.get("nm_empresa") or ""
            ).strip()

            if len(cnpj_digits) != 14 and not nome_empresa:
                continue

            valor_raw = (
                row.get("Valor da penalidade aplicada") or
                row.get("valor_multa") or row.get("vl_multa") or
                row.get("valor") or ""
            )
            entry = {
                "razao_social": nome_empresa,
                "tipo_infracao": (
                    row.get("Espécie de penalidade aplicada") or
                    row.get("tipo_infracao") or row.get("ds_tipo_infracao") or
                    row.get("descricao_infracao") or row.get("tipo") or ""
                ),
                "descricao": (
                    row.get("descricao") or row.get("ds_infracao") or
                    row.get("descricao_auto") or ""
                ),
                "valor_multa": _parse_valor(valor_raw),
                "data_auto": (
                    row.get("data_auto") or row.get("dt_auto") or
                    row.get("data_publicacao") or ""
                ),
                "situacao": (
                    row.get("situacao") or row.get("ds_situacao") or
                    row.get("status") or ""
                ),
            }
            # Indexa por CNPJ quando disponível; por nome normalizado como fallback
            if len(cnpj_digits) == 14:
                index.setdefault(cnpj_digits, []).append(entry)
            if nome_empresa:
                nome_key = f"NAME:{re.sub(r'[^A-Z0-9]', '', nome_empresa.upper())}"
                index.setdefault(nome_key, []).append(entry)
    except Exception as e:
        logger.error("ANAC: erro ao parsear CSV: %s", e)

    _cache_index = index
    _cache_ts = now
    logger.info("ANAC: %d CNPJs indexados", len(index))
    return index


class ANACConnector(SubradarSource):
    fonte = "anac"
    request_delay = 0.0  # dados locais após cache

    def consultar_cnpj(self, cnpj: str, razao_social: str | None = None) -> list[dict]:
        cnpj_digits = _strip(cnpj)
        cnpj_fmt = _fmt(cnpj_digits)
        ciclo = _ciclo_atual()

        index = _load_anac()
        infracoes = index.get(cnpj_digits) or []

        # Fallback: busca por razão social normalizada (CSV ANAC indexa por nome)
        if not infracoes and razao_social:
            nome_key = f"NAME:{re.sub(r'[^A-Z0-9]', '', razao_social.upper())}"
            infracoes = index.get(nome_key) or []

        if not infracoes:
            return []

        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, infracoes)
        if not mudou:
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt,
            "fonte": self.fonte,
            "ciclo": ciclo,
            "hash_dados": hash_novo,
            "dados": {"infracoes": infracoes},
        }])

        alertas = []
        for inf in infracoes:
            tipo = inf.get("tipo_infracao", "INFRAÇÃO ANAC")
            descricao = inf.get("descricao", "")
            valor = inf.get("valor_multa", 0.0)
            data = inf.get("data_auto", "")
            situacao = inf.get("situacao", "")
            sev = _severidade(tipo, valor)

            texto = f"ANAC — {tipo}"
            if descricao:
                texto += f": {descricao}"
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
                "categoria": "regulatorio",
                "severidade": sev,
                "titulo": f"ANAC — {tipo}",
                "descricao": texto,
                "url_fonte": "https://dados.gov.br/dados/conjuntos-dados?organizacao=anac",
                "is_novo": True,
            })

        return alertas
