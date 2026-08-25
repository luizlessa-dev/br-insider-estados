"""
Runner TSE — executa ingestão de candidatos, receitas e/ou despesas.

Uso:
  python -m ingestao.tse.runner --dataset candidatos --ano 2024
  python -m ingestao.tse.runner --dataset receitas   --ano 2022
  python -m ingestao.tse.runner --dataset despesas   --ano 2024
  python -m ingestao.tse.runner --dataset todos      --ano 2022 --ano 2024

Variáveis de ambiente necessárias:
  SUPABASE_URL
  SUPABASE_SERVICE_ROLE_KEY  (ou INTERNAL_SUPABASE_SERVICE_ROLE_KEY)
"""
from __future__ import annotations

import argparse
import logging
import os
import sys

from .connector import get_candidatos, iter_despesas, iter_receitas
from .persistence import TSEWriter

# Anos cujo ZIP de prestação de contas usa URL/formato diferente do padrão moderno
# (layout de colunas por índice, arquivos .txt por UF, latin-1). Roteados pelo
# _run_safe() abaixo para legacy_source.LegacyZipSource em vez de
# zip_source.ZipYearSource — mesmo pipeline seguro (staging + swap atômico),
# só muda o parser de origem.
ANOS_LEGADOS = {2014, 2016}

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(name)s %(levelname)s %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("tse.runner")


def run_candidatos(writer: TSEWriter, ano: int) -> None:
    dataset = f"candidatos_{ano}"
    log_id = writer.start_log(dataset)
    try:
        candidatos = get_candidatos(ano)
        n = writer.upsert_candidatos(candidatos)
        writer.finish_log(log_id, "ok", n_processados=len(candidatos), n_novos=n)
        logger.info("candidatos %d: %d processados, %d gravados", ano, len(candidatos), n)
    except Exception as exc:
        writer.finish_log(log_id, "erro", erro=str(exc))
        logger.error("candidatos %d falhou: %s", ano, exc)
        raise


# Caminho seguro (staging + swap atômico). O flag DEVE valer exatamente "1" para
# habilitar receitas/despesas. Qualquer outro valor (ausente, "0", inválido)
# BLOQUEIA receitas/despesas com erro explícito — nunca há fallback para o
# delete-before-load antigo. O código legado (upsert_receitas/upsert_despesas
# com _delete_year) permanece na classe TSEWriter mas é INALCANÇÁVEL por execução
# normal do runner: nenhum caminho abaixo o chama.
SAFE_LOADER = os.environ.get("TSE_SAFE_LOADER") == "1"


class SafeLoaderDisabled(RuntimeError):
    """Receitas/despesas exigem TSE_SAFE_LOADER=1 (pipeline seguro)."""


class AnoLegadoNaoAprovado(RuntimeError):
    """2014/2016 exigem aprovação humana separada (TSE_LEGACY_APPROVED=1),
    além de TSE_SAFE_LOADER=1. O código está migrado pro pipeline seguro
    (LegacyZipSource) mas isso NÃO é sozinho autorização pra rodar contra
    produção — ver ingestao/tse/HOMOLOGACAO.md: só os anos modernos foram
    homologados numa branch descartável até agora."""


def _exigir_safe_loader(dataset: str) -> None:
    if not SAFE_LOADER:
        raise SafeLoaderDisabled(
            f"'{dataset}' BLOQUEADO: exige TSE_SAFE_LOADER=1 (pipeline seguro com "
            f"staging + swap atômico). O fluxo antigo delete-before-load foi "
            f"desativado por segurança e não é alcançável. Aplique a migration "
            f"sql/0001_tse_safe_pipeline.sql e defina TSE_SAFE_LOADER=1."
        )


def _exigir_aprovacao_legado(dataset: str, ano: int) -> None:
    if ano in ANOS_LEGADOS and os.environ.get("TSE_LEGACY_APPROVED") != "1":
        raise AnoLegadoNaoAprovado(
            f"'{dataset}' {ano}: BLOQUEADO. O ano {ano} usa LegacyZipSource "
            f"(pipeline seguro, formato de coluna antigo) — código pronto e com "
            f"testes unitários, mas AINDA NÃO homologado numa branch descartável "
            f"com ZIP real, e é o mesmo ano do incidente de 2026-06-20. Exige "
            f"aprovação humana separada: defina TSE_LEGACY_APPROVED=1 depois de "
            f"validar contra um ZIP real numa branch descartável."
        )


