"""ALERN — Assembleia Legislativa do Rio Grande do Norte (Tier 2, structure pending)"""
from __future__ import annotations
from ..base_connector import BaseConnector
from ..models import Deputado, Proposicao, Votacao

class ALERNConnector(BaseConnector):
    assembly_id = "alern"
    assembly_name = "Assembleia Legislativa do Rio Grande do Norte"
    uf = "RN"
    base_url = "https://www.al.rn.gov.br"
    request_delay = 0.8

    def get_deputados(self) -> list[Deputado]:
        self.logger.warning("ALERN: get_deputados not yet implemented")
        return []

    def get_proposicoes(self) -> list[Proposicao]:
        self.logger.warning("ALERN: get_proposicoes not yet implemented")
        return []

    def get_votacoes(self) -> list[Votacao]:
        self.logger.warning("ALERN: get_votacoes not yet implemented")
        return []
