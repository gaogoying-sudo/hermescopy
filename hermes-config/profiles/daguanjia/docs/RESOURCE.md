# 项目资源登记册

**最后更新：** 2026-04-18  
**维护者：** 大管家  
**用途：** 所有项目的资源索引（服务器、数据库、API、端口等）

---

## 一、CLM-REVIEW-TOOL（小厨负责）

### 项目信息
| 字段 | 值 |
|------|-----|
| 路径 | /Users/mac/Projects/clm-tools-kw/ |
| 角色 | 小厨/小强 |
| 阶段 | Phase 3 完成 → 云部署 |
| 治理 | docs/progress.md + TASK_BOARD.md + graphify |

### 云环境
| 资源 | 配置 |
|------|------|
| 云主机 IP | 82.156.187.35 |
| SSH 用户 | root |
| SSH 密钥 | ~/.ssh/clm_tencent_ed25519 |
| 部署路径 | /opt/clm-review-tool/ |

### 数据库（云端）
| 字段 | 值 |
|------|-----|
| MySQL 版本 | 8.0 |
| 容器名 | clm-mysql |
| 访问方式 | 127.0.0.1:3306（仅本地） |
| 数据库名 | clm_review |
| 用户名 | clm |
| 密码 | 见 ~/.hermes/profiles/xiaochu/.env |

### 飞书配置
| 字段 | 值 |
|------|-----|
| APP_ID | cli_a92b81d03838dbb3 |
| APP_SECRET | 见 ~/.hermes/profiles/xiaochu/.env |
| 测试群 chat_id | oc_c2eaef0dca9716e687620eec72bbcaa6 |
| 安全配置 | FEISHU_DRY_RUN=true, FEISHU_TEST_MODE=true |

### 端口分配（本地）
| 服务 | 端口 | 访问方式 |
|------|------|---------|
| 前端 | 8081 | http://localhost:8081 |
| 后端 API | 8001 | http://localhost:8001 |
| MySQL | 3307 | localhost:3307 |

### 端口分配（云端）
| 端口 | 服务 | 访问方式 |
|------|------|---------|
| 80 | Nginx (review-app) | 公网 |
| 443 | Nginx (HTTPS) | 公网 |
| 3306 | MySQL | 仅本地 (127.0.0.1) |

### 文档链接
- 交接文档：~/software project/DateUse/CLM-Cloud-Environment-Handoff.md
- 项目治理：/Users/mac/Projects/clm-tools-kw/docs/GOVERNANCE.md
- 任务看板：/Users/mac/Projects/clm-tools-kw/docs/TASK_BOARD.md

---

## 二、OpenViking（狗蛋评估中）

| 字段 | 值 |
|------|-----|
| 路径 | /Users/mac/Projects/OpenViking/ |
| 角色 | 狗蛋 |
| 类型 | 上下文数据库（AI Agents） |
| 状态 | 评估中 |
| 文档 | /Users/mac/Projects/OpenViking/README.md |

---

## 三、其他活跃项目

| 项目 | 路径 | 角色 | 状态 |
|------|------|------|------|
| xiaomiao-cert-knowledge | ./Projects/xiaomiao-cert-knowledge/ | - | 有 TASK_BOARD.md |
| wenbo-agent | ./Projects/wenbo-agent/ | 文博 | 知识库管理 |

---

## 四、全局配置

### LLM 配置
| 字段 | 值 |
|------|-----|
| 当前模型 | qwen3.5-plus（阿里巴巴） |
| Provider | OpenRouter |
| Anthropic | 禁用 |

### Git 注意事项
⚠️ **历史问题：** Git remote URL 曾被注入 `-S -p ''` 后缀
**修复方式：** 直接编辑 .git/config 文件中的 URL 字段

### 敏感信息存储
所有 API Key、密码等敏感信息存储在：
- `~/.hermes/profiles/<角色>/.env`
- 权限：chmod 600

---

**文档维护：**
- 新增项目时在此登记
- 资源变更时更新此文档
- 每季度审查一次
