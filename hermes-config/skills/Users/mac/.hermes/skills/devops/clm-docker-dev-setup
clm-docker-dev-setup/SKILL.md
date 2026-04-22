---
name: clm-docker-dev-setup
category: devops
description: Docker Compose development environment for CLM-Tools project — service configuration, port conflict resolution, and common fixes
---

# CLM-Tools Docker Development Setup

**Use Case:** Starting and troubleshooting the CLM-Tools local Docker development environment.

---

## Services

| Service | Container Name | Port Mapping | Image |
|---------|---------------|--------------|-------|
| MySQL | clm-mysql | 3307:3306 | mysql:8.0 |
| Backend | clm-backend | 8001:8000 | Built from ./backend |
| Frontend | clm-frontend | 8081:80 | Built from ./frontend |

## Quick Start

```bash
cd /Users/mac/Projects/clm-tools-kw
docker compose up -d
```

## Port Conflict Resolution

### Problem
Old containers from previous CLM project instances occupy the same ports:
- `clm-review-tool-db-1` → port 3307
- `clm-review-tool-backend-1` → port 8001

### Solution
```bash
# Check for conflicting containers
docker ps -a | grep 3307
docker ps -a | grep 8001

# Stop old containers
docker stop clm-review-tool-db-1
docker stop clm-review-tool-backend-1

# Then start new environment
docker compose up -d
```

## Common Issues

### 1. Backend can't connect to MySQL
**Error:** `Can't connect to MySQL server on 'localhost' (Connection refused)`

**Cause:** `MYSQL_HOST` defaults to `localhost` but in Docker Compose the MySQL service is named `mysql`.

**Fix:** In `backend/app/config.py`:
- `MYSQL_HOST` default must be `"mysql"` (not `"localhost"`)
- `DATABASE_URL` env var takes precedence over split variables

```python
class Settings:
    _database_url: str = os.getenv("DATABASE_URL", "")

    @property
    def DATABASE_URL(self) -> str:
        if self._database_url:
            return self._database_url
        return f"mysql+pymysql://{self.MYSQL_USER}:{self.MYSQL_PASSWORD}@{self.MYSQL_HOST}:{self.MYSQL_PORT}/{self.MYSQL_DATABASE}"

    MYSQL_HOST: str = os.getenv("MYSQL_HOST", "mysql")  # NOT "localhost"
```

### 2. Frontend nginx can't resolve backend
**Error:** `host not found in upstream "backend" in /etc/nginx/conf.d/default.conf`

**Cause:** Frontend container started before backend was on the network, or old network conflict.

**Fix:**
```bash
docker stop clm-frontend && docker rm clm-frontend
docker compose up -d frontend
```

### 3. Docker Desktop not running
**Error:** `Cannot connect to the Docker daemon at unix:///Users/mac/.docker/run/docker.sock`

**Fix:**
```bash
open -a Docker
# Wait for it to be ready:
for i in $(seq 1 30); do docker info >/dev/null 2>&1 && echo "Ready" && break; sleep 2; done
```

## Verification

```bash
# Check all services running
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Health check
curl http://localhost:8001/health
# Expected: {"status":"ok"}

# Root endpoint
curl http://localhost:8001/
# Expected: {"name":"CLM 录菜复盘助手", "mock_mode":true}

# Frontend
curl http://localhost:8081/ | head -5

# API docs
open http://localhost:8001/docs

# Sync today's data
curl -X POST http://localhost:8001/api/sessions/sync-today

# View session
curl http://localhost:8001/api/sessions/1
```

## MySQL Access

```bash
# From host
docker exec clm-mysql mysql -u root -pclm_root_2026 -e "SHOW DATABASES;"

# With app credentials
docker exec clm-mysql mysql -u clm -pclm_pass_2026 clm_review -e "SHOW TABLES;"
```

## Stopping

```bash
docker compose down
# Or to keep data:
docker compose stop
```

## .env Configuration

```bash
MYSQL_ROOT_PASSWORD=clm_root_2026
MYSQL_DATABASE=clm_review
MYSQL_USER=clm
MYSQL_PASSWORD=clm_pass_2026
DATABASE_URL=mysql+pymysql://clm:clm_pass_2026@mysql:3306/clm_review
DEBUG=true
use_mock_data=true
ADMIN_TOKEN=
FEISHU_DRY_RUN=true
FEISHU_TEST_MODE=true
PUSH_TIME=18:30
PUSH_TIMEZONE=Asia/Shanghai
```

## Data Sources

| Source | Location | Status |
|--------|----------|--------|
| Mock generator | `backend/app/mock_data_generator.py` | ✅ Active (randomized realistic data) |
| Excel inputs | `data-sync/inputs/口味工程师调度看板.xlsx` | ✅ Copied from DateUse project |
| Excel inputs | `data-sync/inputs/全球口味工程师调度看板.xlsx` | ✅ Copied from DateUse project |
| Cache JSON | `data-sync/cache/discovery/` | ✅ Historical DB exploration results |

## Git Push via SSH

The repo uses a specific SSH key. If push fails with "Permission denied" or "deploy key":

```bash
cd /Users/mac/Projects/clm-tools-kw
# Use the usedata identity file
GIT_SSH_COMMAND="ssh -i /Users/mac/.ssh/id_ed25519_usedata -o IdentitiesOnly=yes" git push -u origin main
```

To make it permanent, add to `.git/config`:
```ini
[core]
    sshCommand = ssh -i /Users/mac/.ssh/id_ed25519_usedata -o IdentitiesOnly=yes
```

## Pitfalls

1. **Never commit .venv/** — Add `.venv/` and `venv/` to .gitignore
2. **graphify-out/ is auto-generated** — Must be in .gitignore
3. **Old containers persist** — Always check `docker ps -a` for conflicts before `docker compose up`
4. **Config.py MYSQL_HOST** — The default MUST be `"mysql"` for Docker Compose to work
5. **ADMIN_TOKEN blocks admin API locally** — Set `ADMIN_TOKEN=` (empty) in `.env` for local dev. Otherwise all `/api/admin/*` endpoints return 401.
6. **ADMIN_TOKEN_STORAGE_KEY corruption** — In `frontend/src/api.js`, if the key is corrupted (shows as `***`), admin calls silently fail. Replace with `const ADMIN_TOKEN_STORAGE_KEY = 'clm_admin_token';`
7. **Sidebar role filtering** — `frontend/src/components/Sidebar.jsx` must filter `navItems` by `localStorage.getItem('clm_role')`. Without this, non-superadmins see "系统管理" menu but get empty pages.
8. **Git URL pollution** — If `git remote set-url` injects ` -S -p ''` into the URL, edit `.git/config` directly to fix it.
