"""
Base para conectores de fontes do Subradar Imob.
Análogo a base.py mas especializado para imóveis (matrícula/cartório/endereço).
"""
from __future__ import annotations

import hashlib
import json
import logging
import os
import time
from datetime import date, datetime
from typing import Any

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

logger = logging.getLogger(__name__)

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SUPABASE_KEY = (
    os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    or os.environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY")
    or ""
)


def _ciclo_atual() -> str:
    return datetime.utcnow().strftime("%Y-%m")


def _jsonable(v: Any) -> Any:
    if isinstance(v, (date, datetime)):
        return v.isoformat()
    if isinstance(v, dict):
        return {k: _jsonable(x) for k, x in v.items()}
    if isinstance(v, (list, tuple)):
        return [_jsonable(x) for x in v]
    return v


def _hash(data: Any) -> str:
    raw = json.dumps(_jsonable(data), sort_keys=True, ensure_ascii=False)
    return hashlib.sha256(raw.encode()).hexdigest()


def _supabase_headers() -> dict:
    return {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates,return=minimal",
    }


def _normalize_rows(rows: list[dict]) -> list[dict]:
    """Garante que todos os dicts no batch tenham exatamente as mesmas chaves."""
    all_keys = set()
    for r in rows:
        all_keys.update(r.keys())
    return [{k: r.get(k) for k in all_keys} for r in rows]


# Chaves únicas por tabela, para o on_conflict do PostgREST.
# sub_imob_alertas não tem chave única: o runner apaga o ciclo antes de regravar
# (ver delete_where).
_CHAVES_UNICAS = {
    "sub_imob_dados": ("matricula", "ciclo", "fonte"),
    "sub_imob_resultados": ("matricula", "ciclo"),
}


def upsert(table: str, rows: list[dict]) -> None:
    if not rows:
        return
    if not SUPABASE_URL or not SUPABASE_KEY:
        logger.warning("SUPABASE_URL/KEY ausentes — pulando persistência")
        return
    url = f"{SUPABASE_URL}/rest/v1/{table}"
    chunk = 500
    for i in range(0, len(rows), chunk):
        batch = [_jsonable(r) for r in _normalize_rows(rows[i : i + chunk])]
        for attempt in range(5):
            try:
                # Sem on_conflict, o PostgREST insere em vez de mesclar e a
                # segunda apuração da mesma matrícula no mesmo ciclo morre em
                # 409. Reprocessar é justamente o caminho de recuperação depois
                # de destravar uma fonte pendente — precisa funcionar.
                req_url = url
                req_hdrs = {**_supabase_headers()}
                chaves = _CHAVES_UNICAS.get(table)
                if chaves:
                    req_url = f"{url}?on_conflict={','.join(chaves)}"
                req_hdrs["Prefer"] = "resolution=merge-duplicates,return=minimal"
                resp = requests.post(req_url, json=batch, headers=req_hdrs, timeout=60)
                if resp.ok:
                    break
                if resp.status_code in (429, 503):
                    wait = 2 ** attempt
                    logger.warning("upsert %s: %s — retry em %ds", table, resp.status_code, wait)
                    time.sleep(wait)
                    continue
                logger.error("upsert %s falhou: %s %s", table, resp.status_code, resp.text[:300])
                resp.raise_for_status()
            except requests.exceptions.ConnectionError as e:
                wait = 2 ** attempt
                logger.warning("upsert %s: conexão perdida (%s) — retry em %ds", table, e, wait)
                time.sleep(wait)
        else:
            raise RuntimeError(f"upsert {table}: falhou após 5 tentativas")
    logger.info("upsert %s: %d linhas", table, len(rows))


