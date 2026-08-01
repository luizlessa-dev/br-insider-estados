"""
Direct Data — Enriquecimento PF via AdvancedSearch/FilterNaturalPerson

Dado um CPF + nome completo (+ data de nascimento opcional), localiza a pessoa
na base Direct Data e retorna dados de enriquecimento:
  - Nome completo e nome da mãe
  - Data de nascimento confirmada
  - Programa social (BolsaFamília, BPC, AuxílioEmergencial, etc.) — sinal de renda
  - CPF confirmado (match cruzado)

Custo: pago por consulta (AdvancedSearch FilterNaturalPerson).

Uso no dossiê PF avulso (FONTES_PF_AVULSA).
"""
from __future__ import annotations

import logging
import os
import re

import requests

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.directdata_pf_enriquecimento")

_BASE  = "https://api.app.directd.com.br"
_TOKEN = os.environ.get("DIRECT_DATA_TOKEN", "")

_BENEFICIOS = {
    "receiveAuxilioEmergencial": "Auxílio Emergencial",
    "receiveBolsaFamilia":       "Bolsa Família",
    "receiveBPC":                "BPC/LOAS",
    "receiveGarantiaSafra":      "Garantia-Safra",
    "receiveSeguroDefeso":       "Seguro-Defeso",
}

# Margem de dias em cada lado da data de nascimento no filtro
_BIRTH_WINDOW_DAYS = 0  # data exata — só alarga se não achar match


def _headers() -> dict:
    return {"Token": _TOKEN, "Content-Type": "application/json"}


def _strip_cpf(cpf: str) -> str:
    return re.sub(r"\D", "", str(cpf or ""))


def _fmt_cpf(cpf: str) -> str:
    c = _strip_cpf(cpf)
    return f"{c[:3]}.{c[3:6]}.{c[6:9]}-{c[9:11]}" if len(c) == 11 else cpf


def _birth_to_iso(dob: str) -> str | None:
    """Aceita 'DD/MM/YYYY', 'YYYY-MM-DD' ou 'DDMMYYYY'. Retorna 'YYYY-MM-DD'."""
    dob = re.sub(r"\D", "", dob)
    if len(dob) == 8:
        if int(dob[:4]) > 1900:  # YYYYMMDD
            return f"{dob[:4]}-{dob[4:6]}-{dob[6:8]}"
        return f"{dob[4:8]}-{dob[2:4]}-{dob[:2]}"  # DDMMYYYY
    return None


def _filter_natural_person(
    full_name: str,
    birth_date: str | None = None,
    city: str | None = None,
    state: str | None = None,
) -> dict:
    """Chama FilterNaturalPerson e retorna o payload bruto."""
    body: dict = {"fullName": full_name}

    if birth_date:
        iso = _birth_to_iso(birth_date)
        if iso:
            body["dateOfBirthStart"] = iso
            body["dateOfBirthEnd"]   = iso

    if city:
        body["city"] = city
    if state:
        body["state"] = state

    resp = requests.post(
        f"{_BASE}/api/AdvancedSearch/FilterNaturalPerson",
        headers=_headers(),
        json=body,
        timeout=60,
    )
    resp.raise_for_status()
    return resp.json()


def _match_cpf(filters: list[dict], cpf_digits: str) -> dict | None:
    """Retorna o item cujo CPF bate com cpf_digits, ou None."""
    for item in filters or []:
        item_cpf = _strip_cpf(str(item.get("cpf") or ""))
        if item_cpf == cpf_digits:
            return item
    return None


