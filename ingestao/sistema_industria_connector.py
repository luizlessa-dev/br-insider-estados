"""
Sistema Indústria (SESI + SENAI) — Ingester via REST API
BR Insider

Fonte: sistematransparenciaweb.com.br — API REST pública, sem autenticação
Entidades: SENAI e SESI (27 DRs cada)
Categorias: contratos/patrocínios, licitações (+ participantes), convênios
Anos: 2022 até o ano corrente

Estratégia em 2 fases:
  Fase 1: HTTP GET → JSONL local (/tmp/sisi/*.jsonl)
  Fase 2: JSONL → Supabase via curl (evita bug latin-1 Python 3.14)

Execução:
  python3 -m ingestao.sistema_industria_connector           # ambas as fases
  python3 -m ingestao.sistema_industria_connector extract   # só fase 1
  python3 -m ingestao.sistema_industria_connector load      # só fase 2
"""
from __future__ import annotations

import json
import logging
import os
import subprocess
import sys
import tempfile
import time
import urllib.request
import urllib.error
from datetime import date
from pathlib import Path

logger = logging.getLogger("sisi")

# ── Constantes ─────────────────────────────────────────────────────────────
BASE_URL    = "https://sistematransparenciaweb.com.br"
TMP_DIR     = Path("/tmp/sisi")
BATCH_SIZE  = 500
RETRY_LIMIT = 3
RETRY_SLEEP = 5  # segundos entre tentativas

ENTIDADES = ["SENAI", "SESI"]

UFS = [
    "AC","AL","AM","AP","BA","CE","DF","ES","GO",
    "MA","MG","MS","MT","PA","PB","PE","PI","PR",
    "RJ","RN","RO","RR","RS","SC","SE","SP","TO",
]

# Anos disponíveis na API (dados abertos a partir de 2022)
ANO_INICIO = 2022

# ── Tabelas e seus endpoints ────────────────────────────────────────────────
# (nome_tabela, path_list, path_export, param_formato, fn_normalizar)
MODULES = [
    {
        "tabela":       "sisi_contratos",
        "path_list":    "/api-contratos/publico/contrato-patrocinio",
        "path_export":  None,  # usamos JSON direto, sem XLSX
        "pk_api":       "codigoContratoPatrocinio",
        "conflict":     "entidade,departamento,codigo_contrato",
    },
    {
        "tabela":       "sisi_licitacoes",
        "path_list":    "/api-licitacoes/publico/licitacoes",
        "path_export":  None,
        "pk_api":       "codigoLicitacao",
        "conflict":     "entidade,departamento,codigo_licitacao",
    },
    {
        "tabela":       "sisi_convenios",
        "path_list":    "/api-convenios/convenios",
        "path_export":  None,
        "pk_api":       "codigoConvenios",
        "conflict":     "entidade,departamento,codigo_convenio",
    },
]

CONFLICT_PART = "entidade,departamento,licitacao_codigo,cnpj_cpf"


# ── Helpers HTTP ────────────────────────────────────────────────────────────
def _get_json(path: str, params: dict) -> list | dict | None:
    qs = "&".join(f"{k}={v}" for k, v in params.items())
    url = f"{BASE_URL}{path}?{qs}"
    for attempt in range(1, RETRY_LIMIT + 1):
        try:
            req = urllib.request.Request(
                url,
                headers={"User-Agent": "BRInsider/1.0 (bot dados públicos; contato@thebrinsider.com)"},
            )
            with urllib.request.urlopen(req, timeout=60) as resp:
                raw = resp.read().decode("utf-8")
                return json.loads(raw)
        except urllib.error.HTTPError as e:
            if e.code == 404:
                return []
            logger.warning("HTTP %s para %s (tentativa %d/%d)", e.code, url, attempt, RETRY_LIMIT)
        except Exception as e:
            logger.warning("Erro em %s (tentativa %d/%d): %s", url, attempt, RETRY_LIMIT, e)
        if attempt < RETRY_LIMIT:
            time.sleep(RETRY_SLEEP)
    return None


