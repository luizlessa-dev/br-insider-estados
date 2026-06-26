"""
Seed semestral da tabela sub_lista_suja a partir do PDF oficial do MTE.

Uso:
    python -m ingestao.subradar.lista_suja_seeder

O PDF contém uma tabela com: razão social, CNPJ/CPF, UF, município,
data de inclusão, nº de trabalhadores resgatados.

Estratégia: pdfplumber extrai as tabelas, faz parse, filtra CNPJs (14 dígitos).
"""
from __future__ import annotations

import io
import logging
import os
import re
import time

import pdfplumber
import requests

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("lista_suja_seeder")

PDF_URL = (
    "https://www.gov.br/trabalho-e-emprego/pt-br/assuntos/inspecao-do-trabalho"
    "/areas-de-atuacao/cadastro_de_empregadores.pdf"
)
# Fallback: URL direta do arquivo (caso gov.br redirecione)
PDF_FALLBACK = (
    "https://sit.trabalho.gov.br/radar/assets/lista_suja.pdf"
)

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SUPABASE_KEY = (
    os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    or os.environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY")
    or ""
)

TABLE      = "sub_lista_suja"
BATCH_SIZE = 200

CNPJ_RE = re.compile(r"\d{2}[\.\s]?\d{3}[\.\s]?\d{3}[/\s]?\d{4}[\-\s]?\d{2}")
CPF_RE  = re.compile(r"\d{3}[\.\s]?\d{3}[\.\s]?\d{3}[\-\s]?\d{2}")


def _headers():
    return {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "resolution=ignore-duplicates,return=minimal",
    }


def _strip(v: str) -> str:
    return re.sub(r"\D", "", str(v or ""))


def _upsert(rows: list[dict]) -> None:
    if not rows:
        return
    url = f"{SUPABASE_URL}/rest/v1/{TABLE}"
    for attempt in range(4):
        r = requests.post(url, json=rows, headers=_headers(), timeout=60)
        if r.ok:
            return
        if r.status_code in (429, 503):
            time.sleep(2 ** attempt)
            continue
        logger.error("upsert falhou: %s %s", r.status_code, r.text[:300])
        r.raise_for_status()


