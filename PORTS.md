# =================================================================
# ALOY - Mapa de Portas do Sistema
# =================================================================
# Este arquivo documenta todas as portas utilizadas no sistema Aloy
# Use como referência para evitar conflitos de porta

# =================================================================
# FRONTEND & INTERFACES (1000-1099)
# =================================================================
1000    ALOY_DESKTOP_PORT           Frontend Desktop (Electron)
1001    ALOY_WEB_PORT               Frontend Web
1002    ALOY_MOBILE_API_PORT        API para Mobile

# =================================================================
# APIS PRINCIPAIS (1100-1199)
# =================================================================
1100    ALOY_CORE_PORT              Core API - Serviço principal
1101    ALOY_GATEWAY_PORT           API Gateway
1102    ALOY_AUTH_PORT              Serviço de Autenticação
1103    ALOY_NOTIFICATION_PORT      Serviço de Notificações

# =================================================================
# NLP / STT / TTS (1200-1299)
# =================================================================
1200    ALOY_NLP_PORT               Processamento de Linguagem Natural
1201    ALOY_STT_PORT               Speech to Text
1202    ALOY_TTS_PORT               Text to Speech
1203    ALOY_TRANSLATION_PORT       Serviço de Tradução

# =================================================================
# SERVIÇOS AUXILIARES (1300-1399)
# =================================================================
1300    ALOY_SYSTEM_MONITOR_PORT    Monitor do Sistema
1301    ALOY_SCHEDULER_PORT         Agendador de Tarefas
1302    ALOY_TASK_SYNC_PORT         Sincronização de Tarefas
1303    ALOY_FILE_MANAGER_PORT      Gerenciador de Arquivos
1304    ALOY_BACKUP_PORT            Serviço de Backup

# =================================================================
# INTEGRAÇÕES COM TERCEIROS (1400-1499)
# =================================================================
1400    ALOY_GOOGLE_SYNC_PORT       Integração Google
1401    ALOY_OUTLOOK_SYNC_PORT      Integração Outlook
1402    ALOY_SLACK_SYNC_PORT        Integração Slack
1403    ALOY_TRELLO_SYNC_PORT       Integração Trello
1404    ALOY_GITHUB_SYNC_PORT       Integração GitHub

# =================================================================
# FERRAMENTAS INTERNAS (1500-1599)
# =================================================================
1500    FOCALBOARD_PORT             Focalboard (Kanban)
1501    ALOY_WIKI_PORT              Wiki Interno
1502    ALOY_DOCS_PORT              Documentação
1503    ALOY_ADMIN_PORT             Painel Administrativo

# =================================================================
# INFRA & OBSERVABILIDADE (1600-1699)
# =================================================================
1600    PROMETHEUS_PORT             Prometheus (Métricas)
1601    GRAFANA_PORT                Grafana (Dashboards)
1602    JAEGER_PORT                 Jaeger (Tracing)
1603    ELASTIC_PORT                Elasticsearch
1604    KIBANA_PORT                 Kibana (Logs)
1605    ALERTMANAGER_PORT           AlertManager

# =================================================================
# BANCO DE DADOS & STORAGE (1700-1799)
# =================================================================
1700    POSTGRES_PORT               PostgreSQL
1701    MINIO_PORT                  MinIO (S3 Compatible)
1702    MINIO_CONSOLE_PORT          MinIO Console
1703    MONGODB_PORT                MongoDB (se necessário)
1704    MYSQL_PORT                  MySQL (se necessário)

# =================================================================
# MENSAGERIA (1800-1899)
# =================================================================
1800    RABBITMQ_AMQP_PORT         RabbitMQ AMQP
1801    RABBITMQ_UI_PORT           RabbitMQ Management UI
1802    KAFKA_PORT                 Apache Kafka (se necessário)
1803    REDIS_PORT                 Redis (6379 padrão mantido)

# =================================================================
# DESENVOLVIMENTO & TESTES (9000-9099)
# =================================================================
9000    MOCK_SERVER_PORT           Servidor de Mocks
9001    TEST_DB_PORT               Banco de Dados de Teste
9002    STORYBOOK_PORT             Storybook (se usado)
9003    API_DOCS_PORT              Documentação da API

# =================================================================
# PORTAS PADRÃO MANTIDAS
# =================================================================
6379    REDIS_PORT                 Redis (porta padrão)
80      HTTP_PORT                  Nginx HTTP
443     HTTPS_PORT                 Nginx HTTPS
22      SSH_PORT                   SSH (se necessário)

# =================================================================
# NOTAS DE USO
# =================================================================
# 
# 1. Prefixos por faixa de porta:
#    - 1000-1099: Frontend/UI
#    - 1100-1199: APIs Core
#    - 1200-1299: AI/ML Services
#    - 1300-1399: Utilities
#    - 1400-1499: Integrations
#    - 1500-1599: Tools
#    - 1600-1699: Monitoring
#    - 1700-1799: Databases
#    - 1800-1899: Messaging
#    - 9000-9099: Development
#
# 2. Para adicionar nova porta:
#    - Escolha a faixa apropriada
#    - Atualize este arquivo
#    - Atualize o .env global
#    - Execute: make env-sync
#
# 3. Verificar conflitos:
#    - netstat -tlnp | grep :PORTA
#    - lsof -i :PORTA
#
# 4. Docker port mapping:
#    - HOST_PORT:CONTAINER_PORT
#    - Exemplo: "1100:8080"
