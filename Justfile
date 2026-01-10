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

[group('Setup')]
[no-cd]
init:
    @echo "Initializing Airflow database..."
    @docker compose -f {{DOCKER_COMPOSE_FILE}} up airflow-init
    @echo ""
    @echo "Database initialized!"
    @echo ""
    @echo "IMPORTANT: In Airflow 3.x, users must be created via the API."
    @echo "After starting services, create admin user with:"
    @echo "  just create-user admin admin123 admin@example.com"
    @echo ""
    @echo "Or manually via curl:"
    @echo "  curl -X POST 'http://localhost:8080/api/v1/users' \\"
    @echo "    -H 'Content-Type: application/json' \\"
    @echo "    -d '{\"username\": \"admin\", \"first_name\": \"Admin\", \"last_name\": \"User\", \"email\": \"admin@example.com\", \"password\": \"admin123\", \"role\": \"Admin\"}'"

[group('Setup')]
[no-cd]
create-user username password email:
    @echo "Creating user '{{username}}' via API..."
    @curl -s -X POST 'http://localhost:8080/api/v1/users' \
      -H 'Content-Type: application/json' \
      -d '{"username": "{{username}}", "first_name": "Admin", "last_name": "User", "email": "{{email}}", "password": "{{password}}", "role": "Admin"}' \
      || echo "Failed to create user. Make sure webserver is running."

# ============================================================================
# STARTING AND STOPPING
# ============================================================================

[group('Runtime')]
[no-cd]
up:
    @echo "Starting Airflow services..."
    @docker compose -f {{DOCKER_COMPOSE_FILE}} up -d

[group('Runtime')]
[no-cd]
up-build:
    @echo "Building images and starting Airflow services..."
    @docker compose -f {{DOCKER_COMPOSE_FILE}} up -d --build

[group('Runtime')]
[no-cd]
down:
    @echo "Stopping Airflow services..."
    @docker compose -f {{DOCKER_COMPOSE_FILE}} down

[group('Runtime')]
[no-cd]
down-vols:
    @echo "Stopping Airflow services and removing volumes..."
    @echo "WARNING: This will delete all database data!"
    @docker compose -f {{DOCKER_COMPOSE_FILE}} down --volumes

[group('Runtime')]
[no-cd]
restart:
    @echo "Restarting Airflow services..."
    @docker compose -f {{DOCKER_COMPOSE_FILE}} restart

# ============================================================================
# LOGS AND STATUS
# ============================================================================

[group('Logs')]
[no-cd]
logs:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} logs -f

[group('Logs')]
[no-cd]
logs-service service:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} logs -f {{service}}

[group('Status')]
[no-cd]
status:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} ps

# ============================================================================
# CONTAINER ACCESS
# ============================================================================

[group('Access')]
[no-cd]
bash:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} exec airflow-scheduler bash

[group('Access')]
[no-cd]
cli +args:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow {{args}}

[group('Access')]
[no-cd]
version:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow version

# ============================================================================
# WEB INTERFACES
# ============================================================================

[group('Web')]
[no-cd]
web:
    @echo "Opening Airflow Web UI at http://localhost:8089"
    @open http://localhost:8089 2>/dev/null || xdg-open http://localhost:8089 2>/dev/null || echo "Please open http://localhost:8089 manually"

# ============================================================================
# DAG MANAGEMENT
# ============================================================================

[group('DAGs')]
[no-cd]
dags-list:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow dags list

[group('DAGs')]
[no-cd]
dag-trigger dag_id:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow dags trigger {{dag_id}}

[group('DAGs')]
[no-cd]
dag-pause dag_id:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow dags pause {{dag_id}}

[group('DAGs')]
[no-cd]
dag-unpause dag_id:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow dags unpause {{dag_id}}

[group('DAGs')]
[no-cd]
dag-runs dag_id:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow dags list-runs -d {{dag_id}}

# ============================================================================
# DATABASE
# ============================================================================

[group('Database')]
[no-cd]
db-migrate:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow db migrate

[group('Database')]
[no-cd]
db-reset:
    @echo "WARNING: This will reset the database and delete all data!"
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow db reset

[group('Database')]
[no-cd]
db-status:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow db check

# ============================================================================
# CONNECTIONS AND VARIABLES
# ============================================================================

[group('Config')]
[no-cd]
connections-list:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow connections list

[group('Config')]
[no-cd]
variables-list:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} run --rm airflow-cli airflow variables list

# ============================================================================
# CLEANUP AND MAINTENANCE
# ============================================================================

