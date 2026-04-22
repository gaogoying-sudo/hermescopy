---
name: graphify-multi-team-deployment
description: Deploy Graphify knowledge graph across multiple AI platforms (Cursor, Codex, Hermes/OpenClaw) for multi-team coordination
tags: [graphify, knowledge-graph, multi-team, cursor, codex, hermes, deployment]
created: 2026-04-10
---

# Graphify Multi-Team Deployment

**Purpose:** Enable cross-team codebase awareness when different teams use different AI platforms (Cursor, Codex, Hermes, etc.)

**Key Insight:** Graphify's `graph.json` is platform-agnostic — any AI can read it via `AGENTS.md` configuration, even if the platform isn't natively supported.

---

## Platform Support Matrix

| Platform | Native Support | Install Command | Notes |
|----------|---------------|-----------------|-------|
| Claude Code | ✅ | `graphify claude install` | Full support + PreToolUse hook |
| Codex (VSCode) | ✅ | `graphify codex install` | Full support + hooks.json |
| OpenClaw (Hermes) | ✅ | `graphify claw install` | AGENTS.md only, no hooks |
| Cursor | ❌ | `graphify claw install` | Use `claw` as fallback, reads AGENTS.md |
| OpenCode | ✅ | `graphify opencode install` | Full support |
| Factory Droid | ✅ | `graphify droid install` | Full support |
| Trae | ✅ | `graphify trae install` | Full support |

---

## Deployment Steps

### Step 1: Install Platform Configuration

**For each team's project:**

```bash
# CLM-Tools team (Cursor - no native support, use claw fallback)
cd ~/software/project/cursor/CLM-Tools/dailyReport/clm-review-tool
graphify claw install

# DateUse team (Codex - native support)
cd ~/software/project/DateUse
graphify codex install

# Coordinator (Hermes/OpenClaw)
cd ~/Projects/CLM\ Project
graphify claw install
```

**What this does:**
- Writes graphify section to `AGENTS.md`
- For Codex/Claude: Also installs PreToolUse hooks
- For Claw: AGENTS.md rules only (always-on mechanism)

---

### Step 2: Install Git Hooks (Auto-Update)

```bash
# Each project directory
graphify hook install
```

**Hooks installed:**
- `.git/hooks/post-commit` → Rebuild graph after commits
- `.git/hooks/post-checkout` → Rebuild graph after branch switches

**Note:** If project isn't a git repo:
```bash
git init
git add -A
git commit -m "Initial commit: enable graphify"
graphify hook install
```

---

### Step 3: Generate Initial Graph

**Method 1: AI Assistant Trigger (Recommended)**

Each team's AI assistant generates their own graph:

```
# In Cursor (CLM-Tools team)
/graphify .

# In Codex (DateUse team)
/graphify .

# In Hermes (Coordinator)
/graphify ~/Projects/CLM\ Project
```

**Method 2: Manual Python Trigger**

```bash
cd <project-directory>
python3 -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path('.'))"
```

**Method 3: Graphify CLI Query (Requires existing graph)**

```bash
graphify query "what is the auth flow?"
graphify path "ClassA" "ClassB"
graphify explain "SomeNode"
```

---

## Output Structure

Each project generates `graphify-out/`:

```
graphify-out/
├── graph.html          # Interactive visualization
├── GRAPH_REPORT.md     # Architecture insights (god nodes, communities)
├── graph.json          # Knowledge graph data (platform-agnostic)
└── cache/              # SHA256 cache for incremental updates
```

---

## Cross-Team Coordination Patterns

### Pattern 1: Interface Alignment Check

**Coordinator queries:**
```
/graphify query "What tables does CLM-Tools read from DateUse?"
/graphify path "core_recipes" "sync_tasks"
```

**Purpose:** Verify interface contracts before integration.

---

### Pattern 2: Architecture Change Impact

**Team member asks:**
```
/graphify explain "backend/app/models.py"
```

**Purpose:** Understand what breaks if this file changes.

---

### Pattern 3: Data Flow Tracing

**Coordinator traces:**
```
/graphify query "Complete data flow from source DB to experience_candidates"
```

**Purpose:** Verify end-to-end data contract (DATA_HANDOVER_v1.md).

---

### Pattern 4: Shared Structure Discovery

**Coordinator queries:**
```
/graphify query "What data structures are shared between CLM-Tools and DateUse?"
```

**Purpose:** Identify coupling points for coordination.

---

## Troubleshooting

### Problem: "command not found: graphify"

```bash
# Find installation
which graphify
python3 -c "import os, graphify; print(os.path.dirname(graphify.__file__) + '/../bin/graphify')"

# Add to PATH
export PATH="$HOME/.local/bin:$PATH"
```

### Problem: "Requires Python 3.10+"

```bash
# Check version
python3 --version

# Find alternative Python
ls ~/.local/bin/python3.1*
ls /opt/homebrew/bin/python3.*

# Use specific Python
/Users/mac/.local/bin/python3.11 -m pip install graphifyy --break-system-packages
```

### Problem: "externally-managed-environment"

```bash
# Option 1: Use uv Python directly
/Users/mac/.local/bin/python3.11 -m pip install graphifyy --break-system-packages

# Option 2: Use pipx
pipx install graphifyy

# Option 3: Use uv pip
uv pip install graphifyy --system
```

### Problem: Cursor Doesn't Recognize AGENTS.md

**Solution:** Restart Cursor AI assistant. AGENTS.md is read on session start.

**Fallback:** Manually paste graphify rules into Cursor chat:
```markdown
## graphify

This project has a graphify knowledge graph at graphify-out/.

Rules:
- Before answering architecture questions, read graphify-out/GRAPH_REPORT.md
- After code changes, run: python3 -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path('.'))"
```

---

## Best Practices

1. **One graph per project** — Don't merge multiple projects into one graph
2. **Git hooks are essential** — Manual updates get forgotten
3. **GRAPH_REPORT.md is gold** — Read it before architecture questions
4. **Cross-team graphs stay separate** — Coordinator queries both, doesn't merge
5. **Document the deployment** — Save deployment steps for future reference

---

## Related Documents

- Port Assignment: `PORT_ASSIGNMENT.md`
- Team Registration: `TEAM_REGISTER.md`
- Data Handover: `docs/DATA_HANDOVER_v1.md`

---

**Key Lesson:** Graphify's power isn't just code analysis — it's creating a **shared language** for multiple AI platforms to understand the same codebase consistently.
