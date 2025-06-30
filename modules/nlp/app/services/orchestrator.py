import logging
from app.schemas.schemas import NLPAnalysisResult, CommandResponse
from app.services.spacy_classifier import classify_type, detect_command_type
from app.services.lmstudio_client import query_llm
from app.services.lamp_control import prompt_lamp_control, process_lamp_control_response
from app.services.direct_commands import extract_lamp_command_direct

logger = logging.getLogger(__name__)

def get_command_prompt(command_type: str, user_text: str) -> str:
    """
    Obtém o prompt adequado com base no tipo de comando detectado.
    
    Args:
        command_type: O tipo de comando detectado
        user_text: O texto original do usuário
        
    Returns:
        Um prompt formatado para o LLM
    """
    if command_type == "lamp_control":
        return prompt_lamp_control(user_text)
    
    # Prompt genérico para outros comandos
    return f"""
A partir do texto abaixo, extraia a intenção e os parâmetros necessários.
Retorne um JSON com o formato adequado para o tipo de comando.

Texto: "{user_text}"
Resposta:
"""

def process_command_response(command_type: str, llm_result: dict) -> dict:
    """
    Processa e valida a resposta do LLM com base no tipo de comando.
    
    Args:
        command_type: O tipo de comando detectado
        llm_result: A resposta bruta do LLM
        
    Returns:
        A resposta processada e validada
    """
    try:
        if command_type == "lamp_control":
            return process_lamp_control_response(llm_result)
        # Por padrão, apenas retorna o resultado bruto
        return llm_result
    except Exception as e:
        logger.error(f"Erro no processamento do comando {command_type}: {str(e)}")
        return {
            "type": "error",
            "message": f"Erro ao processar comando {command_type}: {str(e)}",
            "data": {}
        }

def try_direct_command_processing(text: str, command_type: str):
    """
    Tenta processar o comando diretamente sem usar o LLM.
    
    Args:
        text: O texto do usuário
        command_type: O tipo de comando detectado
        
    Returns:
        Um dicionário com o resultado do processamento ou None se não for possível processar diretamente
    """
    try:
        if command_type == "lamp_control":
            result = extract_lamp_command_direct(text)
            if result:
                logger.info("Comando de lâmpada processado diretamente sem LLM")
                return result
        return None
    except Exception as e:
        logger.warning(f"Erro ao processar comando direto: {str(e)}")
        return None

def interpret_message(text: str) -> CommandResponse:
    # Etapa 1: Classificação do tipo com spaCy
    logger.debug("Iniciando classificação com spaCy")
    nlp_result: NLPAnalysisResult = classify_type(text)
    logger.info(f"Texto classificado como: {nlp_result.nlp_type}")

    if nlp_result.nlp_type == "comando":
        # Etapa 1.1: Identificar o tipo específico de comando
        command_type = detect_command_type(text)
        logger.info(f"Tipo de comando detectado: {command_type}")
        
        # Etapa 1.2: Tentar processamento direto sem LLM
        direct_result = try_direct_command_processing(text, command_type)
        if direct_result:
            logger.info(f"Comando processado diretamente: {direct_result.get('type')}")
            return CommandResponse(
                type=direct_result.get("type", command_type),
                message=direct_result.get("message", "Comando interpretado diretamente."),
                data=direct_result.get("data", {})
            )
        
        # Se não for possível processar diretamente, continua com o LLM
        # Etapa 2: Gerar prompt específico para o tipo de comando
        prompt = get_command_prompt(command_type, text)
        
        # Etapa 3: LLM gera JSON com base no prompt
        logger.debug(f"Enviando para processamento com LLM (comando: {command_type})")
        llm_result = query_llm(prompt, structured=True)
        
        # Garantir que llm_result é dict
        if isinstance(llm_result, dict):
            # Etapa 4: Validar e processar a resposta
            processed_result = process_command_response(command_type, llm_result)
            
            logger.info(f"Comando processado: {processed_result.get('type', 'unknown')}")
            return CommandResponse(
                type=processed_result.get("type", command_type),
                message=processed_result.get("message", "Comando interpretado."),
                data=processed_result.get("data", {})
            )
        else:
            # Caso ocorra algum erro e a LLM retorne uma string
            logger.warning("LLM retornou string em vez de dict para um comando")
            return CommandResponse(
                type=command_type,
                message=str(llm_result),
                data={}
            )
    else:
        # Conversa ou pesquisa → obtém resposta textual da LLM
        logger.debug(f"Processando {nlp_result.nlp_type} com LLM (não estruturado)")
        response_text = query_llm(text, structured=False)
        
        # Garantir que response_text é string
        if isinstance(response_text, dict):
            response_message = response_text.get("message", "")
        else:
            response_message = str(response_text)
        
        logger.info(f"Resposta {nlp_result.nlp_type} gerada pela LLM")
        return CommandResponse(
            type=nlp_result.nlp_type,
            message=response_message.strip(),
            data={}
        )
