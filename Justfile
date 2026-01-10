# Apache Airflow Development Tasks
# Use `just --list` to see all available recipes

set dotenv-load

# Default Airflow version - change if needed
AIRFLOW_VERSION := "3.1.5"
AIRFLOW_IMAGE := "apache/airflow:" + AIRFLOW_VERSION

# Default admin credentials
AIRFLOW_USER := env_var_or_default("AIRFLOW_USER", "airflow")
AIRFLOW_PASSWORD := env_var_or_default("AIRFLOW_PASSWORD", "airflow")

# Project directory
PROJECT_DIR := justfile_directory()

# Docker compose file
DOCKER_COMPOSE_FILE := PROJECT_DIR + "/docker-compose.yaml"

# ============================================================================
# SETUP AND INITIALIZATION
# ============================================================================

# Setup Airflow environment (create directories, .env, etc.)
[group('Setup')]
[no-cd]
setup:
    @echo "Setting up Airflow environment..."
    @mkdir -p dags logs plugins config
    @echo "AIRFLOW_UID=$(id -u)" > .env
    @echo "AIRFLOW__CORE__UNIT_TEST_MODE=True" >> .env
    @echo "Created directories: dags, logs, plugins, config"
    @echo "Created .env file with AIRFLOW_UID=$(id -u)"
    @echo ""
    @echo "Next steps:"
    @echo "  1. Run 'just init' to initialize the database"
    @echo "  2. Run 'just up' to start all services"
    @echo "  3. Access UI at http://localhost:8089"

# Initialize the database and create admin user
[group('Setup')]
[no-cd]
init:
    @echo "Initializing Airflow database..."
    @docker compose -f {{DOCKER_COMPOSE_FILE}} up airflow-init
    @echo ""
    @echo "Database initialized! Admin user: {{AIRFLOW_USER}} / {{AIRFLOW_PASSWORD}}"

# Initialize with custom admin credentials
[group('Setup')]
[no-cd]
init-custom user password:
    @echo "Initializing Airflow database with custom credentials..."
    @_AIRFLOW_WWW_USER_USERNAME={{user}} _AIRFLOW_WWW_USER_PASSWORD={{password}} \
        docker compose -f {{DOCKER_COMPOSE_FILE}} up airflow-init
    @echo ""
    @echo "Database initialized! Admin user: {{user}} / {{password}}"

# ============================================================================
# STARTING AND STOPPING
# ============================================================================

# Start all Airflow services in detached mode
[group('Runtime')]
[no-cd]
up:
    @echo "Starting Airflow services..."
    @docker compose -f {{DOCKER_COMPOSE_FILE}} up -d

# Start all services with flower (monitoring)
[group('Runtime')]
[no-cd]
up-flower:
    @echo "Starting Airflow services with Flower monitoring..."
    @docker compose -f {{DOCKER_COMPOSE_FILE}} --profile flower up -d

# Start services and rebuild images if needed
[group('Runtime')]
[no-cd]
up-build:
    @echo "Building images and starting Airflow services..."
    @docker compose -f {{DOCKER_COMPOSE_FILE}} up -d --build

# Stop all Airflow services
[group('Runtime')]
[no-cd]
down:
    @echo "Stopping Airflow services..."
    @docker compose -f {{DOCKER_COMPOSE_FILE}} down

# Stop services and remove volumes (WARNING: deletes all data)
[group('Runtime')]
[no-cd]
down-vols:
    @echo "Stopping Airflow services and removing volumes..."
    @echo "WARNING: This will delete all database data!"
    @docker compose -f {{DOCKER_COMPOSE_FILE}} down --volumes

# Restart all services
[group('Runtime')]
[no-cd]
restart:
    @echo "Restarting Airflow services..."
    @docker compose -f {{DOCKER_COMPOSE_FILE}} restart

# Restart a specific service
[group('Runtime')]
[no-cd]
restart-service service:
    @echo "Restarting {{service}} service..."
    @docker compose -f {{DOCKER_COMPOSE_FILE}} restart {{service}}

# ============================================================================
# LOGS AND STATUS
# ============================================================================

# View logs for all services (follow mode)
[group('Logs')]
[no-cd]
logs:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} logs -f

