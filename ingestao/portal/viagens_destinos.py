"""
Enriquecimento de origem/destino em viagens usando Trecho.csv do Portal da Transparência.

Cada ZIP anual contém 4 arquivos; este script usa apenas o *_Trecho.csv.
Os trechos são agrupados por PCDP; o primeiro trecho define o destino primário.

Uso:
    python -m ingestao.portal.viagens_destinos \\
        /Downloads/2023_Viagens/2023_Trecho.csv \\
        /Downloads/2024_Viagens/2024_Trecho.csv \\
        /Downloads/2025_Viagens/2025_Trecho.csv \\
        /Downloads/2026_Viagens/2026_Trecho.csv
"""
from __future__ import annotations

import csv
import logging
import os
import ssl
import sys
import time
import urllib.request
import json
from pathlib import Path

import requests

logger = logging.getLogger("portal.viagens_destinos")

BATCH_SLEEP_S = 0.12

COL_PCDP   = "Identificador do processo de viagem "   # trailing space real no CSV
COL_SEQ    = "Sequência Trecho"
COL_ORIG_C = "Origem - Cidade"
COL_ORIG_U = "Origem - UF"
COL_DEST_C = "Destino - Cidade"
COL_DEST_U = "Destino - UF"
COL_DEST_P = "Destino - País"

UF_SIGLAS: dict[str, str] = {
    "Acre": "AC", "Alagoas": "AL", "Amapá": "AP", "Amazonas": "AM",
    "Bahia": "BA", "Ceará": "CE", "Distrito Federal": "DF",
    "Espírito Santo": "ES", "Goiás": "GO", "Maranhão": "MA",
    "Mato Grosso": "MT", "Mato Grosso do Sul": "MS", "Minas Gerais": "MG",
    "Pará": "PA", "Paraíba": "PB", "Paraná": "PR", "Pernambuco": "PE",
    "Piauí": "PI", "Rio de Janeiro": "RJ", "Rio Grande do Norte": "RN",
    "Rio Grande do Sul": "RS", "Rondônia": "RO", "Roraima": "RR",
    "Santa Catarina": "SC", "São Paulo": "SP", "Sergipe": "SE", "Tocantins": "TO",
    # abreviações já corretas (fallback)
    **{v: v for v in ["AC","AL","AP","AM","BA","CE","DF","ES","GO","MA",
                       "MT","MS","MG","PA","PB","PR","PE","PI","RJ","RN",
                       "RS","RO","RR","SC","SP","SE","TO"]},
}


def _sigla(nome: str) -> str | None:
    return UF_SIGLAS.get(nome.strip()) or (nome.strip().upper()[:2] or None)


def _buscar_pcdps_db(url: str, key: str) -> set[str]:
    """Retorna o conjunto de PCDPs que existem no banco."""
    ctx = ssl.create_default_context()
    pcdps: set[str] = set()
    offset = 0
    while True:
        req = urllib.request.Request(
            f"{url}/rest/v1/viagens?select=pcdp&pcdp=not.is.null&limit=1000&offset={offset}",
            headers={"apikey": key, "Authorization": f"Bearer {key}"},
        )
        with urllib.request.urlopen(req, context=ctx) as r:
            rows = json.load(r)
        if not rows:
            break
        pcdps.update(r["pcdp"] for r in rows if r.get("pcdp"))
        if len(rows) < 1000:
            break
        offset += 1000
    return pcdps


