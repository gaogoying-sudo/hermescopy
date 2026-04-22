---
name: clm-data-sync-and-deployment
description: CLM-REVIEW-TOOL data sync integration and cloud deployment workflow - integrating data-sync module, creating sync APIs, and preparing production deployment
category: devops
tags: [clm, data-sync, deployment, docker, cloud]
version: 1.1.0
created: 2026-04-13
updated: 2026-04-13
changelog:
  - version: 1.1.0
    date: 2026-04-13
    changes:
      - Added detailed _pull_from_source() implementation pattern
      - Added complete sync API router code examples
      - Expanded deployment preparation steps with 6 sub-steps
      - Added 8 common pitfalls with solutions
      - Added comprehensive reference files list
      - Based on T05/T09/T110/T111 completion experience
---

# CLM Data Sync & Cloud Deployment Skill

## Overview

This skill covers the end-to-end workflow for:
1. Integrating the data-sync module into CLM-REVIEW-TOOL backend
2. Creating data synchronization API endpoints
3. Preparing cloud deployment infrastructure
4. Executing production deployment

## When to Use

- ✅ Implementing real data source synchronization (from company MySQL to CLM DB)
- ✅ Creating manual sync trigger APIs
- ✅ Preparing Docker Compose production deployment
- ✅ Setting up cloud server infrastructure
- ✅ Creating deployment automation scripts

## Prerequisites

- CLM-REVIEW-TOOL project structure in place
- Docker Compose local environment working
- Cloud server accessible via SSH
- Company backend database credentials available

## Phase 1: Data Sync Integration

### Step 1: Copy data-sync Module

```bash
# From DateUse project to CLM backend
cp -r /Users/mac/software\ project/DateUse/app/data_sync \
      /Users/mac/Projects/clm-tools-kw/backend/app/data_sync
```

### Step 2: Update sync_service.py

Add imports and implement `_pull_from_source()`:

```python
# Add to top of file
import json
import logging
from fastapi import HTTPException

logger = logging.getLogger(__name__)
```

**⚠️ Pitfall:** SyncTask model uses `synced_at`, not `created_at` - use correct attribute in queries.

### Step 3: Implement _pull_from_source()

Key implementation pattern:

```python
def _pull_from_source(db: Session, target_date: date) -> List[SyncTask]:
    from .data_sync.config import resolve_source_db_config
    from .data_sync.db import connect_source_db, fetch_account_pool
    from .data_sync.engineers import select_engineers
    from .data_sync.mapper import match_accounts, normalize_text
    
    # Check if already synced
    existing = db.query(SyncTask).filter(SyncTask.task_date == target_date).count()
    if existing > 0:
        return db.query(SyncTask).filter(SyncTask.task_date == target_date).all()
    
    # Get source DB config
    config = resolve_source_db_config()
    
    # Connect and fetch account pool
    conn = connect_source_db(config)
    pool = fetch_account_pool(conn)
    
    # Build engineer name -> admin_id mapping
    name_to_admin = {}
    for eng_roster in select_engineers(None):
        matched = match_accounts(eng_roster, pool)
        if matched:
            admin_id = matched[0].get('admin_id') or matched[0].get('account_id')
            if admin_id:
                name_to_admin[normalize_text(eng_roster['name'])] = admin_id
    
    # Query recipes from source DB
    with conn.cursor() as cur:
        cur.execute("""
            SELECT mr.id, mr.dish_name, rd.power_profile, rd.cook_steps_json, ...
            FROM btyc.main_recipe mr
            LEFT JOIN btyc.recipe_detail rd ON rd.recipe_id = mr.id
            WHERE DATE(mr.update_time) = %s
        """, (target_date.isoformat(),))
        recipes = cur.fetchall()
    
    # Transform and insert to sync_tasks
    # ... (see actual implementation for full code)
    
    conn.close()
    return all_tasks
```

### Step 4: Create Sync API Router

Create `backend/app/routers/sync.py` with 4 endpoints:

