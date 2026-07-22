"""
Conector: SEFAZ Estadual — Certidão Negativa de Débitos para PJ (SP, MG, RJ)

Verifica se o CNPJ possui débitos estaduais confirmados nos portais das
Secretarias de Fazenda de SP, MG e RJ — relevante para empresas com contratos
públicos, participantes de licitações e fornecedores do setor público.

Portais consultados:
  SEFAZ-SP — https://www.fazenda.sp.gov.br/certidaoCDAS/certidaoCDAS.aspx
              Busca HTML; presença de "NEGATIVA" ou "POSITIVA" no corpo da página.
  SEFAZ-MG — https://www.fazenda.mg.gov.br/governo/assuntos/certidoes/cnpj/{cnpj14}
              Tenta JSON; fallback scraping do portal.
  SEFAZ-RJ — https://servicosrfb.receita.fazenda.gov.br/certidaoestadual/rj?cnpj={cnpj14}
              Portal federal de certidões estaduais; gracioso se indisponível.

Regras de alerta:
  - Certidão POSITIVA (débito confirmado) → severity="atencao"
  - Certidão NEGATIVA → sem alerta
  - Inconclusivo / portal indisponível → sem alerta (gracioso)

Env vars: nenhuma necessária (fontes públicas gratuitas).
"""
from __future__ import annotations

import logging
import re
import time

import requests

from .base import SubradarSource

logger = logging.getLogger("subradar.sefaz_estadual_pj")

_HEADERS = {
    "User-Agent": "subradar/1.0 compliance-check",
    "Accept": "application/json, text/html, */*",
}

# Palavras que indicam ausência de débito (certidão NEGATIVA)
_KEYWORDS_NEGATIVA = {
    "negativa",
    "nada consta",
    "sem débitos",
    "sem debitos",
    "inexistência",
    "inexistencia",
    "não foram encontrados",
    "nao foram encontrados",
}

# Palavras que indicam presença de débito (certidão POSITIVA)
_KEYWORDS_POSITIVA = {
    "positiva",
    "débito",
    "debito",
    "pendência",
    "pendencia",
    "irregular",
    "inscrição em dívida",
    "inscricao em divida",
    "dívida ativa",
    "divida ativa",
    "inadimplente",
}


def _fmt_cnpj14(cnpj: str) -> str:
    """Retorna apenas os 14 dígitos numéricos do CNPJ."""
    return re.sub(r"\D", "", str(cnpj or ""))


def _fmt_cnpj_mask(cnpj14: str) -> str:
    """Formata CNPJ com máscara XX.XXX.XXX/XXXX-XX."""
    if len(cnpj14) != 14:
        return cnpj14
    return f"{cnpj14[:2]}.{cnpj14[2:5]}.{cnpj14[5:8]}/{cnpj14[8:12]}-{cnpj14[12:]}"


def _classificar_html(html: str) -> str:
    """
    Analisa o HTML/texto da resposta e retorna 'positiva', 'negativa' ou 'inconclusivo'.
    Prioriza palavras mais específicas (positiva > negativa).
    """
    texto = html.lower()
    # Remove tags HTML para reduzir falsos positivos
    texto_limpo = re.sub(r"<[^>]+>", " ", texto)
    texto_limpo = re.sub(r"\s+", " ", texto_limpo).strip()

    # Verifica positiva primeiro (mais restritivo)
    for kw in _KEYWORDS_POSITIVA:
        if kw in texto_limpo:
            # Confirma que não é no contexto de "certidão NEGATIVA de débitos" (frase comum)
            # Evita falso positivo em "débito" dentro de "certidão negativa de débitos"
            if kw == "débito" or kw == "debito":
                # Contexto suspeito: "débito" aparece FORA de contexto negativo
                contexto_neg = any(n in texto_limpo for n in ("negativa", "sem débito", "sem debito", "nada consta"))
                if contexto_neg:
                    continue
            logger.debug("sefaz_estadual: keyword positiva encontrada: %r", kw)
            return "positiva"

    for kw in _KEYWORDS_NEGATIVA:
        if kw in texto_limpo:
            logger.debug("sefaz_estadual: keyword negativa encontrada: %r", kw)
            return "negativa"

    return "inconclusivo"


