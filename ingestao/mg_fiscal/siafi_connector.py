"""
MG SIAFI Connector — The BR Insider
Fonte: Portal de Dados Abertos de MG — dados.mg.gov.br

Dois datasets complementares (verificados via CKAN 2026-06-15):

  portal_despesa_empenho (2022–2026)
    CSV plano com CNPJ do credor direto na linha.
    URL: dados.mg.gov.br/dataset/8a9482f1.../empenho{ano}.csv
    Colunas: ano_de_exercicio; unidade_orcamentaria_*; numero_empenho;
             elemento_despesa_*; fonte_recurso_*; razao_social_credor;
             cnpj_cpf_credor_formatado; valor_despesa_empenhada/liquidada/pago

  dados-armazem-siafi-{ano} (2025–2026)
    CSV.gz com granularidade maior (funcao/subfuncao/programa/acao).
    Usado como complemento quando disponível.

Estratégia: usar portal_despesa_empenho para 2022–2024 (anos sem SIAFI gz),
            e SIAFI gz para 2025–2026 (maior riqueza de campos).
"""
from __future__ import annotations

import csv
import gzip
import io
import logging
import time
from dataclasses import dataclass, field
from datetime import date, datetime
from typing import Iterator, Optional

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

logger = logging.getLogger("mg_fiscal.siafi")

ENCODING  = "utf-8-sig"
DELIMITER = ";"
PAGE_DELAY = 0.3

# Anos 2025-2026: SIAFI gz (maior riqueza de campos)
_SIAFI_RESOURCES: dict[int, dict[str, str]] = {
    2025: {
        "execucao": "https://dados.mg.gov.br/dataset/38c3c647-df4e-48a8-8887-87b7f27be451/resource/3e387b87-a7a2-4f3e-ac6c-ab9b06704a24/download/execucao.csv.gz",
        "credito":  "https://dados.mg.gov.br/dataset/38c3c647-df4e-48a8-8887-87b7f27be451/resource/1ee6a26f-2804-4fe6-817a-1c1dd0e11f2e/download/credito.csv.gz",
        "receita":  "https://dados.mg.gov.br/dataset/38c3c647-df4e-48a8-8887-87b7f27be451/resource/1d7806db-5a31-4a5e-b535-e5f1ed2cbe89/download/receita.csv.gz",
    },
    2026: {
        "execucao": "https://dados.mg.gov.br/dataset/3ac62062-6b32-4623-9298-9bf949a68d04/resource/a6ebbe98-59b6-498f-9e27-106b88995dcf/download/execucao.csv.gz",
        "credito":  "https://dados.mg.gov.br/dataset/3ac62062-6b32-4623-9298-9bf949a68d04/resource/300889f6-903f-45c0-864f-41d6218a35a4/download/credito.csv.gz",
        "receita":  "https://dados.mg.gov.br/dataset/3ac62062-6b32-4623-9298-9bf949a68d04/resource/c5cc5195-d7b5-492c-848f-046c79866c12/download/receita.csv.gz",
    },
}

# Anos 2022-2024: portal_despesa_empenho (CSV plano, CNPJ direto)
_EMPENHO_RESOURCES: dict[int, str] = {
    2022: "https://dados.mg.gov.br/dataset/8a9482f1-8d9e-49bd-8c58-d1574cb2843b/resource/c8757609-bd2e-4864-a75e-f39c72d025f4/download/empenho2022.csv",
    2023: "https://dados.mg.gov.br/dataset/8a9482f1-8d9e-49bd-8c58-d1574cb2843b/resource/ab2a08af-7db8-407a-a4b4-a91e942eef55/download/empenho2023.csv",
    2024: "https://dados.mg.gov.br/dataset/8a9482f1-8d9e-49bd-8c58-d1574cb2843b/resource/38eafdd6-bc1e-4bf9-bc39-bf5842380d6c/download/empenho2024.csv",
}

ANOS_DISPONIVEIS = sorted(list(_EMPENHO_RESOURCES) + list(_SIAFI_RESOURCES))


