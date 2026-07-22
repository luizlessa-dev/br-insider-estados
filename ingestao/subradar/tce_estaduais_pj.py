"""
Conector: TCE Estaduais — Tribunais de Contas de SP, MG e RJ (Pessoa Jurídica)

Verifica se o CNPJ consta em processos de irregularidade ou sanção
nos Tribunais de Contas estaduais — relevante para fornecedores, OSCs,
contratadas e beneficiárias de emendas parlamentares.

Estratégia por tribunal:
  TCE-SP — Infosimples (endpoint pago, opcional) com fallback scraping portal de apenados
            API:      https://api.infosimples.com/api/v2/consultas/tce/sp/apenados?cnpj={cnpj14}
            Fallback: https://www.tce.sp.gov.br/pesquisa-relacao-apenados?cnpj={cnpj}
  TCE-MG — GET busca processual pública por CNPJ
            https://www.tce.mg.gov.br/Processo/?nrCpfCnpj={cnpj_formatado}
  TCE-RJ — Scraping HTML do portal de pesquisa
            https://www.tcerj.tc.br/portalnovo/pesquisar?q={cnpj14}

Env vars:
  INFOSIMPLES_TOKEN — opcional; sem ele, TCE-SP cai para scraping web.

fonte="tce_estaduais_pj", categoria="controle"
"""
from __future__ import annotations

import logging
import os
import re
import unicodedata

import requests

from .base import SubradarSource

logger = logging.getLogger("subradar.tce_estaduais_pj")

_HEADERS = {
    "User-Agent": "subradar/1.0 compliance-check",
    "Accept": "application/json, text/html, */*",
}

_CRITICO_STATUS = {
    "irregular", "irregularidade", "débito imputado", "multa aplicada",
    "julgado irregular", "condenado", "ressarcimento", "débito",
    "inabilitado", "afastamento", "responsável solidário",
}
_ATENCAO_STATUS = {
    "em julgamento", "pendente", "em análise", "citado", "intimado",
    "audiência", "recurso", "em instrução", "sob análise",
}


def _normalize(s: str) -> str:
    s = unicodedata.normalize("NFD", s)
    return "".join(c for c in s if unicodedata.category(c) != "Mn").lower().strip()


def _fmt_cnpj(cnpj14: str) -> str:
    """Formata CNPJ com máscara: XX.XXX.XXX/XXXX-XX."""
    c = re.sub(r"\D", "", cnpj14)
    if len(c) == 14:
        return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}"
    return c


def _cnpj_presente(cnpj14: str, texto: str) -> bool:
    """Verifica se o CNPJ (com ou sem máscara) aparece no texto."""
    cnpj_fmt = _fmt_cnpj(cnpj14)
    texto_n = _normalize(texto)
    return cnpj14 in texto_n or _normalize(cnpj_fmt) in texto_n


def _via_infosimples(cnpj14: str) -> list[dict]:
    """
    Consulta TCE-SP via Infosimples (endpoint pago, CNPJ).
    Retorna lista vazia se INFOSIMPLES_TOKEN não estiver configurado.
    """
    token = os.environ.get("INFOSIMPLES_TOKEN", "")
    if not token:
        return []

    endpoint = "https://api.infosimples.com/api/v2/consultas/tce/sp/apenados"
    try:
        resp = requests.get(
            endpoint,
            params={"cnpj": cnpj14, "token": token, "timeout": 600},
            timeout=30,
        )
        if resp.ok:
            data = resp.json()
            if data.get("code") == 200:
                registros = data.get("data", [])
                return [{"tribunal": "TCESP", **r} for r in registros]
    except Exception as e:
        logger.debug("Infosimples TCE-SP CNPJ: %s", e)
    return []


