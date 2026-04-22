---
name: gaoclaw-deployment
category: devops
description: gaoclaw 配置包部署 - 多设备 Hermes 配置同步与一键安装
tags: [gaoclaw, hermes, deployment, multi-device, sync]
created: 2026-04-18
---

# gaoclaw 配置包部署 Skill

## 用途
将 Hermes 增强配置（gaoclaw）部署到新设备，实现多设备配置同步。

## 核心优势

比 Hermes 原生强在哪里：

| 功能 | Hermes 原生 | gaoclaw 增强版 |
|------|-------------|---------------|
| 角色隔离 | ❌ 单实例 | ✅ 多 Profile 物理隔离 |
| 会话管理 | ❌ 全局搜索污染 | ✅ 标签系统精确过滤 |
| 命令审计 | ❌ 无 | ✅ 完整审计日志 |
| 自动化收尾 | ❌ 手动 | ✅ 自动 Session 收尾 |
| 健康检查 | ❌ 无 | ✅ 双重心跳机制 |
| 故障转移 | ❌ 单 Provider | ✅ 多 Provider 自动切换 |

## 三件套：备份 → 恢复 → 验证

| 脚本 | 用途 | 何时运行 |
|------|------|----------|
| `gaoclaw-backup.sh` | 备份当前状态到 GitHub | 每周一次，或重大变更后 |
| `gaoclaw-restore.sh` | 从 GitHub 恢复到新设备 | 换电脑、系统重装后 |
| `gaoclaw-verify.sh` | 验证环境是否完整 | 恢复后立即运行 |

### 备份流程（当前设备）

```bash
cd ~/Projects/gaoclaw
./gaoclaw-backup.sh
```

**备份内容：**
- `config.yaml`（自动脱敏，密钥替换为占位符）
- `memory.md`（完整记忆文档）
- `skills/`（所有自定义 Skills）
- `profiles/`（角色配置）
- 各项目的 `AGENTS.md`
- `environment-manifest.md`（环境清单：工具版本、依赖列表）

**不备份（安全考虑）：**
- API 密钥 → 恢复后手动填入 `.env`
- `auth.json` → 会话 Token，可重新登录
- `sessions/` → 历史会话，太大且可重建
- `state.db` → 运行时数据库，自动重建

### 恢复流程（新设备）

```bash
# 1. 克隆配置仓库
git clone git@github.com:gaogoying-sudo/gaoclaw.git ~/Projects/gaoclaw

# 2. 一键恢复
cd ~/Projects/gaoclaw
./gaoclaw-restore.sh

# 3. 填入密钥
nano ~/.hermes/.env
# 填入 DASHSCOPE_API_KEY 和 OPENROUTER_API_KEY

# 4. 验证环境
./gaoclaw-verify.sh

# 5. 登录 Codex
codex login
```

**一行命令恢复（临时设备）：**
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/gaogoying-sudo/gaoclaw/main/gaoclaw-restore.sh)" \
    git@github.com:gaogoying-sudo/gaoclaw.git
```

### 验证流程

```bash
./gaoclaw-verify.sh
```

**输出示例：**
```
✅ 通过：15
⚠️  警告：2    ← 比如 ".env 还没填密钥"
❌ 失败：0
```

如有 `❌ 失败`，环境不完整，不能开始用。

### 自动化备份

```bash
# 每周一定时备份（cronjob 已配置）
# job_id: 7ddbb339c160
# 调度：0 9 * * 1（每周一 9:00）
```

## 完整仓库结构

```
gaoclaw/
├── install.sh                    # 一键安装脚本（旧版，保留兼容）
├── restore.sh                    # Git 恢复脚本（旧版，保留兼容）
├── gaoclaw-backup.sh             # 一键备份脚本（新版）
├── gaoclaw-restore.sh            # 一键恢复脚本（新版）
├── gaoclaw-verify.sh             # 环境验证脚本（新版）
├── BACKUP-GUIDE.md               # 备份恢复完整指南
├── README.md                     # 项目文档
├── LICENSE                       # 个人使用许可
├── .gitignore                    # 排除敏感文件
├── hermes-config/
│   ├── config.yaml               # Hermes 配置（脱敏）
│   ├── memory.md                 # Memory 文档
│   ├── profiles/                 # 角色配置
│   ├── skills/                   # 自定义 Skills
│   └── scripts/                  # 辅助脚本
├── project-configs/              # 各项目 AGENTS.md
│   └── AGENTS-clm-tools-kw.md
└── environment-manifest.md       # 环境清单（自动更新）
```

## 核心代码修改（根治方案）

### 1. 会话标签系统

**修改文件：**

1. `hermes_state.py`
   - sessions 表添加 `tags TEXT` 列
   - `create_session()` 添加 `tags` 参数
   - `search_messages()` 添加 `tags_filter` 参数

2. `session_search_tool.py`
   - `session_search()` 添加 `tags_filter` 参数
   - 解析逗号分隔的 tags 字符串

3. `run_agent.py`
   - `AIAgent.__init__()` 添加 `session_tags` 参数
   - 传递给 `create_session(tags=session_tags)`

**数据库迁移：**
```bash
python3 ~/.hermes/scripts/migrate_add_session_tags.py
```

**使用方式：**
```python
# 创建带标签的会话
AIAgent(session_tags="admin,project-a")