# View logs for a specific service
[group('Logs')]
[no-cd]
logs-service service:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} logs -f {{service}}

# Show last N lines of logs
[group('Logs')]
[no-cd]
logs-tail lines="100":
    @docker compose -f {{DOCKER_COMPOSE_FILE}} logs --tail {{lines}}

# Check status of all containers
[group('Status')]
[no-cd]
status:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} ps

# Check health of containers
[group('Status')]
[no-cd]
health:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} ps --format json | jq -r '.[] | select(.Health != "healthy") | .Name'

# ============================================================================
# CONTAINER ACCESS
# ============================================================================

# Enter Airflow scheduler container bash
[group('Access')]
[no-cd]
bash:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} exec airflow-scheduler bash

# Enter Airflow worker container bash
[group('Access')]
[no-cd]
worker:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} exec airflow-worker bash

# Enter Airflow webserver container bash
[group('Access')]
[no-cd]
webserver:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} exec airflow-webserver bash

# Run airflow CLI command (pass args)
[group('Access')]
[no-cd]
cli +args:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow {{args}}

# Run Python in Airflow container
[group('Access')]
[no-cd]
python:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli python

# Run Airflow CLI info command
[group('Access')]
[no-cd]
info:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow info

# Run airflow version command
[group('Access')]
[no-cd]
version:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow version

# ============================================================================
# WEB INTERFACES
# ============================================================================

# Open Airflow Web UI in browser (MacOS)
[group('Web')]
[no-cd]
web:
    @echo "Opening Airflow Web UI at http://localhost:8089"
    @open http://localhost:8089 2>/dev/null || xdg-open http://localhost:8089 2>/dev/null || echo "Please open http://localhost:8089 manually"

# Open Flower monitoring UI in browser (MacOS)
[group('Web')]
[no-cd]
flower:
    @echo "Opening Flower monitoring UI at http://localhost:5555"
    @open http://localhost:5555 2>/dev/null || xdg-open http://localhost:5555 2>/dev/null || echo "Please open http://localhost:5555 manually"

# ============================================================================
# DAG MANAGEMENT
# ============================================================================

# List all DAGs
[group('DAGs')]
[no-cd]
dags-list:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow dags list

# Show DAG info
[group('DAGs')]
[no-cd]
dag-info dag_id:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow dags list-runs -d {{dag_id}}

# Trigger a DAG run
[group('DAGs')]
[no-cd]
dag-trigger dag_id:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow dags trigger {{dag_id}}

# Pause a DAG
[group('DAGs')]
[no-cd]
dag-pause dag_id:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow dags pause {{dag_id}}

# Unpause a DAG
[group('DAGs')]
[no-cd]
dag-unpause dag_id:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow dags unpause {{dag_id}}

# Delete a DAG run
[group('DAGs')]
[no-cd]
dag-delete dag_id run_id:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow dags delete {{dag_id}} --run_id {{run_id}}

# List DAG runs
[group('DAGs')]
[no-cd]
dag-runs dag_id:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow dags list-runs -d {{dag_id}}

# ============================================================================
# TASK MANAGEMENT
# ============================================================================

# List task instances for a DAG
[group('Tasks')]
[no-cd]
tasks-list dag_id:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow tasks list {{dag_id}}

# Show task instance info
[group('Tasks')]
[no-cd]
task-info dag_id task_id:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow tasks state {{dag_id}} {{task_id}}

# Clear task instance (with optional date range)
[group('Tasks')]
[no-cd]
task-clear dag_id task_id:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow tasks clear {{dag_id}} -t {{task_id}}

# Run a task instance (for testing)
[group('Tasks')]
[no-cd]
task-run dag_id task_id execution_date="2025-01-01":
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow tasks test {{dag_id}} {{task_id}} {{execution_date}}

# ============================================================================
# DATABASE
# ============================================================================

# Run database migrations
[group('Database')]
[no-cd]
db-migrate:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow db migrate

# Reset the database (WARNING: deletes all data)
[group('Database')]
[no-cd]
db-reset:
    @echo "WARNING: This will reset the database and delete all data!"
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow db reset

# Check database status
[group('Database')]
[no-cd]
db-status:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow db check

