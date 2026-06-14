"""
Runner: PBH Despesas Orçamentárias + CMBH — The BR Insider

Uso:
  python -m ingestao.pbh.pbh_runner [--anos 2024,2025,2026] [--dry-run] [--skip-cmbh]
"""
from __future__ import annotations

import argparse
import logging
import os
from datetime import datetime
from typing import Iterable

import requests

from .despesas_connector import (
    DespesaPBH, stream_pbh, stream_cmbh, ANOS_DISPONIVEIS,
)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(name)s %(levelname)s %(message)s",
)
logger = logging.getLogger("pbh_runner")

CHUNK = 500


class Writer:
    def __init__(self) -> None:
        url = os.environ.get("SUPABASE_URL", "").rstrip("/")
        key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY") or os.environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY", "")
        if not url or not key:
            raise RuntimeError("Faltando SUPABASE_URL e/ou SUPABASE_SERVICE_ROLE_KEY")
        self.url = url
        self.s = requests.Session()
        self.s.headers.update({
            "apikey": key,
            "Authorization": f"Bearer {key}",
            "Content-Type": "application/json",
            "Prefer": "resolution=merge-duplicates,return=minimal",
        })

    def _jsonable(self, v):
        from datetime import date, datetime
        if isinstance(v, (date, datetime)):
            return v.isoformat()
        return v

    def _upsert(self, table: str, rows: list[dict], on_conflict: str) -> int:
        rows = [{k: self._jsonable(v) for k, v in r.items()} for r in rows]
        total = 0
        for i in range(0, len(rows), CHUNK):
            chunk = rows[i:i + CHUNK]
            resp = self.s.post(
                f"{self.url}/rest/v1/{table}",
                params={"on_conflict": on_conflict},
                json=chunk,
                timeout=120,
            )
            if resp.status_code >= 300:
                logger.error("Upsert %s falhou (%d): %s", table, resp.status_code, resp.text[:300])
                raise RuntimeError(f"Upsert {table} falhou")
            total += len(chunk)
        return total

    def write_despesas(self, records: Iterable[DespesaPBH], log_prefix: str = "") -> int:
        buf, total = [], 0
        for r in records:
            buf.append({
                "id": r.id,
                "fonte": r.fonte,
                "ano_exercicio": r.ano_exercicio if r.ano_exercicio else None,
                "dt_movimento": r.dt_movimento,
                "unidade_orcamentaria": r.unidade_orcamentaria,
                "numero_empenho": r.numero_empenho,
                "funcao": r.funcao,
                "subfuncao": r.subfuncao,
                "programa": r.programa,
                "acao": r.acao,
                "elemento_despesa": r.elemento_despesa,
                "natureza_despesa": r.natureza_despesa,
                "nome_credor": r.nome_credor,
                "cnpj_cpf_credor": r.cnpj_cpf_credor,
                "modalidade_licitacao": r.modalidade_licitacao,
                "numero_licitacao": r.numero_licitacao,
                "numero_emenda": r.numero_emenda,
                "exercicio_emenda": r.exercicio_emenda,
                "vl_empenhado": r.vl_empenhado,
                "vl_liquidado": r.vl_liquidado,
                "vl_pago": r.vl_pago,
                "vl_liquidado_resto": r.vl_liquidado_resto,
                "vl_pago_resto": r.vl_pago_resto,
                "updated_at": datetime.utcnow().isoformat(),
            })
            if len(buf) >= CHUNK:
                total += self._upsert("pbh_despesas_orcamentarias", buf, "id")
                buf.clear()
                if total % 50_000 < CHUNK:
                    logger.info("%s %d gravados…", log_prefix, total)
        if buf:
            total += self._upsert("pbh_despesas_orcamentarias", buf, "id")
        return total


def main() -> None:
    parser = argparse.ArgumentParser(description="Ingestão PBH Despesas Orçamentárias")
    default_anos = ",".join(str(a) for a in ANOS_DISPONIVEIS)
    parser.add_argument("--anos", default=default_anos)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--skip-pbh", action="store_true")
    parser.add_argument("--skip-cmbh", action="store_true")
    args = parser.parse_args()

    anos = [int(a.strip()) for a in args.anos.split(",")]
    writer = None if args.dry_run else Writer()

    if not args.skip_pbh:
        for ano in sorted(anos):
            logger.info("=== PBH Despesas %d ===", ano)
            records = stream_pbh(ano)
            if args.dry_run:
                count = sum(1 for _ in records)
                logger.info("dry-run: %d registros PBH %d", count, ano)
            else:
                n = writer.write_despesas(records, log_prefix=f"PBH{ano}")
                logger.info("PBH %d: %d gravados", ano, n)

    if not args.skip_cmbh:
        logger.info("=== CMBH Despesas ===")
        records = stream_cmbh()
        if args.dry_run:
            count = sum(1 for _ in records)
            logger.info("dry-run: %d registros CMBH", count)
        else:
            n = writer.write_despesas(records, log_prefix="CMBH")
            logger.info("CMBH: %d gravados", n)

    logger.info("Concluído.")


if __name__ == "__main__":
    main()
