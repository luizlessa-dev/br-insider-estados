"""
USASpending.gov — Contratos e Grants Federais dos EUA
Fonte: api.usaspending.gov (REST público, sem autenticação)

Documentação: https://api.usaspending.gov/docs/endpoints

Endpoints usados:
  POST /api/v2/search/spending_by_award/       → contratos e grants por período
  GET  /api/v2/references/toptier_agencies/    → agências federais
  GET  /api/v2/awards/{generated_id}/          → detalhe de um contrato
  GET  /api/v2/awards/{generated_id}/subawards/→ transações individuais (aditivos)

Schema Supabase: usa_* (isolado, não colide com tabelas federais BR)

Uso editorial:
  Comparar opacidade/detalhe dos contratos EUA × Brasil, cruzar CNPJs de
  empresas brasileiras que operam nos EUA, mostrar metodologia de accountability
  que o governo BR ainda não adota.
"""
from __future__ import annotations

import logging
import time
from dataclasses import dataclass, field
from datetime import date
from typing import Optional

import requests

logger = logging.getLogger("usa_spending")

BASE_URL = "https://api.usaspending.gov/api/v2"
USER_AGENT = "BRInsider/1.0 (pesquisa jornalística; contato@thebrinsider.com)"

# Limite de publicação obrigatória (Federal Acquisition Regulation)
FAR_THRESHOLD_USD = 10_000

# Tamanho de página da API (máx aceito: 100)
PAGE_SIZE = 100


# ── Modelos ──────────────────────────────────────────────────────────────────

@dataclass
class USAContrato:
    award_id: str                        # ID canônico USASpending
    tipo: str                            # "contract" | "grant" | "loan" | "direct_payment"
    agencia_codigo: Optional[str]
    agencia_nome: Optional[str]
    subagencia_nome: Optional[str]
    beneficiario_nome: Optional[str]
    beneficiario_uei: Optional[str]      # Unique Entity Identifier (substituiu DUNS)
    beneficiario_estado: Optional[str]
    valor_obrigado_usd: Optional[float]
    valor_potencial_usd: Optional[float]
    data_inicio: Optional[date]
    data_fim: Optional[date]
    data_assinatura: Optional[date]
    descricao: Optional[str]
    naics_code: Optional[str]            # setor econômico
    naics_descricao: Optional[str]
    lugar_execucao_estado: Optional[str]
    lugar_execucao_pais: Optional[str]
    permalink: Optional[str]
    raw: dict = field(default_factory=dict, repr=False)


@dataclass
class USAAgencia:
    codigo: str
    nome: str
    abreviacao: Optional[str]
    ativo: bool
    total_obrigacoes_usd: Optional[float]


# ── Sessão HTTP ───────────────────────────────────────────────────────────────

def _session() -> requests.Session:
    s = requests.Session()
    s.headers.update({"User-Agent": USER_AGENT, "Content-Type": "application/json"})
    return s


# ── Busca de contratos/grants ─────────────────────────────────────────────────

def buscar_contratos(
    data_inicio: date,
    data_fim: date,
    tipos: list[str] | None = None,
    agencia_codigo: str | None = None,
    valor_minimo_usd: float = FAR_THRESHOLD_USD,
    max_paginas: int = 50,
) -> list[USAContrato]:
    """
    Busca awards (contratos + grants) no período informado.

    tipos: lista de "contract", "grant" — buscados em chamadas separadas
           (a API exige que award_type_codes seja de um único grupo)
    agencia_codigo: filtrar por agência (ex: "097" = Departamento de Defesa)
    """
    if tipos is None:
        tipos = ["contract", "grant"]

    resultados: list[USAContrato] = []
    for tipo in tipos:
        resultados.extend(_buscar_por_grupo(
            tipo, data_inicio, data_fim, agencia_codigo, valor_minimo_usd, max_paginas
        ))
    logger.info("USASpending: %d awards carregados (%s → %s)", len(resultados), data_inicio, data_fim)
    return resultados


