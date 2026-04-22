---
name: multi-project-coordination
category: productivity
description: Manage multiple simultaneous projects without context confusion - conversation threads, memory indexing, and documentation patterns
---

# Multi-Project Coordination with Hermes

**Use Case:** Managing multiple simultaneous projects without context confusion

---

## When to Use

- You're working on 2+ projects with different contexts
- You want to switch between projects without confusion
- You need clear project boundaries and progress tracking
- You're using multiple AI agents (Cursor, Codex, etc.) for different parts

---

## Core Pattern

### 1. One Conversation Thread Per Project

**Rule:** Each project gets its own dedicated conversation thread.

**Why:**
- Prevents context mixing
- Session search stays project-specific
- Clear mental model for both you and the agent

**How:**
- Project A → Open new conversation, first message: "Project A, [task]"
- Project B → Open another conversation, first message: "Project B, [task]"
- Never switch projects mid-thread

### 2. Project Nickname System

**Rule:** Give each project a short nickname for quick switching.

**Example:**
- "小厨" = CLM-REVIEW-TOOL (口味工程师项目)
- "小 X" = New Project A
- etc.

**Memory Entry Format:**
```
📌 [Project Name]（[date]）
**称呼：** 「[nickname]」
**目标：** [one line]
**本地路径：** [path(s)]
**云 IP:** [if applicable]
**部署目录：** [if applicable]
**进度文档：** [docs/progress.md paths]
**阶段：** [current stage]
**下一步：** [next action]
```

### 3. Local Documentation Structure

**Each project has:**
```
[project-root]/docs/
├── 00-PROJECT-INDEX.md    # Project index with key info
├── progress.md            # Progress tracking (updated each session)
├── TASK_BOARD.md          # Task kanban (Backlog/Doing/Done)
├── RESOURCE.md            # Resource registry (servers, DBs, APIs, ports)
├── GOVERNANCE.md          # Governance rules (if using 5-layer architecture)
├── decisions/             # Architecture Decision Records (ADR)
│   └── 001-[topic].md
├── architecture.md        # Architecture decisions
├── requirements.md        # Requirements (if applicable)
└── [role]-STARTER_PACK.md # Starter packs for different agents
```

**Index File (00-PROJECT-INDEX.md):**
- Quick links to all project docs
- Cloud server info (IP, SSH key path, deploy directory)
- Related projects
- Current stage
- Last updated timestamp

**Progress File (progress.md):**
- Timestamped entries with who did what
- Next actions
- Blockers
- User requirements and constraints recorded verbatim

**Task Board (TASK_BOARD.md):**
- Simple kanban: Backlog / Doing / Done columns
- Each task has: ID, description, priority, dependencies, estimated time
- Move tasks between columns as status changes
- Done tasks reference the git commit hash

**Resource Registry (RESOURCE.md):**
- Cloud servers, databases, API keys, port mappings
- Sensitive info: reference location, don't store actual secrets in git
- Environment variable templates in .env.example

### 4. Five-Layer Governance Architecture

For complex projects, use a five-layer approach to prevent information loss across sessions:

```
Layer 0: Memory (auto-injected each session)
  - Project nickname, paths, stage, next action
  - ~2200 chars max, extremely focused

Layer 1: MemPalace (AI structured memory, semantic search)
  - MCP protocol, wing/room organization
  - API contracts, business rules, data models, issue resolutions
  - AI writes automatically, user can correct

Layer 2: Obsidian (personal knowledge base, bidirectional links)
  - User's thinking notes, product decisions, meeting records
  - [[wikilink]] syntax, graph view, long-term accumulation
  - User primarily, AI creates/updates on request

Layer 3: docs/ (engineering docs, version controlled)
  - progress.md, TASK_BOARD.md, RESOURCE.md, decisions/ (ADR)
  - Git version controlled, team shared
  - AI and user co-maintain

Layer 4: graphify (code graph, auto-rebuilt)
  - Code structure, dependency analysis, impact assessment
  - Auto-rebuilt on git commit/checkout
  - Fully automated
```

