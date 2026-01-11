# Airflow Deployment Management
# Using `just` command runner for automated deployments
#
# Installation:
#   curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin
#
# Usage:
#   just init           - Initialize the environment (run once)
#   just up             - Start all services in detached mode
#   just up-debug       - Start in foreground for debugging
#   just down           - Stop all services (preserve volumes)
#   just down-vols      - Stop and remove volumes
#   just restart        - Restart all services
#   just logs           - Follow logs from all services
#   just status         - Show service status
#   just migrate        - Run database migrations
#
# For more commands, run: just

# =============================================================================
# CONFIGURATION
# =============================================================================

# Docker Compose project name
project := "airflow"

# Docker Compose file path
compose_file := "docker-compose.yml"

# Environment file
env_file := ".env"

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

# Get docker compose command with environment file
dc_cmd := "docker compose -f " + compose_file + " --env-file " + env_file

# Get project name
get_project_name:
    @echo {{project}}

# Check if docker is running
check-docker:
    #!/usr/bin/env bash
    if ! docker info > /dev/null 2>&1; then
        echo "Error: Docker is not running. Please start Docker."
        exit 1
    fi
    echo "Docker is running."

# Check if docker compose is available
check-docker-compose:
    #!/usr/bin/env bash
    if ! command -v docker &> /dev/null || ! docker compose version &> /dev/null; then
        echo "Error: Docker Compose is not available. Please install Docker Compose v2.14+."
        exit 1
    fi
    echo "Docker Compose is available."

# =============================================================================
# INITIALIZATION
# =============================================================================

# =============================================================================
# INITIALIZATION
# =============================================================================

# Generate secure keys for production deployment
[no-cd]
generate-keys:
    #!/usr/bin/env bash
    set -e

    echo "========================================"
    echo "Generating Secure Keys for Airflow"
    echo "========================================"
    echo ""

    # Generate Fernet key (requires cryptography package)
    # Fernet key must be Base64-encoded and 32 bytes URL-safe
    if command -v python3 &> /dev/null && python3 -c "from cryptography.fernet import Fernet" 2>/dev/null; then
        FERNET_KEY=$(python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())")
        echo "Generated Fernet key using Python cryptography library."
    else
        # Fallback: Generate a valid-looking key (users should install cryptography for proper key)
        FERNET_KEY=$(openssl rand -base64 32)
        echo "Note: cryptography library not installed. Using OpenSSL-generated key."
        echo "For production, install cryptography and regenerate: pip install cryptography"
    fi

    echo ""
    echo "Fernet Key:"
    echo "  $FERNET_KEY"
    echo ""

    # Generate webserver secret key (URL-safe Base64, 32 bytes)
    WEB_SECRET=$(openssl rand -base64 32)
    echo "Webserver Secret Key:"
    echo "  $WEB_SECRET"
    echo ""

    # Option to update .env file
    if [ -f ".env" ]; then
        echo "========================================"
        echo "Updating .env file with generated keys..."
        echo "========================================"

        # Update or add AIRFLOW_FERNET_KEY
        if grep -q "^AIRFLOW_FERNET_KEY=" .env 2>/dev/null; then
            sed -i "s|^AIRFLOW_FERNET_KEY=.*|AIRFLOW_FERNET_KEY=$FERNET_KEY|" .env
        else
            echo "AIRFLOW_FERNET_KEY=$FERNET_KEY" >> .env
        fi

        # Update or add AIRFLOW_WEBSERVER_SECRET_KEY
        if grep -q "^AIRFLOW_WEBSERVER_SECRET_KEY=" .env 2>/dev/null; then
            sed -i "s|^AIRFLOW_WEBSERVER_SECRET_KEY=.*|AIRFLOW_WEBSERVER_SECRET_KEY=$WEB_SECRET|" .env
        else
            echo "AIRFLOW_WEBSERVER_SECRET_KEY=$WEB_SECRET" >> .env
        fi

        echo ""
        echo "Keys have been saved to .env file."
    else
        echo "========================================"
        echo "No .env file found. Add these to your .env:"
        echo "========================================"
        echo ""
        echo "AIRFLOW_FERNET_KEY=$FERNET_KEY"
        echo "AIRFLOW_WEBSERVER_SECRET_KEY=$WEB_SECRET"
    fi

    echo ""
    echo "IMPORTANT: Keep these keys safe! They are used for:"
    echo "  - AIRFLOW_FERNET_KEY: Encrypting connections and variables"
    echo "  - AIRFLOW_WEBSERVER_SECRET_KEY: Signing session cookies"
    echo ""
    echo "========================================"
    echo "Key Generation Complete!"
    echo "========================================"

