"""
Conector: Escavador — Processos Judiciais por CPF (Pessoa Física)

Usa o mesmo endpoint /api/v2/envolvido/processos do conector PJ,
passando CPF (11 dígitos) no campo cpf_cnpj.

Severidade:
  critico — execução penal, prisão, condenação criminal, improbidade
  atencao — execução fiscal, trabalhista, cível de alto valor
  info     — demais classes

Custo: créditos Escavador (mesma conta do conector PJ).
Env var: ESCAVADOR_API_KEY

Gracioso se saldo zerado ou chave ausente — loga aviso e retorna [].
"""
from __future__ import annotations

import logging
import re
import time

import requests

from .base import SubradarSource

logger = logging.getLogger("subradar.escavador_pf")

from .escavador import (
    ESCAVADOR_KEY,
    ESCAVADOR_BASE,
    _headers,
    _severidade_por_titulo,
    _tribunal_sigla,
    _CRITICO_KW,
    _ATENCAO_KW,
)

# Classes processuais adicionais relevantes para PF
_CRITICO_KW_PF = _CRITICO_KW + [
    "execução penal", "execucao penal", "ação penal", "acao penal",
    "condenação", "condenacao", "prisão", "prisao", "homicídio", "homicidio",
    "tráfico", "trafico", "sequestro", "estelionato", "fraude",
    "lavagem de dinheiro", "corrupção", "corrupcao", "peculato",
]
_ATENCAO_KW_PF = _ATENCAO_KW + [
    "alimentos", "divórcio", "divorcio", "inventário", "inventario",
    "usucapião", "usucapiao", "despejo", "cobrança", "cobranca",
    "indenização", "indenizacao",
]


def _sev_pf(titulo: str) -> str:
    t = titulo.lower()
    if any(kw in t for kw in _CRITICO_KW_PF):
        return "critico"
    if any(kw in t for kw in _ATENCAO_KW_PF):
        return "atencao"
    return "info"


def _buscar_processos_cpf(cpf: str) -> list[dict]:
    todos: list[dict] = []
    page = 1

    while True:
        try:
            r = requests.get(
                f"{ESCAVADOR_BASE}/envolvido/processos",
                params={"cpf_cnpj": cpf, "page": page, "limit": 50},
                headers=_headers(),
                timeout=30,
            )
        except Exception as e:
            logger.warning("Escavador PF: erro de rede pág %d: %s", page, e)
            break

        if r.status_code in (401, 402, 403):
            msg = r.json().get("error", "") if "json" in r.headers.get("Content-Type", "") else ""
            logger.warning("Escavador PF: sem acesso (HTTP %d) — %s", r.status_code, msg)
            break
        if r.status_code == 404 or not r.ok:
            break

        try:
            data = r.json()
        except Exception:
            break

        items = data.get("items") or data.get("data") or []
        todos.extend(items)

        meta = data.get("meta") or {}
        last_page = meta.get("last_page") or 1
        if page >= last_page or not items:
            break

        page += 1
        time.sleep(0.3)

    return todos


class EscavadorPFConnector(SubradarSource):
    """
    Busca processos judiciais vinculados ao CPF via Escavador API v2.
    Gracioso se ESCAVADOR_API_KEY ausente ou saldo zerado.
    """
    fonte = "escavador_pf"
    request_delay = 1.0

    def consultar_cnpj(self, cnpj_or_cpf: str, razao_social: str | None = None, **_) -> list[dict]:
        if not ESCAVADOR_KEY:
            logger.debug("escavador_pf: ESCAVADOR_API_KEY ausente — pulando")
            return []

        cpf = re.sub(r"\D", "", str(cnpj_or_cpf or ""))
        if len(cpf) != 11:
            return []

        cpf_fmt = f"{cpf[:3]}.{cpf[3:6]}.{cpf[6:9]}-{cpf[9:11]}"
        processos = _buscar_processos_cpf(cpf)

        if not processos:
            logger.debug("escavador_pf: nenhum processo para CPF %s***", cpf[:3])
            return []

        alertas = []
        for proc in processos:
            titulo = proc.get("titulo") or proc.get("classe") or ""
            num = proc.get("numero_cnj") or proc.get("numero") or "s/n"
            trib = _tribunal_sigla(proc)
            dt = (proc.get("data_ultima_movimentacao") or "")[:10]
            polo_a = proc.get("titulo_polo_ativo") or ""
            polo_p = proc.get("titulo_polo_passivo") or ""

            sev = _sev_pf(titulo)

            desc_partes = [f"Processo {num} ({trib}) — {titulo}"]
            if polo_a:
                desc_partes.append(f"Polo ativo: {polo_a[:80]}")
            if polo_p:
                desc_partes.append(f"Polo passivo: {polo_p[:80]}")
            if dt:
                desc_partes.append(f"Última movimentação: {dt}")

            url = f"https://www.escavador.com/processos/{num.replace('.', '').replace('/', '-').replace(' ', '')}"

            alertas.append({
                "fonte": self.fonte,
                "categoria": "judicial",
                "severidade": sev,
                "titulo": f"Escavador — {titulo[:80]}: {cpf_fmt}",
                "descricao": ". ".join(desc_partes),
                "url_fonte": url,
                "referencia_id": num,
                "is_novo": True,
            })

        logger.info("escavador_pf: %d processo(s) para CPF %s***", len(alertas), cpf[:3])
        return alertas
