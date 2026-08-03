"""
Mídia & Política — The BR Insider
===================================
Identifica vínculos entre candidatos/parlamentares e empresas de comunicação.

Três eixos de análise:
  A) Candidatos que RECEBERAM doação de empresas do setor de comunicação (TSE)
  B) Parlamentares que são SÓCIOS de empresas de comunicação (RFB × cnpj_socios)
  C) Empresas de comunicação que aparecem tanto como doadoras (TSE)
     quanto como favorecidas de emendas (duplo vínculo)

Fontes no banco:
  - tse_receitas          → doações de campanha (2022 e 2024)
  - tse_candidatos        → cadastro de candidatos
  - cnpj_socios           → sócios de empresas favorecidas (RFB parcial)
  - cnpj_empresas         → razão social das empresas
  - parlamentares         → deputados federais ativos
  - emendas_favorecidos   → empresas que receberam emendas

CNAEs de comunicação/mídia monitorados:
  6010100  Atividades de rádio
  6021700  Televisão aberta
  6022501  Programadoras
  6022502  TV por assinatura
  7311400  Agências de publicidade
  7312200  Agenciamento de espaços publicitários
  7319099  Outras atividades de publicidade

Saída:
  - dados/midia_politicos_eixo_a.csv  (doações de empresas de mídia)
  - dados/midia_politicos_eixo_b.csv  (parlamentares sócios em mídia)
  - dados/midia_politicos_eixo_c.csv  (emissora doadora + recebe emenda)
  - dados/midia_politicos_sql_hints.sql  (queries investigativas)

Uso:
  python -m ingestao.midia_politicos
  python -m ingestao.midia_politicos --eixo a    # apenas doações
  python -m ingestao.midia_politicos --eixo b    # apenas sócios
  python -m ingestao.midia_politicos --eixo c    # apenas emendas
"""

from __future__ import annotations

import argparse
import csv
import logging
import os
import sys
from datetime import date
from pathlib import Path
from typing import Any

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger(__name__)

DADOS_DIR = Path(__file__).parent.parent / "dados"
DADOS_DIR.mkdir(parents=True, exist_ok=True)

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SUPABASE_KEY = (
    os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    or os.environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY")
    or ""
)

# ── CNAEs de comunicação/mídia ────────────────────────────────────────────────

CNAES_MIDIA = {
    "6010100": "Atividades de rádio",
    "6021700": "Televisão aberta",
    "6022501": "Programadoras",
    "6022502": "TV por assinatura",
    "7311400": "Agências de publicidade",
    "7312200": "Agenciamento de espaços publicitários",
    "7319001": "Criação de estandes p/ feiras",
    "7319002": "Promoção de vendas",
    "7319099": "Outras atividades de publicidade",
    "5911101": "Estúdios cinematográficos",
    "6312200": "Portais/provedores de conteúdo",
}

# Palavras no setor_economico_doador (TSE) que indicam comunicação/mídia
SETORES_MIDIA_TSE = [
    "comunicação",
    "comunicacao",
    "publicidade",
    "propaganda",
    "radiodifusão",
    "radiodifusao",
    "televisão",
    "televisao",
    "rádio",
    "radio",
    "mídia",
    "midia",
    "imprensa",
    "editorial",
    "jornalismo",
]

# ── HTTP ──────────────────────────────────────────────────────────────────────

def _session() -> requests.Session:
    s = requests.Session()
    retry = Retry(total=5, backoff_factor=2, status_forcelist=[429, 500, 502, 503])
    s.mount("https://", HTTPAdapter(max_retries=retry))
    s.headers.update({
        "apikey":        SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type":  "application/json",
    })
    return s

SESSION = _session()


def _rpc(function: str, params: dict) -> list[dict]:
    """Chama uma função RPC do Supabase e retorna a lista de resultados."""
    url = f"{SUPABASE_URL}/rest/v1/rpc/{function}"
    resp = SESSION.post(url, json=params, timeout=120)
    if resp.status_code != 200:
        raise RuntimeError(f"RPC {function} erro {resp.status_code}: {resp.text[:300]}")
    return resp.json() or []


