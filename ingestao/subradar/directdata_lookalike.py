"""
Direct Data — LookALike: Prospecção de Empresas Similares

Fluxo:
  1. SearchPreview  → conta e mostra amostra (gratuito)
  2. Purchase       → compra a lista completa (R$ 0,36/empresa)
  3. Export status  → poll até Completed
  4. Download       → ZIP com CSV enriquecido

Filtros disponíveis (todos opcionais, mas ao menos 1 obrigatório):
  states            — lista de UFs ex: ['MG', 'SP']
  primaryCnae       — lista de CNAEs ex: ['6920601']
  companySize       — lista de portes: 'MEI', 'ME', 'EPP', 'MEDIO', 'GRANDE'
  registrationStatus — ['ATIVA', 'BAIXADA', 'SUSPENSA', 'INAPTA', 'NULA']
  employeeCountRange — {'min': 1, 'max': 10}
  openingDateStart  — 'YYYY-MM-DD'
  openingDateEnd    — 'YYYY-MM-DD'
  postalCodes       — lista de CEPs ou prefixos
  cities            — lista de municípios
  neighborhoods     — lista de bairros

CSV enriquecido no ZIP contém: CNPJ, razão social, porte, situação, CNAE, UF, município.

Uso como script:
  python3 -m ingestao.subradar.directdata_lookalike --cnae 6920601 --estados MG SP --porte ME
  python3 -m ingestao.subradar.directdata_lookalike --cnae 6920601 --estados MG --preview-only
  python3 -m ingestao.subradar.directdata_lookalike --purchase <searchGuid> --quantidade 500

Env var: DIRECT_DATA_TOKEN
"""
from __future__ import annotations

import argparse
import logging
import os
import sys
import time
import zipfile
import io
import json

import requests

logger = logging.getLogger("subradar.directdata_lookalike")

_BASE  = "https://api.app.directd.com.br"
_TOKEN = os.environ.get("DIRECT_DATA_TOKEN", "")

_POLL_INTERVAL = 5   # segundos entre polls de export
_POLL_MAX      = 120  # máximo de tentativas (~10 min)


def _headers() -> dict:
    return {"Token": _TOKEN, "Content-Type": "application/json"}


def _wl(items: list) -> dict:
    """Converte lista em formato {whiteList: [...], blackList: []}."""
    return {"whiteList": list(items), "blackList": []}


# ─────────────────────────────────────────────────────────────
# API calls
# ─────────────────────────────────────────────────────────────

def preview(
    states: list[str] | None = None,
    primary_cnae: list[str] | None = None,
    company_size: list[str] | None = None,
    registration_status: list[str] | None = None,
    employee_min: int | None = None,
    employee_max: int | None = None,
    opening_date_start: str | None = None,
    opening_date_end: str | None = None,
    postal_codes: list[str] | None = None,
    cities: list[str] | None = None,
    neighborhoods: list[str] | None = None,
    ignored_cnpjs: list[str] | None = None,
    n_results: int = 5,
) -> dict:
    """
    Executa SearchPreview (gratuito).
    Retorna dict com: total, searchGuid, rows (amostra).
    """
    filters: dict = {}

    if states:
        filters["states"] = _wl(states)
    if primary_cnae:
        filters["primaryCnae"] = _wl(primary_cnae)
    if company_size:
        filters["companySize"] = _wl(company_size)
    if registration_status:
        filters["registrationStatus"] = _wl(registration_status)
    if employee_min is not None or employee_max is not None:
        filters["employeeCountRange"] = {
            "min": employee_min or 0,
            "max": employee_max or 999999,
        }
    if opening_date_start:
        filters["openingDateStart"] = opening_date_start
    if opening_date_end:
        filters["openingDateEnd"] = opening_date_end
    if postal_codes:
        filters["postalCodes"] = _wl(postal_codes)
    if cities:
        filters["cities"] = _wl(cities)
    if neighborhoods:
        filters["neighborhoods"] = _wl(neighborhoods)

    if not filters:
        raise ValueError("Ao menos um filtro é obrigatório para o SearchPreview.")

    payload = {
        "numberOfResults": n_results,
        "filters": filters,
    }
    if ignored_cnpjs:
        payload["ignoredCnpjList"] = ignored_cnpjs

    resp = requests.post(
        f"{_BASE}/api/LookALike/v2/SearchPreview",
        headers=_headers(),
        json=payload,
        timeout=60,
    )
    resp.raise_for_status()
    return resp.json()


