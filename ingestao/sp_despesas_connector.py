"""
Conector: Despesas do Governo do Estado de SP (SIGEO Lei 131)
Fonte: https://www.fazenda.sp.gov.br/SigeoLei131/Paginas/ConsultaDespesaAno.aspx

Uso:
    # baixar + ingerir um ano
    python3 -m ingestao.sp_despesas_connector --ano 2024

    # ingerir de arquivo local já baixado
    python3 -m ingestao.sp_despesas_connector --arquivo /tmp/despesa2024.csv --ano 2024

    # ingerir todos os anos disponíveis
    python3 -m ingestao.sp_despesas_connector --todos
"""

from __future__ import annotations

import argparse
import csv
import io
import logging
import os
import re
import sys
import time
import zipfile
from pathlib import Path
from typing import Optional

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from dossie.client import SupabaseClient

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
log = logging.getLogger(__name__)

SIGEO_URL = "https://www.fazenda.sp.gov.br/SigeoLei131/Paginas/ConsultaDespesaAno.aspx?orgao="
ANOS_DISPONIVEIS = [2023, 2024, 2025, 2026]
BATCH_SIZE = 100
CACHE_DIR = Path("/tmp/sigeo_sp")


def build_session() -> requests.Session:
    s = requests.Session()
    retry = Retry(total=3, backoff_factor=2, status_forcelist=[500, 502, 503])
    s.mount("https://", HTTPAdapter(max_retries=retry))
    s.headers.update({"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"})
    return s


def _get_hidden(html: str, name: str) -> str:
    m = re.search(rf'name="{re.escape(name)}"[^>]*value="([^"]*)"', html)
    return m.group(1) if m else ""


def baixar_ano(ano: int, session: Optional[requests.Session] = None) -> Path:
    """Baixa o ZIP do SIGEO para o ano dado e extrai o CSV. Retorna o Path do CSV."""
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    dest = CACHE_DIR / f"despesa{ano}.csv"
    if dest.exists() and dest.stat().st_size > 1_000_000:
        log.info("Cache: %s", dest)
        return dest

    s = session or build_session()
    log.info("Baixando SIGEO %d...", ano)

    r0 = s.get(SIGEO_URL, timeout=20)
    r0.raise_for_status()

    # Passo 1: consultar o ano para popular ViewState
    r1 = s.post(SIGEO_URL, data={
        "__EVENTTARGET": "", "__EVENTARGUMENT": "",
        "__VIEWSTATE":          _get_hidden(r0.text, "__VIEWSTATE"),
        "__VIEWSTATEGENERATOR": _get_hidden(r0.text, "__VIEWSTATEGENERATOR"),
        "__EVENTVALIDATION":    _get_hidden(r0.text, "__EVENTVALIDATION"),
        "ctl00$ContentPlaceHolder1$ddlAno": str(ano),
        "ctl00$ContentPlaceHolder1$btnConsultar": "Consultar",
    }, timeout=30)
    r1.raise_for_status()

    # Passo 2: trigger do download via __doPostBack
    r2 = s.post(SIGEO_URL, data={
        "__EVENTTARGET": "ctl00$ContentPlaceHolder1$lkbDownloadCliqueAqui",
        "__EVENTARGUMENT": "",
        "__VIEWSTATE":          _get_hidden(r1.text, "__VIEWSTATE"),
        "__VIEWSTATEGENERATOR": _get_hidden(r1.text, "__VIEWSTATEGENERATOR"),
        "__EVENTVALIDATION":    _get_hidden(r1.text, "__EVENTVALIDATION"),
        "ctl00$ContentPlaceHolder1$ddlAno": str(ano),
    }, timeout=180)
    r2.raise_for_status()

    ct = r2.headers.get("content-type", "")
    if "zip" not in ct:
        raise RuntimeError(f"Resposta inesperada: {ct} — {r2.text[:200]}")

    log.info("ZIP recebido: %.1f MB", len(r2.content) / 1024 / 1024)
    with zipfile.ZipFile(io.BytesIO(r2.content)) as z:
        for name in z.namelist():
            if name.endswith(".csv"):
                data = z.read(name)
                dest.write_bytes(data)
                log.info("Extraído: %s (%.0f MB)", dest, dest.stat().st_size / 1024 / 1024)
                return dest

    raise RuntimeError("Nenhum CSV encontrado no ZIP")