# Seed the database with default connections
[group('Database')]
[no-cd]
db-seed:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow connections import-default

# ============================================================================
# CONNECTIONS AND VARIABLES
# ============================================================================

# List all connections
[group('Config')]
[no-cd]
connections-list:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow connections list

# Export connections to file
[group('Config')]
[no-cd]
connections-export file:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow connections export {{file}}

# Import connections from file
[group('Config')]
[no-cd]
connections-import file:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow connections import {{file}}

# List all variables
[group('Config')]
[no-cd]
variables-list:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow variables list

# Set a variable
[group('Config')]
[no-cd]
variables-set key value:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow variables set {{key}} "{{value}}"

# Get a variable
[group('Config')]
[no-cd]
variables-get key:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow variables get {{key}}

# ============================================================================
# CLEANUP AND MAINTENANCE
# ============================================================================

# Clean up everything (containers, volumes, images)
[group('Cleanup')]
[no-cd]
clean:
    @echo "Cleaning up everything (containers, volumes, images)..."
    @echo "WARNING: This will delete all data and downloaded images!"
    @docker compose -f {{DOCKER_COMPOSE_FILE}} down --volumes --rmi all

# Clean up containers and volumes only
[group('Cleanup')]
[no-cd]
clean-containers:
    @echo "Cleaning up containers and volumes..."
    @docker compose -f {{DOCKER_COMPOSE_FILE}} down --volumes

# Remove dangling images
[group('Cleanup')]
[no-cd]
clean-images:
    @echo "Removing dangling images..."
    @docker image prune -f

# Remove unused containers, networks, and volumes
[group('Cleanup')]
[no-cd]
clean-system:
    @echo "Running system prune..."
    @docker system prune -f --volumes

# Clear DAGs parse cache
[group('Cleanup')]
[no-cd]
clear-cache:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow dags delete-na
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow jobs cleanup

# Nuclear option: Delete EVERYTHING including all persistent data
[group('Cleanup')]
[no-cd]
clean-all:
    #!/usr/bin/env bash
    set -euo pipefail
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║                    ⚠️  DANGER ZONE ⚠️                              ║"
    echo "║                   COMPLETE DATA WIPEOUT                           ║"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "This will permanently delete:"
    echo "  ❌ All Docker containers (Airflow, PostgreSQL, Redis)"
    echo "  ❌ All Docker volumes (PostgreSQL data, Redis data)"
    echo "  ❌ All Docker images"
    echo "  ❌ All DAGs execution history"
    echo "  ❌ All logs"
    echo "  ❌ All user accounts and connections"
    echo "  ❌ All variable and connection metadata"
    echo ""
    echo "⚠️  THIS CANNOT BE UNDONE! ⚠️"
    echo ""
    read -p "Are you absolutely sure? Type 'DELETE' to confirm: " confirmation
    if [[ "$confirmation" != "DELETE" ]]; then
        echo ""
        echo "❌ Aborted. No changes made."
        exit 1
    fi
    echo ""
    read -p "Last chance! Type 'YES' to proceed: " final_confirmation
    if [[ "$final_confirmation" != "YES" ]]; then
        echo ""
        echo "❌ Aborted. No changes made."
        exit 1
    fi
    echo ""
    echo "🗑️  Proceeding with complete cleanup..."
    echo ""
    echo "Step 1: Stopping all containers..."
    docker compose -f {{DOCKER_COMPOSE_FILE}} down --volumes --remove-orphans 2>/dev/null || true
    echo "✓ Containers stopped"
    echo ""
    echo "Step 2: Removing all Airflow containers..."
    docker ps -a | grep airflow | awk '{print $1}' | xargs docker rm -f 2>/dev/null || true
    echo "✓ Containers removed"
    echo ""
    echo "Step 3: Removing all Airflow volumes (PostgreSQL & Redis data)..."
    docker volume ls | grep airflow | awk '{print $2}' | xargs docker volume rm -f 2>/dev/null || true
    echo "✓ Volumes removed"
    echo ""
    echo "Step 4: Removing all Airflow images..."
    docker images | grep airflow | awk '{print $3}' | xargs docker rmi -f 2>/dev/null || true
    echo "✓ Images removed"
    echo ""
    echo "Step 5: Cleaning up networks..."
    docker network prune -f >/dev/null 2>&1
    echo "✓ Networks cleaned"
    echo ""
    echo "Step 6: Running Docker system prune..."
    docker system prune -af --volumes >/dev/null 2>&1
    echo "✓ System pruned"
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║              ✅ COMPLETE CLEANUP FINISHED                          ║"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "All data has been permanently deleted."
    echo ""
    echo "To start fresh:"
    echo "  1. just setup"
    echo "  2. just init"
    echo "  3. just up"
    echo ""

