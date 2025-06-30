#!/bin/bash

# Script para executar os testes da API Aloy NLP
echo "=== Executando testes do Aloy NLP ==="

# Cria/ativa ambiente virtual se necessário
if [ ! -d .venv ]; then
    echo "Criando ambiente virtual..."
    python3 -m venv .venv || { echo "ERRO: Falha ao criar ambiente virtual"; exit 1; }
fi

echo "Ativando ambiente virtual..."
source .venv/bin/activate || { echo "ERRO: Falha ao ativar ambiente virtual"; exit 1; }

# Verificando dependências de teste
echo "Verificando dependências para testes..."
pip install -r requirements.txt

# Garante que o diretório atual está no PYTHONPATH
export PYTHONPATH=$PYTHONPATH:$(pwd)

# Executando testes
echo "Executando testes unitários..."
python -m unittest discover -s tests

# Executa teste de integração específico para comandos diretos
echo "Testando processamento direto de comandos de lâmpada..."
python -m tests.test_direct_commands

echo "Testes concluídos!"
