#!/bin/bash

# Script para gerenciar variáveis de ambiente da aplicação Aloy
# Uso: ./scripts/env-manager.sh [comando] [opções]

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

# Lista de módulos
MODULES=(
    "apps/core"
    "modules/nlp"
    "modules/scheduler"
    "modules/sysmonitor"
    "modules/tasksync"
)

# Função para mostrar ajuda
show_help() {
    echo "🔧 Gerenciador de Variáveis de Ambiente - Aloy"
    echo ""
    echo "Uso: $0 [comando] [opções]"
    echo ""
    echo "Comandos:"
    echo "  sync       - Sincronizar .env global com módulos"
    echo "  validate   - Validar arquivos .env"
    echo "  backup     - Fazer backup dos arquivos .env"
    echo "  restore    - Restaurar backup dos arquivos .env"
    echo "  generate   - Gerar novos arquivos .env a partir do template"
    echo "  list       - Listar todas as variáveis por módulo"
    echo "  check      - Verificar se todas as variáveis necessárias estão definidas"
    echo "  template   - Gerar templates .env.example para cada módulo"
    echo ""
    echo "Opções:"
    echo "  --module MODULE    - Executar apenas para um módulo específico"
    echo "  --force           - Forçar operação mesmo com conflitos"
    echo "  --dry-run         - Mostrar o que seria feito sem executar"
    echo ""
    echo "Exemplos:"
    echo "  $0 sync                    # Sincronizar todos os módulos"
    echo "  $0 sync --module core      # Sincronizar apenas o módulo core"
    echo "  $0 validate                # Validar todos os arquivos .env"
    echo "  $0 generate --force        # Gerar novos arquivos .env"
}

# Função para carregar variáveis do .env global
load_global_env() {
    if [ -f ".env" ]; then
        set -a
        source .env
        set +a
        log "Variáveis globais carregadas"
    else
        error "Arquivo .env global não encontrado"
        exit 1
    fi
}

# Função para sincronizar variáveis
sync_env() {
    local module=$1
    local force=$2
    local dry_run=$3
    
    if [ ! -d "$module" ]; then
        error "Módulo $module não encontrado"
        return 1
    fi
    
    local env_file="$module/.env"
    local template_file="$module/.env.template"
    
    log "Sincronizando $module..."
    
    if [ "$dry_run" = "true" ]; then
        log "[DRY RUN] Arquivo seria criado/atualizado: $env_file"
        return 0
    fi
    
    # Se existe template, usar ele, senão criar básico
    if [ -f "$template_file" ]; then
        log "Usando template existente para $module"
        envsubst < "$template_file" > "$env_file"
    else
        # Criar arquivo básico com substituição de variáveis
        case $module in
            "apps/core")
                envsubst < apps/core/.env > "$env_file.tmp" && mv "$env_file.tmp" "$env_file"
                ;;
            "modules/nlp")
                envsubst < modules/nlp/.env > "$env_file.tmp" && mv "$env_file.tmp" "$env_file"
                ;;
            "modules/scheduler")
                envsubst < modules/scheduler/.env > "$env_file.tmp" && mv "$env_file.tmp" "$env_file"
                ;;
            "modules/sysmonitor")
                envsubst < modules/sysmonitor/.env > "$env_file.tmp" && mv "$env_file.tmp" "$env_file"
                ;;
            "modules/tasksync")
                envsubst < modules/tasksync/.env > "$env_file.tmp" && mv "$env_file.tmp" "$env_file"
                ;;
        esac
    fi
    
    success "Sincronizado: $module"
}

# Função para validar arquivos .env
validate_env() {
    local module=$1
    local env_file="$module/.env"
    
    if [ ! -f "$env_file" ]; then
        error "Arquivo $env_file não encontrado"
        return 1
    fi
    
    # Verificar sintaxe básica
    if ! grep -qE "^[A-Z_]+=.*$" "$env_file"; then
        warn "Possível problema de sintaxe em $env_file"
    fi
    
    # Verificar variáveis vazias importantes
    local required_vars=()
    case $module in
        "apps/core")
            required_vars=("PORT" "DB_HOST" "DB_PORT" "RABBITMQ_URL")
            ;;
        "modules/nlp")
            required_vars=("PORT" "SPACY_MODEL")
            ;;
        "modules/scheduler")
            required_vars=("PORT" "DB_HOST" "TIMEZONE")
            ;;
        "modules/sysmonitor")
            required_vars=("PORT" "MONITOR_INTERVAL")
            ;;
        "modules/tasksync")
            required_vars=("PORT" "SYNC_INTERVAL" "ALOY_TASK_PATH")
            ;;
    esac
    
    for var in "${required_vars[@]}"; do
        if ! grep -q "^$var=" "$env_file" || grep -q "^$var=$" "$env_file"; then
            warn "Variável obrigatória $var não definida ou vazia em $module"
        fi
    done
    
    success "Validado: $module"
}

