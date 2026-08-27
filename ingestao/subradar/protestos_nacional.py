"""
Conector: Protestos Nacionais — Direct Data / IEPTB

Fonte: Direct Data (directd.com.br) — única plataforma homologada pelo CENPROT para
       oferecer consulta nacional de protestos IEPTB via API

Cobertura: TODOS os estados do Brasil (via rede IEPTB/CENPROT)
API: GET apiv3.directd.com.br/api/ProtestosOnline
Auth: Token por query string (?token=...) — obtido em app.directd.com.br após cadastro
Formato: JSON
Modelo: pay-per-use, pré ou pós-pago, sem contrato mínimo

── CUSTOS ────────────────────────────────────────────────────────────────────
Modelo de cobrança: por consulta individual realizada (pay-per-use)
Recarga pré-paga: R$ 50, 100, 250, 500, 750, 1.000 ou 5.000
Desconto progressivo: quanto maior o volume, menor o custo unitário
Custo unitário estimado: não publicado — varia por volume contratado
  Referência de mercado (concorrentes similares): R$ 0,50 a R$ 2,50 / consulta
  Para base de 50 CNPJs/mês (plano Profissional): R$ 25–125/mês estimado
Contato para cotação: comercial@directd.com.br | (11) 91371-9902

── CADASTRO ──────────────────────────────────────────────────────────────────
1. Acessar app.directd.com.br e criar conta gratuita
2. Recarregar créditos (mínimo R$ 50 pré-pago)
3. Gerar token de acesso no painel
4. Configurar DIRECT_DATA_TOKEN nas variáveis de ambiente

── VARIÁVEL DE AMBIENTE ─────────────────────────────────────────────────────
DIRECT_DATA_TOKEN=seu_token_aqui
"""
from __future__ import annotations

import logging
import re

import requests

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual, FonteIndisponivel

logger = logging.getLogger("subradar.protestos_nacional")

import os
DIRECT_DATA_TOKEN = os.environ.get("DIRECT_DATA_TOKEN", "")
DIRECT_DATA_BASE  = "https://apiv3.directd.com.br/api"


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", str(cnpj or ""))


def _fmt(cnpj: str) -> str:
    c = _strip(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _resumo_protestos(data: dict) -> str:
    """Gera descrição legível a partir do JSON da Direct Data."""
    total = data.get("numeroTotalProtestos", 0)
    valor = data.get("valorTotalProtestos", 0)
    estados = [p.get("estado", "") for p in data.get("protestos", []) if p.get("estado")]

    partes = [f"{total} protesto(s) registrado(s) em todo o Brasil."]
    if valor:
        try:
            partes.append(f"Valor total: R$ {float(valor):,.2f}.")
        except (ValueError, TypeError):
            partes.append(f"Valor total: R$ {valor}.")
    if estados:
        partes.append(f"Estado(s): {', '.join(sorted(set(estados)))}.")
    partes.append("Consulte a Direct Data para detalhes por cartório.")
    return " ".join(partes)


class ProtestosNacionalConnector(SubradarSource):
    fonte = "protestos_nacional"
    request_delay = 1.0

    def consultar_cnpj(self, cnpj: str, razao_social: str | None = None,
                       **_) -> list[dict]:
        cnpj_digits = _strip(cnpj)
        cnpj_fmt    = _fmt(cnpj_digits)
        ciclo       = _ciclo_atual()

        if not DIRECT_DATA_TOKEN:
            raise FonteIndisponivel("DIRECT_DATA_TOKEN nao configurado")

        try:
            resp = self._session.get(
                f"{DIRECT_DATA_BASE}/ProtestosOnline",
                params={
                    "documento": cnpj_digits,
                    "token": DIRECT_DATA_TOKEN,
                },
                timeout=self.timeout,
            )
        except Exception as e:
            raise FonteIndisponivel("Direct Data inacessivel", str(e)[:120])

        # Sem protesto e "consultei e nao achei". Token invalido, conta sem
        # credito ou 403 e "nao consegui consultar" — nao pode virar lista vazia.
        if resp.status_code == 401:
            raise FonteIndisponivel("Direct Data: token invalido", "HTTP 401")
        if resp.status_code == 402:
            raise FonteIndisponivel("Direct Data: conta sem creditos", "HTTP 402")
        if not resp.ok:
            raise FonteIndisponivel("Direct Data indisponivel", f"HTTP {resp.status_code}")

        try:
            data = resp.json()
        except Exception:
            raise FonteIndisponivel("Direct Data: resposta nao-JSON")

        # Sem protestos
        consta = data.get("constamProtestos", False)
        if not consta:
            return []

        total = data.get("numeroTotalProtestos", 0)
        if not total:
            return []

        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, data)
        if not mudou:
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt,
            "fonte": self.fonte,
            "ciclo": ciclo,
            "hash_dados": hash_novo,
            "dados": {
                "total_protestos": total,
                "valor_total": data.get("valorTotalProtestos"),
                "estados": [p.get("estado") for p in data.get("protestos", [])],
            },
        }])

        # Severidade: valor total determina criticidade
        valor = 0.0
        try:
            valor = float(data.get("valorTotalProtestos") or 0)
        except (ValueError, TypeError):
            pass

        if valor > 100_000 or total > 5:
            severidade = "critico"
        elif valor > 10_000 or total > 1:
            severidade = "atencao"
        else:
            severidade = "atencao"

        descricao = _resumo_protestos(data)

        alertas = [{
            "cnpj": cnpj_fmt,
            "ciclo": ciclo,
            "fonte": self.fonte,
            "categoria": "credito",
            "severidade": severidade,
            "titulo": f"Protestos nacionais: {total} registro(s) — IEPTB/CENPROT",
            "descricao": descricao,
            "url_fonte": "https://www.directd.com.br/protestos-ieptb",
            "is_novo": True,
        }]

        # Gera alertas por estado para visibilidade granular
        for protesto in data.get("protestos", []):
            estado = protesto.get("estado", "")
            cartorios = protesto.get("cartorios", [])
            qtd_estado = sum(len(c.get("titulos", [])) for c in cartorios)
            if qtd_estado and estado:
                alertas.append({
                    "cnpj": cnpj_fmt,
                    "ciclo": ciclo,
                    "fonte": self.fonte,
                    "categoria": "credito",
                    "severidade": "info",
                    "titulo": f"Protesto(s) em {estado} — {qtd_estado} título(s)",
                    "descricao": (
                        f"{qtd_estado} título(s) protestado(s) no estado {estado}. "
                        f"Cartório(s): {', '.join(c.get('cidade','') for c in cartorios if c.get('cidade'))}."
                    ),
                    "url_fonte": "https://www.directd.com.br/protestos-ieptb",
                    "is_novo": True,
                })

        logger.info("Protestos Nacional: %d alertas para %s (%d protesto(s))", len(alertas), cnpj_fmt, total)
        return alertas


