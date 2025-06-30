# Guia de Submódulos - Aloy Monorepo

Este documento explica como trabalhar com os submódulos git no projeto Aloy.

## Submódulos Configurados

Este monorepo contém os seguintes submódulos:

- **apps/core** - Aplicação principal (Go)
  - Repositório: <https://github.com/LuisMarchio03/aloy-core-go-v0>
  
- **modules/nlp** - Módulo de NLP (Python)
  - Repositório: <https://github.com/LuisMarchio03/aloy-nlp-python-v1>
  
- **modules/scheduler** - Módulo de agendamento (TypeScript/Node.js)
  - Repositório: <https://github.com/LuisMarchio03/aloy-scheduler>
  
- **modules/sysmonitor** - Monitor do sistema (Go)
  - Repositório: <https://github.com/LuisMarchio03/aloy-system-monitor-go-v0>
  
- **modules/tasksync** - Sincronizador de tarefas (Go)
  - Repositório: <https://github.com/LuisMarchio03/aloy-task-sync>

## Comandos Essenciais

### Primeira configuração (clone inicial)

```bash
# Clone o repositório principal
git clone git@github.com:LuisMarchio03/aloy-monorepo.git
cd aloy-monorepo

# Inicialize e baixe todos os submódulos
git submodule update --init --recursive
```

### Atualizar todos os submódulos

```bash
# Atualiza todos os submódulos para a versão mais recente
git submodule update --remote

# Commit das atualizações
git add .
git commit -m "update: submodules to latest versions"
git push
```

### Atualizar um submódulo específico

```bash
# Entre no diretório do submódulo
cd modules/nlp

# Faça pull das mudanças
git pull origin main

# Volte para o diretório principal
cd ../..

# Commit da atualização
git add modules/nlp
git commit -m "update: nlp module to latest version"
git push
```

### Trabalhar em um submódulo

```bash
# Entre no diretório do submódulo
cd modules/nlp

# Crie uma nova branch (se necessário)
git checkout -b feature/nova-funcionalidade

# Faça suas alterações e commits
git add .
git commit -m "feat: nova funcionalidade"

# Push para o repositório do submódulo
git push origin feature/nova-funcionalidade

# Volte para o diretório principal
cd ../..

# Atualize o ponteiro do submódulo no monorepo
git add modules/nlp
git commit -m "update: nlp module with new feature"
git push
```

### Verificar status dos submódulos

```bash
# Mostra o status de todos os submódulos
git submodule status

# Mostra mudanças não commitadas nos submódulos
git submodule foreach 'git status'
```

### Executar comandos em todos os submódulos

```bash
# Executa um comando em todos os submódulos
git submodule foreach 'comando'

# Exemplo: verificar branch atual de todos os submódulos
git submodule foreach 'git branch'

# Exemplo: fazer pull em todos os submódulos
git submodule foreach 'git pull origin main'
```

## Workflow Recomendado

1. **Para mudanças pequenas**: Trabalhe diretamente no repositório do submódulo
2. **Para mudanças grandes**: Use branches nos submódulos
3. **Sempre**: Commit as atualizações dos ponteiros dos submódulos no monorepo
4. **Regularmente**: Atualize os submódulos para as versões mais recentes

## Resolução de Problemas

### Submódulo não inicializado

```bash
git submodule update --init modules/nome-do-modulo
```

### Submódulo com mudanças não commitadas

```bash
cd modules/nome-do-modulo
git stash  # ou git commit
cd ../..
```

### Reset de submódulo para versão commitada

```bash
git submodule update --force modules/nome-do-modulo
```

## Notas Importantes

- Submódulos sempre apontam para commits específicos, não para branches
- Mudanças nos submódulos devem ser commitadas tanto no repositório do submódulo quanto no monorepo
- Ao fazer pull do monorepo, execute `git submodule update` para sincronizar os submódulos
- Evite editar arquivos diretamente nos diretórios dos submódulos sem fazer commit
