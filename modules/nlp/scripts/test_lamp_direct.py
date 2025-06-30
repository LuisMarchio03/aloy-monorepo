#!/usr/bin/env python3
# test_lamp_direct.py
# Script para testar o processamento direto de comandos de lâmpada

import sys
import os

# Adicionando o diretório do projeto ao PYTHONPATH
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.services.direct_commands import extract_lamp_command_direct
from app.services.orchestrator import try_direct_command_processing
import json

def print_result(text, result):
    """Imprime o resultado do processamento de forma formatada"""
    print("\n" + "="*60)
    print(f"COMANDO: \"{text}\"")
    print("-"*60)
    
    if result:
        print(f"TIPO: {result.get('type', 'N/A')}")
        print(f"MENSAGEM: {result.get('message', 'N/A')}")
        
        if 'data' in result:
            print("DADOS:")
            for key, value in result['data'].items():
                print(f"  {key}: {value}")
        
        # Versão JSON para desenvolvedores
        print("-"*60)
        print("JSON:")
        print(json.dumps(result, indent=2))
    else:
        print("Não foi reconhecido como comando de lâmpada.")
    
    print("="*60 + "\n")

def run_interactive_tests():
    """Modo interativo para testar comandos personalizados"""
    print("\n===== TESTE INTERATIVO DE COMANDOS DIRETOS DE LÂMPADA =====")
    print("Digite comandos para testar o processamento direto.")
    print("Digite 'sair' para encerrar.\n")
    
    while True:
        text = input("\nComando > ")
        if text.lower() in ["sair", "exit", "quit"]:
            break
            
        # Teste usando a função direta
        result = extract_lamp_command_direct(text)
        print_result(text, result)
        
        # Teste usando o orquestrador
        print("\nTestando via orquestrador...")
        result_orch = try_direct_command_processing(text, "lamp_control")
        if result_orch != result:
            print("ATENÇÃO: Resultados diferentes entre método direto e orquestrador!")
            print_result(text, result_orch)

def run_predefined_tests():
    """Executa testes com comandos predefinidos"""
    test_commands = [
        "Acenda a luz da sala",
        "Apague a lâmpada do quarto",
        "Mude a cor da luz do escritório para azul",
        "Deixe a luz da cozinha mais intensa",
        "Ajuste a intensidade da luz do banheiro para 30%",
        "Coloque a luz da varanda em vermelho",
        "Acenda todas as luzes",
        "Qual é o tempo hoje?",  # Não deve ser reconhecido como comando de lâmpada
        "Ligue a luz",  # Deve usar sala como cômodo padrão
        "Mude a cor para verde"  # Deve usar sala como cômodo padrão
    ]
    
    print("\n===== TESTANDO COMANDOS PREDEFINIDOS =====")
    
    for command in test_commands:
        result = extract_lamp_command_direct(command)
        print_result(command, result)
    
    print("\nTestes predefinidos concluídos!\n")

if __name__ == "__main__":
    # Executar testes predefinidos
    run_predefined_tests()
    
    # Perguntar se deseja executar testes interativos
    interactive = input("Deseja executar testes interativos? (s/n): ")
    if interactive.lower() in ["s", "sim", "yes", "y"]:
        run_interactive_tests()
    
    print("Testes concluídos!")
