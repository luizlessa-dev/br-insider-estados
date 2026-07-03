"""
Conector: Compliance dos Sócios (PF) — extensão do Subradar B2B

Fluxo:
  1. Busca CPFs dos sócios na tabela cnpj_socios (QSA RFB)
  2. Para cada sócio com CPF válido, consulta fontes compatíveis com PF:
       - CEIS / CNEP (tabelas locais — já indexam CPF)
       - Lista Suja MTE (tabela local — já indexa CPF)
       - Dívida Ativa PGFN PF (tabela local)
       - OFAC, ONU, UE, UK (busca por nome — já implementadas)
       - BigDataCorp /peoplev2 (processos PF + score, se BIGDATA_CORP_TOKEN)
  3. Retorna alertas linkados ao CNPJ da empresa, com nome do sócio identificado

Não executa Direct Data por CPF (custo alto, ~R$ 15-20/sócio) — reservado para
modo avulsa via SociosComplianceAvulsaConnector.

LGPD: consulta feita no contexto de due diligence empresarial (art. 7º, IX —
interesse legítimo do contratante em verificar idoneidade dos sócios).
"""
from __future__ import annotations

import logging
import os
import re
import time
from typing import Any

import requests

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual, \
    SUPABASE_URL, SUPABASE_KEY, _supabase_headers

logger = logging.getLogger("subradar.socios_compliance")

BDC_TOKEN = os.environ.get("BIGDATA_CORP_TOKEN", "")
_BDC_PF_URL = "https://bigboost.bigdatacorp.com.br/peoplev2"

# Máximo de sócios PF a consultar por empresa (evita explodir o número de chamadas)
_MAX_SOCIOS = 5


def _strip(doc: str) -> str:
    return re.sub(r"\D", "", str(doc or ""))


def _fmt_cpf(cpf: str) -> str:
    c = _strip(cpf)
    return f"{c[:3]}.{c[3:6]}.{c[6:9]}-{c[9:11]}" if len(c) == 11 else cpf


def _supabase_get(table: str, params: dict) -> list[dict]:
    if not SUPABASE_URL or not SUPABASE_KEY:
        return []
    try:
        r = requests.get(
            f"{SUPABASE_URL}/rest/v1/{table}",
            params=params,
            headers=_supabase_headers(),
            timeout=15,
        )
        return r.json() if r.ok and isinstance(r.json(), list) else []
    except Exception as e:
        logger.debug("supabase %s query error: %s", table, e)
        return []


# ---------------------------------------------------------------------------
# Busca de sócios
# ---------------------------------------------------------------------------

def _get_socios_pf(cnpj_digits: str) -> list[dict]:
    """Retorna lista de {'nome': ..., 'cpf': ..., 'qualificacao': ...} do QSA."""
    cnpj_basico = cnpj_digits[:8]
    rows = _supabase_get("cnpj_socios", {
        "cnpj_basico": f"eq.{cnpj_basico}",
        "select": "nome_socio,cpf_cnpj_socio,qualificacao_socio",
        "limit": 20,
    })
    socios = []
    for r in rows:
        cpf = _strip(r.get("cpf_cnpj_socio", ""))
        if len(cpf) == 11:  # só PF
            socios.append({
                "nome": (r.get("nome_socio") or "").strip(),
                "cpf": cpf,
                "qualificacao": r.get("qualificacao_socio", ""),
            })
    return socios[:_MAX_SOCIOS]


# ---------------------------------------------------------------------------
# Consultas por CPF — fontes locais
# ---------------------------------------------------------------------------

def _check_ceis_cnep(cpf: str) -> list[dict]:
    alertas = []
    for table, label in [("sub_ceis", "CEIS"), ("sub_cnep", "CNEP")]:
        rows = _supabase_get(table, {"cnpj_cpf": f"eq.{cpf}", "limit": 10})
        for row in rows:
            alertas.append({
                "fonte_pf": label,
                "severidade": "critico",
                "detalhe": f"{label} — {row.get('nome_razao_social', '')} | "
                           f"Sanção: {row.get('tipo_sancao') or row.get('descricao_tipo_sancao', '')} | "
                           f"Órgão: {row.get('orgao_sancionador', '')}",
            })
    return alertas


def _check_lista_suja(cpf: str) -> list[dict]:
    rows = _supabase_get("sub_lista_suja", {"cpf_cnpj": f"eq.{cpf}", "limit": 5})
    return [{
        "fonte_pf": "lista_suja_mte",
        "severidade": "critico",
        "detalhe": f"Lista Suja MTE — trabalho escravo | "
                   f"{r.get('nome', '')} | {r.get('uf', '')} | {r.get('ano_acao_fiscal', '')}",
    } for r in rows]


def _check_divida_ativa_pf(cpf: str) -> list[dict]:
    rows = _supabase_get("sub_divida_ativa", {"cpf_cnpj": f"eq.{cpf}", "limit": 10})
    total = sum(float(str(r.get("valor_consolidado") or 0).replace(",", ".") or 0) for r in rows)
    if not rows:
        return []
    return [{
        "fonte_pf": "pgfn_divida_ativa",
        "severidade": "critico" if total > 50_000 else "atencao",
        "detalhe": f"PGFN dívida ativa PF — {len(rows)} inscrição(ões)"
                   + (f" | Valor total: R$ {total:,.2f}" if total else ""),
    }]


# ---------------------------------------------------------------------------
# Consulta BigDataCorp /peoplev2 (processos PF)
# ---------------------------------------------------------------------------

