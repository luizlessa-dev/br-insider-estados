#!/usr/bin/env bash
# scripts/alergs-cron.sh
#
# Ingestão mensal de deputados ALERGS — roda localmente no Mac (IP BR residencial).
# Disparado pelo launchd via RunAtLoad (guard abaixo controla a cadência real).
#
# Por que local e não GitHub Actions:
#   A API na porta 5000 de ww4.al.rs.gov.br bloqueia IP de datacenter
#   (mesmo padrão de ALMG/ALEPE em transparencia-federal) — connect timeout
#   consistente em todo run do GHA desde pelo menos 22/06/2026.
#   IP residencial BR passa sem restrição (testado: HTTP 200 em <1s).
#
# Escopo: só deputados (proposições/votações são permanentemente deferidas —
# API de consultas exige auth e retorna 401, sem relação com bloqueio de IP).
# Roster de deputados muda raramente, cadência mensal é sobra.
#
# Log: ~/Library/Logs/alergs-cron.log

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG_FILE="$HOME/Library/Logs/alergs-cron.log"
MARKER_FILE="$HOME/Library/Logs/alergs-cron.success-$(date +%Y-%m)"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

# Guard: RunAtLoad dispara em todo boot — só segue se já é dia >= 5 e ainda
# não rodou com sucesso este mês.
if [ "$(date +%-d)" -lt 5 ]; then
  log "Ainda não é dia 5 — pulando (RunAtLoad dispara a cada boot)"
  exit 0
fi
if [ -f "$MARKER_FILE" ]; then
  log "Já rodou com sucesso este mês ($MARKER_FILE existe) — pulando"
  exit 0
fi

log "=== Iniciando ingestão ALERGS (deputados) ==="
cd "$REPO_DIR"

if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
  log "Variáveis de ambiente carregadas de .env"
fi

if [ ! -x .venv/bin/python ]; then
  log "ERRO: .venv não encontrado em $REPO_DIR/.venv"
  exit 1
fi

if .venv/bin/python -m ingestao.scheduler --assembly alergs --entidades deputados 2>&1 | tee -a "$LOG_FILE"; then
  log "=== Ingestão ALERGS concluída ==="
  touch "$MARKER_FILE"
else
  log "ERRO na ingestão ALERGS"
  exit 1
fi
