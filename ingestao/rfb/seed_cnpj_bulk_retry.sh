#!/usr/bin/env bash
# Seed bulk CNPJ via RFB com retry horário.
# Tenta até conseguir completar; desiste depois de MAX_TENTATIVAS.
# Agendado via launchd toda segunda às 03h — mas também pode ser chamado manualmente.

set -euo pipefail

REPO="/Users/luizlessa/brasilia-insider"
VENV="$REPO/.venv/bin/python"
LOG_DIR="/tmp"
LOG="$LOG_DIR/seed_cnpj_bulk_$(date +%Y%m%d_%H%M).log"
LOCK="/tmp/seed_cnpj_bulk.lock"
MAX_TENTATIVAS=12   # tenta por até 12h (1 tentativa/hora)
INTERVALO=3600      # segundos entre tentativas

echo "[$(date)] seed_cnpj_bulk_retry.sh iniciado" | tee "$LOG"

# Evita execuções simultâneas
if [ -f "$LOCK" ]; then
    echo "[$(date)] Já existe uma instância rodando (lock: $LOCK). Abortando." | tee -a "$LOG"
    exit 0
fi
touch "$LOCK"
trap 'rm -f "$LOCK"' EXIT

cd "$REPO"

for i in $(seq 1 $MAX_TENTATIVAS); do
    echo "" | tee -a "$LOG"
    echo "[$(date)] === Tentativa $i/$MAX_TENTATIVAS ===" | tee -a "$LOG"

    # Testa conectividade antes de baixar
    if ! curl -s -o /dev/null -w "%{http_code}" --max-time 15 \
            "https://dadosabertos.rfb.gov.br/CNPJ/Empresas0.zip" 2>/dev/null | grep -q "^2"; then
        echo "[$(date)] RFB inacessível. Aguardando ${INTERVALO}s..." | tee -a "$LOG"
        sleep $INTERVALO
        continue
    fi

    echo "[$(date)] RFB acessível. Iniciando seed..." | tee -a "$LOG"
    if "$VENV" -m ingestao.rfb.seed_cnpj >> "$LOG" 2>&1; then
        echo "[$(date)] ✅ Seed concluído com sucesso na tentativa $i." | tee -a "$LOG"
        # Manter só os 7 logs mais recentes
        ls -t "$LOG_DIR"/seed_cnpj_bulk_*.log 2>/dev/null | tail -n +8 | xargs rm -f
        exit 0
    else
        EXIT=$?
        echo "[$(date)] ⚠️  Seed terminou com exit=$EXIT. Aguardando ${INTERVALO}s..." | tee -a "$LOG"
        sleep $INTERVALO
    fi
done

echo "[$(date)] ❌ Esgotadas $MAX_TENTATIVAS tentativas. Verificar log: $LOG" | tee -a "$LOG"
exit 1
