"""
Conector: BigDataCorp — Negativações, Dados Financeiros e Processos Judiciais PJ/PF

Cobre o gap de "consulta básica de crédito" (negativações SPC/Serasa) que os
conectores públicos não proveem:

  negative_data    — restrições/negativações em bureaus (SPC, Serasa, Boa Vista)
  financial_data   — dados financeiros consolidados (faturamento estimado, crédito)
  process_data     — processos judiciais (PJ: via /empresas; PF: via /pessoas)

Endpoints:
  PJ — POST https://plataforma.bigdatacorp.com.br/empresas  (query: doc{CNPJ14})
  PF — POST https://plataforma.bigdatacorp.com.br/pessoas   (query: doc{CPF11})

Retorno -109 = dataset não está no plano → ativar via portal ou Customer Success.
Retorno -114 = dataset ativo mas sem dados para este documento (ok).

Auth: headers TokenId + AccessToken (não vai no body).

Env vars (compartilhadas com bigdatacorp.py):
  BIGDATA_CORP_TOKEN_ID    — header TokenId
  BIGDATA_CORP_ACCESS_TOKEN — header AccessToken

Custo: incluso no plano BDC após liberação dos datasets.
"""
from __future__ import annotations

import logging
import os
import re

import requests

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.bigdatacorp_negativacoes")

BDC_TOKEN_ID     = os.environ.get("BIGDATA_CORP_TOKEN_ID", "") or os.environ.get("BIGDATA_CORP_TOKEN", "")
BDC_ACCESS_TOKEN = os.environ.get("BIGDATA_CORP_ACCESS_TOKEN", "") or os.environ.get("BIGDATA_CORP_TOKEN", "")

_BASE_EMPRESAS = "https://plataforma.bigdatacorp.com.br/empresas"
_BASE_PESSOAS  = "https://plataforma.bigdatacorp.com.br/pessoas"

# Datasets a ativar no portal BDC
_DS_NEGATIVE  = "negative_data"
_DS_FINANCIAL = "financial_data"
# "process_data" responde -109 (fora do plano). O dataset liberado chama-se
# "processes" e devolve o bloco "Processes". Confirmado por sondagem em 27/08/2026.
_DS_PROCESS   = "processes"
_DS_VINCULOS  = "business_relationships"
_DS_KYC       = "kyc"


def _headers() -> dict:
    return {
        "accept": "application/json",
        "content-type": "application/json",
        "TokenId": BDC_TOKEN_ID,
        "AccessToken": BDC_ACCESS_TOKEN,
    }


def _post_bdc(base_url: str, datasets: str, doc_digits: str) -> dict | None:
    """POST genérico para qualquer endpoint BDC — retorna primeiro Result ou None."""
    payload = {
        "Datasets": datasets,
        "q": f"doc{{{doc_digits}}}",
        "Limit": 1,
    }
    try:
        resp = requests.post(base_url, json=payload, headers=_headers(), timeout=30)
        if resp.status_code == 401:
            logger.error("BigDataCorp Neg.: token inválido (HTTP 401)")
            return None
        resp.raise_for_status()
        results = resp.json().get("Result", [])
        return results[0] if results else {}
    except Exception as e:
        logger.error("BigDataCorp Neg.: erro em %s: %s", base_url, e)
        return None


def _consulta_pf(dataset: str, bloco: str, cpf11: str) -> tuple[str, dict]:
    """Consulta um dataset PF e classifica o desfecho.

    Devolve (estado, dados) com estado em {"ok", "falha", "fora_do_plano"}.
    Sem essa distinção, erro de rede, token recusado e dataset fora do contrato
    viravam dado vazio — e dado vazio virava "nada consta" no laudo.
    """
    if not BDC_ACCESS_TOKEN or not BDC_TOKEN_ID:
        return "falha", {}
    result = _post_bdc(_BASE_PESSOAS, dataset, cpf11)
    if result is None:
        return "falha", {}
    dados = result.get(bloco) or {}
    if isinstance(dados, dict) and (dados.get("Code") or dados.get("code")) == -109:
        logger.warning("BigDataCorp: dataset '%s' fora do plano (-109)", dataset)
        return "fora_do_plano", {}
    return "ok", dados


