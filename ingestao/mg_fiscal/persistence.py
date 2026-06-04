"""
Persistência MG Fiscal — The BR Insider
Grava empenhos estaduais MG no Supabase via PostgREST.

Tabelas alvo:
  mg_empenhos   — um registro por empenho (PK: id)
  mg_ingest_log — log de execuções (opcional, para monitoramento)

Env vars (mesmas do restante do pipeline):
  SUPABASE_URL
  SUPABASE_SERVICE_ROLE_KEY  (ou INTERNAL_SUPABASE_SERVICE_ROLE_KEY)
"""
from __future__ import annotations

import logging
import os
from datetime import date, datetime
from typing import Iterable

import requests

from .connector import Empenho

logger = logging.getLogger("mg_fiscal.persistence")
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


class MGFiscalWriter:
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
            "Prefer": "resolution=merge-duplicates,return=minimal",
        })

    @classmethod
    def from_env(cls) -> "MGFiscalWriter | None":
        try:
            return cls()
        except PersistenceError as e:
            logger.warning("Persistência desativada — %s", e)
            return None

    # ── Upsert genérico ────────────────────────────────────────────────────
    def _upsert(self, table: str, rows: list[dict], on_conflict: str) -> int:
        rows = [{k: _jsonable(v) for k, v in r.items()} for r in rows]
        total = 0
        for i in range(0, len(rows), CHUNK):
            chunk = rows[i : i + CHUNK]
            resp = self.session.post(
                f"{self.url}/rest/v1/{table}",
                params={"on_conflict": on_conflict},
                json=chunk,
                timeout=60,
            )
            if resp.status_code >= 300:
                raise PersistenceError(
                    f"Upsert {table} falhou ({resp.status_code}): {resp.text[:300]}"
                )
            total += len(chunk)
        return total

    # ── Empenhos ───────────────────────────────────────────────────────────
    def upsert_empenhos(self, empenhos: Iterable[Empenho]) -> int:
        """
        Grava empenhos em lotes de CHUNK=500.
        Aceita generator (streaming) sem acumular tudo na RAM.
        Retorna total de linhas gravadas/atualizadas.
        """
        buffer: list[dict] = []
        total = 0

        def _flush(buf: list[dict]) -> int:
            return self._upsert("mg_empenhos", buf, on_conflict="id")

        for emp in empenhos:
            buffer.append({
                "id": emp.id,
                "ano_exercicio": emp.ano_exercicio,
                "unidade_orcamentaria_codigo": emp.unidade_orcamentaria_codigo,
                "unidade_orcamentaria_sigla": emp.unidade_orcamentaria_sigla,
                "unidade_orcamentaria_nome": emp.unidade_orcamentaria_nome,
                "ano_empenho": emp.ano_empenho,
                "numero_empenho": emp.numero_empenho,
                "data_registro": emp.data_registro,
                "numero_processo_compra": emp.numero_processo_compra,
                "elemento_despesa_codigo": emp.elemento_despesa_codigo,
                "elemento_despesa_descricao": emp.elemento_despesa_descricao,
                "item_despesa_codigo": emp.item_despesa_codigo,
                "item_despesa_descricao": emp.item_despesa_descricao,
                "fonte_recurso_codigo": emp.fonte_recurso_codigo,
                "fonte_recurso_descricao": emp.fonte_recurso_descricao,
                "razao_social_credor": emp.razao_social_credor,
                "cnpj_cpf_credor": emp.cnpj_cpf_credor,
                "valor_empenhado": emp.valor_empenhado,
                "valor_liquidado": emp.valor_liquidado,
                "valor_pago": emp.valor_pago,
                "updated_at": datetime.utcnow().isoformat(),
            })
            if len(buffer) >= CHUNK:
                total += _flush(buffer)
                buffer.clear()
                logger.info("mg_empenhos: %d gravados…", total)

        if buffer:
            total += _flush(buffer)

        return total

    # ── Log de execução ────────────────────────────────────────────────────
    def start_log(self, dataset: str) -> str | None:
        resp = self.session.post(
            f"{self.url}/rest/v1/mg_ingest_log",
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

    def finish_log(
        self,
        log_id: str | None,
        status: str,
        n_gravados: int = 0,
        erro: str | None = None,
    ) -> None:
        if not log_id:
            return
        self.session.patch(
            f"{self.url}/rest/v1/mg_ingest_log",
            params={"id": f"eq.{log_id}"},
            headers={"Prefer": "return=minimal"},
            json={
                "status": status,
                "finished_at": datetime.utcnow().isoformat(),
                "n_gravados": n_gravados,
                "erro": erro,
            },
            timeout=30,
        )
