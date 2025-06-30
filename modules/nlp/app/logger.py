import logging
import sys
from app.config import LOG_LEVEL, ENABLE_DEBUG

# Configuração básica de logging
def setup_logger():
    log_format = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    
    # Converter string de nível para objeto logging.level
    numeric_level = getattr(logging, LOG_LEVEL.upper(), None)
    if not isinstance(numeric_level, int):
        numeric_level = logging.INFO
    
    # Configuração do logger raiz
    logging.basicConfig(
        level=numeric_level,
        format=log_format,
        handlers=[
            logging.StreamHandler(sys.stdout),
            logging.FileHandler("nlp_api.log"),
        ]
    )
    
    # Ajustando nível de logs para módulos específicos
    if not ENABLE_DEBUG:
        # Reduzir logs verbosos de bibliotecas de terceiros
        logging.getLogger("uvicorn").setLevel(logging.WARNING)
        logging.getLogger("fastapi").setLevel(logging.WARNING)
    
    logger = logging.getLogger(__name__)
    logger.info(f"Logger configurado com nível: {LOG_LEVEL.upper()}")
    
    return logger

# Logger global da aplicação
logger = setup_logger()
