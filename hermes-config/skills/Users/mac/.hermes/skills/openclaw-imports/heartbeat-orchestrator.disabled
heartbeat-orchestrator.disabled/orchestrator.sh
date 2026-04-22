#!/bin/bash
# Heartbeat Orchestrator - 多 Agent 状态汇报脚本
# 用法：./orchestrator.sh [--send]

set -e

WORKSPACE="/Users/mac/.openclaw/workspace"
AGENTS_DIR="$WORKSPACE/agents"
NOTES_DIR="$WORKSPACE/notes"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M")
TIME_SHORT=$(date "+%H:%M")

# ============================================
# 任务队列集成 - 自动记录心跳任务
# ============================================
QUEUE_SCRIPT="$WORKSPACE/scripts/update-task-queue.sh"
START_TIME=$(date +%s)

# 开始心跳任务记录
"$QUEUE_SCRIPT" start "ops" "心跳检查 - Agent 状态" 2>/dev/null || true

# 退出时自动记录完成
trap 'END_TIME=$(date +%s); DURATION=$((END_TIME - START_TIME)); "$QUEUE_SCRIPT" complete "ops" "心跳检查 - Agent 状态" "$DURATION" 2>/dev/null || true' EXIT

# 颜色定义
GREEN="🟢"
YELLOW="🟡"
RED="🔴"
GRAY="⚫"  # 改深色，避免和背景融合

# CPS 专属颜色（紫色系，更醒目）
CPS_ICON="🟣"

# 初始化报告
REPORT="## 🤖 Agent 状态汇报 (${TIME_SHORT})\n\n"
ACTIVE_AGENTS=""
IDLE_AGENTS=""
ALERTS=""

echo "🔍 开始 Agent 状态检查 (${TIMESTAMP})..."

# ============================================
# #cook 专属健康检查 - 隧道检测 + 自动重启
# ============================================
check_cook_tunnel() {
  local cook_state="$AGENTS_DIR/cook/state.json"
  
  if [ -f "$cook_state" ]; then
    # 读取隧道 URL
    local tunnel_url=$(cat "$cook_state" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('health',{}).get('url',''))" 2>/dev/null)
    
    if [ -n "$tunnel_url" ]; then
      echo "  🔍 检查 #cook 隧道：$tunnel_url"
      
      # HTTP 健康检查
      local http_code=$(curl -s -o /dev/null -w "%{http_code}" "$tunnel_url" 2>/dev/null || echo "000")
      
      if [ "$http_code" != "200" ]; then
        echo "  ⚠️ 隧道异常 (HTTP $http_code)，正在重启..."
        
        # 重启隧道
        if [ -x "$WORKSPACE/scripts/start-recipe-tunnel.sh" ]; then
          "$WORKSPACE/scripts/start-recipe-tunnel.sh" > /dev/null 2>&1 &
          sleep 8
          
          # 读取新链接
          local link_file="$NOTES_DIR/recipe-tunnel-link.txt"
          if [ -f "$link_file" ]; then
            local new_url=$(cat "$link_file" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('url',''))" 2>/dev/null)
            
            # 更新 state.json
            cat "$cook_state" | python3 -c "
import sys,json
d=json.load(sys.stdin)
d['health']['url']='$new_url'
d['health']['tunnel']='ok'
d['last_updated']='$(date -Iseconds)'
print(json.dumps(d,indent=2))
" > "${cook_state}.tmp" && mv "${cook_state}.tmp" "$cook_state"
            
            ALERTS+="🔄 #cook 隧道已重启：$new_url\n"
            echo "  ✅ 隧道已重启：$new_url"
          fi
        fi
      else
        echo "  ✅ 隧道正常 (HTTP $http_code)"
      fi
    fi
  fi
}

# 执行 #cook 健康检查
check_cook_tunnel

