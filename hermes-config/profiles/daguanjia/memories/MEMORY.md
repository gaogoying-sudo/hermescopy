_Last updated: 2026-03-05 19:57_
§
---
§
📌 CLM-REVIEW-TOOL（小厨/小强）| 路径：/Users/mac/Projects/clm-tools-kw/ | 云 IP: 82.156.187.35 | 阶段：T101+T102 完成→T105/T106/T109 | 五层治理
§
**角色区分（重要！）：**
- 大管家 = 整机所有项目总控台，管理全部本地项目
- 小厨/小强 = CLM-REVIEW-TOOL 项目专属（口味工程师日总结系统），使用 Hermes + 千问模型
- 小妹 = 语气可可爱爱，职责待定
- 狗蛋 = 软件架构师（源码分析、代码结构解析、核心软件技能抽象、思想工程包装、技术基建沉淀）

**机制期望：** 用户不满足于口头承诺，要求有稳定机制确保 AI 行为一致性（如技能检查清单、文档前置读取、输出前角色确认）
§
📱 飞书应用配置（CLM 项目）
- APP_ID: cli_a92b81d03838dbb3
- APP_SECRET: TO17YrJH0FmJdNqkw2ybhgSpMqS8YK0c
- 测试群：CLM 内测小群 ✅
- chat_id: oc_c2eaef0dca9716e687620eec72bbcaa6
- 群主 ID: ou_40025e775477ba7ffce200c9d0bebe02
- 旧群 chat_id: oc_69142130bd9be78794c0840329a76c8c（有老板，不用）
- 配置位置：/opt/clm-review-tool/env/.env.prod
- 安全配置：FEISHU_DRY_RUN=true（先演练）, FEISHU_TEST_MODE=true
§
🔄 下次会话恢复清单（CLM 项目）
1. 读取此 memory 条目确认云环境信息
2. 读取本地文档：~/software project/DateUse/CLM-Cloud-Environment-Handoff.md
3. 飞书配置已完成测试（chat_id: oc_c2eaef0dca9716e687620eec72bbcaa6）
4. 待部署：review-app 代码、data-sync 代码到云服务器
§
🔧 LLM CLI: llm+OpenRouter 已安装。Anthropic 账号禁用，用 OpenRouter Key 调用千问/GPT
§
🔑 用户核心诉求：AI 行为一致性机制
- 不满足于口头承诺，要求稳定机制确保信息不丢失
- 关键环境信息必须持久化（memory + 本地文档 + 技能）
- 会话恢复时必须主动读取 memory 和交接文档
- 如遇到 API 错误（401 等）立即告知用户，不要继续尝试
- OpenRouter API Key 需写入 ~/.zshrc 否则重启失效
§
⚠️ Git远程URL被污染：所有git remote set-url/add命令会在URL中注入 ` -S -p ''` 后缀（如 `git@github.com:gaogoying-sudo -S -p ''/clm-tools-kw.git`）。导致SSH和HTTPS推送均失败。**修复方法：** 直接编辑 `.git/config` 文件中的URL字段，移除污染部分。
§
🔄 心跳工作流：鼠标宏定期发指令驱动 Agent。规则：必须先读 `TASK_BOARD.md`，将 `TODO` 改为 `DOING` 再执行。若已是 `DOING`/`Done` 则不操作，防冲突。依赖项目文件看进度。