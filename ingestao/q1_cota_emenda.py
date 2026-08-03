"""
Q1: CNPJs que aparecem na Cota Parlamentar E nas Emendas
Usa DuckDB sobre os CSVs locais — evita paginar 4M linhas via API REST.
"""
from __future__ import annotations
import io, os, re, sys, zipfile
from collections import defaultdict
from pathlib import Path

import duckdb, requests
from dotenv import load_dotenv

load_dotenv(Path(__file__).parent.parent / ".env")
sys.path.insert(0, str(Path(__file__).parent.parent))

BASE_URL = "https://www.camara.leg.br/cotas"
ANOS = list(range(2019, 2027))
WORKDIR = Path("/tmp/cota_q1")
WORKDIR.mkdir(exist_ok=True)


def fetch_ano(ano: int, session: requests.Session) -> Path:
    dest = WORKDIR / f"Ano-{ano}.csv"
    if dest.exists():
        return dest
    print(f"  Baixando {ano}...")
    r = session.get(f"{BASE_URL}/Ano-{ano}.csv.zip", timeout=120)
    r.raise_for_status()
    with zipfile.ZipFile(io.BytesIO(r.content)) as zf:
        name = zf.namelist()[0]
        with zf.open(name) as src, open(dest, "wb") as dst:
            dst.write(src.read())
    return dest


def main():
    from supabase import create_client
    sb = create_client(os.environ["SUPABASE_URL"], os.environ["SUPABASE_SERVICE_ROLE_KEY"])

    # 1. CNPJs das emendas
    print("Carregando emendas...")
    emendas: dict[str, dict] = {}
    offset = 0
    while True:
        r = sb.table("emendas_favorecidos").select(
            "codigo_favorecido,favorecido,valor_recebido,codigo_autor"
        ).range(offset, offset + 999).execute()
        if not r.data: break
        for x in r.data:
            c = (x["codigo_favorecido"] or "").strip()
            if not c: continue
            if c not in emendas:
                emendas[c] = {"nome": x["favorecido"], "total": 0, "autores": set()}
            emendas[c]["total"] += x["valor_recebido"] or 0
            emendas[c]["autores"].add(x["codigo_autor"])
        offset += 1000
        if len(r.data) < 1000: break
    print(f"  {len(emendas)} CNPJs em emendas")

    # 2. Processar CSVs da Cota com DuckDB
    session = requests.Session()
    session.headers["User-Agent"] = "BRInsider/1.0"

    con = duckdb.connect(":memory:")
    con.execute("""
        CREATE TABLE cota (
            cnpj_raw VARCHAR,
            cnpj_norm VARCHAR,
            nome_fornecedor VARCHAR,
            valor_liquido DOUBLE,
            id_deputado INTEGER,
            tipo_despesa VARCHAR
        )
    """)

    for ano in ANOS:
        csv_path = fetch_ano(ano, session)
        con.execute(f"""
            INSERT INTO cota
            SELECT
                "txtCNPJCPF"                                              AS cnpj_raw,
                regexp_replace("txtCNPJCPF", '[^0-9]', '', 'g')          AS cnpj_norm,
                "txtFornecedor"                                            AS nome_fornecedor,
                TRY_CAST(replace(replace(CAST("vlrLiquido" AS VARCHAR), '.', ''), ',', '.') AS DOUBLE) AS valor_liquido,
                CAST("nuDeputadoId" AS INTEGER)                           AS id_deputado,
                "txtDescricao"                                             AS tipo_despesa
            FROM read_csv(
                '{csv_path}',
                delim=';',
                header=true,
                encoding='CP1252',
                ignore_errors=true
            )
            WHERE "txtCNPJCPF" IS NOT NULL AND "txtCNPJCPF" <> ''
              AND length(regexp_replace("txtCNPJCPF", '[^0-9]', '', 'g')) = 14
        """)
        print(f"  {ano} carregado")

    # 3. Agregar por cnpj_norm
    print("Agregando...")
    rows = con.execute("""
        SELECT
            cnpj_norm,
            MAX(nome_fornecedor)          AS nome,
            SUM(valor_liquido)            AS total_cota,
            COUNT(DISTINCT id_deputado)   AS n_dep,
            COUNT(*)                      AS n_notas
        FROM cota
        GROUP BY cnpj_norm
    """).fetchall()

    # 4. Cruzar com emendas
    resultado = []
    for cnpj_norm, nome, total_cota, n_dep, n_notas in rows:
        if cnpj_norm in emendas:
            em = emendas[cnpj_norm]
            resultado.append({
                "cnpj": cnpj_norm,
                "nome_cota": (nome or "")[:55],
                "nome_emenda": (em["nome"] or "")[:55],
                "total_cota": total_cota or 0,
                "total_emenda": em["total"],
                "total_combinado": (total_cota or 0) + em["total"],
                "n_dep_cota": n_dep,
                "n_autores_emenda": len(em["autores"]),
                "n_notas_cota": n_notas,
            })

    resultado.sort(key=lambda x: x["total_combinado"], reverse=True)

    print(f"\n{'='*115}")
    print(f"Q1: TOP 30 — MESMO CNPJ NA COTA PARLAMENTAR E NAS EMENDAS  ({len(resultado)} no total)")
    print(f"{'='*115}")
    print(f"{'CNPJ':<16} {'NOME (cota)':<46} {'COTA R$M':>9} {'EMENDA R$M':>11} {'TOTAL R$M':>10} {'DEP':>4} {'AUT':>4}")
    print("─" * 115)
    for r in resultado[:30]:
        print(
            f"{r['cnpj']:<16} {r['nome_cota']:<46} "
            f"{r['total_cota']/1e6:>9.2f} {r['total_emenda']/1e6:>11.2f} "
            f"{r['total_combinado']/1e6:>10.2f} {r['n_dep_cota']:>4} {r['n_autores_emenda']:>4}"
        )

    con.close()


if __name__ == "__main__":
    main()
