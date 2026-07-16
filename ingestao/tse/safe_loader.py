"""
Carga segura de um ano/dataset do TSE (receitas ou despesas).

Ordem inviolável — a tabela FINAL nunca é tocada antes de:
  1. arquivo baixado;
  2. arquivo validado (ZIP + CSV);
  3. staging completo (todas as linhas do run inseridas);
  4. quality gate aprovado (contagem >= mínimo esperado).

O swap final (DELETE do ano + INSERT do staging) é atômico e roda no banco,
via a função tse_promote_year() (ver sql/0001_tse_safe_pipeline.sql). Qualquer
falha em qualquer fase deixa a tabela final intacta.

O módulo é desenhado com dependências injetáveis (Source + Backend) para ser
testável sem rede nem banco — ver ingestao/tse/tests/test_safe_loader.py.
"""
from __future__ import annotations

import logging
import time
import uuid
from dataclasses import dataclass
from typing import Callable, Iterable, Protocol

logger = logging.getLogger("tse.safe_loader")


class SourceError(Exception):
    """Falha de download/validação da fonte (CDN indisponível, ZIP/CSV inválido)."""


class QualityGateError(Exception):
    """Contagem abaixo do mínimo esperado — swap bloqueado."""


class Source(Protocol):
    """Fonte de dados de um ano/dataset. Deve baixar, validar e devolver linhas."""

    def download_and_validate(self) -> None:
        """Baixa o ZIP e valida ZIP + CSV. Levanta SourceError em qualquer problema."""
        ...

    def iter_rows(self) -> Iterable[dict]:
        """Itera as linhas já validadas. Só chamar após download_and_validate()."""
        ...


class Backend(Protocol):
    """Abstrai o acesso ao banco (real = PostgREST; teste = fake em memória)."""

    def count_final(self, dataset: str, ano: int) -> int: ...
    def stage_rows(self, dataset: str, run_id: str, rows: Iterable[dict]) -> int: ...
    def count_staging(self, dataset: str, run_id: str) -> int: ...
    def promote(self, dataset: str, ano: int, run_id: str, min_expected: int) -> dict: ...
    def clear_staging(self, dataset: str, run_id: str) -> None: ...
    def record_run(self, run: "RunRecord") -> None: ...


class _CountingIter:
    """Envolve um iterável contando os itens que passam por ele."""

    def __init__(self, inner):
        self._inner = iter(inner)
        self.count = 0

    def __iter__(self):
        return self

    def __next__(self):
        item = next(self._inner)
        self.count += 1
        return item


@dataclass
class RunRecord:
    run_id: str
    dataset: str
    ano: int
    phase: str = "iniciado"
    status: str = "running"
    rows_downloaded: int | None = None
    rows_parsed: int | None = None
    rows_staged: int | None = None
    rows_final_before: int | None = None
    rows_final_after: int | None = None
    min_expected: int | None = None
    error: str | None = None
    staging_expires_at_days: int | None = None


@dataclass
class SafeLoaderConfig:
    # fração da contagem atual que o staging precisa atingir para o swap passar.
    # 0.70 = tolera até 30% de queda; abaixo disso, bloqueia (dado provavelmente truncado).
    min_ratio: float = 0.70
    # se a final está vazia (ano novo), aceita qualquer contagem > 0.
    max_retries: int = 4
    backoff_base_s: float = 5.0
    staging_expiry_days_on_failure: int = 7


def load_year(
    dataset: str,
    ano: int,
    source: Source,
    backend: Backend,
    cfg: SafeLoaderConfig | None = None,
    sleep: Callable[[float], None] = time.sleep,
) -> dict:
    """Executa a carga segura de um ano/dataset. Retorna o resultado do promote."""
    if dataset not in ("receitas", "despesas"):
        raise ValueError(f"dataset invalido: {dataset}")
    cfg = cfg or SafeLoaderConfig()
    run_id = str(uuid.uuid4())
    run = RunRecord(run_id=run_id, dataset=dataset, ano=ano)

    # snapshot da contagem atual ANTES de tudo — base do quality gate.
    before = backend.count_final(dataset, ano)
    run.rows_final_before = before
    min_expected = 1 if before == 0 else max(1, int(before * cfg.min_ratio))
    run.min_expected = min_expected
    backend.record_run(run)

    try:
        # ── FASE 1+2: download + validação (com retry/backoff) ──────────────
        # Injeta o sleep do cfg via closure para testes controlarem o tempo.
        def _dl() -> None:
            source.download_and_validate()
        _retry_with_sleep(_dl, cfg, f"download {dataset} {ano}", sleep)
        run.phase = "validado"
        backend.record_run(run)

        # ── FASE 3: staging (nada na final ainda) ───────────────────────────
        # Conta as linhas parseadas enquanto insere no staging.
        parsed_counter = _CountingIter(source.iter_rows())
        staged = backend.stage_rows(dataset, run_id, parsed_counter)
        parsed = parsed_counter.count
        run.rows_parsed = parsed
        run.rows_staged = staged
        run.phase = "staged"
        backend.record_run(run)

        # Gate: contagem carregada (no banco) == contagem parseada do arquivo.
        in_db = backend.count_staging(dataset, run_id)
        if in_db != parsed:
            raise QualityGateError(
                f"contagem divergente: parseadas={parsed} != staging_no_banco={in_db} "
                f"(dataset={dataset} ano={ano} run={run_id})"
            )

        # ── FASE 4: promote atômico (quality gate + swap no banco) ──────────
        result = backend.promote(dataset, ano, run_id, min_expected)
        run.rows_final_after = result.get("rows_after")
        run.phase = "promovido"
        run.status = "ok"
        backend.record_run(run)
        logger.info("promote ok: %s", result)
        return result

    except Exception as exc:
        # Falha em qualquer fase: a final NUNCA foi tocada (delete só ocorre
        # dentro do promote atômico). Preserva staging para diagnóstico.
        run.status = "erro"
        run.phase = "falha"
        run.error = str(exc)[:500]
        run.staging_expires_at_days = cfg.staging_expiry_days_on_failure
        backend.record_run(run)
        logger.error("carga segura falhou (dataset=%s ano=%s): %s", dataset, ano, exc)
        raise


def _retry_with_sleep(fn, cfg: SafeLoaderConfig, what: str, sleep) -> None:
    last: Exception | None = None
    for attempt in range(1, cfg.max_retries + 1):
        try:
            fn()
            return
        except SourceError as exc:
            last = exc
            if attempt < cfg.max_retries:
                wait = cfg.backoff_base_s * (2 ** (attempt - 1))
                logger.warning("%s falhou (tentativa %d/%d): %s — retry em %.0fs",
                               what, attempt, cfg.max_retries, exc, wait)
                sleep(wait)
    assert last is not None
    raise last
