"""
Conector: Grafo de Sócios — mapeamento de vínculos societários por CNPJ

Constrói um grafo de 2 níveis a partir do QSA RFB:
  Nível 1 — sócios diretos do CNPJ consultado
  Nível 2 — empresas onde cada sócio PF também participa (participações cruzadas)

Usado para detectar:
  - Sócios em comum com empresas sancionadas ou irregulares
  - Concentração societária (controlador oculto)
  - Participação em concorrentes do mesmo setor (conflito de interesse)
  - Sócio pessoa jurídica com sede em paraíso fiscal

Retorna alertas informativos sobre o grafo, não risco direto.
Sinaliza com severity="atencao" apenas quando sócio PJ tem CNPJ com situação
cadastral irregular ou sócio PF aparece em mais de N empresas simultaneamente.

Env vars: nenhuma (usa Supabase local — tabelas cnpj_socios e cnpj_empresas).
"""
from __future__ import annotations

import logging
import re

import requests

from .base import SubradarSource, SUPABASE_URL, SUPABASE_KEY, _supabase_headers, FonteIndisponivel

logger = logging.getLogger("subradar.grafo_socios_pj")

_MAX_SOCIOS = 10
_MAX_PARTICIPACOES_ALERTA = 5   # sócio em mais de N empresas → info
# _PAISES_RISCO foi removido: dependia de cnpj_socios.pais_socio, coluna que
# nao existe. Reintroduzir so junto com uma fonte que traga a jurisdicao.


def _strip(doc: str) -> str:
    return re.sub(r"\D", "", str(doc or ""))


def _supabase_get(table: str, params: dict) -> list[dict]:
    if not SUPABASE_URL or not SUPABASE_KEY:
        return []
    try:
        r = requests.get(
            f"{SUPABASE_URL}/rest/v1/{table}",
            params=params,
            headers=_supabase_headers(),
            timeout=15,
        )
        data = r.json() if r.ok else []
        return data if isinstance(data, list) else []
    except Exception as e:
        logger.debug("supabase %s: %s", table, e)
        return []


def _get_socios(cnpj_digits: str) -> list[dict]:
    cnpj_basico = cnpj_digits[:8]
    rows = _supabase_get("cnpj_socios", {
        "cnpj_basico": f"eq.{cnpj_basico}",
        # cnpj_socios tem "qualificacao", nao "qualificacao_socio", e nao tem
        # coluna de pais nenhuma — o select antigo respondia 400 e o 400 virava
        # lista vazia, ou seja, "nenhum vinculo de risco" em todo dossie.
        # Socio estrangeiro sai de "identificador" (layout RFB: 3 = estrangeiro).
        "select": "nome_socio,cpf_cnpj_socio,qualificacao,identificador",
        "limit": _MAX_SOCIOS,
    })
    return rows


def _situacao_empresa(cnpj_basico: str) -> str:
    # cnpj_empresas nao tem situacao_cadastral (so razao_social, natureza,
    # capital e porte). A situacao vive em cnpj_enriquecido, chaveada pelo CNPJ
    # completo. String vazia aqui significa "nao sei", e quem chama trata assim.
    rows = _supabase_get("cnpj_enriquecido", {
        "cnpj": f"like.{cnpj_basico}%",
        "select": "situacao_cadastral",
        "limit": 1,
    })
    if rows:
        return str(rows[0].get("situacao_cadastral") or "").lower()
    return ""


def _participacoes_socio(cpf_cnpj: str) -> list[dict]:
    """Outras empresas onde este CPF/CNPJ aparece como sócio."""
    doc = _strip(cpf_cnpj)
    if not doc:
        return []
    rows = _supabase_get("cnpj_socios", {
        "cpf_cnpj_socio": f"eq.{doc}",
        "select": "cnpj_basico,qualificacao",
        "limit": 50,
    })
    return rows


