"""
Conector: CREA/CONFEA e CAU — situação de registro de engenheiro e arquiteto

CREA/CONFEA — Portal de Consulta Profissional (consultaprofissional.confea.org.br)
  Sistema ASP.NET WebForms. Consulta pública por CPF via requisição POST com ViewState.
  Sem autenticação e sem CAPTCHA confirmado na rota de consulta pública.
  Cobre todos os CREAs nacionais (CONFEA é conselho federal, agrega os regionais).

CAU-BR — "Ache um Arquiteto" (acheumarquiteto.caubr.gov.br)
  SPA com chamadas XHR. Endpoint: /api/pesquisa?cpf={cpf} (inferido de DevTools).
  Fallback via Implanta API se IMPLANTA_API_TOKEN estiver configurado.

Lógica de alerta:
  - Registro encontrado E situação ≠ ativo/regular → alerta 'atencao'
  - Registro não encontrado → sem alerta (profissional pode não ser da área)
  - Situação ativa → sem alerta

Env vars:
  IMPLANTA_API_TOKEN (opcional) — melhora cobertura via Implanta nacional
"""
from __future__ import annotations

import logging
import os
import re
import unicodedata

import requests

from .base import SubradarSource

logger = logging.getLogger("subradar.crea_cau_pf")

IMPLANTA_TOKEN = os.environ.get("IMPLANTA_API_TOKEN", "")

_ATIVO = {"ativo", "regular", "quite", "habilitado", "em dia", "ativo permanente", "inscrito"}

_CONFEA_URL = "https://consultaprofissional.confea.org.br/"
_CAU_XHR_URL = "https://acheumarquiteto.caubr.gov.br/api/pesquisa"
_IMPLANTA_CAU_URL = "https://cau-br.implanta.net.br/portaltransparencia/api/dadosabertos/profissionais"

_HEADERS_BROWSER = {
    "User-Agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/126.0.0.0 Safari/537.36"
    ),
    "Accept": "application/json, text/plain, */*",
}


def _strip(cpf: str) -> str:
    return re.sub(r"\D", "", str(cpf or ""))


def _normalize(s: str) -> str:
    s = unicodedata.normalize("NFD", s)
    return "".join(c for c in s if unicodedata.category(c) != "Mn").upper().strip()


def _situacao_ok(situacao: str) -> bool:
    return any(a in situacao for a in _ATIVO)


# ---------------------------------------------------------------------------
# CONFEA — consulta pública por CPF
# ---------------------------------------------------------------------------

def _consultar_confea(cpf: str) -> list[dict]:
    """
    Tenta consulta REST e fallback via form ASP.NET no portal CONFEA.
    O portal é WebForms mas pode expor endpoint JSON internamente.
    """
    # Tentativa 1: endpoint JSON interno (padrão em algumas instâncias CONFEA)
    tentativas_json = [
        f"https://consultaprofissional.confea.org.br/api/profissional?cpf={cpf}",
        f"https://consultaprofissional.confea.org.br/Profissional/BuscarPorCPF?cpf={cpf}",
        f"https://consultaprofissional.confea.org.br/profissional/consulta?cpf={cpf}",
    ]
    for url in tentativas_json:
        try:
            resp = requests.get(url, headers=_HEADERS_BROWSER, timeout=10)
            if resp.ok and "application/json" in resp.headers.get("Content-Type", ""):
                data = resp.json()
                if isinstance(data, list):
                    return data
                if isinstance(data, dict) and data:
                    return [data]
        except Exception:
            pass

    # Tentativa 2: POST WebForms — precisa do ViewState inicial
    try:
        # Primeiro GET para pegar ViewState
        init = requests.get(
            _CONFEA_URL,
            headers={**_HEADERS_BROWSER, "Accept": "text/html,application/xhtml+xml"},
            timeout=10,
        )
        if not init.ok:
            return []

        # Extrai __VIEWSTATE e __VIEWSTATEGENERATOR do HTML
        html = init.text
        vs_match = re.search(r'__VIEWSTATE[^>]*value="([^"]*)"', html)
        vsg_match = re.search(r'__VIEWSTATEGENERATOR[^>]*value="([^"]*)"', html)
        ev_match = re.search(r'__EVENTVALIDATION[^>]*value="([^"]*)"', html)

        viewstate = vs_match.group(1) if vs_match else ""
        viewstate_gen = vsg_match.group(1) if vsg_match else ""
        event_validation = ev_match.group(1) if ev_match else ""

        payload = {
            "__VIEWSTATE": viewstate,
            "__VIEWSTATEGENERATOR": viewstate_gen,
            "__EVENTVALIDATION": event_validation,
            "__EVENTTARGET": "ctl00$cphConteudo$btnConsultar",
            "ctl00$cphConteudo$txtCPF": cpf,
            "ctl00$cphConteudo$rdlTipoBusca": "CPF",
        }
        post = requests.post(
            _CONFEA_URL,
            data=payload,
            headers={**_HEADERS_BROWSER, "Content-Type": "application/x-www-form-urlencoded"},
            timeout=15,
        )
        if not post.ok:
            return []

        # Tenta extrair dados da resposta HTML (tabela de resultados)
        return _parse_confea_html(post.text, cpf)

    except Exception as e:
        logger.debug("CONFEA WebForms: %s", e)
        return []


