"""
Testes do pipeline seguro TSE (safe_loader) com fakes em memória.

Nenhum toca rede ou banco. O FakeBackend reproduz a INVARIANTE crítica da
função tse_promote_year: o swap (delete do ano + insert do staging) é atômico
— ou os dois acontecem, ou a tabela final permanece exatamente como estava.

Cobre os 8 cenários obrigatórios da missão.
"""
from __future__ import annotations

import threading

import pytest

from ingestao.tse.safe_loader import (
    QualityGateError,
    SafeLoaderConfig,
    Source,
    SourceError,
    load_year,
)


# ── Fakes ───────────────────────────────────────────────────────────────────

class FakeSource(Source):
    """Fonte controlável: pode simular CDN off, ZIP corrompido, CSV vazio."""

    def __init__(self, rows, fail_download_times=0, fail_forever=False):
        self._rows = rows
        self._fail_forever = fail_forever
        self._fails_left = fail_download_times
        self.download_calls = 0

    def download_and_validate(self):
        self.download_calls += 1
        if self._fail_forever:
            raise SourceError("CDN indisponível (simulado)")
        if self._fails_left > 0:
            self._fails_left -= 1
            raise SourceError("timeout transitório (simulado)")

    def iter_rows(self):
        return iter(self._rows)


class FakeBackend:
    """Simula final + staging + promote atômico, em memória."""

    def __init__(self, final_rows_by_year, promote_hook=None):
        # final_rows_by_year: {(dataset, ano): [rows]}
        self.final = {k: list(v) for k, v in final_rows_by_year.items()}
        self.staging = {}   # {(dataset, run_id): [rows]}
        self.runs = {}      # {run_id: RunRecord}
        self._promote_hook = promote_hook
        self._lock = threading.Lock()

    def count_final(self, dataset, ano):
        return len(self.final.get((dataset, ano), []))

    def stage_rows(self, dataset, run_id, rows):
        materialized = list(rows)
        self.staging[(dataset, run_id)] = materialized
        return len(materialized)

    def count_staging(self, dataset, run_id):
        return len(self.staging.get((dataset, run_id), []))

    def promote(self, dataset, ano, run_id, min_expected):
        # advisory lock simulado por (dataset, ano)
        with self._lock:
            staged = self.staging.get((dataset, run_id), [])
            n = len(staged)
            if n == 0:
                raise QualityGateError("staging vazio")
            if min_expected is not None and n < min_expected:
                raise QualityGateError(f"queda anormal: {n} < {min_expected}")
            # ponto de injeção de falha DEPOIS do quality gate mas no meio do swap
            before = list(self.final.get((dataset, ano), []))
            # SWAP ATÔMICO simulado: monta o novo estado e só aplica se nada falhar.
            try:
                if self._promote_hook:
                    self._promote_hook()  # pode levantar → simula falha no INSERT
                new_final = staged  # substitui o ano inteiro
            except Exception:
                # rollback: final permanece intacta
                self.final[(dataset, ano)] = before
                raise
            self.final[(dataset, ano)] = list(new_final)
            self.staging.pop((dataset, run_id), None)  # cleanup no sucesso
            return {"rows_before": len(before), "rows_staged": n,
                    "rows_after": len(new_final)}

    def clear_staging(self, dataset, run_id):
        self.staging.pop((dataset, run_id), None)

    def record_run(self, run):
        self.runs[run.run_id] = run


NO_SLEEP = lambda _s: None
FAST = SafeLoaderConfig(backoff_base_s=0.0)


def _rows(n, ano=2022):
    return [{"ano_eleicao": ano, "numero_recibo": f"R{i}", "valor": 1.0} for i in range(n)]


# ── 1. CDN indisponível: tabela final permanece intacta ─────────────────────
def test_cdn_indisponivel_final_intacta():
    final = {("receitas", 2022): _rows(100)}
    be = FakeBackend(final)
    src = FakeSource(_rows(100), fail_forever=True)
    with pytest.raises(SourceError):
        load_year("receitas", 2022, src, be, cfg=FAST, sleep=NO_SLEEP)
    assert be.count_final("receitas", 2022) == 100  # intacta
    assert src.download_calls == FAST.max_retries    # tentou e desistiu


# ── 2. ZIP corrompido: final intacta (validação levanta SourceError) ────────
def test_zip_corrompido_final_intacta():
    be = FakeBackend({("despesas", 2022): _rows(50)})
    src = FakeSource(_rows(50), fail_forever=True)  # download_and_validate sempre falha
    with pytest.raises(SourceError):
        load_year("despesas", 2022, src, be, cfg=FAST, sleep=NO_SLEEP)
    assert be.count_final("despesas", 2022) == 50


