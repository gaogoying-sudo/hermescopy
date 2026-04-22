---
name: multi-team-port-management
description: Manage port assignments across multiple development teams to prevent conflicts, with documentation and registration system
tags: [docker, ports, multi-team, coordination, devops, documentation]
created: 2026-04-10
---

# Multi-Team Port Management

**Problem:** Multiple teams developing microservices often use the same default ports (8000, 8080, 3000, etc.), causing container conflicts.

**Solution:** Centralized port assignment document + mandatory registration system.

---

## Port Assignment Strategy

### Layered Allocation

| Layer | Team A | Team B | Team C |
|-------|--------|--------|--------|
| **Frontend** | 8081 | 8082 | 8083 |
| **Backend API** | 8001 | 8002 | 8003 |
| **Database** | 3307 | 3308 | 3309 |
| **Cache** | 6307 | 6308 | 6309 |

**Pattern:** Base port + team offset (Team A=+1, Team B=+2, Team C=+3)

---

## Documentation Structure

### 1. Port Assignment Document (`PORT_ASSIGNMENT.md`)

```markdown
# Project Name - Port Assignment

## Current Conflicts
- List discovered conflicts

## Allocation Table
| Team | Service | Port | Status |
|------|---------|------|--------|
| Team A | Frontend | 8081 | ✅ |
| Team A | Backend | 8001 | ✅ |

## Docker Compose Examples
### Team A
```yaml
services:
  frontend:
    ports:
      - "8081:80"
  backend:
    ports:
      - "8001:8000"
```

## Restart Commands
docker-compose down
docker-compose up -d
docker ps
```

---

### 2. Team Registration Document (`TEAM_REGISTER.md`)

**Purpose:** Track who did what, when, and what they need.

**Template:**
```markdown
### [Team Name] - [YYYY-MM-DD HH:MM]

**确认身份：** Team Name
**更新时间：** 2026-04-10 15:30 (Asia/Shanghai)
**负责人：** @name

**当前状态：**
- [ ] 环境已配置
- [ ] 端口已调整
- [ ] 容器已重启
- [ ] 服务可访问

**今日进展：**
...

**遇到的问题/诉求：**
...

**下一步计划：**
...
```

**Rules:**
- Must register after port changes
- Must register after container restart
- Must register when blocked
- Coordinator checks daily

---

### 3. Environment Files (`.env` per team)

```bash
# PORT_ASSIGNMENT_TEAM-A.env
# Team A environment configuration

# Service ports (internal - don't change)
API_PORT=8000
FRONTEND_PORT=80

# External ports (mapped in docker-compose.yml)
EXTERNAL_API_PORT=8001
EXTERNAL_FRONTEND_PORT=8081

# Database
DB_PORT=3306
EXTERNAL_DB_PORT=3307
```

---

## Deployment Workflow

### Phase 1: Discovery

```bash
# Find all docker-compose files
find ~ -name "docker-compose.yml" -path "*project*"

# Check current port usage
docker ps --format "table {{.Names}}\t{{.Ports}}"

# Check port conflicts
lsof -i :8000
lsof -i :8080
```

### Phase 2: Assignment

1. Create `PORT_ASSIGNMENT.md` with allocation table
2. Create team-specific `.env` files
3. Update each team's `docker-compose.yml`

### Phase 3: Communication

Send unified notification:
```
═══════════════════════════════════════════════════
⚠️ Port Conflict Notice - Project Name
═══════════════════════════════════════════════════

Teams affected: [list]
Conflict: [ports]
Solution: [allocation table]

Action Required:
1. docker-compose down
2. Update docker-compose.yml ports
3. docker-compose up -d
4. Register in TEAM_REGISTER.md

Access URLs:
- Team A: http://localhost:8081
- Team B: http://localhost:8082

Full doc: PORT_ASSIGNMENT.md
═══════════════════════════════════════════════════
```

### Phase 4: Verification

```bash
# Verify all containers running
docker ps

# Test each service
curl http://localhost:8081
curl http://localhost:8001

# Check registration
cat TEAM_REGISTER.md
```

---

## Common Port Conflicts

| Port | Common Services | Resolution |
|------|-----------------|------------|
| 8000 | FastAPI, Flask | Assign 8001, 8002, 8003 |
| 8080 | React, Vue, Angular | Assign 8081, 8082, 8083 |
| 3000 | Next.js, Node.js | Assign 3001, 3002, 3003 |
| 3306 | MySQL | Assign 3307, 3308, 3309 |
| 5432 | PostgreSQL | Assign 5433, 5434, 5435 |
| 6379 | Redis | Assign 6380, 6381, 6382 |
| 8265 | Ray | Assign 8266, 8267 |
| 9000 | Various | Assign 9001, 9002 |

---

## Coordinator Checklist

- [ ] Discover all teams' port usage
- [ ] Create PORT_ASSIGNMENT.md
- [ ] Create TEAM_REGISTER.md
- [ ] Create team-specific .env files
- [ ] Send unified notification
- [ ] Verify each team's restart
- [ ] Check registration compliance
- [ ] Test all services accessible
- [ ] Document in project wiki

---

## Troubleshooting

### Old Containers from Same Project Hold Ports

**Problem:** Stopping old docker-compose doesn't always remove containers. Old containers from previous project instances (different compose files, same ports) will block new containers even in different project directories.

**Symptoms:**
```
Bind for 0.0.0.0:3307 failed: port is already allocated
```

**Solution:**
```bash
# 1. Find ALL containers using the port (across ALL compose projects)
docker ps -a | grep 3307

# 2. Stop old containers by name (not by compose project)
docker stop <old-container-name>

# 3. Then start new compose
docker compose up -d
```

**Key insight:** `docker compose down` only stops containers from the current compose project. Containers from other compose projects (even in different directories) that use the same ports will still block. Always check `docker ps -a` globally before `docker compose up`.

### Team Can't Restart (Blocked)

1. Check registration for blocker
2. Coordinate with other teams
3. Provide temporary workaround
4. Escalate if needed

### Port Still Conflicted After Restart

```bash
# Find what's using the port
lsof -i :8080

# Kill if necessary
kill -9 <PID>

# Or change port assignment
```

### Team Forgot to Register

1. Check docker ps for their containers
2. Message team directly
3. Update registration for them
4. Remind of registration requirement

---

## Best Practices

1. **Document before changing** — Never change ports without documentation
2. **One source of truth** — PORT_ASSIGNMENT.md is authoritative
3. **Registration is mandatory** — No registration = not done
4. **Coordinator verifies** — Don't trust, verify with curl/docker ps
5. **Keep historical record** — Don't delete old registrations

---

**Key Lesson:** Port conflicts are a coordination problem, not a technical problem. Documentation + registration + verification = no conflicts.
