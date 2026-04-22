---
name: multi-agent-codebase-consolidation
category: software-development
description: Consolidate code from multiple AI agents (Cursor, Codex, etc.) running in separate repositories into a single unified project. Covers analysis, selective copying, structure creation, and governance setup.
---

# Multi-Agent Codebase Consolidation

**Use Case:** You have multiple AI agents (e.g., Cursor, Codex) working on different parts of a project in separate repos, and need to merge them into a single coherent repository.

---

## When to Use

- Multiple AI agents developed different parts in separate repos
- Need to unify frontend/backend/data-sync into one project
- Taking over a multi-team project and consolidating ownership
- Migrating from distributed development to single-repo monorepo

---

## Step-by-Step Process

### Step 1: Inventory Source Repositories

```bash
# List all source repos and their structures
find /path/to/repo1 -type f -not -path '*/.git/*' -not -name '.DS_Store' | head -50
find /path/to/repo2 -type f -not -path '*/.git/*' -not -name '.DS_Store' | head -50
```

Document what each repo owns:
- Repo 1: What layers? (e.g., backend API, frontend UI)
- Repo 2: What layers? (e.g., data sync, ETL pipelines)
- Shared: What overlaps? (e.g., models, config)

### Step 2: Analyze and Classify Files

For each source repo, classify files:

| Category | Action | Examples |
|----------|--------|---------|
| Core source code | Copy | `.py`, `.jsx`, `.ts`, `.js` |
| Build config | Copy | `package.json`, `requirements.txt`, `Dockerfile` |
| Documentation | Selective | `*.md` (keep project-specific, skip generated) |
| Cache/build artifacts | Exclude | `__pycache__/`, `node_modules/`, `dist/`, `*.pyc` |
| IDE configs | Exclude | `.vscode/`, `.idea/`, `.DS_Store` |
| Generated outputs | Exclude | `graphify-out/`, `coverage/` |
| Dependencies (installed) | Exclude | `venv/`, `.venv/`, `node_modules/` |

### Step 3: Create Target Project Structure

```bash
mkdir -p target-project/{backend/app/routers,frontend/src,data-sync/data_sync,docs/decisions}
cd target-project
git init
```

Design the monorepo structure:
```
target-project/
├── backend/          # From Agent A (e.g., Cursor)
├── frontend/         # From Agent A (e.g., Cursor)
├── data-sync/        # From Agent B (e.g., Codex)
├── docker-compose.yml
├── .env.example
├── .gitignore
├── docs/
└── README.md
```

### Step 4: Selective Copy with rsync

```bash
# Copy backend files, excluding noise
rsync -av \
  --exclude='__pycache__' --exclude='*.pyc' --exclude='.git' \
  --exclude='graphify-out' --exclude='.DS_Store' \
  --exclude='node_modules' --exclude='dist' \
  --exclude='*.jpg' --exclude='*.png' \
  /path/to/source-backend/ target-project/backend/

# Copy frontend files
rsync -av \
  --exclude='__pycache__' --exclude='node_modules' \
  --exclude='dist' --exclude='.git' \
  /path/to/source-frontend/ target-project/frontend/

# Copy data-sync files
rsync -av \
  --exclude='__pycache__' --exclude='*.pyc' \
  --exclude='node_modules' --exclude='cache/' \
  /path/to/source-datasync/ target-project/data-sync/
```