# ── 3. CSV vazio: final intacta (staging 0 → quality gate bloqueia) ─────────
def test_csv_vazio_final_intacta():
    be = FakeBackend({("receitas", 2022): _rows(100)})
    src = FakeSource([])  # download ok, mas zero linhas
    with pytest.raises(QualityGateError):
        load_year("receitas", 2022, src, be, cfg=FAST, sleep=NO_SLEEP)
    assert be.count_final("receitas", 2022) == 100


# ── 4. Falha durante INSERT final: transação desfaz o DELETE ────────────────
def test_falha_no_insert_desfaz_delete():
    def boom():
        raise RuntimeError("erro no INSERT final")
    be = FakeBackend({("receitas", 2022): _rows(100)}, promote_hook=boom)
    src = FakeSource(_rows(100))
    with pytest.raises(RuntimeError):
        load_year("receitas", 2022, src, be, cfg=FAST, sleep=NO_SLEEP)
    # o ano continua com as 100 linhas originais — delete foi revertido
    assert be.count_final("receitas", 2022) == 100


# ── 5. Duas execuções simultâneas p/ o mesmo ano: só uma promove por vez ─────
def test_execucoes_simultaneas_serializadas():
    be = FakeBackend({("receitas", 2022): _rows(100)})
    order = []
    real_promote = be.promote

    def instrumented(dataset, ano, run_id, min_expected):
        order.append(("enter", run_id))
        r = real_promote(dataset, ano, run_id, min_expected)
        order.append(("exit", run_id))
        return r
    be.promote = instrumented

    def worker(tag):
        src = FakeSource(_rows(100))
        load_year("receitas", 2022, src, be, cfg=FAST, sleep=NO_SLEEP)

    t1 = threading.Thread(target=worker, args=("a",))
    t2 = threading.Thread(target=worker, args=("b",))
    t1.start(); t2.start(); t1.join(); t2.join()
    # o lock garante enter/exit pareados (nenhum interleave enter/enter)
    for i in range(0, len(order), 2):
        assert order[i][0] == "enter" and order[i + 1][0] == "exit"
        assert order[i][1] == order[i + 1][1]
    assert be.count_final("receitas", 2022) == 100


# ── 6. Reexecução do mesmo arquivo: resultado idempotente ───────────────────
def test_reexecucao_idempotente():
    be = FakeBackend({("receitas", 2022): _rows(100)})
    for _ in range(3):
        src = FakeSource(_rows(100))
        load_year("receitas", 2022, src, be, cfg=FAST, sleep=NO_SLEEP)
    assert be.count_final("receitas", 2022) == 100  # estável, sem duplicar
    assert be.staging == {}                          # staging limpo após sucesso


# ── 7. Queda anormal de contagem: swap bloqueado ────────────────────────────
def test_queda_anormal_bloqueia_swap():
    be = FakeBackend({("receitas", 2022): _rows(1000)})
    # min_ratio 0.70 → min_expected = 700; staging só 300 → bloqueia
    src = FakeSource(_rows(300))
    with pytest.raises(QualityGateError):
        load_year("receitas", 2022, src, be, cfg=SafeLoaderConfig(min_ratio=0.70, backoff_base_s=0.0), sleep=NO_SLEEP)
    assert be.count_final("receitas", 2022) == 1000  # intacta


# ── 8. Carga normal: dados do ano são substituídos integralmente ────────────
def test_carga_normal_substitui_ano():
    be = FakeBackend({("receitas", 2022): _rows(100)})
    novos = [{"ano_eleicao": 2022, "numero_recibo": f"NOVO{i}", "valor": 2.0} for i in range(120)]
    src = FakeSource(novos)
    result = load_year("receitas", 2022, src, be, cfg=FAST, sleep=NO_SLEEP)
    assert be.count_final("receitas", 2022) == 120
    assert result["rows_before"] == 100
    assert result["rows_after"] == 120
    # confirma que são os registros novos, não os antigos
    recibos = {r["numero_recibo"] for r in be.final[("receitas", 2022)]}
    assert all(x.startswith("NOVO") for x in recibos)


# ── Extra: ano novo (final vazia) aceita qualquer contagem > 0 ──────────────
def test_ano_novo_final_vazia():
    be = FakeBackend({})  # sem dado para 2026
    src = FakeSource(_rows(5, ano=2026))
    load_year("receitas", 2026, src, be, cfg=FAST, sleep=NO_SLEEP)
    assert be.count_final("receitas", 2026) == 5