### When to Use Which Layer

| Content Type | Layer | Why |
|-------------|-------|-----|
| "Which project am I on?" | Memory | First thing needed each session |
| "What are the API contracts?" | MemPalace | Semantic search, AI development reference |
| "What's my product thinking?" | Obsidian | User perspective, long-term沉淀 |
| "What's the current progress?" | docs/ | Version controlled, team shared |
| "What does the code structure look like?" | graphify | Auto-generated from code, always current |

### Session Recovery Flow

```
Session starts → Read Memory → docs/progress.md → docs/TASK_BOARD.md
             → Query MemPalace (as needed) → Read graphify GRAPH_REPORT.md
Session ends  → Update docs/progress.md → docs/TASK_BOARD.md
             → Write to MemPalace (key changes) → Git commit → graphify auto-rebuilds
```

**Memory stores only:**
- Project nickname
- Project name
- Key paths (local + cloud)
- Current stage (one line)
- Next action (one line)
- Governance layer references (MemPalace wing, Obsidian vault path)

**Memory does NOT store:**
- Detailed requirements
- Full architecture
- Code snippets
- Long discussions

**Why:** Memory is limited (2,200 chars), shared across all projects.

### 5. Starter Packs for Different Agents

**When starting a new agent on a project:**
- Create a `[AGENT]-STARTER_PACK.md` in docs/
- Include: project goal, architecture, data flow, their responsibilities, current progress, file locations
- Agent reads this first, then starts work

**Example agents:**
- Cursor → Business logic, frontend, API
- Codex → Data sync, SQL, ETL
- etc.

---

## Workflow

### Starting a New Project

1. **Create conversation thread**
   - First message: "[Project Name/Nickname], [initial task]"

2. **Create docs/ structure**
   - `00-PROJECT-INDEX.md`
   - `progress.md`
   - Agent starter packs (as needed)

3. **Add memory index**
   - Minimal info, just enough to identify and switch

4. **Establish project boundaries**
   - What this project owns
   - What other projects own
   - Interface contracts

### Switching Between Projects

**You:** "小厨，继续开发 review-app"

**Agent:**
1. Checks memory for "小厨" → finds CLM project
2. Reads CLM project context
3. Continues with CLM-specific knowledge

**You:** "新项目 A，帮我设计架构"

**Agent:**
1. Checks memory → doesn't find "新项目 A"
2. Asks for project details
3. Creates new memory entry after you provide info

### Ending a Session

**Before closing:**
1. Update `docs/progress.md` with current state
2. Agent updates memory index if anything changed
3. Note what's next for when you return

---

## Anti-Patterns (Avoid These)

❌ **Multiple projects in one conversation thread**
- Leads to context confusion
- Agent may mix up decisions

❌ **Not saying project name at start of new conversation**
- Agent may guess wrong
- Always say "[Nickname/Project Name], [task]"

❌ **Storing detailed info in memory**
- Wastes limited space
- Use local docs/ instead

❌ **No progress documentation**
- Hard to resume after break
- Always update progress.md

❌ **Agent assumes project without confirming**
- If unclear, agent should ask
- You should always specify

---

## Memory Management

### When Memory is Full

1. **Review existing entries**
   - Remove completed projects
   - Consolidate related entries

2. **Keep only active projects**
   - Archive completed projects to docs/
   - Remove from memory

3. **Use replace, not add**
   - Update existing entries instead of adding new ones

### Entry Priority

**Keep:**
- Active projects (in development)
- Recent projects (last 30 days)
- Projects with cloud infrastructure

**Remove:**
- Completed projects (archive to docs/)
- One-off tasks (no need to track)
- Old entries with updated replacements

---

## Example Memory Entries

