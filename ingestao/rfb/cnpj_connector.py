"""
CNPJ Receita Federal — The Brasilia Insider
Enriquece CNPJs já presentes no banco (emendas + TSE) com dados cadastrais.

Fonte: https://dadosabertos.rfb.gov.br/CNPJ/
  Arquivos: Empresas{0-9}.zip + Socios{0-9}.zip + Estabelecimentos{0-9}.zip
  Atualização: mensal

Estratégia (filtro reverso — evita baixar os 85 GB inteiros):
  1. Busca CNPJs-alvo no Supabase (emendas_favorecidos + tse_receitas + tse_despesas)
  2. Baixa uma partição de cada vez (~700 MB comprimido, ~3-4 GB descomprimido)
  3. Processa com DuckDB (filtro por CNPJ_BASICO) — nunca materializa em RAM
  4. Upsert dos matches no Supabase
  5. Apaga o arquivo temporário antes da próxima partição

Layout dos arquivos (separador ";", sem cabeçalho, encoding latin-1):
  Empresas: CNPJ_BASICO;RAZAO_SOCIAL;NATUREZA_JURIDICA;QUALIFICACAO_RESPONSAVEL;
             CAPITAL_SOCIAL;PORTE_EMPRESA;ENTE_FEDERATIVO_RESPONSAVEL
  Socios:   CNPJ_BASICO;IDENTIFICADOR_DE_SOCIO;NOME_SOCIO;CNPJ_CPF_SOCIO;
             QUALIFICACAO_SOCIO;DATA_ENTRADA_SOCIEDADE;PAIS;
             REPRESENTANTE_LEGAL;NOME_REPRESENTANTE;QUALIFICACAO_REPRESENTANTE;FAIXA_ETARIA
  Estabelecimentos: CNPJ_BASICO;CNPJ_ORDEM;CNPJ_DV;IDENTIFICADOR_MATRIZ_FILIAL;
                    NOME_FANTASIA;SITUACAO_CADASTRAL;DATA_SITUACAO_CADASTRAL;
                    MOTIVO_SITUACAO_CADASTRAL;NOME_CIDADE_EXTERIOR;PAIS;
                    DATA_INICIO_ATIVIDADE;CNAE_FISCAL;CNAE_FISCAL_SECUNDARIA;
                    TIPO_LOGRADOURO;LOGRADOURO;NUMERO;COMPLEMENTO;BAIRRO;CEP;UF;MUNICIPIO;...

Base URL: https://dadosabertos.rfb.gov.br/CNPJ/
  Empresas0.zip … Empresas9.zip
  Socios0.zip   … Socios9.zip  (opcionais — pesados, baixar sob demanda)

Tabelas geradas: cnpj_empresas, cnpj_socios
  JOIN: cnpj_basico (8 dígitos = primeiros 8 de qualquer CNPJ 14 dígitos)
"""
from __future__ import annotations

import logging
import os
import pathlib
import re
import tempfile
from typing import Iterator, NamedTuple, Optional

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

logger = logging.getLogger("rfb.cnpj")

BASE_URL = "https://dadosabertos.rfb.gov.br/CNPJ"
PARTICOES = list(range(10))   # 0..9

EMPRESA_COLS = [
    "cnpj_basico", "razao_social", "natureza_juridica", "qualificacao_responsavel",
    "capital_social", "porte_empresa", "ente_federativo_responsavel",
]
SOCIO_COLS = [
    "cnpj_basico", "identificador_socio", "nome_socio", "cnpj_cpf_socio",
    "qualificacao_socio", "data_entrada", "pais",
    "representante_legal", "nome_representante", "qualificacao_representante", "faixa_etaria",
]
ESTAB_COLS = [
    "cnpj_basico", "cnpj_ordem", "cnpj_dv",
    "identificador_matriz_filial",   # 1=MATRIZ, 2=FILIAL
    "nome_fantasia", "situacao_cadastral", "data_situacao_cadastral",
    "motivo_situacao_cadastral", "nome_cidade_exterior", "pais",
    "data_inicio_atividade", "cnae_fiscal", "cnae_fiscal_secundaria",
    "tipo_logradouro", "logradouro", "numero", "complemento", "bairro",
    "cep", "uf", "municipio",
    "ddd1", "telefone1", "ddd2", "telefone2", "ddd_fax", "fax",
    "correio_eletronico", "situacao_especial", "data_situacao_especial",
]


class EmpresaRow(NamedTuple):
    cnpj_basico: str
    razao_social: Optional[str]
    natureza_juridica: Optional[str]
    capital_social: Optional[str]
    porte_empresa: Optional[str]


class SocioRow(NamedTuple):
    cnpj_basico: str
    nome_socio: Optional[str]
    cpf_cnpj_socio: Optional[str]
    qualificacao_socio: Optional[str]
    data_entrada: Optional[str]


# ─── HTTP ──────────────────────────────────────────────────────────────────────

def _build_session() -> requests.Session:
    s = requests.Session()
    retry = Retry(total=4, backoff_factor=2.0, status_forcelist=[429, 500, 502, 503, 504])
    s.mount("https://", HTTPAdapter(max_retries=retry))
    s.headers["User-Agent"] = "BRInsider/1.0 (contato@thebrinsider.com)"
    return s


