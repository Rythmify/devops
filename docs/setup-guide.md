# Rythmify — Local Development Setup Guide

## Prerequisites

Before you can run Rythmify locally, you need to install the following tools:

### 1. Git

Download from: https://git-scm.com/downloads
Used to clone all repositories.

### 2. Docker Desktop

Download from: https://www.docker.com/products/docker-desktop
This is the most important tool — it runs all containers (Postgres, Azurite, Backend, Frontend).
After installing, make sure Docker Desktop is running before using any scripts.

**Recommended setting:** Go to Docker Desktop → Settings → General → Enable "Start Docker Desktop when you sign in to your computer"

### 3. Azure Storage Explorer

Download from: https://azure.microsoft.com/en-us/products/storage/storage-explorer
Used to visually inspect and manage Azurite blob containers (audio and media).

### 4. pgAdmin (Optional)

pgAdmin is already included as a Docker container — accessible at http://localhost:5050
No installation needed.

---

## Repository Setup

Clone all repositories side by side into the same parent folder:

```
Desktop/Rythmify/
  devops/
  backend/
  frontend/
  cross/
  testing/
```

```powershell
git clone <devops-repo-url>
git clone <backend-repo-url>
git clone <frontend-repo-url>
git clone <cross-repo-url>
git clone <testing-repo-url>
```

---

## Environment Configuration

Navigate to the DevOps repo and create your local environment file:

```powershell
cd devops
copy environments\.env.example environments\.env
```

Open `environments\.env` and fill in the required values. The following must be set correctly:

> **Important:** Never commit your `.env` file to git. It is already in `.gitignore`.

---

## Scripts Reference

All scripts are located in the `scripts/` folder and must be run from the DevOps repo root.

To allow PowerShell to run scripts, run this once:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

### build.ps1 — Build All Images

```powershell
.\scripts\build.ps1
```

**What it does:** Builds Docker images for the backend and frontend from their Dockerfiles. Downloads all base images (Node.js, Postgres, Azurite, pgAdmin).

**When to use:**

- First time setting up the project
- After pulling new changes that modify the Dockerfile
- After changing dependencies (package.json)

---

### start-infra.ps1 — Start Infrastructure Only

```powershell
.\scripts\start-infra.ps1
```

**What it does:** Starts Postgres, Azurite, and pgAdmin containers.

**When to use:**

- Backend developers who only need the database and blob storage running
- As the first step before starting backend or frontend

**Services started:**
| Service | URL |
|---|---|
| PostgreSQL | localhost:5433 |
| pgAdmin | http://localhost:5050 |
| Azurite | http://localhost:10000 |

---

### start-backend.ps1 — Start Backend Only

```powershell
.\scripts\start-backend.ps1
```

**What it does:** Starts the Node.js + Express backend container.

**When to use:** After infrastructure is running and you need the API running.

**Services started:**
| Service | URL |
|---|---|
| Backend API | http://localhost:8080/api/v1 |

---

### start-frontend.ps1 — Start Frontend Only

```powershell
.\scripts\start-frontend.ps1
```

**What it does:** Starts the React + Vite frontend container. Also automatically ensures infrastructure is running first.

**When to use:**

- Frontend developers working on UI
- When you need the frontend accessible at localhost:5173

**Services started:**
| Service | URL |
|---|---|
| Frontend | http://localhost:5173 |

---

### start.ps1 — Start Everything

```powershell
.\scripts\start.ps1
```

**What it does:** Starts all services — infrastructure, backend, and frontend — in the correct order.

**When to use:** Full stack development where you need everything running.

**Services started:**
| Service | URL |
|---|---|
| Backend API | http://localhost:8080/api/v1 |
| Frontend | http://localhost:5173 |
| pgAdmin | http://localhost:5050 |
| Azurite | http://localhost:10000 |

---

### stop.ps1 — Stop All Services

```powershell
.\scripts\stop.ps1
```

**What it does:** Stops all running containers. Your data (database, blob storage) is preserved.

**When to use:** End of work session. Safe to run — does not delete any data.

---

### migrate.ps1 — Run Database Migrations

```powershell
.\scripts\migrate.ps1
```

**What it does:** Runs all pending database migrations, creating or updating tables in Postgres.

**When to use:**

- First time setting up (after starting infrastructure and backend)
- After pulling changes that include new migration files
- When a teammate adds a new migration

> **Note:** Backend must be running before running migrations.

---

### seed.ps1 — Seed the Database

```powershell
.\scripts\seed.ps1
```

**What it does:** Populates the database with initial test data from `backend/database/seeds/seed.sql`.

**When to use:**

- After running migrations for the first time
- When you want to reset to a known data state

> **Note:** Backend and infrastructure must be running before seeding.

---

### clean.ps1 — Clean Everything

