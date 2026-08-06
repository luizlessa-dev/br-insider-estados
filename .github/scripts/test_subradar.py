#!/usr/bin/env python3
"""
Subradar PF — Comprehensive test suite.

Tests for:
- Input validation
- API endpoint behavior
- Rate limiting
- Caching
- Error handling

Usage:
  pytest test_subradar.py -v
  pytest test_subradar.py -v --cov=subradar_server --cov=subradar_pf_api
"""
import os
import json
import pytest
from unittest.mock import patch, MagicMock
from pathlib import Path

# Import Flask app and utilities
import sys
sys.path.insert(0, str(Path(__file__).parent))

from subradar_server import app, validate_request, cache_key, is_cached, set_cached, get_cached
from subradar_pf_api import (
    validate_cpf, validate_email, validate_nome, fmt_cpf,
    ValidationError, DataFetchError, PDFGenerationError, EmailSendError
)


# ============================================================================
# FIXTURES
# ============================================================================

@pytest.fixture
def client():
    """Flask test client"""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


@pytest.fixture
def valid_request_data():
    """Valid request payload"""
    return {
        "cpf": "12345678901",
        "nome": "João da Silva",
        "email": "joao@example.com",
        "action": "generate"
    }


@pytest.fixture
def mock_api_success():
    """Mock successful API response"""
    return {
        "success": True,
        "score": 42,
        "faixa": "MÉDIO",
        "message": "Dossiê enviado"
    }


@pytest.fixture
def mock_supabase_data():
    """Mock Supabase response"""
    return {
        "score": 42,
        "faixa": "MÉDIO",
        "alertas": [],
        "dados": [
            {
                "fonte": "cpf_situacao",
                "categoria": "cadastral",
                "status": "LIMPO",
                "titulo_secao": "CPF Situação",
                "resumo": "CPF regular",
                "detalhes": {}
            }
        ]
    }


# ============================================================================
# TESTS: Input Validation (subradar_pf_api.py)
# ============================================================================

class TestCPFValidation:
    """CPF validation tests"""

    def test_valid_cpf(self):
        """Valid 11-digit CPF"""
        result = validate_cpf("12345678901")
        assert result == "12345678901"

    def test_cpf_with_formatting(self):
        """CPF with XXX.XXX.XXX-XX format"""
        result = validate_cpf("123.456.789-01")
        assert result == "12345678901"

    def test_cpf_too_short(self):
        """CPF with less than 11 digits"""
        with pytest.raises(ValidationError) as exc:
            validate_cpf("1234567890")
        assert "11 dígitos" in str(exc.value)

    def test_cpf_too_long(self):
        """CPF with more than 11 digits"""
        with pytest.raises(ValidationError):
            validate_cpf("123456789012")

    def test_cpf_all_same_digits(self):
        """CPF with all same digits (invalid)"""
        with pytest.raises(ValidationError) as exc:
            validate_cpf("11111111111")
        assert "todos os dígitos" in str(exc.value)

    def test_cpf_non_numeric(self):
        """CPF with letters"""
        with pytest.raises(ValidationError):
            validate_cpf("1234567890a")

    def test_cpf_empty(self):
        """Empty CPF"""
        with pytest.raises(ValidationError):
            validate_cpf("")


class TestEmailValidation:
    """Email validation tests"""

    def test_valid_email(self):
        """Valid email"""
        result = validate_email("joao@example.com")
        assert result == "joao@example.com"

    def test_email_with_spaces(self):
        """Email with leading/trailing spaces"""
        result = validate_email("  joao@example.com  ")
        assert result == "joao@example.com"

    def test_email_missing_at(self):
        """Email without @"""
        with pytest.raises(ValidationError) as exc:
            validate_email("joaoexample.com")
        assert "Email inválido" in str(exc.value)

    def test_email_empty(self):
        """Empty email"""
        with pytest.raises(ValidationError):
            validate_email("")

    def test_email_too_long(self):
        """Email exceeding 255 characters"""
        long_email = "a" * 250 + "@example.com"
        with pytest.raises(ValidationError) as exc:
            validate_email(long_email)
        assert "muito longo" in str(exc.value)


class TestNomeValidation:
    """Name validation tests"""

    def test_valid_nome(self):
        """Valid name"""
        result = validate_nome("João da Silva")
        assert result == "João da Silva"

    def test_nome_with_spaces(self):
        """Name with leading/trailing spaces"""
        result = validate_nome("  João da Silva  ")
        assert result == "João da Silva"

    def test_nome_too_short(self):
        """Name with less than 3 characters"""
        with pytest.raises(ValidationError) as exc:
            validate_nome("Jo")
        assert "mínimo 3" in str(exc.value)

    def test_nome_empty(self):
        """Empty name"""
        with pytest.raises(ValidationError):
            validate_nome("")

    def test_nome_too_long(self):
        """Name exceeding 200 characters"""
        long_nome = "a" * 201
        with pytest.raises(ValidationError) as exc:
            validate_nome(long_nome)
        assert "muito longo" in str(exc.value)