# Generate and apply secure keys to .env
[no-cd]
setup-secure: generate-keys
    @echo ""
    @echo "Keys generated and saved. Run 'just init' to continue."

# Initialize the environment (create directories and run init service)
[no-cd]
init: check-docker check-docker-compose create-dirs
    @echo "========================================"
    @echo "Initializing Airflow Environment"
    @echo "========================================"
    {{dc_cmd}} up airflow-init
    @echo ""
    @echo "========================================"
    @echo "Initialization Complete!"
    @echo "========================================"
    @echo "Web UI: http://localhost:8080"
    @echo "Default credentials: airflow / airflow"
    @echo ""
    @echo "Run 'just up' to start all services."

# Create required directories
[no-cd]
create-dirs:
    @echo "Creating required directories..."
    mkdir -p dags logs plugins config data/postgres
    @echo "Directories created."

# =============================================================================
# START/STOP
# =============================================================================

# Start all services in detached mode
[no-cd]
up: check-docker check-docker-compose
    @echo "========================================"
    @echo "Starting Airflow Services"
    @echo "========================================"
    {{dc_cmd}} up -d
    @echo ""
    @echo "Services started. Use 'just logs' to view logs."

# Start all services in foreground (for debugging)
[no-cd]
up-debug: check-docker check-docker-compose
    @echo "========================================"
    @echo "Starting Airflow Services (Debug Mode)"
    @echo "========================================"
    {{dc_cmd}} up

# Start flower dashboard (optional)
[no-cd]
flower-up: check-docker check-docker-compose
    @echo "Starting Flower dashboard..."
    {{dc_cmd}} --profile flower up -d
    @echo "Flower available at http://localhost:5555"

# Stop all services (preserve volumes)
[no-cd]
down: check-docker-compose
    @echo "========================================"
    @echo "Stopping Airflow Services"
    @echo "========================================"
    {{dc_cmd}} down
    @echo "Services stopped. Volumes preserved."

# Stop all services and remove volumes
[no-cd]
down-vols: check-docker-compose
    @echo "========================================"
    @echo "Stopping Airflow Services and Removing Volumes"
    @echo "========================================"
    {{dc_cmd}} down --volumes --remove-orphans
    @echo "Services stopped and volumes removed."

# Stop all services, remove volumes, and remove images
[no-cd]
clean: check-docker-compose
    @echo "========================================"
    @echo "Complete Cleanup"
    @echo "========================================"
    {{dc_cmd}} down --volumes --remove-orphans --rmi all
    @echo "Complete cleanup finished."

# =============================================================================
# RESTART / RECYCLE
# =============================================================================

# Restart all services
[no-cd]
restart: down up
    @echo "Services restarted."

# Restart a specific service
[no-cd]
restart-service service:
    {{dc_cmd}} restart {{service}}

# Recreate all containers (useful for config changes)
[no-cd]
recreate: check-docker-compose
    @echo "========================================"
    @echo "Recreating Containers"
    @echo "========================================"
    {{dc_cmd}} down
    {{dc_cmd}} up -d --force-recreate
    @echo "Containers recreated."

# =============================================================================
# LOGS AND STATUS
# =============================================================================

# Follow logs from all services
logs: check-docker-compose
    {{dc_cmd}} logs -f

# Follow logs from a specific service
[no-cd]
log service:
    {{dc_cmd}} logs -f {{service}}

