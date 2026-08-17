"""
Subradar PF — Complete (25 Fontes: Consumer + 5 Extras)

Versão final com:
- DIA 1: CNPI, CCF, RENAJUD (3 gratuitas)
- DIA 2: Cartório Imóveis Cofiex (1 paga)
- DIA 3: SERASA Score (1 premium)

Total: 30 fontes (25 consumer + 5 new)
Scoring: Proprietário (60%) + SERASA (40%)
"""
from __future__ import annotations

from .runner_pf_extended_v2 import FONTES_PF_EXTENDED_V2

# Importar novo conector
from .serasa_score_pf import SerasaScorePFConnector

import logging
from .base import upsert, _ciclo_atual, SUPABASE_URL, SUPABASE_KEY
from .runner_pf_consumer import calcular_score_risco, _strip, _fmt_cpf

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
)
logger = logging.getLogger("subradar.runner_pf_complete")

# ---------------------------------------------------------------------------
# Pipeline PF Complete — 20 + 5 = 25 fontes
# ---------------------------------------------------------------------------

FONTES_PF_COMPLETE = FONTES_PF_EXTENDED_V2 + [
    SerasaScorePFConnector(),  # SERASA — Score de crédito oficial
]


def _calcular_score_ponderado(score_proprietario: int, serasa_alertas: list) -> dict:
    """
    Calcula score final ponderado:
    Score Final = (Score_Proprietário × 0.60) + (SERASA_Normalizado × 0.40)

    SERASA usa escala 0-1000, precisamos normalizar para 0-100.
    """
    # Extrai score SERASA
    serasa_score = None
    for alerta in serasa_alertas:
        if alerta.get("tipo_dado") == "score_credito":
            serasa_score = alerta.get("score_valor")
            break

    if serasa_score is None:
        # Sem score SERASA, retornar score proprietário
        return {
            "score_proprietario": score_proprietario,
            "score_serasa": None,
            "score_final": score_proprietario,
            "faixa_final": "INFORMAÇÃO",
            "metodo": "Proprietário (SERASA indisponível)",
        }

    # Normaliza SERASA (0-1000) → (0-100)
    serasa_normalizado = (serasa_score / 1000) * 100

    # Pondera
    score_final = (score_proprietario * 0.60) + (serasa_normalizado * 0.40)
    score_final = int(round(score_final))

    # Determina faixa final
    if score_final <= 20:
        faixa_final = "VERDE"
    elif score_final <= 50:
        faixa_final = "AMARELO"
    elif score_final <= 80:
        faixa_final = "LARANJA"
    else:
        faixa_final = "VERMELHO"

    return {
        "score_proprietario": score_proprietario,
        "score_serasa_original": serasa_score,
        "score_serasa_normalizado": int(serasa_normalizado),
        "score_final": score_final,
        "faixa_final": faixa_final,
        "metodo": "Proprietário (60%) + SERASA (40%)",
        "pesos": {"proprietario": 0.60, "serasa": 0.40},
    }


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
    fontes = FONTES_PF_COMPLETE

    logger.info("Subradar PF Complete — %s | %d fontes | dry_run=%s",
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
        "Scores: Proprietário=%d/100, Final=%d/100 [%s] — Método: %s",
        score_proprietario, score_final, faixa_final, weighting_dict["metodo"],
    )

    if dry_run:
        logger.info("DRY RUN — %d alerta(s) encontrado(s)", len(todos_alertas))
        print(f"\n  Score Proprietário: {score_proprietario}/100")
        if weighting_dict["score_serasa_original"]:
            print(f"  Score SERASA: {weighting_dict['score_serasa_original']}/1000")
        print(f"  Score Final: {score_final}/100 [{faixa_final}]")
        print(f"  {weighting_dict['metodo']}\n")
        for a in todos_alertas[:18]:
            sev = a.get("severidade", "?").upper()
            print(f"  [{sev}] {a.get('titulo', '')}")
        if len(todos_alertas) > 18:
            print(f"  ... e mais {len(todos_alertas) - 18}")
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
            "score_risco": score_final,  # Score final ponderado
            "faixa_risco": faixa_final,   # Faixa do score final
            "total_alertas": len(todos_alertas),
            "score_detalhes": score_detalhes,
        }])

    return todos_alertas


def main() -> None:
    import argparse
    parser = argparse.ArgumentParser(description="Subradar PF Complete — 25 fontes + SERASA weighting")
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
