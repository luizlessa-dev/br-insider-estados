"""Persistência de Emendas API — The Brasilia Insider."""
from __future__ import annotations

import logging
import os
from datetime import date, datetime
from typing import Iterator

import requests

from .emendas_api_connector import EmendaApi

logger = logging.getLogger("cgu.emendas_api.persistence")

CHUNK = 500


class PersistenceError(Exception):
    pass


def _jsonable(v):
    if isinstance(v, (date, datetime)):
        return v.isoformat()
    return v


class EmendasApiWriter:
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
    def from_env(cls) -> "EmendasApiWriter | None":
        try:
            return cls()
        except PersistenceError as e:
            logger.warning("EmendasApiWriter desativado — %s", e)
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

    def upsert_emendas(self, emendas: Iterator[EmendaApi]) -> int:
        total_e = 0
        total_d = 0
        batch_e: list[dict] = []
        batch_d: list[dict] = []

        for e in emendas:
            if not e.codigo:
                continue
            batch_e.append({
                "codigo":               e.codigo,
                "ano":                  e.ano,
                "tipo":                 e.tipo,
                "subtipo":              e.subtipo,
                "autor_nome":           e.autor_nome,
                "autor_cpf":            e.autor_cpf,
                "autor_partido":        e.autor_partido,
                "autor_uf":             e.autor_uf,
                "autor_codigo_portal":  e.autor_codigo_portal,
                "funcao_codigo":        e.funcao_codigo,
                "funcao_descricao":     e.funcao_descricao,
                "subfuncao_codigo":     e.subfuncao_codigo,
                "subfuncao_descricao":  e.subfuncao_descricao,
                "localidade_ibge":      e.localidade_ibge,
                "localidade_descricao": e.localidade_descricao,
                "valor_empenhado":      e.valor_empenhado,
                "valor_liquidado":      e.valor_liquidado,
                "valor_pago":           e.valor_pago,
                "valor_resto_pagar":    e.valor_resto_pagar,
                "updated_at":           datetime.utcnow().isoformat(),
            })
            for d in e.documentos:
                batch_d.append({
                    "emenda_codigo":    d.emenda_codigo,
                    "codigo_documento": d.codigo_documento,
                    "tipo_documento":   d.tipo_documento,
                    "data":             d.data,
                    "valor":            d.valor,
                    "orgao":            d.orgao,
                    "acao":             d.acao,
                    "favorecido_cnpj":  d.favorecido_cnpj,
                    "favorecido_nome":  d.favorecido_nome,
                    "updated_at":       datetime.utcnow().isoformat(),
                })

            if len(batch_e) >= CHUNK:
                self._upsert("emendas_api", batch_e, on_conflict="codigo")
                total_e += len(batch_e)
                batch_e = []
            if len(batch_d) >= CHUNK:
                self._upsert("emendas_api_documentos", batch_d,
                             on_conflict="emenda_codigo,codigo_documento")
                total_d += len(batch_d)
                batch_d = []

        if batch_e:
            self._upsert("emendas_api", batch_e, on_conflict="codigo")
            total_e += len(batch_e)
        if batch_d:
            self._upsert("emendas_api_documentos", batch_d,
                         on_conflict="emenda_codigo,codigo_documento")
            total_d += len(batch_d)

        logger.info("Emendas API: %d upsertadas, %d documentos", total_e, total_d)
        return total_e

    def start_log(self, dataset: str) -> int | None:
        resp = self.session.post(
            f"{self.url}/rest/v1/emendas_api_ingest_log",
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
            f"{self.url}/rest/v1/emendas_api_ingest_log",
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
