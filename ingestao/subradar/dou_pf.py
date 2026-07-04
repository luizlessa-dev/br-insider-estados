"""
Conector: Diário Oficial da União — busca por nome de Pessoa Física

Adapta o DOUConnector (que busca por CNPJ) para buscar pelo nome completo
da pessoa física. Cobre as três seções:
  DO1 — sanções, portarias, decretos (ex: demissão de servidor, cassação)
  DO2 — pessoal (nomeação, exoneração, afastamento, aposentadoria)
  DO3 — contratos (menções como representante/responsável técnico)

Classificação via Haiku (IA) quando ANTHROPIC_API_KEY disponível,
fallback em keywords quando não.

Env vars obrigatórias: INLABS_EMAIL, INLABS_PASSWORD
Env var opcional: ANTHROPIC_API_KEY
"""
from __future__ import annotations

import logging
import re
import unicodedata

from .base import SubradarSource
from .dou import (
    INLabsSession,
    INLABS_EMAIL, INLABS_PASSWORD, ANTHROPIC_KEY,
    _extrair_artigos_com_cnpj,
    _classificar_artigo,
    KEYWORDS_CRITICO, KEYWORDS_ATENCAO,
)
from datetime import date, timedelta

logger = logging.getLogger("subradar.dou_pf")

# Buscamos nas três seções para PF (DO2 tem dados de pessoal)
SECOES_PF = ["DO1", "DO2", "DO3"]

# Para PF, keywords PF-específicas sobrepõem as genéricas
_CRITICO_PF = KEYWORDS_CRITICO + [
    "demissão", "demitido", "demitida", "exoneração a bem do serviço público",
    "cassação de aposentadoria", "perda do cargo", "condenado", "condenada",
    "preso", "presa", "indiciado", "indiciada", "processo administrativo disciplinar",
]
_ATENCAO_PF = KEYWORDS_ATENCAO + [
    "investigado", "investigada", "sindicância", "afastamento preventivo",
    "suspenso", "suspensa", "advertência",
]


def _normalize(s: str) -> str:
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    return s.upper().strip()


def _nome_patterns(nome: str) -> list[str]:
    """Gera variantes do nome para busca: nome completo e nome sem acentos."""
    nome_norm = _normalize(nome)
    patterns = [nome.upper(), nome_norm]
    # Também testa primeiros dois nomes + último sobrenome (evita meio nome)
    partes = nome_norm.split()
    if len(partes) >= 3:
        patterns.append(f"{partes[0]} {partes[-1]}")
    return list(dict.fromkeys(patterns))  # dedup mantendo ordem


def _extrair_artigos_com_nome(zip_bytes: bytes, nome: str) -> list[dict]:
    """Abre ZIP, lê XMLs e retorna artigos que mencionam o nome da pessoa."""
    patterns = _nome_patterns(nome)
    # Reutiliza a função do dou.py passando o nome como "razao_social"
    # e um CNPJ fake vazio para não ter match por CNPJ
    return _extrair_artigos_com_cnpj(zip_bytes, cnpj_limpo="", razao_social=nome)


