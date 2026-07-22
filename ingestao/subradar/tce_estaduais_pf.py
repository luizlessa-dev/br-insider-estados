"""
Conector: TCE Estaduais — Tribunais de Contas de SP, MG e RJ

Verifica se a pessoa física consta em processos de irregularidade ou sanção
nos Tribunais de Contas estaduais — relevante para gestores públicos, prefeitos,
secretários, diretores de autarquias e responsáveis por contratos públicos.

Portais com dados abertos:
  TCESP — https://www.tce.sp.gov.br/dadosabertos/
           API CKAN: https://dados.tce.sp.gov.br/
  TCEMG — https://www.tce.mg.gov.br/index.asp
           Consulta de responsáveis: https://contasmg.tce.mg.gov.br/
  TCERJ — https://www.tcerj.tc.br/
           CKAN: https://dados.tcerj.tc.br/

Estratégia:
  1. Busca por nome nos portais de dados abertos (API CKAN ou endpoint REST)
  2. Fallback: scraping da busca fulltext nos portais web
  3. Apenas processos com sanção, irregularidade ou débito imputado

Env vars: nenhuma necessária (fontes públicas gratuitas).
"""
from __future__ import annotations

import logging
import re
import unicodedata

import requests

from .base import SubradarSource

logger = logging.getLogger("subradar.tce_estaduais_pf")

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

# TCE-SP: portal de apenados público (sem API); Infosimples tem wrapper JSON.
#   Busca por CPF em: tce.sp.gov.br/pesquisa-relacao-apenados
# TCE-MG: busca processual pública por CPF em: tce.mg.gov.br/Processo/
#   SSL do CKAN (dadosabertos.tce.mg.gov.br) inválido — não usar.
# TCE-RJ: sem endpoint confirma de apenados por CPF — via web_search.

_TRIBUNAIS = [
    {
        "sigla": "TCESP",
        "nome": "Tribunal de Contas do Estado de São Paulo",
        "ckan_search": None,
        "web_search": "https://www.tce.sp.gov.br/pesquisa-relacao-apenados",
        "resource_id_responsaveis": None,
        # Infosimples endpoint (paga) para certidão de apenados TCE-SP por CPF
        "infosimples_endpoint": "https://api.infosimples.com/api/v2/consultas/tce/sp/apenados",
        "web_params_fn": lambda nome: {"q": nome},
        "cpf_param": "cpf",  # campo CPF aceito no portal
    },
    {
        "sigla": "TCEMG",
        "nome": "Tribunal de Contas do Estado de Minas Gerais",
        "ckan_search": None,
        # Busca processual por CPF — preenche campo "Nr. CPF/CNPJ"
        "web_search": "https://www.tce.mg.gov.br/Processo/",
        "resource_id_responsaveis": None,
        "infosimples_endpoint": None,
        "web_params_fn": lambda nome: {"nrCpfCnpj": "", "nmResponsavel": nome},
        "cpf_param": "nrCpfCnpj",
    },
    {
        "sigla": "TCERJ",
        "nome": "Tribunal de Contas do Estado do Rio de Janeiro",
        "ckan_search": None,
        "web_search": "https://www.tcerj.tc.br/portalnovo/pesquisar",
        "resource_id_responsaveis": None,
        "infosimples_endpoint": None,
        "web_params_fn": lambda nome: {"q": nome},
        "cpf_param": None,
    },
]


def _normalize(s: str) -> str:
    s = unicodedata.normalize("NFD", s)
    return "".join(c for c in s if unicodedata.category(c) != "Mn").lower().strip()


def _nome_presente(nome: str, texto: str) -> bool:
    tokens = [t for t in _normalize(nome).split() if len(t) > 3]
    texto_n = _normalize(texto)
    return sum(1 for t in tokens if t in texto_n) >= 2


def _via_infosimples(tribunal: dict, cpf: str) -> list[dict]:
    """Tenta Infosimples se INFOSIMPLES_TOKEN configurado (TCE-SP apenados)."""
    _token = __import__("os").environ.get("INFOSIMPLES_TOKEN", "")
    endpoint = tribunal.get("infosimples_endpoint")
    if not _token or not endpoint:
        return []
    try:
        resp = requests.get(
            endpoint,
            params={"token": _token, "cpf": cpf, "timeout": 600},
            timeout=30,
        )
        if resp.ok:
            data = resp.json()
            if data.get("code") == 200:
                registros = data.get("data", [])
                return [{"tribunal": tribunal["sigla"], **r} for r in registros]
    except Exception as e:
        logger.debug("Infosimples TCE %s: %s", tribunal["sigla"], e)
    return []


