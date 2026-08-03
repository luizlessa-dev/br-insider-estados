"""
Dívida Ativa Imobiliária — IPTU/débitos municipais e PGFN.
Fontes:
  - PGFN (Procuradoria Geral da Fazenda Nacional): dívida ativa federal
  - Prefeituras municipais: IPTU e débitos locais
"""
from __future__ import annotations

import logging
from datetime import datetime

from .base_imob import SubradarImobSource

logger = logging.getLogger(__name__)


class DividaAtivaImobConnector(SubradarImobSource):
    """Consulta dívida ativa municipal (IPTU) e federal (PGFN)."""

    fonte = "divida_ativa_imovel"
    base_url = "https://www.pgfn.gov.br"
    request_delay = 1.0

    def consultar_imovel(
        self, matricula: str, cartorio_id: str | None = None
    ) -> dict | None:
        """
        Busca dívida ativa sobre imóvel.

        Fontes consultadas:
          1. PGFN: dívida ativa federal (imóvel vinculado a processo de execução)
          2. Prefeitura: IPTU e débitos municipais

        Limitações:
          - PGFN não possui API pública para consulta por matrícula
          - Prefeituras: cada município tem sistema diferente
          - Necessário integração específica por município

        TODO:
          1. Integrar com PGFN via Datajud (ações de execução federal)
          2. Integrar com API de prefeituras (ex: BHTRANS para BH)
          3. Armazenar CEP do imóvel para identificar município
        """
        self.log.info(
            "divida_ativa: buscando dívida ativa para matrícula: %s", matricula
        )

        return None

    def _buscar_divida_pgfn(self, proprietario: str) -> list[dict] | None:
        """
        Busca dívida ativa federal via PGFN.

        TODO: Implementar integração com PGFN.
        Opções:
          1. Datajud: buscar ações de execução fiscal federal
          2. API PGFN (se disponível): GET /divida-ativa?nome={proprietario}
        """
        pass

    def _buscar_divida_municipal(self, endereco: str, cep: str) -> list[dict] | None:
        """
        Busca dívida ativa municipal (IPTU).

        TODO: Implementar integração por município.
        Template para BH (BHTRANS):
          GET https://bhtrans.pbh.gov.br/api/multas?endereco={endereco}&cep={cep}
        """
        pass
