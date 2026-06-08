"""
Eleições 2026 — conector TSE
Fonte: https://dadosabertos.tse.jus.br/

Datasets:
  candidatos    → ele2026_candidatos
  financiamento → ele2026_financiamento  (receitas de campanha)
  gastos        → ele2026_gastos         (despesas de campanha)

STUB: URLs marcadas como NOT_AVAILABLE_YET.
O TSE libera os dados em datas estimadas:
  candidatos        → agosto 2026    (após prazo de registro: 20/jun–05/ago)
  financiamento     → out/nov 2026   (prestação de contas parcial/final)
  gastos            → out/nov 2026

Quando o TSE liberar, substituir a URL e remover o guard DADOS_DISPONIVEIS.

Relação com o módulo tse/:
  - Mesmo encoding (latin-1), mesmo delimitador (;)
  - Mesmos parsers de data/float/cpf
  - Novos campos em Candidato2026: nome_federacao, sigla_federacao, foto_url
  - Financiamento e Gasto são idênticos a Receita/Despesa do tse/ — reusados via import
  - Lógica extra: ao gravar candidatos, cruza com `parlamentares` por CPF para
    preencher parlamentar_id / id_camara e marcar ele2026_alertas.candidatura_entrou

Cargos cobertos (eleições gerais):
  1 = Presidente / Vice-Presidente
  3 = Governador / Vice-Governador
  5 = Senador
  6 = Deputado Federal
  7 = Deputado Estadual / Distrital
"""
from __future__ import annotations

import csv
import io
import logging
import re
import zipfile
from dataclasses import dataclass
from datetime import date
from typing import Iterator, Optional

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

# Reusa parsers e modelos do módulo tse/ para receitas/despesas — sem duplicação.
from ingestao.tse.connector import (
    Despesa,
    Receita,
    _build_session,          # noqa: F401 — reexportado para persistence.py
    _cpf,
    _csv_reader,
    _download_zip,
    _parse_date,
    _parse_float,
    _select_uf_files,
    iter_despesas as _tse_iter_despesas,
    iter_receitas as _tse_iter_receitas,
)

logger = logging.getLogger("ele2026")

# ─────────────────────────────────────────────────────────────────────────────
# FLAG DE DISPONIBILIDADE
# Mude para True quando o TSE liberar os dados.
# O runner aborta com mensagem clara se False (não falha silenciosamente).
# ─────────────────────────────────────────────────────────────────────────────
DADOS_DISPONIVEIS = False          # candidatos: ~agosto 2026
FINANCIAMENTO_DISPONIVEL = False   # receitas:   ~out/nov 2026
GASTOS_DISPONIVEIS = False         # despesas:   ~out/nov 2026

# ─────────────────────────────────────────────────────────────────────────────
# URLs (NOT_AVAILABLE_YET → substituir pela URL real quando o TSE publicar)
# Padrão histórico confirmado nos dados de 2022/2024:
#   candidatos    → cdn.tse.jus.br/estatistica/sead/odsele/consulta_cand/consulta_cand_<ano>.zip
#   prestação     → cdn.tse.jus.br/estatistica/sead/odsele/prestacao_contas/
#                     prestacao_de_contas_eleitorais_candidatos_<ano>.zip
# ─────────────────────────────────────────────────────────────────────────────
ANO = 2026

URL_CANDIDATOS = (
    "https://cdn.tse.jus.br/estatistica/sead/odsele/consulta_cand/"
    f"consulta_cand_{ANO}.zip"
    # NOT_AVAILABLE_YET — liberado ~agosto 2026
)

URL_PRESTACAO = (
    "https://cdn.tse.jus.br/estatistica/sead/odsele/prestacao_contas/"
    f"prestacao_de_contas_eleitorais_candidatos_{ANO}.zip"
    # NOT_AVAILABLE_YET — liberado ~out/nov 2026
)

CARGOS_GERAIS = {"1", "3", "5", "6", "7"}

ENCODING = "latin-1"
DELIMITER = ";"


