"""
Conector: Protestos — CENPROT-SP (cobertura São Paulo)

Fonte: protestosp.com.br — consulta pública gratuita por CNPJ/CPF
Autorização legal: Parecer CG-SP nº 38/2013 (consulta de existência é pública)
Cobertura: cartórios do estado de São Paulo apenas

Limitações conhecidas:
  - Cobertura apenas SP (maior praça, mas não nacional)
  - Apenas existência/inexistência de protesto — sem valor ou origem
  - Integração via scraping web (sem API REST)
  - CAPTCHA pode bloquear consultas automatizadas

Roadmap: ampliar para demais estados via IEPTB quando APIs estaduais forem abertas.
"""
from __future__ import annotations

import logging
import re
import time

import requests
from bs4 import BeautifulSoup

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.protestos")

CENPROT_URL = "https://www.protestosp.com.br/portal/protestos/consultar"
REQUEST_DELAY = 3.0  # respeito ao servidor


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", str(cnpj or ""))


def _fmt(cnpj: str) -> str:
    c = _strip(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _consultar_cenprot(cnpj_digits: str) -> dict:
    """
    Consulta existência de protestos no CENPROT-SP.

    Retorna dict com:
      status: 'com_protesto' | 'sem_protesto' | 'erro' | 'captcha'
      detalhes: texto bruto da resposta
    """
    session = requests.Session()
    session.headers.update({
        "User-Agent": (
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
            "AppleWebKit/537.36 (KHTML, like Gecko) "
            "Chrome/120.0.0.0 Safari/537.36"
        ),
        "Accept": "text/html,application/xhtml+xml",
        "Accept-Language": "pt-BR,pt;q=0.9",
        "Referer": "https://www.protestosp.com.br/",
    })

    try:
        # Carrega página inicial para obter token CSRF se necessário
        page = session.get("https://www.protestosp.com.br/portal/protestos", timeout=20)
        page.raise_for_status()
        soup = BeautifulSoup(page.text, "html.parser")

        # Tenta encontrar token CSRF
        csrf = ""
        token_input = soup.find("input", {"name": re.compile(r"csrf|token|_token", re.I)})
        if token_input:
            csrf = token_input.get("value", "")

        time.sleep(REQUEST_DELAY)

        # Submete consulta
        payload = {
            "documento": cnpj_digits,
            "tipo": "J",  # Jurídica
        }
        if csrf:
            payload["_token"] = csrf

        resp = session.post(CENPROT_URL, data=payload, timeout=30)
        resp.raise_for_status()

        texto = resp.text.lower()

        if "captcha" in texto or "recaptcha" in texto or resp.status_code in (403, 429):
            logger.warning(
                "CENPROT-SP: acesso bloqueado para %s (CAPTCHA/rate-limit). "
                "Limitação conhecida do protestosp.com.br — sem API pública. "
                "Fonte retorna [] graciosamente; cobertura de protestos via "
                "ProtestosNacionalConnector (Direct Data) quando disponível.",
                cnpj_digits,
            )
            return {"status": "captcha", "detalhes": "CAPTCHA/bloqueio bloqueou a consulta"}

        if any(p in texto for p in ["não foram encontrados", "nenhum protesto", "sem protesto", "não há protesto"]):
            return {"status": "sem_protesto", "detalhes": "Nenhum protesto encontrado"}

        if any(p in texto for p in ["protesto", "cartório", "apresentante", "valor"]):
            # Extrai informações básicas disponíveis
            soup2 = BeautifulSoup(resp.text, "html.parser")
            detalhes = soup2.get_text(separator=" ", strip=True)[:500]
            return {"status": "com_protesto", "detalhes": detalhes}

        return {"status": "erro", "detalhes": "Resposta não reconhecida"}

    except requests.exceptions.Timeout:
        return {"status": "erro", "detalhes": "Timeout na consulta"}
    except Exception as e:
        logger.warning("CENPROT-SP: erro na consulta de %s: %s", cnpj_digits, e)
        return {"status": "erro", "detalhes": str(e)[:200]}


class ProtestosConnector(SubradarSource):
    fonte = "protestos_sp"
    request_delay = REQUEST_DELAY

    def consultar_cnpj(self, cnpj: str) -> list[dict]:
        cnpj_digits = _strip(cnpj)
        cnpj_fmt = _fmt(cnpj_digits)
        ciclo = _ciclo_atual()

        resultado = _consultar_cenprot(cnpj_digits)
        status = resultado.get("status")

        # Erros e captchas: não geram alerta, mas logam
        if status in ("erro", "captcha"):
            logger.warning("Protestos SP: consulta inconclusiva para %s: %s", cnpj_fmt, resultado.get("detalhes"))
            return []

        if status == "sem_protesto":
            return []

        # com_protesto
        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, resultado)
        if not mudou:
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt,
            "fonte": self.fonte,
            "ciclo": ciclo,
            "hash_dados": hash_novo,
            "dados": resultado,
        }])

        return [{
            "cnpj": cnpj_fmt,
            "ciclo": ciclo,
            "fonte": self.fonte,
            "categoria": "credito",
            "severidade": "atencao",
            "titulo": "Protesto(s) identificado(s) — CENPROT-SP",
            "descricao": (
                "Existência de protesto(s) registrada nos cartórios do estado de São Paulo. "
                "Consulte o CENPROT-SP para detalhes e valores. "
                "Nota: cobertura limitada ao estado de SP."
            ),
            "url_fonte": "https://www.protestosp.com.br/portal/protestos",
            "is_novo": True,
        }]
