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

# Dataset ID novo (mudou em 2024; URL antiga retorna 404)
_ANTT_DATASET_ID = "c7edbb2b-a6ea-49d9-b807-0db8f336022b"
_ANTT_CKAN = f"https://dados.antt.gov.br/api/3/action/package_show?id={_ANTT_DATASET_ID}"

# Fallbacks hardcoded — atualizados jun/2026
# Estrutura: razao_social;cnpj;numero_tar;vigencia
_ANTT_CSV_FALLBACKS = [
    # Transporte regular (maior base, ~50k empresas)
    "https://dados.antt.gov.br/dataset/c7edbb2b-a6ea-49d9-b807-0db8f336022b/resource/34732a04-28a9-4a21-9a87-fa98a4017b9f/download/empresas_habilitadas_regular.csv",
    # Fretamento (complementar)
    "https://dados.antt.gov.br/dataset/c7edbb2b-a6ea-49d9-b807-0db8f336022b/resource/9b922503-b676-48dd-bc9a-49c20b37027e/download/empresas_habilitadas_fretamento_06_2023.csv",
]

# Cache global do CSV (carregado uma vez por execução)
_cache: dict[str, dict] | None = None
_cache_ts: float = 0.0
_CACHE_TTL = 3600 * 12  # 12h


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", str(cnpj or ""))


def _fmt(cnpj: str) -> str:
    c = _strip(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _descobrir_urls_antt() -> list[str]:
    """Tenta descobrir URLs atuais via CKAN API; usa fallbacks se falhar."""
    try:
        r = requests.get(_ANTT_CKAN, timeout=15, headers={
            "User-Agent": "Subradar/1.0 (dados-publicos; contato@subradar.com.br)"
        })
        if r.ok:
            resources = r.json().get("result", {}).get("resources", [])
            urls = [
                res["url"] for res in resources
                if res.get("url", "").endswith(".csv") and "habilitad" in res.get("url", "").lower()
            ]
            if urls:
                return urls
    except Exception:
        pass
    return _ANTT_CSV_FALLBACKS


def _parse_antt_csv(content: str, index: dict) -> int:
    """Parseia um CSV ANTT e adiciona entradas ao index. Retorna linhas adicionadas."""
    lines = content.splitlines()
    if not lines:
        return 0
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

    added = 0
    for line in lines[1:]:
        row = line.split(sep)
        cnpj_raw = col(row, "cnpj", "nr_cnpj", "nu_cnpj")
        if not cnpj_raw:
            continue
        cnpj_digits = _strip(cnpj_raw)
        if len(cnpj_digits) != 14:
            continue
        # Novo formato: razao_social;cnpj;numero_tar;vigencia
        # Antigo formato: razao_social;cnpj;regime;situacao;modalidade;validade
        index[cnpj_digits] = {
            "razao_social": col(row, "razao_social", "nm_empresa", "nome_empresa"),
            "regime":       col(row, "regime", "tipo_regime", "ds_regime"),
            "situacao":     col(row, "situacao", "ds_situacao", "situacao_habilitacao"),
            "modalidade":   col(row, "modalidade", "ds_modalidade"),
            "validade":     col(row, "validade", "vigencia", "dt_validade", "data_validade"),
            "numero_tar":   col(row, "numero_tar", "tar"),
        }
        added += 1
    return added


def _load_csv() -> dict[str, dict]:
    """Baixa e indexa os CSVs da ANTT por CNPJ (sem pontuação)."""
    global _cache, _cache_ts
    if _cache is not None and time.monotonic() - _cache_ts < _CACHE_TTL:
        return _cache

    urls = _descobrir_urls_antt()
    index: dict[str, dict] = {}

    for url in urls:
        logger.info("ANTT: baixando %s", url.split("/")[-1])
        try:
            resp = requests.get(url, timeout=60, headers={
                "User-Agent": "Subradar/1.0 (dados-publicos; contato@subradar.com.br)"
            })
            resp.raise_for_status()
            content = resp.content.decode("latin-1", errors="replace")
            added = _parse_antt_csv(content, index)
            logger.info("ANTT: +%d empresas de %s", added, url.split("/")[-1])
        except Exception as e:
            logger.error("ANTT: falha ao baixar/parsear %s: %s", url.split("/")[-1], e)
            continue

    _cache = index
    _cache_ts = time.monotonic()
    logger.info("ANTT: %d empresas indexadas no total", len(index))
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
        validade = empresa.get("validade", "")

        # Determina severidade pela situação da habilitação
        # Novo formato de CSV só tem vigência; se vazia = info
        situacoes_criticas = {"CANCELADA", "CASSADA", "REVOGADA", "SUSPENSA"}
        situacoes_atencao = {"IRREGULAR", "VENCIDA", "PENDENTE"}

        if any(s in situacao for s in situacoes_criticas):
            severidade = "critico"
            titulo = f"Habilitação ANTT {situacao.lower()}" + (f" — {regime}" if regime else "")
        elif any(s in situacao for s in situacoes_atencao):
            severidade = "atencao"
            titulo = f"Habilitação ANTT com pendência — {situacao.lower()}"
        else:
            # Empresa habilitada regularmente = info (confirma regularidade)
            severidade = "info"
            titulo = "Empresa habilitada ANTT" + (f" — {regime}" if regime else "") + (f" (válida até {validade})" if validade else "")

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
