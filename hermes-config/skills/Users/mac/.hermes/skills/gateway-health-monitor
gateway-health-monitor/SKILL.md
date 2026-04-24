---
name: gateway-health-monitor
description: Hermes Gateway 健康监控与自动恢复系统
category: devops
version: 1.0.0
---

# Gateway Health Monitor

## 问题背景

Hermes Gateway 通过 WebSocket 连接飞书，存在以下问题：
- 约每 4-5 小时断连一次
- 断连期间消息堆积，用户感觉"卡死"
- 重连后消息可能丢失

## 解决方案

### 三层防护

1. **launchd 守护进程** (`ai.hermes.gateway-monitor.plist`)
   - 每 5 分钟运行一次健康检查
   - 开机自启

2. **Hermes Cron Job** (`gateway-health-monitor`)
   - 每 5 分钟运行一次
   - 作为 launchd 的补充

3. **健康检查脚本** (`gateway-health-check.py`)
   - 检查进程是否存在
   - 检查断连频率
   - 检查响应性
   - 自动重启

### 脚本位置

```
~/.hermes/scripts/gateway-health-check.py    # 健康检查
~/.hermes/scripts/gateway-auto-restart.sh    # 手动重启
~/.hermes/logs/gateway-health.log            # 健康日志
~/.hermes/gateway-health.json                # 状态文件
```

### 触发条件

| 条件 | 动作 |
|------|------|
| 进程不存在 | 立即重启 |
| 5 分钟断连 > 2 次 | 优雅重启 |
| 重连后 30 秒内又断连 | 强制重启 |
| 无响应 | 强制重启 |

### 手动操作

```bash
# 查看状态
cat ~/.hermes/gateway-health.json

# 查看日志
tail -20 ~/.hermes/logs/gateway-health.log

# 手动重启
/Users/mac/.hermes/scripts/gateway-auto-restart.sh

# 暂停监控
launchctl unload ~/Library/LaunchAgents/ai.hermes.gateway-monitor.plist

# 恢复监控
launchctl load ~/Library/LaunchAgents/ai.hermes.gateway-monitor.plist
```

### 注意事项

- 重启冷却时间：300 秒（防止频繁重启）
- 日志保留：最近 1000 行
- 状态文件：~/.hermes/gateway-health.json

## 🔧 实施经验与陷阱

### 关键发现

1. **Gateway 是 WebSocket 客户端，不是服务器**
   - ❌ 错误做法：检查 `lsof -i :14863` 看是否有 LISTEN
   - ✅ 正确做法：检查进程是否存在且活跃（`ps -p <PID>`）
   - Gateway 连接飞书 WebSocket 服务器，不监听本地端口

2. **macOS `ps` 输出格式与 Linux 不同**
   - macOS: `PID TTY TIME CMD`
   - Linux: `PID STAT TIME CMD`
   - 检查响应性时不要依赖 "STAT" 列，改用 "PID" 列

3. **PID 缓存问题**
   - `check_process()` 可能被多次调用，每次返回的 PID 可能不同
   - 如果进程在检查期间重启，不同调用可能返回不同 PID
   - 解决方案：先获取 PID 列表，缓存后复用

### 修复示例

```python
# ❌ 错误：多次调用 check_process()，PID 可能变化
def check_gateway_responsive():
    result = subprocess.run(
        ["ps", "-p", check_process()[0]] if check_process() else [],
        capture_output=True, text=True, timeout=5
    )
    return "STAT" in result.stdout

# ✅ 正确：缓存 PID，检查正确的列
def check_gateway_responsive():
    pids = check_process()
    if not pids:
        return False
    pid = pids[0]  # 缓存
    result = subprocess.run(
        ["ps", "-p", pid],
        capture_output=True, text=True, timeout=5
    )
    return "PID" in result.stdout and pid in result.stdout
```

### 排查卡死问题的诊断流程

1. 检查进程是否存在：`pgrep -f "hermes_cli.main gateway"`
2. 检查断连频率：`grep "disconnect" ~/.hermes/logs/gateway.error.log`
3. 检查重连时间：`grep "connected" ~/.hermes/logs/gateway.log | tail -1`
4. 检查中断日志：`tail ~/.hermes/interrupt_debug.log`
5. 检查会话大小：`python3 -c "import json; d=json.load(open('session.json')); print(len(d['messages']))"`

### 常见卡死原因

| 原因 | 症状 | 解决方案 |
|------|------|----------|
| Gateway 断连 | 消息无响应，30 秒后恢复 | 自动重启 Gateway |
| 消息堆积 | 重复执行相同任务 | 消息去重 |
| 心跳冲突 | 任务被中断重做 | 心跳防冲突检查 |
| 上下文超限 | 响应变慢 | 会话压缩/重置 |
| API 限流 | 429 错误 | 模型自动切换 |
