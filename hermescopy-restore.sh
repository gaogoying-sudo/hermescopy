#!/bin/bash
set -e

# ═══════════════════════════════════════════════════════════
# hermescopy-restore.sh - 一键恢复 Hermes 完整灵魂
# 恢复范围：配置 + Skills + Cronjob + 自启动 + 项目规则 + 环境
# ═══════════════════════════════════════════════════════════

HERMES_HOME="$HOME/.hermes"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "🔄 hermescopy 一键恢复"
echo "======================"
echo ""

# ── 0. 克隆配置仓库 ──
HERMESCLONE_DIR="$HOME/.hermescopy-temp"
CONFIG_REPO="$1"

if [ -n "$CONFIG_REPO" ]; then
    echo "📥 克隆配置仓库..."
    git clone "$CONFIG_REPO" "$HERMESCLONE_DIR"
elif [ -d "$HOME/Projects/hermescopy" ]; then
    HERMESCLONE_DIR="$HOME/Projects/hermescopy"
    echo "📂 使用本地配置仓库：$HERMESCLONE_DIR"
else
    echo "❌ 未找到配置仓库"
    echo ""
    echo "用法："
    echo "  方式1（远程）：./hermescopy-restore.sh git@github.com:gaogoying-sudo/hermescopy.git"
    echo "  方式2（本地）：先把 hermescopy 仓库克隆到 ~/Projects/hermescopy/"
    exit 1
fi

# ── 1. 安装 Hermes ──
echo ""
echo "📦 [1/9] 检查 Hermes..."
if command -v hermes &>/dev/null; then
    echo "  ✅ Hermes 已安装：$(hermes --version 2>&1 | head -1)"
else
    echo "  📥 安装 Hermes Agent..."
    curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
    echo "  ✅ Hermes 安装完成"
fi

# ── 2. 备份现有配置 ──
if [ -d "$HERMES_HOME" ]; then
    echo ""
    echo "📦 [2/9] 备份现有配置..."
    BACKUP_NAME="$HERMES_HOME.backup.$TIMESTAMP"
    mv "$HERMES_HOME" "$BACKUP_NAME"
    echo "  ✅ 备份到：$BACKUP_NAME"
fi

# ── 3. 恢复 Hermes 核心配置 ──
echo ""
echo "📋 [3/9] 恢复 Hermes 核心配置..."
mkdir -p "$HERMES_HOME"

if [ -f "$HERMESCLONE_DIR/hermes-config/config.yaml" ]; then
    cp "$HERMESCLONE_DIR/hermes-config/config.yaml" "$HERMES_HOME/config.yaml"
    echo "  ✅ config.yaml"
fi

if [ -f "$HERMESCLONE_DIR/hermes-config/memory.md" ]; then
    cp "$HERMESCLONE_DIR/hermes-config/memory.md" "$HERMES_HOME/memory.md"
    echo "  ✅ memory.md"
fi

if [ -f "$HERMESCLONE_DIR/hermes-config/SOUL.md" ]; then
    cp "$HERMESCLONE_DIR/hermes-config/SOUL.md" "$HERMES_HOME/SOUL.md"
    echo "  ✅ SOUL.md"
fi

# ── 4. 恢复 Skills ──
echo "📋 [4/9] 恢复 Skills..."
if [ -d "$HERMESCLONE_DIR/hermes-config/skills" ]; then
    mkdir -p "$HERMES_HOME/skills"
    cp -r "$HERMESCLONE_DIR/hermes-config/skills/"* "$HERMES_HOME/skills/" 2>/dev/null || true
    skill_count=$(find "$HERMES_HOME/skills" -name "SKILL.md" | wc -l | tr -d ' ')
    echo "  ✅ 已恢复 $skill_count 个 Skills"
fi

# ── 5. 恢复 Profiles ──
echo "📋 [5/9] 恢复 Profiles..."
if [ -d "$HERMESCLONE_DIR/hermes-config/profiles" ]; then
    mkdir -p "$HERMES_HOME/profiles"
    cp -r "$HERMESCLONE_DIR/hermes-config/profiles/"* "$HERMES_HOME/profiles/" 2>/dev/null || true
    echo "  ✅ Profiles 已恢复"
fi

# ── 6. 恢复 Cronjob ──
echo "📋 [6/9] 恢复 Cronjob..."
if [ -d "$HERMESCLONE_DIR/hermes-config/cron" ]; then
    mkdir -p "$HERMES_HOME/cron"
    cp -r "$HERMESCLONE_DIR/hermes-config/cron/"* "$HERMES_HOME/cron/" 2>/dev/null || true
    echo "  ✅ Cronjob 数据已恢复（重启 Hermes 后生效）"
fi

