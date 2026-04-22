---
name: obsidian-multi-project-vault
category: productivity
description: Design and implement a unified Obsidian vault architecture for multiple AI agents and projects — integrates existing user content with AI-generated notes, enables cross-project linking while maintaining clear isolation.
---

# Obsidian Multi-Project Vault Architecture

**Use Case:** When a user has multiple AI agent projects (大管家、小厨、狗蛋 etc.) and existing Obsidian content, design a unified vault that:
- Integrates existing user notes with new AI-generated content
- Supports multiple projects with clear isolation
- Enables cross-project referencing
- Separates project notes from personal notes and methodology

---

## When to Use

- User has multiple AI agent projects that need knowledge management
- User already has an existing Obsidian vault with content
- Need to integrate old and new content without losing anything
- User wants "one vault to rule them all" with clear structure
- Cross-project knowledge sharing is needed (methodology, lessons learned)

---

## Core Architecture

### Vault Structure (PARA-based)

```
~/Documents/Obsidian-Vault/
│
├── 000-主导航.md              ← Main navigation hub (open this first)
├── 00-整合说明.md             ← Integration documentation
│
├── 00-Inbox/                  ← Inbox (temporary notes, weekly cleanup)
│   └── YYYY-MM-DD-主题.md     ← AI auto-created session records
│
├── 10-Projects/               ← 🚀 Project notes (active projects)
│   ├── CLM/
│   │   ├── CLM-项目概览.md
│   │   ├── CLM-任务看板.md
│   │   ├── CLM-技术选型.md
│   │   └── CLM-项目治理制度.md
│   ├── 不停科技/
│   │   ├── 产品管理/
│   │   └── Cooking LM 系统开发/
│   └── [新项目]/              ← Auto-created for new projects
│
├── 20-Areas/                  ← 🌳 Areas of responsibility (long-term)
│   ├── AI 学习/               ← User's existing AI learning notes
│   │   ├── Hermes/
│   │   ├── 新技术探索/
│   │   └── 工具类 bug 调解/
│   ├── 技术架构/
│   │   └── 五层治理架构.md
│   ├── 产品方法论/
│   └── 个人成长/
│
├── 30-Resources/              ← 📚 Resource library (reusable knowledge)
│   ├── Graphify 代码图谱.md
│   ├── 模板库/
│   │   ├── 会话记录模板.md
│   │   └── 项目概览模板.md
│   └── 代码片段/
│
├── 40-Archives/               ← 🗄️ Archived (completed projects)
│   └── 2024-项目 A/
│
├── 50-Templates/              ← 📝 Templates
│   ├── 会话记录模板.md
│   └── 项目概览模板.md
│
└── 99-Personal/               ← 📔 Personal notes (diary, essays)
    └── 每日记录/
        ├── 2026-04-14.md
        └── 2026-04-13.md
```

---

## Integration Workflow

### Step 1: Analyze Existing Content

```bash
# Find existing Obsidian vault
find ~/Documents -maxdepth 2 -type d -name "*Obsidian*"
find ~/CLM -name "*.md" -type f | head -30

# Identify key content:
# - Personal notes (diary, essays)
# - Project notes (active projects)
# - Methodology (reusable knowledge)
# - Meeting notes
```

### Step 2: Create Unified Structure

```bash
# Backup existing new vault (if any)
cp -r ~/Documents/Obsidian-Vault ~/Documents/Obsidian-Vault.backup

# Create PARA structure
mkdir -p ~/Documents/Obsidian-Vault/{00-Inbox,10-Projects,20-Areas,30-Resources,40-Archives,50-Templates,99-Personal}
```

### Step 3: Migrate Existing Content

```bash
# Map old structure to new PARA:
# Personal → 99-Personal/
# AI Learning → 20-Areas/AI 学习/
# Projects → 10-Projects/
# Product Management → 10-Projects/不停科技/产品管理/

cp -r "/Users/mac/CLM/Doc/Cooking LM/个人记录（纯手敲）" "/Users/mac/Documents/Obsidian-Vault/99-Personal/"
cp -r "/Users/mac/CLM/Doc/Cooking LM/AI 学习" "/Users/mac/Documents/Obsidian-Vault/20-Areas/"
cp -r "/Users/mac/CLM/Doc/Cooking LM/不停科技" "/Users/mac/Documents/Obsidian-Vault/10-Projects/"
```

### Step 4: Create Main Navigation

Create `000-主导航.md` with:
- Links to all major sections
- Dataview queries for recent notes
- Quick links to important documents
- Project status tables

### Step 5: Create Integration Documentation

Create `00-整合说明.md` with:
- What was migrated from where
- New structure explanation
- How to use the unified vault
- What to do with old vault (keep for 1 week, then delete)

### Step 6: Create Welcome Guide

Create `欢迎.md` with:
- Quick start instructions
- Core features (wikilink, search, graph view)
- Important notes to check
- FAQ

---

## AI Auto-Generation Rules

### Session End

```markdown
Create: 00-Inbox/YYYY-MM-DD-主题.md
Content:
- Session goals
- Work completed
- Key decisions
- User insights and thoughts
- Problems and solutions
- Next steps
Links: [[Project-概览]], [[Project-任务看板]]
```

### User Shares Insight

```markdown
If insight is methodology → 20-Areas/对应领域/
If insight is project-specific → 10-Projects/项目/对应笔记
If insight is reusable → 30-Resources/
```

### New Project Start

```markdown
Create: 10-Projects/新项目/
  ├── 新项目 - 概览.md (use template)
  ├── 新项目 - 任务看板.md
  └── 新项目 - 资源登记.md
Update: 000-主导航.md (add to project table)
```

