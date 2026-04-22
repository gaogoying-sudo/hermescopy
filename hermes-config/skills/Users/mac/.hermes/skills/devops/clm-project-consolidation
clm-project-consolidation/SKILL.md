---
name: clm-project-consolidation
category: devops
description: Consolidate CLM-REVIEW-TOOL from three teams (CLM-Tools/Cursor, DateUse/Codex, Hermes) into unified monorepo with 5-layer governance
---

# CLM Project Consolidation & Governance Setup

## When to Use
- Resuming work on CLM-REVIEW-TOOL (口味工程师日总结系统)
- Setting up project governance for similar multi-team code consolidation
- Need to restore CLM project context after session break

## Key Paths
| Resource | Path |
|----------|------|
| New monorepo | /Users/mac/Projects/clm-tools-kw/ |
| DateUse source | /Users/mac/software project/DateUse/ |
| CLM-Tools source | ~/software project/cursor/CLM-Tools/dailyReport/clm-review-tool/ |
| Cloud server | 82.156.187.35 (root@) |
| Cloud deploy | /opt/clm-review-tool/ |
| Obsidian vault | ~/Documents/CLM-Obsidian/ |
| Git remote | git@github.com:gaogoying-sudo/clm-tools-kw.git |

## 5-Layer Governance Architecture

```
Layer 0: Memory (auto-injected, 2200 chars)
Layer 1: MemPalace (wing=clm_review_tool, 6 rooms)
Layer 2: Obsidian (personal knowledge base, wikilinks)
Layer 3: docs/ (version controlled engineering docs)
Layer 4: graphify (auto-rebuilt code graph)
```

### Consolidation Steps

1. **Create monorepo skeleton**
   ```
   clm-tools-kw/
   ├── backend/app/       # FastAPI from CLM-Tools
   ├── frontend/src/      # React from CLM-Tools
   ├── data-sync/         # From DateUse
   ├── docker-compose.yml # MySQL + Backend + Frontend
   ├── docs/              # Governance docs
   └── mempalace.yaml     # MemPalace config
   ```

2. **Copy useful code (exclude cache, pycache, node_modules)**
   - Use `rsync -av --exclude='__pycache__' --exclude='*.pyc' --exclude='node_modules' source/ dest/`
   - Keep source code, discard build artifacts and cache

3. **Setup Docker Compose**
   - MySQL 8.0 (port 3307)
   - Backend FastAPI (port 8001)
   - Frontend React (port 8081)
   - Port conflicts: stop old containers first

4. **Fix common config issues**
   - `MYSQL_HOST` default should be `mysql` (Docker service name), not `localhost`
   - `DATABASE_URL` env var takes priority over split vars
   - `ADMIN_TOKEN` empty for local dev (no auth needed)

5. **Install graphify in project venv**
   ```bash
   python3.12 -m venv .venv && source .venv/bin/activate
   pip install graphifyy
   python3 -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path('.'))"
   ```

6. **Create governance docs**
   - GOVERNANCE.md (5-layer architecture)
   - TASK_BOARD.md (Backlog/Doing/Done)
   - RESOURCE.md (servers, DBs, APIs, ports)
   - progress.md (daily progress log)
   - decisions/ (ADR records)

## Mock Data Generation

### Quick seed (36 engineers + 30 days)
```bash
docker exec clm-backend python3 /app/app/seed_30day_data.py
# Expected: ~1327 tasks, ~394 sessions (86.5% submitted)
```

### Files
- `backend/app/mock_data_generator.py` — 16 recipes with power traces + ingredient timelines
- `backend/app/seed_30day_data.py` — Populates all tables with realistic distribution

## Admin Dashboard Pages (5 pages + login)
- `/login` — Demo auth
- `/dashboard` — Stats + 36 engineer table
- `/search` — Multi-condition search with cache
- `/qa-records` — Three-layer Q&A data
- `/insights` — Experience candidate review
- `/settings` — Engineers + questions + datasource

See skill `clm-admin-dashboard-building` for full details.

## Pitfalls

1. **Git remote URL pollution**: `git remote set-url` injects ` -S -p ''` into URLs. Fix by directly editing `.git/config`.

2. **Port conflicts from old containers**: Old CLM-Tools and DateUse containers may still be running. Check with `docker ps` and stop conflicting containers before starting new ones.

3. **MySQL connection in Docker**: Backend config must use `mysql` as host, not `localhost`. The `DATABASE_URL` env var should be read with priority.

4. **ADMIN_TOKEN blocking local dev**: When `ADMIN_TOKEN` is set, all `/api/admin/*` endpoints require auth. Set to empty string for local development.

5. **Frontend ADMIN_TOKEN_STORAGE_KEY corruption**: If the storage key in api.js is corrupted (e.g., shows as `***`), fix the file or disable backend auth.

6. **Old containers occupying ports**: Always check `docker ps` before running `docker compose up`. Ports 3307, 8001, 8081 are commonly conflicted.

## Verification Checklist
- [ ] Docker compose up -d succeeds (all 3 containers healthy)
- [ ] GET /health returns {"status":"ok"}
- [ ] POST /api/sessions/sync-today creates sessions
- [ ] GET /api/admin/dashboard returns stats (no auth required locally)
- [ ] GET /api/admin/engineers returns engineer list
- [ ] Frontend accessible at http://localhost:8081
- [ ] Admin panel accessible at http://localhost:8081/#/admin
- [ ] graphify-out/GRAPH_REPORT.md exists with code graph
