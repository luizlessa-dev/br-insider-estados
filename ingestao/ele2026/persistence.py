"""
Camada de persistência — Eleições 2026
Tabelas: ele2026_candidatos, ele2026_financiamento, ele2026_gastos, ele2026_ingest_log

Lógica extra (ausente no tse/persistence.py):
  _enrich_com_parlamentares()
      Após gravar candidatos, cruza CPFs com a tabela `parlamentares` para
      preencher parlamentar_id e id_camara em ele2026_candidatos.

  _marcar_alertas_candidatura()
      Marca ele2026_alertas.candidatura_entrou = true para os CPFs que entraram.
      Isso aciona o painel ele26_v_alertas_painel automaticamente.
"""
from __future__ import annotations

import logging
import os
from datetime import date, datetime
from typing import Iterable, Iterator, Union

import requests

from ingestao.tse.connector import Despesa, Receita

from .connector import Candidato2026

logger = logging.getLogger("ele2026.persistence")

CHUNK = 500


class PersistenceError(Exception):
    pass


def _jsonable(v):
    if isinstance(v, (date, datetime)):
        return v.isoformat()
    if isinstance(v, (list, tuple)):
        return [_jsonable(x) for x in v]
    return v


class Ele2026Writer:
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
    def from_env(cls) -> "Ele2026Writer | None":
        try:
            return cls()
        except PersistenceError as e:
            logger.warning("Ele2026Writer desativado — %s", e)
            return None

    # ─── Primitivas HTTP ──────────────────────────────────────────────────

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

    def _bulk_insert(self, table: str, rows: list[dict]) -> int:
        rows = [{k: _jsonable(v) for k, v in r.items()} for r in rows]
        total = 0
        for i in range(0, len(rows), CHUNK):
            chunk = rows[i: i + CHUNK]
            resp = self.session.post(
                f"{self.url}/rest/v1/{table}",
                headers={"Prefer": "return=minimal"},
                json=chunk,
                timeout=300,
            )
            if resp.status_code >= 300:
                raise PersistenceError(
                    f"insert {table}: HTTP {resp.status_code} — {resp.text[:300]}"
                )
            total += len(chunk)
        return total

    def _patch_where(self, table: str, params: dict, payload: dict) -> None:
        resp = self.session.patch(
            f"{self.url}/rest/v1/{table}",
            params=params,
            headers={"Prefer": "return=minimal"},
            json=payload,
            timeout=30,
        )
        if resp.status_code >= 300:
            logger.warning("_patch_where %s: HTTP %d — %s",
                           table, resp.status_code, resp.text[:200])

    def _select(self, table: str, params: dict) -> list[dict]:
        resp = self.session.get(
            f"{self.url}/rest/v1/{table}",
            params=params,
            headers={"Accept": "application/json"},
            timeout=30,
        )
        if resp.status_code >= 300:
            logger.warning("_select %s: HTTP %d", table, resp.status_code)
            return []
        return resp.json()

    # ─── Candidatos ───────────────────────────────────────────────────────

    def upsert_candidatos(self, candidatos: Iterable[Candidato2026]) -> int:
        """
        Grava candidatos em ele2026_candidatos, depois:
          1. Cruza CPFs com `parlamentares` para preencher parlamentar_id e id_camara
          2. Marca ele2026_alertas.candidatura_entrou = true para os monitorados
        """
        rows = []
        cpfs_gravados: list[str] = []

        for c in candidatos:
            rows.append({
                "id": c.id,
                "sq_candidato": c.sq_candidato,
                "cpf": c.cpf,
                "nome": c.nome,
                "nome_urna": c.nome_urna,
                "data_nascimento": c.data_nascimento,
                "genero": c.genero,
                "cor_raca": c.cor_raca,
                "grau_instrucao": c.grau_instrucao,
                "ocupacao": c.ocupacao,
                "estado_civil": c.estado_civil,
                "email": c.email,
                "foto_url": c.foto_url,
                "cd_cargo": c.cd_cargo,
                "cargo": c.cargo,
                "uf": c.uf,
                "municipio_nascimento": c.municipio_nascimento,
                "nr_partido": c.nr_partido,
                "sigla_partido": c.sigla_partido,
                "nome_partido": c.nome_partido,
                "nome_federacao": c.nome_federacao,
                "sigla_federacao": c.sigla_federacao,
                "situacao_candidatura": c.situacao_candidatura,
                "situacao_turno1": c.situacao_turno1,
                "situacao_turno2": c.situacao_turno2,
                "eleito": c.eleito,
                "reeleicao": c.reeleicao,
                "limite_despesa": c.limite_despesa,
                "updated_at": datetime.utcnow().isoformat(),
            })
            if c.cpf:
                cpfs_gravados.append(c.cpf)

        if not rows:
            return 0

        n = self._upsert("ele2026_candidatos", rows, on_conflict="id")
        logger.info("ele2026 candidatos: %d gravados/atualizados", n)

        # Enriquecimento pós-ingestão
        if cpfs_gravados:
            self._enrich_com_parlamentares(cpfs_gravados)
            self._marcar_alertas_candidatura(cpfs_gravados)

        return n

    def _enrich_com_parlamentares(self, cpfs: list[str]) -> None:
        """
        Para cada CPF gravado em ele2026_candidatos, verifica se existe
        um parlamentar ativo em `parlamentares` e preenche parlamentar_id e id_camara.

        Opera em lotes de 50 CPFs (PostgREST 'in' filter).
        """
        enriquecidos = 0
        for i in range(0, len(cpfs), 50):
            lote = cpfs[i:i + 50]
            cpf_list = ",".join(lote)
            parlamentares = self._select(
                "parlamentares",
                {
                    "cpf": f"in.({cpf_list})",
                    "select": "id,cpf,id_camara",
                }
            )
            if not parlamentares:
                continue
            for p in parlamentares:
                self._patch_where(
                    "ele2026_candidatos",
                    {"cpf": f"eq.{p['cpf']}"},
                    {
                        "parlamentar_id": p["id"],
                        "id_camara": p.get("id_camara"),
                        "updated_at": datetime.utcnow().isoformat(),
                    }
                )
                enriquecidos += 1

        logger.info("ele2026 candidatos: %d enriquecidos com dados de parlamentar", enriquecidos)

    def _marcar_alertas_candidatura(self, cpfs: list[str]) -> None:
        """
        Para cada CPF em ele2026_alertas que agora tem candidatura registrada,
        marca candidatura_entrou = true e preenche o CPF no alerta (se estava NULL).
        """
        alertas_atualizados = 0
        for i in range(0, len(cpfs), 50):
            lote = cpfs[i:i + 50]
            cpf_list = ",".join(lote)
            # Busca alertas cujo CPF bate e ainda não foi marcado
            alertas = self._select(
                "ele2026_alertas",
                {
                    "cpf": f"in.({cpf_list})",
                    "candidatura_entrou": "eq.false",
                    "alerta_ativo": "eq.true",
                    "select": "id,cpf,nome",
                }
            )
            for a in alertas:
                self._patch_where(
                    "ele2026_alertas",
                    {"id": f"eq.{a['id']}"},
                    {
                        "candidatura_entrou": True,
                        "notificado_em": datetime.utcnow().isoformat(),
                        "atualizado_em": datetime.utcnow().isoformat(),
                    }
                )
                logger.info("ALERTA candidatura: %s (cpf=%s)", a.get("nome"), a.get("cpf"))
                alertas_atualizados += 1

        if alertas_atualizados:
            logger.warning(
                "ele2026 alertas: %d candidatos monitorados ENTRARAM na corrida!",
                alertas_atualizados
            )

    # ─── Financiamento ────────────────────────────────────────────────────

    def upsert_financiamento(
        self,
        receitas: Union[Iterable[Receita], "Iterator[Receita]"],
    ) -> int:
        """
        Grava receitas em ele2026_financiamento.
        Estratégia: delete-then-stream (mesmo padrão de tse/persistence.py).
        Após gravar, marca ele2026_alertas.financiamento_entrou para os monitorados.
        """
        self._delete_all("ele2026_financiamento")
        total = 0
        batch: list[dict] = []
        cpfs_vistos: set[str] = set()

        for r in receitas:
            batch.append({
                "numero_recibo": r.numero_recibo,
                "data_receita": r.data_receita,
                "cpf_candidato": r.cpf_candidato,
                "nome_candidato": r.nome_candidato,
                "cargo": r.cargo,
                "sigla_partido": r.sigla_partido,
                "uf": r.uf,
                "cpf_cnpj_doador": r.cpf_cnpj_doador,
                "nome_doador": r.nome_doador,
                "tipo_doador": r.tipo_doador,
                "setor_economico_doador": r.setor_economico_doador,
                "cpf_cnpj_doador_originario": r.cpf_cnpj_doador_originario,
                "nome_doador_originario": r.nome_doador_originario,
                "natureza_receita": r.natureza_receita,
                "origem_receita": r.origem_receita,
                "especie_recurso": r.especie_recurso,
                "fonte_recurso": r.fonte_recurso,
                "valor": r.valor,
                "data_prestacao_contas": r.data_prestacao_contas,
            })
            if r.cpf_candidato:
                cpfs_vistos.add(r.cpf_candidato)

            if len(batch) >= CHUNK:
                self._bulk_insert("ele2026_financiamento", batch)
                total += len(batch)
                batch = []

        if batch:
            self._bulk_insert("ele2026_financiamento", batch)
            total += len(batch)

        logger.info("ele2026 financiamento: %d registros gravados", total)

        # Marcar alertas
        if cpfs_vistos:
            self._marcar_alertas_financiamento(list(cpfs_vistos))

        return total

    def _marcar_alertas_financiamento(self, cpfs: list[str]) -> None:
        """Marca financiamento_entrou = true para alertas cujo CPF apareceu nas receitas."""
        atualizados = 0
        for i in range(0, len(cpfs), 50):
            lote = cpfs[i:i + 50]
            cpf_list = ",".join(lote)
            alertas = self._select(
                "ele2026_alertas",
                {
                    "cpf": f"in.({cpf_list})",
                    "financiamento_entrou": "eq.false",
                    "alerta_ativo": "eq.true",
                    "select": "id,cpf,nome",
                }
            )
            for a in alertas:
                self._patch_where(
                    "ele2026_alertas",
                    {"id": f"eq.{a['id']}"},
                    {
                        "financiamento_entrou": True,
                        "atualizado_em": datetime.utcnow().isoformat(),
                    }
                )
                logger.warning(
                    "ALERTA financiamento: %s (cpf=%s) começou a arrecadar!",
                    a.get("nome"), a.get("cpf")
                )
                atualizados += 1

        if atualizados:
            logger.warning(
                "ele2026 alertas: %d candidatos monitorados com FINANCIAMENTO registrado.",
                atualizados
            )

    # ─── Gastos ───────────────────────────────────────────────────────────

    def upsert_gastos(
        self,
        despesas: Union[Iterable[Despesa], "Iterator[Despesa]"],
    ) -> int:
        """Grava despesas em ele2026_gastos. Mesmo padrão streaming do financiamento."""
        self._delete_all("ele2026_gastos")
        total = 0
        batch: list[dict] = []

        for d in despesas:
            batch.append({
                "numero_documento": d.numero_documento,
                "data_despesa": d.data_despesa,
                "cpf_candidato": d.cpf_candidato,
                "nome_candidato": d.nome_candidato,
                "cargo": d.cargo,
                "sigla_partido": d.sigla_partido,
                "uf": d.uf,
                "cpf_cnpj_fornecedor": d.cpf_cnpj_fornecedor,
                "nome_fornecedor": d.nome_fornecedor,
                "tipo_despesa": d.tipo_despesa,
                "descricao_despesa": d.descricao_despesa,
                "origem_despesa": d.origem_despesa,
                "especie_recurso": d.especie_recurso,
                "fonte_recurso": d.fonte_recurso,
                "valor_despesa": d.valor_despesa,
                "valor_prestado": d.valor_prestado,
            })
            if len(batch) >= CHUNK:
                self._bulk_insert("ele2026_gastos", batch)
                total += len(batch)
                batch = []

        if batch:
            self._bulk_insert("ele2026_gastos", batch)
            total += len(batch)

        logger.info("ele2026 gastos: %d registros gravados", total)
        return total

    # ─── Utilidades ───────────────────────────────────────────────────────

    def _delete_all(self, table: str) -> None:
        """Deleta todos os registros da tabela (para reload completo)."""
        resp = self.session.delete(
            f"{self.url}/rest/v1/{table}",
            params={"id": "gt.0"},    # PostgREST exige ao menos um filtro
            headers={"Prefer": "return=minimal"},
            timeout=60,
        )
        if resp.status_code >= 300:
            raise PersistenceError(
                f"delete {table}: HTTP {resp.status_code} — {resp.text[:200]}"
            )
        logger.info("%s: tabela limpa antes do reload", table)

    # ─── Log ──────────────────────────────────────────────────────────────

    def start_log(self, dataset: str) -> int | None:
        resp = self.session.post(
            f"{self.url}/rest/v1/ele2026_ingest_log",
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
        log_id: int | None,
        status: str,
        n_processados: int = 0,
        n_novos: int = 0,
        erro: str | None = None,
    ) -> None:
        if not log_id:
            return
        self.session.patch(
            f"{self.url}/rest/v1/ele2026_ingest_log",
            params={"id": f"eq.{log_id}"},
            headers={"Prefer": "return=minimal"},
            json={
                "finished_at": datetime.utcnow().isoformat(),
                "status": status,
                "n_processados": n_processados,
                "n_novos": n_novos,
                "erro": erro,
            },
            timeout=30,
        )

    def cleanup_stuck_logs(self) -> None:
        self.session.patch(
            f"{self.url}/rest/v1/ele2026_ingest_log",
            params={"status": "eq.running", "finished_at": "is.null"},
            headers={"Prefer": "return=minimal"},
            json={
                "status": "interrompido",
                "finished_at": datetime.utcnow().isoformat(),
                "erro": "marcado como interrompido na próxima execução",
            },
            timeout=30,
        )
