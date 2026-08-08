"""
API HTTP wrapper para Subradar PF runner.
Permite que Edge Functions do Supabase chamem o runner via HTTP.

Uso:
  python3 -m ingestao.subradar.runner_pf_api --port 8000

Endpoint:
  POST /consulta
  Body: {"cpf": "123.456.789-00", "nome": "João Silva", "cliente_id": "..."}
  Response: {
    "sucesso": true,
    "score": 25,
    "faixa": "VERDE",
    "total_alertas": 0,
    "mensagem": "Consulta concluída com sucesso"
  }
"""
from __future__ import annotations

import json
import logging
import re
import sys
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import uuid as _uuid

# Imports do runner_pf
from .runner_pf import (
    processar_cpf,
    calcular_score_risco,
    FONTES_PF,
    _strip,
    _fmt_cpf,
)
from .base import upsert, _ciclo_atual, SUPABASE_URL, SUPABASE_KEY

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("subradar.runner_pf_api")


class ConsultaHandler(BaseHTTPRequestHandler):
    """Handler HTTP para requisições de consulta PF."""

    def do_POST(self):
        """POST /consulta — executa runner PF e retorna resultado."""
        if self.path != "/consulta":
            self.send_error(404)
            return

        try:
            content_length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(content_length).decode("utf-8")
            payload = json.loads(body)
        except Exception as e:
            self.send_json(400, {"erro": f"JSON inválido: {e}"})
            return

        cpf = payload.get("cpf", "").strip()
        nome = payload.get("nome", "").strip()
        cliente_id = payload.get("cliente_id", str(_uuid.uuid4()))

        cpf_digits = _strip(cpf)
        if len(cpf_digits) != 11:
            self.send_json(400, {"erro": "CPF inválido"})
            return

        cpf_fmt = _fmt_cpf(cpf_digits)
        logger.info("Consulta PF iniciada: %s", cpf_fmt)

        try:
            # Executa runner
            alertas = processar_cpf(
                cpf=cpf_digits,
                cliente_id=cliente_id,
                nome=nome,
                dry_run=False,
                avulsa=False,
            )

            # Calcula score
            score_data = calcular_score_risco(alertas)

            # Se chegou aqui, foi gravado no Supabase
            self.send_json(200, {
                "sucesso": True,
                "cpf": cpf_fmt,
                "score": score_data["score"],
                "faixa": score_data["faixa"],
                "descricao": score_data["descricao"],
                "total_alertas": score_data["total_alertas"],
                "criticos": score_data["criticos"],
                "atencao": score_data["atencao"],
                "mensagem": "Consulta concluída com sucesso",
            })
            logger.info("Consulta %s concluída: score=%d [%s]",
                       cpf_fmt, score_data["score"], score_data["faixa"])

        except Exception as e:
            logger.error("Erro ao processar %s: %s", cpf_fmt, e)
            self.send_json(500, {
                "sucesso": False,
                "erro": str(e),
                "mensagem": "Erro ao processar consulta",
            })

    def do_OPTIONS(self):
        """OPTIONS — responde CORS."""
        self.send_response(200)
        self._set_cors_headers()
        self.end_headers()

    def send_json(self, status_code: int, data: dict) -> None:
        """Envia resposta JSON com CORS."""
        self.send_response(status_code)
        self._set_cors_headers()
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(data).encode("utf-8"))

    def _set_cors_headers(self):
        """Adiciona headers CORS."""
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def log_message(self, format, *args):
        """Suprime logs padrão do servidor."""
        pass


def main(port: int = 8000):
    """Inicia servidor HTTP."""
    server = HTTPServer(("127.0.0.1", port), ConsultaHandler)
    logger.info("Servidor Subradar PF API escutando em http://127.0.0.1:%d", port)
    logger.info("Endpoint: POST /consulta")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        logger.info("Servidor parado.")


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="API HTTP para Subradar PF")
    parser.add_argument("--port", type=int, default=8000, help="Porta do servidor")
    args = parser.parse_args()
    main(args.port)
