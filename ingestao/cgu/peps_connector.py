"""
PEPs — Pessoas Expostas Politicamente · The Brasilia Insider

API: GET https://api.portaldatransparencia.gov.br/api-de-dados/peps
Autenticação: header "chave-api-dados" com chave registrada em
  https://portaldatransparencia.gov.br/api-de-dados/cadastrar-email

Parâmetros (todos opcionais, exceto pagina):
  cpfPep         — CPF da PEP
  nomePep        — nome (parcial aceito)
  dataInicioVinculo / dataFimVinculo — DD/MM/AAAA
  pagina         — 1-based (OBRIGATÓRIO)

Campos retornados:
  id, cpfFormatado, nome, nomeSocial,
  funcao.{descricao, dataInicio, dataFim},
  orgaoVinculado.{codigo, descricao},
  classificacaoPep.descricao   — Nível 1/2/3
  tipoPep.descricao            — Cargo efetivo, Nomeado, etc.
  relacionamentos[]            — familiares/sócios da PEP

Cruzamento estratégico:
  peps.cpf × parlamentares.cpf          → confirma PEP no Congresso
  peps.cpf × sancoes.cpf_cnpj           → PEP sancionada
  peps.cpf × tse_candidatos.cpf         → PEP candidata em 2024/2026
  peps.cpf × emendas_favorecidos (via parlamentar) → emenda para PEP
"""
from __future__ import annotations

import logging
import re
import time
from dataclasses import dataclass, field
from datetime import date, datetime
from typing import Iterator, Optional

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

logger = logging.getLogger("cgu.peps")

BASE_URL = "https://api.portaldatransparencia.gov.br/api-de-dados/peps"
FIRST_YEAR = 2003
PAGE_DELAY = 0.4


# ─── Modelos ──────────────────────────────────────────────────────────────────

@dataclass
class Pep:
    cpf: Optional[str]           # mascarado pela API — guardamos como vem
    nome: Optional[str]
    sigla_funcao: Optional[str]
    descricao_funcao: Optional[str]
    nivel_funcao: Optional[str]
    orgao_codigo: Optional[str]
    orgao_nome: Optional[str]
    data_inicio_exercicio: Optional[date]
    data_fim_exercicio: Optional[date]
    data_fim_carencia: Optional[date]


# ─── Utilitários ──────────────────────────────────────────────────────────────

def _strip_digits(v: str | None) -> Optional[str]:
    if not v:
        return None
    d = re.sub(r"\D", "", v.strip())
    return d or None


def _parse_date(v: str | None) -> Optional[date]:
    if not v:
        return None
    for fmt in ("%d/%m/%Y", "%Y-%m-%d"):
        try:
            return datetime.strptime(v.strip()[:10], fmt).date()
        except ValueError:
            continue
    return None


def _build_session(api_key: str) -> requests.Session:
    session = requests.Session()
    retry = Retry(
        total=5, backoff_factor=2.0,
        status_forcelist=[429, 500, 502, 503, 504],
        allowed_methods=["GET"],
        raise_on_status=False,
    )
    session.mount("https://", HTTPAdapter(max_retries=retry))
    session.headers.update({
        "chave-api-dados": api_key,
        "Accept": "application/json",
        "User-Agent": "BRInsider/1.0 (contato@thebrinsider.com)",
    })
    return session


def _parse_record(raw: dict) -> Pep:
    # A API retorna campos snake_case direto (diferente das outras APIs)
    return Pep(
        cpf=raw.get("cpf"),
        nome=(raw.get("nome") or "").strip() or None,
        sigla_funcao=(raw.get("sigla_funcao") or "").strip() or None,
        descricao_funcao=(raw.get("descricao_funcao") or "").strip() or None,
        nivel_funcao=raw.get("nivel_funcao"),
        orgao_codigo=raw.get("cod_orgao"),
        orgao_nome=(raw.get("nome_orgao") or "").strip() or None,
        data_inicio_exercicio=_parse_date(raw.get("dt_inicio_exercicio")),
        data_fim_exercicio=_parse_date(raw.get("dt_fim_exercicio")),
        data_fim_carencia=_parse_date(raw.get("dt_fim_carencia")),
    )


# ─── Conector ─────────────────────────────────────────────────────────────────

class PepsConnector:
    """
    Itera sobre todos os registros de PEPs via API paginada.
    Usa janelas anuais (dataInicioVinculo) para cobrir todo o histórico.
    """

    def __init__(self, api_key: str) -> None:
        if not api_key:
            raise ValueError("PORTAL_TRANSPARENCIA_API_KEY é obrigatória.")
        self.session = _build_session(api_key)
        self._last_req: float = 0.0

    def _throttle(self) -> None:
        elapsed = time.monotonic() - self._last_req
        if elapsed < PAGE_DELAY:
            time.sleep(PAGE_DELAY - elapsed)
        self._last_req = time.monotonic()

    def _fetch_page(self, pagina: int, **params) -> list[dict]:
        self._throttle()
        params["pagina"] = pagina
        resp = self.session.get(BASE_URL, params=params, timeout=(10, 30))
        if resp.status_code == 401:
            raise PermissionError("Chave da API inválida ou expirada.")
        resp.raise_for_status()
        data = resp.json()
        return data if isinstance(data, list) else []

    def _iter_window(self, ini: str, fim: str) -> Iterator[Pep]:
        pagina = 1
        total = 0
        while True:
            records = self._fetch_page(
                pagina,
                dataInicioExercicioDe=ini,
                datInicioExercicioAte=fim,
            )
            if not records:
                break
            for r in records:
                yield _parse_record(r)
                total += 1
            logger.debug("PEPs %s→%s: pág %d → %d acumulados", ini, fim, pagina, total)
            pagina += 1
        if total:
            logger.info("PEPs %s→%s: %d registros", ini, fim, total)

    def _iter_year(self, ano: int) -> Iterator[Pep]:
        # Janelas mensais — API trava em janelas com mais de ~2k registros
        fim_por_mes = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        if ano % 4 == 0 and (ano % 100 != 0 or ano % 400 == 0):
            fim_por_mes[1] = 29
        for mes, ultimo in enumerate(fim_por_mes, start=1):
            ini = f"{1:02d}/{mes:02d}/{ano}"
            fim = f"{ultimo:02d}/{mes:02d}/{ano}"
            yield from self._iter_window(ini, fim)

    def iter_all(self, ano_inicio: int = FIRST_YEAR) -> Iterator[Pep]:
        """Itera sobre todas as PEPs (histórico completo, janelas anuais)."""
        ano_fim = datetime.utcnow().year
        for ano in range(ano_inicio, ano_fim + 1):
            yield from self._iter_year(ano)

    def iter_incremental(self, desde: date) -> Iterator[Pep]:
        """Ingestão incremental a partir de uma data de início de exercício."""
        ini = desde.strftime("%d/%m/%Y")
        fim = datetime.utcnow().strftime("%d/%m/%Y")
        pagina = 1
        while True:
            records = self._fetch_page(
                pagina,
                dataInicioExercicioDe=ini,
                datInicioExercicioAte=fim,
            )
            if not records:
                break
            for r in records:
                yield _parse_record(r)
            pagina += 1

    def fetch_by_nome(self, nome: str) -> Iterator[Pep]:
        """Busca PEPs por nome (consulta pontual)."""
        pagina = 1
        while True:
            records = self._fetch_page(pagina, nome=nome)
            if not records:
                break
            for r in records:
                yield _parse_record(r)
            pagina += 1