def _buscar_por_grupo(
    tipo: str,
    data_inicio: date,
    data_fim: date,
    agencia_codigo: str | None,
    valor_minimo_usd: float,
    max_paginas: int,
) -> list[USAContrato]:
    """Busca um único grupo de award_type_codes (contratos OU grants, nunca misturado)."""
    codigos = _tipos_para_codigos([tipo])
    if not codigos:
        return []

    s = _session()
    resultados: list[USAContrato] = []

    filters: dict = {
        "time_period": [{"start_date": data_inicio.isoformat(), "end_date": data_fim.isoformat()}],
        "award_type_codes": codigos,
    }
    # Nota: a API rejeita 'agencies' junto com 'award_type_codes' (422).
    # Filtro de agência é aplicado no lado cliente após o fetch.

    fields = [
        "Award ID", "Recipient Name", "recipient_uei",
        "Awarding Agency", "Awarding Sub Agency",
        "Award Amount", "Total Outlays",
        "Start Date", "End Date", "Last Modified Date",
        "Description", "NAICS Code", "NAICS Description",
        "Place of Performance State Code", "Place of Performance Country Code",
        "generated_internal_id",
    ]

    for page in range(1, max_paginas + 1):
        payload = {
            "filters": filters,
            "fields": fields,
            "page": page,
            "limit": PAGE_SIZE,
            "sort": "Award Amount",
            "order": "desc",
        }

        try:
            r = s.post(f"{BASE_URL}/search/spending_by_award/", json=payload, timeout=30)
            r.raise_for_status()
            data = r.json()
        except Exception as e:
            logger.warning("USASpending [%s]: erro na página %d: %s", tipo, page, e)
            break

        itens = data.get("results", [])
        if not itens:
            break

        for item in itens:
            valor = item.get("Award Amount") or 0
            if valor < valor_minimo_usd:
                continue

            resultados.append(USAContrato(
                award_id=item.get("Award ID") or item.get("generated_internal_id", ""),
                tipo=tipo,
                agencia_codigo=None,  # preenchido via join com usa_agencias por nome
                agencia_nome=item.get("Awarding Agency"),
                subagencia_nome=item.get("Awarding Sub Agency"),
                beneficiario_nome=item.get("Recipient Name"),
                beneficiario_uei=item.get("recipient_uei"),
                beneficiario_estado=None,
                valor_obrigado_usd=float(valor) if valor else None,
                valor_potencial_usd=float(item.get("Total Outlays") or 0) or None,
                data_inicio=_parse_date(item.get("Start Date")),
                data_fim=_parse_date(item.get("End Date")),
                data_assinatura=_parse_date(item.get("Last Modified Date")),
                descricao=item.get("Description"),
                naics_code=str(item.get("NAICS Code")) if item.get("NAICS Code") else None,
                naics_descricao=item.get("NAICS Description"),
                lugar_execucao_estado=item.get("Place of Performance State Code"),
                lugar_execucao_pais=item.get("Place of Performance Country Code"),
                permalink=f"https://www.usaspending.gov/award/{item.get('generated_internal_id', '')}",
                raw=item,
            ))

        if len(itens) < PAGE_SIZE:
            break

        time.sleep(0.3)

    logger.info("USASpending [%s]: %d awards", tipo, len(resultados))
    return resultados


# ── Agências ──────────────────────────────────────────────────────────────────

def listar_agencias() -> list[USAAgencia]:
    """Retorna todas as agências federais com código e nome."""
    s = _session()
    try:
        r = s.get(f"{BASE_URL}/references/toptier_agencies/", timeout=30)
        r.raise_for_status()
        data = r.json()
    except Exception as e:
        logger.error("USASpending: erro ao listar agências: %s", e)
        return []

    agencias = []
    for item in data.get("results", []):
        agencias.append(USAAgencia(
            codigo=item.get("toptier_code", ""),
            nome=item.get("agency_name", ""),
            abreviacao=item.get("abbreviation"),
            ativo=item.get("active", True),
            total_obrigacoes_usd=item.get("obligated_amount"),
        ))
    return agencias


# ── Helpers ───────────────────────────────────────────────────────────────────

