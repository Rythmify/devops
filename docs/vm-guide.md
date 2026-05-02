# Rythmify VM Operations Guide

Practical reference for navigating and operating the two Azure VMs that run the Rythmify platform.

---

## Overview

Two VMs in **Azure UAE North**, connected by a shared VNet (private subnet `10.0.1.0/24`).

| | VM1 — App | VM2 — Database |
|---|---|---|
| **Name** | `rythmify-app-vm` | `rythmify-db-vm` |
| **Public IP** | `20.196.3.253` | `20.233.118.212` |
| **Private IP** | `10.0.1.5` (VNet) | `10.0.1.4` |
| **Size** | B2s_v2 | B2als_v2 |
| **Runs** | Backend container, Redis, full monitoring stack, Nginx | PostgreSQL in Docker |

VM1 handles all public traffic. VM2 is database-only — PostgreSQL is not exposed publicly, only reachable from VM1 via the private VNet address `10.0.1.4:5432`.

---

## SSH Access

**VM1:**
```bash
ssh rythmify@20.196.3.253 -i rythmify-app-vm_key.pem
```

**VM2:**
```bash
ssh rythmify@20.233.118.212 -i rythmify-db-vm_key.pem
```

Never commit `.pem` key files to the repository. Store them locally and keep permissions restricted:

```bash
chmod 400 rythmify-app-vm_key.pem
chmod 400 rythmify-db-vm_key.pem
```

---

## VM1 Folder Structure

| Path | Description |
|---|---|
| `~/devops/` | Cloned DevOps repo — all container configs, compose files, and nginx configs live here |
| `~/devops/monitoring/.env.monitoring` | Monitoring stack secrets — never committed to git |
| `/etc/nginx/sites-available/rythmify-back.duckdns.org.conf` | Active backend Nginx config |
| `/etc/nginx/sites-available/rythmify.duckdns.org.conf` | Active frontend Nginx config |
| `/var/lib/GeoIP/` | MaxMind GeoLite2-Country database (`GeoLite2-Country.mmdb`) |
| `/var/www/rythmify/` | Frontend static files served by Nginx (if applicable) |

---

## Common VM1 Commands

### Container management

```bash
# Show all running containers with status and ports
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# View backend logs (last 50 lines)
docker logs rythmify-backend --tail 50

# Follow backend logs live
docker logs rythmify-backend -f

# Restart only the backend container
docker compose -f docker-compose.yml up -d --force-recreate backend

# Restart the full monitoring stack
docker compose -f docker-compose.monitoring.yml --env-file monitoring/.env.monitoring up -d

# Pull latest repo changes
cd ~/devops && git pull
```

### Nginx

```bash
# Test config syntax before applying
sudo nginx -t

# Reload Nginx (applies config changes with zero downtime)
sudo systemctl reload nginx

# Check Nginx status
sudo systemctl status nginx
```

### GeoIP

```bash
# Update the MaxMind GeoLite2-Country database
sudo geoipupdate

# Reload Nginx after database update
sudo systemctl reload nginx
```

---

## Common VM2 Commands

```bash
# Check PostgreSQL container is running
docker ps

# View PostgreSQL logs (last 50 lines)
docker logs <postgres-container-name> --tail 50

# Connect to the database
docker exec -it <postgres-container-name> psql -U rythmify_admin -d rythmify_db

# Grant pg_monitor role (required for postgres_exporter on VM1)
docker exec -it <postgres-container-name> psql -U rythmify_admin -d rythmify_db \
  -c "GRANT pg_monitor TO rythmify_admin;"
```

Replace `<postgres-container-name>` with the actual container name shown in `docker ps`.

---

## Monitoring Quick Checks

Run these from VM1 to verify the monitoring stack is healthy.

```bash
# All Prometheus targets — look for "health":"up" for each
curl -s http://localhost:9090/api/v1/targets | python3 -m json.tool | grep health

# Postgres exporter connected (should return pg_up 1)
curl -s http://localhost:9187/metrics | grep pg_up

# Blackbox probe success for backend health endpoint (should return probe_success 1)
curl -s "http://localhost:9115/probe?target=https://rythmify-back.duckdns.org/health&module=https_2xx" \
  | grep probe_success

# Nginx stub_status — confirms nginx_exporter can reach the endpoint
curl -s http://172.17.0.1:8081/nginx_status

# Grafana — open in browser (no SSH tunnel needed)
# https://rythmify-back.duckdns.org/grafana/
```

---

## Security Notes

**Azure NSG (Network Security Group) — VM1 inbound rules:**

| Port | Protocol | Access |
|---|---|---|
| 80 | TCP | Public — HTTP (redirected to HTTPS by Nginx) |
| 443 | TCP | Public — HTTPS |
| 22 | TCP | Restricted — SSH (limit to known IPs if possible) |
| All others | — | Denied |

Grafana (3000), Prometheus (9090), Alertmanager (9093), Redis, and the backend (8080) are internal only — they are **not** in the NSG allow list and are only accessible via Nginx proxy or SSH tunnel.

Never add monitoring ports (3000, 9090, 9093) to NSG public inbound rules.

---

## Updating the Nginx Config

The active Nginx config lives on the VM at `/etc/nginx/sites-available/`. The repo in `~/devops/nginx/` is the source of truth — always edit the repo file, then copy to the system path.

**Workflow:**

```bash
# 1. Pull latest repo changes
cd ~/devops && git pull

# 2. Copy updated configs to sites-available
sudo cp nginx/rythmify-back.duckdns.org.conf /etc/nginx/sites-available/
sudo cp nginx/rythmify.duckdns.org.conf      /etc/nginx/sites-available/

# 3. Test syntax
sudo nginx -t

# 4. Reload
sudo systemctl reload nginx
```

If you make a hotfix directly on the VM, copy it back to the repo and commit:

```bash
cp /etc/nginx/sites-available/rythmify-back.duckdns.org.conf ~/devops/nginx/
cp /etc/nginx/sites-available/rythmify.duckdns.org.conf      ~/devops/nginx/
cd ~/devops
git add nginx/
git commit -m "fix(nginx): <describe the change>"
git push
```
