#!/bin/bash
# restart_service.sh
# Script para reiniciar o serviço Aloy NLP com logs apropriados

# Diretório para os logs
LOG_DIR="logs"
mkdir -p $LOG_DIR

# Nome do arquivo de log com timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOG_DIR/nlp_service_$TIMESTAMP.log"

echo "=== Reiniciando serviço Aloy NLP ==="
echo "Os logs serão salvos em: $LOG_FILE"

# Matar qualquer processo existente do uvicorn/fastapi
echo "Verificando processos existentes..."
pkill -f "uvicorn app.main:app" || echo "Nenhum processo anterior encontrado."

# Iniciar o serviço com redirecionamento de logs
echo "Iniciando serviço Aloy NLP..."
./run.bash > "$LOG_FILE" 2>&1 &

# Verificar se o serviço iniciou corretamente
sleep 2
pgrep -f "uvicorn app.main:app" > /dev/null
if [ $? -eq 0 ]; then
    echo "Serviço iniciado com sucesso! (PID: $(pgrep -f "uvicorn app.main:app"))"
    echo "Use 'tail -f $LOG_FILE' para acompanhar os logs."
else
    echo "ERRO: Falha ao iniciar o serviço."
    echo "Verifique os logs em '$LOG_FILE'"
fi
