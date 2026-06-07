"""
PR — Custos de Ex-Presidentes (Lei nº 7.474/1986)
The BR Insider

Fonte: dadosabertos.presidencia.gov.br/dataset/custo-de-ex-presidentes-da-republica-lei-7474-1986
Formato: XLSX granular do SIC — 1 linha por transação (centro custo × natureza × mês).
Arquivo cobre 2021–2026 (~3.855 linhas).

Colunas do XLSX:
  DH - Ano Emissão | Mês Emissão | Mês Referência |
  Grupo Despesa Código Grupo | Grupo Despesa Nome |
  Natureza Despesa Código | Natureza Despesa Nome |
  Natureza Despesa Detalhada Código | Natureza Despesa Detalhada Nome |
  Centro Custos Código Centro Custos | Centro Custos Nome | Custo - R$

DOWNLOAD MANUAL
  https://dadosabertos.presidencia.gov.br/dataset/custo-de-ex-presidentes-da-republica-lei-7474-1986
  Salvar em: data/presidencia/ex_presidentes/
"""
from __future__ import annotations

import hashlib
import logging
import re
import unicodedata
from pathlib import Path
from typing import Optional

logger = logging.getLogger("presidencia.ex_presidentes")

# Centro de custo → slug canônico
CENTRO_SLUG: dict[str, str] = {
    "EX-PR LULA DA SILVA":      "lula",
    "EX-PR DILMA ROUSSEFF":     "dilma",
    "EX-PR MICHEL TEMER":       "temer",
    "EX-PR JAIR BOLSONARO":     "bolsonaro",
    "EX-PR FERNANDO HENRIQUE":  "fhc",
    "EX-PR FERNANDO COLLOR":    "collor",
    "EX-PR JOSE SARNEY":        "sarney",
    "EX-PR ITAMAR FRANCO":      "itamar",
}


def _slug_de_centro(nome: str) -> str:
    if not nome:
        return "desconhecido"
    nome_upper = nome.strip().upper()
    for chave, slug in CENTRO_SLUG.items():
        if chave in nome_upper:
            return slug
    # fallback: normaliza o próprio nome
    nfkd = unicodedata.normalize("NFKD", nome_upper)
    sem_acento = "".join(c for c in nfkd if not unicodedata.combining(c))
    return re.sub(r"[^A-Z0-9]+", "-", sem_acento).strip("-").lower()[:30]


def _id(row: dict) -> str:
    partes = "|".join(str(row.get(k, "")) for k in [
        "ano_emissao", "mes_emissao", "mes_referencia",
        "natureza_despesa_det_codigo", "centro_custo_codigo", "custo_valor",
    ])
    return hashlib.md5(partes.encode()).hexdigest()


def carregar_arquivo(path: Path) -> list[dict]:
    try:
        import openpyxl
    except ImportError:
        raise ImportError("pip install openpyxl")

    wb = openpyxl.load_workbook(path, data_only=True)
    ws = wb.active

    rows = list(ws.iter_rows(values_only=True))
    if len(rows) < 2:
        logger.warning(f"{path.name}: arquivo vazio")
        return []

    header = [str(c).strip() if c is not None else "" for c in rows[0]]

    # Mapeamento flexível de colunas pelo nome
    col = {}
    for i, h in enumerate(header):
        hl = h.lower()
        if "ano" in hl and "emiss" in hl:
            col["ano_emissao"] = i
        elif "mês emiss" in hl or "mes emiss" in hl:
            col["mes_emissao"] = i
        elif "mês refer" in hl or "mes refer" in hl:
            col["mes_referencia"] = i
        elif "grupo" in hl and "código" in hl:
            col["grupo_despesa_codigo"] = i
        elif "grupo" in hl and "nome" in hl:
            col["grupo_despesa_nome"] = i
        elif "natureza" in hl and "detalhada" in hl and "código" in hl:
            col["natureza_despesa_det_codigo"] = i
        elif "natureza" in hl and "detalhada" in hl and "nome" in hl:
            col["natureza_despesa_det_nome"] = i
        elif "natureza" in hl and "código" in hl:
            col["natureza_despesa_codigo"] = i
        elif "natureza" in hl and "nome" in hl:
            col["natureza_despesa_nome"] = i
        elif "centro" in hl and "código" in hl:
            col["centro_custo_codigo"] = i
        elif "centro" in hl and "nome" in hl:
            col["centro_custo_nome"] = i
        elif "custo" in hl and "r$" in hl:
            col["custo_valor"] = i

    obrigatorias = {"ano_emissao", "centro_custo_nome", "custo_valor"}
    faltando = obrigatorias - col.keys()
    if faltando:
        logger.error(f"{path.name}: colunas obrigatórias não encontradas: {faltando}")
        logger.error(f"  Colunas disponíveis: {header}")
        return []

    registros = []
    for row in rows[1:]:
        if not any(row):
            continue

        def val(campo):
            idx = col.get(campo)
            return row[idx] if idx is not None and idx < len(row) else None

        custo_raw = val("custo_valor")
        if custo_raw is None:
            continue
        try:
            custo = float(custo_raw)
        except (TypeError, ValueError):
            continue

        centro_nome = str(val("centro_custo_nome") or "").strip()

        r = {
            "ano_emissao":               val("ano_emissao"),
            "mes_emissao":               str(val("mes_emissao") or "").strip() or None,
            "mes_referencia":            str(val("mes_referencia") or "").strip() or None,
            "grupo_despesa_codigo":      str(val("grupo_despesa_codigo") or "").strip() or None,
            "grupo_despesa_nome":        str(val("grupo_despesa_nome") or "").strip() or None,
            "natureza_despesa_codigo":   str(val("natureza_despesa_codigo") or "").strip() or None,
            "natureza_despesa_nome":     str(val("natureza_despesa_nome") or "").strip() or None,
            "natureza_despesa_det_codigo": str(val("natureza_despesa_det_codigo") or "").strip() or None,
            "natureza_despesa_det_nome": str(val("natureza_despesa_det_nome") or "").strip() or None,
            "centro_custo_codigo":       str(val("centro_custo_codigo") or "").strip() or None,
            "centro_custo_nome":         centro_nome or None,
            "ex_presidente_slug":        _slug_de_centro(centro_nome),
            "custo_valor":               custo,
            "arquivo_origem":            path.name,
        }
        r["id"] = _id(r)
        registros.append(r)

    logger.info(f"{path.name}: {len(registros)} transações extraídas")
    return registros
