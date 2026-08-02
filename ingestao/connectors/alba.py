"""
ALBA — Assembleia Legislativa da Bahia
Tier 3 — HTML Scraping (no API available)

Base: https://www.al.ba.gov.br
Endpoints:
  - GET /deputados/deputados-estaduais → lista de deputados (HTML scraping)
  - GET /deputados/deputado-estadual/{id} → perfil deputado (individual)

Data structure: 63 deputados, parties in dropdown menu
"""
from __future__ import annotations

from datetime import date
from typing import Optional
import re

from bs4 import BeautifulSoup

from ..base_connector import BaseConnector
from ..models import Deputado, Proposicao, Votacao


class ALBAConnector(BaseConnector):
    assembly_id = "alba"
    assembly_name = "Assembleia Legislativa da Bahia"
    uf = "BA"
    base_url = "https://www.al.ba.gov.br"

    request_delay = 0.8  # Scraping: higher delay to be polite

    # ── Deputados ──────────────────────────────────────────────────
    def get_deputados(self) -> list[Deputado]:
        """
        Fetch current deputies from ALBA by scraping deputados-estaduais page.

        HTML structure:
          <div class="deputado-nome">
            <a href="/deputados/deputado-estadual/910629">ADOLFO MENEZES</a>
          </div>
          <img class="deputado-img" src="/fserver/.../AdolfoMenezes.jpg"/>

        Returns: list[Deputado] with 63 active deputies
        """
        url = f"{self.base_url}/deputados/deputados-estaduais"

        try:
            response = self._get(url, allow_redirects=True)
            soup = BeautifulSoup(response, "html.parser")
        except Exception as e:
            self.logger.error("ALBA: Failed to fetch deputados page: %s", e)
            return []

        deputados = []

        # Find all deputy name containers
        nome_divs = soup.find_all("div", class_="deputado-nome")

        for nome_div in nome_divs:
            try:
                # Extract name and ID from link
                link = nome_div.find("a", href=re.compile(r"/deputados/deputado-estadual/"))
                if not link:
                    continue

                nome = link.text.strip()
                href = link.get("href", "")

                # Extract ID from href: /deputados/deputado-estadual/910629 -> 910629
                id_match = re.search(r"/deputado-estadual/(\d+)", href)
                if not id_match:
                    continue

                dep_id = id_match.group(1)

                # Try to find associated image for photo URL
                # Note: image is in sibling container with class "deputado-img"
                foto_url = None
                img = nome_div.find_previous("img", class_="deputado-img")
                if img and img.get("src"):
                    foto_url = img.get("src", "")
                    # Make it absolute URL if relative
                    if foto_url.startswith("/"):
                        foto_url = self.base_url + foto_url

                # Partido will be scraped separately via partido filter (not available in list)
                # We'll set partido to empty for now, could enhance later

                deputado = Deputado(
                    id=self._prefix_id(dep_id),
                    nome=nome,
                    partido="",  # Not available in list view, would need detail page
                    uf=self.uf,
                    assembly_id=self.assembly_id,
                    foto_url=foto_url,
                    email=None,  # Not available in list view
                    raw={"href": href, "foto_url": foto_url},
                )
                deputados.append(deputado)

            except Exception as e:
                self.logger.warning("ALBA: Failed to parse deputy: %s", e)
                continue

        self.logger.info("ALBA: %d deputados carregados", len(deputados))
        return deputados

    # ── Proposições ──────────────────────────────────────────────────
    def get_proposicoes(self) -> list[Proposicao]:
        """
        Fetch bills/propositions from ALBA by scraping /atividade-legislativa-nova/proposicoes.

        HTML structure:
          <table class="tabela-cab...">
            <tr class="table-itens">
              <td class="mapa">
                <a href="/atividade-legislativa-nova/proposicao/REQ-10650-2025">
                  <span>REQ/10650/2025</span>
                </a>
              </td>
              <td><span class="fe-html-ativ">Ementa/descrição aqui</span></td>
            </tr>
          </table>

        Returns: list[Proposicao] with available propositions
        """
        url = f"{self.base_url}/atividade-legislativa-nova/proposicoes"

        try:
            response = self._get(url, allow_redirects=True)
            soup = BeautifulSoup(response, "html.parser")
        except Exception as e:
            self.logger.error("ALBA: Failed to fetch proposicoes page: %s", e)
            return []

        proposicoes = []

        # Find all rows in the propositions table
        table = soup.find("table", class_=re.compile(r"tabela-cab.*"))
        if not table:
            self.logger.warning("ALBA: Propositions table not found")
            return []

        rows = table.find_all("tr", class_="table-itens")

        for row in rows:
            try:
                # Extract number from first column (link)
                td_numero = row.find("td", class_="mapa")
                if not td_numero:
                    continue

                link = td_numero.find("a", href=re.compile(r"/atividade-legislativa-nova/proposicao/"))
                if not link:
                    continue

                # Extract number from span text (e.g., "REQ/10650/2025")
                span = link.find("span")
                numero = span.text.strip() if span else ""

                if not numero:
                    continue

                # Extract ementa from second column
                tds = row.find_all("td")
                ementa = ""
                if len(tds) > 1:
                    ementa_span = tds[1].find("span", class_="fe-html-ativ")
                    ementa = ementa_span.text.strip() if ementa_span else ""

                # Extract href to detail page
                href = link.get("href", "")

                # Extract year and type from numero (e.g., "REQ/10650/2025" -> type=REQ, ano=2025)
                tipo = ""
                ano = 0

                if "/" in numero:
                    parts = numero.split("/")
                    tipo = parts[0] if len(parts) > 0 else ""
                    try:
                        ano = int(parts[-1]) if len(parts) > 0 else 0
                    except ValueError:
                        ano = 0

                proposicao = Proposicao(
                    id=self._prefix_id(numero.replace("/", "_")),
                    numero=numero,
                    ano=ano,
                    tipo=tipo,
                    ementa=ementa,
                    assembly_id=self.assembly_id,
                    data_apresentacao=None,  # Not available in list view
                    situacao=None,  # Not available in list view
                    url=self.base_url + href if href.startswith("/") else href,
                    raw={"href": href, "numero": numero},
                )
                proposicoes.append(proposicao)

            except Exception as e:
                self.logger.warning("ALBA: Failed to parse proposicao: %s", e)
                continue

        self.logger.info("ALBA: %d proposicoes carregadas", len(proposicoes))
        return proposicoes

    # ── Votações ──────────────────────────────────────────────────
    def get_votacoes(self) -> list[Votacao]:
        """
        Fetch votes/plenary sessions from ALBA.

        TODO: Discover if ALBA exposes voting data.
        For now, returning empty list to avoid breaking the pipeline.
        """
        # Placeholder: ALBA voting endpoint not yet discovered
        self.logger.warning("ALBA: get_votacoes not yet implemented")
        return []

    # ── Helper methods ──────────────────────────────────────────────────
    def _get(self, url: str, **kwargs) -> str:
        """Override to ensure we get HTML text, not JSON."""
        self._throttle()
        try:
            response = self.session.get(url, timeout=self.timeout, **kwargs)
            response.raise_for_status()
            return response.text
        except Exception as e:
            self.logger.error("ALBA: GET %s failed: %s", url, e)
            raise
