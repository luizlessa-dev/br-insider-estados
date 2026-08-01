"""
Infosimples OCR — Extração de dados de documentos PF via OCR

Endpoints implementados:
  ocr/imposto-renda/declaracao  — Declaração de IRPF (PDF)    R$ 0,10/consulta
  ocr/crlv                      — CRLV do veículo (imagem)     R$ 0,10/consulta
  ocr/cnh                       — CNH frente/verso (imagem)    R$ 0,10/consulta

Diferença fundamental em relação aos demais connectors Subradar:
  Os connectors padrão recebem um CPF/CNPJ e consultam fontes públicas.
  Este módulo recebe o *conteúdo do documento* e extrai dados estruturados via OCR.
  Ele é chamado pelo endpoint de upload do dossiê avulso PF, não pelo runner_pf.

Fluxo de uso:
  1. Usuário faz upload do documento no front do Subradar
  2. O arquivo é lido como bytes e passado para extrair_ir() / extrair_crlv() / extrair_cnh()
  3. O retorno contém dados estruturados + alertas no formato padrão Subradar
  4. Os alertas são gravados em sub_alertas; os dados enriquecem o dossiê

Variável de ambiente: INFOSIMPLES_TOKEN (já ativa em produção via Vercel)
"""
from __future__ import annotations

import base64
import logging
import os
from pathlib import Path

import requests

logger = logging.getLogger("subradar.infosimples_ocr")

_BASE_URL = "https://api.infosimples.com/api/v2/imagens/ocr"
_TOKEN = os.environ.get("INFOSIMPLES_TOKEN", "")
_TIMEOUT = 60  # segundos — OCR pode levar tempo para PDFs longos


# ─────────────────────────────────────────────────────────────
# Helpers internos
# ─────────────────────────────────────────────────────────────

def _token() -> str:
    t = os.environ.get("INFOSIMPLES_TOKEN", _TOKEN)
    if not t:
        raise EnvironmentError("INFOSIMPLES_TOKEN não configurado")
    return t


def _to_bytes(source: bytes | str | Path) -> bytes:
    """Aceita bytes já carregados ou caminho para arquivo."""
    if isinstance(source, bytes):
        return source
    return Path(source).read_bytes()


def _b64(data: bytes) -> str:
    return base64.b64encode(data).decode("ascii")


def _post_ocr(endpoint: str, field: str, file_bytes: bytes) -> dict:
    """
    Envia documento para o endpoint Infosimples OCR.
    Retorna o dict bruto da resposta.
    Lança requests.HTTPError em caso de falha HTTP.
    """
    url = f"{_BASE_URL}/{endpoint}"
    payload = {
        field: _b64(file_bytes),
        "token": _token(),
    }
    resp = requests.post(url, data=payload, timeout=_TIMEOUT)
    resp.raise_for_status()
    return resp.json()


def _alerta(
    fonte: str,
    titulo: str,
    descricao: str,
    severidade: str = "atencao",
    categoria: str = "Documento",
) -> dict:
    """Monta alerta no formato padrão Subradar."""
    return {
        "fonte": fonte,
        "titulo": titulo,
        "descricao": descricao,
        "severidade": severidade,
        "categoria": categoria,
    }


def _n(raw: str | None) -> float | None:
    """Converte string monetária para float; None se não conseguir."""
    if not raw:
        return None
    cleaned = str(raw).replace("R$", "").replace(".", "").replace(",", ".").strip()
    try:
        return float(cleaned)
    except ValueError:
        return None


# ─────────────────────────────────────────────────────────────
# IR — Declaração de Imposto de Renda PF
# ─────────────────────────────────────────────────────────────

