"""
Conector: Mídia Adversa — menções negativas em portais de notícias

Busca artigos sobre o nome da pessoa em portais jornalísticos brasileiros
nos últimos 90 dias e classifica se são desfavoráveis usando Haiku.

Fontes buscadas (via NewsAPI.org):
  - G1 (g1.globo.com)
  - Folha de S. Paulo (folha.uol.com.br)
  - UOL (noticias.uol.com.br)
  - O Globo (oglobo.globo.com)
  - Correio Braziliense
  + qualquer portal em pt (language=pt)

Env vars:
  NEWSAPI_KEY       — chave da NewsAPI.org (~USD 50/mês no plano Developer)
  ANTHROPIC_API_KEY — para classificação via Claude Haiku (já existe no pipeline)

Custo:
  NewsAPI: ~USD 0,004 por chamada (plano Developer: 500 req/dia grátis; pago a partir de 100k/mês)
  Haiku: ~USD 0,00025 por artigo classificado

Lógica:
  1. Busca os 5 artigos mais recentes com o nome como query
  2. Filtra artigos com pelo menos 2 palavras do nome no título ou descrição
  3. Classifica via Haiku se são adversos (crime, processo, irregularidade, etc.)
  4. Gera alerta 'atencao' por artigo adverso confirmado
  5. Gera alerta 'critico' se artigo mencionar prisão, condenação ou fraude

Sem NEWSAPI_KEY: gracioso (não roda).
Sem ANTHROPIC_API_KEY: usa keyword fallback para classificação.
"""
from __future__ import annotations

import logging
import os
import re
import unicodedata
from datetime import datetime, timedelta, timezone

import requests

from .base import SubradarSource

logger = logging.getLogger("subradar.midia_adversa_pf")

NEWSAPI_KEY = os.environ.get("NEWSAPI_KEY", "")
ANTHROPIC_KEY = os.environ.get("ANTHROPIC_API_KEY", "")

_NEWSAPI_URL = "https://newsapi.org/v2/everything"
_HAIKU_URL = "https://api.anthropic.com/v1/messages"
_HAIKU_MODEL = "claude-haiku-4-5-20251001"

# Palavras-chave que indicam matéria adversa (fallback sem Haiku)
_CRITICO_KW = {
    "preso", "presa", "preso preventivo", "condenado", "condenada",
    "fraude", "estelionato", "lavagem", "corrupção", "desvio",
    "indiciado", "indiciada", "investigado", "investigada",
    "operação policial", "busca e apreensão", "réu", "ré",
    "prisão", "detido", "detida", "crime", "criminoso",
}
_ATENCAO_KW = {
    "processo", "ação judicial", "autuado", "autuada", "multa",
    "irregularidade", "denúncia", "denunciado", "denunciada",
    "suspeito", "suspeita", "investigação", "inquérito",
    "cade", "mpf", "mpe", "ministério público", "tce", "tcu",
    "reclamação", "improbidade", "habeas corpus",
}

# Domínios de portais jornalísticos confiáveis para filtrar ruído
_DOMINIOS_CONFIAVEIS = {
    "g1.globo.com", "folha.uol.com.br", "uol.com.br", "oglobo.globo.com",
    "correiobraziliense.com.br", "estadao.com.br", "veja.abril.com.br",
    "gazetadopovo.com.br", "terra.com.br", "r7.com", "cnn.com.br",
    "metropoles.com", "agenciabrasil.ebc.com.br", "bbc.com/portuguese",
    "reuters.com", "valor.globo.com",
}


def _normalize(s: str) -> str:
    s = unicodedata.normalize("NFD", s)
    return "".join(c for c in s if unicodedata.category(c) != "Mn").lower().strip()


def _nome_presente(nome: str, texto: str) -> bool:
    """Verifica se pelo menos 2 tokens do nome aparecem no texto."""
    tokens = _normalize(nome).split()
    texto_n = _normalize(texto)
    presentes = sum(1 for t in tokens if len(t) > 2 and t in texto_n)
    return presentes >= 2


def _buscar_noticias(nome: str, dias: int = 90) -> list[dict]:
    """Busca artigos via NewsAPI.org."""
    desde = (datetime.now(timezone.utc) - timedelta(days=dias)).strftime("%Y-%m-%d")
    try:
        resp = requests.get(
            _NEWSAPI_URL,
            params={
                "q": f'"{nome}"',
                "language": "pt",
                "from": desde,
                "sortBy": "relevancy",
                "pageSize": 10,
                "apiKey": NEWSAPI_KEY,
            },
            timeout=15,
        )
        if not resp.ok:
            logger.debug("NewsAPI: HTTP %d", resp.status_code)
            return []
        data = resp.json()
        return data.get("articles", [])
    except Exception as e:
        logger.debug("NewsAPI: %s", e)
        return []


