"""
Cruzamento: doadores campanha Tarcísio 2022 × contratos/concessões governo SP 2023-2026

Fontes consultadas:
  1. PNCP (Portal Nacional de Contratações Públicas) — API pública, sem autenticação
     Endpoint: https://pncp.gov.br/api/pncp/v1/contratos
     Filtro: orgaoEntidade.cnpj começa com "45.773.675" (CNPJ raiz do governo SP)
             ou ufOrgao = "SP" + esferaId = "E" (estadual)

  2. Banco de dados interno BR Insider (Supabase)
     Tabelas: contratos_federais, emendas_favorecidos
     (para identificar vínculos federais do mesmo doador)

  3. TSE DivulgaCandContas (API)
     Para confirmar CPF→doação quando o CPF não está disponível publicamente.

Uso:
    python -m dossie.tarcisio.cruzamento_contratos_sp

    # ou com filtro de CNPJ específico:
    python -m dossie.tarcisio.cruzamento_contratos_sp --cnpj 50746577000115

    # exportar CSV:
    python -m dossie.tarcisio.cruzamento_contratos_sp --output resultados.csv
"""

from __future__ import annotations

import argparse
import csv
import json
import logging
import sys
import time
from datetime import date
from typing import Optional

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

from .doadores_cnpjs import DOADORES_PF, cnpjs_para_cruzamento

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
log = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Configurações
# ---------------------------------------------------------------------------

PNCP_BASE = "https://pncp.gov.br/api/pncp/v1"
TSE_BASE  = "https://divulgacandcontas.tse.jus.br/divulga/rest/v1"

# CNPJ raiz do governo do estado de SP (Fazenda/SEFAZ e Palácio do Governo)
# Confirmar via https://www.cnpj.biz — pode haver variações por secretaria
GOVERNO_SP_CNPJ_RAIZ = "45773675"  # CNPJ raiz sem formatação

# Secretarias com maior chance de contratos relevantes
SECRETARIAS_SP_CNPJ = [
    ("45.773.675/0001-00", "Governo do Estado de SP (sede)"),
    # adicionar CNPJs de secretarias conforme identificados
    # ("XX.XXX.XXX/XXXX-XX", "Secretaria de Infraestrutura e Meio Ambiente"),
    # ("XX.XXX.XXX/XXXX-XX", "Secretaria de Desenvolvimento Econômico"),
]

ANO_INICIO = 2023
ANO_FIM    = 2026


# ---------------------------------------------------------------------------
# Cliente HTTP com retry
# ---------------------------------------------------------------------------

def build_session() -> requests.Session:
    s = requests.Session()
    retry = Retry(total=4, backoff_factor=1.5, status_forcelist=[429, 500, 502, 503])
    s.mount("https://", HTTPAdapter(max_retries=retry))
    s.headers.update({"Accept": "application/json", "User-Agent": "BR-Insider/1.0"})
    return s


SESSION = build_session()


# ---------------------------------------------------------------------------
# 1. Busca no PNCP por CNPJ do fornecedor (lado do contratado)
# ---------------------------------------------------------------------------

def buscar_contratos_pncp_por_cnpj(cnpj: str, ano: int) -> list[dict]:
    """
    Busca contratos no PNCP onde o fornecedor tem esse CNPJ.
    Filtra por ano de publicação.

    PNCP endpoint: GET /contratos
    Params relevantes:
        dataInicial, dataFinal, cnpjFornecedor, pagina, tamanhoPagina
    """
    contratos = []
    pagina = 1
    data_ini = f"{ano}-01-01"
    data_fim = f"{ano}-12-31"

    while True:
        params = {
            "dataInicial": data_ini,
            "dataFinal":   data_fim,
            "cnpjFornecedor": cnpj,
            "pagina":      pagina,
            "tamanhoPagina": 50,
        }
        try:
            resp = SESSION.get(f"{PNCP_BASE}/contratos", params=params, timeout=30)
            if resp.status_code == 404:
                break
            resp.raise_for_status()
            data = resp.json()
        except Exception as exc:
            log.warning("PNCP erro cnpj=%s ano=%d pag=%d: %s", cnpj, ano, pagina, exc)
            break

        items = data if isinstance(data, list) else data.get("data", [])
        if not items:
            break
        contratos.extend(items)

        total = data.get("totalRegistros", 0) if isinstance(data, dict) else len(items)
        if pagina * 50 >= total or not isinstance(data, dict):
            break
        pagina += 1
        time.sleep(0.3)  # respeitar rate limit PNCP

    return contratos


