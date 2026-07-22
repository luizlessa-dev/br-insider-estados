"""
Conector: BNDES Devedores Inadimplentes (PJ)

Verifica se um CNPJ consta na lista de inadimplentes publicada pelo BNDES.
Complementa o bndes.py (que busca contratos ativos / enriquecimento positivo):
este conector busca *risco negativo* — inadimplência declarada.

Fontes tentadas em ordem:
  1. API CKAN dados abertos BNDES — datastore_search no resource inadimplentes
  2. Scraping da tabela HTML no portal de transparência BNDES
  3. Retorna [] se ambas falharem (fail-safe)

Sem variáveis de ambiente obrigatórias — fonte pública.

Campos gerados:
  fonte      = "bndes_devedores"
  categoria  = "financeiro"
  severidade = "atencao"
"""
from __future__ import annotations

import logging
import re
from typing import Any

from .base import SubradarSource, _ciclo_atual, snapshot_changed, upsert

logger = logging.getLogger("subradar.bndes_devedores")

# ---------------------------------------------------------------------------
# URLs das fontes
# ---------------------------------------------------------------------------
_URL_CKAN = "https://dadosabertos.bndes.gov.br/api/3/action/datastore_search"
_URL_PORTAL = (
    "https://www.bndes.gov.br/wps/portal/site/home/transparencia/"
    "consulta-de-operacoes-do-bndes/inadimplentes"
)
_URL_FONTE = "https://www.bndes.gov.br/wps/portal/site/home/transparencia/"

# Resource IDs conhecidos para inadimplentes no CKAN do BNDES.
# O BNDES pode usar qualquer um dos aliases abaixo — tentamos em sequência.
_CKAN_RESOURCE_IDS = [
    "inadimplentes",
    "inadimplentes-pj",
    "lista-inadimplentes",
    "devedores-inadimplentes",
]


def _strip_cnpj(cnpj: str) -> str:
    return re.sub(r"\D", "", cnpj)


