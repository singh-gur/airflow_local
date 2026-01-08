#!/bin/bash
# Log cleanup script for Airflow
# Removes old log files to prevent disk space issues

set -e

LOG_DIR="${LOG_DIR:-./logs}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"

echo "======================================================================"
echo "Airflow Log Cleanup"
echo "======================================================================"
echo ""
echo "Log directory: $LOG_DIR"
echo "Retention period: $RETENTION_DAYS days"
echo ""

# Check if log directory exists
if [ ! -d "$LOG_DIR" ]; then
    echo "ERROR: Log directory not found: $LOG_DIR"
    exit 1
fi

# Count files before cleanup
BEFORE_COUNT=$(find "$LOG_DIR" -type f -name "*.log" | wc -l)
BEFORE_SIZE=$(du -sh "$LOG_DIR" 2>/dev/null | cut -f1)

echo "Before cleanup:"
echo "  Files: $BEFORE_COUNT"
echo "  Size: $BEFORE_SIZE"
echo ""

# Remove old log files
echo "Removing log files older than $RETENTION_DAYS days..."
find "$LOG_DIR" -type f -name "*.log" -mtime +$RETENTION_DAYS -delete

# Remove empty directories
echo "Removing empty directories..."
find "$LOG_DIR" -type d -empty -delete

# Count files after cleanup
AFTER_COUNT=$(find "$LOG_DIR" -type f -name "*.log" | wc -l)
AFTER_SIZE=$(du -sh "$LOG_DIR" 2>/dev/null | cut -f1)
REMOVED=$((BEFORE_COUNT - AFTER_COUNT))

echo ""
echo "After cleanup:"
echo "  Files: $AFTER_COUNT"
echo "  Size: $AFTER_SIZE"
echo "  Removed: $REMOVED files"
echo ""
echo "======================================================================"
echo "Cleanup completed at $(date)"
echo "======================================================================"
