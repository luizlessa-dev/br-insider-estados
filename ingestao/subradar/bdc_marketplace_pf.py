"""
Conector: BigDataCorp Marketplace — Dados de Crédito e Segurança para Pessoa Física

Datasets marketplace ativados (pay-per-query via /marketplace):
  partner_quod_dados_restritivos_pf      — Dados Restritivos | Quod
  partner_biro_credito_dados_restritivos — Dados Restritivos | Birô de Crédito (Serasa/SPC)
  partner_quod_flags_negativos           — Flags Negativos | Quod
  partner_seguranca_publica              — Dados de Segurança Pública
  partner_quod_credit_score_pf           — Score de Crédito | Quod (PF)

ATENÇÃO: os nomes de dataset acima são convenções prováveis baseadas no padrão BDC.
Confirmar os nomes exatos no portal center.bigdatacorp.com.br → Marketplace → Meus Datasets
e ajustar as constantes _DS_* abaixo se houver divergência.

Endpoint: POST https://plataforma.bigdatacorp.com.br/marketplace
Query:    doc{CPF11} (11 dígitos, sem pontuação)
Auth:     headers TokenId + AccessToken

Uso: incluir em FONTES_PF_AVULSA (não em FONTES_PF — cobrança por consulta).

Env vars (compartilhadas):
  BIGDATA_CORP_TOKEN_ID    — header TokenId
  BIGDATA_CORP_ACCESS_TOKEN — header AccessToken
"""
from __future__ import annotations

import logging
import os
import re

import requests

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.bdc_marketplace_pf")

BDC_TOKEN_ID     = os.environ.get("BIGDATA_CORP_TOKEN_ID", "") or os.environ.get("BIGDATA_CORP_TOKEN", "")
BDC_ACCESS_TOKEN = os.environ.get("BIGDATA_CORP_ACCESS_TOKEN", "") or os.environ.get("BIGDATA_CORP_TOKEN", "")

_BASE_MARKETPLACE = "https://plataforma.bigdatacorp.com.br/marketplace"
_BASE_PEOPLEV2    = "https://bigboost.bigdatacorp.com.br/peoplev2"

# Dataset names confirmados (mapeamento BDC 2026-08-01)
_DS_NEGATIVACOES_QUOD     = "partner_quod_credit_risk_details_person"   # R$ 2.41/query
_DS_SCORE_QUOD            = "partner_quod_credit_score_person"           # R$ 2.41/query
_DS_FLAGS_QUOD            = "marketplace_partner_quod_credit_risk_person" # R$ 2.41/query
_DS_SCORE_POSITIVO        = "partner_scorepositivo_individual_finance"   # R$ 7.01/query
_DS_PROTESTOS             = "ondemand_pesquisa_protesto_by_state_person" # on-demand
_DS_SEGURANCA_PUBLICA     = "partner_seguranca_publica"                  # on-demand / contato comercial
_DS_FINANCEIRO            = "pessoas_financial_data"                     # incluso no plano base
_DS_FINANCEIRO_FAMILIA    = "pessoas_family_financial_data"              # incluso no plano base

# Aliases legados (mantidos para não quebrar imports externos)
_DS_RESTRITIVOS_QUOD  = _DS_NEGATIVACOES_QUOD
_DS_RESTRITIVOS_BIRO  = _DS_SCORE_POSITIVO
_DS_SCORE_QUOD_PF     = _DS_SCORE_QUOD

# Score: limiar de alerta (escala Quod 300-1000)
_SCORE_CRITICO = 450
_SCORE_ATENCAO = 600


def _headers() -> dict:
    return {
        "accept": "application/json",
        "content-type": "application/json",
        "TokenId": BDC_TOKEN_ID,
        "AccessToken": BDC_ACCESS_TOKEN,
    }


def _post(dataset: str, cpf11: str) -> dict | None:
    # Datasets do plano base (pessoas_*) usam /peoplev2; marketplace usa /marketplace
    base = _BASE_PEOPLEV2 if dataset.startswith("pessoas_") else _BASE_MARKETPLACE
    payload = {
        "Datasets": dataset,
        "q": f"doc{{{cpf11}}}",
        "Limit": 1,
    }
    try:
        resp = requests.post(base, json=payload, headers=_headers(), timeout=30)
        if resp.status_code == 401:
            logger.error("BDC Marketplace PF: token inválido (HTTP 401)")
            return None
        resp.raise_for_status()
        results = resp.json().get("Result", [])
        return results[0] if results else {}
    except Exception as e:
        logger.error("BDC Marketplace PF [%s]: %s", dataset, e)
        return None


