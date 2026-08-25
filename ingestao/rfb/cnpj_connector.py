"""
CNPJ Receita Federal — The Brasilia Insider
Enriquece CNPJs já presentes no banco (emendas + TSE) com dados cadastrais.

Fonte: https://arquivos.receitafederal.gov.br/ (plataforma SERPRO+, Nextcloud
  público), pasta Dados/Cadastros/CNPJ/{AAAA-MM}/ — mensal, uma subpasta por mês.
  `dadosabertos.rfb.gov.br` (usado antes) está morto — timeout total confirmado
  em 3 redes independentes (GitHub Actions, rede residencial, este ambiente) em
  25/08/2026. A RFB migrou pra essa nova plataforma sem avisar; o domínio antigo
  só nunca mais respondeu. Confirmado via PROPFIND que os nomes de arquivo
  (Empresas{0-9}.zip, Socios{0-9}.zip) não mudaram, só o host/path.
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

Base URL: https://arquivos.receitafederal.gov.br/public.php/dav/files/gn672Ad4CF8N6TK/Dados/Cadastros/CNPJ/{AAAA-MM}/
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

SERPRO_HOST = "https://arquivos.receitafederal.gov.br"
SERPRO_SHARE_TOKEN = "gn672Ad4CF8N6TK"
SERPRO_CNPJ_DIR = f"{SERPRO_HOST}/public.php/dav/files/{SERPRO_SHARE_TOKEN}/Dados/Cadastros/CNPJ"
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

    # DuckDB não lê CSV de dentro de um .zip (não é um filesystem de arquivo
    # único como .gz/.zst — é um contêiner com índice) — testado contra dado
    # real em 25/08/2026: `read_csv` direto no .zip falha tanto na validação
    # de encoding quanto no sniff de dialeto, porque está lendo os bytes
    # binários do contêiner, não o CSV. Extrai primeiro via unzip -p | iconv
    # (mesmo padrão usado pros ZIPs do TSE no ElectioLab), convertendo pra
    # UTF-8 antes — os dumps da RFB têm bytes fora do Latin-1 estrito
    # (Windows-1252), que o validador de encoding do DuckDB 1.5+ rejeita.
    import subprocess

    csv_path = zip_path.with_suffix(".csv")
    try:
        with open(csv_path, "wb") as f:
            unzip_proc = subprocess.Popen(["unzip", "-p", str(zip_path)], stdout=subprocess.PIPE)
            iconv_proc = subprocess.Popen(
                ["iconv", "-f", "WINDOWS-1252//TRANSLIT", "-t", "UTF-8//IGNORE"],
                stdin=unzip_proc.stdout,
                stdout=f,
            )
            unzip_proc.stdout.close()
            iconv_proc.communicate()
            unzip_proc.wait()
    except Exception as e:
        logger.error("Extração de %s falhou: %s", zip_path.name, e)
        csv_path.unlink(missing_ok=True)
        return []

    con = duckdb.connect(database=":memory:")
    parquet_list = ",".join(f"'{c}'" for c in target_cnpjs_basico)
    # Nomes reais gerados pelo DuckDB pra CSV sem header: column0, column1, ...
    # (sem zero-padding — column00 não existe e falha silenciosamente antes).
    col_names = ", ".join(f"column{i} AS {col}" for i, col in enumerate(cols))

    query = f"""
    SELECT {col_names}
    FROM read_csv(
        '{csv_path}',
        delim=';',
        header=false,
        quote='"',
        ignore_errors=true
    )
    WHERE column0 IN ({parquet_list})
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
        csv_path.unlink(missing_ok=True)


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
        self._mes: str | None = None

    def _mes_mais_recente(self) -> str:
        """Descobre a subpasta AAAA-MM mais recente via PROPFIND (Nextcloud WebDAV).
        Evita hardcodar o mês corrente — a RFB às vezes atrasa a publicação."""
        if self._mes:
            return self._mes
        body = (
            '<?xml version="1.0"?>'
            '<d:propfind xmlns:d="DAV:"><d:prop><d:displayname/><d:resourcetype/></d:prop></d:propfind>'
        )
        resp = self.session.request(
            "PROPFIND",
            f"{SERPRO_CNPJ_DIR}/",
            headers={"Depth": "1", "Content-Type": "application/xml"},
            data=body,
            timeout=30,
        )
        resp.raise_for_status()
        meses = sorted(set(re.findall(r"<d:displayname>(\d{4}-\d{2})</d:displayname>", resp.text)))
        if not meses:
            raise RuntimeError(f"Nenhuma pasta AAAA-MM encontrada em {SERPRO_CNPJ_DIR}/")
        self._mes = meses[-1]
        logger.info("rfb.cnpj: usando dump de %s (mais recente disponível)", self._mes)
        return self._mes

    def _particao_url(self, entity: str, idx: int) -> str:
        return f"{SERPRO_CNPJ_DIR}/{self._mes_mais_recente()}/{entity}{idx}.zip"

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