def extrair_ir(
    source: bytes | str | Path,
    cpf_esperado: str | None = None,
) -> dict:
    """
    Extrai dados estruturados de uma declaração de IRPF (PDF).

    Args:
        source: bytes do PDF ou caminho do arquivo
        cpf_esperado: se fornecido, gera alerta se o CPF extraído divergir

    Retorna:
        {
          "dados": {...},     # campos estruturados extraídos
          "alertas": [...],   # alertas no formato Subradar
          "meta": {...},      # fonte, custo, campos presentes
        }
    """
    file_bytes = _to_bytes(source)
    raw = _post_ocr("imposto-renda/declaracao", "pdf_base64", file_bytes)

    dados_brutos = (raw.get("data") or [{}])[0]
    alertas: list[dict] = []
    _FONTE = "infosimples_ocr_ir"

    # Extrai seções principais
    identificacao = dados_brutos.get("identificacao") or {}
    bens = dados_brutos.get("bens_direitos") or {}
    rendimentos_pj = dados_brutos.get("rendimentos_tributaveis_pj_titular") or {}
    dividas = dados_brutos.get("dividas_onus_reais") or {}
    dependentes = dados_brutos.get("dependentes") or []
    resumo = dados_brutos.get("resumo") or {}
    ano_exercicio = dados_brutos.get("ano_exercicio", "")

    cpf_doc = identificacao.get("cpf", "")
    nome = identificacao.get("nome", "")

    # Valores normalizados (float)
    total_bens = (
        bens.get("normalizado_total_exercicio_atual")
        or _n(bens.get("total_exercicio_atual"))
        or 0.0
    )
    total_renda = (
        rendimentos_pj.get("normalizado_total_recebido")
        or 0.0
    )
    total_dividas = (
        dividas.get("normalizado_total_exercicio_atual")
        or _n(dividas.get("total_exercicio_atual"))
        or 0.0
    )
    imposto_devido = (
        resumo.get("normalizado_imposto_devido")
        or _n(resumo.get("imposto_devido"))
        or 0.0
    )

    # CNPJs dos empregadores (para cruzamento)
    empregadores = [
        r.get("cnpj_cpf", "") for r in (rendimentos_pj.get("registros") or [])
        if r.get("cnpj_cpf")
    ]

    dados = {
        "cpf": cpf_doc,
        "nome": nome,
        "data_nascimento": identificacao.get("data_nascimento", ""),
        "endereco_municipio": identificacao.get("endereco_municipio", ""),
        "endereco_uf": identificacao.get("endereco_uf", ""),
        "ocupacao_principal": identificacao.get("ocupacao_principal", ""),
        "titulo_eleitoral": identificacao.get("titulo_eleitoral", ""),
        "ano_exercicio": ano_exercicio,
        "total_bens_brl": total_bens,
        "total_renda_brl": total_renda,
        "total_dividas_brl": total_dividas,
        "imposto_devido_brl": imposto_devido,
        "num_dependentes": len(dependentes),
        "dependentes": [
            {"nome": d.get("nome"), "cpf": d.get("cpf"), "data_nascimento": d.get("data_nascimento")}
            for d in dependentes
        ],
        "empregadores_cnpj": empregadores,
        "n_empregadores": len(empregadores),
        "n_bens": len(bens.get("registros") or []),
    }

    # ── Alertas ────────────────────────────────────────────────

    # CPF divergente
    if cpf_esperado:
        cpf_e = cpf_esperado.replace(".", "").replace("-", "").strip()
        cpf_d = cpf_doc.replace(".", "").replace("-", "").strip()
        if cpf_e and cpf_d and cpf_e != cpf_d:
            alertas.append(_alerta(
                _FONTE,
                "CPF no documento diverge do CPF consultado",
                f"CPF declarado: {cpf_doc} | CPF esperado: {cpf_esperado}",
                severidade="critico",
                categoria="Identidade",
            ))

    # Patrimônio declarado alto (acima de R$ 5M — sinal de PEP/risco)
    if total_bens >= 5_000_000:
        alertas.append(_alerta(
            _FONTE,
            f"Patrimônio declarado alto — R$ {total_bens:,.0f}",
            f"Ano-exercício {ano_exercicio}: bens e direitos totalizam R$ {total_bens:,.0f}. "
            "Valor acima de R$ 5M requer verificação de PEP e origem do patrimônio.",
            severidade="atencao",
            categoria="Patrimônio",
        ))

    # Dívidas maiores que renda declarada
    if total_dividas > 0 and total_renda > 0 and total_dividas > total_renda:
        alertas.append(_alerta(
            _FONTE,
            f"Dívidas ({total_dividas:,.0f}) superam renda declarada ({total_renda:,.0f})",
            f"Ano-exercício {ano_exercicio}: dívidas/ônus reais R$ {total_dividas:,.0f} "
            f"> renda tributável PJ R$ {total_renda:,.0f}. Sinal de comprometimento financeiro.",
            severidade="atencao",
            categoria="Crédito",
        ))

    # Sem renda declarada mas com bens (possível subfaturamento/informalidade)
    if total_bens > 100_000 and total_renda == 0:
        alertas.append(_alerta(
            _FONTE,
            "Patrimônio declarado sem renda tributável PJ registrada",
            f"Bens e direitos: R$ {total_bens:,.0f} | Renda tributável de PJ: R$ 0. "
            "Possível renda informal, aposentadoria ou pessoa física sem empregador.",
            severidade="info",
            categoria="Patrimônio",
        ))

    # Documento desatualizado
    try:
        ano = int(ano_exercicio)
        import datetime
        ano_atual = datetime.date.today().year
        if ano < ano_atual - 2:
            alertas.append(_alerta(
                _FONTE,
                f"Declaração de IR com {ano_atual - ano} anos de defasagem",
                f"Documento do exercício {ano_exercicio}. Considerar solicitar declaração mais recente.",
                severidade="info",
                categoria="Documento",
            ))
    except (ValueError, TypeError):
        pass

    meta = {
        "fonte": _FONTE,
        "endpoint": "ocr/imposto-renda/declaracao",
        "custo_brl": 0.10,
        "billable": raw.get("billable", True),
        "api_code": raw.get("code"),
        "campos_presentes": {
            "identificacao": bool(identificacao.get("nome")),
            "bens_direitos": bool(bens.get("registros")),
            "rendimentos_pj": bool(rendimentos_pj.get("registros")),
            "dividas": bool(dividas.get("registros")),
            "dependentes": len(dependentes) > 0,
            "resumo": bool(resumo.get("imposto_devido")),
        },
    }

    if alertas:
        logger.info("[OCR IR] %d alerta(s) para CPF %s", len(alertas), cpf_doc)
    else:
        logger.info("[OCR IR] extração OK — bens R$ %.0f | renda R$ %.0f", total_bens, total_renda)

    return {"dados": dados, "alertas": alertas, "meta": meta}


