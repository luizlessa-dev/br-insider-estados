"""
Seed mensal da tabela sub_anpd — Processos Administrativos Sancionadores da
ANPD (Autoridade Nacional de Proteção de Dados) por descumprimento da LGPD.

Fontes (nesta ordem de precedência):
  1. XLSX "Painel da Fiscalização" (aba PAS) — fonte primária, estruturada.
     CNPJ explícito, datas, condutas e valor de multa já numérico por
     instância (1ª instância / pós reconsideração / pós CD).
     https://www.gov.br/anpd/pt-br/assuntos/fiscalizacao/saiba-como_fiscalizamos/dadospainelfiscalizacao.xlsx/@@download/file
  2. Página "Decisões em Processos Sancionadores" (HTML) — status fino em
     texto livre (ex.: "Recurso em análise pelo Conselho Diretor") e link
     direto pro PDF do Relatório de Instrução. Casada com (1) por número
     de processo — é a única chave estável entre as duas fontes.
     https://www.gov.br/anpd/pt-br/centrais-de-conteudo/decisoes-em-processos-sancionadores
  3. PDF do Relatório de Instrução (quando existe) — a XLSX só traz o
     artigo da LGPD citado, não o texto da decisão. Extraímos um resumo
     por heurística de seção (busca "CONCLUSÃO"/"DECIDO"/"DISPOSITIVO";
     na ausência, usa a cauda do documento). NÃO tentamos re-extrair o
     valor da multa do PDF — a XLSX já traz isso numérico e é mais
     confiável que regex sobre texto jurídico de formato variável.

Nota sobre CNPJ: diferente do que se poderia supor, a ANPD publica o CNPJ
do ente fiscalizado diretamente na própria base — inclusive para órgãos
públicos (cada unidade orçamentária tem CNPJ próprio no Brasil). Não
observamos nenhuma linha sem CNPJ nos 36 processos PAS inspecionados em
2026-09. Mantemos ainda assim um fallback de match exato (sem fuzzy) por
razão social contra cnpj_enriquecido, só como rede de segurança — o repo
não tem precedente de correspondência aproximada nome→CNPJ, e um match
errado aqui é pior que nenhum (ver ingestao/subradar/base.py, filosofia
de não afirmar o que não se sabe).

Uso:
    python -m ingestao.subradar.anpd_seeder

Tabela: sub_anpd (db/migrations/0055_sub_anpd_schema.sql)
Frequência: mensal (mesmo ciclo de CEIS/CNEP/IBAMA/CVM em subradar-seed.yml)

Diferença de convenção deliberada: ao contrário de ibama_seeder/lista_suja_seeder
(que inserem sem on_conflict e deixam o dedup pro momento da consulta),
aqui fazemos upsert de verdade via on_conflict=num_processo — o volume é
baixo (dezenas de linhas, não milhões) e num_processo é uma chave natural
estável, então não há razão pra deixar a tabela crescer sem limite a cada
reseed mensal.
"""
from __future__ import annotations

import io
import logging
import os
import re
import time
import unicodedata
from datetime import date, datetime

import openpyxl
import pdfplumber
import requests
from bs4 import BeautifulSoup

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("anpd_seeder")

XLSX_URL = (
    "https://www.gov.br/anpd/pt-br/assuntos/fiscalizacao/saiba-como_fiscalizamos/"
    "dadospainelfiscalizacao.xlsx/@@download/file"
)
DECISOES_URL = "https://www.gov.br/anpd/pt-br/centrais-de-conteudo/decisoes-em-processos-sancionadores"
FISCALIZACAO_URL = (
    "https://www.gov.br/anpd/pt-br/assuntos/fiscalizacao-2/saiba-como_fiscalizamos/atividades-fiscalizatorias/"
)
SEI_PESQUISA_PUBLICA = (
    "https://sei.anpd.gov.br/sei/modulos/pesquisa/md_pesq_processo_pesquisar.php"
    "?acao_externa=protocolo_pesquisar&acao_origem_externa=protocolo_pesquisar&id_orgao_acesso_externo=0"
)

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SUPABASE_KEY = (
    os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    or os.environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY")
    or ""
)