def _fmt_cpf(cpf11: str) -> str:
    return f"{cpf11[:3]}.{cpf11[3:6]}.{cpf11[6:9]}-{cpf11[9:]}" if len(cpf11) == 11 else cpf11


def _check_disponivel(result: dict, dataset_name: str) -> bool:
    """Verifica se o dataset retornou dados válidos (não -109 = fora do plano)."""
    if result is None:
        return False
    # Percorre qualquer chave do resultado
    for v in result.values():
        if isinstance(v, dict):
            code = v.get("Code") or v.get("code")
            if code == -109:
                logger.warning("BDC Marketplace PF: dataset '%s' não está no plano (-109)", dataset_name)
                return False
    return True


# ─────────────────────────────────────────────────────────────
# Parsers
# ─────────────────────────────────────────────────────────────

def _parse_restritivos(result: dict) -> list[dict]:
    """Extrai dados restritivos (negativações) — Quod ou Birô de Crédito."""
    for key in (
        "PartnerQuodDadosRestritivosPf", "PartnerBiroCreditoDadosRestritivos",
        "DadosRestritivos", "Restricoes", "Negativacoes",
    ):
        data = result.get(key)
        if data:
            break
    else:
        return []

    ocorrencias = (
        data.get("Ocorrencias") or data.get("Restricoes") or
        data.get("Negativacoes") or data.get("Items") or []
    )
    total = (
        data.get("TotalOcorrencias") or data.get("TotalRestricoes") or
        data.get("Total") or len(ocorrencias)
    )
    valor_total = data.get("ValorTotal") or sum(
        float(re.sub(r"[^\d\.]", "", str(o.get("Valor") or 0)) or 0)
        for o in ocorrencias
    )

    if not total:
        return []

    return [{
        "tipo": "restritivo",
        "total": total,
        "valor_total": valor_total,
        "amostra": ocorrencias[:5],
        "_severidade": "critico" if total > 5 or valor_total > 10_000 else "atencao",
    }]


def _parse_flags(result: dict) -> list[dict]:
    """Extrai flags negativos Quod — formato compacto (sem valor monetário)."""
    for key in ("PartnerQuodFlagsNegativos", "FlagsNegativos", "Flags"):
        data = result.get(key)
        if data:
            break
    else:
        return []

    flags = data.get("Flags") or data.get("Items") or []
    total = data.get("TotalFlags") or data.get("Total") or len(flags)

    if not total:
        return []

    nomes = [f.get("NomeFlag") or f.get("Descricao") or str(f) for f in flags[:10]]

    return [{
        "tipo": "flag_negativo",
        "total": total,
        "flags": nomes,
        "_severidade": "critico" if total > 3 else "atencao",
    }]


def _parse_seguranca_publica(result: dict) -> list[dict]:
    """Extrai dados de segurança pública (antecedentes policiais/criminais)."""
    for key in (
        "PartnerSegurancaPublica", "SegurancaPublica",
        "DadosSegurancaPublica", "Antecedentes",
    ):
        data = result.get(key)
        if data:
            break
    else:
        return []

    ocorrencias = (
        data.get("Ocorrencias") or data.get("Antecedentes") or
        data.get("Registros") or data.get("Items") or []
    )
    total = data.get("Total") or data.get("TotalOcorrencias") or len(ocorrencias)

    if not total:
        return []

    return [{
        "tipo": "seguranca_publica",
        "total": total,
        "amostra": ocorrencias[:5],
        "_severidade": "critico",
    }]


def _parse_score_quod(result: dict) -> dict | None:
    """Extrai score de crédito Quod PF (escala 300-1000)."""
    for key in (
        "PartnerQuodCreditScorePf", "PartnerQuodCreditScore",
        "ScoreCreditoQuod", "Score",
    ):
        data = result.get(key)
        if data:
            break
    else:
        return None

    score_raw = (
        data.get("Score") or data.get("Pontuacao") or
        data.get("ScoreValue") or data.get("Valor")
    )
    if score_raw is None:
        return None

    try:
        score = int(score_raw)
    except (ValueError, TypeError):
        return None

    if score < _SCORE_CRITICO:
        sev, faixa = "critico", "alto_risco"
    elif score < _SCORE_ATENCAO:
        sev, faixa = "atencao", "medio_risco"
    else:
        sev, faixa = "info", "baixo_risco"

    return {
        "tipo": "score_credito",
        "score": score,
        "bureau": "Quod",
        "faixa": faixa,
        "_severidade": sev,
    }


