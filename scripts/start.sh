#!/bin/bash

# Script para inicializar a aplicação Aloy
# Uso: ./scripts/start.sh [ambiente]
# Ambientes: dev (padrão), prod

set -e

ENVIRONMENT=${1:-dev}
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🚀 Iniciando Aloy em modo $ENVIRONMENT..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para log
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARN: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

# Verificar se Docker está rodando
if ! docker info > /dev/null 2>&1; then
    error "Docker não está rodando. Por favor, inicie o Docker."
    exit 1
fi

# Verificar se docker-compose está instalado
if ! command -v docker-compose > /dev/null 2>&1; then
    error "docker-compose não está instalado."
    exit 1
fi

# Função para aguardar serviço ficar disponível
wait_for_service() {
    local service=$1
    local port=$2
    local max_attempts=30
    local attempt=1

    log "Aguardando $service ficar disponível na porta $port..."
    
    while [ $attempt -le $max_attempts ]; do
        if nc -z localhost $port > /dev/null 2>&1; then
            log "$service está disponível!"
            return 0
        fi
        
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    error "$service não ficou disponível após $((max_attempts * 2)) segundos"
    return 1
}

# Limpar containers antigos se existirem
log "Limpando containers antigos..."
docker-compose down > /dev/null 2>&1 || true
docker-compose -f docker-compose.dev.yml down > /dev/null 2>&1 || true

# Verificar disponibilidade de portas
log "Verificando disponibilidade de portas..."
if ! ./scripts/check-ports.sh > /dev/null 2>&1; then
    warn "Algumas portas podem estar em uso. Continuando mesmo assim..."
    echo "Execute 'make check-ports' para ver detalhes"
fi

if [ "$ENVIRONMENT" = "dev" ]; then
    log "Iniciando serviços de desenvolvimento..."
    docker-compose -f docker-compose.dev.yml up -d
    
    # Carregar variáveis de ambiente
    if [ -f ".env" ]; then
        source .env
    fi
    
    # Aguardar serviços ficarem disponíveis
    wait_for_service "PostgreSQL" "${POSTGRES_PORT:-1700}"
    wait_for_service "RabbitMQ" "${RABBITMQ_AMQP_PORT:-1800}"
    wait_for_service "Redis" "${REDIS_PORT:-6379}"
    
    echo ""
    log "✅ Serviços de desenvolvimento iniciados com sucesso!"
    echo ""
    echo "📊 Serviços disponíveis:"
    echo "  🐘 PostgreSQL: localhost:${POSTGRES_PORT:-1700}"
    echo "  🐰 RabbitMQ Management: http://localhost:${RABBITMQ_UI_PORT:-1801} (${RABBITMQ_USER:-aloy}/${RABBITMQ_PASSWORD:-aloy123})"
    echo "  🔴 Redis: localhost:${REDIS_PORT:-6379}"
    echo ""
    echo "Para iniciar os serviços da aplicação, execute:"
    echo "  cd apps/core && go run cmd/main.go"
    echo "  cd modules/nlp && python run.py"
    echo "  cd modules/scheduler && npm run dev"
    echo "  cd modules/sysmonitor && go run cmd/main.go"
    echo "  cd modules/tasksync && go run cmd/main.go"
    
elif [ "$ENVIRONMENT" = "prod" ]; then
    log "Iniciando ambiente de produção..."
    
    # Carregar variáveis de ambiente
    if [ -f ".env" ]; then
        source .env
    fi
    
    # Verificar se as imagens existem, senão construir
    log "Construindo imagens Docker..."
    docker-compose build
    
    # Iniciar todos os serviços
    docker-compose up -d
    
    # Aguardar serviços ficarem disponíveis
    wait_for_service "PostgreSQL" "${POSTGRES_PORT:-1700}"
    wait_for_service "RabbitMQ" "${RABBITMQ_AMQP_PORT:-1800}"
    wait_for_service "Redis" "${REDIS_PORT:-6379}"
    wait_for_service "Core API" "${ALOY_CORE_PORT:-1100}"
    wait_for_service "NLP Service" "${ALOY_NLP_PORT:-1200}"
    wait_for_service "System Monitor" "${ALOY_SYSTEM_MONITOR_PORT:-1300}"
    wait_for_service "Nginx" 80
    
    echo ""
    log "✅ Aplicação Aloy iniciada com sucesso!"
    echo ""
    echo "🌐 Serviços disponíveis:"
    echo "  🚀 API Principal: http://localhost (via Nginx)"
    echo "  🧠 NLP Service: http://localhost/nlp"
    echo "  📊 System Monitor: http://localhost/monitor"
    echo "  ⏰ Scheduler: http://localhost/scheduler"
    echo "  🔄 Task Sync: http://localhost/tasksync"
    echo "  🐰 RabbitMQ Management: http://localhost:${RABBITMQ_UI_PORT:-1801} (${RABBITMQ_USER:-aloy}/${RABBITMQ_PASSWORD:-aloy123})"
    echo ""
    echo "Para ver logs: docker-compose logs -f [serviço]"
    echo "Para parar: ./scripts/stop.sh"
    
else
    error "Ambiente inválido: $ENVIRONMENT. Use 'dev' ou 'prod'."
    exit 1
fi

echo ""
log "🎉 Script concluído!"
