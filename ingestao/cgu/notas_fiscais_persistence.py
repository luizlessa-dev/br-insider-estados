"""Persistência de Notas Fiscais — The Brasilia Insider."""
from __future__ import annotations

import logging
import os
from datetime import date, datetime
from typing import Iterator

import requests

from .notas_fiscais_connector import NotaFiscal

logger = logging.getLogger("cgu.notas_fiscais.persistence")

CHUNK = 500


class PersistenceError(Exception):
    pass


def _jsonable(v):
    if isinstance(v, (date, datetime)):
        return v.isoformat()
    return v


class NotasFiscaisWriter:
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
    def from_env(cls) -> "NotasFiscaisWriter | None":
        try:
            return cls()
        except PersistenceError as e:
            logger.warning("NotasFiscaisWriter desativado — %s", e)
            return None

    def _upsert(self, rows: list[dict]) -> int:
        rows = [{k: _jsonable(v) for k, v in r.items()} for r in rows]
        deduped: dict[str, dict] = {}
        for r in rows:
            deduped[r["chave"]] = r
        rows = list(deduped.values())
        total = 0
        for i in range(0, len(rows), CHUNK):
            chunk = rows[i: i + CHUNK]
            resp = self.session.post(
                f"{self.url}/rest/v1/notas_fiscais",
                params={"on_conflict": "chave"},
                headers={"Prefer": "resolution=merge-duplicates,return=minimal"},
                json=chunk,
                timeout=60,
            )
            if resp.status_code >= 300:
                raise PersistenceError(
                    f"upsert notas_fiscais: HTTP {resp.status_code} — {resp.text[:300]}"
                )
            total += len(chunk)
        return total

    def upsert_notas(self, notas: Iterator[NotaFiscal]) -> int:
        total = 0
        batch: list[dict] = []
        for n in notas:
            if not n.chave:
                continue
            batch.append({
                "chave":                      n.chave,
                "numero":                     n.numero,
                "serie":                      n.serie,
                "data_emissao":               n.data_emissao,
                "data_processamento":         n.data_processamento,
                "emitente_cnpj":              n.emitente_cnpj,
                "emitente_razao_social":      n.emitente_razao_social,
                "emitente_uf":                n.emitente_uf,
                "emitente_municipio":         n.emitente_municipio,
                "destinatario_cnpj":          n.destinatario_cnpj,
                "destinatario_cpf":           n.destinatario_cpf,
                "destinatario_razao_social":  n.destinatario_razao_social,
                "destinatario_uf":            n.destinatario_uf,
                "valor_nota":                 n.valor_nota,
                "natureza_operacao":          n.natureza_operacao,
                "situacao":                   n.situacao,
                "updated_at":                 datetime.utcnow().isoformat(),
            })
            if len(batch) >= CHUNK:
                self._upsert(batch)
                total += len(batch)
                batch = []
        if batch:
            self._upsert(batch)
            total += len(batch)
        logger.info("Notas Fiscais: %d upsertadas", total)
        return total

    def start_log(self, descricao: str) -> int | None:
        resp = self.session.post(
            f"{self.url}/rest/v1/notas_fiscais_ingest_log",
            headers={"Prefer": "return=representation"},
            json=[{"descricao": descricao, "status": "running"}],
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
            f"{self.url}/rest/v1/notas_fiscais_ingest_log",
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
