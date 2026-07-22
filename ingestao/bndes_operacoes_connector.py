"""
BNDES — Operações Não Automáticas (bndes_operacoes_nao_automaticas)
The BR Insider

Fonte: CKAN dadosabertos.bndes.gov.br, dataset "operacoes-financiamento",
resource "Operações não automáticas" (id 6f56b78c-510f-44b6-8274-78a5b7e931f4).
CNPJ do cliente vem completo neste resource — confirmado via datastore_search
em 2026-07-22 (diferente do resource "indiretas automáticas", mascarado, que
não é ingerido aqui). Ver docstring de ingestao/subradar/bndes.py para o
histórico da suposição anterior.

~23,6k linhas, dados desde 2002, atualização mensal. Paginação via
datastore_search (limit 500).

Sem chave natural única: subcréditos do mesmo contrato podem ter valor e
data idênticos, e há linhas idênticas em todos os campos (confirmado em
2026-07-22 — nenhuma combinação de campos elimina colisões). Por isso a
estratégia é full refresh: apaga a tabela e reinsere tudo a cada execução,
em vez de upsert por chave natural (que perderia subcréditos colididos).

Uso:
  python -m ingestao.bndes_operacoes_connector

Tabela: bndes_operacoes_nao_automaticas
"""
from __future__ import annotations

import logging
import os
import re
import time
from datetime import datetime
from typing import Any, Optional

import requests

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("bndes_operacoes")

CKAN_URL    = "https://dadosabertos.bndes.gov.br/api/3/action/datastore_search"
RESOURCE_ID = "6f56b78c-510f-44b6-8274-78a5b7e931f4"
PAGE_SIZE   = 500
PAGE_DELAY  = 0.3

TABLE      = "bndes_operacoes_nao_automaticas"
BATCH_SIZE = 400

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SUPABASE_KEY = (
    os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    or os.environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY")
    or ""
)


# ── helpers ───────────────────────────────────────────────────────────────

def _headers_api() -> dict:
    return {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "return=minimal",
    }


def _strip_cnpj(v: Any) -> Optional[str]:
    digits = re.sub(r"\D", "", str(v or ""))
    return digits if len(digits) == 14 else None


def _txt(v: Any) -> Optional[str]:
    s = str(v).strip() if v is not None else ""
    return s if s and s != "----------" else None


def _parse_date(v: Any) -> Optional[str]:
    """Datastore retorna timestamp tipo '2002-01-02T00:00:00'."""
    if not v:
        return None
    try:
        return datetime.strptime(str(v)[:10], "%Y-%m-%d").date().isoformat()
    except ValueError:
        return None


def _num(v: Any) -> Optional[float]:
    if v is None or v == "":
        return None
    try:
        return float(v)
    except (TypeError, ValueError):
        return None


def _int(v: Any) -> Optional[int]:
    n = _num(v)
    return int(n) if n is not None else None


# ── fetch + parse ────────────────────────────────────────────────────────

def fetch_page(session: requests.Session, offset: int) -> tuple[list[dict], int]:
    last_exc: Exception | None = None
    for attempt in range(5):
        try:
            resp = session.get(
                CKAN_URL,
                params={"resource_id": RESOURCE_ID, "limit": PAGE_SIZE, "offset": offset},
                timeout=60,
            )
            resp.raise_for_status()
            data = resp.json()
            if not data.get("success"):
                raise RuntimeError(f"datastore_search falhou: {data}")
            result = data["result"]
            return result.get("records", []), result.get("total", 0)
        except (requests.exceptions.ConnectionError, requests.exceptions.Timeout) as exc:
            last_exc = exc
            wait = 2 ** attempt
            logger.warning("fetch_page offset=%d: %s — retry em %ds", offset, exc, wait)
            time.sleep(wait)
    raise RuntimeError(f"fetch_page offset={offset}: falhou após 5 tentativas") from last_exc


