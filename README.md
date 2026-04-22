# hermescopy - Hermes 完整灵魂备份与恢复

> 🛡️ 确保你的 Hermes "灵魂"永不丢失 —— 配置、Skills、自启动、行为习惯，全部可还原

---

## 🎯 备份什么？

| 类别 | 内容 | 说明 |
|------|------|------|
| **核心配置** | config.yaml, memory.md, SOUL.md | Hermes 主配置 + 记忆 + 人格定义 |
| **Skills** | 所有自定义 Skills（400+ 文件） | karpathy-guidelines, an-an-task-secretary 等 |
| **Profiles** | 角色配置（大管家/小厨/安安/文博等） | 每个角色的 SOUL.md 和行为规则 |
| **Cronjob** | 定时任务定义（JSON + 清单） | 每日健康检查、月度项目注册、自动备份 |
| **自启动服务** | Launchd plist 文件 | Hermes Gateway、Dashboard、Openclaw 服务、数据库 |
| **项目配置** | 各项目的 AGENTS.md | CLM、Dashboard 等项目的 Agent 规则 |
| **启动脚本** | start-dashboard.sh, docker-compose.yml | 项目启动脚本 |
| **Shell 配置** | .zshrc 自定义部分 | 路径、镜像、环境变量 |
| **环境清单** | 工具版本、依赖列表、项目结构 | 确保可重现的完整清单 |

### ❌ 不备份（安全考虑）

- API 密钥（备份时脱敏，恢复后手动填入）
- auth.json / 会话 Token（可重新登录）
- sessions/ / state.db（运行时数据，自动重建）
- 项目源码（各自有独立 Git 仓库）

---

## 📦 三件套

| 脚本 | 用途 | 何时运行 |
|------|------|----------|
| `hermescopy-backup.sh` | 备份当前状态到 GitHub | 每周一次，或重大变更后 |
| `hermescopy-restore.sh` | 从 GitHub 恢复到新设备 | 换电脑、系统重装后 |
| `hermescopy-verify.sh` | 验证环境是否完整 | 恢复后立即运行 |

---

## 🔄 日常备份

### 手动备份

```bash
cd ~/Projects/hermescopy
./hermescopy-backup.sh
```

### 自动备份（已配置）

每周一早上 9 点自动备份（通过 Hermes cronjob）

---

## 🚀 新设备恢复

### 场景：换了一台新 Mac

```bash
# 1. 克隆配置仓库
git clone git@github.com:gaogoying-sudo/hermescopy.git ~/Projects/hermescopy

# 2. 一键恢复
cd ~/Projects/hermescopy
./hermescopy-restore.sh

# 3. 填入密钥
nano ~/.hermes/.env
# 填入 DASHSCOPE_API_KEY 和 OPENROUTER_API_KEY

# 4. 验证环境
./hermescopy-verify.sh

# 5. 登录 Codex
codex login

# 6. 恢复 shell 配置（可选）
cat ~/Projects/hermescopy/shell-config/.zshrc.custom >> ~/.zshrc
source ~/.zshrc

# 7. 开始使用
hermes
```

### 场景：当前电脑坏了，临时用别人的电脑

```bash
# 一行命令搞定
bash -c "$(curl -fsSL https://raw.githubusercontent.com/gaogoying-sudo/hermescopy/main/hermescopy-restore.sh)" \
    git@github.com:gaogoying-sudo/hermescopy.git
```

---

## 📁 仓库结构

