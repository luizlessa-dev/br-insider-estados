"""
Dívida ativa do imóvel (IPTU e débitos municipais) — sem cobertura contratada.

IPTU em atraso acompanha o imóvel, não o antigo dono, então é dado central num
laudo de compra. Não há fonte nacional: cada prefeitura publica de um jeito, e
a consulta costuma exigir inscrição imobiliária (que o formulário não coleta) em
vez de matrícula. A PGFN cobre dívida federal por CPF/CNPJ, não por imóvel.

Retornava None e sumia do laudo. Agora declara a lacuna.
"""
from __future__ import annotations

from .base_imob import SubradarImobSource, sem_cobertura


class DividaAtivaImobConnector(SubradarImobSource):
    """Dívida ativa municipal sobre o imóvel."""
    fonte = "divida_ativa_imovel"

    def consultar_imovel(self, matricula: str, cartorio_id: str | None = None, **_) -> dict:
        return sem_cobertura(
            self.fonte, "divida_ativa", "Dívida Ativa Imobiliária (IPTU)",
            "não há fonte nacional de IPTU por matrícula; a consulta municipal "
            "exige inscrição imobiliária e integração por prefeitura",
            {"matricula": matricula, "requer": "inscrição imobiliária + integração municipal"},
        )
