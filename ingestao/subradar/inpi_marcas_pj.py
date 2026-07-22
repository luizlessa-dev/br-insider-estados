"""
Conector: INPI — Marcas registradas e processos de nulidade por CNPJ

Objetivo: enriquecimento informacional sobre propriedade intelectual de pessoa jurídica.
Sem autenticação. INPI tem instabilidade conhecida — falhas são silenciosas.

Alertas gerados:
  - Marca "REGISTRADA" / "VIGENTE"        → severity="info"     (positivo: empresa possui marca)
  - Oposição ou nulidade em andamento     → severity="atencao"  (risco de perda de marca)
  - Expiração recente (≤ 6 meses)        → severity="info"      (marca expirada)

fonte="inpi_marcas", categoria="propriedade_intelectual"
"""
from __future__ import annotations

import logging
import re
from datetime import date, datetime
from typing import Any

try:
    from bs4 import BeautifulSoup  # type: ignore
    _BS4 = True
except ImportError:
    _BS4 = False

from .base import SubradarSource, _ciclo_atual, snapshot_changed, upsert

logger = logging.getLogger("subradar.inpi_marcas")

# ---------------------------------------------------------------------------
# Endpoints INPI (sem autenticação)
# ---------------------------------------------------------------------------
_PEPI_URL = "https://busca.inpi.gov.br/pePI/servlet/MarcasServletController"
_REST_URL = "https://api.inpi.gov.br/marcas/v1/pesquisa"

# Situações que indicam marca ativa/registrada
_SITUACOES_ATIVAS = {"registrada", "vigente", "deferida", "concedida"}

# Palavras-chave em situação que indicam oposição / processo de nulidade
_SITUACOES_RISCO = {
    "oposição",
    "oposicao",
    "nulidade",
    "ação de nulidade",
    "acao de nulidade",
    "recurso",
    "indeferida com recurso",
    "caducidade",
}

# Situações de expiração/extinção
_SITUACOES_EXPIRADAS = {
    "extinta",
    "caducada",
    "expirada",
    "arquivada",
    "abandonada",
    "desistida",
    "indeferida",
}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", cnpj)


def _fmt_cnpj(cnpj: str) -> str:
    c = _strip(cnpj)
    if len(c) == 14:
        return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}"
    return cnpj


def _parse_date(s: str) -> str | None:
    if not s:
        return None
    for fmt in ("%d/%m/%Y", "%Y-%m-%d", "%d/%m/%y"):
        try:
            return datetime.strptime(s.strip(), fmt).date().isoformat()
        except ValueError:
            continue
    return None


def _recently_expired(data_iso: str | None, months: int = 6) -> bool:
    """Retorna True se a data é recente (dentro dos últimos `months` meses)."""
    if not data_iso:
        return False
    try:
        d = date.fromisoformat(data_iso)
        delta = (date.today() - d).days
        return 0 <= delta <= months * 30
    except ValueError:
        return False


def _situacao_normalizada(s: str) -> str:
    return re.sub(r"\s+", " ", s.strip().lower())


# ---------------------------------------------------------------------------
# Parsers de resposta
# ---------------------------------------------------------------------------

def _parse_rest_json(data: Any, cnpj14: str) -> list[dict]:
    """Parseia resposta JSON da API REST INPI (se disponível)."""
    marcas = []
    items = data if isinstance(data, list) else data.get("content", data.get("data", []))
    for item in items:
        if not isinstance(item, dict):
            continue
        # Filtro defensivo por CNPJ (API pode retornar resultados adjacentes)
        titular_cnpj = re.sub(r"\D", "", str(item.get("titularCnpj") or item.get("cnpj") or ""))
        if titular_cnpj and titular_cnpj != cnpj14:
            continue
        marcas.append({
            "numero": str(item.get("numeroProcesso") or item.get("numero") or ""),
            "nome": str(item.get("marca") or item.get("nome") or ""),
            "situacao": str(item.get("situacao") or item.get("descricaoSituacao") or ""),
            "classe": str(item.get("classe") or item.get("classificacao") or ""),
            "data_deposito": _parse_date(str(item.get("dataDeposito") or "")),
            "data_vencimento": _parse_date(str(item.get("dataVencimento") or item.get("dataExpiracao") or "")),
            "titular": str(item.get("titular") or item.get("titularNome") or ""),
        })
    return marcas


