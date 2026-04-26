---
name: hermes-agent-troubleshooting
description: Systematic diagnosis of Hermes Agent hanging/freezing/stuck issues
trigger_words: hermes卡死 hermes卡住 agent没反应 消息堆积 gateway断连 hermes troubleshooting
---

# Hermes Agent 故障排查指南

系统性地诊断 Hermes Agent 卡死、无响应、消息堆积等问题。

## 排查流程

### 1. 进程状态检查

```bash
# 检查 Hermes 主进程
ps aux | grep hermes | grep -v grep
ps -p <PID> -o pid,pcpu,pmem,etime,state,command

# 检查 Gateway 进程
ps aux | grep gateway | grep -v grep

# 检查 Python 进程
ps aux | grep python | grep -v grep
```

**关键指标：**
- `state`: `S+` = 正常休眠等待, `R+` = 正在运行, `Z` = 僵尸进程
- `pcpu`: 持续 >50% 可能卡在计算中
- `pmem`: 持续增长可能内存泄漏

### 2. 系统资源检查

```bash
uptime                    # 系统负载
vm_stat | head -10        # 内存
df -h /                   # 磁盘
```

**阈值：**
- 负载 > CPU 核心数 × 2 → 系统过载
- 内存使用 > 90% → 可能 swap 导致卡顿
- 磁盘使用 > 90% → 可能无法写入会话文件

### 3. 端口和网络检查

```bash
lsof -i :9863             # Dashboard
lsof -i :14863            # Gateway
lsof -i :18789            # OpenClaw Gateway
lsof -p <PID> -i          # 进程网络连接
```

**正常状态：**
- Gateway 进程应监听 WebSocket 端口
- Dashboard 应监听 HTTP 端口
- 网络连接应为 `ESTABLISHED` 或 `LISTEN`

### 4. 会话文件检查

```bash
# 检查会话文件大小和修改时间
ls -lt ~/.hermes/sessions/session_*.json | head -10

# 检查当前会话上下文使用
python3 -c "
import json
with open('~/.hermes/sessions/<session_file>.json') as f:
    d = json.load(f)
msgs = d.get('messages', [])
total_chars = sum(len(m.get('content', '')) for m in msgs)
print(f'消息数: {len(msgs)}')
print(f'字符数: {total_chars} ({total_chars/10000:.1f}% of 1M context)')
"
```

**阈值：**
- 上下文使用 > 80% → 可能触发压缩/截断
- 会话文件 > 2MB → 可能加载慢

### 5. Gateway 日志检查

```bash
tail -50 ~/.hermes/logs/gateway.log
tail -50 ~/.hermes/logs/gateway.error.log
tail -50 ~/.hermes/logs/agent.log
tail -50 ~/.hermes/logs/errors.log
```

**关键错误模式：**
- `receive message loop exit, err: no close frame received or sent` → WebSocket 断连
- `usage allocated quota exceeded` → API 配额用尽
- `APITimeoutError: Request timed out` → API 超时
- `processor not found` → 事件处理器缺失（通常无害）

### 6. 中断消息检查

```bash
tail -30 ~/.hermes/interrupt_debug.log
```

**关键模式：**
- 大量 `ENTER: queued interrupt msg=` → 消息堆积
- 频繁 `interrupt fired` → 用户催促消息过多

### 7. Cron Jobs 检查

```bash
cronjob action=list
cat ~/.hermes/cron/jobs.json
```

### 8. Launchd 服务检查

```bash
launchctl list | grep hermes
```

## 常见故障模式

### 模式 1: Gateway WebSocket 断连重连（最常见）

**症状：**
- 每隔几小时卡一次
- 日志显示 `receive message loop exit`
- 重连后恢复正常

**原因：**
- 飞书/Telegram WebSocket 连接不稳定
- 网络波动导致断连
- 服务器端 keepalive 超时

**解决：**
```bash
launchctl stop ai.hermes.gateway
launchctl start ai.hermes.gateway
```

