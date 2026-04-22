---
name: clm-session-completion-workflow
category: devops
description: End-to-end verification and governance completion ritual for CLM-REVIEW-TOOL sessions — API testing, frontend validation, documentation updates, git commit/push, graphify rebuild
---

# CLM Session Completion Workflow

## When to Use
- Completing a development session for CLM-REVIEW-TOOL
- Before ending any CLM project work session
- Need to ensure governance compliance (docs updated, git committed, graph rebuilt)

## The Ritual (Must Do Every Session)

### Phase 1: End-to-End Verification

#### 1.1 API Health Check
```python
import http.client
import json

conn = http.client.HTTPConnection("localhost", 8001, timeout=10)

# Test health
conn.request("GET", "/health")
resp = conn.getresponse()
assert resp.status == 200, "Backend not healthy!"

# Test key APIs
endpoints = [
    "/api/admin/search?size=3",
    "/api/admin/qa-records?size=3",
    "/api/admin/engineers",
    "/api/admin/cache/stats",
]

for ep in endpoints:
    conn.request("GET", ep)
    resp = conn.getresponse()
    print(f"{ep}: {resp.status}")
    assert resp.status == 200
```

#### 1.2 Frontend Page Validation
```python
# Test frontend pages
conn = http.client.HTTPConnection("localhost", 8081, timeout=5)
pages = ["/", "/login", "/dashboard", "/search", "/qa-records", "/insights", "/settings"]

for page in pages:
    conn.request("GET", page)
    resp = conn.getresponse()
    print(f"{page}: {resp.status}")
```

#### 1.3 Browser-Based Functional Test
```python
# Use browser tools to verify actual rendering
browser_navigate("http://localhost:8081")
# Verify login page renders
browser_type("@e2", "admin")  # username
browser_type("@e3", "test123")  # password
browser_click("@e4")  # login button
# Verify dashboard loads with data
browser_snapshot()
# Navigate through key pages
browser_click("@e2")  # search page
browser_click("@e3")  # qa records
browser_click("@e5")  # settings
```

### Phase 2: Documentation Updates

#### 2.1 Update TASK_BOARD.md
```markdown
# Mark completed tasks as Done
|| T109 | 后端缓存层 API | P1 | T105 | 2h | **Done** |
|| T110 | 端到端验证 + 文档更新 | P0 | 全部 | 1h | **Done** |

# Mark next task as DOING (if continuing)
|| T111 | Next task | P1 | T110 | 1h | **DOING** |
```

**Rule:** Always update status before starting work (TODO → DOING) and after completing (DOING → Done).

#### 2.2 Update progress.md
```markdown
**HH:MM** [小强] T109/T110 完成
- List key changes made
- API endpoints added/modified
- Test results (✅ all passed)
- Any bugs fixed
- Git commit hash
```

### Phase 3: Git Commit + Push

#### 3.1 Check Git Status
```bash
cd /Users/mac/Projects/clm-tools-kw
git status
```

#### 3.2 Commit Changes
```bash
git add -A
git commit -m "T109: 后端缓存层 API 完成 + T110: 端到端验证通过

- List key changes
- API endpoints added
- Test results
- Docs updated"
```

#### 3.3 Push to GitHub
```bash
git push origin main
```

**⚠️ Pitfall:** If git remote URL is polluted (contains ` -S -p ''` suffix), edit `.git/config` directly:
```ini
[remote "origin"]
    url = git@github.com:gaogoying-sudo/clm-tools-kw.git
```

### Phase 4: Graphify Rebuild

#### 4.1 Activate Virtual Environment
```bash
cd /Users/mac/Projects/clm-tools-kw
source .venv/bin/activate
```

#### 4.2 Rebuild Code Graph
```bash
python3 -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path('.'))"
```

Expected output:
```
[graphify watch] Rebuilt: XXX nodes, XXX edges, XX communities
[graphify watch] graph.json and GRAPH_REPORT.md updated in graphify-out
```

**Note:** `graphify-out/` is in `.gitignore` — do not commit.

### Phase 5: Final Verification

#### 5.1 Docker Container Status
```bash
docker compose ps
```

Expected:
```
clm-mysql    ✅ Up (healthy)
clm-backend  ✅ Up
clm-frontend ✅ Up
```

#### 5.2 Quick API Smoke Test
```python
conn = http.client.HTTPConnection("localhost", 8001, timeout=5)
conn.request("GET", "/health")
resp = conn.getresponse()
assert resp.status == 200
print("✅ All systems operational")
```

## Session Exit Checklist

- [ ] All APIs responding (health + key endpoints)
- [ ] All frontend pages accessible
- [ ] TASK_BOARD.md updated (Done status)
- [ ] progress.md updated with session log
- [ ] Git commit completed
- [ ] Git push successful
- [ ] Graphify rebuilt
- [ ] Docker containers healthy
- [ ] Memory updated if new info discovered

## Common Issues & Fixes

### 1. Backend 502 Errors
**Symptom:** `urllib` returns 502 but container is up
**Fix:** Use direct HTTP connection test:
```python
import socket
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
result = sock.connect_ex(('localhost', 8001))
# If port open, backend is fine — urllib issue
```

### 2. Git Push Fails (URL Pollution)
**Symptom:** SSH/HTTPS push fails with malformed URL
**Fix:** Edit `.git/config` directly, remove ` -S -p ''` from URL

### 3. Graphify Module Not Found
**Symptom:** `ModuleNotFoundError: No module named 'graphify'`
**Fix:** Activate virtual environment first: `source .venv/bin/activate`

### 4. Frontend SPA Routes Return Strange Status
**Symptom:** `/dashboard` returns "Request-sent" instead of 200
**Fix:** This is normal for React Router — use browser tools to verify actual rendering

## Governance Compliance

This workflow enforces the 5-layer governance architecture:
- **Layer 0 (Memory):** Session context auto-injected
- **Layer 1 (MemPalace):** Semantic search available via MCP
- **Layer 2 (Obsidian):** Personal KB at ~/Documents/CLM-Obsidian/
- **Layer 3 (docs/):** TASK_BOARD.md + progress.md updated ✅
- **Layer 4 (graphify):** Code graph rebuilt ✅

**Rule:** Never end a session without completing this ritual. Future sessions depend on accurate state.