@dataclass
class ExecucaoSIAFI:
    id: str                                  # {ano}_{numero_empenho}
    ano_exercicio: int
    unidade_orcamentaria_codigo: Optional[str]
    unidade_orcamentaria_nome: Optional[str]
    orgao_codigo: Optional[str]
    orgao_nome: Optional[str]
    funcao_codigo: Optional[str]
    funcao_descricao: Optional[str]
    subfuncao_codigo: Optional[str]
    subfuncao_descricao: Optional[str]
    programa_codigo: Optional[str]
    programa_descricao: Optional[str]
    acao_codigo: Optional[str]
    acao_descricao: Optional[str]
    elemento_despesa_codigo: Optional[str]
    elemento_despesa_descricao: Optional[str]
    fonte_recurso_codigo: Optional[str]
    fonte_recurso_descricao: Optional[str]
    numero_empenho: Optional[str]
    data_empenho: Optional[date]
    razao_social_credor: Optional[str]
    cnpj_cpf_credor: Optional[str]
    valor_empenhado: float = 0.0
    valor_liquidado: float = 0.0
    valor_pago: float = 0.0


def _build_session() -> requests.Session:
    s = requests.Session()
    retry = Retry(total=3, backoff_factor=1.0, status_forcelist=[429, 500, 502, 503, 504])
    s.mount("https://", HTTPAdapter(max_retries=retry))
    s.headers["User-Agent"] = "BRInsider/1.0 (dados@thebrinsider.com)"
    return s


def _parse_float(v: str | None) -> float:
    if not v:
        return 0.0
    try:
        return float(v.replace(",", ".").replace(" ", ""))
    except ValueError:
        return 0.0


def _parse_date(v: str | None) -> Optional[date]:
    if not v:
        return None
    for fmt in ("%Y-%m-%d", "%d/%m/%Y", "%d-%m-%Y"):
        try:
            return datetime.strptime(v[:10], fmt).date()
        except ValueError:
            continue
    return None


def _normalize_cnpj(v: str | None) -> Optional[str]:
    if not v:
        return None
    return "".join(c for c in v if c.isdigit()) or None


def _stream_empenho_plano(ano: int, session: requests.Session) -> Iterator[ExecucaoSIAFI]:
    """Anos 2022-2024: CSV plano do portal_despesa_empenho (sem gz, CNPJ direto)."""
    url = _EMPENHO_RESOURCES[ano]
    logger.info("Baixando empenho plano %d de %s", ano, url)
    resp = session.get(url, stream=True, timeout=120)
    resp.raise_for_status()
    text = resp.content.decode(ENCODING, errors="replace")
    reader = csv.DictReader(io.StringIO(text), delimiter=DELIMITER)
    count = 0
    for row in reader:
        row = {k.strip().lstrip("﻿"): v.strip() for k, v in row.items()}
        num_emp = row.get("numero_empenho", str(count))
        uo = row.get("unidade_orcamentaria_codigo", "")
        rec_id = f"{ano}_{uo}_{num_emp}_{count}"
        yield ExecucaoSIAFI(
            id=rec_id,
            ano_exercicio=ano,
            unidade_orcamentaria_codigo=row.get("unidade_orcamentaria_codigo"),
            unidade_orcamentaria_nome=row.get("unidade_orcamentaria_nome"),
            orgao_codigo=None,
            orgao_nome=None,
            funcao_codigo=None,
            funcao_descricao=None,
            subfuncao_codigo=None,
            subfuncao_descricao=None,
            programa_codigo=None,
            programa_descricao=None,
            acao_codigo=None,
            acao_descricao=None,
            elemento_despesa_codigo=row.get("elemento_despesa_codigo"),
            elemento_despesa_descricao=row.get("elemento_despesa_descricao"),
            fonte_recurso_codigo=row.get("fonte_recurso_codigo"),
            fonte_recurso_descricao=row.get("fonte_recurso_descricao"),
            numero_empenho=num_emp,
            data_empenho=_parse_date(row.get("data_registro_doc_empenho")),
            razao_social_credor=row.get("razao_social_credor"),
            cnpj_cpf_credor=_normalize_cnpj(row.get("cnpj_cpf_credor_formatado")),
            valor_empenhado=_parse_float(row.get("valor_despesa_empenhada")),
            valor_liquidado=_parse_float(row.get("valor_despesa_liquidada")),
            valor_pago=_parse_float(row.get("valor_pago_financeiro")),
        )
        count += 1
        if count % 50000 == 0:
            logger.info("  %d linhas lidas…", count)
    logger.info("Empenho plano %d: %d registros", ano, count)


