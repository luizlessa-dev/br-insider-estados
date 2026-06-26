"""
Conector: Diário Oficial da União — INLabs (Imprensa Nacional)

Auth: login por formulário em https://inlabs.in.gov.br/logar.php
Download: ZIPs diários com XMLs de cada artigo/ato publicado
Seções: DO1 (Seção 1 — atos normativos), DO2 (Seção 2 — pessoal), DO3 (Seção 3 — contratos)

Estratégia:
  1. Faz login e mantém cookie de sessão em memória
  2. Baixa ZIP das seções relevantes (DO1 e DO3 por padrão)
  3. Extrai XMLs e faz busca pelo CNPJ e razão social
  4. Para cada hit: usa Haiku para classificar relevância e severidade
  5. Gera alertas com trecho do artigo

Custo estimado: ~R$0.05/CNPJ/mês (Haiku, 5 artigos médios)

Env vars obrigatórias:
  INLABS_EMAIL    — email de login no INLabs
  INLABS_PASSWORD — senha de login no INLabs

Env var opcional:
  ANTHROPIC_API_KEY — para classificação por IA (se ausente, classifica por keyword)
"""
from __future__ import annotations

import io
import logging
import os
import re
import time
import xml.etree.ElementTree as ET
import zipfile
from datetime import date, timedelta

import requests

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.dou")

INLABS_BASE = "https://inlabs.in.gov.br"
INLABS_EMAIL = os.environ.get("INLABS_EMAIL", "")
INLABS_PASSWORD = os.environ.get("INLABS_PASSWORD", "")
ANTHROPIC_KEY = os.environ.get("ANTHROPIC_API_KEY", "")

# Seções do DOU mais relevantes para compliance
# DO1 = Seção 1: leis, decretos, atos normativos, sanções
# DO2 = Seção 2: pessoal, nomeações
# DO3 = Seção 3: contratos, licitações, resultado de licitação
SECOES = ["DO1", "DO3"]

# Keywords de atenção para classificação sem IA
KEYWORDS_CRITICO = [
    "suspensão", "inabilitação", "impedimento", "multa", "infração",
    "descredenciamento", "declaração de inidoneidade", "pena", "sanção",
    "cancelamento do registro", "rescisão unilateral",
]
KEYWORDS_ATENCAO = [
    "notificação", "autuação", "auto de infração", "intimação",
    "instauração de processo", "apuração", "sindicância",
]


def _strip_cnpj(cnpj: str) -> str:
    return re.sub(r"\D", "", cnpj)


def _fmt_cnpj(cnpj: str) -> str:
    c = _strip_cnpj(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _cnpj_patterns(cnpj_limpo: str) -> list[str]:
    """Gera variantes de formato do CNPJ para busca no XML."""
    c = cnpj_limpo
    return [
        c,
        f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}",
        f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:]}",
    ]


class INLabsSession:
    """Gerencia cookie de sessão INLabs (singleton por processo)."""
    _session: requests.Session | None = None
    _logged_in: bool = False

    @classmethod
    def get(cls) -> requests.Session:
        if cls._session is None:
            cls._session = requests.Session()
            cls._session.headers.update({"User-Agent": "Mozilla/5.0"})
        return cls._session

    @classmethod
    def login(cls) -> bool:
        if not INLABS_EMAIL or not INLABS_PASSWORD:
            logger.warning("DOU: INLABS_EMAIL/INLABS_PASSWORD não configurados")
            return False
        s = cls.get()
        try:
            r = s.post(
                f"{INLABS_BASE}/logar.php",
                data={"email": INLABS_EMAIL, "password": INLABS_PASSWORD},
                timeout=20,
                allow_redirects=True,
            )
            if r.status_code in (200, 302) and "inlabs_session_cookie" in s.cookies:
                cls._logged_in = True
                logger.info("DOU: login INLabs OK")
                return True
            logger.error("DOU: login falhou (status %s)", r.status_code)
            return False
        except Exception as e:
            logger.error("DOU: erro no login: %s", e)
            return False

    @classmethod
    def refresh(cls) -> bool:
        """Força novo login (chama a cada N downloads para evitar expiração de sessão)."""
        cls._logged_in = False
        return cls.login()

    @classmethod
    def ensure_logged_in(cls) -> bool:
        if not cls._logged_in:
            return cls.login()
        return True


