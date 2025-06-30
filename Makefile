# Makefile para gerenciar a aplicação Aloy

.PHONY: help setup start stop restart status logs clean build test dev prod

# Variáveis
DOCKER_COMPOSE = docker-compose
DOCKER_COMPOSE_DEV = docker-compose -f docker-compose.dev.yml
PROJECT_NAME = aloy

# Cores para output
GREEN = \033[32m
YELLOW = \033[33m
RED = \033[31m
BLUE = \033[34m
NC = \033[0m

# Comando padrão
help: ## Mostrar ajuda
	@echo "$(BLUE)🚀 Aloy - Sistema de Automação$(NC)"
	@echo ""
	@echo "$(GREEN)Comandos disponíveis:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""

setup: ## Configurar ambiente inicial
	@echo "$(BLUE)🔧 Configurando ambiente inicial...$(NC)"
	@chmod +x scripts/*.sh
	@cp -n .env.example .env.bak 2>/dev/null || true
	@./scripts/env-manager.sh generate --force
	@echo "$(GREEN)✅ Ambiente configurado!$(NC)"
	@echo "$(YELLOW)📝 Edite o arquivo .env com suas configurações$(NC)"
	@echo "$(YELLOW)💡 Use 'make env-help' para gerenciar variáveis de ambiente$(NC)"

dev: ## Iniciar ambiente de desenvolvimento (apenas bancos)
	@echo "$(BLUE)🔧 Iniciando ambiente de desenvolvimento...$(NC)"
	@./scripts/start.sh dev

start: ## Iniciar aplicação completa (produção)
	@echo "$(BLUE)🚀 Iniciando aplicação completa...$(NC)"
	@./scripts/start.sh prod

stop: ## Parar todos os serviços
	@echo "$(BLUE)🛑 Parando serviços...$(NC)"
	@./scripts/stop.sh all

restart: ## Reiniciar aplicação
	@echo "$(BLUE)🔄 Reiniciando aplicação...$(NC)"
	@make stop
	@sleep 2
	@make start

status: ## Verificar status dos serviços
	@echo "$(BLUE)📊 Verificando status...$(NC)"
	@./scripts/health.sh

logs: ## Mostrar logs (uso: make logs SERVICE=core)
	@echo "$(BLUE)📋 Mostrando logs...$(NC)"
	@./scripts/logs.sh $(SERVICE)

logs-follow: ## Seguir logs em tempo real (uso: make logs-follow SERVICE=core)
	@echo "$(BLUE)📋 Seguindo logs...$(NC)"
	@./scripts/logs.sh $(SERVICE) -f

build: ## Construir imagens Docker
	@echo "$(BLUE)🔨 Construindo imagens...$(NC)"
	@$(DOCKER_COMPOSE) build

rebuild: ## Reconstruir imagens sem cache
	@echo "$(BLUE)🔨 Reconstruindo imagens...$(NC)"
	@$(DOCKER_COMPOSE) build --no-cache

clean: ## Limpar containers e imagens
	@echo "$(BLUE)🧹 Limpando recursos...$(NC)"
	@./scripts/cleanup.sh all

clean-containers: ## Limpar apenas containers
	@echo "$(BLUE)🧹 Limpando containers...$(NC)"
	@./scripts/cleanup.sh containers

clean-images: ## Limpar apenas imagens
	@echo "$(BLUE)🧹 Limpando imagens...$(NC)"
	@./scripts/cleanup.sh images

clean-volumes: ## Limpar volumes (CUIDADO: dados serão perdidos)
	@echo "$(RED)⚠️  CUIDADO: Isso irá remover todos os dados!$(NC)"
	@read -p "Tem certeza? [y/N]: " confirm && [ "$$confirm" = "y" ] || exit 1
	@./scripts/cleanup.sh volumes

# Comandos de gerenciamento de ambiente
env-help: ## Mostrar ajuda do gerenciador de ambiente
	@./scripts/env-manager.sh --help

env-sync: ## Sincronizar variáveis de ambiente globais com módulos
	@echo "$(BLUE)🔄 Sincronizando variáveis de ambiente...$(NC)"
	@./scripts/env-manager.sh sync

env-validate: ## Validar arquivos .env
	@echo "$(BLUE)✅ Validando arquivos .env...$(NC)"
	@./scripts/env-manager.sh validate

env-check: ## Verificar se todas as variáveis necessárias estão definidas
	@echo "$(BLUE)🔍 Verificando variáveis de ambiente...$(NC)"
	@./scripts/env-manager.sh check

env-list: ## Listar todas as variáveis por módulo
	@echo "$(BLUE)📋 Listando variáveis de ambiente...$(NC)"
	@./scripts/env-manager.sh list

env-backup: ## Fazer backup dos arquivos .env
	@echo "$(BLUE)💾 Fazendo backup dos arquivos .env...$(NC)"
	@./scripts/env-manager.sh backup

env-restore: ## Restaurar backup dos arquivos .env
	@echo "$(BLUE)🔄 Restaurando backup dos arquivos .env...$(NC)"
	@./scripts/env-manager.sh restore

env-template: ## Gerar templates .env.example para cada módulo
	@echo "$(BLUE)📝 Gerando templates .env.example...$(NC)"
	@./scripts/env-manager.sh template

# Comandos específicos de desenvolvimento
dev-core: ## Executar Core em modo dev
	@echo "$(BLUE)🔧 Iniciando Core em modo desenvolvimento...$(NC)"
	@cd apps/core && go run cmd/main.go

dev-nlp: ## Executar NLP em modo dev
	@echo "$(BLUE)🔧 Iniciando NLP em modo desenvolvimento...$(NC)"
	@cd modules/nlp && python run.py

dev-scheduler: ## Executar Scheduler em modo dev
	@echo "$(BLUE)🔧 Iniciando Scheduler em modo desenvolvimento...$(NC)"
	@cd modules/scheduler && npm run dev

dev-sysmonitor: ## Executar SysMonitor em modo dev
	@echo "$(BLUE)🔧 Iniciando SysMonitor em modo desenvolvimento...$(NC)"
	@cd modules/sysmonitor && go run cmd/main.go

dev-tasksync: ## Executar TaskSync em modo dev
	@echo "$(BLUE)🔧 Iniciando TaskSync em modo desenvolvimento...$(NC)"
	@cd modules/tasksync && go run cmd/main.go

# Comandos de teste
test: ## Executar todos os testes
	@echo "$(BLUE)🧪 Executando testes...$(NC)"
	@make test-core
	@make test-nlp
	@make test-scheduler
	@make test-sysmonitor
	@make test-tasksync

test-core: ## Testar Core service
	@echo "$(BLUE)🧪 Testando Core...$(NC)"
	@cd apps/core && go test -v ./...

test-nlp: ## Testar NLP service
	@echo "$(BLUE)🧪 Testando NLP...$(NC)"
	@cd modules/nlp && python -m pytest tests/ -v

test-scheduler: ## Testar Scheduler service
	@echo "$(BLUE)🧪 Testando Scheduler...$(NC)"
	@cd modules/scheduler && npm test

test-sysmonitor: ## Testar SysMonitor service
	@echo "$(BLUE)🧪 Testando SysMonitor...$(NC)"
	@cd modules/sysmonitor && go test -v ./...

test-tasksync: ## Testar TaskSync service
	@echo "$(BLUE)🧪 Testando TaskSync...$(NC)"
	@cd modules/tasksync && go test -v ./...

# Comandos de manutenção
install-deps: ## Instalar dependências de desenvolvimento
	@echo "$(BLUE)📦 Instalando dependências...$(NC)"
	@cd apps/core && go mod tidy
	@cd modules/nlp && pip install -r requirements.txt
	@cd modules/scheduler && npm install
	@cd modules/sysmonitor && go mod tidy
	@cd modules/tasksync && go mod tidy

update-deps: ## Atualizar dependências
	@echo "$(BLUE)⬆️  Atualizando dependências...$(NC)"
	@cd apps/core && go get -u ./...
	@cd modules/nlp && pip install -r requirements.txt --upgrade
	@cd modules/scheduler && npm update
	@cd modules/sysmonitor && go get -u ./...
	@cd modules/tasksync && go get -u ./...

backup: ## Fazer backup dos volumes de dados
	@echo "$(BLUE)💾 Fazendo backup...$(NC)"
	@mkdir -p backups
	@docker run --rm -v aloy_postgres_data:/data -v $(PWD)/backups:/backup alpine tar czf /backup/postgres_$(shell date +%Y%m%d_%H%M%S).tar.gz -C /data .
	@docker run --rm -v aloy_rabbitmq_data:/data -v $(PWD)/backups:/backup alpine tar czf /backup/rabbitmq_$(shell date +%Y%m%d_%H%M%S).tar.gz -C /data .
	@echo "$(GREEN)✅ Backup concluído em ./backups/$(NC)"

# Comandos de monitoramento
ps: ## Listar containers em execução
	@echo "$(BLUE)📋 Containers em execução:$(NC)"
	@docker ps --filter "name=aloy_" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

images: ## Listar imagens do projeto
	@echo "$(BLUE)📋 Imagens do projeto:$(NC)"
	@docker images --filter "reference=aloy*" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

volumes: ## Listar volumes do projeto
	@echo "$(BLUE)📋 Volumes do projeto:$(NC)"
	@docker volume ls --filter "name=aloy" --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}"

# Comandos de acesso
shell-core: ## Acessar shell do container Core
	@docker exec -it aloy_core sh

shell-nlp: ## Acessar shell do container NLP
	@docker exec -it aloy_nlp bash

shell-scheduler: ## Acessar shell do container Scheduler
	@docker exec -it aloy_scheduler sh

shell-postgres: ## Acessar shell do PostgreSQL
	@docker exec -it aloy_postgres psql -U aloy -d aloy

shell-redis: ## Acessar shell do Redis
	@docker exec -it aloy_redis redis-cli -a aloy123

# Comandos para URLs úteis
urls: ## Mostrar URLs dos serviços
	@echo "$(BLUE)🌐 URLs dos serviços:$(NC)"
	@echo "  Core API:           http://localhost:1100"
	@echo "  NLP Service:        http://localhost:1200"
	@echo "  System Monitor:     http://localhost:1300"
	@echo "  Scheduler:          http://localhost:1301"
	@echo "  Task Sync:          http://localhost:1302"
	@echo "  Nginx (Proxy):      http://localhost"
	@echo "  RabbitMQ Mgmt:      http://localhost:1801 (aloy/aloy123)"
	@echo "  PostgreSQL:         localhost:1700 (aloy/aloy123)"
	@echo "  Redis:              localhost:6379 (senha: aloy123)"