def _ler_trechos(paths: list[Path], pcdps_alvo: set[str]) -> dict[str, dict]:
    """
    Lê os Trecho.csv e constrói um mapa pcdp → campos de destino/origem.
    Filtra apenas PCDPs que existem no banco.
    """
    pcdp_data: dict[str, list[dict]] = {}

    for path in paths:
        logger.info("Lendo %s …", path.name)
        with open(path, encoding="latin-1", newline="") as f:
            reader = csv.DictReader(f, delimiter=";")
            for row in reader:
                pcdp = row.get(COL_PCDP, "").strip()
                if not pcdp or pcdp not in pcdps_alvo:
                    continue
                seq = row.get(COL_SEQ, "99")
                try:
                    seq_n = int(seq)
                except ValueError:
                    seq_n = 99
                pcdp_data.setdefault(pcdp, []).append({
                    "seq": seq_n,
                    "orig_cidade": row.get(COL_ORIG_C, "").strip(),
                    "orig_uf":     row.get(COL_ORIG_U, "").strip(),
                    "dest_cidade": row.get(COL_DEST_C, "").strip(),
                    "dest_uf":     row.get(COL_DEST_U, "").strip(),
                    "dest_pais":   row.get(COL_DEST_P, "").strip(),
                })

    result: dict[str, dict] = {}
    for pcdp, trechos in pcdp_data.items():
        trechos.sort(key=lambda t: t["seq"])
        primeiro = trechos[0]

        # destinos raw: "Cidade1/UF1, Cidade2/UF2"
        dests_raw = []
        for t in trechos:
            uf = _sigla(t["dest_uf"]) or t["dest_uf"]
            label = f"{t['dest_cidade']}/{uf}" if uf else t["dest_cidade"]
            if label and label not in dests_raw:
                dests_raw.append(label)

        pais = primeiro["dest_pais"] if primeiro["dest_pais"] != "Brasil" else None

        result[pcdp] = {
            "destinos":          ", ".join(dests_raw) or None,
            "destino_municipio": primeiro["dest_cidade"] or None,
            "destino_uf":        _sigla(primeiro["dest_uf"]) or None,
            "destino_pais":      pais,
            "origem_municipio":  primeiro["orig_cidade"] or None,
            "origem_uf":         _sigla(primeiro["orig_uf"]) or None,
        }

    return result


def enriquecer(csv_paths: list[Path]) -> int:
    supa_url = (os.environ.get("SUPABASE_URL") or "").rstrip("/")
    supa_key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY") or ""
    if not supa_url or not supa_key:
        raise RuntimeError("SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY são obrigatórios.")

    logger.info("Buscando PCDPs existentes no banco …")
    pcdps_alvo = _buscar_pcdps_db(supa_url, supa_key)
    logger.info("%d PCDPs no banco", len(pcdps_alvo))

    dados = _ler_trechos(csv_paths, pcdps_alvo)
    logger.info("%d PCDPs com trechos encontrados nos CSVs", len(dados))

    session = requests.Session()
    session.headers.update({
        "apikey": supa_key,
        "Authorization": f"Bearer {supa_key}",
        "Content-Type": "application/json",
        "Prefer": "return=minimal",
    })

    atualizados = 0
    erros = 0
    total = len(dados)
    for i, (pcdp, payload) in enumerate(dados.items()):
        for tentativa in range(4):
            try:
                resp = session.patch(
                    f"{supa_url}/rest/v1/viagens",
                    params={"pcdp": f"eq.{pcdp}"},
                    json=payload,
                    timeout=30,
                )
                break
            except (requests.exceptions.ConnectionError, requests.exceptions.Timeout) as exc:
                if tentativa == 3:
                    logger.error("PATCH pcdp=%s falhou após 4 tentativas: %s", pcdp, exc)
                    resp = None
                    break
                wait = 2 ** tentativa
                logger.warning("retry %d pcdp=%s (%s) — aguardando %ds", tentativa + 1, pcdp, type(exc).__name__, wait)
                time.sleep(wait)

        if resp is None:
            erros += 1
        elif resp.status_code >= 300:
            logger.warning("PATCH pcdp=%s → HTTP %d %s", pcdp, resp.status_code, resp.text[:120])
            erros += 1
        else:
            atualizados += 1

        if (i + 1) % 100 == 0:
            print(f"\r  {i+1}/{total} ({100*(i+1)//total}%) …", end="", flush=True)
        time.sleep(BATCH_SLEEP_S)

    print()
    logger.info("✅ %d atualizados, %d erros", atualizados, erros)
    return atualizados


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(name)s — %(message)s")
    if len(sys.argv) < 2:
        print("Uso: python -m ingestao.portal.viagens_destinos <Trecho.csv> [...]")
        sys.exit(1)
    paths = [Path(p) for p in sys.argv[1:]]
    for p in paths:
        if not p.exists():
            print(f"ERRO: {p} não encontrado")
            sys.exit(1)
    n = enriquecer(paths)
    print(f"✅ {n} viagens enriquecidas com origem/destino")