def _classificar_artigo_haiku(titulo: str, descricao: str, nome: str) -> dict:
    """
    Usa Claude Haiku para classificar se o artigo é adverso para a pessoa.
    Retorna {"adverso": bool, "severidade": "critico"|"atencao"|"nenhum", "motivo": str}
    """
    if not ANTHROPIC_KEY:
        return _classificar_keywords(titulo, descricao)

    prompt = f"""Você é um analista de compliance. Classifique se este artigo jornalístico é adverso para a pessoa "{nome}".

Título: {titulo[:300]}
Descrição: {(descricao or '')[:400]}

Responda em uma linha no formato JSON:
{{"adverso": true/false, "severidade": "critico"/"atencao"/"nenhum", "motivo": "resumo em 10 palavras"}}

Critérios:
- critico: prisão, condenação, fraude, crime, investigação policial, improbidade, desvio de verba
- atencao: processo judicial, autuação, denúncia, irregularidade, inquérito, multa relevante
- nenhum: menção neutra, premiação, cargo público legítimo, evento, opinião sem acusação"""

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
            texto = resp.json()["content"][0]["text"].strip()
            import json
            match = re.search(r"\{.*\}", texto, re.DOTALL)
            if match:
                return json.loads(match.group())
    except Exception as e:
        logger.debug("Haiku classificação: %s", e)

    return _classificar_keywords(titulo, descricao)


def _classificar_keywords(titulo: str, descricao: str) -> dict:
    """Fallback keyword-based — sem Haiku."""
    texto = _normalize(f"{titulo} {descricao or ''}")
    for kw in _CRITICO_KW:
        if kw in texto:
            return {"adverso": True, "severidade": "critico", "motivo": f"menção a '{kw}'"}
    for kw in _ATENCAO_KW:
        if kw in texto:
            return {"adverso": True, "severidade": "atencao", "motivo": f"menção a '{kw}'"}
    return {"adverso": False, "severidade": "nenhum", "motivo": "sem indicativo"}


def _dominio(url: str) -> str:
    m = re.search(r"https?://(?:www\.)?([^/]+)", url or "")
    return m.group(1) if m else ""


class MidiaAdversaPFConnector(SubradarSource):
    """
    Busca menções adversas do nome em portais jornalísticos via NewsAPI.
    Classifica com Haiku (fallback: keywords).
    Sem NEWSAPI_KEY: gracioso.
    """
    fonte = "midia_adversa"
    request_delay = 1.0

    def consultar_cnpj(self, cnpj_or_cpf: str, razao_social: str | None = None, **_) -> list[dict]:
        if not NEWSAPI_KEY:
            logger.debug("midia_adversa_pf: NEWSAPI_KEY ausente — pulando")
            return []

        nome = razao_social or ""
        if not nome or len(nome.split()) < 2:
            logger.debug("midia_adversa_pf: nome ausente ou incompleto — pulando")
            return []

        cpf = re.sub(r"\D", "", str(cnpj_or_cpf or ""))
        cpf_fmt = f"{cpf[:3]}.{cpf[3:6]}.{cpf[6:9]}-{cpf[9:11]}" if len(cpf) == 11 else cpf

        artigos = _buscar_noticias(nome)
        if not artigos:
            logger.debug("midia_adversa_pf: sem notícias para '%s'", nome)
            return []

        alertas = []
        for art in artigos:
            titulo = art.get("title") or ""
            descricao = art.get("description") or ""
            url = art.get("url") or ""
            fonte_art = art.get("source", {}).get("name") or _dominio(url)
            data_pub = (art.get("publishedAt") or "")[:10]

            # Filtra artigos onde o nome não aparece no texto
            if not _nome_presente(nome, f"{titulo} {descricao}"):
                continue

            classificacao = _classificar_artigo_haiku(titulo, descricao, nome)

            if not classificacao.get("adverso"):
                continue

            severidade = classificacao.get("severidade", "atencao")
            motivo = classificacao.get("motivo", "")

            logger.info("midia_adversa_pf: artigo adverso [%s] — '%s' (%s)",
                        severidade, titulo[:60], fonte_art)

            alertas.append({
                "fonte": self.fonte,
                "categoria": "reputacional",
                "severidade": severidade,
                "titulo": f"Mídia adversa — {fonte_art}: {titulo[:120]}",
                "descricao": (
                    f"Artigo publicado em {data_pub} por {fonte_art}. "
                    f"Motivo da classificação: {motivo}. "
                    f"Resumo: {descricao[:300]}"
                ),
                "url_fonte": url,
                "referencia_id": re.sub(r"\W+", "-", titulo[:50]).lower(),
                "data_evento": data_pub or None,
                "is_novo": True,
            })

        logger.info("midia_adversa_pf: %d alerta(s) para '%s'", len(alertas), nome)
        return alertas
