"""
Ingestão TSE formato legado (2014 e 2016).
Esses anos usam ZIPs com arquivos por UF no formato antigo.

URLs:
  2014: prestacao_final_2014.zip
  2016: prestacao_contas_final_2016.zip

⚠️  As funções `ingerir`/`ingerir_receitas` deste módulo (delete-before-load)
NÃO são mais o caminho usado por `python -m ingestao.tse.runner` — desde
2026-08-24, receitas/despesas de 2014/2016 passam pelo pipeline seguro
(staging + swap atômico) via `legacy_source.LegacyZipSource`, que reaproveita
só os parsers deste arquivo (`iter_receitas_legado`/`iter_despesas_legado`),
não a orquestração de escrita. Rodar este módulo direto (CLI abaixo) continua
funcionando como escape-hatch manual, mas é o mesmo caminho destrutivo que
causou o incidente de 2026-06-20 — exige aprovação explícita separada antes de
usar contra produção.

Uso (manual, só com aprovação):
  python -m ingestao.tse.ingest_legado --ano 2014 --zip /tmp/tse_2014.zip
  python -m ingestao.tse.ingest_legado --ano 2016 --zip /tmp/tse_2016.zip
"""
from __future__ import annotations

import argparse
import csv
import io
import logging
import os
import re
import zipfile

import time

import requests
from supabase import create_client

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("tse.legado")

def _sb_credentials() -> tuple[str, str]:
    """Lida sob demanda (não no import do módulo) — os parsers puros
    (iter_receitas_legado/iter_despesas_legado, reaproveitados por
    legacy_source.py) não precisam de credencial nenhuma pra funcionar."""
    url = os.environ["SUPABASE_URL"]
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY") or os.environ["INTERNAL_SUPABASE_SERVICE_ROLE_KEY"]
    return url, key

ZIP_URLS = {
    2014: "https://cdn.tse.jus.br/estatistica/sead/odsele/prestacao_contas/prestacao_final_2014.zip",
    2016: "https://cdn.tse.jus.br/estatistica/sead/odsele/prestacao_contas/prestacao_contas_final_2016.zip",
}

# Cargos alvo (igual ao conector moderno)
CARGOS_GERAIS  = {"presidente", "governador", "senador", "deputado federal", "deputado estadual", "deputado distrital"}
CARGOS_MUNIC   = {"prefeito", "vereador"}
CARGOS_ALVO    = CARGOS_GERAIS | CARGOS_MUNIC

CHUNK = 500

# Mapeamento de colunas 2014
COL_2014 = {
    "cpf_candidato":      10,
    "nome_candidato":      9,
    "cargo":               8,
    "sigla_partido":       6,
    "uf":                  5,
    "cpf_cnpj_fornecedor": 13,
    "nome_fornecedor":     14,
    "tipo_despesa":        20,
    "descricao_despesa":   21,
    "valor_despesa":       19,
    "numero_documento":    12,
    "data_despesa":        18,
}

# Mapeamento de colunas 2016 (colunas diferentes de 2014)
COL_2016 = {
    "cpf_candidato":      12,
    "nome_candidato":     11,
    "cargo":              10,
    "sigla_partido":       8,
    "uf":                  5,
    "cpf_cnpj_fornecedor": 16,
    "nome_fornecedor":    17,
    "tipo_despesa":       23,
    "descricao_despesa":  24,
    "valor_despesa":      22,
    "numero_documento":   15,
    "data_despesa":       21,
}


def _parse_valor(v: str) -> float:
    """'1.234,56' → 1234.56"""
    v = v.strip().strip('"')
    v = v.replace(".", "").replace(",", ".")
    try:
        return float(v)
    except ValueError:
        return 0.0


def _strip(v: str) -> str:
    return v.strip().strip('"')


# Sentinela literal do TSE pra "não informado" nos arquivos de 2014/2016 (achado
# validando contra ZIP real de 2014, 2026-08-24): aparece SEMPRE como o valor
# INTEIRO do campo (nunca substring de um nome real), em ~1,8 ocorrência por
# linha nos campos de texto livre. Sem essa normalização, a string literal
# "#NULO" ia pro banco em vez de NULL.
_SENTINELS = {"#NULO"}


def _limpo(v: str) -> str | None:
    """_strip() + normaliza sentinela do TSE (#NULO) pra None. Só usar na
    construção do dict de SAÍDA — nunca no filtro de cargo (que precisa de
    string, não None, pra comparar contra CARGOS_ALVO)."""
    s = _strip(v)
    if not s or s.upper() in _SENTINELS:
        return None
    return s


