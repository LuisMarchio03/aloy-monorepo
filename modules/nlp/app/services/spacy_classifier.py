import spacy
import logging
from app.schemas.schemas import NLPAnalysisResult
from app.config import SPACY_MODEL

logger = logging.getLogger(__name__)

# Carregando modelo do spaCy configurado no .env.local
# ⚠️ Requer: python -m spacy download {SPACY_MODEL}
logger.info(f"Carregando modelo SpaCy: {SPACY_MODEL}")
nlp = spacy.load(SPACY_MODEL)

def detect_command_type(text: str) -> str:
    """
    Detecta o tipo de comando com base no texto.
    
    Args:
        text: O texto da mensagem do usuário
    
    Returns:
        O tipo de comando identificado (ex: "lamp_control", "set_alarm", etc)
    """
    text_lower = text.lower()
    
    # Detectar comandos de lâmpada
    if any(x in text_lower for x in ["luz", "lâmpada", "acenda", "apague", "ilumin"]):
        return "lamp_control"
        
    # Detectar comandos de alarme
    if any(x in text_lower for x in ["alarme", "lembre", "temporizador", "agendar"]):
        return "set_alarm"
        
    # Se nenhum comando específico for detectado
    return "unknown"

def classify_type(text: str) -> NLPAnalysisResult:
    doc = nlp(text.lower())
    text_lower = text.lower()
    
    # Lista de palavras-chave para classificação
    command_keywords = [
        "acordar", "ligar", "desligar", "abrir", "fechar", "tocar", "parar", 
        "lembrar", "agendar", "definir", "marcar", "configurar", "ajustar", 
        "criar", "deletar", "excluir", "remover", "mudar", "alterar", "modificar",
        # Palavras-chave para controle de lâmpadas
        "acender", "acenda", "apagar", "apague", "luz", "lâmpada", "brilho", "cor"
    ]
    
    greeting_keywords = [
        "olá", "oi", "e aí", "opa", "bom dia", "boa tarde", "boa noite", 
        "tudo bem", "como vai", "como está", "prazer", "tchau", "até logo", 
        "até mais", "adeus"
    ]
    
    search_keywords = [
        "pesquisar", "buscar", "procurar", "encontrar", "localizar", 
        "o que é", "quem é", "onde", "quando", "como", "por que", "qual", 
        "quanto", "quais", "me fale sobre", "me diga sobre", "explique", 
        "me explique", "me mostre", "me informe", "saiba", "saber"
    ]
    
    # Classificação
    
    # 1. Verificar se é um comando
    if (any(keyword in text_lower for keyword in command_keywords) or
        any(t.lemma_ in command_keywords for t in doc)):
        return NLPAnalysisResult(nlp_type="comando")
    
    # 2. Verificar se é uma pesquisa
    elif (text_lower.endswith("?") or 
          any(keyword in text_lower for keyword in search_keywords) or 
          any(t.pos_ in ["PRON", "ADV"] and t.dep_ == "advmod" for t in doc)):
        return NLPAnalysisResult(
            nlp_type="pesquisa",
            response_message="Vou pesquisar isso pra você."
        )
    
    # 3. Verificar se é uma saudação/conversa casual
    elif any(keyword in text_lower for keyword in greeting_keywords):
        return NLPAnalysisResult(
            nlp_type="conversa",
            response_message="Olá! Como posso ajudar?"
        )
    
    # 4. Qualquer outra coisa é considerada conversa
    else:
        return NLPAnalysisResult(
            nlp_type="conversa",
            response_message="Entendi. Pode continuar."
        )
