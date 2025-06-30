import os
import logging
from pathlib import Path
from dotenv import load_dotenv

# Configurando logger temporário para diagnóstico
logging.basicConfig(level=logging.INFO)
config_logger = logging.getLogger("config")

# Carregando variáveis de ambiente do .env.local
env_path = Path(__file__).parent.parent / ".env.local"
if env_path.exists():
    config_logger.info(f"Carregando variáveis de ambiente de {env_path}")
    load_dotenv(dotenv_path=env_path)
else:
    config_logger.warning(f"Arquivo .env.local não encontrado em {env_path}")
    config_logger.warning("Usando valores padrão para configuração")

# Função auxiliar para obter variáveis de ambiente com conversão de tipo segura
def get_env(key, default=None, type_converter=str):
    value = os.getenv(key, default)
    if value is None:
        return None
    
    try:
        # Limpa o valor de possíveis comentários ou espaços
        value = value.split('#')[0].strip()
        if type_converter == bool:
            return value.lower() in ('true', 'yes', '1', 'y')
        return type_converter(value)
    except (ValueError, TypeError) as e:
        config_logger.error(f"Erro ao converter variável {key}={value}: {str(e)}")
        config_logger.error(f"Usando valor padrão: {default}")
        return type_converter(default) if default is not None else None

# API Configuration
API_HOST = get_env("NLP_API_HOST", "0.0.0.0")
API_PORT = get_env("NLP_API_PORT", "1200", int)

# LLM Configuration
LLM_HOST = get_env("LLM_HOST", "127.0.0.1")
LLM_PORT = get_env("LLM_PORT", "1234", int)
LLM_URL = get_env("LLM_URL", f"http://{LLM_HOST}:{LLM_PORT}/v1/completions")
LLM_MODEL_NAME = get_env("LLM_MODEL_NAME", "gemma:7b")
LLM_MAX_TOKENS = get_env("LLM_MAX_TOKENS", "512", int)
LLM_TEMPERATURE = get_env("LLM_TEMPERATURE", "0.3", float)
LLM_TOP_P = get_env("LLM_TOP_P", "0.95", float)
LLM_TIMEOUT = get_env("LLM_TIMEOUT", "120", int)  # Tempo limite em segundos para requisições LLM
LLM_RETRIES = get_env("LLM_RETRIES", "2", int)    # Número de tentativas em caso de falha
LLM_FALLBACK = get_env("LLM_FALLBACK", "true", bool)  # Se deve usar respostas de fallback

# SpaCy Configuration
SPACY_MODEL = get_env("SPACY_MODEL", "pt_core_news_sm")

# Logging Configuration
LOG_LEVEL = get_env("LOG_LEVEL", "INFO").upper()
ENABLE_DEBUG = get_env("ENABLE_DEBUG", "false", bool)

# Paths
MODEL_CACHE_DIR = get_env("MODEL_CACHE_DIR", "./.cache/models")

# Conexões com outros serviços
CORE_SERVICE_URL = get_env("CORE_SERVICE_URL", "http://localhost:1100")
GATEWAY_SERVICE_URL = get_env("GATEWAY_SERVICE_URL", "http://localhost:1101")

# Debug: exibir configuração carregada
if ENABLE_DEBUG:
    config_logger.info("=== Configuração carregada ===")
    config_logger.info(f"API_HOST: {API_HOST}")
    config_logger.info(f"API_PORT: {API_PORT}")
    config_logger.info(f"LLM_URL: {LLM_URL}")
    config_logger.info(f"SPACY_MODEL: {SPACY_MODEL}")
    config_logger.info(f"LOG_LEVEL: {LOG_LEVEL}")
    config_logger.info("=============================")