class GrafoSociosPJConnector(SubradarSource):
    """
    Mapeia sócios diretos do CNPJ e suas participações cruzadas.
    Sinaliza sócios em paraíso fiscal, empresas irregulares e concentração.
    Gracioso se tabelas cnpj_socios/cnpj_empresas estiverem ausentes.
    """
    fonte = "grafo_socios"
    request_delay = 0.5

    def consultar_cnpj(self, cnpj_or_cpf: str, razao_social: str | None = None, **_) -> list[dict]:
        cnpj = _strip(cnpj_or_cpf)
        if len(cnpj) != 14:
            return []

        cnpj_fmt = f"{cnpj[:2]}.{cnpj[2:5]}.{cnpj[5:8]}/{cnpj[8:12]}-{cnpj[12:14]}"
        socios = _get_socios(cnpj)

        if not socios:
            # Empresa sem nenhuma linha de QSA na base local nao e empresa sem
            # socios — e empresa que a base nao cobre. Declarar isso como
            # "nenhum vinculo de risco" era afirmar o que nao foi apurado.
            raise FonteIndisponivel(
                "QSA nao disponivel na base local (cnpj_socios) para este CNPJ"
            )

        alertas = []

        for socio in socios:
            nome = socio.get("nome_socio") or "Sócio"
            doc_socio = _strip(socio.get("cpf_cnpj_socio") or "")
            qualif = socio.get("qualificacao") or ""
            estrangeiro = str(socio.get("identificador") or "") == "3"

            # 1. Sócio estrangeiro
            # O QSA da RFB nao traz o pais do socio, so o marcador de tipo
            # (identificador 3 = estrangeiro). Da para sinalizar a presenca de
            # capital estrangeiro, nao para dizer que e paraiso fiscal — a
            # jurisdicao teria de vir de outra fonte. O alerta afirma so o que
            # o dado sustenta.
            if estrangeiro:
                alertas.append({
                    "fonte": self.fonte,
                    "categoria": "societario",
                    "severidade": "atencao",
                    "titulo": f"Grafo Sócios — sócio estrangeiro: {cnpj_fmt}",
                    "descricao": (
                        f"Sócio '{nome}' ({qualif}) está registrado no QSA da Receita "
                        "como sócio estrangeiro. A jurisdição de domicílio não consta "
                        "do QSA — verificar se há exposição a jurisdição de baixa "
                        "transparência exige consulta complementar."
                    ),
                    "url_fonte": "https://www.receita.fazenda.gov.br/",
                    "referencia_id": doc_socio or nome[:30],
                    "is_novo": True,
                })

            # 2. Sócio PJ com situação cadastral irregular
            if len(doc_socio) == 14:
                sit = _situacao_empresa(doc_socio[:8])
                if sit and sit not in ("02", "ativa", "2"):
                    sit_label = {
                        "03": "suspensa", "04": "inapta",
                        "08": "baixada", "01": "nula",
                    }.get(sit, sit)
                    alertas.append({
                        "fonte": self.fonte,
                        "categoria": "societario",
                        "severidade": "atencao",
                        "titulo": f"Grafo Sócios — sócio PJ irregular: {cnpj_fmt}",
                        "descricao": (
                            f"Sócio '{nome}' (CNPJ {doc_socio[:2]}.{doc_socio[2:5]}.{doc_socio[5:8]}"
                            f"/{doc_socio[8:12]}-{doc_socio[12:14]}) tem situação cadastral "
                            f"'{sit_label}' na Receita Federal."
                        ),
                        "url_fonte": "https://servicos.receita.fazenda.gov.br/Servicos/cnpjreva/",
                        "referencia_id": doc_socio,
                        "is_novo": True,
                    })

            # 3. Sócio PF com muitas participações (possível laranja/testa de ferro)
            if len(doc_socio) == 11:
                participacoes = _participacoes_socio(doc_socio)
                cnpjs_distintos = {p.get("cnpj_basico") for p in participacoes if p.get("cnpj_basico")}
                if len(cnpjs_distintos) > _MAX_PARTICIPACOES_ALERTA:
                    cpf_fmt = f"{doc_socio[:3]}.{doc_socio[3:6]}.{doc_socio[6:9]}-{doc_socio[9:11]}"
                    alertas.append({
                        "fonte": self.fonte,
                        "categoria": "societario",
                        "severidade": "info",
                        "titulo": f"Grafo Sócios — sócio em {len(cnpjs_distintos)} empresas: {cnpj_fmt}",
                        "descricao": (
                            f"Sócio '{nome}' (CPF {cpf_fmt}) figura como sócio em "
                            f"{len(cnpjs_distintos)} empresas distintas na base RFB. "
                            "Concentração societária elevada pode indicar uso como controlador indireto."
                        ),
                        "url_fonte": "https://www.receita.fazenda.gov.br/",
                        "referencia_id": doc_socio,
                        "is_novo": True,
                    })

        logger.info("grafo_socios: %d alerta(s) para %s (%d sócio(s))",
                    len(alertas), cnpj_fmt, len(socios))
        return alertas
