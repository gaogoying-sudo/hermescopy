---
name: session-auto-wrapup
category: productivity
description: 自动化会话收尾流程 - 更新进度日志、任务看板、Memory 检查点、Git 提交
tags: [session, wrapup, automation, governance]
created: 2026-04-18
---

# 自动化会话收尾 Skill

## 用途
在每次会话结束时自动执行收尾工作，确保信息持久化、文档更新、Git 提交。

## 触发方式

### 方式 1：用户说"沉淀一下"或"今天先到这"
AI 自动执行以下流程

### 方式 2：会话超时前
AI 主动提醒用户是否要收尾

## 收尾流程

### 1. 更新进度日志
```markdown
# 会话进度 - YYYY-MM-DD

**时间：** HH:MM - HH:MM
**角色：** [当前角色]
**主题：** [会话主题]

## 完成的工作
- [任务 1]
- [任务 2]

## 下一步
- [待办 1]
- [待办 2]

## 关键决策
- [决策 1]
```

### 2. 更新任务看板
- 读取 docs/TASK_BOARD.md
- 将已完成任务移到 Done 列
- 更新进行中的任务状态

### 3. Memory 检查点
- 检查 Memory 使用率
- 如有重要变更，更新 Memory 索引

### 4. Git 提交
```bash
git add docs/progress.md docs/TASK_BOARD.md
git commit -m "chore: 会话收尾 - YYYY-MM-DD"
git push
```

### 5. Graphify 重建
```bash
python3 -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path('.'))"
```

### 6. Obsidian 笔记（可选）
- 如用户说"沉淀一下"，创建会话记录到 00-Inbox/
- 使用 50-Templates/会话记录模板

## 配置

在项目 AGENTS.md 中添加：

```markdown
## Session Wrapup
- 用户说"沉淀一下"时执行自动收尾
- 会话结束前主动提醒用户
- 收尾流程：进度→任务→Memory→Git→Graphify→Obsidian
```

## 使用示例

```
用户：今天先到这，沉淀一下

AI：好的，正在执行会话收尾...

✅ 更新 docs/progress.md
✅ 更新 docs/TASK_BOARD.md  
✅ Memory 检查点（使用率 52%）
✅ Git commit: "chore: 会话收尾 - 2026-04-18"
✅ Graphify 重建完成
✅ Obsidian 笔记已创建：00-Inbox/2026-04-18-会话记录.md

会话收尾完成！下次见 👋
```

## 注意事项

1. 敏感信息不写入文档
2. Git 提交前确认无敏感文件
3. 如 Git 有冲突，提醒用户手动处理
4. 如 Graphify 未安装，跳过该步骤