class TestFormatCPF:
    """CPF formatting tests"""

    def test_format_valid_cpf(self):
        """Format valid CPF"""
        result = fmt_cpf("12345678901")
        assert result == "123.456.789-01"

    def test_format_invalid_length(self):
        """Format CPF with invalid length"""
        with pytest.raises(ValidationError):
            fmt_cpf("123456789")


# ============================================================================
# TESTS: Request Validation (subradar_server.py)
# ============================================================================

class TestRequestValidation:
    """HTTP request validation tests"""

    def test_valid_request(self, valid_request_data):
        """Valid request payload"""
        is_valid, error, data = validate_request(valid_request_data)
        assert is_valid is True
        assert error == ""
        assert data["cpf"] == "12345678901"
        assert data["nome"] == "João da Silva"
        assert data["action"] == "generate"

    def test_missing_cpf(self, valid_request_data):
        """Missing CPF field"""
        del valid_request_data["cpf"]
        is_valid, error, _ = validate_request(valid_request_data)
        assert is_valid is False
        assert "cpf" in error.lower()

    def test_missing_nome(self, valid_request_data):
        """Missing nome field"""
        del valid_request_data["nome"]
        is_valid, error, _ = validate_request(valid_request_data)
        assert is_valid is False
        assert "nome" in error.lower()

    def test_missing_email(self, valid_request_data):
        """Missing email field"""
        del valid_request_data["email"]
        is_valid, error, _ = validate_request(valid_request_data)
        assert is_valid is False
        assert "email" in error.lower()

    def test_missing_action(self, valid_request_data):
        """Missing action field"""
        del valid_request_data["action"]
        is_valid, error, _ = validate_request(valid_request_data)
        assert is_valid is False
        assert "action" in error.lower()

    def test_invalid_cpf_length(self, valid_request_data):
        """CPF with invalid length"""
        valid_request_data["cpf"] = "123456789"
        is_valid, error, _ = validate_request(valid_request_data)
        assert is_valid is False
        assert "dígitos" in error.lower()

    def test_invalid_email_format(self, valid_request_data):
        """Invalid email format"""
        valid_request_data["email"] = "invalid-email"
        is_valid, error, _ = validate_request(valid_request_data)
        assert is_valid is False
        assert "email" in error.lower()

    def test_invalid_action(self, valid_request_data):
        """Invalid action"""
        valid_request_data["action"] = "invalid"
        is_valid, error, _ = validate_request(valid_request_data)
        assert is_valid is False
        assert "ação" in error.lower()

    def test_nome_too_short(self, valid_request_data):
        """Name too short"""
        valid_request_data["nome"] = "Jo"
        is_valid, error, _ = validate_request(valid_request_data)
        assert is_valid is False
        assert "caracteres" in error.lower()


# ============================================================================
# TESTS: API Endpoint (subradar_server.py)
# ============================================================================

class TestAPIEndpoint:
    """HTTP endpoint tests"""

    def test_health_check(self, client):
        """GET / returns health status"""
        response = client.get("/")
        assert response.status_code == 200
        data = response.get_json()
        assert data["service"] == "Subradar PF API"
        assert data["status"] == "online"

    def test_health_endpoint(self, client):
        """GET /health returns healthy"""
        response = client.get("/health")
        assert response.status_code == 200
        data = response.get_json()
        assert data["status"] == "healthy"

    def test_not_found(self, client):
        """GET /invalid returns 404"""
        response = client.get("/invalid")
        assert response.status_code == 404
        data = response.get_json()
        assert data["success"] is False
        assert "não encontrado" in data["error"].lower()

    def test_cors_preflight(self, client):
        """OPTIONS request returns 204"""
        response = client.options("/api/subradar/dossiee")
        assert response.status_code == 204

    @patch('subradar_server.call_api')
    def test_successful_generate(self, mock_call_api, client, valid_request_data, mock_api_success):
        """Successful generate request"""
        mock_call_api.return_value = (200, mock_api_success)

        response = client.post(
            "/api/subradar/dossiee",
            json=valid_request_data,
            content_type="application/json"
        )

        assert response.status_code == 200
        data = response.get_json()
        assert data["success"] is True
        assert data["score"] == 42

    def test_missing_required_field(self, client):
        """Request with missing field returns 400"""
        response = client.post(
            "/api/subradar/dossiee",
            json={"cpf": "12345678901"},
            content_type="application/json"
        )

        assert response.status_code == 400
        data = response.get_json()
        assert data["success"] is False

    def test_invalid_cpf(self, client, valid_request_data):
        """Request with invalid CPF returns 400"""
        valid_request_data["cpf"] = "123"
        response = client.post(
            "/api/subradar/dossiee",
            json=valid_request_data,
            content_type="application/json"
        )

        assert response.status_code == 400
        data = response.get_json()
        assert "dígitos" in data["error"].lower()

    @patch('subradar_server.call_api')
    def test_supabase_error(self, mock_call_api, client, valid_request_data):
        """Supabase error returns 503"""
        mock_call_api.return_value = (503, {"error": "Supabase offline"})

        response = client.post(
            "/api/subradar/dossiee",
            json=valid_request_data,
            content_type="application/json"
        )

        assert response.status_code == 503

    @patch('subradar_server.call_api')
    def test_timeout(self, mock_call_api, client, valid_request_data):
        """Request timeout returns 504"""
        mock_call_api.return_value = (504, {"error": "Timeout"})

        response = client.post(
            "/api/subradar/dossiee",
            json=valid_request_data,
            content_type="application/json"
        )

        assert response.status_code == 504


