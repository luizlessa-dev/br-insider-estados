"""
Conector: SUSEP — Corretoras e Sociedades Irregulares

Fonte: SUSEP — Superintendência de Seguros Privados
URLs:
  - https://www.susep.gov.br/setores-susep/datapi/arquivos/Corretoras.csv
  - https://www.susep.gov.br/setores-susep/datapi/arquivos/Sociedades.csv
Formato: CSV público
Frequência: cache de 12h

Alertas gerados:
  - Autorização cassada/cancelada (CRÍTICO)
  - Autorização suspensa (ATENÇÃO)
"""
from __future__ import annotations

import csv
import io
import logging
import re
import time

import requests

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.susep")

SUSEP_URLS = [
    "https://www.susep.gov.br/setores-susep/datapi/arquivos/Corretoras.csv",
    "https://www.susep.gov.br/setores-susep/datapi/arquivos/Sociedades.csv",
]

_cache: dict[str, dict] | None = None  # cnpj_digits -> row
_cache_ts: float = 0.0
_CACHE_TTL = 3600 * 12  # 12h

# Termos que indicam irregularidade
_CRITICO_TERMS = ("CASSAD", "CANCELAD", "REVOGAD", "ENCERRAD", "LIQUIDAD")
_ATENCAO_TERMS = ("SUSPENS",)


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", str(cnpj or ""))


def _fmt(cnpj: str) -> str:
    c = _strip(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _is_irregular(status: str) -> tuple[bool, str]:
    """Retorna (é irregular, severidade)."""
    s = status.upper()
    if any(t in s for t in _CRITICO_TERMS):
        return True, "critico"
    if any(t in s for t in _ATENCAO_TERMS):
        return True, "atencao"
    return False, ""


def _load_susep() -> dict[str, dict]:
    global _cache, _cache_ts
    if _cache is not None and time.monotonic() - _cache_ts < _CACHE_TTL:
        return _cache

    index: dict[str, dict] = {}

    for url in SUSEP_URLS:
        tipo = "corretora" if "Corretoras" in url else "sociedade"
        try:
            logger.info("SUSEP: baixando %s (%s)", url, tipo)
            resp = requests.get(url, timeout=60, headers={"User-Agent": "Subradar/1.0"})
            if not resp.ok:
                logger.warning("SUSEP: %s retornou %s", url, resp.status_code)
                continue
            content = resp.content.decode("latin-1", errors="replace")
            lines = content.splitlines()
            if len(lines) < 2:
                continue

            sep = ";" if lines[0].count(";") > lines[0].count(",") else ","
            header = [h.strip().lower().replace(" ", "_") for h in lines[0].split(sep)]

            def col(r: list[str], *names: str) -> str:
                for n in names:
                    try:
                        return r[header.index(n)].strip()
                    except (ValueError, IndexError):
                        continue
                return ""

            for line in lines[1:]:
                r = line.split(sep)
                cnpj_raw = col(r, "cnpj", "nr_cnpj", "nu_cnpj", "cpf_cnpj")
                if not cnpj_raw:
                    continue
                cnpj_d = _strip(cnpj_raw)
                if len(cnpj_d) != 14:
                    continue

                status = col(r, "situacao", "status", "situacao_registro", "ds_situacao", "situacao_atual")
                nome = col(r, "razao_social", "nome", "nome_empresa", "empresa")
                codigo = col(r, "codigo", "nr_registro", "registro")

                index[cnpj_d] = {
                    "cnpj": cnpj_d,
                    "razao_social": nome,
                    "status": status,
                    "tipo": tipo,
                    "codigo_registro": codigo,
                }

        except Exception as e:
            logger.warning("SUSEP: erro ao processar %s: %s", url, e)
            continue

    _cache = index
    _cache_ts = time.monotonic()
    logger.info("SUSEP: %d registros indexados", len(index))
    return index


class SUSEPConnector(SubradarSource):
    fonte = "susep"
    request_delay = 0.0

    def consultar_cnpj(self, cnpj: str) -> list[dict]:
        cnpj_digits = _strip(cnpj)
        cnpj_fmt = _fmt(cnpj_digits)
        ciclo = _ciclo_atual()

        dados = _load_susep()
        row = dados.get(cnpj_digits)

        if not row:
            return []

        status = row.get("status", "")
        irregular, severidade = _is_irregular(status)

        if not irregular:
            return []

        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, row)
        if not mudou:
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt,
            "fonte": self.fonte,
            "ciclo": ciclo,
            "hash_dados": hash_novo,
            "dados": row,
        }])

        tipo = row.get("tipo", "N/I")
        codigo = row.get("codigo_registro", "")

        alerta = {
            "cnpj": cnpj_fmt,
            "ciclo": ciclo,
            "fonte": self.fonte,
            "categoria": "regulatorio",
            "severidade": severidade,
            "titulo": f"SUSEP — {tipo.capitalize()} com situação: {status}",
            "descricao": (
                f"Empresa registrada na SUSEP como {tipo} com situação irregular. "
                f"Status: {status}. "
                + (f"Código de registro: {codigo}." if codigo else "")
            ),
            "referencia_id": codigo or None,
            "url_fonte": "https://www.susep.gov.br/",
            "is_novo": True,
        }

        logger.info("SUSEP: 1 alerta para %s (status=%s)", cnpj_fmt, status)
        return [alerta]
