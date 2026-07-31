"""
Conector: Mídia Adversa GDELT — menções negativas de Pessoa Física em portais de notícias

Utiliza a GDELT Doc API (gratuita, sem autenticação) para buscar artigos recentes
sobre o nome da pessoa em português brasileiro nos últimos 90 dias.

Diferenças em relação ao conector PJ:
  - Requer presença de pelo menos 2 tokens do nome no título (evita falsos positivos)
  - Prompt Haiku adaptado para contexto de pessoa física

Env vars:
  ANTHROPIC_API_KEY — para classificação via Claude Haiku (opcional)

Sem env vars: roda com keyword fallback (gratuito).
"""
from __future__ import annotations

import logging
import os
import re
import unicodedata

import requests

from .base import SubradarSource

logger = logging.getLogger("subradar.midia_adversa_gdelt_pf")

ANTHROPIC_KEY = os.environ.get("ANTHROPIC_API_KEY", "")

_GDELT_URL = "https://api.gdeltproject.org/api/v2/doc/doc"
_HAIKU_URL = "https://api.anthropic.com/v1/messages"
_HAIKU_MODEL = "claude-haiku-4-5-20251001"

_STOPWORDS = {
    "de", "do", "da", "dos", "das", "e", "em", "a", "o", "os", "as",
    "sr", "sra", "dr", "dra",
}

_CRITICO_KW = {
    "preso", "presa", "condenado", "condenada", "prisão", "detido", "detida",
    "investigado", "investigada", "indiciado", "indiciada",
    "fraude", "corrupção", "desvio", "estelionato", "lavagem",
    "operação policial", "busca e apreensão", "réu", "ré",
    "tráfico", "homicídio", "assassinato", "crime",
}
_ATENCAO_KW = {
    "processo", "ação judicial", "multa", "irregularidade",
    "denúncia", "denunciado", "denunciada", "inquérito",
    "improbidade", "ministério público", "mpf", "mpe",
    "suspeito", "suspeita", "investigação",
    "autuado", "autuada", "condenado", "embargado",
}


def _normalize(s: str) -> str:
    s = unicodedata.normalize("NFD", s)
    return "".join(c for c in s if unicodedata.category(c) != "Mn").lower().strip()


def _nome_presente(nome: str, texto: str, min_tokens: int = 2) -> bool:
    """Para PF: exige pelo menos 2 tokens do nome no texto para evitar falsos positivos."""
    tokens = [t for t in _normalize(nome).split() if t not in _STOPWORDS and len(t) > 2]
    if len(tokens) < 2:
        return False
    texto_n = _normalize(texto)
    matches = sum(1 for t in tokens if t in texto_n)
    return matches >= min(min_tokens, len(tokens))


def _buscar_noticias_gdelt(nome: str, dias: int = 90) -> list[dict]:
    timespan = f"{min(dias, 90)}d"
    try:
        resp = requests.get(
            _GDELT_URL,
            params={
                "query": f'"{nome}" sourcelang:por',
                "mode": "ArtList",
                "maxrecords": 5,
                "timespan": timespan,
                "format": "json",
            },
            timeout=20,
        )
        if not resp.ok:
            logger.debug("GDELT PF: HTTP %d", resp.status_code)
            return []
        return resp.json().get("articles", [])
    except Exception as e:
        logger.debug("GDELT PF: %s", e)
        return []


def _classificar_artigo_haiku(titulo: str, nome: str) -> dict:
    if not ANTHROPIC_KEY:
        return _classificar_keywords(titulo)

    prompt = (
        f'Você é um analista de compliance. Classifique se este artigo jornalístico '
        f'é adverso para a pessoa física "{nome}".\n\n'
        f"Título: {titulo[:300]}\n\n"
        'Responda em uma linha no formato JSON:\n'
        '{"adverso": true/false, "severidade": "critico"/"atencao"/"nenhum", "motivo": "resumo em 10 palavras"}\n\n'
        "Critérios para pessoa física:\n"
        "- critico: prisão, condenação, investigação criminal, fraude, corrupção, tráfico, homicídio\n"
        "- atencao: processo judicial, improbidade, denúncia formal, inquérito, irregularidade\n"
        "- nenhum: menção neutra, homenagem, entrevista, evento, cargo público sem acusação"
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
        logger.debug("Haiku classificação PF: %s", e)

    return _classificar_keywords(titulo)


def _classificar_keywords(titulo: str) -> dict:
    texto = _normalize(titulo)
    for kw in _CRITICO_KW:
        if kw in texto:
            return {"adverso": True, "severidade": "critico", "motivo": f"menção a '{kw}'"}
    for kw in _ATENCAO_KW:
        if kw in texto:
            return {"adverso": True, "severidade": "atencao", "motivo": f"menção a '{kw}'"}
    return {"adverso": False, "severidade": "nenhum", "motivo": "sem indicativo"}


class MidiaAdversaGDELTPFConnector(SubradarSource):
    """
    Busca menções adversas do nome em portais jornalísticos via GDELT Doc API.
    Gratuito, sem autenticação. Exige ao menos 2 tokens do nome no título.
    Classifica com Haiku (fallback: keywords).
    """
    fonte = "midia_adversa_pf"
    request_delay = 1.0

    def consultar_cpf(self, cpf: str, nome: str | None = None, **_) -> list[dict]:
        if not nome:
            logger.debug("midia_adversa_gdelt_pf: nome ausente — pulando")
            return []

        cpf_digits = re.sub(r"\D", "", str(cpf or ""))
        cpf_fmt = (
            f"{cpf_digits[:3]}.{cpf_digits[3:6]}.{cpf_digits[6:9]}-{cpf_digits[9:]}"
            if len(cpf_digits) == 11
            else cpf_digits
        )

        artigos = _buscar_noticias_gdelt(nome)
        if not artigos:
            logger.debug("midia_adversa_gdelt_pf: sem notícias para '%s'", nome)
            return []

        alertas = []
        for art in artigos:
            titulo = art.get("title") or ""
            url = art.get("url") or ""
            dominio = art.get("domain") or ""
            lingua = art.get("language") or ""
            data_pub = (art.get("seendate") or "")[:8]
            if data_pub and len(data_pub) == 8:
                data_pub = f"{data_pub[:4]}-{data_pub[4:6]}-{data_pub[6:]}"

            if not _nome_presente(nome, titulo):
                continue

            if lingua and lingua.lower() not in ("por", "portuguese", "pt"):
                continue

            classificacao = _classificar_artigo_haiku(titulo, nome)
            if not classificacao.get("adverso"):
                continue

            severidade = classificacao.get("severidade", "atencao")
            motivo = classificacao.get("motivo", "")

            logger.info("midia_adversa_gdelt_pf: artigo adverso [%s] — '%s' (%s)",
                        severidade, titulo[:60], dominio)

            alertas.append({
                "fonte": self.fonte,
                "categoria": "reputacao",
                "severidade": severidade,
                "titulo": f"Mídia adversa PF — {dominio}: {titulo[:120]}",
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

        logger.info("midia_adversa_gdelt_pf: %d alerta(s) para '%s' (%s)",
                    len(alertas), nome, cpf_fmt)
        return alertas
