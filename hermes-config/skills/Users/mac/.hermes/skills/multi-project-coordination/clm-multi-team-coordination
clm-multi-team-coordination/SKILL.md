---
name: clm-multi-team-coordination
description: Coordinate CLM-REVIEW-TOOL project across three teams (CLM-Tools/Cursor, DateUse/Codex, 小厨/Hermes) — handles port allocation, team registration, data handover, and cross-team communication
tags: [clm-review-tool, multi-team, coordination, port-management, documentation]
created: 2026-04-10
---

# CLM-REVIEW-TOOL 多团队协调流程

**适用范围：** CLM-REVIEW-TOOL 项目（口味工程师日总结系统）
**三团队架构：**
- CLM-Tools 团队：Cursor + Cursor 自研模型 → review-app 业务逻辑
- DateUse 团队：VSCode + Codex → data-sync 数据同步
- 小厨：Hermes + 千问模型 → 项目协调/运维部署/文档管理

---

## 1. 端口分配管理

### 1.1 端口冲突预防

两个团队本地开发容易端口冲突（都用 8000/8080），必须预先分配：

| 团队 | 前端 | 后端 API | 数据库 |
|------|------|----------|--------|
| CLM-Tools | 8081 | 8001 | 3307 |
| DateUse | 8082 | 8002 | 3308 |

### 1.2 端口分配文档

创建 `~/Projects/CLM Project/PORT_ASSIGNMENT.md`，包含：
- 端口分配表
- docker-compose.yml 配置示例
- 重启指令（通用）
- 访问地址汇总

### 1.3 团队登记要求

每次团队更新端口/重启容器后，必须到 `~/Projects/CLM Project/TEAM_REGISTER.md` 登记：
- 确认团队身份（CLM-Tools / DateUse）
- 时间戳
- 当前状态（端口已调整/容器已重启/服务可访问）
- 遇到的问题或诉求
- 下一步计划

**登记模板：**
```markdown
### [团队名称] - [YYYY-MM-DD HH:MM]

**确认身份：** CLM-Tools / DateUse
**更新时间：** 2026-04-10 HH:MM (Asia/Shanghai)
**负责人：** @你的名字

**当前状态：**
- [ ] 环境已配置
- [ ] 端口已调整
- [ ] 容器已重启
- [ ] 服务可访问

**今日进展：** ...
**遇到的问题/诉求：** ...
**下一步计划：** ...
```

---

## 2. 数据契约管理

### 2.1 数据交接文档

创建 `~/Projects/CLM Project/docs/DATA_HANDOVER_v1.md`，包含：
- 三团队职责边界（DateUse 写 raw_*/core_*，CLM-Tools 写 biz_*/asset_*）
- 落库策略（同一 MySQL，分层隔离）
- 业务数据链路（从源数据到可回溯回传）
- 验收标准（可对接/可理解/可回溯）
- 飞书推送安全配置
- 运维部署建议

### 2.2 关键架构约束

- review-app **不直连公司源数据库**（只对接 DateUse 写入的 MySQL）
- 回传数据必须**在云端 MySQL 可追溯**（不能只留在飞书/日志里）
- worker 与页面服务资源隔离，避免 Web 容器跑批任务

### 2.3 表结构分层

```
raw_*   → DateUse 写入（原始快照/日志）
core_*  → DateUse 写入（结构化实体）
biz_*   → CLM-Tools 写入（业务会话）
asset_* → CLM-Tools 写入（知识沉淀）
```

---

## 3. 跨平台 AI 协作（Graphify）

### 3.1 三平台架构

| 团队 | 开发平台 | AI 模型 | 职责 |
|------|----------|--------|------|
| CLM-Tools | Cursor | Cursor 自研模型 | review-app 业务逻辑 |
| DateUse | VSCode | Codex | data-sync 数据同步 |
| 小厨 | Hermes | 千问模型 | 项目协调/运维 |

### 3.2 Graphify 跨平台赋能

Graphify 生成通用 graph.json，三个平台都能读取：

```bash
# CLM-Tools 团队
cd ~/software\ project/cursor/CLM-Tools/dailyReport/clm-review-tool
graphify claw install

# DateUse 团队
cd ~/software\ project/DateUse
graphify codex install

# 小厨
cd ~/Projects/CLM\ Project
graphify claw install
```

### 3.3 使用场景

- 接口对齐：查 graph.json 确认两边 API 定义
- 数据流追踪：`graphify path "sync_tasks" "daily_sessions"`
- 架构变更影响：`graphify explain "answers.py"`

---

## 4. 角色一致性检查（小厨专用）

### 4.1 身份确认

小厨在处理 CLM 项目时，必须保持"小厨"身份，不能混淆为"大管家"。

**检查清单（输出对外文档前）：**
1. 当前调用我的指令是什么角色？→ 小厨（CLM 项目）还是大管家（整机管理）？
2. 文档里的称呼是否一致？→ 小厨/大管家
3. 职责范围是否匹配？→ CLM 项目专属 vs 整机所有项目

### 4.2 机制保障

- 记忆保存角色定义（每次会话自动注入）
- 技能保存检查流程（输出前主动调用）
- 文档前置读取（`DATA_HANDOVER_v1.md` + `PORT_ASSIGNMENT.md`）

---

## 5. 验收清单

- [ ] 端口分配文档已创建并分发给两边
- [ ] 团队登记表已创建，团队知道如何登记
- [ ] 数据交接文档已创建，三团队职责清晰
- [ ] Graphify 已集成到三个平台（可选）
- [ ] 云端服务器已部署（82.156.187.35）
- [ ] 飞书测试群模式 + dry-run 已配置

