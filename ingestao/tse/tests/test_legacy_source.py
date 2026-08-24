"""
Testes de LegacyZipSource (2014/2016) — sem rede, sem banco.

Monta um ZIP sintético em memória no layout real de colunas (COL_2016 /
COL_RECEITAS_2016), monkeypatcha requests.get pra servir esse ZIP, e verifica
que LegacyZipSource entrega linhas no formato que o staging do pipeline seguro
espera (mesmas chaves de ZipYearSource, source_id ausente/None).
"""
from __future__ import annotations

import io
import os
import zipfile

import pytest

from ingestao.tse.legacy_source import LegacyZipSource
from ingestao.tse.safe_loader import FINGERPRINT_CAMPOS, SourceError, row_fingerprint


def _col_row(mapping: dict, values: dict, n: int) -> list:
    """Monta uma linha CSV de n colunas, preenchendo os índices mapeados."""
    row = ["" for _ in range(n)]
    for campo, idx in mapping.items():
        if campo in values:
            row[idx] = values[campo]
    return row


DESPESAS_COL_2016 = {
    "cpf_candidato": 12, "nome_candidato": 11, "cargo": 10, "sigla_partido": 8,
    "uf": 5, "cpf_cnpj_fornecedor": 16, "nome_fornecedor": 17, "tipo_despesa": 23,
    "descricao_despesa": 24, "valor_despesa": 22, "numero_documento": 15,
    "data_despesa": 21,
}
RECEITAS_COL_2016 = {
    "uf": 5, "sigla_partido": 8, "cargo": 10, "nome_candidato": 11,
    "cpf_candidato": 12, "numero_recibo": 14, "cpf_cnpj_doador": 16,
    "nome_doador_rfb": 18, "setor_economico_doador": 23, "data_receita": 24,
    "valor": 25, "tipo_doador": 26, "fonte_recurso": 27, "especie_recurso": 28,
    "descricao": 29, "cpf_cnpj_doador_originario": 30,
    "nome_doador_originario_rfb": 34,
}


def _make_zip_bytes(dataset: str, ano: int, rows_por_uf: dict) -> bytes:
    """rows_por_uf: {"SP": [linha1, linha2, ...], ...} — cada linha já em CSV."""
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w") as z:
        for uf, linhas in rows_por_uf.items():
            nome = f"{dataset}_candidatos_{ano}_{uf}.txt"
            header = ";".join(str(i) for i in range(40)) + "\n"
            corpo = "\n".join(";".join(l) for l in linhas)
            z.writestr(nome, (header + corpo).encode("latin-1"))
    return buf.getvalue()


class _FakeResponse:
    def __init__(self, content: bytes):
        self._content = content

    def raise_for_status(self):
        pass

    def iter_content(self, chunk_size):
        yield self._content


@pytest.fixture(autouse=True)
def _limpa_zip_temp():
    for ano in (2014, 2016):
        p = f"/tmp/tse_legado_{ano}.zip"
        if os.path.exists(p):
            os.remove(p)
    yield
    for ano in (2014, 2016):
        p = f"/tmp/tse_legado_{ano}.zip"
        if os.path.exists(p):
            os.remove(p)


def test_despesas_legado_filtra_cargo_e_normaliza(monkeypatch):
    linhas_sp = [
        _col_row(DESPESAS_COL_2016, {
            "cpf_candidato": "12345678901", "nome_candidato": "FULANO",
            "cargo": "DEPUTADO FEDERAL", "sigla_partido": "PXX", "uf": "SP",
            "cpf_cnpj_fornecedor": "-4", "nome_fornecedor": "FORNECEDOR LTDA",
            "tipo_despesa": "COMBUSTIVEIS", "descricao_despesa": "GASOLINA",
            "valor_despesa": "1.234,56", "numero_documento": "NF-001",
            "data_despesa": "25/10/2016",
        }, 40),
        _col_row(DESPESAS_COL_2016, {
            "cpf_candidato": "98765432100", "nome_candidato": "FORA DE ESCOPO",
            "cargo": "JUIZ ELEITORAL", "sigla_partido": "PXX", "uf": "SP",
            "cpf_cnpj_fornecedor": "11222333000181", "nome_fornecedor": "X",
            "tipo_despesa": "X", "descricao_despesa": "X",
            "valor_despesa": "10,00", "numero_documento": "NF-002",
            "data_despesa": "01/01/2016",
        }, 40),
    ]
    zip_bytes = _make_zip_bytes("despesas", 2016, {"SP": linhas_sp})
    monkeypatch.setattr(
        "ingestao.tse.legacy_source.requests.get",
        lambda *a, **kw: _FakeResponse(zip_bytes),
    )

    source = LegacyZipSource("despesas", 2016)
    source.download_and_validate()
    rows = list(source.iter_rows())

    assert len(rows) == 1, "cargo fora de CARGOS_ALVO deveria ser filtrado"
    r = rows[0]
    assert r["ano_eleicao"] == 2016
    assert r["cpf_candidato"] == "12345678901"
    assert r["cpf_cnpj_fornecedor"] is None, "sentinela '-4' deve virar None"
    assert r["valor_despesa"] == 1234.56
    assert r["data_despesa"] == "2016-10-25"
    assert "source_id" not in r or r.get("source_id") is None


