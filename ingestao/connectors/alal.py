"""ALAL — Assembleia Legislativa de Alagoas (Tier 2, structure pending)"""
from __future__ import annotations
from ..base_connector import BaseConnector
from ..models import Deputado, Proposicao, Votacao

class ALALConnector(BaseConnector):
    assembly_id = "alal"
    assembly_name = "Assembleia Legislativa de Alagoas"
    uf = "AL"
    base_url = "https://www.al.al.gov.br"
    request_delay = 0.8

    def get_deputados(self) -> list[Deputado]:
        self.logger.warning("ALAL: get_deputados not yet implemented")
        return []

    def get_proposicoes(self) -> list[Proposicao]:
        self.logger.warning("ALAL: get_proposicoes not yet implemented")
        return []

    def get_votacoes(self) -> list[Votacao]:
        self.logger.warning("ALAL: get_votacoes not yet implemented")
        return []
