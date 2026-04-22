---
name: terminal-audit
category: devops
description: 命令审计日志查询 - 查看历史执行的终端命令
tags: [audit, terminal, security, compliance]
created: 2026-04-18
---

# 终端命令审计 Skill

## 用途
查询历史执行的终端命令，用于安全审计、问题排查、合规检查。

## 审计日志位置
`~/.hermes/logs/terminal-audit.jsonl`

## 使用方法

### 查看最近的命令
```
/audit
```

### 按会话 ID 过滤
```
/audit session=20260418_123456_abc
```

### 按命令模式搜索
```
/audit command=git
/audit command=docker
```

### 查看统计信息
```
/audit stats
```

## 审计日志格式

每条审计记录包含：
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

## 启用/禁用审计

```bash
# 启用审计（默认）
export HERMES_TERMINAL_AUDIT=true

# 禁用审计
export HERMES_TERMINAL_AUDIT=false
```

## 日志轮转

审计日志不会自动轮转。建议每月手动归档：

```bash
# 归档旧日志
mv ~/.hermes/logs/terminal-audit.jsonl \
   ~/.hermes/logs/terminal-audit-$(date +%Y%m).jsonl

# 压缩归档
gzip ~/.hermes/logs/terminal-audit-*.jsonl
```

## 隐私注意事项

审计日志包含：
- ✅ 执行的命令
- ✅ 输出前 500 字符
- ✅ 会话 ID
- ❌ 不包含完整输出（防止敏感信息泄露）

如执行了敏感命令，建议手动删除对应日志行。
