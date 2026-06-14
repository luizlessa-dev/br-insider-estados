#!/usr/bin/env python3
"""
Inventário de datasets em portais CKAN brasileiros.
Fontes: dadosgovbr/catalogos-dados-brasil

Uso: python scripts/inventario-ckan.py [--output dados/inventario_ckan.json]
"""

import csv
import json
import sys
import time
import argparse
from urllib.parse import urljoin, urlparse
from urllib.request import urlopen, Request
from urllib.error import URLError, HTTPError

PORTAIS_CKAN = [
    {"titulo": "Alagoas em dados e informações",  "url": "http://dados.al.gov.br/",               "uf": "AL", "esfera": "Estadual",  "poder": "Executivo"},
    {"titulo": "Fortaleza Dados Abertos",           "url": "http://dados.fortaleza.ce.gov.br/",     "uf": "CE", "esfera": "Municipal", "poder": "Executivo"},
    {"titulo": "Dados abertos Distrito Federal",    "url": "http://dados.df.gov.br/",               "uf": "DF", "esfera": "Estadual",  "poder": "Executivo"},
    {"titulo": "Dados abertos – Estado de MG",      "url": "http://www.dados.mg.gov.br",            "uf": "MG", "esfera": "Estadual",  "poder": "Executivo"},
    {"titulo": "Dados Recife",                      "url": "http://dados.recife.pe.gov.br",         "uf": "PE", "esfera": "Municipal", "poder": "Executivo"},
    {"titulo": "Dados Abertos – PE (Transp.)",      "url": "http://web.transparencia.pe.gov.br/dados-abertos/", "uf": "PE", "esfera": "Estadual", "poder": "Executivo"},
    {"titulo": "data.rio",                          "url": "http://data.rio/",                      "uf": "RJ", "esfera": "Municipal", "poder": "Executivo"},
    {"titulo": "Dados RS",                          "url": "http://dados.rs.gov.br/",               "uf": "RS", "esfera": "Estadual",  "poder": "Executivo"},
    {"titulo": "Dados Abertos POA",                 "url": "https://dados.portoalegre.rs.gov.br/",  "uf": "RS", "esfera": "Municipal", "poder": "Executivo"},
    {"titulo": "Dados Abertos TCE-RS",              "url": "http://dados.tce.rs.gov.br/",           "uf": "RS", "esfera": "Estadual",  "poder": "Legislativo"},
    {"titulo": "Dados Abertos SC",                  "url": "https://dados.sc.gov.br/",              "uf": "SC", "esfera": "Estadual",  "poder": "Executivo"},
    {"titulo": "Governo Aberto SP",                 "url": "http://www.governoaberto.sp.gov.br/",   "uf": "SP", "esfera": "Estadual",  "poder": "Executivo"},
    {"titulo": "Portal de Dados Abertos – SP",      "url": "http://dados.prefeitura.sp.gov.br/",    "uf": "SP", "esfera": "Municipal", "poder": "Executivo"},
    {"titulo": "Portal de Dados Abertos – PBH",     "url": "https://dados.pbh.gov.br/",             "uf": "MG", "esfera": "Municipal", "poder": "Executivo"},
    {"titulo": "Portal Natal",                      "url": "http://dados.natal.br/",                "uf": "RN", "esfera": "Municipal", "poder": "Executivo"},
]

# Palavras-chave de interesse para BR Insider
KEYWORDS_INTERESSE = [
    "contrato", "licitação", "licitacao", "empenho", "despesa", "gasto",
    "transferência", "transferencia", "convênio", "convenio", "emenda",
    "subvenção", "subvencao", "fornecedor", "obra", "servidor", "salário",
    "salario", "remuneração", "remuneracao", "diária", "diaria", "viagem",
    "parlamentar", "vereador", "deputado", "câmara", "camara",
    "tce", "tcm", "tribunal de contas", "fiscalização", "fiscalizacao",
    "repasse", "fundo", "orcamento", "orçamento", "receita", "arrecadação",
    "nota fiscal", "compra", "pregão", "pregao", "tomada de preço",
    "concorrência", "rpa", "folha de pagamento",
]

TIMEOUT = 8
MAX_PKG_POR_PORTAL = 200

