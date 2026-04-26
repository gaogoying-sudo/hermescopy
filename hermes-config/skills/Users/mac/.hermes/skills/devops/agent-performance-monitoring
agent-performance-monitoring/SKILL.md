---
name: agent-performance-monitoring
description: Agent 自我性能监控与自动优化机制 — 实时自检、异常检测、自动修复、定时体检
version: 1.0.0
trigger_words: agent卡顿 agent变慢 性能监控 自检 体检 响应延迟
---

# Agent 性能自我监控机制

从 2026-04-24 卡顿事件沉淀的自动化监控体系。

## 核心原则

1. **重复检测**：同一工具调用 2 次无变化就停，不盲目重试
2. **超时降级**：单次操作超过 30 秒触发替代方案
3. **Memory 控制**：超过 80% 自动清理最旧条目
4. **工具选择最优**：简单命令用 terminal，不要用 execute_code

## 实时自检规则（每个对话内自动执行）

### 规则 1: 重复操作检测

每次工具调用前检查：
- 过去 3 次调用中是否有相同工具 + 相同参数
- 如果是，检查上次结果是否有用
- 无用的重复 = 立即停止，换方案

**反例（已发生过）：**
- `import json` 连续执行 4 次
- `read_file` 同一个文件读 3 遍
- `grep` 搜索相似内容多次

### 规则 2: 超时降级策略

| 操作 | 正常阈值 | 超时后降级方案 |
|------|----------|----------------|
| session_search | 10 秒 | 改用直接读最近 3 个会话文件 |
| execute_code | 30 秒 | 改用 terminal 直接执行 |
| web_search | 15 秒 | 放弃搜索，用已有知识回答 |
| browser_navigate | 20 秒 | 改用 web_extract |

### 规则 3: Memory 管理

每次对话开始时检查 Memory 使用率：
- < 70%: 正常
- 70-85%: 可写入，但保持简洁
- 85-95%: 先清理再写入（删最旧/最不重要条目）
- > 95%: 拒绝写入，先清理到 80% 以下

清理优先级：
1. 过时的技术配置（版本号、旧路径）
2. 冗余的对话模板/占位符
3. 已完成的临时任务状态
4. 合并相似条目（如多个 Agent 角色合成一行）

### 规则 4: 工具选择优化

| 场景 | 推荐工具 | 避免 |
|------|----------|------|
| 查看文件内容 | read_file | cat/head/tail in terminal |
| 搜索文件 | search_files | grep/rg/find in terminal |
| 简单命令 | terminal (foreground) | execute_code |
| 后台常驻服务 | terminal (background=true) | terminal (foreground, 超时等待) |
| 获取网页内容 | web_extract | browser_navigate（除非需交互） |
| 跨会话回忆 | session_search（限时 10 秒） | 手动翻历史文件 |

## 定时体检（每日凌晨 3:00）

### 检查项

1. **Memory 使用率** — 超过 80% 触发清理建议
2. **Skills 健康度** — 检查是否有过时/损坏的 Skill
3. **最近会话异常** — 过去 24 小时是否有超时 > 60 秒的操作
4. **Dashboard 可用性** — 端口 9863 是否监听
5. **Gateway 健康** — WebSocket 连接状态
6. **Cronjob 状态** — 所有定时任务是否正常运行

### 体检报告输出

写入 `~/Projects/hermes-dashboard/health/` 目录：
- `health-YYYY-MM-DD.json` — 结构化数据
- `health-YYYY-MM-DD.md` — 人类可读报告

异常时推送到飞书（通过 Gateway 原生飞书集成）。

## 故障处理流程

### 情况 A: 响应变慢

1. 检查 Memory 使用率 → 清理如果 > 80%
2. 检查最近是否有超时操作 → 分析原因
3. 检查系统资源（CPU/内存/磁盘）

### 情况 B: 工具调用失败

1. 第一次失败 → 检查错误类型（网络/权限/语法）
2. 第二次相同失败 → 换工具或换方案，不要重试
3. 记录失败模式到 health 日志

### 情况 C: 会话卡死

1. 检查 Gateway 进程状态
2. 检查 WebSocket 连接
3. 必要时重启 Gateway: `launchctl stop/start ai.hermes.gateway`

## 日志路径

- 健康检查日志: `~/Projects/hermes-dashboard/health/`
- Gateway 日志: `~/.hermes/logs/gateway.log`
- 错误日志: `~/.hermes/logs/errors.log`
- 会话文件: `~/.hermes/sessions/`

## 性能指标基线（2026-04-24 实测建立）

| 指标 | 正常值 | 警告阈值 | 严重阈值 | 实测值 |
|------|--------|----------|----------|--------|
| 工具调用响应 | < 3 秒 | 5-10 秒 | > 30 秒 | terminal ~0.3s, execute_code ~3s |
| session_search | < 5 秒 | 10-30 秒 | > 60 秒 | 曾超时 279 秒（需降级） |
| Memory 使用率 | < 70% | 70-85% | > 85% | 清理前 92%，清理后 80% |
| Dashboard 启动 | < 2 秒 | 2-5 秒 | > 10 秒 | 后台启动 ~2 秒 |
| Gateway 延迟 | < 1 秒 | 1-3 秒 | > 5 秒 | - |
| skill_view 加载 | < 2 秒 | 3-5 秒 | > 10 秒 | ~0.9s |
| write_file | < 1 秒 | 1-3 秒 | > 5 秒 | ~0.9s |

## 常见性能陷阱（实测发现）

1. **session_search 可能极慢** — 跨会话数据量大时会超时，必须设降级策略
2. **execute_code 过度使用** — 简单命令（ls, cat, version check）用 terminal 更快
3. **前台跑常驻服务** — server.py 等用 foreground 模式会等超时，必须用 background=true
4. **重复工具调用** — 同样的 import json / read_file 连续执行多次，浪费时间和上下文
5. **Memory 接近满载** — 超过 80% 后每次注入都拖慢响应，需定期清理
