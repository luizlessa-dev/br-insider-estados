"""Cliente Supabase compartilhado para os módulos do dossiê."""
from __future__ import annotations

import os
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry


def build_session() -> requests.Session:
    session = requests.Session()
    retry = Retry(total=3, backoff_factor=1.0, status_forcelist=[429, 500, 502, 503])
    session.mount("https://", HTTPAdapter(max_retries=retry))
    return session


class SupabaseClient:
    def __init__(self, url: str | None = None, key: str | None = None) -> None:
        self.url = (url or os.environ.get("SUPABASE_URL") or "").rstrip("/")
        self.key = (
            key
            or os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
            or os.environ.get("INTERNAL_SUPABASE_SERVICE_ROLE_KEY")
            or ""
        )
        if not self.url or not self.key:
            raise RuntimeError("SUPABASE_URL e/ou SUPABASE_SERVICE_ROLE_KEY ausentes.")
        self.session = build_session()
        self.session.headers.update({
            "apikey": self.key,
            "Authorization": f"Bearer {self.key}",
            "Content-Type": "application/json",
        })

    @classmethod
    def from_env(cls) -> "SupabaseClient":
        return cls()

    def get(self, table_or_view: str, params: dict, limit: int = 1000) -> list[dict]:
        """GET simples com paginação automática até `limit` registros."""
        results: list[dict] = []
        page_size = min(1000, limit)
        offset = 0
        while len(results) < limit:
            p = {**params, "limit": page_size, "offset": offset}
            resp = self.session.get(
                f"{self.url}/rest/v1/{table_or_view}",
                params=p,
                headers={"Prefer": "count=exact"},
                timeout=30,
            )
            resp.raise_for_status()
            batch = resp.json()
            if not batch:
                break
            results.extend(batch)
            if len(batch) < page_size:
                break
            offset += page_size
        return results[:limit]

    def get_all(self, table_or_view: str, params: dict) -> list[dict]:
        """Busca todas as páginas sem limite."""
        return self.get(table_or_view, params, limit=100_000)
