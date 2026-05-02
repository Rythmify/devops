# Rythmify DevOps

Infrastructure, CI/CD, Docker, Azure deployment, Nginx, and monitoring for the Rythmify platform.

---

## Overview

This repository manages everything that keeps Rythmify running: containerization for local development, GitHub Actions pipelines for CI/CD, Nginx virtual host configuration for both public domains, and the full Prometheus/Grafana/Alertmanager monitoring stack deployed on Azure VMs.

---

## Repository Structure

```
devops/
├── .github/
│   └── workflows/          # GitHub Actions CI/CD pipelines
├── docker/                 # Docker Compose files for backend and frontend stacks
├── monitoring/             # Prometheus, Grafana, Alertmanager, Blackbox configs
├── nginx/                  # Nginx virtual host configs and GeoIP setup for VM1
├── scripts/                # Deployment and utility scripts (bash + PowerShell)
├── docs/                   # Operational guides
├── environments/           # .env.example templates (never commit filled .env files)
└── docker-compose.monitoring.yml  # Monitoring stack compose file
```

| Folder | Description |
|---|---|
| `.github/workflows/` | GitHub Actions pipelines — validates repo structure on PRs to `main` |
| `docker/` | Docker Compose files (`docker-compose.yml`, `docker-compose.backend.yml`, `docker-compose.frontend.yml`) and Dockerfiles |
| `monitoring/` | Full observability stack config — Prometheus rules, Grafana dashboards, Alertmanager templates, Blackbox module config |
| `nginx/` | Nginx virtual host configs for `rythmify.duckdns.org` and `rythmify-back.duckdns.org`, GeoIP2 setup |
| `scripts/` | `build`, `start`, `stop`, `migrate`, `seed`, `clean` — available in both `.sh` (Linux/Mac) and `.ps1` (Windows) |
| `docs/` | Operational guides — local setup, VM operations |
| `environments/` | `.env.example` templates for local development |

---

## Quick Start

**Prerequisites:** Docker Desktop, Git.

```bash
# Clone the repo
git clone <devops-repo-url>
cd devops

# Copy and fill the environment file
cp environments/.env.example environments/.env
# Edit environments/.env with your values

# Build images
./scripts/build.sh          # Linux/Mac
.\scripts\build.ps1         # Windows

# Start everything
./scripts/start.sh          # Linux/Mac
.\scripts\start.ps1         # Windows
```

Services after `start`:

| Service | URL |
|---|---|
| Backend API | http://localhost:8080/api/v1 |
| Frontend | http://localhost:5173 |
| pgAdmin | http://localhost:5050 |
| Azurite (blob storage) | http://localhost:10000 |

See [docs/setup-guide.md](docs/setup-guide.md) for the full first-time setup walkthrough including blob container creation and database migrations.

---

## Environments

| Environment | Branch | Approval |
|---|---|---|
| Development | any feature branch | none — auto on push |
| Production | `main` | manual approval gate via GitHub Environment protection rule |

Deployments are triggered by `.github/workflows/devops.yml`. Production deploys require a reviewer to approve the job in the GitHub Actions UI before it runs.

---

## Secrets Required

The following secrets must be configured in the GitHub repository or org settings. Production secrets go under the **production** GitHub Environment; org-level secrets are shared across environments.

| Secret | Where | Description |
|---|---|---|
| `ACR_USERNAME` | Org or repo | Azure Container Registry username |
| `ACR_PASSWORD` | Org or repo | Azure Container Registry password |
| `AZURE_CREDENTIALS` | Org or repo | Service principal JSON for `az login` |
| `AZURE_RESOURCE_GROUP` | Org or repo | Resource group name (`rythmify-rg`) |
| `AZURE_SUBSCRIPTION_ID` | Org or repo | Azure subscription ID |
| `POSTGRES_PASSWORD` | Production env | PostgreSQL password for `rythmify_admin` |
| `ALERTMANAGER_SMTP_PASSWORD` | Production env | Gmail App Password for Alertmanager email alerts |
| `GRAFANA_ADMIN_PASSWORD` | Production env | Grafana admin login password |

To add a secret: **GitHub repo → Settings → Secrets and variables → Actions → New repository secret** (or org-level for shared secrets).

---

## Links

- [Nginx config guide](nginx/README.md) — GeoIP setup, stub_status on 172.17.0.1:8081, Grafana proxy, SSL, deployment
- [Monitoring stack guide](monitoring/README.md) — Prometheus, Grafana, Alertmanager, alert rules, env vars
- [Local development setup](docs/setup-guide.md) — first-time setup, scripts reference, blob containers
- [VM operations guide](docs/vm-guide.md) — SSH access, common commands, security notes
