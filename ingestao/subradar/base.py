"""
Base para conectores de fontes do Subradar.
Mais simples que o BaseConnector de assembleias — sem abstração de deputados/votações.
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
    """Garante que todos os dicts no batch tenham exatamente as mesmas chaves (PGRST102)."""
    all_keys = set()
    for r in rows:
        all_keys.update(r.keys())
    return [{k: r.get(k) for k in all_keys} for r in rows]


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
                # sub_snapshots: unique (cnpj/cpf, ciclo, fonte) — usa on_conflict para ignorar duplicatas
                req_url  = url
                req_hdrs = {**_supabase_headers()}
                if table == "sub_snapshots":
                    # Detecta se é PF (cpf) ou PJ (cnpj)
                    has_cpf = any("cpf" in row for row in batch)
                    has_cnpj = any("cnpj" in row for row in batch)
                    conflict_key = "cpf,ciclo,fonte" if has_cpf else "cnpj,ciclo,fonte"
                    req_url  = url + f"?on_conflict={conflict_key}"
                    req_hdrs["Prefer"] = "resolution=ignore-duplicates,return=minimal"
                elif table == "sub_pf_dados":
                    req_url  = url + "?on_conflict=cpf,ciclo,fonte"
                    req_hdrs["Prefer"] = "resolution=merge-duplicates,return=minimal"
                elif table == "sub_pf_resultados":
                    # id é determinístico (uuid5 de cpf+ciclo) — sem on_conflict, uma
                    # segunda consulta do mesmo CPF no mesmo mês colide na PK e falha.
                    req_url  = url + "?on_conflict=id"
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


def patch(table: str, match: dict, fields: dict) -> None:
    """Atualiza parcialmente linhas que casam com `match` (ex: {"id": "..."}), setando `fields`.

    Diferente de `upsert`, que faz POST simples (sem on_conflict) e portanto sempre
    tenta INSERT — usado quando a linha já existe e só queremos mudar alguns campos.
    """
    if not SUPABASE_URL or not SUPABASE_KEY:
        logger.warning("SUPABASE_URL/KEY ausentes — pulando update em %s", table)
        return
    url = f"{SUPABASE_URL}/rest/v1/{table}"
    params = {k: f"eq.{v}" for k, v in match.items()}
    headers = {**_supabase_headers(), "Prefer": "return=minimal"}
    body = dict(fields)
    if table == "sub_pf_consultas" and "updated_at" not in body:
        body["updated_at"] = datetime.utcnow().isoformat()
    resp = requests.patch(url, params=params, json=_jsonable(body), headers=headers, timeout=30)
    if not resp.ok:
        logger.error("patch %s falhou: %s %s", table, resp.status_code, resp.text[:300])
    resp.raise_for_status()


def snapshot_changed(cnpj: str, fonte: str, ciclo: str, dados: Any) -> tuple[bool, str]:
    """Retorna (mudou, hash_novo). Consulta sub_snapshots para comparar."""
    h = _hash(dados)
    if not SUPABASE_URL or not SUPABASE_KEY:
        return True, h
    url = f"{SUPABASE_URL}/rest/v1/sub_snapshots"
    params = {"cnpj": f"eq.{cnpj}", "fonte": f"eq.{fonte}", "ciclo": f"eq.{ciclo}"}
    resp = requests.get(url, params=params, headers=_supabase_headers(), timeout=15)
    rows = resp.json() if resp.ok else []
    if not rows:
        return True, h
    return rows[0].get("hash_dados") != h, h


class FonteIndisponivel(Exception):
    """A fonte não pôde ser consultada — não que ela tenha respondido "nada consta".

    Levantada por um conector quando a consulta falha por motivo externo: HTTP
    4xx/5xx, timeout, credencial ausente, endpoint descontinuado, coluna que
    sumiu do banco. O runner converte em um alerta de severidade "pendente",
    que aparece no dossiê e não pontua no score.

    A regra que motivou isto: ausência de resposta não é ausência de registro.
    Conector que não conseguiu consultar nunca devolve lista vazia — devolver
    vazio é afirmar que a fonte está limpa.
    """

    def __init__(self, motivo: str, detalhe: str | None = None) -> None:
        super().__init__(motivo if not detalhe else f"{motivo}: {detalhe}")
        self.motivo = motivo
        self.detalhe = detalhe


def alerta_pendente(
    doc: str,
    fonte: str,
    motivo: str,
    *,
    categoria: str = "cobertura",
    ciclo: str | None = None,
    titulo_fonte: str | None = None,
    url_fonte: str | None = None,
) -> dict:
    """Monta o alerta que registra "não foi possível consultar esta fonte"."""
    rotulo = titulo_fonte or fonte
    return {
        "cnpj": doc,
        "ciclo": ciclo or _ciclo_atual(),
        "fonte": fonte,
        "categoria": categoria,
        "severidade": "pendente",
        "titulo": f"{rotulo} — não foi possível consultar",
        "descricao": (
            f"A consulta a esta fonte não foi concluída ({motivo}). "
            "Este item NÃO significa ausência de registro: a fonte não respondeu, "
            "e portanto nada pode ser afirmado sobre ela neste ciclo."
        ),
        "url_fonte": url_fonte,
        "is_novo": True,
    }


class SubradarSource:
    """Classe base para fontes do Subradar."""
    fonte: str = ""
    base_url: str = ""
    request_delay: float = 0.5
    timeout: int = 30

    def __init__(self) -> None:
        self.log = logging.getLogger(f"subradar.{self.fonte}")
        self._session = self._build_session()
        self._last: float = 0.0

    def _build_session(self) -> requests.Session:
        s = requests.Session()
        retry = Retry(total=3, backoff_factor=1.0, status_forcelist=[429, 500, 502, 503, 504])
        s.mount("https://", HTTPAdapter(max_retries=retry))
        s.headers.update({
            "User-Agent": "Subradar/1.0 (dados-publicos; contato@subradar.com.br)",
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

    def consultar_cnpj(self, cnpj: str, razao_social: str | None = None) -> list[dict]:
        """Retorna lista de alertas para o CNPJ. Implementar no subclasse.

        `razao_social` é sempre passado pelo runner. Conector que omitir o
        parâmetro estoura TypeError em 100% das consultas — foi o que
        aconteceu com 21 fontes, entre elas CEIS, CNEP, CEPIM, SICAF e PGFN.
        """
        raise NotImplementedError

    def resumo_pf(self, cpf: str, nome: str | None = None) -> dict | None:
        """
        Retorna dados estruturados para o laudo PF ou None se não aplicável.

        Formato esperado:
        {
            "fonte":        str,   # ex: "cpf_situacao_rfb"
            "categoria":    str,   # cadastral | societario | judicial | sancao | financeiro | internacional
            "status":       str,   # limpo | alerta | pendente | erro | nao_aplicavel
            "titulo_secao": str,   # label no laudo, ex: "Situação CPF"
            "resumo":       str,   # 1 linha, ex: "REGULAR" / "2 processos encontrados"
            "detalhes":     dict,  # payload completo
        }

        Retornar None significa que este conector não produz dados para o laudo PF.
        Por padrão retorna None — subclasses que queiram aparecer no laudo implementam.
        """
        return None


# ─────────────────────────────────────────────────────────────
# Cache de execução
# ─────────────────────────────────────────────────────────────
#
# O runner chama consultar_cpf/consultar_cnpj E resumo_pf de cada fonte, e em
# vários conectores o resumo_pf refaz a consulta por dentro. O DOU varria os
# diários duas vezes; as certidões da Justiça Federal eram emitidas quatro
# vezes (dois tipos x dois métodos), cobrando o dobro. Este cache guarda o
# resultado durante uma execução e é limpo a cada CPF processado.

import threading as _threading
from functools import wraps as _wraps

_MEMO: dict = {}
_MEMO_LOCK = _threading.Lock()


def limpar_memo() -> None:
    """Zera o cache. Chamado no início de cada processamento de CPF."""
    with _MEMO_LOCK:
        _MEMO.clear()


def memoizar(fn):
    """Memoiza por argumentos durante a execução corrente.

    Só para consultas idempotentes de leitura — nunca para algo que grave.
    """
    @_wraps(fn)
    def wrapper(*args, **kwargs):
        try:
            chave = (fn.__module__, fn.__qualname__, args, tuple(sorted(kwargs.items())))
            hash(chave)
        except TypeError:
            return fn(*args, **kwargs)  # argumento não-hasheável: segue sem cache
        with _MEMO_LOCK:
            if chave in _MEMO:
                return _MEMO[chave]
        resultado = fn(*args, **kwargs)
        with _MEMO_LOCK:
            _MEMO[chave] = resultado
        return resultado
    return wrapper