# ─────────────────────────────────────────────────────────────
# CRLV — Certificado de Registro e Licenciamento de Veículo
# ─────────────────────────────────────────────────────────────

def extrair_crlv(
    source: bytes | str | Path,
    cpf_cnpj_esperado: str | None = None,
) -> dict:
    """
    Extrai dados estruturados de um CRLV (imagem: JPG, PNG ou PDF).

    Campos típicos retornados pela Infosimples no data[0]:
      placa, renavam, chassi, marca_modelo, ano_fabricacao, ano_modelo,
      cor, tipo, combustivel, proprietario_nome, proprietario_cpf_cnpj,
      municipio, uf, exercicio, data_validade, categoria_uso, potencia,
      cilindrada, carroceria, capacidade_passageiros, capacidade_carga_kg,
      peso_bruto_total, eixos, data_emissao

    Args:
        source: bytes da imagem/PDF ou caminho do arquivo
        cpf_cnpj_esperado: se fornecido, alerta se proprietário divergir

    Retorna:
        {"dados": {...}, "alertas": [...], "meta": {...}}
    """
    file_bytes = _to_bytes(source)
    raw = _post_ocr("crlv", "image_base64", file_bytes)

    dados_brutos = (raw.get("data") or [{}])[0]
    alertas: list[dict] = []
    _FONTE = "infosimples_ocr_crlv"

    placa = dados_brutos.get("placa", "")
    renavam = dados_brutos.get("renavam", "")
    chassi = dados_brutos.get("chassi", "")
    marca_modelo = (
        dados_brutos.get("marca_modelo")
        or f"{dados_brutos.get('marca', '')} {dados_brutos.get('modelo', '')}".strip()
    )
    ano_fab = dados_brutos.get("ano_fabricacao", "")
    ano_mod = dados_brutos.get("ano_modelo", "")
    cor = dados_brutos.get("cor", "")
    proprietario_nome = dados_brutos.get("proprietario_nome", dados_brutos.get("nome_proprietario", ""))
    proprietario_doc = dados_brutos.get(
        "proprietario_cpf_cnpj",
        dados_brutos.get("cpf_cnpj_proprietario", dados_brutos.get("cpf", "")),
    )
    municipio = dados_brutos.get("municipio", "")
    uf = dados_brutos.get("uf", "")
    exercicio = dados_brutos.get("exercicio", "")
    data_validade = dados_brutos.get("data_validade", "")

    dados = {
        "placa": placa,
        "renavam": renavam,
        "chassi": chassi,
        "marca_modelo": marca_modelo,
        "ano_fabricacao": ano_fab,
        "ano_modelo": ano_mod,
        "cor": cor,
        "tipo": dados_brutos.get("tipo", ""),
        "combustivel": dados_brutos.get("combustivel", ""),
        "proprietario_nome": proprietario_nome,
        "proprietario_cpf_cnpj": proprietario_doc,
        "municipio": municipio,
        "uf": uf,
        "exercicio": exercicio,
        "data_validade": data_validade,
        "categoria_uso": dados_brutos.get("categoria_uso", ""),
    }

    # ── Alertas ────────────────────────────────────────────────

    # Proprietário diverge do CPF/CNPJ esperado
    if cpf_cnpj_esperado and proprietario_doc:
        doc_e = "".join(c for c in cpf_cnpj_esperado if c.isdigit())
        doc_d = "".join(c for c in proprietario_doc if c.isdigit())
        if doc_e and doc_d and doc_e != doc_d:
            alertas.append(_alerta(
                _FONTE,
                "Proprietário do veículo diverge do CPF/CNPJ consultado",
                f"Proprietário no CRLV: {proprietario_nome} ({proprietario_doc}) | "
                f"CPF/CNPJ esperado: {cpf_cnpj_esperado}",
                severidade="atencao",
                categoria="Patrimônio",
            ))

    # CRLV vencido (licenciamento em atraso)
    if data_validade:
        try:
            import datetime
            # Formatos comuns: DD/MM/YYYY ou YYYY-MM-DD
            for fmt in ("%d/%m/%Y", "%Y-%m-%d", "%d-%m-%Y"):
                try:
                    validade_dt = datetime.datetime.strptime(data_validade, fmt).date()
                    break
                except ValueError:
                    continue
            else:
                validade_dt = None

            if validade_dt and validade_dt < datetime.date.today():
                alertas.append(_alerta(
                    _FONTE,
                    f"CRLV vencido desde {data_validade}",
                    f"Veículo {placa} ({marca_modelo}) com licenciamento em atraso. "
                    "Exercício no documento: " + str(exercicio),
                    severidade="atencao",
                    categoria="Documento",
                ))
        except Exception:
            pass

    meta = {
        "fonte": _FONTE,
        "endpoint": "ocr/crlv",
        "custo_brl": 0.10,
        "billable": raw.get("billable", True),
        "api_code": raw.get("code"),
        "campos_presentes": {
            "placa": bool(placa),
            "renavam": bool(renavam),
            "chassi": bool(chassi),
            "proprietario": bool(proprietario_nome or proprietario_doc),
        },
    }

    logger.info(
        "[OCR CRLV] placa=%s renavam=%s proprietário=%s",
        placa or "?", renavam or "?", proprietario_nome or "?",
    )

    return {"dados": dados, "alertas": alertas, "meta": meta}


