package server

import (
	"encoding/json"
	"log"
	"net"
	"net/http"
	"os"

	"github.com/gorilla/handlers"
	"github.com/gorilla/mux"
	"github.com/shirou/gopsutil/v4/cpu"
	"github.com/shirou/gopsutil/v4/disk"
	"github.com/shirou/gopsutil/v4/mem"
	netstat "github.com/shirou/gopsutil/v4/net"
)

// NewRouter cria as rotas do servidor HTTP
func NewRouter() http.Handler {
	r := mux.NewRouter()

	// Rota para informações do sistema
	r.HandleFunc("/api/system-info", systemInfosHandler).Methods("GET")

	return r
}

// systemInfosHandler retorna informações do PC Server
func systemInfosHandler(w http.ResponseWriter, r *http.Request) {
	data, err := getSystemInfos()
	if err != nil {
		http.Error(w, "Erro ao obter informações do sistema", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(data)
}

// getSystemInfos obtém informações do sistema
func getSystemInfos() (map[string]any, error) {
	hostname, err := os.Hostname()
	if err != nil {
		hostname = "Desconhecido"
	}
	ip, err := getLocalIP()
	if err != nil {
		ip = "Desconhecido"
	}

	// Dados de uso de CPU, memória e disco
	cpuPercent, err := cpu.Percent(0, false)
	if err != nil {
		return nil, err
	}
	memInfo, err := mem.VirtualMemory()
	if err != nil {
		return nil, err
	}
	diskUsage, err := disk.Usage("/")
	if err != nil {
		return nil, err
	}
	netInfo, err := netstat.IOCounters(false)
	if err != nil {
		return nil, err
	}

	// Retorno de dados coletados
	data := map[string]any{
		"hostname":     hostname,
		"ip":           ip,
		"cpu_usage":    cpuPercent[0],
		"memory_usage": memInfo.UsedPercent,
		"disk_usage":   diskUsage.UsedPercent,
		"net_sent":     netInfo[0].BytesSent,
		"net_recv":     netInfo[0].BytesRecv,
	}

	return data, nil
}

// getLocalIP obtém o IP local do PC
func getLocalIP() (string, error) {
	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return "", err
	}

	for _, addr := range addrs {
		if ipNet, ok := addr.(*net.IPNet); ok && !ipNet.IP.IsLoopback() {
			if ipNet.IP.To4() != nil {
				return ipNet.IP.String(), nil
			}
		}
	}

	return "", nil
}

// StartServer inicia o servidor HTTP
func StartServer() {
	// Configura as rotas
	router := NewRouter()

	// Permite solicitações de todas as origens (CORS)
	corsObj := handlers.AllowedOrigins([]string{"*"})

	// Log de execução e inicialização do servidor HTTP
	log.Println("🚀 Servidor rodando em http://localhost:8080")
	log.Fatal(http.ListenAndServe(":8080", handlers.CORS(corsObj)(router)))
}