# ---------------------------------------------------------------------------
# Funções por estado
# ---------------------------------------------------------------------------

def _consultar_sp(cnpj14: str) -> tuple[str, str]:
    """
    SEFAZ-SP: GET com CNPJ como parâmetro de query.
    Retorna (resultado: 'positiva'|'negativa'|'inconclusivo', url_fonte).
    """
    url = "https://www.fazenda.sp.gov.br/certidaoCDAS/certidaoCDAS.aspx"
    params = {"CNPJ": cnpj14}
    try:
        resp = requests.get(url, params=params, headers=_HEADERS, timeout=15)
        if not resp.ok:
            logger.debug("sefaz_sp: HTTP %s para CNPJ %s", resp.status_code, cnpj14)
            return "inconclusivo", url
        return _classificar_html(resp.text), resp.url
    except Exception as exc:
        logger.debug("sefaz_sp: erro de rede — %s", exc)
        return "inconclusivo", url


def _consultar_mg(cnpj14: str) -> tuple[str, str]:
    """
    SEFAZ-MG: tenta endpoint JSON estruturado; fallback para portal HTML.
    Retorna (resultado: 'positiva'|'negativa'|'inconclusivo', url_fonte).
    """
    url_json = f"https://www.fazenda.mg.gov.br/governo/assuntos/certidoes/cnpj/{cnpj14}"
    url_fallback = f"https://siare.fazenda.mg.gov.br/portaldoscidadaos/web/certidoes/cnpj?cnpj={cnpj14}"

    for url, accept_json in [(url_json, True), (url_fallback, False)]:
        try:
            headers = {**_HEADERS}
            if accept_json:
                headers["Accept"] = "application/json, text/html, */*"
            resp = requests.get(url, headers=headers, timeout=15, allow_redirects=True)
            if not resp.ok:
                logger.debug("sefaz_mg: HTTP %s para %s", resp.status_code, url)
                continue

            ct = resp.headers.get("Content-Type", "")
            if "json" in ct:
                data = resp.json()
                # Tenta campos comuns de APIs de certidão
                situacao = (
                    str(data.get("situacao") or data.get("status") or
                        data.get("resultado") or data.get("certidao") or "")
                ).lower()
                if situacao:
                    for kw in _KEYWORDS_POSITIVA:
                        if kw in situacao:
                            return "positiva", url
                    for kw in _KEYWORDS_NEGATIVA:
                        if kw in situacao:
                            return "negativa", url
                    return "inconclusivo", url

            # HTML
            resultado = _classificar_html(resp.text)
            if resultado != "inconclusivo":
                return resultado, resp.url
        except Exception as exc:
            logger.debug("sefaz_mg: erro em %s — %s", url, exc)

    return "inconclusivo", url_json


def _consultar_rj(cnpj14: str) -> tuple[str, str]:
    """
    SEFAZ-RJ: tenta portal federal de certidões estaduais RJ.
    Fallback: portal próprio SEFAZ-RJ.
    Retorna (resultado: 'positiva'|'negativa'|'inconclusivo', url_fonte).
    """
    urls = [
        (
            "https://servicosrfb.receita.fazenda.gov.br/certidaoestadual/rj",
            {"cnpj": cnpj14},
        ),
        (
            "https://portal.fazenda.rj.gov.br/certidao",
            {"cnpj": cnpj14},
        ),
    ]

    for url, params in urls:
        try:
            resp = requests.get(url, params=params, headers=_HEADERS, timeout=15)
            if not resp.ok:
                logger.debug("sefaz_rj: HTTP %s para %s", resp.status_code, url)
                continue

            ct = resp.headers.get("Content-Type", "")
            if "json" in ct:
                data = resp.json()
                situacao = str(
                    data.get("situacao") or data.get("status") or
                    data.get("resultado") or ""
                ).lower()
                if situacao:
                    for kw in _KEYWORDS_POSITIVA:
                        if kw in situacao:
                            return "positiva", url
                    for kw in _KEYWORDS_NEGATIVA:
                        if kw in situacao:
                            return "negativa", url

            resultado = _classificar_html(resp.text)
            if resultado != "inconclusivo":
                return resultado, resp.url
        except Exception as exc:
            logger.debug("sefaz_rj: erro em %s — %s", url, exc)

    return "inconclusivo", urls[0][0]


