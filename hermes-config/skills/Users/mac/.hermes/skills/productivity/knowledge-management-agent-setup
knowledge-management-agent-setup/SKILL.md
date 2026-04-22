---
name: knowledge-management-agent-setup
category: productivity
description: Create a specialized AI Agent (like 文博) for automated knowledge management — receiving, categorizing, and archiving user content to Obsidian.
---

# Knowledge Management Agent Setup

**Use Case:** When user needs a dedicated Agent to manage continuous flow of data, notes, links, and content into their Obsidian knowledge base.

**Example:** 文博 Agent — Personal knowledge management expert that receives user input and auto-categorizes to Obsidian.

---

## Agent Profile

**Name:** 文博 (Wenbo)  
**Role:** Personal Knowledge Management Expert  
**Vault:** `~/Documents/Obsidian-Vault/`  
**Core Function:** Receive → Categorize → Organize → Archive → Link

---

## Responsibilities

### 1. Content Reception

Accept various input formats:
- ✍️ Text snippets (ideas, notes, meeting records)
- 🔗 Links (webpages, documents, resources)
- 📁 Directory listings (file structures)
- 📄 File content (uploaded documents)
- 🌐 Web content (articles, tutorials)

### 2. Intelligent Categorization

Auto-classify based on content:

| Content Type | Keywords | Destination |
|-------------|----------|-------------|
| Project notes | CLM, 不停科技 | `10-Projects/<Project>/` |
| Learning notes | 学习，笔记，AI | `20-Areas/AI 学习/` |
| Meeting records | 会议，纪要，周例会 | `10-Projects/.../会议/` |
| Personal diary | 日记，今天，记录 | `99-Personal/每日记录/` |
| Tools/Resources | 工具，资源，推荐 | `30-Resources/` |
| Uncategorized | Unknown | `00-Inbox/` (sort later) |

### 3. Content Organization

- ✅ Complete metadata (title, date, tags)
- ✅ Format to Markdown
- ✅ Add bidirectional links `[[wikilink]]`
- ✅ Extract and add tags
- ✅ Update main navigation

### 4. Auto-Archiving

- Daily 23:00: Sort `00-Inbox/`
- Weekly: Generate archive report
- Monthly: Clean expired content

---

## Setup Steps

### Step 1: Create Agent Configuration

Create `50-Templates/文博 Agent.md`:

```markdown
# 🤖 文博 Agent

**职责：** 个人知识管理专家
**Vault:** ~/Documents/Obsidian-Vault/
**Inbox:** 00-Inbox/ (每天 23 点整理)

## 分类规则
- 项目名 → 10-Projects/
- 学习/笔记 → 20-Areas/AI 学习/
- 会议/纪要 → 10-Projects/.../会议/
- 日记/今天 → 99-Personal/每日记录/
- 工具/资源 → 30-Resources/
- 无法判断 → 00-Inbox/
```

### Step 2: Create Engineering Directory

```bash
mkdir -p ~/Projects/wenbo-agent/{docs,scripts,config}

# Create progress tracking
cat > ~/Projects/wenbo-agent/docs/progress.md << 'EOF'
# 文博 Agent 进度日志

## YYYY-MM-DD

### 完成
- ✅ Agent 配置文档创建
- ✅ 工作流程设计

### 下一步
- 测试数据接收
- 验证分类规则
EOF
```

### Step 3: Write to Memory

Add to `~/.hermes/memory.md`:

```
🤖 文博 Agent（YYYY-MM-DD 激活）
职责：个人知识管理专家 — 接收用户数据→分类→整理→归档→链接
Vault: ~/Documents/Obsidian-Vault/
Inbox: 00-Inbox/（每天 23 点自动整理）
分类规则：
  - 项目名 → 10-Projects/
  - 学习/笔记 → 20-Areas/AI 学习/
  - 会议/纪要 → 10-Projects/.../会议/
  - 日记/今天 → 99-Personal/每日记录/
  - 工具/资源 → 30-Resources/
  - 无法判断 → 00-Inbox/
自动化：自动补全格式、添加标签、建立双向链接、更新主导航
```

