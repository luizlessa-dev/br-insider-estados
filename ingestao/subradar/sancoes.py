"""
Conector: Sanções Administrativas — CEIS, CNEP e CEPIM (tabelas locais)

Consulta as tabelas sub_ceis, sub_cnep e sub_cepim que são alimentadas
mensalmente pelo sancoes_seeder.py. Lookup local por CNPJ — sem chamada
à API do Portal Transparência em tempo de execução.

  CEIS  — Cadastro de Empresas Inidôneas e Suspensas
  CNEP  — Cadastro Nacional de Empresas Punidas (Lei Anticorrupção 12.846/2013)
  CEPIM — Cadastro de Entidades Privadas Sem Fins Lucrativos Impedidas

Seeder: python3 -m ingestao.subradar.sancoes_seeder  (rodar mensalmente)
"""
from __future__ import annotations

import logging
import re
from datetime import date

import requests

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual, \
    SUPABASE_URL, SUPABASE_KEY, _supabase_headers

logger = logging.getLogger("subradar.sancoes")


def _strip_cnpj(cnpj: str) -> str:
    return re.sub(r"\D", "", cnpj)


def _fmt_cnpj(cnpj: str) -> str:
    c = _strip_cnpj(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _sancao_ativa(data_fim: str | None) -> bool:
    if not data_fim:
        return True
    return data_fim >= date.today().isoformat()


def _query_local(table: str, cnpj_digits: str) -> list[dict]:
    """Busca registros por CNPJ na tabela local."""
    if not SUPABASE_URL or not SUPABASE_KEY:
        return []
    # Ambas as colunas de CNPJ (cnpj_cpf e cnpj) armazenam só dígitos
    col = "cnpj" if table == "sub_cepim" else "cnpj_cpf"
    try:
        r = requests.get(
            f"{SUPABASE_URL}/rest/v1/{table}",
            params={col: f"eq.{cnpj_digits}", "limit": 100},
            headers=_supabase_headers(),
            timeout=15,
        )
        return r.json() if r.ok and isinstance(r.json(), list) else []
    except Exception as e:
        logger.warning("%s query falhou: %s", table, e)
        return []


class CEISConnector(SubradarSource):
    fonte = "ceis"
    base_url = SUPABASE_URL or ""

    def consultar_cnpj(self, cnpj: str) -> list[dict]:
        cnpj_digits = _strip_cnpj(cnpj)
        cnpj_fmt = _fmt_cnpj(cnpj_digits)
        ciclo = _ciclo_atual()

        registros = _query_local("sub_ceis", cnpj_digits)

        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, registros)
        if not mudou:
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt, "fonte": self.fonte, "ciclo": ciclo,
            "hash_dados": hash_novo, "dados": {"total": len(registros)},
        }])

        if not registros:
            return [{
                "cnpj": cnpj_fmt, "ciclo": ciclo, "fonte": self.fonte,
                "categoria": "sancao", "severidade": "ok",
                "titulo": "Sem registros no CEIS",
                "descricao": "CNPJ não encontrado no Cadastro de Empresas Inidôneas e Suspensas.",
                "is_novo": True,
            }]

        alertas = []
        for r in registros:
            ativo = _sancao_ativa(r.get("data_fim"))
            tipo = r.get("tipo_sancao") or "Sanção"
            orgao = r.get("orgao_sancionador") or "N/D"
            esfera = r.get("esfera") or ""
            inicio = r.get("data_inicio") or ""
            fim = r.get("data_fim") or "indeterminado"
            processo = r.get("numero_processo") or ""
            fundamentacao = r.get("fundamentacao") or ""

            alertas.append({
                "cnpj": cnpj_fmt, "ciclo": ciclo, "fonte": self.fonte,
                "categoria": "sancao",
                "severidade": "critico" if ativo else "atencao",
                "titulo": f"CEIS — {tipo}" + (" [ATIVO]" if ativo else " [EXPIRADO]"),
                "descricao": (
                    f"Sanção aplicada por {orgao} ({esfera}). "
                    f"Tipo: {tipo}. "
                    f"Vigência: {inicio} a {fim}. "
                    + (f"Processo: {processo}. " if processo else "")
                    + (f"Base legal: {fundamentacao}." if fundamentacao else "")
                ),
                "contraparte": orgao,
                "referencia_id": str(r.get("id", "")),
                "data_evento": inicio or None,
                "url_fonte": "https://www.portaldatransparencia.gov.br/sancoes/ceis",
                "is_novo": True,
            })

        logger.info("CEIS: %d alertas para %s", len(alertas), cnpj_fmt)
        return alertas


