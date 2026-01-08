#!/bin/bash
# Script to generate secure secrets for Airflow production deployment
# Run this script to generate all required secrets for .env file

set -e

echo "======================================================================"
echo "Airflow Production Secrets Generator"
echo "======================================================================"
echo ""
echo "This script will generate secure secrets for your Airflow deployment."
echo "Copy the output values to your .env file."
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
echo "Summary - Copy these to your .env file:"
echo "======================================================================"
echo ""
echo "# Security Keys"
echo "AIRFLOW__CORE__FERNET_KEY=${FERNET_KEY}"
echo "AIRFLOW__WEBSERVER__SECRET_KEY=${SECRET_KEY}"
echo ""
echo "# Database Credentials"
echo "POSTGRES_USER=airflow"
echo "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}"
echo "POSTGRES_DB=airflow"
echo ""
echo "# Redis Credentials"
echo "REDIS_PASSWORD=${REDIS_PASSWORD}"
echo ""
echo "# Admin User Credentials"
echo "_AIRFLOW_WWW_USER_USERNAME=admin"
echo "_AIRFLOW_WWW_USER_PASSWORD=${ADMIN_PASSWORD}"
echo "_AIRFLOW_WWW_USER_EMAIL=admin@example.com"
echo ""
echo "# Grafana Credentials (if using monitoring)"
echo "GF_SECURITY_ADMIN_USER=admin"
echo "GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}"
echo ""
echo "# System"
echo "AIRFLOW_UID=${USER_ID}"
echo ""
echo "======================================================================"
echo "IMPORTANT: Save these credentials in a secure location!"
echo "======================================================================"
echo ""
echo "For production deployments, consider using:"
echo "  - AWS Secrets Manager"
echo "  - HashiCorp Vault"
echo "  - Azure Key Vault"
echo "  - Google Secret Manager"
echo ""