```powershell
.\scripts\clean.ps1
```

**What it does:** Stops all containers, removes all volumes (deletes all data), and removes all built images.

**When to use:** When you want a completely fresh start. You will need to rebuild, migrate, and seed again after running this.

> **Warning:** This deletes ALL data including the database. You will be asked to confirm before anything is deleted.

---

## Setting Up Azurite Blob Containers

Azurite is the local emulator for Azure Blob Storage. After starting the infrastructure, you need to create two blob containers manually using Azure Storage Explorer.

### Step 1 — Connect Azure Storage Explorer to Azurite

1. Open **Azure Storage Explorer**
2. Click the plug icon on the left sidebar
3. Select **"Local storage emulator"**
4. Leave all settings as default
5. Click **Next** then **Connect**

You will see **(Emulator - Default Ports)** appear under Storage Accounts.

### Step 2 — Create the `audio` container

1. Expand **(Emulator - Default Ports)** → **Blob Containers**
2. Click **Create** at the top
3. Type `audio` and press Enter
4. Leave access level as **off** (private — no public access)

### Step 3 — Create the `media` container

1. Click **Create** again
2. Type `media` and press Enter
3. Right click `media` → **Set Public Access Level**
4. Select **"Public read access for blobs only"**
5. Click **Apply**

### Result

| Container | Access Level  | Purpose                                        |
| --------- | ------------- | ---------------------------------------------- |
| audio     | off (private) | Audio files — requires authentication          |
| media     | blob (public) | Images, cover art — publicly accessible by URL |

> **Note:** Blob containers persist as long as you don't run `clean.ps1` or `docker compose down -v`. For normal daily stop/start using `stop.ps1`, containers are preserved.

---

## Common Workflows

### First Time Setup

```powershell
# 1. Build all images
.\scripts\build.ps1

# 2. Start infrastructure
.\scripts\start-infra.ps1

# 3. Create blob containers in Azure Storage Explorer (see above)

# 4. Start backend
.\scripts\start-backend.ps1

# 5. Run migrations
.\scripts\migrate.ps1

# 6. Seed the database
.\scripts\seed.ps1

# 7. Start frontend
.\scripts\start-frontend.ps1
```

---

### Daily Development — Backend Developer

```powershell
# Start infrastructure and backend
.\scripts\start-infra.ps1
.\scripts\start-backend.ps1

# End of day
.\scripts\stop.ps1
```

---

### Daily Development — Frontend Developer (Mock Mode)

```powershell
# Frontend only — no backend needed when VITE_USE_MOCK=true
.\scripts\start-frontend.ps1

# End of day
.\scripts\stop.ps1
```

---

### Daily Development — Frontend Developer (Real Backend)

```powershell
# Need full stack
.\scripts\start-infra.ps1
.\scripts\start-backend.ps1
.\scripts\start-frontend.ps1

# End of day
.\scripts\stop.ps1
```

---

### Full Stack / DevOps

```powershell
# Start everything
.\scripts\start.ps1

# End of day
.\scripts\stop.ps1
```

---

### After Pulling New Changes with Migrations

```powershell
.\scripts\start-infra.ps1
.\scripts\start-backend.ps1
.\scripts\migrate.ps1
```

---

### Complete Reset

```powershell
# WARNING: Deletes all data
.\scripts\clean.ps1

# Rebuild and start fresh
.\scripts\build.ps1
.\scripts\start-infra.ps1
# Re-create blob containers in Azure Storage Explorer
.\scripts\start-backend.ps1
.\scripts\migrate.ps1
.\scripts\seed.ps1
.\scripts\start-frontend.ps1
```

---

## Connecting pgAdmin to the Database

After starting infrastructure, access pgAdmin at http://localhost:5050
and login and connect to the db server

---

## Cross-Platform (Flutter)

The Flutter app does not run in Docker. The cross-platform team runs Flutter directly on their machines.

```bash
cd cross
flutter pub get
flutter run
```

Make sure the backend is running at `http://localhost:8080/api/v1` before running the Flutter app.

---

## Troubleshooting

**Containers won't start — port already in use**
Another process is using one of the ports (5433, 5050, 8080, 5173, 10000). Stop the conflicting process in task manager.

**Database connection refused**
Make sure `DATABASE_URL` in your `.env` uses `rythmify_db` as the host, not `localhost`.

**Migrations fail**
Make sure the backend container is running before running `migrate.ps1`.

**Blob containers missing after restart**
If you ran `stop.ps1` they should still be there. If you ran `clean.ps1` or `down -v` you need to recreate them in Azure Storage Explorer.

**Frontend can't reach backend**
Make sure `VITE_USE_MOCK=false` and `VITE_API_BASE_URL=http://localhost:8080/api/v1` in your `.env`.
