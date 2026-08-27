"""Entrega do dossiê Subradar Imob: valida a completude e avisa o cliente.

Mesmo desenho de `entrega_pf.py`, mesma regra central: laudo com fonte pendente
não é entregue. Um dossiê de compliance imobiliário que diz "nada consta" numa
fonte que não respondeu vale menos que nenhum dossiê.

Quando há pendência a entrega é retida, o motivo fica em
`sub_imob_consultas.entrega_bloqueio` e o operador é avisado.

Diferença em relação ao PF: o entregável do Imob é a página do dossiê
(`/imob/dossie/<consulta_id>`), não um PDF anexo. A trava de completude é a
mesma; o que muda é o formato do que sai.

O fluxo antigo não tinha trava nenhuma. O passo "Notificar cliente por email"
do workflow rodava com `if: success()` — bastava o processo Python terminar com
código 0 para o e-mail sair, mesmo que nenhuma fonte tivesse respondido.
"""
from __future__ import annotations

import logging
import os
from datetime import date, datetime, timezone

import requests

logger = logging.getLogger("subradar.entrega_imob")

SB_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SB_KEY = (
    os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    or os.environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY")
    or ""
)
RESEND_KEY = os.environ.get("RESEND_API_KEY", "")
# `or` em vez do default do get: secret inexistente no GitHub Actions chega como
# string vazia, e "" passaria pelo default, deixando o remetente em branco.
REMETENTE = os.environ.get("SUBRADAR_FROM") or "retorno@subradar.com.br"
OPERADOR = os.environ.get("SUBRADAR_OPERADOR") or "luiz@lessalabs.com"
# subradar.com.br, confirmado nos alias do projeto na Vercel. O default herdado
# do send_dossie_imob_resend.py era subradar.dev, domínio que não resolve — o
# e-mail de entrega levava o cliente a um link morto.
BASE_SITE = (os.environ.get("SUBRADAR_BASE_URL") or "https://subradar.com.br").rstrip("/")

# Status que significam "esta fonte não respondeu". Laudo com qualquer um deles
# não vai para o cliente. `nao_contratada` fica de fora de propósito: é limite
# declarado de cobertura, não falha de apuração.
STATUS_INCOMPLETO = {"pendente", "erro"}


def _hdrs() -> dict:
    return {"apikey": SB_KEY, "Authorization": f"Bearer {SB_KEY}",
            "Content-Type": "application/json"}


def _get(tabela: str, params: dict) -> list:
    try:
        r = requests.get(f"{SB_URL}/rest/v1/{tabela}", headers=_hdrs(),
                         params=params, timeout=30)
        return r.json() if r.ok else []
    except Exception as e:
        logger.error("leitura de %s falhou: %s", tabela, e)
        return []


def _patch_consulta(consulta_id: str, campos: dict) -> None:
    try:
        requests.patch(
            f"{SB_URL}/rest/v1/sub_imob_consultas", headers=_hdrs(),
            params={"id": f"eq.{consulta_id}"}, json=campos, timeout=30,
        )
    except Exception as e:
        logger.error("patch da consulta %s falhou: %s", consulta_id, e)


def fontes_pendentes(matricula: str, ciclo: str) -> list[str]:
    """Seções que não puderam ser consultadas nesta apuração."""
    dados = _get("sub_imob_dados", {
        "matricula": f"eq.{matricula}", "ciclo": f"eq.{ciclo}",
        "select": "fonte,status,titulo_secao",
    })
    return [
        d.get("titulo_secao") or d.get("fonte")
        for d in dados
        if str(d.get("status") or "").strip().lower() in STATUS_INCOMPLETO
    ]


def _indicadores(matricula: str, ciclo: str) -> dict:
    dados = _get("sub_imob_dados", {
        "matricula": f"eq.{matricula}", "ciclo": f"eq.{ciclo}",
        "select": "fonte,status,titulo_secao",
    })
    res = _get("sub_imob_resultados", {
        "matricula": f"eq.{matricula}", "ciclo": f"eq.{ciclo}",
        "select": "score_risco,faixa_risco,total_criticos,total_alertas",
    })
    r = res[0] if res else {}
    consultadas = [d for d in dados if str(d.get("status") or "").lower()
                   in ("limpo", "alerta", "critico")]
    sem_cobertura = [d for d in dados if str(d.get("status") or "").lower()
                     in ("nao_contratada", "nao_aplicavel")]
    return {
        "score": r.get("score_risco", 0),
        "faixa": r.get("faixa_risco", "indeterminado"),
        "criticos": r.get("total_criticos", 0),
        "alertas": r.get("total_alertas", 0),
        "total_secoes": len(dados),
        "consultadas": len(consultadas),
        "sem_cobertura": [d.get("titulo_secao") or d.get("fonte") for d in sem_cobertura],
        "ciclo": ciclo,
        "today": date.today().strftime("%d/%m/%Y"),
    }