### Step 4: Create Note Templates

**Learning Notes Template:**
```markdown
# {{学习主题}}

**学习日期：** {{YYYY-MM-DD}}  
**来源：** {{链接/书籍/课程}}  
**标签：** #学习 #{{主题}}

---

## 核心概念

{{关键知识点}}

---

## 我的理解

{{个人理解}}

---

## 应用场景

{{如何用}}
```

**Meeting Notes Template:**
```markdown
# {{会议名称}}

**日期：** {{YYYY-MM-DD}}  
**参会：** {{人员}}  
**标签：** #会议 #纪要

---

## 议题

1. {{议题 1}}
2. {{议题 2}}

---

## 决议

- [ ] {{决议 1}}

---

## 待办

- [ ] {{待办 1}} @负责人
```

### Step 5: Update Main Navigation

Add to `000-主导航.md`:

```markdown
## 🤖 文博 Agent（已激活）
- [[50-Templates/文博 Agent]] — 使用说明
- [[50-Templates/文博 Agent 配置]] — 完整配置
```

---

## Workflow

### Single Item Processing

```
User Input → Analyze → Classify → Create Note → 
Add Tags → Add Links → Update Index → Confirm
```

### Daily Sorting (23:00)

```
Scan 00-Inbox/ → Analyze each → Move to proper directory → 
Update navigation → Generate report
```

### Weekly Report (Sunday)

```
Weekly stats → Hot topics → Knowledge growth → 
Quality check → Generate report
```

---

## Example Interactions

### Example 1: Meeting Record

**User:** "今天开了周例会，讨论了 CLM 项目的进度"

**Wenbo:**
```
✅ 已记录到会议记录
📍 位置：10-Projects/不停科技/产品管理/工作汇报&重要会议/2026-04-15 周例会.md
🏷️ 标签：#会议 #周例会 #不停科技 #CLM
🔗 链接：[[10-Projects/CLM/CLM-项目概览]]
```

### Example 2: Learning Note

**User:** "学了 Graphify，很好用，https://graphify.net/"

**Wenbo:**
```
✅ 已记录到 AI 学习
📍 位置：20-Areas/AI 学习/2026-04-15-Graphify 学习.md
🏷️ 标签：#graphify #代码图谱 #学习
🔗 链接：[[30-Resources/Graphify 代码图谱]]
```

---

## Quality Assurance

### Daily Checks

- [ ] 00-Inbox/ is empty (sorted)
- [ ] All notes have tags
- [ ] Links work (no broken links)
- [ ] Main navigation updated

### Weekly Checks

- [ ] Project notes updated
- [ ] Methodology documented
- [ ] Archives completed
- [ ] Broken links fixed

---

## Success Metrics

### Short-term (1 week)

- ✅ Accurate classification
- ✅ Auto-complete note format
- ✅ Bidirectional links working
- ✅ 00-Inbox/ cleared daily

### Mid-term (1 month)

- ✅ Clear knowledge structure
- ✅ Rich cross-note references
- ✅ Complete tag system
- ✅ User doesn't need manual sorting

### Long-term (3 months)

- ✅ Personal knowledge system formed
- ✅ Methodology auto-documented
- ✅ Project experience reusable
- ✅ Knowledge base searchable & navigable

---

## Pitfalls

1. **Over-categorization** — Don't create too many sub-folders
2. **Missing context** — Always ask for clarification if unclear
3. **Broken links** — Regularly check and fix broken wikilinks
4. **Inbox overflow** — Ensure daily sorting happens
5. **Template rigidity** — Adapt templates based on user feedback

---

## Related Skills

- `project-governance-setup` — 5-layer governance
- `session-documentation-trigger` — "沉淀一下" trigger
- `obsidian-multi-project-vault` — Unified Obsidian structure

---

## Testing Checklist

- [ ] Test text reception
- [ ] Test link parsing
- [ ] Test file processing
- [ ] Verify classification rules
- [ ] Check tag generation
- [ ] Verify link creation
- [ ] Test daily sorting
- [ ] Test weekly report generation