# 按标签搜索
session_search(query="API 配置", tags_filter="admin")
```

### 2. 命令审计系统

**创建文件：**
- `tools/terminal_audit.py` - 审计函数
- `scripts/terminal-audit-query.py` - 查询工具

**审计日志格式：**
```json
{
  "timestamp": "2026-04-18T16:00:00",
  "session_id": "xxx",
  "command": "git status",
  "exit_code": 0,
  "duration_seconds": 0.5,
  "output_preview": "On branch main..."
}
```

## 敏感信息处理

**绝不上传到 Git 的内容：**

```
.env                    # API Keys
auth.json               # OAuth tokens
*.db                    # 会话数据库
logs/                   # 日志文件
sessions/               # 会话记录
```

**每台设备单独配置：**

```bash
# 安装后运行
hermes setup

# 或手动编辑
vim ~/.hermes/.env
```

## 安全检查清单

### 上传前检查

```bash
# 1. 扫描敏感关键词
cd ~/Projects/gaoclaw
grep -r "cli_a92b" . || echo "✅ 无 APP_ID 泄露"
grep -r "82\.156\." . || echo "✅ 无云 IP 泄露"
grep -r "oc_c2ea" . || echo "✅ 无 chat_id 泄露"

# 2. 检查 .gitignore
cat .gitignore

# 3. 查看待提交文件
git status
```

### 配置文件占位符

**❌ 不要这样：**
```yaml
CLOUD_IP: 82.156.187.35
APP_ID: cli_a92b81d03838dbb3
```

**✅ 应该这样：**
```yaml
CLOUD_IP: YOUR_CLOUD_IP
APP_ID: YOUR_APP_ID
```

## 完整部署流程（实战经验）

### 第一阶段：本地创建（15 分钟）

```bash
# 1. 创建项目目录
mkdir -p ~/Projects/gaoclaw
cd ~/Projects/gaoclaw
git init

# 2. 创建核心文件
# - README.md, LICENSE, .gitignore
# - install.sh, restore.sh
# - hermes-config/ 目录结构

# 3. 复制配置（排除敏感文件）
cp ~/.hermes/config.yaml hermes-config/
cp ~/.hermes/memory.md hermes-config/
cp -r ~/.hermes/profiles/ hermes-config/
cp -r ~/.hermes/scripts/ hermes-config/

# 4. 删除敏感文件
find hermes-config -name ".env" -delete
find hermes-config -name "auth.json" -delete
find hermes-config -name "*.db" -delete
```

### 第二阶段：GitHub 推送（10 分钟）

```bash
# 1. 配置 SSH（多 Key 环境）
cat >> ~/.ssh/config << 'EOF'
Host github.com-gaoclaw
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_yourkey
    IdentitiesOnly yes
EOF

# 2. 添加 remote（直接编辑 .git/config）
cat >> .git/config << 'EOF'

