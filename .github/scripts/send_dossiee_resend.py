#!/usr/bin/env python3
"""Envia o dossiê Subradar PF — wrapper do módulo ingestao.subradar.entrega_pf.

A geração do PDF e a regra de entrega vivem no módulo, usado também pelo worker
da Lambda. Este arquivo já teve sua própria cópia do gerador; as duas versões
divergiram e o laudo saía diferente conforme o caminho de execução.

Uso:
  python3 .github/scripts/send_dossiee_resend.py <cpf> <nome> <tipo> <email> <consulta_id>

Variáveis:
  DOSSIE_OUTPUT=<caminho>  grava o PDF em disco e não envia nada (revisão)
  DOSSIE_FORCAR=1          envia mesmo com fonte pendente (decisão consciente)
"""
import logging
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")

from ingestao.subradar.entrega_pf import entregar, montar_pdf  # noqa: E402

cpf = sys.argv[1] if len(sys.argv) > 1 else ""
nome = sys.argv[2] if len(sys.argv) > 2 else ""
tipo = sys.argv[3] if len(sys.argv) > 3 else "completa"
email_cliente = sys.argv[4] if len(sys.argv) > 4 else ""
consulta_id = sys.argv[5] if len(sys.argv) > 5 else ""

if not cpf or not nome:
    print("uso: send_dossiee_resend.py <cpf> <nome> <tipo> <email> <consulta_id>")
    sys.exit(1)

saida = os.environ.get("DOSSIE_OUTPUT", "")
if saida:
    pdf, paginas, ind = montar_pdf(cpf, nome, tipo)
    Path(saida).write_bytes(pdf)
    print(f"PDF gravado em {saida} ({paginas} pág, {len(pdf)//1024} KB, "
          f"score {ind['score']} {ind['faixa_label']}, {ind['fontes_pendente']} pendente(s)) "
          f"— nada enviado")
    sys.exit(0)

if not email_cliente:
    print("e-mail do cliente não informado")
    sys.exit(1)

r = entregar(consulta_id, cpf, nome, email_cliente, tipo=tipo,
             forcar=os.environ.get("DOSSIE_FORCAR") == "1")
if r["enviado"]:
    print(f"Dossiê enviado para {email_cliente}")
    sys.exit(0)

print(f"Não enviado: {r['motivo']}")
sys.exit(1)
