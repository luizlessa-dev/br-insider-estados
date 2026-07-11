"""
ALES — Assembleia Legislativa do Estado do Espírito Santo
Site ASP.NET (al.es.gov.br). Cobertura de atividade legislativa nos dados
abertos é PARCIAL — só deputados de forma limpa.

Verificado live 2026-05-31:
  Deputados   : GET https://www.al.es.gov.br/DadosAbertos/ParlamentaresData
                → JSON [{nmPolitico, tx_partido_sigla, dsEmailDeputado,
                  dsTelefoneDeputado}] (~30). Limpo. Sem id estável → slug do nome.
  Proposições : só via busca ASP.NET WebForms em /Proposicao (__VIEWSTATE/
                __EVENTVALIDATION + postback paginado). NÃO há dataset/JSON.
                DEFERIDO (scraping de postback é frágil e custoso).
  Votações    : NÃO publicadas em dados abertos (sem dataset, sem página).
                api.al.es.gov.br é um nginx default vazio. → vazio.

Decisão (com Luiz): implementar só deputados agora; proposições/votações ficam
como débito documentado.
"""
from __future__ import annotations

import atexit
import re
import tempfile
import unicodedata
from datetime import date
from pathlib import Path

import certifi

from ..base_connector import BaseConnector
from ..models import Deputado, Proposicao, Votacao


PARLAMENTARES_URL = "https://www.al.es.gov.br/DadosAbertos/ParlamentaresData"

# www.al.es.gov.br serve só o certificado folha (CN=*.al.es.gov.br), sem o
# intermediário "Go Daddy Secure Certificate Authority - G2" — cadeia
# incompleta que faz requests/certifi falhar com CERTIFICATE_VERIFY_FAILED
# (curl/navegadores passam porque fazem AIA fetch automático do
# intermediário; urllib3 não faz). Intermediário baixado uma vez via AIA
# URI do próprio certificado leaf (certificates.godaddy.com/repository/
# gdig2.crt), válido até 2031.
_GODADDY_G2_INTERMEDIATE = Path(__file__).parent.parent / "certs" / "godaddy_g2_intermediate.pem"


def _ca_bundle_path() -> str:
    """Concatena o bundle do certifi (root da GoDaddy) + o intermediário
    faltante num arquivo temporário — gerado uma vez por processo, não
    persistido no repo pra não desalinhar do certifi quando ele atualizar."""
    combined = tempfile.NamedTemporaryFile(
        mode="w", suffix=".pem", prefix="ales-ca-bundle-", delete=False
    )
    combined.write(Path(certifi.where()).read_text())
    combined.write("\n")
    combined.write(_GODADDY_G2_INTERMEDIATE.read_text())
    combined.close()
    atexit.register(lambda: Path(combined.name).unlink(missing_ok=True))
    return combined.name


_CA_BUNDLE_PATH = _ca_bundle_path()


def _slug(t: str) -> str:
    s = unicodedata.normalize("NFD", (t or "").lower()).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]+", "-", s).strip("-")


class ALESConnector(BaseConnector):
    assembly_id = "ales"
    assembly_name = "Assembleia Legislativa do Espírito Santo"
    uf = "ES"
    base_url = "https://www.al.es.gov.br"

    request_delay = 0.5

    def __init__(self) -> None:
        super().__init__()
        # Ver comentário de _CA_BUNDLE_PATH: o host não serve o intermediário
        # da cadeia, então o bundle padrão do certifi sozinho não valida.
        self.session.verify = _CA_BUNDLE_PATH

    # ── Deputados (JSON limpo) ────────────────────────────────────────────
    def get_deputados(self) -> list[Deputado]:
        data = self._get(PARLAMENTARES_URL)
        itens = data if isinstance(data, list) else data.get("data", [])
        deputados: list[Deputado] = []
        for d in itens:
            nome = (d.get("nmPolitico") or "").strip()
            if not nome:
                continue
            deputados.append(Deputado(
                id=self._prefix_id(_slug(nome)),   # API não traz id estável
                nome=nome,
                partido=(d.get("tx_partido_sigla") or "").strip(),
                uf="ES",
                assembly_id=self.assembly_id,
                email=(d.get("dsEmailDeputado") or "").strip() or None,
                telefone=(d.get("dsTelefoneDeputado") or "").strip() or None,
                raw=d,
            ))
        self.logger.info("ALES: %d deputados carregados", len(deputados))
        return deputados

    # ── Proposições: WebForms postback (deferido) ─────────────────────────
    def get_proposicoes(self, data_inicio: date, data_fim: date) -> list[Proposicao]:
        self.logger.info(
            "ALES: proposições só via busca WebForms (/Proposicao, postback) — deferido. Vazio."
        )
        return []

    # ── Votações: não publicadas ──────────────────────────────────────────
    def get_votacoes(self, data_inicio: date, data_fim: date) -> list[Votacao]:
        self.logger.info("ALES: votações não disponíveis em dados abertos — vazio.")
        return []

    def health_check(self) -> bool:
        try:
            return self.session.get(PARLAMENTARES_URL, timeout=15).status_code < 400
        except Exception:
            return False
