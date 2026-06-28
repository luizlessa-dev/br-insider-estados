"""
Conector: ANTT — Empresas Habilitadas para Transporte Rodoviário

Fonte: dados.antt.gov.br — dataset "Empresas Habilitadas"
Formato: CSV público, sem autenticação
Frequência: irregular (atualizado pela ANTT; última versão conhecida set/2022)

Alerta gerado quando:
  - CNPJ encontrado na base = empresa não habilitada ou com regime suspenso
  - CNPJ ausente na base (para clientes do setor de transporte) = risco de irregularidade

Nota: a ausência de um CNPJ na lista NÃO é necessariamente um alerta —
só é relevante quando o cliente atua em transporte interestadual/internacional.
"""
from __future__ import annotations

import io
import logging
import re
import time
from functools import lru_cache

import requests

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.antt")

ANTT_CSV_URL = "https://dados.antt.gov.br/dataset/3028a2b2-d6d3-4484-852d-d9e700c5b08c/resource/0a28c9b6-59f1-44ef-9987-a61afd85ba1a/download/empresas-habilitadas.csv"

# Cache global do CSV (carregado uma vez por execução)
_cache: dict[str, dict] | None = None
_cache_ts: float = 0.0
_CACHE_TTL = 3600 * 12  # 12h


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", str(cnpj or ""))


def _fmt(cnpj: str) -> str:
    c = _strip(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _load_csv() -> dict[str, dict]:
    """Baixa e indexa o CSV da ANTT por CNPJ (sem pontuação)."""
    global _cache, _cache_ts
    if _cache is not None and time.monotonic() - _cache_ts < _CACHE_TTL:
        return _cache

    logger.info("ANTT: baixando CSV de empresas habilitadas…")
    try:
        resp = requests.get(ANTT_CSV_URL, timeout=60, headers={
            "User-Agent": "Subradar/1.0 (dados-publicos; contato@subradar.com.br)"
        })
        resp.raise_for_status()
        # Tenta detectar encoding
        content = resp.content.decode("latin-1", errors="replace")
    except Exception as e:
        logger.error("ANTT: falha ao baixar CSV: %s", e)
        _cache = _cache or {}
        return _cache

    index: dict[str, dict] = {}
    lines = content.splitlines()
    if not lines:
        _cache = index
        _cache_ts = time.monotonic()
        return index

    # Detecta separador (;  ou ,)
    sep = ";" if ";" in lines[0] else ","
    header = [h.strip().lower() for h in lines[0].split(sep)]

    def col(row: list[str], *names: str) -> str:
        for n in names:
            try:
                idx = header.index(n)
                return row[idx].strip() if idx < len(row) else ""
            except ValueError:
                continue
        return ""

    for line in lines[1:]:
        row = line.split(sep)
        cnpj_raw = col(row, "cnpj", "nr_cnpj", "nu_cnpj")
        if not cnpj_raw:
            continue
        cnpj_digits = _strip(cnpj_raw)
        if len(cnpj_digits) != 14:
            continue
        index[cnpj_digits] = {
            "razao_social": col(row, "razao_social", "nm_empresa", "nome_empresa"),
            "regime": col(row, "regime", "tipo_regime", "ds_regime"),
            "situacao": col(row, "situacao", "ds_situacao", "situacao_habilitacao"),
            "modalidade": col(row, "modalidade", "ds_modalidade"),
            "validade": col(row, "validade", "dt_validade", "data_validade"),
        }

    _cache = index
    _cache_ts = time.monotonic()
    logger.info("ANTT: %d empresas indexadas", len(index))
    return index


class ANTTConnector(SubradarSource):
    fonte = "antt"
    request_delay = 0.0  # dados locais após cache

    def consultar_cnpj(self, cnpj: str) -> list[dict]:
        cnpj_digits = _strip(cnpj)
        cnpj_fmt = _fmt(cnpj_digits)
        ciclo = _ciclo_atual()

        base = _load_csv()
        empresa = base.get(cnpj_digits)

        if empresa is None:
            # Ausência = sem registro na ANTT (irrelevante para maioria dos CNPJs)
            return []

        situacao = empresa.get("situacao", "").upper()
        regime = empresa.get("regime", "")

        # Determina severidade pela situação da habilitação
        situacoes_criticas = {"CANCELADA", "CASSADA", "REVOGADA", "SUSPENSA"}
        situacoes_atencao = {"IRREGULAR", "VENCIDA", "PENDENTE"}

        if any(s in situacao for s in situacoes_criticas):
            severidade = "critico"
            titulo = f"Habilitação ANTT {situacao.lower()} — regime {regime}"
        elif any(s in situacao for s in situacoes_atencao):
            severidade = "atencao"
            titulo = f"Habilitação ANTT com pendência — {situacao.lower()}"
        else:
            # Empresa habilitada regularmente = info apenas
            severidade = "info"
            titulo = f"Empresa habilitada ANTT — regime {regime}"

        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, empresa)
        if not mudou:
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt,
            "fonte": self.fonte,
            "ciclo": ciclo,
            "hash_dados": hash_novo,
            "dados": empresa,
        }])

        validade = empresa.get("validade", "")
        descricao = (
            f"Empresa registrada na ANTT no regime '{regime}'. "
            f"Situação: {situacao or 'não informada'}."
            + (f" Validade: {validade}." if validade else "")
        )

        return [{
            "cnpj": cnpj_fmt,
            "ciclo": ciclo,
            "fonte": self.fonte,
            "categoria": "regulatorio",
            "severidade": severidade,
            "titulo": titulo,
            "descricao": descricao,
            "url_fonte": "https://dados.antt.gov.br/dataset/empresas-habilitadas",
            "is_novo": True,
        }]
