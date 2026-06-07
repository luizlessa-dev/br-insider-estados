"""
PR — Perfil e Diversidade do Pessoal da Presidência da República
The BR Insider

Fonte: dadosabertos.presidencia.gov.br
  Dataset principal: dados-de-pessoal-perfil-e-diversidade-dos-servidores-da-pr
  Vice-Presidência:  perfil-pessoal-diversidade
Formato: CSV (delimitador ; ou ,), encoding UTF-8 ou latin-1.

DOWNLOAD MANUAL OBRIGATÓRIO
  1. Acesse a página do dataset no portal
  2. Baixe os arquivos CSV por período
  3. Salve em data/presidencia/pessoal/

Uso:
  python -m ingestao.presidencia.runner pessoal --pasta data/presidencia/pessoal/
"""
from __future__ import annotations

import csv
import hashlib
import io
import logging
import re
import unicodedata
from pathlib import Path
from typing import Iterator, Optional

logger = logging.getLogger("presidencia.pessoal")

# Mapeamento de nomes de colunas → campo normalizado
COLUNA_MAP = {
    # Órgão
    "orgao": "orgao",
    "unidade": "orgao",
    "sigla": "orgao",
    # Período
    "mes_referencia": "periodo",
    "periodo": "periodo",
    "competencia": "periodo",
    "data_referencia": "periodo",
    # Categoria de vínculo
    "categoria": "categoria_vinculo",
    "vinculo": "categoria_vinculo",
    "tipo_vinculo": "categoria_vinculo",
    "situacao_funcional": "categoria_vinculo",
    # Dimensão
    "genero": "dimensao_valor",
    "sexo": "dimensao_valor",
    "raca_cor": "dimensao_valor",
    "raca": "dimensao_valor",
    "etnia": "dimensao_valor",
    "escolaridade": "dimensao_valor",
    "grau_instrucao": "dimensao_valor",
    "faixa_etaria": "dimensao_valor",
    "pcd": "dimensao_valor",
    "deficiencia": "dimensao_valor",
    # Quantidade
    "quantidade": "quantidade",
    "quantitativo": "quantidade",
    "total": "quantidade",
    "count": "quantidade",
    # Percentual
    "percentual": "percentual",
    "perc": "percentual",
    "porcentagem": "percentual",
}

DIMENSAO_COLUNAS = {
    "genero", "sexo", "raca_cor", "raca", "etnia",
    "escolaridade", "grau_instrucao", "faixa_etaria",
    "pcd", "deficiencia",
}

DIMENSAO_NOME_MAP = {
    "genero": "genero",
    "sexo": "genero",
    "raca_cor": "raca_cor",
    "raca": "raca_cor",
    "etnia": "raca_cor",
    "escolaridade": "escolaridade",
    "grau_instrucao": "escolaridade",
    "faixa_etaria": "faixa_etaria",
    "pcd": "pcd",
    "deficiencia": "pcd",
}


def _normalizar(texto: str) -> str:
    nfkd = unicodedata.normalize("NFKD", texto)
    sem_acento = "".join(c for c in nfkd if not unicodedata.combining(c))
    return re.sub(r"[^a-z0-9_]", "_", sem_acento.lower()).strip("_")


def _inferir_periodo(path: Path) -> str:
    """Infere período YYYY-MM ou YYYY do nome do arquivo."""
    m = re.search(r"(20\d{2})[-_]?(0[1-9]|1[0-2])?", path.name)
    if m:
        ano, mes = m.group(1), m.group(2)
        return f"{ano}-{mes}" if mes else ano
    return "desconhecido"


def _parse_quantidade(v) -> Optional[int]:
    if v is None:
        return None
    try:
        return int(str(v).replace(".", "").replace(",", "").strip())
    except ValueError:
        return None


def _parse_percentual(v) -> Optional[float]:
    if v is None:
        return None
    try:
        return float(str(v).replace(",", ".").replace("%", "").strip())
    except ValueError:
        return None


def _gerar_id(*partes: str) -> str:
    return hashlib.md5("|".join(str(p) for p in partes).encode()).hexdigest()[:16]


def _detectar_encoding(path: Path) -> str:
    try:
        with open(path, "rb") as f:
            raw = f.read(4096)
        raw.decode("utf-8")
        return "utf-8"
    except UnicodeDecodeError:
        return "latin-1"


def _detectar_delimitador(primeira_linha: str) -> str:
    return ";" if primeira_linha.count(";") >= primeira_linha.count(",") else ","


