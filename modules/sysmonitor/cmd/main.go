package main

import (
	"fmt"
	"log"
	"net/http"

	config "github.com/LuisMarchio03/aloy-system-monitor-go-v0/internal/configs"
	"github.com/LuisMarchio03/aloy-system-monitor-go-v0/internal/server"
	"github.com/gorilla/handlers"
)

func main() {
	// Cria o roteador com as rotas do servidor
	router := server.NewRouter()
	corsObj := handlers.AllowedOrigins([]string{"*"})

	// Inicializa o servidor HTTP e loga as requisições
	port := config.GetEnv("ALOY_SYSTEM_MONITOR_PORT", "1300")
	fmt.Println("🚀 Aloy-System-Monitor rodando na porta: " + port)
	log.Fatal(http.ListenAndServe(":"+port, handlers.CORS(corsObj)(router)))
}
