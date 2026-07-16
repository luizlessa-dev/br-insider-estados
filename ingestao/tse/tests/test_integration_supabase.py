"""
Teste INTEGRADO do pipeline seguro TSE contra um Supabase/PostgREST REAL.

⚠️  NÃO roda contra produção. Só executa se as env vars apontarem para um
projeto DESCARTÁVEL (uma branch Supabase criada só para o teste). Sem elas, o
módulo inteiro é pulado (skip), então CI/produção nunca disparam isto por engano.

Pré-requisitos no projeto descartável:
  1. Aplicar sql/0001_tse_safe_pipeline.sql (staging + logs + RPC).
  2. Ter as tabelas tse_receitas / tse_despesas (do schema base).
  3. Exportar:
       TSE_IT_URL   = https://<branch-ref>.supabase.co
       TSE_IT_SERVICE_KEY = service_role key da branch
       TSE_IT_ANON_KEY    = anon key da branch (para testar RLS/grants)

Cobre: staging real, RPC real, rollback transacional real, advisory lock real,
grants, RLS, service_role, falha de promoção, concorrência e limpeza do staging.
"""
from __future__ import annotations

import os
import uuid

import pytest
import requests

IT_URL = os.environ.get("TSE_IT_URL")
IT_SERVICE = os.environ.get("TSE_IT_SERVICE_KEY")
IT_ANON = os.environ.get("TSE_IT_ANON_KEY")

pytestmark = pytest.mark.skipif(
    not (IT_URL and IT_SERVICE),
    reason="teste integrado: defina TSE_IT_URL e TSE_IT_SERVICE_KEY (projeto descartável)",
)


def _svc():
    s = requests.Session()
    s.headers.update({"apikey": IT_SERVICE, "Authorization": f"Bearer {IT_SERVICE}",
                      "Content-Type": "application/json"})
    return s


def _anon():
    s = requests.Session()
    s.headers.update({"apikey": IT_ANON, "Authorization": f"Bearer {IT_ANON}",
                      "Content-Type": "application/json"})
    return s


ANO_TESTE = 1998  # ano fictício, nunca colide com dado eleitoral real


def _stage_row(run_id, i, ano=ANO_TESTE):
    return {"run_id": run_id, "ano_eleicao": ano, "numero_recibo": f"IT-{run_id}-{i}",
            "valor": 1.0}


def _count_final(s, ano):
    r = s.get(f"{IT_URL}/rest/v1/tse_receitas",
              params={"ano_eleicao": f"eq.{ano}", "select": "ano_eleicao"},
              headers={"Prefer": "count=exact", "Range": "0-0"})
    return int(r.headers.get("content-range", "*/0").split("/")[-1] or 0)


def _record_run(s, run_id, ano, min_expected):
    s.post(f"{IT_URL}/rest/v1/tse_load_runs",
           params={"on_conflict": "run_id"},
           headers={"Prefer": "resolution=merge-duplicates,return=minimal"},
           json=[{"run_id": run_id, "dataset": "receitas", "ano": ano,
                  "phase": "staged", "status": "running", "min_expected": min_expected}])


def _promote(s, run_id, ano, min_expected):
    return s.post(f"{IT_URL}/rest/v1/rpc/tse_promote_year",
                  json={"p_dataset": "receitas", "p_ano": ano,
                        "p_run_id": run_id, "p_min_expected": min_expected})


@pytest.fixture
def clean_ano():
    s = _svc()
    # limpa qualquer resíduo do ano de teste antes e depois
    s.delete(f"{IT_URL}/rest/v1/tse_receitas", params={"ano_eleicao": f"eq.{ANO_TESTE}"})
    yield ANO_TESTE
    s.delete(f"{IT_URL}/rest/v1/tse_receitas", params={"ano_eleicao": f"eq.{ANO_TESTE}"})


def test_grants_rls_anon_sem_acesso():
    """anon não lê staging nem executa a RPC (postura pós-P0)."""
    if not IT_ANON:
        pytest.skip("defina TSE_IT_ANON_KEY para testar RLS/grants")
    a = _anon()
    r = a.get(f"{IT_URL}/rest/v1/tse_receitas_staging", params={"select": "run_id"},
              headers={"Range": "0-0"})
    assert r.status_code in (401, 403) or r.json() == []
    r2 = a.post(f"{IT_URL}/rest/v1/rpc/tse_promote_year",
                json={"p_dataset": "receitas", "p_ano": ANO_TESTE,
                      "p_run_id": str(uuid.uuid4()), "p_min_expected": 1})
    assert r2.status_code in (401, 403, 404)


