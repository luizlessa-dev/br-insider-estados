"""Persistência de PEPs — The Brasilia Insider."""
from __future__ import annotations

import logging
import os
from datetime import date, datetime
from typing import Iterator

import requests

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
            rels = [
                {"nome": r.nome, "cpf": r.cpf, "tipo": r.tipo}
                for r in p.relacionamentos
            ]
            batch.append({
                "id":                  p.id,
                "cpf":                 p.cpf,
                "cpf_formatado":       p.cpf_formatado,
                "nome":                p.nome,
                "nome_social":         p.nome_social,
                "funcao":              p.funcao,
                "data_inicio_vinculo": p.data_inicio_vinculo,
                "data_fim_vinculo":    p.data_fim_vinculo,
                "orgao_codigo":        p.orgao_codigo,
                "orgao_descricao":     p.orgao_descricao,
                "classificacao_pep":   p.classificacao_pep,
                "tipo_pep":            p.tipo_pep,
                "relacionamentos":     rels,
                "updated_at":          datetime.utcnow().isoformat(),
            })
            if len(batch) >= CHUNK:
                self._upsert("peps", batch, on_conflict="id")
                total += len(batch)
                batch = []
        if batch:
            self._upsert("peps", batch, on_conflict="id")
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
