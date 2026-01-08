# Apache Airflow - Production Deployment Guide

This guide provides comprehensive instructions for deploying Apache Airflow to production using the enhanced configuration in this repository.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Security](#security)
- [Deployment](#deployment)
- [Monitoring](#monitoring)
- [Backup and Recovery](#backup-and-recovery)
- [Scaling](#scaling)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### System Requirements

- **Docker Engine**: 20.10+ or Docker Desktop
- **Docker Compose**: v2.14.0+
- **Just**: Command runner (optional but recommended)
- **Memory**: 8GB+ RAM available for Docker containers
- **CPU**: 4+ cores recommended
- **Disk**: 50GB+ available space

### Production Checklist

- [ ] Firewall configured with appropriate rules
- [ ] Load balancer configured with SSL/TLS (for HTTPS)
- [ ] Domain name configured (if using)
- [ ] Backup storage configured
- [ ] Monitoring infrastructure ready
- [ ] Secrets management solution selected
- [ ] Resource limits reviewed and adjusted

## Quick Start

### 1. Clone and Setup

```bash
git clone <repository-url>
cd airflow_local

# Create required directories
mkdir -p dags logs plugins config backups/postgres monitoring
```

### 2. Generate Secrets

```bash
# Run the secrets generator script
./scripts/generate_secrets.sh

# Copy output to .env file
cp .env.example .env
# Edit .env and paste the generated secrets
```

### 3. Configure Environment

Edit `.env` file and update:

- All passwords and secret keys (from step 2)
- Database credentials
- Admin user credentials
- Performance tuning parameters
- Email/alerting configuration

### 4. Build and Initialize

```bash
# Build the production image
docker compose -f docker-compose.prod.yaml build

# Initialize the database
docker compose -f docker-compose.prod.yaml up airflow-init

# Start all services
docker compose -f docker-compose.prod.yaml up -d
```

### 5. Verify Deployment

```bash
# Check health status
./scripts/health_check.sh

# View logs
docker compose -f docker-compose.prod.yaml logs -f

# Access the UI
# Default: http://localhost:8080
```

## Configuration

### Environment Variables

All configuration is managed through the `.env` file. Key variables:

#### Security

- `AIRFLOW__CORE__FERNET_KEY`: Encryption key for secrets
- `AIRFLOW__WEBSERVER__SECRET_KEY`: Flask session encryption
- `POSTGRES_PASSWORD`: Database password
- `REDIS_PASSWORD`: Redis password
- `_AIRFLOW_WWW_USER_PASSWORD`: Admin password

#### Performance

- `AIRFLOW__CORE__PARALLELISM`: Max parallel tasks (default: 32)
- `AIRFLOW__CORE__DAG_CONCURRENCY`: Tasks per DAG (default: 16)
- `AIRFLOW__CELERY__WORKER_CONCURRENCY`: Worker concurrency (default: 16)
- `AIRFLOW_WORKER_REPLICAS`: Number of worker containers (default: 2)

#### Database

- `AIRFLOW__DATABASE__SQL_ALCHEMY_POOL_SIZE`: Connection pool size
- `AIRFLOW__DATABASE__SQL_ALCHEMY_MAX_OVERFLOW`: Max overflow connections

### Resource Limits

Resource limits are defined in `docker-compose.prod.yaml`:

| Service | CPU Limit | Memory Limit | CPU Reserved | Memory Reserved |
|---------|-----------|--------------|--------------|-----------------|
| Webserver | 2 | 2GB | 1 | 1GB |
| Scheduler | 2 | 2GB | 1 | 1GB |
| Worker | 4 | 4GB | 2 | 2GB |
| PostgreSQL | 2 | 2GB | 1 | 1GB |
| Redis | 1 | 512MB | 0.5 | 256MB |

Adjust these based on your workload.

### Custom Configuration

Place custom configurations in:

- `config/airflow.cfg`: Airflow configuration overrides
- `config/airflow_local_settings.py`: Cluster policies and custom settings

## Security

### Secrets Management

#### Option 1: Environment Variables (Basic)

Secrets are stored in `.env` file. **Not recommended for production.**

#### Option 2: External Secrets Backend

Configure external secrets backend in `airflow.cfg`:

```ini
[secrets]
backend = airflow.providers.hashicorp.secrets.vault.VaultBackend
backend_kwargs = {"url": "http://vault:8200", "token": "your-token"}
```

Supported backends:

- HashiCorp Vault
- AWS Secrets Manager
- Google Secret Manager
- Azure Key Vault

### Network Security

1. **Use External Load Balancer or Reverse Proxy**:

For production deployments, use an external reverse proxy:
- AWS Application Load Balancer
- Google Cloud Load Balancer
- Azure Application Gateway
- Traefik, HAProxy, or Caddy

2. **Firewall Rules**:

```bash
# Allow only necessary ports
# - 8080 (Airflow UI) - through load balancer only
# - 5432 (PostgreSQL) - only from Airflow containers
# - 6379 (Redis) - only from Airflow containers
```

### Authentication

Production configuration enables:

- RBAC (Role-Based Access Control)
- User authentication required
- API authentication (Basic Auth + Session)

Configure additional auth backends in `.env`:

```bash
AIRFLOW__API__AUTH_BACKENDS=airflow.api.auth.backend.basic_auth,airflow.api.auth.backend.session
```

## Deployment

### Standard Deployment

```bash
# Using docker-compose directly
docker compose -f docker-compose.prod.yaml up -d

# Using Just (if available)
just -f Justfile-prod up
```

### With Monitoring (Optional)

```bash
# Start with monitoring stack (Prometheus + Grafana)
docker compose -f docker-compose.prod.yaml --profile monitoring up -d

# Access:
# - Grafana: http://localhost:3000
# - Prometheus: http://localhost:9090
```

### Scaling Workers

```bash
# Scale workers to 5 replicas
docker compose -f docker-compose.prod.yaml up -d --scale airflow-worker=5

# Or set in .env:
AIRFLOW_WORKER_REPLICAS=5
```

### SSL/TLS (Use External Load Balancer)

For production HTTPS, use an external load balancer or reverse proxy:
- AWS: Application Load Balancer with ACM certificates
- Google Cloud: HTTPS Load Balancer with managed certificates
- Azure: Application Gateway with SSL termination
- On-premise: HAProxy, Traefik, or cloud provider load balancer

## Monitoring

### Built-in Health Checks

```bash
# Run health check script
./scripts/health_check.sh

# Check individual service health
docker compose -f docker-compose.prod.yaml ps
```

### Metrics Collection

Enable StatsD metrics in `.env`:

```bash
AIRFLOW__METRICS__STATSD_ON=true
AIRFLOW__METRICS__STATSD_HOST=statsd-exporter
AIRFLOW__METRICS__STATSD_PORT=9125
```

### Grafana Dashboards

After starting with `--profile monitoring`:

1. Access Grafana at http://localhost:3000
2. Login with credentials from `.env` (default: admin/admin)
3. Import Airflow dashboards:
   - Airflow Overview
   - DAG Performance
   - Task Duration
   - System Resources

### Alerts

Configure alerts in:

- `monitoring/prometheus.yml`: Prometheus alert rules
- Grafana: Dashboard-based alerts

## Backup and Recovery

### Automated Backups

```bash
# Run manual backup
./scripts/backup_postgres.sh

# Setup cron job for daily backups
0 2 * * * /path/to/airflow_local/scripts/backup_postgres.sh
```

Backups are stored in `backups/postgres/` with 7-day retention by default.

### Restore from Backup

```bash
# List available backups
ls -lh backups/postgres/

# Restore from specific backup
./scripts/restore_postgres.sh backups/postgres/airflow_backup_20260108_120000.sql.gz
```

### Backup to Cloud Storage

Configure remote backup in your backup script or use:

- AWS S3
- Google Cloud Storage
- Azure Blob Storage

### Disaster Recovery Plan

1. **Database**: Daily automated backups with 7-day retention
2. **DAGs**: Version controlled in Git
3. **Logs**: Configure remote log storage (S3/GCS/Azure)
4. **Configuration**: `.env` and config files backed up separately

## Scaling

### Horizontal Scaling

#### Scale Workers

```bash
# Increase worker replicas
docker compose -f docker-compose.prod.yaml up -d --scale airflow-worker=10
```

#### Use Kubernetes

For large-scale deployments, consider:

- **Kubernetes Executor**: Run tasks as Kubernetes pods
- **Helm Charts**: Use official Airflow Helm chart
- **Auto-scaling**: Configure HPA (Horizontal Pod Autoscaler)

### Vertical Scaling

Adjust resource limits in `docker-compose.prod.yaml`:

```yaml
deploy:
  resources:
    limits:
      cpus: '8'
      memory: 16G
```

### Database Scaling

For high-volume workloads:

1. Use external managed PostgreSQL (AWS RDS, Google Cloud SQL)
2. Configure connection pooling (PgBouncer)
3. Enable read replicas for analytics

### Queue Management

Create specialized queues for different workload types:

```python
# In DAG definition
task = BashOperator(
    task_id='heavy_task',
    bash_command='...',
    queue='high_memory'  # Route to specific worker pool
)
```

## Troubleshooting

### Common Issues

#### Services Not Starting

```bash
# Check logs
docker compose -f docker-compose.prod.yaml logs

# Check specific service
docker compose -f docker-compose.prod.yaml logs airflow-scheduler
```

#### Database Connection Issues

```bash
# Check PostgreSQL health
docker compose -f docker-compose.prod.yaml exec postgres pg_isready -U airflow

# Check connection from scheduler
docker compose -f docker-compose.prod.yaml exec airflow-scheduler airflow db check
```

#### Memory Issues

```bash
# Check resource usage
docker stats

# Adjust limits in docker-compose.prod.yaml or Docker Desktop settings
```

#### Permission Issues

```bash
# Fix ownership
sudo chown -R $(id -u):0 ./dags ./logs ./plugins ./config
```

### Performance Issues

#### Slow DAG Processing

1. Increase `AIRFLOW__SCHEDULER__PARSING_PROCESSES`
2. Reduce DAG complexity
3. Use `dagbag_import_timeout` wisely

#### Task Queue Buildup

1. Scale workers: `--scale airflow-worker=N`
2. Increase worker concurrency: `AIRFLOW__CELERY__WORKER_CONCURRENCY`
3. Review task parallelism settings

#### Database Bottlenecks

1. Increase connection pool size
2. Optimize PostgreSQL configuration (see docker-compose.prod.yaml)
3. Use external managed database
4. Add read replicas

### Logs and Debugging

```bash
# View all logs
docker compose -f docker-compose.prod.yaml logs -f

# View specific service logs
docker compose -f docker-compose.prod.yaml logs -f airflow-scheduler

# Access container shell
docker compose -f docker-compose.prod.yaml exec airflow-scheduler bash

# Check Airflow configuration
docker compose -f docker-compose.prod.yaml exec airflow-scheduler airflow config list
```

## Production Best Practices

### 1. Security

- [ ] Use strong, unique passwords
- [ ] Rotate Fernet key periodically
- [ ] Configure load balancer with SSL/TLS
- [ ] Use secrets management backend
- [ ] Implement network segmentation
- [ ] Enable audit logging
- [ ] Regular security updates

### 2. High Availability

- [ ] Run multiple scheduler replicas (Airflow 2.0+)
- [ ] Use external managed databases
- [ ] Configure database replication
- [ ] Deploy across multiple availability zones
- [ ] Implement load balancing

### 3. Monitoring

- [ ] Enable metrics collection
- [ ] Set up alerting (PagerDuty, OpsGenie)
- [ ] Monitor resource usage
- [ ] Track DAG success rates
- [ ] Monitor task durations

### 4. Maintenance

- [ ] Regular backups (automated)
- [ ] Database maintenance (vacuum, analyze)
- [ ] Log rotation and cleanup
- [ ] Dependency updates
- [ ] Performance tuning

### 5. Development Workflow

- [ ] Version control for DAGs
- [ ] CI/CD pipeline for DAG deployment
- [ ] Separate dev/staging/prod environments
- [ ] DAG testing before production
- [ ] Code review process

## Support and Resources

- [Official Airflow Documentation](https://airflow.apache.org/docs/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Production Deployment Best Practices](https://airflow.apache.org/docs/apache-airflow/stable/production-deployment.html)

## License

This configuration is provided as-is under the Apache License 2.0, same as Apache Airflow.
