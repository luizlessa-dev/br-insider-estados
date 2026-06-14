"""
Runner: MG SIAFI + Emendas + Sancionadas — The BR Insider

Uso:
  python -m ingestao.mg_fiscal.siafi_runner [--anos 2025,2026] [--dry-run]

Env vars:
  SUPABASE_URL
  SUPABASE_SERVICE_ROLE_KEY
"""
from __future__ import annotations

import argparse
import logging
import os
import sys
from datetime import datetime, date
from typing import Iterable

import uuid
import requests

from .siafi_connector import stream_execucao, ExecucaoSIAFI, ANOS_DISPONIVEIS
from .emendas_connector import stream_emendas, stream_execucao_pix, EmendaMG, ExecucaoPIX
from .sancionadas_connector import stream_sancionadas, EmpresaSancionadaMG

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(name)s %(levelname)s %(message)s",
)
logger = logging.getLogger("mg_siafi_runner")

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

    def write_siafi(self, records: Iterable[ExecucaoSIAFI]) -> int:
        buf, total = [], 0
        for r in records:
            buf.append({
                "id": r.id, "ano_exercicio": r.ano_exercicio,
                "unidade_orcamentaria_codigo": r.unidade_orcamentaria_codigo,
                "unidade_orcamentaria_nome": r.unidade_orcamentaria_nome,
                "orgao_codigo": r.orgao_codigo, "orgao_nome": r.orgao_nome,
                "funcao_codigo": r.funcao_codigo, "funcao_descricao": r.funcao_descricao,
                "subfuncao_codigo": r.subfuncao_codigo, "subfuncao_descricao": r.subfuncao_descricao,
                "programa_codigo": r.programa_codigo, "programa_descricao": r.programa_descricao,
                "acao_codigo": r.acao_codigo, "acao_descricao": r.acao_descricao,
                "elemento_despesa_codigo": r.elemento_despesa_codigo,
                "elemento_despesa_descricao": r.elemento_despesa_descricao,
                "fonte_recurso_codigo": r.fonte_recurso_codigo,
                "fonte_recurso_descricao": r.fonte_recurso_descricao,
                "numero_empenho": r.numero_empenho, "data_empenho": r.data_empenho,
                "razao_social_credor": r.razao_social_credor,
                "cnpj_cpf_credor": r.cnpj_cpf_credor,
                "valor_empenhado": r.valor_empenhado,
                "valor_liquidado": r.valor_liquidado,
                "valor_pago": r.valor_pago,
                "updated_at": datetime.utcnow().isoformat(),
            })
            if len(buf) >= CHUNK:
                total += self._upsert("mg_siafi_execucao", buf, "id")
                buf.clear()
                logger.info("mg_siafi_execucao: %d gravados…", total)
        if buf:
            total += self._upsert("mg_siafi_execucao", buf, "id")
        return total

    def _uuid(self, key: str) -> str:
        return str(uuid.uuid5(uuid.NAMESPACE_URL, f"mg_emendas:{key}"))

    def write_emendas(self, records: Iterable[EmendaMG]) -> int:
        # dedupe_key é coluna gerada pelo banco — não enviar; usar ignore-duplicates
        rows = [{"esfera": r.esfera, "modalidade": r.modalidade,
                 "autoria": r.autoria, "tipo_instrumento": r.tipo_instrumento,
                 "numero_emenda": r.numero_emenda, "ano": r.ano,
                 "codigo_siafi": r.codigo_siafi, "codigo_sigcon": r.codigo_sigcon,
                 "valor_indicado": r.valor_indicado, "valor_repassado": r.valor_repassado,
                 "objeto": r.objeto, "funcao_governo": r.funcao_governo,
                 "orgao_executor": r.orgao_executor} for r in records]
        return self._upsert("mg_emendas_federais", rows, "dedupe_key")

    def write_emendas_pix(self, records: Iterable[ExecucaoPIX]) -> int:
        rows = [{"id": r.id, "numero_emenda": r.numero_emenda, "ano": r.ano,
                 "cnpj_favorecido": r.cnpj_favorecido, "nome_favorecido": r.nome_favorecido,
                 "municipio": r.municipio, "valor_pago": r.valor_pago,
                 "data_pagamento": r.data_pagamento, "objeto": r.objeto,
                 "updated_at": datetime.utcnow().isoformat()} for r in records]
        return self._upsert("mg_emendas_pix", rows, "id")

    def write_sancionadas(self, records: Iterable[EmpresaSancionadaMG]) -> int:
        def _fmt_cnpj(v: str | None) -> str | None:
            if not v or len(v) != 14:
                return v
            return f"{v[:2]}.{v[2:5]}.{v[5:8]}/{v[8:12]}-{v[12:]}"
        seen: set[str] = set()
        rows = []
        for r in records:
            if not r.sei or r.sei in seen:
                continue
            seen.add(r.sei)
            rows.append({"sei": r.sei, "ano": r.ano,
                         "orgao_instaurador": r.orgao_instaurador, "orgao_lesado": r.orgao_lesado,
                         "empresa": r.empresa, "tipo_societario": r.tipo_societario,
                         "cnpj_norm": r.cnpj, "cnpj_fmt": _fmt_cnpj(r.cnpj),
                         "conduta": r.conduta, "data_publicacao_decisao": r.data_decisao,
                         "decisao": r.decisao, "fase": r.fase, "valor_multa": r.valor_multa,
                         })
        return self._upsert("mg_empresas_sancionadas", rows, "sei")


