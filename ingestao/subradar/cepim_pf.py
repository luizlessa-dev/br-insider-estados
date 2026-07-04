"""
Conector: CEPIM — Pessoa Física como representante de entidade impedida

O CEPIM (Cadastro de Entidades Privadas Sem Fins Lucrativos Impedidas) registra
organizações que não podem receber verbas federais. Este conector verifica se
o CPF consultado é sócio/representante de alguma dessas entidades.

Estratégia:
  1. Busca CNPJs onde o CPF é sócio na tabela cnpj_socios
  2. Para cada CNPJ encontrado, verifica se consta em sub_cepim
  3. Gera alerta crítico se a pessoa for representante de entidade impedida

Sem custo adicional — usa apenas tabelas locais do Supabase.
"""
from __future__ import annotations

import logging
import re

import requests

from .base import SubradarSource, SUPABASE_URL, SUPABASE_KEY, _supabase_headers

logger = logging.getLogger("subradar.cepim_pf")


def _strip(doc: str) -> str:
    return re.sub(r"\D", "", str(doc or ""))


def _fmt_cpf(cpf: str) -> str:
    c = _strip(cpf)
    return f"{c[:3]}.{c[3:6]}.{c[6:9]}-{c[9:11]}" if len(c) == 11 else cpf


def _cnpjs_de_socio(cpf: str) -> list[dict]:
    """Retorna CNPJs onde o CPF aparece como sócio (cnpj_socios)."""
    if not SUPABASE_URL or not SUPABASE_KEY:
        return []
    try:
        resp = requests.get(
            f"{SUPABASE_URL}/rest/v1/cnpj_socios",
            params={
                "cpf_cnpj_socio": f"eq.{cpf}",
                "select": "cnpj,nome_socio,qualificacao_socio",
                "limit": "50",
            },
            headers=_supabase_headers(),
            timeout=15,
        )
        if resp.ok:
            return resp.json() or []
    except Exception as e:
        logger.debug("cepim_pf: erro ao buscar sócios: %s", e)
    return []


def _checar_cepim(cnpj: str) -> list[dict]:
    """Retorna registros CEPIM para o CNPJ (tabela local sub_cepim)."""
    if not SUPABASE_URL or not SUPABASE_KEY:
        return []
    cnpj_digits = _strip(cnpj)
    try:
        resp = requests.get(
            f"{SUPABASE_URL}/rest/v1/sub_cepim",
            params={
                "cnpj": f"like.{cnpj_digits[:8]}%",
                "select": "cnpj,nome,motivo,orgao_superior,num_convenio,data_referencia",
                "limit": "10",
            },
            headers=_supabase_headers(),
            timeout=15,
        )
        if resp.ok:
            return resp.json() or []
    except Exception as e:
        logger.debug("cepim_pf: erro ao checar CEPIM para %s: %s", cnpj[:8], e)
    return []


class CEPIMRepresentantePFConnector(SubradarSource):
    """
    Verifica se o CPF consultado é sócio de alguma entidade presente no CEPIM.
    Gera alerta crítico se encontrar vínculo.
    Gracioso sem Supabase configurado.
    """
    fonte = "cepim_pf"
    request_delay = 0.2

    def consultar_cnpj(self, cnpj_or_cpf: str, razao_social: str | None = None, **_) -> list[dict]:
        cpf = _strip(cnpj_or_cpf)
        if len(cpf) != 11:
            return []

        if not SUPABASE_URL or not SUPABASE_KEY:
            logger.debug("cepim_pf: Supabase não configurado — pulando")
            return []

        cpf_fmt = _fmt_cpf(cpf)
        socios = _cnpjs_de_socio(cpf)

        if not socios:
            logger.debug("cepim_pf: CPF %s*** não é sócio de nenhum CNPJ", cpf[:3])
            return []

        alertas = []
        seen_cnpj = set()

        for socio in socios:
            cnpj_socio = _strip(socio.get("cnpj", ""))
            if not cnpj_socio or cnpj_socio in seen_cnpj:
                continue
            seen_cnpj.add(cnpj_socio)

            registros_cepim = _checar_cepim(cnpj_socio)
            for reg in registros_cepim:
                nome_entidade = reg.get("nome") or cnpj_socio
                motivo = reg.get("motivo") or "N/D"
                orgao = reg.get("orgao_superior") or "N/D"
                convenio = reg.get("num_convenio") or ""
                data_ref = reg.get("data_referencia") or ""
                qualif = socio.get("qualificacao_socio") or "Sócio"

                alertas.append({
                    "fonte": self.fonte,
                    "categoria": "sancao",
                    "severidade": "critico",
                    "titulo": f"CEPIM — {cpf_fmt} é {qualif} de entidade impedida: {nome_entidade}",
                    "descricao": (
                        f"O CPF consultado consta como {qualif} de '{nome_entidade}' (CNPJ {cnpj_socio[:2]}.{cnpj_socio[2:5]}.{cnpj_socio[5:8]}/{cnpj_socio[8:12]}-{cnpj_socio[12:14]}), "
                        f"entidade impedida de receber convênios federais de {orgao}. "
                        f"Motivo: {motivo}."
                        + (f" Convênio: {convenio}." if convenio else "")
                        + (f" Referência: {data_ref}." if data_ref else "")
                    ),
                    "url_fonte": "https://www.portaldatransparencia.gov.br/sancoes/cepim",
                    "is_novo": True,
                })

        if alertas:
            logger.info("cepim_pf: %d alerta(s) para %s", len(alertas), cpf_fmt)
        else:
            logger.debug("cepim_pf: CPF %s*** sem vínculo com entidades CEPIM", cpf[:3])

        return alertas
