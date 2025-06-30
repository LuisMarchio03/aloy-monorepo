# Aloy Task Sync - Configuração de Ambientes

Este documento explica como configurar os arquivos de ambiente para o Aloy Task Sync.

## 📁 Estrutura de Configuração

O projeto suporta dois níveis de configuração de ambiente:

```
Aloy-Microservices/                    # Pasta pai (configuração global)
├── .env.local                         # Configurações globais (opcional)
└── aloy-task-sync/                    # Este projeto
    ├── .env.local                     # Configurações específicas do projeto
    ├── .env.example                   # Exemplo de configurações locais
```

## 🔧 Configuração Inicial

### 1. Configuração Local (Projeto)

Copie o arquivo de exemplo e configure:

```bash
cp .env.example .env.local
```

Edite o arquivo `.env.local` com suas configurações:

```env
# Caminhos obrigatórios
ALOY_REPO_PATH=/seu/caminho/para/aloy-tasks
OBSIDIAN_PATH=/seu/caminho/para/obsidian/vault

# Configurações do Git (opcional)
ALOY_GIT_USERNAME=seu-usuario
ALOY_GIT_TOKEN=seu-token-github

# Configurações de desenvolvimento
ALOY_LOG_LEVEL=info
ALOY_VERBOSE=false
ALOY_DRY_RUN=false
```

### 2. Configuração Global (Opcional)

Para compartilhar configurações entre projetos Aloy, crie um arquivo global:

```bash
# Vá para a pasta pai
cd ..
cp aloy-task-sync/.env.global.example .env.local
```

## 🏷️ Variáveis de Ambiente

### Obrigatórias

| Variável | Descrição | Exemplo |
|----------|-----------|---------|
| `ALOY_REPO_PATH` | Caminho para o repositório de tasks | `/home/user/aloy-tasks` |
| `OBSIDIAN_PATH` | Caminho para o vault do Obsidian | `/home/user/Documents/Obsidian/Aloy` |

### Opcionais

| Variável | Descrição | Padrão | Exemplo |
|----------|-----------|---------|---------|
| `ALOY_GIT_REPO_URL` | URL do repositório Git | `https://github.com/LuisMarchio03/aloy-tasks-repo.git` | - |
| `ALOY_GIT_USERNAME` | Usuário do Git para commits | - | `seu-usuario` |
| `ALOY_GIT_TOKEN` | Token de acesso do GitHub | - | `ghp_xxxxxxxxxxxx` |
| `ALOY_LOG_LEVEL` | Nível de log | `info` | `debug`, `info`, `warn`, `error` |
| `ALOY_VERBOSE` | Modo verboso | `false` | `true`, `false` |
| `ALOY_DRY_RUN` | Modo simulação | `false` | `true`, `false` |
| `ALOY_AUTO_COMMIT` | Commit automático | `true` | `true`, `false` |
| `ALOY_AUTO_SYNC` | Sincronização automática | `true` | `true`, `false` |

## 📋 Prioridade de Carregamento

As configurações são carregadas na seguinte ordem (a última sobrescreve a anterior):

1. `../env` (global)
2. `./.env` (local)
3. `../.env.local` (global local)
4. `./.env.local` (projeto local)

## 🚀 Comandos de Configuração

### Visualizar configuração atual
```bash
aloy config show
```

### Validar configuração
```bash
aloy config validate
```

### Executar em modo verboso
```bash
aloy sync --verbose
```

### Executar em modo simulação
```bash
aloy sync --dry-run
```

## 🔒 Segurança

⚠️ **Importante**: 

- Nunca commite arquivos `.env.local` 
- Use `.env.example` para documentar configurações necessárias
- Tokens e senhas devem ficar apenas nos arquivos `.env.local`
- O `.gitignore` já está configurado para ignorar arquivos de ambiente

## 🛠️ Exemplos de Uso

### Configuração para Desenvolvimento
```env
ALOY_REPO_PATH=/home/dev/aloy-tasks-dev
OBSIDIAN_PATH=/home/dev/Documents/Obsidian/Aloy-Dev
ALOY_LOG_LEVEL=debug
ALOY_VERBOSE=true
ALOY_DRY_RUN=true
```

### Configuração para Produção
```env
ALOY_REPO_PATH=/srv/aloy/tasks
OBSIDIAN_PATH=/srv/aloy/obsidian
ALOY_LOG_LEVEL=info
ALOY_VERBOSE=false
ALOY_AUTO_COMMIT=true
```

## 🐛 Solução de Problemas

### Erro: "ALOY_REPO_PATH é obrigatório"
- Verifique se a variável está definida no arquivo `.env.local`
- Execute `aloy config show` para ver a configuração atual

### Erro: "não foi possível criar diretório"
- Verifique as permissões dos diretórios pai
- Certifique-se que os caminhos são válidos

### Configuração não está sendo carregada
- Verifique a localização dos arquivos `.env.local`
- Execute com `--verbose` para ver quais arquivos foram carregados
- Verifique se há caracteres especiais nos valores das variáveis