def test_receitas_legado_parseia_valor_e_doador(monkeypatch):
    linhas_sp = [
        _col_row(RECEITAS_COL_2016, {
            "uf": "SP", "sigla_partido": "PXX", "cargo": "SENADOR",
            "nome_candidato": "FULANA", "cpf_candidato": "11122233344",
            "numero_recibo": "REC-1", "cpf_cnpj_doador": "22233344455",
            "nome_doador_rfb": "DOADOR FULANO", "setor_economico_doador": "COMERCIO",
            "data_receita": "10/09/2016", "valor": "500,00",
            "tipo_doador": "PESSOA FISICA", "fonte_recurso": "FUNDO PARTIDARIO",
            "especie_recurso": "RECURSOS FINANCEIROS", "descricao": "DOACAO",
        }, 40),
    ]
    zip_bytes = _make_zip_bytes("receitas", 2016, {"SP": linhas_sp})
    monkeypatch.setattr(
        "ingestao.tse.legacy_source.requests.get",
        lambda *a, **kw: _FakeResponse(zip_bytes),
    )

    source = LegacyZipSource("receitas", 2016)
    source.download_and_validate()
    rows = list(source.iter_rows())

    assert len(rows) == 1
    r = rows[0]
    assert r["valor"] == 500.0
    assert r["cpf_cnpj_doador"] == "22233344455"
    assert r["numero_recibo"] == "REC-1"

    # a linha tem exatamente as chaves que row_fingerprint/FINGERPRINT_CAMPOS
    # e _COPY_COLS de receitas esperam (compatibilidade com o staging).
    fp = row_fingerprint(r, 1, FINGERPRINT_CAMPOS["receitas"])
    assert len(fp) == 64  # sha256 hex


def test_download_falha_vira_source_error(monkeypatch):
    def _falha(*a, **kw):
        raise ConnectionError("CDN fora do ar (simulado)")
    monkeypatch.setattr("ingestao.tse.legacy_source.requests.get", _falha)

    source = LegacyZipSource("despesas", 2014)
    with pytest.raises(SourceError):
        source.download_and_validate()


def test_zip_vazio_vira_source_error(monkeypatch):
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w"):
        pass  # zip sem nenhum arquivo
    monkeypatch.setattr(
        "ingestao.tse.legacy_source.requests.get",
        lambda *a, **kw: _FakeResponse(buf.getvalue()),
    )

    source = LegacyZipSource("despesas", 2016)
    with pytest.raises(SourceError):
        source.download_and_validate()


def test_iter_rows_sem_download_previo_falha():
    source = LegacyZipSource("despesas", 2016)
    with pytest.raises(SourceError):
        list(source.iter_rows())


def test_ano_nao_suportado_rejeitado():
    with pytest.raises(ValueError):
        LegacyZipSource("despesas", 2018)


def test_runner_bloqueia_legado_sem_segunda_aprovacao(monkeypatch):
    """TSE_SAFE_LOADER=1 sozinho NÃO libera 2014/2016 — exige também
    TSE_LEGACY_APPROVED=1 (aprovação separada, código migrado != autorizado)."""
    from ingestao.tse import runner

    monkeypatch.setattr(runner, "SAFE_LOADER", True)
    monkeypatch.delenv("TSE_LEGACY_APPROVED", raising=False)

    with pytest.raises(runner.AnoLegadoNaoAprovado):
        runner._exigir_aprovacao_legado("despesas", 2016)

    # ano moderno nunca é afetado por essa trava
    runner._exigir_aprovacao_legado("despesas", 2024)  # não deve levantar

    monkeypatch.setenv("TSE_LEGACY_APPROVED", "1")
    runner._exigir_aprovacao_legado("despesas", 2016)  # não deve levantar


def test_runner_roteia_anos_legado_para_legacy_source(monkeypatch):
    """runner._run_safe deve escolher LegacyZipSource para 2014/2016 e
    ZipYearSource para os demais anos."""
    from ingestao.tse import runner

    criado = {}

    class _FakeLegacySource:
        def __init__(self, dataset, ano):
            criado["classe"] = "legacy"
            criado["dataset"] = dataset
            criado["ano"] = ano

        def download_and_validate(self):
            pass

        def iter_rows(self):
            return iter([])

    class _FakeZipSource:
        def __init__(self, dataset, ano):
            criado["classe"] = "moderno"
            criado["dataset"] = dataset
            criado["ano"] = ano

        def download_and_validate(self):
            pass

        def iter_rows(self):
            return iter([])

    class _FakeBackend:
        def count_final(self, dataset, ano):
            return 0

        def stage_rows(self, dataset, run_id, rows, resume=False):
            return 0

        def count_staging(self, dataset, run_id):
            return 0

        def promote(self, dataset, ano, run_id, min_expected):
            return {"rows_after": 0}

        def clear_staging(self, dataset, run_id):
            pass

        def record_run(self, run):
            pass

    monkeypatch.setattr("ingestao.tse.legacy_source.LegacyZipSource", _FakeLegacySource)
    monkeypatch.setattr("ingestao.tse.zip_source.ZipYearSource", _FakeZipSource)
    monkeypatch.setattr(runner, "PostgrestBackend", None, raising=False)
    monkeypatch.setattr("ingestao.tse.safe_backend.PostgrestBackend", lambda writer: _FakeBackend())

    runner._run_safe(writer=None, dataset="despesas", ano=2016)
    assert criado["classe"] == "legacy"

    runner._run_safe(writer=None, dataset="despesas", ano=2024)
    assert criado["classe"] == "moderno"
