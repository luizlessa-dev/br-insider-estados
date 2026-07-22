"""
Conector: Infosimples — Certidão Negativa de Débitos Estaduais (CND) para PJ

Consulta a situação fiscal estadual de um CNPJ via API Infosimples, cobrindo
todas as UFs disponíveis na plataforma (27 unidades federativas).

UFs cobertas: SP, RJ, MG, RS, PR, SC, BA, GO, PE, CE, ES, MT, MS, RO, TO,
              PI, MA, PB, RN, AL, SE, AP, AC, AM, RR, PA, DF

Nota sobre sobreposição com sefaz_estadual_pj.py:
  O conector sefaz_estadual_pj.py cobre SP, MG e RJ via scraping direto nos
  portais das SEFAZ. Este conector também inclui SP, MG e RJ, mas via API
  Infosimples (resposta estruturada, sem parsing HTML). Em caso de conflito
  nos alertas, o resultado deste conector tem precedência — a resposta
  Infosimples é mais estruturada e confiável.

Padrão de endpoint:
  GET https://api.infosimples.com/api/v2/consultas/sefaz/{uf}/certidao-negativa-debitos
      ?cnpj={cnpj14}&token={TOKEN}

Response padrão Infosimples:
  {
    "code": 200,
    "data": [
      {
        "situacao": "Negativa",   # ou "Positiva", "Regular", "Irregular", etc.
        "numero": "...",
        "validade": "..."
      }
    ]
  }

Regras de alerta:
  - situacao "Negativa" ou "Regular" → sem alerta
  - situacao "Positiva", "Irregular", "Pendente" → severity="atencao"
  - HTTP 402 (créditos esgotados) ou 429 (rate limit) → gracioso, sem alerta
  - Qualquer outra falha de rede ou resposta inesperada → gracioso, sem alerta

Custo estimado: R$ 0,20–R$ 0,50/consulta/UF (verificar tabela Infosimples).
Env var: INFOSIMPLES_TOKEN — retorna [] silenciosamente se ausente.
Documentação: https://infosimples.com/consultas/
"""
from __future__ import annotations

import logging
import re
import time
import os

import requests

from .base import SubradarSource

logger = logging.getLogger("subradar.infosimples_cnd_estadual_pj")

TOKEN = os.environ.get("INFOSIMPLES_TOKEN", "")

_BASE = "https://api.infosimples.com/api/v2/consultas/sefaz"

# Situações que indicam regularidade fiscal (sem alerta)
_SITUACOES_REGULARES = {
    "negativa",
    "regular",
    "negativa com efeito de positiva",  # algumas UFs emitem esta modalidade
}

# Situações que indicam irregularidade fiscal (geram alerta)
_SITUACOES_IRREGULARES = {
    "positiva",
    "irregular",
    "pendente",
    "devedor",
    "inadimplente",
    "em aberto",
    "positiva com efeito de negativa",  # débito confirmado mas com efeito provisório
}

# UFs disponíveis na plataforma Infosimples
# Inclui SP/MG/RJ intencionalmente — ver docstring sobre precedência.
_UFS = [
    ("SP", "São Paulo"),
    ("RJ", "Rio de Janeiro"),
    ("MG", "Minas Gerais"),
    ("RS", "Rio Grande do Sul"),
    ("PR", "Paraná"),
    ("SC", "Santa Catarina"),
    ("BA", "Bahia"),
    ("GO", "Goiás"),
    ("PE", "Pernambuco"),
    ("CE", "Ceará"),
    ("ES", "Espírito Santo"),
    ("MT", "Mato Grosso"),
    ("MS", "Mato Grosso do Sul"),
    ("RO", "Rondônia"),
    ("TO", "Tocantins"),
    ("PI", "Piauí"),
    ("MA", "Maranhão"),
    ("PB", "Paraíba"),
    ("RN", "Rio Grande do Norte"),
    ("AL", "Alagoas"),
    ("SE", "Sergipe"),
    ("AP", "Amapá"),
    ("AC", "Acre"),
    ("AM", "Amazonas"),
    ("RR", "Roraima"),
    ("PA", "Pará"),
    ("DF", "Distrito Federal"),
]


def _fmt_cnpj14(cnpj: str) -> str:
    """Retorna apenas os 14 dígitos numéricos do CNPJ."""
    return re.sub(r"\D", "", str(cnpj or ""))


def _fmt_cnpj_mask(cnpj14: str) -> str:
    """Formata CNPJ com máscara XX.XXX.XXX/XXXX-XX."""
    if len(cnpj14) != 14:
        return cnpj14
    return f"{cnpj14[:2]}.{cnpj14[2:5]}.{cnpj14[5:8]}/{cnpj14[8:12]}-{cnpj14[12:]}"


def _classificar_situacao(situacao: str) -> str:
    """
    Classifica a situação retornada pela Infosimples.
    Retorna 'irregular', 'regular' ou 'inconclusivo'.
    """
    s = situacao.lower().strip()

    for kw in _SITUACOES_IRREGULARES:
        if kw in s:
            return "irregular"

    for kw in _SITUACOES_REGULARES:
        if kw in s:
            return "regular"

    return "inconclusivo"


