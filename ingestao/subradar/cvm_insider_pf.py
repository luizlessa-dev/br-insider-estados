"""
Conector: CVM — Processos Administrativos Sancionadores — Pessoa Física

Verifica se o CPF consta como acusado ou responsável em processos
administrativos sancionadores da Comissão de Valores Mobiliários (CVM).

Relevante para: diretores de fundos, analistas, gestores de renda variável,
insider trading, manipulação de mercado, administradores de companhias abertas.

Fonte de dados: tabela sub_cvm_pas (já populada pelo cvm_seeder.py).
O seeder armazena tanto CPF (PF) quanto CNPJ (PJ) no campo cpf_cnpj.

Sem acesso ao Supabase (SUPABASE_URL/KEY ausentes): gracioso.
"""
from __future__ import annotations

import logging
import os
import re

import requests

from .base import SubradarSource

logger = logging.getLogger("subradar.cvm_insider_pf")

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SUPABASE_KEY = (
    os.environ.get("SUPABASE_SERVICE_ROLE_KEY") or
    os.environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY") or ""
)


def _strip(doc: str) -> str:
    return re.sub(r"\D", "", str(doc or ""))


def _query_cvm_pas(cpf_digits: str) -> list[dict]:
    """Consulta sub_cvm_pas por CPF de 11 dígitos."""
    if not SUPABASE_URL or not SUPABASE_KEY:
        return []
    try:
        resp = requests.get(
            f"{SUPABASE_URL}/rest/v1/sub_cvm_pas",
            params={"cpf_cnpj": f"eq.{cpf_digits}"},
            headers={
                "apikey": SUPABASE_KEY,
                "Authorization": f"Bearer {SUPABASE_KEY}",
                "Accept": "application/json",
            },
            timeout=15,
        )
        if resp.ok and isinstance(resp.json(), list):
            return resp.json()
    except Exception as e:
        logger.debug("cvm_insider_pf: %s", e)
    return []


def _parse_date(s: str) -> str | None:
    if not s:
        return None
    for fmt in ("%d/%m/%Y", "%Y-%m-%d"):
        try:
            from datetime import datetime
            return datetime.strptime(s.strip(), fmt).date().isoformat()
        except ValueError:
            continue
    return None


class CVMInsiderPFConnector(SubradarSource):
    """
    Consulta PAS CVM por CPF via tabela local sub_cvm_pas.
    Gera alerta se o CPF constar como acusado em algum processo.
    Gracioso sem Supabase configurado.
    """
    fonte = "cvm_pas_pf"
    request_delay = 0.5

    def consultar_cnpj(self, cnpj_or_cpf: str, **_) -> list[dict]:
        cpf = _strip(cnpj_or_cpf)
        if len(cpf) != 11:
            return []

        cpf_fmt = f"{cpf[:3]}.{cpf[3:6]}.{cpf[6:9]}-{cpf[9:11]}"
        registros = _query_cvm_pas(cpf)

        if not registros:
            logger.debug("cvm_insider_pf: sem processos para CPF %s***", cpf[:3])
            return []

        alertas = []
        for r in registros:
            num_pas = r.get("num_pas") or ""
            fase = (r.get("des_fase") or "").strip()
            tipo_irr = (r.get("des_tipo_irregularidade") or "").strip()
            sancao = (r.get("des_sancao") or "").strip()
            val_multa = r.get("val_multa")
            dt_julg = r.get("dat_julgamento") or ""
            nome_ac = r.get("nom_acusado") or ""
            orgao = r.get("des_orgao_julgador") or "CVM"

            sancao_lower = sancao.lower()
            fase_lower = fase.lower()
            if any(k in sancao_lower for k in ("inabilitação", "proibição", "suspensão", "multa")):
                severidade = "critico"
            elif any(k in fase_lower for k in ("julgamento", "acusação", "citação")):
                severidade = "atencao"
            else:
                severidade = "info"

            multa_fmt = ""
            if val_multa:
                try:
                    multa_fmt = f" Multa: R$ {float(val_multa):,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")
                except Exception:
                    multa_fmt = f" Multa: {val_multa}"

            alertas.append({
                "fonte": self.fonte,
                "categoria": "mercado_capitais",
                "severidade": severidade,
                "titulo": f"PAS CVM {num_pas} — {fase} ({sancao or 'Em andamento'}): {cpf_fmt}",
                "descricao": (
                    f"Acusado: {nome_ac}. "
                    f"Irregularidade: {tipo_irr[:200]}. "
                    f"Fase: {fase}. Julgamento: {dt_julg}.{multa_fmt} "
                    f"Órgão: {orgao}."
                ),
                "referencia_id": num_pas,
                "data_evento": _parse_date(dt_julg),
                "url_fonte": (
                    f"https://sistemas.cvm.gov.br/?PAS&NumPAS={num_pas}"
                    if num_pas else "https://dados.cvm.gov.br/dataset/processo-sancionador"
                ),
                "is_novo": True,
            })

        logger.info("cvm_insider_pf: %d alerta(s) PAS para CPF %s***", len(alertas), cpf[:3])
        return alertas
