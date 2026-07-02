"""
SENAR (Serviço Nacional de Aprendizagem Rural) — Ingester via CSV
BR Insider

Fonte: app3.cna.org.br/transparencia — CSV público (sem autenticação)
Dados: nacionais (portal não segmenta por AR estadual)
Períodos: trimestrais, descobertos dinamicamente do HTML do portal
Datasets:
  contratos    — ?gestaoContratosCsv-SENAR-{periodo_id}
  licitações   — ?gestaoLicitacaoCsv-SENAR-{ano}
  transferências — ?gestaoTransferenciaRecursosCsv-SENAR-{periodo_id}-9

Estratégia em 2 fases:
  Fase 1: CSV download → JSONL local (/tmp/senar/*.jsonl)
  Fase 2: JSONL → Supabase via curl (evita bug SSL LibreSSL macOS)

Execução:
  python3 -m ingestao.senar_connector           # ambas as fases
  python3 -m ingestao.senar_connector extract   # só fase 1
  python3 -m ingestao.senar_connector load      # só fase 2
"""
from __future__ import annotations

import csv
import io
import json
import logging
import os
import re
import subprocess
import sys
import tempfile
import time
from pathlib import Path

logger = logging.getLogger("senar")

# ── Constantes ─────────────────────────────────────────────────────────────
TMP_DIR     = Path("/tmp/senar")
BATCH_SIZE  = 500
RETRY_LIMIT = 3
RETRY_SLEEP = 5
BASE_URL    = "http://app3.cna.org.br/transparencia/"

# Períodos trimestrais conhecidos (novos são descobertos dinamicamente do HTML)
PERIODOS_FALLBACK = [
    "2026-1573",
    "2025-1517", "2025-1489", "2025-1461", "2025-1405",
    "2024-1377",  "2024-1349", "2024-1321", "2024-1265",
]

CONFLICT_COLS = {
    "senar_contratos":       "periodo_id,numero_contrato",
    "senar_licitacoes":      "ano,numero_ano",
    "senar_transferencias":  "periodo_id,tipo,cnpj,data_firmamento,valor_pactuado",
}

BOM = "﻿"


# ── HTTP via curl (evita bug SSL LibreSSL macOS) ────────────────────────────
def _curl_get(url: str, timeout: int = 60) -> bytes | None:
    for attempt in range(1, RETRY_LIMIT + 1):
        try:
            r = subprocess.run(
                ["curl", "-s", "-L", "--max-time", str(timeout),
                 "-A", "BRInsider/1.0 (bot dados públicos; contato@thebrinsider.com)",
                 url],
                capture_output=True, timeout=timeout + 30,
            )
            if r.returncode != 0:
                raise RuntimeError(f"curl saiu com {r.returncode}: {r.stderr[:200]}")
            return r.stdout
        except Exception as e:
            logger.warning("Erro GET %s (tentativa %d/%d): %s", url, attempt, RETRY_LIMIT, e)
        if attempt < RETRY_LIMIT:
            time.sleep(RETRY_SLEEP)
    return None


def _parse_csv(raw_bytes: bytes) -> list[dict]:
    raw = raw_bytes.decode("utf-8", errors="replace")
    if not raw.strip() or raw.lstrip(BOM).strip().startswith("<"):
        return []
    raw = raw.lstrip(BOM)
    reader = csv.DictReader(io.StringIO(raw), delimiter=";")
    return [
        {k.strip().lstrip(BOM): v.strip().lstrip(BOM) if isinstance(v, str) else v
         for k, v in row.items()}
        for row in reader
    ]


