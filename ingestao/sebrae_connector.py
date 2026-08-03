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
        # Ordem corrigida em 2026-07-22 (confirmada via GetLayout/qDimensionInfo
        # posicional): a lista antiga tinha "tipo_julgamento"/"menor_preco"/
        # "julgamento" fora de ordem, misturando o conteúdo dos 3 campos.
        "f7a53fdc-c669-4914-b7a7-bf11a9eea914", 13, "sebrae_licitacoes",
        ["uf","numero_licitacao","tipo_licitacao","tipo_julgamento",
         "situacao","modalidade","menor_preco","objeto",
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
        # ATENÇÃO: o Qlik de origem tem a medida "Valor do contrato" e o campo
        # "Observação" com conteúdo trocado (confirmado via GetLayout/qDimensionInfo
        # em 2026-07-22). O campo rotulado "Observação" é o que traz o valor
        # numérico real; a medida rotulada "Valor do contrato" traz texto livre
        # truncado a ~30 caracteres (autor/nº de emenda/nº de convênio).
        # Por isso a ordem abaixo NÃO segue os rótulos do Qlik — segue o conteúdo real.
        "AHSdRn", 12, "sebrae_emendas_contratos",
        ["uf","ano","numero_contrato","data_contrato","modalidade",
         "cnpj_cpf","razao_social","vigencia","objeto","aditivo",
         "valor_contrato","nota_parlamentar_truncada"],
    ),
    (
        # Mesmo problema do objeto acima — ver comentário na tabela sebrae_emendas_contratos.
        "DumJhJv", 11, "sebrae_emendas_convenios",
        ["uf","ano","numero_convenio","data_convenio","cnpj_cpf",
         "razao_social","vigencia","objeto","aditivo",
         "valor_emenda","nota_parlamentar_truncada"],
    ),
]

CONFLICT_COLS = {
    "sebrae_contratos":         "uf,numero_contrato",
    # Granularidade real é (licitação × participante) — cada concorrente é uma
    # linha própria. UNIQUE(uf,numero_licitacao) sozinha descartava ~75% das
    # linhas via ignore-duplicates (achado em 2026-07-22).
    "sebrae_licitacoes":        "uf,numero_licitacao,cnpj_fornecedor,resultado",
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

    # Escreve num .partial e só promove pro nome final se bater 100% do total.
    # Isso evita que uma extração cortada por timeout do WebSocket (já visto
    # acontecer — GH Actions run 2026-07-03 travou aos 14000/480314 de
    # sebrae_contratos) deixe pra trás um arquivo "final" incompleto que uma
    # fase_load posterior carregaria sem perceber a falta de linhas.
    partial_path = out_path.with_suffix(out_path.suffix + ".partial")
    written = 0
    with open(partial_path, "w", encoding="utf-8") as f:
        offset = 0
        fetch_id = msg_base + 10
        while offset < total:
            page = [{"qTop": offset, "qLeft": 0, "qWidth": n_cols, "qHeight": PAGE_SIZE}]
            # Retry: o Qlik já mostrou travar uma requisição isolada por >30s no
            # meio de uma extração longa (GH Actions run 2026-07-03), sem relação
            # aparente com volume. GetHyperCubeData é leitura pura — retry é seguro.
            for attempt in range(1, 4):
                try:
                    r3 = await _rpc(ws, "GetHyperCubeData", ["/qHyperCubeDef", page], handle=tbl, msg_id=fetch_id)
                    fetch_id += 1
                    break
                except (asyncio.TimeoutError, TimeoutError, RuntimeError) as e:
                    fetch_id += 1
                    if attempt == 3:
                        raise
                    logger.warning("    timeout em offset=%d, tentativa %d/3: %s", offset, attempt, e)
                    await asyncio.sleep(2 * attempt)
            matrix = r3["result"]["qDataPages"][0]["qMatrix"]
            for row in matrix:
                vals = [cell.get("qText", "") for cell in row]
                f.write(json.dumps(dict(zip(columns, vals)), ensure_ascii=False) + "\n")
                written += 1
            offset += len(matrix)
            if offset % 1000 == 0:
                logger.info("    %d/%d", offset, total)

    if written != total:
        raise RuntimeError(
            f"Extração de {out_path.name} incompleta: {written}/{total} linhas. "
            f"Mantido só o parcial em {partial_path} — NÃO promovido pro nome "
            f"final, então phase_load vai pulá-lo em vez de carregar dado cortado."
        )

    partial_path.replace(out_path)
    logger.info("  %s: %d linhas extraídas → %s", obj_id, written, out_path)
    return written


async def phase_extract():
    TMP_DIR.mkdir(exist_ok=True)
    # Remove qualquer .jsonl final de um run anterior antes de começar — assim,
    # se este run falhar no meio (ex: tabela 3 de 6), as tabelas que nem chegaram
    # a ser tentadas não deixam um arquivo velho pra phase_load carregar sem querer.
    for _, _, table_name, _ in TABLES:
        (TMP_DIR / f"{table_name}.jsonl").unlink(missing_ok=True)

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
