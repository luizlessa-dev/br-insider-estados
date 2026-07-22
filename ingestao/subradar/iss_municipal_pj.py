"""
Conector: ISS / Dívida Ativa Municipal — São Paulo, Belo Horizonte, Rio de Janeiro

Verifica se um CNPJ possui débitos de ISS ou consta na dívida ativa municipal
nas três maiores capitais brasileiras.

Portais consultados:
  São Paulo  — https://divida-ativa.prefeitura.sp.gov.br/api/consulta (SF-SP)
               Fallback: https://www.prefeitura.sp.gov.br/cidade/secretarias/financas/servicos/divida_ativa/
  Belo Horizonte — https://bhiss.pbh.gov.br/api/certidao (tentativa)
               Fallback: https://prefeitura.pbh.gov.br/fazfacil
  Rio de Janeiro — https://smi.rio.rj.gov.br/certidao/cnpj (tentativa)
               Fallback: https://carioca.rio/servicos/certidao-de-debitos-tributarios/

Severidade: "info" — débito municipal é menos grave que federal/estadual.
Env vars: nenhuma necessária (fontes públicas gratuitas).
"""
from __future__ import annotations

import logging
import re

import requests

from .base import SubradarSource

logger = logging.getLogger("subradar.iss_municipal_pj")

_HEADERS = {
    "User-Agent": "subradar/1.0 compliance-check",
    "Accept": "application/json, text/html, */*",
}

_TIMEOUT = 12  # portais municipais são lentos; não penalizar demais

# ---------------------------------------------------------------------------
# Definição dos municípios
# ---------------------------------------------------------------------------

_MUNICIPIOS: list[dict] = [
    {
        "sigla": "SP",
        "nome": "São Paulo",
        # API pública SF-SP — pode exigir token ou não existir ainda; tenta.
        "api_url": "https://divida-ativa.prefeitura.sp.gov.br/api/consulta",
        "api_params_fn": lambda cnpj: {"cnpj": cnpj},
        "api_method": "GET",
        # Campos JSON que indicam débito
        "api_debito_keys": ["possui_debito", "tem_debito", "situacao", "status", "resultado"],
        "api_debito_values_positivos": {"sim", "true", "1", "irregular", "devedor", "com débito",
                                        "com debito", "negativa positiva", "positiva"},
        # Fallback scraping
        "fallback_url": "https://www.prefeitura.sp.gov.br/cidade/secretarias/financas/servicos/divida_ativa/",
        "fallback_params_fn": lambda cnpj: {"cnpj": cnpj},
        # Palavras no HTML que indicam débito
        "html_positivo": ["débito", "devedor", "dívida ativa", "irregular", "possui débito"],
        "html_negativo": ["nada consta", "não possui", "sem débito", "negativa"],
    },
    {
        "sigla": "BH",
        "nome": "Belo Horizonte",
        "api_url": "https://bhiss.pbh.gov.br/api/certidao",
        "api_params_fn": lambda cnpj: {"cnpj": cnpj},
        "api_method": "GET",
        "api_debito_keys": ["situacao", "status", "resultado", "debito", "regularidade"],
        "api_debito_values_positivos": {"sim", "true", "1", "irregular", "devedor", "com débito",
                                        "com debito", "negativa positiva", "positiva"},
        "fallback_url": "https://prefeitura.pbh.gov.br/fazfacil",
        "fallback_params_fn": lambda cnpj: {"cnpj": cnpj, "servico": "certidao-debitos"},
        "html_positivo": ["débito", "devedor", "dívida ativa", "irregular", "possui débito"],
        "html_negativo": ["nada consta", "não possui", "sem débito", "negativa", "regular"],
    },
    {
        "sigla": "RJ",
        "nome": "Rio de Janeiro",
        # Endpoint tentativa — SMF-RJ; path com CNPJ direto
        "api_url": "https://smi.rio.rj.gov.br/certidao/cnpj/{cnpj}",
        "api_params_fn": lambda cnpj: {},  # CNPJ já está no path
        "api_method": "GET",
        "api_debito_keys": ["situacao", "status", "resultado", "debito", "regularidade"],
        "api_debito_values_positivos": {"sim", "true", "1", "irregular", "devedor", "com débito",
                                        "com debito", "negativa positiva", "positiva"},
        "fallback_url": "https://carioca.rio/servicos/certidao-de-debitos-tributarios/",
        "fallback_params_fn": lambda cnpj: {"cnpj": cnpj},
        "html_positivo": ["débito", "devedor", "dívida ativa", "irregular", "possui débito"],
        "html_negativo": ["nada consta", "não possui", "sem débito", "negativa", "regular"],
    },
]


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _limpar_cnpj(cnpj: str) -> str:
    """Remove pontuação, retorna 14 dígitos."""
    return re.sub(r"\D", "", cnpj or "")


def _formatar_cnpj(cnpj14: str) -> str:
    if len(cnpj14) != 14:
        return cnpj14
    return f"{cnpj14[:2]}.{cnpj14[2:5]}.{cnpj14[5:8]}/{cnpj14[8:12]}-{cnpj14[12:]}"