class CNEPConnector(SubradarSource):
    fonte = "cnep"
    base_url = SUPABASE_URL or ""

    def consultar_cnpj(self, cnpj: str) -> list[dict]:
        cnpj_digits = _strip_cnpj(cnpj)
        cnpj_fmt = _fmt_cnpj(cnpj_digits)
        ciclo = _ciclo_atual()

        registros = _query_local("sub_cnep", cnpj_digits)

        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, registros)
        if not mudou:
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt, "fonte": self.fonte, "ciclo": ciclo,
            "hash_dados": hash_novo, "dados": {"total": len(registros)},
        }])

        if not registros:
            return [{
                "cnpj": cnpj_fmt, "ciclo": ciclo, "fonte": self.fonte,
                "categoria": "sancao", "severidade": "ok",
                "titulo": "Sem registros no CNEP",
                "descricao": "CNPJ não encontrado no Cadastro Nacional de Empresas Punidas (Lei Anticorrupção).",
                "is_novo": True,
            }]

        alertas = []
        for r in registros:
            tipo = r.get("tipo_sancao") or "Sanção"
            orgao = r.get("orgao_sancionador") or "N/D"
            esfera = r.get("esfera") or ""
            inicio = r.get("data_inicio") or ""
            fim = r.get("data_fim") or "indeterminado"
            processo = r.get("numero_processo") or ""

            # CNEP = Lei Anticorrupção — sempre crítico independente de prazo
            alertas.append({
                "cnpj": cnpj_fmt, "ciclo": ciclo, "fonte": self.fonte,
                "categoria": "sancao", "severidade": "critico",
                "titulo": f"CNEP — Lei Anticorrupção — {tipo}",
                "descricao": (
                    f"Empresa punida pela Lei Anticorrupção (12.846/2013) por {orgao} ({esfera}). "
                    f"Tipo: {tipo}. "
                    f"Vigência: {inicio} a {fim}. "
                    + (f"Processo: {processo}." if processo else "")
                ),
                "contraparte": orgao,
                "referencia_id": str(r.get("id", "")),
                "data_evento": inicio or None,
                "url_fonte": "https://www.portaldatransparencia.gov.br/sancoes/cnep",
                "is_novo": True,
            })

        logger.info("CNEP: %d alertas para %s", len(alertas), cnpj_fmt)
        return alertas


class CEPIMConnector(SubradarSource):
    fonte = "cepim"
    base_url = SUPABASE_URL or ""

    def consultar_cnpj(self, cnpj: str) -> list[dict]:
        cnpj_digits = _strip_cnpj(cnpj)
        cnpj_fmt = _fmt_cnpj(cnpj_digits)
        ciclo = _ciclo_atual()

        registros = _query_local("sub_cepim", cnpj_digits)

        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, registros)
        if not mudou:
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt, "fonte": self.fonte, "ciclo": ciclo,
            "hash_dados": hash_novo, "dados": {"total": len(registros)},
        }])

        if not registros:
            return [{
                "cnpj": cnpj_fmt, "ciclo": ciclo, "fonte": self.fonte,
                "categoria": "sancao", "severidade": "ok",
                "titulo": "Sem registros no CEPIM",
                "descricao": "Entidade não encontrada no Cadastro de Entidades Privadas Impedidas (CEPIM).",
                "is_novo": True,
            }]

        alertas = []
        for r in registros:
            motivo = r.get("motivo") or "N/D"
            orgao = r.get("orgao_superior") or "N/D"
            convenio = r.get("num_convenio") or ""
            data_ref = r.get("data_referencia") or ""

            alertas.append({
                "cnpj": cnpj_fmt, "ciclo": ciclo, "fonte": self.fonte,
                "categoria": "sancao", "severidade": "critico",
                "titulo": "CEPIM — Entidade impedida de receber convênios federais",
                "descricao": (
                    f"Entidade impedida de celebrar convênios com {orgao}. "
                    f"Motivo: {motivo}. "
                    + (f"Convênio: {convenio}. " if convenio else "")
                    + (f"Referência: {data_ref}." if data_ref else "")
                ),
                "contraparte": orgao,
                "referencia_id": str(r.get("id", "")),
                "data_evento": data_ref or None,
                "url_fonte": "https://www.portaldatransparencia.gov.br/sancoes/cepim",
                "is_novo": True,
            })

        logger.info("CEPIM: %d alertas para %s", len(alertas), cnpj_fmt)
        return alertas