# ─────────────────────────────────────────────────────────────
# CNH — Carteira Nacional de Habilitação
# ─────────────────────────────────────────────────────────────

def extrair_cnh(
    source: bytes | str | Path,
    cpf_esperado: str | None = None,
) -> dict:
    """
    Extrai dados estruturados de uma CNH (imagem: JPG, PNG ou PDF).

    Campos típicos retornados pela Infosimples no data[0]:
      nome, cpf, rg, data_nascimento, data_emissao, data_validade,
      categoria, numero_registro, renach, numero_espelho,
      municipio_emissao, uf_emissao, nome_mae, nome_pai,
      local_nascimento, naturalidade_uf, observacoes, pontuacao,
      num_reincidencia (renovações)

    Args:
        source: bytes da imagem/PDF ou caminho do arquivo
        cpf_esperado: se fornecido, alerta se CPF divergir

    Retorna:
        {"dados": {...}, "alertas": [...], "meta": {...}}
    """
    file_bytes = _to_bytes(source)
    raw = _post_ocr("cnh", "image_base64", file_bytes)

    dados_brutos = (raw.get("data") or [{}])[0]
    alertas: list[dict] = []
    _FONTE = "infosimples_ocr_cnh"

    nome = dados_brutos.get("nome", "")
    cpf_doc = dados_brutos.get("cpf", "")
    rg = dados_brutos.get("rg", "")
    data_nascimento = dados_brutos.get("data_nascimento", "")
    data_emissao = dados_brutos.get("data_emissao", "")
    data_validade = dados_brutos.get("data_validade", "")
    categoria = dados_brutos.get("categoria", "")
    numero_registro = dados_brutos.get("numero_registro", "")
    renach = dados_brutos.get("renach", "")
    municipio_emissao = dados_brutos.get("municipio_emissao", "")
    uf_emissao = dados_brutos.get("uf_emissao", "")
    nome_mae = dados_brutos.get("nome_mae", "")
    nome_pai = dados_brutos.get("nome_pai", "")
    pontuacao = dados_brutos.get("pontuacao", dados_brutos.get("pontos", ""))

    dados = {
        "nome": nome,
        "cpf": cpf_doc,
        "rg": rg,
        "data_nascimento": data_nascimento,
        "data_emissao": data_emissao,
        "data_validade": data_validade,
        "categoria": categoria,
        "numero_registro": numero_registro,
        "renach": renach,
        "numero_espelho": dados_brutos.get("numero_espelho", ""),
        "municipio_emissao": municipio_emissao,
        "uf_emissao": uf_emissao,
        "nome_mae": nome_mae,
        "nome_pai": nome_pai,
        "pontuacao": pontuacao,
    }

    # ── Alertas ────────────────────────────────────────────────

    # CPF divergente
    if cpf_esperado and cpf_doc:
        cpf_e = "".join(c for c in cpf_esperado if c.isdigit())
        cpf_d = "".join(c for c in cpf_doc if c.isdigit())
        if cpf_e and cpf_d and cpf_e != cpf_d:
            alertas.append(_alerta(
                _FONTE,
                "CPF na CNH diverge do CPF consultado",
                f"CPF na CNH: {cpf_doc} | CPF esperado: {cpf_esperado}",
                severidade="critico",
                categoria="Identidade",
            ))

    # CNH vencida
    if data_validade:
        try:
            import datetime
            for fmt in ("%d/%m/%Y", "%Y-%m-%d", "%d-%m-%Y"):
                try:
                    validade_dt = datetime.datetime.strptime(data_validade, fmt).date()
                    break
                except ValueError:
                    continue
            else:
                validade_dt = None

            if validade_dt:
                hoje = datetime.date.today()
                if validade_dt < hoje:
                    dias = (hoje - validade_dt).days
                    alertas.append(_alerta(
                        _FONTE,
                        f"CNH vencida há {dias} dia(s) — venciu em {data_validade}",
                        f"CNH categoria {categoria} vencida. "
                        "Habilitação irregular para dirigir.",
                        severidade="atencao",
                        categoria="Documento",
                    ))
                elif (validade_dt - hoje).days <= 90:
                    alertas.append(_alerta(
                        _FONTE,
                        f"CNH vence em {(validade_dt - hoje).days} dia(s)",
                        f"CNH categoria {categoria} vence em {data_validade}. Renovação necessária em breve.",
                        severidade="info",
                        categoria="Documento",
                    ))
        except Exception:
            pass

    # Pontuação alta (suspenso ≥ 20 pts, cassado ≥ 40)
    if pontuacao:
        try:
            pts = int(str(pontuacao).split()[0])
            if pts >= 20:
                sev = "critico" if pts >= 40 else "atencao"
                alertas.append(_alerta(
                    _FONTE,
                    f"CNH com {pts} pontos de infração",
                    f"CNH categoria {categoria}: {pts} pontos. "
                    + ("Risco de cassação." if pts >= 40 else "Risco de suspensão."),
                    severidade=sev,
                    categoria="Documento",
                ))
        except (ValueError, TypeError):
            pass

    meta = {
        "fonte": _FONTE,
        "endpoint": "ocr/cnh",
        "custo_brl": 0.10,
        "billable": raw.get("billable", True),
        "api_code": raw.get("code"),
        "campos_presentes": {
            "nome": bool(nome),
            "cpf": bool(cpf_doc),
            "data_validade": bool(data_validade),
            "categoria": bool(categoria),
            "nome_mae": bool(nome_mae),
        },
    }

    logger.info(
        "[OCR CNH] nome=%s cpf=%s categoria=%s validade=%s",
        nome or "?", cpf_doc or "?", categoria or "?", data_validade or "?",
    )

    return {"dados": dados, "alertas": alertas, "meta": meta}