```
📌 CLM-REVIEW-TOOL（2026-04-10）
**称呼：** 「小厨」
**目标：** 口味工程师日总结系统
**本地路径：** CLM-Tools + DateUse
**云 IP:** 82.156.187.35
**部署目录：** /opt/clm-review-tool/
**进度文档：** 两项目 docs/progress.md
**阶段：** 云环境已初始化，待开发真实数据接入
**下一步：** Cursor 开发 review-app → Codex 开发 data-sync

📌 Project Alpha（2026-04-11）
**称呼：** 「阿法」
**目标：** [description]
**本地路径：** [path]
**阶段：** [stage]
**下一步：** [next action]
```

---

## Checklist

### New Project Setup
- [ ] Create conversation thread
- [ ] Create docs/00-PROJECT-INDEX.md
- [ ] Create docs/progress.md
- [ ] Add memory index entry
- [ ] Create agent starter packs (as needed)
- [ ] Define project boundaries

### Each Session
- [ ] Start with project name/nickname
- [ ] Review progress.md
- [ ] Work on tasks
- [ ] Update progress.md before ending

### Session End
- [ ] Update progress.md
- [ ] Update memory if needed
- [ ] Note next actions

---

## Pitfalls

1. **Forgetting to say project name**
   - Solution: Always start with "[Nickname], [task]"

2. **Memory fills up**
   - Solution: Regular cleanup, archive completed projects

3. **Docs not updated**
   - Solution: Make it a habit before ending each session

4. **Agent assumes wrong project**
   - Solution: Agent should ask if unclear; you should always specify

---

## Conceptual Distinctions (Agent vs Session vs Context)

### Theoretical Model vs Hermes Reality

**The ideal model:**
```
Hermes (Platform/Engine)
  └── Agent (Role identity + isolated governance config)
        └── Session (Conversation thread instance)
              └── Context (Current working memory)
```

**Hermes reality (v0.8.x):**
```
Hermes (Platform/Engine — SINGLE instance)
  ├── Global config (~/.hermes/config.yaml)
  ├── Global memory (~/.hermes/memories/ — ALL roles read/write same file)
  ├── Global skills (~/.hermes/skills/)
  └── Session A (大管家) ← reads ALL memory, ALL config
  └── Session B (小厨)   ← reads ALL memory, ALL config
  └── Session C (小妹)   ← reads ALL memory, ALL config
```

| Concept | Definition | Lifecycle | Example |
|---------|-----------|-----------|---------|
| **Platform** | Underlying engine (Hermes) | Permanent | Hermes software itself |
| **Agent** | ONE instance per Hermes install | Permanent | There is only ONE Hermes agent |
| **Session** | One conversation thread | One conversation's lifetime | 大管家 dialog, 小厨 dialog |
| **Role identity** | Convention-based nickname in memory | Set by user | 大管家, 小厨, 小妹妹 |
| **Context** | Current working memory | Between tool calls | The task being processed now |

