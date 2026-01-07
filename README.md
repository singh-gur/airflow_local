# Apache Airflow - Local Development Setup

This repository provides a complete setup for running Apache Airflow locally using Docker Compose, with a comprehensive Justfile for common development tasks.

## Prerequisites

- Docker Engine 20.10+ or Docker Desktop
- Docker Compose v2.14.0+
- Just (command runner) - `brew install just` (macOS) or `cargo install just`
- 4GB+ RAM available for Docker containers (8GB recommended)

## Quick Start

### 1. Setup the environment

```bash
just setup
```

This creates the required directories (dags, logs, plugins, config) and the `.env` file with your user ID.

### 2. Initialize the database

```bash
just init
```

This runs the Airflow initialization service, creates the database schema, and creates an admin user (default: `airflow` / `airflow`).

### 3. Start Airflow

```bash
just up
```

All services will start in detached mode. Access the web UI at http://localhost:8080

## Available Commands

Run `just --list` to see all available recipes, or `just help` for detailed usage.

### Common Tasks

| Task | Description |
|------|-------------|
| `just setup` | Create directories and .env file |
| `just init` | Initialize database and create admin user |
| `just up` | Start all services |
| `just down` | Stop all services |
| `just restart` | Restart all services |
| `just logs` | View logs (follow mode) |
| `just status` | Check container status |
| `just bash` | Enter scheduler container |
| `just web` | Open web UI in browser |

### DAG Management

| Task | Description |
|------|-------------|
| `just dags-list` | List all DAGs |
| `just dag-trigger <id>` | Trigger a DAG run |
| `just dag-pause <id>` | Pause a DAG |
| `just dag-unpause <id>` | Unpause a DAG |

### Cleanup

| Task | Description |
|------|-------------|
| `just clean-containers` | Remove containers and volumes |
| `just clean` | Remove everything (containers, volumes, images) |

## Directory Structure

```
.
├── dags/              # DAG files go here
├── logs/              # Task and scheduler logs
├── plugins/           # Custom plugins
├── config/            # Custom configuration
├── docker-compose.yaml
├── Justfile
├── requirements.txt
└── .env
```

## Access Points

| Service | URL | Credentials |
|---------|-----|-------------|
| Airflow Web UI | http://localhost:8080 | admin / admin |
| Flower (Celery) | http://localhost:5555 | No auth |

## Default Credentials

- **Username**: airflow
- **Password**: airflow

To change these, use `just init-custom <username> <password>`

## Adding Dependencies

### Option 1: Using requirements.txt (recommended for development)

1. Edit `requirements.txt`
2. Uncomment and modify the `build` section in `docker-compose.yaml`
3. Run `just build` or `just up-build`

### Option 2: Install at runtime (slower)

Set the `_PIP_ADDITIONAL_REQUIREMENTS` environment variable:

```bash
echo "_PIP_ADDITIONAL_REQUIREMENTS=lxml==4.6.3" >> .env
just restart
```

## Custom Configuration

### airflow_local_settings.py

Create `config/airflow_local_settings.py` to customize cluster policies:

```python
from airflow.www.fab_security.manager import AUTH_DB

def cluster_policy(task_instance):
    if task_instance.task_id == 'sensitive_task':
        task_instance.queue = 'sensitive_queue'
```

### Custom Dockerfile

For production-like setups, create a `Dockerfile`:

```dockerfile
FROM apache/airflow:3.1.5
ADD requirements.txt .
RUN pip install apache-airflow==${AIRFLOW_VERSION} -r requirements.txt
```

Then uncomment the `build: .` section in `docker-compose.yaml`.

## Troubleshooting

### Containers not starting

Check logs: `just logs`

### Webserver continuously restarting

Allocate more memory to Docker (4GB minimum, 8GB recommended).

### Permission issues

Run: `sudo chmod -R 777 ./config ./dags ./logs ./plugins`

### Reset everything

```bash
just down-vols
just clean
just setup
just init
just up
```

## Resources

- [Airflow Documentation](https://airflow.apache.org/docs/)
- [Docker Compose Guide](https://airflow.apache.org/docs/apache-airflow/stable/howto/docker-compose/index.html)
- [Airflow REST API](https://airflow.apache.org/docs/apache-airflow/stable/stable-rest-api-ref.html)