**预防：**
- 增加 Gateway 重连间隔
- 添加断连期间消息缓存
- 监控 Gateway 连接状态

### 模式 2: 消息堆积

**症状：**
- 用户发消息后很久才回复
- 中断日志显示大量排队消息
- Agent 回复的是很久前的消息

**原因：**
- 用户催促消息堆积（"在吗"、"卡死了"）
- 心跳消息和手动消息冲突
- Agent 处理慢，新消息排队

**解决：**
- 减少催促，等待 1-2 分钟
- 添加消息去重机制
- 优化 Agent 处理速度

### 模式 3: API 限流/配额用尽

**症状：**
- 日志显示 `429` 或 `quota exceeded`
- Agent 完全不回复

**解决：**
- 检查 API 配额
- 使用 fallback 模型
- 等待配额重置

### 模式 4: 上下文窗口超限

**症状：**
- 会话文件很大（>2MB）
- 上下文使用 > 80%

**解决：**
- 清理旧会话或让 Agent 自动压缩

### 模式 5: 进程僵死

**症状：**
- 进程存在但 CPU 持续 0%
- 会话文件不再更新

**解决：**
```bash
kill -9 <PID>
hermes
```

### 模式 6: TUI 无法启动 (no TTY)

**症状：**
- 执行 `hermes --tui` 报错 `hermes-tui: no TTY`
- 在 PTY/远程/无头环境中 TUI 无法交互

**原因：**
- TUI 需要真实终端 (TTY)，PTY 模式不满足检测条件
- `hermes --tui` 会检测 `isatty()` 检查，PTY 返回 false

**解决：**
```bash
# 方案 1: 启动 Dashboard（推荐，嵌入 TUI 模式）
hermes dashboard --tui --no-open
# 浏览器打开 http://127.0.0.1:9119/ 即可使用 Chat 标签页中的 TUI

# 方案 2: 使用命令行 chat 模式（无需 TUI）
hermes chat

# 方案 3: 在本地物理终端直接运行
hermes --tui  # 仅在本机终端可用
```

**验证 Dashboard 启动：**
```bash
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:9119/
# 返回 200 表示 Dashboard 已就绪
lsof -i :9119  # 确认端口监听
```

## 快速诊断脚本

```bash
#!/bin/bash
echo "=== Hermes Agent 诊断 ==="
echo ""
echo "【进程状态】"
ps aux | grep -E "hermes|gateway" | grep -v grep | awk '{print $2, $3, $4, $8, $11}'
echo ""
echo "【端口状态】"
for port in 9863 14863 18789; do
    result=$(lsof -i :$port 2>/dev/null | grep LISTEN)
    if [ -n "$result" ]; then echo "  端口 $port: OK"; else echo "  端口 $port: FAIL"; fi
done
echo ""
echo "【最新会话】"
ls -lt ~/.hermes/sessions/session_*.json 2>/dev/null | head -3
echo ""
echo "【Gateway 日志】"
tail -3 ~/.hermes/logs/gateway.log 2>/dev/null
echo ""
echo "【最近错误】"
tail -3 ~/.hermes/logs/errors.log 2>/dev/null
echo "=== 诊断完成 ==="
```

## 预防措施

1. **监控 Gateway 连接**：定期检查 WebSocket 连接状态
2. **限制消息堆积**：设置消息处理超时，过期消息丢弃
3. **心跳防冲突**：心跳前先检查 Agent 是否忙
4. **定期会话清理**：自动归档/清理旧会话
5. **API 配额监控**：设置配额告警

## 参考路径

- Gateway 日志：`~/.hermes/logs/gateway.log`
- 错误日志：`~/.hermes/logs/errors.log`
- 中断日志：`~/.hermes/interrupt_debug.log`
- 会话文件：`~/.hermes/sessions/`
- 配置文件：`~/.hermes/config.yaml`
- Gateway 服务：`ai.hermes.gateway` (launchd)
