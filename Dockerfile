# Apache Airflow Production Dockerfile
# Build a production-ready Airflow image with all dependencies baked in

ARG AIRFLOW_VERSION=2.10.4
ARG PYTHON_VERSION=3.11

FROM apache/airflow:${AIRFLOW_VERSION}-python${PYTHON_VERSION}

# Switch to root to install system dependencies
USER root

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        # Build essentials for compiling Python packages
        build-essential \
        # Version control
        git \
        # Network utilities
        curl \
        wget \
        # SSL certificates
        ca-certificates \
        # Database clients (optional, for debugging)
        postgresql-client \
        # Cleanup
    && apt-get autoremove -yqq --purge \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Switch back to airflow user
USER airflow

# Set working directory
WORKDIR /opt/airflow

# Copy requirements file
COPY --chown=airflow:root requirements.txt .

# Upgrade pip and install Python dependencies
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r requirements.txt

# Copy DAGs, plugins, and config (optional - can be mounted as volumes instead)
# COPY --chown=airflow:root dags/ /opt/airflow/dags/
# COPY --chown=airflow:root plugins/ /opt/airflow/plugins/
# COPY --chown=airflow:root config/ /opt/airflow/config/

# Create necessary directories
RUN mkdir -p /opt/airflow/logs /opt/airflow/dags /opt/airflow/plugins /opt/airflow/config

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD airflow jobs check --job-type SchedulerJob --hostname $(hostname) || exit 1

# Set environment variables for production
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    AIRFLOW__CORE__LOAD_EXAMPLES=false \
    AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION=true

# Expose port for webserver
EXPOSE 8080

# Default command (can be overridden in docker-compose)
CMD ["webserver"]
