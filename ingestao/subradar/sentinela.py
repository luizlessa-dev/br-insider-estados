"""Sentinela de execução: observa as chamadas HTTP que um conector faz.

Por que existe
-------------
O dossiê PJ é montado a partir dos alertas gravados. Fonte que não grava linha
nenhuma aparece no PDF como "Nenhuma ocorrência encontrada" — verde. Isso
transforma qualquer falha silenciosa em afirmação de ausência.

Já existe proteção para o conector que reconhece a própria falha (levanta
`FonteIndisponivel`) e para o que estoura exceção (o runner captura). Sobra o
caso mais comum e mais perigoso: o conector que trata o erro por dentro, engole
o 403 e devolve `[]` como se a fonte tivesse respondido "nada consta". Foi assim
que o laudo de uma pessoa com oito processos saiu limpo.

Esta sentinela é o método da auditoria virado guarda permanente: interceptar as
requisições e perguntar, depois da consulta, se a fonte chegou a responder.

Regra de decisão
----------------
Só declara pendência quando **houve requisição à fonte externa e todas
falharam**. Nesse caso o `[]` não pode significar "nada consta" — não houve
resposta para sustentar a afirmação.

Zero requisições externas NÃO vira pendência: é ambíguo (cache, memoização,
Playwright, leitura de tabela local) e marcar isso como pendente encheria o
dossiê de ruído, que é o outro jeito de destruir a credibilidade do laudo. Esse
caso vira aviso no log, para investigação.

Chamadas ao Supabase ficam fora da conta: são infraestrutura do próprio
pipeline, não a fonte consultada. Sem essa exclusão, um snapshot gravado com
sucesso mascararia o 403 da fonte — que é exatamente o cenário do Escavador.
"""
from __future__ import annotations

import logging
from contextlib import contextmanager
from urllib.parse import urlparse

import requests
from requests.sessions import Session

from .base import SUPABASE_URL

logger = logging.getLogger("subradar.sentinela")

_HOST_SUPABASE = urlparse(SUPABASE_URL).netloc if SUPABASE_URL else ""


class Observacao:
    """Contagem das requisições feitas durante a consulta de uma fonte."""

    def __init__(self) -> None:
        self.externas = 0
        self.falhas = 0
        self.motivos: list[str] = []

    @property
    def todas_falharam(self) -> bool:
        return self.externas > 0 and self.falhas == self.externas

    @property
    def sem_requisicao(self) -> bool:
        return self.externas == 0

    def motivo_resumido(self) -> str:
        if not self.motivos:
            return "a fonte não respondeu"
        vistos: list[str] = []
        for m in self.motivos:
            if m not in vistos:
                vistos.append(m)
        cauda = "" if len(vistos) <= 2 else f" (+{len(vistos) - 2})"
        return "; ".join(vistos[:2]) + cauda


def _e_supabase(url: str) -> bool:
    if not _HOST_SUPABASE:
        return False
    try:
        return urlparse(url).netloc == _HOST_SUPABASE
    except Exception:
        return False


@contextmanager
def observar():
    """Conta as requisições externas feitas dentro do bloco.

    Faz patch em `Session.request`, que é o funil por onde passam tanto
    `session.get/post` quanto `requests.get/post` — a API de módulo cria uma
    Session e chama esse mesmo método.

    O patch é global enquanto o bloco durar. O runner PJ consulta as fontes em
    sequência, então não há mistura; se algum dia isso virar paralelo, a
    contagem precisa migrar para contextvars.
    """
    obs = Observacao()
    original = Session.request

    def instrumentado(self, method, url, *a, **kw):
        if _e_supabase(str(url)):
            return original(self, method, url, *a, **kw)
        obs.externas += 1
        try:
            resp = original(self, method, url, *a, **kw)
        except Exception as e:
            obs.falhas += 1
            obs.motivos.append(f"{type(e).__name__}")
            raise
        if resp.status_code >= 400:
            obs.falhas += 1
            obs.motivos.append(f"HTTP {resp.status_code}")
        return resp

    Session.request = instrumentado
    try:
        yield obs
    finally:
        Session.request = original


def avaliar(fonte: str, alertas: list, obs: Observacao) -> str | None:
    """Devolve o motivo da pendência, ou None se o resultado é confiável.

    `alertas` não vazio significa que a fonte produziu resultado — nada a fazer,
    mesmo que alguma requisição tenha falhado pelo caminho.
    """
    if alertas:
        return None
    if obs.todas_falharam:
        return (
            f"{obs.externas} requisição(ões) à fonte, todas sem resposta útil: "
            f"{obs.motivo_resumido()}"
        )
    if obs.sem_requisicao:
        logger.warning(
            "Fonte %s devolveu vazio sem fazer requisição externa — "
            "verificar se consulta por cache, Playwright ou tabela local",
            fonte,
        )
    return None