def _via_web_tcesp(cnpj14: str) -> list[dict]:
    """
    Fallback: scraping do portal de apenados do TCE-SP por CNPJ.
    URL: https://www.tce.sp.gov.br/pesquisa-relacao-apenados?cnpj={cnpj}
    """
    url = "https://www.tce.sp.gov.br/pesquisa-relacao-apenados"
    cnpj_fmt = _fmt_cnpj(cnpj14)
    try:
        resp = requests.get(
            url,
            params={"cnpj": cnpj_fmt},
            headers=_HEADERS,
            timeout=12,
        )
        if not resp.ok:
            return []

        ct = resp.headers.get("Content-Type", "")
        if "json" in ct:
            data = resp.json()
            items = (
                data if isinstance(data, list) else
                data.get("apenados") or data.get("results") or
                data.get("items") or data.get("data") or []
            )
            return [{"tribunal": "TCESP", **i} for i in items if isinstance(i, dict)]

        html = resp.text
        resultados = []
        rows = re.findall(r"<tr[^>]*>(.*?)</tr>", html, re.DOTALL | re.IGNORECASE)
        for row in rows:
            texto = re.sub(r"<[^>]+>", " ", row)
            texto = re.sub(r"\s+", " ", texto).strip()
            if _cnpj_presente(cnpj14, texto) and len(texto) > 20:
                resultados.append({
                    "tribunal": "TCESP",
                    "texto": texto[:400],
                    "cnpj": cnpj14,
                })
        return resultados[:5]
    except Exception as e:
        logger.debug("TCE-SP web CNPJ: %s", e)
    return []


def _via_web_tcemg(cnpj14: str) -> list[dict]:
    """
    Busca processual pública do TCE-MG por CNPJ.
    URL: https://www.tce.mg.gov.br/Processo/?nrCpfCnpj={cnpj_formatado}
    """
    url = "https://www.tce.mg.gov.br/Processo/"
    cnpj_fmt = _fmt_cnpj(cnpj14)
    try:
        resp = requests.get(
            url,
            params={"nrCpfCnpj": cnpj_fmt},
            headers=_HEADERS,
            timeout=12,
        )
        if not resp.ok:
            return []

        ct = resp.headers.get("Content-Type", "")
        if "json" in ct:
            data = resp.json()
            items = (
                data if isinstance(data, list) else
                data.get("processos") or data.get("results") or
                data.get("items") or data.get("data") or []
            )
            return [{"tribunal": "TCEMG", **i} for i in items if isinstance(i, dict)]

        html = resp.text
        resultados = []
        rows = re.findall(r"<tr[^>]*>(.*?)</tr>", html, re.DOTALL | re.IGNORECASE)
        for row in rows:
            texto = re.sub(r"<[^>]+>", " ", row)
            texto = re.sub(r"\s+", " ", texto).strip()
            # TCE-MG pode retornar resultados sem o CNPJ explícito na linha;
            # aceita qualquer linha de tabela que pareça um processo
            if len(texto) > 30 and re.search(r"\d{4,}", texto):
                resultados.append({
                    "tribunal": "TCEMG",
                    "texto": texto[:400],
                    "cnpj": cnpj14,
                })
        return resultados[:5]
    except Exception as e:
        logger.debug("TCE-MG web CNPJ: %s", e)
    return []


def _via_web_tcerj(cnpj14: str) -> list[dict]:
    """
    Scraping HTML do portal de pesquisa do TCE-RJ por CNPJ.
    URL: https://www.tcerj.tc.br/portalnovo/pesquisar?q={cnpj14}
    """
    url = "https://www.tcerj.tc.br/portalnovo/pesquisar"
    try:
        resp = requests.get(
            url,
            params={"q": cnpj14},
            headers=_HEADERS,
            timeout=12,
        )
        if not resp.ok:
            return []

        ct = resp.headers.get("Content-Type", "")
        if "json" in ct:
            data = resp.json()
            items = (
                data if isinstance(data, list) else
                data.get("resultados") or data.get("results") or
                data.get("items") or data.get("data") or []
            )
            return [{"tribunal": "TCERJ", **i} for i in items if isinstance(i, dict)]

        html = resp.text
        resultados = []
        rows = re.findall(r"<tr[^>]*>(.*?)</tr>", html, re.DOTALL | re.IGNORECASE)
        for row in rows:
            texto = re.sub(r"<[^>]+>", " ", row)
            texto = re.sub(r"\s+", " ", texto).strip()
            if _cnpj_presente(cnpj14, texto) and len(texto) > 20:
                resultados.append({
                    "tribunal": "TCERJ",
                    "texto": texto[:400],
                    "cnpj": cnpj14,
                })
        return resultados[:5]
    except Exception as e:
        logger.debug("TCE-RJ web CNPJ: %s", e)
    return []


def _classificar_registro(reg: dict) -> tuple[bool, str]:
    """
    Retorna (é_irregularidade, severidade).
    Analisa campos de status/situação/resultado do registro TCE.
    """
    campos = " ".join(str(v) for v in reg.values() if isinstance(v, str))
    campos_n = _normalize(campos)

    for kw in _CRITICO_STATUS:
        if kw in campos_n:
            return True, "critico"
    for kw in _ATENCAO_STATUS:
        if kw in campos_n:
            return True, "atencao"
    return False, "nenhum"