**Key rules (current Hermes):**
- Hermes runs ONE agent instance with global memory and config
- Different "roles" (大管家, 小厨, 小妹妹) are NOT separate agents — they are different sessions of the same agent, distinguished by memory entries
- All sessions read the SAME global memory — no isolation
- Session search crosses ALL roles
- Role identity is maintained by convention (user says "小厨" → agent reads 小厨's memory entries)

**Note:** OpenClaw had the same issue — its `agents.list` config existed but in practice all roles ran as the `main` agent playing different parts, or used subagent spawn for temporary isolation. Neither platform natively supports multiple persistent, isolated agents with separate memory.

### Isolation Levels

**Weak isolation (current Hermes, convention-based):**
- Dialog context: ISOLATED (each conversation has separate session history)
- Memory: SHARED (all sessions read/write same global MEMORY.md)
- Skills: SHARED (one global skill library)
- Config: SHARED (one config.yaml)
- Session search: CROSSES ALL roles
- Requires discipline to not cross role boundaries

**Strong isolation (requires multiple Hermes instances):**
```
~/.hermes-da-guanjia/     ← independent memory + config + sessions
~/.hermes-xiao-chu/       ← independent memory + config + sessions
~/.hermes-xiao-mei/       ← independent memory + config + sessions
~/.hermes-shared/         ← shared skills + governance templates (symlink/script sync)
```
- Each instance has its own memory, config, and session store
- Shared architecture maintained via symlinks or sync scripts
- Requires launching different instances for different roles

## Governance Portability Across Hermes Instances

**The governance framework is portable; the data is per-instance.**

**Portable (same across all Hermes conversations):**
- Five-layer architecture rules (Memory → MemPalace → Obsidian → docs/ → graphify)
- Session recovery flow (read Memory → docs/ → MemPalace → graphify)
- Anti-pattern rules (don't mix projects, don't fill memory, always write progress.md)
- Starter Pack pattern (new agents read starter pack first)

**Per-instance (unique to each Agent/conversation):**
- Memory entry (nickname, paths, stage, next action)
- MemPalace wing (e.g., `clm_review_tool`)
- Obsidian vault path (e.g., `~/Documents/CLM-Obsidian/`)
- docs/ directory (project-specific)
- graphify graph (codebase-specific)

## Context Governance Flowchart

```
User sends message
  → Hermes engine receives, starts session
    → STEP 1: Identity recognition (read Agent nickname from message)
    → STEP 2: Context recovery
        2a. Memory injection (~2200 chars auto-injected, confirm Agent identity)
        2b. Read docs/ (progress.md, TASK_BOARD.md, current task state)
        2c. MemPalace query (semantic search, API contracts, business rules via MCP)
        2d. graphify read (GRAPH_REPORT.md, code structure overview)
        2e. session_search (cross-session history retrieval if needed)
    → STEP 3: Task execution
        Tool calls → Skill loading → Sub-agent delegation (with governance context passed)
    → STEP 4: Context persistence
        4a. Update docs/ (progress.md + TASK_BOARD.md)
        4b. Write to MemPalace (key changes to corresponding wing/room)
        4c. Git commit (docs/ changes → triggers graphify rebuild)
        4d. Update Memory (stage/next action changes, replace not add)
        4e. Update Obsidian (on user request, thinking notes/decision records)
```

## Data Persistence Strategies

| Data temperature | Content | Storage | Update trigger |
|-----------------|---------|---------|----------------|
| Ultra-hot | Agent identity, current task | Memory | Manual (user confirms or agent discovers critical fact) |
| Hot | Current task state, progress | docs/progress.md + TASK_BOARD.md | Automatic (every session end) |
| Warm | Project knowledge, decisions | MemPalace wing + Obsidian | Conditional (key changes) |
| Cold | Historical records | session_search retrieval | On-demand (search when needed) |
| Code context | Code structure, dependencies | graphify | Triggered (git commit/checkout auto-rebuild) |

## User Work Preferences (Discovered)

These preferences were observed during real usage and should be applied:

- **Batch work style**: User says "多搞几轮" — prefer continuous execution without stopping for confirmation at each step
- **Dashboard preference**: Desktop-level dashboards, NOT mobile-first layouts
- **Data retention**: Q&A raw data must be preserved in three layers (raw_input → transcribed_text → structured_result), never deleted
- **Search caching**: Today's incomplete data marked "in progress", historical retrieved data returned from local cache
- **Reference data**: DateUse cache data copied to project for reference even if not uploaded or actively used
- **Governance tools mandatory**: todo/task_board/progress/ADR/graphify must be actively used — user explicitly fears losing track of architecture and progress mid-work

## Related Skills

- `writing-plans` - For detailed project planning
- `obsidian` - If using Obsidian for project docs
- `github-pr-workflow` - For code management across projects
- `clm-project-role-identity` - CLM-specific agent role management
- `clm-cloud-environment-handoff` - CLM cloud environment handoff
