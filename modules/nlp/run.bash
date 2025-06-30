#!/bin/bash
# Script melhorado para iniciar o serviço Aloy NLP API
# Este script verifica o ambiente, instala dependências e inicia o serviço

echo "=== Iniciando configuração do serviço Aloy NLP API ==="

# Verificando se o arquivo .env.local existe
if [ ! -f .env.local ]; then
    echo "ERRO: Arquivo .env.local não encontrado."
    echo "Crie um arquivo .env.local baseado no .env.example antes de continuar."
    exit 1
fi

USE_VENV=true

# Verificando se python3-venv está instalado
python3 -m venv --help > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "AVISO: O pacote python3-venv não está instalado."
    echo "Para instalar no Ubuntu/Debian, execute:"
    echo "    sudo apt install python3-venv"
    echo ""
    echo "Continuando sem ambiente virtual..."
    USE_VENV=false
fi

# Se estamos usando ambiente virtual, configurá-lo
if [ "$USE_VENV" = true ]; then
    # Verificando se o ambiente virtual já existe
    if [ ! -d .venv ]; then
        echo "Ambiente virtual não encontrado. Criando..."
        python3 -m venv .venv
        if [ $? -ne 0 ]; then
            echo "AVISO: Falha ao criar ambiente virtual."
            echo "Continuando sem ambiente virtual..."
            USE_VENV=false
        else
            echo "Ambiente virtual criado com sucesso."
        fi
    fi

    # Ativando o ambiente virtual (se disponível)
    if [ "$USE_VENV" = true ]; then
        echo "Ativando ambiente virtual..."
        source .venv/bin/activate
        if [ $? -ne 0 ]; then
            echo "AVISO: Falha ao ativar ambiente virtual."
            echo "Continuando sem ambiente virtual..."
            USE_VENV=false
        fi
    fi
fi

# Exibindo status do ambiente
if [ "$USE_VENV" = true ]; then
    echo "Usando ambiente virtual Python."
else
    echo "Usando instalação global do Python."
fi

# Verificando e instalando dependências
echo "Instalando dependências..."
pip install -r requirements.txt
if [ $? -ne 0 ]; then
    echo "AVISO: Houve problemas ao instalar algumas dependências."
    echo "O serviço pode não funcionar corretamente."
    echo "Tentando continuar mesmo assim..."
fi

# Carregando modelo do SpaCy configurado no .env.local
echo "Verificando modelo SpaCy..."
SPACY_MODEL=$(grep SPACY_MODEL .env.local | cut -d '=' -f2 | tr -d '"' | tr -d "'")
if [ -z "$SPACY_MODEL" ]; then
    echo "AVISO: SPACY_MODEL não definido no .env.local. Usando modelo padrão 'pt_core_news_sm'."
    SPACY_MODEL="pt_core_news_sm"
fi

# Tentando verificar se o modelo SpaCy está instalado
python3 -c "import spacy; spacy.load('$SPACY_MODEL')" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Modelo SpaCy '$SPACY_MODEL' não encontrado. Tentando instalar..."
    python3 -m spacy download $SPACY_MODEL
    if [ $? -ne 0 ]; then
        echo "AVISO: Falha ao instalar modelo SpaCy '$SPACY_MODEL'."
        echo "O serviço pode não funcionar corretamente com classificação."
        echo "Tentando continuar mesmo assim..."
    fi
fi

# Carregando variáveis de ambiente do .env.local
echo "Carregando variáveis de ambiente..."
# Extraindo variáveis sem usar 'export' para compatibilidade
while IFS= read -r line || [[ -n "$line" ]]; do
    # Ignorar linhas em branco ou comentários
    if [[ ! "$line" =~ ^[[:space:]]*# && -n "$line" ]]; then
        # Extrair apenas a parte antes de qualquer comentário
        clean_line=$(echo "$line" | sed 's/#.*$//')
        # Dividir em nome e valor
        var_name=$(echo "$clean_line" | cut -d '=' -f1)
        var_value=$(echo "$clean_line" | cut -d '=' -f2-)
        # Remover espaços em branco
        var_name=$(echo "$var_name" | xargs)
        var_value=$(echo "$var_value" | xargs)
        # Remover aspas se presentes
        var_value=$(echo "$var_value" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
        # Verificar se não está vazio
        if [ -n "$var_name" ] && [ -n "$var_value" ]; then
            # Exportar a variável
            echo "  - Carregando: $var_name"
            export "$var_name=$var_value"
        fi
    fi
done < .env.local

# Verificando se as variáveis necessárias foram carregadas
if [ -z "$NLP_API_HOST" ] || [ -z "$NLP_API_PORT" ]; then
    echo "AVISO: Variáveis NLP_API_HOST e/ou NLP_API_PORT não definidas no .env.local."
    echo "Usando valores padrão: 0.0.0.0:1200"
    export NLP_API_HOST=${NLP_API_HOST:-"0.0.0.0"}
    export NLP_API_PORT=${NLP_API_PORT:-"1200"}
fi

# Verificando se o LM Studio está rodando (opcional)
CHECK_LM_STUDIO=${CHECK_LM_STUDIO:-"false"}
if [ "$CHECK_LM_STUDIO" = "true" ]; then
    echo "Verificando conexão com LM Studio..."
    LM_STUDIO_HOST=${LM_STUDIO_HOST:-localhost}
    LM_STUDIO_PORT=${LM_STUDIO_PORT:-11434}
    
    curl -s "http://$LM_STUDIO_HOST:$LM_STUDIO_PORT/v1/models" > /dev/null
    if [ $? -ne 0 ]; then
        echo "AVISO: Não foi possível conectar ao LM Studio em $LM_STUDIO_HOST:$LM_STUDIO_PORT."
        echo "Certifique-se que o LM Studio está rodando para comandos que dependem de LLM."
        echo "Comandos diretos como 'lamp_control' funcionarão mesmo sem o LLM."
    else
        echo "Conexão com LM Studio estabelecida com sucesso."
    fi
else
    echo "AVISO: Verificação de conexão com LM Studio desativada."
    echo "Comandos diretos como 'lamp_control' funcionarão mesmo sem o LLM."
fi

# Iniciando o serviço
echo ""
echo "=== Iniciando o serviço Aloy NLP API ==="
echo "Host: $NLP_API_HOST"
echo "Porta: $NLP_API_PORT"
echo "Processamento direto: habilitado para comandos de lâmpada"
echo ""
echo "Digite Ctrl+C para encerrar o serviço"
echo ""

# Executar o script Python ou direto com uvicorn
if [ -f run.py ]; then
    python3 run.py
else
    # Alternativa usando uvicorn diretamente
    python3 -m uvicorn app.main:app --host $NLP_API_HOST --port $NLP_API_PORT --reload
fi