def dados_cadastrais_pf(cpf11: str) -> dict:
    """Nome, data de nascimento e nome da mãe do CPF, via basic_data.

    A emissão de certidões oficiais (antecedentes da PF, por exemplo) exige
    esses campos e o formulário do Subradar só coleta CPF e nome. Buscar aqui
    evita pedir mais dados ao cliente.
    """
    estado, d = _consulta_pf("basic_data", "BasicData", cpf11)
    if estado != "ok" or not d:
        return {}
    nasc = (d.get("BirthDate") or "")[:10]
    return {
        "nome": d.get("Name") or "",
        "nascimento": nasc,
        "nome_mae": d.get("MotherName") or "",
        "situacao": d.get("TaxIdStatus") or "",
    }


def _pendencia(fonte: str, categoria: str, titulo: str, motivo: str) -> dict:
    return {
        "fonte": fonte, "categoria": categoria, "status": "pendente",
        "titulo_secao": titulo,
        "resumo": f"Não foi possível consultar — {motivo}",
        "detalhes": {},
    }


def _dataset_ativo(result: dict, dataset_key: str) -> bool:
    """Retorna True se o dataset está presente e não retornou código de erro -109."""
    data = result.get(dataset_key) or {}
    code = data.get("Code") or data.get("code")
    if code == -109:
        logger.warning(
            "BigDataCorp: dataset '%s' não está no plano (-109). "
            "Liberar via portal center.bigdatacorp.com.br ou e-mail suporte.",
            dataset_key,
        )
        return False
    return True


# ─────────────────────────────────────────────────────────────
# Parsers
# ─────────────────────────────────────────────────────────────

def _parse_negativacoes(result: dict, dataset_key: str) -> list[dict]:
    """Extrai registros de negativações/restrições do resultado BDC."""
    data = result.get(dataset_key) or {}
    if not data or not _dataset_ativo(result, dataset_key):
        return []

    # Estrutura BDC varia; tentamos múltiplas chaves comuns
    registros = (
        data.get("Negativacoes") or
        data.get("Restricoes") or
        data.get("Ocorrencias") or
        data.get("Items") or
        []
    )
    total = (
        data.get("TotalNegativacoes") or
        data.get("TotalRestricoes") or
        data.get("TotalOcorrencias") or
        len(registros)
    )
    valor_total = data.get("ValorTotal") or sum(
        float(re.sub(r"[^\d\.]", "", str(r.get("Valor") or 0)) or 0)
        for r in registros
    )

    if not total:
        return []

    return [{
        "tipo": "negativacao",
        "total": total,
        "valor_total": valor_total,
        "amostra": registros[:5],
        "_severidade": "critico" if total > 5 or valor_total > 10_000 else "atencao",
    }]


def _parse_financeiro(result: dict, dataset_key: str) -> list[dict]:
    """Extrai indicadores financeiros relevantes para compliance."""
    data = result.get(dataset_key) or {}
    if not data or not _dataset_ativo(result, dataset_key):
        return []

    faturamento = (
        data.get("FaturamentoEstimado") or
        data.get("Faturamento") or
        data.get("ReceitaEstimada")
    )
    score_financeiro = (
        data.get("ScoreFinanceiro") or
        data.get("Score")
    )
    risco = data.get("ClassificacaoRisco") or data.get("Risco") or ""

    if not any([faturamento, score_financeiro, risco]):
        return []

    severidade = "info"
    if risco and risco.lower() in ("alto", "muito alto", "critico"):
        severidade = "atencao"

    return [{
        "tipo": "financeiro",
        "faturamento_estimado": faturamento,
        "score_financeiro": score_financeiro,
        "classificacao_risco": risco,
        "_severidade": severidade,
    }]


