"""
Titularidade e ônus reais do imóvel — sem cobertura contratada.

Não existe fonte pública que devolva titularidade ou ônus (hipoteca, alienação
fiduciária, penhora, servidão) a partir da matrícula. O caminho real é o ONR
(Operador Nacional do Registro, registrodeimoveis.org.br): consulta paga, por
matrícula, com contrato. Enquanto não houver contrato, estas duas seções
declaram a lacuna no laudo em vez de desaparecer dele.

Até 27/08/2026 os dois conectores retornavam None, o que os removia
silenciosamente do laudo. O efeito prático era um dossiê de compliance
imobiliário que nunca mencionava ônus reais — e um cliente não tem como
distinguir "verificamos e está livre" de uma seção que nunca existiu.
"""
from __future__ import annotations

from .base_imob import SubradarImobSource, sem_cobertura

_MOTIVO_ONR = (
    "titularidade e ônus por matrícula só são obtidos via ONR "
    "(registrodeimoveis.org.br), consulta paga ainda não contratada"
)


class CNPJCNJImobConnector(SubradarImobSource):
    """Titularidade do imóvel."""
    fonte = "cnpj_cnj_registros"

    def consultar_imovel(self, matricula: str, cartorio_id: str | None = None, **_) -> dict:
        return sem_cobertura(
            self.fonte, "titularidade", "Titularidade e Propriedade", _MOTIVO_ONR,
            {"matricula": matricula, "cartorio_id": cartorio_id, "requer": "contrato ONR"},
        )


class OususReaisConnector(SubradarImobSource):
    """Ônus reais: hipoteca, alienação fiduciária, penhora, servidão."""
    fonte = "onus_reais"

    def consultar_imovel(self, matricula: str, cartorio_id: str | None = None, **_) -> dict:
        return sem_cobertura(
            self.fonte, "onus_reais", "Ônus Reais", _MOTIVO_ONR,
            {"matricula": matricula, "cartorio_id": cartorio_id, "requer": "contrato ONR"},
        )