def _doc(v: str) -> str | None:
    """Normaliza CPF/CNPJ: dígitos apenas; None pra sentinela negativo do TSE
    (-1/-3/-4 = não divulgável) ou comprimento < 11. Evita que '-4' vire '4' e
    colapse todos os CPFs não-divulgados num supergrupo falso ao agregar."""
    s = _strip(v)
    if not s or s.startswith("-"):
        return None
    d = re.sub(r"\D", "", s)
    return d if len(d) >= 11 else None


def _parse_data(v: str) -> str | None:
    """'25/10/2014' → '2014-10-25'"""
    v = _strip(v)
    if not v:
        return None
    # formato DD/MM/YYYY
    m = re.match(r"(\d{2})/(\d{2})/(\d{4})", v)
    if m:
        return f"{m.group(3)}-{m.group(2)}-{m.group(1)}"
    return None


def iter_despesas_legado(zip_path: str, ano: int, ufs: list | None = None):
    col = COL_2014 if ano == 2014 else COL_2016
    if ano == 2014:
        pat = re.compile(rf"despesas_candidatos_{ano}_[A-Z]{{2}}\.txt", re.IGNORECASE)
    else:
        pat = re.compile(rf"despesas_candidatos_.*{ano}_[A-Z]{{2}}\.txt", re.IGNORECASE)

    with zipfile.ZipFile(zip_path) as z:
        arquivos = [n for n in z.namelist() if pat.match(n)]
        log.info("%d arquivos de despesas encontrados", len(arquivos))

        for nome in sorted(arquivos):
            uf_match = re.search(r"_([A-Z]{2})\.txt$", nome, re.IGNORECASE)
            uf_arquivo = uf_match.group(1).upper() if uf_match else "??"
            if uf_arquivo == "BR":
                continue  # arquivo Brasil é consolidado, evitar duplicata
            if ufs and uf_arquivo not in ufs:
                continue

            log.info("Processando %s", nome)
            with z.open(nome) as f:
                reader = csv.reader(
                    io.TextIOWrapper(f, encoding="latin-1"),
                    delimiter=";",
                    quotechar='"',
                )
                next(reader)  # pular header

                for row in reader:
                    if len(row) < max(col.values()) + 1:
                        continue
                    cargo = _strip(row[col["cargo"]]).lower()
                    if cargo not in CARGOS_ALVO:
                        continue

                    cpf = _doc(row[col["cpf_candidato"]])
                    cnpj = _doc(row[col["cpf_cnpj_fornecedor"]])

                    yield {
                        "ano_eleicao":        ano,
                        "numero_documento":   _limpo(row[col["numero_documento"]]),
                        "cpf_candidato":      cpf or None,
                        "nome_candidato":     _limpo(row[col["nome_candidato"]]),
                        "cargo":              _limpo(row[col["cargo"]]),
                        "sigla_partido":      _limpo(row[col["sigla_partido"]]),
                        "uf":                 _limpo(row[col["uf"]]),
                        "cpf_cnpj_fornecedor": cnpj or None,
                        "nome_fornecedor":    _limpo(row[col["nome_fornecedor"]]),
                        "tipo_despesa":       _limpo(row[col["tipo_despesa"]]),
                        "descricao_despesa":  _limpo(row[col["descricao_despesa"]]),
                        "origem_despesa":     None,
                        "especie_recurso":    None,
                        "fonte_recurso":      None,
                        "valor_despesa":      _parse_valor(row[col["valor_despesa"]]),
                        "valor_prestado":     None,
                        "data_despesa":       _parse_data(row[col["data_despesa"]]),
                    }


# ─── Receitas legado (2014 / 2016) ────────────────────────────────────────────

# Mapeamento: nome_campo → índice de coluna no CSV
COL_RECEITAS_2014 = {
    "uf": 5, "sigla_partido": 6, "cargo": 8, "nome_candidato": 9,
    "cpf_candidato": 10, "numero_recibo": 11,
    "cpf_cnpj_doador": 13, "nome_doador_rfb": 15,
    "setor_economico_doador": 20, "data_receita": 21, "valor": 22,
    "tipo_doador": 23, "fonte_recurso": 24, "especie_recurso": 25,
    "descricao": 26,
    "cpf_cnpj_doador_originario": 27, "nome_doador_originario_rfb": 31,
}

