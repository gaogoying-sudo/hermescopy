---
name: project-governance-setup
category: productivity
description: Set up 5-layer governance architecture for any project — Memory indexing, MemPalace, Obsidian, docs/, and graphify. Ensures information persistence, session recovery, and team coordination.
---

# Project Governance Setup

**Use Case:** When starting a new project or restructuring an existing one, set up the 5-layer governance architecture to ensure information persistence, session recovery, and team coordination.

**Key Learning (2026-04-15):** For multi-project setups, use ONE unified Obsidian Vault with clear分区 (00-Inbox, 10-Projects, 20-Areas, etc.) rather than separate Vaults per project. This enables cross-project linking, global search, and unified backup.

---

## When to Use

- Starting a new project with an AI agent
- Reorganizing a messy project's documentation
- User complains about "forgetting" context between sessions
- Multi-agent project needs coordination structure
- User wants "mechanisms, not promises" for information persistence
- **Multi-project setup requiring cross-project references**

---

## 5-Layer Architecture

```
Layer 0: Memory Index (auto-injected per session)
Layer 1: MemPalace (AI structured memory, semantic search)
Layer 2: Obsidian (user's personal knowledge base, bidirectional links)
Layer 3: docs/ (engineering docs, version controlled via Git)
Layer 4: graphify (code graph, auto-rebuilt on commit)
```

---

## Setup Steps

### Step 1: Initialize docs/ Structure

```bash
mkdir -p docs/decisions
```

Create these files:
- `docs/00-PROJECT-INDEX.md` — Quick navigation, cloud info, current stage
- `docs/progress.md` — Daily progress log (timestamped entries)
- `docs/TASK_BOARD.md` — Backlog / Doing / Done table
- `docs/RESOURCE.md` — External resources (servers, DBs, APIs, ports)
- `docs/GOVERNANCE.md` — Governance rules (this document)

### Step 2: Configure MemPalace

Create `mempalace.yaml` in project root:

```yaml
wing: <project_name_snake_case>
rooms:
  - name: general
    description: General project memory — team, workflow, conventions
  - name: backend
    description: Backend development — API contracts, data models, business rules
  - name: frontend
    description: Frontend development — components, UI specs, user feedback
  - name: deployment
    description: Deployment & ops — cloud environment, configs, monitoring
  - name: documentation
    description: Documentation & handoff — meetings, decisions, troubleshooting
```

Add to AGENTS.md:
```markdown
## MemPalace
- Always use MCP server `mempalace` for project memory lookup
- Use wing `<project_name>` rooms for context
- Search before making non-trivial code changes
```

### Step 3: Configure Obsidian (Multi-Project Unified Vault)

**Recommended:** Create a unified vault for ALL projects, not per-project vaults.

```bash
mkdir -p ~/Documents/Obsidian-Vault/{00-Inbox,10-Projects,20-Areas,30-Resources,40-Archives,50-Templates}
```

**Directory Structure:**
```
~/Documents/Obsidian-Vault/
├── 000-主导航.md              ← Main navigation entry point
├── 00-Inbox/                 ← Temporary notes, session records
│   └── YYYY-MM-DD-Session.md
├── 10-Projects/              ← Project-specific notes
│   ├── <ProjectA>/
│   │   ├── <ProjectA>-概览.md
│   │   ├── <ProjectA>-任务看板.md
│   │   └── <ProjectA>-资源登记.md
│   └── <ProjectB>/
├── 20-Areas/                 ← Long-term knowledge areas
│   ├── 技术架构.md
│   ├── 产品方法论.md
│   └── AI 协作.md
├── 30-Resources/             ← Reusable knowledge fragments
│   ├── 代码片段.md
│   └── 工具清单.md
├── 40-Archives/              ← Completed projects
└── 50-Templates/             ← Note templates
    ├── 会话记录模板.md
    └── 项目概览模板.md
```

**AI Auto-Generation Rules:**
- Session end → Create `00-Inbox/YYYY-MM-DD-主题.md` with session summary
- User shares insights → Create/update `20-Areas/` notes
- New project → Use templates to create `10-Projects/<Project>/` notes
- Technical decisions → Create ADR notes with links

Add to AGENTS.md:
```markdown
## Obsidian
- Unified vault at ~/Documents/Obsidian-Vault/
- Multi-project structure: 10-Projects/<ProjectName>/
- AI auto-generates session records to 00-Inbox/
- Use [[wikilink]] syntax for cross-referencing
- Add #<project-tag> tag to all related notes
- Auto-link to 000-主导航.md as main entry point
```

