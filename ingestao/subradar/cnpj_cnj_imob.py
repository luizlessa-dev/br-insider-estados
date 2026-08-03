"""
CNPJ-CNJ para Subradar Imob — dados de ônus reais registrados via CNPJ.
Fonte: API pública CNJ (CNPJ-CNJ ou via cartórios participantes)

Próximas versões:
- Integração ONR (manual, com custo)
- SICAR/IBAMA (CAR rural)
- Prefeituras (IPTU, habite-se)
"""
from __future__ import annotations

from .base_imob import SubradarImobSource, logger


class CNPJCNJImobConnector(SubradarImobSource):
    """CNPJ-CNJ — titularidade e ônus reais básicos."""
    fonte = "cnpj_cnj_registros"
    base_url = "https://www.cnj.jus.br"  # placeholder — sem API pública direta

    def consultar_imovel(self, matricula: str, cartorio_id: str | None = None) -> dict | None:
        """
        CNPJ-CNJ não expõe API pública para matrícula imobiliária.
        Implementação futura: integração via ONR (paga) ou parser de cartório.
        Por agora, retorna estrutura básica para teste.
        """
        self.log.info("consulta CNPJ-CNJ para matrícula: %s (cartório: %s)", matricula, cartorio_id)

        # TODO: integrar com ONR ou API de cartório específico
        # Para MVP: retornar None (não aplicável) até ter integração real
        return None


class OususReaisConnector(SubradarImobSource):
    """Placeholder para conectar dados de ônus reais."""
    fonte = "onus_reais"

    def consultar_imovel(self, matricula: str, cartorio_id: str | None = None) -> dict | None:
        """
        Ônus reais: hipotecas, alienação fiduciária, penhoras, servidões.
        Requer integração com RI Digital ou base de cartórios.
        """
        self.log.debug("ônus reais para %s (cartório: %s)", matricula, cartorio_id)
        return None