COL_RECEITAS_2016 = {
    "uf": 5, "sigla_partido": 8, "cargo": 10, "nome_candidato": 11,
    "cpf_candidato": 12, "numero_recibo": 14,
    "cpf_cnpj_doador": 16, "nome_doador_rfb": 18,
    "setor_economico_doador": 23, "data_receita": 24, "valor": 25,
    "tipo_doador": 26, "fonte_recurso": 27, "especie_recurso": 28,
    "descricao": 29,
    "cpf_cnpj_doador_originario": 30, "nome_doador_originario_rfb": 34,
}


def iter_receitas_legado(zip_path: str, ano: int, ufs: list | None = None):
    col = COL_RECEITAS_2014 if ano == 2014 else COL_RECEITAS_2016
    if ano == 2014:
        pat = re.compile(r"receitas_candidatos_2014_[A-Z]{2}\.txt", re.IGNORECASE)
    else:
        pat = re.compile(r"receitas_candidatos_.*2016_[A-Z]{2}\.txt", re.IGNORECASE)

    with zipfile.ZipFile(zip_path) as z:
        arquivos = [n for n in z.namelist() if pat.match(n)]
        log.info("%d arquivos de receitas encontrados", len(arquivos))

        for nome in sorted(arquivos):
            uf_match = re.search(r"_([A-Z]{2})\.txt$", nome, re.IGNORECASE)
            uf_arquivo = uf_match.group(1).upper() if uf_match else "??"
            if uf_arquivo == "BR":
                continue
            if ufs and uf_arquivo not in ufs:
                continue

            log.info("Receitas legado %d — %s", ano, uf_arquivo)
            with z.open(nome) as f:
                reader = csv.reader(
                    io.TextIOWrapper(f, encoding="latin-1"),
                    delimiter=";",
                    quotechar='"',
                )
                next(reader)  # pular header

                for row in reader:
                    if len(row) < max(col.values()) + 1:
                        continue
                    cargo = _strip(row[col["cargo"]]).lower()
                    if cargo not in CARGOS_ALVO:
                        continue

                    valor_str = _strip(row[col["valor"]])
                    try:
                        valor = _parse_valor(valor_str)
                    except Exception:
                        continue
                    if not valor:
                        continue

                    # "Tipo receita" do TSE (col tipo_doador) é uma classificação de
                    # ORIGEM do recurso (ex.: "Recursos de partido político", "Doação
                    # de pessoa física") — não é PF/PJ do doador. O connector.py
                    # moderno alimenta tipo_doador E origem_receita a partir do mesmo
                    # campo de origem (DS_ORIGEM_RECEITA); espelhado aqui pra manter
                    # os dois campos preenchidos igual aos anos modernos, em vez de
                    # deixar origem_receita sempre None só pra 2014/2016.
                    origem = _limpo(row[col["tipo_doador"]])

                    yield {
                        "ano_eleicao": ano,
                        "numero_recibo": _limpo(row[col["numero_recibo"]]),
                        "cpf_candidato": _doc(row[col["cpf_candidato"]]),
                        "nome_candidato": _limpo(row[col["nome_candidato"]]),
                        "cargo": _limpo(row[col["cargo"]]),
                        "sigla_partido": _limpo(row[col["sigla_partido"]]),
                        "uf": _limpo(row[col["uf"]]),
                        "cpf_cnpj_doador": _doc(row[col["cpf_cnpj_doador"]]),
                        "nome_doador": _limpo(row[col["nome_doador_rfb"]]),
                        "tipo_doador": origem,
                        "setor_economico_doador": _limpo(row[col["setor_economico_doador"]]),
                        "cpf_cnpj_doador_originario": _doc(row[col["cpf_cnpj_doador_originario"]]),
                        "nome_doador_originario": _limpo(row[col["nome_doador_originario_rfb"]]),
                        # "Descricao da receita" (texto livre) não tem equivalente
                        # estrutural em tse_receitas — mantido em natureza_receita
                        # como melhor aproximação disponível (ver nota no header do
                        # arquivo: não é o mesmo tipo de dado que DS_NATUREZA_RECEITA
                        # dos anos modernos, que é categórico, não texto livre).
                        "natureza_receita": _limpo(row[col["descricao"]]),
                        "origem_receita": origem,
                        "especie_recurso": _limpo(row[col["especie_recurso"]]),
                        "fonte_recurso": _limpo(row[col["fonte_recurso"]]),
                        "valor": valor,
                        "data_receita": _parse_data(row[col["data_receita"]]),
                        "data_prestacao_contas": None,
                    }


