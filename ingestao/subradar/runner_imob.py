"""
Subradar Imob — pipeline de compliance imobiliário (matrícula/cartório/endereço)

Regra que rege este runner: fonte que não respondeu devolve "pendente", nunca
"limpo", e laudo com pendência não é entregue. Ver `entrega_imob.py`.

Estado da cobertura em 27/08/2026 — auditado interceptando as chamadas HTTP de
cada conector. Das cinco fontes originais, nenhuma consultava nada: quatro eram
stubs que retornavam None (e sumiam do laudo) e a do Datajud chamava um método
inexistente, engolia o erro e concluía "Nenhuma ação judicial encontrada". Hoje:

  processos_proprietario   consulta de verdade (BigDataCorp/processes)
  datajud_acoes_imovel     sem cobertura — API pública do CNJ não publica partes
  cnpj_cnj_registros       sem cobertura — depende de contrato ONR
  onus_reais               sem cobertura — depende de contrato ONR
  divida_ativa_imovel      sem cobertura — sem fonte nacional de IPTU
  bigdatacorp_pessoas      sem cobertura — dataset fora do plano

As "sem cobertura" aparecem no laudo declarando a lacuna, em vez de sumir dele.
Não retêm a entrega: não houve falha, houve limite conhecido do produto.

Uso:
  python3 -m ingestao.subradar.runner_imob \
    --matricula 123456-7.89.0123.4.56789 --cartorio-id "0123" --dry-run

  python3 -m ingestao.subradar.runner_imob \
    --matricula 123456-7.89.0123.4.56789 --consulta-id <UUID> \
    --email-cliente cliente@exemplo.com
"""
from __future__ import annotations

import argparse
import logging
import re
import sys
from datetime import datetime, timezone
from uuid import UUID

import requests

from .base_imob import (
    upsert, delete_where, _ciclo_atual, _supabase_headers,
    SUPABASE_URL, SUPABASE_KEY, STATUS_INCOMPLETO, STATUS_SEM_COBERTURA,
)

# Conectores Imob
from .cnpj_cnj_imob import CNPJCNJImobConnector, OususReaisConnector
from .datajud_imob import DatajudImobConnector
from .divida_ativa_imob import DividaAtivaImobConnector
from .bigdatacorp_imob import BigDataCorpImobConnector
from .processos_proprietario_imob import ProcessosProprietarioImobConnector

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
)
logger = logging.getLogger("subradar.runner_imob")


FONTES_IMOB = [
    ProcessosProprietarioImobConnector(),  # judicial — única que consulta hoje
    DatajudImobConnector(),                # judicial — lacuna declarada
    CNPJCNJImobConnector(),                # titularidade — lacuna declarada
    OususReaisConnector(),                 # ônus reais — lacuna declarada
    DividaAtivaImobConnector(),            # IPTU — lacuna declarada
    BigDataCorpImobConnector(),            # negativações — lacuna declarada
]


def _validar_matricula(matricula: str) -> bool:
    """Valida formato básico de matrícula (NNNNNN-D.DD.DDDD.D.DDDDD)."""
    return bool(re.match(r"^\d{6}-\d\.\d{2}\.\d{4}\.\d\.\d{5}$", matricula.strip()))


def _patch_consulta(consulta_id: str | None, campos: dict) -> None:
    """Atualiza sub_imob_consultas. O runner antigo nunca escrevia nada aqui:
    a consulta ficava 'pendente' para sempre, mesmo com o pipeline concluído."""
    if not consulta_id or not SUPABASE_URL or not SUPABASE_KEY:
        return
    try:
        r = requests.patch(
            f"{SUPABASE_URL}/rest/v1/sub_imob_consultas",
            headers=_supabase_headers(), params={"id": f"eq.{consulta_id}"},
            json=campos, timeout=30,
        )
        if not r.ok:
            logger.warning("patch consulta %s: HTTP %s %s", consulta_id, r.status_code, r.text[:200])
    except Exception as e:
        logger.warning("patch consulta %s falhou: %s", consulta_id, e)


def _buscar_proprietario_cpf_cnpj(consulta_id: str | None) -> str | None:
    """CPF/CNPJ do proprietário registrado no pedido."""
    if not consulta_id or not SUPABASE_URL or not SUPABASE_KEY:
        return None
    try:
        r = requests.get(
            f"{SUPABASE_URL}/rest/v1/sub_imob_consultas",
            headers=_supabase_headers(),
            params={"id": f"eq.{consulta_id}", "select": "proprietario_cpf_cnpj"},
            timeout=30,
        )
        if not r.ok:
            logger.warning("busca do proprietário: HTTP %s", r.status_code)
            return None
        linhas = r.json()
        if not linhas:
            logger.warning("consulta %s não encontrada em sub_imob_consultas", consulta_id)
            return None
        return linhas[0].get("proprietario_cpf_cnpj") or None
    except Exception as e:
        logger.warning("erro ao buscar proprietário: %s", e)
        return None