def main() -> None:
    parser = argparse.ArgumentParser(description="Ingestão MG SIAFI + Emendas + Sancionadas")
    default_anos = ",".join(str(a) for a in ANOS_DISPONIVEIS)
    parser.add_argument("--anos", default=default_anos, help="Anos separados por vírgula (default: todos disponíveis)")
    parser.add_argument("--dry-run", action="store_true", help="Baixa e parseia, não grava")
    parser.add_argument("--skip-siafi", action="store_true")
    parser.add_argument("--skip-emendas", action="store_true")
    parser.add_argument("--skip-sancionadas", action="store_true")
    args = parser.parse_args()

    anos = [int(a.strip()) for a in args.anos.split(",")]
    writer = None if args.dry_run else Writer()

    # ── SIAFI execução ────────────────────────────────────────────────────
    if not args.skip_siafi:
        for ano in anos:
            logger.info("=== SIAFI execução %d ===", ano)
            records = stream_execucao(ano)
            if args.dry_run:
                count = sum(1 for _ in records)
                logger.info("dry-run: %d registros SIAFI %d", count, ano)
            else:
                n = writer.write_siafi(records)
                logger.info("SIAFI %d: %d gravados", ano, n)

    # ── Emendas Federais MG ───────────────────────────────────────────────
    if not args.skip_emendas:
        logger.info("=== Emendas Federais MG ===")
        emendas = list(stream_emendas())
        pix = list(stream_execucao_pix())
        if args.dry_run:
            logger.info("dry-run: %d emendas, %d execucoes PIX", len(emendas), len(pix))
        else:
            n1 = writer.write_emendas(emendas)
            n2 = writer.write_emendas_pix(pix)
            logger.info("Emendas MG: %d cabeçalhos + %d PIX gravados", n1, n2)

    # ── Empresas Sancionadas ──────────────────────────────────────────────
    if not args.skip_sancionadas:
        logger.info("=== Empresas Sancionadas MG ===")
        sancionadas = list(stream_sancionadas())
        if args.dry_run:
            logger.info("dry-run: %d empresas sancionadas", len(sancionadas))
        else:
            n = writer.write_sancionadas(sancionadas)
            logger.info("Sancionadas MG: %d gravadas", n)

    logger.info("Concluído.")


if __name__ == "__main__":
    main()