def _download_partition(url: str, dest: pathlib.Path, session: requests.Session) -> pathlib.Path:
    """Baixa um arquivo ZIP para disco. Retorna o caminho local."""
    logger.info("Baixando %s → %s", url, dest.name)
    with session.get(url, stream=True, timeout=600) as resp:
        resp.raise_for_status()
        with open(dest, "wb") as f:
            for chunk in resp.iter_content(chunk_size=4 << 20):
                f.write(chunk)
    size_mb = dest.stat().st_size / 1024 / 1024
    logger.info("Download concluído: %.1f MB", size_mb)
    return dest


def _cnpj_basico(cnpj14: str) -> str:
    """Extrai os 8 primeiros dígitos de um CNPJ de 14 dígitos."""
    return re.sub(r"\D", "", cnpj14)[:8]


# ─── DuckDB filter ─────────────────────────────────────────────────────────────

def _filter_partition_duckdb(
    zip_path: pathlib.Path,
    target_cnpjs_basico: set[str],
    cols: list[str],
    entity: str,
) -> list[dict]:
    """
    Abre o ZIP com DuckDB, filtra pelas `target_cnpjs_basico` e retorna as linhas.
    Nunca materializa o CSV inteiro em Python — usa DuckDB como motor.
    """
    try:
        import duckdb
    except ImportError:
        raise RuntimeError("duckdb não instalado. Execute: pip install duckdb")

    con = duckdb.connect(database=":memory:")

    # DuckDB lê ZIP diretamente
    parquet_list = ",".join(f"'{c}'" for c in target_cnpjs_basico)
    col_names = ", ".join(f"column{i:02d} AS {col}" for i, col in enumerate(cols))

    query = f"""
    SELECT {col_names}
    FROM read_csv(
        '{zip_path}',
        delim=';',
        header=false,
        encoding='latin1',
        ignore_errors=true
    )
    WHERE column00 IN ({parquet_list})
    """

    try:
        result = con.execute(query).fetchall()
        rows = [dict(zip(cols, row)) for row in result]
        logger.info("%s partição %s: %d linhas filtradas de %d CNPJs-alvo",
                    entity, zip_path.name, len(rows), len(target_cnpjs_basico))
        return rows
    except Exception as e:
        logger.error("DuckDB falhou em %s: %s", zip_path.name, e)
        return []
    finally:
        con.close()


# ─── API pública: CNPJs individuais (lento, para enriquecimento pontual) ──────

def lookup_cnpj_brasilapi(cnpj: str, session: requests.Session) -> dict | None:
    """
    Busca dados de um CNPJ específico via BrasilAPI (gratuita, sem autenticação).
    Rate limit: ~30 req/min. Use para enriquecimento pontual, não bulk.
    """
    cnpj_digits = re.sub(r"\D", "", cnpj)
    if len(cnpj_digits) != 14:
        return None
    try:
        r = session.get(
            f"https://brasilapi.com.br/api/cnpj/v1/{cnpj_digits}",
            timeout=15,
        )
        if r.status_code == 200:
            return r.json()
        return None
    except Exception:
        return None


# ─── Conector principal ─────────────────────────────────────────────────────────

class CNPJConnector:
    """
    Enriquece CNPJs do banco usando o dump bulk da Receita Federal.

    Fluxo:
      1. Recebe set de CNPJs-alvo (14 dígitos, sem formatação)
      2. Para cada partição (0..9), baixa, filtra, apaga
      3. Agrega resultados de Empresas e Socios
    """

    def __init__(self, workdir: str | None = None) -> None:
        self.session = _build_session()
        self.workdir = pathlib.Path(workdir or tempfile.gettempdir())

    def _particao_url(self, entity: str, idx: int) -> str:
        return f"{BASE_URL}/{entity}{idx}.zip"

    def iter_empresas(self, target_cnpjs: set[str]) -> Iterator[dict]:
        """
        Itera sobre dados de Empresas para os CNPJs-alvo.
        Baixa e apaga cada partição antes da próxima.
        """
        target_basico = {_cnpj_basico(c) for c in target_cnpjs if len(re.sub(r'\D','',c)) == 14}
        if not target_basico:
            logger.warning("Nenhum CNPJ válido no conjunto alvo.")
            return

        logger.info("Buscando %d CNPJs em 10 partições de Empresas...", len(target_basico))
        for idx in PARTICOES:
            url = self._particao_url("Empresas", idx)
            dest = self.workdir / f"Empresas{idx}.zip"
            try:
                _download_partition(url, dest, self.session)
                rows = _filter_partition_duckdb(dest, target_basico, EMPRESA_COLS, "Empresas")
                yield from rows
            except Exception as e:
                logger.error("Partição Empresas%d falhou: %s", idx, e)
            finally:
                if dest.exists():
                    dest.unlink()
                    logger.debug("Partição Empresas%d removida", idx)

    def iter_socios(self, target_cnpjs: set[str]) -> Iterator[dict]:
        """
        Itera sobre Sócios (QSA) para os CNPJs-alvo.
        Revela a cadeia de controle — quem é dono das empresas favorecidas.
        """
        target_basico = {_cnpj_basico(c) for c in target_cnpjs if len(re.sub(r'\D','',c)) == 14}
        if not target_basico:
            return

        logger.info("Buscando sócios de %d CNPJs em 10 partições...", len(target_basico))
        for idx in PARTICOES:
            url = self._particao_url("Socios", idx)
            dest = self.workdir / f"Socios{idx}.zip"
            try:
                _download_partition(url, dest, self.session)
                rows = _filter_partition_duckdb(dest, target_basico, SOCIO_COLS, "Socios")
                yield from rows
            except Exception as e:
                logger.error("Partição Socios%d falhou: %s", idx, e)
            finally:
                if dest.exists():
                    dest.unlink()