# ---------------------------------------------------------------------------
# Mapeamento dos estados
# ---------------------------------------------------------------------------

_ESTADOS = [
    {
        "sigla": "SP",
        "nome": "São Paulo",
        "fn": _consultar_sp,
        "url_padrao": "https://www.fazenda.sp.gov.br/certidaoCDAS/certidaoCDAS.aspx",
    },
    {
        "sigla": "MG",
        "nome": "Minas Gerais",
        "fn": _consultar_mg,
        "url_padrao": "https://www.fazenda.mg.gov.br/governo/assuntos/certidoes/cnpj/",
    },
    {
        "sigla": "RJ",
        "nome": "Rio de Janeiro",
        "fn": _consultar_rj,
        "url_padrao": "https://servicosrfb.receita.fazenda.gov.br/certidaoestadual/rj",
    },
]


# ---------------------------------------------------------------------------
# Conector Subradar
# ---------------------------------------------------------------------------

class SEFAZEstadualPJConnector(SubradarSource):
    """
    Verifica certidão negativa de débitos estaduais (SEFAZ-SP, SEFAZ-MG, SEFAZ-RJ) para CNPJ.

    Certidão POSITIVA (débito confirmado) → alerta severity='atencao'.
    Certidão NEGATIVA ou inconclusiva → sem alerta.
    Gracioso em qualquer falha de rede ou portal indisponível.

    Env vars: nenhuma necessária.
    """

    fonte = "sefaz_estadual"
    request_delay = 2.0

    def consultar_cnpj(self, cnpj: str, razao_social: str | None = None, **_) -> list[dict]:
        cnpj14 = _fmt_cnpj14(cnpj)
        if len(cnpj14) != 14:
            logger.debug("sefaz_estadual_pj: CNPJ inválido (%r) — pulando", cnpj)
            return []

        cnpj_mask = _fmt_cnpj_mask(cnpj14)
        nome = razao_social or cnpj_mask
        alertas: list[dict] = []

        for i, estado in enumerate(_ESTADOS):
            if i > 0:
                time.sleep(self.request_delay)

            sigla = estado["sigla"]
            logger.debug("sefaz_estadual_pj: consultando SEFAZ-%s para %s", sigla, cnpj_mask)

            try:
                resultado, url_fonte = estado["fn"](cnpj14)
            except Exception as exc:
                logger.warning("sefaz_estadual_pj: erro inesperado em SEFAZ-%s — %s", sigla, exc)
                continue

            if resultado != "positiva":
                logger.debug(
                    "sefaz_estadual_pj: SEFAZ-%s resultado=%r para %s — sem alerta",
                    sigla, resultado, cnpj_mask,
                )
                continue

            logger.info(
                "sefaz_estadual_pj: DÉBITO ESTADUAL confirmado em SEFAZ-%s para %s",
                sigla, cnpj_mask,
            )

            alertas.append({
                "fonte": self.fonte,
                "categoria": "fiscal",
                "severidade": "atencao",
                "titulo": f"SEFAZ-{sigla} — certidão positiva: {cnpj_mask}",
                "descricao": (
                    f"O CNPJ {cnpj_mask} ({nome}) possui débito(s) estadual(is) "
                    f"confirmado(s) perante a Secretaria de Fazenda do estado de "
                    f"{estado['nome']} (SEFAZ-{sigla}). "
                    "Certidão de regularidade fiscal estadual em situação POSITIVA."
                ),
                "url_fonte": url_fonte,
                "referencia_id": f"sefaz-{sigla.lower()}-{cnpj14}",
                "is_novo": True,
            })

        logger.info(
            "sefaz_estadual_pj: %d alerta(s) para CNPJ %s", len(alertas), cnpj_mask
        )
        return alertas
