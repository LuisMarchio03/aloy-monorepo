package main

import (
	"fmt"
	"log"
	"os"
	"runtime"

	"github.com/LuisMarchio03/aloy-task-sync/internal/config"
	"github.com/spf13/cobra"
)

var (
	verbose    bool
	dryRun     bool
	taskID     string
	configPath string
)

func main() {
	// Carrega configurações
	cfg, err := config.LoadConfig()
	if err != nil {
		log.Fatalf("❌ Erro ao carregar configuração: %v", err)
	}

	// Comando raiz
	var rootCmd = &cobra.Command{
		Use:   "aloy",
		Short: "Gerenciador de tasks Aloy",
		Long: `Aloy Task Sync é uma ferramenta CLI para gerenciamento de tasks
no repositório Git, mantendo rastreabilidade e detectando alterações.`,
		PersistentPreRun: func(cmd *cobra.Command, args []string) {
			// Atualiza configuração com flags
			if dryRun {
				cfg.DryRun = true
			}

			if verbose {
				fmt.Println("======== ALOY TASK SYNC ========")
				fmt.Printf("Versão Go: %s\n", runtime.Version())
				dir, _ := os.Getwd()
				fmt.Printf("Diretório: %s\n", dir)

				// Mostra resumo da configuração
				fmt.Println("\n--- Configuração ---")
				for key, value := range cfg.GetConfigSummary() {
					fmt.Printf("%s: %s\n", key, value)
				}
				fmt.Println("-------------------")
			}
		},
	}

	// Flags globais
	rootCmd.PersistentFlags().BoolVarP(&verbose, "verbose", "v", false, "Modo verboso")
	rootCmd.PersistentFlags().BoolVar(&dryRun, "dry-run", cfg.DryRun, "Modo simulação (não faz alterações)")
	rootCmd.PersistentFlags().StringVar(&configPath, "config", "", "Caminho personalizado para arquivo de configuração")

	// Comando de sincronização
	var syncCmd = &cobra.Command{
		Use:   "sync",
		Short: "Sincroniza tasks do Git para o Obsidian",
		Long:  "Sincroniza tasks do repositório Git para o Obsidian, detectando mudanças e mantendo histórico",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Print("Sincronizando tasks... ")
			if err := syncTasks(cfg); err != nil {
				fmt.Printf("❌ Erro: %v\n", err)
				os.Exit(1)
			}
			fmt.Println("✅ Concluído")
		},
	}

	syncCmd.Flags().StringVar(&taskID, "task", "", "Sincroniza apenas a task específica (ID)")

	// Comando de sincronização reversa
	var syncFromCmd = &cobra.Command{
		Use:   "sync-from",
		Short: "Sincroniza tasks do Obsidian para o Git",
		Long:  "Sincroniza mudanças feitas no Obsidian de volta para o repositório Git",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Print("Sincronizando do Obsidian para Git... ")
			if err := syncFromObsidian(cfg); err != nil {
				fmt.Printf("❌ Erro: %v\n", err)
				os.Exit(1)
			}
			fmt.Println("✅ Concluído")
		},
	}

	syncFromCmd.Flags().StringVar(&taskID, "task", "", "Sincroniza apenas a task específica (ID)")

	// Comando de criação de task
	var (
		taskService   string
		taskTitle     string
		taskType      string
		taskStatus    string
		taskPriority  string
		taskAssignee  string
		autoCommit    bool
		autoSync      bool
	)

	var createCmd = &cobra.Command{
		Use:     "create [título]",
		Aliases: []string{"new"},
		Short:   "Cria uma nova task",
		Long:    "Cria uma nova task no repositório Git com ID sequencial e opcionalmente sincroniza com Obsidian",
		Example: `  aloy create "Implementar sistema de login"
  aloy create --title="Corrigir bug no formulário" --type=bug --priority=high
  aloy create "Nova feature" --service=api --assignee=joao`,
		Run: func(cmd *cobra.Command, args []string) {
			// Se título foi passado como argumento
			if len(args) > 0 && taskTitle == "" {
				taskTitle = args[0]
			}

			if taskTitle == "" {
				fmt.Println("❌ Erro: Título da task é obrigatório")
				fmt.Println("Use: aloy create 'Título da task' ou --title='Título da task'")
				os.Exit(1)
			}

			fmt.Printf("Criando task: %s... ", taskTitle)
			taskPath, err := createTask(cfg, taskTitle, taskService, taskType, taskStatus, taskPriority, taskAssignee, autoCommit)
			if err != nil {
				fmt.Printf("❌ Erro: %v\n", err)
				os.Exit(1)
			}
			fmt.Println("✅ Criada")
			fmt.Printf("📝 %s\n", taskPath)

			// Sincroniza com Obsidian se solicitado
			if autoSync {
				fmt.Print("Sincronizando com Obsidian... ")
				if err := syncTaskWithObsidian(cfg, taskPath); err != nil {
					fmt.Printf("❌ Erro na sincronização: %v\n", err)
				} else {
					fmt.Println("✅ Sincronizado")
				}
			}
		},
	}

	createCmd.Flags().StringVar(&taskService, "service", "app", "Serviço relacionado à task")
	createCmd.Flags().StringVar(&taskTitle, "title", "", "Título da task")
	createCmd.Flags().StringVar(&taskType, "type", "feature", "Tipo da task (feature, bug, chore, etc.)")
	createCmd.Flags().StringVar(&taskStatus, "status", "backlog", "Status inicial da task")
	createCmd.Flags().StringVar(&taskPriority, "priority", "medium", "Prioridade da task (low, medium, high, critical)")
	createCmd.Flags().StringVar(&taskAssignee, "assignee", "", "Pessoa responsável pela task")
	createCmd.Flags().BoolVar(&autoCommit, "commit", true, "Fazer commit automático da task criada")
	createCmd.Flags().BoolVar(&autoSync, "sync", true, "Sincronizar automaticamente com Obsidian")

	// Comando de configuração
	var configCmd = &cobra.Command{
		Use:   "config",
		Short: "Gerencia configurações",
		Long:  "Comandos para visualizar e validar configurações do Aloy Task Sync",
	}

	var configShowCmd = &cobra.Command{
		Use:   "show",
		Short: "Mostra configuração atual",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Println("=== Configuração Atual ===")
			for key, value := range cfg.GetConfigSummary() {
				fmt.Printf("%-20s: %s\n", key, value)
			}
		},
	}

	var configValidateCmd = &cobra.Command{
		Use:   "validate",
		Short: "Valida configuração atual",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Print("Validando configuração... ")
			if err := cfg.Validate(); err != nil {
				fmt.Printf("❌ Erro: %v\n", err)
				os.Exit(1)
			}
			fmt.Println("✅ Configuração válida")
		},
	}

	configCmd.AddCommand(configShowCmd)
	configCmd.AddCommand(configValidateCmd)

	// Registra todos os comandos
	rootCmd.AddCommand(syncCmd)
	rootCmd.AddCommand(syncFromCmd)
	rootCmd.AddCommand(createCmd)
	rootCmd.AddCommand(configCmd)

	// Executa comando
	if err := rootCmd.Execute(); err != nil {
		fmt.Printf("❌ Erro: %v\n", err)
		os.Exit(1)
	}
}

func syncTasks(cfg *config.Config) error {
	// TODO: Implementar sincronização Git -> Obsidian
	return fmt.Errorf("sincronização não implementada")
}

func syncFromObsidian(cfg *config.Config) error {
	// TODO: Implementar sincronização Obsidian -> Git
	return fmt.Errorf("sincronização reversa não implementada")
}

func createTask(cfg *config.Config, title, service, taskType, status, priority, assignee string, autoCommit bool) (string, error) {
	// TODO: Implementar criação de task
	return "", fmt.Errorf("criação de task não implementada")
}

func syncTaskWithObsidian(cfg *config.Config, taskPath string) error {
	// TODO: Implementar sincronização individual
	return fmt.Errorf("sincronização individual não implementada")
}