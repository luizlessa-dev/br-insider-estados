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

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

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

    def consultar_cnpj(self, cnpj: str) -> list[dict]:
        cnpj_digits = _strip(cnpj)
        cnpj_fmt    = _fmt(cnpj_digits)
        ciclo       = _ciclo_atual()

        if not DIRECT_DATA_TOKEN:
            logger.info("Protestos Nacional: DIRECT_DATA_TOKEN não configurado — fonte indisponível")
            return []

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
            logger.warning("Protestos Nacional: erro na requisição para %s: %s", cnpj_fmt, e)
            return []

        if resp.status_code == 401:
            logger.error("Protestos Nacional: token inválido ou sem créditos")
            return []
        if resp.status_code == 402:
            logger.error("Protestos Nacional: sem créditos na conta Direct Data")
            return []
        if not resp.ok:
            logger.warning("Protestos Nacional: HTTP %s para %s", resp.status_code, cnpj_fmt)
            return []

        try:
            data = resp.json()
        except Exception:
            logger.warning("Protestos Nacional: resposta não-JSON para %s", cnpj_fmt)
            return []

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
