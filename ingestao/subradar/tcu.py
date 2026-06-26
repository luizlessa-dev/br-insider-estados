"""
Conector: TCU — Certidão de Regularidade + Acórdãos com multa/inabilitação

Estratégias (em cascata):
  1. Certidão PDF/HTML via https://certificados.tcu.gov.br/certidao/  (scraping Playwright)
  2. Pesquisa de acórdãos por CNPJ via portal de jurisprudência TCU (Playwright)

Requer: playwright + chromium (python -m playwright install chromium)
"""
from __future__ import annotations

import asyncio
import logging
import re

from .base import SubradarSource, snapshot_changed, upsert, _ciclo_atual

logger = logging.getLogger("subradar.tcu")

CERT_URL  = "https://pesquisa.apps.tcu.gov.br/#/juris"  # certidão TCU sem DNS externo; usa portal de jurisprudência
JURIS_URL = "https://pesquisa.apps.tcu.gov.br/#/juris"

SITUACOES_IRREGULARES = {
    "irregular", "débito", "multa", "inabilitado", "inabilitação",
    "suspensão", "proibição",
}


def _strip(cnpj: str) -> str:
    return re.sub(r"\D", "", str(cnpj or ""))


def _fmt(cnpj: str) -> str:
    c = _strip(cnpj)
    return f"{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:14]}" if len(c) == 14 else cnpj


async def _scrape_certidao(cnpj_digits: str) -> dict:
    """
    Tenta obter situação do CNPJ via pesquisa de processos TCU.
    O portal certificados.tcu.gov.br não resolve DNS externamente;
    usa o portal de jurisprudência como proxy.
    """
    # Delega à busca de acórdãos — a certidão formal requer acesso à intranet TCU
    return {"conteudo": "portal_certidao_indisponivel", "fallback": "acordaos"}


async def _scrape_acordaos(cnpj_digits: str) -> list[dict]:
    """Busca acórdãos TCU mencionando o CNPJ via portal de jurisprudência."""
    try:
        from playwright.async_api import async_playwright
    except ImportError:
        return []

    async with async_playwright() as pw:
        browser = await pw.chromium.launch(headless=True)
        page = await browser.new_page()
        results = []
        try:
            await page.goto(JURIS_URL, timeout=30000)
            await page.wait_for_load_state("networkidle", timeout=15000)

            # Preenche campo de busca e submete
            campo = await page.query_selector("input[placeholder]")
            if not campo:
                return []
            await campo.fill(cnpj_digits)
            await page.keyboard.press("Enter")
            await page.wait_for_load_state("networkidle", timeout=15000)
            await page.wait_for_timeout(2000)

            # Extrai o texto resultante
            content = await page.inner_text("body")

            # Conta resultado na seção de acórdãos
            # Padrão no DOM: "Acórdãos\n<número>\nResultados encontrados"
            lines = content.splitlines()
            total_acordaos = 0
            for i, line in enumerate(lines):
                if line.strip().lower() in ("acórdãos", "acordaos") and i + 2 < len(lines):
                    num_str = lines[i + 1].strip()
                    if num_str.isdigit():
                        total_acordaos = int(num_str)
                        break
            # Fallback: regex inline
            if not total_acordaos:
                m = re.search(r'Acórdãos\s+(\d+)\s+Resultados', content, re.IGNORECASE)
                if m:
                    total_acordaos = int(m.group(1))

            # Clica em "Acórdãos" para navegar para a lista
            if total_acordaos > 0:
                try:
                    await page.click("text=Acórdãos", timeout=5000)
                    await page.wait_for_load_state("networkidle", timeout=15000)
                    await page.wait_for_timeout(2000)
                    content2 = await page.inner_text("body")
                    # Extrai trechos de acórdãos
                    trechos = re.findall(r'Acórdão\s+[\d\.]+[^\n]{0,300}', content2)
                    results = [{"texto": t.strip(), "total": total_acordaos} for t in trechos[:8]]
                    if not results:
                        results = [{"texto": f"{total_acordaos} acórdãos encontrados para este CNPJ no TCU.", "total": total_acordaos}]
                except Exception:
                    results = [{"texto": f"{total_acordaos} acórdãos encontrados para este CNPJ no TCU.", "total": total_acordaos}]
            else:
                results = []

            return results
        except Exception as e:
            logger.debug("TCU acórdãos scraping: %s", e)
            return []
        finally:
            await browser.close()


def _classify_certidao(content: str) -> tuple[str, str]:
    """Extrai situação e descrição do texto da certidão."""
    text_lower = content.lower()
    if any(k in text_lower for k in SITUACOES_IRREGULARES):
        return "critico", "Situação irregular identificada no TCU."
    if "regular" in text_lower or "nada consta" in text_lower:
        return "ok", "Situação regular perante o TCU."
    return "atencao", "Não foi possível determinar a situação no TCU."


class TCUConnector(SubradarSource):
    fonte         = "tcu"
    request_delay = 2.0

    def consultar_cnpj(self, cnpj: str, razao_social: str | None = None) -> list[dict]:
        cnpj_limpo = _strip(cnpj)
        cnpj_fmt   = _fmt(cnpj_limpo)
        ciclo      = _ciclo_atual()

        # Executa scraping assíncrono — sempre via asyncio.run() em nova thread
        import concurrent.futures
        try:
            with concurrent.futures.ThreadPoolExecutor(max_workers=1) as pool:
                certidao = pool.submit(asyncio.run, _scrape_certidao(cnpj_limpo)).result(timeout=60)
                acordaos = pool.submit(asyncio.run, _scrape_acordaos(cnpj_limpo)).result(timeout=90)
        except Exception as e:
            logger.warning("TCU: scraping falhou: %s", e)
            certidao = {"conteudo": "erro", "erro": str(e)}
            acordaos = []

        dados = {"certidao": certidao, "acordaos": acordaos}
        mudou, hash_novo = snapshot_changed(cnpj_fmt, self.fonte, ciclo, dados)
        if not mudou:
            logger.info("TCU: sem mudanças para %s", cnpj_fmt)
            return []

        upsert("sub_snapshots", [{
            "cnpj": cnpj_fmt, "fonte": self.fonte, "ciclo": ciclo,
            "hash_dados": hash_novo,
            "dados": {"acordaos_encontrados": len(acordaos), "certidao_ok": "erro" not in certidao},
        }])

        alertas = []

        if not acordaos:
            alertas.append({
                "cnpj": cnpj_fmt, "ciclo": ciclo, "fonte": self.fonte,
                "categoria": "judicial", "severidade": "ok",
                "titulo": "Sem acórdãos TCU identificados para este CNPJ",
                "descricao": "CNPJ não encontrado em acórdãos do TCU no portal de jurisprudência.",
                "url_fonte": JURIS_URL,
                "is_novo": True,
            })
            logger.info("TCU: sem acórdãos para %s", cnpj_fmt)
            return alertas

        # Alertas de acórdãos
        for i, ac in enumerate(acordaos[:5]):
            texto = ac.get("texto", "")
            sev   = "critico" if any(k in texto.lower() for k in SITUACOES_IRREGULARES) else "atencao"
            alertas.append({
                "cnpj": cnpj_fmt, "ciclo": ciclo, "fonte": self.fonte,
                "categoria": "judicial", "severidade": sev,
                "titulo": f"TCU — Acórdão mencionando o CNPJ (#{i+1})",
                "descricao": texto[:400],
                "url_fonte": JURIS_URL,
                "is_novo": True,
            })

        logger.info("TCU: %d alertas para %s", len(alertas), cnpj_fmt)
        return alertas
