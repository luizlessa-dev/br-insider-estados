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
class Relacionamento:
    nome: Optional[str]
    cpf: Optional[str]
    tipo: Optional[str]


@dataclass
class Pep:
    id: int
    cpf: Optional[str]           # só dígitos — chave de cruzamento
    cpf_formatado: Optional[str]
    nome: Optional[str]
    nome_social: Optional[str]
    funcao: Optional[str]
    data_inicio_vinculo: Optional[date]
    data_fim_vinculo: Optional[date]
    orgao_codigo: Optional[str]
    orgao_descricao: Optional[str]
    classificacao_pep: Optional[str]   # Nível 1 / 2 / 3
    tipo_pep: Optional[str]
    relacionamentos: list[Relacionamento] = field(default_factory=list)


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
    )
    session.mount("https://", HTTPAdapter(max_retries=retry))
    session.headers.update({
        "chave-api-dados": api_key,
        "Accept": "application/json",
        "User-Agent": "BRInsider/1.0 (contato@thebrinsider.com)",
    })
    return session


def _parse_record(raw: dict) -> Pep:
    funcao_obj = raw.get("funcao") or {}
    orgao_obj  = raw.get("orgaoVinculado") or {}
    classif    = raw.get("classificacaoPep") or {}
    tipo       = raw.get("tipoPep") or {}

    rels = []
    for r in raw.get("relacionamentos") or []:
        rels.append(Relacionamento(
            nome=r.get("nome"),
            cpf=_strip_digits(r.get("cpfFormatado")),
            tipo=r.get("tipoRelacionamento"),
        ))

    cpf_fmt = raw.get("cpfFormatado")
    return Pep(
        id=raw.get("id"),
        cpf=_strip_digits(cpf_fmt),
        cpf_formatado=cpf_fmt,
        nome=raw.get("nome"),
        nome_social=raw.get("nomeSocial"),
        funcao=funcao_obj.get("descricao"),
        data_inicio_vinculo=_parse_date(funcao_obj.get("dataInicio")),
        data_fim_vinculo=_parse_date(funcao_obj.get("dataFim")),
        orgao_codigo=str(orgao_obj.get("codigo")) if orgao_obj.get("codigo") else None,
        orgao_descricao=orgao_obj.get("descricao"),
        classificacao_pep=classif.get("descricao"),
        tipo_pep=tipo.get("descricao"),
        relacionamentos=rels,
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

    def _fetch_page(self, pagina: int,
                    ini: str | None = None, fim: str | None = None) -> list[dict]:
        self._throttle()
        params: dict = {"pagina": pagina}
        if ini:
            params["dataInicioVinculo"] = ini
        if fim:
            params["dataFimVinculo"] = fim
        resp = self.session.get(BASE_URL, params=params, timeout=45)
        if resp.status_code == 401:
            raise PermissionError("Chave da API inválida ou expirada.")
        resp.raise_for_status()
        data = resp.json()
        return data if isinstance(data, list) else []

    def _iter_year(self, ano: int) -> Iterator[Pep]:
        ini = f"01/01/{ano}"
        fim = f"31/12/{ano}"
        pagina = 1
        total = 0
        while True:
            records = self._fetch_page(pagina, ini, fim)
            if not records:
                break
            for r in records:
                yield _parse_record(r)
                total += 1
            logger.debug("PEPs %d: pág %d → %d acumulados", ano, pagina, total)
            pagina += 1
        if total:
            logger.info("PEPs %d: %d registros", ano, total)

    def iter_all(self, ano_inicio: int = FIRST_YEAR) -> Iterator[Pep]:
        """Itera sobre todas as PEPs (histórico completo, janelas anuais)."""
        ano_fim = datetime.utcnow().year
        for ano in range(ano_inicio, ano_fim + 1):
            yield from self._iter_year(ano)

    def iter_incremental(self, desde: date) -> Iterator[Pep]:
        """Ingestão incremental a partir de uma data de início de vínculo."""
        ini = desde.strftime("%d/%m/%Y")
        fim = datetime.utcnow().strftime("%d/%m/%Y")
        pagina = 1
        while True:
            records = self._fetch_page(pagina, ini, fim)
            if not records:
                break
            for r in records:
                yield _parse_record(r)
            pagina += 1

    def fetch_by_cpf(self, cpf: str) -> list[Pep]:
        """Busca PEPs por CPF (consulta pontual)."""
        self._throttle()
        params = {"cpfPep": cpf, "pagina": 1}
        resp = self.session.get(BASE_URL, params=params, timeout=30)
        resp.raise_for_status()
        data = resp.json()
        return [_parse_record(r) for r in (data if isinstance(data, list) else [])]
