package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	timego "time"

	"github.com/LuisMarchio03/aloy-core-go-v0/internal/config"
	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"

	amqp "github.com/rabbitmq/amqp091-go"
)

type Message struct {
	Message string `json:"message"`
}

type Command struct {
	Type    string          `json:"type"`
	Data    json.RawMessage `json:"data"` // Changed from string to json.RawMessage
	Message string          `json:"message"`
}

type AlarmCommand struct {
	Time   string `json:"time"`
	Date   string `json:"date"`
	Repeat string `json:"repeat"`
	Days   string `json:"days"`
	Label  string `json:"label"`
}

type LampCommand struct {
	Action    string `json:"action"`
	Room      string `json:"room"`
	Color     string `json:"color,omitempty"`
	Intensity string `json:"intensity,omitempty"`
}

func failOnError(err error, msg string) {
	if err != nil {
		log.Panicf("%s: %s", msg, err)
	}
}

func main() {
	// Load .env
	config.LoadEnv()

	// CHI Router
	r := chi.NewRouter()

	// RabbitMQ
	stringConn := config.GetEnv("RABBITMQ_CONNECTION_STRING", "")
	conn, err := amqp.Dial(stringConn)
	failOnError(err, "Failed to connect to RabbitMQ")
	defer conn.Close()

	// Middlewares
	r.Use(
		middleware.RequestID,
		middleware.Recoverer,
		middleware.Logger,
	)

	// CORS para acesso externo
	r.Use(cors.Handler(cors.Options{
		AllowedOrigins:   []string{"https://*", "http://*"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type", "X-CSRF-Token"},
		ExposedHeaders:   []string{"Link"},
		AllowCredentials: false,
		MaxAge:           300,
	}))

	// Rota principal para processar comandos
	r.Post("/commands", func(w http.ResponseWriter, r *http.Request) {
		var msg Message
		if err := json.NewDecoder(r.Body).Decode(&msg); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		// Simula o processamento do comando
		result, err := ProcessMessage(msg, conn)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(result)
	})

	port := config.GetEnv("ALOY_CORE_PORT", "1100")

	fmt.Println("🚀 Aloy-Core rodando na porta: ", port)
	http.ListenAndServe(":"+port, r)
}

// ProcessMessage simula a IA processando linguagem natural
func ProcessMessage(msg Message, conn *amqp.Connection) (map[string]string, error) {
	if msg.Message == "" {
		return nil, fmt.Errorf("mensagem vazia")
	}

	// 🔍 Simula a IA LLaMA 3 interpretando o comando
	// cmd := InterpretWithLLaMA(msg.Message)
	cmd, err := interpretWithLLaMA(msg.Message)
	if err != nil {
		return nil, fmt.Errorf("erro ao interpretar a mensagem: %v", err)
	}

	// Adiciona log do tipo e mensagem recebidos do NLP
	log.Printf("[Aloy-Core] Tipo recebido do NLP: %s | Mensagem: %s", cmd.Type, cmd.Message)

	var allCases [20]string

	// Comandos de alarme
	allCases[0] = "set_alarm"
	allCases[1] = "cancel_alarm"

	// Comandos de lembrete - Google Agenda
	allCases[2] = "set_reminder"
	allCases[3] = "cancel_reminder"
	
	// Comandos de controle de lâmpadas
	allCases[4] = "lamp_control"

	// Open programas PC Windows
	allCases[5] = "open_program"
	allCases[6] = "close_program"

	// Executar comandos no terminal - Windows (Tentar integrar com PowerShell... recebe um comando e executa)
	allCases[7] = "execute_command"

	// Integrar com Spotify
	allCases[8] = "play_music"
	allCases[9] = "pause_music"
	allCases[10] = "stop_music"
	allCases[11] = "next_song"
	allCases[12] = "previous_song"

	// ⚙️ Simula a execução da ação
	switch cmd.Type {
	case allCases[0]:
		var alarmCommand AlarmCommand
		if err := json.Unmarshal(cmd.Data, &alarmCommand); err != nil { // Remove []byte() conversion
			return nil, fmt.Errorf("erro ao decodificar o comando: %v", err)
		}
		setAlarm(alarmCommand, conn)
	case allCases[1]:
		cancelAlarm()
	case allCases[2]:
		// setReminder(cmd.Data)
	case allCases[3]:
		cancelReminder()
	case allCases[4]: // lamp_control
		var lampCmd LampCommand
		if err := json.Unmarshal(cmd.Data, &lampCmd); err != nil {
			return nil, fmt.Errorf("erro ao decodificar comando da lâmpada: %v", err)
		}
		return sendLampCommand(lampCmd, conn)
	case "conversa", "pesquisa":
		return map[string]string{
			"status":  "ok",
			"message": cmd.Message,
		}, nil
	default:
		log.Printf("Comando não reconhecido: %s", cmd.Type)
		return map[string]string{
			"status":  "unknown",
			"message": cmd.Message,
		}, nil
	}

	return map[string]string{
		"status":  "success",
		"message": cmd.Message,
	}, nil
}

// InterpretWithLLaMA simula a IA interpretando linguagem natural
// func InterpretWithLLaMA(input string) Command {
// 	input = strings.ToLower(input)

// 	// ⚠️ Aqui seria onde você integra com a LLaMA 3 de verdade.
// 	// Esta simulação reconhece apenas comandos de alarme.
// 	if strings.Contains(input, "despertador") && strings.Contains(input, "amanhã") {
// 		return Command{
// 			Type: "set_alarm",
// 			Data: "07:00",
// 		}
// 	}

// 	// Comando desconhecido
// 	return Command{
// 		Type: "unknown",
// 		Data: "",
// 	}
// }

func interpretWithLLaMA(message string) (Command, error) {
	// Corpo da requisição
	body := map[string]string{
		"message": message,
	}
	bodyJson, err := json.Marshal(body)
	if err != nil {
		return Command{}, fmt.Errorf("erro ao marshaling a mensagem: %v", err)
	}

	// Enviar requisição POST para a API Python (rodando no Docker)
	resp, err := http.Post("http://127.0.0.1:1200/interpret", "application/json", bytes.NewBuffer(bodyJson))
	if err != nil {
		return Command{}, fmt.Errorf("erro ao fazer requisição para a API Python: %v", err)
	}
	defer resp.Body.Close()

	// Processar a resposta da API
	var cmd Command
	err = json.NewDecoder(resp.Body).Decode(&cmd)
	if err != nil {
		return Command{}, fmt.Errorf("erro ao decodificar a resposta: %v", err)
	}

	return cmd, nil
}

func setAlarm(alarmCommand AlarmCommand, conn *amqp.Connection) string {
	// Enviar operação de alarme pelo rabbitMQ para o Proximo Serviços --> No caso eu vou criar um app no Celular proprio para ativar esses despertadores
	ch, err := conn.Channel()
	failOnError(err, "Failed to open a channel")
	defer ch.Close()

	q, err := ch.QueueDeclare(
		"set_alarm", // name
		true,        // durable
		false,       // delete when unused
		false,       // exclusive
		false,       // no-wait
		nil,         // arguments
	)
	failOnError(err, "Failed to declare a queue")

	ctx, cancel := context.WithTimeout(context.Background(), 5*timego.Second)
	defer cancel()

	body, err := json.Marshal(map[string]string{
		"time":   alarmCommand.Time,
		"date":   alarmCommand.Date,
		"repeat": alarmCommand.Repeat,
		"days":   alarmCommand.Days,
		"label":  alarmCommand.Label,
	})
	if err != nil {
		failOnError(err, "Failed to marshal JSON")
	}

	err = ch.PublishWithContext(ctx,
		"",     // exchange
		q.Name, // routing key
		false,  // mandatory
		false,  // immediate
		amqp.Publishing{
			ContentType: "text/plain",
			Body:        []byte(body),
		})
	failOnError(err, "Failed to publish a message")
	log.Printf(" [x] Sent %s\n", body)

	return "Alarme definido com sucesso"
}

func cancelAlarm() string {
	// Simula o cancelamento de um alarme
	return "Alarme cancelado"
}

func setReminder(date string) string {
	// Simula o agendamento de um lembrete
	return fmt.Sprintf("Lembrete definido para %s", date)
}

func cancelReminder() string {
	// Simula o cancelamento de um lembrete
	return "Lembrete cancelado"
}

func sendLampCommand(cmd LampCommand, conn *amqp.Connection) (map[string]string, error) {
	ch, err := conn.Channel()
	failOnError(err, "Erro ao abrir canal")
	defer ch.Close()

	q, err := ch.QueueDeclare(
		"lamp_control", // nome
		true,           // durable
		false,          // delete when unused
		false,          // exclusive
		false,          // no-wait
		nil,            // arguments
	)
	failOnError(err, "Erro ao declarar fila")

	ctx, cancel := context.WithTimeout(context.Background(), 5*timego.Second)
	defer cancel()

	body, err := json.Marshal(cmd)
	failOnError(err, "Erro ao serializar comando de lâmpada")

	err = ch.PublishWithContext(ctx,
		"",     // exchange
		q.Name, // routing key
		false,  // mandatory
		false,  // immediate
		amqp.Publishing{
			ContentType: "application/json",
			Body:        body,
		})
	failOnError(err, "Erro ao publicar mensagem de lâmpada")

	log.Printf("🔌 Comando de lâmpada enviado: %s", body)

	message := fmt.Sprintf("Comando para %s da lâmpada no(a) %s enviado com sucesso", cmd.Action, cmd.Room)
	if cmd.Action == "set_color" && cmd.Color != "" {
		message = fmt.Sprintf("Cor da lâmpada no(a) %s alterada para %s", cmd.Room, cmd.Color)
	} else if cmd.Action == "set_intensity" && cmd.Intensity != "" {
		message = fmt.Sprintf("Intensidade da lâmpada no(a) %s alterada para %s%%", cmd.Room, cmd.Intensity)
	} else if cmd.Action == "turn_on" {
		message = fmt.Sprintf("Lâmpada no(a) %s acesa", cmd.Room)
	} else if cmd.Action == "turn_off" {
		message = fmt.Sprintf("Lâmpada no(a) %s apagada", cmd.Room)
	}

	return map[string]string{
		"status":  "ok",
		"message": message,
	}, nil
}