[group('Cleanup')]
[no-cd]
clean:
    @echo "Cleaning up everything (containers, volumes, images)..."
    @echo "WARNING: This will delete all data and downloaded images!"
    @docker compose -f {{DOCKER_COMPOSE_FILE}} down --volumes --rmi all

[group('Cleanup')]
[no-cd]
clean-containers:
    @echo "Cleaning up containers and volumes..."
    @docker compose -f {{DOCKER_COMPOSE_FILE}} down --volumes

# ============================================================================
# BUILD AND DEVELOPMENT
# ============================================================================

[group('Build')]
[no-cd]
build:
    @echo "Building Airflow images..."
    @docker compose -f {{DOCKER_COMPOSE_FILE}} build

[group('Build')]
[no-cd]
pull:
    @echo "Pulling latest images..."
    @docker compose -f {{DOCKER_COMPOSE_FILE}} pull

# ============================================================================
# DEBUG
# ============================================================================

[group('Debug')]
[no-cd]
stats:
    @docker stats $(docker compose -f {{DOCKER_COMPOSE_FILE}} ps -q)

[group('Debug')]
[no-cd]
db-shell:
    @docker compose -f {{DOCKER_COMPOSE_FILE}} exec postgres psql -U airflow -d airflow

# ============================================================================
# PRODUCTION
# ============================================================================

[group('Production')]
[no-cd]
prod-secrets:
    @./scripts/generate_secrets.sh

[group('Production')]
[no-cd]
prod-build:
    @echo "Building production image..."
    @docker compose -f docker-compose.prod.yaml build

[group('Production')]
[no-cd]
prod-init:
    @echo "Initializing production database..."
    @docker compose -f docker-compose.prod.yaml up airflow-init

[group('Production')]
[no-cd]
prod-create-user username password email:
    @echo "Creating user '{{username}}' via API..."
    @curl -s -X POST 'http://localhost:8080/api/v1/users' \
      -H 'Content-Type: application/json' \
      -d '{"username": "{{username}}", "first_name": "Admin", "last_name": "User", "email": "{{email}}", "password": "{{password}}", "role": "Admin"}' \
      || echo "Failed to create user. Make sure webserver is running."

[group('Production')]
[no-cd]
prod-web:
    @echo "Opening Airflow Web UI at http://localhost:8080"
    @open http://localhost:8080 2>/dev/null || xdg-open http://localhost:8080 2>/dev/null || echo "Please open http://localhost:8080 manually"

[group('Production')]
[no-cd]
prod-up:
    @echo "Starting production services..."
    @docker compose -f docker-compose.prod.yaml up -d
    @echo "Production services started. Access: http://localhost:8080"

[group('Production')]
[no-cd]
prod-down:
    @docker compose -f docker-compose.prod.yaml down

[group('Production')]
[no-cd]
prod-logs:
    @docker compose -f docker-compose.prod.yaml logs -f

[group('Production')]
[no-cd]
prod-backup:
    @./scripts/backup_postgres.sh

[group('Production')]
[no-cd]
prod-scale workers="5":
    @docker compose -f docker-compose.prod.yaml up -d --scale airflow-worker={{workers}}
    @echo "Scaled to {{workers}} workers"

[group('Production')]
[no-cd]
prod-clean-all:
    #!/usr/bin/env bash
    set -euo pipefail
    echo ""
    echo "WARNING: This will delete ALL production data!"
    echo ""
    read -p "Type 'DELETE PRODUCTION' to confirm: " confirmation
    if [[ "$confirmation" != "DELETE PRODUCTION" ]]; then
        echo "Aborted."
        exit 1
    fi
    docker compose -f docker-compose.prod.yaml down --volumes --rmi all
    echo "Production cleanup complete."

# ============================================================================
# UPGRADE
# ============================================================================

[group('Upgrade')]
[no-cd]
upgrade:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "=============================================="
    echo "Airflow Upgrade Helper"
    echo "=============================================="
    echo ""
    echo "Steps to upgrade Airflow:"
    echo ""
    echo "1. Backup database:"
    echo "   just prod-backup"
    echo ""
    echo "2. Stop current services:"
    echo "   just prod-down"
    echo ""
    echo "3. Pull latest code and rebuild:"
    echo "   git pull"
    echo "   just prod-build"
    echo ""
    echo "4. Run database migrations:"
    echo "   just prod-init"
    echo ""
    echo "5. Start services:"
    echo "   just prod-up"
    echo ""
    echo "6. Verify upgrade:"
    echo "   just prod-logs"
    echo "   just version"
    echo ""
    echo "Recommended: Test in staging first!"
