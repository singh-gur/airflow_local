# Monitoring

For production monitoring, the docker-compose.prod.yaml file includes optional Prometheus and Grafana services.

## Quick Start

```bash
# Start Airflow with monitoring
docker compose -f docker-compose.prod.yaml --profile monitoring up -d
```

## Access

- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000

## Configuration

Prometheus and Grafana are configured to automatically:
- Collect metrics from Airflow via StatsD
- Provide pre-configured datasources
- Support custom dashboards

## Custom Configuration

To customize monitoring:

1. Create `prometheus.yml` in this directory for Prometheus config
2. Create `grafana/provisioning/` for Grafana dashboards and datasources

See the official documentation:
- [Prometheus Configuration](https://prometheus.io/docs/prometheus/latest/configuration/configuration/)
- [Grafana Provisioning](https://grafana.com/docs/grafana/latest/administration/provisioning/)
