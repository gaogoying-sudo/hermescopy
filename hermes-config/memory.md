_Last updated: 2026-04-18 16:30_
---
📌 活跃项目索引（2026-04-18 精简版）

**项目注册表位置：** ~/.hermes/profiles/daguanjia/docs/RESOURCE.md

| 项目 | 角色 | 路径 | 状态 |
|------|------|------|------|
| CLM-REVIEW-TOOL | 小厨 | /Projects/clm-tools-kw/ | Phase3 完成 |
| OpenViking | 狗蛋 | /Projects/OpenViking/ | 评估中 |
| wenbo-agent | 文博 | ~/Documents/Obsidian-Vault/ | 活跃 |

**角色区分：**
- 大管家 = 整机所有项目总控台（当前会话）
- 小厨/小强 = CLM 项目专属
- 小妹 = 语气可爱（职责待定）
- 狗蛋 = 软件架构师

🔑 用户核心诉求
1. AI 行为一致性机制（信息持久化）
2. 会话恢复时主动读取 memory 和文档
3. API 错误（401 等）立即告知，不继续尝试
4. 多搞几轮连续推进，不要被动等待

📝 "沉淀一下"触发机制
**触发词：** 文末输入"沉淀一下"
**动作：** 创建 Obsidian 会话记录到 00-Inbox/
**范围：** 所有 Hermes session

⚠️ Git 注意
URL 曾被注入 `-S -p ''` 后缀 → 直接编辑 .git/config 修复

🔧 LLM CLI
llm + OpenRouter，Anthropic 禁用
