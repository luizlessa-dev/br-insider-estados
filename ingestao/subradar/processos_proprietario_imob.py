"""
Processos judiciais do proprietário — fonte judicial do Subradar Imob.

Por que não é o Datajud: a API pública do CNJ não indexa as partes do processo.
Sondagem em 27/08/2026 no índice `api_publica_tjsp` — os campos disponíveis no
`_source` são @timestamp, assuntos, classe, dataAjuizamento,
dataHoraUltimaAtualizacao, formato, grau, id, movimentos, nivelSigilo,
numeroProcesso, orgaoJulgador, sistema e tribunal. Não há nome nem CPF/CNPJ de
parte. Busca textual por "PETROBRAS" ou pelo CNPJ devolve 0 resultados, enquanto
a mesma busca por um `numeroProcesso` conhecido devolve 2 — ou seja, a busca
funciona, o dado de parte é que não existe. Ver `datajud_imob.py`.

Aqui a consulta é feita pelo CPF/CNPJ do proprietário no BigDataCorp, dataset
`processes` (bloco `Processes`), o mesmo já em produção no Subradar PF.
"""
from __future__ import annotations

import re

from .base_imob import SubradarImobSource, pendencia, limpo, sem_cobertura
from .bigdatacorp_negativacoes import (
    _post_bdc,
    _BASE_PESSOAS,
    _BASE_EMPRESAS,
    _DS_PROCESS,
    BDC_TOKEN_ID,
    BDC_ACCESS_TOKEN,
)

TITULO = "Ações Judiciais do Proprietário"

# Assuntos/classes que tocam diretamente o imóvel. Um processo do proprietário
# que não é imobiliário ainda importa (risco de fraude à execução), mas estes
# pesam mais.
_TERMOS_IMOBILIARIOS = (
    "usucapi", "reintegra", "reivindicat", "despejo", "possess", "posse",
    "hipotec", "aliena", "penhor", "adjudica", "imissao", "imóvel", "imovel",
    "condomin", "locac", "locaç", "arremat", "execucao fiscal", "execução fiscal",
    "iptu",
)


def _consultar_bdc(doc_digits: str) -> tuple[str, dict]:
    """Devolve (estado, bloco de processos) com estado em ok|falha|fora_do_plano.

    Sem essa distinção, token recusado e "nada consta" seriam indistinguíveis —
    que é como o laudo PF passou a afirmar ausência de processos para quem tinha
    oito.

    O mesmo dataset `processes` devolve o bloco com nomes diferentes conforme o
    endpoint: `Processes` em /pessoas e `Lawsuits` em /empresas. O conteúdo
    interno é idêntico (Lawsuits, TotalLawsuits, TotalLawsuitsAsDefendant...).
    Ler só "Processes" fazia todo CNPJ cair em bloco vazio — e bloco vazio
    viraria "nenhum processo encontrado". Verificado em 27/08/2026 com o CNPJ
    da Petrobras, que devolve processos.

    O timeout é generoso porque /empresas passa dos 30s padrão com frequência.
    """
    if not BDC_TOKEN_ID or not BDC_ACCESS_TOKEN:
        return "falha", {}
    if len(doc_digits) == 11:
        base, chave = _BASE_PESSOAS, "Processes"
    else:
        base, chave = _BASE_EMPRESAS, "Lawsuits"

    result = _post_bdc(base, _DS_PROCESS, doc_digits, timeout=120)
    if result is None:
        return "falha", {}
    bloco = result.get(chave) or {}
    if isinstance(bloco, dict) and (bloco.get("Code") or bloco.get("code")) == -109:
        return "fora_do_plano", {}
    return "ok", bloco


def _e_imobiliario(lw: dict) -> bool:
    texto = " ".join(str(lw.get(k) or "") for k in
                     ("Type", "MainSubject", "InferredCNJSubjectName", "CourtType")).lower()
    return any(t in texto for t in _TERMOS_IMOBILIARIOS)


class ProcessosProprietarioImobConnector(SubradarImobSource):
    """Processos judiciais em nome do proprietário do imóvel (BigDataCorp)."""

    fonte = "processos_proprietario"
    request_delay = 1.0

    def consultar_imovel(
        self, matricula: str, cartorio_id: str | None = None,
        proprietario_cpf_cnpj: str | None = None, **_,
    ) -> dict:
        doc = re.sub(r"\D", "", str(proprietario_cpf_cnpj or ""))

        if not doc:
            # Sem proprietário não há o que consultar. Isso é uma lacuna do
            # pedido, não uma falha da fonte — mas o laudo não pode dizer
            # "nenhum processo": tem de dizer que não deu para olhar.
            return pendencia(
                self.fonte, "judicial", TITULO,
                "CPF/CNPJ do proprietário não informado no pedido",
            )

        if len(doc) not in (11, 14):
            return pendencia(
                self.fonte, "judicial", TITULO,
                f"CPF/CNPJ do proprietário inválido ({len(doc)} dígitos)",
            )

        estado, bloco = _consultar_bdc(doc)
        if estado == "falha":
            return pendencia(self.fonte, "judicial", TITULO,
                             "BigDataCorp não respondeu ou recusou o token")
        if estado == "fora_do_plano":
            return sem_cobertura(self.fonte, "judicial", TITULO,
                                 "dataset de processos fora do plano contratado")

        lawsuits = bloco.get("Lawsuits") or []
        total = bloco.get("TotalLawsuits") or len(lawsuits)

        if not total:
            return limpo(
                self.fonte, "judicial", TITULO,
                "Nenhum processo judicial encontrado em nome do proprietário.",
                {"proprietario": doc, "total": 0, "fonte_dados": "BigDataCorp/processes"},
            )

        imobiliarios = [lw for lw in lawsuits if _e_imobiliario(lw)]
        como_reu = bloco.get("TotalLawsuitsAsDefendant") or 0

        partes = [f"{total} processo(s) em nome do proprietário"]
        if como_reu:
            partes.append(f"{como_reu} como réu(ré)")
        if imobiliarios:
            partes.append(f"{len(imobiliarios)} com objeto imobiliário")

        return {
            "fonte": self.fonte,
            "categoria": "judicial",
            "status": "critico" if imobiliarios else "alerta",
            "titulo_secao": f"{TITULO} ({total})",
            "resumo": " · ".join(partes) + ".",
            "detalhes": {
                "proprietario": doc,
                "total": total,
                "total_como_reu": como_reu,
                "fonte_dados": "BigDataCorp/processes",
                "processos": [
                    {
                        "numero": lw.get("Number"),
                        "tipo": lw.get("Type"),
                        "assunto": lw.get("InferredCNJSubjectName") or lw.get("MainSubject"),
                        "tribunal": lw.get("CourtName"),
                        "uf": lw.get("State"),
                        "situacao": lw.get("Status"),
                        "valor": lw.get("Value"),
                        "ultima_movimentacao": (lw.get("LastMovementDate") or "")[:10] or None,
                        "imobiliario": _e_imobiliario(lw),
                    }
                    for lw in lawsuits[:50]
                ],
            },
        }