def filtrar_contratos_sp(contratos: list[dict]) -> list[dict]:
    """
    Filtra contratos cujo órgão contratante é o governo de SP (estadual).
    Critérios: ufOrgao == 'SP' e esferaId == 'E' (estadual)
    """
    resultado = []
    for c in contratos:
        orgao = c.get("orgaoEntidade", {}) or {}
        uf    = orgao.get("ufNome", "") or c.get("ufOrgao", "") or ""
        esfera = c.get("esferaId", "") or orgao.get("esferaId", "") or ""
        if uf.upper() in ("SP", "SÃO PAULO") and esfera.upper() == "E":
            resultado.append(c)
    return resultado


# ---------------------------------------------------------------------------
# 2. Busca alternativa: API de contratações SP direto
#    (SP tem portal próprio em transparencia.sp.gov.br/licitacoes)
#    Endpoint JSON não documentado publicamente — tentativa heurística
# ---------------------------------------------------------------------------

SP_TRANSPARENCIA_BASE = "https://www.transparencia.sp.gov.br/PortalTransparencia/OpenData"

def buscar_contratos_sp_portal(cnpj: str) -> list[dict]:
    """
    Tenta buscar contratos no portal de transparência SP por CNPJ do fornecedor.
    Este endpoint não tem documentação pública; retorna vazio se indisponível.
    """
    cnpj_limpo = cnpj.replace(".", "").replace("/", "").replace("-", "")
    url = f"{SP_TRANSPARENCIA_BASE}/contrato?cnpj={cnpj_limpo}&formato=json"
    try:
        resp = SESSION.get(url, timeout=15)
        if resp.status_code != 200:
            return []
        return resp.json() if isinstance(resp.json(), list) else []
    except Exception:
        return []


# ---------------------------------------------------------------------------
# 3. Verificar doações TSE por nome (quando CPF não disponível)
# ---------------------------------------------------------------------------

def buscar_doacoes_tse_por_nome(nome: str, ano_eleicao: int = 2022) -> list[dict]:
    """
    Consulta TSE DivulgaCandContas por fragmento de nome do doador.
    Endpoint: /candidatura/listar/{ano}/RS/governador/doadores?nomeDoador={nome}
    Nota: o endpoint real varia — adaptação necessária conforme API TSE atual.
    """
    url = (
        f"{TSE_BASE}/candidatura/listar/{ano_eleicao}/SP/governor/doadores"
        f"?nomeDoador={requests.utils.quote(nome)}"
    )
    try:
        resp = SESSION.get(url, timeout=20)
        if resp.status_code != 200:
            return []
        return resp.json().get("candidaturas", [])
    except Exception:
        return []


# ---------------------------------------------------------------------------
# 4. Cruzamento principal
# ---------------------------------------------------------------------------

def formatar_contrato(c: dict, doador_info: dict) -> dict:
    """Normaliza campos do contrato PNCP para output."""
    orgao = c.get("orgaoEntidade", {}) or {}
    return {
        # identificação do doador
        "doador_nome":        doador_info["doador_nome"],
        "doador_valor":       doador_info["doador_valor"],
        "doador_status":      doador_info["doador_status"],
        "doador_operacao":    doador_info["doador_operacao"],
        # empresa
        "empresa_cnpj":       doador_info["cnpj_fmt"],
        "empresa_nome":       doador_info["razao_social"],
        "empresa_setor":      doador_info["setor"],
        # contrato
        "contrato_numero":    c.get("numero") or c.get("numeroContratoEmpenho", ""),
        "contrato_objeto":    c.get("objetoContrato", "")[:200],
        "contrato_valor":     c.get("valorInicial", 0),
        "contrato_inicio":    c.get("dataVigenciaInicio", ""),
        "contrato_fim":       c.get("dataVigenciaFim", ""),
        "contrato_modalidade":c.get("modalidadeNome", ""),
        # órgão contratante
        "orgao_nome":         orgao.get("razaoSocial", ""),
        "orgao_cnpj":         orgao.get("cnpj", ""),
        "orgao_uf":           orgao.get("ufNome", ""),
        "orgao_esfera":       c.get("esferaId", ""),
        # link
        "pncp_url": (
            f"https://pncp.gov.br/app/contratos/{c.get('anoContratacao', '')}"
            f"/{c.get('sequencialContrato', '')}"
        ),
        "notas": doador_info["notas"],
    }


