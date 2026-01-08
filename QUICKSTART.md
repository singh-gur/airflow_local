# Production Deployment Quick Start

This is a quick reference guide for deploying Airflow to production. For detailed instructions, see [PRODUCTION.md](PRODUCTION.md).

## Prerequisites

- Docker & Docker Compose installed
- 8GB+ RAM available
- 50GB+ disk space
- Just (command runner) - optional but recommended

## 5-Minute Production Setup

### 1. Generate Secrets

```bash
./scripts/generate_secrets.sh
```

Copy the output to a new `.env` file:

```bash
cp .env.example .env
# Paste the generated secrets into .env
```

### 2. Build and Deploy

```bash
# Build production images
just -f Justfile-prod prod-build

# Initialize database
just -f Justfile-prod prod-init

# Start all services
just -f Justfile-prod prod-up

# Or with monitoring (Prometheus + Grafana)
just -f Justfile-prod prod-up-monitoring
```

### 3. Verify Deployment

```bash
# Check health
just -f Justfile-prod prod-health

# View logs
just -f Justfile-prod prod-logs
```

### 4. Access Airflow

- **Airflow UI**: http://localhost:8080
- **Grafana** (if monitoring enabled): http://localhost:3000
- **Prometheus** (if monitoring enabled): http://localhost:9090

Login with credentials from `.env`:
- Username: Value of `_AIRFLOW_WWW_USER_USERNAME`
- Password: Value of `_AIRFLOW_WWW_USER_PASSWORD`

## Common Operations

### Scale Workers

```bash
# Scale to 5 workers
just -f Justfile-prod prod-scale 5
```

### Create Backup

```bash
# Manual backup
just -f Justfile-prod prod-backup

# Setup automated daily backups (cron)
0 2 * * * cd /path/to/airflow && just -f Justfile-prod prod-backup
```

### Deploy Updates

```bash
# Zero-downtime deployment
just -f Justfile-prod prod-deploy
```

### View Status

```bash
# Service status
just -f Justfile-prod prod-status

# Resource usage
just -f Justfile-prod prod-stats

# Health check
just -f Justfile-prod prod-health
```

## Production Checklist

Before going live, ensure:

- [ ] Strong passwords set in `.env`
- [ ] Fernet key generated and set
- [ ] Load balancer with SSL/TLS configured (if needed)
- [ ] Firewall rules configured
- [ ] Automated backups scheduled
- [ ] Monitoring enabled
- [ ] Resource limits reviewed
- [ ] Email/alerting configured
- [ ] DAGs tested in staging

## Troubleshooting

### Services Won't Start

```bash
# Check logs
just -f Justfile-prod prod-logs

# Check specific service
just -f Justfile-prod prod-logs-service airflow-scheduler
```

### Database Connection Issues

```bash
# Check database health
just -f Justfile-prod prod-db-check
```

### Performance Issues

```bash
# Check resource usage
just -f Justfile-prod prod-stats

# Scale workers
just -f Justfile-prod prod-scale 5
```

## Key Files

| File | Purpose |
|------|---------|
| `docker-compose.prod.yaml` | Production service configuration |
| `Dockerfile` | Production image build |
| `.env` | Environment variables and secrets |
| `PRODUCTION.md` | Detailed deployment guide |
| `Justfile-prod` | Production commands |
| `scripts/` | Utility scripts |
| `nginx/` | Reverse proxy configuration |
| `monitoring/` | Prometheus/Grafana configs |

## Support

For issues or questions:
1. Check [PRODUCTION.md](PRODUCTION.md) for detailed documentation
2. Review [Airflow Documentation](https://airflow.apache.org/docs/)
3. Check logs: `just -f Justfile-prod prod-logs`

## Security Notes

**IMPORTANT**: 
- Never commit `.env` file to version control
- Use strong, unique passwords for all services
- Rotate secrets regularly
- Use a load balancer with SSL/TLS for production
- Configure firewall rules appropriately
- Use external secrets management (Vault, AWS Secrets Manager, etc.) for production