def _parse_processos(result: dict, dataset_key: str) -> list[dict]:
    """Extrai processos judiciais do resultado BDC."""
    data = result.get(dataset_key) or {}
    if not data or not _dataset_ativo(result, dataset_key):
        return []

    processos = (
        data.get("Processos") or
        data.get("Lawsuits") or
        data.get("Items") or
        []
    )
    total = (
        data.get("TotalProcessos") or
        data.get("TotalLawsuits") or
        data.get("Total") or
        len(processos)
    )
    valor_total = data.get("ValorTotal") or 0

    if not total:
        return []

    return [{
        "tipo": "processo_judicial",
        "total": total,
        "valor_total": valor_total,
        "amostra": processos[:5],
        "_severidade": "critico" if total > 10 or valor_total > 100_000 else "atencao",
    }]


# ─────────────────────────────────────────────────────────────
# Builder de alerta
# ─────────────────────────────────────────────────────────────

def _build_alerta(doc_fmt: str, ciclo: str, dado: dict, fonte: str) -> dict:
    tipo = dado.get("tipo", "desconhecido")
    sev  = dado.get("_severidade", "info")

    if tipo == "negativacao":
        total = dado["total"]
        valor = dado["valor_total"]
        titulo = f"Negativações/restrições — {total} ocorrência(s)"
        descricao = (
            f"Documento com {total} negativação(ões)/restrição(ões) registrada(s) "
            f"em bureaus de crédito (SPC/Serasa/Boa Vista) via BigDataCorp."
            + (f" Valor total: R$ {valor:,.2f}." if valor else "")
        )
        categoria = "credito"

    elif tipo == "financeiro":
        fat = dado.get("faturamento_estimado")
        risco = dado.get("classificacao_risco") or "-"
        titulo = f"Indicadores financeiros — risco {risco}"
        descricao = (
            f"Dados financeiros via BigDataCorp: classificação de risco '{risco}'."
            + (f" Faturamento estimado: R$ {fat:,.0f}." if fat else "")
        )
        categoria = "credito"

    elif tipo == "processo_judicial":
        total = dado["total"]
        valor = dado["valor_total"]
        titulo = f"Processos judiciais — {total} registro(s)"
        descricao = (
            f"Documento com {total} processo(s) judicial(is) registrado(s) via BigDataCorp."
            + (f" Valor total envolvido: R$ {valor:,.2f}." if valor else "")
        )
        categoria = "juridico"

    else:
        titulo = f"BigDataCorp — {tipo}"
        descricao = str(dado)
        categoria = "credito"

    return {
        "doc": doc_fmt,
        "ciclo": ciclo,
        "fonte": fonte,
        "categoria": categoria,
        "severidade": sev,
        "titulo": titulo,
        "descricao": descricao,
        "url_fonte": "https://bigdatacorp.com.br",
        "is_novo": True,
    }


# ─────────────────────────────────────────────────────────────
# Conectores PJ
# ─────────────────────────────────────────────────────────────

class BDCNegativacoesPJConnector(SubradarSource):
    """
    Negativações/restrições em bureaus de crédito para PJ via BigDataCorp.
    Dataset: negative_data (endpoint /empresas).
    Ativar via portal center.bigdatacorp.com.br se retornar -109.
    """
    fonte = "bdc_negativacoes_pj"
    request_delay = 1.0

    def consultar_cnpj(self, cnpj: str, razao_social: str | None = None, **_) -> list[dict]:
        if not BDC_ACCESS_TOKEN:
            logger.debug("BDCNegativacoesPJ: token não configurado — pulando")
            return []

        cnpj14 = re.sub(r"\D", "", str(cnpj or ""))
        if len(cnpj14) != 14:
            return []
        cnpj_fmt = f"{cnpj14[:2]}.{cnpj14[2:5]}.{cnpj14[5:8]}/{cnpj14[8:12]}-{cnpj14[12:]}"
        ciclo = _ciclo_atual()

        result = _post_bdc(_BASE_EMPRESAS, _DS_NEGATIVE, cnpj14)
        if result is None:
            return []

        dados = _parse_negativacoes(result, "NegativeData")
        if not dados:
            # tenta chave alternativa CamelCase sem espaço
            dados = _parse_negativacoes(result, "negative_data")
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

        return [_build_alerta(cnpj_fmt, ciclo, d, self.fonte) for d in dados]