def carregar_arquivo(path: Path) -> list[dict]:
    """
    Lê um CSV de diversidade/pessoal e retorna lista de dicts para upsert.
    O CSV pode estar em formato LARGO (uma coluna por dimensão) ou
    LONGO (uma linha por categoria × valor).
    """
    periodo = _inferir_periodo(path)
    encoding = _detectar_encoding(path)

    with open(path, encoding=encoding, errors="replace") as f:
        primeira_linha = f.readline()
        delimitador = _detectar_delimitador(primeira_linha)
        f.seek(0)
        reader = csv.DictReader(f, delimiter=delimitador)
        rows = list(reader)

    if not rows:
        logger.warning(f"{path.name}: arquivo vazio")
        return []

    # Normalizar nomes de colunas
    header_norm = {col: _normalizar(col) for col in rows[0].keys()}

    # Detecta se é formato LARGO (uma coluna por dimensão demográfica)
    dimensoes_presentes = [
        col for col, norm in header_norm.items()
        if norm in DIMENSAO_COLUNAS
    ]

    registros = []

    if dimensoes_presentes:
        # Formato LARGO: expandir para formato longo (1 linha por dimensão)
        registros.extend(_ler_largo(rows, header_norm, dimensoes_presentes, periodo, path.name))
    else:
        # Formato LONGO: mapear direto
        registros.extend(_ler_longo(rows, header_norm, periodo, path.name))

    logger.info(f"{path.name}: {len(registros)} registros extraídos")
    return registros


def _ler_largo(
    rows: list[dict],
    header_norm: dict[str, str],
    dimensoes_presentes: list[str],
    periodo: str,
    arquivo: str,
) -> Iterator[dict]:
    col_orgao = next((c for c, n in header_norm.items() if n == "orgao"), None)
    col_categoria = next((c for c, n in header_norm.items() if n == "categoria_vinculo"), None)
    col_qtd = next((c for c, n in header_norm.items() if n == "quantidade"), None)
    col_perc = next((c for c, n in header_norm.items() if n == "percentual"), None)

    for row in rows:
        orgao = str(row.get(col_orgao, "")).strip() if col_orgao else "PR"
        categoria = str(row.get(col_categoria, "")).strip() if col_categoria else None

        for col_dim in dimensoes_presentes:
            norm_dim = header_norm[col_dim]
            dimensao = DIMENSAO_NOME_MAP.get(norm_dim, norm_dim)
            valor_dim = str(row.get(col_dim, "")).strip()
            if not valor_dim:
                continue

            qtd = _parse_quantidade(row.get(col_qtd)) if col_qtd else None
            pct = _parse_percentual(row.get(col_perc)) if col_perc else None

            if qtd is None:
                continue

            yield {
                "id": _gerar_id(orgao, periodo, categoria or "", dimensao, valor_dim),
                "orgao": orgao,
                "periodo": periodo,
                "categoria_vinculo": categoria,
                "dimensao": dimensao,
                "valor_dimensao": valor_dim,
                "quantidade": qtd,
                "percentual": pct,
                "arquivo_origem": arquivo,
            }


def _ler_longo(
    rows: list[dict],
    header_norm: dict[str, str],
    periodo: str,
    arquivo: str,
) -> Iterator[dict]:
    col_orgao = next((c for c, n in header_norm.items() if n == "orgao"), None)
    col_categoria = next((c for c, n in header_norm.items() if n == "categoria_vinculo"), None)
    col_dimensao = next((c for c, n in header_norm.items() if "dimensao" in n or "tipo" in n), None)
    col_valor_dim = next(
        (c for c, n in header_norm.items()
         if "valor" in n and "dimensao" in n and "valor_dimensao" != n[:5]),
        None,
    )
    col_qtd = next((c for c, n in header_norm.items() if n == "quantidade"), None)
    col_perc = next((c for c, n in header_norm.items() if n == "percentual"), None)

    for row in rows:
        orgao = str(row.get(col_orgao, "")).strip() if col_orgao else "PR"
        categoria = str(row.get(col_categoria, "")).strip() if col_categoria else None
        dimensao = str(row.get(col_dimensao, "")).strip() if col_dimensao else "desconhecida"
        valor_dim = str(row.get(col_valor_dim, "")).strip() if col_valor_dim else ""
        qtd = _parse_quantidade(row.get(col_qtd)) if col_qtd else None
        pct = _parse_percentual(row.get(col_perc)) if col_perc else None

        if not valor_dim or qtd is None:
            continue

        yield {
            "id": _gerar_id(orgao, periodo, categoria or "", dimensao, valor_dim),
            "orgao": orgao,
            "periodo": periodo,
            "categoria_vinculo": categoria,
            "dimensao": dimensao,
            "valor_dimensao": valor_dim,
            "quantidade": qtd,
            "percentual": pct,
            "arquivo_origem": arquivo,
        }