def _json_indica_debito(data: dict | list, municipio: dict) -> bool | None:
    """
    Analisa payload JSON e diz se há débito confirmado.
    Retorna True (débito), False (negativa), None (inconclusivo).
    """
    if isinstance(data, list):
        # Lista de débitos/itens: se não vazia, há débito
        return len(data) > 0

    if not isinstance(data, dict):
        return None

    positivos = municipio["api_debito_values_positivos"]
    for key in municipio["api_debito_keys"]:
        valor = data.get(key)
        if valor is None:
            continue
        v_str = str(valor).lower().strip()
        if v_str in positivos:
            return True
        # Negativa explícita
        if v_str in {"nao", "não", "false", "0", "negativa", "regular", "sem débito",
                     "sem debito", "nada consta"}:
            return False

    # Chave 'itens', 'debitos', 'lancamentos' populada → débito
    for lista_key in ("itens", "debitos", "lancamentos", "dividas", "ocorrencias"):
        itens = data.get(lista_key)
        if isinstance(itens, list) and len(itens) > 0:
            return True

    return None  # inconclusivo


def _html_indica_debito(html: str, municipio: dict) -> bool | None:
    """
    Scraping simples: procura palavras-chave de positivo/negativo no HTML.
    Retorna True, False ou None.
    """
    html_lower = html.lower()

    for kw in municipio["html_negativo"]:
        if kw.lower() in html_lower:
            return False  # certidão negativa — nada a reportar

    for kw in municipio["html_positivo"]:
        if kw.lower() in html_lower:
            return True

    return None  # inconclusivo


def _consultar_municipio(municipio: dict, cnpj14: str) -> bool | None:
    """
    Tenta API primária e depois fallback HTML.
    Retorna True (débito confirmado), False (negativa), None (inconclusivo/erro).
    """
    sigla = municipio["sigla"]

    # --- API primária ---
    api_url = municipio["api_url"].replace("{cnpj}", cnpj14)
    params = municipio["api_params_fn"](cnpj14)

    try:
        resp = requests.request(
            municipio["api_method"],
            api_url,
            params=params if params else None,
            headers=_HEADERS,
            timeout=_TIMEOUT,
        )
        logger.debug("iss_municipal [%s] API status=%s", sigla, resp.status_code)

        if resp.ok:
            ct = resp.headers.get("Content-Type", "")
            if "json" in ct:
                try:
                    data = resp.json()
                    resultado = _json_indica_debito(data, municipio)
                    if resultado is not None:
                        return resultado
                except Exception as e:
                    logger.debug("iss_municipal [%s] JSON parse error: %s", sigla, e)
            else:
                # API respondeu HTML — analisa como scraping
                resultado = _html_indica_debito(resp.text, municipio)
                if resultado is not None:
                    return resultado

    except Exception as e:
        logger.debug("iss_municipal [%s] API falhou: %s", sigla, e)

    # --- Fallback scraping ---
    fallback_url = municipio["fallback_url"]
    fallback_params = municipio["fallback_params_fn"](cnpj14)

    try:
        resp = requests.get(
            fallback_url,
            params=fallback_params if fallback_params else None,
            headers=_HEADERS,
            timeout=_TIMEOUT,
        )
        logger.debug("iss_municipal [%s] fallback status=%s", sigla, resp.status_code)

        if resp.ok:
            resultado = _html_indica_debito(resp.text, municipio)
            if resultado is not None:
                return resultado

    except Exception as e:
        logger.debug("iss_municipal [%s] fallback falhou: %s", sigla, e)

    return None  # inconclusivo


# ---------------------------------------------------------------------------
# Connector principal
# ---------------------------------------------------------------------------

class ISSMunicipalPJConnector(SubradarSource):
    """
    Verifica débitos de ISS / dívida ativa municipal para CNPJ em São Paulo,
    Belo Horizonte e Rio de Janeiro.

    Débito confirmado → alerta severity="info" (municipal é menos grave que federal/estadual).
    Negativa ou inconclusivo → nenhum alerta.
    Gracioso em qualquer falha — portais municipais são instáveis.
    """
    fonte = "iss_municipal"
    request_delay = 1.5

    def consultar_cnpj(self, cnpj: str, razao_social: str | None = None, **_) -> list[dict]:
        cnpj14 = _limpar_cnpj(cnpj)
        if len(cnpj14) != 14:
            logger.debug("iss_municipal_pj: CNPJ inválido '%s' — pulando", cnpj)
            return []

        cnpj_fmt = _formatar_cnpj(cnpj14)
        alertas: list[dict] = []

        for municipio in _MUNICIPIOS:
            sigla = municipio["sigla"]
            nome_municipio = municipio["nome"]

            try:
                resultado = _consultar_municipio(municipio, cnpj14)
            except Exception as e:
                # Nunca deve chegar aqui, mas proteção extra
                logger.warning("iss_municipal [%s] exceção inesperada: %s", sigla, e)
                resultado = None

            if resultado is True:
                logger.info(
                    "iss_municipal_pj: [info] débito confirmado em %s para CNPJ %s",
                    nome_municipio, cnpj_fmt,
                )
                alertas.append({
                    "fonte": self.fonte,
                    "categoria": "fiscal",
                    "severidade": "info",
                    "titulo": f"Dívida Ativa Municipal — {nome_municipio}: {cnpj_fmt}",
                    "descricao": (
                        f"O CNPJ {cnpj_fmt} consta na dívida ativa ou possui débito de ISS "
                        f"no município de {nome_municipio}. "
                        "Recomenda-se obter a certidão atualizada no portal municipal."
                    ),
                    "url_fonte": municipio["fallback_url"],
                    "referencia_id": f"iss_{sigla.lower()}_{cnpj14}",
                    "is_novo": True,
                })
            elif resultado is False:
                logger.debug("iss_municipal [%s] certidão negativa para %s", sigla, cnpj_fmt)
            else:
                logger.debug("iss_municipal [%s] inconclusivo para %s", sigla, cnpj_fmt)

        logger.info(
            "iss_municipal_pj: %d alerta(s) para CNPJ %s", len(alertas), cnpj_fmt
        )
        return alertas
