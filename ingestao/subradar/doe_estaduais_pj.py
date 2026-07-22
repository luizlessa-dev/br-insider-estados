"""
Conector: DOE Estaduais — Diários Oficiais de SP, MG e RJ — Pessoa Jurídica

Complementa o DOU federal (DO1/DO2/DO3) com publicações em diários estaduais.
Relevante para: empresas fornecedoras estaduais, concessionárias, prestadoras
de serviço sujeitas a regulação estadual em SP/MG/RJ.

Portais e APIs:
  SP  — Imprensa Oficial SP: doe.sp.gov.br (busca fulltext)
  MG  — IOIMPRENSA MG: jornal.iof.mg.gov.br (DSpace REST)
  RJ  — IOERJ: www.ioerj.com.br/portal/ (portal simples)

Busca por razão social (nome da empresa).
Classificação via keywords PJ ou Haiku se ANTHROPIC_API_KEY disponível.

Env vars:
  ANTHROPIC_API_KEY (opcional) — classificação mais precisa
  DOE_SP_TOKEN (opcional) — API key da Imprensa Oficial SP se disponível

Custo: gratuito para busca pública nos portais.
"""
from __future__ import annotations

import json
import logging
import os
import re
import unicodedata
from datetime import datetime, timedelta, timezone

import requests

from .base import SubradarSource

logger = logging.getLogger("subradar.doe_estaduais_pj")

ANTHROPIC_KEY = os.environ.get("ANTHROPIC_API_KEY", "")
DOE_SP_TOKEN = os.environ.get("DOE_SP_TOKEN", "")

_HAIKU_URL = "https://api.anthropic.com/v1/messages"
_HAIKU_MODEL = "claude-haiku-4-5-20251001"

_HEADERS = {
    "User-Agent": "subradar/1.0 compliance-check",
    "Accept": "application/json, text/html, */*",
}

_CRITICO_KW = {
    "interdição", "cassação de alvará", "cancelamento de licença",
    "rescisão contratual", "suspensão de atividades", "embargo",
    "apreensão", "lacração",
}
_ATENCAO_KW = {
    "autuada", "notificada", "penalidade", "multa", "advertência",
    "irregularidade", "descredenciamento", "habilitação cancelada",
}

_ESTADOS = [
    {
        "sigla": "SP",
        "nome": "São Paulo",
        "method": "GET",
        "url": "https://doe.sp.gov.br/busca-avancada",
        "params_fn": lambda razao, desde: {
            "q": f'"{razao}"',
            "dt_inicio": desde,
            "tipo": "qualquer",
        },
    },
    {
        "sigla": "MG",
        "nome": "Minas Gerais",
        "method": "GET",
        "url": "http://jornal.iof.mg.gov.br/rest/items",
        "params_fn": lambda razao, desde: {
            "query": razao,
            "limit": 5,
            "offset": 0,
        },
    },
    {
        "sigla": "RJ",
        "nome": "Rio de Janeiro",
        "method": "POST",
        "url": "https://www.ioerj.com.br/portal/modules/conteudoonline/busca_do.php",
        "params_fn": lambda razao, desde: {
            "Palavra-chave": razao,
            "Tipo": "Normal",
            "Ordem": "data_desc",
        },
    },
]


def _normalize(s: str) -> str:
    s = unicodedata.normalize("NFD", s)
    return "".join(c for c in s if unicodedata.category(c) != "Mn").lower()


def _nome_presente(razao: str, texto: str) -> bool:
    """Para PJ basta 1 token com >4 letras presente no texto."""
    tokens = _normalize(razao).split()
    texto_n = _normalize(texto)
    return any(len(t) > 4 and t in texto_n for t in tokens)


def _buscar_doe_estado(estado: dict, razao: str, dias: int = 90) -> list[dict]:
    """Tenta busca no portal DOE estadual. Gracioso em falha."""
    desde = (datetime.now(timezone.utc) - timedelta(days=dias)).strftime("%Y-%m-%d")
    metodo = estado.get("method", "GET").upper()
    params = estado["params_fn"](razao, desde)
    try:
        if metodo == "POST":
            resp = requests.post(
                estado["url"],
                data=params,
                headers={**_HEADERS, "Content-Type": "application/x-www-form-urlencoded"},
                timeout=12,
            )
        else:
            resp = requests.get(
                estado["url"],
                params=params,
                headers=_HEADERS,
                timeout=12,
            )
        if not resp.ok:
            logger.debug("DOE-%s: HTTP %d", estado["sigla"], resp.status_code)
            return []

        ct = resp.headers.get("Content-Type", "")
        if "json" in ct:
            data = resp.json()
            if isinstance(data, list):
                return [{"estado": estado["sigla"], **item} for item in data]
            docs = (
                data.get("docs") or data.get("results") or
                data.get("atos") or data.get("items") or []
            )
            return [{"estado": estado["sigla"], **d} for d in docs]

        html = resp.text
        return _parse_doe_html(html, razao, estado["sigla"])

    except Exception as e:
        logger.debug("DOE-%s: %s", estado["sigla"], e)
        return []