# Função para fazer backup
backup_env() {
    local backup_dir="backups/env_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    log "Fazendo backup dos arquivos .env..."
    
    # Backup do global
    if [ -f ".env" ]; then
        cp .env "$backup_dir/global.env"
    fi
    
    # Backup dos módulos
    for module in "${MODULES[@]}"; do
        if [ -f "$module/.env" ]; then
            local module_name=$(echo $module | tr '/' '_')
            cp "$module/.env" "$backup_dir/${module_name}.env"
        fi
    done
    
    success "Backup criado em: $backup_dir"
    echo "$backup_dir" > .last_env_backup
}

# Função para restaurar backup
restore_env() {
    local backup_dir=$1
    
    if [ -z "$backup_dir" ] && [ -f ".last_env_backup" ]; then
        backup_dir=$(cat .last_env_backup)
    fi
    
    if [ -z "$backup_dir" ] || [ ! -d "$backup_dir" ]; then
        error "Diretório de backup não especificado ou não encontrado"
        return 1
    fi
    
    log "Restaurando backup de: $backup_dir"
    
    # Restaurar global
    if [ -f "$backup_dir/global.env" ]; then
        cp "$backup_dir/global.env" .env
        log "Restaurado: .env global"
    fi
    
    # Restaurar módulos
    for module in "${MODULES[@]}"; do
        local module_name=$(echo $module | tr '/' '_')
        if [ -f "$backup_dir/${module_name}.env" ]; then
            cp "$backup_dir/${module_name}.env" "$module/.env"
            log "Restaurado: $module"
        fi
    done
    
    success "Backup restaurado"
}

# Função para gerar templates
generate_templates() {
    log "Gerando templates .env.example..."
    
    for module in "${MODULES[@]}"; do
        if [ -f "$module/.env" ]; then
            # Criar template removendo valores sensíveis
            sed 's/=.*/=/' "$module/.env" > "$module/.env.example"
            log "Template criado: $module/.env.example"
        fi
    done
    
    # Template global
    if [ -f ".env" ]; then
        sed 's/=.*/=/' .env > .env.example
        log "Template criado: .env.example"
    fi
    
    success "Templates gerados"
}

# Função para listar variáveis
list_vars() {
    local module=$1
    
    if [ -n "$module" ]; then
        if [ -f "$module/.env" ]; then
            echo "=== Variáveis de $module ==="
            cat "$module/.env" | grep -E "^[A-Z_]+=" | sort
            echo ""
        fi
    else
        echo "=== Variáveis Globais ==="
        if [ -f ".env" ]; then
            cat .env | grep -E "^[A-Z_]+=" | sort
        fi
        echo ""
        
        for mod in "${MODULES[@]}"; do
            if [ -f "$mod/.env" ]; then
                echo "=== Variáveis de $mod ==="
                cat "$mod/.env" | grep -E "^[A-Z_]+=" | sort
                echo ""
            fi
        done
    fi
}

# Função principal
main() {
    local command=${1:-help}
    local module=""
    local force=false
    local dry_run=false
    
    # Processar argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            --module)
                module="$2"
                shift 2
                ;;
            --force)
                force=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                if [ -z "$command" ] || [ "$command" = "help" ]; then
                    command="$1"
                fi
                shift
                ;;
        esac
    done
    
    case $command in
        sync)
            load_global_env
            if [ -n "$module" ]; then
                sync_env "$module" "$force" "$dry_run"
            else
                for mod in "${MODULES[@]}"; do
                    sync_env "$mod" "$force" "$dry_run"
                done
            fi
            ;;
        validate)
            if [ -n "$module" ]; then
                validate_env "$module"
            else
                for mod in "${MODULES[@]}"; do
                    validate_env "$mod"
                done
            fi
            ;;
        backup)
            backup_env
            ;;
        restore)
            restore_env "$2"
            ;;
        generate)
            load_global_env
            for mod in "${MODULES[@]}"; do
                sync_env "$mod" true "$dry_run"
            done
            ;;
        template)
            generate_templates
            ;;
        list)
            list_vars "$module"
            ;;
        check)
            log "Verificando arquivos .env..."
            local issues=0
            
            # Verificar global
            if [ ! -f ".env" ]; then
                error "Arquivo .env global não encontrado"
                issues=$((issues + 1))
            fi
            
            # Verificar módulos
            for mod in "${MODULES[@]}"; do
                if [ ! -f "$mod/.env" ]; then
                    error "Arquivo .env não encontrado em $mod"
                    issues=$((issues + 1))
                else
                    validate_env "$mod" || issues=$((issues + 1))
                fi
            done
            
            if [ $issues -eq 0 ]; then
                success "Todos os arquivos .env estão OK!"
            else
                error "Encontrados $issues problemas"
                exit 1
            fi
            ;;
        help|*)
            show_help
            ;;
    esac
}

# Executar função principal
main "$@"