def stream_execucao(ano: int, session: requests.Session | None = None) -> Iterator[ExecucaoSIAFI]:
    """
    Roteia para a fonte correta conforme o ano:
      2022-2024 → portal_despesa_empenho (CSV plano)
      2025-2026 → dados-armazem-siafi (CSV.gz, mais campos)
    """
    if ano not in ANOS_DISPONIVEIS:
        raise ValueError(f"Ano {ano} não disponível. Use: {ANOS_DISPONIVEIS}")

    sess = session or _build_session()

    if ano in _EMPENHO_RESOURCES:
        yield from _stream_empenho_plano(ano, sess)
        return

    url = _SIAFI_RESOURCES[ano]["execucao"]

    logger.info("Baixando SIAFI execucao %d de %s", ano, url)
    resp = sess.get(url, stream=True, timeout=120)
    resp.raise_for_status()

    raw = b"".join(resp.iter_content(chunk_size=65536))
    decompressed = gzip.decompress(raw)
    text = decompressed.decode(ENCODING, errors="replace")

    reader = csv.DictReader(io.StringIO(text), delimiter=DELIMITER)
    count = 0
    for row in reader:
        # Normaliza chaves removendo BOM e espaços
        row = {k.strip().lstrip("﻿"): v.strip() for k, v in row.items()}

        num_emp = row.get("numero_empenho") or row.get("num_empenho") or str(count)
        uo = row.get("codigo_unidade_orcamentaria") or row.get("cd_unidade_orcamentaria") or ""
        rec_id = f"{ano}_{uo}_{num_emp}_{count}"

        yield ExecucaoSIAFI(
            id=rec_id,
            ano_exercicio=ano,
            unidade_orcamentaria_codigo=row.get("codigo_unidade_orcamentaria") or row.get("cd_unidade_orcamentaria"),
            unidade_orcamentaria_nome=row.get("nome_unidade_orcamentaria") or row.get("nm_unidade_orcamentaria"),
            orgao_codigo=row.get("codigo_orgao") or row.get("cd_orgao"),
            orgao_nome=row.get("nome_orgao") or row.get("nm_orgao"),
            funcao_codigo=row.get("codigo_funcao") or row.get("cd_funcao"),
            funcao_descricao=row.get("descricao_funcao") or row.get("ds_funcao"),
            subfuncao_codigo=row.get("codigo_subfuncao") or row.get("cd_subfuncao"),
            subfuncao_descricao=row.get("descricao_subfuncao") or row.get("ds_subfuncao"),
            programa_codigo=row.get("codigo_programa") or row.get("cd_programa"),
            programa_descricao=row.get("descricao_programa") or row.get("ds_programa"),
            acao_codigo=row.get("codigo_acao") or row.get("cd_acao"),
            acao_descricao=row.get("descricao_acao") or row.get("ds_acao"),
            elemento_despesa_codigo=row.get("codigo_elemento_despesa") or row.get("cd_elemento_despesa"),
            elemento_despesa_descricao=row.get("descricao_elemento_despesa") or row.get("ds_elemento_despesa"),
            fonte_recurso_codigo=row.get("codigo_fonte_recurso") or row.get("cd_fonte_recurso"),
            fonte_recurso_descricao=row.get("descricao_fonte_recurso") or row.get("ds_fonte_recurso"),
            numero_empenho=num_emp,
            data_empenho=_parse_date(row.get("data_empenho") or row.get("dt_empenho")),
            razao_social_credor=row.get("razao_social_credor") or row.get("nm_credor"),
            cnpj_cpf_credor=_normalize_cnpj(row.get("cnpj_cpf_credor") or row.get("nu_cnpj_cpf")),
            valor_empenhado=_parse_float(row.get("valor_empenhado") or row.get("vl_empenhado")),
            valor_liquidado=_parse_float(row.get("valor_liquidado") or row.get("vl_liquidado")),
            valor_pago=_parse_float(row.get("valor_pago") or row.get("vl_pago")),
        )
        count += 1
        if count % 50000 == 0:
            logger.info("  %d linhas lidas…", count)
            time.sleep(PAGE_DELAY)

    logger.info("SIAFI %d: %d registros extraídos", ano, count)
