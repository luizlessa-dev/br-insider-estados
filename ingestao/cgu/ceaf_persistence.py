"""Persistência CEAF — The Brasilia Insider."""
from __future__ import annotations

import logging
import os
from datetime import date, datetime
from typing import Iterable

import requests

from .ceaf_connector import Expulsao

logger = logging.getLogger("cgu.ceaf.persistence")
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


class CEAFWriter:
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
    def from_env(cls) -> "CEAFWriter | None":
        try:
            return cls()
        except PersistenceError as e:
            logger.warning("CEAFWriter desativado — %s", e)
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

    def upsert_expulsoes(self, expulsoes: Iterable[Expulsao]) -> int:
        rows = []
        for e in expulsoes:
            rows.append({
                "id": e.id,
                "data_publicacao": e.data_publicacao,
                "data_referencia": e.data_referencia,
                "cpf_punido": e.cpf_punido,
                "nome_punido": e.nome_punido,
                "tipo_punicao": e.tipo_punicao,
                "cargo_efetivo": e.cargo_efetivo,
                "cargo_comissao": e.cargo_comissao,
                "orgao_sigla": e.orgao_sigla,
                "orgao_pasta_sigla": e.orgao_pasta_sigla,
                "orgao_nome": e.orgao_nome,
                "uf_lotacao": e.uf_lotacao,
                "portaria": e.portaria,
                "numero_processo": e.numero_processo,
                "pagina_dou": e.pagina_dou,
                "secao_dou": e.secao_dou,
                "fundamentacao": e.fundamentacao or None,
                "updated_at": datetime.utcnow().isoformat(),
            })
        if not rows:
            return 0
        n = self._upsert("ceaf_expulsoes", rows, on_conflict="id")
        logger.info("CEAF: %d expulsões gravadas/atualizadas", n)
        return n

    def start_log(self) -> int | None:
        resp = self.session.post(
            f"{self.url}/rest/v1/ceaf_ingest_log",
            headers={"Prefer": "return=representation"},
            json=[{"status": "running"}],
            timeout=30,
        )
        if resp.status_code >= 300:
            logger.warning("start_log falhou: %s", resp.text[:200])
            return None
        try:
            return resp.json()[0]["id"]
        except Exception:
            return None

    def finish_log(
        self,
        log_id: int | None,
        status: str,
        n_processados: int = 0,
        n_paginas: int = 0,
        erro: str | None = None,
    ) -> None:
        if not log_id:
            return
        self.session.patch(
            f"{self.url}/rest/v1/ceaf_ingest_log",
            params={"id": f"eq.{log_id}"},
            headers={"Prefer": "return=minimal"},
            json={
                "finished_at": datetime.utcnow().isoformat(),
                "status": status,
                "n_processados": n_processados,
                "n_paginas": n_paginas,
                "erro": erro,
            },
            timeout=30,
        )
