"""
BigDataCorp Imob — negativações e scores de pessoas via imóvel.
Reusar estrutura de bigdatacorp_negativacoes.py mas para inquilinos/compradores.
"""
from __future__ import annotations

import logging
from .base_imob import SubradarImobSource

logger = logging.getLogger(__name__)


class BigDataCorpImobConnector(SubradarImobSource):
    """BigDataCorp — negativações de pessoas envolvidas no imóvel."""
    fonte = "bigdatacorp_negativacoes_imovel"
    base_url = "https://api.bigdatacorp.com.br"

    def consultar_imovel(self, matricula: str, cartorio_id: str | None = None) -> dict | None:
        """
        Busca negativações de pessoas vinculadas ao imóvel:
        - Inquilino: negativações, protestos, restrições
        - Comprador: score de crédito, capacidade pagamento
        - Proprietário: débitos, restrições financeiras
        
        TODO: integração com CPF/CNPJ do envolvido (extrair de transações)
        """
        self.log.info("bigdatacorp: verificando negativações para matrícula: %s", matricula)
        
        return None  # TODO: implementar após ter CPF/CNPJ de envolvidos
