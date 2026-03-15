# 🎵 Rythmify — DevOps Repository

> **Rythmify** is a university software engineering project — a SoundCloud-like music streaming platform. This repository contains all DevOps infrastructure, CI/CD pipelines, containerization configuration, environment management, monitoring plans, and deployment strategies that support the development lifecycle.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [DevOps Architecture Overview](#2-devops-architecture-overview)
3. [Repository Structure Explanation](#3-repository-structure-explanation)
4. [Local Development Workflow](#4-local-development-workflow)
5. [CI/CD Strategy — GitHub Actions](#5-cicd-strategy--github-actions)
6. [Containerization Strategy — Docker](#6-containerization-strategy--docker)
7. [Environment Configuration](#7-environment-configuration)
8. [Monitoring Plan — Grafana (Future Phase)](#8-monitoring-plan--grafana-future-phase)
9. [Future Deployment Architecture — Azure](#9-future-deployment-architecture--azure)
10. [Quick Start for Developers](#10-quick-start-for-developers)

---

## 1. Project Overview

**Rythmify** is a music streaming web platform inspired by SoundCloud, enabling users to upload, stream, discover, and interact with music content. The system is built with a decoupled frontend/backend architecture and is designed for scalability through cloud deployment in later phases.

| Attribute         | Detail                                    |
| ----------------- | ----------------------------------------- |
| **Project Type**  | University Software Engineering Capstone  |
| **Domain**        | Music Streaming Platform                  |
| **Architecture**  | Frontend + Backend + Database (decoupled) |
| **Current Phase** | Local Development                         |
| **Future Phases** | Cloud deployment on Microsoft Azure       |

### DevOps Stack at a Glance

| Category                | Technology                    |
| ----------------------- | ----------------------------- |
| CI/CD                   | GitHub Actions                |
| Containerization        | Docker & Docker Compose       |
| Cloud Provider (future) | Microsoft Azure               |
| Database (future)       | Azure Database for PostgreSQL |
| File Storage (future)   | Azure Blob Storage            |
| Monitoring (future)     | Grafana                       |

---

## 2. DevOps Architecture Overview

The DevOps pipeline for Rythmify is structured around three progressive phases:

```
┌─────────────────────────────────────────────────────────────────┐
│                        PHASE 1 — CURRENT                        │
│                      Local Development                          │
│                                                                 │
│   Developer ──► Docker Compose ──► Backend + Frontend (local)  │
│                      │                                          │
│                  GitHub Actions                                 │
│              (CI: Lint, Test, Build)                            │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                     PHASE 2 — FUTURE                            │
│                    Azure Deployment                             │
│                                                                 │
│   GitHub Actions ──► Build & Push Images                        │
│         │                                                       │
│         └──► Azure App Service (Backend + Frontend)             │
│              Azure PostgreSQL (Database)                        │
│              Azure Blob Storage (Media Files)                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                     PHASE 3 — FUTURE                            │
│                  Monitoring & Observability                      │
│                                                                 │
│   Grafana Dashboards ◄── Metrics, Logs & Alerts                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. Repository Structure Explanation

```
C:.
├── .gitignore
├── README.md
│
├── .github/
│   ├── CODEOWNERS
│   └── workflows/
│       ├── backend-ci.yml
│       ├── deploy.yml
│       ├── frontend-ci.yml
│       └── mobile-ci.yml
│
├── docker/
│   ├── docker-compose.yml
│   ├── backend/
│   │   └── Dockerfile
│   └── frontend/
│       └── Dockerfile
│
├── docs/
│   ├── deployment-guide.md
│   ├── infrastructure-overview.md
│   └── system-architecture.md
│
├── environments/
│   ├── .env.example
│   ├── dev.env
│   ├── production.env
│   └── staging.env
│
├── monitoring/
│   ├── alerts.md
│   ├── grafana.md
│   └── logs.md
│
└── scripts/
    ├── build.ps1
    ├── build.sh
    ├── deploy.ps1
    ├── deploy.sh
    ├── test.ps1
    └── test.sh
```

### Directory Breakdown

#### `.github/`

Contains all GitHub-specific configuration for the repository.

| File / Folder               | Purpose                                                                                                                                                          |
| --------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `CODEOWNERS`                | Defines which team members are responsible for reviewing changes to specific parts of the codebase. Ensures the right people are auto-assigned to pull requests. |
| `workflows/backend-ci.yml`  | GitHub Actions pipeline triggered on backend code changes. Runs linting, unit tests, and build validation.                                                       |
| `workflows/frontend-ci.yml` | GitHub Actions pipeline triggered on frontend code changes. Runs linting, component tests, and build checks.                                                     |
| `workflows/mobile-ci.yml`   | GitHub Actions pipeline for any mobile client code. Mirrors the frontend CI structure for the mobile platform.                                                   |
| `workflows/deploy.yml`      | Deployment workflow (initially a stub). Will orchestrate building Docker images and deploying to Azure in future phases.                                         |

---

#### `docker/`

Centralizes all containerization configuration for the Rythmify platform.

| File / Folder         | Purpose                                                                                                                                                                      |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `docker-compose.yml`  | Orchestrates the full local development environment. Defines services (backend, frontend), networking between containers, volume mounts, and environment variable injection. |
| `backend/Dockerfile`  | Defines the Docker image for the backend service — base image, dependency installation, build steps, and the runtime command.                                                |
| `frontend/Dockerfile` | Defines the Docker image for the frontend service — Node.js build stage, static asset generation, and serving configuration.                                                 |

---

#### `docs/`

Houses human-readable documentation for infrastructure and system design decisions.

| File                         | Purpose                                                                                                                               |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| `system-architecture.md`     | High-level description of how the frontend, backend, database, and storage components interact. Useful for onboarding new developers. |
| `infrastructure-overview.md` | Documents the infrastructure stack — what tools are used, why they were chosen, and how they fit together.                            |
| `deployment-guide.md`        | Step-by-step instructions for deploying the system, both locally and (in future phases) to Azure.                                     |

---

#### `environments/`

Manages environment-specific configuration variables across all deployment stages.

| File             | Purpose                                                                                                                                                                                       |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `.env.example`   | A template file showing all required environment variables with placeholder values. Committed to version control. New developers copy this to create their local `.env`.                      |
| `dev.env`        | Environment variables for local development (e.g., local DB URLs, debug flags, mock storage paths).                                                                                           |
| `staging.env`    | Variables for the staging environment, pointing to staging Azure resources. Used for pre-production validation.                                                                               |
| `production.env` | Variables for the production environment. Contains references to live Azure services. **Secrets must never be stored in plain text — use Azure Key Vault or GitHub Secrets in later phases.** |

> ⚠️ **Security Note:** `.env` files containing real credentials must be listed in `.gitignore` and should never be committed to version control.

---

#### `monitoring/`

Documents the monitoring and observability strategy for the platform (to be implemented in a future phase).

| File         | Purpose                                                                                                                                        |
| ------------ | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| `grafana.md` | Describes the planned Grafana dashboard setup — which metrics to visualize, how to connect Grafana to the backend, and dashboard layout plans. |
| `alerts.md`  | Defines alerting rules and thresholds — what conditions should trigger alerts, who gets notified, and via which channels (email, Slack, etc.). |
| `logs.md`    | Describes the logging strategy — log formats, log levels, which services emit logs, and how logs will be aggregated and queried.               |

---

#### `scripts/`

Cross-platform automation scripts for common DevOps tasks. Each action has both a Bash (`.sh`) version for Linux/macOS and a PowerShell (`.ps1`) version for Windows.

| Script                     | Purpose                                                                                            |
| -------------------------- | -------------------------------------------------------------------------------------------------- |
| `build.sh` / `build.ps1`   | Builds Docker images for the backend and frontend services.                                        |
| `deploy.sh` / `deploy.ps1` | Triggers a deployment (currently a stub; will deploy to Azure in future phases).                   |
| `test.sh` / `test.ps1`     | Runs the test suite across all services — useful for pre-commit validation or local CI simulation. |

---

## 4. Local Development Workflow

In the current phase, Rythmify runs entirely on a developer's local machine via Docker Compose.

```
Developer Workstation
│
├── Edits source code in the main application repositories
│
├── Runs: docker-compose up --build
│          │
│          ├── Starts Backend container  (port 8000)
│          └── Starts Frontend container (port 3000)
│
└── Accesses app at http://localhost:3000
```

### Workflow Steps

1. **Clone** this DevOps repository alongside the application repositories.
2. **Copy** `environments/.env.example` to `environments/dev.env` and fill in local values.
3. **Build & start** all services using Docker Compose:
   ```bash
   docker-compose -f docker/docker-compose.yml --env-file environments/dev.env up --build
   ```
4. **Develop** — changes to application code can be reflected via volume mounts (hot reload).
5. **Test** locally before pushing:

   ```bash
   # Linux / macOS
   bash scripts/test.sh

   # Windows
   .\scripts\test.ps1
   ```

6. **Push** to a feature branch — CI pipelines trigger automatically.

---

## 5. CI/CD Strategy — GitHub Actions

GitHub Actions powers the automated CI/CD pipeline. Workflows are triggered on push and pull request events.

### Pipeline Overview

```
Push / Pull Request
       │
       ▼
┌─────────────────────────────────────────┐
│             GitHub Actions              │
│                                         │
│  ┌──────────────┐  ┌─────────────────┐  │
│  │  backend-ci  │  │  frontend-ci    │  │
│  │              │  │                 │  │
│  │  • Lint      │  │  • Lint         │  │
│  │  • Unit Test │  │  • Unit Test    │  │
│  │  • Build     │  │  • Build        │  │
│  └──────────────┘  └─────────────────┘  │
│                                         │
│  ┌──────────────┐  ┌─────────────────┐  │
│  │  mobile-ci   │  │  deploy (stub)  │  │
│  │              │  │                 │  │
│  │  • Lint      │  │  Future: Push   │  │
│  │  • Test      │  │  images to ACR  │  │
│  └──────────────┘  └─────────────────┘  │
└─────────────────────────────────────────┘
```

### Workflow Trigger Strategy

| Workflow          | Trigger                                   | Target Branch(es)                   |
| ----------------- | ----------------------------------------- | ----------------------------------- |
| `backend-ci.yml`  | Push / PR to paths matching `backend/**`  | `main`, `develop`, feature branches |
| `frontend-ci.yml` | Push / PR to paths matching `frontend/**` | `main`, `develop`, feature branches |
| `mobile-ci.yml`   | Push / PR to paths matching `mobile/**`   | `main`, `develop`, feature branches |
| `deploy.yml`      | Manual trigger / merge to `main`          | `main` only                         |

### Branch Protection

The `CODEOWNERS` file enforces code review requirements — designated owners must approve pull requests before merging into protected branches. This ensures accountability and knowledge sharing across the team.

---

## 6. Containerization Strategy — Docker

Docker is used to create consistent, reproducible environments across all developer machines and deployment targets.

### Service Architecture

```
docker-compose.yml
│
├── backend (service)
│   ├── Image: built from docker/backend/Dockerfile
│   ├── Port: 8000:8000
│   └── Env: injected from dev.env
│
└── frontend (service)
    ├── Image: built from docker/frontend/Dockerfile
    ├── Port: 3000:3000
    └── Depends on: backend
```

### Dockerfile Philosophy

| Service  | Base Image Strategy                                   | Build Approach                                 |
| -------- | ----------------------------------------------------- | ---------------------------------------------- |
| Backend  | Lightweight runtime image (e.g., `python:3.x-slim`)   | Install dependencies, copy source, expose port |
| Frontend | Multi-stage build (`node:lx-alpine` → `nginx:alpine`) | Build static assets, serve via Nginx           |

### Why Docker?

- **Consistency** — eliminates "works on my machine" issues across the team.
- **Isolation** — each service runs in its own container with its own dependencies.
- **Cloud-readiness** — the same images used locally can be pushed to Azure Container Registry (ACR) in future phases.
- **Onboarding speed** — new developers can run the full stack with a single command.

---

## 7. Environment Configuration

The `environments/` directory provides a structured approach to managing configuration across all deployment stages.

### Environment Hierarchy

| Environment | File             | Purpose                | Azure Resources            |
| ----------- | ---------------- | ---------------------- | -------------------------- |
| Development | `dev.env`        | Local machine          | None (local services)      |
| Staging     | `staging.env`    | Pre-production testing | Staging Azure instances    |
| Production  | `production.env` | Live user traffic      | Production Azure instances |

### Required Variables (see `.env.example`)

```env
# Application
APP_ENV=development
SECRET_KEY=your-secret-key-here
DEBUG=true

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/rythmify_db

# Storage
STORAGE_BUCKET=your-blob-storage-bucket
STORAGE_CONNECTION_STRING=your-connection-string

# API
API_BASE_URL=http://localhost:8000
```

### Security Guidelines

- Real credentials are **never** committed to version control.
- The `.env.example` file serves as the contract for required variables.
- In production, secrets will be managed through **Azure Key Vault** and injected via **GitHub Actions Secrets**.

---

## 8. Monitoring Plan — Grafana (Future Phase)

> 📌 **Status:** Planned for a future implementation phase. The `monitoring/` directory contains design documentation only.

Grafana will provide real-time observability into the Rythmify platform once deployed to Azure.

### Planned Dashboards

| Dashboard             | Metrics Tracked                                          |
| --------------------- | -------------------------------------------------------- |
| **System Health**     | CPU usage, memory, disk I/O per container/service        |
| **API Performance**   | Request rate, response times (p50/p95/p99), error rates  |
| **Streaming Metrics** | Active streams, bandwidth usage, buffering events        |
| **Database**          | Query latency, connection pool utilization, slow queries |
| **User Activity**     | Active sessions, uploads per hour, plays per track       |

### Alerting Strategy (defined in `monitoring/alerts.md`)

| Alert                 | Condition                 | Severity | Notification Channel |
| --------------------- | ------------------------- | -------- | -------------------- |
| High Error Rate       | HTTP 5xx > 5% for 5 min   | Critical | Email + Slack        |
| Slow API Response     | p95 latency > 2s          | Warning  | Slack                |
| Database Overload     | Connections > 80% of pool | Critical | Email                |
| Storage Near Capacity | Azure Blob > 85% used     | Warning  | Email                |

### Logging Strategy (defined in `monitoring/logs.md`)

- **Format:** Structured JSON logs for machine parseability.
- **Levels:** `DEBUG` (dev only), `INFO`, `WARNING`, `ERROR`, `CRITICAL`.
- **Aggregation:** Azure Monitor Logs / Log Analytics Workspace (future).
- **Retention:** 30 days for standard logs; 90 days for audit logs.

---

## 9. Future Deployment Architecture — Azure

> 📌 **Status:** Planned for a future implementation phase.

Once local development is stable, the platform will be deployed to Microsoft Azure.

### Target Architecture

```
                        ┌──────────────────────────────────┐
                        │         Microsoft Azure          │
                        │                                  │
  GitHub Actions  ────► │  Azure Container Registry (ACR)  │
  (deploy.yml)          │         (Docker Images)          │
                        │                                  │
                        │  ┌────────────────────────────┐  │
                        │  │    Azure App Service       │  │
                        │  │  ┌──────────┐ ┌─────────┐ │  │
                        │  │  │ Backend  │ │Frontend │ │  │
                        │  │  └────┬─────┘ └─────────┘ │  │
                        │  └───────┼────────────────────┘  │
                        │          │                        │
                        │  ┌───────▼──────────────────┐    │
                        │  │  Azure PostgreSQL DB      │    │
                        │  └──────────────────────────┘    │
                        │                                  │
                        │  ┌───────────────────────────┐   │
                        │  │  Azure Blob Storage       │   │
                        │  │  (Audio & Media Files)    │   │
                        │  └───────────────────────────┘   │
                        │                                  │
                        │  ┌───────────────────────────┐   │
                        │  │  Grafana (Monitoring)     │   │
                        │  └───────────────────────────┘   │
                        └──────────────────────────────────┘
```

### Azure Service Mapping

| Azure Service                      | Role in Rythmify                                                                    |
| ---------------------------------- | ----------------------------------------------------------------------------------- |
| **Azure App Service**              | Hosts the backend API and frontend web application as containerized services.       |
| **Azure Container Registry (ACR)** | Private registry for storing built Docker images pushed by GitHub Actions.          |
| **Azure Database for PostgreSQL**  | Managed relational database for user data, track metadata, playlists, and more.     |
| **Azure Blob Storage**             | Scalable object storage for audio files, album artwork, and other media assets.     |
| **Azure Key Vault**                | Secure storage for secrets, API keys, and connection strings — injected at runtime. |
| **Azure Monitor**                  | Platform-level metrics and log aggregation feeding into Grafana dashboards.         |

### Deployment Flow (Future)

```bash
# GitHub Actions deploy.yml will:

1. Build Docker images for backend and frontend
2. Push images to Azure Container Registry (ACR)
3. Pull new images into Azure App Service (rolling update)
4. Run database migrations (if applicable)
5. Health check the deployment endpoint
6. Notify team of success or failure
```

---

## 10. Quick Start for Developers

### Prerequisites

Ensure the following tools are installed on your machine:

| Tool           | Version | Purpose                                 |
| -------------- | ------- | --------------------------------------- |
| Git            | Latest  | Version control                         |
| Docker         | 24.x+   | Container runtime                       |
| Docker Compose | 2.x+    | Multi-container orchestration           |
| PowerShell     | 7.x+    | Windows script execution (Windows only) |

### Setup Instructions

```bash
# 1. Clone this DevOps repository
git clone https://github.com/your-org/rythmify-devops.git
cd rythmify-devops

# 2. Set up your local environment file
cp environments/.env.example environments/dev.env
# Edit dev.env with your local configuration values

# 3. Build and start all services
docker-compose -f docker/docker-compose.yml --env-file environments/dev.env up --build

# 4. Verify services are running
docker ps

# 5. Access the application
# Frontend:  http://localhost:3000
# Backend:   http://localhost:8000
# API Docs:  http://localhost:8000/docs
```

### Common Commands

```bash
# Start services (detached mode)
docker-compose -f docker/docker-compose.yml up -d

# Stop all services
docker-compose -f docker/docker-compose.yml down

# View logs for a specific service
docker-compose -f docker/docker-compose.yml logs -f backend

# Rebuild a single service after code changes
docker-compose -f docker/docker-compose.yml up --build backend

# Run tests locally (Linux/macOS)
bash scripts/test.sh

# Run tests locally (Windows)
.\scripts\test.ps1

# Run build scripts (Linux/macOS)
bash scripts/build.sh

# Run build scripts (Windows)
.\scripts\build.ps1
```

### Troubleshooting

| Issue                       | Solution                                                                          |
| --------------------------- | --------------------------------------------------------------------------------- |
| Port already in use         | Stop conflicting processes: `lsof -i :3000` or `lsof -i :8000`, then `kill <PID>` |
| Docker daemon not running   | Start Docker Desktop or run `sudo systemctl start docker`                         |
| `.env` file missing         | Copy `.env.example`: `cp environments/.env.example environments/dev.env`          |
| Container fails to start    | Check logs: `docker-compose logs <service-name>`                                  |
| Database connection refused | Ensure DB container is healthy: `docker ps` and check the `STATUS` column         |

---

## Contributing

1. Create a feature branch from `develop`: `git checkout -b feature/your-feature`
2. Make your changes and test locally using the scripts in `scripts/`.
3. Push your branch and open a Pull Request — CI pipelines will run automatically.
4. Request a review from the relevant `CODEOWNERS`.
5. Merge only after CI passes and reviews are approved.

---

## License

This project is developed for academic purposes as part of a university software engineering course.

---

_Maintained by the Rythmify DevOps Team._
