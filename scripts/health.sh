#!/bin/bash

# Script para verificar o status de saúde da aplicação Aloy
# Uso: ./scripts/health.sh

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Verificar se Docker está rodando
if ! docker info > /dev/null 2>&1; then
    error "Docker não está rodando"
    exit 1
fi

log "🔍 Verificando status de saúde da aplicação Aloy..."
echo ""

# Função para verificar status de container
check_container() {
    local container_name=$1
    local service_name=$2
    
    if docker ps --format "{{.Names}}" | grep -q "^${container_name}$"; then
        local status=$(docker inspect --format='{{.State.Status}}' $container_name 2>/dev/null)
        if [ "$status" = "running" ]; then
            success "$service_name está rodando"
            return 0
        else
            error "$service_name está parado (status: $status)"
            return 1
        fi
    else
        error "$service_name não encontrado"
        return 1
    fi
}

# Função para verificar conectividade HTTP
check_http() {
    local url=$1
    local service_name=$2
    local timeout=${3:-5}
    
    if curl -sSf --max-time $timeout "$url" > /dev/null 2>&1; then
        success "$service_name responde HTTP"
        return 0
    else
        error "$service_name não responde HTTP"
        return 1
    fi
}

# Função para verificar porta TCP
check_port() {
    local host=$1
    local port=$2
    local service_name=$3
    local timeout=${4:-3}
    
    if timeout $timeout bash -c "</dev/tcp/$host/$port" 2>/dev/null; then
        success "$service_name porta $port acessível"
        return 0
    else
        error "$service_name porta $port não acessível"
        return 1
    fi
}

# Contadores
total_checks=0
passed_checks=0

# Verificar containers
echo "📦 Verificando Containers:"
containers=(
    "aloy_postgres:PostgreSQL"
    "aloy_rabbitmq:RabbitMQ"
    "aloy_redis:Redis"
    "aloy_core:Core Service"
    "aloy_nlp:NLP Service"
    "aloy_scheduler:Scheduler"
    "aloy_sysmonitor:System Monitor"
    "aloy_tasksync:Task Sync"
    "aloy_nginx:Nginx"
)

for container_info in "${containers[@]}"; do
    IFS=':' read -r container_name service_name <<< "$container_info"
    total_checks=$((total_checks + 1))
    if check_container "$container_name" "$service_name"; then
        passed_checks=$((passed_checks + 1))
    fi
done

echo ""

# Verificar conectividade de portas
echo "🔌 Verificando Conectividade:"

# Carregar variáveis de ambiente
if [ -f ".env" ]; then
    source .env
fi

ports=(
    "localhost:${POSTGRES_PORT:-1700}:PostgreSQL"
    "localhost:${RABBITMQ_AMQP_PORT:-1800}:RabbitMQ"
    "localhost:${REDIS_PORT:-6379}:Redis"
    "localhost:${ALOY_CORE_PORT:-1100}:Core API"
    "localhost:${ALOY_NLP_PORT:-1200}:NLP Service"
    "localhost:${ALOY_SYSTEM_MONITOR_PORT:-1300}:System Monitor"
    "localhost:${ALOY_SCHEDULER_PORT:-1301}:Scheduler"
    "localhost:${ALOY_TASK_SYNC_PORT:-1302}:Task Sync"
    "localhost:80:Nginx"
    "localhost:${RABBITMQ_UI_PORT:-1801}:RabbitMQ Management"
)

for port_info in "${ports[@]}"; do
    IFS=':' read -r host port service_name <<< "$port_info"
    total_checks=$((total_checks + 1))
    if check_port "$host" "$port" "$service_name"; then
        passed_checks=$((passed_checks + 1))
    fi
done

echo ""

# Verificar APIs HTTP
echo "🌐 Verificando APIs HTTP:"

# Carregar variáveis se ainda não carregadas
if [ -z "${ALOY_CORE_PORT}" ] && [ -f ".env" ]; then
    source .env
fi

apis=(
    "http://localhost/health:Nginx Health"
    "http://localhost:${ALOY_CORE_PORT:-1100}/health:Core API"
    "http://localhost:${ALOY_NLP_PORT:-1200}/health:NLP Service"
    "http://localhost:${ALOY_SYSTEM_MONITOR_PORT:-1300}/health:System Monitor"
    "http://localhost:${RABBITMQ_UI_PORT:-1801}:RabbitMQ Management"
)

for api_info in "${apis[@]}"; do
    IFS=':' read -r url service_name <<< "$api_info"
    total_checks=$((total_checks + 1))
    if check_http "$url" "$service_name"; then
        passed_checks=$((passed_checks + 1))
    fi
done

echo ""

# Verificar recursos do sistema
echo "📊 Recursos do Sistema:"
if command -v free > /dev/null 2>&1; then
    memory_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    if (( $(echo "$memory_usage < 80" | bc -l) )); then
        success "Uso de memória: ${memory_usage}%"
    else
        warn "Uso de memória alto: ${memory_usage}%"
    fi
fi

if command -v df > /dev/null 2>&1; then
    disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -lt 80 ]; then
        success "Uso de disco: ${disk_usage}%"
    else
        warn "Uso de disco alto: ${disk_usage}%"
    fi
fi

echo ""

# Resumo final
echo "📋 Resumo:"
echo "Total de verificações: $total_checks"
echo "Verificações aprovadas: $passed_checks"
echo "Verificações falharam: $((total_checks - passed_checks))"

percentage=$((passed_checks * 100 / total_checks))

if [ $percentage -eq 100 ]; then
    success "Sistema está 100% operacional! 🎉"
    exit 0
elif [ $percentage -ge 80 ]; then
    warn "Sistema está ${percentage}% operacional (alguns problemas detectados)"
    exit 1
else
    error "Sistema está ${percentage}% operacional (problemas críticos detectados)"
    exit 2
fi
