"""
Negativações das pessoas envolvidas na transação — sem cobertura contratada.

A ideia era varrer inquilino, comprador e agente (tabela `sub_imob_pessoas`)
atrás de restrições. Duas coisas faltam: o formulário público do Imob só coleta
o proprietário, e o dataset `negative_data` do BigDataCorp está fora do plano
contratado (responde -109, sondado em 27/08/2026).

O risco do proprietário é coberto por `processos_proprietario_imob.py`, que usa
o dataset `processes`, esse sim liberado.

Retornava None e sumia do laudo. Agora declara a lacuna.
"""
from __future__ import annotations

from .base_imob import SubradarImobSource, sem_cobertura


class BigDataCorpImobConnector(SubradarImobSource):
    """Negativações de inquilino, comprador e agente."""
    fonte = "bigdatacorp_pessoas"

    def consultar_imovel(self, matricula: str, cartorio_id: str | None = None, **_) -> dict:
        return sem_cobertura(
            self.fonte, "pessoas", "Negativações das Pessoas Envolvidas",
            "o pedido coleta apenas o proprietário, e o dataset de negativações "
            "do BigDataCorp está fora do plano contratado (-109)",
            {"matricula": matricula, "requer": "dataset negative_data + coleta das demais partes"},
        )
