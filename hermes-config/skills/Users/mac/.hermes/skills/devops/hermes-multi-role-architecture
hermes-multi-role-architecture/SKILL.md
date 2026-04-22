---
name: hermes-multi-role-architecture
category: devops
description: Manage multiple role identities (personas) within a single Hermes Agent instance — architecture, isolation model, and how to add new roles
tags: [hermes, multi-role, persona, architecture, memory, isolation]
created: 2026-04-12
---

# Hermes Multi-Role Architecture

## Core Architecture

Hermes Agent is a **single instance** with **shared global memory**. Multiple "roles" are NOT separate Agent processes — they are separate conversation sessions that share the same memory file and skill library.

```
Hermes Agent（单一软件实例）
  └── 全局 memory（~/.hermes/memories/MEMORY.md）← 所有会话共享
  └── 全局 skills（~/.hermes/skills/）             ← 所有会话共享
  └── 全局 config（~/.hermes/config.yaml）        ← 一套配置
        ├── Session A（大管家对话框）← 能读到所有 memory
        ├── Session B（小厨对话框）  ← 能读到所有 memory
        ├── Session C（狗蛋对话框）  ← 能读到所有 memory
        └── Session D（小妹对话框）  ← 能读到所有 memory
```

### What IS isolated
- **对话上下文（session history）** — 每个对话框有独立的 conversation history
- **会话恢复** — 每个 session 独立加载，不自动加载其他 session 的对话

### What is NOT isolated
- **Memory** — 所有 session 共享同一份 MEMORY.md + USER.md
- **Skills** — 所有 session 共享同一套 skills
- **Config** — 所有 session 共享 config.yaml
- **Session search** — 跨所有 session 全局搜索

## Role Identity Pattern

Roles are distinguished by:
1. **Name convention** — user calls a specific name in a new session (e.g. "狗蛋")
2. **Memory registration** — the role's identity and scope is saved in MEMORY.md
3. **Session context** — the agent recognizes the role from the user's greeting and reads relevant memory entries

### How to Add a New Role

1. **Define the role** — name, purpose, scope
2. **Register in memory** — use `memory` tool to add the role to the "角色区分" entry in MEMORY.md
3. **Confirm with user** — tell them the role is registered and what it can do

```
Example: Adding "狗蛋"
- 角色: 软件架构师
- 职责: 源码分析、代码结构解析、核心软件技能抽象、技术基建沉淀
- memory 操作: memory(action='replace', target='memory', content='更新角色区分条目')
```

## Isolation Level

This is **weak isolation** (约定式隔离):
- All information is visible to every session
- Roles stay separate by discipline, not system enforcement
- Memory has a hard char limit (2200 for MEMORY.md, 1375 for USER.md)

### Limitations
1. Memory capacity is limited — entries compete for space
2. Any session can read/write all memory — hand-editing can pollute other roles
3. session_search returns results from ALL sessions, not just the current role
4. No per-role persona files — AGENTS.md/SOUL.md apply globally

### When weak isolation is sufficient
- Roles have clearly separated responsibilities
- User discipline in keeping conversations in the correct dialog
- Memory entries are kept concise and role-tagged

### When strong isolation is needed
- Different roles need different secrets/credentials
- Memory pollution is unacceptable
- Per-role tone/persona is required
- **Solution:** Multiple Hermes instances with separate `~/.hermes-*` directories (not yet implemented)

## Historical Context

This architecture limitation was also present in **OpenClaw** (the predecessor):
- OpenClaw had `agents.list` config but only supported 2 native agents (main, cf)
- Other roles were simulated via "virtual role mode" (prefix-based identity) or subagent spawning
- User discovered the same issue in March 2026: "所有角色都是同一个 agent (main) 在扮演，没有真正的并行和隔离"

## Existing Roles (as of 2026-04-12)

| Role | Purpose | Project/Scope |
|------|---------|---------------|
| 大管家 | Local project management, all-machine coordination | Global |
| 小厨/小强 | CLM-REVIEW-TOOL (口味工程师日总结系统) | /Users/mac/Projects/clm-tools-kw/ |
| 小妹 | Kawaii tone, responsibilities TBD | TBD |
| 狗蛋 | Software architect, code analysis, skill abstraction | Global |

## Pitfalls

1. **Do NOT confuse session with Agent** — A session is a conversation thread. The Agent is the software. Multiple sessions = multiple conversations, not multiple Agents.
2. **Do NOT expect per-role memory isolation** — Everything in MEMORY.md is visible to every session.
3. **Do NOT overload memory** — 2200 char limit means entries must be terse. Use docs/ in project directories for detailed information.
4. **Do NOT mix role conversations** — Keep each role in its own dialog window. If the user says "狗蛋", you are in the dog-egg persona session.