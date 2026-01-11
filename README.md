# Apache Airflow 3.1.5 Deployment

Production-ready Docker Compose deployment for Apache Airflow 3.1.5 with Python 3.13.

## Features

- **CeleryExecutor** for distributed task execution
- **PostgreSQL 16** as metadata database
- **Redis 7.2** as message broker
- **All core services**: scheduler, triggerer, worker, api-server, dag-processor
- **DockerOperator support** for running containers as tasks
- **Production-ready**: health checks, restart policies, resource limits
- **Justfile** for easy deployment management

## Requirements

- Docker Engine 24.0+
- Docker Compose v2.14+
- Python 3.13+ (for local tooling)
- [Just](https://github.com/casey/just) command runner
- 4GB+ RAM available for containers

## Quick Start

```bash
# 1. Install just
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin

# 2. Copy environment file and generate secure keys
cp .env.example .env
just setup-secure

# 3. Initialize (creates dirs, DB, admin user)
just init

# 4. Start services
just up

# 5. Access: http://localhost:8080 (airflow/airflow)
```

---

## Step-by-Step Deployment Guide

This guide walks you through deploying Airflow on a fresh server or local machine.

### Step 1: Prepare the Environment

#### 1.1 Install Docker

**On Ubuntu/Debian:**
```bash
# Update package index
sudo apt-get update

# Install prerequisites
sudo apt-get install -y ca-certificates curl gnupg

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group (log out and back in after)
sudo usermod -aG docker $USER
```

**On RHEL/CentOS/Fedora:**
```bash
# Install prerequisites
sudo dnf -y install dnf-plugins-core

# Add Docker repository
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

# Install Docker
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER
```

**On macOS:**
1. Download Docker Desktop from https://www.docker.com/products/docker-desktop/
2. Install and start Docker Desktop
3. Allocate 4GB+ RAM in Docker Desktop preferences

#### 1.2 Verify Docker Installation

```bash
# Check Docker version
docker --version
# Expected: Docker version 24.0+ or later

# Check Docker Compose version
docker compose version
# Expected: Docker Compose version v2.14+ or later

# Test Docker is running
docker run hello-world
```

#### 1.3 Install Just (Command Runner)

**Linux/macOS:**
```bash
# Install just to /usr/local/bin
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin

# Verify installation
just --version
```

**macOS (via Homebrew):**
```bash
brew install just
```

**Windows (via Scoop):**
```bash
scoop install just
```

### Step 2: Clone and Prepare the Project

#### 2.1 Get the Deployment Files

```bash
# Clone or download the deployment files
git clone <repository-url> airflow-deployment
cd airflow-deployment

# Or if you have the files locally, navigate to the directory
cd /path/to/airflow-deployment
```

#### 2.2 Create Required Directories

```bash
# The just init command will create these, but you can create them manually:
mkdir -p dags logs plugins config data/postgres scripts
touch dags/.gitkeep logs/.gitkeep plugins/.gitkeep config/.gitkeep
```

### Step 3: Configure Environment Variables

#### 3.1 Copy the Environment Template

```bash
# Copy example env file
cp .env.example .env
```

#### 3.2 Generate Secure Keys

Generate secure keys for Airflow (Fernet key for encryption, webserver secret for sessions):

```bash
# Generate and display keys (copy manually if needed)
just generate-keys

# OR generate and automatically save to .env file
just setup-secure
```

This will generate:
- **AIRFLOW_FERNET_KEY** - Used for encrypting connections and variables
- **AIRFLOW_WEBSERVER_SECRET_KEY** - Used for signing session cookies

#### 3.3 Edit the Environment File

```bash
nano .env
```

Update these critical values:

```bash
# Passwords (change these!)
POSTGRES_PASSWORD=secure_password_here
REDIS_PASSWORD=secure_password_here

# Admin user (optional - create via UI instead)
AIRFLOW_CREATE_ADMIN_USER=false
AIRFLOW_ADMIN_USERNAME=admin
AIRFLOW_ADMIN_PASSWORD=secure_password_here
AIRFLOW_ADMIN_EMAIL=admin@example.com
```

**Note:** The security keys (AIRFLOW_FERNET_KEY, AIRFLOW_WEBSERVER_SECRET_KEY) are already set by `just setup-secure`.

#### 3.4 Set File Permissions (Linux)

```bash
# Set AIRFLOW_UID to your user ID
echo "AIRFLOW_UID=$(id -u)" >> .env

# Secure the .env file
chmod 600 .env
```

### Step 4: Build Custom Image (Optional)

If you need custom Python dependencies, install them before starting:

#### 4.1 Edit Requirements

```bash
nano requirements.txt
```

Add your dependencies:
```
apache-airflow-providers-amazon>=8.0.0
pandas>=2.0.0
numpy>=1.24.0
```

#### 4.2 Build the Image

```bash
# Build custom image (this takes 5-10 minutes)
just build

# Or build without cache (slower but cleaner)
just build-no-cache
```

### Step 5: Initialize the Environment

This step:
- Creates necessary directories
- Initializes the database schema
- Creates the admin user

```bash
just init
```

Expected output:
```
========================================
Airflow Initialization Started
========================================
Available Memory: XXXX MB
Available CPUs: X

Airflow Version:
X.X.X

Running database migrations...
Database migrations complete.

Creating admin user...
Admin user created.

========================================
Airflow Initialization Complete
========================================
```

### Step 6: Start Airflow Services

#### 6.1 Start in Detached Mode (Recommended)

```bash
just up
```

#### 6.2 Start in Foreground (For Debugging)

```bash
just up-debug
```

#### 6.3 Verify Services are Running

```bash
just status
```

Expected output:
```
CONTAINER ID   IMAGE                  COMMAND              STATUS         PORTS               NAMES
abc123         postgres:16            "docker-entrypoint.s"   Up 5 minutes   5432/tcp            airflow-postgres
def456         redis:7.2-bookworm     "docker-entrypoint.s"   Up 5 minutes   6379/tcp            airflow-redis
ghi789         apache/airflow:3.1.5   "/usr/bin/dumb-init"    Up 4 minutes   8080/tcp            airflow-apiserver
jkl012         apache/airflow:3.1.5   "/usr/bin/dumb-init"    Up 4 minutes   8974/tcp            airflow-scheduler
mno345         apache/airflow:3.1.5   "/usr/bin/dumb-init"    Up 4 minutes                       airflow-worker
pqr678         apache/airflow:3.1.5   "/usr/bin/dumb-init"    Up 4 minutes                       airflow-triggerer
stu901         apache/airflow:3.1.5   "/usr/bin/dumb-init"    Up 4 minutes                       airflow-dag-processor
```

### Step 7: Access the Web UI

1. Open your browser to: **http://localhost:8080**
2. Login with credentials from `.env`:
   - **Username**: `airflow` (or your custom admin username)
   - **Password**: `airflow` (or your custom admin password)

### Step 8: Verify Installation

#### 8.1 Check Service Health

```bash
just health
```

#### 8.2 View Logs

```bash
# Follow all logs
just logs

# Follow specific service
just log airflow-scheduler
```

#### 8.3 Run a Test DAG

1. In the Airflow UI, find the `example_docker_operator` DAG
2. Toggle the DAG on (unpause it)
3. Trigger the DAG manually using the "Play" button
4. Watch the task execution in the Graph or Grid view

---

## Management Commands Reference

### Start/Stop Commands

| Command | Description |
|---------|-------------|
| `just init` | Initialize environment (run once) |
| `just up` | Start all services in background |
| `just up-debug` | Start in foreground (debug mode) |
| `just down` | Stop services (preserve volumes) |
| `just down-vols` | Stop and remove volumes |
| `just restart` | Restart all services |
| `just recreate` | Recreate all containers |

### Monitoring Commands

| Command | Description |
|---------|-------------|
| `just logs` | Follow logs from all services |
| `just log <service>` | Follow logs from specific service |
| `just status` | Show service status and resource usage |
| `just health` | Check health of all services |
| `just errors` | Show recent errors from logs |

### Database Commands

| Command | Description |
|---------|-------------|
| `just migrate` | Run database migrations |
| `just db-status` | Check database status |
| `just db-reset` | Reset database (WARNING: destroys data) |
| `just backup` | Backup database to SQL file |
| `just restore <file>` | Restore database from backup |

### Scaling Commands

| Command | Description |
|---------|-------------|
| `just scale-worker n` | Scale workers to n instances |
| `just flower-up` | Start Flower monitoring dashboard |

### CLI Commands

| Command | Description |
|---------|-------------|
| `just airflow <args>` | Run airflow CLI command |
| `just bash` | Enter bash shell in CLI container |
| `just python` | Enter Python shell |
| `just dags-list` | List all DAGs |
| `just dag-unpause <id>` | Unpause a DAG |
| `just dag-trigger <id>` | Trigger a DAG run |

---

## DockerOperator Guide

This deployment supports running Docker containers as Airflow tasks.

### Basic Example

```python
from airflow import DAG
from airflow.providers.docker.operators.docker import DockerOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'airflow',
    'retries': 1,
}

with DAG(
    'docker_example',
    default_args=default_args,
    schedule_interval=timedelta(days=1),
    start_date=datetime(2024, 1, 1),
) as dag:

    run_container = DockerOperator(
        task_id='run_docker_container',
        image='alpine:latest',
        command='echo "Hello from Docker Operator!"',
        docker_url='unix://var/run/docker.sock',
        auto_remove='success',
    )
```

### Example with Environment Variables

```python
DockerOperator(
    task_id='container_with_env',
    image='python:3.13-slim',
    command='python -c "import os; print(os.environ[\"MY_VAR\"])"',
    docker_url='unix://var/run/docker.sock',
    environment={
        'MY_VAR': 'my_value',
    },
    auto_remove='success',
)
```

### Example with Volume Mounts

```python
DockerOperator(
    task_id='container_with_volume',
    image='alpine:latest',
    command='cat /data/input.txt',
    docker_url='unix://var/run/docker.sock',
    volumes=[
        '/host/path:/data:ro',  # Read-only mount
    ],
    auto_remove='success',
)
```

---

## Customization

### Adding Python Dependencies

1. Edit `requirements.txt`:
   ```bash
   nano requirements.txt
   ```

2. Rebuild the image:
   ```bash
   just build
   just restart
   ```

### Adding System Dependencies

Edit the `Dockerfile`:
```dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*
```

### Custom Configuration

Edit `config/airflow.cfg` or add environment variables to `.env`:

```bash
# Scheduler settings
AIRFLOW_SCHEDULER_DAG_DIR_LIST_INTERVAL=30
AIRFLOW_SCHEDULER_MAX_DAGRUNS_TO_CREATE_PER_LOOP=10

# Worker settings
AIRFLOW_WORKER_CONCURRENCY=16
```

### Adjusting Resources

Edit `.env` to adjust resource limits:

```bash
# Container limits
AIRFLOW_CONTAINER_CPU_LIMIT=2.0
AIRFLOW_CONTAINER_MEMORY_LIMIT=4G

# PostgreSQL limits
POSTGRES_MEMORY_LIMIT=1G
POSTGRES_CPU_LIMIT=2.0
```

---

## Production Deployment Checklist

Before deploying to production, ensure:

- [ ] Generated strong Fernet key and webserver secret
- [ ] Changed all default passwords
- [ ] Configured external PostgreSQL (optional but recommended)
- [ ] Configured external Redis (optional but recommended)
- [ ] Enabled SSL/TLS for webserver
- [ ] Set up firewall rules (only allow ports 80/443, 8080)
- [ ] Configured backup strategy
- [ ] Set up monitoring and alerting
- [ ] Reviewed security of Docker socket mounting
- [ ] Tested DAG execution with DockerOperator
- [ ] Documented custom dependencies in requirements.txt

---

## Troubleshooting

### Services Not Starting

```bash
# Check status
just status

# Check logs
just logs

# Check specific service
just log airflow-scheduler
```

### Database Connection Failed

```bash
# Check database health
just db-status

# Check database logs
just log postgres

# Reset database (WARNING: destroys all data)
just db-reset
```

### DockerOperator Fails

```bash
# Verify Docker socket is accessible
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock alpine ls /var/run/docker.sock

# Check worker has Docker socket mounted
just log airflow-worker | grep -i docker
```

### Out of Memory

```bash
# Check memory usage
just status

# Reduce worker concurrency in .env
AIRFLOW_WORKER_CONCURRENCY=8
just restart
```

### Clear Everything and Start Fresh

```bash
just clean
just init
just up
```

---

## Project Structure

```
airflow-deployment/
├── docker-compose.yml      # Main compose configuration
├── .env                    # Environment variables (DO NOT COMMIT)
├── .env.example            # Environment template
├── justfile                # Deployment commands
├── Dockerfile              # Custom image definition
├── requirements.txt        # Python dependencies
├── README.md               # This file
├── dags/                   # DAG files
│   └── example_docker_operator.py
├── logs/                   # Task and scheduler logs
├── plugins/                # Custom plugins
├── config/                 # Configuration files
│   └── airflow.cfg
└── data/                   # Data volumes
    └── postgres/
```

---

## Airflow Version Information

- **Apache Airflow**: 3.1.5
- **Python**: 3.13
- **PostgreSQL**: 16
- **Redis**: 7.2-bookworm
- **Docker Provider**: 3.5.0+

---

## Additional Resources

- [Airflow Documentation](https://airflow.apache.org/docs/apache-airflow/3.1.5/)
- [Docker Operator Documentation](https://airflow.apache.org/docs/apache-airflow-providers-docker/stable/operators.html)
- [Celery Executor](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/executor/celery.html)
- [Docker Stack Image](https://airflow.apache.org/docs/docker-stack/)
- [Just Command Runner](https://github.com/casey/just)

---

## License

Apache License 2.0 - See [Apache Airflow License](https://github.com/apache/airflow/blob/main/LICENSE)
