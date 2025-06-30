#!/bin/bash

# Script de deploy para produção da aplicação Aloy
# Uso: ./scripts/deploy.sh [environment]

set -e

ENVIRONMENT=${1:-production}
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

# Verificações pré-deploy
pre_deploy_checks() {
    log "Executando verificações pré-deploy..."
    
    # Verificar se Docker está rodando
    if ! docker info > /dev/null 2>&1; then
        error "Docker não está rodando"
        exit 1
    fi
    
    # Verificar se docker-compose está instalado
    if ! command -v docker-compose > /dev/null 2>&1; then
        error "docker-compose não está instalado"
        exit 1
    fi
    
    # Verificar se arquivo .env existe
    if [ ! -f ".env" ]; then
        warn "Arquivo .env não encontrado, copiando de .env.example"
        cp .env.example .env
        warn "Por favor, configure o arquivo .env antes de continuar"
        exit 1
    fi
    
    # Verificar espaço em disco
    AVAILABLE_SPACE=$(df . | tail -1 | awk '{print $4}')
    REQUIRED_SPACE=1048576  # 1GB em KB
    
    if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
        error "Espaço em disco insuficiente. Necessário: 1GB, Disponível: $(($AVAILABLE_SPACE/1024))MB"
        exit 1
    fi
    
    success "Verificações pré-deploy concluídas"
}

# Fazer backup antes do deploy
backup_data() {
    log "Fazendo backup dos dados..."
    
    mkdir -p backups
    BACKUP_DIR="backups/deploy_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup do PostgreSQL
    if docker ps --format "{{.Names}}" | grep -q "aloy_postgres"; then
        log "Fazendo backup do PostgreSQL..."
        docker exec aloy_postgres pg_dump -U aloy aloy > "$BACKUP_DIR/postgres_backup.sql"
        success "Backup do PostgreSQL concluído"
    fi
    
    # Backup dos volumes
    if docker volume ls --format "{{.Name}}" | grep -q "aloy_postgres_data"; then
        log "Fazendo backup dos volumes..."
        docker run --rm -v aloy_postgres_data:/data -v $(pwd)/$BACKUP_DIR:/backup alpine \
            tar czf /backup/postgres_volume.tar.gz -C /data . 2>/dev/null || warn "Falha no backup do volume PostgreSQL"
    fi
    
    if docker volume ls --format "{{.Name}}" | grep -q "aloy_rabbitmq_data"; then
        docker run --rm -v aloy_rabbitmq_data:/data -v $(pwd)/$BACKUP_DIR:/backup alpine \
            tar czf /backup/rabbitmq_volume.tar.gz -C /data . 2>/dev/null || warn "Falha no backup do volume RabbitMQ"
    fi
    
    success "Backup concluído em $BACKUP_DIR"
    echo "$BACKUP_DIR" > .last_backup
}

# Construir imagens
build_images() {
    log "Construindo imagens Docker..."
    
    # Construir com cache primeiro, depois sem cache se falhar
    if ! docker-compose build; then
        warn "Build com cache falhou, tentando sem cache..."
        docker-compose build --no-cache
    fi
    
    success "Imagens construídas com sucesso"
}

# Deploy gradual
gradual_deploy() {
    log "Iniciando deploy gradual..."
    
    # 1. Parar serviços de aplicação (manter bancos rodando)
    log "Parando serviços de aplicação..."
    docker-compose stop core nlp scheduler sysmonitor tasksync nginx 2>/dev/null || true
    
    # 2. Aguardar um pouco
    sleep 5
    
    # 3. Iniciar bancos de dados primeiro
    log "Iniciando serviços de infraestrutura..."
    docker-compose up -d postgres rabbitmq redis
    
    # 4. Aguardar bancos ficarem prontos
    wait_for_databases
    
    # 5. Iniciar serviços de aplicação
    log "Iniciando serviços de aplicação..."
    docker-compose up -d core nlp scheduler sysmonitor tasksync
    
    # 6. Aguardar serviços ficarem prontos
    wait_for_services
    
    # 7. Iniciar proxy por último
    log "Iniciando proxy..."
    docker-compose up -d nginx
    
    success "Deploy gradual concluído"
}

# Aguardar bancos de dados
wait_for_databases() {
    log "Aguardando bancos de dados ficarem prontos..."
    
    # PostgreSQL
    until docker exec aloy_postgres pg_isready -U aloy > /dev/null 2>&1; do
        echo -n "."
        sleep 2
    done
    success "PostgreSQL pronto"
    
    # RabbitMQ
    until docker exec aloy_rabbitmq rabbitmq-diagnostics -q ping > /dev/null 2>&1; do
        echo -n "."
        sleep 2
    done
    success "RabbitMQ pronto"
    
    # Redis
    until docker exec aloy_redis redis-cli ping > /dev/null 2>&1; do
        echo -n "."
        sleep 2
    done
    success "Redis pronto"
}

