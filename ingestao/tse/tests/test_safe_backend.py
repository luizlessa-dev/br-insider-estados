"""
Teste offline de PostgrestBackend.record_run() — sem rede, sem banco.

Existia um mismatch real entre o payload de record_run() e as colunas de
tse_load_runs (achado em produção, 2026-08-24): o payload mandava
rows_downloaded/rows_staged, que não existem — a tabela usa
linhas_parseadas/linhas_staged (ver sql/0001_tse_safe_pipeline.sql). PostgREST
rejeitava com 400/PGRST204; o erro era só logado como WARNING, então a carga
seguia rodando sem gravar progresso nenhum, sem quebrar visivelmente.

Este teste intercepta a chamada HTTP (sem rede real) e valida que toda chave
do payload é uma coluna real de tse_load_runs.
"""
from __future__ import annotations

from ingestao.tse.safe_backend import PostgrestBackend
from ingestao.tse.safe_loader import RunRecord

# Colunas reais de public.tse_load_runs, extraídas de
# sql/0001_tse_safe_pipeline.sql — mantenha em sincronia se a migration mudar.
COLUNAS_REAIS_TSE_LOAD_RUNS = {
    "run_id", "dataset", "ano", "phase", "status",
    "batches_total", "batch_atual", "ultimo_batch_confirmado",
    "linhas_parseadas", "linhas_staged", "linhas_enviadas",
    "linhas_inseridas", "linhas_ignoradas",
    "zip_sha256", "pipeline_commit", "transformer_version",
    "rows_final_before", "rows_final_after", "min_expected", "null_key_count",
    "override_gate", "override_motivo", "override_by", "override_at",
    "override_pct_drop", "override_github_run_id", "override_github_actor",
    "override_github_sha", "override_run_url",
    "source_url", "zip_bytes", "error",
    "started_at", "finished_at", "staging_expires_at",
}


class _FakeResponse:
    status_code = 200
    text = ""


class _FakeSession:
    def __init__(self):
        self.last_payload = None

    def post(self, url, params=None, headers=None, json=None, timeout=None):
        self.last_payload = json[0] if json else None
        return _FakeResponse()


class _FakeWriter:
    def __init__(self):
        self.url = "https://fake.supabase.co"
        self.session = _FakeSession()


def test_record_run_payload_so_usa_colunas_reais():
    writer = _FakeWriter()
    backend = PostgrestBackend(writer)
    run = RunRecord(
        run_id="00000000-0000-0000-0000-000000000000",
        dataset="despesas", ano=2016, phase="staged", status="running",
        rows_parsed=100, rows_staged=100, min_expected=1,
    )
    backend.record_run(run)

    payload = writer.session.last_payload
    assert payload is not None, "record_run não chamou session.post"
    chaves_invalidas = set(payload.keys()) - COLUNAS_REAIS_TSE_LOAD_RUNS
    assert not chaves_invalidas, (
        f"payload de record_run usa colunas que não existem em tse_load_runs: "
        f"{chaves_invalidas}"
    )