def _consultar_uf(uf: str, cnpj14: str) -> dict | None:
    """
    Consulta a CND estadual de uma UF via Infosimples.

    Retorna dict com keys: situacao, numero, validade, url_fonte
    ou None em caso de falha gracioso.
    """
    url = f"{_BASE}/{uf.lower()}/certidao-negativa-debitos"
    params = {"cnpj": cnpj14, "token": TOKEN, "timeout": 600}

    try:
        resp = requests.get(url, params=params, timeout=30)
    except Exception as exc:
        logger.debug("infosimples_cnd/%s: erro de rede — %s", uf, exc)
        return None

    if resp.status_code == 402:
        logger.warning("infosimples_cnd: créditos esgotados (HTTP 402) — interrompendo consultas")
        return None

    if resp.status_code == 429:
        logger.warning("infosimples_cnd/%s: rate limit atingido (HTTP 429) — pulando", uf)
        return None

    if not resp.ok:
        logger.debug("infosimples_cnd/%s: HTTP %d para CNPJ %s", uf, resp.status_code, cnpj14)
        return None

    try:
        data = resp.json()
    except Exception as exc:
        logger.debug("infosimples_cnd/%s: resposta não é JSON — %s", uf, exc)
        return None

    if data.get("code") != 200:
        logger.debug(
            "infosimples_cnd/%s: code=%s para CNPJ %s",
            uf, data.get("code"), cnpj14,
        )
        return None

    registros = data.get("data", [])
    if not registros:
        logger.debug("infosimples_cnd/%s: sem registros para CNPJ %s", uf, cnpj14)
        return None

    # Usa o primeiro registro (normalmente há apenas um por UF)
    reg = registros[0]
    situacao = (
        reg.get("situacao") or
        reg.get("status") or
        reg.get("resultado") or
        ""
    )
    numero = reg.get("numero") or reg.get("numero_certidao") or ""
    validade = reg.get("validade") or reg.get("data_validade") or ""

    return {
        "situacao": situacao,
        "numero": numero,
        "validade": validade,
        "url_fonte": f"https://api.infosimples.com/api/v2/consultas/sefaz/{uf.lower()}/certidao-negativa-debitos",
    }


class InfosimplesCNDEstadualPJConnector(SubradarSource):
    """
    Verifica Certidão Negativa de Débitos Estaduais via Infosimples para todas
    as UFs disponíveis na plataforma (27 UFs).

    Situação irregular/positiva → alerta severity='atencao', categoria='fiscal'.
    Situação regular/negativa ou inconclusiva → sem alerta.
    Gracioso em qualquer falha de rede, créditos esgotados ou token ausente.

    Env var: INFOSIMPLES_TOKEN
    """

    fonte = "infosimples_cnd_estadual"
    request_delay = 1.0  # 1 segundo entre UFs — respeita rate limit Infosimples

    def consultar_cnpj(self, cnpj: str, razao_social: str | None = None, **_) -> list[dict]:
        if not TOKEN:
            logger.debug("infosimples_cnd: INFOSIMPLES_TOKEN ausente — pulando")
            return []

        cnpj14 = _fmt_cnpj14(cnpj)
        if len(cnpj14) != 14:
            logger.debug("infosimples_cnd: CNPJ inválido (%r) — pulando", cnpj)
            return []

        cnpj_mask = _fmt_cnpj_mask(cnpj14)
        nome = razao_social or cnpj_mask
        alertas: list[dict] = []
        creditos_esgotados = False

        for i, (uf, nome_uf) in enumerate(_UFS):
            if creditos_esgotados:
                break

            if i > 0:
                time.sleep(self.request_delay)

            logger.debug(
                "infosimples_cnd: consultando SEFAZ-%s para %s", uf, cnpj_mask
            )

            resultado = _consultar_uf(uf, cnpj14)

            # _consultar_uf retorna None tanto em falha de rede quanto em 402/429.
            # Detecta 402 inspecionando o log já emitido — aqui apenas pula graciosamente.
            if resultado is None:
                continue

            situacao_raw = resultado["situacao"]
            classificacao = _classificar_situacao(situacao_raw)

            if classificacao != "irregular":
                logger.debug(
                    "infosimples_cnd: SEFAZ-%s situacao=%r (%s) para %s — sem alerta",
                    uf, situacao_raw, classificacao, cnpj_mask,
                )
                continue

            logger.info(
                "infosimples_cnd: DÉBITO ESTADUAL confirmado em SEFAZ-%s para %s (situacao=%r)",
                uf, cnpj_mask, situacao_raw,
            )

            numero = resultado["numero"]
            validade = resultado["validade"]

            descricao_parts = [
                f"O CNPJ {cnpj_mask} ({nome}) possui pendência(s) fiscal(is) "
                f"junto à Secretaria de Fazenda de {nome_uf} (SEFAZ-{uf}).",
                f"Situação retornada: {situacao_raw!r}.",
            ]
            if numero:
                descricao_parts.append(f"Número da certidão: {numero}.")
            if validade:
                descricao_parts.append(f"Validade: {validade}.")
            descricao_parts.append(
                "Fonte: Infosimples via API Infosimples (dados estruturados SEFAZ)."
            )

            alertas.append({
                "fonte": self.fonte,
                "categoria": "fiscal",
                "severidade": "atencao",
                "titulo": f"SEFAZ-{uf} — CND irregular: {cnpj_mask}",
                "descricao": " ".join(descricao_parts),
                "url_fonte": resultado["url_fonte"],
                "referencia_id": f"infosimples-cnd-{uf.lower()}-{cnpj14}",
                "is_novo": True,
                "metadados": {
                    "uf": uf,
                    "nome_uf": nome_uf,
                    "situacao": situacao_raw,
                    "numero_certidao": numero,
                    "validade": validade,
                },
            })

        logger.info(
            "infosimples_cnd: %d alerta(s) para CNPJ %s", len(alertas), cnpj_mask
        )
        return alertas