def _classificar_artigo_pf(artigo: dict, nome: str) -> tuple[str, str, str]:
    """Classifica usando IA com prompt PF-específico, ou keywords."""
    identifica = artigo.get("identifica", "") or artigo.get("ementa", "") or "Publicação no DOU"
    orgao = artigo.get("orgao", "N/D")
    data = artigo.get("data_pub", "")
    texto = f"{artigo.get('identifica','')} {artigo.get('ementa','')} {artigo.get('texto','')}".lower()

    if ANTHROPIC_KEY:
        try:
            import requests, json
            texto_resumo = (
                f"Nome consultado: {nome}\n"
                f"Identifica: {artigo.get('identifica','')}\n"
                f"Ementa: {artigo.get('ementa','')}\n"
                f"Órgão: {artigo.get('orgao','')}\n"
                f"Texto (trecho): {artigo.get('texto','')[:800]}"
            ).strip()
            prompt = f"""Você é especialista em compliance e direito administrativo.

Este artigo do Diário Oficial menciona a pessoa física consultada:

{texto_resumo}

Classifique a severidade para compliance:
- critico: demissão, cassação, sanção, multa, inabilitação, condenação, indiciamento, suspensão, declaração de inidoneidade
- atencao: exoneração voluntária, afastamento preventivo, notificação, autuação, sindicância, investigação
- info: nomeação, posse, aposentadoria voluntária, publicação de contrato, ato normal

Responda APENAS com JSON: {{"severidade": "critico|atencao|info", "motivo": "uma frase"}}"""

            r = requests.post(
                "https://api.anthropic.com/v1/messages",
                headers={
                    "x-api-key": ANTHROPIC_KEY,
                    "anthropic-version": "2023-06-01",
                    "content-type": "application/json",
                },
                json={
                    "model": "claude-haiku-4-5-20251001",
                    "max_tokens": 100,
                    "messages": [{"role": "user", "content": prompt}],
                },
                timeout=15,
            )
            r.raise_for_status()
            content = r.json()["content"][0]["text"].strip()
            match = re.search(r'\{[^}]+\}', content)
            if match:
                d = json.loads(match.group())
                sev = d.get("severidade", "info")
                if sev not in ("critico", "atencao", "info"):
                    sev = "info"
                motivo = d.get("motivo", "")
                titulo = f"DOU — {identifica[:80]}"
                descricao = (
                    f"Publicação em {orgao} ({data}). {motivo} "
                    f"Identifica: {identifica[:200]}."
                )
                if artigo.get("url_artigo"):
                    descricao += f" URL: https://www.in.gov.br/web/dou/-/{artigo['url_artigo']}"
                return sev, titulo, descricao
        except Exception as e:
            logger.debug("dou_pf: classificação IA falhou: %s", e)

    # Fallback keywords
    if any(k in texto for k in _CRITICO_PF):
        sev = "critico"
    elif any(k in texto for k in _ATENCAO_PF):
        sev = "atencao"
    else:
        sev = "info"

    titulo = f"DOU — {identifica[:80]}"
    descricao = f"Publicação no DOU em {orgao} ({data}). Identifica: {identifica[:200]}."
    return sev, titulo, descricao


class DOUPFConnector(SubradarSource):
    """
    Busca o nome da pessoa física no Diário Oficial da União (últimos 30 dias).
    Seções DO1, DO2 e DO3. Gracioso sem credenciais INLabs.
    """
    fonte = "dou_pf"

    def consultar_cnpj(self, cnpj_or_cpf: str, razao_social: str | None = None, **_) -> list[dict]:
        nome = razao_social or ""
        if not nome:
            logger.debug("dou_pf: nome não informado — pulando")
            return []

        if not INLABS_EMAIL or not INLABS_PASSWORD:
            logger.debug("dou_pf: credenciais INLabs ausentes — pulando")
            return []

        if not INLabsSession.ensure_logged_in():
            return []

        hoje = date.today()
        datas = [
            (hoje - timedelta(days=d)).isoformat()
            for d in range(30)
            if (hoje - timedelta(days=d)).weekday() < 5
        ][:20]

        todos_artigos = []
        for data in datas:
            for secao in SECOES_PF:
                zip_bytes = INLabsSession.get_zip(data, secao)
                if not zip_bytes:
                    continue
                artigos = _extrair_artigos_com_nome(zip_bytes, nome)
                for a in artigos:
                    a["_data"] = data
                    a["_secao"] = secao
                todos_artigos.extend(artigos)

        if not todos_artigos:
            logger.debug("dou_pf: nenhuma menção a '%s' nos últimos 30d", nome)
            return []

        alertas = []
        for artigo in todos_artigos:
            sev, titulo, descricao = _classificar_artigo_pf(artigo, nome)
            alertas.append({
                "fonte": self.fonte,
                "categoria": "dou",
                "severidade": sev,
                "titulo": titulo,
                "descricao": descricao,
                "contraparte": artigo.get("orgao"),
                "data_evento": artigo.get("data_pub") or artigo.get("_data"),
                "url_fonte": (
                    f"https://www.in.gov.br/web/dou/-/{artigo['url_artigo']}"
                    if artigo.get("url_artigo") else
                    "https://www.in.gov.br/web/guest/inicio"
                ),
                "is_novo": True,
            })

        logger.info("dou_pf: %d alerta(s) para '%s'", len(alertas), nome)
        return alertas
