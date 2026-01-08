# Changelog

All notable changes to this Airflow deployment repository.

## [2.0.0] - Production Ready - 2026-01-08

### Added - Production Features

#### Core Infrastructure
- Production-ready `docker-compose.prod.yaml` with security and performance optimizations
- Custom `Dockerfile` for building production images with baked-in dependencies
- Resource limits and reservations for all services
- Health checks for all critical services
- Restart policies configured for high availability

#### Security
- `.env.example` with comprehensive environment variable documentation
- `scripts/generate_secrets.sh` for secure secret generation
- Fernet key and webserver secret key generation
- Password management for PostgreSQL, Redis, and admin users
- Nginx reverse proxy configuration with SSL/TLS termination
- Security headers and rate limiting
- RBAC enabled by default

#### Monitoring & Observability
- Prometheus configuration for metrics collection
- Grafana dashboards and provisioning
- StatsD exporter for Airflow metrics
- Health check script (`scripts/health_check.sh`)
- Enhanced logging configuration

#### Backup & Recovery
- Automated PostgreSQL backup script (`scripts/backup_postgres.sh`)
- Database restore script (`scripts/restore_postgres.sh`)
- 7-day backup retention policy
- Log cleanup script (`scripts/cleanup_logs.sh`)

#### Configuration Management
- Production-ready `airflow.cfg` template
- Environment-based configuration
- Separate development and production compose files
- `.dockerignore` for optimized builds

#### Automation & CI/CD
- Production Justfile (`Justfile-prod`) with 40+ commands
- GitHub Actions CI/CD workflows
  - CI: Build, test, lint, security scanning
  - Deploy: Automated deployment with zero-downtime
- Deployment scripts and automation

#### Documentation
- Comprehensive production deployment guide (`PRODUCTION.md`)
- Quick start guide (`QUICKSTART.md`)
- Nginx configuration documentation
- Secrets management guide
- Troubleshooting section

#### Performance Optimization
- PostgreSQL tuning for production workloads
- Redis configuration with persistence
- Celery worker scaling support
- Connection pooling configuration
- Database query optimization settings

### Changed

#### Infrastructure
- Updated to Airflow 2.10.4
- PostgreSQL upgraded to version 16
- Redis 7.2 with improved configuration
- Enhanced Docker networking

#### Configuration
- Updated `requirements.txt` with production essentials
- Enhanced `.gitignore` for production files
- Improved volume mounting strategy

### Enhanced

#### Development Workflow
- Improved local development experience
- Better separation of dev and prod environments
- Enhanced DAG development guidelines

## [1.0.0] - Initial Release

### Added
- Basic Docker Compose setup for local development
- Justfile with common development tasks
- Development README
- Basic configuration files
- Example DAG structure

---

## Upgrade Guide

### From 1.0.0 to 2.0.0

1. **Backup your data**:
   ```bash
   # If you have existing data
   docker compose exec postgres pg_dump -U airflow airflow > backup.sql
   ```

2. **Generate production secrets**:
   ```bash
   ./scripts/generate_secrets.sh
   cp .env.example .env
   # Add generated secrets to .env
   ```

3. **Update configuration**:
   - Review `docker-compose.prod.yaml` for resource limits
   - Update `requirements.txt` with your dependencies
   - Configure monitoring if needed

4. **Deploy**:
   ```bash
   just -f Justfile-prod prod-build
   just -f Justfile-prod prod-init
   just -f Justfile-prod prod-up
   ```

5. **Restore data** (if applicable):
   ```bash
   cat backup.sql | docker compose -f docker-compose.prod.yaml exec -T postgres psql -U airflow airflow
   ```

---

## Migration Notes

### Breaking Changes in 2.0.0

- Environment variables now required in `.env` file
- Fernet key must be explicitly set
- PostgreSQL and Redis passwords now required
- Port changed from 8080 to 8089 for development (production uses 8080)

### New Requirements

- Docker Compose v2.14.0+
- Just command runner (optional but recommended)
- Python 3.9+ (for secret generation scripts)

---

## Contributing

When adding new features, please:
1. Update this CHANGELOG
2. Update relevant documentation
3. Add tests if applicable
4. Update Justfile commands if needed