# ─────────────────────────────────────────────────────────────
# Ponto de entrada unificado — usado pelo endpoint de upload
# ─────────────────────────────────────────────────────────────

_EXTRACTORS = {
    "ir": extrair_ir,
    "crlv": extrair_crlv,
    "cnh": extrair_cnh,
}


def extrair_documento(
    tipo: str,
    source: bytes | str | Path,
    cpf_esperado: str | None = None,
) -> dict:
    """
    Ponto de entrada unificado para extração OCR.

    Args:
        tipo: "ir" | "crlv" | "cnh"
        source: bytes do arquivo ou caminho
        cpf_esperado: CPF/CNPJ para validação cruzada (opcional)

    Retorna:
        {"dados": {...}, "alertas": [...], "meta": {...}}

    Exemplo de uso no endpoint de upload:
        from ingestao.subradar.infosimples_ocr import extrair_documento
        resultado = extrair_documento("cnh", file_bytes, cpf_esperado="123.456.789-00")
        for alerta in resultado["alertas"]:
            alerta["cliente_id"] = cliente_id
        upsert("sub_alertas", resultado["alertas"])
    """
    extractor = _EXTRACTORS.get(tipo)
    if not extractor:
        raise ValueError(f"Tipo de documento desconhecido: '{tipo}'. Use: {list(_EXTRACTORS)}")
    return extractor(source, cpf_esperado=cpf_esperado)
