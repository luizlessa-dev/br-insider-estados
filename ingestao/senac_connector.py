"""
SENAC (Serviço Nacional de Aprendizagem Comercial) — Ingester via API JSON
BR Insider

Fonte: transparencia.senac.br — API JSON pública (sem autenticação)
Regionais: DN + 27 DRs estaduais (28 regionais)
Endpoints:
  contratos → GET /service/api/contratos-parcerias?regional={sigla}
              (inclui contratos, acordos, convênios, parcerias e patrocínios)
  licitações → GET /service/api/licitacoes/regional/{sigla}

Estratégia em 2 fases:
  Fase 1: API JSON download → JSONL local (/tmp/senac/*.jsonl)
  Fase 2: JSONL → Supabase via curl (evita bug SSL LibreSSL macOS)

Execução:
  python3 -m ingestao.senac_connector           # ambas as fases
  python3 -m ingestao.senac_connector extract   # só fase 1
  python3 -m ingestao.senac_connector load      # só fase 2
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

logger = logging.getLogger("senac")

# ── Constantes ─────────────────────────────────────────────────────────────
TMP_DIR     = Path("/tmp/senac")
BATCH_SIZE  = 500
RETRY_LIMIT = 3
RETRY_SLEEP = 5
API_BASE    = "https://transparencia.senac.br/service/api"

REGIONAIS = [
    "ac", "al", "am", "ap", "ba", "ce", "df", "dn",
    "es", "go", "ma", "mg", "ms", "mt", "pa", "pb",
    "pe", "pi", "pr", "rj", "rn", "ro", "rr", "rs",
    "sc", "se", "sp", "to",
]

CONFLICT_COLS = {
    "senac_contratos":  "regional,numero",
    "senac_licitacoes": "regional,licitacao_id",
}


# ── HTTP via curl ───────────────────────────────────────────────────────────
def _curl_get_json(url: str, timeout: int = 30) -> dict | list | None:
    for attempt in range(1, RETRY_LIMIT + 1):
        try:
            r = subprocess.run(
                ["curl", "-s", "-L", "--max-time", str(timeout),
                 "-H", "Accept: application/json",
                 "-A", "BRInsider/1.0 (bot dados públicos; contato@thebrinsider.com)",
                 url],
                capture_output=True, timeout=timeout + 30,
            )
            if r.returncode != 0:
                raise RuntimeError(f"curl saiu com {r.returncode}: {r.stderr[:200]}")
            return json.loads(r.stdout.decode("utf-8", errors="replace"))
        except Exception as e:
            logger.warning("Erro GET %s (tentativa %d/%d): %s", url, attempt, RETRY_LIMIT, e)
        if attempt < RETRY_LIMIT:
            time.sleep(RETRY_SLEEP)
    return None


# ── Normalização ────────────────────────────────────────────────────────────
def _parse_date(s: str | None) -> str | None:
    if not s:
        return None
    return s[:10] if len(s) >= 10 else s


def _norm_contrato(row: dict, regional: str) -> dict | None:
    numero = (row.get("numero") or "").strip()
    if not numero:
        return None
    return {
        "regional":            regional,
        "numero":              numero,
        "numero_origem":       row.get("numeroOrigem"),
        "tipo":                row.get("tipo"),
        "situacao":            row.get("situacao"),
        "objeto":              row.get("objeto"),
        "favorecido":          row.get("favorecido"),
        "cnpj_cpf":            row.get("cpfCnpj"),
        "tipo_pessoa":         row.get("tipoPessoa"),
        "elemento_despesa":    row.get("elementoDespesa"),
        "modalidade_origem":   str(row["modalidadeOrigem"]) if row.get("modalidadeOrigem") else None,
        "natureza":            row.get("natureza"),
        "valor_total":         row.get("valorTotal"),
        "valor_pago":          row.get("valorPago"),
        "data_contratacao":    _parse_date(row.get("dataContratacao")),
        "data_fim":            _parse_date(row.get("dataFim")),
        "ano_mes_referencia":  row.get("anoMesReferencia"),
        "data_ultima_carga":   row.get("dataUltimaCarga"),
    }


def _norm_licitacao(lic: dict, modalidade_id: str, modalidade: str,
                    regional: str, data_ultima_carga: str) -> dict | None:
    lid = (lic.get("id") or "").strip()
    if not lid:
        return None
    return {
        "regional":           regional,
        "modalidade_id":      modalidade_id,
        "modalidade":         modalidade,
        "licitacao_id":       lid,
        "situacao":           lic.get("situacao"),
        "numero_processo":    lic.get("numeroProcesso"),
        "objeto":             lic.get("objeto"),
        "data_abertura":      lic.get("dataAbertura"),
        "data_situacao":      lic.get("dataSituacao"),
        "data_ultima_carga":  data_ultima_carga,
    }


# ── FASE 1: API → JSONL ─────────────────────────────────────────────────────
def phase_extract():
    TMP_DIR.mkdir(parents=True, exist_ok=True)

    f_contratos  = open(TMP_DIR / "senac_contratos.jsonl",  "w", encoding="utf-8")
    f_licitacoes = open(TMP_DIR / "senac_licitacoes.jsonl", "w", encoding="utf-8")
    totais = {"senac_contratos": 0, "senac_licitacoes": 0}

    try:
        for regional in REGIONAIS:
            # Contratos / parcerias / convênios / acordos / patrocínios
            url_c = f"{API_BASE}/contratos-parcerias?regional={regional}"
            data_c = _curl_get_json(url_c)
            if data_c is None:
                logger.warning("Falha ao baixar contratos de %s", regional)
            elif isinstance(data_c, list):
                for row in data_c:
                    norm = _norm_contrato(row, regional)
                    if norm:
                        f_contratos.write(json.dumps(norm, ensure_ascii=False) + "\n")
                        totais["senac_contratos"] += 1

            # Licitações
            url_l = f"{API_BASE}/licitacoes/regional/{regional}"
            data_l = _curl_get_json(url_l)
            if data_l is None:
                logger.warning("Falha ao baixar licitações de %s", regional)
            else:
                licitacoes_list = data_l.get("data", []) if isinstance(data_l, dict) else []
                ultima_carga = data_l.get("dataUltimaCarga") if isinstance(data_l, dict) else None
                for modalidade_bloco in licitacoes_list:
                    mod_id  = modalidade_bloco.get("modalidadeId", "")
                    mod_nom = modalidade_bloco.get("modalidade", "")
                    uc      = modalidade_bloco.get("dataUltimaCarga") or ultima_carga
                    for lic in modalidade_bloco.get("dadosModalidadeLicitacao", []):
                        norm = _norm_licitacao(lic, mod_id, mod_nom, regional, uc)
                        if norm:
                            f_licitacoes.write(json.dumps(norm, ensure_ascii=False) + "\n")
                            totais["senac_licitacoes"] += 1

            logger.info("%s: contratos=%d licitações=%d",
                        regional, totais["senac_contratos"], totais["senac_licitacoes"])

    finally:
        f_contratos.close()
        f_licitacoes.close()

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
    for tabela in ("senac_contratos", "senac_licitacoes"):
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
        logger.info("=== FASE 1: API → JSONL ===")
        phase_extract()

    if mode in ("load", "all"):
        if not url or not key:
            raise SystemExit("SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY são obrigatórios para load")
        logger.info("=== FASE 2: JSONL → Supabase ===")
        phase_load(url, key)

    logger.info("Concluído.")


if __name__ == "__main__":
    main()
