---
name: session-documentation-trigger
category: productivity
description: Implement "沉淀一下" (summarize) trigger mechanism for automatic session documentation across all Hermes sessions via Memory persistence.
---

# Session Documentation Trigger ("沉淀一下")

**Use Case:** When user wants to automatically document a conversation/session to Obsidian for long-term knowledge retention.

**Key Insight:** By writing the trigger mechanism to `~/.hermes/memory.md`, it persists across ALL Hermes sessions, enabling any Agent role to create session records.

---

## Trigger Mechanism

**User Input:** At the end of any conversation, user types:

```
沉淀一下
```

**AI Actions:**
1. Create session record in `00-Inbox/YYYY-MM-DD-主题.md`
2. Fill in: title, date, tags, key decisions, user insights, action items
3. Add bidirectional links to related notes
4. Update `000-主导航.md` with new note link
5. Confirm with location and tags

---

## Session Record Template

```markdown
# YYYY-MM-DD-会话主题

**日期：** YYYY-MM-DD  
**Agent 角色：** [当前角色，如文博/小厨/大管家]  
**标签：** #会话记录 #相关标签

---

## 会话主题

[本次会话的主要议题]

---

## 关键决策

[记录用户做出的决策]

---

## 用户的想法和洞见

[记录用户分享的观点、思考、洞察]

---

## 待办事项

- [ ] [待办 1]
- [ ] [待办 2]

---

## 关联笔记

- [[相关笔记 1]]
- [[相关笔记 2]]

---

**记录时间：** YYYY-MM-DD HH:mm
```

---

## Memory Configuration

Add to `~/.hermes/memory.md`:

```
📝 "沉淀一下"触发机制
**触发词：** 文末输入"沉淀一下"
**动作：** 创建 Obsidian 会话记录到 00-Inbox/
**内容：** 会话主题、关键决策、用户想法、待办、链接
**格式：** 使用 50-Templates/会话记录模板
**范围：** 所有 Hermes session（通过 Memory 持久化）
```

---

## Cross-Session Coverage

This trigger works across ALL Agent roles because:

| Agent Role | Coverage |
|-----------|----------|
| 大管家 (Multi-project) | ✅ |
| 小厨/小强 (CLM) | ✅ |
| 文博 (Knowledge Mgmt) | ✅ |
| 小妹 (Casual) | ✅ |
| 狗蛋 (Architect) | ✅ |
| Any new session | ✅ |

**Why it works:**
1. Memory is auto-injected at session start
2. All Agents read the same Memory
3. All Agents write to same Obsidian Vault

---

## Implementation Steps

### Step 1: Write to Memory

```python
from pathlib import Path
memory_path = Path.home() / ".hermes" / "memory.md"
# Append trigger mechanism config
```

### Step 2: Create Obsidian Template

Create `50-Templates/会话记录模板.md`:

```markdown
# {{日期}}-{{主题}}

**创建日期：** {{YYYY-MM-DD}}  
**创建者：** {{Agent 角色}}  
**标签：** #会话记录 #{{标签}}

---

## 会话主题

{{主题}}

---

## 关键决策

{{决策}}

---

## 用户的想法和洞见

{{想法}}

---

## 待办事项

{{待办}}

---

## 关联笔记

{{链接}}
```

### Step 3: Process Trigger

When user types "沉淀一下":

```python
# 1. Analyze session content
session_summary = analyze_conversation()

# 2. Determine topic and tags
topic = extract_topic(session_summary)
tags = extract_tags(session_summary)

# 3. Create note
note_path = f"00-Inbox/{date}-{topic}.md"
create_note(note_path, template, session_summary)

# 4. Add bidirectional links
add_links(note_path, related_notes)

# 5. Update main navigation
update_main_nav(note_path)

# 6. Confirm to user
print(f"✅ 已沉淀到 Obsidian")
print(f"📍 位置：{note_path}")
print(f"🏷️ 标签：{tags}")
```

---

## Example Usage

### Example 1: Project Discussion

**User:**
```
今天 CLM 项目完成了检索页和问答页，
接下来修复 GitHub push 问题。

沉淀一下
```

**AI Response:**
```
✅ 已沉淀到 Obsidian
📍 00-Inbox/2026-04-15-CLM 项目进度.md
🏷️ #会话记录 #CLM #进度
🔗 [[10-Projects/CLM/CLM-项目概览]]
```

### Example 2: Learning Share

**User:**
```
学了 Graphify，代码图谱很好用

沉淀一下
```

**AI Response:**
```
✅ 已沉淀到 Obsidian
📍 00-Inbox/2026-04-15-Graphify 学习.md
🏷️ #会话记录 #graphify #学习
🔗 [[30-Resources/Graphify 代码图谱]]
```

---

## Quality Checklist

After each "沉淀一下":

- [ ] Note has complete format (title, date, tags)
- [ ] Key decisions recorded
- [ ] User insights captured
- [ ] Bidirectional links added
- [ ] Main navigation updated
- [ ] Confirmation provided to user

---

## Daily/Weekly Processing

### Daily (23:00) - 文博 Agent

- Sort `00-Inbox/` notes to proper directories
- Generate daily summary report
- Update project notes

### Weekly (Sunday)

- Generate weekly knowledge growth report
- Review and optimize categorization
- Archive completed items

---

## Pitfalls

1. **Forgetting to check for trigger** — Always scan end of user message
2. **Generic topic names** — Extract specific topic from conversation
3. **Missing links** — Auto-detect project names and link to relevant notes
4. **Not updating navigation** — Remember to update `000-主导航.md`
5. **Memory not persisted** — Verify `~/.hermes/memory.md` is written

---

## Related Skills

- `project-governance-setup` — 5-layer governance architecture
- `obsidian-multi-project-vault` — Unified Obsidian structure
- `hermes-multi-role-architecture` — Multiple Agent roles

---

## Testing

Test the trigger in different sessions:

1. **CLM Session:** "小厨，继续开发检索页... 沉淀一下"
2. **General Session:** "今天学了新知识... 沉淀一下"
3. **Meeting Session:** "刚开了周例会... 沉淀一下"

Verify:
- Note created in correct location
- Tags are relevant
- Links work
- Navigation updated