def _check_bdc_pf(cpf: str) -> list[dict]:
    if not BDC_TOKEN:
        return []
    try:
        resp = requests.post(
            _BDC_PF_URL,
            json={
                "Datasets": "processes,kyc",
                "q": f"doc{{{cpf}}}",
                "Limit": 1,
            },
            headers={
                "accept": "application/json",
                "content-type": "application/json",
                "AccessToken": BDC_TOKEN,
            },
            timeout=30,
        )
        if not resp.ok:
            logger.debug("BigDataCorp PF: HTTP %d para CPF %s***", resp.status_code, cpf[:3])
            return []
        result = (resp.json().get("Result") or [{}])[0]
    except Exception as e:
        logger.debug("BigDataCorp PF: %s", e)
        return []

    alertas = []

    # Processos judiciais
    processos = result.get("Processes") or result.get("Lawsuits") or {}
    total_proc = processos.get("TotalLawsuits") or processos.get("Total") or 0
    if total_proc:
        alertas.append({
            "fonte_pf": "bigdatacorp_processos_pf",
            "severidade": "atencao",
            "detalhe": f"BigDataCorp — {total_proc} processo(s) judicial(is) em nome do sócio",
        })

    return alertas


# ---------------------------------------------------------------------------
# Busca por nome em listas internacionais
# ---------------------------------------------------------------------------

def _normalize_nome(nome: str) -> str:
    return re.sub(r"[^A-Z0-9]", "", nome.upper())


def _check_sancoes_internacionais(nome: str) -> list[dict]:
    """Busca nome do sócio nas listas já carregadas em memória (OFAC, ONU, UE, UK)."""
    alertas = []
    nome_key = f"NAME:{_normalize_nome(nome)}"

    # OFAC
    try:
        from .ofac import _load_ofac
        idx = _load_ofac()
        if idx.get(nome_key):
            alertas.append({
                "fonte_pf": "ofac",
                "severidade": "critico",
                "detalhe": f"OFAC SDN — sócio '{nome}' encontrado na lista de sanções dos EUA",
            })
    except Exception:
        pass

    # UN
    try:
        from .un_sanctions import _load_un
        idx = _load_un()
        if idx.get(nome_key):
            alertas.append({
                "fonte_pf": "un_sanctions",
                "severidade": "critico",
                "detalhe": f"ONU — sócio '{nome}' encontrado na lista consolidada da ONU",
            })
    except Exception:
        pass

    # UK
    try:
        from .uk_sanctions import _load_uk
        idx = _load_uk()
        if idx.get(nome_key):
            alertas.append({
                "fonte_pf": "uk_sanctions",
                "severidade": "critico",
                "detalhe": f"UK Sanctions — sócio '{nome}' encontrado na lista britânica",
            })
    except Exception:
        pass

    # EU
    try:
        from .eu_sanctions import _load_eu
        idx = _load_eu()
        if idx.get(nome_key):
            alertas.append({
                "fonte_pf": "eu_sanctions",
                "severidade": "critico",
                "detalhe": f"EU Sanctions — sócio '{nome}' encontrado na lista europeia",
            })
    except Exception:
        pass

    return alertas


# ---------------------------------------------------------------------------
# Conector principal
# ---------------------------------------------------------------------------

class SociosComplianceConnector(SubradarSource):
    """
    Monitoramento: consulta CPFs dos sócios contra fontes PF gratuitas.
    Inclui: CEIS/CNEP, Lista Suja, PGFN PF, sanções internacionais por nome,
    BigDataCorp /peoplev2 (se token disponível).
    """
    fonte = "socios_compliance"
    request_delay = 0.5

    def consultar_cnpj(self, cnpj: str, **_) -> list[dict]:
        cnpj_digits = _strip(cnpj)
        cnpj_fmt = f"{cnpj_digits[:2]}.{cnpj_digits[2:5]}.{cnpj_digits[5:8]}/{cnpj_digits[8:12]}-{cnpj_digits[12:14]}"
        ciclo = _ciclo_atual()

        socios = _get_socios_pf(cnpj_digits)
        if not socios:
            logger.debug("socios_compliance: nenhum sócio PF encontrado para %s", cnpj_fmt)
            return []

        logger.info("socios_compliance: %d sócio(s) PF em %s", len(socios), cnpj_fmt)

        todos_alertas = []
        snapshot_dados = []

        for socio in socios:
            cpf = socio["cpf"]
            nome = socio["nome"]
            achados: list[dict] = []

            achados.extend(_check_ceis_cnep(cpf))
            achados.extend(_check_lista_suja(cpf))
            achados.extend(_check_divida_ativa_pf(cpf))
            achados.extend(_check_sancoes_internacionais(nome))
            achados.extend(_check_bdc_pf(cpf))

            if achados:
                snapshot_dados.append({"socio": nome, "cpf_hash": cpf[:3] + "***", "achados": achados})

            for achado in achados:
                todos_alertas.append({
                    "cnpj": cnpj_fmt,
                    "ciclo": ciclo,
                    "fonte": self.fonte,
                    "categoria": "societario",
                    "severidade": achado["severidade"],
                    "titulo": f"Sócio {nome} — {achado['fonte_pf'].upper().replace('_', ' ')}",
                    "descricao": achado["detalhe"],
                    "url_fonte": "https://www.gov.br/cgu/pt-br/assuntos/responsabilizacao-de-empresas",
                    "is_novo": True,
                })

        if not todos_alertas:
            return []

        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, snapshot_dados)
        if not mudou:
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt,
            "fonte": self.fonte,
            "ciclo": ciclo,
            "hash_dados": hash_novo,
            "dados": {"socios_com_alertas": snapshot_dados},
        }])

        return todos_alertas