# ============================================================================
# TESTS: Caching
# ============================================================================

class TestCaching:
    """Request caching tests"""

    def test_cache_key(self):
        """Cache key generation"""
        key = cache_key("12345678901", "send")
        assert key == "12345678901:send"

    def test_set_and_get_cache(self):
        """Set and retrieve cached value"""
        key = "test:key"
        value = {"success": True, "score": 42}

        set_cached(key, value)
        assert is_cached(key) is True

        cached_value = get_cached(key)
        assert cached_value == value

    def test_cache_miss(self):
        """Cache miss returns False"""
        key = "nonexistent:key"
        assert is_cached(key) is False


# ============================================================================
# TESTS: Integration
# ============================================================================

class TestIntegration:
    """End-to-end integration tests"""

    @patch('subradar_server.subprocess.run')
    def test_end_to_end_generate(self, mock_run, client, valid_request_data):
        """Complete generate flow"""
        # Mock subprocess call
        mock_run.return_value = MagicMock(
            returncode=0,
            stdout=json.dumps({
                "success": True,
                "score": 42,
                "faixa": "MÉDIO",
                "pdf": "base64-pdf-content"
            })
        )

        response = client.post(
            "/api/subradar/dossiee",
            json=valid_request_data,
            content_type="application/json"
        )

        assert response.status_code == 200
        data = response.get_json()
        assert data["success"] is True
        assert data["score"] == 42
        assert "pdf" in data

    @patch('subradar_server.subprocess.run')
    def test_end_to_end_send(self, mock_run, client):
        """Complete send flow"""
        request_data = {
            "cpf": "12345678901",
            "nome": "João da Silva",
            "email": "joao@example.com",
            "action": "send"
        }

        mock_run.return_value = MagicMock(
            returncode=0,
            stdout=json.dumps({
                "success": True,
                "score": 42,
                "faixa": "MÉDIO",
                "message": "Dossiê enviado para joao@example.com"
            })
        )

        response = client.post(
            "/api/subradar/dossiee",
            json=request_data,
            content_type="application/json"
        )

        assert response.status_code == 200
        data = response.get_json()
        assert data["success"] is True
        assert "message" in data


# ============================================================================
# TESTS: Error Handling
# ============================================================================

class TestErrorHandling:
    """Error handling tests"""

    @patch('subradar_server.subprocess.run')
    def test_subprocess_validation_error(self, mock_run, client, valid_request_data):
        """Subprocess validation error (exit code 1)"""
        mock_run.return_value = MagicMock(
            returncode=1,
            stdout=json.dumps({"success": False, "error": "CPF inválido"})
        )

        response = client.post(
            "/api/subradar/dossiee",
            json=valid_request_data,
            content_type="application/json"
        )

        assert response.status_code == 400

    @patch('subradar_server.subprocess.run')
    def test_subprocess_data_error(self, mock_run, client, valid_request_data):
        """Subprocess data fetch error (exit code 2)"""
        mock_run.return_value = MagicMock(
            returncode=2,
            stdout=json.dumps({"success": False, "error": "Supabase offline"})
        )

        response = client.post(
            "/api/subradar/dossiee",
            json=valid_request_data,
            content_type="application/json"
        )

        assert response.status_code == 503

    @patch('subradar_server.subprocess.run')
    def test_subprocess_timeout(self, mock_run, client, valid_request_data):
        """Subprocess timeout"""
        import subprocess
        mock_run.side_effect = subprocess.TimeoutExpired("cmd", 60)

        response = client.post(
            "/api/subradar/dossiee",
            json=valid_request_data,
            content_type="application/json"
        )

        assert response.status_code == 504

    @patch('subradar_server.subprocess.run')
    def test_invalid_json_response(self, mock_run, client, valid_request_data):
        """Subprocess returns invalid JSON"""
        mock_run.return_value = MagicMock(
            returncode=0,
            stdout="invalid json"
        )

        response = client.post(
            "/api/subradar/dossiee",
            json=valid_request_data,
            content_type="application/json"
        )

        assert response.status_code == 500


# ============================================================================
# TESTS: Rate Limiting
# ============================================================================

class TestRateLimiting:
    """Rate limiting tests"""

    @patch('subradar_server.call_api')
    def test_rate_limit_exceeded(self, mock_call_api, client, valid_request_data):
        """Rate limit exceeded returns 429"""
        mock_call_api.return_value = (200, {"success": True, "score": 42})

        # Make 11 requests (limit is 10/min)
        for i in range(11):
            response = client.post(
                "/api/subradar/dossiee",
                json=valid_request_data,
                content_type="application/json"
            )

            if i < 10:
                assert response.status_code == 200
            else:
                assert response.status_code == 429


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