def _download_zip(data: str, secao: str) -> bytes | None:
    """Baixa o ZIP de uma seção do DOU para uma data (YYYY-MM-DD)."""
    session = INLabsSession.get()
    filename = f"{data}-{secao}.zip"
    url = f"{INLABS_BASE}/index.php?p={data}&dl={filename}"

    for attempt in range(3):
        try:
            r = session.get(url, timeout=120, headers={"Referer": f"{INLABS_BASE}/index.php?p={data}"})
            if r.status_code == 404:
                # Edição não existe (feriado, final de semana sem suplemento) — silencioso
                logger.debug("DOU: %s %s não disponível (404)", data, secao)
                return None
            if not r.ok:
                logger.warning("DOU: download %s %s retornou %s", data, secao, r.status_code)
                return None
            # Verifica se é realmente um ZIP (não HTML de sessão expirada)
            if r.content[:4] == b"PK\x03\x04":
                return r.content
            # Sessão expirou — re-login e retry
            logger.debug("DOU: sessão expirada para %s %s — re-login (tentativa %d)", data, secao, attempt + 1)
            if not INLabsSession.refresh():
                return None
        except Exception as e:
            logger.warning("DOU: erro ao baixar %s %s (tentativa %d): %s", data, secao, attempt + 1, e)
            if attempt < 2:
                time.sleep(2 ** attempt)
    logger.warning("DOU: falhou após 3 tentativas para %s %s", data, secao)
    return None


def _extrair_artigos_com_cnpj(zip_bytes: bytes, cnpj_limpo: str, razao_social: str | None) -> list[dict]:
    """Abre ZIP, lê XMLs e retorna artigos que mencionam o CNPJ."""
    patterns = _cnpj_patterns(cnpj_limpo)
    hits = []
    try:
        with zipfile.ZipFile(io.BytesIO(zip_bytes)) as z:
            for nome in z.namelist():
                if not nome.endswith(".xml"):
                    continue
                try:
                    with z.open(nome) as f:
                        texto_xml = f.read().decode("utf-8", errors="replace")

                    # Busca rápida por CNPJ antes de parsear XML
                    encontrou = any(p in texto_xml for p in patterns)
                    if not encontrou and razao_social:
                        # Busca também pela razão social (truncada em 20 chars pra evitar falsos negativos)
                        rs_curta = razao_social[:20].upper()
                        encontrou = rs_curta in texto_xml.upper()

                    if not encontrou:
                        continue

                    # Parseia XML para extrair campos estruturados
                    root = ET.fromstring(texto_xml)
                    artigo = {
                        "arquivo": nome,
                        "identifica": _xml_text(root, ".//identifica"),
                        "ementa": _xml_text(root, ".//ementa"),
                        "texto": _xml_text(root, ".//texto")[:2000],
                        "orgao": _xml_text(root, ".//orgao"),
                        "secao": _xml_text(root, ".//secao") or nome.split("/")[0] if "/" in nome else "",
                        "numero_dou": _xml_text(root, ".//numeroDOU"),
                        "data_pub": _xml_text(root, ".//dataPublicacao"),
                        "url_artigo": _xml_text(root, ".//urlTitle"),
                        "pagina": _xml_text(root, ".//paginaInicio"),
                    }
                    hits.append(artigo)
                except Exception as e:
                    logger.debug("DOU: erro ao processar %s: %s", nome, e)
    except zipfile.BadZipFile:
        logger.warning("DOU: arquivo ZIP inválido")
    return hits


def _xml_text(root: ET.Element, xpath: str) -> str:
    el = root.find(xpath)
    return (el.text or "").strip() if el is not None else ""


def _classificar_artigo(artigo: dict) -> tuple[str, str, str]:
    """
    Classifica um artigo como critico/atencao/info.
    Usa IA (Haiku) se disponível, senão classifica por keywords.
    Retorna (severidade, titulo, descricao).
    """
    texto = f"{artigo.get('identifica','')} {artigo.get('ementa','')} {artigo.get('texto','')}".lower()
    identifica = artigo.get("identifica", "") or artigo.get("ementa", "") or "Publicação no DOU"
    orgao = artigo.get("orgao", "N/D")
    data = artigo.get("data_pub", "")

    # Classificação por IA (Haiku — mais barato)
    if ANTHROPIC_KEY:
        try:
            severidade, motivo = _classificar_com_ia(artigo)
            titulo = f"DOU — {identifica[:80]}"
            descricao = (
                f"Publicação em {orgao} ({data}). {motivo} "
                f"Identifica: {identifica[:200]}."
            )
            if artigo.get("url_artigo"):
                descricao += f" URL: https://www.in.gov.br/web/dou/-/{artigo['url_artigo']}"
            return severidade, titulo, descricao
        except Exception as e:
            logger.debug("DOU: classificação IA falhou, usando keywords: %s", e)

    # Fallback: keywords
    if any(k in texto for k in KEYWORDS_CRITICO):
        severidade = "critico"
    elif any(k in texto for k in KEYWORDS_ATENCAO):
        severidade = "atencao"
    else:
        severidade = "info"

    titulo = f"DOU — {identifica[:80]}"
    descricao = (
        f"Publicação no DOU em {orgao} ({data}). "
        f"Identifica: {identifica[:200]}."
    )
    return severidade, titulo, descricao


