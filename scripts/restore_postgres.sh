#!/bin/bash
# PostgreSQL restore script for Airflow database
# Restores from a backup file

set -e

DOCKER_COMPOSE_FILE="${DOCKER_COMPOSE_FILE:-docker-compose.prod.yaml}"
BACKUP_DIR="${BACKUP_DIR:-./backups/postgres}"
POSTGRES_CONTAINER="postgres"

# Check if backup file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <backup_file>"
    echo ""
    echo "Available backups:"
    ls -lh "$BACKUP_DIR"/airflow_backup_*.sql.gz 2>/dev/null || echo "No backups found"
    exit 1
fi

BACKUP_FILE="$1"

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo "ERROR: Backup file not found: $BACKUP_FILE"
    exit 1
fi

# Load environment variables from .env
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

POSTGRES_USER="${POSTGRES_USER:-airflow}"
POSTGRES_DB="${POSTGRES_DB:-airflow}"

echo "======================================================================"
echo "Airflow Database Restore"
echo "======================================================================"
echo ""
echo "WARNING: This will restore the database from backup."
echo "All current data will be replaced!"
echo ""
echo "Backup file: $BACKUP_FILE"
echo "Database: $POSTGRES_DB"
echo ""

# Confirm restore
read -p "Are you sure you want to continue? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Restore cancelled"
    exit 0
fi

echo ""
echo "Starting restore at $(date)"
echo ""

# Stop Airflow services
echo "Stopping Airflow services..."
docker compose -f "$DOCKER_COMPOSE_FILE" stop airflow-webserver airflow-scheduler airflow-worker airflow-triggerer

echo "Restoring database..."
gunzip -c "$BACKUP_FILE" | docker compose -f "$DOCKER_COMPOSE_FILE" exec -T "$POSTGRES_CONTAINER" \
    psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"

echo "✓ Database restored successfully"
echo ""

# Start Airflow services
echo "Starting Airflow services..."
docker compose -f "$DOCKER_COMPOSE_FILE" start airflow-webserver airflow-scheduler airflow-worker airflow-triggerer

echo ""
echo "======================================================================"
echo "Restore completed at $(date)"
echo "======================================================================"
echo ""
echo "Please verify that the Airflow UI is accessible and functioning correctly."