def _parse_doe_html(html: str, razao: str, sigla: str) -> list[dict]:
    """Extrai resultados básicos do HTML de busca DOE."""
    resultados = []
    blocos = re.findall(
        r"(?:class=['\"](?:resultado|ato|item|entry)['\"][^>]*>)(.*?)(?=class=['\"](?:resultado|ato|item|entry)['\"]|$)",
        html, re.DOTALL | re.IGNORECASE
    )
    if not blocos:
        paragrafos = re.findall(r"<p[^>]*>(.*?)</p>", html, re.DOTALL | re.IGNORECASE)
        blocos = [p for p in paragrafos if _nome_presente(razao, re.sub(r"<[^>]+>", " ", p))]

    for bloco in blocos[:5]:
        texto_limpo = re.sub(r"<[^>]+>", " ", bloco).strip()
        texto_limpo = re.sub(r"\s+", " ", texto_limpo)
        if _nome_presente(razao, texto_limpo):
            resultados.append({
                "estado": sigla,
                "texto": texto_limpo[:500],
                "titulo": texto_limpo[:100],
            })
    return resultados


def _classificar_doe(titulo: str, texto: str, razao: str, sigla: str) -> dict:
    """Classifica publicação via Haiku ou keywords PJ."""
    if ANTHROPIC_KEY:
        prompt = (
            f"Classifique esta publicação do Diário Oficial de {sigla} para a empresa '{razao}'.\n"
            f"Texto: {titulo[:200]} — {texto[:300]}\n"
            "Responda em JSON: "
            '{"adverso": true/false, "severidade": "critico"/"atencao"/"nenhum", "motivo": "10 palavras"}\n'
            "critico=interdição/embargo/cassação de alvará/rescisão contratual/suspensão de atividades/lacração, "
            "atencao=multa/autuação/notificação/irregularidade/descredenciamento, "
            "nenhum=contrato normal/credenciamento/publicação neutra"
        )
        try:
            resp = requests.post(
                _HAIKU_URL,
                json={"model": _HAIKU_MODEL, "max_tokens": 60,
                      "messages": [{"role": "user", "content": prompt}]},
                headers={"x-api-key": ANTHROPIC_KEY,
                         "anthropic-version": "2023-06-01",
                         "Content-Type": "application/json"},
                timeout=12,
            )
            if resp.ok:
                raw = resp.json()["content"][0]["text"]
                m = re.search(r"\{.*\}", raw, re.DOTALL)
                if m:
                    return json.loads(m.group())
        except Exception:
            pass

    # Fallback keywords PJ
    texto_n = _normalize(f"{titulo} {texto}")
    for kw in _CRITICO_KW:
        if kw in texto_n:
            return {"adverso": True, "severidade": "critico", "motivo": f"'{kw}'"}
    for kw in _ATENCAO_KW:
        if kw in texto_n:
            return {"adverso": True, "severidade": "atencao", "motivo": f"'{kw}'"}
    return {"adverso": False, "severidade": "nenhum", "motivo": "publicação neutra"}


class DOEEstaduaisPJConnector(SubradarSource):
    """
    Busca menções da razão social nos Diários Oficiais de SP, MG e RJ.
    Classifica publicações adversas com Haiku (fallback: keywords PJ).
    Gracioso se os portais DOE estiverem indisponíveis.
    """
    fonte = "doe_estaduais_pj"
    categoria = "regulatorio"
    request_delay = 1.5

    def consultar_cnpj(self, cnpj_or_cpf: str, razao_social: str | None = None, **_) -> list[dict]:
        razao = razao_social or ""
        razao_norm = _normalize(razao).strip()
        if not razao or len(razao_norm) < 2:
            logger.debug("doe_estaduais_pj: razao_social ausente ou muito curta — pulando")
            return []

        cnpj = re.sub(r"\D", "", str(cnpj_or_cpf or ""))

        alertas = []

        for estado in _ESTADOS:
            publicacoes = _buscar_doe_estado(estado, razao)
            for pub in publicacoes:
                titulo = pub.get("titulo") or pub.get("title") or pub.get("texto", "")[:100]
                texto = pub.get("texto") or pub.get("content") or pub.get("descricao") or ""
                data_pub = pub.get("data") or pub.get("date") or pub.get("dataPublicacao") or ""

                if not _nome_presente(razao, f"{titulo} {texto}"):
                    continue

                classif = _classificar_doe(titulo, texto, razao, estado["sigla"])
                if not classif.get("adverso"):
                    continue

                severidade = classif.get("severidade", "atencao")
                motivo = classif.get("motivo", "")
                sigla = estado["sigla"]

                logger.info("doe_estaduais_pj: publicação [%s] no DOE-%s para '%s'",
                            severidade, sigla, razao)

                alertas.append({
                    "fonte": self.fonte,
                    "categoria": self.categoria,
                    "severidade": severidade,
                    "titulo": f"DOE-{sigla} — {titulo[:120]}",
                    "descricao": (
                        f"Publicação no Diário Oficial de {estado['nome']}"
                        + (f" em {data_pub[:10]}" if data_pub else "") + ". "
                        f"Motivo: {motivo}. Extrato: {texto[:300]}"
                    ),
                    "url_fonte": estado["url"],
                    "data_evento": data_pub[:10] if data_pub else None,
                    "is_novo": True,
                })

        logger.info("doe_estaduais_pj: %d alerta(s) para '%s'", len(alertas), razao)
        return alertas
