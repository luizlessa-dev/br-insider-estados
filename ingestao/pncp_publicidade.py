"""
PNCP Publicidade Federal — The BR Insider
==========================================
Baixa contratos federais do PNCP cujo objeto menciona publicidade,
comunicação social, assessoria de imprensa ou propaganda.

Varredura por janela MENSAL para robustez: cada mês é uma unidade
atômica. Se a rede falhar no meio do mês, o mês é descartado e
re-tentado na próxima execução. Meses já concluídos são pulados
via arquivo de checkpoint.

Fonte: https://pncp.gov.br/api/consulta/v1/contratos
Sem autenticação. Paginação via ?pagina=N&tamanhoPagina=500.

Filtros client-side:
  - esferaId == 'F'  (federal)
  - objetoContrato contém keywords de publicidade

Saída:
  - Checkpoint em dados/pncp_checkpoint.json  (meses concluídos)
  - CSV mensal em dados/pncp_meses/AAAA-MM.csv
  - Upsert incremental no Supabase após cada mês

Uso:
  python3 ingestao/pncp_publicidade.py                        # 2021–hoje
  python3 ingestao/pncp_publicidade.py --ano 2024 2025        # anos específicos
  python3 ingestao/pncp_publicidade.py --mes 2024-06          # mês específico (force)
  python3 ingestao/pncp_publicidade.py --csv-only             # sem Supabase
  python3 ingestao/pncp_publicidade.py --status               # mostra cobertura atual
"""

from __future__ import annotations

import argparse
import calendar
import csv
import json
import logging
import os
import re
import sys
import time
from datetime import date, datetime
from pathlib import Path
from typing import Iterator

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger(__name__)

# ── Constantes ────────────────────────────────────────────────────────────────

PNCP_BASE     = "https://pncp.gov.br/api/consulta/v1"
PAGE_SIZE     = 500   # máximo aceito pelo PNCP
SLEEP_BETWEEN = 0.5   # segundos entre requisições
ANO_INICIAL   = 2023  # PNCP entrou em operação em 2023; anos anteriores retornam vazio

KEYWORDS = [
    "publicidade",
    "comunicação social",
    "comunicacao social",
    "assessoria de imprensa",
    "assessoria de comunicação",
    "assessoria de comunicacao",
    "propaganda institucional",
    "propaganda governamental",
    "serviços de comunicação",
    "servicos de comunicacao",
    "agência de publicidade",
    "agencia de publicidade",
    "mídia",
    "midia",
    "veiculação",
    "veiculacao",
    "divulgação institucional",
    "divulgacao institucional",
    "campanha publicitária",
    "campanha publicitaria",
    "press release",
    "monitoramento de mídia",
    "monitoramento de midia",
]

KEYWORDS_RE = re.compile(
    "|".join(re.escape(k) for k in KEYWORDS),
    re.IGNORECASE,
)

DADOS_DIR    = Path(__file__).parent.parent / "dados"
MESES_DIR    = DADOS_DIR / "pncp_meses"
CHECKPOINT   = DADOS_DIR / "pncp_checkpoint.json"

# ── HTTP ──────────────────────────────────────────────────────────────────────

def _session() -> requests.Session:
    s = requests.Session()
    retry = Retry(total=5, backoff_factor=3, status_forcelist=[429, 500, 502, 503])
    s.mount("https://", HTTPAdapter(max_retries=retry))
    s.headers.update({
        "Accept": "application/json",
        "User-Agent": "BR-Insider/1.0 (contato: luiz@thebrinsider.com)",
    })
    return s

SESSION = _session()

# ── Checkpoint ────────────────────────────────────────────────────────────────

def carregar_checkpoint() -> dict:
    """Retorna dict com chaves 'concluidos' (set de 'AAAA-MM') e 'stats'."""
    if CHECKPOINT.exists():
        data = json.loads(CHECKPOINT.read_text())
        data["concluidos"] = set(data.get("concluidos", []))
        return data
    return {"concluidos": set(), "stats": {}}

def salvar_checkpoint(cp: dict) -> None:
    cp_serial = {**cp, "concluidos": sorted(cp["concluidos"])}
    CHECKPOINT.write_text(json.dumps(cp_serial, indent=2, ensure_ascii=False))

