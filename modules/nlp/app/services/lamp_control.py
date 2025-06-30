from typing import Dict, Literal, Union

def prompt_lamp_control(texto_usuario: str) -> str:
    """
    Gera um prompt para o LLM extrair informações de controle de lâmpada do texto.
    
    Args:
        texto_usuario: A mensagem do usuário
        
    Returns:
        Um prompt formatado para o LLM
    """
    return f"""
A partir do texto abaixo, identifique o comando `lamp_control`.
Retorne um JSON com os seguintes campos:

{{
  "type": "lamp_control",
  "message": "mensagem amigável de confirmação para o usuário",
  "data": {{
    "action": "turn_on|turn_off|set_color|set_intensity",
    "room": "quarto|sala|cozinha|banheiro|escritório|...",
    "color": "branco|azul|vermelho|verde|amarelo|roxo|...",
    "intensity": "0-100"
  }}
}}

Para o campo "action":
- "turn_on" → quando o usuário quer ligar/acender a luz
- "turn_off" → quando o usuário quer desligar/apagar a luz
- "set_color" → quando o usuário quer mudar a cor da luz
- "set_intensity" → quando o usuário quer mudar a intensidade/brilho da luz

Se não houver menção específica a um cômodo ou sala, use "sala" como padrão.
Se a ação for "set_color" mas não houver cor especificada, use "branco" como padrão.
Se a ação for "set_intensity" mas não houver intensidade especificada, use "100" como padrão.

Texto: "{texto_usuario}"
Resposta:
"""

def process_lamp_control_response(response: Dict) -> Dict:
    """
    Valida e processa a resposta do LLM para comandos de lâmpada.
    
    Args:
        response: O dicionário de resposta do LLM
        
    Returns:
        O dicionário validado e formatado
        
    Raises:
        ValueError: Se a estrutura do comando estiver incorreta
    """
    try:
        # Verificar se os campos obrigatórios existem
        if "type" not in response or response["type"] != "lamp_control":
            raise ValueError("Tipo de comando inválido ou ausente")
            
        if "data" not in response or not isinstance(response["data"], dict):
            raise ValueError("Campo 'data' ausente ou inválido")
            
        data = response["data"]
        
        # Validar campos obrigatórios em data
        if "action" not in data:
            raise ValueError("Campo 'action' obrigatório ausente")
            
        # Validar ação
        valid_actions = ["turn_on", "turn_off", "set_color", "set_intensity"]
        if data["action"] not in valid_actions:
            raise ValueError(f"Ação '{data['action']}' inválida. Deve ser uma das: {valid_actions}")
            
        # Validar room (padrão: sala)
        if "room" not in data or not data["room"]:
            data["room"] = "sala"
            
        # Validar color para set_color
        if data["action"] == "set_color" and ("color" not in data or not data["color"]):
            data["color"] = "branco"
            
        # Validar intensity para set_intensity
        if data["action"] == "set_intensity" and ("intensity" not in data or not data["intensity"]):
            data["intensity"] = "100"
            
        # Garantir que message existe
        if "message" not in response or not response["message"]:
            response["message"] = f"Controle de luz configurado para: {data['action']} no cômodo {data['room']}"
            
        return response
    except Exception as e:
        raise ValueError(f"Erro na estrutura do comando lamp_control: {e}")
