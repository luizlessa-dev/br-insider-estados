"""
ALESC — Assembleia Legislativa de Santa Catarina
Tier 2 — Partial implementation (HTML structure to be mapped)

Base: https://www.alesc.sc.gov.br
Status: Basic structure mapped, full scraping pending detailed site exploration
"""
from __future__ import annotations

from datetime import date
from typing import Optional
import re

from bs4 import BeautifulSoup

from ..base_connector import BaseConnector
from ..models import Deputado, Proposicao, Votacao


class ALESCConnector(BaseConnector):
    assembly_id = "alesc"
    assembly_name = "Assembleia Legislativa de Santa Catarina"
    uf = "SC"
    base_url = "https://www.alesc.sc.gov.br"

    request_delay = 0.8

    # ── Deputados ──────────────────────────────────────────────────
    def get_deputados(self) -> list[Deputado]:
        """
        Fetch current deputies from ALESC.

        Note: ALESC site structure requires mapping. For now, returning empty
        to avoid pipeline breakage. Implementation pending.
        """
        url = f"{self.base_url}/deputados/"

        try:
            response = self._get(url, allow_redirects=True)
            # TODO: Map ALESC HTML structure and extract deputados
            # Site appears to use WordPress + JavaScript rendering
            # Requires Selenium or detailed site inspection
        except Exception as e:
            self.logger.error("ALESC: Failed to fetch deputados page: %s", e)

        self.logger.warning("ALESC: get_deputados not yet implemented (site structure needs mapping)")
        return []

    # ── Proposições ──────────────────────────────────────────────────
    def get_proposicoes(self) -> list[Proposicao]:
        """Fetch propositions from ALESC (not yet implemented)."""
        self.logger.warning("ALESC: get_proposicoes not yet implemented")
        return []

    # ── Votações ──────────────────────────────────────────────────
    def get_votacoes(self) -> list[Votacao]:
        """Fetch votes from ALESC (not yet implemented)."""
        self.logger.warning("ALESC: get_votacoes not yet implemented")
        return []

    # ── Helper methods ──────────────────────────────────────────────────
    def _get(self, url: str, **kwargs) -> str:
        """Override to ensure we get HTML text, not JSON."""
        self._throttle()
        try:
            response = self.session.get(url, timeout=self.timeout, **kwargs)
            response.raise_for_status()
            return response.text
        except Exception as e:
            self.logger.error("ALESC: GET %s failed: %s", url, e)
            raise