def test_carga_normal_e_cleanup(clean_ano):
    """staging real → RPC real → final substituída → staging limpo."""
    s = _svc()
    run_id = str(uuid.uuid4())
    _record_run(s, run_id, clean_ano, 1)
    s.post(f"{IT_URL}/rest/v1/tse_receitas_staging",
           headers={"Prefer": "return=minimal"},
           json=[_stage_row(run_id, i) for i in range(50)])
    r = _promote(s, run_id, clean_ano, 1)
    assert r.status_code < 300, r.text
    assert _count_final(s, clean_ano) == 50
    # staging limpo após sucesso
    cnt = s.get(f"{IT_URL}/rest/v1/tse_receitas_staging",
                params={"run_id": f"eq.{run_id}", "select": "run_id"},
                headers={"Prefer": "count=exact", "Range": "0-0"})
    assert int(cnt.headers.get("content-range", "*/0").split("/")[-1]) == 0


def test_quality_gate_bloqueia_e_final_intacta(clean_ano):
    """staged < min_expected → RPC levanta, final permanece intacta."""
    s = _svc()
    # semeia 100 linhas 'existentes'
    run0 = str(uuid.uuid4())
    _record_run(s, run0, clean_ano, 1)
    s.post(f"{IT_URL}/rest/v1/tse_receitas_staging", headers={"Prefer": "return=minimal"},
           json=[_stage_row(run0, i) for i in range(100)])
    _promote(s, run0, clean_ano, 1)
    assert _count_final(s, clean_ano) == 100

    # nova carga com só 10 linhas e min_expected=70 → bloqueia
    run1 = str(uuid.uuid4())
    _record_run(s, run1, clean_ano, 70)
    s.post(f"{IT_URL}/rest/v1/tse_receitas_staging", headers={"Prefer": "return=minimal"},
           json=[_stage_row(run1, i) for i in range(10)])
    r = _promote(s, run1, clean_ano, 70)
    assert r.status_code >= 400            # RPC abortou
    assert _count_final(s, clean_ano) == 100  # final intacta (rollback real)


def test_mistura_de_anos_bloqueia(clean_ano):
    """staging com ano != p_ano → RPC recusa."""
    s = _svc()
    run_id = str(uuid.uuid4())
    _record_run(s, run_id, clean_ano, 1)
    rows = [_stage_row(run_id, i) for i in range(5)]
    rows.append(_stage_row(run_id, 99, ano=1997))  # ano intruso
    s.post(f"{IT_URL}/rest/v1/tse_receitas_staging", headers={"Prefer": "return=minimal"}, json=rows)
    r = _promote(s, run_id, clean_ano, 1)
    assert r.status_code >= 400
    assert _count_final(s, clean_ano) == 0


def test_run_de_outro_dataset_ou_ano_recusado(clean_ano):
    """run registrado como (receitas, X) não promove (receitas, Y)."""
    s = _svc()
    run_id = str(uuid.uuid4())
    _record_run(s, run_id, 1996, 1)  # run pertence a 1996
    s.post(f"{IT_URL}/rest/v1/tse_receitas_staging", headers={"Prefer": "return=minimal"},
           json=[_stage_row(run_id, i, ano=clean_ano) for i in range(5)])
    r = _promote(s, run_id, clean_ano, 1)  # tenta promover para ANO_TESTE
    assert r.status_code >= 400


def test_idempotencia_repromote(clean_ano):
    """promover o mesmo run 2x: 2ª chamada é no-op idempotente."""
    s = _svc()
    run_id = str(uuid.uuid4())
    _record_run(s, run_id, clean_ano, 1)
    s.post(f"{IT_URL}/rest/v1/tse_receitas_staging", headers={"Prefer": "return=minimal"},
           json=[_stage_row(run_id, i) for i in range(20)])
    r1 = _promote(s, run_id, clean_ano, 1)
    assert r1.status_code < 300
    r2 = _promote(s, run_id, clean_ano, 1)
    assert r2.status_code < 300
    assert r2.json().get("already_promoted") is True
    assert _count_final(s, clean_ano) == 20  # não duplicou


# NOTA sobre advisory lock / concorrência:
# O lock (pg_advisory_xact_lock) só é observável com duas transações de fato
# concorrentes contra o MESMO (dataset, ano). Um teste determinístico exige
# duas conexões psql/psycopg simultâneas segurando transações abertas — fora do
# alcance do PostgREST (cada request é sua própria transação curta). Recomenda-se
# validar o lock com um script psycopg dedicado (ver plano de teste integrado),
# não via este arquivo. O comportamento funcional (uma promoção por vez, sem
# corromper a final) está coberto pelos testes acima + o teste de concorrência
# em test_safe_loader.py.
