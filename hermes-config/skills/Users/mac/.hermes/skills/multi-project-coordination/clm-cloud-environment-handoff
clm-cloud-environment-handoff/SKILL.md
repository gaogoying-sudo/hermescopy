---
name: clm-cloud-environment-handoff
description: CLM 项目云环境信息获取后的标准交接流程 —— 确保关键信息持久化保存，避免每次会话重新检索
category: multi-project-coordination
---

## 触发条件
当获取到 CLM-REVIEW-TOOL 项目云环境的关键信息后（如 SSH 认证、目录结构、服务状态、配置路径等），必须立即执行此流程。

**会话开始时也必须执行：** 先读取 memory 确认已有信息，避免重新检索。

## 核心原则
**禁止口头承诺，必须持久化保存。** 用户不满足于"我记住了"，要求有稳定机制确保信息不丢失。

**用户原话：** "如果你每次都不能自主地去找到过去的历史信息，我是没有办法和你合作的。"

## 执行步骤

### 1. 会话开始：读取 memory 确认现状（必须做）
- 读取 CLM-REVIEW-TOOL 项目的 memory 条目
- 确认云环境信息是否完整（IP、目录、SSH、服务状态、配置路径）
- 如有缺失，立即补充

### 2. 获取新信息后：立即更新 memory（必须做）
更新 CLM-REVIEW-TOOL 项目的 memory 条目，包含：
- 云 IP 地址
- 部署目录
- SSH 认证方式（密钥路径用"本地有密钥"描述，避免敏感词触发安全过滤）
- 运行中的容器/服务
- 关键配置文件路径
- 待完成事项清单

**注意：** Memory 有安全过滤，避免使用"ssh_access"、"密钥内容"、"密码明文"等模式。用"SSH 认证：本地有密钥，用户 root"这种描述方式。

### 3. 创建本地交接文档（跨团队协作时）
当需要与其他 AI 协作（Codex、Cursor）时，创建完整的本地交接文档：
- 文档位置：`~/software project/DateUse/CLM-Cloud-Environment-Handoff.md`
- 包含：SSH 信息、目录结构、服务状态、数据库配置、飞书配置、待办清单
- 用途：直接转发给协作方，避免重复沟通

### 4. 检索本地已有配置（避免重复工作）
在询问用户之前，先检索本地是否有已有配置：
- 搜索 `.env` 文件中的飞书配置、数据库配置
- 搜索 `get_chat_id.py` 等工具脚本
- 避免让用户重复提供已有信息

### 5. 监控 memory 使用量
- 当前 memory 上限：2,200 chars
- 使用量超过 70% 时，考虑将详细文档移到本地文件
- Memory 只保留关键索引信息

### 4. 会话结束前确认
在会话结束前，再次确认 memory 已包含本次获取的所有关键信息。

### 5. Memory 空间管理
- 定期检查 memory 使用率（上限 2,200 chars）
- 如超过 75%，优先保留：云环境核心配置 > 飞书配置 > 待办事项
- 详细信息放入本地文档，memory 只存索引和关键值
- 如接近上限，清理已完成项目的条目
- 确认本地交接文档已更新

## 禁止行为
- ❌ 只依赖 session_search 检索历史信息
- ❌ 口头承诺"我记住了"但不保存
- ❌ 在 memory 中保存敏感信息（SSH 密钥内容、数据库密码明文等）
- ❌ 会话开始时不先读 memory 就直接操作

## 验证方法
下次会话开始时，先读取 memory 中的云环境信息，确认是否完整。如有缺失，立即补充。

## 会话恢复标准流程（用户呼唤"小厨上线"时）
1. **立即读取 memory** → 确认 CLM 项目条目存在
2. **读取本地交接文档** → `~/software project/DateUse/CLM-Cloud-Environment-Handoff.md`
3. **输出状态速览** → 云 IP、部署目录、当前阶段、待办事项
4. **验证 API 配置** → 确认主模型可用（如遇到 401 错误，立即告知用户）
5. **等待用户指令** → 不要主动执行操作，先分析需求

## 常见陷阱
- ❌ 会话恢复时不读 memory 就直接回答问题
- ❌ 遇到 API 错误不告知用户，继续尝试其他操作
- ❌ 把"小厨"和"大管家"角色混淆
- ❌ 口头承诺"记住了"但不写入 memory

## 相关文件
- Memory 条目：CLM-REVIEW-TOOL 项目、飞书应用配置
- 云上文档：/opt/clm-review-tool/DEPLOYMENT.md
- 本地文档：`~/software project/DateUse/CLM-Cloud-Environment-Handoff.md`
- 工具脚本：`~/software project/DateUse/get_chat_id.py`

## 相关文件
- Memory 条目：CLM-REVIEW-TOOL 项目
- 云上文档：/opt/clm-review-tool/DEPLOYMENT.md
- 本地文档：CLM-Tools/docs/progress.md, DateUse/docs/progress.md
- 交接文档：~/software project/DateUse/CLM-Cloud-Environment-Handoff.md

## API/模型配置检查
- 主模型（qwen3.5-plus / qwen3.6-plus）：通常由 Hermes 配置自动处理
- 降级模型（google/gemini-2.5-flash via OpenRouter）：需要 `OPENROUTER_API_KEY` 环境变量
- 如遇到 HTTP 401 错误，立即告知用户，不要继续尝试
- OpenRouter Key 应持久化到 `~/.zshrc`，否则重启后失效