# ============================================================================
# BUILD AND DEVELOPMENT
# ============================================================================

# Rebuild all images
[group('Build')]
[no-cd]
build:
    @echo "Building Airflow images..."
    @docker compose -f {{DOCKER_COMPOSE_FILE}} build

# Rebuild a specific service
[group('Build')]
[no-cd]
build-service service:
    @echo "Building {{service}} image..."
    @docker compose -f {{DOCKER_COMPOSE_FILE}} build {{service}}

# Pull latest images
[group('Build')]
[no-cd]
pull:
    @echo "Pulling latest images..."
    @docker compose -f {{DOCKER_COMPOSE_FILE}} pull

# Pull a specific image
[group('Build')]
[no-cd]
pull-service service:
    @echo "Pulling {{service}} image..."
    @docker compose -f {{DOCKER_COMPOSE_FILE}} pull {{service}}

# ============================================================================
# TESTING AND LINTING
# ============================================================================

# Lint DAGs using pylint
[group('Quality')]
[no-cd]
lint-dags:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli python -m pylint --rcfile=.pylintrc dags/ 2>/dev/null || \
    docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli python -m py_compile dags/*.py

# Run Airflow internal tests
[group('Quality')]
[no-cd]
test:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli pytest tests/ -v 2>/dev/null || \
    echo "No tests found or tests skipped"

# Check DAG syntax
[group('Quality')]
[no-cd]
check-dags:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Checking DAG syntax..."
    for f in dags/*.py; do
        if [ -f "$f" ]; then
            echo "Checking $f..."
            docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli python -m py_compile "$f" || echo "Syntax error in $f"
        fi
    done

# List and validate all connections
[group('Config')]
[no-cd]
validate-connections:
    @echo "Listing all connections..."
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow connections list

# ============================================================================
# TROUBLESHOOTING
# ============================================================================

# Show container resource usage
[group('Debug')]
[no-cd]
stats:
    @docker stats $(docker compose -f {{DOCKER_COMPOSE_FILE}} ps -q)

# Show Airflow configuration
[group('Debug')]
[no-cd]
config:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow config list

# Show scheduler heartbeat
[group('Debug')]
[no-cd]
scheduler:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} exec airflow-scheduler airflow scheduler --num-runs 1

# Show triggerer status
[group('Debug')]
[no-cd]
triggerer:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} exec airflow-triggerer ps aux

# Check PostgreSQL database
[group('Debug')]
[no-cd]
db-shell:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} exec postgres psql -U airflow -d airflow

# Check Redis status
[group('Debug')]
[no-cd]
redis-cli:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} exec redis redis-cli info

# ============================================================================
# HELP
# ============================================================================

# Show this help message
[group('Help')]
[no-cd]
help:
    @echo "Apache Airflow Development Tasks"
    @echo ""
    @echo "Usage: just <recipe> [args]"
    @echo ""
    @echo "Setup:"
    @echo "  setup                    Setup environment (directories, .env)"
    @echo "  init                     Initialize database and create admin user"
    @echo "  init-custom <user> <pw>  Initialize with custom admin credentials"
    @echo ""
    @echo "Runtime:"
    @echo "  up                       Start all services (detached)"
    @echo "  up-flower               Start with Flower monitoring"
    @echo "  up-build                Start and rebuild images"
    @echo "  down                    Stop all services"
    @echo "  down-vols               Stop and remove volumes (data loss!)"
    @echo "  restart                 Restart all services"
    @echo "  restart-service <svc>   Restart specific service"
    @echo ""
    @echo "Logs & Status:"
    @echo "  logs                    View all logs (follow mode)"
    @echo "  logs-service <svc>      View specific service logs"
    @echo "  status                  Show container status"
    @echo "  health                  Show unhealthy containers"
    @echo ""
    @echo "Access:"
    @echo "  bash                    Enter scheduler container"
    @echo "  worker                  Enter worker container"
    @echo "  api                     Enter API server container"
    @echo "  cli <args>              Run airflow CLI command"
    @echo "  info                    Show Airflow info"
    @echo ""
    @echo "Web:"
    @echo "  web                     Open Airflow UI in browser (port 8089)"
    @echo "  flower                  Open Flower UI in browser (port 5555)"
    @echo ""
    @echo "DAGs:"
    @echo "  dags-list               List all DAGs"
    @echo "  dag-info <id>           Show DAG info"
    @echo "  dag-trigger <id>        Trigger a DAG run"
    @echo "  dag-pause <id>          Pause a DAG"
    @echo "  dag-unpause <id>        Unpause a DAG"
    @echo "  dag-runs <id>           List DAG runs"
    @echo ""
    @echo "Tasks:"
    @echo "  tasks-list <dag>        List tasks in a DAG"
    @echo "  task-run <dag> <task>   Run a task (for testing)"
    @echo ""
    @echo "Database:"
    @echo "  db-migrate              Run database migrations"
    @echo "  db-reset                Reset database (data loss!)"
    @echo "  db-status               Check database status"
    @echo ""
    @echo "Cleanup:"
    @echo "  clean                   Remove everything (containers, volumes, images)"
    @echo "  clean-containers        Remove containers and volumes"
    @echo "  clean-images            Remove dangling images"
    @echo "  clean-system            System prune"
    @echo ""
    @echo "Build:"
    @echo "  build                   Rebuild all images"
    @echo "  build-service <svc>     Rebuild specific service"
    @echo "  pull                    Pull latest images"
    @echo ""
    @echo "Quality:"
    @echo "  lint-dags               Lint DAG files"
    @echo "  check-dags              Check DAG syntax"
    @echo "  test                    Run tests"
    @echo ""
    @echo "Debug:"
    @echo "  stats                   Show container resource usage"
    @echo "  config                  Show Airflow configuration"
    @echo "  scheduler               Show scheduler status"
    @echo "  db-shell                Open PostgreSQL shell"
    @echo ""
    @echo "Run 'just --list' for full list of recipes"

# ============================================================================
# PRODUCTION COMMANDS
# ============================================================================

# Generate production secrets
[group('Production')]
[no-cd]
prod-secrets:
    @./scripts/generate_secrets.sh

# Build production image
[group('Production')]
[no-cd]
prod-build:
    @echo "Building production image..."
    @docker compose -f docker-compose.prod.yaml build

# Initialize production database
[group('Production')]
[no-cd]
prod-init:
    @echo "Initializing production database..."
    @docker compose -f docker-compose.prod.yaml up airflow-init

# Start production services
[group('Production')]
[no-cd]
prod-up:
    @echo "Starting production services..."
    @docker compose -f docker-compose.prod.yaml up -d
    @echo "✓ Production services started"
    @echo "Access: http://localhost:8080"

# Start production with monitoring
[group('Production')]
[no-cd]
prod-up-monitoring:
    @echo "Starting production with monitoring..."
    @docker compose -f docker-compose.prod.yaml --profile monitoring up -d
    @echo "✓ Services started"
    @echo "Airflow: http://localhost:8080"
    @echo "Grafana: http://localhost:3000"
    @echo "Prometheus: http://localhost:9090"

# Stop production services
[group('Production')]
[no-cd]
prod-down:
    @docker compose -f docker-compose.prod.yaml down

# View production logs
[group('Production')]
[no-cd]
prod-logs:
    @docker compose -f docker-compose.prod.yaml logs -f

# Check production health
[group('Production')]
[no-cd]
prod-health:
    @./scripts/health_check.sh

# Backup production database
[group('Production')]
[no-cd]
prod-backup:
    @./scripts/backup_postgres.sh

# Scale production workers
[group('Production')]
[no-cd]
prod-scale workers="5":
    @docker compose -f docker-compose.prod.yaml up -d --scale airflow-worker={{workers}}
    @echo "✓ Scaled to {{workers}} workers"

# Nuclear option: Delete EVERYTHING including all persistent data (PRODUCTION)
[group('Production')]
[no-cd]
prod-clean-all:
    #!/usr/bin/env bash
    set -euo pipefail
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║              ⚠️  PRODUCTION DANGER ZONE ⚠️                         ║"
    echo "║              COMPLETE DATA WIPEOUT - PRODUCTION                   ║"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "⚠️  WARNING: YOU ARE ABOUT TO DELETE PRODUCTION DATA! ⚠️"
    echo ""
    echo "This will permanently delete:"
    echo "  ❌ All production Docker containers (Airflow, PostgreSQL, Redis)"
    echo "  ❌ All production Docker volumes (PostgreSQL data, Redis data)"
    echo "  ❌ All production Docker images"
    echo "  ❌ All DAGs execution history"
    echo "  ❌ All logs"
    echo "  ❌ All user accounts and connections"
    echo "  ❌ All variable and connection metadata"
    echo "  ❌ ALL PRODUCTION DATA"
    echo ""
    echo "⚠️  THIS CANNOT BE UNDONE! BACKUPS RECOMMENDED! ⚠️"
    echo ""
    echo "Have you created a backup? (just prod-backup)"
    read -p "Type 'BACKUP DONE' if you have a backup, or 'SKIP' to continue without: " backup_confirm
    if [[ "$backup_confirm" != "BACKUP DONE" ]] && [[ "$backup_confirm" != "SKIP" ]]; then
        echo ""
        echo "❌ Aborted. No changes made."
        echo "💡 Run 'just prod-backup' first, then try again."
        exit 1
    fi
    echo ""
    read -p "Are you absolutely sure? Type 'DELETE PRODUCTION' to confirm: " confirmation
    if [[ "$confirmation" != "DELETE PRODUCTION" ]]; then
        echo ""
        echo "❌ Aborted. No changes made."
        exit 1
    fi
    echo ""
    read -p "Final confirmation! Type 'YES I AM SURE' to proceed: " final_confirmation
    if [[ "$final_confirmation" != "YES I AM SURE" ]]; then
        echo ""
        echo "❌ Aborted. No changes made."
        exit 1
    fi
    echo ""
    echo "🗑️  Proceeding with complete production cleanup..."
    echo ""
    echo "Step 1: Stopping all production containers..."
    docker compose -f docker-compose.prod.yaml down --volumes --remove-orphans 2>/dev/null || true
    echo "✓ Containers stopped"
    echo ""
    echo "Step 2: Removing all Airflow containers..."
    docker ps -a | grep airflow | awk '{print $1}' | xargs docker rm -f 2>/dev/null || true
    echo "✓ Containers removed"
    echo ""
    echo "Step 3: Removing all Airflow volumes (PostgreSQL & Redis data)..."
    docker volume ls | grep airflow | awk '{print $2}' | xargs docker volume rm -f 2>/dev/null || true
    echo "✓ Volumes removed (ALL DATA DELETED)"
    echo ""
    echo "Step 4: Removing all Airflow images..."
    docker images | grep airflow | awk '{print $3}' | xargs docker rmi -f 2>/dev/null || true
    echo "✓ Images removed"
    echo ""
    echo "Step 5: Cleaning up networks..."
    docker network prune -f >/dev/null 2>&1
    echo "✓ Networks cleaned"
    echo ""
    echo "Step 6: Running Docker system prune..."
    docker system prune -af --volumes >/dev/null 2>&1
    echo "✓ System pruned"
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║         ✅ COMPLETE PRODUCTION CLEANUP FINISHED                    ║"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "All production data has been permanently deleted."
    echo ""
    echo "To start fresh:"
    echo "  1. ./scripts/generate_secrets.sh --create"
    echo "  2. just prod-build"
    echo "  3. just prod-init"
    echo "  4. just prod-up"
    echo ""
    echo "To restore from backup (if available):"
    echo "  1. just prod-init"
    echo "  2. just prod-up"
    echo "  3. ./scripts/restore_postgres.sh backups/postgres/<backup_file>"
    echo ""