class ProtestosNacionalPFConnector(SubradarSource):
    """
    Consulta protestos em cartório para CPF via Direct Data (endpoint /Protestos).
    Gracioso quando sem crédito — retorna vazio sem quebrar o pipeline.
    Assim que houver crédito na conta directd.com.br, passa a funcionar.
    """
    fonte = "protestos_nacional_pf"
    request_delay = 1.0

    def consultar_cnpj(self, cnpj_or_cpf: str, **_) -> list[dict]:
        cpf = _strip(cnpj_or_cpf)
        if len(cpf) != 11:
            return []
        if not DIRECT_DATA_TOKEN:
            logger.debug("protestos_pf: DIRECT_DATA_TOKEN ausente — pulando")
            return []

        cpf_fmt = f"{cpf[:3]}.{cpf[3:6]}.{cpf[6:9]}-{cpf[9:]}"

        try:
            resp = self._session.get(
                f"{DIRECT_DATA_BASE}/Protestos",
                params={"cpf": cpf, "token": DIRECT_DATA_TOKEN},
                timeout=self.timeout,
            )
        except Exception as e:
            logger.warning("protestos_pf: erro de rede — %s", e)
            return []

        if resp.status_code == 403:
            body = resp.json() if resp.text else {}
            msg = (body.get("metaDados") or {}).get("resultado", "")
            if "Saldo" in msg:
                logger.info("protestos_pf: sem crédito na conta Direct Data — pulando")
            else:
                logger.warning("protestos_pf: HTTP 403 — %s", msg)
            return []

        if not resp.ok:
            logger.warning("protestos_pf: HTTP %s para CPF %s***", resp.status_code, cpf[:3])
            return []

        try:
            data = resp.json()
        except Exception:
            return []

        consta = data.get("constamProtestos", False)
        if not consta:
            logger.debug("protestos_pf: nenhum protesto para CPF %s***", cpf[:3])
            return []

        total = data.get("numeroTotalProtestos", 0) or 0
        valor = data.get("valorTotalProtestos", 0) or 0
        severidade = "critico" if total >= 3 else "atencao"

        try:
            valor_fmt = f"R$ {float(valor):,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")
        except Exception:
            valor_fmt = f"R$ {valor}"

        estados = sorted({p.get("estado", "") for p in data.get("protestos", []) if p.get("estado")})
        desc = (
            f"{total} protesto(s) encontrado(s) em cartório para o CPF {cpf_fmt}. "
            + (f"Valor total: {valor_fmt}. " if valor else "")
            + (f"Estado(s): {', '.join(estados)}. " if estados else "")
            + "Fonte: IEPTB/CENPROT via Direct Data."
        )

        logger.info("protestos_pf: %d protesto(s) para CPF %s***", total, cpf[:3])
        return [{
            "fonte": self.fonte,
            "categoria": "financeiro",
            "severidade": severidade,
            "titulo": f"Protestos em cartório — {total} registro(s): {cpf_fmt}",
            "descricao": desc,
            "url_fonte": "https://www.directd.com.br/protestos-ieptb",
            "is_novo": True,
        }]

    def resumo_pf(self, cpf: str, nome: str | None = None) -> dict | None:
        alertas = self.consultar_cnpj(cpf)
        if not alertas:
            # Sem crédito ou sem protesto — distinguir pelo log não é possível aqui,
            # então retornamos None para não inflar o laudo com "sem protestos" não verificados
            return None
        n = len(alertas)
        return {
            "fonte": self.fonte,
            "categoria": "financeiro",
            "status": "critico" if any(a.get("severidade") == "critico" for a in alertas) else "alerta",
            "titulo_secao": "Protestos em Cartório (IEPTB Nacional)",
            "resumo": alertas[0].get("titulo", f"{n} protesto(s) encontrado(s)"),
            "detalhes": {"total": n, "descricao": alertas[0].get("descricao", "")},
        }
