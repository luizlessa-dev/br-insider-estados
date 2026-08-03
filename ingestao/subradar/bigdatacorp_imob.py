"""
BigDataCorp Imob — negativações de pessoas envolvidas com imóvel.
Busca: inadimplência, protestos, bloqueios, restrições em nome de inquilino/comprador/proprietário.
"""
from __future__ import annotations

import logging
from datetime import datetime

from .base_imob import SubradarImobSource

logger = logging.getLogger(__name__)


class BigDataCorpImobConnector(SubradarImobSource):
    """Busca negativações de pessoas vinculadas ao imóvel."""

    fonte = "bigdatacorp_pessoas"
    base_url = "https://api.bigdatacorp.com.br"
    request_delay = 1.0

    def consultar_imovel(
        self, matricula: str, cartorio_id: str | None = None
    ) -> dict | None:
        """
        Busca negativações de pessoas (inquilino/comprador/proprietário).

        Limitação:
          Precisamos dos dados de pessoas vinculadas ao imóvel.
          Dados obtidos de:
            - sub_imob_pessoas (inquilino, comprador, proprietário, agente)

        Fluxo:
          1. Buscar pessoas vinculadas à consulta na sub_imob_pessoas
          2. Para cada pessoa: buscar negativações via BigDataCorp
          3. Consolidar em relatório único

        TODO:
          1. Integrar com sub_imob_pessoas (já está no schema)
          2. Implementar busca real via BigDataCorp API
          3. Adicionar suporte para consulta por CPF/CNPJ
        """
        self.log.info(
            "bigdatacorp: buscando negativações para matrícula: %s", matricula
        )

        # Placeholder até integrar com sub_imob_pessoas
        return None

    def _buscar_negativacoes_pessoa(
        self, cpf_cnpj: str, tipo: str = "PF"
    ) -> list[dict] | None:
        """
        Busca negativações em nome de pessoa/empresa.

        Args:
          cpf_cnpj: CPF (11 dígitos) ou CNPJ (14 dígitos)
          tipo: PF (Pessoa Física) | PJ (Pessoa Jurídica)

        TODO: Implementar busca real via BigDataCorp.
        Quando implementar:
          1. Validar API token (variável de ambiente)
          2. GET /consultas/pf?cpf={cpf}
          3. Retornar negativações com severidade
        """
        pass

    def _processar_negativacoes(
        self, negativacoes: list[dict]
    ) -> dict | None:
        """Processa lista de negativações e retorna no formato esperado."""
        if not negativacoes:
            return None

        return {
            "fonte": self.fonte,
            "categoria": "pessoas",
            "status": "alerta" if negativacoes else "limpo",
            "titulo_secao": "Negativações de Pessoas Envolvidas",
            "resumo": f"{len(negativacoes)} negativação(ões) encontrada(s)",
            "detalhes": {
                "total": len(negativacoes),
                "negativacoes": negativacoes,
                "atualizado_em": datetime.utcnow().isoformat(),
            },
        }
