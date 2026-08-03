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
        self, matricula: str, cartorio_id: str | None = None
    ) -> dict | None:
        """
        Busca ações judiciais sobre imóvel.

        Limitação atual:
          Datajud busca por parte (pessoa/CNPJ), não por matrícula.
          Para funcionar, precisamos do proprietário do imóvel.

        Solução:
          1. Integrar com ONR (Ofício de Notas de Registro) para extrair proprietário
          2. Buscar ações em nome do proprietário no Datajud
          3. Filtrar apenas ações reais imobiliárias

        Por enquanto: retorna None até ter integração ONR.
        """
        self.log.info(
            "datajud: buscando ações judiciais para matrícula: %s", matricula
        )

        # TODO: quando ONR estiver integrada
        # proprietario = self._buscar_proprietario_onr(matricula)
        # if proprietario:
        #     return self._buscar_acoes_por_proprietario(proprietario)

        return None

    def _buscar_proprietario_onr(self, matricula: str) -> str | None:
        """
        Extrai proprietário via ONR Digital.

        TODO: Implementar integração com ONR.
        Quando disponível, fará:
          1. GET https://onr.gov.br/api/matricula/{matricula}
          2. Extrai nome/CNPJ do proprietário
          3. Retorna (nome, tipo: PF/PJ)
        """
        pass

    def _buscar_acoes_por_proprietario(
        self, proprietario: str, tipo_pf_pj: str = "PESSOA_FISICA"
    ) -> dict | None:
        """
        Busca ações judiciais em nome do proprietário.

        Args:
          proprietario: Nome ou CNPJ
          tipo_pf_pj: PESSOA_FISICA | PESSOA_JURIDICA
        """
        try:
            # Parâmetros da busca
            # dataInicio: últimos 5 anos
            data_inicio = (datetime.now() - timedelta(days=5 * 365)).strftime(
                "%Y-%m-%d"
            )
            data_fim = datetime.now().strftime("%Y-%m-%d")

            acoes_encontradas = []

            # Buscar para cada tipo de ação imobiliária
            for codigo_acao, nome_acao in TIPOS_ACAO_IMOVEL.items():
                try:
                    endpoint = f"{self.base_url}/consultas"
                    params = {
                        "dataInicio": data_inicio,
                        "dataFim": data_fim,
                        "parteNome": quote(proprietario),
                        "classeJudicial": codigo_acao,
                    }

                    resp = self._fazer_request(
                        "GET",
                        endpoint,
                        params=params,
                        timeout=15,
                    )
                    if not resp:
                        continue

                    dados = resp.get("hits", {}).get("hits", [])
                    if not dados:
                        self.log.debug(
                            "datajud: nenhuma ação %s encontrada", nome_acao
                        )
                        continue

                    # Processar ações encontradas
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

                except Exception as e:
                    self.log.warning(
                        "datajud: erro ao buscar ação %s: %s", nome_acao, e
                    )
                    continue

            if not acoes_encontradas:
                self.log.info("datajud: nenhuma ação judicialmente encontrada")
                return None

            return {
                "fonte": self.fonte,
                "categoria": "judicial",
                "status": "alerta" if acoes_encontradas else "limpo",
                "titulo_secao": "Ações Judiciais sobre o Imóvel",
                "resumo": f"{len(acoes_encontradas)} ação(ões) judicial(is) encontrada(s)",
                "detalhes": {
                    "total": len(acoes_encontradas),
                    "proprietario": proprietario,
                    "acoes": acoes_encontradas,
                    "periodo_busca": f"{data_inicio} a {data_fim}",
                    "atualizado_em": datetime.utcnow().isoformat(),
                },
            }

        except Exception as e:
            self.log.exception("datajud: erro geral: %s", e)
            return None