def marcar_concluido(cp: dict, mes_key: str, n_pub: int, n_total: int, valor: float) -> None:
    cp["concluidos"].add(mes_key)
    cp["stats"][mes_key] = {
        "n_publicidade": n_pub,
        "n_varridos": n_total,
        "valor_total": valor,
        "concluido_em": datetime.now().isoformat(timespec="seconds"),
    }
    salvar_checkpoint(cp)

# ── Janelas mensais ───────────────────────────────────────────────────────────

def janelas_mes(anos: list[int]) -> list[tuple[str, str, str]]:
    """
    Retorna lista de (mes_key, data_ini, data_fim) para todos os meses
    dos anos solicitados, até o mês atual inclusive.
    Formato: mes_key='AAAA-MM', datas='AAAAMMDD'.
    """
    hoje = date.today()
    resultado = []
    for ano in sorted(anos):
        for mes in range(1, 13):
            if date(ano, mes, 1) > hoje:
                break
            ultimo_dia = calendar.monthrange(ano, mes)[1]
            fim = date(ano, mes, ultimo_dia)
            if fim > hoje:
                fim = hoje
            mes_key  = f"{ano}-{mes:02d}"
            data_ini = f"{ano}{mes:02d}01"
            data_fim = f"{fim.year}{fim.month:02d}{fim.day:02d}"
            resultado.append((mes_key, data_ini, data_fim))
    return resultado

# ── Coleta PNCP ───────────────────────────────────────────────────────────────

def _fetch_page(data_ini: str, data_fim: str, pagina: int) -> dict:
    url = f"{PNCP_BASE}/contratos"
    params = {
        "dataInicial":   data_ini,
        "dataFinal":     data_fim,
        "pagina":        pagina,
        "tamanhoPagina": PAGE_SIZE,
    }
    resp = SESSION.get(url, params=params, timeout=90)
    resp.raise_for_status()
    return resp.json()


def iter_contratos_mes(data_ini: str, data_fim: str, mes_key: str) -> Iterator[dict]:
    """Itera sobre todos os contratos do mês, página por página."""
    pagina = 1
    total_paginas = None

    while True:
        try:
            data = _fetch_page(data_ini, data_fim, pagina)
        except requests.HTTPError as exc:
            log.error("[%s] Erro HTTP pág %d: %s", mes_key, pagina, exc)
            raise
        except Exception as exc:
            log.error("[%s] Erro pág %d: %s", mes_key, pagina, exc)
            raise

        items = data.get("data", [])
        if not items:
            break

        if total_paginas is None:
            total_paginas = data.get("totalPaginas", 1)
            total_reg     = data.get("totalRegistros", 0)
            log.info("[%s] %d contratos em %d páginas", mes_key, total_reg, total_paginas)

        yield from items

        if pagina >= total_paginas:
            break
        pagina += 1
        time.sleep(SLEEP_BETWEEN)


def is_publicidade(contrato: dict) -> bool:
    objeto = (contrato.get("objetoContrato") or "").lower()
    return bool(KEYWORDS_RE.search(objeto))


def is_federal(contrato: dict) -> bool:
    orgao = contrato.get("orgaoEntidade") or {}
    return orgao.get("esferaId") == "F"


# ── Normalização ──────────────────────────────────────────────────────────────

def normalizar(c: dict) -> dict:
    orgao  = c.get("orgaoEntidade") or {}
    unidad = c.get("unidadeOrgao")  or {}
    return {
        "numero_controle_pncp": c.get("numeroControlePNCP", ""),
        "ano_contrato":         c.get("anoContrato"),
        "data_assinatura":      c.get("dataAssinatura", ""),
        "data_publicacao_pncp": c.get("dataPublicacaoPncp", ""),
        "data_vigencia_inicio": c.get("dataVigenciaInicio", ""),
        "data_vigencia_fim":    c.get("dataVigenciaFim", ""),
        "valor_inicial":        c.get("valorInicial") or 0,
        "valor_global":         c.get("valorGlobal")  or 0,
        "objeto_contrato":      (c.get("objetoContrato") or "")[:500],
        "numero_contrato":      c.get("numeroContratoEmpenho", ""),
        "modalidade":           (c.get("tipoContrato") or {}).get("nome", ""),
        "cnpj_fornecedor":      c.get("niFornecedor", ""),
        "nome_fornecedor":      (c.get("nomeRazaoSocialFornecedor") or "")[:200],
        "cnpj_orgao":           orgao.get("cnpj", ""),
        "nome_orgao":           orgao.get("razaoSocial", "")[:200],
        "esfera_orgao":         orgao.get("esferaId", ""),
        "poder_orgao":          orgao.get("poderId", ""),
        "uf_orgao":             unidad.get("ufSigla", ""),
        "municipio_orgao":      unidad.get("municipioNome", ""),
        "nome_unidade":         unidad.get("nomeUnidade", "")[:200],
        "url_pncp": (
            f"https://pncp.gov.br/app/contratos"
            f"/{c.get('anoContrato','')}/"
            f"{c.get('sequencialContrato','')}"
        ),
        "coletado_em": datetime.now(datetime.UTC if hasattr(datetime, 'UTC') else None).isoformat()
                       if False else datetime.utcnow().isoformat(),
    }