# 遍历所有 agent 目录
if [ -d "$AGENTS_DIR" ]; then
  for agent_dir in "$AGENTS_DIR"/*/; do
    if [ -d "$agent_dir" ]; then
      agent_name=$(basename "$agent_dir")
      state_file="$agent_dir/state.json"
      
      if [ -f "$state_file" ]; then
        # 读取状态
        status=$(cat "$state_file" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status','unknown'))" 2>/dev/null || echo "error")
        task=$(cat "$state_file" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('current_task','无'))" 2>/dev/null || echo "未知")
        progress=$(cat "$state_file" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('progress','-'))" 2>/dev/null || echo "-")
        updated=$(cat "$state_file" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('last_updated','未知'))" 2>/dev/null || echo "未知")
        
        # 状态图标
        case "$agent_name" in
          "cps") icon="$CPS_ICON" ;;  # CPS 专属紫色
          "running") icon="$GREEN" ;;
          "idle") icon="$YELLOW" ;;
          "error") icon="$RED" ;;
          *) icon="$GRAY" ;;
        esac
        
        # 检查是否过期 (超过 10 分钟未更新)
        if [ "$status" = "running" ]; then
          last_ts=$(cat "$state_file" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('last_updated',''))" 2>/dev/null)
          # 简单检查：如果包含今天日期则认为未过期
          if [[ ! "$last_ts" =~ "2026-03-04" ]]; then
            ALERTS+="⚠️ #$agent_name: 状态文件过期 (最后更新：$last_ts)\n"
            icon="$YELLOW"
          fi
        fi
        
        # 读取额外信息（用于展开详情）
        health=$(cat "$state_file" | python3 -c "import sys,json; d=json.load(sys.stdin); h=d.get('health',{}); print(' | '.join([f'{k}:{v}' for k,v in h.items()]))" 2>/dev/null || echo "")
        updated_short=$(echo "$updated" | cut -d'T' -f2 | cut -d'+' -f1 | cut -d'.' -f1)
        
        # 添加到活跃或待命列表 - 有任务的 agent 展开详情
        if [ "$status" = "running" ] || { [ "$task" != "无" ] && [ "$task" != "等待老大指令" ] && [ "$task" != "等待老大发送群文件" ]; }; then
          # 有任务的 agent - 展开详情模式（占两行）
          ACTIVE_AGENTS+="| #$agent_name | $icon | $task | $progress | - |\n"
          ACTIVE_AGENTS+="| ↳ 更新 | $updated_short | 健康：$health | |\n"
        else
          IDLE_AGENTS+="| #$agent_name | $icon | $task |\n"
        fi
        
        echo "  $icon #$agent_name: $status - $task"
      else
        echo "  $GRAY #$agent_name: 无 state.json"
        IDLE_AGENTS+="| #$agent_name | $GRAY | 未配置 |\n"
      fi
    fi
  done
fi

# 检查系统状态
GATEWAY_STATUS="🟢"
ps aux | grep -q "openclaw-gateway" || GATEWAY_STATUS="🔴"

# ============================================
# 任务队列集成 - 自动记录心跳任务
# ============================================
QUEUE_SCRIPT="$WORKSPACE/scripts/update-task-queue.sh"
START_TIME=$(date +%s)

# 开始心跳任务记录
"$QUEUE_SCRIPT" start "ops" "心跳检查 - Agent 状态" 2>/dev/null || true

# 退出时自动记录完成
trap 'END_TIME=$(date +%s); DURATION=$((END_TIME - START_TIME)); "$QUEUE_SCRIPT" complete "ops" "心跳检查 - Agent 状态" "$DURATION" 2>/dev/null || true' EXIT

# ============================================
# Agent 调度器集成 - 自动检查和提醒
# ============================================
SCHEDULER_SCRIPT="$WORKSPACE/scripts/agent-scheduler.sh"

# 执行 Agent 检查
"$SCHEDULER_SCRIPT" check 2>/dev/null || true

# 生成完整报告
REPORT+="### 活跃 Agent\n\n"
REPORT+="| Agent | 状态 | 当前任务 | 进展 | 下次汇报 |\n"
REPORT+="|-------|------|---------|------|----------|\n"
if [ -n "$ACTIVE_AGENTS" ]; then
  REPORT+="$ACTIVE_AGENTS"
else
  REPORT+="| - | - | - | - |\n"
fi

REPORT+="\n### 待命中 Agent\n\n"
REPORT+="| Agent | 状态 | 最后任务 |\n"
REPORT+="|-------|------|----------|\n"
if [ -n "$IDLE_AGENTS" ]; then
  REPORT+="$IDLE_AGENTS"
else
  REPORT+="| - | - | - |\n"
fi

if [ -n "$ALERTS" ]; then
  REPORT+="\n### ⚠️ 异常告警\n\n"
  REPORT+="$ALERTS\n"
fi

REPORT+="\n---\n\n"
REPORT+="**系统状态：** $GATEWAY_STATUS 正常\n"
REPORT+="**下次汇报：** $(date -v+5M "+%H:%M")\n"

# 保存到文件
echo -e "$REPORT" > "$NOTES_DIR/agent-status.md"

# 保存到文件
echo -e "$REPORT" > "$NOTES_DIR/agent-status.md"

# 如果指定 --send，发送到飞书群
# 🛑 2026-03-05 老大指令：暂停飞书群播报
if [ "$1" = "--send" ] && [ "$DISABLE_BROADCAST" != "true" ]; then
  FEISHU_CHAT_ID="oc_5bf44c5321706142664ca80fee8db816"
  
  # 生成简洁播报消息
  MESSAGE="## 🤖 Agent 进展播报 (${TIME_SHORT})

### 活跃 Agent
$(echo -e "$ACTIVE_AGENTS" | sed 's/\\n//g' | head -5)

### 待命中 Agent
$(echo -e "$IDLE_AGENTS" | sed 's/\\n//g' | head -5)
$(if [ -n "$ALERTS" ]; then echo -e "\n### ⚠️ 告警\n$ALERTS"; fi)

**系统状态：** 🟢 正常
**下次播报：** $(date -v+5M "+%H:%M")"

  # 发送飞书消息
  # openclaw message send --channel feishu --target "$FEISHU_CHAT_ID" --message "$MESSAGE" >/dev/null 2>&1
  echo "📤 播报已禁用 (DISABLE_BROADCAST=true)"
fi
