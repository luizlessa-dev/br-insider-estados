"""Persistência de PEPs — The Brasilia Insider."""
from __future__ import annotations

import logging
import os
from datetime import date, datetime
from typing import Iterator

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

from .peps_connector import Pep

logger = logging.getLogger("cgu.peps.persistence")

CHUNK = 500


class PersistenceError(Exception):
    pass


def _jsonable(v):
    if isinstance(v, (date, datetime)):
        return v.isoformat()
    if isinstance(v, list):
        return [_jsonable(x) for x in v]
    if isinstance(v, dict):
        return {k: _jsonable(vv) for k, vv in v.items()}
    return v


class PepsWriter:
    def __init__(self, url: str | None = None, key: str | None = None) -> None:
        self.url = (url or os.environ.get("SUPABASE_URL") or "").rstrip("/")
        self.key = (
            key
            or os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
            or os.environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY")
            or ""
        )
        if not self.url or not self.key:
            raise PersistenceError("Faltando SUPABASE_URL e/ou SUPABASE_SERVICE_ROLE_KEY.")
        self.session = requests.Session()
        retry = Retry(total=5, backoff_factor=1.5,
                      status_forcelist=[429, 500, 502, 503, 504],
                      allowed_methods=["GET", "POST", "PATCH"])
        self.session.mount("https://", HTTPAdapter(max_retries=retry))
        self.session.headers.update({
            "apikey": self.key,
            "Authorization": f"Bearer {self.key}",
            "Content-Type": "application/json",
        })

    @classmethod
    def from_env(cls) -> "PepsWriter | None":
        try:
            return cls()
        except PersistenceError as e:
            logger.warning("PepsWriter desativado — %s", e)
            return None

    def _upsert(self, table: str, rows: list[dict], on_conflict: str) -> int:
        rows = [{k: _jsonable(v) for k, v in r.items()} for r in rows]
        keys = [k.strip() for k in on_conflict.split(",")]
        deduped: dict[tuple, dict] = {}
        for r in rows:
            deduped[tuple(r.get(k) for k in keys)] = r
        rows = list(deduped.values())
        total = 0
        for i in range(0, len(rows), CHUNK):
            chunk = rows[i: i + CHUNK]
            resp = self.session.post(
                f"{self.url}/rest/v1/{table}",
                params={"on_conflict": on_conflict},
                headers={"Prefer": "resolution=merge-duplicates,return=minimal"},
                json=chunk,
                timeout=60,
            )
            if resp.status_code >= 300:
                raise PersistenceError(
                    f"upsert {table}: HTTP {resp.status_code} — {resp.text[:300]}"
                )
            total += len(chunk)
        return total

    def upsert_peps(self, peps: Iterator[Pep]) -> int:
        total = 0
        batch: list[dict] = []
        for p in peps:
            batch.append({
                "cpf":                    p.cpf,
                "nome":                   p.nome,
                "sigla_funcao":           p.sigla_funcao,
                "descricao_funcao":       p.descricao_funcao,
                "nivel_funcao":           p.nivel_funcao,
                "orgao_codigo":           p.orgao_codigo,
                "orgao_nome":             p.orgao_nome,
                "data_inicio_exercicio":  p.data_inicio_exercicio,
                "data_fim_exercicio":     p.data_fim_exercicio,
                "data_fim_carencia":      p.data_fim_carencia,
                "updated_at":             datetime.utcnow().isoformat(),
            })
            if len(batch) >= CHUNK:
                self._upsert("peps", batch, on_conflict="cpf,orgao_codigo,data_inicio_exercicio")
                total += len(batch)
                batch = []
        if batch:
            self._upsert("peps", batch, on_conflict="cpf,orgao_codigo,data_inicio_exercicio")
            total += len(batch)
        logger.info("PEPs: %d upsertadas", total)
        return total

    def start_log(self, dataset: str) -> int | None:
        resp = self.session.post(
            f"{self.url}/rest/v1/peps_ingest_log",
            headers={"Prefer": "return=representation"},
            json=[{"dataset": dataset, "status": "running"}],
            timeout=30,
        )
        if resp.status_code >= 300:
            logger.warning("start_log falhou: %s", resp.text[:200])
            return None
        try:
            return resp.json()[0]["id"]
        except (IndexError, KeyError, ValueError):
            return None

    def finish_log(self, log_id: int | None, status: str,
                   n_novos: int = 0, erro: str | None = None) -> None:
        if not log_id:
            return
        self.session.patch(
            f"{self.url}/rest/v1/peps_ingest_log",
            params={"id": f"eq.{log_id}"},
            headers={"Prefer": "return=minimal"},
            json={
                "finished_at": datetime.utcnow().isoformat(),
                "status": status,
                "n_novos": n_novos,
                "erro": erro,
            },
            timeout=30,
        )