# ── CSV ───────────────────────────────────────────────────────────────────────

CAMPOS_CSV = [
    "numero_controle_pncp", "ano_contrato", "data_assinatura",
    "data_publicacao_pncp", "data_vigencia_inicio", "data_vigencia_fim",
    "valor_inicial", "valor_global", "objeto_contrato", "numero_contrato",
    "modalidade", "cnpj_fornecedor", "nome_fornecedor",
    "cnpj_orgao", "nome_orgao", "esfera_orgao", "poder_orgao",
    "uf_orgao", "municipio_orgao", "nome_unidade", "url_pncp", "coletado_em",
]


def salvar_csv_mes(registros: list[dict], mes_key: str) -> Path:
    MESES_DIR.mkdir(parents=True, exist_ok=True)
    path = MESES_DIR / f"{mes_key}.csv"
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=CAMPOS_CSV, extrasaction="ignore")
        w.writeheader()
        w.writerows(registros)
    return path


# ── Supabase ──────────────────────────────────────────────────────────────────

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SUPABASE_KEY = (
    os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    or os.environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY")
    or ""
)
CHUNK = 500


def upsert_supabase(registros: list[dict]) -> bool:
    if not SUPABASE_URL or not SUPABASE_KEY:
        log.warning("Supabase não configurado — pulando upsert.")
        return False

    headers = {
        "apikey":        SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type":  "application/json",
        "Prefer":        "resolution=merge-duplicates",
    }
    url = f"{SUPABASE_URL}/rest/v1/pncp_publicidade"

    total = 0
    for i in range(0, len(registros), CHUNK):
        chunk = registros[i:i + CHUNK]
        try:
            resp = SESSION.post(url, headers=headers, json=chunk, timeout=60)
            if resp.status_code not in (200, 201):
                log.error("Supabase erro chunk %d: %s %s", i, resp.status_code, resp.text[:200])
                return False
            total += len(chunk)
        except Exception as exc:
            log.error("Supabase falhou no chunk %d: %s", i, exc)
            return False

    log.info("Upsert: %d registros enviados", total)
    return True


# ── Processamento mensal ──────────────────────────────────────────────────────

def processar_mes(
    mes_key: str,
    data_ini: str,
    data_fim: str,
    csv_only: bool = False,
    force: bool = False,
) -> tuple[list[dict], bool]:
    """
    Processa um mês. Retorna (registros, sucesso).
    sucesso=False se houve erro de rede — mês não é marcado como concluído.
    """
    registros = []
    total_varridos = 0
    erro_rede = False

    try:
        for contrato in iter_contratos_mes(data_ini, data_fim, mes_key):
            total_varridos += 1
            if is_federal(contrato) and is_publicidade(contrato):
                registros.append(normalizar(contrato))
    except Exception:
        erro_rede = True

    log.info(
        "[%s] Concluído: %d varridos, %d publicidade%s",
        mes_key, total_varridos, len(registros),
        " (ERRO DE REDE — mês não marcado)" if erro_rede else "",
    )

    if registros:
        path = salvar_csv_mes(registros, mes_key)
        log.info("[%s] CSV: %s", mes_key, path)
        if not csv_only:
            ok = upsert_supabase(registros)
            if not ok:
                log.warning("[%s] Upsert falhou — dados no CSV, re-tentaremos no próximo run", mes_key)

    return registros, not erro_rede


# ── Status ────────────────────────────────────────────────────────────────────