def fetch_json(url):
    req = Request(url, headers={"User-Agent": "BR-Insider-Inventario/1.0"})
    resp = urlopen(req, timeout=TIMEOUT)
    return json.loads(resp.read().decode("utf-8"))

def base_ckan(url):
    parsed = urlparse(url)
    return f"{parsed.scheme}://{parsed.netloc}"

def get_package_list(base):
    data = fetch_json(f"{base}/api/3/action/package_list")
    if data.get("success"):
        return data["result"]
    return []

def get_package_show(base, pkg_id):
    data = fetch_json(f"{base}/api/3/action/package_show?id={pkg_id}")
    if data.get("success"):
        return data["result"]
    return None

def is_relevante(pkg):
    texto = " ".join([
        (pkg.get("title") or ""),
        (pkg.get("notes") or ""),
        (pkg.get("name") or ""),
        " ".join(t.get("display_name", "") for t in (pkg.get("tags") or [])),
    ]).lower()
    return any(kw in texto for kw in KEYWORDS_INTERESSE)

def inventariar_portal(portal):
    base = base_ckan(portal["url"])
    print(f"\n→ {portal['titulo']} ({base})", flush=True)
    resultado = {
        "titulo": portal["titulo"],
        "url": portal["url"],
        "base_ckan": base,
        "uf": portal["uf"],
        "esfera": portal["esfera"],
        "poder": portal["poder"],
        "status": "ok",
        "total_datasets": 0,
        "datasets_relevantes": [],
        "erro": None,
    }
    try:
        ids = get_package_list(base)
        resultado["total_datasets"] = len(ids)
        print(f"   {len(ids)} datasets encontrados", flush=True)

        relevantes = []
        ids_sample = ids[:MAX_PKG_POR_PORTAL]
        if len(ids) > MAX_PKG_POR_PORTAL:
            print(f"   (limitado a {MAX_PKG_POR_PORTAL} de {len(ids)})", flush=True)
        for i, pkg_id in enumerate(ids_sample):
            try:
                pkg = get_package_show(base, pkg_id)
                if pkg and is_relevante(pkg):
                    relevantes.append({
                        "id": pkg_id,
                        "titulo": pkg.get("title", pkg_id),
                        "descricao": (pkg.get("notes") or "")[:200],
                        "url": f"{base}/dataset/{pkg_id}",
                        "formatos": list({
                            r.get("format", "").upper()
                            for r in (pkg.get("resources") or [])
                            if r.get("format")
                        }),
                        "tags": [t.get("display_name", "") for t in (pkg.get("tags") or [])],
                        "atualizado": pkg.get("metadata_modified", ""),
                    })
            except Exception:
                pass
            # rate-limit gentil
            if i % 20 == 19 and i > 0:
                time.sleep(0.5)

        resultado["datasets_relevantes"] = relevantes
        print(f"   {len(relevantes)} relevantes para BR Insider", flush=True)

    except (URLError, HTTPError, Exception) as e:
        resultado["status"] = "erro"
        resultado["erro"] = str(e)
        print(f"   ERRO: {e}", flush=True)

    return resultado

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", default="/Users/luizlessa/brasilia-insider/dados/inventario_ckan.json")
    args = parser.parse_args()

    print(f"Inventariando {len(PORTAIS_CKAN)} portais CKAN...", flush=True)
    resultados = []
    for portal in PORTAIS_CKAN:
        r = inventariar_portal(portal)
        resultados.append(r)
        time.sleep(1)

    import os
    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(resultados, f, ensure_ascii=False, indent=2)

    # Resumo
    print("\n" + "="*60)
    print("RESUMO")
    print("="*60)
    total_rel = sum(len(r["datasets_relevantes"]) for r in resultados)
    print(f"Portais responderam: {sum(1 for r in resultados if r['status'] == 'ok')}/{len(PORTAIS_CKAN)}")
    print(f"Total de datasets escaneados: {sum(r['total_datasets'] for r in resultados)}")
    print(f"Datasets relevantes encontrados: {total_rel}")
    print(f"\nArquivo salvo em: {args.output}")

    print("\nPOR PORTAL:")
    for r in resultados:
        status = "✓" if r["status"] == "ok" else "✗"
        print(f"  {status} {r['titulo']} ({r['uf']}) — {r['total_datasets']} datasets / {len(r['datasets_relevantes'])} relevantes")

if __name__ == "__main__":
    main()
