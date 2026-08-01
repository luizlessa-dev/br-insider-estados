"""
Backfill sub_pf_dados — re-roda runner_pf para consultas concluídas
que ainda não têm dados estruturados na tabela sub_pf_dados.

Uso:
  python3 scripts/backfill_pf_dados.py [--dry-run] [--cpf 064.659.796-59]
"""
import argparse
import logging
import os
import subprocess
import sys
import time

import requests

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("backfill_pf")

SB_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SB_KEY = (
    os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    or os.environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY", "")
)


def _hdrs():
    return {"apikey": SB_KEY, "Authorization": f"Bearer {SB_KEY}"}


def listar_consultas_sem_dados(cpf_filtro: str | None = None) -> list[dict]:
    """Retorna consultas concluídas cujo CPF ainda não tem registros em sub_pf_dados."""
    params = {"status": "eq.concluida", "limit": 200, "order": "created_at.asc"}
    if cpf_filtro:
        params["cpf_consultado"] = f"eq.{cpf_filtro.replace('.', '').replace('-', '')}"

    r = requests.get(f"{SB_URL}/rest/v1/sub_pf_consultas", params=params, headers=_hdrs(), timeout=20)
    consultas = r.json() if r.ok else []

    resultado = []
    for c in consultas:
        cpf_raw = c.get("cpf_consultado", "")
        cpf_fmt = f"{cpf_raw[:3]}.{cpf_raw[3:6]}.{cpf_raw[6:9]}-{cpf_raw[9:]}" if len(cpf_raw) == 11 else cpf_raw
        ciclo = (c.get("created_at") or "")[:7]

        r2 = requests.get(
            f"{SB_URL}/rest/v1/sub_pf_dados",
            params={"cpf": f"eq.{cpf_fmt}", "ciclo": f"eq.{ciclo}", "limit": 1, "select": "id"},
            headers=_hdrs(), timeout=15,
        )
        dados = r2.json() if r2.ok else []
        if not dados:
            resultado.append(c)

    return resultado


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", help="Listar sem executar")
    parser.add_argument("--cpf", help="Filtrar por CPF específico")
    args = parser.parse_args()

    if not SB_URL or not SB_KEY:
        log.error("SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY são obrigatórios")
        sys.exit(1)

    log.info("Buscando consultas sem sub_pf_dados...")
    pendentes = listar_consultas_sem_dados(cpf_filtro=args.cpf)

    if not pendentes:
        log.info("Nenhuma consulta pendente de backfill.")
        return

    log.info("%d consulta(s) para backfill:", len(pendentes))
    for c in pendentes:
        log.info("  %s | CPF %s | %s | %s", c["id"], c["cpf_consultado"], c["nome_consultado"], c["tipo"])

    if args.dry_run:
        log.info("--dry-run: nenhum runner executado.")
        return

    for c in pendentes:
        cpf    = c["cpf_consultado"]
        nome   = c["nome_consultado"] or ""
        cid    = c["id"]
        tipo   = c.get("tipo", "simples")
        avulsa = ["--avulsa"] if tipo == "completa" else []

        log.info("Rodando pipeline para %s (%s)...", cpf, nome)
        cmd = [
            sys.executable, "-m", "ingestao.subradar.runner_pf",
            "--cpf", cpf,
            "--nome", nome,
            "--cliente-id", cid,
        ] + avulsa

        result = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
        if result.returncode == 0:
            log.info("OK %s", cpf)
        else:
            log.warning("FALHOU %s — código %d\n%s", cpf, result.returncode, result.stderr[-500:])

        time.sleep(2)

    log.info("Backfill concluído.")


if __name__ == "__main__":
    main()
