#!/bin/bash

# Script de inicialização completa da aplicação Aloy
# Este script configura todo o ambiente do zero

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Banner
echo -e "${PURPLE}"
echo "  ██████╗ ██╗      ██████╗ ██╗   ██╗"
echo " ██╔══██╗██║     ██╔═══██╗╚██╗ ██╔╝"
echo " ██████╔╝██║     ██║   ██║ ╚████╔╝ "
echo " ██╔══██╗██║     ██║   ██║  ╚██╔╝  "
echo " ██║  ██║███████╗╚██████╔╝   ██║   "
echo " ╚═╝  ╚═╝╚══════╝ ╚═════╝    ╚═╝   "
echo ""
echo "    Sistema de Automação Inteligente"
echo -e "${NC}"

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

step() {
    echo -e "${PURPLE}[PASSO $1/8] $2${NC}"
    echo "=================================================="
}

# Verificar sistema
check_system() {
    step 1 "Verificando sistema"
    
    # Verificar se é Linux
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        warn "Este script foi otimizado para Linux. Pode haver problemas em outros sistemas."
    fi
    
    # Verificar Docker
    if ! command -v docker &> /dev/null; then
        error "Docker não está instalado. Instale o Docker primeiro."
        echo "Instruções: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    # Verificar Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose não está instalado. Instale o Docker Compose primeiro."
        echo "Instruções: https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    # Verificar se Docker está rodando
    if ! docker info &> /dev/null; then
        error "Docker não está rodando. Inicie o Docker primeiro."
        exit 1
    fi
    
    # Verificar Make
    if ! command -v make &> /dev/null; then
        warn "Make não está instalado. Algumas funcionalidades podem não estar disponíveis."
        echo "Instale com: sudo apt-get install make"
    fi
    
    # Verificar espaço em disco
    available_space=$(df . | tail -1 | awk '{print $4}')
    required_space=2097152  # 2GB em KB
    
    if [ "$available_space" -lt "$required_space" ]; then
        error "Espaço em disco insuficiente. Necessário: 2GB, Disponível: $(($available_space/1024))MB"
        exit 1
    fi
    
    success "Sistema verificado com sucesso"
}

