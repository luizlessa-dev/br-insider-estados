"""
Upload de PDFs do Subradar para Supabase Storage.

Bucket: subradar
Caminho: pdfs/subradar_{cnpj_digits}_{ciclo_slug}.pdf

Requer que o bucket 'subradar' exista no Supabase com política de leitura privada.
"""
from __future__ import annotations

import logging
import os
from pathlib import Path

import requests

logger = logging.getLogger("subradar.pdf_upload")

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SUPABASE_KEY = (
    os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    or os.environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY")
    or ""
)
BUCKET = "subradar"


def _hdrs() -> dict:
    return {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
    }


def upload_pdf(pdf_path: str) -> str | None:
    """
    Faz upload do PDF para Supabase Storage.
    Retorna o storage_path em caso de sucesso, None em caso de falha.
    """
    if not SUPABASE_URL or not SUPABASE_KEY:
        logger.warning("pdf_upload: SUPABASE_URL/KEY não configurados — pulando upload")
        return None

    path = Path(pdf_path)
    if not path.exists():
        logger.error("pdf_upload: arquivo não encontrado: %s", pdf_path)
        return None

    storage_path = f"pdfs/{path.name}"
    url = f"{SUPABASE_URL}/storage/v1/object/{BUCKET}/{storage_path}"

    with open(pdf_path, "rb") as f:
        content = f.read()

    headers = {
        **_hdrs(),
        "Content-Type": "application/pdf",
        "x-upsert": "true",
    }

    try:
        r = requests.put(url, data=content, headers=headers, timeout=60)
        if r.ok:
            logger.info("pdf_upload: %s → Storage/%s (%d bytes)", path.name, storage_path, len(content))
            return storage_path
        logger.error("pdf_upload: HTTP %s ao fazer upload de %s: %s", r.status_code, path.name, r.text[:200])
        return None
    except Exception as e:
        logger.error("pdf_upload: erro ao fazer upload de %s: %s", path.name, e)
        return None
