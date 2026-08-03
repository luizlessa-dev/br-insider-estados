"""
Datajud Imob — ações judiciais sobre imóvel via CNJ.
Reusar estrutura de datajud.py (PF/PJ) mas filtrar por "ação real imobiliária".
"""
from __future__ import annotations

import logging
from .base_imob import SubradarImobSource

logger = logging.getLogger(__name__)


class DatajudImobConnector(SubradarImobSource):
    """Ações judiciais sobre imóvel via Datajud/CNJ."""
    fonte = "datajud_acoes_imovel"
    base_url = "https://api-publica.datajud.cnj.jus.br"

    def consultar_imovel(self, matricula: str, cartorio_id: str | None = None) -> dict | None:
        """
        Busca ações judiciais reais (sobre o imóvel) via Datajud.
        
        Tipos buscados:
        - Execução de imóvel
        - Ação de despejo
        - Ação reivindicatória
        - Ação de usucapião
        - Ação de reintegração de posse
        
        TODO: implementar busca por matrícula/endereço quando Datajud suportar
        """
        self.log.info("datajud: buscando ações judiciais para matrícula: %s", matricula)
        
        # Datajud hoje busca por CNPJ/CPF, não por matrícula
        # Será necessário:
        # 1. Consultar proprietário via ONR/CNPJ-CNJ
        # 2. Buscar ações em nome do proprietário
        # 3. Filtrar apenas ações reais (sobre o imóvel)
        
        return None  # TODO: implementar com ONR integration
