"""ALEPA — Assembleia Legislativa do Pará (Tier 3, JS-heavy site pending mapping)"""
from __future__ import annotations
from bs4 import BeautifulSoup
from ..base_connector import BaseConnector
from ..models import Deputado, Proposicao, Votacao

class ALEPAConnector(BaseConnector):
    """
    ALEPA uses JavaScript rendering. Requires Selenium or detailed endpoint discovery.

    Known endpoints:
      - /Institucional/Deputados → redirects, JS-rendered list
      - /Institucional/Deputado/{ID} → individual deputy profile
      - /Home/Page/Proposicoes → propositions (JS-rendered)
    """
    assembly_id = "alepa"
    assembly_name = "Assembleia Legislativa do Pará"
    uf = "PA"
    base_url = "https://www.alepa.pa.gov.br"
    request_delay = 0.8

    def get_deputados(self) -> list[Deputado]:
        """
        ALEPA site is JS-rendered. HTML scraping won't work without Selenium.
        TODO: Implement Selenium-based scraping or find JSON API endpoint.
        """
        self.logger.warning("ALEPA: get_deputados requires JS rendering (Selenium) - not yet implemented")
        return []

    def get_proposicoes(self) -> list[Proposicao]:
        self.logger.warning("ALEPA: get_proposicoes not yet implemented")
        return []

    def get_votacoes(self) -> list[Votacao]:
        self.logger.warning("ALEPA: get_votacoes not yet implemented")
        return []
