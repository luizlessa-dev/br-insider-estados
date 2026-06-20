"""Persistência de Licitações — The Brasilia Insider."""
from __future__ import annotations

import logging
import os
from datetime import date, datetime
from typing import Iterator

import requests

from .licitacoes_connector import Licitacao, Participante

logger = logging.getLogger("cgu.licitacoes.persistence")

CHUNK = 300


class PersistenceError(Exception):
    pass


def _jsonable(v):
    if isinstance(v, (date, datetime)):
        return v.isoformat()
    return v


class LicitacoesWriter:
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
    def from_env(cls) -> "LicitacoesWriter | None":
        try:
            return cls()
        except PersistenceError as e:
            logger.warning("LicitacoesWriter desativado — %s", e)
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

    def upsert_licitacoes(self, licitacoes: Iterator[Licitacao]) -> int:
        total_l = 0
        total_p = 0
        batch_l: list[dict] = []
        batch_p: list[dict] = []

        for l in licitacoes:
            if not l.id:
                continue
            batch_l.append({
                "id":                    l.id,
                "numero":                l.numero,
                "objeto":                l.objeto,
                "data_abertura":         l.data_abertura,
                "data_publicacao":       l.data_publicacao,
                "situacao_codigo":       l.situacao_codigo,
                "situacao_descricao":    l.situacao_descricao,
                "modalidade_codigo":     l.modalidade_codigo,
                "modalidade_descricao":  l.modalidade_descricao,
                "ug_codigo":             l.ug_codigo,
                "ug_descricao":          l.ug_descricao,
                "orgao_codigo":          l.orgao_codigo,
                "orgao_descricao":       l.orgao_descricao,
                "valor_estimado":        l.valor_estimado,
                "tipo_licitacao":        l.tipo_licitacao,
                "numero_processo":       l.numero_processo,
                "updated_at":            datetime.utcnow().isoformat(),
            })
            for p in l.participantes:
                batch_p.append({
                    "licitacao_id":           p.licitacao_id,
                    "cnpj":                   p.cnpj,
                    "cpf":                    p.cpf,
                    "nome":                   p.nome,
                    "situacao_participante":  p.situacao_participante,
                    "situacao_fornecedor":    p.situacao_fornecedor,
                    "valor_proposta":         p.valor_proposta,
                    "updated_at":             datetime.utcnow().isoformat(),
                })

            if len(batch_l) >= CHUNK:
                self._upsert("licitacoes", batch_l, on_conflict="id")
                total_l += len(batch_l)
                batch_l = []
            if len(batch_p) >= CHUNK:
                self._upsert("licitacoes_participantes", batch_p,
                             on_conflict="licitacao_id,cnpj,cpf")
                total_p += len(batch_p)
                batch_p = []

        if batch_l:
            self._upsert("licitacoes", batch_l, on_conflict="id")
            total_l += len(batch_l)
        if batch_p:
            self._upsert("licitacoes_participantes", batch_p,
                         on_conflict="licitacao_id,cnpj,cpf")
            total_p += len(batch_p)

        logger.info("Licitações: %d upsertadas, %d participantes", total_l, total_p)
        return total_l

    def start_log(self, descricao: str) -> int | None:
        resp = self.session.post(
            f"{self.url}/rest/v1/licitacoes_ingest_log",
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
            f"{self.url}/rest/v1/licitacoes_ingest_log",
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