def _query(table: str, select: str, filters: list[str], limit: int = 5000) -> list[dict]:
    """
    GET simples no PostgREST.
    filters: lista de strings no formato "coluna=eq.valor" ou "coluna=ilike.%termo%"
    """
    url = f"{SUPABASE_URL}/rest/v1/{table}"
    params: dict[str, Any] = {"select": select, "limit": limit}
    for f in filters:
        k, v = f.split("=", 1)
        params[k] = v
    resp = SESSION.get(url, params=params, timeout=120)
    if resp.status_code != 200:
        raise RuntimeError(f"Query {table} erro {resp.status_code}: {resp.text[:200]}")
    return resp.json() or []


# ── Eixo A: doações de empresas de mídia ──────────────────────────────────────

EIXO_A_QUERY = """
SELECT
  r.ano_eleicao,
  r.cpf_cnpj_doador               AS cnpj_doador,
  r.nome_doador                   AS nome_empresa_doadora,
  r.setor_economico_doador        AS setor_tse,
  r.nome_candidato,
  r.cargo,
  r.sigla_partido,
  r.uf,
  SUM(r.valor)                    AS total_doado,
  COUNT(*)                        AS n_doacoes,
  c.situacao_turno                AS resultado
FROM tse_receitas r
LEFT JOIN tse_candidatos c
  ON c.cpf = r.cpf_candidato AND c.ano_eleicao = r.ano_eleicao
WHERE
  r.tipo_doador = 'PJ'
  AND (
    r.setor_economico_doador ILIKE '%comunicação%'
    OR r.setor_economico_doador ILIKE '%comunicacao%'
    OR r.setor_economico_doador ILIKE '%publicidade%'
    OR r.setor_economico_doador ILIKE '%radiodifusão%'
    OR r.setor_economico_doador ILIKE '%radiodifusao%'
    OR r.setor_economico_doador ILIKE '%televisão%'
    OR r.setor_economico_doador ILIKE '%televisao%'
    OR r.setor_economico_doador ILIKE '%rádio%'
    OR r.setor_economico_doador ILIKE '%radio%'
    OR r.setor_economico_doador ILIKE '%mídia%'
    OR r.setor_economico_doador ILIKE '%midia%'
    OR r.setor_economico_doador ILIKE '%imprensa%'
    OR r.setor_economico_doador ILIKE '%editorial%'
  )
GROUP BY
  r.ano_eleicao, r.cpf_cnpj_doador, r.nome_doador, r.setor_economico_doador,
  r.nome_candidato, r.cargo, r.sigla_partido, r.uf, c.situacao_turno
ORDER BY total_doado DESC
LIMIT 2000;
"""

EIXO_B_QUERY = """
SELECT
  p.nome                          AS parlamentar,
  p.partido,
  p.uf,
  cs.cnpj_basico,
  ce.razao_social                 AS empresa,
  cs.qualificacao                 AS papel_societario,
  cs.data_entrada,
  ce.porte_empresa
FROM cnpj_socios cs
JOIN parlamentares p
  ON p.cpf = cs.cpf_cnpj_socio
LEFT JOIN cnpj_empresas ce
  ON ce.cnpj_basico = cs.cnpj_basico
WHERE
  length(cs.cpf_cnpj_socio) = 11
  AND (
    ce.razao_social ILIKE '%radio%'
    OR ce.razao_social ILIKE '%rádio%'
    OR ce.razao_social ILIKE '%televisão%'
    OR ce.razao_social ILIKE '%televisao%'
    OR ce.razao_social ILIKE '%comunicações%'
    OR ce.razao_social ILIKE '%comunicacoes%'
    OR ce.razao_social ILIKE '%emissora%'
    OR ce.razao_social ILIKE '%publicidade%'
    OR ce.razao_social ILIKE '%jornal%'
    OR ce.razao_social ILIKE '%revista%'
    OR ce.razao_social ILIKE '%mídia%'
    OR ce.razao_social ILIKE '%midia%'
  )
ORDER BY p.nome;
"""

