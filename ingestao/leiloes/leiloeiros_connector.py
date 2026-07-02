"""
Leiloeiros Credenciados — Receita Federal (CNAE 8299-7/04)
BR Insider

Filtra os arquivos bulk da RFB para extrair todos os estabelecimentos
com CNAE principal 8299704 (leiloeiros independentes).
Enriquece com razão social do arquivo Empresas.

Fonte: dadosabertos.rfb.gov.br/CNPJ/
  Estabelecimentos{0..9}.zip — ~700 MB comprimido por partição
  Empresas{0..9}.zip         — ~200 MB comprimido por partição

Estratégia de memória: processa uma partição por vez via streaming CSV,
nunca materializa o arquivo inteiro em RAM.

Execução:
  python3 -m ingestao.leiloes.leiloeiros_connector           # ambas as fases
  python3 -m ingestao.leiloes.leiloeiros_connector extract   # só extração → JSONL
  python3 -m ingestao.leiloes.leiloeiros_connector load      # só carga → Supabase
"""
from __future__ import annotations

import csv
import io
import json
import logging
import os
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

import requests

# EMPRESA_COLS removido — razão social enriquecida via JOIN Supabase pós-carga

logger = logging.getLogger("leiloes.leiloeiros")

# ── Constantes ─────────────────────────────────────────────────────────────
RFB_BASE   = "https://dadosabertos.rfb.gov.br/CNPJ"
PARTICOES  = list(range(10))      # 0..9
CNAE_ALVO  = "8299704"            # CNAE 8299-7/04 — leiloeiros independentes
BATCH_SIZE = 500
TMP_DIR    = Path("/tmp/leiloes_leiloeiros")
TMP_ESTAB  = TMP_DIR / "estabelecimentos.jsonl"

# Colunas do arquivo Estabelecimentos (sem cabeçalho, sep=";", latin-1)
ESTAB_COLS = [
    "cnpj_basico", "cnpj_ordem", "cnpj_dv",
    "identificador_matriz_filial",
    "nome_fantasia", "situacao_cadastral", "data_situacao_cadastral",
    "motivo_situacao_cadastral", "nome_cidade_exterior", "pais",
    "data_inicio_atividade", "cnae_fiscal", "cnae_fiscal_secundaria",
    "tipo_logradouro", "logradouro", "numero", "complemento", "bairro",
    "cep", "uf", "municipio",
    "ddd1", "telefone1", "ddd2", "telefone2", "ddd_fax", "fax",
    "correio_eletronico", "situacao_especial", "data_situacao_especial",
]

# ── Helpers ─────────────────────────────────────────────────────────────────
def _date(raw: str) -> str | None:
    raw = (raw or "").strip()
    if len(raw) == 8 and raw.isdigit():
        return f"{raw[:4]}-{raw[4:6]}-{raw[6:]}"
    return None or raw or None


def _session() -> requests.Session:
    s = requests.Session()
    s.headers["User-Agent"] = "BRInsider/1.0 (dados públicos; contato@thebrinsider.com)"
    return s


# ── Fase 1a: Estabelecimentos → JSONL ───────────────────────────────────────
def _extract_estab_particao(session: requests.Session, particao: int, out_file) -> int:
    url = f"{RFB_BASE}/Estabelecimentos{particao}.zip"
    logger.info("  Baixando Estabelecimentos%d ...", particao)
    try:
        r = session.get(url, timeout=600, stream=True)
        r.raise_for_status()
    except Exception as e:
        logger.error("  Estabelecimentos%d falhou: %s", particao, e)
        return 0

    written = 0
    with tempfile.NamedTemporaryFile(suffix=".zip", delete=False) as tmp:
        tmp_path = tmp.name
        for chunk in r.iter_content(chunk_size=8 * 1024 * 1024):
            tmp.write(chunk)

    try:
        with zipfile.ZipFile(tmp_path) as zf:
            for name in zf.namelist():
                with zf.open(name) as raw_f:
                    reader = csv.reader(
                        io.TextIOWrapper(raw_f, encoding="latin-1", errors="replace"),
                        delimiter=";",
                    )
                    for row in reader:
                        if len(row) < len(ESTAB_COLS):
                            continue
                        rec = dict(zip(ESTAB_COLS, row))
                        cnae = (rec.get("cnae_fiscal") or "").strip().lstrip("0")
                        if cnae != CNAE_ALVO.lstrip("0"):
                            continue
                        out = {
                            "cnpj_basico":               (rec["cnpj_basico"] or "").strip(),
                            "cnpj_ordem":                (rec["cnpj_ordem"] or "").strip(),
                            "cnpj_dv":                   (rec["cnpj_dv"] or "").strip(),
                            "identificador_matriz_filial": _int(rec.get("identificador_matriz_filial")),
                            "nome_fantasia":              (rec.get("nome_fantasia") or "").strip() or None,
                            "situacao_cadastral":         _int(rec.get("situacao_cadastral")),
                            "data_situacao_cadastral":    _date(rec.get("data_situacao_cadastral")),
                            "data_inicio_atividade":      _date(rec.get("data_inicio_atividade")),
                            "cnae_fiscal":                cnae,
                            "tipo_logradouro":            (rec.get("tipo_logradouro") or "").strip() or None,
                            "logradouro":                 (rec.get("logradouro") or "").strip() or None,
                            "numero":                     (rec.get("numero") or "").strip() or None,
                            "complemento":                (rec.get("complemento") or "").strip() or None,
                            "bairro":                     (rec.get("bairro") or "").strip() or None,
                            "cep":                        (rec.get("cep") or "").strip() or None,
                            "uf":                         (rec.get("uf") or "").strip() or None,
                            "municipio_codigo":           _int(rec.get("municipio")),
                            "ddd1":                       (rec.get("ddd1") or "").strip() or None,
                            "telefone1":                  (rec.get("telefone1") or "").strip() or None,
                            "correio_eletronico":         (rec.get("correio_eletronico") or "").strip() or None,
                        }
                        out_file.write(json.dumps(out, ensure_ascii=False) + "\n")
                        written += 1
    finally:
        os.unlink(tmp_path)

    logger.info("  Estabelecimentos%d: %d leiloeiros encontrados", particao, written)
    return written


