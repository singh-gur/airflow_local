# Apache Airflow - Local Development & Production Deployment

Complete setup for running Apache Airflow locally for development and in production, using Docker Compose with comprehensive automation.

## Quick Links

- **Local Development**: See below for quick start
- **Production Deployment**: See [PRODUCTION.md](PRODUCTION.md)

## Local Development Quick Start

### Prerequisites

- Docker Engine 20.10+ or Docker Desktop
- Docker Compose v2.14.0+
- Just (command runner) - `brew install just` (macOS) or `cargo install just`
- 4GB+ RAM available for Docker containers (8GB recommended)

### Setup in 3 Steps

```bash
# 1. Setup environment
just setup

# 2. Initialize database
just init

# 3. Start Airflow
just up
```

Access the web UI at http://localhost:8089 (login: airflow/airflow)

## Common Commands

```bash
just --list              # Show all available commands
just up                  # Start all services
just down                # Stop all services
just logs                # View logs
just bash                # Access scheduler container
just dags-list           # List all DAGs
just dag-trigger <id>    # Trigger a DAG run
```

## Production Deployment

For production deployments, see [PRODUCTION.md](PRODUCTION.md) which includes:

- Security hardening (secrets, SSL/TLS)
- Monitoring with Prometheus & Grafana
- Automated backups and disaster recovery
- High availability configuration
- Performance tuning
- CI/CD pipelines

Quick production start:

```bash
# Generate secrets
./scripts/generate_secrets.sh

# Setup .env file
cp .env.example .env
# Add generated secrets to .env

# Deploy
just -f Justfile-prod prod-build
just -f Justfile-prod prod-init
just -f Justfile-prod prod-up
```

## Directory Structure

```
.
├── dags/              # DAG files
├── logs/              # Airflow logs
├── plugins/           # Custom plugins
├── config/            # Configuration files
├── scripts/           # Utility scripts (backup, health checks)
├── monitoring/        # Prometheus & Grafana configs
├── docker-compose.yaml      # Development setup
├── docker-compose.prod.yaml # Production setup
├── Justfile                 # Development commands
└── Justfile-prod           # Production commands
```

## Resources

- [Production Deployment Guide](PRODUCTION.md)
- [Quick Start Guide](QUICKSTART.md)
- [Official Airflow Documentation](https://airflow.apache.org/docs/)
- [Docker Compose Guide](https://airflow.apache.org/docs/apache-airflow/stable/howto/docker-compose/index.html)