class BDCFinanceiroPJConnector(SubradarSource):
    """
    Dados financeiros estimados para PJ via BigDataCorp.
    Dataset: financial_data (endpoint /empresas).
    """
    fonte = "bdc_financeiro_pj"
    request_delay = 1.0

    def consultar_cnpj(self, cnpj: str, **_) -> list[dict]:
        if not BDC_ACCESS_TOKEN:
            return []

        cnpj14 = re.sub(r"\D", "", str(cnpj or ""))
        if len(cnpj14) != 14:
            return []
        cnpj_fmt = f"{cnpj14[:2]}.{cnpj14[2:5]}.{cnpj14[5:8]}/{cnpj14[8:12]}-{cnpj14[12:]}"
        ciclo = _ciclo_atual()

        result = _post_bdc(_BASE_EMPRESAS, _DS_FINANCIAL, cnpj14)
        if result is None:
            return []

        dados = (
            _parse_financeiro(result, "FinancialData")
            or _parse_financeiro(result, "FinantialData")  # typo real na API BDC para PF
            or _parse_financeiro(result, "financial_data")
        )
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

        return [_build_alerta(cnpj_fmt, ciclo, d, self.fonte) for d in dados]


# ─────────────────────────────────────────────────────────────
# Conectores PF
# ─────────────────────────────────────────────────────────────

def _fmt_cpf(cpf11: str) -> str:
    return f"{cpf11[:3]}.{cpf11[3:6]}.{cpf11[6:9]}-{cpf11[9:]}" if len(cpf11) == 11 else cpf11


class BDCNegativacoesPFConnector(SubradarSource):
    """
    Negativações/restrições em bureaus de crédito para PF via BigDataCorp.
    Dataset: negative_data (endpoint /pessoas).
    """
    fonte = "bdc_negativacoes_pf"
    request_delay = 1.0

    def consultar_cpf(self, cpf: str, nome: str | None = None, **_) -> list[dict]:
        if not BDC_ACCESS_TOKEN:
            return []

        cpf11 = re.sub(r"\D", "", str(cpf or ""))
        if len(cpf11) != 11:
            return []
        cpf_fmt = _fmt_cpf(cpf11)
        ciclo = _ciclo_atual()

        result = _post_bdc(_BASE_PESSOAS, _DS_NEGATIVE, cpf11)
        if result is None:
            return []

        dados = _parse_negativacoes(result, "NegativeData") or _parse_negativacoes(result, "negative_data")
        if not dados:
            return []

        mudou, hash_novo = snapshot_changed(cpf_fmt, self.fonte, ciclo, dados)
        if not mudou:
            return []

        # Persiste em sub_pf_dados (tabela específica para PF)
        for d in dados:
            alerta = _build_alerta(cpf_fmt, ciclo, d, self.fonte)
            upsert("sub_pf_dados", [{
                "cpf": cpf_fmt,
                "fonte": self.fonte,
                "ciclo": ciclo,
                "categoria": alerta["categoria"],
                "status": "CRITICO" if alerta["severidade"] == "critico" else "LIMPO",
                "titulo_secao": alerta["titulo"],
                "resumo": alerta["descricao"],
                "detalhes": {"tipo": d.get("tipo"), "dados": d},
            }])

        return [_build_alerta(cpf_fmt, ciclo, d, self.fonte) for d in dados]


