FROM python:3.13-slim-bookworm

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    AIRFLOW_HOME=/opt/airflow \
    AIRFLOW_VERSION=3.1.5 \
    PYTHON_VERSION=3.13

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    libpq-dev \
    libssl-dev \
    libffi-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create airflow user and group
RUN groupadd -r airflow && useradd -r -g airflow -d ${AIRFLOW_HOME} -s /bin/bash airflow

# Create necessary directories
RUN mkdir -p ${AIRFLOW_HOME}/dags \
    ${AIRFLOW_HOME}/logs \
    ${AIRFLOW_HOME}/plugins \
    ${AIRFLOW_HOME}/config \
    && chown -R airflow:airflow ${AIRFLOW_HOME}

# Set working directory
WORKDIR ${AIRFLOW_HOME}

# Copy requirements file
COPY requirements.txt .

# Install Apache Airflow and dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir apache-airflow==${AIRFLOW_VERSION} && \
    pip install --no-cache-dir -r requirements.txt

# Switch to airflow user
USER airflow

# Expose ports
EXPOSE 8080

# Default command
CMD ["airflow", "webserver"]