def _parse_valor(v: str) -> float:
    try:
        return float(v.strip().replace(".", "").replace(",", "."))
    except (ValueError, AttributeError):
        return 0.0


def _cnpj_ou_none(cod: str) -> Optional[str]:
    """Retorna CNPJ normalizado (14 dígitos) se parecer PJ, senão None."""
    digits = re.sub(r"\D", "", cod or "")
    if len(digits) == 14:
        return digits
    if len(digits) == 11:
        return None  # CPF — pessoa física
    return None


def _normalizar_linha(row: dict, ano: int) -> dict:
    cod_credor = (row.get("CODIGO CREDOR") or "").strip()
    return {
        "ano":               ano,
        "cod_orgao":         (row.get("CODIGO ORGAO") or "").strip(),
        "nome_orgao":        (row.get("NOME ORGAO") or "").strip() or None,
        "cod_uo":            (row.get("CODIGO UNIDADE ORCAMENTARIA") or "").strip() or None,
        "nome_uo":           (row.get("NOME UNIDADE ORCAMENTARIA") or "").strip() or None,
        "cod_ug":            (row.get("CODIGO UNIDADE GESTORA") or "").strip() or None,
        "nome_ug":           (row.get("NOME UNIDADE GESTORA") or "").strip() or None,
        "cod_categoria":     (row.get("CODIGO CATEGORIA DE DESPESA") or "").strip() or None,
        "nome_categoria":    (row.get("NOME CATEGORIA DE DESPESA") or "").strip() or None,
        "cod_grupo":         (row.get("CODIGO GRUPO DE DESPESA") or "").strip() or None,
        "nome_grupo":        (row.get("NOME GRUPO DE DESPESA") or "").strip() or None,
        "cod_modalidade":    (row.get("CODIGO MODALIDADE") or "").strip() or None,
        "nome_modalidade":   (row.get("NOME MODALIDADE") or "").strip() or None,
        "cod_elemento":      (row.get("CODIGO ELEMENTO DE DESPESA") or "").strip() or None,
        "nome_elemento":     (row.get("NOME ELEMENTO DE DESPESA") or "").strip() or None,
        "cod_item":          (row.get("CODIGO ITEM DE DESPESA") or "").strip(),  # '' quando ausente (NULL causa conflito intra-batch)
        "nome_item":         (row.get("NOME ITEM DE DESPESA") or "").strip() or None,
        "cod_funcao":        (row.get("CODIGO FUNCAO") or "").strip() or None,
        "nome_funcao":       (row.get("NOME FUNCAO") or "").strip() or None,
        "cod_subfuncao":     (row.get("CODIGO SUBFUNCAO") or "").strip() or None,
        "nome_subfuncao":    (row.get("NOME SUBFUNCAO") or "").strip() or None,
        "cod_programa":      (row.get("CODIGO PROGRAMA") or "").strip() or None,
        "nome_programa":     (row.get("NOME PROGRAMA") or "").strip() or None,
        "cod_ptrab":         (row.get("CODIGO PROGRAMA DE TRABALHO") or "").strip() or None,
        "nome_ptrab":        (row.get("NOME PROGRAMA DE TRABALHO") or "").strip() or None,
        "cod_fonte":         (row.get("CODIGO FONTE DE RECURSOS") or "").strip() or None,
        "nome_fonte":        (row.get("NOME FONTE DE RECURSOS") or "").strip() or None,
        "numero_processo":   (row.get("NUMERO PROCESSO") or "").strip() or None,
        "numero_empenho":    (row.get("NUMERO NOTA DE EMPENHO") or "").strip() or None,
        "cod_credor":        cod_credor or None,
        "nome_credor":       (row.get("NOME CREDOR") or "").strip() or None,
        "cnpj_credor":       _cnpj_ou_none(cod_credor),
        "cod_acao":          (row.get("CODIGO ACAO") or "").strip() or None,
        "nome_acao":         (row.get(" NOME ACAO") or "").strip() or None,
        "tipo_licitacao":    (row.get(" TIPO LICITACAO") or "").strip() or None,
        "valor_empenhado":   _parse_valor(row.get("VALOR EMPENHADO") or "0"),
        "valor_liquidado":   _parse_valor(row.get("VALOR LIQUIDADO") or "0"),
        "valor_pago":        _parse_valor(row.get("VALOR PAGO") or "0"),
        "valor_pago_anos_ant": _parse_valor(row.get("VALOR PAGO DE ANOS ANTERIORES") or "0"),
    }


