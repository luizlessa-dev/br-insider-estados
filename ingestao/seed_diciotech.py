"""
Seed glossario_tech — The Brasilia Insider

Ingere os termos do Diciotech (github.com/levxyca/diciotech) em PT-BR,
populando a tabela `glossario_tech` no Supabase.

Fonte: arquivos YAML públicos no repositório GitHub via API.
Sem autenticação necessária — repositório open source.

Uso:
  python -m ingestao.seed_diciotech [--dry-run] [--lang pt-br|en-us]
"""
from __future__ import annotations

import argparse
import logging
import os
import sys
import time
from typing import Optional
from urllib.request import urlopen, Request
from urllib.error import URLError, HTTPError
import base64
import json

try:
    import yaml
except ImportError:
    print("Instale pyyaml: pip install pyyaml", file=sys.stderr)
    sys.exit(1)

try:
    from supabase import create_client
except ImportError:
    print("Instale supabase-py: pip install supabase", file=sys.stderr)
    sys.exit(1)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("seed_diciotech")

GITHUB_API = "https://api.github.com"
REPO = "levxyca/diciotech"
# Letras + arquivos especiais presentes no repo
LETTER_FILES = list("abcdefghijklmnoprstuvwxyz") + ["numbers", "strings"]
REQUEST_DELAY = 0.5  # segundos entre chamadas à API GitHub


def fetch_github_json(path: str) -> dict:
    url = f"{GITHUB_API}/repos/{REPO}/contents/{path}"
    headers = {"User-Agent": "BRInsider/1.0 (contato@thebrinsider.com)"}
    token = os.environ.get("GITHUB_TOKEN")
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = Request(url, headers=headers)
    with urlopen(req, timeout=15) as resp:
        return json.loads(resp.read().decode())


def fetch_yaml_terms(lang: str) -> list[dict]:
    """Baixa e parseia todos os arquivos YAML de `_data/<lang>/`."""
    all_terms: list[dict] = []

    for letter in LETTER_FILES:
        path = f"_data/{lang}/{letter}.yml"
        try:
            data = fetch_github_json(path)
        except HTTPError as e:
            if e.code == 404:
                logger.debug("Arquivo não encontrado: %s — pulando", path)
                continue
            raise
        except URLError as e:
            logger.warning("Erro ao buscar %s: %s", path, e)
            continue

        raw_yaml = base64.b64decode(data["content"]).decode("utf-8")
        entries = yaml.safe_load(raw_yaml)

        if not entries or not isinstance(entries, list):
            logger.debug("  %s/%s.yml — ignorado (não é lista de termos)", lang, letter)
            continue

        for entry in entries:
            # strings.yml é i18n da UI (dict, não lista de termos) — ignorar
            if not isinstance(entry, dict):
                continue
            if "title" not in entry:
                continue
            all_terms.append({
                "id": entry.get("id", ""),
                "titulo": entry.get("title", ""),
                "descricao": entry.get("description", ""),
                "tags": entry.get("tags", []),
                "lang": lang,
                "letra": letter,
                "fonte_url": f"https://diciotech.netlify.app/?search={entry.get('id', '')}",
            })

        logger.info("  %s/%s.yml → %d termos", lang, letter, len(entries))
        time.sleep(REQUEST_DELAY)

    return all_terms


def upsert_terms(sb, terms: list[dict], dry_run: bool) -> None:
    if dry_run:
        logger.info("[DRY-RUN] %d termos seriam gravados", len(terms))
        for t in terms[:3]:
            logger.info("  Exemplo: %s — %s", t["id"], t["titulo"])
        return

    BATCH = 100
    total_upserted = 0
    for i in range(0, len(terms), BATCH):
        batch = terms[i : i + BATCH]
        sb.table("glossario_tech").upsert(batch, on_conflict="id,lang").execute()
        total_upserted += len(batch)
        logger.info("  Upsert %d/%d", total_upserted, len(terms))

    logger.info("✅ %d termos gravados em glossario_tech", total_upserted)


SQL_MIGRATION = """
-- Rodar UMA VEZ antes do seed:
CREATE TABLE IF NOT EXISTS glossario_tech (
    id          TEXT        NOT NULL,
    lang        TEXT        NOT NULL DEFAULT 'pt-br',
    titulo      TEXT        NOT NULL,
    descricao   TEXT,
    tags        TEXT[]      DEFAULT '{}',
    letra       TEXT,
    fonte_url   TEXT,
    criado_em   TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (id, lang)
);

CREATE INDEX IF NOT EXISTS idx_glossario_tech_tags ON glossario_tech USING GIN (tags);
CREATE INDEX IF NOT EXISTS idx_glossario_tech_lang ON glossario_tech (lang);
"""


def main() -> None:
    parser = argparse.ArgumentParser(description="Seed glossario_tech via Diciotech")
    parser.add_argument(
        "--lang",
        choices=["pt-br", "en-us", "all"],
        default="pt-br",
        help="Idioma a ingerir (default: pt-br)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Apenas lista termos, não grava no Supabase",
    )
    parser.add_argument(
        "--show-migration",
        action="store_true",
        help="Imprime o SQL de criação da tabela e sai",
    )
    args = parser.parse_args()

    if args.show_migration:
        print(SQL_MIGRATION)
        return

    if not args.dry_run:
        url = os.environ.get("SUPABASE_URL")
        key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
        if not url or not key:
            logger.error("SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY são obrigatórios")
            sys.exit(1)
        sb = create_client(url, key)
    else:
        sb = None

    langs = ["pt-br", "en-us"] if args.lang == "all" else [args.lang]

    for lang in langs:
        logger.info("Buscando termos — lang=%s", lang)
        terms = fetch_yaml_terms(lang)
        logger.info("Total: %d termos em %s", len(terms), lang)
        upsert_terms(sb, terms, args.dry_run)


if __name__ == "__main__":
    main()
