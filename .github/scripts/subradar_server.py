#!/usr/bin/env python3
"""
Subradar PF — Production-grade Flask API server.

Exposes HTTP endpoint for Lovable frontend to call.
Calls subradar_pf_api.py as subprocess.

Environment variables:
  - SUBRADAR_PORT: HTTP port (default: 5000)
  - SUBRADAR_HOST: Bind address (default: 0.0.0.0)
  - FLASK_ENV: development or production
  - SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, RESEND_API_KEY: passed to subradar_pf_api.py

Usage:
  python3 subradar_server.py
"""
import os
import sys
import json
import subprocess
import logging
import re
from datetime import datetime, timedelta
from pathlib import Path
from typing import Tuple, Dict, Any

from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(name)s] %(levelname)s: %(message)s"
)
logger = logging.getLogger(__name__)

# Configuration
PORT = int(os.environ.get("SUBRADAR_PORT", "5000"))
HOST = os.environ.get("SUBRADAR_HOST", "0.0.0.0")
FLASK_ENV = os.environ.get("FLASK_ENV", "production")
DEBUG = FLASK_ENV == "development"

# Paths
SCRIPT_DIR = Path(__file__).parent
API_SCRIPT = SCRIPT_DIR / "subradar_pf_api.py"

if not API_SCRIPT.exists():
    logger.error(f"API script not found: {API_SCRIPT}")
    sys.exit(1)

# Flask app
app = Flask(__name__)
CORS(app, resources={
    r"/api/*": {
        "origins": ["*"],
        "methods": ["GET", "POST", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization"]
    }
})

# Rate limiting: 10 requests per minute per IP
limiter = Limiter(
    app=app,
    key_func=get_remote_address,
    default_limits=["200 per day", "50 per hour"],
    storage_uri="memory://",
)

# Request cache to avoid duplicate processing
REQUEST_CACHE = {}
CACHE_TTL = 300  # 5 minutes


def cache_key(cpf: str, action: str) -> str:
    """Generate cache key"""
    return f"{cpf}:{action}"


def is_cached(key: str) -> bool:
    """Check if request result is cached"""
    if key not in REQUEST_CACHE:
        return False

    timestamp, _ = REQUEST_CACHE[key]
    if datetime.now() - timestamp > timedelta(seconds=CACHE_TTL):
        del REQUEST_CACHE[key]
        return False

    return True


def get_cached(key: str) -> Any:
    """Get cached result"""
    timestamp, result = REQUEST_CACHE[key]
    return result


def set_cached(key: str, result: Any):
    """Set cache result"""
    REQUEST_CACHE[key] = (datetime.now(), result)


def validate_request(data: Dict[str, Any]) -> Tuple[bool, str, Dict[str, Any]]:
    """
    Validate incoming request.

    Returns:
        (is_valid, error_message, normalized_data)
    """
    # Check required fields
    required_fields = ["cpf", "nome", "email", "action"]
    for field in required_fields:
        if field not in data:
            return False, f"Campo obrigatório ausente: {field}", {}

    cpf = (data.get("cpf") or "").strip()
    nome = (data.get("nome") or "").strip()
    email = (data.get("email") or "").strip()
    action = (data.get("action") or "").strip()

    # Validate CPF (11 digits)
    cpf_digits = re.sub(r"\D", "", cpf)
    if len(cpf_digits) != 11:
        return False, "CPF deve conter 11 dígitos", {}

    # Validate nome
    if not nome or len(nome) < 3:
        return False, "Nome deve ter no mínimo 3 caracteres", {}

    if len(nome) > 200:
        return False, "Nome deve ter no máximo 200 caracteres", {}

    # Validate email
    if "@" not in email or len(email) > 255:
        return False, "Email inválido", {}

    # Validate action
    if action not in ("send", "generate"):
        return False, f"Ação inválida: {action} (use 'send' ou 'generate')", {}

    return True, "", {
        "cpf": cpf_digits,
        "nome": nome,
        "email": email,
        "action": action,
    }


def call_api(cpf: str, nome: str, email: str, action: str) -> Tuple[int, Dict[str, Any]]:
    """
    Call subradar_pf_api.py as subprocess.

    Returns:
        (exit_code, response_dict)
    """
    try:
        logger.info(f"Calling API: cpf={cpf}, action={action}")

        # Prepare environment
        env = os.environ.copy()
        # Ensure required env vars are passed
        if "SUPABASE_URL" not in env or "SUPABASE_SERVICE_ROLE_KEY" not in env:
            return 1, {"error": "Supabase não configurado"}

        if action == "send" and "RESEND_API_KEY" not in env:
            return 1, {"error": "Resend não configurado"}

        # Call subprocess
        result = subprocess.run(
            ["python3", str(API_SCRIPT), cpf, nome, email, action],
            capture_output=True,
            text=True,
            timeout=60,
            env=env,
        )

        # Parse response
        try:
            response = json.loads(result.stdout)
        except json.JSONDecodeError:
            logger.error(f"Invalid JSON response: {result.stdout}")
            return 1, {"error": "Resposta inválida do servidor"}

        # Map subprocess exit code to HTTP status
        exit_code = result.returncode
        if exit_code == 0:
            return 200, response
        elif exit_code == 1:
            return 400, response  # Validation error
        elif exit_code == 2:
            return 503, response  # Data fetch error (service unavailable)
        elif exit_code == 3:
            return 500, response  # PDF generation error
        elif exit_code == 4:
            return 503, response  # Email send error
        else:
            return 500, {"error": f"Erro desconhecido (exit code {exit_code})"}

    except subprocess.TimeoutExpired:
        logger.error("API call timeout")
        return 504, {"error": "Timeout ao processar requisição"}
    except Exception as e:
        logger.error(f"Error calling API: {e}", exc_info=True)
        return 500, {"error": f"Erro ao processar: {str(e)}"}


@app.route("/", methods=["GET"])
def index():
    """Health check / info endpoint"""
    return jsonify({
        "service": "Subradar PF API",
        "version": "1.0.0",
        "status": "online",
        "endpoints": {
            "POST /api/subradar/dossiee": "Generate and send dossiê",
            "GET /health": "Health check",
        }
    })


@app.route("/health", methods=["GET"])
def health():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
    }), 200