class BDCProcessosPFConnector(SubradarSource):
    """
    Processos judiciais para PF via BigDataCorp.
    Dataset: process_data (endpoint /pessoas).
    Confirmado disponível (retornou -114 = sem dados, não -109 = fora do plano).
    """
    fonte = "bdc_processos_pf"
    request_delay = 1.0

    def resumo_pf(self, cpf: str, nome: str | None = None) -> dict | None:
        cpf11 = re.sub(r"\D", "", str(cpf or ""))
        if len(cpf11) != 11:
            return None
        return _resumo_processos_pf(cpf11, self.fonte)

    def consultar_cpf(self, cpf: str, nome: str | None = None, **_) -> list[dict]:
        if not BDC_ACCESS_TOKEN:
            return []

        cpf11 = re.sub(r"\D", "", str(cpf or ""))
        if len(cpf11) != 11:
            return []
        cpf_fmt = _fmt_cpf(cpf11)
        ciclo = _ciclo_atual()

        result = _post_bdc(_BASE_PESSOAS, _DS_PROCESS, cpf11)
        if result is None:
            return []

        dados = _parse_processos(result, "ProcessData") or _parse_processos(result, "process_data")
        if not dados:
            logger.info("BDCProcessosPFConnector: sem dados para %s (result=%s)", cpf_fmt, result)
            return []

        mudou, hash_novo = snapshot_changed(cpf_fmt, self.fonte, ciclo, dados)
        if not mudou:
            return []

        # Persiste em sub_pf_dados (tabela específica para PF)
        for d in dados:
            alerta = _build_alerta(cpf_fmt, ciclo, d, self.fonte)
            upsert("sub_pf_dados", [{
                "cpf": cpf_fmt,
                "fonte": self.fonte,
                "ciclo": ciclo,
                "categoria": alerta["categoria"],
                "status": "CRITICO" if alerta["severidade"] == "critico" else "LIMPO",
                "titulo_secao": alerta["titulo"],
                "resumo": alerta["descricao"],
                "detalhes": {"tipo": d.get("tipo"), "dados": d},
            }])

        return [_build_alerta(cpf_fmt, ciclo, d, self.fonte) for d in dados]


def _classifica_processo(lw: dict) -> str:
    """Severidade de um processo, do ponto de vista de quem vai contratar."""
    tipo_vara = (lw.get("CourtType") or "").upper()
    status = (lw.get("Status") or "").upper()
    encerrado = status in ("ARQUIVADO", "BAIXADO", "EXTINTO")
    if "CRIMINAL" in tipo_vara and not encerrado:
        return "critico"
    if not encerrado:
        return "atencao"
    return "info"


def _resumo_processos_pf(cpf11: str, fonte: str) -> dict:
    estado, d = _consulta_pf(_DS_PROCESS, "Processes", cpf11)
    titulo = "Processos Judiciais"
    if estado == "falha":
        return _pendencia(fonte, "judicial", titulo, "BigDataCorp indisponível")
    if estado == "fora_do_plano":
        return _pendencia(fonte, "judicial", titulo, "dataset de processos fora do plano contratado")

    lawsuits = d.get("Lawsuits") or []
    total = d.get("TotalLawsuits") or len(lawsuits)
    if not total:
        return {
            "fonte": fonte, "categoria": "judicial", "status": "limpo",
            "titulo_secao": titulo, "resumo": "Nenhum processo judicial encontrado",
            "detalhes": {"total": 0},
        }

    sev = [_classifica_processo(lw) for lw in lawsuits]
    ativos = [lw for lw, sv in zip(lawsuits, sev) if sv in ("critico", "atencao")]
    criminais = [lw for lw, sv in zip(lawsuits, sev) if sv == "critico"]

    partes = [f"{total} processo(s)"]
    if d.get("TotalLawsuitsAsDefendant"):
        partes.append(f"{d['TotalLawsuitsAsDefendant']} como réu(ré)")
    if ativos:
        partes.append(f"{len(ativos)} em andamento")
    if criminais:
        partes.append(f"{len(criminais)} criminal(is) em curso")

    return {
        "fonte": fonte, "categoria": "judicial",
        "status": "critico" if criminais else ("alerta" if ativos else "limpo"),
        "titulo_secao": titulo,
        "resumo": " · ".join(partes),
        "detalhes": {
            "total": total,
            "como_autor": d.get("TotalLawsuitsAsAuthor"),
            "como_reu": d.get("TotalLawsuitsAsDefendant"),
            "primeiro": d.get("FirstLawsuitDate"),
            "ultimo": d.get("LastLawsuitDate"),
            "ultimos_365_dias": d.get("Last365DaysLawsuits"),
            "processos": [{
                "numero": lw.get("Number"),
                "tribunal": lw.get("CourtName"),
                "uf": lw.get("State"),
                "vara": lw.get("CourtType"),
                "tipo": lw.get("Type"),
                "assunto": lw.get("MainSubject"),
                "status": lw.get("Status"),
                "severidade": sv,
            } for lw, sv in zip(lawsuits, sev)],
        },
    }


