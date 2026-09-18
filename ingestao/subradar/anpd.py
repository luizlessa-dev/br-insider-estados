"""
Conector: ANPD — Processos Administrativos Sancionadores por descumprimento da LGPD

Estratégia: seed mensal (XLSX oficial + HTML + PDF) → tabela local sub_anpd.
Filtro por CNPJ feito localmente.

Seed: python -m ingestao.subradar.anpd_seeder
Tabela: sub_anpd
Frequência: mensal

Severidade (regra combinada — task original só previa "em andamento" x
"concluído com sanção pecuniária/publicização" x "arquivado", mas dados
reais têm um terceiro caso intermediário: concluído com sanção não-
pecuniária como Advertência, ex. Secretaria de Educação do DF):
  - Em andamento (sem decisão)                              → atencao
  - Concluído + multa > 0 OU sanção inclui "publicização"    → critico
  - Concluído + alguma sanção aplicada, sem multa/publiciz.  → atencao
  - Concluído sem nenhuma sanção (arquivado)                 → info
"""
from __future__ import annotations

import logging
import re

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual, exigir_tabela_populada

logger = logging.getLogger("subradar.anpd")

SUPABASE_URL = __import__("os").environ.get("SUPABASE_URL", "").rstrip("/")
SUPABASE_KEY = (
    __import__("os").environ.get("SUPABASE_SERVICE_ROLE_KEY")
    or __import__("os").environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY")
    or ""
)

URL_FISCALIZACAO = "https://www.gov.br/anpd/pt-br/assuntos/fiscalizacao"


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", cnpj or "")


def _fmt(cnpj: str) -> str:
    c = _strip(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


def _query_local(cnpj_digits: str) -> list[dict]:
    if not SUPABASE_URL or not SUPABASE_KEY:
        return []
    import requests as req
    r = req.get(
        f"{SUPABASE_URL}/rest/v1/sub_anpd",
        params={"cnpj_cpf": f"eq.{cnpj_digits}"},
        headers={
            "apikey": SUPABASE_KEY,
            "Authorization": f"Bearer {SUPABASE_KEY}",
            "Accept": "application/json",
        },
        timeout=15,
    )
    return r.json() if r.ok and isinstance(r.json(), list) else []


def _severidade(reg: dict) -> str:
    fase = (reg.get("des_fase") or "").strip().lower()
    if fase != "concluído":
        return "atencao"  # em andamento, sem decisão — não é achado, é vigilância

    conduta = (reg.get("conduta_apurada") or "").lower()
    val_multa = reg.get("val_multa")
    tem_multa = isinstance(val_multa, (int, float)) and val_multa > 0
    tem_publicizacao = "publicização" in conduta or "publicizacao" in conduta

    if tem_multa or tem_publicizacao:
        return "critico"
    if "sanção aplicada" in conduta or "sancao aplicada" in conduta:
        return "atencao"  # houve sanção (ex.: advertência), mas não pecuniária/publicização
    return "info"  # concluído sem nenhuma sanção — arquivado


def _parse_date(s) -> str | None:
    if not s:
        return None
    s = str(s).strip()
    if re.match(r"^\d{4}-\d{2}-\d{2}$", s):
        return s
    for fmt in ("%d/%m/%Y",):
        try:
            from datetime import datetime
            return datetime.strptime(s, fmt).date().isoformat()
        except ValueError:
            continue
    return None


class ANPDConnector(SubradarSource):
    fonte = "anpd"

    def consultar_cnpj(self, cnpj: str, razao_social: str | None = None) -> list[dict]:
        cnpj_limpo = _strip(cnpj)
        cnpj_fmt   = _fmt(cnpj_limpo)
        ciclo      = _ciclo_atual()

        # Tabela vazia nao e "nada consta": e seed que nao rodou.
        exigir_tabela_populada("sub_anpd", "ANPD — Processos Administrativos Sancionadores")
        registros = _query_local(cnpj_limpo)

        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, registros)
        if not mudou:
            logger.info("ANPD: sem mudanças para %s", cnpj_fmt)
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt, "fonte": self.fonte, "ciclo": ciclo,
            "hash_dados": hash_novo, "dados": {"total": len(registros)},
        }])

        if not registros:
            return [{
                "cnpj": cnpj_fmt, "ciclo": ciclo, "fonte": self.fonte,
                "categoria": "lgpd", "severidade": "ok",
                "titulo": "Sem processos sancionadores na ANPD",
                "descricao": "CNPJ não encontrado na base de Processos Administrativos Sancionadores da ANPD por descumprimento da LGPD.",
                "url_fonte": URL_FISCALIZACAO,
                "is_novo": True,
            }]

        alertas = []
        for r in registros:
            num_processo = r.get("num_processo") or ""
            ente         = r.get("ente_fiscalizado") or razao_social or cnpj_fmt
            fase         = r.get("des_fase") or ""
            situacao     = r.get("des_situacao") or ""
            conduta      = r.get("conduta_apurada") or ""
            setor        = r.get("setor") or ""
            val_multa    = r.get("val_multa")
            dat_inst     = r.get("dat_instauracao") or ""
            dat_dec      = r.get("dat_decisao_final") or ""

            severidade = _severidade(r)

            multa_fmt = (
                f"R$ {float(val_multa):,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")
                if isinstance(val_multa, (int, float)) and val_multa > 0 else None
            )

            status_txt = situacao or fase
            descricao = (
                f"Processo {num_processo} ({fase}). {status_txt} "
                f"Conduta apurada: {conduta[:300] or 'não especificada'}. "
                f"Instaurado em {dat_inst or 'data não informada'}."
                + (f" Decisão em {dat_dec}." if dat_dec else "")
                + (f" Multa aplicada: {multa_fmt}." if multa_fmt else "")
            )

            alertas.append({
                "cnpj": cnpj_fmt, "ciclo": ciclo, "fonte": self.fonte,
                "categoria": "lgpd",
                "severidade": severidade,
                "titulo": f"ANPD — Processo Sancionador LGPD ({setor or 'ente'}) — {fase}",
                "descricao": descricao,
                "contraparte": ente,
                "referencia_id": num_processo,
                "data_evento": _parse_date(dat_dec) or _parse_date(dat_inst),
                "url_fonte": r.get("url_fonte") or URL_FISCALIZACAO,
                "is_novo": True,
            })

        logger.info("ANPD: %d alertas para %s", len(alertas), cnpj_fmt)
        return alertas
