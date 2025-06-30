# Aloy Monorepo

Um monorepo que contém múltiplos serviços e aplicações da plataforma Aloy.

## Estrutura do Projeto

```
aloy/
├── apps/
│   └── core/              # Aplicação principal em Go
├── modules/
│   ├── nlp/              # Módulo de processamento de linguagem natural (Python)
│   ├── scheduler/        # Módulo de agendamento (TypeScript/Node.js)
│   ├── sysmonitor/       # Módulo de monitoramento do sistema (Go)
│   └── tasksync/         # Módulo de sincronização de tarefas (Go)
├── configs/              # Configurações compartilhadas
├── docker/               # Arquivos Docker
└── shared/               # Recursos compartilhados
```

## Módulos

### Apps

- **core**: Aplicação principal desenvolvida em Go

### Modules

- **nlp**: Serviço de processamento de linguagem natural usando Python e spaCy
- **scheduler**: Serviço de agendamento desenvolvido em TypeScript/Node.js
- **sysmonitor**: Serviço de monitoramento do sistema em Go
- **tasksync**: Serviço de sincronização de tarefas em Go

## Pré-requisitos

- Go 1.19+
- Python 3.8+
- Node.js 16+
- Docker (opcional)

## Instalação e Execução

### 🐳 Docker (Recomendado)

A forma mais fácil de executar a aplicação Aloy é usando Docker:

```bash
# Configuração automática completa
./scripts/init.sh

# OU configuração manual
make setup
vim .env  # Editar configurações
make start
```

📚 **Para instruções detalhadas sobre Docker, consulte [DOCKER.md](./DOCKER.md)**

### 🔧 Desenvolvimento Local

1. Clone o repositório:

```bash
git clone git@github.com:LuisMarchio03/aloy-monorepo.git
cd aloy-monorepo
```

2. Inicialize os submódulos:

```bash
git submodule update --init --recursive
```

3. Configure cada módulo individualmente seguindo as instruções em seus respectivos diretórios.

**📖 Para instruções detalhadas sobre como trabalhar com submódulos, consulte [SUBMODULES.md](./SUBMODULES.md)**

### 🚀 Comandos Rápidos

```bash
# Ver todos os comandos disponíveis
make help

# Iniciar desenvolvimento
make dev
make dev-core      # Executar Core service
make dev-nlp       # Executar NLP service

# Produção
make start         # Iniciar tudo
make status        # Verificar status
make logs          # Ver logs
make stop          # Parar tudo

# Gerenciar ambiente
make env-sync      # Sincronizar .env
make env-check     # Verificar configuração
make env-backup    # Backup das configurações

# Manutenção
make clean         # Limpar containers
make backup        # Backup dos dados
```

## 🔧 Gerenciamento de Variáveis de Ambiente

O sistema Aloy usa um **sistema centralizado de variáveis de ambiente** com:

- **`.env` global**: Configurações compartilhadas por toda a aplicação
- **`.env` por módulo**: Configurações específicas de cada serviço
- **Sincronização automática**: As variáveis globais são propagadas automaticamente

### 📋 Portas do Sistema

```
Frontend:          1000-1099
APIs Principais:   1100-1199  (Core: 1100, Gateway: 1101)
NLP/AI:           1200-1299  (NLP: 1200, STT: 1201, TTS: 1202)
Serviços:         1300-1399  (Monitor: 1300, Scheduler: 1301)
Integrações:      1400-1499  (Google: 1400)
Ferramentas:      1500-1599  (Focalboard: 1500)
Monitoramento:    1600-1699  (Prometheus: 1600, Grafana: 1601)
Banco de Dados:   1700-1799  (Postgres: 1700, MinIO: 1701)
Mensageria:       1800-1899  (RabbitMQ: 1800/1801)
Desenvolvimento:  9000-9099  (Mocks: 9000)
```

📚 **Ver mapa completo de portas em [PORTS.md](./PORTS.md)**

### 🛠️ Comandos de Environment

```bash
make env-help      # Ajuda do gerenciador
make env-sync      # Sincronizar variáveis globais
make env-validate  # Validar arquivos .env
make env-list      # Listar todas as variáveis
make env-backup    # Backup das configurações
```

## Contribuição

1. Faça fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.