def _download_pdf() -> bytes:
    headers = {
        "User-Agent": "Mozilla/5.0 (compatible; Subradar/1.0)",
        "Accept": "application/pdf,*/*",
    }
    for url in [PDF_URL, PDF_FALLBACK]:
        try:
            logger.info("Tentando: %s", url)
            r = requests.get(url, headers=headers, timeout=60, allow_redirects=True)
            if r.ok and b"%PDF" in r.content[:10]:
                logger.info("PDF baixado: %d KB", len(r.content) // 1024)
                return r.content
            logger.warning("URL retornou %s ou não é PDF", r.status_code)
        except Exception as e:
            logger.warning("Erro em %s: %s", url, e)
    raise RuntimeError("Não foi possível baixar o PDF da Lista Suja MTE")


def _parse_pdf(pdf_bytes: bytes) -> list[dict]:
    """Extrai registros do PDF usando pdfplumber."""
    registros: list[dict] = []

    with pdfplumber.open(io.BytesIO(pdf_bytes)) as pdf:
        logger.info("PDF com %d páginas", len(pdf.pages))

        for page_num, page in enumerate(pdf.pages, 1):
            tables = page.extract_tables()
            if not tables:
                continue

            for table in tables:
                for row in table:
                    if not row or all(not c for c in row):
                        continue

                    # Concatena células para buscar CNPJ/CPF
                    row_text = " ".join(str(c or "") for c in row)

                    cnpj_matches = CNPJ_RE.findall(row_text)
                    cnpj_digits  = next((_strip(m) for m in cnpj_matches if len(_strip(m)) == 14), None)
                    cpf_digits   = None
                    if not cnpj_digits:
                        cpf_matches = CPF_RE.findall(row_text)
                        cpf_digits  = next((_strip(m) for m in cpf_matches if len(_strip(m)) == 11), None)

                    doc = cnpj_digits or cpf_digits
                    if not doc:
                        continue

                    # Tenta extrair campos por posição (ordem típica da tabela MTE)
                    cells = [str(c or "").strip() for c in row]

                    registros.append({
                        "cpf_cnpj":         doc,
                        "tipo_doc":         "CNPJ" if cnpj_digits else "CPF",
                        "nome_empregador":  _find_nome(cells, doc),
                        "uf":               _find_uf(cells),
                        "municipio":        _find_municipio(cells),
                        "dat_inclusao":     _find_data(cells),
                        "qtd_trabalhadores": _find_qtd(cells),
                        "decisao_judicial": _find_decisao(cells),
                    })

    logger.info("Registros extraídos do PDF: %d", len(registros))
    return registros


def _find_nome(cells: list[str], doc: str) -> str:
    """Retorna a célula mais longa que não é o documento nem UF."""
    uf_set = {
        "AC","AL","AP","AM","BA","CE","DF","ES","GO","MA","MT","MS",
        "MG","PA","PB","PR","PE","PI","RJ","RN","RS","RO","RR","SC",
        "SP","SE","TO",
    }
    candidates = [
        c for c in cells
        if c and len(c) > 5
        and _strip(c) != doc
        and c.upper() not in uf_set
        and not re.match(r"^\d{1,3}$", c)
        and not re.match(r"\d{2}/\d{4}", c)
    ]
    return max(candidates, key=len, default="")[:300]


def _find_uf(cells: list[str]) -> str:
    uf_set = {
        "AC","AL","AP","AM","BA","CE","DF","ES","GO","MA","MT","MS",
        "MG","PA","PB","PR","PE","PI","RJ","RN","RS","RO","RR","SC",
        "SP","SE","TO",
    }
    return next((c.upper() for c in cells if c and c.upper().strip() in uf_set), "")


def _find_municipio(cells: list[str]) -> str:
    # Município: texto médio sem dígitos, não é UF
    uf_set = {
        "AC","AL","AP","AM","BA","CE","DF","ES","GO","MA","MT","MS",
        "MG","PA","PB","PR","PE","PI","RJ","RN","RS","RO","RR","SC",
        "SP","SE","TO",
    }
    candidates = [
        c for c in cells
        if c and 3 < len(c) < 50
        and not any(d.isdigit() for d in c)
        and c.upper().strip() not in uf_set
    ]
    # Pega o segundo candidato (o primeiro tende a ser o nome do empregador)
    return candidates[1] if len(candidates) > 1 else (candidates[0] if candidates else "")


def _find_data(cells: list[str]) -> str:
    for c in cells:
        if re.match(r"\d{2}/\d{4}", c.strip()):
            return c.strip()
        if re.match(r"\d{4}-\d{2}", c.strip()):
            return c.strip()
    return ""


def _find_qtd(cells: list[str]) -> str:
    for c in cells:
        if re.match(r"^\d{1,4}$", c.strip()):
            return c.strip()
    return ""


def _find_decisao(cells: list[str]) -> str:
    keywords = ["liminar", "suspensa", "decisão", "judicial", "reintroduzido"]
    for c in cells:
        if any(k in c.lower() for k in keywords):
            return c.strip()[:200]
    return ""


def run() -> None:
    if not SUPABASE_URL or not SUPABASE_KEY:
        raise SystemExit("SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY ausentes")

    pdf_bytes = _download_pdf()
    registros = _parse_pdf(pdf_bytes)

    if not registros:
        logger.warning("Nenhum registro extraído do PDF — verificar estrutura")
        return

    # Dedup por cpf_cnpj
    seen: set[str] = set()
    uniq = []
    for r in registros:
        if r["cpf_cnpj"] not in seen:
            seen.add(r["cpf_cnpj"])
            uniq.append(r)

    logger.info("Registros únicos por CPF/CNPJ: %d", len(uniq))

    for i in range(0, len(uniq), BATCH_SIZE):
        _upsert(uniq[i : i + BATCH_SIZE])

    logger.info("Seed Lista Suja MTE concluído: %d registros", len(uniq))


if __name__ == "__main__":
    run()
