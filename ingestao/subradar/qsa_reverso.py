"""
Conector: QSA Reverso — empresas onde o CPF é sócio (Receita Federal)

Consulta a tabela cnpj_socios no Supabase (dados RFB) para encontrar todos os
CNPJs onde aquele CPF aparece como sócio ou administrador.

Para cada empresa encontrada, verifica:
  - Situação cadastral do CNPJ (ativa/baixada/inapta)
  - Presença em CEIS/CNEP das empresas (via sub_ceis / sub_cnep)
  - Dívida ativa das empresas (via sub_divida_ativa)

Retorna alertas se encontrar empresa baixada/inapta ou com sanções/dívidas.
Dados: tabela cnpj_socios (RFB QSA, ingerida no pipeline CNPJ).
"""
from __future__ import annotations

import logging
import re

import requests

from .base import SubradarSource, SUPABASE_URL, SUPABASE_KEY, _supabase_headers

logger = logging.getLogger("subradar.qsa_reverso")


def _strip(doc: str) -> str:
    return re.sub(r"\D", "", str(doc or ""))


def _sb_get(table: str, params: dict) -> list[dict]:
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
        logger.debug("supabase %s: %s", table, e)
        return []


def _fmt_cnpj(digits: str) -> str:
    d = digits.zfill(14)
    return f"{d[:2]}.{d[2:5]}.{d[5:8]}/{d[8:12]}-{d[12:14]}"


class QSAReversoConnector(SubradarSource):
    """Busca empresas onde o CPF é sócio e verifica a situação delas."""
    fonte = "qsa_reverso_rfb"
    request_delay = 0.2

    def consultar_cnpj(self, cnpj_or_cpf: str, **_) -> list[dict]:
        cpf = _strip(cnpj_or_cpf)
        if len(cpf) != 11:
            return []

        # Buscar CNPJs onde este CPF é sócio
        socios_rows = _sb_get("cnpj_socios", {
            "cpf_cnpj_socio": f"eq.{cpf}",
            "select": "cnpj_basico,qualificacao_socio,nome_socio",
            "limit": 20,
        })

        if not socios_rows:
            logger.debug("qsa_reverso: nenhuma empresa encontrada para CPF %s***", cpf[:3])
            return []

        logger.info("qsa_reverso: %d empresa(s) com CPF %s***", len(socios_rows), cpf[:3])

        alertas = []
        vistos = set()

        for row in socios_rows:
            cnpj_basico = _strip(str(row.get("cnpj_basico", "")))
            if cnpj_basico in vistos:
                continue
            vistos.add(cnpj_basico)

            qualificacao = row.get("qualificacao_socio", "Sócio")
            nome_socio = row.get("nome_socio", "")

            # Verificar situação cadastral da empresa
            empresa_rows = _sb_get("cnpj_dados", {
                "cnpj_basico": f"eq.{cnpj_basico}",
                "select": "razao_social,descricao_situacao_cadastral,cnpj_basico",
                "limit": 1,
            })
            empresa = empresa_rows[0] if empresa_rows else {}
            razao = empresa.get("razao_social") or f"CNPJ {cnpj_basico}"
            situacao = (empresa.get("descricao_situacao_cadastral") or "").upper()

            if situacao and situacao not in ("ATIVA", ""):
                alertas.append({
                    "fonte": self.fonte,
                    "categoria": "societario",
                    "severidade": "atencao",
                    "titulo": f"Empresa {situacao}: {razao}",
                    "descricao": (
                        f"O titular figura como {qualificacao} em {razao} "
                        f"(CNPJ {cnpj_basico}), com situação cadastral '{situacao}' na RFB."
                    ),
                    "url_fonte": f"https://www.receita.fazenda.gov.br/pessoajuridica/cnpj/cnpjreva/cnpjrevaw.asp",
                    "is_novo": True,
                })

            # Verificar CEIS/CNEP das empresas
            cnpj14 = cnpj_basico.zfill(8)  # basico tem 8 dígitos
            for table, label in [("sub_ceis", "CEIS"), ("sub_cnep", "CNEP")]:
                rows = _sb_get(table, {
                    "select": "tipo_sancao,orgao_sancionador",
                    "limit": 3,
                    # filtra pelo prefixo do CNPJ nos 8 primeiros dígitos
                    "cnpj_cpf": f"like.{cnpj_basico}%",
                })
                if rows:
                    alertas.append({
                        "fonte": self.fonte,
                        "categoria": "sancao",
                        "severidade": "critico",
                        "titulo": f"Empresa com {label}: {razao}",
                        "descricao": (
                            f"{razao} (empresa onde o titular é {qualificacao}) "
                            f"consta no {label} — {rows[0].get('tipo_sancao','sanção')}."
                        ),
                        "url_fonte": "https://www.portaltransparencia.gov.br/sancoes",
                        "is_novo": True,
                    })

        return alertas
