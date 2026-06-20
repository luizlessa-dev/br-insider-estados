"""
Enriquecimento de destino em viagens — lê CSVs bulk do Portal da Transparência
e atualiza as colunas destinos/destino_municipio/destino_uf na tabela viagens
usando PCDP como chave de join.

Download manual dos ZIPs:
  https://portaldatransparencia.gov.br/download-de-dados/viagens
  → selecionar mês/ano → baixar → extrair CSV

Uso:
    python -m ingestao.portal.viagens_destinos /path/202301_Viagens.csv /path/202302_Viagens.csv ...

    # ou para um diretório inteiro de CSVs:
    python -m ingestao.portal.viagens_destinos /path/viagens/*.csv
"""
from __future__ import annotations

import csv
import logging
import os
import re
import sys
import time
from pathlib import Path
from typing import Iterator

import requests

logger = logging.getLogger("portal.viagens_destinos")

BATCH_SLEEP_S = 0.15

# Possíveis nomes de coluna no CSV (Portal muda o nome ocasionalmente)
COLUNAS_PCDP = [
    "Identificador do processo de viagem (PCDP)",
    "PCDP",
    "Número PCDP",
    "Identificador PCDP",
]
COLUNAS_DESTINOS = [
    "Destinos",
    "Destino",
    "Destino(s)",
    "Local de destino",
]


def _detectar_coluna(header: list[str], candidatos: list[str]) -> str | None:
    for c in candidatos:
        if c in header:
            return c
    return None


def _parse_destino(raw: str) -> tuple[str | None, str | None]:
    """
    "BRASÍLIA/DF - SÃO PAULO/SP" → ("BRASÍLIA", "DF")
    "PARIS/FRANCA"                → ("PARIS", "FRANCA")
    """
    if not raw:
        return None, None
    # pegar apenas o primeiro destino (antes do ' - ' ou ',')
    primeiro = re.split(r"\s*[-,]\s*", raw.strip(), maxsplit=1)[0].strip()
    if "/" in primeiro:
        partes = primeiro.rsplit("/", 1)
        municipio = partes[0].strip().upper() or None
        uf = partes[1].strip().upper() or None
        return municipio, uf
    return primeiro.upper() or None, None


def iter_registros(path: Path) -> Iterator[dict]:
    """Lê um CSV e emite dicts com pcdp + campos de destino."""
    for enc in ("utf-8-sig", "latin-1"):
        try:
            with open(path, encoding=enc, newline="") as f:
                reader = csv.DictReader(f, delimiter=";")
                header = reader.fieldnames or []

                col_pcdp = _detectar_coluna(list(header), COLUNAS_PCDP)
                col_dest = _detectar_coluna(list(header), COLUNAS_DESTINOS)

                if not col_pcdp or not col_dest:
                    logger.warning(
                        "%s — colunas não encontradas. Disponíveis: %s",
                        path.name, list(header)
                    )
                    return

                for row in reader:
                    pcdp = row.get(col_pcdp, "").strip()
                    raw_dest = row.get(col_dest, "").strip()
                    if not pcdp:
                        continue
                    municipio, uf = _parse_destino(raw_dest)
                    yield {
                        "pcdp": pcdp,
                        "destinos": raw_dest or None,
                        "destino_municipio": municipio,
                        "destino_uf": uf,
                    }
            return  # encoding funcionou
        except UnicodeDecodeError:
            continue


def enriquecer(csv_paths: list[Path]) -> int:
    url = (os.environ.get("SUPABASE_URL") or "").rstrip("/")
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY") or ""
    if not url or not key:
        raise RuntimeError("SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY são obrigatórios.")

    session = requests.Session()
    session.headers.update({
        "apikey": key,
        "Authorization": f"Bearer {key}",
        "Content-Type": "application/json",
        "Prefer": "return=minimal",
    })

    # Agregar por PCDP (o mesmo PCDP pode aparecer em várias linhas do CSV)
    pcdp_map: dict[str, dict] = {}
    for path in csv_paths:
        logger.info("Lendo %s …", path.name)
        for rec in iter_registros(path):
            pcdp_map[rec["pcdp"]] = rec

    logger.info("%d PCDPs únicos encontrados nos CSVs", len(pcdp_map))

    atualizados = 0
    erros = 0
    for i, (pcdp, dados) in enumerate(pcdp_map.items()):
        payload = {k: v for k, v in dados.items() if k != "pcdp"}
        resp = session.patch(
            f"{url}/rest/v1/viagens",
            params={"pcdp": f"eq.{pcdp}"},
            json=payload,
            timeout=30,
        )
        if resp.status_code >= 300:
            logger.warning("PATCH pcdp=%s → HTTP %d %s", pcdp, resp.status_code, resp.text[:120])
            erros += 1
        else:
            atualizados += 1

        if (i + 1) % 200 == 0:
            print(f"\r  {i+1}/{len(pcdp_map)} PCDPs processados …", end="", flush=True)
        time.sleep(BATCH_SLEEP_S)

    print()
    logger.info("✅ %d atualizados, %d erros", atualizados, erros)
    return atualizados


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(name)s — %(message)s")
    if len(sys.argv) < 2:
        print("Uso: python -m ingestao.portal.viagens_destinos <csv1> [csv2] ...")
        sys.exit(1)
    paths = [Path(p) for p in sys.argv[1:]]
    for p in paths:
        if not p.exists():
            print(f"ERRO: arquivo não encontrado: {p}")
            sys.exit(1)
    n = enriquecer(paths)
    print(f"✅ {n} PCDPs atualizados em viagens")