```
hermescopy/
├── hermescopy-backup.sh          # 备份脚本
├── hermescopy-restore.sh         # 恢复脚本
├── hermescopy-verify.sh          # 验证脚本
├── README.md                     # 本文档
├── environment-manifest.md       # 环境清单（自动生成）
│
├── hermes-config/                # Hermes 核心配置
│   ├── config.yaml               # 主配置（脱敏）
│   ├── memory.md                 # 记忆文档
│   ├── SOUL.md                   # 人格定义
│   ├── skills/                   # 所有自定义 Skills
│   │   ├── software-development/
│   │   │   ├── karpathy-guidelines/
│   │   │   └── ...
│   │   ├── productivity/
│   │   │   ├── an-an-task-secretary/
│   │   │   └── ...
│   │   └── ...
│   ├── profiles/                 # 角色配置
│   │   ├── daguanjia/
│   │   ├── xiaochu/
│   │   └── ...
│   └── cron/                     # Cronjob 数据
│       └── cronjob-manifest.md   # 可读清单
│
├── autostart/                    # 自启动服务
│   ├── launchagents/             # Launchd plist 文件
│   │   ├── ai.hermes.gateway.plist
│   │   ├── com.hermes.dashboard.plist
│   │   └── ...
│   └── SERVICES.md               # 服务清单 + 恢复方法
│
├── project-configs/              # 项目配置
│   ├── AGENTS-clm-tools-kw.md
│   ├── AGENTS-hermes-dashboard.md
│   └── ...
│
├── scripts/                      # 启动脚本
│   ├── start-dashboard.sh
│   └── docker-compose.yml
│
└── shell-config/
    └── .zshrc.custom             # Shell 自定义配置
```

---

## 🔐 密钥管理

备份时密钥会被替换为占位符：

```yaml
# 备份到 GitHub 的版本：
providers:
  alibaba:
    keys:
      - DASHSCOPE_API_KEY  # ← 只存变量名，不存值
```

恢复后需要手动填入：

```bash
# 编辑 ~/.hermes/.env
DASHSCOPE_API_KEY="sk-你的真实密钥"
OPENROUTER_API_KEY="sk-or-你的真实密钥"
```

---

## ✅ 验证清单

恢复后运行 `./hermescopy-verify.sh`，检查：

- [ ] Hermes CLI 已安装
- [ ] config.yaml 存在且无占位符
- [ ] .env 存在且已填入密钥
- [ ] memory.md 完整
- [ ] SOUL.md 存在
- [ ] Skills 目录完整（400+ 文件）
- [ ] Profiles 完整（大管家/小厨/安安/文博等）
- [ ] Cronjob 数据存在
- [ ] Codex / Claude Code 已安装
- [ ] 自启动服务已加载
- [ ] CLM 项目 AGENTS.md 存在
- [ ] Karpathy 规范已加载

---

## 🆘 故障排查

**问题：恢复后 Hermes 启动报错**
```bash
hermes config validate
env | grep -E "DASHSCOPE|OPENROUTER"
```

**问题：Skills 加载失败**
```bash
find ~/.hermes/skills -name "SKILL.md" | wc -l
# 应该 > 400
```

**问题：自启动服务没跑起来**
```bash
# 手动加载
launchctl load ~/Library/LaunchAgents/ai.hermes.gateway.plist
launchctl load ~/Library/LaunchAgents/com.hermes.dashboard.plist
```

**问题：Cronjob 没生效**
```bash
# 重启 Hermes Gateway
launchctl kickstart ai.hermes.gateway
```

---

## 📊 备份内容对比

| 内容 | gaoclaw（旧） | hermescopy（新） |
|------|---------------|------------------|
| 配置文件 | ✅ | ✅ |
| Skills | ✅ | ✅ |
| Profiles | ✅ | ✅ |
| Memory | ✅ | ✅ |
| Cronjob | ❌ | ✅ |
| 自启动服务 | ❌ | ✅ |
| 项目 AGENTS.md | ✅ | ✅ |
| 启动脚本 | ❌ | ✅ |
| Shell 配置 | ❌ | ✅ |
| 环境清单 | ✅ | ✅（更详细） |
| 验证脚本 | ✅ | ✅（更完整） |

---

**最后更新**：2026-04-22 | **维护者**：大管家 | **仓库**：https://github.com/gaogoying-sudo/hermescopy