def _parse_pepi_html(html: str, cnpj14: str) -> list[dict]:
    """Parseia resposta HTML do portal pePI (fallback)."""
    if not _BS4:
        logger.warning("beautifulsoup4 não instalado — parse HTML indisponível")
        return []

    soup = BeautifulSoup(html, "html.parser")
    marcas: list[dict] = []

    # pePI retorna tabela com resultados de busca
    # Estrutura típica: <table class="tabelaResultado"> com linhas de marca
    tabelas = soup.find_all("table")
    for tabela in tabelas:
        linhas = tabela.find_all("tr")
        for linha in linhas[1:]:  # pula cabeçalho
            cols = [td.get_text(strip=True) for td in linha.find_all("td")]
            if len(cols) < 4:
                continue
            # Colunas típicas: [Número, Marca, Titular, Situação, Classe, Vencimento]
            numero = cols[0] if cols else ""
            nome = cols[1] if len(cols) > 1 else ""
            titular = cols[2] if len(cols) > 2 else ""
            situacao = cols[3] if len(cols) > 3 else ""
            classe = cols[4] if len(cols) > 4 else ""
            data_str = cols[5] if len(cols) > 5 else ""

            # Filtra por CNPJ no texto do titular quando disponível
            if cnpj14 and cnpj14 not in re.sub(r"\D", "", titular):
                # Titular pode não conter CNPJ — inclui assim mesmo se campos preenchidos
                if not numero and not nome:
                    continue

            marcas.append({
                "numero": numero,
                "nome": nome,
                "situacao": situacao,
                "classe": classe,
                "data_deposito": None,
                "data_vencimento": _parse_date(data_str),
                "titular": titular,
            })

    return marcas


# ---------------------------------------------------------------------------
# Conector principal
# ---------------------------------------------------------------------------

