# Production Deployment Checklist

Use this checklist when deploying to production. Check off items as you complete them.

## Pre-Deployment

### Security Setup
- [ ] Run `./scripts/generate_secrets.sh` and save output securely
- [ ] Create `.env` file from `.env.example`
- [ ] Add all generated secrets to `.env` file
- [ ] Verify Fernet key is set (`AIRFLOW__CORE__FERNET_KEY`)
- [ ] Verify webserver secret key is set (`AIRFLOW__WEBSERVER__SECRET_KEY`)
- [ ] Change default admin password (strong password)
- [ ] Change PostgreSQL password (strong password)
- [ ] Change Redis password (strong password)

### SSL/TLS Configuration (if using HTTPS)
- [ ] Obtain SSL certificates from trusted CA (or generate self-signed for testing)
- [ ] Place certificates in `nginx/ssl/cert.pem` and `nginx/ssl/key.pem`
- [ ] Update `nginx/nginx.conf` with your domain name
- [ ] Verify SSL configuration: `openssl x509 -in nginx/ssl/cert.pem -text -noout`

### Infrastructure Setup
- [ ] Verify Docker and Docker Compose versions meet requirements
- [ ] Ensure sufficient resources (8GB+ RAM, 50GB+ disk)
- [ ] Review and adjust resource limits in `docker-compose.prod.yaml`
- [ ] Configure firewall rules (allow 80/443, restrict 8080/5432/6379)
- [ ] Set up DNS records (if using custom domain)

### Application Configuration
- [ ] Review and customize `requirements.txt` with your dependencies
- [ ] Update performance settings in `.env` based on workload
- [ ] Configure email/SMTP settings for alerts
- [ ] Review and customize `config/airflow.cfg.template`
- [ ] Set timezone (`AIRFLOW__CORE__DEFAULT_TIMEZONE`)

### Monitoring Setup
- [ ] Decide on monitoring strategy (enable Prometheus/Grafana?)
- [ ] Configure Grafana admin password if using monitoring
- [ ] Review Prometheus configuration
- [ ] Plan alerting strategy (email, PagerDuty, Slack, etc.)

## Deployment

### Build and Initialize
- [ ] Build production images: `just -f Justfile-prod prod-build`
- [ ] Verify build completed successfully
- [ ] Initialize database: `just -f Justfile-prod prod-init`
- [ ] Verify initialization completed without errors

### Start Services
- [ ] Choose deployment profile:
  - [ ] Standard: `just -f Justfile-prod prod-up`
  - [ ] With monitoring: `just -f Justfile-prod prod-up-monitoring`
  - [ ] With HTTPS: `just -f Justfile-prod prod-up-proxy`
- [ ] Wait for services to start (30-60 seconds)

### Verification
- [ ] Run health check: `just -f Justfile-prod prod-health`
- [ ] Verify all services show as healthy
- [ ] Check service status: `just -f Justfile-prod prod-status`
- [ ] Access Airflow UI and verify login works
- [ ] Verify database connectivity: `just -f Justfile-prod prod-db-check`
- [ ] Review logs for any errors: `just -f Justfile-prod prod-logs`

## Post-Deployment

### Testing
- [ ] Create and trigger a simple test DAG
- [ ] Verify DAG appears in UI
- [ ] Verify DAG executes successfully
- [ ] Check task logs are accessible
- [ ] Test worker scaling: `just -f Justfile-prod prod-scale 3`
- [ ] Verify all workers are healthy

### Backup Configuration
- [ ] Test manual backup: `just -f Justfile-prod prod-backup`
- [ ] Verify backup file created in `backups/postgres/`
- [ ] Test restore procedure: `just -f Justfile-prod prod-restore <backup_file>`
- [ ] Schedule automated backups via cron:
  ```bash
  # Edit crontab
  crontab -e
  
  # Add backup job (daily at 2 AM)
  0 2 * * * cd /path/to/airflow && just -f Justfile-prod prod-backup
  ```
- [ ] Configure off-site backup storage (S3, GCS, etc.)
- [ ] Test backup restoration process

