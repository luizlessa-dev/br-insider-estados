"""
Subradar PF — Complete Final (27 Fontes: Consumer + 7 Extras)

VERSÃO FINAL COM COBERTURA DE CRÉDITO COMPLETA:

Base (20 consumer):
  + DIA 1: CNPI, CCF, RENAJUD (3 BC/PF gratuitas)
  + DIA 2: Cartório Imóveis (1 patrimonial paga)
  + DIA 3: SERASA Score (1 premium)
  + DIA 3 EXTRA: Negativações + Protestos (2 crédito)

Total: 27 fontes

Cobertura de Crédito COMPLETA:
  ✅ Score Oficial (SERASA: 0-1000)
  ✅ Negativações (BigDataCorp)
  ✅ Protestos (Direct Data)
  ✅ Weighting: Proprietário (60%) + SERASA (40%)
"""
from __future__ import annotations

from .runner_pf_complete import (
    FONTES_PF_COMPLETE,
    _calcular_score_ponderado,
    calcular_score_risco,
    _strip,
    _fmt_cpf,
)

# Importar conectores Enterprise de crédito
from .bigdatacorp_negativacoes import BDCNegativacoesPFConnector
from .protestos_nacional import ProtestosNacionalPFConnector

import logging
from .base import upsert, _ciclo_atual, SUPABASE_URL, SUPABASE_KEY

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
)
logger = logging.getLogger("subradar.runner_pf_complete_final")

# ---------------------------------------------------------------------------
# Pipeline PF Complete Final — 25 + 2 crédito = 27 fontes
# ---------------------------------------------------------------------------

FONTES_PF_COMPLETE_FINAL = FONTES_PF_COMPLETE + [
    # ── Extras: Cobertura de Crédito Completa ──────────────────────────────
    BDCNegativacoesPFConnector(),     # BigDataCorp — Negativações/Restrições
    ProtestosNacionalPFConnector(),   # Direct Data — Protestos IEPTB/CENPROT
]


