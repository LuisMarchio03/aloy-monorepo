# 🐳 Docker Setup - Aloy Platform

Este documento explica como executar a aplicação Aloy usando Docker e Docker Compose.

## 📋 Pré-requisitos

- [Docker](https://docs.docker.com/get-docker/) 20.10+
- [Docker Compose](https://docs.docker.com/compose/install/) 2.0+
- Make (opcional, mas recomendado)

## 🚀 Início Rápido

### 1. Configuração Inicial

```bash
# Clonar o repositório
git clone <repository-url>
cd aloy

# Configurar ambiente
make setup
# ou
cp .env.example .env
chmod +x scripts/*.sh
```

### 2. Editar Configurações

Edite o arquivo `.env` com suas configurações:

```bash
vim .env  # ou seu editor preferido
```

### 3. Iniciar Aplicação

#### Desenvolvimento (apenas bancos de dados)

```bash
make dev
# ou
./scripts/start.sh dev
```

Isso iniciará apenas PostgreSQL, RabbitMQ e Redis. Você pode executar os serviços individualmente:

```bash
# Em terminais separados
make dev-core       # Core service
make dev-nlp        # NLP service  
make dev-scheduler  # Scheduler service
make dev-sysmonitor # System Monitor
make dev-tasksync   # Task Sync
```

#### Produção (aplicação completa)

```bash
make start
# ou
./scripts/start.sh prod
```

## 📊 Monitoramento

### Verificar Status

```bash
make status
# ou
./scripts/health.sh
```

### Ver Logs

```bash
# Todos os serviços
make logs

# Serviço específico
make logs SERVICE=core
make logs SERVICE=nlp

# Seguir logs em tempo real
make logs-follow SERVICE=core
```

### Listar Containers

```bash
make ps
```

## 🛠️ Comandos Úteis

### Gerenciamento

```bash
make start          # Iniciar aplicação completa
make dev            # Iniciar ambiente de desenvolvimento
make stop           # Parar todos os serviços
make restart        # Reiniciar aplicação
make status         # Verificar status
```

### Build e Deploy

```bash
make build          # Construir imagens
make rebuild        # Reconstruir sem cache
```

### Limpeza

```bash
make clean          # Limpar tudo
make clean-containers # Limpar apenas containers
make clean-images   # Limpar apenas imagens
make clean-volumes  # Limpar volumes (DADOS SERÃO PERDIDOS!)
```

### Testes

```bash
make test           # Executar todos os testes
make test-core      # Testar apenas Core
make test-nlp       # Testar apenas NLP
```

### Acesso aos Containers

```bash
make shell-core     # Shell do Core
make shell-nlp      # Shell do NLP
make shell-postgres # Shell do PostgreSQL
make shell-redis    # Shell do Redis
```

## 🌐 URLs dos Serviços

Após iniciar a aplicação, os serviços estarão disponíveis em:

### Aplicação

- **API Principal**: http://localhost (via Nginx)
- **Core API**: http://localhost:8080
- **NLP Service**: http://localhost:8001
- **System Monitor**: http://localhost:8002

### Infraestrutura

- **RabbitMQ Management**: http://localhost:15672
  - Usuário: `aloy`
  - Senha: `aloy123`
- **PostgreSQL**: `localhost:5432`
  - Database: `aloy`
  - Usuário: `aloy`
  - Senha: `aloy123`
- **Redis**: `localhost:6379`
  - Senha: `aloy123`

## 🏗️ Arquitetura

### Serviços

```mermaid
graph TB
    subgraph "Load Balancer"
        nginx[Nginx]
    end
    
    subgraph "Application Services"
        core[Core Service<br/>Go - Port 8080]
        nlp[NLP Service<br/>Python - Port 8001]
        sysmonitor[System Monitor<br/>Go - Port 8002]
        scheduler[Scheduler<br/>Node.js]
        tasksync[Task Sync<br/>Go]
    end
    
    subgraph "Data Layer"
        postgres[(PostgreSQL<br/>Port 5432)]
        redis[(Redis<br/>Port 6379)]
        rabbitmq[RabbitMQ<br/>Port 5672/15672]
    end
    
    nginx --> core
    nginx --> nlp
    nginx --> sysmonitor
    
    core --> postgres
    core --> redis
    core --> rabbitmq
    
    nlp --> redis
    nlp --> rabbitmq
    
    scheduler --> postgres
    scheduler --> rabbitmq
    
    sysmonitor --> redis
    sysmonitor --> rabbitmq
    
    tasksync --> postgres
    tasksync --> rabbitmq
```

### Volumes

- `postgres_data`: Dados do PostgreSQL
- `rabbitmq_data`: Dados do RabbitMQ
- `redis_data`: Dados do Redis

### Networks

- `aloy_network`: Rede interna para comunicação entre serviços

## 🔧 Configuração Avançada

### Variáveis de Ambiente

Principais variáveis no `.env`:

```bash
# Banco de dados
DB_HOST=postgres
DB_PORT=5432
DB_NAME=aloy
DB_USER=aloy
DB_PASSWORD=aloy123

# RabbitMQ
RABBITMQ_URL=amqp://aloy:aloy123@rabbitmq:5672/

# Redis
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=aloy123

# Portas dos serviços
CORE_PORT=8080
NLP_PORT=8001
SYSMONITOR_PORT=8002
```

### Customização de Portas

Para alterar as portas expostas, edite o `docker-compose.yml`:

```yaml
services:
  core:
    ports:
      - "8080:8080"  # host:container
```

### Escalabilidade

Para escalar serviços:

```bash
docker-compose up -d --scale core=3 --scale nlp=2
```

## 🚨 Troubleshooting

### Problemas Comuns

#### 1. Porta já em uso

```bash
# Verificar qual processo está usando a porta
sudo lsof -i :8080

# Parar todos os containers
make stop
```

#### 2. Problemas de permissão

```bash
# Dar permissão aos scripts
chmod +x scripts/*.sh

# Problemas com volumes
sudo chown -R $USER:$USER .
```

#### 3. Containers não iniciam

```bash
# Ver logs detalhados
make logs SERVICE=core

# Verificar recursos do sistema
docker system df
docker system prune -f
```

#### 4. Banco de dados não conecta

```bash
# Verificar se PostgreSQL está rodando
make shell-postgres

# Reiniciar apenas o banco
docker-compose restart postgres
```

### Logs de Debug

Para debug mais detalhado:

```bash
# Logs com timestamp
docker-compose logs -f -t

# Logs de um serviço específico
docker-compose logs -f core

# Logs desde um horário específico
docker-compose logs --since "2023-01-01T00:00:00"
```

## 🔒 Segurança

### Em Produção

1. **Altere senhas padrão** no `.env`
2. **Use SSL/TLS** para conexões externas
3. **Configure firewall** para expor apenas portas necessárias
4. **Atualize regularmente** as imagens base
5. **Configure backup** dos volumes de dados

### Backup e Restore

```bash
# Fazer backup
make backup

# Restaurar backup (exemplo)
docker run --rm -v aloy_postgres_data:/data -v $(pwd)/backups:/backup alpine \
  tar xzf /backup/postgres_20231201_120000.tar.gz -C /data
```

## 📚 Referências

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [PostgreSQL Docker Hub](https://hub.docker.com/_/postgres)
- [RabbitMQ Docker Hub](https://hub.docker.com/_/rabbitmq)
- [Redis Docker Hub](https://hub.docker.com/_/redis)

---

Para mais informações sobre cada serviço, consulte a documentação específica em seus respectivos diretórios.
