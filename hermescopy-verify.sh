#!/bin/bash

# ═══════════════════════════════════════════════════════════
# hermescopy-verify.sh - 验证 Hermes 环境是否完整
# ═══════════════════════════════════════════════════════════

HERMESCLONE_DIR="${1:-$HOME/Projects/hermescopy}"
HERMES_HOME="$HOME/.hermes"
PASS=0
WARN=0
FAIL=0

echo "🔍 Hermes 环境验证"
echo "=================="
echo ""

check_pass() { echo "  ✅ $1"; PASS=$((PASS+1)); }
check_warn() { echo "  ⚠️  $1"; WARN=$((WARN+1)); }
check_fail() { echo "  ❌ $1"; FAIL=$((FAIL+1)); }

# ── 1. Hermes 核心 ──
echo "📦 Hermes 核心"
command -v hermes &>/dev/null && check_pass "Hermes CLI" || check_fail "Hermes CLI 未安装"
[ -f "$HERMES_HOME/config.yaml" ] && check_pass "config.yaml" || check_fail "config.yaml 缺失"
[ -f "$HERMES_HOME/memory.md" ] && check_pass "memory.md" || check_fail "memory.md 缺失"
[ -f "$HERMES_HOME/SOUL.md" ] && check_pass "SOUL.md" || check_warn "SOUL.md 缺失"
[ -f "$HERMES_HOME/.env" ] && check_pass ".env" || check_fail ".env 缺失"
grep -q "your_key_here" "$HERMES_HOME/.env" 2>/dev/null && check_warn ".env 中仍有占位符密钥"

echo ""

# ── 2. Skills ──
echo "📦 Skills"
if [ -d "$HERMES_HOME/skills" ]; then
    skill_count=$(find "$HERMES_HOME/skills" -name "SKILL.md" | wc -l | tr -d ' ')
    [ "$skill_count" -gt 0 ] && check_pass "Skills ($skill_count 个)" || check_warn "Skills 目录为空"
fi
for skill in "karpathy-guidelines" "an-an-task-secretary"; do
    find "$HERMES_HOME/skills" -path "*/$skill/SKILL.md" | grep -q . && check_pass "$skill" || check_warn "Skill 缺失: $skill"
done

echo ""

# ── 3. Profiles ──
echo "📦 Profiles"
if [ -d "$HERMES_HOME/profiles" ]; then
    profile_count=$(ls -d "$HERMES_HOME/profiles/"*/ 2>/dev/null | wc -l | tr -d ' ')
    check_pass "Profiles ($profile_count 个)"
else
    check_fail "Profiles 缺失"
fi

echo ""

# ── 4. Cronjob ──
echo "📦 Cronjob"
if [ -d "$HERMES_HOME/cron" ]; then
    cron_count=$(ls "$HERMES_HOME/cron/"*.json 2>/dev/null | wc -l | tr -d ' ')
    check_pass "Cronjob 数据 ($cron_count 个)"
else
    check_warn "Cronjob 目录缺失"
fi

echo ""

# ── 5. CLI 工具 ──
echo "📦 CLI 工具"
for tool in hermes codex claude git node npm; do
    if command -v $tool &>/dev/null; then
        version=$($tool --version 2>&1 | head -1)
        check_pass "$tool ($version)"
    else
        check_fail "$tool 未安装"
    fi
done

echo ""

# ── 6. 自启动服务 ──
echo "📦 自启动服务 (Launchd)"
LAUNCHD_DIR="$HOME/Library/LaunchAgents"
for service in "ai.hermes.gateway" "com.hermes.dashboard"; do
    if [ -f "$LAUNCHD_DIR/${service}.plist" ]; then
        status=$(launchctl list "$service" 2>/dev/null | grep -c "Label" || echo "0")
        [ "$status" -gt 0 ] && check_pass "$service (运行中)" || check_warn "$service (已安装但未运行)"
    else
        check_warn "$service 未安装"
    fi
done

echo ""

# ── 7. 项目配置 ──
echo "📦 项目配置"
for project in "clm-tools-kw" "hermes-dashboard"; do
    if [ -f "$HOME/Projects/$project/AGENTS.md" ]; then
        check_pass "$project/AGENTS.md"
    else
        check_warn "$project/AGENTS.md 缺失"
    fi
done

echo ""

# ── 8. Python 依赖 ──
echo "📦 Python 依赖"
for pkg in openpyxl pandas; do
    pip3 show $pkg &>/dev/null && check_pass "$pkg" || check_warn "Python 包缺失: $pkg"
done

echo ""

# ── 总结 ──
echo "═══════════════════════════════════════════════════════"
echo "验证结果"
echo "═══════════════════════════════════════════════════════"
echo "  ✅ 通过：$PASS"
echo "  ⚠️  警告：$WARN"
echo "  ❌ 失败：$FAIL"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo "❌ 环境不完整，请检查上述失败项"
    exit 1
elif [ "$WARN" -gt 0 ]; then
    echo "⚠️  环境基本可用，但有警告项需要处理"
    exit 0
else
    echo "✅ 环境完整，可以开始使用！"
    exit 0
fi
