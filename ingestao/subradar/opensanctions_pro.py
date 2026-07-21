"""
Conector: OpenSanctions Pro — cobertura expandida de sanções internacionais

API: https://api.opensanctions.org/
Plano: SaaS Pro (~USD 300/mês) — 400+ listas, busca em tempo real por CNPJ/nome,
       datasets Premium incluindo mídia adversa, PEPs globais, Offshore Leaks,
       sanções regionais (SECO/Suíça, DFAT/Austrália, OFAC secundário, etc.)

Diferencial vs. conector gratuito:
  - Cobre 400+ listas vs. ~100 no plano gratuito
  - Inclui PEPs globais (não só BR)
  - Mídia adversa estruturada
  - Offshore Leaks / ICIJ integrado
  - SLA e suporte comercial

Variável de ambiente: OPENSANCTIONS_PRO_KEY
  Obter em: https://www.opensanctions.org/api/

Produto Subradar: "Global Compliance" — plano premium
"""
from __future__ import annotations

import logging
import os
import re

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.opensanctions_pro")

OS_BASE = "https://api.opensanctions.org"
OS_PRO_KEY = os.environ.get("OPENSANCTIONS_PRO_KEY", "")

# Datasets Premium — cobertura expandida vs. plano gratuito
DATASETS_PRO = [
    # Sanções financeiras principais
    "us_ofac_sdn",
    "us_ofac_cons",          # OFAC Consolidated (não-SDN)
    "eu_sanctions",
    "un_sc_sanctions",
    "gb_hmt_sanctions",
    # Sanções adicionais
    "ch_seco_sanctions",     # Suíça SECO
    "au_dfat_sanctions",     # Austrália DFAT
    "ca_sema_sanctions",     # Canadá SEMA
    "jp_mof_sanctions",      # Japão MOF
    # Procurados / aplicação da lei
    "interpol_red_notices",
    "us_fbi_most_wanted",
    # PEPs globais
    "every_politician",      # Parlamentos globais
    "us_senate_lda",         # Lobby EUA
    # Offshore / vazamentos
    "icij_offshoreleaks",    # Panama Papers, Pandora Papers, etc.
    # Brasil
    "br_tcu_inabilitados",
    "br_ceis",
    "br_cnep",
]

DATASET_LABELS = {
    "us_ofac_sdn":          "OFAC SDN (EUA)",
    "us_ofac_cons":         "OFAC Consolidado (EUA)",
    "eu_sanctions":         "Sanções UE",
    "un_sc_sanctions":      "Sanções ONU",
    "gb_hmt_sanctions":     "Sanções Reino Unido",
    "ch_seco_sanctions":    "Sanções Suíça (SECO)",
    "au_dfat_sanctions":    "Sanções Austrália (DFAT)",
    "ca_sema_sanctions":    "Sanções Canadá (SEMA)",
    "jp_mof_sanctions":     "Sanções Japão (MOF)",
    "interpol_red_notices": "INTERPOL Red Notices",
    "us_fbi_most_wanted":   "FBI Most Wanted",
    "every_politician":     "PEP Global",
    "us_senate_lda":        "Lobby EUA (Senado)",
    "icij_offshoreleaks":   "Offshore Leaks (ICIJ)",
    "br_tcu_inabilitados":  "TCU Inabilitados",
    "br_ceis":              "CEIS/BR",
    "br_cnep":              "CNEP/BR",
}

# Datasets que sempre geram severidade crítica
_CRITICO_DATASETS = {
    "us_ofac_sdn", "us_ofac_cons", "eu_sanctions", "un_sc_sanctions",
    "gb_hmt_sanctions", "ch_seco_sanctions", "au_dfat_sanctions",
    "ca_sema_sanctions", "interpol_red_notices", "us_fbi_most_wanted",
}

# Datasets que geram atenção (PEPs, offshore — risco reputacional, não sanção direta)
_ATENCAO_DATASETS = {
    "every_politician", "us_senate_lda", "icij_offshoreleaks",
}


def _strip_cnpj(cnpj: str) -> str:
    return re.sub(r"\D", "", cnpj)


