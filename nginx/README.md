# Nginx Reverse Proxy Configuration

This directory contains the Nginx configuration for securing Airflow with SSL/TLS termination.

## Setup

### 1. Generate SSL Certificates

For production, obtain certificates from a trusted CA (Let's Encrypt, etc.):

```bash
# Using Let's Encrypt (certbot)
sudo certbot certonly --standalone -d your-domain.com

# Copy certificates
cp /etc/letsencrypt/live/your-domain.com/fullchain.pem nginx/ssl/cert.pem
cp /etc/letsencrypt/live/your-domain.com/privkey.pem nginx/ssl/key.pem
```

For testing/development, generate self-signed certificates:

```bash
mkdir -p nginx/ssl

# Generate self-signed certificate (valid for 365 days)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout nginx/ssl/key.pem \
    -out nginx/ssl/cert.pem \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
```

### 2. Update nginx.conf

Edit `nginx/nginx.conf` and update:

- `server_name`: Replace `_` with your domain name
- SSL certificate paths (if different)
- Rate limiting rules
- Security headers

### 3. Start with Nginx Proxy

```bash
# Start Airflow with nginx proxy
docker compose -f docker-compose.prod.yaml --profile proxy up -d

# Access Airflow
# HTTP: http://your-domain.com (redirects to HTTPS)
# HTTPS: https://your-domain.com
```

## Features

### Security

- **SSL/TLS Termination**: Encrypts all traffic
- **HSTS**: Enforces HTTPS
- **Security Headers**: Protects against common attacks
- **Rate Limiting**: Prevents abuse (10 req/s per IP)
- **Connection Limiting**: Max 10 concurrent connections per IP

### Performance

- **HTTP/2**: Faster page loads
- **Gzip Compression**: Reduces bandwidth
- **Static File Caching**: Caches assets for 7 days
- **Keep-Alive Connections**: Reduces overhead

### High Availability

- **Upstream Load Balancing**: Least connections algorithm
- **Health Checks**: Automatic failover
- **Connection Pooling**: Reuses connections

## Monitoring

View Nginx logs:

```bash
# Access logs
docker compose -f docker-compose.prod.yaml logs nginx

# Real-time logs
docker compose -f docker-compose.prod.yaml logs -f nginx
```

## Troubleshooting

### SSL Certificate Errors

```bash
# Verify certificate
openssl x509 -in nginx/ssl/cert.pem -text -noout

# Test SSL configuration
docker compose -f docker-compose.prod.yaml exec nginx nginx -t
```

### Connection Refused

```bash
# Check if webserver is running
docker compose -f docker-compose.prod.yaml ps airflow-webserver

# Test upstream connection
docker compose -f docker-compose.prod.yaml exec nginx curl http://airflow-webserver:8080/health
```

### Rate Limiting Issues

Adjust rate limits in `nginx.conf`:

```nginx
# Increase rate limit to 50 req/s
limit_req_zone $binary_remote_addr zone=airflow_limit:10m rate=50r/s;
```

## Advanced Configuration

### Custom Domain

Update `nginx.conf`:

```nginx
server {
    listen 443 ssl http2;
    server_name airflow.example.com;
    # ... rest of config
}
```

### Basic Authentication

Add basic auth layer:

```bash
# Install htpasswd utility in nginx container
docker compose -f docker-compose.prod.yaml exec nginx sh -c "apk add apache2-utils"

# Create password file
docker compose -f docker-compose.prod.yaml exec nginx htpasswd -c /etc/nginx/.htpasswd admin
```

Update `nginx.conf`:

```nginx
location / {
    auth_basic "Restricted Access";
    auth_basic_user_file /etc/nginx/.htpasswd;
    proxy_pass http://airflow_webserver;
}
```

### Load Balancing Multiple Webservers

Update upstream in `nginx.conf`:

```nginx
upstream airflow_webserver {
    least_conn;
    server airflow-webserver-1:8080 max_fails=3 fail_timeout=30s;
    server airflow-webserver-2:8080 max_fails=3 fail_timeout=30s;
    server airflow-webserver-3:8080 max_fails=3 fail_timeout=30s;
    keepalive 32;
}
```