def _fmt_cnpj(cnpj: str) -> str:
    c = _strip_cnpj(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


# ---------------------------------------------------------------------------
# Fonte 1 — API CKAN dados abertos BNDES
# ---------------------------------------------------------------------------

def _buscar_ckan(session_get, cnpj14: str) -> list[dict] | None:
    """
    Retorna lista de registros encontrados, lista vazia se não encontrado,
    ou None se a fonte estiver indisponível / resource inexistente.
    """
    import json as _json

    filters = _json.dumps({"cnpj": cnpj14})

    for resource_id in _CKAN_RESOURCE_IDS:
        try:
            data: dict = session_get(
                _URL_CKAN,
                params={
                    "resource_id": resource_id,
                    "filters": filters,
                    "limit": 10,
                },
            )
            if not data.get("success"):
                continue  # resource_id inválido — tenta o próximo
            records: list[dict] = data.get("result", {}).get("records", [])
            logger.debug(
                "CKAN resource=%s cnpj=%s → %d registros",
                resource_id, cnpj14, len(records),
            )
            return records  # sucesso (pode ser lista vazia)
        except Exception as exc:
            logger.debug("CKAN resource=%s erro: %s", resource_id, exc)
            continue

    return None  # todas as tentativas falharam


# ---------------------------------------------------------------------------
# Fonte 2 — Scraping do portal HTML
# ---------------------------------------------------------------------------

def _buscar_portal_html(session: Any, cnpj14: str) -> list[dict] | None:
    """
    Faz GET no portal de transparência e procura o CNPJ na tabela HTML.
    Retorna lista de dicts com campos extraídos, [] se não encontrado,
    None se o scraping falhar.

    O portal não aceita filtros por GET; baixamos a página completa e
    pesquisamos o CNPJ na resposta (a lista tende a ser curta — centenas
    de linhas, não milhões).
    """
    try:
        from urllib3.util.retry import Retry  # noqa — já importado via session
        import requests

        headers = {
            "User-Agent": "Subradar/1.0 (dados-publicos; contato@subradar.com.br)",
            "Accept": "text/html,application/xhtml+xml",
        }
        resp = requests.get(_URL_PORTAL, headers=headers, timeout=30)
        resp.raise_for_status()
        html = resp.text

        # Verifica presença do CNPJ (com ou sem pontuação) na página
        cnpj_fmt = _fmt_cnpj(cnpj14)
        if cnpj14 not in html and cnpj_fmt not in html:
            return []  # não encontrado

        # Tenta extrair linha da tabela com o CNPJ
        # Padrão esperado: <tr>...<td>CNPJ</td><td>Razão Social</td><td>Valor</td>...
        pattern = re.compile(
            rf"<tr[^>]*>.*?{re.escape(cnpj14)}.*?</tr>|"
            rf"<tr[^>]*>.*?{re.escape(cnpj_fmt)}.*?</tr>",
            re.IGNORECASE | re.DOTALL,
        )
        matches = pattern.findall(html)
        if not matches:
            # CNPJ presente mas não em <tr> — retorna hit genérico
            return [{"cnpj": cnpj_fmt, "fonte_scraping": "portal_bndes"}]

        registros = []
        td_re = re.compile(r"<td[^>]*>(.*?)</td>", re.IGNORECASE | re.DOTALL)
        tag_re = re.compile(r"<[^>]+>")

        for row in matches:
            cells = [tag_re.sub("", td).strip() for td in td_re.findall(row)]
            if not cells:
                continue
            registros.append({
                "cnpj": cnpj_fmt,
                "razao_social": cells[1] if len(cells) > 1 else None,
                "valor_devedor": cells[2] if len(cells) > 2 else None,
                "situacao": cells[3] if len(cells) > 3 else None,
                "fonte_scraping": "portal_bndes",
            })
        return registros or [{"cnpj": cnpj_fmt, "fonte_scraping": "portal_bndes"}]

    except Exception as exc:
        logger.warning("Scraping portal BNDES falhou: %s", exc)
        return None


# ---------------------------------------------------------------------------
# Conector principal
# ---------------------------------------------------------------------------

class BNDESDevedoresPJConnector(SubradarSource):
    """
    Verifica inadimplência junto ao BNDES.

    Retorna alerta severity="atencao" se o CNPJ constar na lista de
    devedores inadimplentes. Retorna [] se não encontrado ou se ambas
    as fontes estiverem indisponíveis (fail-safe).
    """

    fonte = "bndes_devedores"
    base_url = "https://dadosabertos.bndes.gov.br"
    request_delay = 1.0  # respeita servidor público
    timeout = 30

    def consultar_cnpj(self, cnpj: str) -> list[dict]:
        cnpj14 = _strip_cnpj(cnpj)
        if len(cnpj14) != 14:
            logger.warning("CNPJ inválido (não tem 14 dígitos): %r", cnpj)
            return []

        cnpj_fmt = _fmt_cnpj(cnpj14)
        ciclo = _ciclo_atual()

        registros: list[dict] | None = None

        # --- Fonte 1: API CKAN ---
        try:
            registros = _buscar_ckan(self._get, cnpj14)
        except Exception as exc:
            logger.warning("CKAN BNDES erro inesperado: %s", exc)
            registros = None

        # --- Fonte 2: scraping HTML (fallback) ---
        if registros is None:
            logger.info("CKAN indisponível, tentando scraping portal BNDES")
            registros = _buscar_portal_html(self._session, cnpj14)

        # --- Falha total: fail-safe ---
        if registros is None:
            logger.warning(
                "Ambas as fontes BNDES indisponíveis para %s — retornando []",
                cnpj_fmt,
            )
            return []

        # --- Não encontrado ---
        if not registros:
            logger.debug("CNPJ %s não consta na lista de inadimplentes BNDES", cnpj_fmt)
            return []

        # --- Encontrado: monta alerta ---
        # Extrai campos do primeiro registro (os demais são redundantes para o mesmo CNPJ)
        r0 = registros[0]
        razao_social = r0.get("razao_social") or r0.get("nome") or r0.get("denominacao") or ""
        valor_raw = r0.get("valor_devedor") or r0.get("valor") or r0.get("saldo_devedor") or ""
        situacao = r0.get("situacao") or r0.get("status") or "inadimplente"

        # Tenta parsear valor numérico
        valor_brl: float | None = None
        if valor_raw:
            try:
                valor_brl = float(
                    re.sub(r"[^\d,.]", "", str(valor_raw))
                    .replace(".", "")
                    .replace(",", ".")
                )
            except ValueError:
                pass

        titulo = f"Devedor inadimplente BNDES — {razao_social or cnpj_fmt}"
        descricao_parts = [
            f"CNPJ {cnpj_fmt} consta na lista de devedores inadimplentes do BNDES.",
        ]
        if razao_social:
            descricao_parts.append(f"Razão social: {razao_social}.")
        if valor_brl is not None:
            descricao_parts.append(f"Saldo devedor: R$ {valor_brl:,.2f}.")
        elif valor_raw:
            descricao_parts.append(f"Saldo devedor: {valor_raw}.")
        descricao_parts.append(f"Situação: {situacao}.")

        alerta = {
            "cnpj": cnpj_fmt,
            "ciclo": ciclo,
            "fonte": self.fonte,
            "categoria": "financeiro",
            "severidade": "atencao",
            "titulo": titulo,
            "descricao": " ".join(descricao_parts),
            "valor_brl": valor_brl,
            "contraparte": "BNDES",
            "url_fonte": _URL_FONTE,
            "is_novo": True,
        }

        # Snapshot para delta detection
        resumo = {"inadimplente": True, "registros": len(registros), "situacao": situacao}
        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, resumo)
        if mudou:
            upsert("sub_snapshots", [{
                "cnpj": cnpj_fmt,
                "fonte": self.fonte,
                "ciclo": ciclo,
                "hash_dados": hash_novo,
                "dados": resumo,
            }])
        else:
            logger.debug("Sem mudança no snapshot BNDES devedores para %s", cnpj_fmt)
            return []

        logger.info("bndes_devedores: alerta de inadimplência para %s", cnpj_fmt)
        return [alerta]
