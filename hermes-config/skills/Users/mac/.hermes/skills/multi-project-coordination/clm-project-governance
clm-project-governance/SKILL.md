---
name: clm-project-governance
category: multi-project-coordination
description: Five-layer governance architecture for CLM project (and reusable for other projects) - Memory → MemPalace → Obsidian → docs/ → graphify
---

# CLM Project Governance - Five-Layer Architecture

**Use Case:** Managing a project with an AI agent where context must survive across sessions without losing information.

---

## Overview

A five-layer governance system that separates concerns by persistence scope, access pattern, and audience:

```
Layer 0: Memory (auto-injected, ~2200 chars)
Layer 1: MemPalace (semantic search, MCP protocol)
Layer 2: Obsidian (personal knowledge base, bidirectional links)
Layer 3: docs/ (engineering docs, Git version controlled)
Layer 4: graphify (code graph, auto-rebuilt on commit)
```

---

## Layer Responsibilities

| Layer | Purpose | Capacity | Content | Who Writes |
|-------|---------|----------|---------|------------|
| Memory | Project identity | ~2200 chars | Nickname, paths, stage, next step | AI auto-maintains |
| MemPalace | Structured project memory | Large (wing/rooms) | API contracts, business rules, data models, troubleshooting | AI auto-writes |
| Obsidian | Personal knowledge | Unlimited | Product thinking, requirements drafts, meeting notes, reviews | User (AI creates on request) |
| docs/ | Engineering docs | Unlimited (Git) | Progress logs, task boards, resource registry, ADRs | AI + user |
| graphify | Code structure graph | Auto-generated | Dependencies, god nodes, community structure | Fully automated |

---

## Session Flow

### Session Start
1. Memory auto-injects → identify project
2. Read docs/progress.md → see last progress
3. Read docs/TASK_BOARD.md → see current tasks
4. Query MemPalace (MCP) → load project context
5. Read graphify-out/GRAPH_REPORT.md → code structure

### Session End
1. Update docs/progress.md
2. Update docs/TASK_BOARD.md
3. Write MemPalace for significant changes
4. Git commit → triggers graphify rebuild
5. Update Memory if stage/next-step changed

---

## File Structure

```
project-root/
├── mempalace.yaml          # MemPalace configuration
├── AGENTS.md               # AI rules (MemPalace + graphify + Obsidian)
├── docs/
│   ├── 00-PROJECT-INDEX.md
│   ├── GOVERNANCE.md
│   ├── progress.md
│   ├── TASK_BOARD.md
│   ├── RESOURCE.md
│   └── decisions/
│       └── 001-*.md
└── graphify-out/           # Auto-generated, gitignored
```

---

## Key Rules

1. **No duplication** — Same info stored in only one layer, linked/referenced elsewhere
2. **Progressive loading** — Read layers as needed, not all at once
3. **Auto-maintenance** — graphify rebuilds on commit, Memory auto-updates, docs/ versioned with Git
4. **User owns Obsidian** — AI only creates/updates on explicit request
5. **Memory is minimal** — Only identity + path + stage + next step

---

## Pitfalls

1. **Storing detailed info in Memory** — Wastes limited 2200 char space. Use docs/ instead.
2. **Not updating progress.md** — Makes session recovery impossible. Always update at session end.
3. **Forgetting graphify-out/ in .gitignore** — It's auto-generated, should not be committed.
4. **Mixing Obsidian and docs/ content** — Obsidian is for thinking/notes, docs/ is for facts/progress.
5. **Missing DateUse cache data** — When consolidating, always copy `data-sync/cache/` as reference. It contains critical DB exploration results.
6. **ADMIN_TOKEN_STORAGE_KEY corruption** — If the frontend api.js has `ADMIN_TOKEN_STORAGE_KEY='***'`, the key name is damaged. Reset to a valid string like `'clm_admin_token'`.
7. **`.env` overriding docker-compose** — Environment variables in `.env` override docker-compose.yml defaults. Always check `.env` when containers have stale config.
8. **Old container port conflicts** — Previous project versions' containers can occupy ports. Always `docker ps -a` to find and stop them before `docker compose up`.
9. **Admin API returns 401 when ADMIN_TOKEN is set** — If you want open access in dev, set `ADMIN_TOKEN=` (empty) in both `.env` and docker-compose.yml.

