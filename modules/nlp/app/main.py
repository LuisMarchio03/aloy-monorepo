from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Literal, Optional, Dict
import logging
from app.services.orchestrator import interpret_message
from app.config import API_HOST, API_PORT, ENABLE_DEBUG
from app.logger import logger

app = FastAPI(
    title="Aloy NLP API",
    description="API para processamento de linguagem natural do Aloy Microservices",
    version="0.1.0",
    debug=ENABLE_DEBUG
)

logger.info(f"Iniciando Aloy NLP API em {API_HOST}:{API_PORT}")


class InterpretRequest(BaseModel):
    message: str


class CommandResponse(BaseModel):
    type: str                # Ex: "set_alarm", "pesquisa", "conversa"
    message: str             # Resposta legível para logs ou retorno
    data: Dict[str, str]     # Estrutura esperada pelo Aloy-Core (ou vazio)


@app.post("/interpret", response_model=CommandResponse)
def interpret(req: InterpretRequest):
    try:
        logger.info(f"Interpretando mensagem: {req.message}")
        result = interpret_message(req.message)
        logger.info(f"Interpretação concluída com tipo: {result.type}")
        return result
    except Exception as e:
        logger.error(f"Erro na interpretação: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
