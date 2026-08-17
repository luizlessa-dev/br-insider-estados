"""
Datajud Imob — ações judiciais reais sobre imóvel via CNJ.
API Pública: https://api-publica.datajud.cnj.jus.br

Tipos de ação real imobiliária:
  10003 — Execução de Imóvel
  10004 — Ação de Despejo
  10005 — Ação Reivindicatória
  10006 — Ação de Usucapião
  10007 — Ação de Reintegração de Posse
"""
from __future__ import annotations

import logging
from datetime import datetime, timedelta
from urllib.parse import quote

from .base_imob import SubradarImobSource

logger = logging.getLogger(__name__)

# Tipos de ação imobiliária
TIPOS_ACAO_IMOVEL = {
    "10003": "Execução de Imóvel",
    "10004": "Ação de Despejo",
    "10005": "Ação Reivindicatória",
    "10006": "Ação de Usucapião",
    "10007": "Ação de Reintegração de Posse",
}


class DatajudImobConnector(SubradarImobSource):
    """Ações judiciais reais sobre imóvel via Datajud/CNJ."""

    fonte = "datajud_acoes_imovel"
    base_url = "https://api-publica.datajud.cnj.jus.br"
    request_delay = 1.0

    def consultar_imovel(
        self, matricula: str, cartorio_id: str | None = None,
        proprietario_cpf_cnpj: str | None = None
    ) -> dict | None:
        """
        Busca ações judiciais sobre imóvel.

        Datajud busca por parte (pessoa/CNPJ), não por matrícula.
        Solução: recebe CPF/CNPJ do proprietário como parâmetro.

        Args:
          matricula: matrícula do imóvel (para logging)
          cartorio_id: ID do cartório (não usado)
          proprietario_cpf_cnpj: CPF/CNPJ do proprietário (REQUERIDO para buscar)
        """
        self.log.info(
            "datajud: buscando ações judiciais para matrícula: %s", matricula
        )

        if not proprietario_cpf_cnpj:
            self.log.debug(
                "datajud: proprietário não fornecido. Não é possível consultar Datajud."
            )
            return None

        return self._buscar_acoes_por_proprietario(proprietario_cpf_cnpj, matricula)

    def _buscar_acoes_por_proprietario(
        self, proprietario_cpf_cnpj: str, matricula: str
    ) -> dict | None:
        """Busca ações judiciais em nome do proprietário."""
        try:
            data_inicio = (datetime.now() - timedelta(days=5 * 365)).strftime(
                "%Y-%m-%d"
            )
            data_fim = datetime.now().strftime("%Y-%m-%d")

            acoes_encontradas = []

            for codigo_acao, nome_acao in TIPOS_ACAO_IMOVEL.items():
                try:
                    endpoint = f"{self.base_url}/consultas"
                    params = {
                        "dataInicio": data_inicio,
                        "dataFim": data_fim,
                        "parteNome": quote(proprietario_cpf_cnpj),
                        "classeJudicial": codigo_acao,
                    }

                    resp = self._fazer_request(
                        "GET",
                        endpoint,
                        params=params,
                        timeout=15,
                    )
                    if not resp:
                        self.log.debug("datajud: sem resposta para %s", nome_acao)
                        continue

                    dados = resp.get("hits", {}).get("hits", [])
                    if not dados:
                        self.log.debug(
                            "datajud: nenhuma ação %s encontrada", nome_acao
                        )
                        continue

                    for item in dados:
                        source = item.get("_source", {})
                        acao = {
                            "tipo": nome_acao,
                            "classe": codigo_acao,
                            "tribunal": source.get("tribunal", ""),
                            "numero_processo": source.get("numeroProcesso", ""),
                            "data_distribuicao": source.get("dataDistribuicao", ""),
                            "status": source.get("status", ""),
                        }
                        acoes_encontradas.append(acao)
                        self.log.info(
                            "datajud: encontrada ação %s (%s)",
                            nome_acao,
                            source.get("numeroProcesso", "?")
                        )

                except Exception as e:
                    self.log.warning(
                        "datajud: erro ao buscar ação %s: %s", nome_acao, e
                    )
                    continue

            if not acoes_encontradas:
                self.log.info("datajud: nenhuma ação judicial encontrada para %s", proprietario_cpf_cnpj)
                return {
                    "fonte": self.fonte,
                    "categoria": "judicial",
                    "status": "limpo",
                    "titulo_secao": "Ações Judiciais",
                    "resumo": "Nenhuma ação judicial encontrada relacionada ao imóvel.",
                    "detalhes": {
                        "proprietario_consultado": proprietario_cpf_cnpj,
                        "periodo": f"5 anos até {datetime.now().strftime('%Y-%m-%d')}",
                    }
                }

            return {
                "fonte": self.fonte,
                "categoria": "judicial",
                "status": "critico" if len(acoes_encontradas) > 0 else "alerta",
                "titulo_secao": f"Ações Judiciais ({len(acoes_encontradas)})",
                "resumo": f"{len(acoes_encontradas)} ação(ões) judicial(is) encontrada(s) contra o proprietário.",
                "detalhes": {
                    "proprietario": proprietario_cpf_cnpj,
                    "acoes": acoes_encontradas,
                    "total": len(acoes_encontradas),
                }
            }

        except Exception as e:
            self.log.exception("datajud: erro geral: %s", e)
            return None
