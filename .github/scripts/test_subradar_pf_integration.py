#!/usr/bin/env python3
"""
Teste integrado end-to-end: Subradar PF
- Testa runner com dry-run
- Testa API HTTP wrapper
- Verifica estrutura de dados
"""
import sys
import json
import subprocess
import time
from pathlib import Path

# Add repo to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from ingestao.subradar.runner_pf import (
    processar_cpf,
    calcular_score_risco,
    _strip,
    _fmt_cpf,
)


def test_runner_dry_run():
    """Testa runner em modo dry-run."""
    print("\n" + "="*60)
    print("✓ TESTE 1: Runner PF — Dry-Run")
    print("="*60)

    cpf = "123.456.789-00"
    cpf_clean = _strip(cpf)

    print(f"  CPF: {_fmt_cpf(cpf_clean)}")
    print(f"  Modo: DRY-RUN (sem gravar Supabase)")
    print()

    try:
        alertas = processar_cpf(
            cpf=cpf,
            cliente_id="test-client-000",
            nome="João Test Silva",
            dry_run=True,
            avulsa=False,
        )

        print(f"  Alertas encontrados: {len(alertas)}")
        if alertas:
            for i, alerta in enumerate(alertas[:3], 1):
                print(f"    {i}. {alerta.get('titulo')} [{alerta.get('severidade').upper()}]")
                print(f"       Fonte: {alerta.get('fonte')}")
            if len(alertas) > 3:
                print(f"    ... e mais {len(alertas) - 3}")

        # Calcula score
        score_data = calcular_score_risco(alertas)
        print()
        print(f"  Score de risco: {score_data['score']}/100")
        print(f"  Faixa: {score_data['faixa']}")
        print(f"  Descrição: {score_data['descricao']}")
        print(f"  Total: {score_data['criticos']} crítico(s), {score_data['atencao']} atenção")

        # Validações
        assert isinstance(score_data['score'], int), "Score deve ser inteiro"
        assert 0 <= score_data['score'] <= 100, "Score deve estar em 0-100"
        assert score_data['faixa'] in ["VERDE", "AMARELO", "LARANJA", "VERMELHO"], "Faixa inválida"

        print("\n  ✅ PASSOU")
        return True

    except Exception as e:
        print(f"\n  ❌ FALHOU: {e}")
        return False


def test_score_calculation():
    """Testa algoritmo de scoring."""
    print("\n" + "="*60)
    print("✓ TESTE 2: Algoritmo de Scoring Proprietário")
    print("="*60)

    test_cases = [
        {
            "name": "Sem ocorrências",
            "alertas": [],
            "expected_faixa": "VERDE",
        },
        {
            "name": "Uma atenção leve",
            "alertas": [{"severidade": "info", "fonte": "teste"}],
            "expected_faixa": "VERDE",
        },
        {
            "name": "Múltiplas atenções",
            "alertas": [
                {"severidade": "atencao", "fonte": "judicial"},
                {"severidade": "atencao", "fonte": "sanções"},
                {"severidade": "info", "fonte": "mídia"},
            ],
            "expected_faixa": "AMARELO",
        },
        {
            "name": "Alerta crítico",
            "alertas": [
                {"severidade": "critico", "fonte": "bnmp_cnj"},
            ],
            "expected_faixa": "AMARELO",
        },
        {
            "name": "Múltiplos críticos + bônus",
            "alertas": [
                {"severidade": "critico", "fonte": "bnmp_cnj"},
                {"severidade": "critico", "fonte": "ceis"},
                {"severidade": "critico", "fonte": "ofac"},
            ],
            "expected_faixa": "VERMELHO",  # 3*30 + 10 (judicial) + 10 (internacional) = 100
        },
    ]

    all_passed = True
    for test in test_cases:
        score_data = calcular_score_risco(test["alertas"])
        passed = score_data["faixa"] == test["expected_faixa"]
        status = "✅" if passed else "❌"

        print(f"\n  {status} {test['name']}")
        print(f"     Score: {score_data['score']}/100, Faixa: {score_data['faixa']}")

        if not passed:
            print(f"     ESPERADO: {test['expected_faixa']}")
            all_passed = False

    if all_passed:
        print("\n  ✅ PASSOU")
    return all_passed


def test_api_http_server():
    """Testa estrutura do servidor HTTP API (sem executar runner completo)."""
    print("\n" + "="*60)
    print("✓ TESTE 3: API HTTP Server (runner_pf_api)")
    print("="*60)

    try:
        # Apenas verifica se o módulo é importável
        from ingestao.subradar.runner_pf_api import ConsultaHandler, main
        print("  ✅ Módulo importável")

        # Verifica se tem os handlers corretos
        assert hasattr(ConsultaHandler, 'do_POST'), "Falta handler POST"
        assert hasattr(ConsultaHandler, 'do_OPTIONS'), "Falta handler OPTIONS"
        assert hasattr(ConsultaHandler, 'send_json'), "Falta método send_json"
        print("  ✅ Handlers implementados")

        print("  ✅ PASSOU (para iniciar servidor: python3 -m ingestao.subradar.runner_pf_api --port 8000)")
        return True

    except Exception as e:
        print(f"  ❌ Erro: {e}")
        return False


def main():
    print("\n" + "█"*60)
    print("  SUBRADAR PF — Teste Integrado End-to-End")
    print("█"*60)

    results = {
        "Dry-Run": test_runner_dry_run(),
        "Scoring": test_score_calculation(),
        "API HTTP": test_api_http_server(),
    }

    print("\n" + "="*60)
    print("RESUMO")
    print("="*60)

    passed = sum(1 for v in results.values() if v is True)
    failed = sum(1 for v in results.values() if v is False)
    skipped = sum(1 for v in results.values() if v is None)

    for name, result in results.items():
        status = "✅ PASSOU" if result is True else "❌ FALHOU" if result is False else "⚠️  PULADO"
        print(f"  {status} — {name}")

    print()
    print(f"Total: {passed} passou(aram), {failed} falhou(aram), {skipped} pula(dos)")

    if failed > 0:
        sys.exit(1)
    sys.exit(0)


if __name__ == "__main__":
    main()
