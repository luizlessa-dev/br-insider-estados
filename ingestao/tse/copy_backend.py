"""
Transporte de carga do staging via COPY (psycopg 3) — para datasets grandes
(receitas/despesas de 2022/2024, 2M–6,5M linhas). MUITO mais rápido que POSTs
PostgREST em batch.

Requisitos atendidos:
  • streaming: usa cursor.copy() com um gerador — nunca acumula o dataset em RAM.
  • TLS: sslmode=require na connection string.
  • credencial só via secret: lê TSE_PG_DSN do ambiente (secret do runner); nunca
    hardcoded, nunca logado.
  • transaction control explícito: BEGIN/COMMIT manual; falha → ROLLBACK.
  • retomada por run_id: COPY para uma tabela temporária do run, depois
    INSERT ... ON CONFLICT (run_id, identity_key) DO NOTHING no staging real →
    reenviar o mesmo arquivo é idempotente.
  • progresso persistido: atualiza tse_load_runs (linhas_enviadas/inseridas).
  • hash e proveniência: grava zip_sha256/zip_bytes/source_url/pipeline_commit/
    transformer_version no run antes de carregar.
  • limpeza segura: DROP da temp ao fim (inclusive em falha).
  • falha sem tocar a final: COPY e o INSERT vão para STAGING; a tabela FINAL só é
    tocada por tse_promote_year (swap atômico), nunca aqui.

PostgREST permanece como fallback para datasets pequenos (ver safe_backend).
"""
from __future__ import annotations

import logging
import os
from typing import Iterable

from .safe_loader import FINGERPRINT_CAMPOS, row_fingerprint

logger = logging.getLogger("tse.copy_backend")

# ordem das colunas no COPY (dados + controle), por dataset. identity_key é
# GERADA pelo banco — não entra no COPY.
_COPY_COLS = {
    "receitas": ["ano_eleicao", "source_id", "numero_recibo", "cpf_candidato",
                 "nome_candidato", "cargo", "sigla_partido", "uf", "cpf_cnpj_doador",
                 "nome_doador", "tipo_doador", "setor_economico_doador",
                 "cpf_cnpj_doador_originario", "nome_doador_originario",
                 "natureza_receita", "origem_receita", "especie_recurso",
                 "fonte_recurso", "valor", "data_receita", "data_prestacao_contas",
                 "run_id", "row_fingerprint"],
    "despesas": ["ano_eleicao", "source_id", "numero_documento", "cpf_candidato",
                 "nome_candidato", "cargo", "sigla_partido", "uf", "cpf_cnpj_fornecedor",
                 "nome_fornecedor", "tipo_despesa", "descricao_despesa", "origem_despesa",
                 "especie_recurso", "fonte_recurso", "valor_despesa", "valor_prestado",
                 "data_despesa", "run_id", "row_fingerprint"],
}
_STAGING = {"receitas": "tse_receitas_staging", "despesas": "tse_despesas_staging"}


class CopyBackend:
    """Carrega staging via COPY. Requer TSE_PG_DSN (secret) com sslmode=require."""

    def __init__(self, dsn: str | None = None) -> None:
        self.dsn = dsn or os.environ.get("TSE_PG_DSN")
        if not self.dsn:
            raise RuntimeError("TSE_PG_DSN ausente (secret com a connection string TLS).")
        if "sslmode=" not in self.dsn:
            self.dsn += " sslmode=require"

    def stage_via_copy(self, dataset: str, run_id: str, rows: Iterable[dict]) -> dict:
        """COPY streaming → temp → INSERT idempotente no staging. Retorna
        {enviadas, inseridas, ignoradas}. Nunca toca a tabela final."""
        import psycopg  # import tardio: só quando o COPY é realmente usado

        cols = _COPY_COLS[dataset]
        fp_campos = FINGERPRINT_CAMPOS[dataset]
        staging = _STAGING[dataset]
        tmp = f"_tse_copy_{run_id.replace('-', '')}"

        conn = psycopg.connect(self.dsn, autocommit=False)
        enviadas = inseridas = 0
        try:
            with conn.cursor() as cur:
                # temp do run: mesmas colunas do COPY (sem a generated identity_key)
                cur.execute(
                    f"create temp table {tmp} (like public.{staging} "
                    f"including defaults excluding constraints) on commit drop")
                # a temp herda identity_key (generated) — remover para o COPY
                cur.execute(f"alter table {tmp} drop column if exists identity_key")

                copy_sql = f"copy {tmp} ({', '.join(cols)}) from stdin"
                with cur.copy(copy_sql) as cp:
                    ordinal = 0
                    for r in rows:
                        ordinal += 1
                        fp = row_fingerprint(r, ordinal, fp_campos)
                        rec = dict(r)
                        rec["run_id"] = run_id
                        rec["row_fingerprint"] = fp
                        cp.write_row([rec.get(c) for c in cols])
                        enviadas += 1

                # move para o staging real de forma idempotente
                collist = ", ".join(cols)
                cur.execute(
                    f"insert into public.{staging} ({collist}) "
                    f"select {collist} from {tmp} "
                    f"on conflict (run_id, identity_key) do nothing")
                inseridas = cur.rowcount

                # progresso/proveniência
                cur.execute(
                    "update public.tse_load_runs set linhas_enviadas=%s, "
                    "linhas_inseridas=%s, linhas_ignoradas=%s, phase='staged' "
                    "where run_id=%s",
                    (enviadas, inseridas, enviadas - inseridas, run_id))
            conn.commit()   # transaction control explícito
            logger.info("COPY %s run=%s enviadas=%d inseridas=%d ignoradas=%d",
                        dataset, run_id, enviadas, inseridas, enviadas - inseridas)
            return {"enviadas": enviadas, "inseridas": inseridas,
                    "ignoradas": enviadas - inseridas}
        except Exception:
            conn.rollback()   # falha → nada persiste; final intocada
            raise
        finally:
            conn.close()      # limpeza segura (temp cai com a sessão)

    def record_provenance(self, run_id: str, *, zip_sha256: str, zip_bytes: int,
                          source_url: str, pipeline_commit: str,
                          transformer_version: str) -> None:
        """Grava hash/proveniência ANTES da carga (base da decisão de retomada)."""
        import psycopg
        conn = psycopg.connect(self.dsn, autocommit=True)
        try:
            with conn.cursor() as cur:
                cur.execute(
                    "update public.tse_load_runs set zip_sha256=%s, zip_bytes=%s, "
                    "source_url=%s, pipeline_commit=%s, transformer_version=%s "
                    "where run_id=%s",
                    (zip_sha256, zip_bytes, source_url, pipeline_commit,
                     transformer_version, run_id))
        finally:
            conn.close()