# Show service status
[no-cd]
status: check-docker-compose
    @echo "========================================"
    @echo "Airflow Service Status"
    @echo "========================================"
    {{dc_cmd}} ps
    @echo ""
    @echo "========================================"
    @echo "Resource Usage"
    @echo "========================================"
    @docker stats --no-stream $$(docker ps -q --filter "name={{project}}")

# =============================================================================
# DATABASE OPERATIONS
# =============================================================================

# Run database migrations
[no-cd]
migrate: check-docker-compose
    @echo "========================================"
    @echo "Running Database Migrations"
    @echo "========================================"
    {{dc_cmd}} exec airflow-scheduler airflow db migrate
    @echo "Database migrations complete."

# Check database status
[no-cd]
db-status: check-docker-compose
    {{dc_cmd}} exec postgres psql -U airflow -d airflow -c "SELECT 1 as test;"

# Reset database (WARNING: destroys all data)
[no-cd]
db-reset: check-docker-compose
    @echo "========================================"
    @echo "WARNING: This will destroy all data!"
    @echo "========================================"
    {{dc_cmd}} down -v
    {{dc_cmd}} up -d postgres
    @echo "Waiting for database to be ready..."
    sleep 5
    {{dc_cmd}} run airflow-init
    @echo "Database reset complete."

# =============================================================================
# SCALING
# =============================================================================

# Scale workers to n instances
[no-cd]
scale-worker n: check-docker-compose
    {{dc_cmd}} up -d --scale airflow-worker={{n}}
    @echo "Scaled to {{n}} worker(s)."

# =============================================================================
# CLI COMMANDS
# =============================================================================

# Run airflow CLI command
[no-cd]
airflow args="":
    {{dc_cmd}} run --rm airflow-cli airflow {{args}}

# Run bash in airflow-cli container
[no-cd]
bash:
    {{dc_cmd}} run --rm -it airflow-cli bash

# Run python in airflow-cli container
[no-cd]
python:
    {{dc_cmd}} run --rm -it airflow-cli python

# List DAGs
[no-cd]
dags-list: check-docker-compose
    {{dc_cmd}} exec airflow-scheduler airflow dags list

# Unpause a DAG
[no-cd]
dag-unpause dag_id:
    {{dc_cmd}} exec airflow-scheduler airflow dags unpause {{dag_id}}

# Pause a DAG
[no-cd]
dag-pause dag_id:
    {{dc_cmd}} exec airflow-scheduler airflow dags pause {{dag_id}}

# Trigger a DAG run
[no-cd]
dag-trigger dag_id:
    {{dc_cmd}} exec airflow-scheduler airflow dags trigger {{dag_id}}

# =============================================================================
# BACKUP AND RESTORE
# =============================================================================

# Backup database
[no-cd]
backup:
    #!/usr/bin/env bash
    set -e
    BACKUP_FILE="backup_airflow_$(date +%Y%m%d_%H%M%S).sql"
    echo "Creating backup: $BACKUP_FILE"
    {{dc_cmd}} exec -T postgres pg_dump -U airflow airflow > "$BACKUP_FILE"
    echo "Backup created: $BACKUP_FILE"

# Restore database from backup
[no-cd]
restore file:
    #!/usr/bin/env bash
    set -e
    echo "Restoring database from: {{file}}"
    {{dc_cmd}} exec -T postgres psql -U airflow -d airflow < "{{file}}"
    echo "Database restored."

# =============================================================================
# MAINTENANCE
# =============================================================================