# ── Descoberta de períodos ──────────────────────────────────────────────────
def _discover_periodos() -> list[str]:
    """Lê o HTML do portal e extrai os códigos de período do <select COD_PERIODO>."""
    raw = _curl_get(f"{BASE_URL}?dadosAbertos-SENAR=")
    if not raw:
        logger.warning("Não foi possível descobrir períodos — usando fallback")
        return PERIODOS_FALLBACK
    html = raw.decode("utf-8", errors="replace")
    # <option value="2025-1517">2025 :: QUARTO TRIMESTRE</option>
    # O select COD_PERIODO contém os period_ids completos no formato "{ano}-{cod}"
    periodos = re.findall(r'<option value="(\d{4}-\d+)"', html)
    if not periodos:
        logger.warning("Nenhum período encontrado no HTML — usando fallback")
        return PERIODOS_FALLBACK
    # deduplicar preservando ordem
    seen: set[str] = set()
    result = []
    for p in periodos:
        if p not in seen:
            seen.add(p)
            result.append(p)
    logger.info("Períodos descobertos: %s", result)
    return result


def _anos_licitacoes(periodos: list[str]) -> list[int]:
    anos = sorted({int(p.split("-")[0]) for p in periodos})
    return anos


# ── Normalização ────────────────────────────────────────────────────────────
def _norm_contrato(row: dict, periodo_id: str) -> dict | None:
    numero = (row.get("CONTRATO") or "").strip().lstrip(BOM)
    if not numero or numero in ("-", ""):
        return None
    return {
        "periodo_id":           periodo_id,
        "numero_contrato":      numero,
        "modalidade_licitacao": row.get("MODALIDADE DE LICITAÇÃO"),
        "natureza_objeto":      row.get("NATUREZA DO OBJETO"),
        "descricao_objeto":     row.get("DESCRIÇÃO DO OBJETO"),
        "categoria_objeto":     row.get("CATEGORIA DO OBJETO"),
        "criterio_julgamento":  row.get("CRITÉRIO DE JULGAMENTO"),
        "nome_contratada":      row.get("NOME DA CONTRATADA"),
        "cnpj":                 row.get("CNPJ"),
        "cpf":                  row.get("CPF"),
        "data_contrato":        row.get("DATA DE CONTRATO"),
        "valor_contrato":       row.get("VALOR DO CONTRATO (R$)"),
        "valor_pago":           row.get("VALOR PAGO (R$)"),
        "vigencia_meses":       row.get("VIGÊNCIA (MESES)"),
        "valor_aditivo_preco":  row.get("VALOR ADITIVO PREÇO (R$)"),
        "valor_aditivo_prazo":  row.get("VALOR ADITIVO PRAZO"),
        "obs":                  row.get("OBS"),
    }


def _norm_licitacao(row: dict, ano: int) -> dict | None:
    numero = (row.get("NÚMERO/ANO") or "").strip().lstrip(BOM)
    if not numero or numero in ("-", ""):
        return None
    return {
        "ano":                  ano,
        "modalidade":           row.get("MODALIDADE"),
        "numero_ano":           numero,
        "processo":             row.get("PROCESSO"),
        "descricao_objeto":     row.get("DESCRIÇÃO DO OBJETO"),
        "natureza_objeto":      row.get("NATUREZA DO OBJETO"),
        "data_abertura":        row.get("DATA DA ABERTURA DAS PROPOSTAS"),
        "criterio_julgamento":  row.get("CRITÉRIO DE JULGAMENTO"),
        "data_homologacao":     row.get("DATA DE HOMOLOGAÇÃO"),
        "resultado_certame":    row.get("RESULTADO DO CERTAME"),
        "licitantes_propostas": row.get("IDENTIFICAÇÃO DOS LICITANTES|VALORES DAS PROPOSTAS"),
        "situacao":             row.get("SITUAÇÃO DA LICITAÇÃO"),
    }


