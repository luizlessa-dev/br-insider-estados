#!/usr/bin/env python3
"""
API FastAPI para Subradar PF

Fluxo assíncrono: POST /consulta cria um job em `sub_pf_consultas` e dispara
uma invocação assíncrona da própria Lambda (worker) pra rodar as ~35 fontes,
sem ficar preso ao limite de 29s do API Gateway. O cliente faz polling em
GET /consulta/{consulta_id} até status virar "concluida" ou "erro".
"""
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import json
import logging
import os
import re
import uuid
from datetime import datetime, timezone

from dotenv import load_dotenv

load_dotenv()

from ingestao.subradar.base import SUPABASE_URL, SUPABASE_KEY, _supabase_headers, upsert, patch

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("subradar-api")

app = FastAPI(title="Subradar PF API", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─────────────────────────────────────────────────────────────
# Models
# ─────────────────────────────────────────────────────────────


class ConsultaRequest(BaseModel):
    cpf: str
    nome: str
    cliente_id: str = "default"
    email: str = ""
    tipo: str = "completa"  # "simples" (fontes gratuitas) | "completa" (+ fontes pagas)
    consentimento_lgpd: bool = True


class ProcessarRequest(BaseModel):
    """Dispara o processamento de uma consulta já existente (criada por outro
    sistema — ex: o backend do site, depois de validar pagamento no Stripe)."""

    cpf: str
    nome: str
    tipo: str = "completa"
    cliente_id: str = ""


class ConsultaAceitaResponse(BaseModel):
    consulta_id: str
    status: str


class ConsultaStatusResponse(BaseModel):
    consulta_id: str
    status: str
    cpf: str
    nome: str
    total_alertas: int | None = None
    criticos: int | None = None
    atencao: int | None = None
    info: int | None = None
    score_proprietario: int | None = None
    score_final: int | None = None
    faixa_final: str | None = None
    erro: str | None = None
    updated_at: str | None = None


# ─────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────


def _strip_cpf(cpf: str) -> str:
    return re.sub(r"\D", "", cpf or "")


def _ciclo_atual() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m")


def _supabase_select(table: str, params: dict) -> list[dict]:
    if not SUPABASE_URL or not SUPABASE_KEY:
        logger.warning("SUPABASE_URL/KEY ausentes — não é possível consultar %s", table)
        return []
    import requests

    resp = requests.get(
        f"{SUPABASE_URL}/rest/v1/{table}",
        params=params,
        headers=_supabase_headers(),
        timeout=15,
    )
    resp.raise_for_status()
    return resp.json()


def _invoke_worker_async(payload: dict) -> None:
    function_name = os.environ.get("AWS_LAMBDA_FUNCTION_NAME")
    if not function_name:
        # Ambiente local (sem Lambda) — roda síncrono pra facilitar testes manuais
        logger.warning("AWS_LAMBDA_FUNCTION_NAME ausente — rodando worker inline (modo local)")
        from handler import _run_worker

        _run_worker(payload)
        return

    import boto3

    region = os.environ.get("AWS_REGION") or os.environ.get("AWS_DEFAULT_REGION") or "us-east-1"
    boto3.client("lambda", region_name=region).invoke(
        FunctionName=function_name,
        InvocationType="Event",
        Payload=json.dumps(payload).encode("utf-8"),
    )


# ─────────────────────────────────────────────────────────────
# Routes
# ─────────────────────────────────────────────────────────────


@app.get("/")
def root():
    return {
        "service": "Subradar PF API",
        "version": "2.0.0",
        "endpoints": {
            "POST /consulta": "Cria consulta de CPF (assíncrona) — retorna consulta_id",
            "GET /consulta/{consulta_id}": "Status/resultado da consulta",
            "GET /health": "Status da API",
        },
    }


@app.get("/health")
def health():
    return {"status": "ok", "timestamp": datetime.now(timezone.utc).isoformat()}


@app.post("/consulta", response_model=ConsultaAceitaResponse, status_code=202)
def criar_consulta(req: ConsultaRequest):
    if not req.consentimento_lgpd:
        raise HTTPException(status_code=400, detail="Consentimento LGPD é obrigatório")

    cpf_digits = _strip_cpf(req.cpf)
    if len(cpf_digits) != 11:
        raise HTTPException(status_code=400, detail="CPF inválido")
    if req.tipo not in ("simples", "completa"):
        raise HTTPException(status_code=400, detail="tipo deve ser 'simples' ou 'completa'")

    consulta_id = str(uuid.uuid4())

    upsert("sub_pf_consultas", [{
        "id": consulta_id,
        "session_id": consulta_id,
        "tipo": req.tipo,
        "status": "pendente",
        "cpf_consultado": cpf_digits,
        "nome_consultado": req.nome,
        "finalidade": "compliance",
        "email_cliente": req.email,
        "consentimento": req.consentimento_lgpd,
    }])

    logger.info("Consulta criada: %s (cpf=%s tipo=%s)", consulta_id, cpf_digits, req.tipo)

    try:
        _invoke_worker_async({
            "job_type": "subradar_pf_consulta",
            "consulta_id": consulta_id,
            "cpf": cpf_digits,
            "nome": req.nome,
            "tipo": req.tipo,
            "cliente_id": req.cliente_id,
        })
    except Exception as e:
        logger.exception("Falha ao disparar worker para consulta %s", consulta_id)
        patch("sub_pf_consultas", {"id": consulta_id}, {
            "status": "erro",
            "erro": f"Falha ao iniciar processamento: {e}"[:500],
        })
        raise HTTPException(status_code=502, detail="Falha ao iniciar processamento da consulta")

    return ConsultaAceitaResponse(consulta_id=consulta_id, status="pendente")


@app.post("/consulta/{consulta_id}/processar", response_model=ConsultaAceitaResponse, status_code=202)
def processar_consulta_existente(consulta_id: str, req: ProcessarRequest):
    """Dispara o worker para uma consulta cuja linha em sub_pf_consultas já foi
    criada por outro sistema (ex: app/api/pf/submit do site, após validar o
    pagamento no Stripe). Não recria a linha — só confirma que ela existe."""
    cpf_digits = _strip_cpf(req.cpf)
    if len(cpf_digits) != 11:
        raise HTTPException(status_code=400, detail="CPF inválido")
    if req.tipo not in ("simples", "completa"):
        raise HTTPException(status_code=400, detail="tipo deve ser 'simples' ou 'completa'")

    existing = _supabase_select("sub_pf_consultas", {
        "id": f"eq.{consulta_id}",
        "select": "id,status",
        "limit": 1,
    })
    if not existing:
        raise HTTPException(status_code=404, detail="Consulta não encontrada")

    logger.info("Disparando processamento: %s (cpf=%s tipo=%s)", consulta_id, cpf_digits, req.tipo)

    try:
        _invoke_worker_async({
            "job_type": "subradar_pf_consulta",
            "consulta_id": consulta_id,
            "cpf": cpf_digits,
            "nome": req.nome,
            "tipo": req.tipo,
            "cliente_id": req.cliente_id,
        })
    except Exception as e:
        logger.exception("Falha ao disparar worker para consulta %s", consulta_id)
        patch("sub_pf_consultas", {"id": consulta_id}, {
            "status": "erro",
            "erro": f"Falha ao iniciar processamento: {e}"[:500],
        })
        raise HTTPException(status_code=502, detail="Falha ao iniciar processamento da consulta")

    return ConsultaAceitaResponse(consulta_id=consulta_id, status="pendente")


@app.get("/consulta/{consulta_id}", response_model=ConsultaStatusResponse)
def status_consulta(consulta_id: str):
    rows = _supabase_select("sub_pf_consultas", {
        "id": f"eq.{consulta_id}",
        "select": "id,status,cpf_consultado,nome_consultado,erro,resultado_id,updated_at",
        "limit": 1,
    })
    if not rows:
        raise HTTPException(status_code=404, detail="Consulta não encontrada")

    job = rows[0]
    resp = ConsultaStatusResponse(
        consulta_id=job["id"],
        status=job["status"],
        cpf=job["cpf_consultado"],
        nome=job["nome_consultado"],
        erro=job.get("erro"),
        updated_at=job.get("updated_at"),
    )

    if job["status"] == "concluida" and job.get("resultado_id"):
        resultados = _supabase_select("sub_pf_resultados", {
            "id": f"eq.{job['resultado_id']}",
            "select": "score_risco,faixa_risco,total_alertas,score_detalhes",
            "limit": 1,
        })
        if resultados:
            r = resultados[0]
            detalhes = r.get("score_detalhes") or {}
            total = r.get("total_alertas") or 0
            criticos = detalhes.get("criticos") or 0
            atencao = detalhes.get("atencao") or 0
            resp.total_alertas = total
            resp.criticos = criticos
            resp.atencao = atencao
            resp.info = max(total - criticos - atencao, 0)
            resp.score_final = r.get("score_risco")
            resp.faixa_final = r.get("faixa_risco")
            resp.score_proprietario = detalhes.get("score")

    return resp


if __name__ == "__main__":
    import uvicorn

    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
