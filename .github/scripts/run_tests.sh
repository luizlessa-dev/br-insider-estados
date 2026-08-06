#!/bin/bash
# Subradar PF — Test runner script

set -e

echo "🧪 Subradar PF — Test Suite"
echo "=============================="
echo ""

# Check if pytest is installed
if ! command -v pytest &> /dev/null; then
    echo "❌ pytest not found. Installing dependencies..."
    pip install -r requirements-server.txt
    echo ""
fi

# Run tests
echo "📋 Running unit tests..."
pytest test_subradar.py -v --tb=short

echo ""
echo "📊 Running tests with coverage..."
pytest test_subradar.py -v --cov=subradar_server --cov=subradar_pf_api --cov-report=term-missing

echo ""
echo "✅ All tests passed!"
echo ""
echo "Test Summary:"
echo "- Input validation tests: 13 tests"
echo "- Request validation tests: 8 tests"
echo "- API endpoint tests: 7 tests"
echo "- Caching tests: 3 tests"
echo "- Integration tests: 2 tests"
echo "- Error handling tests: 4 tests"
echo "- Rate limiting tests: 1 test"
echo "- Total: 38 tests"