# ─────────────────────────────────────────────────────────────
# Builder de alerta
# ─────────────────────────────────────────────────────────────

def _build_alerta(cpf_fmt: str, ciclo: str, dado: dict, fonte: str) -> dict:
    tipo = dado["tipo"]
    sev  = dado["_severidade"]

    if tipo == "restritivo":
        total = dado["total"]
        valor = dado["valor_total"]
        titulo = f"Dados restritivos — {total} ocorrência(s)"
        descricao = (
            f"CPF com {total} registro(s) restritivo(s)/negativação(ões) "
            f"em bureau de crédito (BigDataCorp Marketplace)."
            + (f" Valor total: R$ {valor:,.2f}." if valor else "")
        )
        categoria = "credito"

    elif tipo == "flag_negativo":
        total = dado["total"]
        flags_str = ", ".join(dado["flags"][:5]) or "-"
        titulo = f"Flags negativos Quod — {total} flag(s)"
        descricao = (
            f"CPF com {total} flag(s) negativo(s) na base Quod (BigDataCorp Marketplace). "
            f"Flags: {flags_str}."
        )
        categoria = "credito"

    elif tipo == "seguranca_publica":
        total = dado["total"]
        titulo = f"Antecedentes — {total} registro(s) de segurança pública"
        descricao = (
            f"CPF com {total} registro(s) em bases de segurança pública "
            f"(BigDataCorp Marketplace / parceiro Dados de Segurança Pública)."
        )
        categoria = "juridico"

    elif tipo == "score_credito":
        score = dado["score"]
        faixa = dado["faixa"].replace("_", " ")
        titulo = f"Score Quod PF: {score} ({faixa})"
        descricao = (
            f"Score de crédito Quod para pessoa física: {score} (escala 300-1000). "
            f"Faixa: {faixa}. "
            f"Escores abaixo de {_SCORE_CRITICO} indicam alto risco de inadimplência."
        )
        categoria = "credito"

    else:
        titulo = f"BDC Marketplace PF — {tipo}"
        descricao = str(dado)
        categoria = "credito"

    return {
        "cpf": cpf_fmt,
        "ciclo": ciclo,
        "fonte": fonte,
        "categoria": categoria,
        "severidade": sev,
        "titulo": titulo,
        "descricao": descricao,
        "url_fonte": "https://bigdatacorp.com.br",
        "is_novo": True,
    }


def _salvar_snapshot(cpf_fmt: str, fonte: str, ciclo: str, dados: list) -> tuple[bool, str]:
    return snapshot_changed(cpf_fmt, fonte, ciclo, dados)


# ─────────────────────────────────────────────────────────────
# Conectores
# ─────────────────────────────────────────────────────────────

class BDCRestritivosQuodPFConnector(SubradarSource):
    """Dados Restritivos Quod para PF — BigDataCorp Marketplace (pay-per-query)."""
    fonte = "bdc_restritivos_quod_pf"
    request_delay = 1.0

    def consultar_cpf(self, cpf: str, nome: str | None = None, **_) -> list[dict]:
        if not BDC_ACCESS_TOKEN:
            return []
        cpf11 = re.sub(r"\D", "", str(cpf or ""))
        if len(cpf11) != 11:
            return []
        cpf_fmt = _fmt_cpf(cpf11)
        ciclo = _ciclo_atual()

        result = _post(_DS_RESTRITIVOS_QUOD, cpf11)
        if not _check_disponivel(result, _DS_RESTRITIVOS_QUOD):
            return []

        dados = _parse_restritivos(result)
        if not dados:
            return []

        mudou, hash_novo = _salvar_snapshot(cpf_fmt, self.fonte, ciclo, dados)
        if not mudou:
            return []

        upsert("sub_snapshots", [{"cpf": cpf_fmt, "fonte": self.fonte, "ciclo": ciclo,
                                   "hash_dados": hash_novo, "dados": {"registros": dados}}])
        return [_build_alerta(cpf_fmt, ciclo, d, self.fonte) for d in dados]


