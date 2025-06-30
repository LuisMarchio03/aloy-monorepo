#!/usr/bin/env python3
# script_test_direct_commands.py
# Script para testar comandos diretos sem depender do ambiente virtual

import sys
import os
import json

# Adicionar o diretório atual ao path para poder importar os módulos
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

try:
    # Tentar importar o módulo de comandos diretos
    from app.services.direct_commands import extract_lamp_command_direct
    print("✅ Módulo de comandos diretos importado com sucesso!")
except ImportError as e:
    print(f"❌ Erro ao importar módulo: {str(e)}")
    print("Verifique se você está no diretório correto e se as dependências estão instaladas.")
    sys.exit(1)

def test_command(text):
    """Teste um comando e exibe o resultado"""
    print(f"\n🔍 Testando comando: \"{text}\"")
    print("-" * 50)
    
    try:
        result = extract_lamp_command_direct(text)
        
        if result:
            print("✅ Comando reconhecido como controle de lâmpada!")
            print(f"📋 TIPO: {result.get('type', 'N/A')}")
            print(f"💬 MENSAGEM: {result.get('message', 'N/A')}")
            
            if 'data' in result:
                print("🔹 DADOS:")
                for key, value in result['data'].items():
                    print(f"  {key}: {value}")
            
            print("\n📊 JSON resultante:")
            print(json.dumps(result, indent=2, ensure_ascii=False))
        else:
            print("❌ Não foi reconhecido como comando de lâmpada.")
    
    except Exception as e:
        print(f"❌ Erro ao processar comando: {str(e)}")
    
    print("-" * 50)

def main():
    """Função principal"""
    print("=" * 50)
    print("🔆 TESTE DE COMANDOS DIRETOS DE LÂMPADA 🔆")
    print("=" * 50)
    print("\nEste script testa o processamento direto de comandos de lâmpada")
    print("sem usar o LLM, apenas com expressões regulares e regras.\n")
    
    # Lista de comandos para testar
    test_commands = [
        "Ligar a luz do quarto",
        "Apague a luz da sala",
        "Mude a cor da luz para azul",
        "Ajuste o brilho da luz da cozinha para 50%",
        "Deixe a luz mais fraca",
        "Coloque a luz do escritório na cor vermelho",
        "Diminua a intensidade da luz do banheiro",
        "Qual a previsão do tempo para hoje?"  # Não deve ser reconhecido
    ]
    
    # Testar cada comando da lista
    for cmd in test_commands:
        test_command(cmd)
    
    # Modo interativo
    print("\n" + "=" * 50)
    print("🔄 MODO INTERATIVO: Digite comandos para testar")
    print("Digite 'sair' para encerrar o programa")
    print("=" * 50)
    
    while True:
        user_input = input("\n➤ Digite um comando: ")
        if user_input.lower() in ['sair', 'exit', 'quit']:
            break
        
        test_command(user_input)
    
    print("\n✨ Testes concluídos! ✨")

if __name__ == "__main__":
    main()
