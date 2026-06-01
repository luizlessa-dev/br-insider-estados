"""
ALES — Assembleia Legislativa do Estado do Espírito Santo
Site ASP.NET (al.es.gov.br). Cobertura de atividade legislativa nos dados
abertos é PARCIAL — só deputados de forma limpa.

Verificado live 2026-05-31:
  Deputados   : GET https://www.al.es.gov.br/DadosAbertos/ParlamentaresData
                → JSON [{nmPolitico, tx_partido_sigla, dsEmailDeputado,
                  dsTelefoneDeputado}] (~30). Limpo. Sem id estável → slug do nome.
  Proposições : só via busca ASP.NET WebForms em /Proposicao (__VIEWSTATE/
                __EVENTVALIDATION + postback paginado). NÃO há dataset/JSON.
                DEFERIDO (scraping de postback é frágil e custoso).
  Votações    : NÃO publicadas em dados abertos (sem dataset, sem página).
                api.al.es.gov.br é um nginx default vazio. → vazio.

Decisão (com Luiz): implementar só deputados agora; proposições/votações ficam
como débito documentado.
"""
from __future__ import annotations

import re
import unicodedata
from datetime import date

from ..base_connector import BaseConnector
from ..models import Deputado, Proposicao, Votacao


PARLAMENTARES_URL = "https://www.al.es.gov.br/DadosAbertos/ParlamentaresData"


def _slug(t: str) -> str:
    s = unicodedata.normalize("NFD", (t or "").lower()).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]+", "-", s).strip("-")


class ALESConnector(BaseConnector):
    assembly_id = "ales"
    assembly_name = "Assembleia Legislativa do Espírito Santo"
    uf = "ES"
    base_url = "https://www.al.es.gov.br"

    request_delay = 0.5

    # ── Deputados (JSON limpo) ────────────────────────────────────────────
    def get_deputados(self) -> list[Deputado]:
        data = self._get(PARLAMENTARES_URL)
        itens = data if isinstance(data, list) else data.get("data", [])
        deputados: list[Deputado] = []
        for d in itens:
            nome = (d.get("nmPolitico") or "").strip()
            if not nome:
                continue
            deputados.append(Deputado(
                id=self._prefix_id(_slug(nome)),   # API não traz id estável
                nome=nome,
                partido=(d.get("tx_partido_sigla") or "").strip(),
                uf="ES",
                assembly_id=self.assembly_id,
                email=(d.get("dsEmailDeputado") or "").strip() or None,
                telefone=(d.get("dsTelefoneDeputado") or "").strip() or None,
                raw=d,
            ))
        self.logger.info("ALES: %d deputados carregados", len(deputados))
        return deputados

    # ── Proposições: WebForms postback (deferido) ─────────────────────────
    def get_proposicoes(self, data_inicio: date, data_fim: date) -> list[Proposicao]:
        self.logger.info(
            "ALES: proposições só via busca WebForms (/Proposicao, postback) — deferido. Vazio."
        )
        return []

    # ── Votações: não publicadas ──────────────────────────────────────────
    def get_votacoes(self, data_inicio: date, data_fim: date) -> list[Votacao]:
        self.logger.info("ALES: votações não disponíveis em dados abertos — vazio.")
        return []

    def health_check(self) -> bool:
        try:
            return self.session.get(PARLAMENTARES_URL, timeout=15).status_code < 400
        except Exception:
            return False
