"""ALEPI — Assembleia Legislativa do Piauí (Tier 2, structure pending)"""
from __future__ import annotations
from ..base_connector import BaseConnector
from ..models import Deputado, Proposicao, Votacao

class ALEPIConnector(BaseConnector):
    assembly_id = "alepi"
    assembly_name = "Assembleia Legislativa do Piauí"
    uf = "PI"
    base_url = "https://www.al.pi.gov.br"
    request_delay = 0.8

    def get_deputados(self) -> list[Deputado]:
        self.logger.warning("ALEPI: get_deputados not yet implemented")
        return []

    def get_proposicoes(self) -> list[Proposicao]:
        self.logger.warning("ALEPI: get_proposicoes not yet implemented")
        return []

    def get_votacoes(self) -> list[Votacao]:
        self.logger.warning("ALEPI: get_votacoes not yet implemented")
        return []
