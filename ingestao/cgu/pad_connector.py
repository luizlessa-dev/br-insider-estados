"""
CGU-PAD Connector — The Brasilia Insider
Baixa e parseia o CSV mensal do Sistema CGU-PAD (Processos Administrativos
Disciplinares do Poder Executivo Federal).

Fonte: https://dadosabertos-download.cgu.gov.br/CGUPAD/CGUPAD.csv
Encoding: Latin-1 · Delimitador: ponto-e-vírgula · ~90 k linhas

Campos do CSV:
  NumeroPadPrincipal, Tipo_Processo, Assuntos, Pasta, Entidade,
  Estado, Cidade, Data_Instauracao, Fase_Atual, Data_Fase_Atual,
  investigados, advertências, suspensões, expulsivas, outras
"""
from __future__ import annotations

import csv
import io
import logging
import re
import time
from datetime import date, datetime
from typing import Iterator

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

from .models import ProcessoDisciplinar

logger = logging.getLogger("cgu.pad")

CSV_URL = "https://dadosabertos-download.cgu.gov.br/CGUPAD/CGUPAD.csv"
ENCODING = "latin-1"
DELIMITER = ";"

# Padrão de timestamp do CGU: "2006/05/10 00:00:00.000000000"
_DATE_RE = re.compile(r"(\d{4})/(\d{2})/(\d{2})")


def _parse_date(value: str | None) -> date | None:
    if not value:
        return None
    m = _DATE_RE.match(value.strip())
    if not m:
        return None
    try:
        return date(int(m.group(1)), int(m.group(2)), int(m.group(3)))
    except ValueError:
        return None


def _parse_assuntos(raw: str) -> list[str]:
    """
    O campo Assuntos é uma string de assuntos separados por ' - ' com
    fragmentos soltos e hífens isolados. Extrai entradas com conteúdo real.
    """
    if not raw or not raw.strip():
        return []
    partes = [p.strip().strip("-").strip() for p in raw.split(" - ")]
    return [p for p in partes if p and p != "-" and len(p) > 3]


def _safe_int(value: str | None) -> int:
    try:
        return int(value or 0)
    except (ValueError, TypeError):
        return 0


def _build_session() -> requests.Session:
    session = requests.Session()
    retry = Retry(
        total=3,
        backoff_factor=2.0,
        status_forcelist=[429, 500, 502, 503, 504],
        allowed_methods=["GET"],
    )
    adapter = HTTPAdapter(max_retries=retry)
    session.mount("https://", adapter)
    session.headers.update({
        "User-Agent": "BRInsider/1.0 (bot dados públicos; contato@thebrinsider.com)",
        "Accept-Encoding": "gzip, deflate",
    })
    return session


class CGUPADConnector:
    """Baixa o CSV do CGU-PAD e itera sobre ProcessoDisciplinar."""

    def __init__(self, url: str = CSV_URL) -> None:
        self.url = url
        self.session = _build_session()

    def fetch_raw(self) -> bytes:
        logger.info("Baixando CGU-PAD de %s", self.url)
        t0 = time.monotonic()
        resp = self.session.get(self.url, timeout=120, stream=False)
        resp.raise_for_status()
        elapsed = time.monotonic() - t0
        size_mb = len(resp.content) / 1_048_576
        logger.info("CGU-PAD: %.1f MB baixados em %.1fs", size_mb, elapsed)
        return resp.content

    def parse(self, raw: bytes) -> Iterator[ProcessoDisciplinar]:
        text = raw.decode(ENCODING)
        reader = csv.DictReader(io.StringIO(text), delimiter=DELIMITER)
        for i, row in enumerate(reader):
            numero = (row.get("NumeroPadPrincipal") or "").strip()
            if not numero:
                logger.debug("Linha %d sem NumeroPadPrincipal — pulando", i + 2)
                continue

            yield ProcessoDisciplinar(
                numero_processo=numero,
                tipo_processo=(row.get("Tipo_Processo") or "").strip() or None,
                assuntos=_parse_assuntos(row.get("Assuntos") or ""),
                pasta=(row.get("Pasta") or "").strip() or None,
                entidade=(row.get("Entidade") or "").strip() or None,
                uf=(row.get("Estado") or "").strip()[:2] or None,
                cidade=(row.get("Cidade") or "").strip().title() or None,
                data_instauracao=_parse_date(row.get("Data_Instauracao")),
                fase_atual=(row.get("Fase_Atual") or "").strip() or None,
                data_fase=_parse_date(row.get("Data_Fase_Atual")),
                n_investigados=_safe_int(row.get("investigados")),
                n_advertencias=_safe_int(row.get("advertências")),
                n_suspensoes=_safe_int(row.get("suspensões")),
                n_expulsivas=_safe_int(row.get("expulsivas")),
                n_outras_sancoes=_safe_int(row.get("outras")),
            )

    def load(self) -> list[ProcessoDisciplinar]:
        """Baixa e parseia o CSV completo. Retorna lista."""
        raw = self.fetch_raw()
        processos = list(self.parse(raw))
        logger.info("CGU-PAD: %d processos parseados", len(processos))
        return processos
