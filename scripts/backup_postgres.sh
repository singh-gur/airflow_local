#!/bin/bash
# PostgreSQL backup script for Airflow database
# Creates timestamped backups and manages retention

set -e

DOCKER_COMPOSE_FILE="${DOCKER_COMPOSE_FILE:-docker-compose.prod.yaml}"
BACKUP_DIR="${BACKUP_DIR:-./backups/postgres}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
POSTGRES_CONTAINER="postgres"

# Load environment variables from .env
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

POSTGRES_USER="${POSTGRES_USER:-airflow}"
POSTGRES_DB="${POSTGRES_DB:-airflow}"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Generate timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/airflow_backup_${TIMESTAMP}.sql.gz"

echo "======================================================================"
echo "Airflow Database Backup"
echo "======================================================================"
echo ""
echo "Starting backup at $(date)"
echo "Backup file: $BACKUP_FILE"
echo ""

# Create backup
echo "Creating database backup..."
docker compose -f "$DOCKER_COMPOSE_FILE" exec -T "$POSTGRES_CONTAINER" \
    pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --clean --if-exists | gzip > "$BACKUP_FILE"

# Check if backup was successful
if [ -f "$BACKUP_FILE" ] && [ -s "$BACKUP_FILE" ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "✓ Backup completed successfully"
    echo "  Size: $BACKUP_SIZE"
    echo "  Location: $BACKUP_FILE"
else
    echo "✗ Backup failed!"
    exit 1
fi

echo ""

# Clean up old backups
echo "Cleaning up backups older than $RETENTION_DAYS days..."
find "$BACKUP_DIR" -name "airflow_backup_*.sql.gz" -type f -mtime +$RETENTION_DAYS -delete
REMAINING_BACKUPS=$(find "$BACKUP_DIR" -name "airflow_backup_*.sql.gz" -type f | wc -l)
echo "✓ Cleanup completed"
echo "  Remaining backups: $REMAINING_BACKUPS"

echo ""
echo "======================================================================"
echo "Backup completed at $(date)"
echo "======================================================================"
