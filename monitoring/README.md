# Rythmify Monitoring

This stack runs Prometheus, Grafana, node_exporter, nginx_exporter, and blackbox_exporter on the Dir 2 VM.

## Architecture

- Prometheus scrapes every 15 seconds.
- Backend app metrics are scraped from `host.docker.internal:8080/metrics`.
- VM CPU, memory, and disk metrics come from `node_exporter`.
- Nginx metrics come from `nginx_exporter`, which reads `http://host.docker.internal/nginx_status`.
- Public uptime checks are run through `blackbox_exporter` for:
  - `http://rythmify.duckdns.org/`
  - `http://rythmify-back.duckdns.org/`
  - `http://rythmify-back.duckdns.org/metrics`
- Grafana provisions Prometheus as the default data source and email alerts for core health signals.

## VM Access

```powershell
ssh -i "C:\Users\alaba\OneDrive\Desktop\rythmify-app-vm_key.pem" rythmify@20.196.3.253
```

## Nginx stub_status

Add this location to the Nginx server block that listens on localhost:

```nginx
location /nginx_status {
    stub_status;
    allow 127.0.0.1;
    allow 172.16.0.0/12;
    allow 172.17.0.0/16;
    deny all;
}
```

Validate and reload Nginx:

```bash
sudo nginx -t
sudo systemctl reload nginx
curl http://localhost/nginx_status
```

## Environment

Create a runtime environment file from the example:

```bash
cp monitoring/.env.monitoring.example .env.monitoring
```

Edit `.env.monitoring` and replace `SMTP_PASSWORD` with a Gmail app password. Do not commit `.env.monitoring`.

## Docker Commands

Start the stack:

```bash
docker compose --env-file .env.monitoring -f docker-compose.monitoring.yml up -d
```

Check containers:

```bash
docker compose --env-file .env.monitoring -f docker-compose.monitoring.yml ps
```

View logs:

```bash
docker compose --env-file .env.monitoring -f docker-compose.monitoring.yml logs -f prometheus grafana
```

Restart after config changes:

```bash
docker compose --env-file .env.monitoring -f docker-compose.monitoring.yml restart prometheus grafana
```

Stop the stack:

```bash
docker compose --env-file .env.monitoring -f docker-compose.monitoring.yml down
```

## Verification

```bash
curl http://localhost:9090/-/ready
curl http://localhost:9115/-/healthy
curl http://localhost/nginx_status
curl http://localhost:9090/api/v1/targets
```

Open Grafana:

```text
http://20.196.3.253:3000
```

Default credentials are configured through `.env.monitoring`.

## Alerts

Grafana provisions alerts for:

- backend down
- high CPU
- high memory
- disk full
- high backend error rate
- high backend latency
- public endpoint down

## Troubleshooting

- If `backend_metrics` is down, verify the backend is listening on VM port `8080` and `curl http://localhost:8080/metrics` works on the VM.
- If `nginx_exporter` is down, verify `curl http://localhost/nginx_status` works on the VM and that the Nginx allow list includes Docker bridge ranges.
- If blackbox targets are down, run `curl -I` against each public URL from the VM.
- If Grafana email alerts do not send, verify `GF_SMTP_ENABLED=true`, `SMTP_HOST`, `SMTP_USER`, and the app password in `.env.monitoring`.
- If Prometheus cannot resolve `host.docker.internal`, confirm the compose services include `extra_hosts: host.docker.internal:host-gateway` and the host has a recent Docker Engine.
