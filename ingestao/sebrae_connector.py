"""
SEBRAE — Ingester via Qlik Engine API (WebSocket)
BR Insider

Estratégia em 2 fases para evitar conflito WebSocket × HTTP:
  Fase 1: extrai dados do Qlik para arquivos JSONL locais (/tmp/sebrae_*.jsonl)
  Fase 2: lê os arquivos e insere no Supabase via curl

Execução:
  python3 -m ingestao.sebrae_connector           # ambas as fases
  python3 -m ingestao.sebrae_connector extract   # só fase 1
  python3 -m ingestao.sebrae_connector load      # só fase 2
"""
from __future__ import annotations

import asyncio
import json
import logging
import os
import subprocess
import sys
import tempfile
from pathlib import Path

import websockets

logger = logging.getLogger("sebrae")

# ── Constantes ─────────────────────────────────────────────────────────────
APP_ID  = "e2407c39-2fb9-4637-bf20-7eb974711cea"
WS_URL  = f"wss://paineis-lai.sebrae.com.br/app/{APP_ID}"
WS_HEADERS = {
    "User-Agent": "BRInsider/1.0 (bot dados públicos; contato@thebrinsider.com)",
    "Origin": "https://paineis-lai.sebrae.com.br",
}

PAGE_SIZE  = 50    # linhas por requisição Qlik
BATCH_SIZE = 500   # linhas por upsert no Supabase
TMP_DIR    = Path("/tmp/sebrae")

TABLES: list[tuple[str, int, str, list[str]]] = [
    (
        "wzSfv", 12, "sebrae_contratos",
        ["uf","ano","numero_contrato","data_contrato","modalidade",
         "cnpj_cpf","razao_social","vigencia","objeto","aditivo",
         "valor_contrato","valor_pago"],
    ),
    (
        "f7a53fdc-c669-4914-b7a7-bf11a9eea914", 13, "sebrae_licitacoes",
        ["uf","numero_licitacao","tipo_julgamento","menor_preco",
         "situacao","modalidade","julgamento","objeto",
         "data_abertura","data_homologacao","resultado",
         "cnpj_fornecedor","nome_fornecedor"],
    ),
    (
        "BQUYPp", 12, "sebrae_convenios",
        ["uf","ano","numero_convenio","data_convenio","cnpj_cpf",
         "razao_social","vigencia","objeto","aditivo",
         "participacao_sebrae","valor_repasse","valor_contrapartida"],
    ),
    (
        "cvyJb", 11, "sebrae_patrocinios",
        ["uf","ano","numero_contrato","data_contrato","cnpj_cpf",
         "razao_social","vigencia","objeto","aditivo",
         "valor_contrato","valor_pago"],
    ),
    (
        "AHSdRn", 12, "sebrae_emendas_contratos",
        ["uf","ano","numero_contrato","data_contrato","modalidade",
         "cnpj_cpf","razao_social","vigencia","objeto","aditivo",
         "observacao","valor_contrato"],
    ),
    (
        "DumJhJv", 11, "sebrae_emendas_convenios",
        ["uf","ano","numero_convenio","data_convenio","cnpj_cpf",
         "razao_social","vigencia","objeto","aditivo",
         "observacao","valor_emenda"],
    ),
]

CONFLICT_COLS = {
    "sebrae_contratos":         "uf,numero_contrato",
    "sebrae_licitacoes":        "uf,numero_licitacao",
    "sebrae_convenios":         "uf,numero_convenio",
    "sebrae_patrocinios":       "uf,numero_contrato",
    "sebrae_emendas_contratos": "uf,numero_contrato",
    "sebrae_emendas_convenios": "uf,numero_convenio",
}


# ── Qlik RPC ────────────────────────────────────────────────────────────────
async def _rpc(ws, method, params=None, handle=-1, msg_id=1):
    req = {"jsonrpc":"2.0","id":msg_id,"method":method,"handle":handle,"params":params or []}
    await ws.send(json.dumps(req))
    while True:
        raw = await asyncio.wait_for(ws.recv(), timeout=30)
        msg = json.loads(raw)
        if msg.get("id") == msg_id:
            if "error" in msg:
                raise RuntimeError(f"Qlik error: {msg['error']}")
            return msg


