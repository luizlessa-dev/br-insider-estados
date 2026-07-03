"""
Conector: BigDataCorp — Negativações, Protestos e Score PJ

Cobre o que os conectores públicos (PGFN, sanções) não cobrem:
  - Negativações em bureaus privados (Boa Vista/Equifax, Quod, SPC)
  - Protestos cartorias por UF (ondemand)
  - Score de crédito PJ 0–1000

APIs:
  Empresas (dados próprios): POST https://plataforma.bigdatacorp.com.br/empresas
  On-Demand (real-time):     POST https://plataforma.bigdatacorp.com.br/ondemand
  Marketplace (parceiros):   POST https://plataforma.bigdatacorp.com.br/marketplace

Auth: header "AccessToken: <token>" — NÃO é Bearer, NÃO vai no body.

Variável de ambiente:
  BIGDATA_CORP_TOKEN   — AccessToken obtido no portal center.bigdatacorp.com.br
                         ou via POST /tokens/generate com login+senha

Cadastro: NÃO é self-service. Contato: comercial@bigdatacorp.com.br (CNPJ obrigatório).
Trial: 500 chamadas/mês por API após conta criada.

Datasets usados — monitoramento contínuo (FONTES):
  registration_data                    — dados cadastrais RF
  owners_lawsuits                      — processos dos sócios (endpoint /empresas)
  ondemand_pesquisa_protesto_by_state  — protestos por UF (endpoint /ondemand)

Datasets avulsa (FONTES_AVULSA, via marketplace — custo por consulta):
  partner_quod_credit_score_company      — Score Quod PJ 300-1000 (~R$ 2,41/consulta)
  partner_boavista_one_score_company     — Score Boa Vista PJ 0-1000 (~R$ 13,02/consulta)
"""
from __future__ import annotations

import logging
import os
import re
import time

import requests

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.bigdatacorp")

BDC_TOKEN = os.environ.get("BIGDATA_CORP_TOKEN", "")

_BASE_EMPRESAS    = "https://plataforma.bigdatacorp.com.br/empresas"
_BASE_ONDEMAND    = "https://plataforma.bigdatacorp.com.br/ondemand"
_BASE_MARKETPLACE = "https://plataforma.bigdatacorp.com.br/marketplace"

# Dataset score — Quod é ~6x mais barato que Boa Vista (~R$ 2,41 vs ~R$ 13,02)
_DATASET_SCORE_QUOD      = "partner_quod_credit_score_company"
_DATASET_SCORE_BOAVISTA  = "partner_boavista_one_score_company"

# Limiares de alerta (escala Quod: 300-1000; escala BV: 0-1000)
_SCORE_CRITICO = 450
_SCORE_ATENCAO = 600


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", str(cnpj or ""))