def _email_html(matricula: str, consulta_id: str, ind: dict) -> str:
    lacunas = "".join(f"<li>{s}</li>" for s in ind["sem_cobertura"])
    bloco_lacunas = (
        f"""<div style="background:#fff7ed;border:1px solid #fed7aa;padding:12px;
             border-radius:6px;margin-bottom:16px">
          <p style="margin:0 0 6px;font-weight:bold;color:#9a3412">
            Fora da cobertura desta apuração</p>
          <ul style="margin:0;padding-left:18px;color:#7c2d12;font-size:13px">{lacunas}</ul>
          <p style="margin:8px 0 0;font-size:12px;color:#9a3412">
            Estas seções não foram verificadas. A ausência de apontamento nelas
            não significa ausência de registro.</p>
        </div>"""
        if ind["sem_cobertura"] else ""
    )
    return f"""<!DOCTYPE html>
<html><head><title>Dossiê Subradar Imob</title></head>
<body style="font-family:system-ui,-apple-system,sans-serif;padding:20px;background:#f8fafc">
  <div style="max-width:600px;margin:auto;background:white;padding:20px;border-radius:8px">
    <h1 style="color:#0f172a;margin:0 0 16px">Subradar Imob — Dossiê de Compliance</h1>
    <div style="background:#f1f5f9;padding:12px;border-radius:6px;margin-bottom:16px">
      <p style="margin:4px 0"><strong>Matrícula:</strong> {matricula}</p>
      <p style="margin:4px 0"><strong>Score de Risco:</strong>
         <span style="font-size:24px;font-weight:bold">{ind['score']}</span>/100 ({ind['faixa']})</p>
      <p style="margin:4px 0"><strong>Seções consultadas:</strong>
         {ind['consultadas']} de {ind['total_secoes']}</p>
      <p style="margin:4px 0"><strong>Data:</strong> {ind['today']}</p>
    </div>
    {bloco_lacunas}
    <p><a href="{BASE_SITE}/imob/dossie/{consulta_id}"
       style="background:#2563eb;color:white;padding:12px 24px;border-radius:6px;
              text-decoration:none;display:inline-block">Ver dossiê completo</a></p>
    <p style="font-size:12px;color:#64748b;margin:16px 0 0">Dúvidas: {OPERADOR}</p>
  </div>
</body></html>"""


def _avisar_operador(assunto: str, corpo: str) -> None:
    if not RESEND_KEY:
        logger.error("Sem RESEND_API_KEY — operador não avisado: %s", assunto)
        return
    try:
        requests.post(
            "https://api.resend.com/emails",
            json={"from": REMETENTE, "to": OPERADOR, "subject": assunto,
                  "html": f"<pre style='font-family:monospace'>{corpo}</pre>"},
            headers={"Authorization": f"Bearer {RESEND_KEY}"}, timeout=30,
        )
    except Exception as e:
        logger.error("Falha ao avisar operador: %s", e)


def entregar(consulta_id: str, matricula: str, email_cliente: str,
             forcar: bool = False) -> dict:
    """Avisa o cliente que o dossiê está pronto, salvo se houver fonte pendente.

    `forcar=True` envia mesmo incompleto — use só em reenvio manual consciente.
    Devolve {"enviado": bool, "motivo": str, "indicadores": dict}.
    """
    ciclo = date.today().strftime("%Y-%m")

    pendentes = fontes_pendentes(matricula, ciclo)
    if pendentes and not forcar:
        motivo = "fonte(s) não consultada(s): " + "; ".join(pendentes)
        logger.warning("Entrega retida para %s — %s", consulta_id, motivo)
        _patch_consulta(consulta_id, {"status": "retida",
                                      "entrega_bloqueio": motivo[:500]})
        _avisar_operador(
            f"[Subradar Imob] Entrega retida — laudo incompleto ({len(pendentes)} fonte(s))",
            f"Consulta: {consulta_id}\nMatrícula: {matricula}\n"
            f"Cliente: {email_cliente}\n\nFontes que não responderam:\n  - "
            + "\n  - ".join(pendentes)
            + "\n\nO dossiê NÃO foi enviado. Destravar a fonte e reprocessar, ou "
              "reenviar com forcar=True se a lacuna for aceitável.",
        )
        return {"enviado": False, "motivo": motivo, "indicadores": {}}

    ind = _indicadores(matricula, ciclo)

    if not RESEND_KEY:
        _patch_consulta(consulta_id, {"entrega_bloqueio": "RESEND_API_KEY ausente"})
        return {"enviado": False, "motivo": "RESEND_API_KEY ausente", "indicadores": ind}

    resp = requests.post(
        "https://api.resend.com/emails",
        json={
            "from": REMETENTE,
            "to": email_cliente,
            "subject": f"Subradar Imob — {matricula} · Score {ind['score']} ({ind['faixa']})",
            "html": _email_html(matricula, consulta_id, ind),
        },
        headers={"Authorization": f"Bearer {RESEND_KEY}"}, timeout=60,
    )

    if not resp.ok:
        motivo = f"Resend HTTP {resp.status_code}: {resp.text[:200]}"
        logger.error("Falha no envio de %s — %s", consulta_id, motivo)
        _patch_consulta(consulta_id, {"entrega_bloqueio": motivo[:500]})
        _avisar_operador(f"[Subradar Imob] Falha no envio — {matricula}",
                         f"Consulta: {consulta_id}\n{motivo}")
        return {"enviado": False, "motivo": motivo, "indicadores": ind}

    _patch_consulta(consulta_id, {
        "entregue_em": datetime.now(timezone.utc).isoformat(),
        "entrega_bloqueio": None,
    })
    logger.info("Dossiê Imob entregue: %s (score %s)", email_cliente, ind["score"])
    return {"enviado": True, "motivo": "", "indicadores": ind}
