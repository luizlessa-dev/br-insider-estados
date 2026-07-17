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

import requests

from .connector import get_candidatos, iter_despesas, iter_receitas
from .ingest_legado import (
    ZIP_URLS as ZIP_URLS_LEGADO,
    ingerir as ingerir_despesas_legado,
    ingerir_receitas as ingerir_receitas_legado,
)
from .persistence import TSEWriter

# Anos cujo ZIP de prestação de contas usa URL/formato diferente do padrão moderno.
# O connector.py tenta prestacao_de_contas_eleitorais_candidatos_{ano}.zip (404 nesses anos).
# ingest_legado.py sabe as URLs corretas e lida com o formato .txt.
ANOS_LEGADOS = {2014, 2016}


def _baixar_zip_legado(ano: int) -> str:
    """Baixa o ZIP legado para /tmp e retorna o caminho. Reutiliza se já existe."""
    zip_path = f"/tmp/tse_{ano}.zip"
    if os.path.exists(zip_path):
        logger.info("ZIP legado %d já existe: %s", ano, zip_path)
        return zip_path
    url = ZIP_URLS_LEGADO[ano]
    logger.info("Baixando ZIP legado %d → %s", ano, zip_path)
    r = requests.get(url, stream=True, timeout=600)
    r.raise_for_status()
    with open(zip_path, "wb") as f:
        for chunk in r.iter_content(65536):
            f.write(chunk)
    logger.info("Download concluído: %s", zip_path)
    return zip_path

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


def _exigir_safe_loader(dataset: str) -> None:
    if not SAFE_LOADER:
        raise SafeLoaderDisabled(
            f"'{dataset}' BLOQUEADO: exige TSE_SAFE_LOADER=1 (pipeline seguro com "
            f"staging + swap atômico). O fluxo antigo delete-before-load foi "
            f"desativado por segurança e não é alcançável. Aplique a migration "
            f"sql/0001_tse_safe_pipeline.sql e defina TSE_SAFE_LOADER=1."
        )


def _run_safe(writer: TSEWriter, dataset: str, ano: int) -> int:
    """Executa receitas/despesas modernas pelo pipeline seguro. Retorna linhas finais."""
    from .safe_backend import PostgrestBackend
    from .safe_loader import load_year
    from .zip_source import ZipYearSource

    source = ZipYearSource(dataset, ano)
    backend = PostgrestBackend(writer)
    result = load_year(dataset, ano, source, backend)
    return int(result.get("rows_after") or 0)


def run_receitas(writer: TSEWriter, ano: int) -> None:
    dataset = f"receitas_{ano}"
    log_id = writer.start_log(dataset)
    try:
        if ano in ANOS_LEGADOS:
            # 2014/2016: ainda usam ingest_legado (delete-before-load). NÃO liberar
            # como teste seguro. Bloqueado até o legado ganhar o mesmo tratamento.
            raise SafeLoaderDisabled(
                f"receitas {ano}: ano legado ainda usa ingest_legado "
                f"(delete-before-load). Bloqueado até migração para o pipeline seguro."
            )
        _exigir_safe_loader("receitas")
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
        if ano in ANOS_LEGADOS:
            raise SafeLoaderDisabled(
                f"despesas {ano}: ano legado ainda usa ingest_legado "
                f"(delete-before-load). Bloqueado até migração para o pipeline seguro."
            )
        _exigir_safe_loader("despesas")
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