# ── FASE 1: Extração Qlik → JSONL ──────────────────────────────────────────
async def extract_table(ws, app_handle, obj_id, n_cols, columns, msg_base, out_path):
    r = await _rpc(ws, "GetObject", [obj_id], handle=app_handle, msg_id=msg_base)
    tbl = r["result"]["qReturn"]["qHandle"]

    r2 = await _rpc(ws, "GetLayout", [], handle=tbl, msg_id=msg_base+1)
    total = r2["result"]["qLayout"]["qHyperCube"]["qSize"].get("qcy", 0)
    logger.info("  total=%d linhas", total)

    written = 0
    with open(out_path, "w", encoding="utf-8") as f:
        offset = 0
        fetch_id = msg_base + 10
        while offset < total:
            page = [{"qTop": offset, "qLeft": 0, "qWidth": n_cols, "qHeight": PAGE_SIZE}]
            r3 = await _rpc(ws, "GetHyperCubeData", ["/qHyperCubeDef", page], handle=tbl, msg_id=fetch_id)
            fetch_id += 1
            matrix = r3["result"]["qDataPages"][0]["qMatrix"]
            for row in matrix:
                vals = [cell.get("qText", "") for cell in row]
                f.write(json.dumps(dict(zip(columns, vals)), ensure_ascii=False) + "\n")
                written += 1
            offset += len(matrix)
            if offset % 1000 == 0:
                logger.info("    %d/%d", offset, total)

    logger.info("  %s: %d linhas extraídas → %s", obj_id, written, out_path)
    return written


async def phase_extract():
    TMP_DIR.mkdir(exist_ok=True)
    async with websockets.connect(
        WS_URL,
        additional_headers=WS_HEADERS,
        max_size=50 * 1024 * 1024,
        ping_interval=None,  # Qlik não responde pings da biblioteca; usa keepalive próprio
    ) as ws:
        r = await _rpc(ws, "OpenDoc", [APP_ID], msg_id=1)
        app_handle = r["result"]["qReturn"]["qHandle"]
        logger.info("App aberto handle=%d", app_handle)

        for idx, (obj_id, n_cols, table_name, columns) in enumerate(TABLES):
            out_path = TMP_DIR / f"{table_name}.jsonl"
            logger.info("Extraindo %s ...", table_name)
            await extract_table(ws, app_handle, obj_id, n_cols, columns, 1000 + idx*1000, out_path)


# ── FASE 2: JSONL → Supabase ────────────────────────────────────────────────
def upsert_batch(table, rows, url, key):
    on_conflict = CONFLICT_COLS.get(table, "")
    endpoint = f"{url}/rest/v1/{table}?on_conflict={on_conflict}"
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
            logger.warning("upsert %s: HTTP %s", table, status)
    finally:
        os.unlink(tmp)


def phase_load(url, key):
    for _, _, table_name, _ in TABLES:
        path = TMP_DIR / f"{table_name}.jsonl"
        if not path.exists():
            logger.warning("Arquivo não encontrado: %s — pule ou rode extract primeiro", path)
            continue

        logger.info("Carregando %s ...", table_name)
        buf = []
        total = 0
        with open(path, encoding="utf-8") as f:
            for line in f:
                row = json.loads(line)
                # linhas-totalizadoras do Qlik têm campos chave como "-"; descartar
                if row.get("numero_contrato") == "-" or row.get("numero_convenio") == "-" or row.get("numero_licitacao") == "-":
                    continue
                # normalizar ano: string vazia ou "-" → None
                if "ano" in row and not str(row["ano"]).strip().lstrip("-").isdigit():
                    row["ano"] = None
                buf.append(row)
                if len(buf) >= BATCH_SIZE:
                    upsert_batch(table_name, buf, url, key)
                    total += len(buf)
                    buf.clear()
                    if total % 5000 == 0:
                        logger.info("  %d inseridos", total)
        if buf:
            upsert_batch(table_name, buf, url, key)
            total += len(buf)
        logger.info("  %s: %d linhas carregadas", table_name, total)


# ── Main ────────────────────────────────────────────────────────────────────
def main():
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

    url = os.environ.get("SUPABASE_URL", "")
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY") or os.environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY", "")

    mode = sys.argv[1] if len(sys.argv) > 1 else "all"

    if mode in ("extract", "all"):
        logger.info("=== FASE 1: Extração Qlik → JSONL ===")
        asyncio.run(phase_extract())

    if mode in ("load", "all"):
        if not url or not key:
            raise SystemExit("SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY são obrigatórios para load")
        logger.info("=== FASE 2: JSONL → Supabase ===")
        phase_load(url, key)

    logger.info("Concluído.")


if __name__ == "__main__":
    main()
