"""
Source real do pipeline seguro: baixa e valida o ZIP do TSE, depois itera as
linhas já mapeadas para dict (formato que o staging espera).

Reaproveita o connector existente (_open_prestacao_zip, iter_receitas,
iter_despesas). A validação garante que um ZIP truncado / resposta HTML de erro
reprove ANTES de qualquer coisa tocar o banco.
"""
from __future__ import annotations

import logging
import zipfile

from . import connector
from .safe_loader import Source, SourceError

logger = logging.getLogger("tse.zip_source")


def _receita_to_dict(r) -> dict:
    return {
        "ano_eleicao": r.ano_eleicao, "numero_recibo": r.numero_recibo,
        "cpf_candidato": r.cpf_candidato, "nome_candidato": r.nome_candidato,
        "cargo": r.cargo, "sigla_partido": r.sigla_partido, "uf": r.uf,
        "cpf_cnpj_doador": r.cpf_cnpj_doador, "nome_doador": r.nome_doador,
        "tipo_doador": r.tipo_doador, "setor_economico_doador": r.setor_economico_doador,
        "cpf_cnpj_doador_originario": r.cpf_cnpj_doador_originario,
        "nome_doador_originario": r.nome_doador_originario,
        "natureza_receita": r.natureza_receita, "origem_receita": r.origem_receita,
        "especie_recurso": r.especie_recurso, "fonte_recurso": r.fonte_recurso,
        "valor": r.valor, "data_receita": r.data_receita,
        "data_prestacao_contas": r.data_prestacao_contas,
    }


def _despesa_to_dict(d) -> dict:
    return {
        "ano_eleicao": d.ano_eleicao, "numero_documento": d.numero_documento,
        "cpf_candidato": d.cpf_candidato, "nome_candidato": d.nome_candidato,
        "cargo": d.cargo, "sigla_partido": d.sigla_partido, "uf": d.uf,
        "cpf_cnpj_fornecedor": d.cpf_cnpj_fornecedor, "nome_fornecedor": d.nome_fornecedor,
        "tipo_despesa": d.tipo_despesa, "descricao_despesa": d.descricao_despesa,
        "origem_despesa": d.origem_despesa, "especie_recurso": d.especie_recurso,
        "fonte_recurso": d.fonte_recurso, "valor_despesa": d.valor_despesa,
        "valor_prestado": d.valor_prestado, "data_despesa": d.data_despesa,
    }


class ZipYearSource(Source):
    """Fonte de receitas OU despesas de um ano (formato moderno, >= 2018)."""

    def __init__(self, dataset: str, ano: int) -> None:
        if dataset not in ("receitas", "despesas"):
            raise ValueError(f"dataset invalido: {dataset}")
        self.dataset = dataset
        self.ano = ano
        self._zf: zipfile.ZipFile | None = None

    def download_and_validate(self) -> None:
        try:
            zf = connector._open_prestacao_zip(self.ano)
        except Exception as exc:  # timeout, DNS, HTTP, etc. → tratado como fonte
            raise SourceError(f"download {self.dataset} {self.ano}: {exc}") from exc
        # Validação: ZIP íntegro e com ao menos um arquivo.
        bad = zf.testzip()
        if bad is not None:
            raise SourceError(f"ZIP corrompido em {self.dataset} {self.ano}: {bad}")
        if not zf.namelist():
            raise SourceError(f"ZIP vazio em {self.dataset} {self.ano}")
        self._zf = zf

    def iter_rows(self):
        if self._zf is None:
            raise SourceError("download_and_validate() não foi chamado")
        if self.dataset == "receitas":
            for r in connector.iter_receitas(self.ano, zf=self._zf):
                yield _receita_to_dict(r)
        else:
            for d in connector.iter_despesas(self.ano, zf=self._zf):
                yield _despesa_to_dict(d)