# ─────────────────────────────────────────────────────────────────────────────
# Modelo: Candidato2026
# Estende Candidato (tse/) com campos novos do ciclo 2026.
# ─────────────────────────────────────────────────────────────────────────────

@dataclass
class Candidato2026:
    id: str                             # "2026_<sq_candidato>"
    sq_candidato: str
    cpf: Optional[str]
    nome: str
    nome_urna: Optional[str]
    data_nascimento: Optional[date]
    genero: Optional[str]
    cor_raca: Optional[str]
    grau_instrucao: Optional[str]
    ocupacao: Optional[str]
    estado_civil: Optional[str]
    email: Optional[str]
    foto_url: Optional[str]

    cd_cargo: Optional[int]
    cargo: Optional[str]
    uf: Optional[str]
    municipio_nascimento: Optional[str]

    nr_partido: Optional[int]
    sigla_partido: Optional[str]
    nome_partido: Optional[str]

    # Federações partidárias (reintroduzidas em 2022)
    nome_federacao: Optional[str]
    sigla_federacao: Optional[str]

    situacao_candidatura: Optional[str]
    situacao_turno1: Optional[str]      # preenchido pós-apuração 1º turno
    situacao_turno2: Optional[str]      # preenchido pós-apuração 2º turno (se aplicável)
    eleito: Optional[bool]              # None até apuração
    reeleicao: Optional[bool]
    limite_despesa: Optional[float]


# ─────────────────────────────────────────────────────────────────────────────
# Parser: Candidatos 2026
# ─────────────────────────────────────────────────────────────────────────────

def _parse_candidatos_2026(reader: csv.DictReader) -> Iterator[Candidato2026]:
    for row in reader:
        if row.get("CD_CARGO", "").strip() not in CARGOS_GERAIS:
            continue
        sq = row.get("SQ_CANDIDATO", "").strip()
        if not sq:
            continue
        yield Candidato2026(
            id=f"{ANO}_{sq}",
            sq_candidato=sq,
            cpf=_cpf(row.get("NR_CPF_CANDIDATO")),
            nome=row.get("NM_CANDIDATO", "").strip(),
            nome_urna=row.get("NM_URNA_CANDIDATO", "").strip() or None,
            data_nascimento=_parse_date(row.get("DT_NASCIMENTO")),
            genero=row.get("DS_GENERO", "").strip() or None,
            cor_raca=row.get("DS_COR_RACA", "").strip() or None,
            grau_instrucao=row.get("DS_GRAU_INSTRUCAO", "").strip() or None,
            ocupacao=row.get("DS_OCUPACAO", "").strip() or None,
            estado_civil=row.get("DS_ESTADO_CIVIL", "").strip() or None,
            email=row.get("NM_EMAIL", "").strip().lower() or None,
            # Foto: campo NR_CPF_CANDIDATO usado para montar URL pública do TSE
            # https://divulgacandcontas.tse.jus.br/candidaturas/oficial/2026/
            #   <sq_candidato>/foto/<sq_candidato>.jpg
            # (gerado na persistence após confirmar disponibilidade)
            foto_url=None,
            cd_cargo=int(row["CD_CARGO"].strip()),
            cargo=row.get("DS_CARGO", "").strip() or None,
            uf=row.get("SG_UF", "").strip() or None,
            municipio_nascimento=row.get("NM_MUNICIPIO_NASCIMENTO", "").strip() or None,
            nr_partido=int(row["NR_PARTIDO"].strip()) if row.get("NR_PARTIDO", "").strip().isdigit() else None,
            sigla_partido=row.get("SG_PARTIDO", "").strip() or None,
            nome_partido=row.get("NM_PARTIDO", "").strip() or None,
            nome_federacao=row.get("NM_FEDERACAO_PARTIDARIA", "").strip() or None,
            sigla_federacao=row.get("SG_FEDERACAO_PARTIDARIA", "").strip() or None,
            situacao_candidatura=row.get("DS_SITUACAO_CANDIDATURA", "").strip() or None,
            situacao_turno1=row.get("DS_SIT_TOT_TURNO", "").strip() or None,
            situacao_turno2=None,    # preenchido após 2º turno
            eleito=None,             # preenchido após apuração
            reeleicao=row.get("ST_REELEICAO", "").strip().upper() == "S",
            limite_despesa=_parse_float(row.get("VR_DESPESA_MAX_CAMPANHA")),
        )