class BDCVinculosPFConnector(SubradarSource):
    """Vínculos societários e empregatícios via BigDataCorp (business_relationships).

    Substitui o QSA reverso, que consultava uma coluna inexistente no Supabase e
    devolvia "nenhuma participação societária" para qualquer CPF.
    """
    fonte = "bdc_vinculos_pf"
    request_delay = 1.0

    def consultar_cpf(self, cpf: str, nome: str | None = None, **_) -> list[dict]:
        return []  # a seção é montada em resumo_pf; alertas saem dos processos

    def resumo_pf(self, cpf: str, nome: str | None = None) -> dict | None:
        cpf11 = re.sub(r"\D", "", str(cpf or ""))
        if len(cpf11) != 11:
            return None
        titulo = "Vínculos Societários e Empregatícios"
        estado, d = _consulta_pf(_DS_VINCULOS, "BusinessRelationships", cpf11)
        if estado == "falha":
            return _pendencia(self.fonte, "societario", titulo, "BigDataCorp indisponível")
        if estado == "fora_do_plano":
            return _pendencia(self.fonte, "societario", titulo, "dataset fora do plano contratado")

        rels = d.get("BusinessRelationships") or []
        socios = d.get("TotalOwnerships") or 0
        partners = d.get("TotalPartners") or 0
        ativos = [r for r in rels if r.get("IsCurrentlyActive")]

        if not rels:
            return {
                "fonte": self.fonte, "categoria": "societario", "status": "limpo",
                "titulo_secao": titulo, "resumo": "Nenhum vínculo societário ou empregatício encontrado",
                "detalhes": {"total": 0},
            }

        partes = [f"{len(rels)} vínculo(s)"]
        if socios or partners:
            partes.append(f"{socios + partners} societário(s)")
        if ativos:
            partes.append(f"{len(ativos)} ativo(s)")

        return {
            "fonte": self.fonte, "categoria": "societario",
            "status": "alerta" if (socios or partners) else "limpo",
            "titulo_secao": titulo,
            "resumo": " · ".join(partes),
            "detalhes": {
                "total": len(rels),
                "societarios": socios + partners,
                "empregos": d.get("TotalEmployments"),
                "vinculos": [{
                    "entidade": r.get("RelatedEntityName"),
                    "documento": r.get("RelatedEntityTaxIdNumber"),
                    "tipo": r.get("RelationshipType"),
                    "ativo": r.get("IsCurrentlyActive"),
                    "inicio": (r.get("RelationshipStartDate") or "")[:10],
                    "fim": (r.get("RelationshipEndDate") or "")[:10],
                } for r in rels],
            },
        }


# Abaixo desse limiar o "match" do KYC é homonímia, não identificação. A busca é
# por nome, então nomes comuns colidem com listas internacionais.
_KYC_MATCH_MINIMO = 85


