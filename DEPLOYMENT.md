# Server Deployment Guide

Quick guide for deploying Airflow on a server.

## Prerequisites on Server

1. Install Docker and Docker Compose
2. Install just command runner
3. Ensure ports 8080, 5555, 5432, 6379 are available

## Deployment Steps

### 1. Clone or Transfer Files

```bash
# Option A: Clone from git
git clone <your-repo-url>
cd airflow_local

# Option B: Transfer files via rsync
rsync -avz --exclude '.git' ./ user@server:/path/to/airflow_local/
```

### 2. Initial Setup

```bash
# Initialize environment
just init

# Edit .env file with your configuration
nano .env

# Set AIRFLOW_UID to your user ID
echo "AIRFLOW_UID=$(id -u)" >> .env

# Generate and set Fernet key
echo "AIRFLOW_FERNET_KEY=$(just generate-fernet-key)" >> .env

# Generate and set secret key
echo "AIRFLOW_WEBSERVER_SECRET_KEY=$(just generate-secret-key)" >> .env

# Update admin credentials
# Edit these lines in .env:
# AIRFLOW_ADMIN_USERNAME=your_username
# AIRFLOW_ADMIN_PASSWORD=your_secure_password
```

### 3. Deploy

```bash
# Build images
just build

# Start with initialization
just up-init

# Wait for services to be ready (check status)
just status

# View logs
just logs
```

### 4. Verify Deployment

```bash
# Check service status
just status

# Test web UI access
curl http://localhost:8080/health

# View logs for any errors
just logs
```

### 5. Access Airflow

- Web UI: http://server-ip:8080
- Flower: http://server-ip:5555

## Production Configuration

### 1. Firewall Configuration

```bash
# Allow Airflow web UI
sudo ufw allow 8080/tcp

# Allow Flower (optional, can restrict to internal network)
sudo ufw allow 5555/tcp

# Or use nginx/apache as reverse proxy with SSL
```

### 2. Reverse Proxy (Recommended)

Example nginx configuration:

```nginx
server {
    listen 80;
    server_name airflow.yourdomain.com;

    location / {
        return 301 https://$server_name$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name airflow.yourdomain.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 3. Systemd Service (Auto-start on Boot)

Create `/etc/systemd/system/airflow.service`:

```ini
[Unit]
Description=Apache Airflow
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/path/to/airflow_local
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
User=your_user
Group=your_group

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable airflow
sudo systemctl start airflow
```

### 4. Automated Backups

Create backup script `/usr/local/bin/backup-airflow.sh`:

```bash
#!/bin/bash
BACKUP_DIR="/backups/airflow"
RETENTION_DAYS=30

mkdir -p "$BACKUP_DIR"
cd /path/to/airflow_local

# Backup database
just backup

# Backup DAGs, plugins, config
tar -czf "$BACKUP_DIR/airflow-files-$(date +%Y%m%d).tar.gz" dags plugins config

# Clean old backups
find "$BACKUP_DIR" -name "*.sql" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete
```

Add to crontab:

```bash
# Daily backup at 2 AM
0 2 * * * /usr/local/bin/backup-airflow.sh
```

### 5. Monitoring

```bash
# Check service status
just status

# Monitor resource usage
just stats

# View logs
just logs

# Check worker status
just monitor-workers
```

## Maintenance Tasks

### Update Airflow

```bash
# Pull latest changes
git pull

# Update and restart
just update
```

### Scale Workers

```bash
# Scale to 3 workers
docker compose up -d --scale airflow-worker=3
```

### Database Maintenance

```bash
# Vacuum database (run periodically)
just shell
airflow db clean --clean-before-timestamp "$(date -d '30 days ago' '+%Y-%m-%d')"
exit
```

### Log Rotation

Add to `/etc/logrotate.d/airflow`:

```
/path/to/airflow_local/logs/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    missingok
    copytruncate
}
```

## Troubleshooting

### Services won't start

```bash
# Check Docker daemon
sudo systemctl status docker

# Check logs
just logs

# Check disk space
df -h

# Check memory
free -h
```

### Permission errors

```bash
# Fix permissions
sudo chown -R $(id -u):$(id -g) /path/to/airflow_local
chmod -R 755 logs dags plugins config
```

### Network issues

```bash
# Check port availability
sudo netstat -tlnp | grep -E '8080|5555'

# Check Docker network
docker network ls
docker network inspect airflow_local_default
```

### Database connection issues

```bash
# Check PostgreSQL
docker compose exec postgres psql -U airflow -c '\l'

# Reset database (WARNING: loses data)
just down-volumes
just up-init
```

## Security Checklist

- [ ] Changed default admin password
- [ ] Generated secure Fernet and secret keys
- [ ] Configured firewall rules
- [ ] Set up SSL/TLS (nginx/apache)
- [ ] Restricted database access
- [ ] Enabled authentication for Flower
- [ ] Regular backups configured
- [ ] Log rotation configured
- [ ] Monitoring set up
- [ ] Updated Docker images regularly

## Quick Command Reference

```bash
# Start
just up

# Stop
just down

# Restart
just restart

# Logs
just logs

# Shell
just shell

# Status
just status

# Backup
just backup

# Update
just update
```