def _fmt(cnpj: str) -> str:
    c = _strip(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _headers() -> dict:
    return {
        "accept": "application/json",
        "content-type": "application/json",
        "AccessToken": BDC_TOKEN,
    }


def _post(url: str, datasets: str, cnpj_digits: str) -> dict | None:
    """Faz POST na API BigDataCorp e retorna o primeiro item de Result, ou None em erro."""
    payload = {
        "Datasets": datasets,
        "q": f"doc{{{cnpj_digits}}}",
        "Limit": 1,
    }
    try:
        resp = requests.post(url, json=payload, headers=_headers(), timeout=30)
        if resp.status_code == 401:
            logger.error("BigDataCorp: token inválido ou expirado (HTTP 401)")
            return None
        resp.raise_for_status()
        data = resp.json()
        results = data.get("Result", [])
        return results[0] if results else {}
    except Exception as e:
        logger.error("BigDataCorp: erro em %s para %s: %s", url, cnpj_digits, e)
        return None


def _parse_protestos(result: dict) -> list[dict]:
    """Extrai protestos cartoriais do resultado ondemand."""
    dados = (
        result.get("ProtestoEstadual") or
        result.get("Protestos") or
        result.get("OndemandPesquisaProtestoByState") or
        {}
    )
    if not dados:
        return []

    ocorrencias = dados.get("Ocorrencias") or dados.get("Items") or []
    total = dados.get("TotalOcorrencias") or len(ocorrencias)
    valor_total = dados.get("ValorTotal") or sum(
        float(re.sub(r"[^\d\.]", "", str(o.get("Valor") or 0)) or 0)
        for o in ocorrencias
    )

    if not total:
        return []

    return [{
        "tipo": "protesto",
        "total_ocorrencias": total,
        "valor_total": valor_total,
        "ocorrencias": ocorrencias[:10],
        "_severidade": "critico" if total > 3 or valor_total > 50_000 else "atencao",
    }]


def _parse_socios_processos(result: dict) -> list[dict]:
    """Extrai processos dos sócios vinculados ao CNPJ."""
    dados = result.get("OwnersLawsuits") or result.get("Lawsuits") or {}
    processos = dados.get("Lawsuits") or dados.get("Items") or []
    total = dados.get("TotalLawsuits") or len(processos)

    if not total:
        return []

    return [{
        "tipo": "processo_socio",
        "total": total,
        "amostra": processos[:5],
        "_severidade": "atencao",
    }]


def _parse_score(result: dict, bureau: str = "quod") -> dict | None:
    """Extrai score de crédito PJ do resultado do marketplace."""
    # Tenta múltiplas chaves conforme o bureau
    score_data = (
        result.get("PartnerQuodCreditScoreCompany") or
        result.get("PartnerBoavistaOneScoreCompany") or
        result.get("ScoreCreditoMultidados") or
        result.get("Score") or
        {}
    )
    score = score_data.get("Score") or score_data.get("Pontuacao") or score_data.get("ScoreValue")
    if score is None:
        return None

    try:
        score = int(score)
    except (ValueError, TypeError):
        return None

    if score < _SCORE_CRITICO:
        sev = "critico"
    elif score < _SCORE_ATENCAO:
        sev = "atencao"
    else:
        sev = "info"

    return {
        "tipo": "score_credito",
        "score": score,
        "bureau": "Quod" if bureau == "quod" else "Boa Vista",
        "faixa": "alto_risco" if score < _SCORE_CRITICO else ("medio_risco" if score < _SCORE_ATENCAO else "baixo_risco"),
        "_severidade": sev,
    }


def _build_alerta(cnpj_fmt: str, ciclo: str, dado: dict, fonte: str = "bigdatacorp") -> dict:
    tipo = dado["tipo"]
    sev = dado["_severidade"]

    if tipo == "protesto":
        qtd = dado["total_ocorrencias"]
        valor = dado["valor_total"]
        titulo = f"Protestos cartoriais — {qtd} ocorrência(s)"
        descricao = (
            f"CNPJ com protestos em cartório(s) registrados via BigDataCorp. "
            f"{qtd} ocorrência(s)."
            + (f" Valor total: R$ {valor:,.2f}." if valor else "")
        )

    elif tipo == "processo_socio":
        total = dado["total"]
        titulo = f"Processos dos sócios — {total} registro(s)"
        descricao = (
            f"Sócios vinculados ao CNPJ possuem {total} processo(s) judicial(is) registrado(s) "
            f"na base BigDataCorp."
        )

    elif tipo == "score_credito":
        score = dado["score"]
        bureau = dado.get("bureau", "bureau")
        faixa = dado["faixa"].replace("_", " ")
        titulo = f"Score de crédito PJ {bureau}: {score} ({faixa})"
        descricao = (
            f"Score de crédito PJ via {bureau} (BigDataCorp Marketplace): {score}. "
            f"Faixa: {faixa}. "
            f"Escores baixos indicam maior probabilidade de inadimplência."
        )
    else:
        titulo = f"BigDataCorp — {tipo}"
        descricao = str(dado)

    return {
        "cnpj": cnpj_fmt,
        "ciclo": ciclo,
        "fonte": fonte,
        "categoria": "credito",
        "severidade": sev,
        "titulo": titulo,
        "descricao": descricao,
        "url_fonte": "https://bigdatacorp.com.br",
        "is_novo": True,
    }


class BigDataCorpConnector(SubradarSource):
    """
    Monitoramento contínuo: protestos + processos dos sócios.
    Usa endpoints /ondemand e /empresas — tier gratuito 500 chamadas/mês.
    """
    fonte = "bigdatacorp"
    request_delay = 1.5

    def consultar_cnpj(self, cnpj: str, **_) -> list[dict]:
        if not BDC_TOKEN:
            logger.info("BigDataCorp: BIGDATA_CORP_TOKEN não configurado — fonte indisponível")
            return []

        cnpj_digits = _strip(cnpj)
        cnpj_fmt = _fmt(cnpj_digits)
        ciclo = _ciclo_atual()

        dados: list[dict] = []

        # Protestos cartorias via ondemand
        result_od = _post(_BASE_ONDEMAND, "ondemand_pesquisa_protesto_by_state", cnpj_digits)
        if result_od is not None:
            dados.extend(_parse_protestos(result_od))

        # Processos dos sócios via /empresas
        result_emp = _post(_BASE_EMPRESAS, "owners_lawsuits", cnpj_digits)
        if result_emp is not None:
            dados.extend(_parse_socios_processos(result_emp))

        if not dados:
            return []

        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, dados)
        if not mudou:
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt,
            "fonte": self.fonte,
            "ciclo": ciclo,
            "hash_dados": hash_novo,
            "dados": {"registros": dados},
        }])

        return [_build_alerta(cnpj_fmt, ciclo, d) for d in dados]


class BigDataCorpScoreConnector(SubradarSource):
    """
    Consulta avulsa: Score de crédito PJ via Quod (Marketplace).
    Custo ~R$ 2,41/consulta — usar somente em FONTES_AVULSA.
    Fallback para Boa Vista (~R$ 13,02) se Quod não retornar score.
    """
    fonte = "bigdatacorp_score"
    request_delay = 1.0

    def consultar_cnpj(self, cnpj: str, **_) -> list[dict]:
        if not BDC_TOKEN:
            logger.info("BigDataCorp Score: BIGDATA_CORP_TOKEN não configurado — fonte indisponível")
            return []

        cnpj_digits = _strip(cnpj)
        cnpj_fmt = _fmt(cnpj_digits)
        ciclo = _ciclo_atual()

        # Tenta Quod primeiro (mais barato); fallback Boa Vista
        score_dado = None
        for dataset, bureau in [
            (_DATASET_SCORE_QUOD, "quod"),
            (_DATASET_SCORE_BOAVISTA, "boavista"),
        ]:
            result = _post(_BASE_MARKETPLACE, dataset, cnpj_digits)
            if result is not None:
                score_dado = _parse_score(result, bureau=bureau)
                if score_dado:
                    break

        if not score_dado:
            return []

        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, score_dado)
        if not mudou:
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt,
            "fonte": self.fonte,
            "ciclo": ciclo,
            "hash_dados": hash_novo,
            "dados": score_dado,
        }])

        return [_build_alerta(cnpj_fmt, ciclo, score_dado, fonte=self.fonte)]