def _tipos_para_codigos(tipos: list[str]) -> list[str]:
    """Mapeia nomes legíveis para os códigos de award_type da API."""
    mapa = {
        "contract": ["A", "B", "C", "D"],
        "grant": ["02", "03", "04", "05"],
        "loan": ["07", "08"],
        "direct_payment": ["06", "10"],
        "other": ["09", "11"],
    }
    codigos = []
    for t in tipos:
        codigos.extend(mapa.get(t, []))
    return codigos


def _codigo_para_tipo(award_id: str) -> str:
    """Infere o tipo pelo prefixo do Award ID (convenção USASpending)."""
    pid = award_id.upper()
    if pid.startswith("CONT_"):
        return "contract"
    if pid.startswith("ASST_"):
        return "grant"
    return "other"


def _parse_date(val: str | None) -> Optional[date]:
    if not val:
        return None
    try:
        from datetime import datetime
        return datetime.strptime(val[:10], "%Y-%m-%d").date()
    except ValueError:
        return None


# ── Transações individuais (aditivos / modificações) ─────────────────────────

@dataclass
class USATransacao:
    transacao_id: str           # id único da transação
    award_id: str               # FK → usa_contratos.award_id
    tipo_acao: Optional[str]    # "NEW", "CONTINUATION", "REVISION", etc.
    data_acao: Optional[date]
    valor_federal_usd: Optional[float]
    valor_nao_federal_usd: Optional[float]
    descricao: Optional[str]
    agencia_nome: Optional[str]
    beneficiario_nome: Optional[str]
    lugar_execucao_pais: Optional[str]
    lugar_execucao_estado: Optional[str]
    raw: dict = field(default_factory=dict, repr=False)


def buscar_transacoes(generated_internal_id: str, max_paginas: int = 20) -> list[USATransacao]:
    """
    Busca todas as transações (modificações/aditivos) de um contrato específico.

    generated_internal_id: campo 'generated_internal_id' do contrato, ex:
        CONT_AWD_NAS1510110_8000_-NONE-_-NONE-

    Endpoint: GET /api/v2/transactions/?award_id=<id>&page=<n>&limit=100
    """
    s = _session()
    resultados: list[USATransacao] = []

    for page in range(1, max_paginas + 1):
        try:
            r = s.post(
                f"{BASE_URL}/transactions/",
                json={"award_id": generated_internal_id, "page": page, "limit": PAGE_SIZE},
                timeout=30,
            )
            r.raise_for_status()
            data = r.json()
        except Exception as e:
            logger.warning("USASpending transações [%s] p%d: %s", generated_internal_id, page, e)
            break

        itens = data.get("results", [])
        if not itens:
            break

        for item in itens:
            resultados.append(USATransacao(
                transacao_id=str(item.get("id", "")),
                award_id=generated_internal_id,
                tipo_acao=item.get("type") or item.get("action_type"),
                data_acao=_parse_date(item.get("action_date")),
                valor_federal_usd=_parse_float(item.get("federal_action_obligation")),
                valor_nao_federal_usd=_parse_float(item.get("non_federal_funding_amount")),
                descricao=item.get("description"),
                agencia_nome=item.get("awarding_agency", {}).get("toptier_agency", {}).get("name") if isinstance(item.get("awarding_agency"), dict) else None,
                beneficiario_nome=item.get("recipient", {}).get("recipient_name") if isinstance(item.get("recipient"), dict) else None,
                lugar_execucao_pais=item.get("place_of_performance", {}).get("country_name") if isinstance(item.get("place_of_performance"), dict) else None,
                lugar_execucao_estado=item.get("place_of_performance", {}).get("state_code") if isinstance(item.get("place_of_performance"), dict) else None,
                raw=item,
            ))

        if len(itens) < PAGE_SIZE:
            break

        time.sleep(0.3)

    logger.info("USASpending: %d transações para %s", len(resultados), generated_internal_id)
    return resultados


def _parse_float(val) -> Optional[float]:
    if val is None:
        return None
    try:
        return float(val)
    except (TypeError, ValueError):
        return None
