"""Persistência de Contratos — The Brasilia Insider."""
from __future__ import annotations

import logging
import os
from datetime import date, datetime
from typing import Iterator

import requests

from .contratos_connector import Contrato

logger = logging.getLogger("cgu.contratos.persistence")

CHUNK = 300


class PersistenceError(Exception):
    pass


def _jsonable(v):
    if isinstance(v, (date, datetime)):
        return v.isoformat()
    return v


class ContratosWriter:
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
    def from_env(cls) -> "ContratosWriter | None":
        try:
            return cls()
        except PersistenceError as e:
            logger.warning("ContratosWriter desativado — %s", e)
            return None

    def _upsert(self, rows: list[dict]) -> int:
        rows = [{k: _jsonable(v) for k, v in r.items()} for r in rows]
        deduped: dict[int, dict] = {}
        for r in rows:
            deduped[r["id"]] = r
        rows = list(deduped.values())
        total = 0
        for i in range(0, len(rows), CHUNK):
            chunk = rows[i: i + CHUNK]
            resp = self.session.post(
                f"{self.url}/rest/v1/contratos_federais",
                params={"on_conflict": "id"},
                headers={"Prefer": "resolution=merge-duplicates,return=minimal"},
                json=chunk,
                timeout=60,
            )
            if resp.status_code >= 300:
                raise PersistenceError(
                    f"upsert contratos_federais: HTTP {resp.status_code} — {resp.text[:300]}"
                )
            total += len(chunk)
        return total

    def upsert_contratos(self, contratos: Iterator[Contrato]) -> int:
        total = 0
        batch: list[dict] = []
        for c in contratos:
            if not c.id:
                continue
            batch.append({
                "id":                    c.id,
                "numero":                c.numero,
                "objeto":                c.objeto,
                "data_assinatura":       c.data_assinatura,
                "data_publicacao_tcu":   c.data_publicacao_tcu,
                "data_inicio_vigencia":  c.data_inicio_vigencia,
                "data_fim_vigencia":     c.data_fim_vigencia,
                "valor":                 c.valor,
                "valor_aditivos":        c.valor_aditivos,
                "valor_total":           c.valor_total,
                "situacao_codigo":       c.situacao_codigo,
                "situacao_descricao":    c.situacao_descricao,
                "fornecedor_cnpj":       c.fornecedor_cnpj,
                "fornecedor_cpf":        c.fornecedor_cpf,
                "fornecedor_nome":       c.fornecedor_nome,
                "fornecedor_razao_social": c.fornecedor_razao_social,
                "ug_codigo":             c.ug_codigo,
                "ug_descricao":          c.ug_descricao,
                "orgao_codigo":          c.orgao_codigo,
                "orgao_descricao":       c.orgao_descricao,
                "orgao_poder":           c.orgao_poder,
                "modalidade_codigo":     c.modalidade_codigo,
                "modalidade_descricao":  c.modalidade_descricao,
                "tipo_contrato":         c.tipo_contrato,
                "licitacao_numero":      c.licitacao_numero,
                "licitacao_modalidade":  c.licitacao_modalidade,
                "updated_at":            datetime.utcnow().isoformat(),
            })
            if len(batch) >= CHUNK:
                self._upsert(batch)
                total += len(batch)
                batch = []
        if batch:
            self._upsert(batch)
            total += len(batch)
        logger.info("Contratos: %d upsertados", total)
        return total

    def start_log(self, descricao: str) -> int | None:
        resp = self.session.post(
            f"{self.url}/rest/v1/contratos_ingest_log",
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
            f"{self.url}/rest/v1/contratos_ingest_log",
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