@app.route("/api/subradar/dossiee", methods=["OPTIONS"])
def dossiee_options():
    """CORS preflight"""
    return "", 204


@app.route("/api/subradar/dossiee", methods=["POST"])
@limiter.limit("10 per minute")  # 10 requests per minute per IP
def dossiee():
    """
    Generate and send Subradar PF dossiê.

    Request body (JSON):
    {
        "cpf": "string (11 digits or formatted)",
        "nome": "string (full name)",
        "email": "string (email address)",
        "action": "send|generate"
    }

    Response (success, 200):
    {
        "success": true,
        "score": 42,
        "faixa": "MÉDIO",
        "message": "Dossiê enviado para email@example.com"
    }

    Response (generate, 200):
    {
        "success": true,
        "score": 42,
        "faixa": "MÉDIO",
        "pdf": "base64-encoded-pdf..."
    }

    Response (error):
    {
        "success": false,
        "error": "Error message"
    }
    """
    try:
        # Get request data
        data = request.get_json() or {}

        logger.info(f"Request from {request.remote_addr}: {data.get('cpf', 'unknown')}")

        # Validate
        is_valid, error_msg, normalized = validate_request(data)
        if not is_valid:
            logger.warning(f"Validation error: {error_msg}")
            return jsonify({
                "success": False,
                "error": error_msg,
            }), 400

        cpf = normalized["cpf"]
        nome = normalized["nome"]
        email = normalized["email"]
        action = normalized["action"]

        # Check cache
        cache_k = cache_key(cpf, action)
        if is_cached(cache_k):
            logger.info(f"Returning cached result for {cpf}")
            return jsonify(get_cached(cache_k)), 200

        # Call API
        status_code, response = call_api(cpf, nome, email, action)

        # Cache successful responses
        if status_code == 200:
            set_cached(cache_k, response)

        return jsonify(response), status_code

    except Exception as e:
        logger.error(f"Unexpected error: {e}", exc_info=True)
        return jsonify({
            "success": False,
            "error": "Erro interno do servidor",
        }), 500


@app.errorhandler(429)
def rate_limit_handler(e):
    """Handle rate limit"""
    return jsonify({
        "success": False,
        "error": "Muitas requisições. Tente novamente em alguns minutos.",
    }), 429


@app.errorhandler(404)
def not_found(e):
    """Handle 404"""
    return jsonify({
        "success": False,
        "error": "Endpoint não encontrado",
    }), 404


@app.errorhandler(500)
def internal_error(e):
    """Handle 500"""
    logger.error(f"Internal error: {e}", exc_info=True)
    return jsonify({
        "success": False,
        "error": "Erro interno do servidor",
    }), 500


def main():
    """Start Flask server"""
    logger.info(f"Starting Subradar PF API server on {HOST}:{PORT}")
    logger.info(f"Environment: {FLASK_ENV}")
    logger.info(f"API script: {API_SCRIPT}")

    try:
        app.run(
            host=HOST,
            port=PORT,
            debug=DEBUG,
            use_reloader=False,  # Disable reloader in production
        )
    except Exception as e:
        logger.error(f"Failed to start server: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