class BDCRestritevosBiroPFConnector(SubradarSource):
    """Dados Restritivos Birô de Crédito (Serasa/SPC) para PF — BigDataCorp Marketplace."""
    fonte = "bdc_restritivos_biro_pf"
    request_delay = 1.0

    def consultar_cpf(self, cpf: str, nome: str | None = None, **_) -> list[dict]:
        if not BDC_ACCESS_TOKEN:
            return []
        cpf11 = re.sub(r"\D", "", str(cpf or ""))
        if len(cpf11) != 11:
            return []
        cpf_fmt = _fmt_cpf(cpf11)
        ciclo = _ciclo_atual()

        result = _post(_DS_RESTRITIVOS_BIRO, cpf11)
        if not _check_disponivel(result, _DS_RESTRITIVOS_BIRO):
            return []

        dados = _parse_restritivos(result)
        if not dados:
            return []

        mudou, hash_novo = _salvar_snapshot(cpf_fmt, self.fonte, ciclo, dados)
        if not mudou:
            return []

        upsert("sub_snapshots", [{"cpf": cpf_fmt, "fonte": self.fonte, "ciclo": ciclo,
                                   "hash_dados": hash_novo, "dados": {"registros": dados}}])
        return [_build_alerta(cpf_fmt, ciclo, d, self.fonte) for d in dados]


class BDCFlagsNegativosQuodPFConnector(SubradarSource):
    """Flags Negativos Quod para PF — BigDataCorp Marketplace."""
    fonte = "bdc_flags_negativos_quod_pf"
    request_delay = 1.0

    def consultar_cpf(self, cpf: str, nome: str | None = None, **_) -> list[dict]:
        if not BDC_ACCESS_TOKEN:
            return []
        cpf11 = re.sub(r"\D", "", str(cpf or ""))
        if len(cpf11) != 11:
            return []
        cpf_fmt = _fmt_cpf(cpf11)
        ciclo = _ciclo_atual()

        result = _post(_DS_FLAGS_QUOD, cpf11)
        if not _check_disponivel(result, _DS_FLAGS_QUOD):
            return []

        dados = _parse_flags(result)
        if not dados:
            return []

        mudou, hash_novo = _salvar_snapshot(cpf_fmt, self.fonte, ciclo, dados)
        if not mudou:
            return []

        upsert("sub_snapshots", [{"cpf": cpf_fmt, "fonte": self.fonte, "ciclo": ciclo,
                                   "hash_dados": hash_novo, "dados": {"registros": dados}}])
        return [_build_alerta(cpf_fmt, ciclo, d, self.fonte) for d in dados]


class BDCSegurancaPublicaPFConnector(SubradarSource):
    """Dados de Segurança Pública (antecedentes) para PF — BigDataCorp Marketplace."""
    fonte = "bdc_seguranca_publica_pf"
    request_delay = 1.0

    def consultar_cpf(self, cpf: str, nome: str | None = None, **_) -> list[dict]:
        if not BDC_ACCESS_TOKEN:
            return []
        cpf11 = re.sub(r"\D", "", str(cpf or ""))
        if len(cpf11) != 11:
            return []
        cpf_fmt = _fmt_cpf(cpf11)
        ciclo = _ciclo_atual()

        result = _post(_DS_SEGURANCA_PUBLICA, cpf11)
        if not _check_disponivel(result, _DS_SEGURANCA_PUBLICA):
            return []

        dados = _parse_seguranca_publica(result)
        if not dados:
            return []

        mudou, hash_novo = _salvar_snapshot(cpf_fmt, self.fonte, ciclo, dados)
        if not mudou:
            return []

        upsert("sub_snapshots", [{"cpf": cpf_fmt, "fonte": self.fonte, "ciclo": ciclo,
                                   "hash_dados": hash_novo, "dados": {"registros": dados}}])
        return [_build_alerta(cpf_fmt, ciclo, d, self.fonte) for d in dados]


class BDCScoreQuodPFConnector(SubradarSource):
    """Score de Crédito Quod para PF (300-1000) — BigDataCorp Marketplace (pay-per-query)."""
    fonte = "bdc_score_quod_pf"
    request_delay = 1.0

    def consultar_cpf(self, cpf: str, nome: str | None = None, **_) -> list[dict]:
        if not BDC_ACCESS_TOKEN:
            return []
        cpf11 = re.sub(r"\D", "", str(cpf or ""))
        if len(cpf11) != 11:
            return []
        cpf_fmt = _fmt_cpf(cpf11)
        ciclo = _ciclo_atual()

        result = _post(_DS_SCORE_QUOD_PF, cpf11)
        if not _check_disponivel(result, _DS_SCORE_QUOD_PF):
            return []

        dado = _parse_score_quod(result)
        if not dado:
            return []

        mudou, hash_novo = _salvar_snapshot(cpf_fmt, self.fonte, ciclo, dado)
        if not mudou:
            return []

        upsert("sub_snapshots", [{"cpf": cpf_fmt, "fonte": self.fonte, "ciclo": ciclo,
                                   "hash_dados": hash_novo, "dados": dado}])
        return [_build_alerta(cpf_fmt, ciclo, dado, self.fonte)]