TABLE = "sub_anpd"
UA = {"User-Agent": "Mozilla/5.0 (compatible; Subradar/1.0; +contato@subradar.com.br)"}
REQUEST_DELAY = 2.0  # respeito ao servidor — página gov.br + N PDFs por run

PROCESSO_RE = re.compile(r"\d{5}\.\d{6}/\d{4}-\d{2}")


# ─────────────────────────────────────────────────────────────
# Utilitários
# ─────────────────────────────────────────────────────────────

def _strip(v) -> str:
    return re.sub(r"\D", "", str(v or ""))


def _sem_acentos(s: str) -> str:
    s = unicodedata.normalize("NFD", s or "")
    return "".join(c for c in s if unicodedata.category(c) != "Mn")


def _cnpj_valido(digits: str) -> bool:
    return len(digits) in (11, 14)


def _to_date(v) -> str | None:
    if v is None:
        return None
    if isinstance(v, (date, datetime)):
        return v.date().isoformat() if isinstance(v, datetime) else v.isoformat()
    return None


def _first_non_none(*vals):
    for v in vals:
        if v is not None and str(v).strip() != "":
            return v
    return None


# A XLSX não deixa célula vazia quando uma etapa do processo não ocorreu —
# preenche com um texto-sentinela ("Não houve recurso", "Em andamento" etc.)
# que, se não filtrado, contamina a precedência de conduta/sanção (ex.:
# Ministério da Saúde 00261.000456/2022-12, que nunca teve recurso, tinha
# "Sanções aplicadas pós CD" = "Não houve recurso" — texto, não nulo).
_SENTINELAS = {
    "não houve", "não houve recurso", "não submetido ao cd",
    "em andamento", "n/a", "none",
}


def _util(v):
    """Como _first_non_none, mas trata texto-sentinela como ausência de valor."""
    if v is None:
        return None
    s = str(v).strip()
    if not s or s.lower() in _SENTINELAS:
        return None
    return v


def _headers():
    return {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates,return=minimal",
    }


def _normalize_rows(rows: list[dict]) -> list[dict]:
    """Garante que todos os dicts do batch tenham exatamente as mesmas chaves
    (PGRST102). Nem todo registro passa por _enriquecer_com_pdf/_scrape_decisoes
    — quem não teve match na página Decisões nunca ganha des_situacao/
    url_relatorio/fundamentacao no dict, então o batch fica com chaves
    inconsistentes entre linhas se não normalizar aqui."""
    all_keys = set()
    for r in rows:
        all_keys.update(r.keys())
    return [{k: r.get(k) for k in all_keys} for r in rows]


def _upsert(rows: list[dict]) -> None:
    if not rows:
        return
    rows = _normalize_rows(rows)
    url = f"{SUPABASE_URL}/rest/v1/{TABLE}?on_conflict=num_processo"
    for attempt in range(4):
        r = requests.post(url, json=rows, headers=_headers(), timeout=60)
        if r.ok:
            return
        if r.status_code in (429, 503):
            time.sleep(2 ** attempt)
            continue
        logger.error("upsert falhou: %s %s", r.status_code, r.text[:500])
        r.raise_for_status()
    raise RuntimeError(f"upsert {TABLE}: falhou após 4 tentativas")


def _resolver_cnpj_por_nome(nome: str) -> str | None:
    """Fallback só quando a própria ANPD não informou CNPJ. Match exato
    (sem fuzzy) por razão social normalizada contra cnpj_enriquecido."""
    if not SUPABASE_URL or not SUPABASE_KEY or not nome:
        return None
    alvo = _sem_acentos(nome).upper().strip()
    try:
        r = requests.get(
            f"{SUPABASE_URL}/rest/v1/cnpj_enriquecido",
            params={"select": "cnpj,razao_social", "limit": 5000},
            headers={
                "apikey": SUPABASE_KEY,
                "Authorization": f"Bearer {SUPABASE_KEY}",
                "Accept": "application/json",
            },
            timeout=30,
        )
        if not r.ok:
            return None
        for row in r.json():
            if _sem_acentos(row.get("razao_social") or "").upper().strip() == alvo:
                return _strip(row.get("cnpj"))
    except Exception as e:
        logger.warning("fallback de CNPJ por nome falhou para %r: %s", nome, e)
    return None


