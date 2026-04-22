# Heartbeat Orchestrator - 多 Agent 定时反馈系统

**版本：** 1.0  
**创建时间：** 2026-03-04  
**负责人：** #ops (ClawOps)

---

## 🎯 功能

每 5 分钟自动检查所有 Agent 的状态，生成汇总报告：

- ✅ 遍历 `agents/*/state.json` 获取状态
- ✅ 检测异常（隧道失效/任务停滞/文件过期）
- ✅ 生成 Markdown 报告
- ✅ 保存到 `notes/agent-status.md`
- 🔄 可选：发送到飞书群

---

## 📊 效果示例

```markdown
## 🤖 Agent 状态汇报 (12:06)

### 活跃 Agent

| Agent | 状态 | 当前任务 | 进展 | 下次汇报 |
|-------|------|---------|------|----------|
| #cook | 🟢   | Phase 2 | 0%   | -        |
| #ops  | 🟢   | 心跳调度 | 100% | -        |

### 待命中 Agent

| Agent | 状态 | 最后任务 |
|-------|------|---------|
| #dev  | 🟡   | Agent Monitor v2.0 |
| #pm   | 🟡   | 待命中 |

**系统状态：** 🟢 正常
**下次汇报：** 12:11
```

---

## 🚀 使用方式

### 手动触发

```bash
./skills/heartbeat-orchestrator/orchestrator.sh
```

### 自动触发 (每 5 分钟)

```bash
# 加载 launchd 配置
launchctl load ~/Library/LaunchAgents/com.openclaw.heartbeat.plist

# 查看状态
launchctl list | grep heartbeat

# 卸载
launchctl unload ~/Library/LaunchAgents/com.openclaw.heartbeat.plist
```

---

## 📁 文件结构

```
skills/heartbeat-orchestrator/
├── SKILL.md              # Skill 定义
├── orchestrator.sh       # 执行脚本
├── README.md             # 本文档
└── templates/
    └── agent-state.json  # 状态模板

agents/
├── cook/
│   └── state.json        # Cook Agent 状态
├── dev/
│   └── state.json        # Dev Agent 状态
├── ops/
│   └── state.json        # Ops Agent 状态
└── ...                   # 其他 Agent

notes/
└── agent-status.md       # 生成的状态报告
```

---

## 📝 Agent 状态文件格式

每个 Agent 维护自己的 `state.json`：

```json
{
  "agent": "#cook",
  "status": "running",           // running | idle | error | stopped
  "current_task": "Phase 2",
  "progress": 50,                // 0-100
  "last_updated": "2026-03-04T12:05:00+08:00",
  "health": {
    "tunnel": "ok",
    "server": "ok"
  }
}
```

---

## 🔧 配置

### 修改检查频率

编辑 `com.openclaw.heartbeat.plist`：

```xml
<key>StartInterval</key>
<integer>180</integer>  <!-- 秒 (3 分钟) -->
```

### 添加新 Agent

1. 创建目录：`mkdir agents/<agent-name>`
2. 创建状态文件：`cp skills/heartbeat-orchestrator/templates/agent-state.json agents/<agent-name>/state.json`
3. 编辑 `state.json` 填写 Agent 信息

---

## 🎛️ 状态码

| 状态 | 含义 | 图标 |
|------|------|------|
| running | 运行中 | 🟢 |
| idle | 待命中 | 🟡 |
| error | 错误 | 🔴 |
| stopped | 已停止 | ⚪ |

---

## 📈 下一步优化

- [ ] 集成飞书消息发送
- [ ] 添加异常告警（连续 3 次失败）
- [ ] 支持自定义汇报频率
- [ ] 添加历史状态趋势图

---

**最后更新：** 2026-03-04 12:06
