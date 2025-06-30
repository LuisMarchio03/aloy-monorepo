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

### Desenvolvimento Local

1. Clone o repositório:
```bash
git clone git@github.com:LuisMarchio03/aloy-monorepo.git
cd aloy-monorepo
```

2. Configure cada módulo individualmente seguindo as instruções em seus respectivos diretórios.

### Docker

Para executar com Docker, utilize os arquivos de configuração no diretório `docker/`.

## Contribuição

1. Faça fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.