class INPIMarcasConnector(SubradarSource):
    fonte = "inpi_marcas"
    request_delay = 1.5  # INPI é instável; espaçamento generoso
    timeout = 45

    def __init__(self) -> None:
        super().__init__()
        # pePI espera User-Agent de navegador para não bloquear
        self._session.headers.update({
            "User-Agent": (
                "Mozilla/5.0 (compatible; Subradar/1.0; "
                "+https://subradar.com.br; dados-publicos)"
            ),
            "Accept": "text/html,application/xhtml+xml,application/json,*/*",
        })

    # ------------------------------------------------------------------
    # Busca via API REST (preferencial)
    # ------------------------------------------------------------------

    def _buscar_rest(self, cnpj14: str) -> list[dict] | None:
        """Tenta API REST. Retorna None em qualquer falha."""
        try:
            params = {"titularCnpj": cnpj14, "pagina": 1, "tamanhoPagina": 100}
            resp = self._session.get(_REST_URL, params=params, timeout=self.timeout)
            if resp.status_code == 404:
                return []  # CNPJ sem marcas — resposta válida
            if not resp.ok:
                logger.debug("API REST INPI: HTTP %s", resp.status_code)
                return None
            data = resp.json()
            return _parse_rest_json(data, cnpj14)
        except Exception as exc:
            logger.debug("API REST INPI indisponível: %s", exc)
            return None

    # ------------------------------------------------------------------
    # Busca via portal pePI (fallback HTML)
    # ------------------------------------------------------------------

    def _buscar_pepi(self, cnpj14: str) -> list[dict] | None:
        """Tenta portal pePI (HTML scraping). Retorna None em qualquer falha."""
        try:
            # Parâmetros do formulário de busca por titular (CNPJ)
            params = {
                "Action": "SearchBasic",
                "CNJ": cnpj14,
                "tipoPesquisa": "titular",
            }
            resp = self._session.get(_PEPI_URL, params=params, timeout=self.timeout)
            if not resp.ok:
                logger.debug("pePI INPI: HTTP %s", resp.status_code)
                return None
            ct = resp.headers.get("Content-Type", "")
            if "json" in ct:
                try:
                    return _parse_rest_json(resp.json(), cnpj14)
                except Exception:
                    pass
            return _parse_pepi_html(resp.text, cnpj14)
        except Exception as exc:
            logger.debug("pePI INPI indisponível: %s", exc)
            return None

    # ------------------------------------------------------------------
    # Lógica de alerta
    # ------------------------------------------------------------------

    def _gerar_alertas(self, marcas: list[dict], cnpj_fmt: str, ciclo: str) -> list[dict]:
        if not marcas:
            return [{
                "cnpj": cnpj_fmt,
                "ciclo": ciclo,
                "fonte": self.fonte,
                "categoria": "propriedade_intelectual",
                "severidade": "ok",
                "titulo": "Nenhuma marca registrada no INPI",
                "descricao": (
                    "CNPJ não possui marcas associadas na base do INPI. "
                    "Isso pode indicar que a empresa opera sem registro de marca."
                ),
                "is_novo": True,
            }]

        alertas: list[dict] = []
        for m in marcas:
            sit_norm = _situacao_normalizada(m.get("situacao") or "")
            numero = m.get("numero") or ""
            nome = m.get("nome") or "(sem nome)"
            classe = m.get("classe") or ""
            data_venc = m.get("data_vencimento")
            data_dep = m.get("data_deposito")
            url_marca = (
                f"https://busca.inpi.gov.br/pePI/servlet/MarcasServletController"
                f"?Action=Detail&CodMarca={numero}"
                if numero else
                "https://busca.inpi.gov.br/pePI/jsp/marcas/pesquisa_num_processo_cnd.jsp"
            )

            classe_txt = f" (classe {classe})" if classe else ""
            deposito_txt = f" Depósito: {data_dep}." if data_dep else ""
            venc_txt = f" Vencimento: {data_venc}." if data_venc else ""

            # ---- risco: oposição ou nulidade ----
            if any(r in sit_norm for r in _SITUACOES_RISCO):
                alertas.append({
                    "cnpj": cnpj_fmt,
                    "ciclo": ciclo,
                    "fonte": self.fonte,
                    "categoria": "propriedade_intelectual",
                    "severidade": "atencao",
                    "titulo": f"Marca '{nome}' com processo em andamento no INPI",
                    "descricao": (
                        f"A marca '{nome}'{classe_txt} (proc. {numero}) está com situação "
                        f"'{m['situacao']}', indicando possível oposição ou processo de nulidade."
                        f"{deposito_txt}{venc_txt}"
                    ),
                    "referencia_id": numero,
                    "data_evento": data_dep,
                    "url_fonte": url_marca,
                    "is_novo": True,
                })
                continue

            # ---- expirada recente ----
            if any(e in sit_norm for e in _SITUACOES_EXPIRADAS):
                if _recently_expired(data_venc) or _recently_expired(data_dep):
                    alertas.append({
                        "cnpj": cnpj_fmt,
                        "ciclo": ciclo,
                        "fonte": self.fonte,
                        "categoria": "propriedade_intelectual",
                        "severidade": "info",
                        "titulo": f"Marca '{nome}' expirada recentemente no INPI",
                        "descricao": (
                            f"A marca '{nome}'{classe_txt} (proc. {numero}) consta com situação "
                            f"'{m['situacao']}' e expirou nos últimos 6 meses."
                            f"{venc_txt}"
                        ),
                        "referencia_id": numero,
                        "data_evento": data_venc or data_dep,
                        "url_fonte": url_marca,
                        "is_novo": True,
                    })
                # expiradas antigas: ignorar (sem valor informacional imediato)
                continue

            # ---- marca ativa / registrada ----
            if any(a in sit_norm for a in _SITUACOES_ATIVAS):
                alertas.append({
                    "cnpj": cnpj_fmt,
                    "ciclo": ciclo,
                    "fonte": self.fonte,
                    "categoria": "propriedade_intelectual",
                    "severidade": "info",
                    "titulo": f"Marca registrada no INPI: '{nome}'",
                    "descricao": (
                        f"Empresa possui a marca '{nome}'{classe_txt} (proc. {numero}) "
                        f"com situação '{m['situacao']}' no INPI."
                        f"{deposito_txt}{venc_txt}"
                    ),
                    "referencia_id": numero,
                    "data_evento": data_dep,
                    "url_fonte": url_marca,
                    "is_novo": True,
                })

        # Se nenhuma situação conhecida gerou alerta, emite resumo genérico
        if not alertas:
            alertas.append({
                "cnpj": cnpj_fmt,
                "ciclo": ciclo,
                "fonte": self.fonte,
                "categoria": "propriedade_intelectual",
                "severidade": "info",
                "titulo": f"{len(marcas)} marca(s) localizada(s) no INPI",
                "descricao": (
                    f"Foram encontradas {len(marcas)} entrada(s) no INPI para este CNPJ. "
                    "Situações não enquadradas nas categorias de monitoramento automático."
                ),
                "is_novo": True,
            })

        return alertas

    # ------------------------------------------------------------------
    # Ponto de entrada público
    # ------------------------------------------------------------------

    def consultar_cnpj(self, cnpj: str, razao_social: str | None = None) -> list[dict]:
        cnpj14 = _strip(cnpj)
        cnpj_fmt = _fmt_cnpj(cnpj14)
        ciclo = _ciclo_atual()

        # Tenta REST primeiro; cai no pePI em caso de falha
        marcas: list[dict] | None = self._buscar_rest(cnpj14)
        if marcas is None:
            logger.info("INPI REST indisponível para %s — tentando pePI", cnpj_fmt)
            marcas = self._buscar_pepi(cnpj14)

        if marcas is None:
            # INPI fora do ar — falha silenciosa, sem registrar no Supabase
            logger.warning("INPI indisponível para %s — conector pulado", cnpj_fmt)
            return []

        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, marcas)
        if not mudou:
            logger.info("INPI marcas: sem mudanças para %s", cnpj_fmt)
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt,
            "fonte": self.fonte,
            "ciclo": ciclo,
            "hash_dados": hash_novo,
            "dados": {"total_marcas": len(marcas)},
        }])

        alertas = self._gerar_alertas(marcas, cnpj_fmt, ciclo)
        logger.info("INPI marcas: %d alerta(s) para %s", len(alertas), cnpj_fmt)
        return alertas