EIXO_C_QUERY = """
SELECT
  r.cpf_cnpj_doador               AS cnpj,
  r.nome_doador                   AS nome_empresa,
  r.setor_economico_doador        AS setor_tse,
  SUM(r.valor)                    AS total_doado_campanha,
  COUNT(DISTINCT r.nome_candidato) AS n_candidatos_beneficiados,
  ef.valor_recebido               AS total_emendas_recebidas,
  ef.numero_emenda
FROM tse_receitas r
JOIN emendas_favorecidos ef
  ON ef.codigo_favorecido = r.cpf_cnpj_doador
WHERE
  r.tipo_doador = 'PJ'
  AND (
    r.setor_economico_doador ILIKE '%comunicação%'
    OR r.setor_economico_doador ILIKE '%comunicacao%'
    OR r.setor_economico_doador ILIKE '%publicidade%'
    OR r.setor_economico_doador ILIKE '%radiodifusão%'
    OR r.setor_economico_doador ILIKE '%televisão%'
    OR r.setor_economico_doador ILIKE '%televisao%'
    OR r.setor_economico_doador ILIKE '%rádio%'
  )
GROUP BY
  r.cpf_cnpj_doador, r.nome_doador, r.setor_economico_doador,
  ef.valor_recebido, ef.numero_emenda
ORDER BY total_doado_campanha DESC
LIMIT 500;
"""

SQL_HINTS = """\
-- =============================================================================
-- BR Insider — Mídia & Política: queries investigativas
-- Gerado automaticamente por midia_politicos.py
-- =============================================================================

-- EIXO A: empresas de comunicação doadoras × candidatos beneficiados
-- (copiar para Supabase SQL editor ou psql)
{eixo_a}

-- EIXO B: parlamentares ativos que são sócios em empresas de mídia
-- (requer base RFB cnpj_socios populada)
{eixo_b}

-- EIXO C: empresa de comunicação que doa para campanha E recebe emenda
-- do mesmo parlamentar — conflito duplo
{eixo_c}

-- EIXO D (complementar — disponível quando dados MC/ANATEL ingeridos):
-- SELECT a.*, t.nome_candidato, t.cargo
-- FROM anatel_radiodifusao_outorgas a
-- JOIN tse_candidatos t ON a.cpf_cnpj_titular = t.cpf
-- WHERE t.cargo IN ('DEPUTADO FEDERAL', 'SENADOR', 'GOVERNADOR', 'PRESIDENTE')
-- ORDER BY a.uf, a.municipio;
--
-- Para ingerir dados do MC manualmente:
--   1. Acesse https://www.gov.br/mcom (login gov.br)
--   2. Dados abertos > Radiodifusão > Outorgas
--   3. Baixe o CSV e coloque em dados/mc_outorgas_radiodifusao.csv
--   4. Execute: python -m ingestao.midia_politicos --ingerir-mc
"""


def _executar_sql_via_rpc(sql: str) -> list[dict]:
    """
    Executa SQL arbitrário via função RPC exec_sql no Supabase.
    Requer que a função exista. Se não existir, instrui como criar.
    """
    try:
        return _rpc("exec_sql", {"query": sql})
    except RuntimeError as exc:
        if "404" in str(exc) or "not found" in str(exc).lower():
            log.warning(
                "Função RPC exec_sql não encontrada. "
                "Execute no Supabase SQL editor:\n"
                "CREATE OR REPLACE FUNCTION exec_sql(query text)\n"
                "RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$\n"
                "DECLARE result jsonb;\n"
                "BEGIN EXECUTE query INTO result; RETURN result; END;\n"
                "$$;"
            )
        raise


