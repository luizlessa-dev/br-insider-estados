"""
SESC (Serviço Social do Comércio) — Ingester via CSV
BR Insider

Fonte: transparencia-[uf].sesc.com.br — CSV público, sem autenticação
Portais: DN + 27 DRs estaduais (28 portais)
Datasets:
  178 — Principais Contratos Firmados por Exercício
  179 — Principais Contratos com pagamentos por Exercício
  180 — Principais Convênios Firmados por Exercício
  183 — Todos os Convênios com pagamentos por Exercício

Estratégia em 2 fases:
  Fase 1: CSV download → JSONL local (/tmp/sesc/*.jsonl)
  Fase 2: JSONL → Supabase via curl (evita bug latin-1 Python 3.14)

Execução:
  python3 -m ingestao.sesc_connector           # ambas as fases
  python3 -m ingestao.sesc_connector extract   # só fase 1
  python3 -m ingestao.sesc_connector load      # só fase 2
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
import time
from pathlib import Path

logger = logging.getLogger("sesc")

# ── Constantes ─────────────────────────────────────────────────────────────
TMP_DIR     = Path("/tmp/sesc")
BATCH_SIZE  = 500
RETRY_LIMIT = 3
RETRY_SLEEP = 5

# Portal DN + 27 UFs
PORTAIS: list[dict] = [{"codigo": "DN", "host": "transparencia-dn.sesc.com.br"}] + [
    {"codigo": uf, "host": f"transparencia-{uf.lower()}.sesc.com.br"}
    for uf in [
        "AC","AL","AM","AP","BA","CE","DF","ES","GO",
        "MA","MG","MS","MT","PA","PB","PE","PI","PR",
        "RJ","RN","RO","RR","RS","SC","SE","SP","TO",
    ]
]

# Datasets a ingerir: (id, tabela_destino)
DATASETS_CONTRATOS = [178, 179]
DATASETS_CONVENIOS = [180, 183]

CONFLICT_COLS = {
    "sesc_contratos": "portal,exercicio,numero_contrato",
    "sesc_convenios": "portal,exercicio,numero_convenio",
}


# ── HTTP + CSV via curl (evita bug SSL LibreSSL macOS) ──────────────────────
def _download_csv(host: str, dataset_id: int) -> list[dict] | None:
    url = f"https://{host}/transparencia/dados/download/{dataset_id}/csv"
    for attempt in range(1, RETRY_LIMIT + 1):
        try:
            r = subprocess.run(
                ["curl", "-s", "-L", "--max-time", "60",
                 "-A", "BRInsider/1.0 (bot dados públicos; contato@thebrinsider.com)",
                 url],
                capture_output=True, timeout=90,
            )
            if r.returncode != 0:
                raise RuntimeError(f"curl saiu com {r.returncode}: {r.stderr[:200]}")
            raw = r.stdout.decode("utf-8", errors="replace")
            if not raw.strip() or raw.lstrip("﻿").strip().startswith("<"):
                # portal retornou HTML (redirect/erro) — sem dados
                return []
            # strip BOM do início do arquivo e normalizar encoding
            raw = raw.lstrip("﻿")
            reader = csv.DictReader(io.StringIO(raw), delimiter=";")
            # limpar BOM/zero-width chars de cada campo (portal emite ﻿ em cada valor)
            BOM = "﻿"
            return [
                {k.strip().lstrip(BOM): v.strip().lstrip(BOM) if isinstance(v, str) else v
                 for k, v in row.items()}
                for row in reader
            ]
        except Exception as e:
            logger.warning("Erro %s dataset %d (tentativa %d/%d): %s",
                           host, dataset_id, attempt, RETRY_LIMIT, e)
        if attempt < RETRY_LIMIT:
            time.sleep(RETRY_SLEEP)
    return None


# ── Normalização ────────────────────────────────────────────────────────────
def _norm_contrato(row: dict, portal: str, dataset_id: int) -> dict | None:
    numero = (row.get("Numero_do_Contrato") or "").strip()
    if not numero or numero == "-":
        return None
    exercicio_raw = (row.get("Exercicio") or "").strip()
    try:
        exercicio = int(exercicio_raw)
    except (ValueError, TypeError):
        exercicio = None

    # dataset 179 usa valor_pago; dataset 178 usa valor_contrato
    valor_pago = (
        row.get("Valor_do_Pagamento_no_exercicio")
        or row.get("Valor_do_pagamento_no_exercicio")
        or None
    )

    return {
        "portal":               portal,
        "dataset_id":           dataset_id,
        "unidade":              row.get("Unidade_id"),
        "exercicio":            exercicio,
        "numero_contrato":      numero,
        "objeto":               row.get("Objeto"),
        "favorecido":           row.get("Favorecido"),
        "cnpj_cpf":             row.get("CNPJ_CPF"),
        "modalidade_licitacao": row.get("Modalidade_Licitacao") or row.get("Modadelidade_da_licitacao"),
        "data_contratacao":     row.get("Data_da_Contratacao"),
        "elemento_despesa":     row.get("Elemento_da_despesa") or row.get("Elemento_da_Despesa"),
        "valor_contrato":       row.get("Valor_do_contrato") or row.get("Valor_do_Contrato"),
        "valor_pago":           valor_pago,
    }


def _norm_convenio(row: dict, portal: str, dataset_id: int) -> dict | None:
    numero = (row.get("Numero_Convenio") or "").strip()
    if not numero or numero == "-":
        return None

    return {
        "portal":                portal,
        "dataset_id":            dataset_id,
        "unidade":               row.get("Unidade_id"),
        "exercicio":             (row.get("Exercicio") or "").strip() or None,
        "numero_convenio":       numero,
        "objeto":                row.get("Objeto"),
        "favorecido":            row.get("Favorecido"),
        "cnpj_cpf":              row.get("CNPJ_CPF"),
        "valor_contrapartida":   row.get("Valor_da_Contrapartida"),
        "data_firmatura":        row.get("Data_da_Firmatura"),
        "valor_total":           row.get("Valor_Total"),
        "valor_pago_exercicio":  row.get("Valor_do_Pagamento_no_exercicio"),
    }


# ── FASE 1: CSV → JSONL ─────────────────────────────────────────────────────
def phase_extract():
    TMP_DIR.mkdir(parents=True, exist_ok=True)

    f_contratos = open(TMP_DIR / "sesc_contratos.jsonl", "w", encoding="utf-8")
    f_convenios = open(TMP_DIR / "sesc_convenios.jsonl", "w", encoding="utf-8")
    totais = {"sesc_contratos": 0, "sesc_convenios": 0}

    try:
        for portal in PORTAIS:
            codigo = portal["codigo"]
            host   = portal["host"]

            # Contratos
            for ds_id in DATASETS_CONTRATOS:
                rows = _download_csv(host, ds_id)
                if rows is None:
                    logger.warning("Falha ao baixar %s dataset %d", codigo, ds_id)
                    continue
                for row in rows:
                    norm = _norm_contrato(row, codigo, ds_id)
                    if norm:
                        f_contratos.write(json.dumps(norm, ensure_ascii=False) + "\n")
                        totais["sesc_contratos"] += 1

            # Convênios
            for ds_id in DATASETS_CONVENIOS:
                rows = _download_csv(host, ds_id)
                if rows is None:
                    logger.warning("Falha ao baixar %s dataset %d", codigo, ds_id)
                    continue
                for row in rows:
                    norm = _norm_convenio(row, codigo, ds_id)
                    if norm:
                        f_convenios.write(json.dumps(norm, ensure_ascii=False) + "\n")
                        totais["sesc_convenios"] += 1

            logger.info("%s: contratos=%d convênios=%d",
                        codigo, totais["sesc_contratos"], totais["sesc_convenios"])
    finally:
        f_contratos.close()
        f_convenios.close()

    for tabela, n in totais.items():
        logger.info("  %s: %d linhas extraídas", tabela, n)


# ── FASE 2: JSONL → Supabase ────────────────────────────────────────────────
def _upsert_batch(tabela: str, rows: list, url: str, key: str):
    on_conflict = CONFLICT_COLS[tabela]
    endpoint = f"{url}/rest/v1/{tabela}?on_conflict={on_conflict}"
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
            logger.warning("upsert %s: HTTP %s", tabela, status)
    finally:
        os.unlink(tmp)


def phase_load(url: str, key: str):
    for tabela in ("sesc_contratos", "sesc_convenios"):
        path = TMP_DIR / f"{tabela}.jsonl"
        if not path.exists():
            logger.warning("Arquivo não encontrado: %s — rode extract primeiro", path)
            continue

        logger.info("Carregando %s ...", tabela)
        buf: list = []
        total = 0

        with open(path, encoding="utf-8") as f:
            for line in f:
                buf.append(json.loads(line))
                if len(buf) >= BATCH_SIZE:
                    _upsert_batch(tabela, buf, url, key)
                    total += len(buf)
                    buf.clear()
                    if total % 5000 == 0:
                        logger.info("  %d inseridos", total)

        if buf:
            _upsert_batch(tabela, buf, url, key)
            total += len(buf)

        logger.info("  %s: %d linhas carregadas", tabela, total)


# ── Main ────────────────────────────────────────────────────────────────────
def main():
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

    url = os.environ.get("SUPABASE_URL", "")
    key = (
        os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
        or os.environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY", "")
    )

    mode = sys.argv[1] if len(sys.argv) > 1 else "all"

    if mode in ("extract", "all"):
        logger.info("=== FASE 1: CSV → JSONL ===")
        phase_extract()

    if mode in ("load", "all"):
        if not url or not key:
            raise SystemExit("SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY são obrigatórios para load")
        logger.info("=== FASE 2: JSONL → Supabase ===")
        phase_load(url, key)

    logger.info("Concluído.")


if __name__ == "__main__":
    main()
