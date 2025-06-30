#!/bin/bash

# Script para limpar recursos Docker da aplicação Aloy
# Uso: ./scripts/cleanup.sh [opção]
# Opções: containers, images, volumes, all

set -e

OPTION=${1:-containers}
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🧹 Limpando recursos Docker da Aloy..."

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

cleanup_containers() {
    log "Parando e removendo containers..."
    docker-compose down > /dev/null 2>&1 || true
    docker-compose -f docker-compose.dev.yml down > /dev/null 2>&1 || true
    
    # Remover containers específicos do Aloy
    CONTAINERS=$(docker ps -a --filter "name=aloy_" --format "{{.Names}}" 2>/dev/null || true)
    if [ -n "$CONTAINERS" ]; then
        echo "$CONTAINERS" | xargs docker rm -f > /dev/null 2>&1 || true
        log "Containers removidos!"
    else
        log "Nenhum container Aloy encontrado."
    fi
}

cleanup_images() {
    log "Removendo imagens Docker..."
    
    # Remover imagens do projeto
    IMAGES=$(docker images --filter "reference=aloy*" --format "{{.Repository}}:{{.Tag}}" 2>/dev/null || true)
    if [ -n "$IMAGES" ]; then
        echo "$IMAGES" | xargs docker rmi -f > /dev/null 2>&1 || true
        log "Imagens removidas!"
    else
        log "Nenhuma imagem Aloy encontrada."
    fi
    
    # Limpar imagens órfãs
    docker image prune -f > /dev/null 2>&1 || true
    log "Imagens órfãs removidas!"
}

cleanup_volumes() {
    log "Removendo volumes..."
    
    # Remover volumes do projeto
    VOLUMES=$(docker volume ls --filter "name=aloy" --format "{{.Name}}" 2>/dev/null || true)
    if [ -n "$VOLUMES" ]; then
        echo "$VOLUMES" | xargs docker volume rm -f > /dev/null 2>&1 || true
        log "Volumes removidos!"
    else
        log "Nenhum volume Aloy encontrado."
    fi
    
    # Limpar volumes órfãos
    docker volume prune -f > /dev/null 2>&1 || true
    log "Volumes órfãos removidos!"
}

cleanup_networks() {
    log "Removendo redes..."
    
    # Remover redes do projeto
    NETWORKS=$(docker network ls --filter "name=aloy" --format "{{.Name}}" 2>/dev/null || true)
    if [ -n "$NETWORKS" ]; then
        echo "$NETWORKS" | xargs docker network rm > /dev/null 2>&1 || true
        log "Redes removidas!"
    else
        log "Nenhuma rede Aloy encontrada."
    fi
    
    # Limpar redes órfãs
    docker network prune -f > /dev/null 2>&1 || true
    log "Redes órfãs removidas!"
}

case $OPTION in
    containers)
        cleanup_containers
        ;;
    images)
        cleanup_images
        ;;
    volumes)
        cleanup_volumes
        ;;
    networks)
        cleanup_networks
        ;;
    all)
        cleanup_containers
        cleanup_images
        cleanup_volumes
        cleanup_networks
        
        # Limpeza geral do Docker
        log "Executando limpeza geral do Docker..."
        docker system prune -f > /dev/null 2>&1 || true
        ;;
    *)
        error "Opção inválida: $OPTION"
        echo "Uso: $0 [containers|images|volumes|networks|all]"
        exit 1
        ;;
esac

echo ""
log "✅ Limpeza concluída!"

# Mostrar estatísticas
echo ""
log "📊 Estatísticas do Docker após limpeza:"
echo "Containers: $(docker ps -a | wc -l) total"
echo "Imagens: $(docker images | wc -l) total"
echo "Volumes: $(docker volume ls | wc -l) total"
echo "Redes: $(docker network ls | wc -l) total"