_TRIBUNAIS_WEB = [
    {
        "sigla": "TCESP",
        "nome": "Tribunal de Contas do Estado de São Paulo",
        "web_search": "https://www.tce.sp.gov.br/pesquisa-relacao-apenados",
        "fn": _via_web_tcesp,
    },
    {
        "sigla": "TCEMG",
        "nome": "Tribunal de Contas do Estado de Minas Gerais",
        "web_search": "https://www.tce.mg.gov.br/Processo/",
        "fn": _via_web_tcemg,
    },
    {
        "sigla": "TCERJ",
        "nome": "Tribunal de Contas do Estado do Rio de Janeiro",
        "web_search": "https://www.tcerj.tc.br/portalnovo/pesquisar",
        "fn": _via_web_tcerj,
    },
]

_SIGLA_TO_WEB = {t["sigla"]: t["web_search"] for t in _TRIBUNAIS_WEB}


class TCEEstaduaisPJConnector(SubradarSource):
    """
    Verifica se o CNPJ consta em processos de irregularidade nos TCE de SP, MG e RJ.

    TCE-SP: tenta Infosimples (INFOSIMPLES_TOKEN) → fallback scraping portal apenados.
    TCE-MG: busca processual pública por CNPJ formatado.
    TCE-RJ: scraping HTML do portal de pesquisa geral.

    Gracioso se os portais estiverem indisponíveis ou token ausente.
    """
    fonte = "tce_estaduais_pj"
    request_delay = 2.0

    def consultar_cnpj(self, cnpj_or_cpf: str, razao_social: str | None = None, **_) -> list[dict]:
        cnpj14 = re.sub(r"\D", "", str(cnpj_or_cpf or ""))
        if len(cnpj14) != 14:
            logger.debug("tce_estaduais_pj: CNPJ inválido (%s) — pulando", cnpj14)
            return []

        cnpj_fmt = _fmt_cnpj(cnpj14)
        alertas: list[dict] = []

        # --- TCE-SP: Infosimples primeiro, depois scraping web ---
        registros_sp = _via_infosimples(cnpj14)
        if not registros_sp:
            registros_sp = _via_web_tcesp(cnpj14)

        # --- TCE-MG ---
        registros_mg = _via_web_tcemg(cnpj14)

        # --- TCE-RJ ---
        registros_rj = _via_web_tcerj(cnpj14)

        todos_registros = registros_sp + registros_mg + registros_rj

        for reg in todos_registros:
            sigla = reg.get("tribunal", "TCE")
            eh_irregular, severidade = _classificar_registro(reg)
            if not eh_irregular:
                continue

            processo = (
                reg.get("num_processo") or reg.get("processo") or
                reg.get("numero") or reg.get("id") or "s/n"
            )
            situacao = (
                reg.get("situacao") or reg.get("status") or
                reg.get("resultado") or reg.get("julgamento") or ""
            )
            entidade = (
                reg.get("entidade") or reg.get("orgao") or
                reg.get("municipio") or ""
            )

            desc_partes = [f"Processo {sigla} n° {processo}"]
            if situacao:
                desc_partes.append(f"situação: {situacao}")
            if entidade:
                desc_partes.append(f"entidade: {entidade}")
            if razao_social:
                desc_partes.append(f"empresa: {razao_social}")
            desc_partes.append(
                "CNPJ com irregularidade apontada pelo Tribunal de Contas."
            )

            url_fonte = _SIGLA_TO_WEB.get(sigla, "")

            logger.info(
                "tce_estaduais_pj: [%s] processo %s no %s para CNPJ %s",
                severidade, processo, sigla, cnpj_fmt,
            )

            alertas.append({
                "fonte": self.fonte,
                "categoria": "controle",
                "severidade": severidade,
                "titulo": f"{sigla} — irregularidade CNPJ: {cnpj_fmt}",
                "descricao": ". ".join(desc_partes),
                "url_fonte": url_fonte,
                "referencia_id": str(processo),
                "is_novo": True,
            })

        logger.info(
            "tce_estaduais_pj: %d alerta(s) para CNPJ %s", len(alertas), cnpj_fmt
        )
        return alertas