**Key rsync flags:**
- `-a`: Archive mode (preserves permissions, timestamps)
- `-v`: Verbose (see what's being copied)
- `--exclude`: Pattern to skip (add as needed per project)

### Step 5: Copy Key Documentation Selectively

```bash
mkdir -p target-project/docs/
cp /path/to/source1/docs/handover.md target-project/docs/
cp /path/to/source2/docs/discovery.md target-project/docs/
# Only copy documents with project context, skip generated reports
```

### Step 6: Create Unified Configuration

**docker-compose.yml:**
```yaml
services:
  mysql:
    image: mysql:8.0
    ports:
      - "3307:3306"
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
  backend:
    build: ./backend
    ports:
      - "8001:8000"
    depends_on:
      - mysql
  frontend:
    build: ./frontend
    ports:
      - "8081:80"
    depends_on:
      - backend
```

**.env.example:**
```
# Document all environment variables with defaults
MYSQL_ROOT_PASSWORD=default_pass
DEBUG=true
```

**.gitignore:**
```
# Python
__pycache__/
*.pyc
.venv/
venv/

# Node
node_modules/
dist/

# Generated
graphify-out/

# Env
.env
!.env.example

# OS
.DS_Store
```

### Step 7: Create Governance Documents

At minimum:
- `README.md` - Project overview and quick start
- `docs/progress.md` - Current progress and next steps
- `docs/RESOURCE.md` - External resources (servers, APIs, ports)
- `AGENTS.md` - AI agent rules (graphify, MemPalace, etc.)
- `mempalace.yaml` - MemPalace configuration (if using)

### Step 8: Initial Commit and Graph Generation

```bash
git add -A
git commit -m "Initial consolidation: merged [repo1] + [repo2]"

# If using graphify
source .venv/bin/activate
python3 -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path('.'))"
```

---

## Pitfalls

1. **Don't copy installed dependencies** - `venv/`, `node_modules/`, `.venv/` should be recreated, not copied. Always exclude them.

2. **Watch for hidden pollution in git remote URLs** - Some environments inject artifacts like ` -S -p ''` into git remote URLs. Fix by directly editing `.git/config`:
   ```bash
   # Bad: url = https://github.com/user -S -p ''/repo.git
   # Fix: edit .git/config directly to remove pollution
   ```

3. **Don't copy cache/data files** - Discovery caches, SQLite files, recipe payloads are local artifacts. Exclude `cache/`, `*.sqlite3`, `*.json` in cache directories.

4. **Python version matters** - graphify requires Python 3.10+. System Python on macOS is often 3.9.6. Create a venv with the right version:
   ```bash
   python3.12 -m venv .venv
   source .venv/bin/activate
   pip install graphifyy
   ```

5. **Don't copy .git directories** - Each source repo has its own git history. You want a fresh unified history. Always `--exclude='.git'`.

6. **Merge port assignments carefully** - If source repos used the same ports, reassign them:
   - Backend: 8001 (was 8000)
   - Frontend: 8081 (was 8080)
   - MySQL: 3307 (was 3306)

7. **Preserve important docs but skip generated ones** - Handover docs, architecture docs, and progress logs are valuable. Generated reports, graph outputs, and build artifacts are not.

---

## Verification Checklist

After consolidation:
- [ ] All source files copied (check file counts)
- [ ] No `__pycache__/`, `node_modules/`, `.venv/` in target
- [ ] `.gitignore` excludes common noise patterns
- [ ] `docker-compose.yml` runs all services
- [ ] `.env.example` documents all required variables
- [ ] Key documentation copied to `docs/`
- [ ] Git commit succeeds with clean working tree
- [ ] (Optional) graphify generates initial graph
- [ ] Remote URL is clean (no pollution artifacts)

---

## Example: CLM Project Consolidation

**Sources:**
- CLM-Tools (Cursor): `~/software project/cursor/CLM-Tools/dailyReport/clm-review-tool/`
- DateUse (Codex): `~/software project/DateUse/app/data-sync/`
- Docs: `~/Projects/CLM Project/docs/`

**Target:**
- `/Users/mac/Projects/clm-tools-kw/`

**What was copied:**
- Backend: FastAPI app (17 files)
- Frontend: React app (6 files)
- Data-sync: Python ETL (7 files)
- Docs: 6 key documents

**What was excluded:**
- `__pycache__/`, `*.pyc` (Python cache)
- `graphify-out/` (generated graph)
- `.DS_Store` (macOS artifacts)
- `ai-recipe-roadmap/`, `*.jpg` (images/assets)
- `mempalace.yaml` (recreated fresh)
- `CHANGELOG_V1.md` (superseded)
- `cache/`, `dist/` (DateUse local data)

---

## Related Skills

- `multi-project-coordination` - Managing multiple projects simultaneously
- `graphify-install` - Installing and configuring graphify
- `writing-plans` - Creating implementation plans
- `subagent-driven-development` - Delegating tasks to subagents
