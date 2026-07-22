"""
Conector: Mídia Adversa — menções negativas de Pessoa Jurídica em portais de notícias

Busca artigos sobre a razão social da empresa em portais jornalísticos brasileiros
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
  1. Busca os 10 artigos mais recentes com a razão social como query
  2. Filtra artigos com pelo menos 1 token relevante da razão social no título ou descrição
  3. Classifica via Haiku se são adversos (crime, processo, irregularidade, etc.)
  4. Gera alerta 'atencao' por artigo adverso confirmado
  5. Gera alerta 'critico' se artigo mencionar falência, fraude, operação policial, etc.

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

logger = logging.getLogger("subradar.midia_adversa_pj")

NEWSAPI_KEY = os.environ.get("NEWSAPI_KEY", "")
ANTHROPIC_KEY = os.environ.get("ANTHROPIC_API_KEY", "")

_NEWSAPI_URL = "https://newsapi.org/v2/everything"
_HAIKU_URL = "https://api.anthropic.com/v1/messages"
_HAIKU_MODEL = "claude-haiku-4-5-20251001"

# Stopwords descartadas para evitar falsos positivos na verificação do nome
_STOPWORDS = {
    "de", "do", "da", "dos", "das", "e", "em", "a", "o", "os", "as",
    "ltda", "sa", "s/a", "me", "epp", "eireli", "cia", "soc",
    "com", "para", "por", "que", "se", "no", "na",
}

# Palavras-chave que indicam matéria crítica para empresa (fallback sem Haiku)
_CRITICO_KW = {
    "falência", "concordata", "recuperação judicial",
    "fraude contábil", "fraude", "estelionato", "lavagem",
    "corrupção", "desvio", "operação policial", "lava jato",
    "intervenção", "liquidação", "busca e apreensão",
    "indiciado", "indiciada", "investigado", "investigada",
    "preso", "presa", "condenado", "condenada",
    "crime", "criminoso", "réu", "ré", "prisão",
}
_ATENCAO_KW = {
    "ação civil pública", "improbidade", "autuação", "descredenciamento",
    "recall", "interdição", "processo", "ação judicial",
    "multa", "irregularidade", "denúncia", "denunciado", "denunciada",
    "suspeito", "suspeita", "investigação", "inquérito",
    "cade", "mpf", "mpe", "ministério público", "tce", "tcu",
    "reclamação", "habeas corpus", "autuado", "autuada",
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


def _nome_presente(razao_social: str, texto: str) -> bool:
    """
    Verifica se pelo menos 1 token relevante da razão social aparece no texto.
    Mais permissivo que PF: empresas podem ter nome curto como "VALE" ou "PETROBRAS".
    Ignora stopwords e sufixos jurídicos.
    """
    tokens = [t for t in _normalize(razao_social).split() if t not in _STOPWORDS and len(t) > 2]
    if not tokens:
        return False
    texto_n = _normalize(texto)
    return any(t in texto_n for t in tokens)


def _buscar_noticias(razao_social: str, dias: int = 90) -> list[dict]:
    """Busca artigos via NewsAPI.org."""
    desde = (datetime.now(timezone.utc) - timedelta(days=dias)).strftime("%Y-%m-%d")
    try:
        resp = requests.get(
            _NEWSAPI_URL,
            params={
                "q": f'"{razao_social}"',
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


def _classificar_artigo_haiku(titulo: str, descricao: str, razao_social: str) -> dict:
    """
    Usa Claude Haiku para classificar se o artigo é adverso para a empresa.
    Retorna {"adverso": bool, "severidade": "critico"|"atencao"|"nenhum", "motivo": str}
    """
    if not ANTHROPIC_KEY:
        return _classificar_keywords(titulo, descricao)

    prompt = f"""Você é um analista de compliance. Classifique se este artigo jornalístico é adverso para a empresa (pessoa jurídica) "{razao_social}".

Título: {titulo[:300]}
Descrição: {(descricao or '')[:400]}

Responda em uma linha no formato JSON:
{{"adverso": true/false, "severidade": "critico"/"atencao"/"nenhum", "motivo": "resumo em 10 palavras"}}

Critérios para empresa:
- critico: falência, recuperação judicial, fraude contábil, operação policial, lava jato, intervenção, liquidação, condenação, desvio de verba, investigação criminal
- atencao: ação civil pública, improbidade, autuação, descredenciamento, recall, interdição, processo judicial, multa relevante, denúncia formal, inquérito
- nenhum: menção neutra, parceria, expansão, contratação, resultado financeiro positivo, evento, opinião sem acusação"""

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


class MidiaAdversaPJConnector(SubradarSource):
    """
    Busca menções adversas da razão social em portais jornalísticos via NewsAPI.
    Classifica com Haiku (fallback: keywords).
    Sem NEWSAPI_KEY: gracioso.
    """
    fonte = "midia_adversa_pj"
    request_delay = 1.0

    def consultar_cnpj(self, cnpj_or_cpf: str, razao_social: str | None = None, **_) -> list[dict]:
        if not NEWSAPI_KEY:
            logger.debug("midia_adversa_pj: NEWSAPI_KEY ausente — pulando")
            return []

        razao = razao_social or ""
        if not razao:
            logger.debug("midia_adversa_pj: razao_social ausente — pulando")
            return []

        cnpj = re.sub(r"\D", "", str(cnpj_or_cpf or ""))
        cnpj_fmt = (
            f"{cnpj[:2]}.{cnpj[2:5]}.{cnpj[5:8]}/{cnpj[8:12]}-{cnpj[12:14]}"
            if len(cnpj) == 14
            else cnpj
        )

        artigos = _buscar_noticias(razao)
        if not artigos:
            logger.debug("midia_adversa_pj: sem notícias para '%s'", razao)
            return []

        alertas = []
        for art in artigos:
            titulo = art.get("title") or ""
            descricao = art.get("description") or ""
            url = art.get("url") or ""
            fonte_art = art.get("source", {}).get("name") or _dominio(url)
            data_pub = (art.get("publishedAt") or "")[:10]

            # Filtra artigos onde a razão social não aparece no texto
            if not _nome_presente(razao, f"{titulo} {descricao}"):
                continue

            classificacao = _classificar_artigo_haiku(titulo, descricao, razao)

            if not classificacao.get("adverso"):
                continue

            severidade = classificacao.get("severidade", "atencao")
            motivo = classificacao.get("motivo", "")

            logger.info("midia_adversa_pj: artigo adverso [%s] — '%s' (%s)",
                        severidade, titulo[:60], fonte_art)

            alertas.append({
                "fonte": self.fonte,
                "categoria": "reputacao",
                "severidade": severidade,
                "titulo": f"Mídia adversa PJ — {fonte_art}: {titulo[:120]}",
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

        logger.info("midia_adversa_pj: %d alerta(s) para '%s' (%s)", len(alertas), razao, cnpj_fmt)
        return alertas