def _parse_confea_html(html: str, cpf: str) -> list[dict]:
    """Extrai registros de profissional de tabela HTML do CONFEA."""
    # Busca padrões comuns em tabelas de resultado CONFEA
    situacao_match = re.search(
        r"(Situação|Situacao|Status)[:\s]*<[^>]*>([^<]+)<",
        html, re.IGNORECASE
    )
    nome_match = re.search(
        r"(Nome)[:\s]*<[^>]*>([^<]+)<",
        html, re.IGNORECASE
    )
    registro_match = re.search(
        r"(Registro|Número)[:\s]*<[^>]*>([^<]+)<",
        html, re.IGNORECASE
    )

    # Se não encontrou indicativo de resultado, assume sem registro
    if not situacao_match and "nenhum" in html.lower():
        return []
    if not situacao_match:
        return []

    return [{
        "conselho": "CREA/CONFEA",
        "nome": nome_match.group(2).strip() if nome_match else "",
        "registro": registro_match.group(2).strip() if registro_match else "",
        "situacao": situacao_match.group(2).strip(),
        "cpf": cpf,
    }]


# ---------------------------------------------------------------------------
# CAU — "Ache um Arquiteto"
# ---------------------------------------------------------------------------

def _consultar_cau(cpf: str) -> list[dict]:
    """
    Consulta CAU-BR por CPF via endpoint XHR do portal "Ache um Arquiteto"
    e/ou via Implanta API.
    """
    resultados = []

    # Tentativa 1: endpoint XHR do portal CAU
    for url in [
        f"{_CAU_XHR_URL}?cpf={cpf}",
        f"https://acheumarquiteto.caubr.gov.br/api/profissional/buscar?cpf={cpf}",
        f"https://acheumarquiteto.caubr.gov.br/busca?cpf={cpf}",
    ]:
        try:
            resp = requests.get(url, headers=_HEADERS_BROWSER, timeout=10)
            if resp.ok and "json" in resp.headers.get("Content-Type", ""):
                data = resp.json()
                if isinstance(data, list) and data:
                    return [{"conselho": "CAU-BR", **r} for r in data]
                if isinstance(data, dict) and data.get("profissionais"):
                    return [{"conselho": "CAU-BR", **r} for r in data["profissionais"]]
                if isinstance(data, dict) and data.get("cpf"):
                    return [{"conselho": "CAU-BR", **data}]
        except Exception:
            pass

    # Tentativa 2: Implanta API pública CAU
    try:
        resp = requests.get(
            _IMPLANTA_CAU_URL,
            params={"cpf": cpf},
            headers=_HEADERS_BROWSER,
            timeout=10,
        )
        if resp.ok and "json" in resp.headers.get("Content-Type", ""):
            data = resp.json()
            registros = data if isinstance(data, list) else data.get("data", data.get("profissionais", []))
            for reg in registros:
                resultados.append({"conselho": "CAU-BR", **reg})
    except Exception as e:
        logger.debug("CAU Implanta: %s", e)

    # Tentativa 3: Implanta com token
    if not resultados and IMPLANTA_TOKEN:
        try:
            resp = requests.get(
                "https://api.implantasistemas.com.br/v1/profissionais",
                params={"cpf": cpf, "token": IMPLANTA_TOKEN, "conselho": "CAU"},
                timeout=15,
            )
            if resp.ok:
                data = resp.json()
                lista = data if isinstance(data, list) else [data] if isinstance(data, dict) else []
                for reg in lista:
                    resultados.append({"conselho": "CAU-BR", **reg})
        except Exception as e:
            logger.debug("CAU Implanta token: %s", e)

    return resultados