### Technical Decision

```markdown
Create: 10-Projects/项目/decisions/001-决策名.md
Or update: 20-Areas/技术架构/对应主题.md
Link to related projects
```

---

## Cross-Project Linking

### Example 1: Reference Methodology

```markdown
# 大管家 - 技术选型

采用 [[20-Areas/五层治理架构]] 治理框架
参考 [[20-Areas/AI 学习/Hermes/治理咨询 逻辑 实现]]
```

### Example 2: Reference Another Project

```markdown
# 狗蛋 - 项目概览

## 参考经验
- [[10-Projects/CLM/CLM-技术选型]] — CLM 的技术栈选择
- [[10-Projects/不停科技/产品管理/3.0 产品/研发交付/3.0 产品 EMC 专项]] — EMC 专项经验
```

### Example 3: Lessons Learned

```markdown
# 20-Areas/AI 协作方法论

## 来自 CLM 项目的经验
[[10-Projects/CLM/CLM-复盘]] 中学到：
- 每次会话结束必须更新 progress.md
- graphify 改代码前必查

## 来自大管家项目的经验
...
```

---

## Key Design Principles

### 1. One Vault to Rule Them All

**Why:** Cross-project search, linking, backup simplicity

**How:**
- All projects in `10-Projects/`
- All methodology in `20-Areas/`
- All personal in `99-Personal/`

### 2. Clear Separation

| Type | Location | Lifecycle |
|------|----------|-----------|
| Project notes | `10-Projects/` | Archived when project ends |
| Personal notes | `99-Personal/` | Permanent |
| Methodology | `20-Areas/` | Long-term, cross-project |
| Resources | `30-Resources/` | Reusable templates, snippets |
| Temporary | `00-Inbox/` | Weekly cleanup |

### 3. Enable Cross-Pollination

- Use `[[wikilink]]` freely across folders
- Create methodology notes that synthesize learnings from multiple projects
- Link project notes to relevant methodology

### 4. AI Auto-Maintenance

- AI creates session records automatically
- AI updates project status on request
- AI creates methodology notes from user insights
- User focuses on thinking, AI handles organization

---

## Templates

### Session Record Template

```markdown
# {{日期}}-{{项目}}会话记录

**创建日期：** {{YYYY-MM-DD}}
**标签：** #会话记录 #{{项目标签}}

## 🎯 本次会话目标
{{goals}}

## ✅ 完成的工作
{{completed}}

## 💡 关键决策
{{decisions}}

## 🤔 遇到的问题
{{problems}}

## 📝 用户的想法和洞见
{{insights}}

## 🔗 关联笔记
- [[{{项目}}-项目概览]]
- [[{{项目}}-任务看板]]

## ➡️ 下一步
{{next_steps}}
```

### Project Overview Template

```markdown
# {{项目名称}}

**创建日期：** {{YYYY-MM-DD}}
**标签：** #项目 #{{项目标签}}

## 📌 一句话定位
{{one-line description}}

## 🎯 项目目标
{{goals}}

## 🗺️ 知识图谱导航
### 基础笔记
- [[{{项目}}-任务看板]]
- [[{{项目}}-资源登记]]
- [[{{项目}}-技术选型]]

### 上级导航
- [[../../000-主导航]]

## 📊 当前状态
**阶段：** {{current phase}}
**进度：** {{progress}}
**下一步：** {{next action}}

## 🔗 关联笔记
- [[000-主导航]]
- [[20-Areas/技术架构]]
```

---

## Pitfalls

1. **Creating too many vaults** — One vault enables cross-project search and linking
2. **Mixing personal and project notes** — Keep `99-Personal/` separate from `10-Projects/`
3. **Not cleaning Inbox** — Schedule weekly Inbox cleanup
4. **Forgetting to migrate existing content** — Always ask "do you have existing Obsidian content?"
5. **Breaking links during migration** — Test key links after migration
6. **Not creating main navigation** — `000-主导航.md` is essential for orientation

---

## Verification Checklist

### After Integration

- [ ] All existing notes migrated successfully
- [ ] Key documents accessible (check file sizes)
- [ ] `000-主导航.md` links work
- [ ] Cross-project links work
- [ ] Personal notes in correct location
- [ ] Old vault backed up (keep for 1 week)
- [ ] User can find their existing content
- [ ] AI auto-generation paths are clear

### Ongoing

- [ ] Weekly Inbox cleanup
- [ ] Project notes updated on completion
- [ ] Methodology notes created from insights
- [ ] Archives updated when projects end

---

## Related Skills

- `project-governance-setup` — 5-layer governance architecture
- `clm-project-governance` — CLM-specific governance implementation
- `obsidian` — Basic Obsidian operations

---

## Example: CLM + 不停科技 Integration

**Before:**
- CLM notes: `~/Documents/CLM-Obsidian/` (new, empty)
- 不停科技 notes: `~/CLM/Doc/Cooking LM/` (existing, has content)

**After:**
- Unified: `~/Documents/Obsidian-Vault/`
- CLM: `10-Projects/CLM/`
- 不停科技：`10-Projects/不停科技/`
- AI Learning: `20-Areas/AI 学习/` (from existing)
- Personal: `99-Personal/` (from existing)
- Governance: `20-Areas/五层治理架构.md` (new)

**Result:** 32 notes total, all accessible from one vault, cross-referencing enabled.

---

**Version:** 1.0  
**Created:** 2026-04-15  
**Based on:** CLM + 不停科技 integration experience
