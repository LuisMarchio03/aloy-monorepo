import unittest
from app.services.direct_commands import extract_lamp_command_direct

class TestLampCommandDirect(unittest.TestCase):
    
    def test_turn_on_command(self):
        # Teste para comandos de ligar a luz
        result = extract_lamp_command_direct("Acenda a luz da sala")
        self.assertIsNotNone(result)
        self.assertEqual(result["type"], "lamp_control")
        self.assertEqual(result["data"]["action"], "turn_on")
        self.assertEqual(result["data"]["room"], "sala")
        
        # Variante do comando
        result = extract_lamp_command_direct("Liga a lâmpada do quarto")
        self.assertIsNotNone(result)
        self.assertEqual(result["data"]["action"], "turn_on")
        self.assertEqual(result["data"]["room"], "quarto")
    
    def test_turn_off_command(self):
        # Teste para comandos de desligar a luz
        result = extract_lamp_command_direct("Apague a luz da cozinha")
        self.assertIsNotNone(result)
        self.assertEqual(result["type"], "lamp_control")
        self.assertEqual(result["data"]["action"], "turn_off")
        self.assertEqual(result["data"]["room"], "cozinha")
        
        # Variante do comando
        result = extract_lamp_command_direct("Desliga a iluminação do banheiro")
        self.assertIsNotNone(result)
        self.assertEqual(result["data"]["action"], "turn_off")
        self.assertEqual(result["data"]["room"], "banheiro")
    
    def test_set_color_command(self):
        # Teste para comandos de alterar cor
        result = extract_lamp_command_direct("Mude a cor da luz da sala para azul")
        self.assertIsNotNone(result)
        self.assertEqual(result["type"], "lamp_control")
        self.assertEqual(result["data"]["action"], "set_color")
        self.assertEqual(result["data"]["room"], "sala")
        self.assertEqual(result["data"]["color"], "azul")
        
        # Variante do comando
        result = extract_lamp_command_direct("Coloque a luz do quarto na cor vermelha")
        self.assertIsNotNone(result)
        self.assertEqual(result["data"]["action"], "set_color")
        self.assertEqual(result["data"]["room"], "quarto")
        self.assertEqual(result["data"]["color"], "vermelho")
    
    def test_set_intensity_command(self):
        # Teste para comandos de alterar intensidade
        result = extract_lamp_command_direct("Ajuste a luz da sala para 75%")
        self.assertIsNotNone(result)
        self.assertEqual(result["type"], "lamp_control")
        self.assertEqual(result["data"]["action"], "set_intensity")
        self.assertEqual(result["data"]["room"], "sala")
        self.assertEqual(result["data"]["intensity"], "75")
        
        # Teste com palavras descritivas
        result = extract_lamp_command_direct("Deixe a luz do quarto mais baixa")
        self.assertIsNotNone(result)
        self.assertEqual(result["data"]["action"], "set_intensity")
        self.assertEqual(result["data"]["room"], "quarto")
        self.assertEqual(result["data"]["intensity"], "25")  # Valor correspondente a "baixo"
    
    def test_not_lamp_command(self):
        # Teste com textos que não são comandos de lâmpada
        result = extract_lamp_command_direct("Qual é a previsão do tempo para hoje?")
        self.assertIsNone(result)
        
        result = extract_lamp_command_direct("Me conte uma piada")
        self.assertIsNone(result)
    
    def test_default_values(self):
        # Teste para verificar valores default quando informações estão faltando
        result = extract_lamp_command_direct("Acenda a luz")  # Sem especificar cômodo
        self.assertIsNotNone(result)
        self.assertEqual(result["data"]["room"], "sala")  # Valor padrão
        
        result = extract_lamp_command_direct("Mude a cor da luz da sala")  # Sem especificar cor
        self.assertIsNotNone(result)
        self.assertEqual(result["data"]["action"], "set_color")
        self.assertEqual(result["data"]["color"], "branco")  # Valor padrão
    
if __name__ == '__main__':
    unittest.main()
