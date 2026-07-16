"""
Backend real do pipeline seguro TSE — fala com o Supabase via PostgREST/RPC.

Usa a mesma sessão autenticada do TSEWriter. O swap atômico e o quality gate
acontecem no banco (função tse_promote_year); aqui só orquestramos as chamadas.
Nenhuma DDL é criada em runtime — staging/logs/RPC vêm da migration
sql/0001_tse_safe_pipeline.sql.
"""
from __future__ import annotations

import logging
from datetime import datetime, timedelta, timezone
from typing import Iterable

from .persistence import PersistenceError, TSEWriter
from .safe_loader import Backend, RunRecord

logger = logging.getLogger("tse.safe_backend")

CHUNK = 500
_STAGING = {"receitas": "tse_receitas_staging", "despesas": "tse_despesas_staging"}
_FINAL = {"receitas": "tse_receitas", "despesas": "tse_despesas"}


class PostgrestBackend(Backend):
    def __init__(self, writer: TSEWriter) -> None:
        self.w = writer

    def count_final(self, dataset: str, ano: int) -> int:
        # HEAD com count=exact devolve a contagem sem trafegar linhas.
        resp = self.w.session.get(
            f"{self.w.url}/rest/v1/{_FINAL[dataset]}",
            params={"ano_eleicao": f"eq.{ano}", "select": "ano_eleicao"},
            headers={"Prefer": "count=exact", "Range": "0-0"},
            timeout=60,
        )
        if resp.status_code >= 300:
            raise PersistenceError(f"count_final {dataset} {ano}: {resp.status_code} {resp.text[:200]}")
        cr = resp.headers.get("content-range", "*/0")
        return int(cr.split("/")[-1] or 0)

    def stage_rows(self, dataset: str, run_id: str, rows: Iterable[dict]) -> int:
        table = _STAGING[dataset]
        total, batch = 0, []
        for r in rows:
            batch.append({**r, "run_id": run_id})
            if len(batch) >= CHUNK:
                total += self._insert(table, batch)
                batch = []
        if batch:
            total += self._insert(table, batch)
        return total

    def count_staging(self, dataset: str, run_id: str) -> int:
        resp = self.w.session.get(
            f"{self.w.url}/rest/v1/{_STAGING[dataset]}",
            params={"run_id": f"eq.{run_id}", "select": "run_id"},
            headers={"Prefer": "count=exact", "Range": "0-0"},
            timeout=60,
        )
        if resp.status_code >= 300:
            raise PersistenceError(f"count_staging {dataset}: {resp.status_code} {resp.text[:200]}")
        return int(resp.headers.get("content-range", "*/0").split("/")[-1] or 0)

    def _insert(self, table: str, rows: list[dict]) -> int:
        resp = self.w.session.post(
            f"{self.w.url}/rest/v1/{table}",
            headers={"Prefer": "return=minimal"},
            json=rows,
            timeout=300,
        )
        if resp.status_code >= 300:
            raise PersistenceError(f"stage insert {table}: {resp.status_code} {resp.text[:300]}")
        return len(rows)

    def promote(self, dataset: str, ano: int, run_id: str, min_expected: int) -> dict:
        resp = self.w.session.post(
            f"{self.w.url}/rest/v1/rpc/tse_promote_year",
            json={
                "p_dataset": dataset,
                "p_ano": ano,
                "p_run_id": run_id,
                "p_min_expected": min_expected,
            },
            timeout=600,
        )
        if resp.status_code >= 300:
            # O quality gate e o swap falham aqui de forma atômica — final intacta.
            raise PersistenceError(f"promote {dataset} {ano}: {resp.status_code} {resp.text[:300]}")
        return resp.json() if resp.text else {}

    def clear_staging(self, dataset: str, run_id: str) -> None:
        self.w.session.delete(
            f"{self.w.url}/rest/v1/{_STAGING[dataset]}",
            params={"run_id": f"eq.{run_id}"},
            headers={"Prefer": "return=minimal"},
            timeout=120,
        )

    def record_run(self, run: RunRecord) -> None:
        expires = None
        if run.staging_expires_at_days:
            expires = (datetime.now(timezone.utc)
                       + timedelta(days=run.staging_expires_at_days)).isoformat()
        payload = {
            "run_id": run.run_id,
            "dataset": run.dataset,
            "ano": run.ano,
            "phase": run.phase,
            "status": run.status,
            "rows_downloaded": run.rows_downloaded,
            "rows_staged": run.rows_staged,
            "rows_final_before": run.rows_final_before,
            "rows_final_after": run.rows_final_after,
            "min_expected": run.min_expected,
            "error": run.error,
            "staging_expires_at": expires,
        }
        if run.status in ("ok", "erro"):
            payload["finished_at"] = datetime.now(timezone.utc).isoformat()
        # upsert por run_id (idempotente: cada fase re-grava a mesma linha)
        resp = self.w.session.post(
            f"{self.w.url}/rest/v1/tse_load_runs",
            params={"on_conflict": "run_id"},
            headers={"Prefer": "resolution=merge-duplicates,return=minimal"},
            json=[payload],
            timeout=30,
        )
        if resp.status_code >= 300:
            logger.warning("record_run falhou: %s %s", resp.status_code, resp.text[:200])