def calcular_score_risco(dados: list[dict], alertas: list[dict]) -> tuple[int, str]:
    """
    Score de risco: 0 (sem risco) a 100 (risco máximo).

    Pesos por severidade do alerta: critico=30 · atencao=10 · info=2.

    Faixas:
      0–20 verde · 21–50 amarelo · 51–80 laranja · 81–100 vermelho

    Com qualquer fonte pendente a faixa vira "indeterminado", independente do
    score. Score baixo calculado sobre fonte que não respondeu é a mesma
    armadilha que quase entregou um laudo VERDE no Subradar PF para alguém com
    ação penal em curso — a ausência de achado não é achado de ausência.
    """
    score = 0
    for alerta in alertas:
        sev = alerta.get("severidade", "info")
        if sev == "critico":
            score += 30
        elif sev == "atencao":
            score += 10
        elif sev == "info":
            score += 2

    score = min(100, score)

    if any(str(d.get("status") or "").lower() in STATUS_INCOMPLETO for d in dados):
        return score, "indeterminado"

    if score <= 20:
        faixa = "verde"
    elif score <= 50:
        faixa = "amarelo"
    elif score <= 80:
        faixa = "laranja"
    else:
        faixa = "vermelho"

    return score, faixa


def rodar_imovel(
    matricula: str,
    cartorio_id: str | None = None,
    consulta_id: str | None = None,
    email_cliente: str | None = None,
    dry_run: bool = False,
) -> dict:
    """Executa o pipeline Imob para uma matrícula e devolve o resultado consolidado."""
    matricula = (matricula or "").strip()
    if not matricula:
        logger.error("Matrícula vazia")
        sys.exit(1)

    if not _validar_matricula(matricula):
        logger.error("Matrícula inválida: %s (esperado NNNNNN-D.DD.DDDD.D.DDDDD)", matricula)
        _patch_consulta(consulta_id, {
            "status": "erro",
            "mensagem_erro": f"Matrícula em formato inválido: {matricula}"[:500],
        })
        sys.exit(1)

    if consulta_id:
        try:
            UUID(consulta_id)
        except (ValueError, TypeError):
            logger.error("consulta_id inválido: %s", consulta_id)
            sys.exit(1)

    logger.info("iniciando pipeline imob: matrícula=%s cartório=%s consulta=%s dry_run=%s",
                matricula, cartorio_id, consulta_id, dry_run)

    ciclo = _ciclo_atual()
    agora = datetime.now(timezone.utc).isoformat()

    if not dry_run:
        _patch_consulta(consulta_id, {"status": "processando", "iniciado_em": agora})

    proprietario_cpf_cnpj = _buscar_proprietario_cpf_cnpj(consulta_id)
    if not proprietario_cpf_cnpj:
        logger.warning("proprietário não informado — a seção judicial sairá pendente")

    dados_imob: list[dict] = []
    alertas_imob: list[dict] = []

    for fonte in FONTES_IMOB:
        logger.info("consultando %s", fonte.fonte)
        try:
            resultado = fonte.consultar_imovel(
                matricula, cartorio_id,
                proprietario_cpf_cnpj=proprietario_cpf_cnpj,
            )
        except Exception as e:
            # Exceção não pode virar seção ausente nem seção limpa: vira
            # pendência, e pendência retém a entrega.
            logger.exception("erro em %s: %s", fonte.fonte, e)
            resultado = {
                "fonte": fonte.fonte, "categoria": "erro", "status": "pendente",
                "titulo_secao": fonte.fonte,
                "resumo": f"Não foi possível consultar — {type(e).__name__}: {str(e)[:150]}",
                "detalhes": {},
            }

        if resultado is None:
            # Conector que devolve None não some mais do laudo. Se não sabe
            # dizer o que aconteceu, o laudo não pode afirmar que está limpo.
            logger.warning("%s: devolveu None — registrado como pendente", fonte.fonte)
            resultado = {
                "fonte": fonte.fonte, "categoria": "indefinida", "status": "pendente",
                "titulo_secao": fonte.fonte,
                "resumo": "Não foi possível consultar — conector não devolveu resultado",
                "detalhes": {},
            }

        dados_imob.append({
            "matricula": matricula,
            "ciclo": ciclo,
            "fonte": fonte.fonte,
            "categoria": resultado.get("categoria", ""),
            "status": resultado.get("status", "pendente"),
            "titulo_secao": resultado.get("titulo_secao", ""),
            "resumo": resultado.get("resumo", ""),
            "detalhes": resultado.get("detalhes", {}),
        })
        logger.info("%s: status=%s", fonte.fonte, resultado.get("status"))

    for dado in dados_imob:
        status = str(dado.get("status") or "").lower()
        if status in ("alerta", "critico"):
            alertas_imob.append({
                "matricula": matricula, "ciclo": ciclo,
                "fonte": dado.get("fonte", ""),
                "categoria": dado.get("categoria", ""),
                "severidade": "critico" if status == "critico" else "atencao",
                "titulo": dado.get("titulo_secao", ""),
                "descricao": dado.get("resumo", ""),
                "url_fonte": None,
            })
        elif status in STATUS_INCOMPLETO:
            # A pendência precisa aparecer como alerta para o operador ver na
            # tela, mas com severidade info: fonte que não respondeu não é
            # achado de risco e não pode inflar o score.
            alertas_imob.append({
                "matricula": matricula, "ciclo": ciclo,
                "fonte": dado.get("fonte", ""),
                "categoria": dado.get("categoria", ""),
                "severidade": "info",
                "titulo": f"Fonte não consultada: {dado.get('titulo_secao', '')}",
                "descricao": dado.get("resumo", ""),
                "url_fonte": None,
            })

    criticos = len([d for d in dados_imob if d.get("status") == "critico"])
    pendentes = [d for d in dados_imob
                 if str(d.get("status") or "").lower() in STATUS_INCOMPLETO]
    sem_cob = [d for d in dados_imob
               if str(d.get("status") or "").lower() in STATUS_SEM_COBERTURA]
    score, faixa = calcular_score_risco(dados_imob, alertas_imob)

    resultado_consolidado = {
        "matricula": matricula,
        "ciclo": ciclo,
        "score_risco": score,
        "faixa_risco": faixa,
        "total_criticos": criticos,
        "total_alertas": len([a for a in alertas_imob if a.get("severidade") != "info"]),
        "total_info": len([a for a in alertas_imob if a.get("severidade") == "info"]),
    }

    logger.info(
        "resumo: score=%d faixa=%s fontes=%d consultadas=%d pendentes=%d sem_cobertura=%d criticos=%d",
        score, faixa, len(dados_imob),
        len(dados_imob) - len(pendentes) - len(sem_cob),
        len(pendentes), len(sem_cob), criticos,
    )
    for d in pendentes:
        logger.warning("PENDENTE %s — %s", d["fonte"], d["resumo"])

    if dry_run or not SUPABASE_URL or not SUPABASE_KEY:
        logger.info("dry_run ativo ou sem credenciais — dados não persistidos")
        return {"dados": dados_imob, "alertas": alertas_imob,
                "resultado": resultado_consolidado, "pendentes": pendentes}

    upsert("sub_imob_dados", dados_imob)
    # Alertas não têm chave única: sem limpar, reprocessar a matrícula empilha
    # os alertas da tentativa anterior sobre os desta.
    delete_where("sub_imob_alertas", {"matricula": matricula, "ciclo": ciclo})
    upsert("sub_imob_alertas", alertas_imob)
    upsert("sub_imob_resultados", [resultado_consolidado])
    _patch_consulta(consulta_id, {
        "status": "concluido",
        "concluido_em": datetime.now(timezone.utc).isoformat(),
        "mensagem_erro": None,
    })
    logger.info("pipeline concluído e salvo no Supabase")

    if email_cliente and consulta_id:
        from .entrega_imob import entregar
        entregar(consulta_id, matricula, email_cliente)
    else:
        logger.info("sem e-mail de cliente — entrega não disparada")

    return {"dados": dados_imob, "alertas": alertas_imob,
            "resultado": resultado_consolidado, "pendentes": pendentes}


