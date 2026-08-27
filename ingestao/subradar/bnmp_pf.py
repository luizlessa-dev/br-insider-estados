"""
Conector: BNMP — Banco Nacional de Mandados de Prisão (CNJ)

Verifica se o CPF possui mandado de prisão ativo em qualquer tribunal do país.
A API pública do CNJ exige credencial via PDPJ-Br (apenas órgãos públicos credenciados).
Este conector usa a Direct Data API v3 como proxy, que já possui convênio com o CNJ.

Custo: consumido pelo mesmo DIRECT_DATA_TOKEN do pipeline B2B.
Endpoint: GET https://apiv3.directd.com.br/api/CNJMandadosPrisao

Env var: DIRECT_DATA_TOKEN
Severity: critico — mandado de prisão ativo é impedimento grave para qualquer contratação.
"""
from __future__ import annotations

import logging
import os
import re
import unicodedata

import requests

from .base import SubradarSource

logger = logging.getLogger("subradar.bnmp_pf")

_DD_TOKEN = os.environ.get("DIRECT_DATA_TOKEN", "")
_DD_V3_BASE = "https://apiv3.directd.com.br/api"

_STATUS_ATIVO = {"ativo", "pendente", "aberto", "vigente", "expedido"}


def _strip(cpf: str) -> str:
    return re.sub(r"\D", "", str(cpf or ""))


_INFOSIMPLES_TOKEN = os.environ.get("INFOSIMPLES_TOKEN", "")
_INFOSIMPLES_BNMP = "https://api.infosimples.com/api/v2/consultas/cnj/mandados-prisao"


def _norm(txt: str) -> str:
    return unicodedata.normalize("NFD", str(txt or "")).encode("ascii", "ignore").decode().upper().strip()


def _via_infosimples(nome: str, nome_mae: str = "") -> list[dict] | None:
    """Mandados de prisão no BNMP/CNJ, buscando por nome.

    O BNMP não indexa CPF — os próprios registros trazem "cpf": "Não Informado"
    — então a busca é por nome e o filtro de homônimo é o nome da mãe, que vem
    em cada mandado. Consulta por CPF respondia sempre "sem dados", inclusive
    para CPF inexistente.

    None quando a consulta falhou; lista vazia quando buscou e nada consta.
    """
    if not _INFOSIMPLES_TOKEN or not nome:
        return None
    try:
        r = requests.post(
            _INFOSIMPLES_BNMP,
            data={"nome": nome, "token": _INFOSIMPLES_TOKEN, "timeout": 600},
            timeout=600,
        )
        j = r.json()
        code = j.get("code")
        # 612 = a busca rodou e não achou ninguém com esse nome.
        if code == 612:
            return []
        if code != 200:
            logger.warning("BNMP Infosimples: code %s (%s)", code, str(j.get("code_message"))[:80])
            return None
        itens = j.get("data") or []
        if not nome_mae:
            return itens
        alvo = _norm(nome_mae)
        filtrados = [m for m in itens if _norm(m.get("mae")) == alvo]
        if itens and not filtrados:
            logger.info("BNMP: %d mandado(s) homônimo(s) descartado(s) pela filiação", len(itens))
        return filtrados
    except Exception as e:
        logger.warning("BNMP Infosimples: %s", e)
        return None


def _consultar_bnmp(cpf: str) -> list[dict] | None:
    """Consulta Direct Data v3 — BNMP mandados de prisão por CPF.

    None quando a consulta não pôde ser feita; lista vazia quando consultou e
    não há mandado. Sem essa distinção, um 403 do Direct Data virava "nenhum
    mandado de prisão encontrado" no laudo.
    """
    if not _DD_TOKEN:
        return None
    try:
        resp = requests.get(
            f"{_DD_V3_BASE}/CNJMandadosPrisao",
            params={"Cpf": cpf, "Token": _DD_TOKEN},
            timeout=20,
        )
        if not resp.ok:
            logger.warning("BNMP: HTTP %d para CPF %s*** — consulta não realizada",
                           resp.status_code, cpf[:3])
            return None
        data = resp.json()
        if isinstance(data, list):
            return data
        if isinstance(data, dict):
            return data.get("data", data.get("mandados", data.get("result", [])))
        return []
    except Exception as e:
        logger.warning("BNMP: %s", e)
        return None