[remote "origin"]
	url = git@github.com-gaoclaw:YOUR_USERNAME/gaoclaw.git
	fetch = +refs/heads/*:refs/remotes/origin/*
EOF

# 3. 提交并推送
git add -A
git commit -m "Initial commit: gaoclaw v1.0.0"
git branch -M main
git push -u origin main
```

### 第三阶段：新设备安装（5 分钟）

```bash
# 一键安装
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/gaoclaw/main/install.sh | bash

# 配置 API Key
hermes setup

# 验证
hermes profile list
```

### 经验教训

1. **先检查再推送** - 用 grep 扫描敏感词
2. **SSH 多 Key 配置** - 用 `github.com-gaoclaw` 别名
3. **Git URL 污染** - 直接编辑 .git/config，不要用 git 命令
4. **强制推送准备** - 如果泄露敏感信息，`git push -f` 覆盖历史

### 拉取更新

```bash
cd ~/.hermes-config
git pull
bash restore.sh
```

### 推送本地变更

```bash
cd ~/Projects/gaoclaw
git add .
git commit -m "更新：添加新功能"
git push origin main
```

## 故障排查

### 问题 1：Profile 未创建

**症状：** `hermes profile list` 不显示 admin/dev/architect

**解决：**

```bash
# 重新运行恢复脚本
bash ~/.hermes-config/restore.sh

# 或手动创建
hermes profile create admin --clone
hermes profile create dev --clone
hermes profile create architect --clone
```

### 问题 2：Git URL 污染

**症状：** `git remote add` 命令报错 "unknown switch `S'"

**原因：** Git 命令被注入 `-S -p ''` 后缀

**解决：**

```python
# 直接编辑 .git/config（不要用 git 命令）
from pathlib import Path
git_config = Path(".git/config")
content = git_config.read_text().replace(" -S -p ''", "")
git_config.write_text(content)
```

### 问题 3：数据库迁移失败

**症状：** session tags 功能不可用

**解决：**

```bash
# 运行数据库迁移脚本
python3 ~/.hermes/scripts/migrate_add_session_tags.py
```

### 问题 4：SSH 认证失败

**症状：** `Permission denied (publickey)` 推送 GitHub 失败

**解决：**

```bash
# 配置 SSH（多 Key 环境）
cat >> ~/.ssh/config << 'EOF'
Host github.com-gaoclaw
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_yourkey
    IdentitiesOnly yes
EOF

# 测试连接
ssh -T git@github.com-gaoclaw
```

### 问题 5：敏感信息已上传

**症状：** 不小心上传了 API Key、云 IP 等敏感信息

**紧急处理：**

```bash
# 1. 立即删除本地敏感内容
# 编辑文件，用占位符替换真实值

# 2. 强制推送覆盖历史
cd ~/Projects/gaoclaw
git add -A
git commit -m "Fix: 删除敏感信息"
git push -f origin main

# 3. 联系 GitHub 支持清除缓存（如果已公开）
```

## 角色说明（通用版）

| 角色 | Profile 名 | 职责 | 使用场景 |
|------|-----------|------|---------|
| 管理员 | admin | 整机所有项目总控台 | 跨项目协调、系统健康检查 |
| 开发者 | dev | 项目开发专属 | 具体功能开发、第三方集成 |
| 架构师 | architect | 技术分析 | 代码分析、架构评估、技术选型 |

**自定义角色：**

```bash
# 创建新 Profile
hermes profile create newrole --clone

# 编辑人格配置
vim ~/.hermes/profiles/newrole/SOUL.md
```

## 更新与维护

**当前电脑：**
```bash
cd ~/Projects/gaoclaw
# 修改配置...
git add -A
git commit -m "更新：xxx"
git push
```

**新设备：**
```bash
cd ~/.hermes-config
git pull
bash restore.sh
```

## 非商业声明

> **本项目纯属个人学习研究使用，不涉及任何商业行为。**
>
> - ✅ 完全开源，基于 Hermes Agent
> - ✅ 个人学习、研究、娱乐目的
> - ✅ 未来 Hermes 升级后，会同步升级本配置包
> - ❌ 不用于任何商业用途
> - ❌ 不提供任何商业支持

## 相关资源

- GitHub: https://github.com/gaogoying-sudo/gaoclaw
- Hermes Agent: https://github.com/NousResearch/hermes-agent
- 安装脚本：https://raw.githubusercontent.com/gaogoying-sudo/gaoclaw/main/install.sh
