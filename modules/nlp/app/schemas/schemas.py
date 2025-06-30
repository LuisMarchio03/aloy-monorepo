from pydantic import BaseModel
from typing import Literal, Optional, Dict


class InterpretRequest(BaseModel):
    message: str


class CommandResponse(BaseModel):
    type: str                # Ex: "set_alarm", "pesquisa", "conversa"
    message: str             # Texto que será logado ou respondido
    data: Dict[str, Optional[str]]     # JSON bruto com parâmetros para o Core (ou vazio)


class NLPAnalysisResult(BaseModel):
    nlp_type: Literal["comando", "pesquisa", "conversa"]
    intent: Optional[str] = None              # Apenas se comando
    parsed_data: Optional[Dict[str, str]] = None  # Apenas se comando
    response_message: Optional[str] = None    # Para conversa/pesquisa