# ── Extra: retry transitório recupera antes de esgotar ──────────────────────
def test_retry_transitorio_recupera():
    be = FakeBackend({("receitas", 2022): _rows(100)})
    src = FakeSource(_rows(100), fail_download_times=2)  # falha 2x, sucesso na 3ª
    load_year("receitas", 2022, src, be, cfg=FAST, sleep=NO_SLEEP)
    assert src.download_calls == 3
    assert be.count_final("receitas", 2022) == 100


# ── Extra: gate parseadas == staging bloqueia se o banco perder linhas ───────
def test_gate_parsed_diferente_de_staged():
    be = FakeBackend({("receitas", 2022): _rows(100)})

    # backend que "perde" metade das linhas ao contar staging (simula insert parcial)
    real_count_staging = be.count_staging
    be.count_staging = lambda ds, rid: real_count_staging(ds, rid) // 2

    src = FakeSource(_rows(100))
    with pytest.raises(QualityGateError):
        load_year("receitas", 2022, src, be, cfg=FAST, sleep=NO_SLEEP)
    assert be.count_final("receitas", 2022) == 100  # final intacta


# ═══ Testes adicionais (revisão): fingerprint, resume, sent-vs-inserted ═══════
from ingestao.tse.safe_loader import (  # noqa: E402
    FINGERPRINT_CAMPOS, TRANSFORMER_VERSION, pode_retomar, row_fingerprint,
)


def test_fingerprint_deterministico_e_distingue_por_ordinal():
    c = FINGERPRINT_CAMPOS["despesas"]
    r = {"ano_eleicao": 2024, "numero_documento": None, "cpf_candidato": "X", "valor_despesa": 10.0}
    assert row_fingerprint(r, 5, c) == row_fingerprint(r, 5, c)          # determinístico
    assert row_fingerprint(r, 5, c) != row_fingerprint(r, 6, c)          # ordinal distingue idênticas
    assert row_fingerprint(r, 5, c) == row_fingerprint({**r, "cpf_candidato": " x "}, 5, c)  # normaliza


def test_resume_mesmo_hash_permite():
    run = {"phase": "staging", "status": "running", "dataset": "receitas", "ano": 2024,
           "zip_sha256": "abc", "zip_bytes": 100, "transformer_version": TRANSFORMER_VERSION}
    assert pode_retomar(run, "abc", 100, "receitas", 2024) is True


def test_resume_hash_diferente_obriga_novo_run():
    run = {"phase": "staging", "status": "running", "dataset": "receitas", "ano": 2024,
           "zip_sha256": "abc", "zip_bytes": 100, "transformer_version": TRANSFORMER_VERSION}
    assert pode_retomar(run, "XYZ", 100, "receitas", 2024) is False      # conteúdo mudou
    assert pode_retomar(run, "abc", 999, "receitas", 2024) is False      # tamanho mudou
    assert pode_retomar({**run, "transformer_version": "0"}, "abc", 100, "receitas", 2024) is False
    assert pode_retomar({**run, "phase": "promovido"}, "abc", 100, "receitas", 2024) is False


def test_sent_vs_inserted_conflito_inesperado_sem_resume():
    """stage_rows do backend real: conflito inesperado (sem resume) → erro.
    Testado com um backend fake que simula o count antes/depois."""
    from ingestao.tse.safe_backend import PostgrestBackend, PersistenceError

    class FakeSession:
        def __init__(self): self.n = 0
        def post(self, *a, **k):
            # simula que só metade "entrou" (conflito): count sobe só 1 por batch de 2
            self.n += 1
            class R: status_code = 200; text = ""
            return R()
        def get(self, *a, **k):
            class R:
                status_code = 200
                headers = {"content-range": f"*/{_be.calls}"}
                text = ""
            return R()
        def patch(self, *a, **k):
            class R: status_code = 200; text = ""
            return R()

    class W: url = "http://x"; session = FakeSession()
    _be = PostgrestBackend(W(), sleep=lambda s: None)
    # força count: before=0, after=1 (só 1 de 2 entrou) → ignoradas=1 sem resume → erro
    seq = iter([0, 1])
    _be._count = lambda t, r: next(seq)
    _be._patch_run = lambda r, f: None
    _be._post_batch = lambda *a, **k: None
    try:
        _be.stage_rows("despesas", "run1",
                       [{"ano_eleicao": 2024, "valor_despesa": 1.0},
                        {"ano_eleicao": 2024, "valor_despesa": 2.0}], resume=False)
        assert False, "deveria ter levantado por conflito inesperado"
    except PersistenceError as e:
        assert "conflito inesperado" in str(e)