class BNMPMandadosPrisaoPFConnector(SubradarSource):
    """
    Verifica mandados de prisão ativos no BNMP/CNJ via Direct Data v3.
    Só gera alerta se existir mandado com status ativo/vigente.
    Gracioso se DIRECT_DATA_TOKEN ausente.
    """
    fonte = "bnmp_cnj"
    request_delay = 1.0

    def consultar_cnpj(self, cnpj_or_cpf: str, razao_social: str | None = None, **_) -> list[dict]:
        if not _DD_TOKEN:
            logger.debug("bnmp_pf: DIRECT_DATA_TOKEN ausente — pulando")
            return []

        cpf = _strip(cnpj_or_cpf)
        if len(cpf) != 11:
            return []

        cpf_fmt = f"{cpf[:3]}.{cpf[3:6]}.{cpf[6:9]}-{cpf[9:11]}"
        mandados = _consultar_bnmp(cpf) or []

        if not mandados:
            logger.debug("bnmp_pf: sem mandados para CPF %s***", cpf[:3])
            return []

        alertas = []
        for m in mandados:
            status = (
                m.get("status") or
                m.get("situacao") or
                m.get("statusMandado") or ""
            ).lower().strip()

            # Ignora mandados revogados, cumpridos ou cancelados
            if status and not any(s in status for s in _STATUS_ATIVO):
                logger.debug("bnmp_pf: mandado ignorado (status=%s)", status)
                continue

            numero = m.get("numeroCnj") or m.get("numero") or m.get("id") or "s/n"
            tipo = m.get("tipoMandado") or m.get("tipo") or "Prisão"
            crime = m.get("crime") or m.get("delito") or m.get("infracaoPenal") or ""
            tribunal = m.get("tribunal") or m.get("orgaoExpedidor") or m.get("juizo") or ""

            descricao_partes = [f"Mandado n° {numero} — tipo: {tipo}"]
            if crime:
                descricao_partes.append(f"Infração: {crime}")
            if tribunal:
                descricao_partes.append(f"Órgão expedidor: {tribunal}")

            alertas.append({
                "fonte": self.fonte,
                "categoria": "judicial",
                "severidade": "critico",
                "titulo": f"BNMP/CNJ — mandado de prisão ATIVO: {cpf_fmt}",
                "descricao": ". ".join(descricao_partes),
                "url_fonte": "https://bnmp.pdpj.jus.br/",
                "referencia_id": str(numero),
                "is_novo": True,
            })

        if alertas:
            logger.info("bnmp_pf: %d mandado(s) ativo(s) para CPF %s***", len(alertas), cpf[:3])
        return alertas

    def resumo_pf(self, cpf: str, nome: str | None = None) -> dict | None:
        if not _DD_TOKEN:
            return None
        cpf_digits = re.sub(r"\D", "", str(cpf or ""))
        if len(cpf_digits) != 11:
            return None
        # Fonte primária: Infosimples por nome (o Direct Data responde 403).
        cad = {}
        try:
            from .bigdatacorp_negativacoes import dados_cadastrais_pf
            cad = dados_cadastrais_pf(cpf_digits) or {}
        except Exception:
            pass
        mandados = _via_infosimples(nome or cad.get("nome", ""), cad.get("nome_mae", ""))
        if mandados is None:
            mandados = _consultar_bnmp(cpf_digits)
        if mandados is None:
            return {
                "fonte": self.fonte, "categoria": "judicial",
                "status": "pendente", "titulo_secao": "Mandados de Prisão (BNMP/CNJ)",
                "resumo": "Não foi possível consultar — Direct Data indisponível (token ou saldo)",
                "detalhes": {},
            }
        ativos = [
            m for m in mandados
            if not (m.get("status") or m.get("situacao") or m.get("statusMandado") or "").lower().strip()
            or any(s in (m.get("status") or m.get("situacao") or m.get("statusMandado") or "").lower() for s in _STATUS_ATIVO)
        ]
        n = len(ativos)
        return {
            "fonte": self.fonte,
            "categoria": "judicial",
            "status": "critico" if n else "limpo",
            "titulo_secao": "Mandados de Prisão (BNMP/CNJ)",
            "resumo": f"{n} mandado(s) ativo(s)" if n else "Nenhum mandado de prisão encontrado",
            "detalhes": {"total_ativos": n, "mandados": ativos[:5]},
        }