class BDCDadosFinanceirosPFConnector(SubradarSource):
    """Dados Financeiros Estimados PF — incluso no plano base BDC (/peoplev2)."""
    fonte = "bdc_financeiro_pf"
    request_delay = 1.0

    def consultar_cpf(self, cpf: str, nome: str | None = None, **_) -> list[dict]:
        if not BDC_ACCESS_TOKEN:
            return []
        cpf11 = re.sub(r"\D", "", str(cpf or ""))
        if len(cpf11) != 11:
            return []
        cpf_fmt = _fmt_cpf(cpf11)
        ciclo = _ciclo_atual()

        result = _post(_DS_FINANCEIRO, cpf11)
        if not result or not _check_disponivel(result, _DS_FINANCEIRO):
            return []
        return []  # financeiro gera dados, não alertas — ver resumo_pf()

    def resumo_pf(self, cpf: str, nome: str | None = None) -> dict | None:
        if not BDC_ACCESS_TOKEN:
            return {
                "fonte": self.fonte, "categoria": "financeiro",
                "status": "pendente", "titulo_secao": "Dados Financeiros (BDC)",
                "resumo": "Token BDC não configurado",
                "detalhes": {},
            }
        cpf11 = re.sub(r"\D", "", str(cpf or ""))
        if len(cpf11) != 11:
            return None
        result = _post(_DS_FINANCEIRO, cpf11)
        if not result or not _check_disponivel(result, _DS_FINANCEIRO):
            return {
                "fonte": self.fonte, "categoria": "financeiro",
                "status": "pendente", "titulo_secao": "Dados Financeiros (BDC)",
                "resumo": "Dataset não habilitado no plano atual",
                "detalhes": {},
            }
        data = result.get("PessoasFinancialData") or result.get("FinancialData") or {}
        renda = data.get("EstimatedIncome") or data.get("estimated_income")
        patrimonio = data.get("AssetValue") or data.get("asset_value")
        resumo_txt = []
        if renda:
            resumo_txt.append(f"Renda estimada: R$ {float(renda):,.0f}".replace(",", "."))
        if patrimonio:
            resumo_txt.append(f"Patrimônio: R$ {float(patrimonio):,.0f}".replace(",", "."))
        return {
            "fonte": self.fonte, "categoria": "financeiro",
            "status": "limpo" if resumo_txt else "pendente",
            "titulo_secao": "Dados Financeiros Estimados (BDC)",
            "resumo": " · ".join(resumo_txt) if resumo_txt else "Dados não disponíveis",
            "detalhes": data,
        }


