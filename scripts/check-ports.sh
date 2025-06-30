#!/bin/bash

# Script para verificar disponibilidade de portas
# Uso: ./scripts/check-ports.sh

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
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1${NC}"
}

# Carregar variáveis de ambiente
if [ -f ".env" ]; then
    source .env
else
    error "Arquivo .env não encontrado"
    exit 1
fi

log "🔍 Verificando disponibilidade de portas..."

# Lista de portas a verificar
ports_to_check=(
    "${ALOY_CORE_PORT:-1100}:Core API"
    "${ALOY_NLP_PORT:-1200}:NLP Service"
    "${ALOY_SYSTEM_MONITOR_PORT:-1300}:System Monitor"
    "${ALOY_SCHEDULER_PORT:-1301}:Scheduler"
    "${ALOY_TASK_SYNC_PORT:-1302}:Task Sync"
    "${POSTGRES_PORT:-1700}:PostgreSQL"
    "${RABBITMQ_AMQP_PORT:-1800}:RabbitMQ AMQP"
    "${RABBITMQ_UI_PORT:-1801}:RabbitMQ Management"
    "${REDIS_PORT:-6379}:Redis"
    "80:Nginx HTTP"
)

# Contadores
total_ports=0
available_ports=0
conflicts=()

# Verificar cada porta
for port_info in "${ports_to_check[@]}"; do
    IFS=':' read -r port service <<< "$port_info"
    total_ports=$((total_ports + 1))
    
    if command -v netstat >/dev/null 2>&1; then
        # Usar netstat se disponível
        if netstat -tln 2>/dev/null | grep -q ":$port "; then
            error "Porta $port ($service) está em uso"
            
            # Tentar identificar o processo
            if command -v lsof >/dev/null 2>&1; then
                process=$(lsof -ti:$port 2>/dev/null | head -1)
                if [ -n "$process" ]; then
                    process_name=$(ps -p $process -o comm= 2>/dev/null || echo "desconhecido")
                    echo "  Processo: $process ($process_name)"
                fi
            fi
            
            conflicts+=("$port:$service")
        else
            success "Porta $port ($service) está disponível"
            available_ports=$((available_ports + 1))
        fi
    elif command -v ss >/dev/null 2>&1; then
        # Usar ss como alternativa
        if ss -tln 2>/dev/null | grep -q ":$port "; then
            error "Porta $port ($service) está em uso"
            conflicts+=("$port:$service")
        else
            success "Porta $port ($service) está disponível"
            available_ports=$((available_ports + 1))
        fi
    else
        # Tentar conexão direta como último recurso
        if timeout 1 bash -c "</dev/tcp/localhost/$port" 2>/dev/null; then
            error "Porta $port ($service) está em uso"
            conflicts+=("$port:$service")
        else
            success "Porta $port ($service) está disponível"
            available_ports=$((available_ports + 1))
        fi
    fi
done

echo ""

# Resumo
log "📊 Resumo da verificação:"
echo "Total de portas verificadas: $total_ports"
echo "Portas disponíveis: $available_ports"
echo "Conflitos encontrados: ${#conflicts[@]}"

if [ ${#conflicts[@]} -eq 0 ]; then
    success "🎉 Todas as portas estão disponíveis!"
    
    echo ""
    log "🚀 Portas que serão utilizadas:"
    printf "%-8s %-20s %-30s\n" "PORTA" "SERVIÇO" "VARIÁVEL"
    printf "%-8s %-20s %-30s\n" "-----" "-------" "--------"
    printf "%-8s %-20s %-30s\n" "${ALOY_CORE_PORT:-1100}" "Core API" "ALOY_CORE_PORT"
    printf "%-8s %-20s %-30s\n" "${ALOY_NLP_PORT:-1200}" "NLP Service" "ALOY_NLP_PORT"
    printf "%-8s %-20s %-30s\n" "${ALOY_SYSTEM_MONITOR_PORT:-1300}" "System Monitor" "ALOY_SYSTEM_MONITOR_PORT"
    printf "%-8s %-20s %-30s\n" "${ALOY_SCHEDULER_PORT:-1301}" "Scheduler" "ALOY_SCHEDULER_PORT"
    printf "%-8s %-20s %-30s\n" "${ALOY_TASK_SYNC_PORT:-1302}" "Task Sync" "ALOY_TASK_SYNC_PORT"
    printf "%-8s %-20s %-30s\n" "${POSTGRES_PORT:-1700}" "PostgreSQL" "POSTGRES_PORT"
    printf "%-8s %-20s %-30s\n" "${RABBITMQ_AMQP_PORT:-1800}" "RabbitMQ AMQP" "RABBITMQ_AMQP_PORT"
    printf "%-8s %-20s %-30s\n" "${RABBITMQ_UI_PORT:-1801}" "RabbitMQ UI" "RABBITMQ_UI_PORT"
    printf "%-8s %-20s %-30s\n" "${REDIS_PORT:-6379}" "Redis" "REDIS_PORT"
    printf "%-8s %-20s %-30s\n" "80" "Nginx HTTP" "(fixo)"
    
    exit 0
else
    error "❌ Encontrados ${#conflicts[@]} conflitos de porta!"
    echo ""
    echo "Portas conflitantes:"
    for conflict in "${conflicts[@]}"; do
        IFS=':' read -r port service <<< "$conflict"
        echo "  - Porta $port ($service)"
    done
    
    echo ""
    log "💡 Soluções sugeridas:"
    echo "1. Parar os serviços que estão usando essas portas"
    echo "2. Alterar as portas no arquivo .env"
    echo "3. Usar 'make stop' para parar containers existentes da Aloy"
    echo ""
    echo "Para identificar processos:"
    echo "  lsof -i :PORTA"
    echo "  sudo netstat -tlnp | grep :PORTA"
    echo ""
    echo "Para parar containers Aloy:"
    echo "  make stop"
    echo "  make clean"
    
    exit 1
fi
