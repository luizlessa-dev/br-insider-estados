"""
Subradar Imob — pipeline de compliance imobiliário (matrícula/cartório/endereço)

Uso:
  # Dry-run
  python3 -m ingestao.subradar.runner_imob \
    --matricula 123456-7.89.0123.4.56789 \
    --cartorio-id "0123" \
    --dry-run

  # Run real com cliente
  python3 -m ingestao.subradar.runner_imob \
    --matricula 123456-7.89.0123.4.56789 \
    --cartorio-id "0123" \
    --cliente-id <UUID>
"""
from __future__ import annotations

import argparse
import logging
import re
import sys
from uuid import UUID

from .base_imob import upsert, _ciclo_atual, SUPABASE_URL, SUPABASE_KEY

# Conectores Imob
from .cnpj_cnj_imob import CNPJCNJImobConnector
from .datajud_imob import DatajudImobConnector
from .divida_ativa_imob import DividaAtivaImobConnector
from .bigdatacorp_imob import BigDataCorpImobConnector

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
)
logger = logging.getLogger("subradar.runner_imob")


FONTES_IMOB = [
    CNPJCNJImobConnector(),           # Titularidade (placeholder)
    DatajudImobConnector(),            # Ações judiciais sobre imóvel
    DividaAtivaImobConnector(),        # Dívida ativa (IPTU, municipal)
    BigDataCorpImobConnector(),        # Negativações de envolvidos
]


def _validar_matricula(matricula: str) -> bool:
    """Valida formato básico de matrícula (NNNNNN-D.DD.DDDD.D.DDDDD)."""
    return bool(re.match(r"^\d{6}-\d\.\d{2}\.\d{4}\.\d\.\d{5}$", matricula.strip()))


def _fmt_matricula(matricula: str) -> str:
    """Formata matrícula removendo espaços."""
    return matricula.strip() if matricula else ""


def calcular_score_risco(alertas: list[dict], criticos: int) -> tuple[int, str]:
    """
    Score de risco: 0 (sem risco) a 100 (risco máximo).

    Metodologia:
      Cada alerta contribui com pontos proporcional à severidade.
      Pesos: critico=30 · atencao=10 · info=2
      Score final clamped em [0, 100].

    Faixas:
      0–20  → VERDE
      21–50 → AMARELO
      51–80 → LARANJA
      81–100 → VERMELHO
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
    cliente_id: str | None = None,
    dry_run: bool = False,
) -> None:
    """
    Executa pipeline Imob para uma matrícula.

    Args:
      matricula: Formato NNNNNN-D.DD.DDDD.D.DDDDD
      cartorio_id: ID CNIB do cartório (ex: "0123")
      cliente_id: UUID do cliente (se None, modo dry-run forçado)
      dry_run: Se True, não salva no Supabase
    """
    matricula = _fmt_matricula(matricula)
    if not matricula:
        logger.error("Matrícula vazia")
        sys.exit(1)

    if not _validar_matricula(matricula):
        logger.error("Matrícula inválida: %s (esperado NNNNNN-D.DD.DDDD.D.DDDDD)", matricula)
        sys.exit(1)

    try:
        UUID(cliente_id)
    except (ValueError, TypeError):
        logger.error("cliente_id inválido: %s", cliente_id)
        sys.exit(1)

    logger.info("iniciando pipeline imob: matrícula=%s cartório=%s cliente=%s dry_run=%s",
                matricula, cartorio_id, cliente_id, dry_run)

    ciclo = _ciclo_atual()

    # Recolher dados de cada fonte
    dados_imob: list[dict] = []
    alertas_imob: list[dict] = []

    for fonte in FONTES_IMOB:
        logger.info("consultando %s", fonte.fonte)
        try:
            resultado = fonte.consultar_imovel(matricula, cartorio_id)
            if resultado is None:
                logger.debug("%s: não aplicável", fonte.fonte)
                continue

            # Montar registro de sub_imob_dados
            dado = {
                "matricula": matricula,
                "ciclo": ciclo,
                "fonte": fonte.fonte,
                "categoria": resultado.get("categoria", ""),
                "status": resultado.get("status", "pendente"),
                "titulo_secao": resultado.get("titulo_secao", ""),
                "resumo": resultado.get("resumo", ""),
                "detalhes": resultado.get("detalhes", {}),
            }
            dados_imob.append(dado)
            logger.info("%s: status=%s", fonte.fonte, resultado.get("status"))

        except Exception as e:
            logger.exception("erro em %s: %s", fonte.fonte, e)
            alertas_imob.append({
                "matricula": matricula,
                "ciclo": ciclo,
                "fonte": fonte.fonte,
                "categoria": "erro",
                "severidade": "info",
                "titulo": f"Erro ao processar {fonte.fonte}",
                "descricao": str(e)[:200],
            })

    # Extrair alertas de dados_imob
    for dado in dados_imob:
        status = dado.get("status", "limpo")
        if status in ("alerta", "critico"):
            alertas_imob.append({
                "matricula": matricula,
                "ciclo": ciclo,
                "fonte": dado.get("fonte", ""),
                "categoria": dado.get("categoria", ""),
                "severidade": "critico" if status == "critico" else "atencao",
                "titulo": dado.get("titulo_secao", ""),
                "descricao": dado.get("resumo", ""),
                "url_fonte": None,
            })

    # Calcular score
    criticos = len([d for d in dados_imob if d.get("status") == "critico"])
    score, faixa = calcular_score_risco(alertas_imob, criticos)

    resultado_consolidado = {
        "matricula": matricula,
        "ciclo": ciclo,
        "score_risco": score,
        "faixa_risco": faixa,
        "total_criticos": criticos,
        "total_alertas": len(alertas_imob),
        "total_info": len([a for a in alertas_imob if a.get("severidade") == "info"]),
    }

    logger.info("resumo: score=%d faixa=%s alertas=%d criticos=%d",
                score, faixa, len(alertas_imob), criticos)

    if not dry_run and SUPABASE_URL and SUPABASE_KEY:
        upsert("sub_imob_dados", dados_imob)
        upsert("sub_imob_alertas", alertas_imob)
        upsert("sub_imob_resultados", [resultado_consolidado])
        logger.info("pipeline concluído e salvo no Supabase")
    else:
        logger.info("dry_run ativo ou sem credenciais — dados não persistidos")
        logger.debug("dados: %s", dados_imob)
        logger.debug("alertas: %s", alertas_imob)


def main():
    parser = argparse.ArgumentParser(
        description="Subradar Imob — pipeline de compliance imobiliário",
    )
    parser.add_argument("--matricula", required=True, help="Matrícula do imóvel")
    parser.add_argument("--cartorio-id", help="ID CNIB do cartório")
    parser.add_argument("--cliente-id", help="UUID do cliente")
    parser.add_argument("--dry-run", action="store_true", help="Não salvar no Supabase")

    args = parser.parse_args()

    if args.dry_run:
        cliente_id = args.cliente_id or "00000000-0000-0000-0000-000000000000"
    else:
        if not args.cliente_id:
            logger.error("--cliente-id obrigatório (exceto em --dry-run)")
            sys.exit(1)
        cliente_id = args.cliente_id

    rodar_imovel(
        matricula=args.matricula,
        cartorio_id=args.cartorio_id,
        cliente_id=cliente_id,
        dry_run=args.dry_run,
    )


if __name__ == "__main__":
    main()