def ingerir_arquivo(csv_path: Path, ano: int, db: SupabaseClient) -> dict:
    log.info("Ingerindo %s (%d)...", csv_path.name, ano)
    total = inseridos = erros = 0
    batch: list[dict] = []

    with open(csv_path, encoding="latin-1", errors="replace") as f:
        reader = csv.DictReader(f, delimiter=",")
        for row in reader:
            total += 1
            rec = _normalizar_linha(row, ano)

            # Pular linhas sem empenho (agregações ou linhas em branco)
            if not rec["numero_empenho"] or not rec["cod_orgao"]:
                continue

            batch.append(rec)

            if len(batch) >= BATCH_SIZE:
                n = _flush(batch, db)
                inseridos += n
                if n == 0:
                    erros += len(batch)
                batch = []
                if total % 50_000 == 0:
                    log.info("  %d: %d lidas, %d inseridas, %d erros", ano, total, inseridos, erros)

        if batch:
            inseridos += _flush(batch, db)

    log.info("Ano %d: %d linhas lidas, %d inseridas", ano, total, inseridos)
    return {"ano": ano, "total_lidas": total, "inseridas": inseridos}


def _dedup_batch(batch: list[dict]) -> list[dict]:
    """Remove duplicatas intra-batch pela chave única (ano, numero_empenho, cod_credor, cod_item).
    Mantém a última ocorrência (que pode ter valores_pago mais atualizados)."""
    seen: dict[tuple, dict] = {}
    for rec in batch:
        key = (rec["ano"], rec["numero_empenho"], rec["cod_credor"], rec["cod_item"])
        seen[key] = rec
    return list(seen.values())


def _flush(batch: list[dict], db: SupabaseClient) -> int:
    """Upsert de um batch via Supabase REST com dedup intra-batch e retry."""
    import time as _time
    batch = _dedup_batch(batch)
    for attempt in range(4):
        try:
            resp = db.session.post(
                f"{db.url}/rest/v1/sp_despesas"
                "?on_conflict=ano,numero_empenho,cod_credor,cod_item",
                json=batch,
                headers={
                    **db.session.headers,
                    "Prefer": "resolution=ignore-duplicates,return=minimal",
                },
                timeout=60,
            )
            if resp.status_code in (200, 201):
                return len(batch)
            if resp.status_code == 429:
                wait = 2 ** attempt * 5
                log.warning("Rate limit (429) — aguardando %ds (tentativa %d/4)", wait, attempt+1)
                _time.sleep(wait)
                continue
            log.warning("Upsert status %d: %s", resp.status_code, resp.text[:300])
            if attempt < 3:
                _time.sleep(2 ** attempt)
        except Exception as e:
            log.error("Erro no flush (tentativa %d/4): %s", attempt+1, e)
            if attempt < 3:
                _time.sleep(2 ** attempt)
    return 0


def main() -> None:
    parser = argparse.ArgumentParser(description="Ingestor SIGEO SP → Supabase")
    parser.add_argument("--ano",      type=int, help="Ano a baixar e ingerir (ex: 2024)")
    parser.add_argument("--arquivo",  help="CSV local já baixado (requer --ano)")
    parser.add_argument("--todos",    action="store_true", help="Ingerir 2023, 2024 e 2025")
    parser.add_argument("--so-baixar", action="store_true", help="Apenas baixar, sem ingerir")
    args = parser.parse_args()

    db  = SupabaseClient.from_env()
    ses = build_session()

    anos = ANOS_DISPONIVEIS[:3] if args.todos else ([args.ano] if args.ano else [])
    if not anos and not args.arquivo:
        parser.print_help()
        return

    if args.arquivo and args.ano:
        csv_path = Path(args.arquivo)
        if not args.so_baixar:
            ingerir_arquivo(csv_path, args.ano, db)
        return

    resultados = []
    for ano in anos:
        try:
            csv_path = baixar_ano(ano, ses)
            if not args.so_baixar:
                r = ingerir_arquivo(csv_path, ano, db)
                resultados.append(r)
        except Exception as e:
            log.error("Erro no ano %d: %s", ano, e)

    if resultados:
        print("\n=== RESUMO ===")
        for r in resultados:
            print(f"  {r['ano']}: {r['total_lidas']:,} lidas, {r['inseridas']:,} inseridas")


if __name__ == "__main__":
    main()
