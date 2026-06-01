"""
ALERJ — Assembleia Legislativa do Estado do Rio de Janeiro
Tier 3. Site ASP.NET MVC (www.alerj.rj.gov.br). Cobertura de atividade nos
canais públicos é limitada a deputados.

Verificado live 2026-06-01:
  Deputados   : GET /Deputados/QuemSao — cards server-rendered, 70 deputados.
                Cada card: div.partido, div.nome, link
                /Deputados/PerfilDeputado/{id}?Legislatura=20 (img alt=nome).
  Proposições : NÃO há enumeração estruturada. A única busca pública é
                /ResultadoPesquisa/Consultar com `termoPesquisa` (texto livre,
                busca genérica do site) — não permite listar por data/ano/tipo.
                O sistema legislativo estruturado (www3.alerj.rj.gov.br, Lotus
                Notes) responde 403. → deferido.
  Votações    : não publicadas em canal acessível. → vazio.

Decisão: implementar só deputados; proposições/votações ficam como débito
documentado (sem fonte ingerível encontrada).
"""
from __future__ import annotations

import re
from datetime import date

from bs4 import BeautifulSoup

from ..base_connector import BaseConnector
from ..models import Deputado, Proposicao, Votacao


QUEMSAO_URL = "https://www.alerj.rj.gov.br/Deputados/QuemSao"
BASE = "https://www.alerj.rj.gov.br"


class ALERJConnector(BaseConnector):
    assembly_id = "alerj"
    assembly_name = "Assembleia Legislativa do Estado do Rio de Janeiro"
    uf = "RJ"
    base_url = "https://www.alerj.rj.gov.br"

    request_delay = 0.6
    timeout = 45

    # ── Deputados (QuemSao) ───────────────────────────────────────────────
    def get_deputados(self) -> list[Deputado]:
        html = self._get_text(QUEMSAO_URL, headers={"Accept": "text/html,*/*"})
        soup = BeautifulSoup(html, "html.parser")
        deputados: list[Deputado] = []
        vistos: set[str] = set()
        for desc in soup.select(".descricao"):
            nome_el = desc.select_one(".nome")
            if not nome_el:
                continue
            nome = nome_el.get_text(strip=True)
            partido_el = desc.select_one(".partido")
            # o card (pai da .descricao) também contém a .imagem com o link/foto
            card = desc.parent
            link = card.select_one('a[href*="/Deputados/PerfilDeputado/"]') if card else None
            img = card.find("img") if card else None
            raw_id = None
            if link:
                m = re.search(r"/PerfilDeputado/(\d+)", link.get("href", ""))
                raw_id = m.group(1) if m else None
            if not raw_id:
                raw_id = re.sub(r"[^a-z0-9]+", "-", nome.lower()).strip("-")
            if not nome or raw_id in vistos:
                continue
            vistos.add(raw_id)
            deputados.append(Deputado(
                id=self._prefix_id(raw_id),
                nome=nome.title() if nome.isupper() else nome,
                partido=(partido_el.get_text(strip=True) if partido_el else ""),
                uf="RJ",
                assembly_id=self.assembly_id,
                foto_url=(BASE + img.get("src")) if img and img.get("src", "").startswith("/") else (img.get("src") if img else None),
                raw={"perfil": link.get("href") if link else None},
            ))
        self.logger.info("ALERJ: %d deputados carregados", len(deputados))
        return deputados

    # ── Proposições: sem fonte estruturada (deferido) ─────────────────────
    def get_proposicoes(self, data_inicio: date, data_fim: date) -> list[Proposicao]:
        self.logger.info(
            "ALERJ: proposições só via busca por texto livre (sem enumeração por data) — deferido. Vazio."
        )
        return []

    # ── Votações: não publicadas ──────────────────────────────────────────
    def get_votacoes(self, data_inicio: date, data_fim: date) -> list[Votacao]:
        self.logger.info("ALERJ: votações não disponíveis em canal acessível — vazio.")
        return []

    def health_check(self) -> bool:
        try:
            return self.session.get(QUEMSAO_URL, timeout=15).status_code < 400
        except Exception:
            return False
