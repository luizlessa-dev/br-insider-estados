"""
Conector: Mídia Adversa GDELT — menções negativas de Pessoa Jurídica em portais de notícias

Utiliza a GDELT Doc API (gratuita, sem autenticação) para buscar artigos recentes
sobre a razão social da empresa em português brasileiro nos últimos 90 dias.

GDELT Doc API:
  https://api.gdeltproject.org/api/v2/doc/doc
  Parâmetros:
    query=    — expressão de busca (suporta operadores booleanos e site:)
    mode=     — ArtList (lista de artigos) | TimelineVol (volume temporal)
    maxrecords= — máximo de registros
    timespan=  — 1w, 2w, 30d, 90d (máximo: 3 meses)
    sourcelang= — por idioma (por = Português)
    format=   — json

Cobertura:
  - Indexa centenas de portais brasileiros (G1, Folha, UOL, Metrópoles, etc.)
  - Atualização a cada 15 minutos
  - Gratuito, sem limite de requisições documentado
  - Cobertura mais ampla que NewsAPI para veículos regionais brasileiros

Classificação:
  1. Tenta via Claude Haiku (ANTHROPIC_API_KEY) — mais preciso
  2. Fallback: keyword matching em PT-BR

Env vars:
  ANTHROPIC_API_KEY — para classificação via Claude Haiku (opcional, já existe no pipeline)

Sem nenhum env var: roda com keyword fallback (gratuito).
"""
from __future__ import annotations

import logging
import os
import re
import unicodedata
from datetime import datetime, timezone
from urllib.parse import quote_plus

import requests

from .base import SubradarSource

logger = logging.getLogger("subradar.midia_adversa_gdelt_pj")

ANTHROPIC_KEY = os.environ.get("ANTHROPIC_API_KEY", "")

_GDELT_URL = "https://api.gdeltproject.org/api/v2/doc/doc"
_HAIKU_URL = "https://api.anthropic.com/v1/messages"
_HAIKU_MODEL = "claude-haiku-4-5-20251001"

_STOPWORDS = {
    "de", "do", "da", "dos", "das", "e", "em", "a", "o", "os", "as",
    "ltda", "sa", "s/a", "me", "epp", "eireli", "cia", "soc",
    "com", "para", "por", "que", "se", "no", "na",
}

_CRITICO_KW = {
    "falência", "concordata", "recuperação judicial",
    "fraude contábil", "fraude", "estelionato", "lavagem",
    "corrupção", "desvio", "operação policial", "lava jato",
    "intervenção", "liquidação", "busca e apreensão",
    "indiciado", "indiciada", "investigado", "investigada",
    "preso", "presa", "condenado", "condenada",
    "crime", "criminoso", "réu", "ré", "prisão",
    "operação da polícia", "operação federal",
}
_ATENCAO_KW = {
    "ação civil pública", "improbidade", "autuação", "descredenciamento",
    "recall", "interdição", "processo", "ação judicial",
    "multa", "irregularidade", "denúncia", "denunciado", "denunciada",
    "suspeito", "suspeita", "investigação", "inquérito",
    "cade", "mpf", "mpe", "ministério público", "tce", "tcu",
    "reclamação", "autuado", "autuada", "embargo", "interdito",
}


def _normalize(s: str) -> str:
    s = unicodedata.normalize("NFD", s)
    return "".join(c for c in s if unicodedata.category(c) != "Mn").lower().strip()


def _nome_presente(razao_social: str, texto: str) -> bool:
    tokens = [t for t in _normalize(razao_social).split() if t not in _STOPWORDS and len(t) > 2]
    if not tokens:
        return False
    texto_n = _normalize(texto)
    return any(t in texto_n for t in tokens)


def _buscar_noticias_gdelt(razao_social: str, dias: int = 90) -> list[dict]:
    """Busca artigos via GDELT Doc API."""
    timespan = f"{min(dias, 90)}d"
    # Cota razoável: até 10 artigos por consulta
    try:
        resp = requests.get(
            _GDELT_URL,
            params={
                "query": f'"{razao_social}" sourcelang:por',
                "mode": "ArtList",
                "maxrecords": 10,
                "timespan": timespan,
                "format": "json",
            },
            timeout=20,
        )
        if not resp.ok:
            logger.debug("GDELT: HTTP %d", resp.status_code)
            return []
        data = resp.json()
        return data.get("articles", [])
    except Exception as e:
        logger.debug("GDELT: %s", e)
        return []