```python
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from ..database import get_db
from ..sync_service import sync_today_tasks, sync_history_tasks

router = APIRouter(prefix="/api/admin/sync", tags=["sync"])

@router.get("/status", summary="查看同步状态")
def get_sync_status(db: Session = Depends(get_db)):
    today = date.today()
    return {
        "today_tasks": db.query(SyncTask).filter(SyncTask.task_date == today).count(),
        "total_tasks": db.query(SyncTask).count(),
        "latest_sync_at": "...",
        "use_mock_data": settings.use_mock_data,
        "source_db_configured": bool(settings.SOURCE_DB_HOST and settings.SOURCE_DB_USER),
    }

@router.post("/trigger/today", summary="手动触发当天同步")
def trigger_sync_today(force: bool = Query(False), db: Session = Depends(get_db)):
    if force:
        db.query(SyncTask).filter(SyncTask.task_date == date.today()).delete()
        db.commit()
    tasks = sync_today_tasks(db)
    return {"success": True, "synced_tasks": len(tasks)}

@router.post("/trigger/history", summary="手动触发历史同步")
def trigger_sync_history(days: int = Query(30, ge=1, le=365), db: Session = Depends(get_db)):
    total = sync_history_tasks(db, days_back=days)
    return {"success": True, "synced_tasks": total}

@router.get("/config", summary="查看数据源配置状态")
def get_source_config():
    return {
        "use_mock_data": settings.use_mock_data,
        "configured": bool(settings.SOURCE_DB_HOST),
        "hint": "配置 SOURCE_DB_* 环境变量以启用真实数据同步",
    }
```

### Step 5: Register Router in main.py

```python
from .routers import sessions, answers, admin, search, sync  # Add sync

app.include_router(sync.router)  # Add this line
```

### Step 6: Verify API Endpoints

```bash
docker compose restart backend
sleep 5

# Test all endpoints
curl http://localhost:8001/api/admin/sync/status
curl -X POST http://localhost:8001/api/admin/sync/trigger/today
curl "http://localhost:8001/api/admin/sync/trigger/history?days=30"
curl http://localhost:8001/api/admin/sync/config
```

**Expected output:**
```json
{
  "today_tasks": 129,
  "total_tasks": 2777,
  "today_sessions": 54,
  "total_engineers": 75,
  "use_mock_data": true,
  "source_db_configured": false
}
```

## Phase 2: Cloud Deployment Preparation

### Step 1: Create Deployment Documentation

- `docs/DEPLOYMENT.md` - Complete deployment guide (7KB+)
  - Target environment specs
  - Pre-deployment checklist
  - Step-by-step deployment instructions
  - Nginx configuration (optional)
  - Backup strategy
  - Troubleshooting guide

- `docs/decisions/003-cloud-deployment-strategy.md` - ADR for deployment strategy
  - Architecture decision record
  - Technology choices and rationale
  - Alternative solutions considered
  - Implementation plan

### Step 2: Create Configuration Templates

- `.env.prod.template` - Production environment template
  ```bash
  # === MySQL ===
  MYSQL_ROOT_PASSWORD=<STRONG_ROOT_PASSWORD>
  MYSQL_DATABASE=clm_review
  MYSQL_USER=clm
  MYSQL_PASSWORD=<STRONG_CLM_PASSWORD>
  
  # === Backend ===
  DATABASE_URL=mysql+pymysql://clm:<PASSWORD>@mysql:3306/clm_review
  DEBUG=false
  use_mock_data=false
  ADMIN_TOKEN=<ADMIN_TOKEN>
  
  # === Feishu ===
  FEISHU_APP_ID=cli_xxx
  FEISHU_APP_SECRET=xxx
  FEISHU_DRY_RUN=false
  FEISHU_TEST_MODE=false
  
  # === Source DB ===
  SOURCE_DB_HOST=<COMPANY_DB_HOST>
  SOURCE_DB_USER=<COMPANY_DB_USER>
  SOURCE_DB_PASSWORD=<COMPANY_DB_PASSWORD>
  ```

### Step 3: Create Deployment Scripts

- `scripts/deploy-to-cloud.sh` - Automated deployment script
  - SSH connection check
  - Docker environment verification
  - Code upload via git archive
  - Service startup and health check
  - Usage: `./deploy-to-cloud.sh`

- `scripts/backup-db.sh` - Database backup with retention
  - Daily mysqldump via cron
  - Compression and rotation (7 days)
  - Optional: remote storage upload

