import os
import sys
import pytest
import json
from unittest.mock import patch, MagicMock

# Adicionar o diretório pai ao path para importar os módulos da aplicação
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.services.lamp_control import prompt_lamp_control, process_lamp_control_response
from app.services.spacy_classifier import detect_command_type


class TestLampControl:
    
    def test_detect_command_type_lamp(self):
        """Testa se o detector de comandos identifica corretamente comandos de lâmpada"""
        
        # Frases para testar
        frases = [
            "Acenda a luz da sala",
            "Apague a luz do quarto",
            "Mude a cor da lâmpada para azul",
            "Aumente a intensidade da luz da cozinha",
            "Diminua o brilho da luz do escritório",
            "Apague todas as luzes",
            "Ligue a luz do corredor",
            "Mude a iluminação do quarto para verde",
            "Acenda a lâmpada do banheiro"
        ]
        
        # Todas devem ser identificadas como lamp_control
        for frase in frases:
            assert detect_command_type(frase) == "lamp_control"
    
    def test_prompt_generation(self):
        """Testa se o prompt está sendo gerado corretamente"""
        
        # Frase de teste
        frase = "Acenda a luz do quarto"
        
        # Gerar prompt
        prompt = prompt_lamp_control(frase)
        
        # Verificar se contém as partes essenciais
        assert "lamp_control" in prompt
        assert "turn_on|turn_off|set_color|set_intensity" in prompt
        assert "Texto: \"Acenda a luz do quarto\"" in prompt
    
    def test_process_valid_lamp_response(self):
        """Testa processamento de respostas válidas"""
        
        # Resposta válida para ligar luz
        valid_response = {
            "type": "lamp_control",
            "message": "Luz do quarto ligada",
            "data": {
                "action": "turn_on",
                "room": "quarto"
            }
        }
        
        # Processar e verificar
        processed = process_lamp_control_response(valid_response)
        assert processed["type"] == "lamp_control"
        assert processed["data"]["action"] == "turn_on"
        assert processed["data"]["room"] == "quarto"
    
    def test_process_incomplete_response(self):
        """Testa processamento de respostas incompletas que devem ser completadas com valores padrão"""
        
        # Resposta incompleta para mudar cor
        incomplete_response = {
            "type": "lamp_control",
            "message": "Cor da luz alterada",
            "data": {
                "action": "set_color",
                "room": "sala"
                # Cor ausente
            }
        }
        
        # Processar e verificar se adicionou cor padrão
        processed = process_lamp_control_response(incomplete_response)
        assert processed["data"]["color"] == "branco"
        assert processed["data"]["room"] == "sala"
    
    def test_process_invalid_response(self):
        """Testa processamento de respostas inválidas"""
        
        # Resposta com ação inválida
        invalid_response = {
            "type": "lamp_control",
            "message": "Mensagem teste",
            "data": {
                "action": "explode",  # Ação inválida
                "room": "sala"
            }
        }
        
        # Deve lançar ValueError
        with pytest.raises(ValueError):
            process_lamp_control_response(invalid_response)


# Exemplos de frases para testar manualmente o sistema completo:
test_phrases = [
    "Acenda a luz da sala",
    "Apague a luz do quarto",
    "Mude a cor da lâmpada para azul",
    "Ajuste a intensidade da luz para 50%",
    "Acenda a luz da cozinha com cor vermelha",
    "Diminua o brilho da luz para 30%",
    "Mude a cor da iluminação do quarto para verde",
    "Desligue todas as luzes da casa",
    "Ligue a luz do banheiro"
]

# Se executado diretamente, exibe os prompts para cada frase de teste
if __name__ == "__main__":
    print("Exemplos de prompts para comandos de lâmpada:\n")
    
    for phrase in test_phrases:
        print(f"Frase: \"{phrase}\"")
        print(f"Tipo detectado: {detect_command_type(phrase)}")
        print("Prompt gerado:")
        print(prompt_lamp_control(phrase))
        print("-" * 80)