def _run_safe(writer: TSEWriter, dataset: str, ano: int) -> int:
    """Executa receitas/despesas pelo pipeline seguro. Retorna linhas finais.
    Anos legado (ANOS_LEGADOS) usam LegacyZipSource (parser de formato antigo);
    os demais usam ZipYearSource (connector.py moderno). Em ambos os casos o
    DELETE só acontece dentro de tse_promote_year() (swap atômico) — nunca
    antes do download, ao contrário do ingest_legado.py standalone.

    Backend: DirectPgBackend (COPY, via TSE_PG_DSN) se a env var estiver
    presente; senão PostgrestBackend (REST) como fallback. Achado em produção
    (2026-08-24, despesas 2016): PostgrestBackend.stage_rows() faz dois counts
    exatos por batch de 500, cujo custo cresce com o staging e bateu em
    statement_timeout do Postgres com ~1,3M linhas acumuladas. DirectPgBackend
    evita isso (um COPY, uma contagem via rowcount) — ver copy_backend.py."""
    from .safe_loader import load_year

    if ano in ANOS_LEGADOS:
        from .legacy_source import LegacyZipSource
        source = LegacyZipSource(dataset, ano)
    else:
        from .zip_source import ZipYearSource
        source = ZipYearSource(dataset, ano)

    if os.environ.get("TSE_PG_DSN"):
        from .copy_backend import DirectPgBackend
        backend = DirectPgBackend()
        logger.info("backend: DirectPgBackend (COPY, TSE_PG_DSN presente)")
    else:
        from .safe_backend import PostgrestBackend
        backend = PostgrestBackend(writer)
        logger.info("backend: PostgrestBackend (REST) — TSE_PG_DSN ausente")

    result = load_year(dataset, ano, source, backend)
    return int(result.get("rows_after") or 0)


def run_receitas(writer: TSEWriter, ano: int) -> None:
    dataset = f"receitas_{ano}"
    log_id = writer.start_log(dataset)
    try:
        _exigir_safe_loader("receitas")
        _exigir_aprovacao_legado("receitas", ano)
        n = _run_safe(writer, "receitas", ano)
        writer.finish_log(log_id, "ok", n_novos=n)
        logger.info("receitas %d: %d gravadas", ano, n)
    except Exception as exc:
        writer.finish_log(log_id, "erro", erro=str(exc))
        logger.error("receitas %d falhou: %s", ano, exc)
        raise


def run_despesas(writer: TSEWriter, ano: int, skip_delete: bool = False) -> None:
    dataset = f"despesas_{ano}"
    log_id = writer.start_log(dataset)
    try:
        _exigir_safe_loader("despesas")
        _exigir_aprovacao_legado("despesas", ano)
        # o pipeline seguro substitui o ano inteiro atomicamente; skip_delete
        # não se aplica (não há delete-antes-do-load para pular).
        n = _run_safe(writer, "despesas", ano)
        writer.finish_log(log_id, "ok", n_novos=n)
        logger.info("despesas %d: %d gravadas", ano, n)
    except Exception as exc:
        writer.finish_log(log_id, "erro", erro=str(exc))
        logger.error("despesas %d falhou: %s", ano, exc)
        raise


def main() -> None:
    parser = argparse.ArgumentParser(description="Ingestão TSE → Supabase")
    parser.add_argument(
        "--dataset",
        choices=["candidatos", "receitas", "despesas", "todos"],
        required=True,
    )
    parser.add_argument(
        "--ano",
        type=int,
        action="append",
        dest="anos",
        required=True,
        help="Ano da eleição (pode repetir: --ano 2022 --ano 2024)",
    )
    parser.add_argument(
        "--skip-delete",
        action="store_true",
        help="Não deletar ano antes de inserir (útil para retomar run parcial)",
    )
    args = parser.parse_args()

    writer = TSEWriter.from_env()
    if not writer:
        logger.error("Credenciais Supabase ausentes. Abortando.")
        sys.exit(1)

    writer.cleanup_stuck_logs()

    erros = 0
    for ano in args.anos:
        if args.dataset in ("candidatos", "todos"):
            try:
                run_candidatos(writer, ano)
            except Exception:
                erros += 1
        if args.dataset in ("receitas", "todos"):
            try:
                run_receitas(writer, ano)
            except Exception:
                erros += 1
        if args.dataset in ("despesas", "todos"):
            try:
                run_despesas(writer, ano, skip_delete=args.skip_delete)
            except Exception:
                erros += 1

    if erros:
        logger.error("%d dataset(s) falharam.", erros)
        sys.exit(1)
    logger.info("Ingestão TSE concluída.")


if __name__ == "__main__":
    main()
