package config

import (
	"log"
	"os"
	"path/filepath"

	"github.com/joho/godotenv"
)

func LoadEnv() {
	rootEnvPath := filepath.Join("..", ".env.local")
	localEnvPath := ".env.local"

	if err := godotenv.Overload(rootEnvPath); err != nil {
		log.Println("⚠️  .env global não carregado:", err)
	} else {
		log.Println("✅ .env global carregado")
	}

	if err := godotenv.Overload(localEnvPath); err != nil {
		log.Println("⚠️  .env local não carregado:", err)
	} else {
		log.Println("✅ .env local carregado")
	}
}

func GetEnv(key string, fallback string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return fallback
}