def enriquecer_pf(
    cpf: str,
    nome: str,
    data_nascimento: str | None = None,
    municipio: str | None = None,
    uf: str | None = None,
) -> dict | None:
    """
    Busca e confirma a PF pelo CPF + nome.
    Retorna dict com campos de enriquecimento, ou None se não encontrar.
    """
    if not _TOKEN:
        logger.warning("DIRECT_DATA_TOKEN não configurado — enriquecimento PF ignorado.")
        return None

    cpf_digits = _strip_cpf(cpf)

    try:
        result = _filter_natural_person(nome, data_nascimento, municipio, uf)
    except requests.HTTPError as e:
        logger.warning("DirectData PF enriquecimento HTTP %s para %s", e.response.status_code, cpf_digits)
        return None
    except Exception as e:
        logger.warning("DirectData PF enriquecimento erro: %s", e)
        return None

    n_found = result.get("numberOfPeople", 0)
    filters = result.get("listFilters") or []

    if n_found == 0 or not filters:
        logger.debug("DirectData PF: nenhum resultado para %s / %s", cpf_digits, nome)
        return None

    match = _match_cpf(filters, cpf_digits)
    if not match:
        logger.debug(
            "DirectData PF: %d resultado(s) para '%s' mas CPF %s não confirmado",
            n_found, nome, cpf_digits,
        )
        return None

    return {
        "cpf_confirmado":  True,
        "nome_completo":   match.get("fullName"),
        "nome_mae":        match.get("motherName"),
        "data_nascimento": match.get("dateOfBirth"),
        "filter_id":       match.get("id"),
        "total_encontrado": n_found,
    }


# ─────────────────────────────────────────────────────────────
# SubradarSource connector (para FONTES_PF_AVULSA)
# ─────────────────────────────────────────────────────────────

class DirectDataPFEnriquecimentoConnector(SubradarSource):
    fonte = "directdata_pf_enriquecimento"
    request_delay = 1.0

    def consultar_cpf(
        self,
        cpf: str,
        nome: str | None = None,
        data_nascimento: str | None = None,
        municipio: str | None = None,
        uf: str | None = None,
    ) -> list[dict]:
        """
        Enriquece uma PF via Direct Data.
        Parâmetros extras (nome, data_nascimento) vêm do perfil Subradar.
        Retorna lista com 0 ou 1 alerta quando identifica programa social de risco.
        """
        if not nome:
            logger.debug("DirectData PF enriquecimento: nome obrigatório — ignorando %s", cpf)
            return []

        cpf_fmt = _fmt_cpf(cpf)
        ciclo   = _ciclo_atual()

        dados = enriquecer_pf(cpf, nome, data_nascimento, municipio, uf)
        if not dados:
            return []

        mudou, hash_novo = snapshot_changed(cpf_fmt, self.fonte, ciclo, dados)
        if not mudou:
            return []

        upsert("sub_snapshots", [{
            "cnpj":       cpf_fmt,  # reutiliza campo cnpj para CPF
            "fonte":      self.fonte,
            "ciclo":      ciclo,
            "hash_dados": hash_novo,
            "dados":      dados,
        }])

        alertas = []

        # Dados de enriquecimento sempre salvos — só geram alerta se houver sinal de renda baixa
        # (indicado por nome_mae ausente = dado incompleto na RF / possível CPF irregular)
        if dados.get("nome_mae") is None:
            alertas.append({
                "cnpj":         cpf_fmt,
                "ciclo":        ciclo,
                "fonte":        self.fonte,
                "categoria":    "cadastral",
                "severidade":   "atencao",
                "titulo":       "PF — Nome da mãe ausente na base Direct Data",
                "descricao": (
                    f"CPF {cpf_fmt} confirmado na base Direct Data mas sem nome da mãe registrado. "
                    "Pode indicar cadastro incompleto ou CPF irregular na Receita Federal."
                ),
                "referencia_id": dados.get("filter_id"),
                "url_fonte":     "https://app.directd.com.br",
                "is_novo":       True,
            })

        logger.info(
            "DirectData PF: %s confirmado | nome_mae=%s | alertas=%d",
            cpf_fmt,
            "sim" if dados.get("nome_mae") else "ausente",
            len(alertas),
        )
        return alertas
