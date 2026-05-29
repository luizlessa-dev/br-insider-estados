"""
ALESP — Assembleia Legislativa do Estado de São Paulo
Tier 1 — dados abertos via DUMPS BULK (sem filtro de data no servidor).

A ALESP não oferece API com query por período: publica arquivos completos sob
https://www.al.sp.gov.br/repositorioDados/. O conector baixa o dump e filtra
por data no cliente. Caminhos verificados em 2026-05-28 (HTTP 200):

  deputados/deputados.xml                              302 KB   [em exercício: Situacao=EXE]
  processo_legislativo/proposituras.zip                16 MB    (130 MB descomprimido)
  processo_legislativo/naturezasSpl.xml                14 KB    (lookup IdNatureza→sigla)
  processo_legislativo/comissoes_permanentes_votacoes.xml  67 MB
  processo_legislativo/comissoes_permanentes_reunioes.xml  2.9 MB (datas das reuniões)

ESCOPO DAS VOTAÇÕES: são votos de COMISSÕES PERMANENTES (nível deputado), não
votações de plenário. Cada Votacao agrupa votos por (IdReuniao, IdPauta); a data
vem do arquivo de reuniões via join. Plenário não está neste conjunto bulk.

CUSTO: get_votacoes baixa ~70 MB por execução (limitação da ALESP, não do
conector). Para janelas incrementais curtas isso é caro — considerar cron menos
frequente para votações que para deputados/proposições.
"""
from __future__ import annotations

import io
import zipfile
from datetime import date
from xml.etree import ElementTree as ET

from ..base_connector import BaseConnector, ConnectorError
from ..models import Deputado, Proposicao, Votacao, VotoDeputado


REPO = "https://www.al.sp.gov.br/repositorioDados"

# TipoVoto da ALESP → categoria canônica
_VOTO_MAP = {
    "F": "sim",          # Favorável
    "C": "não",          # Contrário
    "A": "abstenção",
    "B": "branco",
}