class BDCNegativacoesPFConnectorV2(SubradarSource):
    """Negativações PF — Quod (partner_quod_credit_risk_details_person)."""
    fonte = "bdc_negativacoes_quod_pf"
    request_delay = 1.0

    def consultar_cpf(self, cpf: str, nome: str | None = None, **_) -> list[dict]:
        if not BDC_ACCESS_TOKEN:
            return []
        cpf11 = re.sub(r"\D", "", str(cpf or ""))
        if len(cpf11) != 11:
            return []
        cpf_fmt = _fmt_cpf(cpf11)
        ciclo = _ciclo_atual()
        result = _post(_DS_NEGATIVACOES_QUOD, cpf11)
        if not result or not _check_disponivel(result, _DS_NEGATIVACOES_QUOD):
            return []
        dados = _parse_restritivos(result)
        if not dados:
            return []
        mudou, hash_novo = _salvar_snapshot(cpf_fmt, self.fonte, ciclo, dados)
        if not mudou:
            return []
        upsert("sub_snapshots", [{"cpf": cpf_fmt, "fonte": self.fonte, "ciclo": ciclo,
                                   "hash_dados": hash_novo, "dados": {"registros": dados}}])
        return [_build_alerta(cpf_fmt, ciclo, d, self.fonte) for d in dados]

    def resumo_pf(self, cpf: str, nome: str | None = None) -> dict | None:
        if not BDC_ACCESS_TOKEN:
            return {"fonte": self.fonte, "categoria": "financeiro", "status": "pendente",
                    "titulo_secao": "Negativações (Serasa/SPC/Quod)", "resumo": "Token BDC não configurado", "detalhes": {}}
        cpf11 = re.sub(r"\D", "", str(cpf or ""))
        if len(cpf11) != 11:
            return None
        result = _post(_DS_NEGATIVACOES_QUOD, cpf11)
        if not result or not _check_disponivel(result, _DS_NEGATIVACOES_QUOD):
            return {"fonte": self.fonte, "categoria": "financeiro", "status": "pendente",
                    "titulo_secao": "Negativações (Serasa/SPC/Quod)", "resumo": "Dataset não habilitado no plano", "detalhes": {}}
        dados = _parse_restritivos(result)
        n = sum(d.get("total", 0) for d in dados)
        valor = sum(d.get("valor_total", 0) for d in dados)
        if n == 0:
            return {"fonte": self.fonte, "categoria": "financeiro", "status": "limpo",
                    "titulo_secao": "Negativações (Serasa/SPC/Quod)",
                    "resumo": "Nenhuma negativação encontrada", "detalhes": {"total": 0}}
        resumo_txt = f"{n} negativação(ões)"
        if valor:
            resumo_txt += f" — R$ {valor:,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")
        return {"fonte": self.fonte, "categoria": "financeiro", "status": "alerta",
                "titulo_secao": "Negativações (Serasa/SPC/Quod)",
                "resumo": resumo_txt, "detalhes": {"total": n, "valor_total": valor, "registros": dados}}


class BDCScoreQuodPFConnectorV2(SubradarSource):
    """Score de Crédito Quod PF (300-1000) — BigDataCorp Marketplace."""
    fonte = "bdc_score_quod_pf_v2"
    request_delay = 1.0

    def consultar_cpf(self, cpf: str, nome: str | None = None, **_) -> list[dict]:
        if not BDC_ACCESS_TOKEN:
            return []
        cpf11 = re.sub(r"\D", "", str(cpf or ""))
        if len(cpf11) != 11:
            return []
        cpf_fmt = _fmt_cpf(cpf11)
        ciclo = _ciclo_atual()
        result = _post(_DS_SCORE_QUOD, cpf11)
        if not result or not _check_disponivel(result, _DS_SCORE_QUOD):
            return []
        dado = _parse_score_quod(result)
        if not dado:
            return []
        mudou, hash_novo = _salvar_snapshot(cpf_fmt, self.fonte, ciclo, dado)
        if not mudou:
            return []
        upsert("sub_snapshots", [{"cpf": cpf_fmt, "fonte": self.fonte, "ciclo": ciclo,
                                   "hash_dados": hash_novo, "dados": dado}])
        return [_build_alerta(cpf_fmt, ciclo, dado, self.fonte)]

    def resumo_pf(self, cpf: str, nome: str | None = None) -> dict | None:
        if not BDC_ACCESS_TOKEN:
            return {"fonte": self.fonte, "categoria": "financeiro", "status": "pendente",
                    "titulo_secao": "Score de Crédito Quod (300–1000)", "resumo": "Token BDC não configurado", "detalhes": {}}
        cpf11 = re.sub(r"\D", "", str(cpf or ""))
        if len(cpf11) != 11:
            return None
        result = _post(_DS_SCORE_QUOD, cpf11)
        if not result or not _check_disponivel(result, _DS_SCORE_QUOD):
            return {"fonte": self.fonte, "categoria": "financeiro", "status": "pendente",
                    "titulo_secao": "Score de Crédito Quod (300–1000)", "resumo": "Dataset não habilitado", "detalhes": {}}
        dado = _parse_score_quod(result)
        if not dado:
            return {"fonte": self.fonte, "categoria": "financeiro", "status": "pendente",
                    "titulo_secao": "Score de Crédito Quod (300–1000)", "resumo": "Sem dados disponíveis", "detalhes": {}}
        score = dado["score"]
        faixa = dado["faixa"].replace("_", " ")
        return {"fonte": self.fonte, "categoria": "financeiro",
                "status": "alerta" if score < _SCORE_ATENCAO else "limpo",
                "titulo_secao": "Score de Crédito Quod (300–1000)",
                "resumo": f"{score} — {faixa}",
                "detalhes": dado}