class SubradarImobSource:
    """Classe base para fontes do Subradar Imob."""
    fonte: str = ""
    base_url: str = ""
    request_delay: float = 0.5
    timeout: int = 30

    def __init__(self) -> None:
        self.log = logging.getLogger(f"subradar.imob.{self.fonte}")
        self._session = self._build_session()
        self._last: float = 0.0

    def _build_session(self) -> requests.Session:
        s = requests.Session()
        retry = Retry(total=3, backoff_factor=1.0, status_forcelist=[429, 500, 502, 503, 504])
        s.mount("https://", HTTPAdapter(max_retries=retry))
        s.headers.update({
            "User-Agent": "Subradar/1.0 (imobiliario; contato@subradar.com.br)",
            "Accept": "application/json",
        })
        return s

    def _get(self, url: str, params: dict | None = None, **kw) -> Any:
        elapsed = time.monotonic() - self._last
        if elapsed < self.request_delay:
            time.sleep(self.request_delay - elapsed)
        self._last = time.monotonic()
        self.log.debug("GET %s", url)
        r = self._session.get(url, params=params, timeout=self.timeout, **kw)
        r.raise_for_status()
        return r.json()

    def consultar_imovel(self, matricula: str, cartorio_id: str | None = None) -> dict | None:
        """
        Retorna dados estruturados para o laudo Imob ou None se não aplicável.

        Formato esperado:
        {
            "fonte":        str,   # ex: "cnpj_cnj_registros"
            "categoria":    str,   # titularidade | onus_reais | divida_ativa | judicial | ...
            "status":       str,   # limpo | alerta | pendente | erro | nao_aplicavel
            "titulo_secao": str,   # label no laudo
            "resumo":       str,   # 1 linha, ex: "Sem ônus registrados"
            "detalhes":     dict,  # payload completo
        }

        Retornar None significa que este conector não produz dados para o imóvel.
        Por padrão retorna None — subclasses que queiram aparecer no laudo implementam.
        """
        return None


# ---------------------------------------------------------------------------
# Vocabulário de status das seções do laudo
#
# A auditoria de 27/08/2026 (Subradar PF) mostrou que "lista vazia" e "não
# consegui consultar" viravam a mesma coisa no laudo: "nada consta". Aqui os
# dois casos são separados na origem e cada conector é obrigado a escolher.
#
#   limpo          consultei a fonte, ela respondeu, não há registro
#   alerta         há registro que merece atenção
#   critico        há registro grave
#   pendente       a fonte deveria responder e NÃO respondeu  -> retém a entrega
#   nao_aplicavel  a fonte não cobre este caso concreto        -> não é pendência
#   nao_contratada a fonte não está implementada/contratada    -> não é pendência,
#                  mas é declarada no laudo como limite de cobertura
# ---------------------------------------------------------------------------

STATUS_INCOMPLETO = {"pendente", "erro"}
STATUS_SEM_COBERTURA = {"nao_aplicavel", "nao_contratada"}


def pendencia(fonte: str, categoria: str, titulo: str, motivo: str,
              detalhes: dict | None = None) -> dict:
    """Fonte que deveria responder e não respondeu. Retém a entrega do laudo."""
    return {
        "fonte": fonte, "categoria": categoria, "status": "pendente",
        "titulo_secao": titulo,
        "resumo": f"Não foi possível consultar — {motivo}",
        "detalhes": detalhes or {},
    }


def sem_cobertura(fonte: str, categoria: str, titulo: str, motivo: str,
                  detalhes: dict | None = None) -> dict:
    """Fonte fora da cobertura contratada. Declarada no laudo, não retém entrega.

    Diferente de `pendencia`: aqui não houve falha, a fonte simplesmente não
    faz parte do que o produto cobre hoje. O cliente precisa ver isso escrito —
    é a diferença entre "verificamos e não há" e "não verificamos".
    """
    return {
        "fonte": fonte, "categoria": categoria, "status": "nao_contratada",
        "titulo_secao": titulo,
        "resumo": f"Fora da cobertura desta apuração — {motivo}",
        "detalhes": detalhes or {},
    }


def limpo(fonte: str, categoria: str, titulo: str, resumo: str,
          detalhes: dict | None = None) -> dict:
    """Fonte consultada com resposta válida e sem registro.

    Só use depois de confirmar que a requisição respondeu. Chamar isto no
    `except` de uma consulta é exatamente o bug que a auditoria do PF achou.
    """
    return {
        "fonte": fonte, "categoria": categoria, "status": "limpo",
        "titulo_secao": titulo, "resumo": resumo, "detalhes": detalhes or {},
    }


def delete_where(table: str, filtros: dict) -> None:
    """Apaga linhas antes de regravar.

    `sub_imob_alertas` não tem chave única, então o upsert só empilha. Ao
    reprocessar uma matrícula, o alerta da execução que falhou continuava no
    laudo ao lado do alerta da execução que deu certo — o dossiê exibia
    "fonte não consultada" e o resultado da mesma fonte, um contradizendo o
    outro.
    """
    if not SUPABASE_URL or not SUPABASE_KEY:
        return
    try:
        params = {k: f"eq.{v}" for k, v in filtros.items()}
        r = requests.delete(f"{SUPABASE_URL}/rest/v1/{table}",
                            headers=_supabase_headers(), params=params, timeout=30)
        if not r.ok:
            logger.warning("delete %s: HTTP %s %s", table, r.status_code, r.text[:200])
    except Exception as e:
        logger.warning("delete %s falhou: %s", table, e)