def _classificar_artigo_haiku(titulo: str, descricao: str, razao_social: str) -> dict:
    if not ANTHROPIC_KEY:
        return _classificar_keywords(titulo, descricao)

    prompt = (
        f'Você é um analista de compliance. Classifique se este artigo jornalístico '
        f'é adverso para a empresa (pessoa jurídica) "{razao_social}".\n\n'
        f"Título: {titulo[:300]}\n"
        f"Descrição: {(descricao or '')[:400]}\n\n"
        'Responda em uma linha no formato JSON:\n'
        '{"adverso": true/false, "severidade": "critico"/"atencao"/"nenhum", "motivo": "resumo em 10 palavras"}\n\n'
        "Critérios para empresa:\n"
        "- critico: falência, recuperação judicial, fraude contábil, operação policial, lava jato, "
        "intervenção, liquidação, condenação, desvio de verba, investigação criminal\n"
        "- atencao: ação civil pública, improbidade, autuação, descredenciamento, recall, "
        "interdição, processo judicial, multa relevante, denúncia formal, inquérito\n"
        "- nenhum: menção neutra, parceria, expansão, contratação, resultado financeiro positivo"
    )

    try:
        resp = requests.post(
            _HAIKU_URL,
            json={
                "model": _HAIKU_MODEL,
                "max_tokens": 80,
                "messages": [{"role": "user", "content": prompt}],
            },
            headers={
                "x-api-key": ANTHROPIC_KEY,
                "anthropic-version": "2023-06-01",
                "Content-Type": "application/json",
            },
            timeout=15,
        )
        if resp.ok:
            import json
            texto = resp.json()["content"][0]["text"].strip()
            match = re.search(r"\{.*\}", texto, re.DOTALL)
            if match:
                return json.loads(match.group())
    except Exception as e:
        logger.debug("Haiku classificação PJ: %s", e)

    return _classificar_keywords(titulo, descricao)


def _classificar_keywords(titulo: str, descricao: str) -> dict:
    texto = _normalize(f"{titulo} {descricao or ''}")
    for kw in _CRITICO_KW:
        if kw in texto:
            return {"adverso": True, "severidade": "critico", "motivo": f"menção a '{kw}'"}
    for kw in _ATENCAO_KW:
        if kw in texto:
            return {"adverso": True, "severidade": "atencao", "motivo": f"menção a '{kw}'"}
    return {"adverso": False, "severidade": "nenhum", "motivo": "sem indicativo"}


class MidiaAdversaGDELTPJConnector(SubradarSource):
    """
    Busca menções adversas da razão social em portais jornalísticos via GDELT Doc API.
    Gratuito, sem autenticação, cobertura ampla de veículos brasileiros.
    Classifica com Haiku (fallback: keywords).
    """
    fonte = "midia_adversa_pj"
    request_delay = 1.0

    def consultar_cnpj(self, cnpj: str, razao_social: str | None = None, **_) -> list[dict]:
        razao = razao_social or ""
        if not razao:
            logger.debug("midia_adversa_gdelt_pj: razao_social ausente — pulando")
            return []

        cnpj_digits = re.sub(r"\D", "", str(cnpj or ""))
        cnpj_fmt = (
            f"{cnpj_digits[:2]}.{cnpj_digits[2:5]}.{cnpj_digits[5:8]}/"
            f"{cnpj_digits[8:12]}-{cnpj_digits[12:14]}"
            if len(cnpj_digits) == 14
            else cnpj_digits
        )

        artigos = _buscar_noticias_gdelt(razao)
        if not artigos:
            logger.debug("midia_adversa_gdelt_pj: sem notícias para '%s'", razao)
            return []

        alertas = []
        for art in artigos:
            titulo = art.get("title") or art.get("seendate") or ""
            url = art.get("url") or ""
            dominio = art.get("domain") or ""
            lingua = art.get("language") or ""
            data_pub = (art.get("seendate") or "")[:8]
            if data_pub and len(data_pub) == 8:
                data_pub = f"{data_pub[:4]}-{data_pub[4:6]}-{data_pub[6:]}"
            descricao = ""  # GDELT ArtList não retorna snippet no modo padrão

            # Filtro: nome deve aparecer no título
            if not _nome_presente(razao, titulo):
                continue

            # Filtro: só português
            if lingua and lingua.lower() not in ("por", "portuguese", "pt"):
                continue

            classificacao = _classificar_artigo_haiku(titulo, descricao, razao)
            if not classificacao.get("adverso"):
                continue

            severidade = classificacao.get("severidade", "atencao")
            motivo = classificacao.get("motivo", "")

            logger.info("midia_adversa_gdelt_pj: artigo adverso [%s] — '%s' (%s)",
                        severidade, titulo[:60], dominio)

            alertas.append({
                "fonte": self.fonte,
                "categoria": "reputacao",
                "severidade": severidade,
                "titulo": f"Mídia adversa PJ — {dominio}: {titulo[:120]}",
                "descricao": (
                    f"Artigo publicado em {data_pub} por {dominio}. "
                    f"Motivo da classificação: {motivo}. "
                    f"Fonte: GDELT / {dominio}."
                ),
                "url_fonte": url,
                "referencia_id": re.sub(r"\W+", "-", titulo[:50]).lower(),
                "data_evento": data_pub or None,
                "is_novo": True,
            })

        logger.info("midia_adversa_gdelt_pj: %d alerta(s) para '%s' (%s)",
                    len(alertas), razao, cnpj_fmt)
        return alertas