def _classificar_com_ia(artigo: dict) -> tuple[str, str]:
    """Usa Claude Haiku para classificar o artigo e retornar (severidade, motivo)."""
    texto_resumo = f"""
Identifica: {artigo.get('identifica','')}
Ementa: {artigo.get('ementa','')}
Órgão: {artigo.get('orgao','')}
Texto (trecho): {artigo.get('texto','')[:800]}
""".strip()

    prompt = f"""Você é especialista em compliance e direito administrativo brasileiro.

Um CNPJ monitorado foi mencionado neste artigo do Diário Oficial da União:

{texto_resumo}

Classifique a severidade para fins de compliance:
- critico: sanção, multa, inabilitação, suspensão, rescisão unilateral de contrato, cassação, declaração de inidoneidade
- atencao: notificação, autuação, intimação, instauração de processo, alteração contratual relevante
- info: publicação de contrato novo, aditivo, extrato, licitação, outros atos administrativos normais

Responda APENAS com o JSON: {"severidade": "critico|atencao|info", "motivo": "uma frase explicando"}"""

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
    # Extrai JSON da resposta
    match = re.search(r'\{[^}]+\}', content)
    if match:
        import json
        d = json.loads(match.group())
        sev = d.get("severidade", "info")
        if sev not in ("critico", "atencao", "info"):
            sev = "info"
        return sev, d.get("motivo", "")
    return "info", ""


class DOUConnector(SubradarSource):
    fonte = "dou"
    base_url = INLABS_BASE

    def consultar_cnpj(self, cnpj: str, razao_social: str | None = None) -> list[dict]:
        if not INLABS_EMAIL or not INLABS_PASSWORD:
            logger.warning("DOU: credenciais INLabs não configuradas — pulando %s", cnpj)
            return []

        if not INLabsSession.ensure_logged_in():
            return []

        cnpj_limpo = _strip_cnpj(cnpj)
        cnpj_fmt = _fmt_cnpj(cnpj_limpo)
        ciclo = _ciclo_atual()

        # Busca nos últimos 30 dias (últimas 4 semanas úteis)
        hoje = date.today()
        datas = [
            (hoje - timedelta(days=d)).isoformat()
            for d in range(30)
            if (hoje - timedelta(days=d)).weekday() < 5  # só dias úteis
        ][:20]  # máximo 20 datas para controlar o custo

        todos_artigos = []
        downloads_feitos = 0
        for data in datas:
            # Re-login a cada 8 downloads para evitar expiração de sessão PHP
            if downloads_feitos > 0 and downloads_feitos % 8 == 0:
                INLabsSession.refresh()
            for secao in SECOES:
                zip_bytes = _download_zip(data, secao)
                downloads_feitos += 1
                if not zip_bytes:
                    continue
                artigos = _extrair_artigos_com_cnpj(zip_bytes, cnpj_limpo, razao_social)
                for a in artigos:
                    a["_data"] = data
                    a["_secao"] = secao
                todos_artigos.extend(artigos)
                time.sleep(0.3)  # evita sobrecarga no servidor

        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, todos_artigos)
        if not mudou:
            logger.info("DOU: sem mudanças para %s", cnpj_fmt)
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt, "fonte": self.fonte, "ciclo": ciclo,
            "hash_dados": hash_novo,
            "dados": {"total_artigos": len(todos_artigos), "datas_consultadas": len(datas)},
        }])

        alertas = []
        for artigo in todos_artigos:
            severidade, titulo, descricao = _classificar_artigo(artigo)
            alertas.append({
                "cnpj": cnpj_fmt,
                "ciclo": ciclo,
                "fonte": self.fonte,
                "categoria": "dou",
                "severidade": severidade,
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

        logger.info("DOU: %d alertas para %s (%d artigos encontrados)", len(alertas), cnpj_fmt, len(todos_artigos))
        return alertas
