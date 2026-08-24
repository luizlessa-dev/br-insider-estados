"""
Source do pipeline seguro para os anos legado (2014/2016) — mesmo protocolo de
zip_source.ZipYearSource, mas reaproveitando os parsers de formato antigo
(ingest_legado.py: layout de colunas por índice, arquivos por UF, .txt em
latin-1) em vez do connector.py moderno.

Isso NÃO reintroduz o caminho delete-before-load: download_and_validate() só
baixa e valida o ZIP; iter_rows() só itera linhas já parseadas. O DELETE
continua acontecendo apenas dentro de tse_promote_year() (swap atômico), como
em qualquer outro ano — ver safe_loader.load_year().

Escopo de cargos preservado do ingest_legado.py original (inclui vereador),
que é mais amplo que o dos anos modernos (connector.py: só Prefeito/Vice, sem
vereador — decisão de volume, ver comentário em ingest-tse.yml). Mantido como
estava para não mudar escopo de dado numa migração que é só de mecanismo de
carga — se quiser alinhar escopo com os anos modernos, é uma decisão separada.
"""
from __future__ import annotations

import logging
import os
import zipfile

import requests

from .ingest_legado import ZIP_URLS, iter_despesas_legado, iter_receitas_legado
from .safe_loader import Source, SourceError

logger = logging.getLogger("tse.legacy_source")

ANOS_SUPORTADOS = (2014, 2016)


class LegacyZipSource(Source):
    """Fonte de receitas OU despesas de um ano legado (2014/2016)."""

    def __init__(self, dataset: str, ano: int) -> None:
        if dataset not in ("receitas", "despesas"):
            raise ValueError(f"dataset invalido: {dataset}")
        if ano not in ANOS_SUPORTADOS:
            raise ValueError(f"ano legado nao suportado: {ano} (só {ANOS_SUPORTADOS})")
        self.dataset = dataset
        self.ano = ano
        self._zip_path: str | None = None

    def download_and_validate(self) -> None:
        zip_path = f"/tmp/tse_legado_{self.ano}.zip"
        if not os.path.exists(zip_path):
            url = ZIP_URLS[self.ano]
            try:
                logger.info("Baixando ZIP legado %d → %s", self.ano, zip_path)
                r = requests.get(url, stream=True, timeout=600)
                r.raise_for_status()
                tmp = zip_path + ".part"
                with open(tmp, "wb") as f:
                    for chunk in r.iter_content(65536):
                        f.write(chunk)
                os.replace(tmp, zip_path)  # atômico: nunca deixa .zip parcial c/ nome final
            except Exception as exc:
                raise SourceError(f"download legado {self.dataset} {self.ano}: {exc}") from exc
        else:
            logger.info("ZIP legado %d já existe: %s", self.ano, zip_path)

        try:
            with zipfile.ZipFile(zip_path) as zf:
                bad = zf.testzip()
                if bad is not None:
                    raise SourceError(
                        f"ZIP corrompido em legado {self.dataset} {self.ano}: {bad}")
                if not zf.namelist():
                    raise SourceError(f"ZIP vazio em legado {self.dataset} {self.ano}")
        except zipfile.BadZipFile as exc:
            raise SourceError(f"ZIP inválido em legado {self.dataset} {self.ano}: {exc}") from exc

        self._zip_path = zip_path

    def iter_rows(self):
        if self._zip_path is None:
            raise SourceError("download_and_validate() não foi chamado")
        if self.dataset == "receitas":
            yield from iter_receitas_legado(self._zip_path, self.ano)
        else:
            yield from iter_despesas_legado(self._zip_path, self.ano)
