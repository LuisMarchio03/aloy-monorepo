import requests
import json
import re
import logging
import time
import random
from typing import Dict, Union
from app.config import (
    LLM_URL, LLM_MODEL_NAME, LLM_MAX_TOKENS, 
    LLM_TEMPERATURE, LLM_TOP_P, LLM_TIMEOUT, LLM_RETRIES,
    LLM_FALLBACK
)

logger = logging.getLogger(__name__)

def _get_fallback_response(text: str, structured: bool) -> Union[Dict, str]:
    """
    Gera uma resposta de fallback quando o LLM não está disponível.
    
    Args:
        text: O texto da mensagem original ou prompt
        structured: Se deve retornar uma resposta estruturada (dict) ou texto simples
    
    Returns:
        Uma resposta de fallback (Dict para comandos, str para conversas/pesquisas)
    """
    if structured:
        # Detecção simples para classificar o tipo de mensagem
        text_lower = text.lower()
        
        # Detectar comandos de lâmpada
        if any(word in text_lower for word in ["luz", "lâmpada", "acend", "apag"]):
            return {
                "type": "lamp_control",
                "message": "Não foi possível processar sua solicitação de controle de iluminação neste momento.",
                "data": {
                    "action": "turn_on",
                    "room": "sala",
                    "error": "llm_unavailable"
                }
            }
            
        # Detectar comandos de alarme
        elif any(word in text_lower for word in ["defina", "alarme", "temporizador", "lembrete", "agende"]):
            return {
                "type": "set_alarm",
                "message": "Não foi possível processar sua solicitação de alarme/lembrete neste momento.",
                "data": {"error": "llm_unavailable"}
            }
        elif any(word in text_lower for word in ["pesquise", "busque", "procure", "encontre"]):
            return {
                "type": "pesquisa",
                "message": "Desculpe, não consegui realizar sua pesquisa no momento.",
                "data": {}
            }
        else:
            return {
                "type": "conversa",
                "message": "Estou com dificuldades de processamento no momento. Poderia tentar novamente mais tarde?",
                "data": {}
            }
    else:
        # Respostas de fallback para conversas
        fallback_responses = [
            "Desculpe, estou com dificuldades de conexão no momento. Poderia tentar novamente mais tarde?",
            "Parece que estou tendo problemas para processar sua solicitação agora. Vamos tentar novamente em breve?",
            "Estou enfrentando limitações técnicas neste momento. Poderia reformular sua pergunta ou tentar mais tarde?",
            "Não consegui processar sua solicitação adequadamente. Estou trabalhando para resolver isso.",
            "Desculpe pela inconveniência, mas não estou conseguindo responder corretamente agora."
        ]
        return random.choice(fallback_responses)

def query_llm(text: str, structured: bool = True) -> Union[Dict, str]:
    if structured:
        prompt = f"""
A partir do texto abaixo, classifique em tipo (comando, pesquisa, conversa).
Se for comando, gere um JSON com os campos necessários para o comando executar.
Retorne sempre um JSON válido com as chaves: type, message, data.

Texto: \"{text}\"
Resposta:
"""
    else:
        prompt = f"""
Você é a assistente Aloy. Responda com simpatia, informalidade leve e objetividade.
Texto: \"{text}\"
Resposta:
"""

    payload = {
        "prompt": prompt,
        "model": LLM_MODEL_NAME,
        "max_tokens": LLM_MAX_TOKENS,
        "temperature": LLM_TEMPERATURE,
        "top_p": LLM_TOP_P,
        "stream": False
    }
    
    logger.debug(f"Enviando requisição para LLM em: {LLM_URL}")

    for retry in range(LLM_RETRIES + 1):
        try:
            logger.debug(f"Enviando requisição para LLM: {payload} (tentativa {retry+1}/{LLM_RETRIES+1})")
            response = requests.post(
                LLM_URL, 
                json=payload, 
                timeout=LLM_TIMEOUT
            )
            response.raise_for_status()
            response_json = response.json()
            
            # Tenta extrair texto do formato de resposta da API
            if "choices" in response_json and len(response_json["choices"]) > 0:
                result_text = response_json["choices"][0].get("text", "")
            else:
                result_text = response_json.get("response", "")
                
            logger.debug(f"Resposta do LLM recebida com sucesso")
            break  # Sai do loop se a requisição foi bem-sucedida
        except requests.RequestException as e:
            logger.warning(f"Tentativa {retry+1}/{LLM_RETRIES+1} falhou: {str(e)}")
            if retry < LLM_RETRIES:
                # Espera exponencial antes de tentar novamente
                wait_time = 2 ** retry
                logger.info(f"Aguardando {wait_time} segundos antes de tentar novamente...")
                time.sleep(wait_time)
            else:
                # Se todas as tentativas falharem
                logger.error(f"Todas as {LLM_RETRIES+1} tentativas falharam. Erro: {str(e)}")
                if LLM_FALLBACK:
                    logger.warning("Usando resposta de fallback devido a falha no LLM")
                    return _get_fallback_response(text, structured)
                else:
                    raise ValueError(f"Erro ao comunicar com o serviço LLM após {LLM_RETRIES+1} tentativas: {str(e)}")
    else:
        # Este bloco será executado se o loop terminar sem um 'break'
        if LLM_FALLBACK:
            logger.warning("Usando resposta de fallback devido a falha no LLM")
            return _get_fallback_response(text, structured)
        else:
            raise ValueError(f"Não foi possível conectar ao serviço LLM após {LLM_RETRIES+1} tentativas")

    if structured:
        # Extrair JSON do texto retornado pelo modelo
        json_match = re.search(r"\{.*\}", result_text, re.DOTALL)
        if not json_match:
            logger.warning(f"Não foi possível extrair JSON da resposta da LLM: {result_text}")
            
            # Fallback para formato estruturado
            return {
                "type": "conversa",
                "message": result_text.strip(),
                "data": {}
            }

        try:
            json_data = json.loads(json_match.group(0))
        except json.JSONDecodeError as e:
            logger.warning(f"Erro ao decodificar JSON da resposta da LLM: {e}")
            
            # Fallback para formato estruturado
            return {
                "type": "conversa",
                "message": result_text.strip(),
                "data": {}
            }

        # Garantir chaves mínimas
        json_data.setdefault("type", "unknown")
        json_data.setdefault("message", "")
        json_data.setdefault("data", {})

        return json_data
    else:
        # Retorna apenas o texto da resposta, removendo qualquer formatação ou espaços extras
        return result_text.strip()
