"""
Seed CNPJ prioritário via BrasilAPI — The Brasilia Insider
Enriquece as top empresas privadas (por nº de autores × volume) sem depender
do dump bulk da RFB. Rate limit: ~30 req/min → ~200 CNPJs em ~8 min.

Uso:
  python -m ingestao.rfb.seed_cnpj_priority
  python -m ingestao.rfb.seed_cnpj_priority --limit 50   # só os 50 maiores
"""
from __future__ import annotations

import argparse
import logging
import os
import re
import sys
import time
from collections import defaultdict
from pathlib import Path

from dotenv import load_dotenv

load_dotenv(Path(__file__).parents[2] / ".env")
sys.path.insert(0, str(Path(__file__).parents[2]))

from ingestao.rfb.cnpj_connector import _build_session, lookup_cnpj_brasilapi

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s — %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("seed_priority")

EXCLUIR_NOMES = ["fundo", "estado ", "municipio", "prefeitura", "secretaria", "ministerio", "governo"]
RATE_LIMIT_DELAY = 2.1  # segundos entre requisições (~28 req/min, abaixo do limite de 30)
BATCH_UPSERT = 50


def get_priority_cnpjs(sb, limit: int) -> list[tuple[str, str]]:
    """Retorna lista (cnpj, nome) ordenada por n_autores desc, valor desc."""
    r = sb.table("emendas_favorecidos").select(
        "codigo_favorecido,favorecido,valor_recebido,nome_autor"
    ).execute()

    totais: dict[str, dict] = defaultdict(lambda: {"total": 0, "nome": "", "autores": set()})
    for row in r.data:
        cnpj = re.sub(r"\D", "", row.get("codigo_favorecido") or "")
        if len(cnpj) != 14:
            continue
        nome = row.get("favorecido", "").strip()
        if any(ex in nome.lower() for ex in EXCLUIR_NOMES):
            continue
        totais[cnpj]["total"] += row.get("valor_recebido", 0) or 0
        totais[cnpj]["nome"] = nome
        totais[cnpj]["autores"].add(row.get("nome_autor", ""))

    ranked = sorted(
        totais.items(),
        key=lambda x: (len(x[1]["autores"]), x[1]["total"]),
        reverse=True,
    )[:limit]

    return [(cnpj, d["nome"]) for cnpj, d in ranked]


def upsert_empresa(sb, data: dict) -> None:
    """Upsert de um único CNPJ enriquecido via BrasilAPI."""
    cnpj14 = re.sub(r"\D", "", data.get("cnpj", ""))
    if not cnpj14:
        return
    cnpj_basico = cnpj14[:8]

    capital = data.get("capital_social")
    nat = data.get("natureza_juridica")
    if isinstance(nat, dict):
        nat = nat.get("descricao")
    porte = data.get("porte")
    if isinstance(porte, dict):
        porte = porte.get("descricao")
    payload = {
        "cnpj_basico": cnpj_basico,
        "razao_social": data.get("razao_social"),
        "natureza_juridica": nat,
        "capital_social": str(capital) if capital is not None else None,
        "porte_empresa": porte,
    }
    sb.table("cnpj_empresas").upsert(payload, on_conflict="cnpj_basico").execute()

    # Sócios (QSA)
    qsa = data.get("qsa") or []
    if qsa:
        socios_payload = []
        for s in qsa:
            cpf_cnpj = re.sub(r"\D", "", s.get("cnpj_cpf_do_socio") or "")
            qual = s.get("qualificacao_socio")
            if isinstance(qual, dict):
                qual = qual.get("descricao")
            faixa = s.get("faixa_etaria")
            if isinstance(faixa, dict):
                faixa = faixa.get("descricao")
            socios_payload.append({
                "cnpj_basico": cnpj_basico,
                "identificador": str(s.get("identificador_de_socio", "")),
                "nome_socio": s.get("nome_socio_ou_razao_social"),
                "nome_norm": (s.get("nome_socio_ou_razao_social") or "").upper().strip(),
                "cpf_cnpj_socio": cpf_cnpj,
                "qualificacao": qual,
                "data_entrada": s.get("data_entrada_sociedade") or None,
                "faixa_etaria": faixa,
            })
        if socios_payload:
            # cnpj_socios não tem constraint UNIQUE declarada — usa insert ignorando duplicatas
            try:
                sb.table("cnpj_socios").insert(
                    socios_payload, returning="minimal"
                ).execute()
            except Exception:
                # Em caso de conflito de chave, insere um a um ignorando erros
                for s in socios_payload:
                    try:
                        sb.table("cnpj_socios").insert(s, returning="minimal").execute()
                    except Exception:
                        pass


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--limit", type=int, default=200, help="Nº de CNPJs a enriquecer")
    args = parser.parse_args()

    from supabase import create_client
    sb = create_client(os.environ["SUPABASE_URL"], os.environ["SUPABASE_SERVICE_ROLE_KEY"])
    session = _build_session()

    targets = get_priority_cnpjs(sb, args.limit)
    logger.info("Iniciando seed prioritário: %d CNPJs via BrasilAPI", len(targets))

    ok = err = skip = 0
    for i, (cnpj, nome) in enumerate(targets, 1):
        for attempt in range(3):
            try:
                data = lookup_cnpj_brasilapi(cnpj, session)
                if data:
                    upsert_empresa(sb, data)
                    ok += 1
                    logger.info("[%d/%d] ✓ %s — %s", i, len(targets), cnpj, nome[:50])
                else:
                    skip += 1
                    logger.warning("[%d/%d] ✗ sem dados: %s — %s", i, len(targets), cnpj, nome[:50])
                break
            except Exception as e:
                if attempt < 2:
                    logger.warning("[%d/%d] retry %d após erro: %s", i, len(targets), attempt + 1, e)
                    time.sleep(5)
                    session = _build_session()  # reconecta
                else:
                    err += 1
                    logger.error("[%d/%d] ✗ falhou 3x: %s — %s", i, len(targets), cnpj, e)

        time.sleep(RATE_LIMIT_DELAY)

    logger.info("Concluído — ok=%d  sem_dados=%d  erro=%d", ok, skip, err)


if __name__ == "__main__":
    main()