def _norm_transferencia(row: dict, periodo_id: str) -> dict | None:
    cnpj = (row.get("CNPJ") or "").strip().lstrip(BOM)
    data = (row.get("DATA DO FIRMAMENTO") or "").strip().lstrip(BOM)
    valor = (row.get("VALOR PACTUADO") or "").strip().lstrip(BOM)
    tipo = (row.get("TIPO") or "").strip().lstrip(BOM)
    if not (cnpj or data) or not valor or valor == "-":
        return None
    return {
        "periodo_id":           periodo_id,
        "tipo":                 tipo,
        "instrumento":          row.get("INSTRUMENTO"),
        "tipo_transferencia":   row.get("TIPO DE TRANSFERÊNCIA"),
        "nome_beneficiario":    row.get("NOME DO BENEFICIÁRIO"),
        "cnpj":                 cnpj,
        "descricao_objeto":     row.get("DESCRIÇÃO DO OBJETO"),
        "data_firmamento":      data,
        "qtde_parcelas_total":  row.get("QTDE DE PARCELAS TOTAL"),
        "qtde_parcelas_trans":  row.get("QTDE PARCELAS TRANSFERIDA"),
        "valor_pactuado":       valor,
        "valor_transferido":    row.get("VALOR TRANSFERIDO (R$)"),
        "prestacao_contas":     row.get("PRESTAÇÃO DE CONTAS"),
    }


# ── FASE 1: CSV → JSONL ─────────────────────────────────────────────────────
def phase_extract():
    TMP_DIR.mkdir(parents=True, exist_ok=True)

    periodos = _discover_periodos()
    anos = _anos_licitacoes(periodos)

    f_contratos      = open(TMP_DIR / "senar_contratos.jsonl",      "w", encoding="utf-8")
    f_licitacoes     = open(TMP_DIR / "senar_licitacoes.jsonl",     "w", encoding="utf-8")
    f_transferencias = open(TMP_DIR / "senar_transferencias.jsonl", "w", encoding="utf-8")
    totais = {"senar_contratos": 0, "senar_licitacoes": 0, "senar_transferencias": 0}

    try:
        # Contratos e Transferências — por período trimestral
        for periodo_id in periodos:
            # Contratos
            url_c = f"{BASE_URL}?gestaoContratosCsv-SENAR-{periodo_id}"
            raw = _curl_get(url_c)
            if raw is None:
                logger.warning("Falha ao baixar contratos %s", periodo_id)
            else:
                rows = _parse_csv(raw)
                for row in rows:
                    norm = _norm_contrato(row, periodo_id)
                    if norm:
                        f_contratos.write(json.dumps(norm, ensure_ascii=False) + "\n")
                        totais["senar_contratos"] += 1

            # Transferências (sufixo -9: união de federações + convênios)
            url_t = f"{BASE_URL}?gestaoTransferenciaRecursosCsv-SENAR-{periodo_id}-9"
            raw = _curl_get(url_t)
            if raw is None:
                logger.warning("Falha ao baixar transferências %s", periodo_id)
            else:
                rows = _parse_csv(raw)
                for row in rows:
                    norm = _norm_transferencia(row, periodo_id)
                    if norm:
                        f_transferencias.write(json.dumps(norm, ensure_ascii=False) + "\n")
                        totais["senar_transferencias"] += 1

            logger.info("Período %s: contratos=%d transferências=%d",
                        periodo_id, totais["senar_contratos"], totais["senar_transferencias"])

        # Licitações — por ano civil
        for ano in anos:
            url_l = f"{BASE_URL}?gestaoLicitacaoCsv-SENAR-{ano}"
            raw = _curl_get(url_l)
            if raw is None:
                logger.warning("Falha ao baixar licitações %d", ano)
                continue
            rows = _parse_csv(raw)
            for row in rows:
                norm = _norm_licitacao(row, ano)
                if norm:
                    f_licitacoes.write(json.dumps(norm, ensure_ascii=False) + "\n")
                    totais["senar_licitacoes"] += 1
            logger.info("Licitações %d: %d linhas", ano, totais["senar_licitacoes"])

    finally:
        f_contratos.close()
        f_licitacoes.close()
        f_transferencias.close()

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
    for tabela in ("senar_contratos", "senar_licitacoes", "senar_transferencias"):
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
