from typing import Dict, Optional, Tuple
import re

def extract_lamp_command_direct(text: str) -> Optional[Dict]:
    """
    Extrai comandos de controle de lâmpada diretamente, sem usar o LLM.
    Usa regras e expressões regulares para identificar padrões no texto.
    
    Args:
        text: O texto do comando em linguagem natural
        
    Returns:
        Um dicionário com os parâmetros extraídos ou None se não for um comando de lâmpada
    """
    text_lower = text.lower()
    
    # Detectar se é um comando de lâmpada
    lamp_keywords = ["luz", "lâmpada", "ilumina", "acend", "acenda", "apaga", "apague", "brilho", "lumin"]
    if not any(keyword in text_lower for keyword in lamp_keywords):
        return None
    
    # Dicionário para armazenar os resultados
    result = {
        "type": "lamp_control",
        "message": "Comando de luz processado",
        "data": {
            "action": "",
            "room": "sala",  # Valor padrão
            "color": "",
            "intensity": ""
        }
    }
    
    # Detectar ação
    if any(word in text_lower for word in ["acend", "acenda", "liga", "ligar", "lig"]):
        result["data"]["action"] = "turn_on"
        result["message"] = "Luz ligada"
    elif any(word in text_lower for word in ["apaga", "apague", "desliga", "desligar", "desl"]):
        result["data"]["action"] = "turn_off"
        result["message"] = "Luz desligada"
    elif any(word in text_lower for word in ["cor", "tonalidade", "colorir", "mude", "trocar"]):
        result["data"]["action"] = "set_color"
        result["message"] = "Cor da luz alterada"
    elif any(word in text_lower for word in ["intensidade", "brilho", "força", "luminosidade", "claro", "escuro"]):
        result["data"]["action"] = "set_intensity"
        result["message"] = "Intensidade da luz ajustada"
    else:
        # Se não identificou uma ação específica, assume ligar
        result["data"]["action"] = "turn_on"
        result["message"] = "Luz ligada"
    
    # Detectar cômodo
    rooms = {
        "sala": ["sala", "living", "estar"],
        "quarto": ["quarto", "dormitório", "suite"],
        "cozinha": ["cozinha", "copa"],
        "banheiro": ["banheiro", "lavabo", "toalete"],
        "escritório": ["escritório", "estudo", "home office"],
        "corredor": ["corredor", "hall", "entrada", "passagem"],
        "varanda": ["varanda", "sacada", "terraço"]
    }
    
    # Procurar por menções de cômodos no texto
    for room, keywords in rooms.items():
        if any(keyword in text_lower for keyword in keywords):
            result["data"]["room"] = room
            break
    
    # Detectar cor (se for um comando de cor)
    if result["data"]["action"] == "set_color":
        colors = {
            "branco": ["branco", "branca", "clara", "claro"],
            "azul": ["azul", "azulado"],
            "vermelho": ["vermelho", "vermelha", "vermelhado"],
            "verde": ["verde", "esverdeado"],
            "amarelo": ["amarelo", "amarelado", "âmbar"],
            "roxo": ["roxo", "roxo", "violeta", "lilás"],
            "rosa": ["rosa", "rosado", "pink"],
            "laranja": ["laranja", "alaranjado"]
        }
        
        for color, keywords in colors.items():
            if any(keyword in text_lower for keyword in keywords):
                result["data"]["color"] = color
                result["message"] = f"Cor da luz alterada para {color}"
                break
        
        # Se não encontrou cor específica
        if not result["data"]["color"]:
            result["data"]["color"] = "branco"  # valor padrão
    
    # Detectar intensidade (se for um comando de intensidade)
    if result["data"]["action"] == "set_intensity":
        # Tentar encontrar números no texto (ex: "50%")
        intensity_match = re.search(r'(\d+)\s*%?', text_lower)
        if intensity_match:
            intensity = int(intensity_match.group(1))
            # Garantir que está entre 0 e 100
            intensity = min(100, max(0, intensity))
            result["data"]["intensity"] = str(intensity)
            result["message"] = f"Intensidade ajustada para {intensity}%"
        else:
            # Procurar por palavras que indicam intensidade
            intensity_words = {
                "baixo": ["baixo", "baixa", "pouco", "fraco", "tênue", "mínimo", "mínima"],
                "médio": ["médio", "média", "moderado", "moderada", "normal"],
                "alto": ["alto", "alta", "forte", "intenso", "intensa", "máximo", "máxima"]
            }
            
            intensity_level = None
            for level, keywords in intensity_words.items():
                if any(keyword in text_lower for keyword in keywords):
                    intensity_level = level
                    break
            
            # Converter palavra em valor numérico
            if intensity_level == "baixo":
                result["data"]["intensity"] = "25"
                result["message"] = "Intensidade ajustada para baixa (25%)"
            elif intensity_level == "médio":
                result["data"]["intensity"] = "50"
                result["message"] = "Intensidade ajustada para média (50%)"
            elif intensity_level == "alto":
                result["data"]["intensity"] = "100"
                result["message"] = "Intensidade ajustada para alta (100%)"
            else:
                # Valor padrão se não encontrar nada específico
                result["data"]["intensity"] = "75"
                result["message"] = "Intensidade ajustada (75%)"
    
    # Personalizar mensagem final com base na ação e no cômodo
    if result["data"]["action"] == "turn_on":
        result["message"] = f"Luz do(a) {result['data']['room']} acesa"
    elif result["data"]["action"] == "turn_off":
        result["message"] = f"Luz do(a) {result['data']['room']} apagada"
    elif result["data"]["action"] == "set_color" and result["data"]["color"]:
        result["message"] = f"Cor da luz do(a) {result['data']['room']} alterada para {result['data']['color']}"
    elif result["data"]["action"] == "set_intensity" and result["data"]["intensity"]:
        result["message"] = f"Intensidade da luz do(a) {result['data']['room']} ajustada para {result['data']['intensity']}%"
            
    return result