## Obsidian Integration (2026-04-15 Update)

CLM project notes are now integrated into unified multi-project vault:

**Vault Path:** `~/Documents/Obsidian-Vault/`

**CLM Notes Location:** `10-Projects/CLM/`

**Key Files:**
- `CLM-项目概览.md` — Project overview with graph.html link
- `CLM-项目治理制度.md` — Governance implementation details
- `CLM-任务看板.md` — Task board (synced with docs/TASK_BOARD.md)
- `CLM-技术选型.md` — Tech stack and architecture decisions
- `CLM-资源登记.md` — Resources and configuration

**Graphify Visualization:**
- Location: `~/Projects/clm-tools-kw/graphify-out/graph.html`
- Generated with pyvis (232 nodes, 426 edges, 41 communities)
- Linked in CLM-项目概览.md with `file:///` protocol
- Auto-rebuilt on git commit

**Cross-Project Links:**
- `[[20-Areas/五层治理架构]]` — Universal governance framework
- `[[30-Resources/Graphify 代码图谱]]` — Graphify tool documentation
- `[[000-主导航]]` — Main navigation hub

**AI Auto-Generation:**
- Session end → Creates `00-Inbox/YYYY-MM-DD-CLM-主题.md`
- Technical decisions → Updates `CLM-技术选型.md` or creates ADR
- Phase completion → Creates `CLM-PhaseX 复盘.md`

## Admin Dashboard Architecture (v2.0 - learned 2026-04-12)

The CLM admin dashboard follows a 5-page + login pattern with role-based access:

```
/login        → Authentication (demo mode: any credentials)
/dashboard    → Aggregated metrics (stats cards, engineer table)
/search       → Multi-condition search with local cache layer
/qa-records   → Raw Q&A data (3-layer retention: raw/transcribed/structured)
/insights     → Experience candidates (review workflow)
/settings     → System admin (users, templates, engineers, data sources)
```

**Role hierarchy:**
| Role | Access |
|------|--------|
| superadmin | All 5 pages + settings |
| admin | dashboard + search + qa-records + insights |
| analyst | dashboard + search (readonly) + qa-records (readonly) |

**Search cache logic:**
1. Check if data is "today's" → mark as "in progress", don't use directly
2. Check local cache for this query combination
3. Cache hit → return immediately; Cache miss → query DB + write cache

**QA data retention policy:**
- All Q&A records are NEVER deleted, only archived
- Three layers preserved: raw_input → transcribed_text → structured_result
- Export supports CSV and JSON by date range

## DateUse Data Reference Integration

When consolidating CLM project, always copy DateUse's cache directory as reference:
- `data-sync/cache/discovery/` — Database schema exploration results
- `data-sync/cache/recipe_payload/` — Real recipe data samples
- `data-sync/cache/schema_dashboard_rows*.json` — Dashboard data structure
- `data-sync/cache/analytics_store.sqlite3` — Analysis cache

These are NOT for runtime use — they're reference data for understanding the source database structure.

## Docker Troubleshooting

**Port conflicts:** Old containers from previous project versions can occupy ports. Always check:
```bash
docker ps -a | grep <port>
docker stop <old-container>
docker rm <old-container>
```

**Environment variable priority:** `.env` file overrides docker-compose.yml defaults. If a container has stale env, check `.env` first:
```bash
docker exec <container> env | grep <VAR_NAME>
```

**Common fix pattern:**
```bash
# Fix ADMIN_TOKEN being set when it should be empty
echo "ADMIN_TOKEN=" >> .env  # or edit directly
docker stop clm-backend && docker rm clm-backend
docker compose up -d backend
```

---

## MemPalace Configuration Example

```yaml
wing: clm_review_tool
rooms:
  - name: backend
    description: API contracts, data models, business rules
  - name: frontend
    description: Components, UI patterns, user feedback
  - name: deployment
    description: Cloud environment, Docker config, monitoring
  - name: documentation
    description: Meetings, decisions, troubleshooting
  - name: general
    description: Team, processes, conventions
```

---

## Related Skills
- `multi-project-coordination` — General multi-project patterns
- `writing-plans` — Implementation planning