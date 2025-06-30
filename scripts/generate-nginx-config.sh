#!/bin/bash

# Script para gerar configuração do Nginx com variáveis de ambiente
# Uso: ./scripts/generate-nginx-config.sh

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# Carregar variáveis de ambiente
if [ -f ".env" ]; then
    source .env
else
    echo "Erro: Arquivo .env não encontrado"
    exit 1
fi

# Gerar configuração do Nginx
echo "Gerando configuração do Nginx com as portas atuais..."

envsubst '${ALOY_SCHEDULER_PORT} ${ALOY_TASK_SYNC_PORT}' < docker/nginx/nginx.conf.template > docker/nginx/nginx.conf

echo "✅ Configuração do Nginx gerada com sucesso!"
echo "📁 Arquivo: docker/nginx/nginx.conf"
