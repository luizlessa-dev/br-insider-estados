"""
Datajud/CNJ para o Subradar Imob — fonte descartada, com a evidência registrada.

O desenho original buscava ações reais sobre o imóvel pelo CPF/CNPJ do
proprietário, em `POST /consultas` com os parâmetros `parteNome` e
`classeJudicial`, e classificava as ações pelos códigos 10003 a 10007. Três
problemas, todos verificados contra a API real em 27/08/2026 com a
`DATAJUD_API_KEY` de produção:

1. O método `_fazer_request` nunca existiu na classe base. Toda consulta
   levantava AttributeError, era engolida pelo `except` de cada classe, e o
   conector concluía "Nenhuma ação judicial encontrada" — um falso "limpo"
   idêntico aos oito achados na auditoria do Subradar PF.
2. Os códigos de classe 10003–10007 não existem. Em `api_publica_tjsp` cada um
   devolve `total: 0`, enquanto os códigos CNJ reais devolvem volume: 58
   (Reintegração de Posse) e 81 (Usucapião) estouram o teto de 10.000, 46
   (Reivindicatória) devolve 4.038.
3. O que inviabiliza a fonte: a API pública não indexa as partes. Os campos do
   `_source` são @timestamp, assuntos, classe, dataAjuizamento,
   dataHoraUltimaAtualizacao, formato, grau, id, movimentos, nivelSigilo,
   numeroProcesso, orgaoJulgador, sistema e tribunal. Não há nome nem
   CPF/CNPJ. Controle: `query_string` por "PETROBRAS", "PETROLEO BRASILEIRO",
   "33.000.167/0001-01" e "33000167000101" devolve 0 em todos os casos; a mesma
   `query_string` sobre um `numeroProcesso` colhido do próprio índice devolve 2.
   A busca funciona — o dado de parte é que não está publicado. `_mapping`
   responde 403, então nem a inspeção do esquema é aberta.

Buscar processo por proprietário na API pública é impossível, não é questão de
ajustar a query. A cobertura judicial do Imob passou para
`processos_proprietario_imob.py`, que consulta o BigDataCorp pelo CPF/CNPJ.

Este conector fica no laudo declarando a lacuna, em vez de sumir em silêncio:
o cliente precisa saber que a matrícula em si não foi cruzada com o Judiciário.
Reativar exige convênio com o CNJ para a API restrita, que expõe as partes.
"""
from __future__ import annotations

from .base_imob import SubradarImobSource, sem_cobertura


class DatajudImobConnector(SubradarImobSource):
    """Ações reais sobre o imóvel via Datajud — sem cobertura na API pública."""

    fonte = "datajud_acoes_imovel"
    base_url = "https://api-publica.datajud.cnj.jus.br"
    request_delay = 1.0

    def consultar_imovel(
        self, matricula: str, cartorio_id: str | None = None, **_
    ) -> dict:
        return sem_cobertura(
            self.fonte, "judicial",
            "Ações Reais sobre o Imóvel (Datajud/CNJ)",
            "a API pública do CNJ não publica as partes do processo, o que "
            "impede buscar ações pelo proprietário ou pela matrícula; "
            "a cobertura judicial desta apuração vem da seção "
            "'Ações Judiciais do Proprietário'",
            {
                "verificado_em": "2026-08-27",
                "campos_publicados": [
                    "@timestamp", "assuntos", "classe", "dataAjuizamento",
                    "dataHoraUltimaAtualizacao", "formato", "grau", "id",
                    "movimentos", "nivelSigilo", "numeroProcesso",
                    "orgaoJulgador", "sistema", "tribunal",
                ],
                "requer": "convênio CNJ para a API restrita",
            },
        )