# ─────────────────────────────────────────────────────────────
# 1. XLSX — Painel da Fiscalização, aba PAS
# ─────────────────────────────────────────────────────────────

def _baixar_xlsx() -> bytes:
    r = requests.get(XLSX_URL, headers=UA, timeout=60)
    r.raise_for_status()
    if b"PK" not in r.content[:4]:  # xlsx = zip, magic bytes "PK\x03\x04"
        raise RuntimeError("Download do XLSX da ANPD não retornou um arquivo válido")
    logger.info("XLSX baixado: %d KB", len(r.content) // 1024)
    return r.content


def _parse_xlsx_pas(xlsx_bytes: bytes, cnpjs_html: dict[str, str] | None = None) -> list[dict]:
    wb = openpyxl.load_workbook(io.BytesIO(xlsx_bytes), data_only=True)
    ws = wb["PAS"]
    rows = list(ws.iter_rows(values_only=True))
    headers = rows[0]
    idx = {h: i for i, h in enumerate(headers)}

    def get(row, col):
        i = idx.get(col)
        return row[i] if i is not None else None

    registros = []
    for row in rows[1:]:
        num_processo = str(get(row, "Nº Processo SEI") or "").strip()
        if not num_processo:
            continue

        ente = str(get(row, "Agente de Tratamento") or "").strip()

        cnpj_raw = str(get(row, "CNPJ") or "").strip()
        cnpj_digits = _strip(cnpj_raw)
        if not _cnpj_valido(cnpj_digits):
            # CNPJ da XLSX ausente ou corrompido (ex.: RaiaDrogasil
            # 00261.000439/2025-28 trazia o nº do processo na célula CNPJ)
            cnpj_digits = (cnpjs_html or {}).get(num_processo)
        if not _cnpj_valido(cnpj_digits or ""):
            cnpj_digits = _resolver_cnpj_por_nome(ente)  # None se não achar — não inventamos

        # A XLSX só tem "Condutas sancionadas" para 1ª instância e pós-CD — não
        # existe coluna "pós reconsideração" pra condutas (só pra imputadas).
        conduta = _first_non_none(
            _util(get(row, "Condutas sancionadas pós CD")),
            _util(get(row, "Condutas sancionadas 1ª instância")),
            _util(get(row, "Condutas imputadas pós reconsideração")),
            _util(get(row, "Condutas imputadas 1ª instância")),
        )
        sancao = _first_non_none(
            _util(get(row, "Sanções aplicadas pós CD")),
            _util(get(row, "Sanções aplicadas pós reconsideração")),
            _util(get(row, "Sanções aplicadas 1ª instância")),
        )
        # Dobra sanção aplicada dentro de conduta_apurada (schema não tem coluna
        # própria pra isso) — a severidade do connector depende de saber se
        # houve "Publicização da infração", não só a conduta investigada.
        conduta_texto = str(conduta or "").strip() or None
        if sancao:
            conduta_texto = (
                f"{conduta_texto} — Sanção aplicada: {sancao}"
                if conduta_texto else f"Sanção aplicada: {sancao}"
            )

        val_multa = _first_non_none(
            get(row, "Valor da multa aplicado pós CD"),
            get(row, "Valor da multa pós reconsideração"),
            get(row, "Valor da multa 1ª instância"),
        )
        try:
            val_multa = float(val_multa) if val_multa is not None else None
        except (TypeError, ValueError):
            val_multa = None

        dat_decisao_final = _to_date(_first_non_none(
            get(row, "Data decisão do CD"),
            get(row, "Data decisão CGF"),
        ))

        registros.append({
            "num_processo": num_processo,
            "cnpj_cpf": cnpj_digits or None,
            "ente_fiscalizado": ente,
            "setor": str(get(row, "Setor") or "").strip() or None,
            "conduta_apurada": conduta_texto,
            "des_fase": str(get(row, "Situação atual") or "").strip() or "Em andamento",
            "val_multa": val_multa,
            "dat_instauracao": _to_date(get(row, "Data_instauração")),
            "dat_decisao_final": dat_decisao_final,
            "url_fonte": SEI_PESQUISA_PUBLICA,
            # preenchidos depois por _enriquecer_com_pdf, quando houver match
            # na página Decisões — explícitos aqui pra o dict já nascer com
            # o shape completo (_normalize_rows cobre o caso mesmo assim, mas
            # não custa deixar claro na origem).
            "des_situacao": None,
            "url_relatorio": None,
            "fundamentacao": None,
        })

    logger.info("XLSX aba PAS: %d processos", len(registros))
    return registros


# ─────────────────────────────────────────────────────────────
# 1b. HTML — "Saiba como fiscalizamos" (fallback de CNPJ por nº de processo)
# ─────────────────────────────────────────────────────────────
#
# A célula CNPJ da XLSX veio errada pra RaiaDrogasil (00261.000439/2025-28
# — continha o próprio número do processo, não o CNPJ) enquanto a tabela
# HTML desta página trazia o valor correto. Usamos como fallback por
# número de processo (chave estável), não como fonte primária — a XLSX
# tem 36 processos PAS estruturados contra ~8 tabelas HTML misturando
# PAS/procedimento preparatório/monitoramento nesta página.

def _scrape_fiscalizacao_cnpjs() -> dict[str, str]:
    """Retorna {num_processo: cnpj_digits} de todas as tabelas da página
    que tenham colunas Nº do Processo + CNPJ (mistura PAS/preparatório/
    monitoramento — não filtramos por categoria, só usamos como lookup)."""
    try:
        r = requests.get(FISCALIZACAO_URL, headers=UA, timeout=30)
        r.raise_for_status()
    except Exception as e:
        logger.warning("Falha ao buscar página Saiba como fiscalizamos: %s", e)
        return {}

    soup = BeautifulSoup(r.content, "lxml")
    out: dict[str, str] = {}
    for table in soup.find_all("table"):
        trs = table.find_all("tr")
        if not trs:
            continue
        header_cells = [c.get_text(strip=True).lower() for c in trs[0].find_all(["td", "th"])]
        if not any("processo" in h for h in header_cells) or not any("cnpj" in h for h in header_cells):
            continue
        col_processo = next((i for i, h in enumerate(header_cells) if "processo" in h), None)
        col_cnpj = next((i for i, h in enumerate(header_cells) if "cnpj" in h), None)
        for tr in trs[1:]:
            cells = tr.find_all(["td", "th"])
            if col_processo is None or col_cnpj is None:
                continue
            if col_processo >= len(cells) or col_cnpj >= len(cells):
                continue
            m = PROCESSO_RE.search(cells[col_processo].get_text(" ", strip=True))
            if not m:
                continue
            cnpj_digits = _strip(cells[col_cnpj].get_text(strip=True))
            if _cnpj_valido(cnpj_digits):
                out[m.group(0)] = cnpj_digits

    logger.info("Página Saiba como fiscalizamos: %d processos com CNPJ", len(out))
    return out


# ─────────────────────────────────────────────────────────────
# 2. HTML — "Decisões em Processos Sancionadores" (status fino + PDF)
# ─────────────────────────────────────────────────────────────

def _scrape_decisoes() -> dict[str, dict]:
    """Retorna {num_processo: {"des_situacao": str, "url_relatorio": str}}."""
    try:
        r = requests.get(DECISOES_URL, headers=UA, timeout=30)
        r.raise_for_status()
    except Exception as e:
        logger.warning("Falha ao buscar página Decisões: %s — seguindo só com XLSX", e)
        return {}

    soup = BeautifulSoup(r.content, "lxml")
    marcador = soup.find(string=lambda s: s and "processos sancionadores finalizados" in s.lower())
    wrapper = marcador.find_parent("div", class_="column-blocks-wrapper") if marcador else None
    if wrapper is None:
        logger.warning("Estrutura da página Decisões mudou — marcador não encontrado, seguindo só com XLSX")
        return {}

    out: dict[str, dict] = {}
    url_relatorio = None
    time.sleep(REQUEST_DELAY)

    for p in wrapper.find_all("p"):
        link = p.find("a")
        texto = p.get_text(" ", strip=True)
        if not texto:
            continue

        if link and re.match(r"Relat[oó]rio de Instru[cç][aã]o", link.get_text(strip=True), re.I):
            url_relatorio = link.get("href")
            if url_relatorio and url_relatorio.startswith("/"):
                url_relatorio = "https://www.gov.br" + url_relatorio
            continue

        if link and "despacho decis" in link.get_text(strip=True).lower():
            continue  # despacho decisório — não é o RI, ignora pro fim de url_relatorio

        m = PROCESSO_RE.search(texto)
        if m and texto.lower().startswith("processo"):
            num_processo = m.group(0)
            out[num_processo] = {"des_situacao": None, "url_relatorio": url_relatorio}
            continue

        # próximo parágrafo depois de "Processo nº..." é o status, com ou sem prefixo "Status:"
        if out and num_processo in out and out[num_processo]["des_situacao"] is None:
            out[num_processo]["des_situacao"] = re.sub(r"^status:\s*", "", texto, flags=re.I).strip()

    logger.info("Página Decisões: %d processos com status/PDF", len(out))
    return out


# ─────────────────────────────────────────────────────────────
# 3. PDF do Relatório de Instrução — fundamentação resumida (heurística)
# ─────────────────────────────────────────────────────────────

_SECOES_CONCLUSAO = [
    r"da\s+conclus[aã]o", r"conclus[aã]o\b", r"do\s+dispositivo", r"dispositivo\b",
    r"da\s+decis[aã]o", r"decido\b",
]


def _extrair_fundamentacao(pdf_bytes: bytes) -> str | None:
    if b"%PDF" not in pdf_bytes[:16]:
        return None
    try:
        with pdfplumber.open(io.BytesIO(pdf_bytes)) as pdf:
            texto_completo = "\n".join(pg.extract_text() or "" for pg in pdf.pages)
    except Exception as e:
        logger.warning("Falha ao extrair texto do PDF: %s", e)
        return None

    if not texto_completo.strip():
        return None

    for padrao in _SECOES_CONCLUSAO:
        m = re.search(padrao, texto_completo, re.I)
        if m:
            trecho = texto_completo[m.start():m.start() + 4000]
            return re.sub(r"\s+", " ", trecho).strip()[:4000]

    # sem seção identificável — usa a cauda do documento (decisões costumam
    # ficar no fim de um Relatório de Instrução)
    return re.sub(r"\s+", " ", texto_completo[-3000:]).strip()


def _enriquecer_com_pdf(registros: list[dict], decisoes: dict[str, dict]) -> None:
    """Baixa e parseia o PDF de cada processo concluído com RI disponível.
    Muta `registros` in-place (fundamentacao, url_relatorio, des_situacao)."""
    for reg in registros:
        info = decisoes.get(reg["num_processo"])
        if not info:
            continue
        reg["des_situacao"] = info.get("des_situacao")
        reg["url_relatorio"] = info.get("url_relatorio")

        url = info.get("url_relatorio")
        if not url:
            continue
        try:
            time.sleep(REQUEST_DELAY)
            r = requests.get(url, headers=UA, timeout=60, allow_redirects=True)
            if not r.ok:
                logger.warning("PDF indisponível (%s) para %s", r.status_code, reg["num_processo"])
                continue
            reg["fundamentacao"] = _extrair_fundamentacao(r.content)
        except Exception as e:
            logger.warning("Erro ao baixar/parsear PDF de %s: %s", reg["num_processo"], e)


# ─────────────────────────────────────────────────────────────
# Orquestração
# ─────────────────────────────────────────────────────────────

def run() -> None:
    if not SUPABASE_URL or not SUPABASE_KEY:
        raise SystemExit("SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY ausentes")

    cnpjs_html = _scrape_fiscalizacao_cnpjs()
    registros = _parse_xlsx_pas(_baixar_xlsx(), cnpjs_html)
    if not registros:
        logger.warning("Nenhum processo extraído do XLSX — verificar estrutura da fonte")
        return

    decisoes = _scrape_decisoes()
    _enriquecer_com_pdf(registros, decisoes)

    _upsert(registros)
    logger.info("Seed ANPD concluído: %d processos", len(registros))


if __name__ == "__main__":
    run()