def _int(v) -> int | None:
    try:
        return int(str(v).strip())
    except (TypeError, ValueError):
        return None



def phase_extract() -> int:
    TMP_DIR.mkdir(exist_ok=True)
    session = _session()
    total = 0

    # Passo 1: varrer Estabelecimentos em busca de CNAE 8299704
    with open(TMP_ESTAB, "w", encoding="utf-8") as f:
        for p in PARTICOES:
            total += _extract_estab_particao(session, p, f)

    logger.info("Total leiloeiros extraídos: %d", total)
    # razao_social é enriquecida via JOIN com cnpj_empresas no Supabase (pós-carga)
    # evita baixar ~2 GB de partições Empresas para ~3k registros
    return total


# ── Fase 2: JSONL → Supabase ─────────────────────────────────────────────────
def _upsert_batch(rows: list[dict], url: str, key: str) -> None:
    endpoint = (
        f"{url}/rest/v1/leiloes_leiloeiros"
        "?on_conflict=cnpj_basico,cnpj_ordem,cnpj_dv"
    )
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
            logger.warning("upsert leiloes_leiloeiros: HTTP %s", status)
    finally:
        os.unlink(tmp)


def phase_load(url: str, key: str) -> int:
    if not TMP_ESTAB.exists():
        raise FileNotFoundError(f"{TMP_ESTAB} não encontrado — rode extract primeiro")

    buf: list[dict] = []
    total = 0
    with open(TMP_ESTAB, encoding="utf-8") as f:
        for line in f:
            row = json.loads(line)
            if not row.get("cnpj_basico"):
                continue
            buf.append(row)
            if len(buf) >= BATCH_SIZE:
                _upsert_batch(buf, url, key)
                total += len(buf)
                buf.clear()
    if buf:
        _upsert_batch(buf, url, key)
        total += len(buf)

    logger.info("leiloes_leiloeiros: %d linhas carregadas", total)

    # Enriquecer razao_social via JOIN com cnpj_empresas (já populada no Supabase)
    _enrich_razao_social(url, key)
    return total


def _enrich_razao_social(url: str, key: str) -> None:
    """UPDATE leiloes_leiloeiros.razao_social via JOIN com cnpj_empresas existente."""
    sql = (
        "UPDATE public.leiloes_leiloeiros ll "
        "SET razao_social = ce.razao_social "
        "FROM public.cnpj_empresas ce "
        "WHERE ce.cnpj_basico = ll.cnpj_basico "
        "AND ll.razao_social IS NULL"
    )
    endpoint = f"{url}/rest/v1/rpc/exec_sql"
    body = json.dumps({"query": sql})

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
             "--data-binary", f"@{tmp}"],
            capture_output=True, text=True, timeout=30,
        )
        status = r.stdout.strip()
        if status not in ("200", "204"):
            # exec_sql pode não existir — logar e seguir
            logger.warning(
                "enrich razao_social via RPC falhou (HTTP %s) — "
                "execute manualmente: UPDATE leiloes_leiloeiros ll "
                "SET razao_social = ce.razao_social "
                "FROM cnpj_empresas ce WHERE ce.cnpj_basico = ll.cnpj_basico",
                status,
            )
        else:
            logger.info("razao_social enriquecida via cnpj_empresas")
    finally:
        os.unlink(tmp)


# ── Main ────────────────────────────────────────────────────────────────────
def main() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
        datefmt="%H:%M:%S",
    )

    url = os.environ.get("SUPABASE_URL", "")
    sb_key = (
        os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
        or os.environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY", "")
    )

    mode = sys.argv[1] if len(sys.argv) > 1 else "all"

    if mode in ("extract", "all"):
        logger.info("=== FASE 1: RFB Estabelecimentos → JSONL ===")
        phase_extract()

    if mode in ("load", "all"):
        if not url or not sb_key:
            raise SystemExit("SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY são obrigatórios para load")
        logger.info("=== FASE 2: JSONL → Supabase ===")
        phase_load(url, sb_key)

    logger.info("Concluído.")


if __name__ == "__main__":
    main()
