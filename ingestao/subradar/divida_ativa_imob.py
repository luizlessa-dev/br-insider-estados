"""
Dívida Ativa Imobiliária — IPTU e débitos municipais via PGFN/prefeituras.
"""
from __future__ import annotations

import logging
from .base_imob import SubradarImobSource

logger = logging.getLogger(__name__)


class DividaAtivaImobConnector(SubradarImobSource):
    """Dívida ativa imobiliária (IPTU, municipal)."""
    fonte = "divida_ativa_imovel"
    base_url = "https://www.pgfn.gov.br"

    def consultar_imovel(self, matricula: str, cartorio_id: str | None = None) -> dict | None:
        """
        Busca dívida ativa do imóvel:
        - IPTU em aberto (via prefeituras)
        - Débitos municipais (SIAFI municipal)
        - Inscrição em dívida ativa da União
        
        TODO: integração com prefeituras locais (variam por município)
        Por agora: placeholder esperando estrutura de prefeituras
        """
        self.log.info("divida_ativa: verificando débitos para matrícula: %s", matricula)
        
        # Será necessário:
        # 1. Extrair município/UF da matrícula ou endereço
        # 2. Consultar prefeitura local (API varia por cidade)
        # 3. Agregar PGFN dívida ativa federal
        
        return None  # TODO: implementar com integrações municipais
