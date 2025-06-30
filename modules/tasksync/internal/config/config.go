package config

import (
	"fmt"
	"log"
	"os"
	"path/filepath"

	"github.com/joho/godotenv"
)

// Config representa a configuração da aplicação
type Config struct {
	AloyRepoPath  string
	ObsidianPath  string
	GitRepoURL    string
	GitUsername   string
	GitToken      string
	LogLevel      string
	DryRun        bool
}

// LoadEnv carrega as variáveis de ambiente dos arquivos .env
// Prioridade: .env.local (projeto) > .env.local (global) > .env (projeto) > .env (global)
func LoadEnv() {
	var loadedFiles []string
	var errors []error

	// Caminhos dos arquivos de ambiente
	projectRoot, _ := os.Getwd()
	globalRoot := filepath.Join(projectRoot, "..")
	
	envFiles := []struct {
		path     string
		name     string
		priority int
	}{
		{filepath.Join(globalRoot, ".env"), "global .env", 1},
		{filepath.Join(projectRoot, ".env"), "local .env", 2},
		{filepath.Join(globalRoot, ".env.local"), "global .env.local", 3},
		{filepath.Join(projectRoot, ".env.local"), "local .env.local", 4},
	}

	// Carrega arquivos em ordem de prioridade
	for _, envFile := range envFiles {
		if err := godotenv.Load(envFile.path); err != nil {
			errors = append(errors, fmt.Errorf("%s (%s): %w", envFile.name, envFile.path, err))
		} else {
			loadedFiles = append(loadedFiles, envFile.name)
		}
	}

	// Log dos resultados
	if len(loadedFiles) > 0 {
		log.Printf("✅ Arquivos de ambiente carregados: %v", loadedFiles)
	} else {
		log.Println("⚠️  Nenhum arquivo de ambiente carregado")
	}

	// Log de erros apenas em modo verbose
	if os.Getenv("ALOY_VERBOSE") == "true" {
		for _, err := range errors {
			log.Printf("⚠️  %v", err)
		}
	}
}

// GetEnv obtém uma variável de ambiente com valor padrão
func GetEnv(key string, fallback string) string {
	if value, exists := os.LookupEnv(key); exists && value != "" {
		return value
	}
	return fallback
}

// GetRequiredEnv obtém uma variável de ambiente obrigatória
func GetRequiredEnv(key string) (string, error) {
	if value, exists := os.LookupEnv(key); exists && value != "" {
		return value, nil
	}
	return "", fmt.Errorf("variável de ambiente obrigatória não definida: %s", key)
}

// LoadConfig carrega toda a configuração da aplicação
func LoadConfig() (*Config, error) {
	LoadEnv()

	config := &Config{
		AloyRepoPath: GetEnv("ALOY_REPO_PATH", ""),
		ObsidianPath: GetEnv("OBSIDIAN_PATH", ""),
		GitRepoURL:   GetEnv("ALOY_GIT_REPO_URL", "https://github.com/LuisMarchio03/aloy-tasks-repo.git"),
		GitUsername:  GetEnv("ALOY_GIT_USERNAME", ""),
		GitToken:     GetEnv("ALOY_GIT_TOKEN", ""),
		LogLevel:     GetEnv("ALOY_LOG_LEVEL", "info"),
		DryRun:       GetEnv("ALOY_DRY_RUN", "false") == "true",
	}

	// Validação de configurações obrigatórias
	if err := config.Validate(); err != nil {
		return nil, fmt.Errorf("configuração inválida: %w", err)
	}

	return config, nil
}

// Validate valida se as configurações obrigatórias estão definidas
func (c *Config) Validate() error {
	if c.AloyRepoPath == "" {
		return fmt.Errorf("ALOY_REPO_PATH é obrigatório")
	}

	if c.ObsidianPath == "" {
		return fmt.Errorf("OBSIDIAN_PATH é obrigatório")
	}

	// Verifica se os diretórios existem ou podem ser criados
	if err := c.validatePaths(); err != nil {
		return err
	}

	return nil
}

// validatePaths valida se os caminhos especificados são válidos
func (c *Config) validatePaths() error {
	// Valida ALOY_REPO_PATH
	if c.AloyRepoPath != "" {
		if err := ensureDirectoryExists(c.AloyRepoPath); err != nil {
			return fmt.Errorf("erro no ALOY_REPO_PATH (%s): %w", c.AloyRepoPath, err)
		}
	}

	// Valida OBSIDIAN_PATH
	if c.ObsidianPath != "" {
		if err := ensureDirectoryExists(c.ObsidianPath); err != nil {
			return fmt.Errorf("erro no OBSIDIAN_PATH (%s): %w", c.ObsidianPath, err)
		}
	}

	return nil
}

// ensureDirectoryExists verifica se um diretório existe ou pode ser criado
func ensureDirectoryExists(path string) error {
	// Verifica se já existe
	if info, err := os.Stat(path); err == nil {
		if !info.IsDir() {
			return fmt.Errorf("caminho existe mas não é um diretório: %s", path)
		}
		return nil // Diretório já existe
	}

	// Tenta criar o diretório
	if err := os.MkdirAll(path, 0755); err != nil {
		return fmt.Errorf("não foi possível criar diretório: %w", err)
	}

	return nil
}

// GetConfigSummary retorna um resumo da configuração para debug
func (c *Config) GetConfigSummary() map[string]string {
	return map[string]string{
		"ALOY_REPO_PATH":     c.AloyRepoPath,
		"OBSIDIAN_PATH":      c.ObsidianPath,
		"ALOY_GIT_REPO_URL":  c.GitRepoURL,
		"ALOY_GIT_USERNAME":  maskSensitive(c.GitUsername),
		"ALOY_GIT_TOKEN":     maskSensitive(c.GitToken),
		"ALOY_LOG_LEVEL":     c.LogLevel,
		"ALOY_DRY_RUN":       fmt.Sprintf("%t", c.DryRun),
	}
}

// maskSensitive mascara informações sensíveis para logs
func maskSensitive(value string) string {
	if value == "" {
		return "<não definido>"
	}
	if len(value) <= 4 {
		return "****"
	}
	return value[:2] + "****" + value[len(value)-2:]
}