def get_candidatos_2026() -> list[Candidato2026]:
    """
    Baixa e parseia candidatos das eleições 2026.

    Levanta DataIndisponivel se DADOS_DISPONIVEIS = False.
    Quando o TSE liberar: setar DADOS_DISPONIVEIS = True e confirmar a URL.
    """
    if not DADOS_DISPONIVEIS:
        raise DataIndisponivel(
            "TSE ainda não publicou os dados de candidatos 2026. "
            f"URL prevista: {URL_CANDIDATOS}\n"
            "Quando disponível: setar DADOS_DISPONIVEIS = True em connector.py."
        )

    session = _build_session()
    zf = _download_zip(URL_CANDIDATOS, session)

    # ZIP de candidatos contém um único arquivo BRASIL (sem divisão por UF)
    brasil_files = [n for n in zf.namelist()
                    if re.search(r"BRASIL\.csv$", n, re.IGNORECASE)]
    if not brasil_files:
        brasil_files = [n for n in zf.namelist() if n.endswith(".csv")]

    candidatos: list[Candidato2026] = []
    for fname in brasil_files:
        reader = _csv_reader(zf, fname)
        candidatos.extend(_parse_candidatos_2026(reader))
        logger.info("ele2026 candidatos — %s: %d registros", fname, len(candidatos))

    logger.info("ele2026 candidatos: total %d (cargos gerais)", len(candidatos))
    return candidatos


# ─────────────────────────────────────────────────────────────────────────────
# Financiamento 2026 (≡ Receitas TSE)
# Reusa iter_receitas do tse/ apontando para a URL de 2026.
# ─────────────────────────────────────────────────────────────────────────────

def iter_financiamento_2026() -> Iterator[Receita]:
    """
    Itera receitas de campanha 2026 por UF (streaming, memória baixa).

    Levanta DataIndisponivel se FINANCIAMENTO_DISPONIVEL = False.
    Quando o TSE liberar a prestação de contas: setar FINANCIAMENTO_DISPONIVEL = True.
    """
    if not FINANCIAMENTO_DISPONIVEL:
        raise DataIndisponivel(
            "TSE ainda não publicou os dados de financiamento de campanha 2026. "
            f"URL prevista: {URL_PRESTACAO}\n"
            "Quando disponível: setar FINANCIAMENTO_DISPONIVEL = True em connector.py."
        )

    session = _build_session()
    zf = _download_zip(URL_PRESTACAO, session)
    # Reutiliza o parser de receitas do tse/ — mesmo formato CSV
    yield from _tse_iter_receitas(ANO, zf=zf)


# ─────────────────────────────────────────────────────────────────────────────
# Gastos 2026 (≡ Despesas TSE)
# ─────────────────────────────────────────────────────────────────────────────

def iter_gastos_2026() -> Iterator[Despesa]:
    """
    Itera despesas de campanha 2026 por UF (streaming, memória baixa).

    Levanta DataIndisponivel se GASTOS_DISPONIVEIS = False.
    """
    if not GASTOS_DISPONIVEIS:
        raise DataIndisponivel(
            "TSE ainda não publicou os dados de gastos de campanha 2026. "
            f"URL prevista: {URL_PRESTACAO}\n"
            "Quando disponível: setar GASTOS_DISPONIVEIS = True em connector.py."
        )

    session = _build_session()
    zf = _download_zip(URL_PRESTACAO, session)
    yield from _tse_iter_despesas(ANO, zf=zf)


# ─────────────────────────────────────────────────────────────────────────────
# Exceção própria
# ─────────────────────────────────────────────────────────────────────────────

class DataIndisponivel(RuntimeError):
    """Levantada quando os dados do TSE ainda não foram publicados."""
    pass
