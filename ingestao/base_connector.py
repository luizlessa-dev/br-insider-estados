"""
BaseConnector — The Brasilia Insider
Interface comum para todos os 27 conectores de assembleias estaduais + CLDF.

Todo conector concreto deve:
  1. Definir os atributos de classe: assembly_id, assembly_name, uf, base_url
  2. Implementar os 3 métodos abstratos: get_deputados, get_proposicoes, get_votacoes
  3. Opcionalmente sobrescrever health_check() se o endpoint padrão não servir
"""
from __future__ import annotations

import logging
import time
from abc import ABC, abstractmethod
from datetime import date, datetime
from typing import Optional

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

from .models import Deputado, Proposicao, Votacao


logger = logging.getLogger(__name__)


class ConnectorError(Exception):
    """Erro genérico de conector — sinaliza que a fonte está inacessível."""


class NotImplementedConnector(Exception):
    """Conector ainda não implementado (stub)."""


class BaseConnector(ABC):
    # ── Atributos obrigatórios nos subclasses ──────────────────────────────
    assembly_id: str    # ex: "almg", "alesp", "cldf"
    assembly_name: str  # ex: "Assembleia Legislativa de Minas Gerais"
    uf: str             # ex: "MG"
    base_url: str       # URL raiz do portal/API

    # ── Configurações com defaults razoáveis ──────────────────────────────
    request_delay: float = 0.5      # segundos entre requisições
    timeout: int = 30               # timeout HTTP em segundos
    max_retries: int = 3
    backoff_factor: float = 1.0

    def __init__(self) -> None:
        self.logger = logging.getLogger(f"connector.{self.assembly_id}")
        self.session = self._build_session()
        self._last_request: float = 0.0

    # ── Session com retry automático ──────────────────────────────────────
    def _build_session(self) -> requests.Session:
        session = requests.Session()
        retry = Retry(
            total=self.max_retries,
            backoff_factor=self.backoff_factor,
            status_forcelist=[429, 500, 502, 503, 504],
            allowed_methods=["GET", "POST"],
        )
        adapter = HTTPAdapter(max_retries=retry)
        session.mount("http://", adapter)
        session.mount("https://", adapter)
        session.headers.update({
            "User-Agent": (
                "BRInsider/1.0 "
                "(bot de dados públicos; contato@brinsider.com)"
            ),
            "Accept": "application/json",
        })
        return session

    # ── Helpers de requisição ─────────────────────────────────────────────
    def _throttle(self) -> None:
        """Garante intervalo mínimo entre requisições."""
        elapsed = time.monotonic() - self._last_request
        if elapsed < self.request_delay:
            time.sleep(self.request_delay - elapsed)
        self._last_request = time.monotonic()

    def _get(self, url: str, params: dict | None = None, **kwargs) -> dict | list:
        self._throttle()
        self.logger.debug("GET %s %s", url, params or "")
        try:
            resp = self.session.get(url, params=params, timeout=self.timeout, **kwargs)
            resp.raise_for_status()
            return resp.json()
        except requests.HTTPError as e:
            raise ConnectorError(f"HTTP {e.response.status_code} em {url}") from e
        except requests.RequestException as e:
            raise ConnectorError(f"Falha de rede em {url}: {e}") from e

    def _get_xml(self, url: str, params: dict | None = None, **kwargs) -> bytes:
        self._throttle()
        self.logger.debug("GET XML %s %s", url, params or "")
        try:
            resp = self.session.get(url, params=params, timeout=self.timeout, **kwargs)
            resp.raise_for_status()
            return resp.content
        except requests.RequestException as e:
            raise ConnectorError(f"Falha ao baixar XML de {url}: {e}") from e

    def _get_text(self, url: str, params: dict | None = None, **kwargs) -> str:
        self._throttle()
        try:
            resp = self.session.get(url, params=params, timeout=self.timeout, **kwargs)
            resp.raise_for_status()
            return resp.text
        except requests.RequestException as e:
            raise ConnectorError(f"Falha ao baixar texto de {url}: {e}") from e

    # ── Interface obrigatória ─────────────────────────────────────────────
    @abstractmethod
    def get_deputados(self) -> list[Deputado]:
        """Retorna todos os deputados do mandato atual."""
        ...

    @abstractmethod
    def get_proposicoes(self, data_inicio: date, data_fim: date) -> list[Proposicao]:
        """Retorna proposições apresentadas no período."""
        ...

    @abstractmethod
    def get_votacoes(self, data_inicio: date, data_fim: date) -> list[Votacao]:
        """Retorna votações realizadas no período."""
        ...

    # ── Health check ──────────────────────────────────────────────────────
    def health_check(self) -> bool:
        """Verifica se a fonte está acessível. Sobrescreva se necessário."""
        try:
            resp = self.session.get(self.base_url, timeout=10)
            ok = resp.status_code < 500
            if not ok:
                self.logger.warning("health_check falhou: HTTP %s", resp.status_code)
            return ok
        except Exception as e:
            self.logger.warning("health_check erro: %s", e)
            return False

    # ── Helpers de normalização ───────────────────────────────────────────
    @staticmethod
    def parse_date(value: str | None, fmt: str = "%Y-%m-%d") -> Optional[date]:
        if not value:
            return None
        try:
            return datetime.strptime(value[:10], fmt).date()
        except ValueError:
            return None

    def _prefix_id(self, raw_id: str | int) -> str:
        """Garante unicidade global: 'almg_12345'"""
        return f"{self.assembly_id}_{raw_id}"

    def __repr__(self) -> str:
        return f"<{self.__class__.__name__} assembly_id={self.assembly_id!r}>"


# ── Mixin para conectores ainda não implementados ────────────────────────
class StubConnector(BaseConnector):
    """
    Placeholder para assembleias sem conector implementado.
    Levanta NotImplementedConnector em vez de falhar silenciosamente.
    Registra a assembleia no registry para fins de health check e cobertura.
    """

    def get_deputados(self) -> list[Deputado]:
        raise NotImplementedConnector(
            f"{self.assembly_id} ({self.uf}): conector ainda não implementado."
        )

    def get_proposicoes(self, data_inicio: date, data_fim: date) -> list[Proposicao]:
        raise NotImplementedConnector(
            f"{self.assembly_id} ({self.uf}): conector ainda não implementado."
        )

    def get_votacoes(self, data_inicio: date, data_fim: date) -> list[Votacao]:
        raise NotImplementedConnector(
            f"{self.assembly_id} ({self.uf}): conector ainda não implementado."
        )

    def health_check(self) -> bool:
        """Stub: tenta o base_url mas não falha o pipeline."""
        try:
            resp = self.session.get(self.base_url, timeout=8)
            return resp.status_code < 500
        except Exception:
            return False