# Configurar permissões
setup_permissions() {
    step 2 "Configurando permissões"
    
    # Tornar scripts executáveis
    chmod +x scripts/*.sh
    
    # Criar diretórios necessários
    mkdir -p logs
    mkdir -p backups
    mkdir -p data
    
    success "Permissões configuradas"
}

# Configurar variáveis de ambiente
setup_environment() {
    step 3 "Configurando variáveis de ambiente"
    
    # Gerar arquivos .env se não existirem
    if [ ! -f ".env" ]; then
        log "Criando arquivo .env global..."
        cp .env .env.backup 2>/dev/null || true
        
        # Detectar sistema operacional para ajustar caminhos
        if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
            # Windows
            sed 's|/home/luismarchio03/Documents/Sistemas|C:/sistemas|g' .env > .env.tmp
            mv .env.tmp .env
        fi
    fi
    
    # Sincronizar variáveis com módulos
    log "Sincronizando variáveis de ambiente..."
    ./scripts/env-manager.sh generate --force
    
    # Gerar configuração do Nginx
    log "Gerando configuração do Nginx..."
    ./scripts/generate-nginx-config.sh
    
    # Validar configuração
    ./scripts/env-manager.sh check
    
    success "Variáveis de ambiente configuradas"
}

# Verificar e instalar dependências
install_dependencies() {
    step 4 "Verificando dependências dos módulos"
    
    # Go modules
    if command -v go &> /dev/null; then
        log "Verificando módulos Go..."
        
        if [ -f "apps/core/go.mod" ]; then
            cd apps/core
            go mod tidy
            cd ../..
            log "Dependências do Core atualizadas"
        fi
        
        if [ -f "modules/sysmonitor/go.mod" ]; then
            cd modules/sysmonitor
            go mod tidy
            cd ../..
            log "Dependências do SysMonitor atualizadas"
        fi
        
        if [ -f "modules/tasksync/go.mod" ]; then
            cd modules/tasksync
            go mod tidy
            cd ../..
            log "Dependências do TaskSync atualizadas"
        fi
    else
        warn "Go não encontrado. Módulos Go não foram verificados."
    fi
    
    # Node.js modules
    if command -v npm &> /dev/null; then
        log "Verificando módulos Node.js..."
        
        if [ -f "modules/scheduler/package.json" ]; then
            cd modules/scheduler
            npm install
            cd ../..
            log "Dependências do Scheduler instaladas"
        fi
    else
        warn "npm não encontrado. Módulos Node.js não foram verificados."
    fi
    
    # Python modules (será instalado no container)
    if command -v pip3 &> /dev/null && [ -f "modules/nlp/requirements.txt" ]; then
        log "Verificando dependências Python..."
        # Não instalar aqui, será feito no container
        log "Dependências Python serão instaladas no container Docker"
    fi
    
    success "Dependências verificadas"
}

# Configurar rede e portas
setup_network() {
    step 5 "Configurando rede e verificando portas"
    
    # Verificar portas em uso
    ports_to_check=(1100 1200 1300 1301 1302 1700 1800 1801 6379)
    
    for port in "${ports_to_check[@]}"; do
        if netstat -tln 2>/dev/null | grep -q ":$port "; then
            warn "Porta $port já está em uso"
        fi
    done
    
    # Criar rede Docker se não existir
    if ! docker network ls | grep -q "aloy_network"; then
        log "Criando rede Docker..."
        docker network create aloy_network 2>/dev/null || true
    fi
    
    success "Rede configurada"
}

# Preparar banco de dados
setup_database() {
    step 6 "Preparando banco de dados"
    
    # Verificar se o script de inicialização existe
    if [ ! -f "docker/postgres/init.sql" ]; then
        error "Script de inicialização do banco não encontrado"
        exit 1
    fi
    
    log "Script de inicialização do PostgreSQL preparado"
    success "Banco de dados preparado"
}

# Construir imagens Docker
build_images() {
    step 7 "Construindo imagens Docker"
    
    log "Isso pode levar alguns minutos..."
    
    # Construir imagens em paralelo quando possível
    if docker-compose build --parallel 2>/dev/null; then
        log "Imagens construídas em paralelo"
    else
        log "Construindo imagens sequencialmente..."
        docker-compose build
    fi
    
    success "Imagens Docker construídas"
}

# Finalizar configuração
finalize_setup() {
    step 8 "Finalizando configuração"
    
    # Criar arquivo de status
    cat > .aloy_setup_complete << EOF
Setup completed at: $(date)
Version: 1.0.0
Environment: development
EOF
    
    success "Configuração finalizada"
}

# Mostrar informações finais
show_final_info() {
    echo ""
    echo -e "${GREEN}🎉 Configuração da Aloy concluída com sucesso!${NC}"
    echo ""
    echo -e "${BLUE}📋 Próximos passos:${NC}"
    echo ""
    echo "1. 🔧 Editar configurações (opcional):"
    echo "   vim .env"
    echo ""
    echo "2. 🚀 Iniciar aplicação:"
    echo "   make start       # Produção completa"
    echo "   make dev         # Desenvolvimento (apenas bancos)"
    echo ""
    echo "3. 📊 Verificar status:"
    echo "   make status      # Status dos serviços"
    echo "   make logs        # Ver logs"
    echo ""
    echo "4. 🌐 Acessar serviços:"
    echo "   Core API:        http://localhost:1100"
    echo "   NLP Service:     http://localhost:1200"
    echo "   System Monitor:  http://localhost:1300"
    echo "   RabbitMQ UI:     http://localhost:1801"
    echo ""
    echo "5. 📚 Comandos úteis:"
    echo "   make help        # Ver todos os comandos"
    echo "   make env-help    # Gerenciar ambiente"
    echo "   make urls        # Ver todas as URLs"
    echo ""
    echo -e "${YELLOW}💡 Dica: Use 'make help' para ver todos os comandos disponíveis${NC}"
    echo ""
    echo -e "${PURPLE}🚀 Aloy está pronto para uso!${NC}"
}

# Função principal
main() {
    echo "🔧 Iniciando configuração da aplicação Aloy..."
    echo ""
    
    check_system
    setup_permissions
    setup_environment
    install_dependencies
    setup_network
    setup_database
    build_images
    finalize_setup
    
    show_final_info
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