### Monitoring Configuration
- [ ] Access Grafana (if enabled) and verify dashboards load
- [ ] Import additional Airflow dashboards
- [ ] Configure alert rules in Prometheus
- [ ] Set up notification channels (email, Slack, PagerDuty)
- [ ] Test alerting by triggering a failure
- [ ] Configure log aggregation (optional: ELK, Splunk, etc.)

### Security Hardening
- [ ] Verify HTTPS is working (if configured)
- [ ] Test rate limiting (make rapid requests)
- [ ] Review security headers: `curl -I https://your-domain.com`
- [ ] Enable external secrets backend (Vault, AWS Secrets Manager)
- [ ] Configure OAuth/SSO authentication (optional)
- [ ] Enable audit logging
- [ ] Review and restrict network access
- [ ] Set up VPN access (if needed)

### Documentation
- [ ] Document your deployment configuration
- [ ] Create runbook for common operations
- [ ] Document incident response procedures
- [ ] Document backup/restore procedures
- [ ] Share access credentials with team (securely)
- [ ] Document maintenance windows
- [ ] Create on-call rotation (if applicable)

### Team Readiness
- [ ] Train team on production commands (`Justfile-prod`)
- [ ] Share access to monitoring dashboards
- [ ] Review incident response procedures
- [ ] Schedule regular health checks
- [ ] Plan for future scaling needs

## Ongoing Maintenance

### Daily
- [ ] Monitor health checks: `just -f Justfile-prod prod-health`
- [ ] Review error logs for issues
- [ ] Check resource usage: `just -f Justfile-prod prod-stats`
- [ ] Monitor DAG success rates

### Weekly
- [ ] Verify automated backups are running
- [ ] Test backup integrity (spot checks)
- [ ] Review performance metrics
- [ ] Check for security updates
- [ ] Review disk space usage

### Monthly
- [ ] Run database maintenance: `just -f Justfile-prod prod-db-vacuum`
- [ ] Clean up old task instances: `just -f Justfile-prod prod-cleanup 30`
- [ ] Review and optimize slow DAGs
- [ ] Update dependencies (security patches)
- [ ] Rotate secrets (if required by policy)
- [ ] Review access logs for anomalies
- [ ] Performance tuning based on metrics

### Quarterly
- [ ] Full disaster recovery drill
- [ ] Security audit
- [ ] Review and update documentation
- [ ] Review resource allocation and scaling needs
- [ ] Upgrade Airflow version (test in staging first)
- [ ] Team training refresh

## Emergency Procedures

### Service Down
1. Check health: `just -f Justfile-prod prod-health`
2. Check logs: `just -f Justfile-prod prod-logs`
3. Restart services: `just -f Justfile-prod prod-restart`
4. If issue persists, check individual service logs

### Database Issues
1. Check database: `just -f Justfile-prod prod-db-check`
2. Review PostgreSQL logs
3. Consider restore from backup if corrupted

### Performance Degradation
1. Check resource usage: `just -f Justfile-prod prod-stats`
2. Scale workers if needed: `just -f Justfile-prod prod-scale <N>`
3. Review slow queries and DAGs
4. Consider vertical scaling (increase resources)

### Security Incident
1. Review access logs
2. Rotate compromised credentials
3. Update Fernet key: `just -f Justfile-prod prod-rotate-fernet`
4. Review and update security policies
5. Notify security team

## Rollback Procedure

If deployment fails:
1. Stop services: `just -f Justfile-prod prod-down`
2. Restore from backup: `just -f Justfile-prod prod-restore <backup_file>`
3. Checkout previous version: `git checkout <previous-tag>`
4. Rebuild: `just -f Justfile-prod prod-build`
5. Start services: `just -f Justfile-prod prod-up`
6. Verify health: `just -f Justfile-prod prod-health`

## Notes

**Date Deployed**: _______________  
**Deployed By**: _______________  
**Version**: _______________  
**Notes**: 
_______________________________________________
_______________________________________________
_______________________________________________

## Sign-off

- [ ] Technical Lead: _______________  Date: _______________
- [ ] Security Review: _______________  Date: _______________
- [ ] Operations: _______________  Date: _______________
