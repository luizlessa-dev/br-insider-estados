"""
Seeder CEIS / CNEP / CEPIM — ingestão completa via API do Portal Transparência

O filtro por CNPJ da API não funciona corretamente — esta estratégia baixa
TODOS os registros uma vez por mês e armazena em tabelas locais (sub_ceis,
sub_cnep, sub_cepim) para lookup instantâneo.

Volume estimado:
  CEIS  ~22.500 registros (~1.500 páginas)
  CNEP  ~3.500 registros (~250 páginas)
  CEPIM ~7.500 registros (~500 páginas)

Uso:
  python3 -m ingestao.subradar.sancoes_seeder
  python3 -m ingestao.subradar.sancoes_seeder --dataset ceis
"""
from __future__ import annotations

import argparse
import logging
import os
import re
import sys
import time
from datetime import datetime
from pathlib import Path

import requests

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from ingestao.subradar.base import SUPABASE_URL, SUPABASE_KEY, _supabase_headers, _jsonable

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
)
logger = logging.getLogger("sancoes_seeder")

PT_BASE = "https://api.portaldatransparencia.gov.br/api-de-dados"
PT_KEY = os.environ.get("PORTAL_TRANSPARENCIA_API_KEY", "")
PT_HEADERS = {"chave-api-dados": PT_KEY, "Accept": "application/json"}

BATCH_SIZE = 200
REQUEST_DELAY = 0.15  # segundos entre páginas (respeita rate limit)


def _parse_date(s: str) -> str | None:
    if not s:
        return None
    for fmt in ("%d/%m/%Y", "%Y-%m-%d"):
        try:
            return datetime.strptime(s.strip(), fmt).date().isoformat()
        except ValueError:
            pass
    return None


def _upsert_local(table: str, rows: list[dict]) -> None:
    if not rows or not SUPABASE_URL or not SUPABASE_KEY:
        return
    url = f"{SUPABASE_URL}/rest/v1/{table}"
    params = {"on_conflict": "id"}
    headers = {**_supabase_headers(), "Prefer": "resolution=ignore-duplicates,return=minimal"}
    for i in range(0, len(rows), BATCH_SIZE):
        batch = [_jsonable(r) for r in rows[i:i + BATCH_SIZE]]
        for attempt in range(5):
            try:
                r = requests.post(url, json=batch, headers=headers, params=params, timeout=60)
                if r.ok:
                    break
                if r.status_code in (429, 503):
                    time.sleep(2 ** attempt)
                    continue
                logger.error("upsert %s: %s %s", table, r.status_code, r.text[:200])
                r.raise_for_status()
            except requests.exceptions.ConnectionError:
                time.sleep(2 ** attempt)
        else:
            raise RuntimeError(f"upsert {table} falhou após 5 tentativas")


def _transform_ceis_cnep(item: dict) -> dict:
    pessoa = item.get("pessoa") or {}
    orgao = item.get("orgaoSancionador") or {}
    tipo = item.get("tipoSancao") or {}
    fundam = (item.get("fundamentacao") or [{}])[0].get("codigo", "")[:200] if item.get("fundamentacao") else ""
    cnpj_cpf = pessoa.get("cnpjFormatado") or pessoa.get("cpfFormatado") or \
               (item.get("sancionado") or {}).get("codigoFormatado", "")
    return {
        "id": item.get("id"),
        "cnpj_cpf": re.sub(r"\D", "", cnpj_cpf),  # só dígitos para index
        "nome": pessoa.get("nome") or (item.get("sancionado") or {}).get("nome"),
        "tipo_sancao": tipo.get("descricaoResumida", ""),
        "orgao_sancionador": orgao.get("nome", ""),
        "esfera": orgao.get("esfera", ""),
        "data_inicio": _parse_date(item.get("dataInicioSancao", "")),
        "data_fim": _parse_date(item.get("dataFimSancao", "")),
        "numero_processo": item.get("numeroProcesso", ""),
        "fundamentacao": fundam,
        "texto_publicacao": item.get("textoPublicacao", "")[:300],
        "link_publicacao": item.get("linkPublicacao", "")[:300],
    }


def _transform_cepim(item: dict) -> dict:
    pj = item.get("pessoaJuridica") or {}
    orgao = item.get("orgaoSuperior") or {}
    convenio = item.get("convenio") or {}
    cnpj = re.sub(r"\D", "", pj.get("cnpjFormatado", ""))
    return {
        "id": item.get("id"),
        "cnpj": cnpj,
        "nome": pj.get("nome", ""),
        "motivo": item.get("motivo", "")[:300],
        "orgao_superior": orgao.get("nome", ""),
        "num_convenio": convenio.get("numero", "") if isinstance(convenio, dict) else "",
        "data_referencia": _parse_date(item.get("dataReferencia", "")),
    }


DATASETS = {
    "ceis":  {"endpoint": "ceis",  "table": "sub_ceis",  "transform": _transform_ceis_cnep},
    "cnep":  {"endpoint": "cnep",  "table": "sub_cnep",  "transform": _transform_ceis_cnep},
    "cepim": {"endpoint": "cepim", "table": "sub_cepim", "transform": _transform_cepim},
}


def seed_dataset(key: str) -> int:
    cfg = DATASETS[key]
    endpoint = cfg["endpoint"]
    table = cfg["table"]
    transform = cfg["transform"]
    logger.info("Iniciando %s → %s", endpoint.upper(), table)

    total = 0
    pagina = 1
    batch = []

    while True:
        try:
            r = requests.get(
                f"{PT_BASE}/{endpoint}",
                params={"pagina": pagina},
                headers=PT_HEADERS,
                timeout=20,
            )
            if not r.ok:
                if r.status_code == 403:
                    logger.warning("%s: rate limit p.%d — aguardando 30s", endpoint, pagina)
                    time.sleep(30)
                    continue
                logger.warning("%s: HTTP %s na p.%d — encerrando", endpoint, r.status_code, pagina)
                break
            items = r.json()
            if not isinstance(items, list) or not items:
                break  # fim da paginação

            for item in items:
                row = transform(item)
                if row.get("cnpj_cpf") or row.get("cnpj"):  # ignora sem CNPJ
                    batch.append(row)

            if len(batch) >= BATCH_SIZE:
                _upsert_local(table, batch)
                total += len(batch)
                batch = []
                if total % 5000 == 0:
                    logger.info("  %s: %d registros inseridos (p.%d)", endpoint, total, pagina)

            pagina += 1
            time.sleep(REQUEST_DELAY)

        except requests.exceptions.RequestException as e:
            logger.warning("%s: erro p.%d: %s — retry", endpoint, pagina, e)
            time.sleep(5)

    if batch:
        _upsert_local(table, batch)
        total += len(batch)

    logger.info("%s concluído: %d registros", endpoint.upper(), total)
    return total


def main() -> None:
    parser = argparse.ArgumentParser(description="Seeder CEIS/CNEP/CEPIM")
    parser.add_argument("--dataset", choices=list(DATASETS.keys()) + ["todos"], default="todos")
    args = parser.parse_args()

    if not PT_KEY:
        logger.error("PORTAL_TRANSPARENCIA_API_KEY não configurada")
        sys.exit(1)

    keys = list(DATASETS.keys()) if args.dataset == "todos" else [args.dataset]
    total_geral = 0
    for k in keys:
        total_geral += seed_dataset(k)

    logger.info("TOTAL: %d registros inseridos", total_geral)


if __name__ == "__main__":
    main()
