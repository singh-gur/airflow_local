#!/bin/bash
# Health check script for Airflow services
# Returns 0 if all critical services are healthy, 1 otherwise

set -e

DOCKER_COMPOSE_FILE="${DOCKER_COMPOSE_FILE:-docker-compose.prod.yaml}"
CRITICAL_SERVICES=("postgres" "redis" "airflow-webserver" "airflow-scheduler" "airflow-worker")

echo "======================================================================"
echo "Airflow Health Check"
echo "======================================================================"
echo ""

ALL_HEALTHY=true

# Check if docker-compose is running
if ! docker compose -f "$DOCKER_COMPOSE_FILE" ps &>/dev/null; then
    echo "ERROR: Docker Compose is not running or cannot be accessed"
    exit 1
fi

# Check each critical service
for service in "${CRITICAL_SERVICES[@]}"; do
    echo -n "Checking $service... "
    
    # Get service status
    status=$(docker compose -f "$DOCKER_COMPOSE_FILE" ps "$service" --format json 2>/dev/null | jq -r '.[0].Health // .[0].State' 2>/dev/null || echo "unknown")
    
    if [[ "$status" == "healthy" ]] || [[ "$status" == "running" ]]; then
        echo "✓ HEALTHY"
    else
        echo "✗ UNHEALTHY (status: $status)"
        ALL_HEALTHY=false
    fi
done

echo ""

# Check Airflow API
echo -n "Checking Airflow API... "
if curl -s -f http://localhost:8080/health &>/dev/null; then
    echo "✓ RESPONDING"
else
    echo "✗ NOT RESPONDING"
    ALL_HEALTHY=false
fi

echo ""

# Summary
if $ALL_HEALTHY; then
    echo "======================================================================"
    echo "All services are HEALTHY ✓"
    echo "======================================================================"
    exit 0
else
    echo "======================================================================"
    echo "Some services are UNHEALTHY ✗"
    echo "======================================================================"
    exit 1
fi