def mostrar_status(cp: dict, anos: list[int]) -> None:
    janelas = janelas_mes(anos)
    total_meses = len(janelas)
    concluidos  = len(cp["concluidos"])
    pendentes   = [m for m, _, _ in janelas if m not in cp["concluidos"]]

    total_pub   = sum(s.get("n_publicidade", 0) for s in cp["stats"].values())
    total_var   = sum(s.get("n_varridos", 0) for s in cp["stats"].values())
    total_val   = sum(s.get("valor_total", 0) for s in cp["stats"].values())

    print(f"\n{'='*55}")
    print(f"  PNCP Publicidade — cobertura atual")
    print(f"{'='*55}")
    print(f"  Meses concluídos:  {concluidos}/{total_meses}")
    print(f"  Contratos varridos: {total_var:,}")
    print(f"  Hits publicidade:   {total_pub:,}")
    print(f"  Valor total:        R$ {total_val:,.2f}")
    if pendentes:
        print(f"\n  Pendentes ({len(pendentes)}): {', '.join(pendentes[:12])}")
        if len(pendentes) > 12:
            print(f"  ... e mais {len(pendentes)-12} meses")
    else:
        print("\n  Base completa!")
    print()


# ── Principal ─────────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(
        description="PNCP — contratos de publicidade federal (varredura mensal)"
    )
    parser.add_argument(
        "--ano", type=int, nargs="+",
        default=list(range(ANO_INICIAL, date.today().year + 1)),
        help=f"Anos a processar (padrão: {ANO_INICIAL}–hoje)",
    )
    parser.add_argument(
        "--mes", type=str,
        help="Forçar reprocessamento de um mês específico (ex: 2024-06)",
    )
    parser.add_argument(
        "--csv-only", action="store_true",
        help="Não enviar ao Supabase",
    )
    parser.add_argument(
        "--force", action="store_true",
        help="Reprocessar mesmo meses já marcados como concluídos",
    )
    parser.add_argument(
        "--status", action="store_true",
        help="Mostrar cobertura atual e sair",
    )
    args = parser.parse_args()

    DADOS_DIR.mkdir(parents=True, exist_ok=True)
    cp = carregar_checkpoint()

    if args.status:
        mostrar_status(cp, args.ano)
        return

    # Modo mês único (--mes 2024-06)
    if args.mes:
        try:
            ano, mes = map(int, args.mes.split("-"))
        except ValueError:
            log.error("Formato inválido para --mes. Use AAAA-MM (ex: 2024-06)")
            sys.exit(1)
        ultimo_dia = calendar.monthrange(ano, mes)[1]
        data_ini = f"{ano}{mes:02d}01"
        data_fim = f"{ano}{mes:02d}{ultimo_dia:02d}"
        regs, ok = processar_mes(args.mes, data_ini, data_fim, args.csv_only, force=True)
        if ok:
            valor = sum(float(r["valor_global"] or 0) for r in regs)
            marcar_concluido(cp, args.mes, len(regs), 0, valor)
        return

    janelas = janelas_mes(args.ano)
    total   = len(janelas)
    feitos  = 0
    pulados = 0
    erros   = 0
    todos_registros = []

    for i, (mes_key, data_ini, data_fim) in enumerate(janelas, 1):
        if mes_key in cp["concluidos"] and not args.force:
            pulados += 1
            log.debug("[%s] Pulado (já concluído)", mes_key)
            continue

        log.info("── [%d/%d] %s ──────────────────────────────", i, total, mes_key)
        regs, ok = processar_mes(mes_key, data_ini, data_fim, args.csv_only)
        todos_registros.extend(regs)

        if ok:
            valor = sum(float(r["valor_global"] or 0) for r in regs)
            marcar_concluido(cp, mes_key, len(regs), 0, valor)
            feitos += 1
        else:
            erros += 1
            log.warning("[%s] Falhou — será re-tentado no próximo run", mes_key)

        # Pausa entre meses para não sobrecarregar o PNCP
        time.sleep(1.0)

    print(f"\n{'='*55}")
    print(f"  Resultado da execução")
    print(f"{'='*55}")
    print(f"  Meses processados:  {feitos}")
    print(f"  Meses pulados:      {pulados} (já concluídos)")
    print(f"  Erros de rede:      {erros} (serão re-tentados)")
    print(f"  Contratos novos:    {len(todos_registros)}")
    if todos_registros:
        valor_total = sum(float(r["valor_global"] or 0) for r in todos_registros)
        print(f"  Valor total:        R$ {valor_total:,.2f}")
    print()
    mostrar_status(cp, args.ano)


if __name__ == "__main__":
    main()
