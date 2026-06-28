"""
Conector: JUCESP / RFB Fallback — Mudanças Societárias Relevantes

Fonte: Junta Comercial do Estado de São Paulo / RFB (QSA via sub_snapshots)
Acesso: Wrapper sobre snapshots internos — detecta mudanças comparando QSA atual vs anterior
Frequência: verificação a cada ciclo mensal

Alertas gerados:
  - Novo sócio com participação >25% (INFO / ATENÇÃO se CNPJ já com score alto)
  - Saída de sócio controlador (INFO / ATENÇÃO)
  - Mudança de endereço fiscal (INFO / ATENÇÃO)

Nota: requer dados societários previamente carregados em sub_snapshots (via SocietarioConnector).
"""
from __future__ import annotations

import logging
import re
import time

import requests

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual, SUPABASE_URL, SUPABASE_KEY, _supabase_headers

logger = logging.getLogger("subradar.jucesp")

_CACHE_TTL = 3600 * 6  # 6h

# Score mínimo para elevar para ATENÇÃO
_HIGH_SCORE_THRESHOLD = 40


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", str(cnpj or ""))


def _fmt(cnpj: str) -> str:
    c = _strip(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _buscar_snapshots_societarios(cnpj_fmt: str) -> list[dict]:
    """Busca os 2 últimos snapshots societários para comparação."""
    if not SUPABASE_URL or not SUPABASE_KEY:
        return []
    try:
        url = f"{SUPABASE_URL}/rest/v1/sub_snapshots"
        params = {
            "cnpj": f"eq.{cnpj_fmt}",
            "fonte": "eq.societario",
            "order": "created_at.desc",
            "limit": "2",
        }
        resp = requests.get(url, params=params, headers=_supabase_headers(), timeout=15)
        if not resp.ok:
            return []
        return resp.json()
    except Exception as e:
        logger.warning("JUCESP: erro ao buscar snapshots: %s", e)
        return []


def _buscar_score_dossie(cnpj_fmt: str, ciclo: str) -> int:
    """Busca o score atual do dossiê para o CNPJ."""
    if not SUPABASE_URL or not SUPABASE_KEY:
        return 0
    try:
        url = f"{SUPABASE_URL}/rest/v1/sub_dossies"
        params = {
            "cnpj": f"eq.{cnpj_fmt}",
            "ciclo": f"eq.{ciclo}",
            "select": "score_num",
            "limit": "1",
        }
        resp = requests.get(url, params=params, headers=_supabase_headers(), timeout=10)
        if not resp.ok:
            return 0
        rows = resp.json()
        return int(rows[0].get("score_num", 0)) if rows else 0
    except Exception:
        return 0


def _extrair_socios(dados: dict) -> list[dict]:
    """Extrai lista de sócios de um snapshot societário."""
    if not dados:
        return []
    qsa = dados.get("qsa") or dados.get("socios") or dados.get("quadro_societario") or []
    return qsa if isinstance(qsa, list) else []


def _extrair_endereco(dados: dict) -> str:
    """Extrai endereço fiscal de um snapshot societário."""
    if not dados:
        return ""
    end = dados.get("endereco") or dados.get("logradouro") or dados.get("endereço") or ""
    municipio = dados.get("municipio") or dados.get("cidade") or ""
    uf = dados.get("uf") or dados.get("estado") or ""
    return f"{end}, {municipio}/{uf}".strip(", ")


def _participacao_pct(socio: dict) -> float:
    """Extrai percentual de participação de um sócio."""
    pct_raw = (
        socio.get("percentual_capital_social") or
        socio.get("participacao") or
        socio.get("pct") or
        "0"
    )
    try:
        return float(str(pct_raw).replace(",", ".").replace("%", "").strip() or "0")
    except ValueError:
        return 0.0


class JUCESPConnector(SubradarSource):
    fonte = "jucesp"
    request_delay = 0.0

    def consultar_cnpj(self, cnpj: str) -> list[dict]:
        cnpj_digits = _strip(cnpj)
        cnpj_fmt = _fmt(cnpj_digits)
        ciclo = _ciclo_atual()

        # Busca snapshots societários (requer SocietarioConnector já executado)
        snapshots = _buscar_snapshots_societarios(cnpj_fmt)
        if len(snapshots) < 2:
            # Sem histórico suficiente para comparação
            return []

        atual = snapshots[0].get("dados") or {}
        anterior = snapshots[1].get("dados") or {}

        if not atual or not anterior:
            return []

        # Score atual para determinar severidade
        score = _buscar_score_dossie(cnpj_fmt, ciclo)
        severidade_base = "atencao" if score >= _HIGH_SCORE_THRESHOLD else "info"

        mudancas = []

        # 1. Detecta novos sócios com participação >25%
        socios_atual = {s.get("cnpj_cpf_do_socio", s.get("cpf_cnpj", s.get("nome", ""))): s for s in _extrair_socios(atual)}
        socios_anterior = {s.get("cnpj_cpf_do_socio", s.get("cpf_cnpj", s.get("nome", ""))): s for s in _extrair_socios(anterior)}

        for key, socio in socios_atual.items():
            if key and key not in socios_anterior:
                pct = _participacao_pct(socio)
                if pct > 25.0:
                    mudancas.append({
                        "tipo": "entrada_socio",
                        "descricao": (
                            f"Novo sócio com {pct:.1f}% de participação: "
                            f"{socio.get('nome_socio', socio.get('nome', key))}."
                        ),
                        "severidade": severidade_base,
                    })

        # 2. Detecta saída de sócio controlador
        for key, socio in socios_anterior.items():
            if key and key not in socios_atual:
                pct = _participacao_pct(socio)
                if pct > 25.0:
                    mudancas.append({
                        "tipo": "saida_socio_controlador",
                        "descricao": (
                            f"Saída de sócio com {pct:.1f}% de participação: "
                            f"{socio.get('nome_socio', socio.get('nome', key))}."
                        ),
                        "severidade": severidade_base,
                    })

        # 3. Detecta mudança de endereço fiscal
        end_atual = _extrair_endereco(atual)
        end_anterior = _extrair_endereco(anterior)
        if end_atual and end_anterior and end_atual != end_anterior:
            mudancas.append({
                "tipo": "mudanca_endereco",
                "descricao": f"Endereço fiscal alterado: '{end_anterior}' → '{end_atual}'.",
                "severidade": severidade_base,
            })

        if not mudancas:
            return []

        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, mudancas)
        if not mudou:
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt,
            "fonte": self.fonte,
            "ciclo": ciclo,
            "hash_dados": hash_novo,
            "dados": {"total": len(mudancas), "mudancas": mudancas},
        }])

        alertas = []
        for m in mudancas:
            alertas.append({
                "cnpj": cnpj_fmt,
                "ciclo": ciclo,
                "fonte": self.fonte,
                "categoria": "societario",
                "severidade": m["severidade"],
                "titulo": f"Mudança societária: {m['tipo'].replace('_', ' ').capitalize()}",
                "descricao": m["descricao"],
                "referencia_id": None,
                "url_fonte": "https://www.jucesp.sp.gov.br/",
                "is_novo": True,
            })

        logger.info("JUCESP: %d alertas para %s", len(alertas), cnpj_fmt)
        return alertas
