# Rythmify Monitoring Stack

## Overview

Full observability stack for the Rythmify platform running on VM1 (`rythmify-app-vm`). Covers backend API health, system resources, database connectivity, public uptime, and Nginx traffic — with email alerting via Gmail when anything goes wrong.

Components: **Prometheus** · **Grafana** · **Alertmanager** · **Blackbox Exporter** · **Nginx Exporter** · **Postgres Exporter** · **Node Exporter**

---

## Architecture

```
                        ┌─────────────────────────────────────────┐
                        │  VM1 — Docker monitoring stack           │
                        │                                          │
  ┌──────────────┐      │  ┌───────────┐    ┌──────────────────┐  │
  │ Backend      │◄─────┼──│ Prometheus│───►│ Grafana          │  │
  │ :8080/metrics│      │  │ :9090     │    │ :3000            │  │
  └──────────────┘      │  └─────┬─────┘    │ /grafana/ proxy  │  │
                        │        │           └──────────────────┘  │
  ┌──────────────┐      │        │           ┌──────────────────┐  │
  │ Node Exporter│◄─────┼────────┤           │ Alertmanager     │  │
  │ :9100        │      │        │           │ :9093            │  │
  └──────────────┘      │        │           │ Gmail SMTP       │  │
                        │        │           └──────────────────┘  │
  ┌──────────────┐      │        │                                  │
  │ Nginx        │◄─────┼────────┤  ┌──────────────────────────┐  │
  │ stub_status  │      │        │  │ Blackbox Exporter :9115   │  │
  │ 172.17.0.1   │      │        ├──┤ probes public HTTPS URLs  │  │
  │ :8081        │      │        │  └──────────────────────────┘  │
  └──────────────┘      │        │                                  │
                        │        │  ┌──────────────────────────┐  │
  ┌──────────────┐      │        └──┤ Postgres Exporter :9187   │  │
  │ PostgreSQL   │◄─────┼───────────┤ connects to VM2 :5432    │  │
  │ VM2:5432     │      │           └──────────────────────────┘  │
  └──────────────┘      └─────────────────────────────────────────┘
```

---

## Stack

### Prometheus

Scrapes all targets every 15 seconds. Evaluates alert rules from `prometheus/alert_rules.yml`.

Targets:

| Job | Target | What it scrapes |
|---|---|---|
| `backend_metrics` | `host.docker.internal:8080/metrics` | Backend API metrics |
| `node_exporter` | `node_exporter:9100` | VM1 CPU, memory, disk |
| `nginx` | `nginx-exporter:9113` | Nginx connection stats |
| `postgres_exporter` | `postgres_exporter:9187` | PostgreSQL health and query stats |
| `blackbox` | `blackbox_exporter:9115` | Public HTTPS probes |
| `prometheus` | `prometheus:9090` | Prometheus self-metrics |

### Grafana

Dashboards at: **https://rythmify-back.duckdns.org/grafana/**

Login with `GRAFANA_ADMIN_PASSWORD` from `monitoring/.env.monitoring`. No SSH tunnel needed — Nginx proxies `/grafana/` to port 3000.

Provisioned dashboards:

| Dashboard | What it shows |
|---|---|
| Backend API | Request rate, error rate, latency, active connections |
| PostgreSQL Health | DB connections, query duration, rows fetched/inserted |
| Uptime & Availability | Blackbox probe success, TLS certificate expiry |
| Node Exporter Full | VM CPU, memory, disk I/O, network |
| NGINX Exporter | Active connections, requests per second, handled vs accepted |

### Alertmanager

Sends email alerts via Gmail SMTP (port 587, STARTTLS). Recipient is configured in `ALERT_EMAIL_TO` in `.env.monitoring`.