def purchase(search_guid: str, quantity: int) -> dict:
    """
    Compra `quantity` empresas do SearchGuid. Cobra R$ 0,36/empresa.
    Retorna dict com: listGuid, exportGuid, quantityCharged, amountCharged.
    """
    resp = requests.post(
        f"{_BASE}/api/LookALike/v2/Purchase",
        headers=_headers(),
        json={"searchGuid": search_guid, "quantity": quantity},
        timeout=30,
    )
    resp.raise_for_status()
    return resp.json()


def export_status(export_guid: str) -> dict:
    """Verifica status do export: Processing → Enriching → Completed."""
    resp = requests.get(
        f"{_BASE}/api/LookALike/Export/{export_guid}",
        headers=_headers(),
        params={"exportGuid": export_guid},
        timeout=15,
    )
    resp.raise_for_status()
    return resp.json()


def download_zip(export_guid: str) -> bytes:
    """Baixa o ZIP com CSV enriquecido. Só disponível quando status=Completed."""
    resp = requests.get(
        f"{_BASE}/api/LookALike/Export/{export_guid}/Download",
        headers={k: v for k, v in _headers().items() if k != "Content-Type"},
        params={"exportGuid": export_guid},
        timeout=120,
    )
    resp.raise_for_status()
    return resp.content


def poll_until_ready(export_guid: str) -> bool:
    """Aguarda export ficar Completed. Retorna True quando pronto."""
    for attempt in range(_POLL_MAX):
        status = export_status(export_guid)
        estado = (status.get("exportStatus") or "").lower()
        logger.info("LookALike export %s: %s (%ds)", export_guid[:8], estado, attempt * _POLL_INTERVAL)

        if estado == "completed" and status.get("isDownloadReady"):
            return True
        if estado in ("failed", "refunded", "cancelled"):
            logger.error("LookALike export falhou: %s", status.get("refundReason"))
            return False

        time.sleep(_POLL_INTERVAL)

    logger.error("LookALike: timeout aguardando export %s", export_guid[:8])
    return False


def csv_from_zip(zip_bytes: bytes) -> str:
    """Extrai o primeiro CSV do ZIP retornado pelo Direct Data."""
    with zipfile.ZipFile(io.BytesIO(zip_bytes)) as z:
        for name in z.namelist():
            if name.lower().endswith(".csv"):
                return z.read(name).decode("utf-8-sig", errors="replace")
    raise ValueError("Nenhum CSV encontrado no ZIP do LookALike.")


# ─────────────────────────────────────────────────────────────
# CLI
# ─────────────────────────────────────────────────────────────

