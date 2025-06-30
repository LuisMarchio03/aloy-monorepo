#!/bin/bash
# Script para instalar dependências necessárias para o Aloy NLP

echo "=== Instalando dependências para Aloy NLP ==="

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then
    echo "Este script precisa ser executado como administrador (sudo)."
    echo "Por favor, execute: sudo $0"
    exit 1
fi

# Atualizando repositórios
echo "Atualizando listas de pacotes..."
apt update

# Instalando dependências
echo "Instalando dependências necessárias..."
apt install -y python3-pip python3-venv curl

# Verificando se instalou corretamente
python3 -m venv --help > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "ERRO: Falha ao instalar python3-venv!"
    exit 1
fi

echo "=== Dependências instaladas com sucesso! ==="
echo "Agora você pode executar ./run.bash para iniciar o serviço Aloy NLP."