---

## 6. 常见问题

### Q: 端口冲突了怎么办？
A: 立即执行 `docker-compose down`，修改端口配置，重启并登记。

### Q: DateUse 的数据 CLM-Tools 读不到？
A: 检查 MySQL 端口（3307 vs 3308），检查表名前缀（core_* vs biz_*）。

### Q: 飞书推送误发了怎么办？
A: 确保 `FEISHU_TEST_MODE=true` + `FEISHU_DRY_RUN=true`，只发测试群。

### Q: 小厨角色混淆了怎么办？
A: 立即纠正，检查 `memory` 中的角色定义，输出前执行检查清单。

---

## 7. 云部署检查清单（82.156.187.35）

### 7.1 云环境现状

**服务器信息：**
- IP: `82.156.187.35`（Ubuntu）
- 部署目录：`/opt/clm-review-tool/`
- SSH 密钥：`~/.ssh/clm_tencent_ed25519`

**目录结构：**
```
/opt/clm-review-tool/
├── app/          # 应用代码（待上传）
├── backup/       # 数据库备份
├── compose/      # Docker Compose 配置 ✅
├── env/          # 环境变量 ✅
├── logs/         # 日志文件
├── mysql/        # MySQL 数据
├── nginx/        # Nginx 配置 ✅
└── scripts/      # 运维脚本 ✅
```

**已运行服务：**
- `clm-mysql` ✅ MySQL 8.0 运行中（端口 3306，仅本地访问）
- `clm-review-app` ⏳ 待启动（Nginx，端口 80/443）
- `clm-worker` ⏳ 待启动
- `clm-data-sync` ⏳ 待启动

**数据库密码：**
- root: `ClmProdRoot2026!Secure`
- clm: `ClmProd2026!Secure`

### 7.2 部署前检查清单

- [ ] SSH 可连接：`ssh -i ~/.ssh/clm_tencent_ed25519 root@82.156.187.35`
- [ ] Docker 运行中：`docker ps -a`
- [ ] MySQL 健康：`docker exec clm-mysql mysqladmin ping -h localhost`
- [ ] 代码分支确认（main 还是 feat/review-app-admin？）
- [ ] 飞书应用凭证已获取（APP_ID + APP_SECRET）
- [ ] 飞书测试群已创建，chat_id 已获取

### 7.3 飞书 chat_id 获取方法

**方法 1：运行 Python 脚本（推荐）**

```python
# 保存为 get_chat_id.py，填写 APP_ID 和 APP_SECRET 后运行
import requests

APP_ID = "cli_xxxxx"
APP_SECRET = "xxxxx"

# 获取 token
token = requests.post("https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal",
    json={"app_id": APP_ID, "app_secret": APP_SECRET}).json()["tenant_access_token"]

# 获取群列表
chats = requests.get("https://open.feishu.cn/open-apis/im/v1/chats",
    headers={"Authorization": f"Bearer {token}"}).json()["data"]["items"]

for chat in chats:
    print(f"{chat['name']}: {chat['chat_id']}")
```

**方法 2：飞书开放平台后台查看**
- 访问 https://open.feishu.cn/
- 进入应用管理 → 事件订阅/机器人 → 查看测试群 ID

### 7.4 .env.prod 配置模板

```bash
# 基础
DEBUG=false

# MySQL
MYSQL_HOST=db
MYSQL_PORT=3306
MYSQL_USER=clm
MYSQL_PASSWORD=ClmProd2026!Secure
MYSQL_DATABASE=clm_review

# 飞书（自建应用）
FEISHU_APP_ID=cli_***
FEISHU_APP_SECRET=***
FEISHU_BOT_WEBHOOK=http://82.156.187.35  # 与对外前端入口一致
FEISHU_TEST_MODE=true
FEISHU_TEST_CHAT_ID=oc_***
FEISHU_DRY_RUN=true

# 公司源数据库（后续填写）
SOURCE_DB_HOST=
SOURCE_DB_PORT=3306
SOURCE_DB_USER=
SOURCE_DB_PASSWORD=***
```

### 7.5 部署步骤

1. **上传代码**
   ```bash
   # CLM-Tools → /opt/clm-review-tool/app/worker
   # DateUse → /opt/clm-review-tool/app/data-sync
   ```

2. **更新 .env.prod**
   ```bash
   ssh -i ~/.ssh/clm_tencent_ed25519 root@82.156.187.35
   cd /opt/clm-review-tool/env
   vim .env.prod  # 填写飞书配置
   ```

3. **启动服务**
   ```bash
   cd /opt/clm-review-tool
   source env/.env.prod
   docker compose -f compose/docker-compose.prod.yml up -d
   ```

4. **验证**
   - 前端：`http://82.156.187.35/`
   - 后端健康：`http://82.156.187.35/health`
   - 飞书 dry-run 测试

### 7.6 交付打包边界

| 必须上云 | 禁止上云 | 可裁剪 |
|---------|---------|-------|
| 代码仓库 (git clone) | `.env` | `docs/dateuse_results/` 大 CSV |
| docker-compose.yml | `__pycache__/`、`*.pyc` | |
| backend/、frontend/ | `.DS_Store`、`node_modules/` | |
| docs/（核心文档） | 本地 `mysql_data` 卷 | |

> 上云用 git 拉代码最干净，`.env` 只在服务器本地创建。