def main():
    parser = argparse.ArgumentParser(
        description="Subradar Imob — pipeline de compliance imobiliário",
    )
    parser.add_argument("--matricula", required=True, help="Matrícula do imóvel")
    parser.add_argument("--cartorio-id", help="ID CNIB do cartório")
    parser.add_argument("--consulta-id", help="UUID da consulta em sub_imob_consultas")
    # Nome antigo mantido: o workflow passava --cliente-id com o UUID da consulta.
    parser.add_argument("--cliente-id", dest="consulta_id_legado",
                        help="obsoleto — mesmo efeito de --consulta-id")
    parser.add_argument("--email-cliente", help="E-mail para entrega do dossiê")
    parser.add_argument("--dry-run", action="store_true", help="Não salvar no Supabase")

    args = parser.parse_args()
    consulta_id = args.consulta_id or args.consulta_id_legado

    if not args.dry_run and not consulta_id:
        logger.error("--consulta-id obrigatório (exceto em --dry-run)")
        sys.exit(1)

    try:
        rodar_imovel(
            matricula=args.matricula,
            cartorio_id=args.cartorio_id,
            consulta_id=consulta_id,
            email_cliente=args.email_cliente,
            dry_run=args.dry_run,
        )
    except SystemExit:
        raise
    except Exception as e:
        logger.exception("pipeline falhou: %s", e)
        _patch_consulta(consulta_id, {
            "status": "erro", "mensagem_erro": f"{type(e).__name__}: {str(e)[:400]}",
        })
        sys.exit(1)


if __name__ == "__main__":
    main()
