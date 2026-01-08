# Apache Airflow - Docker Setup

Production-ready Apache Airflow deployment using Docker Compose with automated setup, backups, and monitoring.

## Table of Contents

- [Quick Start (Development)](#quick-start-development)
- [Production Setup](#production-setup)
- [Common Commands](#common-commands)
- [Configuration](#configuration)
- [Backup & Recovery](#backup--recovery)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)

---

## Quick Start (Development)

Get Airflow running locally in 3 commands:

```bash
# 1. Setup environment
just setup

# 2. Initialize database
just init

# 3. Start Airflow
just up
```

**Access**: http://localhost:8089 (login: airflow/airflow)

**Prerequisites**: Docker, Docker Compose, Just (optional but recommended)

---

## Production Setup

### Step 1: Generate Secrets

```bash
# Generate secure passwords and keys
./scripts/generate_secrets.sh
```

This generates:
- Fernet key (for encrypting secrets)
- Webserver secret key
- PostgreSQL password
- Redis password
- Admin password

### Step 2: Configure Environment

```bash
# Copy template
cp .env.example .env

# Edit .env and add the secrets from step 1
nano .env
```

**Required variables**:
```env
AIRFLOW__CORE__FERNET_KEY=<from generate_secrets.sh>
AIRFLOW__WEBSERVER__SECRET_KEY=<from generate_secrets.sh>
POSTGRES_PASSWORD=<from generate_secrets.sh>
REDIS_PASSWORD=<from generate_secrets.sh>
_AIRFLOW_WWW_USER_PASSWORD=<from generate_secrets.sh>
AIRFLOW_UID=<your user id>
```

### Step 3: Build Production Image

```bash
docker compose -f docker-compose.prod.yaml build
```

### Step 4: Initialize Database

```bash
docker compose -f docker-compose.prod.yaml up airflow-init
```

### Step 5: Start Production Services

```bash
# Standard deployment
docker compose -f docker-compose.prod.yaml up -d

# With monitoring (Prometheus + Grafana)
docker compose -f docker-compose.prod.yaml --profile monitoring up -d
```

### Step 6: Verify Health

```bash
# Check all services
./scripts/health_check.sh

# View logs
docker compose -f docker-compose.prod.yaml logs -f
```

**Access**: http://localhost:8080 (use admin credentials from .env)

### Step 7: Production Hardening

1. **Configure External Load Balancer** (for SSL/TLS):
   - AWS: Application Load Balancer with ACM
   - GCP: HTTPS Load Balancer
   - Azure: Application Gateway
   - On-premise: Traefik, HAProxy, or Caddy

2. **Firewall Rules**:
   ```bash
   # Allow only necessary ports
   # - 8080 (Airflow UI) - through load balancer only
   # - Block direct access to PostgreSQL (5432) and Redis (6379)
   ```

3. **Setup Automated Backups**:
   ```bash
   # Add to crontab for daily backups at 2 AM
   crontab -e
   0 2 * * * cd /path/to/airflow && ./scripts/backup_postgres.sh
   ```

4. **Use External Secrets Manager** (recommended):
   - AWS Secrets Manager
   - HashiCorp Vault
   - Azure Key Vault
   - Google Secret Manager

   Configure in `config/airflow.cfg.template`:
   ```ini
   [secrets]
   backend = airflow.providers.amazon.aws.secrets.secrets_manager.SecretsManagerBackend
   backend_kwargs = {"connections_prefix": "airflow/connections", "variables_prefix": "airflow/variables"}
   ```

---

## Common Commands

### Development

```bash
just setup              # Create directories and .env
just init               # Initialize database
just up                 # Start all services
just down               # Stop all services
just restart            # Restart services
just logs               # View logs
just bash               # Access scheduler container
just dags-list          # List all DAGs
just dag-trigger <id>   # Trigger a DAG
```

### Production

```bash
# Build and deploy
docker compose -f docker-compose.prod.yaml build
docker compose -f docker-compose.prod.yaml up -d

# Manage services
docker compose -f docker-compose.prod.yaml ps              # Status
docker compose -f docker-compose.prod.yaml logs -f         # Logs
docker compose -f docker-compose.prod.yaml restart         # Restart
docker compose -f docker-compose.prod.yaml down            # Stop

# Scale workers
docker compose -f docker-compose.prod.yaml up -d --scale airflow-worker=5

# Health check
./scripts/health_check.sh
```

---

## Configuration

### Environment Variables (.env)

Key configuration options:

```env
# Security
AIRFLOW__CORE__FERNET_KEY=          # Encryption key
AIRFLOW__WEBSERVER__SECRET_KEY=     # Flask session key
POSTGRES_PASSWORD=                   # Database password
REDIS_PASSWORD=                      # Redis password

# Performance
AIRFLOW__CORE__PARALLELISM=32                    # Max parallel tasks
AIRFLOW__CORE__DAG_CONCURRENCY=16               # Tasks per DAG
AIRFLOW__CELERY__WORKER_CONCURRENCY=16          # Worker concurrency
AIRFLOW_WORKER_REPLICAS=2                       # Number of workers

# Database Pool
AIRFLOW__DATABASE__SQL_ALCHEMY_POOL_SIZE=10
AIRFLOW__DATABASE__SQL_ALCHEMY_MAX_OVERFLOW=20

# Logging
AIRFLOW__LOGGING__LOGGING_LEVEL=INFO
```

### Custom Python Dependencies

Edit `requirements.txt` to add your packages:

```txt
# Cloud providers
apache-airflow-providers-amazon>=8.18.0
apache-airflow-providers-google>=10.16.0

# Data processing
pandas>=2.2.0
numpy>=1.26.0

# Your custom packages
your-package>=1.0.0
```

Then rebuild:
```bash
docker compose -f docker-compose.prod.yaml build
```

### Resource Limits

Adjust in `docker-compose.prod.yaml`:

```yaml
deploy:
  resources:
    limits:
      cpus: '4'      # Increase CPU limit
      memory: 8G     # Increase memory limit
```

---

## Backup & Recovery

### Manual Backup

```bash
./scripts/backup_postgres.sh
```

Backups stored in: `backups/postgres/airflow_backup_YYYYMMDD_HHMMSS.sql.gz`

### Automated Backups

```bash
# Add to crontab (daily at 2 AM)
crontab -e
0 2 * * * cd /path/to/airflow && ./scripts/backup_postgres.sh
```

### Restore from Backup

```bash
# List available backups
ls -lh backups/postgres/

# Restore specific backup
./scripts/restore_postgres.sh backups/postgres/airflow_backup_20260108_020000.sql.gz
```

### Log Cleanup

```bash
# Clean logs older than 30 days
LOG_RETENTION_DAYS=30 ./scripts/cleanup_logs.sh

# Setup automated cleanup (weekly)
crontab -e
0 0 * * 0 cd /path/to/airflow && ./scripts/cleanup_logs.sh
```

---

## Monitoring

### Built-in Monitoring

Start with monitoring enabled:

```bash
docker compose -f docker-compose.prod.yaml --profile monitoring up -d
```

**Access**:
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000 (admin/from .env)

### Metrics Collection

Enable StatsD metrics in `.env`:

```env
AIRFLOW__METRICS__STATSD_ON=true
AIRFLOW__METRICS__STATSD_HOST=statsd-exporter
AIRFLOW__METRICS__STATSD_PORT=9125
```

### Health Checks

```bash
# Manual health check
./scripts/health_check.sh

# Add to monitoring (every 5 minutes)
*/5 * * * * cd /path/to/airflow && ./scripts/health_check.sh || /path/to/alert.sh
```

---

## Troubleshooting

### Services Won't Start

```bash
# Check logs
docker compose -f docker-compose.prod.yaml logs

# Check specific service
docker compose -f docker-compose.prod.yaml logs airflow-scheduler

# Check resources
docker stats
```

### Database Connection Issues

```bash
# Test database connection
docker compose -f docker-compose.prod.yaml exec postgres pg_isready -U airflow

# Check from scheduler
docker compose -f docker-compose.prod.yaml exec airflow-scheduler \
  airflow db check
```

### Permission Errors

```bash
# Fix ownership
sudo chown -R $(id -u):0 ./dags ./logs ./plugins ./config
```

### Out of Memory

```bash
# Check memory usage
docker stats

# Increase Docker memory (Docker Desktop settings)
# Or reduce worker concurrency in .env:
AIRFLOW__CELERY__WORKER_CONCURRENCY=8
```

### DAGs Not Appearing

```bash
# Check DAG directory
docker compose -f docker-compose.prod.yaml exec airflow-scheduler \
  ls -la /opt/airflow/dags

# Check for import errors
docker compose -f docker-compose.prod.yaml exec airflow-scheduler \
  airflow dags list-import-errors
```

---

## Directory Structure

```
.
├── dags/                      # Your DAG files
├── logs/                      # Airflow logs
├── plugins/                   # Custom plugins
├── config/                    # Configuration templates
│   ├── airflow.cfg.template  # Airflow config
│   └── log4j2.properties     # Logging config
├── scripts/                   # Utility scripts
│   ├── generate_secrets.sh   # Secret generation
│   ├── backup_postgres.sh    # Database backup
│   ├── restore_postgres.sh   # Database restore
│   ├── health_check.sh       # Health monitoring
│   └── cleanup_logs.sh       # Log cleanup
├── backups/                   # Database backups
├── .github/workflows/         # CI/CD pipelines
├── docker-compose.yaml        # Development setup
├── docker-compose.prod.yaml   # Production setup
├── Dockerfile                 # Production image
├── .env.example              # Environment template
├── requirements.txt          # Python dependencies
└── Justfile                  # Command shortcuts
```

---

## Production Checklist

Before going live:

- [ ] Generate and secure all secrets
- [ ] Configure `.env` with strong passwords
- [ ] Set up external load balancer with SSL/TLS
- [ ] Configure firewall rules
- [ ] Set up automated backups
- [ ] Enable monitoring (Prometheus + Grafana)
- [ ] Configure email/alerting
- [ ] Test DAGs in staging environment
- [ ] Document runbooks and procedures
- [ ] Set up log aggregation (optional: ELK, Splunk)
- [ ] Configure external secrets manager (Vault, AWS Secrets Manager)

---

## Scaling

### Horizontal Scaling

```bash
# Scale workers to 10 replicas
docker compose -f docker-compose.prod.yaml up -d --scale airflow-worker=10

# Or set in .env:
AIRFLOW_WORKER_REPLICAS=10
```

### Vertical Scaling

Edit resource limits in `docker-compose.prod.yaml`:

```yaml
airflow-worker:
  deploy:
    resources:
      limits:
        cpus: '8'
        memory: 16G
```

### External Database

For high-volume production, use managed database:

1. Set up AWS RDS, Google Cloud SQL, or Azure Database
2. Update `.env`:
   ```env
   POSTGRES_USER=airflow
   POSTGRES_PASSWORD=<secure_password>
   POSTGRES_HOST=<rds_endpoint>
   POSTGRES_DB=airflow
   ```
3. Comment out `postgres` service in `docker-compose.prod.yaml`

---

## Support & Resources

- **Official Docs**: https://airflow.apache.org/docs/
- **Docker Guide**: https://airflow.apache.org/docs/apache-airflow/stable/howto/docker-compose/
- **Best Practices**: https://airflow.apache.org/docs/apache-airflow/stable/best-practices.html

---

## License

Apache License 2.0
