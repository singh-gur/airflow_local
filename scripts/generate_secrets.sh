#!/bin/bash
# Script to generate secure secrets for Airflow production deployment
# Run this script to generate all required secrets for .env file
#
# Usage:
#   ./scripts/generate_secrets.sh              # Display on screen
#   ./scripts/generate_secrets.sh > .env       # Save directly to .env
#   ./scripts/generate_secrets.sh --create     # Create .env file automatically

set -e

# Check if --create flag is passed
CREATE_FILE=false
if [[ "$1" == "--create" ]]; then
    CREATE_FILE=true
    if [[ -f .env ]]; then
        echo "WARNING: .env file already exists!"
        echo "Backing up to .env.backup.$(date +%Y%m%d_%H%M%S)"
        cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
    fi
fi

echo "======================================================================"
echo "Airflow Production Secrets Generator"
echo "======================================================================"
echo ""
echo "This script will generate secure secrets for your Airflow deployment."
echo ""

# Function to generate random password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Generate Fernet Key
echo "1. Generating Fernet Key (for encrypting secrets in database)..."
FERNET_KEY=$(python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())" 2>/dev/null || \
    python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())")
echo "   AIRFLOW__CORE__FERNET_KEY=${FERNET_KEY}"
echo ""

# Generate Webserver Secret Key
echo "2. Generating Webserver Secret Key (for Flask sessions)..."
SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))" 2>/dev/null || \
    python -c "import secrets; print(secrets.token_urlsafe(32))")
echo "   AIRFLOW__WEBSERVER__SECRET_KEY=${SECRET_KEY}"
echo ""

# Generate PostgreSQL password
echo "3. Generating PostgreSQL Password..."
POSTGRES_PASSWORD=$(generate_password)
echo "   POSTGRES_PASSWORD=${POSTGRES_PASSWORD}"
echo ""

# Generate Redis password
echo "4. Generating Redis Password..."
REDIS_PASSWORD=$(generate_password)
echo "   REDIS_PASSWORD=${REDIS_PASSWORD}"
echo ""

# Generate Admin password
echo "5. Generating Admin Password..."
ADMIN_PASSWORD=$(generate_password)
echo "   _AIRFLOW_WWW_USER_PASSWORD=${ADMIN_PASSWORD}"
echo ""

# Generate Grafana password
echo "6. Generating Grafana Admin Password..."
GRAFANA_PASSWORD=$(generate_password)
echo "   GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}"
echo ""

# Get user ID
echo "7. Getting User ID..."
USER_ID=$(id -u)
echo "   AIRFLOW_UID=${USER_ID}"
echo ""

echo "======================================================================"
echo "COMPLETE .env FILE - Ready to use!"
echo "======================================================================"
echo ""
echo "# ==================================================================="
echo "# Apache Airflow Production Environment - AUTO-GENERATED"
echo "# Generated on: $(date)"
echo "# ==================================================================="
echo ""
echo "# ==================== REQUIRED SETTINGS ===================="
echo ""
echo "# Security Keys (REQUIRED)"
echo "AIRFLOW__CORE__FERNET_KEY=${FERNET_KEY}"
echo "AIRFLOW__WEBSERVER__SECRET_KEY=${SECRET_KEY}"
echo ""
echo "# Database Credentials (REQUIRED)"
echo "POSTGRES_USER=airflow"
echo "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}"
echo "POSTGRES_DB=airflow"
echo ""
echo "# Redis Credentials (REQUIRED)"
echo "REDIS_PASSWORD=${REDIS_PASSWORD}"
echo ""
echo "# Admin User (REQUIRED)"
echo "_AIRFLOW_WWW_USER_USERNAME=admin"
echo "_AIRFLOW_WWW_USER_PASSWORD=${ADMIN_PASSWORD}"
echo "_AIRFLOW_WWW_USER_EMAIL=admin@example.com"
echo ""
echo "# System (REQUIRED)"
echo "AIRFLOW_UID=${USER_ID}"
echo "AIRFLOW_PROJ_DIR=."
echo ""
echo "# ==================== OPTIONAL SETTINGS ===================="
echo ""
echo "# Performance (Optional - defaults are set)"
echo "AIRFLOW__CORE__PARALLELISM=32"
echo "AIRFLOW__CORE__DAG_CONCURRENCY=16"
echo "AIRFLOW__CELERY__WORKER_CONCURRENCY=16"
echo ""
echo "# Monitoring (Optional - only if using --profile monitoring)"
echo "GF_SECURITY_ADMIN_USER=admin"
echo "GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}"
echo ""
echo "# ==================================================================="
echo ""
echo "======================================================================"
echo "QUICK SETUP INSTRUCTIONS:"
echo "======================================================================"
echo ""
echo "Save this to .env file with:"
echo "  ./scripts/generate_secrets.sh > .env"
echo ""
echo "Or copy manually:"
echo "  1. Copy everything between the lines above"
echo "  2. Paste into a new file: nano .env"
echo "  3. Save and exit (Ctrl+X, then Y, then Enter)"
echo ""
echo "Then start Airflow:"
echo "  docker compose -f docker-compose.prod.yaml up -d"
echo ""
echo "======================================================================"
echo "IMPORTANT: Keep these credentials secure!"
echo "======================================================================"
echo ""
echo "Admin Login:"
echo "  URL: http://localhost:8080"
echo "  Username: admin"
echo "  Password: ${ADMIN_PASSWORD}"
echo ""
echo "For production, use external secrets management:"
echo "  - AWS Secrets Manager"
echo "  - HashiCorp Vault"
echo "  - Azure Key Vault"
echo "  - Google Secret Manager"
echo ""

# If --create flag was used, save to .env file
if [[ "$CREATE_FILE" == "true" ]]; then
    ENV_FILE=".env"
    
    cat > "$ENV_FILE" << ENV_CONTENT
# ===================================================================
# Apache Airflow Production Environment - AUTO-GENERATED
# Generated on: $(date)
# ===================================================================

# ==================== REQUIRED SETTINGS ====================

# Security Keys (REQUIRED)
AIRFLOW__CORE__FERNET_KEY=${FERNET_KEY}
AIRFLOW__WEBSERVER__SECRET_KEY=${SECRET_KEY}

# Database Credentials (REQUIRED)
POSTGRES_USER=airflow
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_DB=airflow

# Redis Credentials (REQUIRED)
REDIS_PASSWORD=${REDIS_PASSWORD}

# Admin User (REQUIRED)
_AIRFLOW_WWW_USER_USERNAME=admin
_AIRFLOW_WWW_USER_PASSWORD=${ADMIN_PASSWORD}
_AIRFLOW_WWW_USER_EMAIL=admin@example.com

# System (REQUIRED)
AIRFLOW_UID=${USER_ID}
AIRFLOW_PROJ_DIR=.

# ==================== OPTIONAL SETTINGS ====================

# Performance (Optional - defaults are set)
AIRFLOW__CORE__PARALLELISM=32
AIRFLOW__CORE__DAG_CONCURRENCY=16
AIRFLOW__CELERY__WORKER_CONCURRENCY=16

# Monitoring (Optional - only if using --profile monitoring)
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}

# ===================================================================
ENV_CONTENT

    echo ""
    echo "✅ SUCCESS! .env file created at: $(pwd)/.env"
    echo ""
    echo "Admin credentials:"
    echo "  Username: admin"
    echo "  Password: ${ADMIN_PASSWORD}"
    echo ""
    echo "Next steps:"
    echo "  1. Review the .env file: cat .env"
    echo "  2. Start Airflow: docker compose -f docker-compose.prod.yaml up -d"
    echo ""
fi