# Clear all task logs
[no-cd]
clear-logs:
    @echo "Clearing task logs..."
    rm -rf logs/*
    @echo "Logs cleared."

# Clear DAG processing history
[no-cd]
clear-history: check-docker-compose
    @echo "Clearing DAG run history..."
    {{dc_cmd}} exec airflow-scheduler airflow dags clean --yes --no_confirm
    @echo "History cleared."

# =============================================================================
# TROUBLESHOOTING
# =============================================================================

# Check service health
[no-cd]
health: check-docker-compose
    @echo "========================================"
    @echo "Service Health Checks"
    @echo "========================================"
    @echo "PostgreSQL:"
    {{dc_cmd}} exec postgres pg_isready -U airflow || echo "PostgreSQL not healthy"
    @echo ""
    @echo "Redis:"
    {{dc_cmd}} exec redis redis-cli ping || echo "Redis not healthy"
    @echo ""
    @echo "Scheduler:"
    curl -s http://localhost:8974/health || echo "Scheduler health check failed"
    @echo ""
    @echo "API Server:"
    curl -s http://localhost:8080/api/v2/version || echo "API server not healthy"

# Show recent errors from logs
errors:
    {{dc_cmd}} logs --tail=100 2>&1 | grep -i error | tail -20

# Show connection strings (masked)
connections:
    @echo "Checking connections..."
    {{dc_cmd}} exec airflow-scheduler airflow connections get -c || true

# =============================================================================
# DOCKER COMPOSE SHORTCUTS
# =============================================================================

# Build custom image
[no-cd]
build: check-docker-compose
    {{dc_cmd}} build

# Build with no cache
[no-cd]
build-no-cache: check-docker-compose
    {{dc_cmd}} build --no-cache

# Pull latest images
[no-cd]
pull: check-docker-compose
    {{dc_cmd}} pull

# =============================================================================
# HELP
# =============================================================================

# Show this help
help:
    @echo "Airflow Deployment Management"
    @echo ""
    @echo "Usage: just <command>"
    @echo ""
    @echo "Initialization:"
    @echo "  init              Initialize the environment (run once)"
    @echo "  create-dirs       Create required directories"
    @echo "  generate-keys     Generate secure Fernet and secret keys"
    @echo "  setup-secure      Generate keys and save to .env"
    @echo ""
    @echo "Start/Stop:"
    @echo "  up                Start all services (detached)"
    @echo "  up-debug          Start in foreground (debug mode)"
    @echo "  flower-up         Start Flower dashboard"
    @echo "  down              Stop services (preserve volumes)"
    @echo "  down-vols         Stop and remove volumes"
    @echo "  clean             Complete cleanup (down, volumes, images)"
    @echo ""
    @echo "Restart:"
    @echo "  restart           Restart all services"
    @echo "  recreate          Recreate all containers"
    @echo ""
    @echo "Logs & Status:"
    @echo "  logs              Follow logs from all services"
    @echo "  log <service>     Follow logs from specific service"
    @echo "  status            Show service status and resource usage"
    @echo "  health            Check service health"
    @echo ""
    @echo "Database:"
    @echo "  migrate           Run database migrations"
    @echo "  db-status         Check database status"
    @echo "  db-reset          Reset database (WARNING: destroys data)"
    @echo "  backup            Backup database to file"
    @echo "  restore <file>    Restore database from backup"
    @echo ""
    @echo "Scaling:"
    @echo "  scale-worker <n>  Scale workers to n instances"
    @echo ""
    @echo "CLI Commands:"
    @echo "  airflow <args>    Run airflow CLI command"
    @echo "  bash              Enter bash shell in CLI container"
    @echo "  python            Enter Python shell"
    @echo "  dags-list         List all DAGs"
    @echo "  dag-unpause <id>  Unpause a DAG"
    @echo "  dag-pause <id>    Pause a DAG"
    @echo "  dag-trigger <id>  Trigger a DAG run"
    @echo ""
    @echo "Maintenance:"
    @echo "  clear-logs        Clear task logs"
    @echo "  clear-history     Clear DAG run history"
    @echo ""
    @echo "Troubleshooting:"
    @echo "  errors            Show recent errors from logs"
    @echo "  connections       Check connections"
    @echo ""
    @echo "Docker:"
    @echo "  build             Build custom image"
    @echo "  build-no-cache    Build without cache"
    @echo "  pull              Pull latest images"
    @echo ""
    @echo "  help              Show this help message"