def _query_via_postgrest(sql_label: str, tabela_alvo: str, filtros_or: list[str]) -> list[dict]:
    """
    Executa uma query aproximada via PostgREST usando filtros OR.
    Menos poderoso que SQL puro mas não requer função RPC.
    tabela_alvo: ex. "tse_receitas"
    filtros_or: lista de strings no formato "coluna=ilike.*termo*"
    """
    url = f"{SUPABASE_URL}/rest/v1/{tabela_alvo}"
    # PostgREST suporta OR via ?or=(coluna.ilike.*a*,coluna.ilike.*b*)
    or_clause = ",".join(filtros_or)
    params = {
        "select": "*",
        "or":     f"({or_clause})",
        "limit":  5000,
    }
    resp = SESSION.get(url, params=params, timeout=120)
    if resp.status_code != 200:
        log.error("%s erro %d: %s", sql_label, resp.status_code, resp.text[:200])
        return []
    return resp.json() or []


def executar_eixo_a() -> list[dict]:
    """Doações de empresas de mídia para candidatos."""
    log.info("=== Eixo A: doações de mídia → candidatos ===")

    setor_filtros = [
        f"setor_economico_doador.ilike.*{s}*" for s in [
            "comunicação", "comunicacao", "publicidade",
            "radiodifusão", "radiodifusao", "televisão", "televisao",
            "rádio", "radio", "mídia", "midia", "imprensa",
        ]
    ]

    try:
        rows = _query_via_postgrest("eixo_a", "tse_receitas", setor_filtros)
    except Exception as exc:
        log.error("Eixo A falhou: %s", exc)
        return []

    # Filtrar apenas PJ
    rows = [r for r in rows if r.get("tipo_doador") == "PJ"]
    log.info("Eixo A: %d doações de empresas de comunicação", len(rows))
    return rows


def executar_eixo_b() -> list[dict]:
    """Parlamentares sócios em empresas de mídia (via cnpj_socios × razão social)."""
    log.info("=== Eixo B: parlamentares sócios em empresas de mídia ===")

    nome_filtros = [
        f"razao_social.ilike.*{t}*" for t in [
            "radio", "rádio", "televisão", "televisao", "comunicações",
            "comunicacoes", "emissora", "publicidade", "jornal", "mídia", "midia",
        ]
    ]

    try:
        socios = _query_via_postgrest("eixo_b_socios", "cnpj_socios", [])
        empresas_midia = _query_via_postgrest("eixo_b_empresas", "cnpj_empresas", nome_filtros)
    except Exception as exc:
        log.error("Eixo B falhou: %s", exc)
        return []

    # Cruzar localmente
    cnpjs_midia = {e["cnpj_basico"] for e in empresas_midia}
    socios_midia = [s for s in socios if s.get("cnpj_basico") in cnpjs_midia]
    log.info("Eixo B: %d sócios em empresas de mídia (base RFB parcial)", len(socios_midia))
    return socios_midia


def executar_eixo_c() -> list[dict]:
    """Empresas de comunicação que doam para campanha E recebem emendas."""
    log.info("=== Eixo C: empresa de mídia doadora + favorecida por emenda ===")

    setor_filtros = [
        f"setor_economico_doador.ilike.*{s}*" for s in [
            "comunicação", "comunicacao", "publicidade",
            "radiodifusão", "radiodifusao", "televisão", "televisao",
            "rádio", "radio", "mídia", "midia",
        ]
    ]

    try:
        doadoras = _query_via_postgrest("eixo_c_doadoras", "tse_receitas", setor_filtros)
    except Exception as exc:
        log.error("Eixo C falhou ao buscar doadoras: %s", exc)
        return []

    cnpjs_doadoras = {r["cpf_cnpj_doador"] for r in doadoras if r.get("tipo_doador") == "PJ"}
    if not cnpjs_doadoras:
        log.info("Eixo C: nenhuma empresa de mídia identificada como doadora")
        return []

    log.info("CNPJs doadoras de mídia: %d — verificando recebimento de emendas...", len(cnpjs_doadoras))
    resultados = []
    for cnpj in cnpjs_doadoras:
        try:
            emendas = _query(
                "emendas_favorecidos",
                "codigo_favorecido,valor_recebido,numero_emenda,ano_emenda",
                [f"codigo_favorecido=eq.{cnpj}"],
                limit=100,
            )
            if emendas:
                total_doacoes = sum(
                    r.get("valor", 0) for r in doadoras
                    if r.get("cpf_cnpj_doador") == cnpj
                )
                nome = next(
                    (r.get("nome_doador") for r in doadoras if r.get("cpf_cnpj_doador") == cnpj), ""
                )
                setor = next(
                    (r.get("setor_economico_doador") for r in doadoras if r.get("cpf_cnpj_doador") == cnpj), ""
                )
                for e in emendas:
                    resultados.append({
                        "cnpj":                    cnpj,
                        "nome_empresa":            nome,
                        "setor_tse":               setor,
                        "total_doado_campanha":    total_doacoes,
                        "valor_emenda_recebida":   e.get("valor_recebido", 0),
                        "numero_emenda":           e.get("numero_emenda", ""),
                        "ano_emenda":              e.get("ano_emenda", ""),
                    })
        except Exception:
            pass

    log.info("Eixo C: %d vínculos empresa-de-mídia doadora + recebedora de emenda", len(resultados))
    return resultados


