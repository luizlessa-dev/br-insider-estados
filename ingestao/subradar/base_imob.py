"""
Base para conectores de fontes do Subradar Imob.
Análogo a base.py mas especializado para imóveis (matrícula/cartório/endereço).
"""
from __future__ import annotations

import hashlib
import json
import logging
import os
import time
from datetime import date, datetime
from typing import Any

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

logger = logging.getLogger(__name__)

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SUPABASE_KEY = (
    os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    or os.environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY")
    or ""
)


def _ciclo_atual() -> str:
    return datetime.utcnow().strftime("%Y-%m")


def _jsonable(v: Any) -> Any:
    if isinstance(v, (date, datetime)):
        return v.isoformat()
    if isinstance(v, dict):
        return {k: _jsonable(x) for k, x in v.items()}
    if isinstance(v, (list, tuple)):
        return [_jsonable(x) for x in v]
    return v


def _hash(data: Any) -> str:
    raw = json.dumps(_jsonable(data), sort_keys=True, ensure_ascii=False)
    return hashlib.sha256(raw.encode()).hexdigest()


def _supabase_headers() -> dict:
    return {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates,return=minimal",
    }


def _normalize_rows(rows: list[dict]) -> list[dict]:
    """Garante que todos os dicts no batch tenham exatamente as mesmas chaves."""
    all_keys = set()
    for r in rows:
        all_keys.update(r.keys())
    return [{k: r.get(k) for k in all_keys} for r in rows]


def upsert(table: str, rows: list[dict]) -> None:
    if not rows:
        return
    if not SUPABASE_URL or not SUPABASE_KEY:
        logger.warning("SUPABASE_URL/KEY ausentes — pulando persistência")
        return
    url = f"{SUPABASE_URL}/rest/v1/{table}"
    chunk = 500
    for i in range(0, len(rows), chunk):
        batch = [_jsonable(r) for r in _normalize_rows(rows[i : i + chunk])]
        for attempt in range(5):
            try:
                # sub_imob_dados: unique (matricula, ciclo, fonte)
                req_url = url
                req_hdrs = {**_supabase_headers()}
                if table == "sub_imob_dados":
                    req_url = url + "?on_conflict=matricula,ciclo,fonte"
                    req_hdrs["Prefer"] = "resolution=merge-duplicates,return=minimal"
                elif table == "sub_imob_alertas":
                    req_url = url
                    req_hdrs["Prefer"] = "resolution=merge-duplicates,return=minimal"
                resp = requests.post(req_url, json=batch, headers=req_hdrs, timeout=60)
                if resp.ok:
                    break
                if resp.status_code in (429, 503):
                    wait = 2 ** attempt
                    logger.warning("upsert %s: %s — retry em %ds", table, resp.status_code, wait)
                    time.sleep(wait)
                    continue
                logger.error("upsert %s falhou: %s %s", table, resp.status_code, resp.text[:300])
                resp.raise_for_status()
            except requests.exceptions.ConnectionError as e:
                wait = 2 ** attempt
                logger.warning("upsert %s: conexão perdida (%s) — retry em %ds", table, e, wait)
                time.sleep(wait)
        else:
            raise RuntimeError(f"upsert {table}: falhou após 5 tentativas")
    logger.info("upsert %s: %d linhas", table, len(rows))


class SubradarImobSource:
    """Classe base para fontes do Subradar Imob."""
    fonte: str = ""
    base_url: str = ""
    request_delay: float = 0.5
    timeout: int = 30

    def __init__(self) -> None:
        self.log = logging.getLogger(f"subradar.imob.{self.fonte}")
        self._session = self._build_session()
        self._last: float = 0.0

    def _build_session(self) -> requests.Session:
        s = requests.Session()
        retry = Retry(total=3, backoff_factor=1.0, status_forcelist=[429, 500, 502, 503, 504])
        s.mount("https://", HTTPAdapter(max_retries=retry))
        s.headers.update({
            "User-Agent": "Subradar/1.0 (imobiliario; contato@subradar.com.br)",
            "Accept": "application/json",
        })
        return s

    def _get(self, url: str, params: dict | None = None, **kw) -> Any:
        elapsed = time.monotonic() - self._last
        if elapsed < self.request_delay:
            time.sleep(self.request_delay - elapsed)
        self._last = time.monotonic()
        self.log.debug("GET %s", url)
        r = self._session.get(url, params=params, timeout=self.timeout, **kw)
        r.raise_for_status()
        return r.json()

    def consultar_imovel(self, matricula: str, cartorio_id: str | None = None) -> dict | None:
        """
        Retorna dados estruturados para o laudo Imob ou None se não aplicável.

        Formato esperado:
        {
            "fonte":        str,   # ex: "cnpj_cnj_registros"
            "categoria":    str,   # titularidade | onus_reais | divida_ativa | judicial | ...
            "status":       str,   # limpo | alerta | pendente | erro | nao_aplicavel
            "titulo_secao": str,   # label no laudo
            "resumo":       str,   # 1 linha, ex: "Sem ônus registrados"
            "detalhes":     dict,  # payload completo
        }

        Retornar None significa que este conector não produz dados para o imóvel.
        Por padrão retorna None — subclasses que queiram aparecer no laudo implementam.
        """
        return None
