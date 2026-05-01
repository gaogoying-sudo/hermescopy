# 自启动服务清单

> 备份时间：2026-05-02 00:02:31

## Launchd 服务

- `ai.hermes.gateway-monitor` → unknown
- `ai.hermes.gateway` → unknown
- `ai.openclaw.agent-monitor-server` → unknown
- `ai.openclaw.cfbot` → unknown
- `ai.openclaw.cloudflared-monitor` → unknown
- `ai.openclaw.cloudflared-recipe` → unknown
- `ai.openclaw.gateway` → unknown
- `ai.openclaw.gpbot` → unknown
- `ai.openclaw.recipe-server` → unknown
- `ai.openclaw.server-watchdog` → unknown
- `ai.openclaw.tunnel-monitor` → unknown
- `com.hermes.dashboard` → unknown
- `unknown` → unknown
- `com.mac.gpbot` → unknown
- `com.mac.larkws` → unknown
- `homebrew.mxcl.mysql` → unknown
- `homebrew.mxcl.postgresql@18` → unknown
- `homebrew.mxcl.redis` → unknown

## 恢复方法
```bash
cp ~/Projects/hermescopy/autostart/launchagents/*.plist ~/Library/LaunchAgents/
for f in ~/Library/LaunchAgents/ai.*.plist ~/Library/LaunchAgents/com.hermes.*.plist; do
  launchctl load "$f" 2>/dev/null
done
```
