#!/usr/bin/env python3
"""
Baixa PDFs das LAIs 001, 003 e 004 a partir dos id_documento no Supabase.
URL padrão: https://www.camara.leg.br/cota-parlamentar/documentos/publ/{id_camara}/{ano}/{id_documento}.pdf
"""

import os
import sys
import time
import requests
from pathlib import Path
from dotenv import load_dotenv
from supabase import create_client

load_dotenv(Path(__file__).parent.parent / ".env")
sb = create_client(os.environ["SUPABASE_URL"], os.environ["SUPABASE_SERVICE_ROLE_KEY"])

BASE_URL = "https://www.camara.leg.br/cota-parlamentar/documentos/publ/{dep}/{ano}/{doc}.pdf"
HEADERS = {"User-Agent": "Mozilla/5.0 (compatible; pesquisa-jornalistica/1.0)"}

def buscar_despesas(id_deputado: int, filtro_nome: str) -> list[dict]:
    r = sb.table("cota_despesa").select(
        "id_documento,ano,mes,data_emissao,numero_documento,valor_documento,cnpj_cpf_fornecedor,nome_fornecedor"
    ).eq("id_deputado", id_deputado).ilike("nome_fornecedor", filtro_nome).order("ano").order("mes").execute()
    return r.data

def baixar_pdfs(registros: list[dict], id_camara: int, destino: Path, prefixo: str):
    destino.mkdir(parents=True, exist_ok=True)
    ok, erro, vazio = [], [], []

    for reg in registros:
        ide = reg["id_documento"]
        ano = reg["ano"]
        nf  = reg["numero_documento"].replace("/", "-").replace(" ", "").strip()
        data = (reg["data_emissao"] or "").replace("-", "")[:8]
        valor = reg["valor_documento"]

        url = BASE_URL.format(dep=id_camara, ano=ano, doc=ide)
        nome_arquivo = f"{prefixo}_NF{nf}_{data}_R${int(valor)}.pdf"
        caminho = destino / nome_arquivo

        if caminho.exists():
            print(f"  [JÁ EXISTE] {nome_arquivo}")
            ok.append(nome_arquivo)
            continue

        try:
            resp = requests.get(url, headers=HEADERS, timeout=30)
            if resp.status_code == 200 and len(resp.content) > 500:
                caminho.write_bytes(resp.content)
                print(f"  [OK] {nome_arquivo} ({len(resp.content)//1024}KB)")
                ok.append(nome_arquivo)
            elif resp.status_code == 404:
                print(f"  [404] {nome_arquivo} — {url}")
                vazio.append((nome_arquivo, url, "404"))
            else:
                print(f"  [ERRO {resp.status_code}] {nome_arquivo}")
                erro.append((nome_arquivo, url, resp.status_code))
        except Exception as e:
            print(f"  [EXCEÇÃO] {nome_arquivo} — {e}")
            erro.append((nome_arquivo, url, str(e)))

        time.sleep(0.4)

    return ok, erro, vazio

def relatorio(lai: str, ok, erro, vazio):
    total = len(ok) + len(erro) + len(vazio)
    print(f"\n{'='*60}")
    print(f"LAI {lai}: {total} registros → {len(ok)} baixados, {len(vazio)} 404, {len(erro)} erros")
    if vazio:
        print("  404:")
        for n, u, _ in vazio:
            print(f"    {n}")
    if erro:
        print("  Erros:")
        for n, u, s in erro:
            print(f"    {n} [{s}]")

ROOT = Path(__file__).parent

# ─────────────────────────────────────────
# LAI 001 — L.L.D.P (Mario Frias)
# ─────────────────────────────────────────
print("\n>>> LAI 001 — L.L.D.P — Mario Frias (3641)")
regs_ldp_frias = buscar_despesas(3641, "%L.L.D.P%")
print(f"  {len(regs_ldp_frias)} registros encontrados")
ok1a, err1a, v1a = baixar_pdfs(
    regs_ldp_frias, 3641,
    ROOT / "mario_frias" / "ldp",
    "LDP"
)

# LAI 001 — L.L.D.P (Bilynskyj) — 0 registros no DB, mas tenta pelo CNPJ também
print("\n>>> LAI 001 — L.L.D.P — Bilynskyj (3620)")
regs_ldp_bily = buscar_despesas(3620, "%L.L.D.P%")
print(f"  {len(regs_ldp_bily)} registros encontrados")
if regs_ldp_bily:
    ok1b, err1b, v1b = baixar_pdfs(
        regs_ldp_bily, 3620,
        ROOT / "bilynskyj" / "ldp",
        "LDP"
    )
else:
    ok1b, err1b, v1b = [], [], []
    print("  Nenhum registro — pasta não criada")

relatorio("001 LDP/Mario Frias", ok1a, err1a, v1a)
relatorio("001 LDP/Bilynskyj",   ok1b, err1b, v1b)

# ─────────────────────────────────────────
# LAI 003 — Merli Junior PF (Mario Frias)
# ─────────────────────────────────────────
print("\n>>> LAI 003 — Paulo Merli Junior (PF) — Mario Frias (3641)")
regs_merli = buscar_despesas(3641, "%merli%")
print(f"  {len(regs_merli)} registros encontrados")
ok3, err3, v3 = baixar_pdfs(
    regs_merli, 3641,
    ROOT / "mario_frias" / "merli",
    "MERLI"
)
relatorio("003 Merli/Mario Frias", ok3, err3, v3)

# ─────────────────────────────────────────
# LAI 004 — Flavia Souza (Raimundo Costa)
# ─────────────────────────────────────────
print("\n>>> LAI 004 — Flavia Souza de Melo — Raimundo Costa (3426)")
regs_flavia = buscar_despesas(3426, "%flavia souza%")
print(f"  {len(regs_flavia)} registros encontrados")
ok4, err4, v4 = baixar_pdfs(
    regs_flavia, 3426,
    ROOT / "raimundo_costa" / "flavia_souza",
    "FLAVIA"
)
relatorio("004 Flavia Souza/Raimundo Costa", ok4, err4, v4)

# ─────────────────────────────────────────
# Sumário final
# ─────────────────────────────────────────
total_ok  = len(ok1a) + len(ok1b) + len(ok3) + len(ok4)
total_err = len(err1a)+len(err1b)+len(err3)+len(err4)
total_v   = len(v1a)+len(v1b)+len(v3)+len(v4)
print(f"\n{'='*60}")
print(f"TOTAL GERAL: {total_ok} PDFs baixados | {total_v} não encontrados (404) | {total_err} erros")
