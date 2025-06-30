# Guia para Implementação de Processadores de Comandos Diretos

Este documento descreve como criar novos processadores de comandos diretos no Aloy NLP, 
evitando o uso do LLM para comandos com formato predefinido.

## Por que criar processadores diretos?

1. **Eficiência**: Comandos diretos são processados muito mais rapidamente
2. **Resiliência**: Funcionam mesmo quando o LLM está indisponível
3. **Consistência**: Produzem resultados mais previsíveis
4. **Economia**: Reduzem o consumo de recursos do LLM

## Estrutura de um Processador de Comandos Direto

Um processador direto é uma função Python que:
1. Recebe um texto em linguagem natural
2. Tenta extrair parâmetros relevantes usando regras e expressões regulares
3. Retorna um dicionário formatado ou `None` se não conseguir processar

## Passo a Passo para Criar um Novo Processador

### 1. Identifique o Tipo de Comando

Determine que tipo de comando você deseja processar diretamente, por exemplo:
- Controle de dispositivos (como lâmpadas, TV, etc.)
- Configurações de alarme/temporizador
- Consultas de informações estruturadas (clima, tempo, etc.)

### 2. Defina o Padrão de Saída

O resultado deve ser um dicionário com a mesma estrutura que o LLM produziria:

```python
{
    "type": "tipo_do_comando",
    "message": "Mensagem legível para usuário",
    "data": {
        # Parâmetros específicos do comando
        "parametro1": "valor1",
        "parametro2": "valor2",
        # ...
    }
}
```

### 3. Implemente a Função Extratora

Crie uma função no módulo `app/services/direct_commands.py` seguindo o padrão:

```python
def extract_TIPO_command_direct(text: str) -> Optional[Dict]:
    """
    Extrai comandos de TIPO diretamente, sem usar o LLM.
    
    Args:
        text: O texto do comando em linguagem natural
        
    Returns:
        Um dicionário com os parâmetros extraídos ou None se não for um comando de TIPO
    """
    text_lower = text.lower()
    
    # 1. Detectar se é um comando do tipo esperado
    keywords = ["palavra1", "palavra2", "palavra3"]
    if not any(keyword in text_lower for keyword in keywords):
        return None
    
    # 2. Inicializar o resultado
    result = {
        "type": "tipo_comando",
        "message": "Mensagem padrão",
        "data": {
            # Parâmetros com valores padrão
            "parametro1": "valor_padrao",
            "parametro2": None
        }
    }
    
    # 3. Detectar variantes de comando e extrair parâmetros
    # Exemplo para detectar uma ação:
    if any(word in text_lower for word in ["ação1", "ação2"]):
        result["data"]["parametro1"] = "valor_correspondente"
    
    # 4. Usar regex para extrair valores numéricos ou específicos
    # Exemplo:
    match = re.search(r'padrão (\d+)', text_lower)
    if match:
        result["data"]["parametro2"] = match.group(1)
    
    # 5. Personalizar mensagem final
    result["message"] = f"Mensagem personalizada com {result['data']['parametro1']}"
    
    return result
```

### 4. Integre no Orquestrador

No arquivo `app/services/orchestrator.py`, na função `try_direct_command_processing`:

```python
def try_direct_command_processing(text: str, command_type: str):
    try:
        if command_type == "lamp_control":
            result = extract_lamp_command_direct(text)
            if result:
                return result
        elif command_type == "novo_tipo_comando":  # Adicione seu novo tipo aqui
            result = extract_TIPO_command_direct(text)
            if result:
                return result
        return None
    except Exception as e:
        logger.warning(f"Erro ao processar comando direto: {str(e)}")
        return None
```

### 5. Crie Testes Unitários

Adicione testes para seu processador em `tests/test_direct_commands.py`:

```python
def test_new_command_type(self):
    # Teste para seu novo tipo de comando
    result = extract_TIPO_command_direct("Texto de exemplo")
    self.assertIsNotNone(result)
    self.assertEqual(result["type"], "tipo_comando")
    self.assertEqual(result["data"]["parametro1"], "valor_esperado")
```

### Dicas para Processadores Eficientes

1. **Comece simples**: Implemente primeiro as variantes mais comuns do comando
2. **Use palavras-chave**: Liste todas as variações possíveis de palavras-chave
3. **Valores padrão**: Sempre forneça valores padrão para parâmetros opcionais
4. **Expressões regulares eficientes**: Use regex apenas quando necessário
5. **Tratamento de erros**: Garanta que exceções não interrompam o fluxo
6. **Mensagens claras**: Crie mensagens intuitivas para o usuário final

## Exemplo: Processador de Alarme

Se implementássemos um processador para alarmes, poderia ser assim:

```python
def extract_alarm_command_direct(text: str) -> Optional[Dict]:
    text_lower = text.lower()
    
    # Detectar se é um comando de alarme
    alarm_keywords = ["alarme", "despertador", "despertar", "acordar", "lembrete", "temporizador"]
    if not any(keyword in text_lower for keyword in alarm_keywords):
        return None
    
    result = {
        "type": "set_alarm",
        "message": "Alarme configurado",
        "data": {
            "time": None,
            "date": None,
            "description": ""
        }
    }
    
    # Extrair hora (formato HH:MM ou descritivo)
    time_match = re.search(r'(\d{1,2})[:\.](\d{2})', text_lower)  # 08:30 ou 8.30
    if time_match:
        hour = int(time_match.group(1))
        minute = int(time_match.group(2))
        # Validação básica de hora
        if 0 <= hour <= 23 and 0 <= minute <= 59:
            result["data"]["time"] = f"{hour:02d}:{minute:02d}"
    
    # Extrair descrição
    description_match = re.search(r'para\s+(.+?)(?:para|às|as|em|$)', text_lower)
    if description_match:
        result["data"]["description"] = description_match.group(1).strip()
    
    # Personalizar mensagem
    if result["data"]["time"]:
        result["message"] = f"Alarme configurado para {result['data']['time']}"
        if result["data"]["description"]:
            result["message"] += f" - {result['data']['description']}"
    else:
        result = None  # Se não conseguiu extrair horário, não é um comando válido
    
    return result
```
