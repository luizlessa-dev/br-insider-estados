"""
Runner CLI — dossiê de doadores TSE.

Uso:
    # por CPF/CNPJ
    python -m dossie.runner --cpf 02781881686
    python -m dossie.runner --cpf 02781881686 --detalhado

    # por nome (fragmento)
    python -m dossie.runner --nome ZETTEL
    python -m dossie.runner --nome "BANCO ABC"

    # salvar JSON
    python -m dossie.runner --nome ZETTEL --json saida.json

Variáveis de ambiente:
    SUPABASE_URL
    SUPABASE_SERVICE_ROLE_KEY
"""
from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

from dotenv import load_dotenv  # pip install python-dotenv

# Carrega .env do diretório raiz do repo
_repo_root = Path(__file__).parent.parent
if (_repo_root / ".env").exists():
    load_dotenv(_repo_root / ".env")

from .doador import DossieDoador  # noqa: E402


def main() -> None:
    parser = argparse.ArgumentParser(description="Dossiê de doadores TSE")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--cpf", metavar="CPF_CNPJ",
                       help="CPF ou CNPJ do doador (apenas dígitos)")
    group.add_argument("--nome", metavar="FRAGMENTO",
                       help="Fragmento do nome do doador (case-insensitive)")
    parser.add_argument("--originario", action="store_true",
                        help="Buscar também no campo doador_originario")
    parser.add_argument("--detalhado", action="store_true",
                        help="Exibir todas as transações individuais")
    parser.add_argument("--json", metavar="ARQUIVO",
                        help="Salvar resultado em JSON")
    args = parser.parse_args()

    dossie = DossieDoador.from_env()

    if args.cpf:
        rel = dossie.por_cpf_cnpj(args.cpf)
    elif args.originario:
        rel = dossie.por_nome_originario(args.nome)
    else:
        rel = dossie.por_nome(args.nome)

    if not rel.doacoes:
        print(f"Nenhuma doação encontrada para '{args.cpf or args.nome}'.")
        sys.exit(0)

    DossieDoador.imprimir(rel, detalhado=args.detalhado)

    if args.json:
        Path(args.json).write_text(DossieDoador.para_json(rel), encoding="utf-8")
        print(f"JSON salvo em {args.json}")


if __name__ == "__main__":
    main()