See [Alerting](#alerting) for the full list of alert rules.

### Blackbox Exporter

Probes the following public HTTPS endpoints every 15 seconds (via Prometheus relabeling):

- `https://rythmify-back.duckdns.org/health` — backend liveness
- `https://rythmify.duckdns.org` — frontend availability

A probe is considered failed when the HTTP response is not 2xx or when TLS handshake fails.

### Postgres Exporter

Connects to VM2 at `10.0.1.4:5432` as `rythmify_admin`. The `pg_monitor` role must be granted:

```sql
GRANT pg_monitor TO rythmify_admin;
```

Exposes PostgreSQL metrics at `:9187/metrics`, scraped by Prometheus.

### Nginx Exporter

Scrapes Nginx stub_status at `http://172.17.0.1:8081/nginx_status`. This endpoint is defined in `nginx/rythmify-back.duckdns.org.conf` as a dedicated server block bound to the Docker bridge host IP — reachable from Docker containers but not from the public internet.

Verify the endpoint is reachable from the VM:

```bash
curl -s http://172.17.0.1:8081/nginx_status
```

### Node Exporter

Collects VM1 system metrics: CPU usage, memory, disk space, disk I/O, and network traffic. Runs as a Docker container and exports on port 9100.

---

## Setup

**1. Copy the example env file**

```bash
cp monitoring/.env.monitoring.example monitoring/.env.monitoring
```

**2. Fill in all values**

Edit `monitoring/.env.monitoring`. Required values:

- `GRAFANA_ADMIN_PASSWORD` — Grafana admin login password
- `SMTP_USER` / `SMTP_PASSWORD` — Gmail account and App Password for Grafana SMTP
- `GF_SMTP_FROM_ADDRESS` — sender address shown in alert emails
- `ALERT_EMAIL_TO` — recipient for all alert emails
- `ALERTMANAGER_SMTP_PASSWORD` — Gmail App Password used by Alertmanager directly
- `POSTGRES_PASSWORD` — `rythmify_admin` database password

Do not commit `monitoring/.env.monitoring` to git.

**3. Start the stack**

```bash
docker compose -f docker-compose.monitoring.yml --env-file monitoring/.env.monitoring up -d
```

**4. Verify**

```bash
# All containers running
docker ps

# All Prometheus targets healthy
curl http://localhost:9090/api/v1/targets
```

---

## Environment Variables

All variables are defined in `monitoring/.env.monitoring.example`:

| Variable | Description |
|---|---|
| `GRAFANA_ADMIN_USER` | Grafana admin username (default: `admin`) |
| `GRAFANA_ADMIN_PASSWORD` | Grafana admin password |
| `GF_SMTP_ENABLED` | Enable Grafana SMTP (set to `true`) |
| `SMTP_HOST` | SMTP server and port (e.g. `smtp.gmail.com:587`) |
| `SMTP_USER` | Gmail address used as sender |
| `SMTP_PASSWORD` | Gmail App Password for Grafana SMTP |
| `GF_SMTP_FROM_ADDRESS` | From address in Grafana alert emails |
| `GF_SMTP_FROM_NAME` | From name in Grafana alert emails |
| `ALERT_EMAIL_TO` | Email address that receives alerts |
| `ALERTMANAGER_SMTP_PASSWORD` | Gmail App Password for Alertmanager |
| `POSTGRES_PASSWORD` | PostgreSQL password for `rythmify_admin` |

Generate a Gmail App Password at https://myaccount.google.com/apppasswords. Do not use special characters (`/`, `&`, `@`, `$`) in the Alertmanager password — `envsubst` will break on them. Gmail App Passwords (16 lowercase letters) are safe by default.

---

## Alerting

Seven alert rules are defined in `monitoring/prometheus/alert_rules.yml`:

| Alert | Condition | Severity | Fires after |
|---|---|---|---|
| `BackendDown` | `up{job="backend_metrics"} == 0` | critical | 2 min |
| `PostgresDown` | `pg_up == 0` | critical | 2 min |
| `PublicEndpointDown` | `probe_success{job="blackbox"} == 0` | critical | 2 min |
| `HighErrorRate` | HTTP 4xx/5xx rate > 5% of total requests | warning | 5 min |
| `HighMemoryUsage` | Available memory < 15% of total | warning | 5 min |
| `HighCPUUsage` | CPU idle < 15% (i.e. usage > 85%) | warning | 5 min |
| `DiskSpaceLow` | Disk usage > 85% on any non-tmpfs filesystem | warning | 5 min |

All alerts are routed through Alertmanager to the email address in `ALERT_EMAIL_TO`.

---

## Accessing Grafana

**URL:** https://rythmify-back.duckdns.org/grafana/

Nginx on VM1 proxies `/grafana/` to Grafana on port 3000. No SSH tunnel or port forwarding is needed — the proxy is already configured in `nginx/rythmify-back.duckdns.org.conf`.

Login credentials:
- **Username:** value of `GRAFANA_ADMIN_USER` in `.env.monitoring` (default: `admin`)
- **Password:** value of `GRAFANA_ADMIN_PASSWORD` in `.env.monitoring`

---

## Troubleshooting

**`backend_metrics` target is down**
Verify the backend container is running and listening: `curl http://localhost:8080/metrics` on VM1.

**`nginx` target is down**
Check that the stub_status endpoint is reachable: `curl -s http://172.17.0.1:8081/nginx_status`. If it returns nothing, confirm Nginx is running (`sudo systemctl status nginx`) and the `listen 172.17.0.1:8081` block is active in the Nginx config.

**`postgres_exporter` target is down**
Verify VM2 is reachable from VM1: `nc -zv 10.0.1.4 5432`. Confirm `rythmify_admin` has the `pg_monitor` role.

**Blackbox targets are down**
Run `curl -I https://rythmify-back.duckdns.org/health` from VM1. Check that the SSL certificate is valid and not expired (`sudo certbot certificates`).

**Grafana email alerts not sending**
Verify `GF_SMTP_ENABLED=true`, `SMTP_HOST=smtp.gmail.com:587`, `SMTP_USER`, and `SMTP_PASSWORD` in `.env.monitoring`. Use an App Password, not your Google account password.

**`host.docker.internal` not resolving in Prometheus**
Confirm `docker-compose.monitoring.yml` includes `extra_hosts: - "host.docker.internal:host-gateway"` on the Prometheus service.
