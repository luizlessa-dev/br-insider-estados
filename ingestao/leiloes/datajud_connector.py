"""
DataJud — Processos de Execução para Leilões Judiciais
BR Insider

Coleta processos das classes de execução em todos os tribunais estaduais e federais.
A API pública DataJud NÃO expõe o campo `partes` (CPF/CNPJ) — limitação documentada.
Os movimentos são gravados como JSONB para análise futura dos códigos TPU de hasta pública.

Execução:
  python3 -m ingestao.leiloes.datajud_connector           # todas as fases
  python3 -m ingestao.leiloes.datajud_connector extract   # só extração → JSONL
  python3 -m ingestao.leiloes.datajud_connector load      # só carga → Supabase

Variáveis de ambiente:
  DATAJUD_API_KEY            — chave pública CNJ (padrão: chave pública atual)
  SUPABASE_URL
  SUPABASE_SERVICE_ROLE_KEY  ou INTERNAL_SUPABASE_SERVICE_ROLE_KEY
"""
from __future__ import annotations

import json
import logging
import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path

import requests

logger = logging.getLogger("leiloes.datajud")

# ── Constantes ─────────────────────────────────────────────────────────────
DATAJUD_BASE = "https://api-publica.datajud.cnj.jus.br"
# Chave pública CNJ — cadastrada em datajud-wiki.cnj.jus.br/api-publica/acesso
DATAJUD_KEY_DEFAULT = "cDZHYzlZa0JadVREZDJCendQbXY6SkJlTzNjLV9TRENyQk1RdnFKZGRQdw=="

PAGE_SIZE  = 1000   # máximo permitido pela API
BATCH_SIZE = 500    # linhas por upsert no Supabase
SLEEP_OK   = 2.0   # segundos entre páginas (API sobrecarregada em horário comercial)
SLEEP_429  = 30.0  # backoff em rate-limit
MAX_RETRIES = 5

TMP_DIR = Path("/tmp/leiloes_datajud")
TMP_FILE = TMP_DIR / "processos.jsonl"

# Classes processuais de execução (CNJ TPU)
CLASSES = {
    159:  "Execução de Título Extrajudicial",
    1116: "Execução Fiscal",
    1028: "Execução Cível",
    154:  "Cumprimento de Sentença",
    1199: "Alienação Judicial",
}

# Índices por tribunal — estaduais com maior volume + todos TRFs
TRIBUNAIS = [
    ("api_publica_tjsp", "TJSP"),
    ("api_publica_tjrj", "TJRJ"),
    ("api_publica_tjmg", "TJMG"),
    ("api_publica_tjrs", "TJRS"),
    ("api_publica_tjpr", "TJPR"),
    ("api_publica_tjba", "TJBA"),
    ("api_publica_tjsc", "TJSC"),
    ("api_publica_tjgo", "TJGO"),
    ("api_publica_tjpe", "TJPE"),
    ("api_publica_tjce", "TJCE"),
    ("api_publica_tjdf", "TJDF"),
    ("api_publica_tjmt", "TJMT"),
    ("api_publica_tjms", "TJMS"),
    ("api_publica_tjma", "TJMA"),
    ("api_publica_tjpa", "TJPA"),
    ("api_publica_trf1", "TRF1"),
    ("api_publica_trf2", "TRF2"),
    ("api_publica_trf3", "TRF3"),
    ("api_publica_trf4", "TRF4"),
    ("api_publica_trf5", "TRF5"),
    ("api_publica_trf6", "TRF6"),
]

SOURCE_FIELDS = [
    "numeroProcesso", "tribunal", "grau",
    "classe", "assuntos", "orgaoJulgador",
    "movimentos", "dataAjuizamento", "dataHoraUltimaAtualizacao",
]


# ── HTTP helpers ────────────────────────────────────────────────────────────
def _headers(key: str) -> dict:
    return {
        "Authorization": f"APIKey {key}",
        "Content-Type": "application/json",
        "User-Agent": "BRInsider/1.0 (dados públicos; contato@thebrinsider.com)",
    }


def _search_page(session: requests.Session, indice: str, key: str,
                 search_after: list | None) -> dict | None:
    body: dict = {
        "size": PAGE_SIZE,
        "query": {
            "bool": {
                "filter": [
                    {"terms": {"classe.codigo": list(CLASSES.keys())}}
                ]
            }
        },
        "_source": SOURCE_FIELDS,
        "sort": [
            {"dataHoraUltimaAtualizacao": "asc"},
            {"_id": "asc"},
        ],
    }
    if search_after:
        body["search_after"] = search_after

    url = f"{DATAJUD_BASE}/{indice}/_search"
    for attempt in range(MAX_RETRIES):
        try:
            r = session.post(url, json=body, headers=_headers(key), timeout=60)
        except requests.RequestException as e:
            logger.warning("  %s tentativa %d erro: %s", indice, attempt + 1, e)
            time.sleep(SLEEP_429)
            continue

        if r.status_code == 429:
            logger.warning("  %s rate-limit — aguardando %.0fs", indice, SLEEP_429)
            time.sleep(SLEEP_429)
            continue
        if r.status_code in (400, 404):
            logger.debug("  %s HTTP %d — ignorando", indice, r.status_code)
            return None
        if r.status_code != 200:
            logger.warning("  %s HTTP %d", indice, r.status_code)
            time.sleep(SLEEP_OK)
            continue

        return r.json()

    logger.error("  %s esgotou %d tentativas", indice, MAX_RETRIES)
    return None


