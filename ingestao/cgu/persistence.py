"""Camada de persistência para dados CGU — The Brasilia Insider."""
from __future__ import annotations

import logging
import os
from datetime import date, datetime
from typing import Iterable

import requests

from .models import ProcessoDisciplinar

logger = logging.getLogger("cgu.persistence")

CHUNK = 500


class PersistenceError(Exception):
    pass


def _jsonable(v):
    if isinstance(v, (date, datetime)):
        return v.isoformat()
    if isinstance(v, dict):
        return {k: _jsonable(x) for k, x in v.items()}
    if isinstance(v, (list, tuple)):
        return [_jsonable(x) for x in v]
    return v


class CGUWriter:
    def __init__(self, url: str | None = None, key: str | None = None) -> None:
        self.url = (url or os.environ.get("SUPABASE_URL") or "").rstrip("/")
        self.key = (
            key
            or os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
            or os.environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY")
            or ""
        )
        if not self.url or not self.key:
            raise PersistenceError(
                "Faltando SUPABASE_URL e/ou SUPABASE_SERVICE_ROLE_KEY."
            )
        self.session = requests.Session()
        self.session.headers.update({
            "apikey": self.key,
            "Authorization": f"Bearer {self.key}",
            "Content-Type": "application/json",
        })

    @classmethod
    def from_env(cls) -> "CGUWriter | None":
        try:
            return cls()
        except PersistenceError as e:
            logger.warning("CGUWriter desativado — %s", e)
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
            chunk = rows[i : i + CHUNK]
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

    def upsert_processos(self, processos: Iterable[ProcessoDisciplinar]) -> int:
        rows = []
        for p in processos:
            rows.append({
                "numero_processo": p.numero_processo,
                "tipo_processo": p.tipo_processo,
                "assuntos": p.assuntos or None,
                "pasta": p.pasta,
                "entidade": p.entidade,
                "uf": p.uf,
                "cidade": p.cidade,
                "data_instauracao": p.data_instauracao,
                "fase_atual": p.fase_atual,
                "data_fase": p.data_fase,
                "n_investigados": p.n_investigados,
                "n_advertencias": p.n_advertencias,
                "n_suspensoes": p.n_suspensoes,
                "n_expulsivas": p.n_expulsivas,
                "n_outras_sancoes": p.n_outras_sancoes,
                "updated_at": datetime.utcnow().isoformat(),
            })
        if not rows:
            return 0
        n = self._upsert("cgu_pad_processos", rows, on_conflict="numero_processo")
        logger.info("CGU-PAD: %d processos gravados/atualizados", n)
        return n

    def start_log(self) -> int | None:
        resp = self.session.post(
            f"{self.url}/rest/v1/cgu_pad_ingest_log",
            headers={"Prefer": "return=representation"},
            json=[{"status": "running"}],
            timeout=30,
        )
        if resp.status_code >= 300:
            logger.warning("start_log falhou: %s", resp.text[:200])
            return None
        try:
            return resp.json()[0]["id"]
        except (IndexError, KeyError, ValueError):
            return None

    def finish_log(
        self,
        log_id: int | None,
        status: str,
        n_processados: int = 0,
        erro: str | None = None,
    ) -> None:
        if not log_id:
            return
        self.session.patch(
            f"{self.url}/rest/v1/cgu_pad_ingest_log",
            params={"id": f"eq.{log_id}"},
            headers={"Prefer": "return=minimal"},
            json={
                "finished_at": datetime.utcnow().isoformat(),
                "status": status,
                "n_processados": n_processados,
                "erro": erro,
            },
            timeout=30,
        )
