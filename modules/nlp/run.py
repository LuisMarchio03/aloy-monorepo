#!/usr/bin/env python
# filepath: /home/luismarchio03/Documents/Sistemas/Aloy-Microservices/aloy-nlp-python-v1/run.py

"""
Script para inicialização do servidor Aloy NLP API.
Este script carrega as configurações do .env.local e inicia o servidor.
"""

import uvicorn
from app.config import API_HOST, API_PORT, ENABLE_DEBUG
from app.logger import logger

if __name__ == "__main__":
    logger.info(f"Iniciando servidor Aloy NLP API em {API_HOST}:{API_PORT}")
    logger.info(f"Debug mode: {ENABLE_DEBUG}")
    
    uvicorn.run(
        "app.main:app", 
        host=API_HOST, 
        port=API_PORT, 
        reload=ENABLE_DEBUG
    )