def _fmt_cnpj(cnpj: str) -> str:
    c = _strip_cnpj(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _severidade(datasets_hit: list[str]) -> str:
    if any(d in _CRITICO_DATASETS for d in datasets_hit):
        return "critico"
    if any(d in _ATENCAO_DATASETS for d in datasets_hit):
        return "atencao"
    return "info"


class OpenSanctionsProConnector(SubradarSource):
    fonte = "opensanctions_pro"
    request_delay = 0.5

    def _headers(self) -> dict:
        return {
            "Accept": "application/json",
            "Authorization": f"ApiKey {OS_PRO_KEY}",
        }

    def _search(self, query: str, schema: str = "Company") -> list[dict]:
        try:
            r = self._session.get(
                f"{OS_BASE}/search/default",
                params={"q": query, "schema": schema, "limit": 10},
                headers=self._headers(),
                timeout=self.timeout,
            )
            r.raise_for_status()
            return r.json().get("results", [])
        except Exception as e:
            logger.warning("OpenSanctions Pro search '%s' falhou: %s", query, e)
            return []

    def consultar_cnpj(self, cnpj: str) -> list[dict]:
        if not OS_PRO_KEY:
            logger.info("OpenSanctions Pro: OPENSANCTIONS_PRO_KEY não configurada — fonte indisponível")
            return []

        cnpj_digits = _strip_cnpj(cnpj)
        cnpj_fmt = _fmt_cnpj(cnpj_digits)
        ciclo = _ciclo_atual()

        resultados = self._search(cnpj_digits, schema="Company")
        if not resultados:
            return []

        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, resultados)
        if not mudou:
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt,
            "fonte": self.fonte,
            "ciclo": ciclo,
            "hash_dados": hash_novo,
            "dados": {"total": len(resultados)},
        }])

        alertas = []
        for entidade in resultados:
            datasets = entidade.get("datasets", [])
            properties = entidade.get("properties", {})
            nome = (properties.get("name") or [entidade.get("caption", "")])[0]

            hits = [d for d in datasets if d in DATASETS_PRO]
            if not hits:
                continue

            lista_labels = ", ".join(DATASET_LABELS.get(d, d) for d in hits)
            sev = _severidade(hits)

            alertas.append({
                "cnpj": cnpj_fmt,
                "ciclo": ciclo,
                "fonte": self.fonte,
                "categoria": "internacional",
                "severidade": sev,
                "titulo": f"Sanção/Restrição Internacional — {lista_labels}",
                "descricao": (
                    f"Entidade '{nome}' identificada em: {lista_labels}. "
                    f"Cobertura via OpenSanctions Pro (400+ listas globais)."
                ),
                "referencia_id": entidade.get("id"),
                "url_fonte": f"https://www.opensanctions.org/entities/{entidade.get('id')}/",
                "is_novo": True,
            })

        logger.info("OpenSanctions Pro: %d alertas para %s", len(alertas), cnpj_fmt)
        return alertas


class OpenSanctionsProPFConnector(SubradarSource):
    """
    OpenSanctions Pro para Pessoa Física — busca por nome com schema Person.
    Cobre PEPs globais, INTERPOL, FBI, OFAC, sanções internacionais e Offshore Leaks.
    Gracioso se OPENSANCTIONS_PRO_KEY ausente.
    """
    fonte = "opensanctions_pro_pf"
    request_delay = 0.5

    def _headers(self) -> dict:
        return {
            "Accept": "application/json",
            "Authorization": f"ApiKey {OS_PRO_KEY}",
        }

    def consultar_cnpj(self, cnpj_or_cpf: str, razao_social: str | None = None, **_) -> list[dict]:
        if not OS_PRO_KEY:
            logger.debug("opensanctions_pro_pf: OPENSANCTIONS_PRO_KEY ausente — pulando")
            return []

        nome = razao_social or ""
        if not nome:
            return []

        try:
            r = self._session.get(
                f"{OS_BASE}/search/default",
                params={"q": nome, "schema": "Person", "limit": 10},
                headers=self._headers(),
                timeout=self.timeout,
            )
            r.raise_for_status()
            resultados = r.json().get("results", [])
        except Exception as e:
            logger.warning("opensanctions_pro_pf: busca '%s' falhou: %s", nome, e)
            return []

        alertas = []
        for entidade in resultados:
            datasets = entidade.get("datasets", [])
            properties = entidade.get("properties", {})
            nome_entidade = (properties.get("name") or [entidade.get("caption", nome)])[0]

            hits = [d for d in datasets if d in DATASETS_PRO]
            if not hits:
                continue

            lista_labels = ", ".join(DATASET_LABELS.get(d, d) for d in hits)
            sev = _severidade(hits)

            alertas.append({
                "fonte": self.fonte,
                "categoria": "internacional",
                "severidade": sev,
                "titulo": f"OpenSanctions — {lista_labels}: {nome_entidade}",
                "descricao": (
                    f"Pessoa '{nome_entidade}' identificada em: {lista_labels}. "
                    f"Cobertura via OpenSanctions Pro (400+ listas, PEPs globais, INTERPOL)."
                ),
                "referencia_id": entidade.get("id"),
                "url_fonte": f"https://www.opensanctions.org/entities/{entidade.get('id')}/",
                "is_novo": True,
            })

        if alertas:
            logger.info("opensanctions_pro_pf: %d alerta(s) para '%s'", len(alertas), nome)
        return alertas
