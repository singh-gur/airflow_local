# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

# syntax=docker/dockerfile:1.4
#
# Custom Airflow Docker Image
# This Dockerfile is used to build a custom Airflow image with
# additional dependencies installed.
#
# Usage:
#   1. Update requirements.txt with your Python dependencies
#   2. Update Dockerfile if you need system dependencies
#   3. Build the image: docker compose build
#   4. Update .env to use your custom image:
#      AIRFLOW_IMAGE_NAME=airflow-custom:1.0.0
#
# For more information, see:
#   https://airflow.apache.org/docs/docker-stack/build.html
#

# Build arguments
ARG AIRFLOW_VERSION=3.1.5
ARG PYTHON_VERSION=3.13

# Base image
FROM apache/airflow:${AIRFLOW_VERSION}

# Maintainer
LABEL maintainer="Airflow Team <dev@airflow.apache.org>"

# Arguments for build
ARG AIRFLOW_VERSION
ARG PYTHON_VERSION

# Install Docker CLI for DockerOperator
# This allows Airflow to communicate with the Docker daemon
RUN apt-get update && apt-get install -y --no-install-recommends \
    docker.io \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements file
COPY requirements.txt /requirements.txt

# Install Python dependencies
# Using --no-cache-dir to reduce image size
RUN if [ -f /requirements.txt ]; then \
    pip install --no-cache-dir \
        --upgrade pip \
        -r /requirements.txt; \
    fi

# Add custom scripts
COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh

# Set working directory
WORKDIR /opt/airflow

# Default environment variables
ENV PYTHONPATH=/opt/airflow

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=5 \
    CMD curl --fail http://localhost:8974/health || exit 1

# Entrypoint (inherited from base image)
# See: https://airflow.apache.org/docs/docker-stack/entrypoint.html