# ── 7. 恢复 Launchd 自启动服务 ──
echo "📋 [7/9] 恢复自启动服务..."
if [ -d "$HERMESCLONE_DIR/autostart/launchagents" ]; then
    LAUNCHD_DIR="$HOME/Library/LaunchAgents"
    mkdir -p "$LAUNCHD_DIR"
    for plist in "$HERMESCLONE_DIR/autostart/launchagents/"*.plist; do
        if [ -f "$plist" ]; then
            cp "$plist" "$LAUNCHD_DIR/"
            label=$(defaults read "$plist" Label 2>/dev/null || basename "$plist")
            # 加载服务
            launchctl load "$LAUNCHD_DIR/$(basename "$plist")" 2>/dev/null && echo "  ✅ $label" || echo "  ⚠️ $label（加载失败，可能已存在）"
        fi
    done
fi

# ── 8. 恢复项目配置和脚本 ──
echo "📋 [8/9] 恢复项目配置..."
if [ -d "$HERMESCLONE_DIR/project-configs" ]; then
    for agents_file in "$HERMESCLONE_DIR/project-configs"/AGENTS-*.md; do
        if [ -f "$agents_file" ]; then
            project_name=$(basename "$agents_file" | sed 's/AGENTS-//;s/.md//')
            project_dir="$HOME/Projects/$project_name"
            if [ -d "$project_dir" ]; then
                cp "$agents_file" "$project_dir/AGENTS.md"
                echo "  ✅ $project_name/AGENTS.md"
            else
                echo "  ⏭️  $project_name/ 不存在，跳过"
            fi
        fi
    done
fi

# 恢复启动脚本
if [ -d "$HERMESCLONE_DIR/scripts" ]; then
    mkdir -p "$HOME/Projects/hermes-dashboard"
    cp "$HERMESCLONE_DIR/scripts/"* "$HOME/Projects/hermes-dashboard/" 2>/dev/null || true
    chmod +x "$HOME/Projects/hermes-dashboard/"*.sh 2>/dev/null || true
    echo "  ✅ 启动脚本已恢复"
fi

# ── 9. 恢复 shell 配置提示 ──
echo "📋 [9/9] Shell 配置..."
if [ -f "$HERMESCLONE_DIR/shell-config/.zshrc.custom" ]; then
    echo ""
    echo "  ⚠️  请将以下内容追加到 ~/.zshrc（如需要）："
    echo "  cat ~/Projects/hermescopy/shell-config/.zshrc.custom >> ~/.zshrc"
    echo "  然后运行：source ~/.zshrc"
fi

# ── 10. 创建 .env 模板 ──
echo ""
echo "🔑 创建密钥模板..."
cat > "$HERMES_HOME/.env" << 'EOF'
# ═══════════════════════════════════════════════════════════
# Hermes 密钥配置 - hermescopy
# 请填写以下密钥（或导出到环境变量）
# ═══════════════════════════════════════════════════════════

# 阿里云 DashScope（主 Provider）
DASHSCOPE_API_KEY="your_key_here"

# OpenRouter（备用 Provider）
OPENROUTER_API_KEY="your_key_here"

# 飞书应用（如需飞书集成）
# FEISHU_APP_ID="your_app_id"
# FEISHU_APP_SECRET="your_app_secret"
EOF
chmod 600 "$HERMES_HOME/.env"
echo "  ✅ .env 模板已创建（请填入你的密钥）"

# ── 11. 安装 CLI 工具 ──
echo ""
echo "📦 安装 CLI 工具..."
for tool in "@openai/codex" "@anthropic-ai/claude-code" "openclaw"; do
    pkg_name=$(echo "$tool" | cut -d'/' -f2)
    if ! command -v "$pkg_name" &>/dev/null; then
        echo "  📥 安装 $pkg_name..."
        npm install -g "$tool" 2>/dev/null && echo "  ✅ $pkg_name" || echo "  ⚠️ $pkg_name 安装失败"
    else
        echo "  ✅ $pkg_name 已安装"
    fi
done

# ── 12. 运行验证 ──
echo ""
echo "🔍 运行环境验证..."
if [ -f "$HERMESCLONE_DIR/hermescopy-verify.sh" ]; then
    bash "$HERMESCLONE_DIR/hermescopy-verify.sh" "$HERMESCLONE_DIR"
fi

# ── 清理 ──
rm -rf "$HERMESCLONE_DIR"

# ── 完成 ──
echo ""
echo "═══════════════════════════════════════════════════════"
echo "✅ 恢复完成！"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "下一步："
echo "  1. 编辑 ~/.hermes/.env 填入你的 API 密钥"
echo "  2. 运行 hermes 验证配置"
echo "  3. 运行 codex login 登录 ChatGPT 账号"
echo "  4. 如需 shell 配置：cat ~/Projects/hermescopy/shell-config/.zshrc.custom >> ~/.zshrc"
echo ""