def executar_cruzamento(
    cnpj_filtro: Optional[str] = None,
    verbose: bool = True,
) -> list[dict]:
    """
    Para cada CNPJ da lista de doadores:
      1. Busca contratos no PNCP por ano (2023-2026)
      2. Filtra contratos do governo SP (esfera estadual)
      3. Retorna lista de hits com contexto do doador
    """
    candidatos = cnpjs_para_cruzamento()
    if cnpj_filtro:
        cnpj_filtro_limpo = cnpj_filtro.replace(".", "").replace("/", "").replace("-", "")
        candidatos = [c for c in candidatos if c["cnpj"] == cnpj_filtro_limpo]

    resultados = []

    for info in candidatos:
        cnpj = info["cnpj"]
        if not cnpj:
            continue

        log.info("Buscando PNCP: %s (%s)", info["cnpj_fmt"], info["razao_social"])

        hits_pncp = []
        for ano in range(ANO_INICIO, ANO_FIM + 1):
            contratos_ano = buscar_contratos_pncp_por_cnpj(cnpj, ano)
            sp_contratos  = filtrar_contratos_sp(contratos_ano)
            if sp_contratos and verbose:
                log.info(
                    "  ✓ %d contratos SP em %d — %s",
                    len(sp_contratos), ano, info["razao_social"],
                )
            hits_pncp.extend(sp_contratos)

        # portal SP como fallback
        if not hits_pncp:
            hits_portal = buscar_contratos_sp_portal(cnpj)
            if hits_portal and verbose:
                log.info("  ✓ %d contratos no portal SP — %s", len(hits_portal), info["razao_social"])
            # normalização simplificada para hits do portal SP
            for c in hits_portal:
                resultados.append({**info, "fonte": "portal_sp", "raw": c})

        for c in hits_pncp:
            resultados.append(formatar_contrato(c, info))

    return resultados


# ---------------------------------------------------------------------------
# 5. Output
# ---------------------------------------------------------------------------

def imprimir_resultado(resultados: list[dict]) -> None:
    if not resultados:
        print("\n[SEM HITS] Nenhum contrato SP encontrado para os CNPJs listados.")
        print("Próximos passos:")
        print("  1. Confirmar CNPJs com needs_verification=True na Receita Federal")
        print("  2. Verificar portal transparencia.sp.gov.br manualmente")
        print("  3. Cruzar com base interna BR Insider (contratos_federais)")
        return

    print(f"\n{'='*70}")
    print(f"HITS: {len(resultados)} contrato(s) encontrado(s)")
    print(f"{'='*70}")
    for r in resultados:
        print(f"\nDoador:    {r.get('doador_nome')} | R$ {r.get('doador_valor'):,.0f} | {r.get('doador_status')}")
        print(f"Empresa:   {r.get('empresa_nome')} ({r.get('empresa_cnpj')})")
        print(f"Contrato:  {r.get('contrato_numero')} — {r.get('contrato_objeto')}")
        print(f"Valor:     R$ {r.get('contrato_valor', 0):,.2f}")
        print(f"Vigência:  {r.get('contrato_inicio')} → {r.get('contrato_fim')}")
        print(f"Órgão SP:  {r.get('orgao_nome')}")
        print(f"PNCP:      {r.get('pncp_url')}")
        if r.get("notas"):
            print(f"Nota:      {r.get('notas')[:100]}")


def exportar_csv(resultados: list[dict], path: str) -> None:
    if not resultados:
        print(f"Nenhum resultado para exportar em {path}.")
        return
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(resultados[0].keys()))
        writer.writeheader()
        writer.writerows(resultados)
    print(f"Exportado: {path} ({len(resultados)} linhas)")


# ---------------------------------------------------------------------------
# 6. Relatório complementar: CNPJs ainda sem verificação
# ---------------------------------------------------------------------------

def listar_pendencias() -> None:
    """Imprime CNPJs que ainda precisam de verificação manual na RFB."""
    print("\n=== CNPJs PENDENTES DE VERIFICAÇÃO (RFB/Junta Comercial) ===")
    for doador in DOADORES_PF:
        for emp in doador.empresas:
            if emp.needs_verification or not emp.cnpj:
                status = "SEM CNPJ" if not emp.cnpj else f"CNPJ A CONFIRMAR: {emp.cnpj}"
                print(f"  {doador.nome} → {emp.razao_social} [{status}]")
                if emp.notas:
                    print(f"    {emp.notas[:120]}")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(description="Cruzamento doadores Tarcísio × contratos SP")
    parser.add_argument("--cnpj",    help="Filtrar por CNPJ específico (sem formatação)")
    parser.add_argument("--output",  help="Exportar resultados em CSV (ex: resultados.csv)")
    parser.add_argument("--pendencias", action="store_true",
                        help="Listar CNPJs ainda sem verificação e sair")
    args = parser.parse_args()

    if args.pendencias:
        listar_pendencias()
        return

    print(f"Iniciando cruzamento — {date.today()}")
    print(f"CNPJs a checar: {len([c for c in cnpjs_para_cruzamento() if c['cnpj']])}")
    print(f"Período: {ANO_INICIO}–{ANO_FIM}\n")

    resultados = executar_cruzamento(cnpj_filtro=args.cnpj)

    imprimir_resultado(resultados)

    if args.output:
        exportar_csv(resultados, args.output)


if __name__ == "__main__":
    main()
