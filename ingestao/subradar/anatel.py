"""
Conector: ANATEL — Sanções Administrativas e Processos Sancionadores

Fontes:
  - Portal da Transparência ANATEL (dados.gov.br) — CSV de sanções
  - PADO (Processo Administrativo para Apuração de Descumprimento de Obrigações)

Formato: CSV/JSON via dados.gov.br
Acesso: público, sem autenticação

Alertas gerados:
  - Multa aplicada (ATENÇÃO)
  - Cassação de autorização/licença (CRÍTICO)
  - Suspensão de serviço (CRÍTICO)
  - Processo sancionador em andamento (INFO)
"""
from __future__ import annotations

import io
import logging
import re
import time

import requests

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.anatel")

# Dataset de sanções no dados.gov.br (ANATEL — Fiscalização)
ANATEL_SANCOES_URL = "https://www.dados.gov.br/api/publico/conjuntos-dados/sancoes-administrativas-anatel"
# URL direta do recurso CSV (fallback)
ANATEL_CSV_FALLBACK = "https://dados.gov.br/dataset/sancoes-anatel/resource/"

# Cache global
_cache: list[dict] | None = None
_cache_ts: float = 0.0
_CACHE_TTL = 3600 * 6  # 6h


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", str(cnpj or ""))


def _fmt(cnpj: str) -> str:
    c = _strip(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _fetch_recursos_dataset() -> list[str]:
    """Busca URLs dos recursos CSV no CKAN do dados.gov.br."""
    try:
        resp = requests.get(
            "https://dados.gov.br/api/3/action/package_show",
            params={"id": "sancoes-administrativas-anatel"},
            timeout=20,
            headers={"User-Agent": "Subradar/1.0"},
        )
        if not resp.ok:
            return []
        data = resp.json()
        resources = data.get("result", {}).get("resources", [])
        return [r["url"] for r in resources if r.get("format", "").upper() in ("CSV", "XLS", "XLSX")]
    except Exception as e:
        logger.warning("ANATEL: falha ao buscar recursos CKAN: %s", e)
        return []


def _load_sancoes() -> list[dict]:
    """Baixa e parseia o CSV de sanções da ANATEL."""
    global _cache, _cache_ts
    if _cache is not None and time.monotonic() - _cache_ts < _CACHE_TTL:
        return _cache

    urls = _fetch_recursos_dataset()
    if not urls:
        # Fallback: tenta URL conhecida
        urls = [
            "https://sistemas.anatel.gov.br/dadosabertos/transparencia/sancoes.csv",
        ]

    rows: list[dict] = []
    for url in urls[:2]:  # máximo 2 tentativas
        try:
            logger.info("ANATEL: baixando sanções de %s", url)
            resp = requests.get(url, timeout=60, headers={"User-Agent": "Subradar/1.0"})
            if not resp.ok:
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
                cnpj_raw = col(r, "cnpj", "nr_cnpj", "cpf_cnpj", "nu_cnpj")
                if not cnpj_raw:
                    continue
                cnpj_d = _strip(cnpj_raw)
                if len(cnpj_d) not in (11, 14):
                    continue
                rows.append({
                    "cnpj": cnpj_d,
                    "razao_social": col(r, "razao_social", "nome_empresa", "empresa"),
                    "tipo_sancao": col(r, "tipo_sancao", "tipo", "ds_tipo_sancao", "descricao_sancao"),
                    "valor_multa": col(r, "valor_multa", "vl_multa", "valor"),
                    "data_sancao": col(r, "data_sancao", "dt_sancao", "data"),
                    "situacao": col(r, "situacao", "ds_situacao", "status"),
                    "numero_processo": col(r, "numero_processo", "nr_processo", "processo"),
                    "servico": col(r, "servico", "ds_servico", "tipo_servico"),
                })
            if rows:
                break
        except Exception as e:
            logger.warning("ANATEL: erro ao processar %s: %s", url, e)
            continue

    _cache = rows
    _cache_ts = time.monotonic()
    logger.info("ANATEL: %d sanções indexadas", len(rows))
    return rows


class ANATELConnector(SubradarSource):
    fonte = "anatel"
    request_delay = 0.0

    def consultar_cnpj(self, cnpj: str) -> list[dict]:
        cnpj_digits = _strip(cnpj)
        cnpj_fmt = _fmt(cnpj_digits)
        ciclo = _ciclo_atual()

        sancoes = _load_sancoes()
        hits = [s for s in sancoes if s["cnpj"] == cnpj_digits]

        if not hits:
            return []

        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, hits)
        if not mudou:
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt,
            "fonte": self.fonte,
            "ciclo": ciclo,
            "hash_dados": hash_novo,
            "dados": {"total": len(hits), "sancoes": hits},
        }])

        alertas = []
        for s in hits:
            tipo = s.get("tipo_sancao", "").upper()
            situacao = s.get("situacao", "").upper()

            # Mapeamento de severidade
            if any(t in tipo for t in ("CASSAÇÃO", "CASSACAO", "REVOGAÇÃO", "REVOGACAO", "SUSPENSÃO", "SUSPENSAO")):
                severidade = "critico"
            elif any(t in tipo for t in ("MULTA",)):
                severidade = "atencao"
            else:
                severidade = "info"

            valor = s.get("valor_multa", "")
            valor_str = f" — R$ {valor}" if valor and valor != "0" else ""
            processo = s.get("numero_processo", "")

            alertas.append({
                "cnpj": cnpj_fmt,
                "ciclo": ciclo,
                "fonte": self.fonte,
                "categoria": "regulatorio",
                "severidade": severidade,
                "titulo": f"Sanção ANATEL: {s.get('tipo_sancao', 'penalidade')}{valor_str}",
                "descricao": (
                    f"Tipo: {s.get('tipo_sancao', 'N/I')}. "
                    f"Serviço: {s.get('servico', 'N/I')}. "
                    f"Data: {s.get('data_sancao', 'N/I')}. "
                    f"Situação: {s.get('situacao', 'N/I')}."
                    + (f" Processo: {processo}." if processo else "")
                ),
                "referencia_id": processo or None,
                "url_fonte": "https://www.gov.br/anatel/pt-br/acesso-a-informacao/sancoes-administrativas",
                "is_novo": True,
            })

        logger.info("ANATEL: %d alertas para %s", len(alertas), cnpj_fmt)
        return alertas