### Step 4: Install & Configure graphify

```bash
cd <project-root>
# Use Python 3.10+ venv
python3.12 -m venv .venv
source .venv/bin/activate
pip install graphifyy

# Generate initial graph
python3 -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path('.'))"

# Install git hooks
graphify hook install
```

Add `.venv/` and `graphify-out/` to `.gitignore`.

Add to AGENTS.md:
```markdown
## graphify
- Before answering architecture questions, read graphify-out/GRAPH_REPORT.md
- After modifying code: python3 -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path('.'))"
```

### Step 5: Write Memory Index

```
📌 <ProjectName> (<date> update)
**Nickname:** 「<name>」
**Goal:** <one-line goal>
**Local Path:** <path>
**Cloud IP:** <ip if applicable>
**Deploy Dir:** <dir if applicable>
**Progress Docs:** docs/progress.md + docs/TASK_BOARD.md
**Governance:** docs/GOVERNANCE.md (5-layer: Memory → MemPalace → Obsidian → docs/ → graphify)
**Stage:** <current stage>
**Next:** <next action>
**Key Mechanisms:** <critical configs, safety flags>
```

### Step 6: Initialize TASK_BOARD.md

```markdown
# <ProjectName> Task Board

## Backlog
| ID | Task | Priority | Dependency | ETA |
|----|------|----------|------------|-----|
| T01 | First task | P0 | - | 30min |

## Doing
(empty)

## Done
(empty)
```

---

## Session Workflow

### Session Start (recovery)
1. Memory auto-injected → confirm project identity
2. Read docs/progress.md → see where last session left off
3. Read docs/TASK_BOARD.md → see current tasks
4. Query MemPalace (MCP) → load project context
5. Read graphify-out/GRAPH_REPORT.md → understand code structure
6. Start work

### Session End (wrap-up)
1. Update docs/progress.md → what was done, what's next, blockers
2. Update docs/TASK_BOARD.md → move tasks to Done
3. Write critical changes to MemPalace
4. Git commit → triggers graphify auto-rebuild
5. Update Memory if stage/next-action changed

---

## Layer Responsibilities

| Content Type | Layer | Why |
|-------------|-------|-----|
| "Which project am I?" | Memory | Zero-cost wake-up |
| Server IP, DB passwords | Memory + docs/RESOURCE.md | Quick index + full registry |
| "What did I do yesterday?" | docs/progress.md | Version-controlled log |
| "What's next?" | Memory + docs/TASK_BOARD.md | Quick locate + full board |
| API contracts, business rules | MemPalace (backend room) | Semantic search for AI dev |
| Product thinking, decisions | Obsidian | User's personal knowledge |
| Code dependencies | graphify | Auto-generated, always fresh |

---

## Anti-Patterns

❌ Storing detailed requirements in Memory — use docs/ instead
❌ Not updating progress.md at session end — context lost on resume
❌ Skipping graphify — no code structure awareness
❌ Multiple projects in one Obsidian vault without tags — hard to filter
❌ Not committing docs/ changes — version history lost

---

## Checklist

### New Project Setup
- [ ] Create docs/ directory structure (00-PROJECT-INDEX.md, progress.md, TASK_BOARD.md, RESOURCE.md, decisions/)
- [ ] Create mempalace.yaml
- [ ] Add MemPalace rules to AGENTS.md
- [ ] Create Obsidian vault directory + initial note
- [ ] Add Obsidian rules to AGENTS.md
- [ ] Install graphify, generate initial graph, install git hooks
- [ ] Add graphify rules to AGENTS.md
- [ ] Write Memory index entry
- [ ] Initialize TASK_BOARD.md
- [ ] Git commit all governance files

### Each Session
- [ ] Read progress.md + TASK_BOARD.md at start
- [ ] Update progress.md + TASK_BOARD.md at end
- [ ] Git commit (triggers graphify rebuild)
- [ ] Update Memory if stage changed

---

## Pitfalls

1. **Memory space is limited (~2200 chars)** — Only store minimal index, not details
2. **graphify needs Python 3.10+** — Use venv if system Python is old
3. **Obsidian vault path must be quoted** — Paths may contain spaces
4. **`.venv/` must be in .gitignore** — Don't commit virtual environment
5. **`graphify-out/` must be in .gitignore** — Locally generated, not version-controlled
6. **MemPalace rooms should match project structure** — Don't create rooms no one will use
7. **Session end without updating docs = context loss** — This is the #1 failure mode
