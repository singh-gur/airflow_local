# Apache Airflow 3.1.5 Docker Deployment

Production-ready Apache Airflow deployment using Docker Compose with Python 3.13 and CeleryExecutor.

## Features

- Apache Airflow 3.1.5
- Python 3.13
- CeleryExecutor for distributed task execution
- PostgreSQL 16 for metadata database
- Redis 7 for Celery message broker
- Flower for Celery monitoring
- Persistent volumes for data
- Health checks for all services
- Easy management with justfile commands

## Architecture

The deployment includes the following services:

- **airflow-webserver**: Web UI (port 8080)
- **airflow-scheduler**: DAG scheduling
- **airflow-worker**: Celery worker for task execution
- **airflow-triggerer**: For deferrable operators
- **flower**: Celery monitoring UI (port 5555)
- **postgres**: Metadata database (port 5432)
- **redis**: Message broker (port 6379)

## Prerequisites

- Docker (20.10+)
- Docker Compose (2.0+)
- just command runner (optional but recommended)

### Installing just

```bash
# On macOS
brew install just

# On Linux
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin

# On other systems, see: https://github.com/casey/just#installation
```

## Quick Start

### 1. Initialize Environment

```bash
just init
```

This will:
- Create a `.env` file from `.env.example`
- Create necessary directories
- Display instructions for required configuration

### 2. Configure Environment

Edit the `.env` file and update:

```bash
# Set your user ID (Linux/macOS)
AIRFLOW_UID=$(id -u)

# Generate Fernet key
just generate-fernet-key
# Copy output to AIRFLOW_FERNET_KEY in .env

# Generate secret key
just generate-secret-key
# Copy output to AIRFLOW_WEBSERVER_SECRET_KEY in .env

# Update admin credentials
AIRFLOW_ADMIN_USERNAME=your_username
AIRFLOW_ADMIN_PASSWORD=your_secure_password
```

### 3. Build and Start

```bash
# Build Docker images
just build

# Start all services with initialization
just up-init
```

### 4. Access Airflow

- Web UI: http://localhost:8080
- Flower (Celery Monitor): http://localhost:5555
- Default credentials: admin/admin (change this!)

## Common Commands

### Service Management

```bash
# Start all services
just up

# Stop all services
just down

# Restart all services
just restart

# Restart specific service
just restart-service airflow-scheduler

# Check service status
just status

# View resource usage
just stats
```

### Logs and Monitoring

```bash
# View all logs
just logs

# View logs for specific service
just logs-service airflow-webserver

# Monitor Celery workers
just monitor-workers

# View worker statistics
just worker-stats
```

### Shell Access

```bash
# Open shell in webserver container
just shell

# Open shell in specific service
just shell-service airflow-scheduler

# Run Airflow CLI commands
just airflow version
just airflow dags list
just airflow tasks list example_dag
```

### DAG Management

```bash
# List all DAGs
just airflow dags list

# Validate DAGs
just validate-dags

# Trigger a DAG
just trigger-dag my_dag_id

# Pause a DAG
just pause-dag my_dag_id

# Unpause a DAG
just unpause-dag my_dag_id
```

### User Management

```bash
# Create a new admin user
just create-user john john@example.com secure_password

# List all users
just list-users
```

### Database Management

```bash
# Upgrade database schema
just db-upgrade

# Backup database
just backup

# Restore from backup
just restore backups/airflow_backup_20260110_120000.sql
```

### Maintenance

```bash
# Clean up stopped containers
just clean

# Full cleanup (WARNING: removes all data!)
just clean-all

# Update Airflow
just update
```

## Directory Structure

```
.
├── dags/           # Put your DAG files here
├── logs/           # Airflow logs
├── plugins/        # Custom Airflow plugins
├── config/         # Additional configuration files
├── docker-compose.yml
├── Dockerfile
├── requirements.txt
├── justfile
└── .env
```

## Adding DAGs

1. Place your DAG Python files in the `dags/` directory
2. Airflow will automatically detect and load them
3. Refresh the web UI to see your new DAGs

Example DAG:

```python
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    'example_dag',
    default_args=default_args,
    description='A simple example DAG',
    schedule_interval=timedelta(days=1),
    catchup=False,
) as dag:

    task1 = BashOperator(
        task_id='print_date',
        bash_command='date',
    )

    task2 = BashOperator(
        task_id='sleep',
        bash_command='sleep 5',
    )

    task1 >> task2
```

## Installing Additional Python Packages

### Method 1: Update requirements.txt

1. Add packages to `requirements.txt`
2. Rebuild the Docker image:
   ```bash
   just build
   just restart
   ```

### Method 2: Runtime Installation (temporary)

Set in `.env`:
```bash
_PIP_ADDITIONAL_REQUIREMENTS=pandas==2.0.0 requests==2.31.0
```

## Scaling Workers

To scale the number of Celery workers:

```bash
docker compose up -d --scale airflow-worker=3
```

## Troubleshooting

### Services won't start

```bash
# Check logs
just logs

# Check specific service
just logs-service airflow-webserver

# Verify environment variables
cat .env
```

### Permission issues

```bash
# Fix permissions on directories
chmod -R 777 logs dags plugins config

# Verify AIRFLOW_UID matches your user
echo $(id -u)
```

### Database issues

```bash
# Reset database (WARNING: loses all data)
just down-volumes
just up-init
```

### Worker not picking up tasks

```bash
# Check worker status
just monitor-workers

# Restart workers
just restart-service airflow-worker

# Check Celery configuration
just logs-service airflow-worker
```

## Production Considerations

### Security

1. Change default admin password
2. Generate strong Fernet and secret keys
3. Use environment-specific `.env` files
4. Restrict network access to services
5. Enable SSL/TLS for web UI
6. Use secrets management (Docker secrets, Vault, etc.)

### Performance

1. Adjust worker concurrency in docker-compose.yml
2. Scale workers based on load
3. Monitor resource usage with `just stats`
4. Configure database connection pooling
5. Tune scheduler settings

### Backup

1. Regular database backups: `just backup`
2. Backup DAGs, plugins, and config directories
3. Store backups off-server
4. Test restore procedures

### Monitoring

1. Use Flower for Celery monitoring (http://localhost:5555)
2. Monitor container resources: `just stats`
3. Set up external monitoring (Prometheus, Grafana, etc.)
4. Configure alerting for failures

## Environment Variables

Key environment variables in `.env`:

| Variable | Description | Required |
|----------|-------------|----------|
| AIRFLOW_UID | User ID for file permissions | Yes |
| POSTGRES_USER | PostgreSQL username | Yes |
| POSTGRES_PASSWORD | PostgreSQL password | Yes |
| AIRFLOW_FERNET_KEY | Encryption key for secrets | Yes |
| AIRFLOW_WEBSERVER_SECRET_KEY | Flask secret key | Yes |
| AIRFLOW_ADMIN_USERNAME | Initial admin username | Yes |
| AIRFLOW_ADMIN_PASSWORD | Initial admin password | Yes |
| _PIP_ADDITIONAL_REQUIREMENTS | Extra Python packages | No |

## Useful Links

- [Apache Airflow Documentation](https://airflow.apache.org/docs/apache-airflow/3.1.5/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Celery Documentation](https://docs.celeryproject.org/)
- [just Documentation](https://just.systems/man/)

## Support

For issues and questions:
- Check logs: `just logs`
- Review Airflow documentation
- Check Docker and Docker Compose versions
- Verify environment configuration

## License

This deployment configuration is provided as-is for use with Apache Airflow.