def processar_cpf(
    cpf: str,
    cliente_id: str,
    nome: str = "",
    dry_run: bool = False,
) -> list[dict]:
    cpf_digits = _strip(cpf)
    if len(cpf_digits) != 11:
        logger.error("CPF inválido: %s", cpf)
        return []

    cpf_fmt = _fmt_cpf(cpf_digits)
    ciclo = _ciclo_atual()
    fontes = FONTES_PF_COMPLETE_FINAL

    logger.info("Subradar PF Complete Final — %s | %d fontes | dry_run=%s",
                cpf_fmt, len(fontes), dry_run)

    todos_alertas: list[dict] = []
    todos_dados: list[dict] = []
    alertas_serasa: list[dict] = []

    for fonte in fontes:
        nome_fonte = getattr(fonte, "fonte", "?")
        try:
            import inspect
            if hasattr(fonte, "consultar_cpf"):
                fn = fonte.consultar_cpf
                sig = inspect.signature(fn)
                alertas = fn(cpf_digits, nome=nome) if "nome" in sig.parameters else fn(cpf_digits)
            else:
                alertas = []

            if alertas:
                logger.info("  ✓ %s — %d alerta(s)", nome_fonte, len(alertas))
                todos_alertas.extend(alertas)

                # Captura alertas SERASA para weighting
                if nome_fonte == "serasa_score_oficial":
                    alertas_serasa = alertas

            # Coleta dados estruturados
            if hasattr(fonte, "resumo_pf"):
                try:
                    dado = fonte.resumo_pf(cpf_digits, nome=nome)
                    if dado:
                        todos_dados.append(dado)
                except Exception as e_d:
                    logger.debug("  resumo_pf %s falhou: %s", nome_fonte, e_d)

        except Exception as e:
            logger.error("  ✗ %s — erro: %s", nome_fonte, e)

    # Calcula score proprietário
    score_proprietario_dict = calcular_score_risco(todos_alertas)
    score_proprietario = score_proprietario_dict["score"]

    # Calcula score ponderado com SERASA
    weighting_dict = _calcular_score_ponderado(score_proprietario, alertas_serasa)
    score_final = weighting_dict["score_final"]
    faixa_final = weighting_dict["faixa_final"]

    logger.info(
        "Scores: Proprietário=%d/100, Final=%d/100 [%s]",
        score_proprietario, score_final, faixa_final,
    )

    if dry_run:
        logger.info("DRY RUN — %d alerta(s) encontrado(s)", len(todos_alertas))
        print(f"\n  Score Proprietário: {score_proprietario}/100")
        if weighting_dict["score_serasa_original"]:
            print(f"  Score SERASA: {weighting_dict['score_serasa_original']}/1000")
        print(f"  Score Final: {score_final}/100 [{faixa_final}]")
        print(f"  Método: {weighting_dict['metodo']}\n")
        print(f"  Total Alertas: {len(todos_alertas)}\n")

        # Mostra alertas críticos primeiro
        criticos = [a for a in todos_alertas if a.get("severidade") == "critico"]
        atencao = [a for a in todos_alertas if a.get("severidade") == "atencao"]
        info = [a for a in todos_alertas if a.get("severidade") == "info"]

        if criticos:
            print("  🔴 CRÍTICO:")
            for a in criticos[:5]:
                print(f"     • {a.get('titulo')}")

        if atencao:
            print("  🟡 ATENÇÃO:")
            for a in atencao[:5]:
                print(f"     • {a.get('titulo')}")

        if info:
            print("  🔵 INFO:")
            for a in info[:8]:
                print(f"     • {a.get('titulo')}")

        if len(todos_alertas) > 18:
            print(f"\n  ... e mais {len(todos_alertas) - 18}")

        return todos_alertas

    # Grava alertas
    if SUPABASE_URL and SUPABASE_KEY:
        if todos_alertas:
            for alerta in todos_alertas:
                alerta["cliente_id"] = cliente_id
                alerta["cpf"] = cpf_fmt
            upsert("sub_pf_alertas", todos_alertas)
            logger.info("Gravados %d alertas para %s", len(todos_alertas), cpf_fmt)

        # Grava dados estruturados
        if todos_dados:
            rows_dados = []
            for d in todos_dados:
                rows_dados.append({
                    "cpf": cpf_fmt,
                    "ciclo": ciclo,
                    "cliente_id": cliente_id,
                    "consulta_id": cliente_id,
                    "fonte": d.get("fonte", ""),
                    "categoria": d.get("categoria", ""),
                    "status": d.get("status", ""),
                    "titulo_secao": d.get("titulo_secao", ""),
                    "resumo": d.get("resumo", ""),
                    "detalhes": d.get("detalhes"),
                })
            upsert("sub_pf_dados", rows_dados)

        # Grava score ponderado
        import uuid as _uuid
        resultado_id = str(_uuid.uuid5(_uuid.NAMESPACE_DNS, f"{cpf_digits}-{ciclo}"))
        score_detalhes = {
            **score_proprietario_dict,
            "score_final": score_final,
            "faixa_final": faixa_final,
            "weighting": weighting_dict,
        }
        upsert("sub_pf_resultados", [{
            "id": resultado_id,
            "cpf": cpf_fmt,
            "cliente_id": cliente_id,
            "ciclo": ciclo,
            "score_risco": score_final,
            "faixa_risco": faixa_final,
            "total_alertas": len(todos_alertas),
            "score_detalhes": score_detalhes,
        }])

    return todos_alertas


def main() -> None:
    import argparse
    parser = argparse.ArgumentParser(description="Subradar PF Complete Final — 27 fontes (cobertura crédito completa)")
    parser.add_argument("--cpf", required=True, help="CPF a consultar")
    parser.add_argument("--nome", default="", help="Nome completo")
    parser.add_argument("--cliente-id", default="00000000-0000-0000-0000-000000000000")
    parser.add_argument("--dry-run", action="store_true", help="Não grava no Supabase")
    args = parser.parse_args()

    alertas = processar_cpf(
        cpf=args.cpf,
        cliente_id=args.cliente_id,
        nome=args.nome,
        dry_run=args.dry_run,
    )

    criticos = sum(1 for a in alertas if a.get("severidade") == "critico")
    atencao = sum(1 for a in alertas if a.get("severidade") == "atencao")
    info = len(alertas) - criticos - atencao
    logger.info("Concluído — %d crítico(s), %d atenção, %d info",
                criticos, atencao, info)


if __name__ == "__main__":
    main()