def _insert_receitas_com_retry(sb_factory, batch: list, tentativas: int = 5) -> None:
    for t in range(tentativas):
        try:
            sb_factory().table("tse_receitas").upsert(batch, on_conflict="numero_recibo,ano_eleicao").execute()
            return
        except Exception as e:
            if t == tentativas - 1:
                raise
            espera = 5 * (t + 1)
            log.warning("Erro ao inserir receitas (tentativa %d/%d): %s — aguardando %ds", t + 1, tentativas, e, espera)
            time.sleep(espera)


def ingerir_receitas(ano: int, zip_path: str, skip_delete: bool = False, ufs: list | None = None) -> None:
    def sb_factory():
        return create_client(*_sb_credentials())

    sb = sb_factory()

    if not skip_delete:
        log.info("Deletando receitas existentes de %d...", ano)
        sb.table("tse_receitas").delete().eq("ano_eleicao", ano).execute()

    buf: dict[tuple, dict] = {}  # dedup por (numero_recibo, ano_eleicao) dentro de cada batch
    total = 0

    for row in iter_receitas_legado(zip_path, ano, ufs=ufs):
        key = (row.get("numero_recibo"), row.get("ano_eleicao"))
        buf[key] = row
        if len(buf) >= CHUNK:
            batch = list(buf.values())
            _insert_receitas_com_retry(sb_factory, batch)
            total += len(batch)
            buf = {}
            if total % 50000 == 0:
                log.info("%d receitas gravadas", total)

    if buf:
        batch = list(buf.values())
        _insert_receitas_com_retry(sb_factory, batch)
        total += len(batch)

    log.info("TSE receitas %d: %d linhas gravadas", ano, total)
    return total


def _insert_com_retry(sb_factory, batch: list, tentativas: int = 5) -> None:
    for t in range(tentativas):
        try:
            sb_factory().table("tse_despesas").insert(batch).execute()
            return
        except Exception as e:
            if t == tentativas - 1:
                raise
            espera = 5 * (t + 1)
            log.warning("Erro ao inserir (tentativa %d/%d): %s — aguardando %ds", t + 1, tentativas, e, espera)
            time.sleep(espera)


def ingerir(ano: int, zip_path: str, skip_delete: bool = False, ufs: list | None = None) -> None:
    def sb_factory():
        return create_client(*_sb_credentials())

    sb = sb_factory()

    if not skip_delete:
        log.info("Deletando linhas existentes de %d...", ano)
        sb.table("tse_despesas").delete().eq("ano_eleicao", ano).execute()

    batch = []
    total = 0

    for row in iter_despesas_legado(zip_path, ano, ufs=ufs):
        batch.append(row)
        if len(batch) >= CHUNK:
            _insert_com_retry(sb_factory, batch)
            total += len(batch)
            batch = []
            if total % 50000 == 0:
                log.info("%d linhas gravadas", total)

    if batch:
        _insert_com_retry(sb_factory, batch)
        total += len(batch)

    log.info("TSE despesas %d: %d linhas gravadas", ano, total)
    return total


def main() -> None:
    parser = argparse.ArgumentParser(description="Ingestão TSE formato legado (2014/2016)")
    parser.add_argument("--ano", type=int, required=True, choices=[2014, 2016])
    parser.add_argument("--dataset", choices=["despesas", "receitas", "todos"], default="despesas",
                        help="Dataset a ingerir (padrão: despesas)")
    parser.add_argument("--zip", help="Caminho do ZIP já baixado (opcional — baixa se omitido)")
    parser.add_argument("--skip-delete", action="store_true", help="Não deletar ano antes de inserir (útil pra retomar run parcial)")
    parser.add_argument("--ufs", help="UFs a processar, separadas por vírgula (ex: SP,TO)")
    args = parser.parse_args()

    zip_path = args.zip
    if not zip_path:
        zip_path = f"/tmp/tse_{args.ano}.zip"
        if not os.path.exists(zip_path):
            url = ZIP_URLS[args.ano]
            log.info("Baixando %s → %s", url, zip_path)
            r = requests.get(url, stream=True, timeout=300)
            r.raise_for_status()
            with open(zip_path, "wb") as f:
                for chunk in r.iter_content(65536):
                    f.write(chunk)
            log.info("Download concluído: %s", zip_path)
        else:
            log.info("ZIP já existe: %s", zip_path)

    ufs = [u.strip().upper() for u in args.ufs.split(",")] if args.ufs else None

    if args.dataset in ("despesas", "todos"):
        ingerir(args.ano, zip_path, skip_delete=args.skip_delete, ufs=ufs)
    if args.dataset in ("receitas", "todos"):
        ingerir_receitas(args.ano, zip_path, skip_delete=args.skip_delete, ufs=ufs)


if __name__ == "__main__":
    main()