def parse_record(r: dict) -> Optional[dict]:
    cnpj = _strip_cnpj(r.get("cnpj"))
    numero_contrato = _int(r.get("numero_do_contrato"))
    if not cnpj or numero_contrato is None:
        return None

    return {
        "numero_do_contrato":                      numero_contrato,
        "cnpj":                                     cnpj,
        "cliente":                                  _txt(r.get("cliente")),
        "descricao_do_projeto":                    _txt(r.get("descricao_do_projeto")),
        "uf":                                        _txt(r.get("uf")),
        "municipio":                                 _txt(r.get("municipio")),
        "municipio_codigo":                         _int(r.get("municipio_codigo")),
        "data_da_contratacao":                      _parse_date(r.get("data_da_contratacao")),
        "valor_contratado_reais":                   _num(r.get("valor_contratado_reais")),
        "valor_desembolsado_reais":                 _num(r.get("valor_desembolsado_reais")),
        "fonte_de_recurso_desembolsos":             _txt(r.get("fonte_de_recurso_desembolsos")),
        "custo_financeiro":                         _txt(r.get("custo_financeiro")),
        "juros":                                     _num(r.get("juros")),
        "prazo_carencia_meses":                     _int(r.get("prazo_carencia_meses")),
        "prazo_amortizacao_meses":                  _int(r.get("prazo_amortizacao_meses")),
        "modalidade_de_apoio":                       _txt(r.get("modalidade_de_apoio")),
        "forma_de_apoio":                            _txt(r.get("forma_de_apoio")),
        "produto":                                   _txt(r.get("produto")),
        "instrumento_financeiro":                   _txt(r.get("instrumento_financeiro")),
        "inovacao":                                  _txt(r.get("inovacao")),
        "area_operacional":                          _txt(r.get("area_operacional")),
        "setor_cnae":                                _txt(r.get("setor_cnae")),
        "subsetor_cnae_agrupado":                   _txt(r.get("subsetor_cnae_agrupado")),
        "subsetor_cnae_codigo":                      _txt(r.get("subsetor_cnae_codigo")),
        "subsetor_cnae_nome":                        _txt(r.get("subsetor_cnae_nome")),
        "setor_bndes":                                _txt(r.get("setor_bndes")),
        "subsetor_bndes":                            _txt(r.get("subsetor_bndes")),
        "porte_do_cliente":                          _txt(r.get("porte_do_cliente")),
        "natureza_do_cliente":                       _txt(r.get("natureza_do_cliente")),
        "instituicao_financeira_credenciada":        _txt(r.get("instituicao_financeira_credenciada")),
        "cnpj_instituicao_financeira_credenciada":   _strip_cnpj(r.get("cnpj_da_instituicao_financeira_credenciada")),
        "tipo_de_garantia":                          _txt(r.get("tipo_de_garantia")),
        "tipo_de_excepcionalidade":                  _txt(r.get("tipo_de_excepcionalidade")),
        "situacao_do_contrato":                      _txt(r.get("situacao_do_contrato")),
    }


# ── persistência (full refresh: limpa e reinsere) ──────────────────────────

def _clear_table() -> None:
    url = f"{SUPABASE_URL}/rest/v1/{TABLE}?id=gt.0"
    r = requests.delete(url, headers=_headers_api(), timeout=60)
    if not r.ok:
        logger.error("limpeza da tabela falhou: %s %s", r.status_code, r.text[:300])
        r.raise_for_status()
    logger.info("tabela %s limpa para full refresh", TABLE)


def _insert(rows: list[dict]) -> None:
    if not rows:
        return
    url = f"{SUPABASE_URL}/rest/v1/{TABLE}"
    for attempt in range(4):
        r = requests.post(url, json=rows, headers=_headers_api(), timeout=90)
        if r.ok:
            return
        if r.status_code in (429, 503):
            time.sleep(2 ** attempt)
            continue
        logger.error("insert falhou: %s %s", r.status_code, r.text[:300])
        r.raise_for_status()


# ── entry point ───────────────────────────────────────────────────────────

def _build_session() -> requests.Session:
    s = requests.Session()
    s.headers["User-Agent"] = "BRInsider/1.0 (dados@thebrinsider.com)"
    return s


def run() -> None:
    if not SUPABASE_URL or not SUPABASE_KEY:
        raise SystemExit("SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY ausentes")

    session = _build_session()
    offset = 0
    total = None
    rows: list[dict] = []
    counters = {"lidos": 0, "validos": 0}

    logger.info("Iniciando fetch BNDES operações não automáticas (resource=%s)", RESOURCE_ID)

    # Busca tudo antes de mexer no banco — não deixa a tabela vazia se o
    # fetch falhar no meio (ver docstring: full refresh, sem chave natural).
    while total is None or offset < total:
        records, total = fetch_page(session, offset)
        if not records:
            break
        for raw in records:
            counters["lidos"] += 1
            row = parse_record(raw)
            if row is None:
                continue
            counters["validos"] += 1
            rows.append(row)

        offset += len(records)
        logger.info("  %d/%d linhas lidas", offset, total)
        time.sleep(PAGE_DELAY)

    logger.info(
        "Fetch concluído: %d linhas válidas de %d lidas — iniciando full refresh",
        counters["validos"], counters["lidos"],
    )

    _clear_table()
    for i in range(0, len(rows), BATCH_SIZE):
        _insert(rows[i:i + BATCH_SIZE])

    logger.info("BNDES operações concluído: %d linhas inseridas", len(rows))


if __name__ == "__main__":
    run()