class ALESPConnector(BaseConnector):
    assembly_id = "alesp"
    assembly_name = "Assembleia Legislativa do Estado de São Paulo"
    uf = "SP"
    base_url = "https://www.al.sp.gov.br"

    # dumps grandes — timeout generoso
    timeout = 180
    request_delay = 1.0

    # ── Download helpers ──────────────────────────────────────────────────
    def _download(self, path: str) -> bytes:
        url = f"{REPO}/{path}"
        self._throttle()
        self.logger.info("ALESP: baixando %s", path)
        try:
            resp = self.session.get(url, timeout=self.timeout)
            resp.raise_for_status()
            return resp.content
        except Exception as e:
            raise ConnectorError(f"Falha ao baixar {url}: {e}") from e

    def _naturezas(self) -> dict[str, str]:
        """Mapa IdNatureza → sigla (fallback nome). Usado p/ tipo da proposição."""
        raw = self._download("processo_legislativo/naturezasSpl.xml")
        root = ET.fromstring(raw)
        mapa: dict[str, str] = {}
        for n in root:
            campos = {c.tag: (c.text or "").strip() for c in n}
            idn = campos.get("idNatureza")
            if idn:
                mapa[idn] = campos.get("sgNatureza") or campos.get("nmNatureza") or ""
        return mapa

    # ── Deputados ─────────────────────────────────────────────────────────
    def get_deputados(self) -> list[Deputado]:
        raw = self._download("deputados/deputados.xml")
        root = ET.fromstring(raw)
        deputados: list[Deputado] = []
        for dep in root.findall("Deputado"):
            c = {e.tag: (e.text or "").strip() for e in dep}
            # só mandato atual
            if c.get("Situacao") and c.get("Situacao") != "EXE":
                continue
            idd = c.get("IdDeputado")
            if not idd:
                continue
            deputados.append(Deputado(
                id=self._prefix_id(idd),
                nome=c.get("NomeParlamentar", ""),
                partido=c.get("Partido", ""),
                uf="SP",
                assembly_id=self.assembly_id,
                email=c.get("Email") or None,
                telefone=c.get("Telefone") or None,
                raw=c,
            ))
        self.logger.info("ALESP: %d deputados carregados", len(deputados))
        return deputados

    # ── Proposições ───────────────────────────────────────────────────────
    def get_proposicoes(self, data_inicio: date, data_fim: date) -> list[Proposicao]:
        naturezas = self._naturezas()
        raw = self._download("processo_legislativo/proposituras.zip")
        proposicoes: list[Proposicao] = []

        with zipfile.ZipFile(io.BytesIO(raw)) as z:
            nome = z.namelist()[0]
            with z.open(nome) as fp:
                for _, el in ET.iterparse(fp, events=("end",)):
                    if el.tag != "propositura":
                        continue
                    c = {ch.tag: (ch.text or "").strip() for ch in el}
                    el.clear()

                    dt = self.parse_date(c.get("DtPublicacao")) or self.parse_date(
                        c.get("DtEntradaSistema")
                    )
                    if dt and not (data_inicio <= dt <= data_fim):
                        continue
                    if not dt:  # sem data não dá pra situar na janela — pula
                        continue

                    iddoc = c.get("IdDocumento")
                    if not iddoc:
                        continue
                    ano = c.get("AnoLegislativo")
                    proposicoes.append(Proposicao(
                        id=self._prefix_id(iddoc),
                        numero=c.get("NroLegislativo", ""),
                        ano=int(ano) if ano and ano.isdigit() else data_inicio.year,
                        tipo=naturezas.get(c.get("IdNatureza", ""), c.get("IdNatureza", "")),
                        ementa=c.get("Ementa", ""),
                        assembly_id=self.assembly_id,
                        data_apresentacao=dt,
                        raw=c,
                    ))

        self.logger.info(
            "ALESP: %d proposições carregadas (%s → %s)",
            len(proposicoes), data_inicio, data_fim,
        )
        return proposicoes

    # ── Votações (comissões permanentes, join com reuniões p/ data) ───────
    def get_votacoes(self, data_inicio: date, data_fim: date) -> list[Votacao]:
        # 1) datas das reuniões: (IdReuniao, IdPauta) → date
        raw_reun = self._download("processo_legislativo/comissoes_permanentes_reunioes.xml")
        datas: dict[tuple[str, str], date | None] = {}
        for _, el in ET.iterparse(io.BytesIO(raw_reun), events=("end",)):
            if el.tag != "ReuniaoComissao":
                continue
            c = {ch.tag: (ch.text or "").strip() for ch in el}
            el.clear()
            key = (c.get("IdReuniao", ""), c.get("IdPauta", ""))
            datas[key] = self.parse_date(c.get("Data"))

        # 2) votos individuais agrupados por (IdReuniao, IdPauta)
        raw_vot = self._download("processo_legislativo/comissoes_permanentes_votacoes.xml")
        grupos: dict[tuple[str, str], dict] = {}
        for _, el in ET.iterparse(io.BytesIO(raw_vot), events=("end",)):
            if el.tag != "ReuniaoComissaoVotacao":
                continue
            c = {ch.tag: (ch.text or "").strip() for ch in el}
            el.clear()
            key = (c.get("IdReuniao", ""), c.get("IdPauta", ""))
            dt = datas.get(key)
            if not dt or not (data_inicio <= dt <= data_fim):
                continue
            g = grupos.setdefault(key, {
                "data": dt,
                "id_documento": c.get("IdDocumento", ""),
                "votos": [],
            })
            tipo = (c.get("TipoVoto") or "").strip().upper()
            g["votos"].append(VotoDeputado(
                deputado_id=self._prefix_id(c.get("IdDeputado", "")),
                deputado_nome=c.get("Deputado", ""),
                voto=_VOTO_MAP.get(tipo, (c.get("Voto") or "").strip().lower()),
            ))

        # 3) materializa Votacao
        votacoes: list[Votacao] = []
        for (id_reuniao, id_pauta), g in grupos.items():
            detalhes = g["votos"]
            votacoes.append(Votacao(
                id=self._prefix_id(f"{id_reuniao}_{id_pauta}"),
                proposicao_id=self._prefix_id(g["id_documento"]) if g["id_documento"] else "",
                assembly_id=self.assembly_id,
                data=g["data"],
                resultado=None,  # ALESP não publica resultado agregado da comissão
                votos_sim=sum(1 for v in detalhes if v.voto == "sim"),
                votos_nao=sum(1 for v in detalhes if v.voto in ("não", "nao")),
                votos_abstencao=sum(1 for v in detalhes if v.voto == "abstenção"),
                detalhes=detalhes,
                raw={"id_reuniao": id_reuniao, "id_pauta": id_pauta},
            ))

        self.logger.info("ALESP: %d votações carregadas", len(votacoes))
        return votacoes

    # ── Health check: dump de deputados é leve e estável ──────────────────
    def health_check(self) -> bool:
        try:
            resp = self.session.head(f"{REPO}/deputados/deputados.xml", timeout=15)
            return resp.status_code < 400
        except Exception as e:
            self.logger.warning("health_check erro: %s", e)
            return False
