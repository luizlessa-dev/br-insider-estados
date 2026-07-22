"""
Conector: CND Federal — Certidão Negativa de Débitos Federais consolidada (PJ)

Verifica a regularidade fiscal federal do CNPJ perante a Receita Federal do Brasil (RFB)
e a Procuradoria-Geral da Fazenda Nacional (PGFN) — a chamada "Certidão Conjunta".

Tipos de resultado:
  - "Negativa" (CND): sem débitos. Sem alerta.
  - "Positiva com Efeito de Negativa" (CPEN): parcelamento ou suspensão judicial.
    Tratada como regular — CPEN é prova de regularidade plena para fins legais.
  - "Positiva": débito(s) vencido(s). Gera alerta severity="atencao".

Relevante para:
  - Fornecedores com contratos públicos (exigência legal — Lei 8.666/93, art. 29)
  - Empresas licitantes e credenciadas
  - Monitoramento preventivo de entidades vinculadas a parlamentares

Estratégia de coleta:
  1. Direct Data v3 — ReceitaFederalCertidaoNegativaDebitos (primário)
  2. Portal RFB — solucoes.receita.fazenda.gov.br (fallback gracioso)

Custo: consumido pelo DIRECT_DATA_TOKEN existente.
Env var: DIRECT_DATA_TOKEN (opcional — gracioso se ausente)
Severity: atencao — débito federal vencido impede participação em licitações.
"""
from __future__ import annotations

import logging
import os
import re

import requests

from .base import SubradarSource

logger = logging.getLogger("subradar.cnd_federal_pj")

_DD_TOKEN = os.environ.get("DIRECT_DATA_TOKEN", "")
_DD_V3_BASE = "https://apiv3.directd.com.br/api"

# Endpoint público RFB (emissão programática / sistemas integrados)
_RFB_URL = (
    "https://solucoes.receita.fazenda.gov.br/Servicos/certidaointernet/PJ/EmitirPJ"
)

# Situações que indicam regularidade (sem alerta)
_SITUACOES_REGULARES = {
    "negativa",
    "cnd",
    "positiva com efeito de negativa",
    "cpen",
    "com efeito de negativa",
    "regular",
}

# Situações que indicam débito (alerta)
_SITUACOES_POSITIVAS = {
    "positiva",
    "com debito",
    "com débito",
    "irregular",
    "inadimplente",
}


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", str(cnpj or ""))


def _via_direct_data(cnpj14: str) -> dict | None:
    """
    Consulta CND Federal via Direct Data v3.
    Endpoint: ReceitaFederalCertidaoNegativaDebitos
    Resposta esperada:
      { "retorno": { "situacao": "Negativa"/"Positiva"/"Positiva com Efeito de Negativa",
                     "numeroCertidao": str,
                     "validade": str } }
    Variação alternativa:
      { "retorno": { "regular": bool, "tipo": "CND"/"CPEN", ... } }
    """
    if not _DD_TOKEN:
        return None
    try:
        resp = requests.get(
            f"{_DD_V3_BASE}/ReceitaFederalCertidaoNegativaDebitos",
            params={"Cnpj": cnpj14, "Token": _DD_TOKEN},
            timeout=25,
        )
        if resp.ok and "json" in resp.headers.get("Content-Type", ""):
            data = resp.json()
            if isinstance(data, dict):
                return data
    except Exception as e:
        logger.debug("cnd_federal_pj Direct Data: %s", e)
    return None


def _via_portal_rfb(cnpj14: str) -> dict | None:
    """
    Tenta consulta direta ao portal da RFB via GET.
    Retorna None se bloqueado, com CAPTCHA ou indisponível.
    """
    try:
        resp = requests.get(
            _RFB_URL,
            params={"cnpj": cnpj14},
            headers={
                "User-Agent": (
                    "Mozilla/5.0 (compatible; SubradarBot/1.0; "
                    "+https://thebrinsider.com)"
                ),
                "Referer": "https://solucoes.receita.fazenda.gov.br/",
            },
            timeout=20,
            allow_redirects=True,
        )
        if not resp.ok:
            logger.debug("cnd_federal_pj portal RFB: HTTP %s", resp.status_code)
            return None
        body = resp.text.lower()
        # Detecta situação na resposta HTML
        if "positiva com efeito de negativa" in body or "cpen" in body:
            return {"situacao_portal": "positiva com efeito de negativa"}
        if "certidao negativa" in body or "negativa de debito" in body or "cnd" in body:
            return {"situacao_portal": "negativa"}
        if "certidao positiva" in body or "debito" in body or "inadimplente" in body:
            return {"situacao_portal": "positiva"}
    except Exception as e:
        logger.debug("cnd_federal_pj portal RFB: %s", e)
    return None


