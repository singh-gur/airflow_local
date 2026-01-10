# Airflow Deployment and Management
# Usage: just <command>

# Default recipe to display help information
default:
    @just --list

# Initialize the environment - first time setup
init:
    @echo "Initializing Airflow environment..."
    @if [ ! -f .env ]; then \
        cp .env.example .env; \
        echo "Created .env file from template"; \
        echo ""; \
        echo "IMPORTANT: Please update the following in .env:"; \
        echo "  1. AIRFLOW_UID (run: echo \$$(id -u))"; \
        echo "  2. AIRFLOW_FERNET_KEY (run: python -c \"from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())\")"; \
        echo "  3. AIRFLOW_WEBSERVER_SECRET_KEY (run: python -c \"import secrets; print(secrets.token_hex(32))\")"; \
        echo "  4. AIRFLOW_ADMIN_PASSWORD (change from default 'admin')"; \
    else \
        echo ".env file already exists"; \
    fi
    @mkdir -p logs dags plugins config
    @chmod -R 777 logs dags plugins config
    @echo "Environment initialized successfully!"

# Generate Fernet key for Airflow
generate-fernet-key:
    @python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"

# Generate secret key for Airflow webserver
generate-secret-key:
    @python -c "import secrets; print(secrets.token_hex(32))"

# Build Docker images
build:
    @echo "Building Docker images..."
    docker compose build

# Start all services
up:
    @echo "Starting Airflow services..."
    docker compose up -d

# Start all services with initialization
up-init:
    @echo "Starting Airflow with initialization..."
    docker compose up -d airflow-init
    @echo "Waiting for initialization to complete..."
    @sleep 5
    docker compose up -d

# Stop all services
down:
    @echo "Stopping Airflow services..."
    docker compose down

# Stop all services and remove volumes
down-volumes:
    @echo "Stopping Airflow services and removing volumes..."
    docker compose down -v

# Restart all services
restart:
    @echo "Restarting Airflow services..."
    docker compose restart

# Restart a specific service
restart-service service:
    @echo "Restarting {{service}}..."
    docker compose restart {{service}}

# View logs for all services
logs:
    docker compose logs -f

# View logs for a specific service
logs-service service:
    docker compose logs -f {{service}}

# Execute a shell in the webserver container
shell:
    docker compose exec airflow-webserver /bin/bash

# Execute a shell in a specific service
shell-service service:
    docker compose exec {{service}} /bin/bash

# Run airflow CLI commands
airflow *args:
    docker compose exec airflow-webserver airflow {{args}}

# Upgrade the Airflow database
db-upgrade:
    docker compose exec airflow-webserver airflow db migrate

# Create a new admin user
create-user username email password:
    docker compose exec airflow-webserver airflow users create \
        --username {{username}} \
        --firstname Admin \
        --lastname User \
        --role Admin \
        --email {{email}} \
        --password {{password}}

# List all Airflow users
list-users:
    docker compose exec airflow-webserver airflow users list

# Check status of all services
status:
    docker compose ps

# View resource usage
stats:
    docker stats

# Clean up stopped containers
clean:
    @echo "Cleaning up stopped containers..."
    docker compose down
    docker system prune -f

# Full cleanup - remove everything including volumes
clean-all:
    @echo "WARNING: This will remove all containers, volumes, and data!"
    @read -p "Are you sure? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
    docker compose down -v
    docker system prune -af --volumes
    @echo "Cleanup complete!"

# Backup the PostgreSQL database
backup:
    @echo "Creating database backup..."
    @mkdir -p backups
    docker compose exec -T postgres pg_dump -U airflow airflow > backups/airflow_backup_$(date +%Y%m%d_%H%M%S).sql
    @echo "Backup created successfully!"

# Restore the PostgreSQL database from backup
restore backup_file:
    @echo "Restoring database from {{backup_file}}..."
    docker compose exec -T postgres psql -U airflow airflow < {{backup_file}}
    @echo "Database restored successfully!"

# Run tests on DAGs
test-dags:
    docker compose exec airflow-webserver python -m pytest /opt/airflow/dags --tb=short

# Validate DAGs for syntax errors
validate-dags:
    docker compose exec airflow-webserver airflow dags list

# Trigger a specific DAG
trigger-dag dag_id:
    docker compose exec airflow-webserver airflow dags trigger {{dag_id}}

# Pause a specific DAG
pause-dag dag_id:
    docker compose exec airflow-webserver airflow dags pause {{dag_id}}

# Unpause a specific DAG
unpause-dag dag_id:
    docker compose exec airflow-webserver airflow dags unpause {{dag_id}}

# Show the web UI URL
url:
    @echo "Airflow Web UI: http://localhost:8080"
    @echo "Flower (Celery Monitor): http://localhost:5555"

# Show the current version
version:
    docker compose exec airflow-webserver airflow version

# Update Airflow (rebuild and restart)
update:
    @echo "Updating Airflow..."
    docker compose build --no-cache
    docker compose down
    docker compose up -d airflow-init
    @sleep 5
    docker compose up -d
    @echo "Update complete!"

# Monitor Celery workers
monitor-workers:
    docker compose exec airflow-webserver airflow celery inspect active

# Show Celery worker stats
worker-stats:
    docker compose exec airflow-webserver airflow celery inspect stats