def _cli_preview(args: argparse.Namespace) -> None:
    states = args.estados or []
    cnaes  = args.cnae or []
    portes = args.porte or []

    print(f"\nBuscando empresas: CNAE={cnaes} | UFs={states} | Porte={portes}")

    # API retorna 500 quando muitos filtros são combinados — tenta progressivamente menos
    filter_combos = [
        dict(states=states or None, primary_cnae=cnaes or None, company_size=portes or None),
        dict(states=states or None, primary_cnae=cnaes or None),
        dict(states=states or None, company_size=portes or None),
        dict(primary_cnae=cnaes or None),
        dict(states=states or None),
    ]

    result = None
    for combo in filter_combos:
        # Remove chaves com valor None
        combo = {k: v for k, v in combo.items() if v}
        if not combo:
            continue
        try:
            result = preview(**combo, n_results=9999)  # total real vem no campo 'total'; rows max=5
            if combo != {k: v for k, v in dict(states=states or None, primary_cnae=cnaes or None, company_size=portes or None).items() if v}:
                print(f"  (API 500 com todos os filtros — usando subconjunto: {list(combo.keys())})")
            break
        except Exception as e:
            if "500" in str(e):
                continue
            raise

    if result is None:
        print("Erro: API retornou 500 para todas as combinações de filtros.")
        return

    # Campos possíveis: total, totalCount, numberOfResults, count, quantityAvailable
    total = (
        result.get("totalCount")
        or result.get("total")
        or result.get("numberOfResults")
        or result.get("count")
        or result.get("quantityAvailable")
        or len(result.get("rows", []))
    )
    guid       = result.get("searchGuid", "")
    rows       = result.get("rows", [])

    print(f"\nTotal encontrado: {total:,} empresas")
    print(f"SearchGuid: {guid}\n")

    if rows:
        print("Amostra (5 empresas):")
        for row in rows:
            cnpj   = row.get("cnpj", "-")
            nome   = row.get("companyName", "-")
            estado = row.get("state", "-")
            porte  = row.get("companySize", "-")
            cnae   = (row.get("mainCnae") or {}).get("description", "-")
            print(f"  {cnpj} | {nome[:40]} | {estado} | {porte} | {cnae[:30]}")

    if not args.preview_only and total > 0:
        print(f"\nCusto estimado para comprar tudo: R$ {total * 0.36:,.2f}")
        qtd = args.quantidade or min(total, 500)
        print(f"Comprando {qtd} empresas → R$ {qtd * 0.36:,.2f}")
        confirma = input("\nConfirma compra? [s/N] ").strip().lower()
        if confirma == "s":
            _cli_purchase_guid(guid, qtd)
        else:
            print("Compra cancelada. Para comprar depois:")
            print(f"  python3 -m ingestao.subradar.directdata_lookalike --purchase {guid} --quantidade {qtd}")


def _cli_purchase_guid(search_guid: str, quantity: int) -> None:
    print(f"\nComprando {quantity} empresas do guid {search_guid[:16]}…")
    result = purchase(search_guid, quantity)

    if not result.get("success"):
        print(f"Erro: {result.get('error')}")
        return

    charged     = result.get("quantityCharged", 0)
    amount      = result.get("amountCharged", 0)
    export_guid = result.get("exportGuid", "")

    print(f"Comprado: {charged} empresas | Custo: R$ {amount:.2f}")
    print(f"ExportGuid: {export_guid}")
    print("Aguardando processamento…")

    if poll_until_ready(export_guid):
        print("Export pronto! Baixando…")
        zip_bytes = download_zip(export_guid)
        csv_text  = csv_from_zip(zip_bytes)

        output_path = f"lookalike_{export_guid[:8]}.csv"
        with open(output_path, "w", encoding="utf-8") as fp:
            fp.write(csv_text)

        lines = csv_text.count("\n")
        print(f"Salvo em {output_path} ({lines} linhas)")


def main() -> None:
    logging.basicConfig(level=logging.INFO, format="%(message)s")

    if not _TOKEN:
        print("DIRECT_DATA_TOKEN não configurado.")
        sys.exit(1)

    parser = argparse.ArgumentParser(description="LookALike — Prospecção Direct Data")
    parser.add_argument("--cnae",         nargs="+", help="Código(s) CNAE principal ex: 6920601")
    parser.add_argument("--estados",      nargs="+", help="UFs ex: MG SP RJ")
    parser.add_argument("--porte",        nargs="+", help="MEI ME EPP MEDIO GRANDE")
    parser.add_argument("--preview-only", action="store_true", help="Apenas conta, não compra")
    parser.add_argument("--quantidade",   type=int,  help="Qtd a comprar (default: tudo até 500)")
    parser.add_argument("--purchase",     metavar="SEARCH_GUID", help="Pula o preview e compra direto pelo guid")

    args = parser.parse_args()

    if args.purchase:
        qtd = args.quantidade or 500
        _cli_purchase_guid(args.purchase, qtd)
    else:
        if not any([args.cnae, args.estados, args.porte]):
            parser.print_help()
            sys.exit(1)
        _cli_preview(args)


if __name__ == "__main__":
    main()