class BDCKycPFConnector(SubradarSource):
    """PEP e sanções via BigDataCorp (kyc), com limiar de similaridade de nome."""
    fonte = "bdc_kyc_pf"
    request_delay = 1.0

    def consultar_cpf(self, cpf: str, nome: str | None = None, **_) -> list[dict]:
        return []

    def resumo_pf(self, cpf: str, nome: str | None = None) -> dict | None:
        cpf11 = re.sub(r"\D", "", str(cpf or ""))
        if len(cpf11) != 11:
            return None
        titulo = "PEP e Sanções (BigDataCorp)"
        estado, d = _consulta_pf(_DS_KYC, "KycData", cpf11)
        if estado == "falha":
            return _pendencia(self.fonte, "internacional", titulo, "BigDataCorp indisponível")
        if estado == "fora_do_plano":
            return _pendencia(self.fonte, "internacional", titulo, "dataset fora do plano contratado")

        is_pep = bool(d.get("IsCurrentlyPEP"))
        sancionado = bool(d.get("IsCurrentlySanctioned"))
        brutos = d.get("SanctionsHistory") or []
        relevantes = [x for x in brutos if (x.get("MatchRate") or 0) >= _KYC_MATCH_MINIMO]
        descartados = len(brutos) - len(relevantes)

        partes = []
        if is_pep:
            partes.append("Pessoa politicamente exposta")
        if relevantes:
            partes.append(f"{len(relevantes)} correspondência(s) em listas restritivas")
        resumo = " · ".join(partes) if partes else "Não consta como PEP nem em listas restritivas"
        if descartados:
            resumo += f" ({descartados} homônimo(s) descartado(s))"

        return {
            "fonte": self.fonte, "categoria": "internacional",
            "status": "alerta" if (is_pep or sancionado or relevantes) else "limpo",
            "titulo_secao": titulo,
            "resumo": resumo,
            "detalhes": {
                "is_pep": is_pep,
                "sancionado": sancionado,
                "match_minimo": _KYC_MATCH_MINIMO,
                "descartados_por_similaridade": descartados,
                "correspondencias": [{
                    "fonte": x.get("Source"),
                    "tipo": x.get("StandardizedSanctionType"),
                    "match": x.get("MatchRate"),
                } for x in relevantes],
            },
        }


class BDCFinanceiroPFConnector(SubradarSource):
    """
    Dados financeiros para PF via BigDataCorp.
    Dataset: financial_data (endpoint /pessoas).
    """
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

        result = _post_bdc(_BASE_PESSOAS, _DS_FINANCIAL, cpf11)
        if result is None:
            return []

        dados = (
            _parse_financeiro(result, "FinancialData")
            or _parse_financeiro(result, "FinantialData")  # typo real na API BDC para PF
            or _parse_financeiro(result, "financial_data")
        )
        if not dados:
            logger.info("BDCFinanceiroPFConnector: sem dados para %s (result=%s)", cpf_fmt, result)
            return []

        mudou, hash_novo = snapshot_changed(cpf_fmt, self.fonte, ciclo, dados)
        if not mudou:
            return []

        # Persiste em sub_pf_dados (tabela específica para PF)
        for d in dados:
            alerta = _build_alerta(cpf_fmt, ciclo, d, self.fonte)
            upsert("sub_pf_dados", [{
                "cpf": cpf_fmt,
                "fonte": self.fonte,
                "ciclo": ciclo,
                "categoria": alerta["categoria"],
                "status": "CRITICO" if alerta["severidade"] == "critico" else "LIMPO",
                "titulo_secao": alerta["titulo"],
                "resumo": alerta["descricao"],
                "detalhes": {"tipo": d.get("tipo"), "dados": d},
            }])

        return [_build_alerta(cpf_fmt, ciclo, d, self.fonte) for d in dados]
