-- Inicialização do banco de dados Aloy
-- Criação de schema e tabelas básicas

-- Extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Schema para Core
CREATE SCHEMA IF NOT EXISTS core;

-- Schema para Scheduler
CREATE SCHEMA IF NOT EXISTS scheduler;

-- Schema para Task Sync
CREATE SCHEMA IF NOT EXISTS tasksync;

-- Schema para System Monitor
CREATE SCHEMA IF NOT EXISTS sysmonitor;

-- Tabela de usuários (Core)
CREATE TABLE IF NOT EXISTS core.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de tarefas (Scheduler)
CREATE TABLE IF NOT EXISTS scheduler.tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    cron_expression VARCHAR(100),
    enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de execuções de tarefas (Scheduler)
CREATE TABLE IF NOT EXISTS scheduler.task_executions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID REFERENCES scheduler.tasks(id),
    status VARCHAR(50) NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    finished_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT
);

-- Tabela de sincronização (Task Sync)
CREATE TABLE IF NOT EXISTS tasksync.sync_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source VARCHAR(100) NOT NULL,
    target VARCHAR(100) NOT NULL,
    sync_type VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL,
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de métricas do sistema (System Monitor)
CREATE TABLE IF NOT EXISTS sysmonitor.system_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cpu_usage DECIMAL(5,2),
    memory_usage DECIMAL(5,2),
    disk_usage DECIMAL(5,2),
    network_in BIGINT,
    network_out BIGINT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_users_email ON core.users(email);
CREATE INDEX IF NOT EXISTS idx_tasks_enabled ON scheduler.tasks(enabled);
CREATE INDEX IF NOT EXISTS idx_task_executions_task_id ON scheduler.task_executions(task_id);
CREATE INDEX IF NOT EXISTS idx_task_executions_status ON scheduler.task_executions(status);
CREATE INDEX IF NOT EXISTS idx_sync_logs_created_at ON tasksync.sync_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_system_metrics_timestamp ON sysmonitor.system_metrics(timestamp);

-- Dados iniciais de exemplo
INSERT INTO core.users (email, password_hash, name) VALUES 
('admin@aloy.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'Administrator')
ON CONFLICT (email) DO NOTHING;

INSERT INTO scheduler.tasks (name, description, cron_expression) VALUES 
('Health Check', 'Verificação de saúde dos serviços', '*/5 * * * *'),
('Data Backup', 'Backup dos dados do sistema', '0 2 * * *'),
('Log Cleanup', 'Limpeza de logs antigos', '0 3 * * 0')
ON CONFLICT DO NOTHING;
