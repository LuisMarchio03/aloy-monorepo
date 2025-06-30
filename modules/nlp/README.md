# Aloy NLP Python v1

Serviço de Processamento de Linguagem Natural para o ecossistema Aloy Microservices.

## 🔄 Comandos Suportados

O serviço atualmente suporta os seguintes comandos:

### 💡 Controle de Iluminação (`lamp_control`)

Permite controlar dispositivos de iluminação inteligente através de comandos de voz.

- **Ações suportadas:**
  - `turn_on` - Ligar/acender uma luz
  - `turn_off` - Desligar/apagar uma luz
  - `set_color` - Mudar a cor da luz
  - `set_intensity` - Ajustar o brilho/intensidade da luz

- **Exemplos de frases:**
  - "Acenda a luz do quarto"
  - "Apague a luz da sala"
  - "Mude a cor da lâmpada da sala para azul"
  - "Ajuste a intensidade da luz da cozinha para 50%"

- **Estrutura da resposta JSON:**
  ```json
  {
    "type": "lamp_control",
    "message": "Luz da sala acesa com sucesso",
    "data": {
      "action": "turn_on",
      "room": "sala",
      "color": "branco",
      "intensity": "100"
    }
  }
  ```

### ⏰ Alarme e Lembretes

Comandos para definir alarmes e lembretes ainda aguardando implementação completa.

## 🔍 Processamento de Comandos

O sistema possui dois métodos para processar comandos:

### ✅ Processamento Direto (Sem LLM)

Para comandos com formato conhecido e predefinido, como controle de lâmpadas, o sistema pode processar diretamente sem depender do LLM, garantindo:

- Menor latência na resposta
- Operação mesmo quando o LLM não está disponível
- Maior consistência nas respostas

Implementado para comandos:
- `lamp_control` - Controle completo de iluminação

### 🧠 Processamento via LLM

Para comandos mais complexos ou que necessitam interpretação avançada, o sistema utiliza o LLM configurado:

- Maior flexibilidade na interpretação
- Capacidade de lidar com linguagem natural ambígua
- Adaptabilidade a novos formatos de comando

## 🛠️ Configuração de Ambiente

O projeto utiliza variáveis de ambiente para configuração. Essas variáveis estão definidas no arquivo `.env.local`.

### Principais Configurações

```
# Configurações da API do NLP
NLP_API_HOST=0.0.0.0       # Host da API
NLP_API_PORT=1200          # Porta da API (padrão definido no arquivo global)

# Configurações do Modelo LLM
LLM_HOST=localhost         # Host do serviço LLM (LM Studio)
LLM_PORT=11434             # Porta do serviço LLM
LLM_URL=...                # URL completa do serviço LLM
LLM_MODEL_NAME=gemma:7b    # Nome do modelo LLM a ser utilizado
LLM_MAX_TOKENS=512         # Número máximo de tokens na resposta
LLM_TEMPERATURE=0.3        # Temperatura do modelo (criatividade)
LLM_TOP_P=0.95             # Top-p sampling

# Modelo SpaCy
SPACY_MODEL=pt_core_news_sm # Modelo SpaCy para processamento em PT-BR

# Logs e monitoramento
LOG_LEVEL=INFO             # Nível de log (DEBUG, INFO, WARNING, ERROR)
ENABLE_DEBUG=false         # Habilitar modo debug

# Verificação opcional do LM Studio
CHECK_LM_STUDIO=false      # Define se o script deve verificar conexão com LM Studio
```

## Instalação e Execução

1. Clone este repositório
2. Configure o arquivo `.env.local` conforme suas necessidades
3. Execute o script melhorado `run.bash`

```bash
# Usando o script bash (recomendado)
chmod +x run.bash
./run.bash

# OU usando o script Python diretamente (requer ambiente já configurado)
python3 run.py
```

O script `run.bash` agora:
- Verifica a existência do arquivo `.env.local`
- Cria/ativa o ambiente virtual automaticamente
- Instala dependências necessárias
- Verifica/instala o modelo SpaCy configurado
- Opcionalmente verifica a conexão com o LM Studio
- Inicia o serviço com as configurações apropriadas

## Integração com outros serviços

Este serviço se integra com:

- **Aloy Core API**: Recebe requisições e envia os comandos processados
- **LM Studio**: Modelo de linguagem para processamento avançado
- **SpaCy**: Processamento de linguagem natural para classificação e extração
- **Aloy Smarthome**: Execução dos comandos de controle de dispositivos inteligentes

## Arquitetura

- **app/main.py**: Endpoints da API FastAPI
- **app/config.py**: Carregamento de configurações do arquivo .env.local
- **app/services/**: Implementações dos serviços de NLP
  - **direct_commands.py**: Processamento direto de comandos sem uso de LLM
  - **orchestrator.py**: Orquestração do fluxo de processamento
  - **spacy_classifier.py**: Classificação de intenção usando SpaCy
  - **lmstudio_client.py**: Cliente para comunicação com LM Studio
  - **lamp_control.py**: Lógica específica para comandos de lâmpadas
- **app/schemas/**: Modelos de dados usando Pydantic