- `scripts/clm-review-tool.service` - systemd service file
  - Auto-start on boot
  - Docker Compose integration

- `scripts/nginx.conf.template` - Nginx reverse proxy config
  - HTTP/HTTPS support
  - WebSocket support
  - Static resource caching

### Step 4: Create Manual Operations Checklist

- `docs/MANUAL_OPERATIONS.md` - List of user-required actions
  - Sensitive information configuration
  - Cloud server deployment steps
  - Verification checklist
  - Common operations commands
  - Troubleshooting guide

### Step 5: Create Test Report

- `docs/TEST_REPORT_T111.md` - End-to-end verification report
  - API endpoint testing (17 items)
  - Frontend page validation
  - Performance metrics
  - Issues and recommendations

### Step 6: Phase Completion Summary

- `docs/PHASE_2_COMPLETE.md` - Phase completion summary
  - Task completion status
  - Deliverables list
  - Git commit history
  - Next steps

## Phase 3: Git & Governance

```bash
cd /Users/mac/Projects/clm-tools-kw
git add -A
git commit -m "T05: Data sync integration"  # or appropriate message
git push origin main
.venv/bin/python3 -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path('.'))"
```

Update:
- `docs/TASK_BOARD.md` - Mark tasks as Done
- `docs/progress.md` - Log detailed progress

## Common Pitfalls

1. **SyncTask Attribute Error**: Use `synced_at` not `created_at`
   - Error: `AttributeError: type object 'SyncTask' has no attribute 'created_at'`
   - Fix: Change to `SyncTask.synced_at`

2. **Missing Imports**: Remember to add `json`, `logging`, `HTTPException`
   - `import json` for JSON parsing
   - `import logging` for logger
   - `from fastapi import HTTPException` for error handling

3. **data_sync Module Path**: Ensure correct import path `app.data_sync.*`
   - Wrong: `from data_sync.config import ...`
   - Correct: `from .data_sync.config import ...`

4. **Environment Variables**: SOURCE_DB_* must be set for real mode
   - Check: `curl /api/admin/sync/config` → `source_db_configured: false`
   - Fix: Set `SOURCE_DB_HOST`, `SOURCE_DB_USER`, `SOURCE_DB_PASSWORD`

5. **Port Conflicts**: Check ports 8001/8081/3307 not in use
   - `netstat -tlnp | grep -E '8001|8081|3307'`

6. **Engineer Name Matching**: Normalize names for comparison
   - Use `normalize_text()` from data_sync.mapper
   - Handle aliases and variations

7. **JSON Parsing Errors**: cook_steps_json may be invalid
   - Wrap in try/except: `json.loads(recipe['cook_steps_json'])`
   - Default to empty list on failure

8. **Database Connection Timeout**: Source DB may be slow
   - Add timeout config in `SourceDBConfig`
   - Use connection pooling for production

## Reference Files

### Core Implementation
- `backend/app/sync_service.py` - Sync service with _pull_from_source()
- `backend/app/routers/sync.py` - Sync API endpoints (4 endpoints)
- `backend/app/data_sync/` - Data sync module (5 files)
  - `config.py` - Source DB configuration resolver
  - `db.py` - Database connection and account pool fetch
  - `engineers.py` - Engineer roster (36 engineers)
  - `mapper.py` - Name matching and export functions

### Deployment Documentation
- `docs/DEPLOYMENT.md` - Complete deployment guide (7KB)
- `docs/decisions/003-cloud-deployment-strategy.md` - ADR
- `docs/MANUAL_OPERATIONS.md` - User action checklist
- `docs/TEST_REPORT_T111.md` - End-to-end verification report
- `docs/PHASE_2_COMPLETE.md` - Phase completion summary

### Configuration & Scripts
- `.env.prod.template` - Production environment template
- `scripts/deploy-to-cloud.sh` - Automated deployment script
- `scripts/backup-db.sh` - Database backup script
- `scripts/clm-review-tool.service` - systemd service
- `scripts/nginx.conf.template` - Nginx configuration

## Related Skills

- `clm-docker-dev-setup` - Local Docker development
- `clm-project-governance` - Project governance workflow
- `clm-session-completion-workflow` - Session completion ritual
