"""
CNES — Cadastro Nacional de Estabelecimentos de Saúde
Fonte: https://apidadosabertos.saude.gov.br/cnes/estabelecimentos

Ingestão de todos os estabelecimentos de saúde do Brasil com CNPJ,
para cruzamento com emendas_favorecidos.

Parâmetros aceitos pela API:
  codigo_uf          → filtra por UF (Integer, ex: 31 = MG)
  codigo_municipio   → filtra por município IBGE 6 dígitos
  limit              → max 20 por requisição (limite da API)
  offset             → paginação

Estratégia: iterar por UF para ter checkpoints naturais e simplificar
logs. Cada UF tem centenas/milhares de estabelecimentos → offset loop.
"""
from __future__ import annotations

import logging
import os
import time
from dataclasses import dataclass
from datetime import date
from typing import Iterator

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

logger = logging.getLogger("cnes")

BASE_URL = "https://apidadosabertos.saude.gov.br/cnes/estabelecimentos"
PAGE_SIZE = 20   # máximo aceito pela API
REQUEST_DELAY = 0.4

# Códigos numéricos das 27 UFs brasileiras
UFS = [
    (11, "RO"), (12, "AC"), (13, "AM"), (14, "RR"), (15, "PA"),
    (16, "AP"), (17, "TO"), (21, "MA"), (22, "PI"), (23, "CE"),
    (24, "RN"), (25, "PB"), (26, "PE"), (27, "AL"), (28, "SE"),
    (29, "BA"), (31, "MG"), (32, "ES"), (33, "RJ"), (35, "SP"),
    (41, "PR"), (42, "SC"), (43, "RS"), (50, "MS"), (51, "MT"),
    (52, "GO"), (53, "DF"),
]


@dataclass
class Estabelecimento:
    codigo_cnes: int
    numero_cnpj: str | None
    nome_razao_social: str
    nome_fantasia: str | None
    codigo_tipo_unidade: int | None
    tipo_gestao: str | None
    descricao_esfera_administrativa: str | None
    descricao_natureza_juridica: str | None
    codigo_uf: int | None
    uf: str | None
    codigo_municipio: int | None
    codigo_cep: str | None
    endereco: str | None
    numero: str | None
    bairro: str | None
    latitude: float | None
    longitude: float | None
    telefone: str | None
    email: str | None
    atende_sus: bool | None
    possui_centro_cirurgico: bool | None
    possui_atendimento_hospitalar: bool | None
    possui_atendimento_ambulatorial: bool | None
    data_atualizacao: date | None


def _build_session() -> requests.Session:
    session = requests.Session()
    retry = Retry(
        total=4,
        backoff_factor=1.5,
        status_forcelist=[429, 500, 502, 503, 504],
        allowed_methods=["GET"],
    )
    adapter = HTTPAdapter(max_retries=retry)
    session.mount("https://", adapter)
    session.headers.update({
        "User-Agent": "BRInsider/1.0 (bot dados públicos; contato@thebrinsider.com)",
        "Accept": "application/json",
    })
    return session


def _parse_date(value: str | None) -> date | None:
    if not value:
        return None
    try:
        return date.fromisoformat(value[:10])
    except ValueError:
        return None


def _normalize(raw: dict, uf_sigla: str) -> Estabelecimento:
    cnpj = raw.get("numero_cnpj") or raw.get("numero_cnpj_entidade")
    # Remove formatação se vier com pontuação
    if cnpj:
        cnpj = "".join(c for c in cnpj if c.isdigit()) or None

    nome = raw.get("nome_razao_social") or raw.get("nome_fantasia") or ""

    return Estabelecimento(
        codigo_cnes=raw["codigo_cnes"],
        numero_cnpj=cnpj if cnpj and len(cnpj) == 14 else None,
        nome_razao_social=nome,
        nome_fantasia=raw.get("nome_fantasia"),
        codigo_tipo_unidade=raw.get("codigo_tipo_unidade"),
        tipo_gestao=raw.get("tipo_gestao"),
        descricao_esfera_administrativa=raw.get("descricao_esfera_administrativa"),
        descricao_natureza_juridica=raw.get("descricao_natureza_juridica_estabelecimento"),
        codigo_uf=raw.get("codigo_uf"),
        uf=uf_sigla,
        codigo_municipio=raw.get("codigo_municipio"),
        codigo_cep=raw.get("codigo_cep_estabelecimento"),
        endereco=raw.get("endereco_estabelecimento"),
        numero=raw.get("numero_estabelecimento"),
        bairro=raw.get("bairro_estabelecimento"),
        latitude=raw.get("latitude_estabelecimento_decimo_grau"),
        longitude=raw.get("longitude_estabelecimento_decimo_grau"),
        telefone=raw.get("numero_telefone_estabelecimento"),
        email=raw.get("endereco_email_estabelecimento"),
        atende_sus=raw.get("estabelecimento_faz_atendimento_ambulatorial_sus") == "SIM",
        possui_centro_cirurgico=bool(raw.get("estabelecimento_possui_centro_cirurgico")),
        possui_atendimento_hospitalar=bool(raw.get("estabelecimento_possui_atendimento_hospitalar")),
        possui_atendimento_ambulatorial=bool(raw.get("estabelecimento_possui_atendimento_ambulatorial")),
        data_atualizacao=_parse_date(raw.get("data_atualizacao")),
    )


def fetch_por_uf(
    codigo_uf: int,
    uf_sigla: str,
    session: requests.Session | None = None,
) -> Iterator[Estabelecimento]:
    """Gera todos os estabelecimentos de uma UF via paginação."""
    sess = session or _build_session()
    offset = 0
    last_request = 0.0

    while True:
        elapsed = time.monotonic() - last_request
        if elapsed < REQUEST_DELAY:
            time.sleep(REQUEST_DELAY - elapsed)

        try:
            resp = sess.get(
                BASE_URL,
                params={"codigo_uf": codigo_uf, "limit": PAGE_SIZE, "offset": offset},
                timeout=20,
            )
            resp.raise_for_status()
            last_request = time.monotonic()
        except requests.HTTPError as e:
            logger.error("HTTP %s ao buscar UF %s offset %d", e.response.status_code, uf_sigla, offset)
            break
        except requests.RequestException as e:
            logger.error("Erro de rede UF %s offset %d: %s", uf_sigla, offset, e)
            break

        batch = resp.json().get("estabelecimentos", [])
        for raw in batch:
            yield _normalize(raw, uf_sigla)

        if len(batch) < PAGE_SIZE:
            break
        offset += PAGE_SIZE


def fetch_todos(
    ufs: list[tuple[int, str]] | None = None,
    session: requests.Session | None = None,
) -> Iterator[tuple[str, Estabelecimento]]:
    """Gera (uf_sigla, estabelecimento) para todas as UFs."""
    sess = session or _build_session()
    for codigo_uf, uf_sigla in (ufs or UFS):
        logger.info("CNES: iniciando UF %s (%d)", uf_sigla, codigo_uf)
        count = 0
        for estab in fetch_por_uf(codigo_uf, uf_sigla, sess):
            count += 1
            yield uf_sigla, estab
        logger.info("CNES: %s → %d estabelecimentos", uf_sigla, count)