# ── Normalização por módulo ─────────────────────────────────────────────────
def _norm_contrato(row: dict, entidade: str, departamento: str) -> dict:
    return {
        "entidade":             entidade,
        "departamento":         departamento,
        "codigo_contrato":      row.get("codigoContratoPatrocinio"),
        "ano":                  row.get("ano"),
        "contrato":             row.get("contrato"),
        "processo":             row.get("processo"),
        "contratantes":         row.get("contratantes"),
        "data_contrato":        row.get("dataContrato"),
        "vigencia_meses":       row.get("vigencia"),
        "data_final":           row.get("dataFinal"),
        "status_contrato":      row.get("statusContrato"),
        "modalidade":           row.get("modalidade"),
        "objeto":               row.get("objeto"),
        "categoria":            row.get("categoria"),
        "cpf_cnpj":             row.get("cpfCnpj"),
        "nome_razao_social":    row.get("nomeRazaoSocial"),
        "valor_contrato":       row.get("valorContrato"),
        "valor_previsto":       row.get("valorPrevisto"),
        "valor_executado":      row.get("valorExecutado"),
        "houve_aditivo_preco":  row.get("houveAditivoPreco"),
        "valor_aditivo":        row.get("valorAditivo"),
        "houve_aditivo_prazo":  row.get("houveAditivoPrazo"),
        "observacoes":          row.get("observacoes"),
        "data_publicacao":      row.get("dataPublicacao"),
    }


def _norm_licitacao(row: dict, entidade: str, departamento: str) -> tuple[dict, list[dict]]:
    licitacao = {
        "entidade":                 entidade,
        "departamento":             departamento,
        "codigo_licitacao":         row.get("codigoLicitacao"),
        "ano":                      row.get("ano"),
        "numero":                   row.get("numero"),
        "titulo":                   row.get("titulo"),
        "data_abertura":            row.get("dataAbertura"),
        "modalidade":               row.get("modalidade"),
        "objeto":                   row.get("objeto"),
        "status_licitacao":         row.get("statusLicitacao"),
        "crit_julgamento":          row.get("critJulgamento"),
        "dt_homologacao":           row.get("dtHomologacao"),
        "nm_empresa_vencedora":     row.get("nmEmpresa"),
        "data_publicacao":          row.get("dataPublicacao"),
    }

    participantes = []
    for lote in (row.get("itensLotes") or []):
        for p in (lote.get("participantes") or []):
            cnpj = p.get("cnpjCpf") or ""
            if not cnpj or cnpj == "-":
                continue
            try:
                valor = float(str(p.get("valorProposta") or "0").replace(".", "").replace(",", "."))
            except (ValueError, TypeError):
                valor = None
            participantes.append({
                "entidade":         entidade,
                "departamento":     departamento,
                "licitacao_codigo": row.get("codigoLicitacao"),
                "participante":     p.get("participante"),
                "cnpj_cpf":         cnpj,
                "valor_proposta":   valor,
            })

    return licitacao, participantes


def _norm_convenio(row: dict, entidade: str, departamento: str) -> dict:
    return {
        "entidade":                         entidade,
        "departamento":                     departamento,
        "codigo_convenio":                  row.get("codigoConvenios"),
        "ano":                              row.get("ano"),
        "numero_convenio":                  row.get("numeroConvenio"),
        "data_convenio":                    row.get("dataConvenio"),
        "vigencia":                         row.get("vigencia"),
        "data_final":                       row.get("dataFinal"),
        "descricao_objeto":                 row.get("descricaoObjeto"),
        "razao_social_convenente":          row.get("razaoSocialConvenente"),
        "cnpj":                             row.get("cnpj"),
        "valor_participacao_concedente":    row.get("valorParticipacaoConcedente"),
        "valor_transferido":                row.get("valorTransferido"),
        "status_convenio":                  row.get("statusConvenioRenovacao"),
        "valor_contrapartida":              row.get("valorContrapartida"),
        "houve_aditivo_valor":              row.get("houveAditivoValorConcedente"),
        "valor_aditivos":                   row.get("valorAditivosConcedente"),
        "houve_aditivo_prazo":              row.get("houveAditivoPrazo"),
        "data_publicacao":                  row.get("dataPublicacao"),
    }


