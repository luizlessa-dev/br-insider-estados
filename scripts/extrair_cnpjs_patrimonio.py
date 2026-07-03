"""
Extrai CNPJs declarados no patrimônio TSE dos parlamentares e busca
contratos federais para cada empresa encontrada.

Uso:
  cd /Users/luizlessa/brasilia-insider
  source .venv/bin/activate
  python scripts/extrair_cnpjs_patrimonio.py [--dry-run]

Variáveis de ambiente obrigatórias:
  SUPABASE_URL
  SUPABASE_SERVICE_ROLE_KEY
  PORTAL_TRANSPARENCIA_API_KEY

Saídas:
  /tmp/cnpjs_parlamentares_validos.txt  — CNPJs válidos (1 por linha)
  /tmp/cnpjs_parlamentares_mapa.json    — mapa CNPJ → parlamentar
"""
from __future__ import annotations

import argparse
import json
import logging
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

logger = logging.getLogger(__name__)

TIPOS_EMPRESA = {
    "Quotas ou quinhões de capital",
    "Outras participações societárias",
    "Outros fundos",
}
CNPJ_RE = re.compile(r"(\d{2})[\.\s]?(\d{3})[\.\s]?(\d{3})[\/\s]?(\d{4})[-\s]?(\d{2})")


def _valida_cnpj(cnpj: str) -> bool:
    c = cnpj.strip()
    if len(c) != 14 or c == c[0] * 14:
        return False

    def calc_dv(digits, pesos):
        s = sum(d * p for d, p in zip(digits, pesos))
        r = s % 11
        return 0 if r < 2 else 11 - r

    d = [int(x) for x in c]
    dv1 = calc_dv(d[:12], [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2])
    dv2 = calc_dv(d[:13], [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2])
    return d[12] == dv1 and d[13] == dv2


def _curl_get_json(url: str, headers: list[str]) -> list | dict:
    args = ["curl", "-s", "--max-time", "30", url]
    for h in headers:
        args += ["-H", h]
    r = subprocess.run(args, capture_output=True, text=True)
    return json.loads(r.stdout)


def extrair_cnpjs(url: str, key: str) -> tuple[list[dict], list[str]]:
    """Busca bens de empresa no patrimonio_tse e extrai CNPJs válidos."""
    tipos_encoded = ",".join(f'"{t}"' for t in TIPOS_EMPRESA)
    headers = [f"apikey: {key}", f"Authorization: Bearer {key}"]

    all_rows: list[dict] = []
    for offset in range(0, 2000, 700):
        rows = _curl_get_json(
            f"{url}/rest/v1/patrimonio_tse"
            f"?select=parlamentar_id,cpf,ds_bem,ds_tipo_bem,vr_bem"
            f"&ds_tipo_bem=in.({tipos_encoded})"
            f"&limit=700&offset={offset}",
            headers,
        )
        if not isinstance(rows, list) or not rows:
            break
        all_rows.extend(rows)
        if len(rows) < 700:
            break

    logger.info("Total bens de empresa: %d", len(all_rows))

    resultados: list[dict] = []
    for r in all_rows:
        texto = r.get("ds_bem") or ""
        for m in CNPJ_RE.findall(texto):
            cnpj = "".join(m)
            if _valida_cnpj(cnpj):
                resultados.append({
                    "parlamentar_id": r["parlamentar_id"],
                    "cpf": r["cpf"],
                    "cnpj": cnpj,
                    "ds_bem": texto[:200],
                    "valor_declarado": r.get("vr_bem"),
                })

    unique_cnpjs = sorted({r["cnpj"] for r in resultados})
    logger.info("CNPJs únicos válidos: %d", len(unique_cnpjs))
    return resultados, unique_cnpjs


def main() -> None:
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

    parser = argparse.ArgumentParser(description="Extrai CNPJs do patrimônio TSE e busca contratos")
    parser.add_argument("--dry-run", action="store_true", help="Só extrai CNPJs, não roda contratos")
    parser.add_argument("--output-dir", default="/tmp", help="Diretório de saída dos arquivos")
    args = parser.parse_args()

    url = (os.environ.get("SUPABASE_URL") or "").rstrip("/")
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY") or ""
    if not url or not key:
        logger.error("SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY são obrigatórios.")
        sys.exit(1)

    resultados, unique_cnpjs = extrair_cnpjs(url, key)

    out = Path(args.output_dir)
    cnpjs_file = out / "cnpjs_parlamentares_validos.txt"
    mapa_file = out / "cnpjs_parlamentares_mapa.json"

    cnpjs_file.write_text("\n".join(unique_cnpjs))
    mapa_file.write_text(json.dumps(resultados, ensure_ascii=False, indent=2))
    logger.info("Salvo: %s (%d CNPJs)", cnpjs_file, len(unique_cnpjs))
    logger.info("Salvo: %s (%d registros)", mapa_file, len(resultados))

    if args.dry_run:
        logger.info("--dry-run: pulando busca de contratos.")
        return

    api_key = os.environ.get("PORTAL_TRANSPARENCIA_API_KEY") or ""
    if not api_key:
        logger.error("PORTAL_TRANSPARENCIA_API_KEY é obrigatória para buscar contratos.")
        sys.exit(1)

    logger.info("Iniciando busca de contratos para %d CNPJs...", len(unique_cnpjs))
    subprocess.run(
        [sys.executable, "-m", "ingestao.cgu.contratos_runner",
         "--lista-cnpjs", str(cnpjs_file)],
        check=True,
    )


if __name__ == "__main__":
    main()