def _via_web(tribunal: dict, nome: str, cpf: str = "") -> list[dict]:
    """Tenta busca via portal web do TCE (scraping básico). Usa CPF se disponível."""
    params = tribunal["web_params_fn"](nome)
    # Injeta CPF se o tribunal aceita busca por documento
    if cpf and tribunal.get("cpf_param"):
        params[tribunal["cpf_param"]] = cpf

    try:
        resp = requests.get(
            tribunal["web_search"],
            params=params,
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
                data.get("responsaveis") or data.get("results") or
                data.get("items") or data.get("data") or []
            )
            return [{"tribunal": tribunal["sigla"], **i} for i in items if isinstance(i, dict)]

        # HTML fallback: extrai linhas com o nome e palavras-chave de irregularidade
        html = resp.text
        resultados = []
        # Tenta linhas de tabela HTML
        rows = re.findall(r"<tr[^>]*>(.*?)</tr>", html, re.DOTALL | re.IGNORECASE)
        for row in rows:
            texto = re.sub(r"<[^>]+>", " ", row)
            texto = re.sub(r"\s+", " ", texto).strip()
            if _nome_presente(nome, texto) and len(texto) > 20:
                resultados.append({
                    "tribunal": tribunal["sigla"],
                    "texto": texto[:400],
                    "nome_responsavel": nome,
                })
        return resultados[:5]
    except Exception as e:
        logger.debug("TCE web %s: %s", tribunal["sigla"], e)
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


class TCEEstaduaisPFConnector(SubradarSource):
    """
    Verifica se o nome da PF consta em processos de irregularidade nos TCE de SP, MG e RJ.
    Busca via API CKAN e fallback web dos portais de dados abertos.
    Gracioso se os portais estiverem indisponíveis.
    Requer 'razao_social' (nome completo) — sem nome, não executa.
    """
    fonte = "tce_estaduais"
    request_delay = 2.0

    def consultar_cnpj(self, cnpj_or_cpf: str, razao_social: str | None = None, **_) -> list[dict]:
        nome = razao_social or ""
        if not nome or len(nome.split()) < 2:
            logger.debug("tce_estaduais_pf: nome ausente — pulando")
            return []

        cpf = re.sub(r"\D", "", str(cnpj_or_cpf or ""))
        cpf_fmt = f"{cpf[:3]}.{cpf[3:6]}.{cpf[6:9]}-{cpf[9:11]}" if len(cpf) == 11 else cpf

        alertas = []

        for tribunal in _TRIBUNAIS:
            # TCE-SP: Infosimples tem endpoint estruturado para apenados por CPF
            registros = _via_infosimples(tribunal, cpf)
            if not registros:
                registros = _via_web(tribunal, nome, cpf)

            for reg in registros:
                # Verifica se o nome aparece no registro
                texto_reg = " ".join(str(v) for v in reg.values() if isinstance(v, str))
                if not _nome_presente(nome, texto_reg):
                    continue

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

                desc_partes = [
                    f"Processo {tribunal['sigla']} n° {processo}",
                ]
                if situacao:
                    desc_partes.append(f"situação: {situacao}")
                if entidade:
                    desc_partes.append(f"entidade: {entidade}")
                desc_partes.append(
                    "Responsável com irregularidade apontada pelo Tribunal de Contas."
                )

                logger.info("tce_estaduais_pf: [%s] processo %s no %s para '%s'",
                            severidade, processo, tribunal["sigla"], nome)

                alertas.append({
                    "fonte": self.fonte,
                    "categoria": "controle",
                    "severidade": severidade,
                    "titulo": f"{tribunal['sigla']} — irregularidade: {cpf_fmt}",
                    "descricao": ". ".join(desc_partes),
                    "url_fonte": tribunal["web_search"],
                    "referencia_id": str(processo),
                    "is_novo": True,
                })

        logger.info("tce_estaduais_pf: %d alerta(s) para '%s'", len(alertas), nome)
        return alertas