def _extrair_situacao(data: dict) -> tuple[str | None, str, str]:
    """
    Normaliza resposta para (situacao: "negativa"|"cpen"|"positiva"|None, numero: str, validade: str).

    Retorna:
      "negativa"  — CND, sem débitos
      "cpen"      — Positiva com Efeito de Negativa (parcelamento/suspensão)
      "positiva"  — há débito(s) vencido(s) → alerta
      None        — inconclusivo
    """
    retorno = data.get("retorno") or data
    if not isinstance(retorno, dict):
        return None, "", ""

    numero = (
        retorno.get("numeroCertidao")
        or retorno.get("numeroCnd")
        or retorno.get("numero")
        or retorno.get("numCertidao")
        or "s/n"
    )
    validade = retorno.get("validade") or retorno.get("dataValidade") or ""

    # Campo booleano explícito
    regular_bool = retorno.get("regular")
    tipo = str(retorno.get("tipo") or "").upper()
    if isinstance(regular_bool, bool):
        if regular_bool:
            situacao_norm = "cpen" if tipo == "CPEN" else "negativa"
        else:
            situacao_norm = "positiva"
        return situacao_norm, str(numero), str(validade)

    # Campo textual de situação (API DD ou portal)
    situacao_raw = data.get("situacao_portal", "")
    for campo in ("situacao", "status", "resultado", "descricao", "tipoCertidao", "tipo"):
        val = retorno.get(campo) or ""
        if val and isinstance(val, str):
            situacao_raw = val.lower().strip()
            break

    if situacao_raw:
        if "positiva com efeito de negativa" in situacao_raw or situacao_raw == "cpen":
            return "cpen", str(numero), str(validade)
        if any(lbl in situacao_raw for lbl in _SITUACOES_REGULARES):
            return "negativa", str(numero), str(validade)
        if any(lbl in situacao_raw for lbl in _SITUACOES_POSITIVAS):
            return "positiva", str(numero), str(validade)

    return None, str(numero), str(validade)


class CNDFederalPJConnector(SubradarSource):
    """
    Verifica Certidão Negativa de Débitos Federais (RFB+PGFN) por CNPJ (PJ).

    Gera alerta 'atencao' apenas quando a certidão for Positiva (há débito).
    CND (Negativa) e CPEN (Positiva com Efeito de Negativa) não geram alerta —
    ambas conferem regularidade fiscal plena para fins legais.
    Gracioso se DIRECT_DATA_TOKEN ausente e portal RFB não estiver acessível.
    """
    fonte = "cnd_federal"
    request_delay = 1.0

    def consultar_cnpj(self, cnpj_or_cpf: str, razao_social: str | None = None, **_) -> list[dict]:
        cnpj = _strip(cnpj_or_cpf)
        if len(cnpj) != 14:
            return []

        cnpj_fmt = (
            f"{cnpj[:2]}.{cnpj[2:5]}.{cnpj[5:8]}/{cnpj[8:12]}-{cnpj[12:14]}"
        )
        nome = razao_social or cnpj_fmt

        # Tentativa 1: Direct Data v3
        data = _via_direct_data(cnpj)

        # Tentativa 2: portal direto da RFB (se DD falhou ou ausente)
        if data is None:
            logger.debug(
                "cnd_federal_pj: DD indisponível para %s — tentando portal RFB", cnpj_fmt
            )
            data = _via_portal_rfb(cnpj)

        if data is None:
            logger.debug("cnd_federal_pj: sem resposta para %s", cnpj_fmt)
            return []

        situacao, numero, validade = _extrair_situacao(data)

        # Regular (CND) → sem alerta
        if situacao == "negativa":
            logger.debug("cnd_federal_pj: CND Negativa para %s (certidão %s)", cnpj_fmt, numero)
            return []

        # CPEN → regularidade plena, sem alerta
        if situacao == "cpen":
            logger.debug(
                "cnd_federal_pj: CPEN (Positiva c/ Efeito de Negativa) para %s — sem alerta",
                cnpj_fmt,
            )
            return []

        # Inconclusivo → gracioso
        if situacao is None:
            logger.debug("cnd_federal_pj: sem dado conclusivo para %s", cnpj_fmt)
            return []

        # Positiva → débito → alerta
        logger.info("cnd_federal_pj: CND POSITIVA (débito) para %s (certidão %s)", cnpj_fmt, numero)

        desc_parts = [
            f"Certidão de Débitos Relativos a Créditos Tributários Federais e à Dívida Ativa da União "
            f"com resultado POSITIVO para {nome} (CNPJ {cnpj_fmt})."
        ]
        if numero and numero != "s/n":
            desc_parts.append(f"Número da certidão: {numero}.")
        if validade:
            desc_parts.append(f"Referência/validade: {validade}.")
        desc_parts.append(
            "A Certidão Positiva indica a existência de débitos vencidos perante a RFB e/ou PGFN, "
            "o que impede a participação em licitações, celebração de contratos e obtenção de "
            "financiamentos com recursos públicos (Lei 8.666/93, art. 29, III; Lei 8.212/91, art. 47)."
        )

        return [{
            "fonte": self.fonte,
            "categoria": "fiscal",
            "severidade": "atencao",
            "titulo": f"CND Federal — certidão POSITIVA (débito): {cnpj_fmt}",
            "descricao": " ".join(desc_parts),
            "url_fonte": _RFB_URL,
            "referencia_id": str(numero),
            "is_novo": True,
        }]
