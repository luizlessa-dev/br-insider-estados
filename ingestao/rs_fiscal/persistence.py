"""
Persistência RS Fiscal — The BR Insider
Grava despesas estaduais do RS no Supabase via PostgREST.

Tabela alvo: rs_despesas (PK: id)
"""
from __future__ import annotations

import logging
import os
from datetime import date, datetime
from typing import Iterable

import requests

from .connector import DespesaRS

logger = logging.getLogger("rs_fiscal.persistence")
CHUNK = 500


class PersistenceError(Exception):
    pass


def _jsonable(v):
    if isinstance(v, (date, datetime)):
        return v.isoformat()
    if isinstance(v, (list, tuple)):
        return [_jsonable(x) for x in v]
    return v


class RSFiscalWriter:
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
    def from_env(cls) -> "RSFiscalWriter | None":
        try:
            return cls()
        except PersistenceError as e:
            logger.warning("Persistência desativada — %s", e)
            return None

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

    def upsert_despesas(self, despesas: Iterable[DespesaRS]) -> int:
        buffer: list[dict] = []
        total = 0

        def _flush(buf):
            return self._upsert("rs_despesas", buf, on_conflict="id")

        for d in despesas:
            buffer.append({
                "id": d.id,
                "ano_exercicio": d.ano_exercicio,
                "mes": d.mes,
                "fase_gasto": d.fase_gasto,
                "tipo_gasto": d.tipo_gasto,
                "numero_empenho": d.numero_empenho,
                "numero_processo": d.numero_processo,
                "numero_contrato": d.numero_contrato,
                "cod_credor": d.cod_credor,
                "favorecido": d.favorecido,
                "cnpj": d.cnpj,
                "orgao": d.orgao,
                "uo": d.uo,
                "elemento": d.elemento,
                "modalidade": d.modalidade,
                "procedimento_licitatorio": d.procedimento_licitatorio,
                "tipo_procedimento": d.tipo_procedimento,
                "municipio": d.municipio,
                "cod_municipio": d.cod_municipio,
                "data_gasto": d.data_gasto,
                "valor": d.valor,
                "funcao": d.funcao,
                "subfuncao": d.subfuncao,
                "programa": d.programa,
                "acao": d.acao,
                "updated_at": datetime.utcnow().isoformat(),
            })
            if len(buffer) >= CHUNK:
                total += _flush(buffer)
                buffer.clear()
                logger.info("rs_despesas: %d gravados…", total)

        if buffer:
            total += _flush(buffer)
        return total

    def start_log(self, dataset: str) -> str | None:
        resp = self.session.post(
            f"{self.url}/rest/v1/rs_ingest_log",
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

    def finish_log(self, log_id, status, n_gravados=0, erro=None):
        if not log_id:
            return
        self.session.patch(
            f"{self.url}/rest/v1/rs_ingest_log",
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