# ── CSV ───────────────────────────────────────────────────────────────────────

def salvar(registros: list[dict], nome: str) -> None:
    if not registros:
        log.warning("Nenhum resultado para %s", nome)
        return
    path = DADOS_DIR / f"midia_politicos_{nome}.csv"
    campos = list(registros[0].keys())
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=campos, extrasaction="ignore")
        w.writeheader()
        w.writerows(registros)
    log.info("Salvo: %s (%d linhas)", path, len(registros))


def salvar_sql_hints() -> None:
    path = DADOS_DIR / "midia_politicos_sql_hints.sql"
    conteudo = SQL_HINTS.format(
        eixo_a=EIXO_A_QUERY,
        eixo_b=EIXO_B_QUERY,
        eixo_c=EIXO_C_QUERY,
    )
    path.write_text(conteudo, encoding="utf-8")
    log.info("SQL hints salvo: %s", path)


# ── Principal ─────────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(description="Mídia & Política — vínculos parlamentares × mídia")
    parser.add_argument("--eixo", choices=["a", "b", "c", "all"], default="all",
                        help="Eixo de análise a executar (padrão: all)")
    args = parser.parse_args()

    if not SUPABASE_URL or not SUPABASE_KEY:
        log.error(
            "SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY não configurados.\n"
            "Exportando apenas SQL hints para execução manual."
        )
        salvar_sql_hints()
        sys.exit(0)

    salvar_sql_hints()
    log.info("SQL hints salvos em dados/midia_politicos_sql_hints.sql")

    if args.eixo in ("a", "all"):
        eixo_a = executar_eixo_a()
        salvar(eixo_a, "eixo_a")

    if args.eixo in ("b", "all"):
        eixo_b = executar_eixo_b()
        salvar(eixo_b, "eixo_b")

    if args.eixo in ("c", "all"):
        eixo_c = executar_eixo_c()
        salvar(eixo_c, "eixo_c")

    print("\n=== Resumo ===")
    print("CSVs gerados em dados/midia_politicos_eixo_*.csv")
    print("SQL queries completas em dados/midia_politicos_sql_hints.sql")
    print()
    print("Próximos passos:")
    print("  1. Execute o SQL em dados/midia_politicos_sql_hints.sql no Supabase SQL editor")
    print("     para resultados mais completos (JOINs não disponíveis via REST)")
    print("  2. Para dados de concessões de radiodifusão (MC):")
    print("     - Acesse https://www.gov.br/mcom (login gov.br necessário)")
    print("     - Dados abertos > Radiodifusão > Outorgas")
    print("     - Baixe o CSV e coloque em dados/mc_outorgas_radiodifusao.csv")
    print("     - Rode: python -m ingestao.midia_politicos_mc (script a criar após download)")


if __name__ == "__main__":
    main()