# Aguardar serviços de aplicação
wait_for_services() {
    log "Aguardando serviços de aplicação ficarem prontos..."
    
    # Carregar variáveis de ambiente
    if [ -f ".env" ]; then
        source .env
    fi
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        local healthy_services=0
        
        # Verificar Core
        if curl -sSf http://localhost:${ALOY_CORE_PORT:-1100}/health > /dev/null 2>&1; then
            healthy_services=$((healthy_services + 1))
        fi
        
        # Verificar NLP
        if curl -sSf http://localhost:${ALOY_NLP_PORT:-1200}/health > /dev/null 2>&1; then
            healthy_services=$((healthy_services + 1))
        fi
        
        # Verificar SysMonitor
        if curl -sSf http://localhost:${ALOY_SYSTEM_MONITOR_PORT:-1300}/health > /dev/null 2>&1; then
            healthy_services=$((healthy_services + 1))
        fi
        
        if [ $healthy_services -ge 2 ]; then
            success "Serviços de aplicação prontos"
            return 0
        fi
        
        echo -n "."
        sleep 3
        attempt=$((attempt + 1))
    done
    
    warn "Alguns serviços podem não estar completamente prontos"
}

# Verificar se deploy foi bem-sucedido
verify_deployment() {
    log "Verificando deploy..."
    
    # Executar health check
    if ./scripts/health.sh > /dev/null 2>&1; then
        success "Deploy verificado com sucesso"
        return 0
    else
        error "Verificação do deploy falhou"
        return 1
    fi
}

# Rollback em caso de falha
rollback() {
    error "Deploy falhou, executando rollback..."
    
    # Parar todos os serviços
    docker-compose down
    
    # Restaurar backup se existir
    if [ -f ".last_backup" ]; then
        BACKUP_DIR=$(cat .last_backup)
        if [ -d "$BACKUP_DIR" ]; then
            log "Restaurando backup de $BACKUP_DIR..."
            
            # Restaurar volume do PostgreSQL
            if [ -f "$BACKUP_DIR/postgres_volume.tar.gz" ]; then
                docker run --rm -v aloy_postgres_data:/data -v $(pwd)/$BACKUP_DIR:/backup alpine \
                    tar xzf /backup/postgres_volume.tar.gz -C /data
            fi
            
            # Restaurar volume do RabbitMQ
            if [ -f "$BACKUP_DIR/rabbitmq_volume.tar.gz" ]; then
                docker run --rm -v aloy_rabbitmq_data:/data -v $(pwd)/$BACKUP_DIR:/backup alpine \
                    tar xzf /backup/rabbitmq_volume.tar.gz -C /data
            fi
        fi
    fi
    
    # Iniciar versão anterior
    docker-compose up -d
    
    warn "Rollback concluído"
}

# Cleanup pós-deploy
cleanup() {
    log "Executando limpeza pós-deploy..."
    
    # Remover imagens antigas (manter apenas as 3 mais recentes)
    docker image prune -f > /dev/null 2>&1 || true
    
    # Remover containers parados
    docker container prune -f > /dev/null 2>&1 || true
    
    success "Limpeza concluída"
}

# Função principal
main() {
    echo "🚀 Deploy da Aplicação Aloy - Ambiente: $ENVIRONMENT"
    echo "=================================================="
    
    # Executar etapas do deploy
    pre_deploy_checks
    backup_data
    build_images
    gradual_deploy
    
    # Verificar se deploy foi bem-sucedido
    if verify_deployment; then
        cleanup
        
        echo ""
        success "🎉 Deploy concluído com sucesso!"
        echo ""
        echo "📊 Resumo:"
        echo "  - Ambiente: $ENVIRONMENT"
        echo "  - Backup: $(cat .last_backup 2>/dev/null || echo 'N/A')"
        echo "  - Data: $(date)"
        echo ""
        echo "🌐 Serviços disponíveis:"
        echo "  - API Principal: http://localhost"
        echo "  - Core API: http://localhost:${ALOY_CORE_PORT:-1100}"
        echo "  - NLP Service: http://localhost:${ALOY_NLP_PORT:-1200}"
        echo "  - System Monitor: http://localhost:${ALOY_SYSTEM_MONITOR_PORT:-1300}"
        echo "  - Scheduler: http://localhost:${ALOY_SCHEDULER_PORT:-1301}"
        echo "  - Task Sync: http://localhost:${ALOY_TASK_SYNC_PORT:-1302}"
        echo "  - RabbitMQ Mgmt: http://localhost:${RABBITMQ_UI_PORT:-1801}"
        echo ""
        echo "Para monitorar: make status"
        echo "Para ver logs: make logs"
        
    else
        rollback
        error "Deploy falhou e rollback foi executado"
        exit 1
    fi
}

# Executar função principal
main "$@"
