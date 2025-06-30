#!/bin/bash

# Script para parar a aplicação Aloy
# Uso: ./scripts/stop.sh [ambiente]
# Ambientes: dev (padrão), prod, all

set -e

ENVIRONMENT=${1:-all}
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🛑 Parando Aloy..."

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
    warn "Docker não está rodando."
    exit 0
fi

if [ "$ENVIRONMENT" = "dev" ]; then
    log "Parando serviços de desenvolvimento..."
    docker-compose -f docker-compose.dev.yml down
    log "✅ Serviços de desenvolvimento parados!"
    
elif [ "$ENVIRONMENT" = "prod" ]; then
    log "Parando ambiente de produção..."
    docker-compose down
    log "✅ Ambiente de produção parado!"
    
elif [ "$ENVIRONMENT" = "all" ]; then
    log "Parando todos os ambientes..."
    docker-compose down > /dev/null 2>&1 || true
    docker-compose -f docker-compose.dev.yml down > /dev/null 2>&1 || true
    log "✅ Todos os ambientes parados!"
    
else
    error "Ambiente inválido: $ENVIRONMENT. Use 'dev', 'prod' ou 'all'."
    exit 1
fi

echo ""
log "🎉 Script concluído!"
