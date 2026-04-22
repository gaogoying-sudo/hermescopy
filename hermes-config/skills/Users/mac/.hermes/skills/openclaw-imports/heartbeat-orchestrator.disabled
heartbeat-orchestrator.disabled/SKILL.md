# Heartbeat Orchestrator Skill

**功能：** 定时检查所有 agent 状态并汇总汇报

**触发：** 每 5 分钟 (通过 launchd 或 cron)

**负责人：** #ops (ClawOps)

---

## 执行流程

### 1. 读取 Agent 状态

遍历 `agents/*/state.json` 获取每个 agent 的当前状态：

```bash
for agent_dir in agents/*/; do
  if [ -f "${agent_dir}state.json" ]; then
    # 读取状态
    # 检查健康度
    # 记录进展
  fi
done
```

### 2. 检查系统健康

- Gateway 状态
- 飞书连接
- 隧道/服务状态

### 3. 生成汇总报告

**输出格式：**

```markdown
## 🤖 Agent 状态汇报 (HH:MM)

### 活跃 Agent

| Agent | 状态 | 当前任务 | 进展 | 下次汇报 |
|-------|------|---------|------|---------|
| #cook | 🟢   | Phase 2 | 50%  | 12:05   |
| #ops  | 🟢   | 心跳汇报 | ✅   | 12:05   |

### 待命中 Agent

| Agent | 状态 | 最后任务 |
|-------|------|---------|
| #dev  | 🟡   | Agent Monitor v2.0 |
| #pm   | ⚪   | 无 |

### ⚠️ 异常告警

- #cook: 隧道 503 错误 (已自动重启)

---

**系统状态：** 🟢 正常
**下次汇报：** 12:05
```

### 4. 发送到飞书群

```bash
# 通过飞书插件发送
openclaw message --channel feishu --target oc_xxx "汇报内容..."
```

### 5. 更新状态文件

```bash
# 更新 notes/agent-status.md
# 更新 memory/YYYY-MM-DD.md
```

---

## 状态码定义

| 状态 | 含义 | 颜色 |
|------|------|------|
| 🟢 running | 正常运行中 | 绿 |
| 🟡 idle | 待命中 | 黄 |
| 🔴 error | 错误/异常 | 红 |
| ⚪ stopped | 已停止 | 灰 |

---

## 异常检测规则

1. **隧道失效：** HTTP 检查返回 503/404
2. **任务停滞：** 超过 30 分钟无进展更新
3. **进程退出：** PID 不存在
4. **文件过期：** state.json 超过 10 分钟未更新

---

## 文件结构

```
skills/heartbeat-orchestrator/
├── SKILL.md              # 本文件
├── orchestrator.sh       # 执行脚本
└── templates/
    ├── status-report.md  # 汇报模板
    └── agent-state.json  # 状态模板
```

---

## 调用示例

```bash
# 手动触发
./skills/heartbeat-orchestrator/orchestrator.sh

# launchd 自动触发 (每 5 分钟)
launchctl load ~/Library/LaunchAgents/com.openclaw.heartbeat.plist
```

---

**最后更新：** 2026-03-04  
**版本：** 1.0