# ── Fase 1: Extração DataJud → JSONL ───────────────────────────────────────
def _parse_ts(raw: str | None) -> str | None:
    if not raw:
        return None
    # formatos: "20260122130953" ou "2026-01-22T13:09:53.000Z"
    raw = raw.strip()
    if len(raw) == 14 and raw.isdigit():
        return f"{raw[:4]}-{raw[4:6]}-{raw[6:8]}T{raw[8:10]}:{raw[10:12]}:{raw[12:14]}Z"
    return raw


def _flatten(src: dict) -> dict:
    classe = src.get("classe") or {}
    orgao  = src.get("orgaoJulgador") or {}
    return {
        "numero_processo":         src.get("numeroProcesso"),
        "tribunal":                src.get("tribunal"),
        "grau":                    src.get("grau"),
        "classe_codigo":           classe.get("codigo"),
        "classe_nome":             classe.get("nome") or CLASSES.get(classe.get("codigo")),
        "assuntos":                json.dumps(src.get("assuntos") or [], ensure_ascii=False),
        "orgao_julgador_codigo":   orgao.get("codigo"),
        "orgao_julgador_nome":     orgao.get("nome"),
        "municipio_ibge":          orgao.get("codigoMunicipioIBGE"),
        "movimentos":              json.dumps(src.get("movimentos") or [], ensure_ascii=False),
        "data_ajuizamento":        _parse_ts(src.get("dataAjuizamento")),
        "data_ultima_atualizacao": _parse_ts(src.get("dataHoraUltimaAtualizacao")),
    }


def phase_extract(key: str) -> int:
    TMP_DIR.mkdir(exist_ok=True)
    session = requests.Session()
    total_written = 0

    with open(TMP_FILE, "w", encoding="utf-8") as out:
        for indice, sigla in TRIBUNAIS:
            logger.info("Extraindo %s ...", sigla)
            search_after = None
            pagina = 0
            trib_total = 0

            while True:
                data = _search_page(session, indice, key, search_after)
                if data is None:
                    break

                hits = data.get("hits", {}).get("hits", [])
                if not hits:
                    break

                for h in hits:
                    row = _flatten(h["_source"])
                    out.write(json.dumps(row, ensure_ascii=False) + "\n")

                trib_total += len(hits)
                pagina += 1

                # search_after usa os valores de sort do último hit
                last_sort = hits[-1].get("sort")
                if not last_sort or len(hits) < PAGE_SIZE:
                    break
                search_after = last_sort

                if pagina % 5 == 0:
                    logger.info("  %s: %d processos (pág %d)", sigla, trib_total, pagina)
                time.sleep(SLEEP_OK)

            logger.info("  %s: %d processos extraídos", sigla, trib_total)
            total_written += trib_total

    logger.info("Total extraído: %d processos → %s", total_written, TMP_FILE)
    return total_written


# ── Fase 2: JSONL → Supabase ────────────────────────────────────────────────
def _upsert_batch(rows: list[dict], url: str, key: str) -> None:
    endpoint = f"{url}/rest/v1/leiloes_processos?on_conflict=numero_processo,tribunal"
    body = json.dumps(rows, ensure_ascii=False)

    with tempfile.NamedTemporaryFile(mode="w", suffix=".json", encoding="utf-8", delete=False) as f:
        f.write(body)
        tmp = f.name

    try:
        r = subprocess.run(
            ["curl", "-s", "-o", "/dev/null", "-w", "%{http_code}",
             "-X", "POST", endpoint,
             "-H", f"apikey: {key}",
             "-H", f"Authorization: Bearer {key}",
             "-H", "Content-Type: application/json",
             "-H", "Prefer: resolution=ignore-duplicates",
             "--data-binary", f"@{tmp}"],
            capture_output=True, text=True, timeout=120,
        )
        status = r.stdout.strip()
        if status not in ("200", "201", "204"):
            logger.warning("upsert leiloes_processos: HTTP %s", status)
    finally:
        os.unlink(tmp)


def phase_load(url: str, key: str) -> int:
    if not TMP_FILE.exists():
        raise FileNotFoundError(f"{TMP_FILE} não encontrado — rode extract primeiro")

    buf: list[dict] = []
    total = 0

    with open(TMP_FILE, encoding="utf-8") as f:
        for line in f:
            row = json.loads(line)
            if not row.get("numero_processo"):
                continue
            buf.append(row)
            if len(buf) >= BATCH_SIZE:
                _upsert_batch(buf, url, key)
                total += len(buf)
                buf.clear()
                if total % 5000 == 0:
                    logger.info("  %d inseridos", total)

    if buf:
        _upsert_batch(buf, url, key)
        total += len(buf)

    logger.info("leiloes_processos: %d linhas carregadas", total)
    return total


# ── Main ────────────────────────────────────────────────────────────────────
def main() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
        datefmt="%H:%M:%S",
    )

    key = os.environ.get("DATAJUD_API_KEY") or DATAJUD_KEY_DEFAULT
    url = os.environ.get("SUPABASE_URL", "")
    sb_key = (
        os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
        or os.environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY", "")
    )

    mode = sys.argv[1] if len(sys.argv) > 1 else "all"

    if mode in ("extract", "all"):
        logger.info("=== FASE 1: DataJud → JSONL ===")
        phase_extract(key)

    if mode in ("load", "all"):
        if not url or not sb_key:
            raise SystemExit("SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY são obrigatórios para load")
        logger.info("=== FASE 2: JSONL → Supabase ===")
        phase_load(url, sb_key)

    logger.info("Concluído.")


if __name__ == "__main__":
    main()