# ── FASE 1: HTTP GET → JSONL ────────────────────────────────────────────────
def phase_extract():
    TMP_DIR.mkdir(parents=True, exist_ok=True)
    ano_atual = date.today().year
    anos = list(range(ANO_INICIO, ano_atual + 1))

    # arquivos de saída
    files: dict[str, object] = {}
    try:
        files["sisi_contratos"]               = open(TMP_DIR / "sisi_contratos.jsonl", "w", encoding="utf-8")
        files["sisi_licitacoes"]              = open(TMP_DIR / "sisi_licitacoes.jsonl", "w", encoding="utf-8")
        files["sisi_licitacoes_participantes"] = open(TMP_DIR / "sisi_licitacoes_participantes.jsonl", "w", encoding="utf-8")
        files["sisi_convenios"]               = open(TMP_DIR / "sisi_convenios.jsonl", "w", encoding="utf-8")

        totais: dict[str, int] = {k: 0 for k in files}

        for entidade in ENTIDADES:
            for uf in UFS:
                departamento = f"{entidade}-{uf}"
                for ano in anos:
                    params = {"entidade": entidade, "departamento": departamento, "ano": ano}

                    # Contratos
                    dados = _get_json("/api-contratos/publico/contrato-patrocinio", params)
                    if dados:
                        for row in (dados if isinstance(dados, list) else []):
                            norm = _norm_contrato(row, entidade, departamento)
                            if not norm.get("codigo_contrato"):
                                continue
                            files["sisi_contratos"].write(json.dumps(norm, ensure_ascii=False) + "\n")
                            totais["sisi_contratos"] += 1

                    # Licitações
                    dados = _get_json("/api-licitacoes/publico/licitacoes", params)
                    if dados:
                        for row in (dados if isinstance(dados, list) else []):
                            lic, parts = _norm_licitacao(row, entidade, departamento)
                            if not lic.get("codigo_licitacao"):
                                continue
                            files["sisi_licitacoes"].write(json.dumps(lic, ensure_ascii=False) + "\n")
                            totais["sisi_licitacoes"] += 1
                            for p in parts:
                                files["sisi_licitacoes_participantes"].write(json.dumps(p, ensure_ascii=False) + "\n")
                                totais["sisi_licitacoes_participantes"] += 1

                    # Convênios
                    dados = _get_json("/api-convenios/convenios", params)
                    if dados:
                        for row in (dados if isinstance(dados, list) else []):
                            norm = _norm_convenio(row, entidade, departamento)
                            if not norm.get("codigo_convenio"):
                                continue
                            files["sisi_convenios"].write(json.dumps(norm, ensure_ascii=False) + "\n")
                            totais["sisi_convenios"] += 1

                logger.info("%s %s: contratos=%d licitações=%d convênios=%d",
                            entidade, uf,
                            totais["sisi_contratos"],
                            totais["sisi_licitacoes"],
                            totais["sisi_convenios"])
    finally:
        for f in files.values():
            f.close()

    for tabela, n in totais.items():
        logger.info("  %s: %d linhas extraídas", tabela, n)


# ── FASE 2: JSONL → Supabase ────────────────────────────────────────────────
CONFLICT_COLS = {
    "sisi_contratos":                "entidade,departamento,codigo_contrato",
    "sisi_licitacoes":               "entidade,departamento,codigo_licitacao",
    "sisi_licitacoes_participantes": "entidade,departamento,licitacao_codigo,cnpj_cpf",
    "sisi_convenios":                "entidade,departamento,codigo_convenio",
}


def _upsert_batch(tabela: str, rows: list, url: str, key: str):
    on_conflict = CONFLICT_COLS.get(tabela, "")
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
    tabelas = [
        "sisi_contratos",
        "sisi_licitacoes",
        "sisi_licitacoes_participantes",
        "sisi_convenios",
    ]

    for tabela in tabelas:
        path = TMP_DIR / f"{tabela}.jsonl"
        if not path.exists():
            logger.warning("Arquivo não encontrado: %s — rode extract primeiro", path)
            continue

        logger.info("Carregando %s ...", tabela)
        buf: list = []
        total = 0

        with open(path, encoding="utf-8") as f:
            for line in f:
                row = json.loads(line)
                buf.append(row)
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
        logger.info("=== FASE 1: HTTP GET → JSONL ===")
        phase_extract()

    if mode in ("load", "all"):
        if not url or not key:
            raise SystemExit("SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY são obrigatórios para load")
        logger.info("=== FASE 2: JSONL → Supabase ===")
        phase_load(url, key)

    logger.info("Concluído.")


if __name__ == "__main__":
    main()