# ---------------------------------------------------------------------------
# Processamento de alertas
# ---------------------------------------------------------------------------

def _processar_registros(registros: list[dict], cpf_fmt: str, fonte_id: str) -> list[dict]:
    alertas = []
    for reg in registros:
        conselho = reg.get("conselho", "Conselho")
        situacao = (
            reg.get("situacao") or
            reg.get("status") or
            reg.get("situacaoInscricao") or ""
        ).lower().strip()

        if not situacao:
            continue

        if _situacao_ok(situacao):
            logger.debug("%s: %s — %s (regular)", conselho, cpf_fmt, situacao)
            continue

        numero = (
            reg.get("registro") or
            reg.get("numero") or
            reg.get("inscricao") or
            reg.get("numeroCau") or
            reg.get("numeroCrea") or "s/n"
        )
        nome = reg.get("nome") or reg.get("nomeProfissional") or ""

        descricao_partes = [f"Registro n° {numero} no {conselho} com situação '{situacao.upper()}'"]
        if nome:
            descricao_partes.append(f"Profissional: {nome}")

        alertas.append({
            "fonte": fonte_id,
            "categoria": "cadastral",
            "severidade": "atencao",
            "titulo": f"{conselho} — registro {situacao.upper()}: {cpf_fmt}",
            "descricao": ". ".join(descricao_partes) + ". Profissional pode estar impedido de exercer a atividade.",
            "url_fonte": "https://consultaprofissional.confea.org.br/" if "CREA" in conselho else "https://acheumarquiteto.caubr.gov.br/",
            "referencia_id": str(numero),
            "is_novo": True,
        })
    return alertas


# ---------------------------------------------------------------------------
# Conectores
# ---------------------------------------------------------------------------

class CREACONFEAPFConnector(SubradarSource):
    """
    Verifica situação do registro de engenheiro/agrônomo no CREA/CONFEA.
    Consulta o portal público do CONFEA (cobre todos os CREAs nacionais).
    Gracioso se o portal estiver indisponível ou retornar erro.
    """
    fonte = "crea_confea"
    request_delay = 1.5

    def consultar_cnpj(self, cnpj_or_cpf: str, **_) -> list[dict]:
        cpf = _strip(cnpj_or_cpf)
        if len(cpf) != 11:
            return []

        cpf_fmt = f"{cpf[:3]}.{cpf[3:6]}.{cpf[6:9]}-{cpf[9:11]}"
        registros = _consultar_confea(cpf)

        if not registros:
            logger.debug("crea_confea: sem registro para CPF %s***", cpf[:3])
            return []

        return _processar_registros(registros, cpf_fmt, self.fonte)


class CAUBRPFConnector(SubradarSource):
    """
    Verifica situação do registro de arquiteto e urbanista no CAU-BR.
    Usa o portal "Ache um Arquiteto" (CAU-BR) e, como fallback, a Implanta API.
    Gracioso se os endpoints estiverem indisponíveis.
    """
    fonte = "cau_br"
    request_delay = 1.5

    def consultar_cnpj(self, cnpj_or_cpf: str, **_) -> list[dict]:
        cpf = _strip(cnpj_or_cpf)
        if len(cpf) != 11:
            return []

        cpf_fmt = f"{cpf[:3]}.{cpf[3:6]}.{cpf[6:9]}-{cpf[9:11]}"
        registros = _consultar_cau(cpf)

        if not registros:
            logger.debug("cau_br: sem registro para CPF %s***", cpf[:3])
            return []

        return _processar_registros(registros, cpf_fmt, self.fonte)
