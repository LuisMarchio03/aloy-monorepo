#!/bin/bash

# Script para monitorar logs da aplicação Aloy
# Uso: ./scripts/logs.sh [serviço] [opções]

set -e

SERVICE=${1:-all}
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para log
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

# Verificar se Docker está rodando
if ! docker info > /dev/null 2>&1; then
    error "Docker não está rodando."
    exit 1
fi

# Lista de serviços disponíveis
SERVICES="core nlp scheduler sysmonitor tasksync postgres rabbitmq redis nginx"

show_help() {
    echo "🔍 Monitor de Logs da Aplicação Aloy"
    echo ""
    echo "Uso: $0 [serviço] [opções]"
    echo ""
    echo "Serviços disponíveis:"
    echo "  all         - Todos os serviços"
    echo "  core        - Serviço principal (Go)"
    echo "  nlp         - Serviço de NLP (Python)"
    echo "  scheduler   - Serviço de agendamento (Node.js)"
    echo "  sysmonitor  - Monitor do sistema (Go)"
    echo "  tasksync    - Sincronização de tarefas (Go)"
    echo "  postgres    - Banco de dados PostgreSQL"
    echo "  rabbitmq    - Message broker RabbitMQ"
    echo "  redis       - Cache Redis"
    echo "  nginx       - Reverse proxy Nginx"
    echo ""
    echo "Opções:"
    echo "  --follow, -f    - Seguir logs em tempo real"
    echo "  --tail N        - Mostrar últimas N linhas (padrão: 100)"
    echo "  --since TIME    - Mostrar logs desde TIME (ex: 2023-01-01T00:00:00)"
    echo "  --help, -h      - Mostrar esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 core -f                    # Seguir logs do core em tempo real"
    echo "  $0 nlp --tail 50             # Últimas 50 linhas do NLP"
    echo "  $0 all --since 1h            # Todos os logs da última hora"
}

# Processar argumentos
FOLLOW=""
TAIL="100"
SINCE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --follow|-f)
            FOLLOW="-f"
            shift
            ;;
        --tail)
            TAIL="$2"
            shift 2
            ;;
        --since)
            SINCE="--since $2"
            shift 2
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            if [ -z "$SERVICE" ] || [ "$SERVICE" = "all" ]; then
                SERVICE="$1"
            fi
            shift
            ;;
    esac
done

# Verificar se o serviço existe
if [ "$SERVICE" != "all" ] && ! echo "$SERVICES" | grep -q "\b$SERVICE\b"; then
    error "Serviço inválido: $SERVICE"
    echo ""
    show_help
    exit 1
fi

log "🔍 Monitorando logs do serviço: $SERVICE"

# Construir comando docker-compose logs
CMD="docker-compose logs"

if [ -n "$FOLLOW" ]; then
    CMD="$CMD $FOLLOW"
fi

if [ -n "$TAIL" ]; then
    CMD="$CMD --tail $TAIL"
fi

if [ -n "$SINCE" ]; then
    CMD="$CMD $SINCE"
fi

if [ "$SERVICE" = "all" ]; then
    eval "$CMD"
else
    eval "$CMD $SERVICE"
fi
